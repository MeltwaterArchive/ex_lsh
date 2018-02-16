# ExLSH

Calculates a locality sensitive hash for text.

[Locality-sensitive hashing](https://en.wikipedia.org/wiki/Locality-sensitive_hashing) is a
technique for dimensionality reduction. Its properties guarantee similar
output vectors for similar inputs. It can be used for clustering and
[near-duplicate detection](https://moz.com/devblog/near-duplicate-detection/). This implementation is targeted for natural language as input. It takes a `String` of arbitrary length and outputs a vector encoded as `:binary`.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_lsh` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_lsh, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_lsh](https://hexdocs.pm/ex_lsh).

## Usage

TBD


## Credits

- [SimHash](https://github.com/UniversalAvenue/simhash-ex) is a very similar, but less versatile implementation that is focused on short strings only.
- [Resemblance](https://github.com/matpalm/resemblance) explores simhash and sketching in Ruby. The author has documented his findings in a series of articles. You may want to make yourself familiar with [Part 3: The SimHash Algorithm](http://matpalm.com/resemblance/simhash/).
- [Near-duplicate detection](https://moz.com/devblog/near-duplicate-detection/) is a very helpful article by Moz. It explains core concepts such as tokinzation, shingling, MinHash, SimHash, etc.
