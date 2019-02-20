defmodule ExLSH.BitMacro do
  @moduledoc false

  # The following code aggregates hashes of shingles onto a list of ints.
  # To do this efficiently, we generate a set of functions that pattern-match
  # on the individual bits as wide as possible. An example implementation for 2
  # bits looks like this:
  #
  # def vector_reducer(
  #       <<b0::size(1), b1::size(1), b_rest::binary>>,
  #       [a0, a1 | a_rest]
  #     ) do
  #   [
  #     a0 + b0 * 2 - 1,
  #     a1 + b1 * 2 - 1 | vector_reducer(b_rest, a_rest)
  #   ]
  # end
  # def vector_reducer(<<>>, []), do: []
  #
  # This would result in 64 recursions per shingle for a 128-bit hash. To speed
  # things up, we try to match for as many bits as possible, and keep the
  # recursion number low. Obviously, writing this out for more than 16 bits is
  # unfeasible, so we have built a macro.

  @doc false
  defmacro vector_reducer(bits) do
    # match individual bits of the hash bitstring
    bit_matches =
      quote bind_quoted: [bits: bits] do
        for i <- 0..(bits - 1) do
          var = Macro.var(:"b#{i}", nil)

          quote do
            <<unquote(var)::size(1)>>
          end
        end
      end

    # match individual elements of the accumulator list
    acc_matches =
      quote bind_quoted: [bits: bits] do
        for i <- 0..(bits - 1) do
          Macro.var(:"a#{i}", nil)
        end
      end

    # bitwise operation: adds 1 if bit is 1, substracts 1 if bit is 0
    addition =
      quote bind_quoted: [bits: bits] do
        for i <- 0..(bits - 1) do
          bitvar = Macro.var(:"b#{i}", nil)
          accvar = Macro.var(:"a#{i}", nil)

          quote do
            unquote(accvar) + 2 * unquote(bitvar) - 1
          end
        end
      end

    quote bind_quoted: [
            bit_matches: bit_matches,
            acc_matches: acc_matches,
            addition: addition
          ] do
      defp vector_reducer(
             <<unquote_splicing(bit_matches), bit_rest::bitstring>>,
             [unquote_splicing(acc_matches) | acc_rest]
           ) do
        [unquote_splicing(addition) | vector_reducer(bit_rest, acc_rest)]
      end
    end
  end
end
