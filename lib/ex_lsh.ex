defmodule ExLSH do
  @moduledoc """
  TODO Documentation for ExLSH.
  """

  # see :crypto.supports()[:hashs] for all available hash functions on your platform
  @default_hash :md5

  @spec lsh(
          String.t(),
          pos_integer,
          function(list(String.t())) :: binary(),
          function(String.t()) :: String.t(),
          function(String.t()) :: list(String.t()),
          function(list(String.t())) :: String.t()
        ) :: binary
  @doc """
  Compute an LSH/SimHash for a given text. 

  Returns a non-printable `:binary` of the hash.

  The following parameters are configurable:
  - `shingle_width`: if given 1, it will use the "bag of words" approach.
    Given an int > 1, it will compute hashes of n-grams of the given width.
  - `hasher`: a function that takes an IOList and returns its hash in a
    `:binary`. LSH computation is significantly faster on shorter hashes.
  - `normalizer`: a function that takes a string and returns a normalized string
  - `tokenizer`: a function that takes a normalized string and returns
    tokens, e.g. graphemes or words
  - `filter`: a functions that filters a list of tokens, e.g. removes
    stop-words, non-ASCII chars, etc.
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
  def filter(words), do: words

  @doc """
  Converts a list of tokens into a list of overlapping lists.
  """
  def shingle(words, n) do
    Enum.chunk_every(words, n, 1, :discard)
  end

  @doc """
  Default hash, uses :crypto.hash(:md5)
  """
  def default_hash(message) do
    :crypto.hash(@default_hash, message)
  end

  @doc """
  Aggregate a list of binaries using a SimHash algorithm.
  """
  def add_vectors(vectors, hash_width) do
    seed = List.duplicate(0, hash_width)
    Enum.reduce(vectors, seed, &sum_binaries/2)
  end

  def sum_binaries(
        <<b0::size(1), b1::size(1), b2::size(1), b3::size(1), b4::size(1), b5::size(1),
          b6::size(1), b7::size(1), bin_rest::bitstring>>,
        [agg0, agg1, agg2, agg3, agg4, agg5, agg6, agg7 | agg_rest]
      ) do
    [
      agg0 + b0 * 2 - 1,
      agg1 + b1 * 2 - 1,
      agg2 + b2 * 2 - 1,
      agg3 + b3 * 2 - 1,
      agg4 + b4 * 2 - 1,
      agg5 + b5 * 2 - 1,
      agg6 + b6 * 2 - 1,
      agg7 + b7 * 2 - 1
      | sum_binaries(bin_rest, agg_rest)
    ]
  end

  def sum_binaries(<<>>, []), do: []

  @doc """
  Convert a list of ints to bits: positive ints become a 1, others: 0.
  """
  def ints_to_bits([head | tail]) when head > 0, do: [1 | ints_to_bits(tail)]
  def ints_to_bits([_head | tail]), do: [0 | ints_to_bits(tail)]
  def ints_to_bits([]), do: []

  @doc """
  Convert a list of bits represented by integers to a binary.
  """
  def bits_to_binary(bits) do
    bits
    |> Enum.chunk_every(8)
    |> Enum.map(&undigits/1)
    |> :binary.list_to_bin()
  end

  def undigits(bits), do: Integer.undigits(bits, 2)
end
