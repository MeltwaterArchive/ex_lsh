![ExLSH logo](logo.svg)

## ExLSH

[![Build Status](https://travis-ci.com/meltwater/ex_lsh.svg?token=ydrd7j6fwuq6xzD4yQkt&branch=master)](https://travis-ci.com/meltwater/ex_lsh)

Calculates a locality sensitive hash for text.

[Locality-sensitive hashing](https://en.wikipedia.org/wiki/Locality-sensitive_hashing)
is a technique for dimensionality reduction. Its properties guarantee similar
output vectors for similar inputs. It can be used for clustering and
[near-duplicate detection](https://moz.com/devblog/near-duplicate-detection/).
This implementation is targeted for natural language as input. It takes a
`String` of arbitrary length and outputs a vector encoded as `:binary`.

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

- [SimHash](https://github.com/UniversalAvenue/simhash-ex) is a very similar,
  but less versatile implementation that is focused on short strings only.
  ExLSH is approximately [7 times faster](#benchmark) and supports arbitrary
  tokenization, shingling and hash functions.
- [SpiritFingers](https://github.com/holsee/spirit_fingers) is potentially
  faster than ExLSH but relies on a NIF written in Rust that is untrivial to
  compile, and doesn't support any customization of the algorithm.
- [Resemblance](https://github.com/matpalm/resemblance) explores simhash and
  sketching in Ruby. The author has documented his findings in a series of
  articles. You may want to make yourself familiar with
  [Part 3: The SimHash Algorithm](http://matpalm.com/resemblance/simhash/).
- [Near-duplicate detection](https://moz.com/devblog/near-duplicate-detection/)
  is a very helpful article by Moz. It explains core concepts such as
  tokinization, shingling, MinHash, SimHash, etc.

## Benchmark

Benchmark agains [SimHash](https://hex.pm/packages/simhash), run with
[Benchee](https://hex.pm/packages/benchee).

```
Compiling 2 files (.ex)
Generated ex_lsh app
Operating System: macOS
CPU Information: Intel(R) Core(TM) i7-4870HQ CPU @ 2.50GHz
Number of Available Cores: 8
Available memory: 16 GB
Elixir 1.8.1
Erlang 21.2.5

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 0 ns
parallel: 1
inputs: none specified
Estimated total run time: 14 s


Benchmarking ExLSH.lsh/1...
Benchmarking SimHash.hash/1...

Name                     ips        average  deviation         median         99th %
ExLSH.lsh/1           325.08        3.08 ms     ±8.25%        2.97 ms        3.87 ms
SimHash.hash/1         43.85       22.81 ms    ±12.32%       23.58 ms       27.68 ms

Comparison:
ExLSH.lsh/1           325.08
SimHash.hash/1         43.85 - 7.41x slower
```
