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
- [SpiritFingers](https://github.com/holsee/spirit_fingers) is ca. [27 times
  faster](#benchmark) than ExLSH but relies on a NIF that needs the full Rust
  toolchain to compile. SpiritFingers doesn't support customization of the
  algorithm, it uses SipHash by default.
- [Resemblance](https://github.com/matpalm/resemblance) explores simhash and
  sketching in Ruby. The author has documented his findings in a series of
  articles. You may want to make yourself familiar with
  [Part 3: The SimHash Algorithm](http://matpalm.com/resemblance/simhash/).
- [Near-duplicate detection](https://moz.com/devblog/near-duplicate-detection/)
  is a very helpful article by Moz. It explains core concepts such as
  tokenization, shingling, MinHash, SimHash, etc.

## Benchmark

Benchmark against [SimHash](https://hex.pm/packages/simhash), run with
[Benchee](https://hex.pm/packages/benchee). See the setup on the [benchmark
branch](https://github.com/meltwater/ex_lsh/tree/benchmark).

```
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
Estimated total run time: 21 s


Benchmarking ExLSH...
Benchmarking Simhash...
Benchmarking SpiritFingers...

Name                    ips        average  deviation         median         99th %
SpiritFingers       8556.15       0.117 ms    ±13.37%       0.111 ms       0.183 ms
ExLSH                309.61        3.23 ms     ±5.88%        3.19 ms        3.81 ms
Simhash               43.19       23.15 ms    ±12.57%       22.08 ms       30.54 ms

Comparison:
SpiritFingers       8556.15
ExLSH                309.61 - 27.64x slower
Simhash               43.19 - 198.11x slower
```
