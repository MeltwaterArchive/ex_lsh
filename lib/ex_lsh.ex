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
    matrix =
      vectors
      |> hashlist_to_matrex(hash_width)
      |> Matrex.multiply(2)
      |> Matrex.add(-1)
      |> Matrex.transpose()

    for i <- 1..hash_width do
      matrix[i] |> Matrex.sum()
    end

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

  defp hashlist_to_matrex(vectors, hash_width) do
    binvectors = Enum.reduce(vectors, <<>>, &concat/2)
    rows = length(vectors)

    header = <<
      rows::integer-unsigned-little-32,
      hash_width::integer-unsigned-little-32
    >>

    %Matrex{data: append_digits(binvectors, header)}
  end

  defp concat(bin1, bin2) when is_binary(bin1) and is_binary(bin2) do
    <<bin1::binary, bin2::binary>>
  end

  # Generates a pattern matcher for `count` leftmost bits of a binary and its
  # `rest`. Bit #0 goes into a variable `b0`, #1 into `b1` and so on. Use
  # together with `float_bits`.
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
      for i <- (count - 2)..0 do
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
         {:var!, [context: Elixir, import: Kernel],
          [{String.to_atom("#{prefix}#{count - 1}"), [], Elixir}]},
         rest_var
       ]}

    Enum.reverse([rest_match | list_match])
  end

  # Outputs bits previously matched with `match_bits/2` to a binary as floats.
  # This is used to construct a Matrex.
  defmacrop float_bits(prefix, count, agg) do
    bits_bin =
      for i <- 0..(count - 1) do
        {:::, [],
         [
           {:var!, [context: Elixir, import: Kernel],
            [{String.to_atom("#{prefix}#{i}"), [], Elixir}]},
           quote do
             float - little - 32
           end
         ]}
      end

    agg_bin =
      quote do
        unquote(agg) :: binary
      end

    {:<<>>, [], [agg_bin | bits_bin]}
  end

  defp append_digits(<<>>, agg), do: agg

  # Generate bit aggregators for all common hash function bit widths
  for i <- [512, 384, 256, 224, 160, 128, 64, 32, 8] do
    defp append_digits(match_bits(:b, unquote(i), rest), agg),
      do: append_digits(rest, float_bits(:b, unquote(i), agg))
  end

  def agg_bits(
        match_bits(:b, 8, bin_rest),
        match_list(:acc, 8, acc_rest)
      ) do
    [
      acc0 + (b0 * 2 - 1),
      acc1 + (b1 * 2 - 1),
      acc2 + (b2 * 2 - 1),
      acc3 + (b3 * 2 - 1),
      acc4 + (b4 * 2 - 1),
      acc5 + (b5 * 2 - 1),
      acc6 + (b6 * 2 - 1),
      acc7 + (b7 * 2 - 1)
      | agg_bits(bin_rest, acc_rest)
    ]
  end

  def agg_bits(<<>>, []), do: []
end
