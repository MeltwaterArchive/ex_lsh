# ExLSH

[![Build Status](https://travis-ci.com/meltwater/ex_lsh.svg?token=ydrd7j6fwuq6xzD4yQkt&branch=master)](https://travis-ci.com/meltwater/ex_lsh)

Calculates a locality sensitive hash for text.

[Locality-sensitive hashing](https://en.wikipedia.org/wiki/Locality-sensitive_hashing) is a
technique for dimensionality reduction. Its properties guarantee similar
output vectors for similar inputs. It can be used for clustering and
[near-duplicate detection](https://moz.com/devblog/near-duplicate-detection/). This implementation is targeted for natural language as input. It takes a `String` of arbitrary length and outputs a vector encoded as `:binary`.

## Installation

Add `ex_lsh` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_lsh, version: "~> 0.4"}
  ]
end
```

## Usage

```elixir
"Lorem ipsum dolor sit amet"
|> ExLSH.lsh()
|> Base.encode64()
```

## Docs
see [hexdocs.pm/ex_lsh](https://hexdocs.pm/ex_lsh)

## Contributions
Please fork the project and submit a PR.

## Credits

- [SimHash](https://github.com/UniversalAvenue/simhash-ex) is a very similar, but less versatile implementation that is focused on short strings only.
- [Resemblance](https://github.com/matpalm/resemblance) explores simhash and sketching in Ruby. The author has documented his findings in a series of articles. You may want to make yourself familiar with [Part 3: The SimHash Algorithm](http://matpalm.com/resemblance/simhash/).
- [Near-duplicate detection](https://moz.com/devblog/near-duplicate-detection/) is a very helpful article by Moz. It explains core concepts such as tokinization, shingling, MinHash, SimHash, etc.
