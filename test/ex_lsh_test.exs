defmodule ExLSHTest do
  use ExUnit.Case
  doctest ExLSH
  require IEx

  test "Bag of words is independent of word order" do
    assert ExLSH.wordwise_lsh("foo bar baz", 1) == ExLSH.wordwise_lsh("foo baz bar", 1)
  end

  test "Repeating the phrase doesn't affect the hash" do
    s1 = repeat("foo bar baz", 100)
    s2 = repeat("foo bar baz", 200)
    assert ExLSH.wordwise_lsh(s1) == ExLSH.wordwise_lsh(s2)
  end

  def similarity(hash1, hash2) do
    1.0 - hamming_distance(hash_to_bin(hash1), hash_to_bin(hash2)) / length(hash_to_bin(hash1))
  end

  def hamming_distance([bit1 | rest1], [bit2 | rest2]) do
    if(bit1 == bit2, do: 0, else: 1) + hamming_distance(rest1, rest2)
  end

  def hamming_distance([], []), do: 0

  def hash_to_bin(
        <<b0::size(1), b1::size(1), b2::size(1), b3::size(1), b4::size(1), b5::size(1),
          b6::size(1), b7::size(1), rest::binary>>
      ) do
    [b0, b1, b2, b3, b4, b5, b6, b7] ++ hash_to_bin(rest)
  end

  def hash_to_bin(<<>>), do: []

  def repeat(s, times) do
    1..times |> Enum.map(fn _ -> s end) |> Enum.join(" ")
  end
end
