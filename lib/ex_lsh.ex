defmodule ExLSH do
  @moduledoc """
  Calculates a locality sensitive hash for text.

  ## Examples:

      iex> "Lorem ipsum dolor sit amet"
      ...> |> ExLSH.lsh()
      ...> |> :base64.encode()
      "uX05itKaghA0gQHCwDCIFg=="

      iex> "Lorem ipsum dolor sit amet"
      ...> |> ExLSH.lsh(2, &:crypto.hash(:sha, &1))
      ...> |> :base64.encode()
      "VhW06EEJyWQA1gKIAAlQgI4NHUE="

  """

  @spec lsh(
          String.t(),
          pos_integer,
          (iodata() -> binary()),
          (String.t() -> String.t()),
          (String.t() -> list(String.t())),
          (list(String.t()) -> list(String.t()))
        ) :: binary

  @doc ~S"""
  Compute an LSH/SimHash for a given text.

  Returns a non-printable `:binary` of the hash.

  ## The following parameters are configurable:
  - `shingle_width`: if given 1, it will use the "bag of words" approach.
  Given an int > 1, it will compute hashes of n-grams of the given width.
  - `hasher`: a function that takes an IOList and returns its hash in a
  `:binary`. LSH computation is significantly faster on shorter hashes. See
  :crypto.supports()[:hashs] for all available hash functions on your
  platform
  - `normalizer`: a function that takes a string and returns a normalized string
  - `tokenizer`: a function that takes a normalized string and returns
  tokens, e.g. graphemes or words
  - `filter`: a functions that filters a list of tokens, e.g. removes
  stop-words, non-ASCII chars, etc.

  ## Examples:

      iex> "Lorem ipsum dolor sit amet"
      ...> |> ExLSH.lsh()
      ...> |> :base64.encode()
      "uX05itKaghA0gQHCwDCIFg=="

      iex> "Lorem ipsum dolor sit amet"
      ...> |> ExLSH.lsh(2, &:crypto.hash(:sha, &1))
      ...> |> :base64.encode()
      "VhW06EEJyWQA1gKIAAlQgI4NHUE="

  """
  def lsh(
        text,
        shingle_width \\ 3,
        hasher \\ &default_hash/1,
        normalizer \\ &normalize/1,
        tokenizer \\ &tokenize_words/1,
        filter \\ &filter/1
      ) do
    hash_width = bit_size(hasher.("foo"))

    text
    |> normalizer.()
    |> tokenizer.()
    |> filter.()
    |> shingle(shingle_width)
    |> Enum.map(hasher)
    |> add_vectors(hash_width)
    |> ints_to_bits()
    |> bits_to_binary()
  end

  @doc """
  Compute an LSH for a piece of text, e.g. a document.
  """
  def wordwise_lsh(text, shingle_width \\ 3) do
    lsh(text, shingle_width)
  end

  @doc """
  Compute an LSH for a short string, e.g. a username or email.
  """
  def charwise_lsh(text, shingle_width \\ 3) do
    lsh(text, shingle_width, &default_hash/1, &normalize/1, &tokenize_chars/1)
  end

  @doc """
  Default text normalizer: unicode normalization, lower case, replace all
  non-word chars with space, reduce consecutive spaces to one.
  """
  def normalize(text) do
    text
    |> String.normalize(:nfc)
    |> String.downcase()
    |> String.replace(~r/\W/, " ")
    |> String.replace(~r/\W+/, " ")
  end

  @doc """
  Split a string to its unicode graphemes.
  """
  def tokenize_chars(text), do: text |> String.graphemes()

  @doc """
  Split a string into words
  """
  def tokenize_words(text), do: text |> String.split()

  @doc """
  A noop filter.
  """
  @spec filter(String.t()) :: String.t()
  def filter(words), do: words

  # Converts a list of tokens into a list of overlapping lists.
  defp shingle(words, n) do
    Enum.chunk_every(words, n, 1, :discard)
  end

  @doc """
  Default hash, uses `:crypto.hash(:md5)`
  """
  def default_hash(message) do
    :erlang.md5(message)
  end

  # Aggregate a list of binaries using a SimHash algorithm.
  defp add_vectors(vectors, hash_width) do
    acc = List.duplicate(0, hash_width)
    Enum.reduce(vectors, acc, &agg_bits/2)
  end

  # Convert a list of ints to bits: positive ints become a 1, others: 0.
  defp ints_to_bits([head | tail]) when head > 0, do: [1 | ints_to_bits(tail)]
  defp ints_to_bits([_head | tail]), do: [0 | ints_to_bits(tail)]
  defp ints_to_bits([]), do: []

  # Convert a list of bits represented by integers to a binary.
  defp bits_to_binary(bits) do
    bits
    |> Enum.chunk_every(8)
    |> Enum.map(&Integer.undigits(&1, 2))
    |> :binary.list_to_bin()
  end

  # Generates a pattern matcher for `count` leftmost bits of a binary and its
  # `rest`. Bit #0 goes into a variable `b0`, #1 into `b1` and so on.
  defmacrop match_bits(prefix, count, rest) do
    # doing it backwards to be able to add the rest matcher and then flip
    bits_match =
      for i <- (count - 1)..0 do
        {:::, [],
         [
           {:var!, [context: Elixir, import: Kernel],
            [{String.to_atom("#{prefix}#{i}"), [], Elixir}]},
           {:size, [], [1]}
         ]}
      end

    rest_match =
      quote do
        unquote(rest) :: binary
      end

    {:<<>>, [], Enum.reverse([rest_match | bits_match])}
  end

  # Generates a pattern matcher for `count` leftmost elements of a list and its
  # tail. Element #0 goes into a variable `<prefix>0`, #1 into `<prefix>1` and
  # so on.
  defmacrop match_list(prefix, count, rest) do
    # doing it backwards to be able to add the rest matcher and then flip
    list_match =
      for i <- (count - 1)..0 do
        {:var!, [context: Elixir, import: Kernel],
         [{String.to_atom("#{prefix}#{i}"), [], Elixir}]}
      end

    rest_var =
      quote do
        unquote(rest)
      end

    rest_match =
      {:|, {},
       [
         hd(list_match),
         rest_var
       ]}

    Enum.reverse([rest_match | tl(list_match)])
  end

  # Sums a number of bits
  defmacrop sum_bits(bit_prefix, bit_rest, acc_prefix, acc_rest, count, fun) do
    elements =
      for i <- (count - 1)..0 do
        quote do
          unquote(
            {:var!, [context: Elixir, import: Kernel], [{:"#{acc_prefix}#{i}", [], Elixir}]}
          ) +
            2 *
              unquote(
                {:var!, [context: Elixir, import: Kernel], [{:"#{bit_prefix}#{i}", [], Elixir}]}
              ) - 1
        end
      end

    recursion =
      quote do
        unquote(fun)(unquote(bit_rest), unquote(acc_rest))
      end

    tail_recursion =
      {:|, {},
       [
         hd(elements),
         recursion
       ]}

    Enum.reverse([tail_recursion | tl(elements)])
  end

  defp agg_bits(<<>>, []), do: []

  for i <- [256, 128, 64, 32, 8] do
    defp agg_bits(
           match_bits(:b, unquote(i), bin_rest),
           match_list(:acc, unquote(i), acc_rest)
         ) do
      sum_bits(:b, bin_rest, :acc, acc_rest, unquote(i), :agg_bits)
    end
  end
end
