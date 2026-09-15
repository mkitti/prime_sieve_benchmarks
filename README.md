# Sieve of Eratosthenes: Mojo vs. Julia vs. Python

Three implementations of the same algorithm — a sieve of Eratosthenes with a
segmented extension — for comparing language/compiler characteristics:

- `sieve.mojo` / `sieve_mojo` — Mojo, ahead-of-time compiled binary.
- `sieve.jl` / `sieve_julia` — Julia, ahead-of-time compiled via `juliac --trim`.
- `sieve.py` — Python (CPython), interpreted.

All three take the same CLI arguments: `<limit> [new_limit]`.

## Building

```
pixi run build-julia   # produces ./sieve_julia
```

`sieve_mojo` is checked in as a pre-built binary (see `mojo_strace.txt` /
`pyenv_strace.txt` for how the environments were set up).

## Benchmarks

Measured with `hyperfine`, comparing pre-built/AOT binaries (`sieve_mojo`,
`sieve_julia`) against the interpreted `sieve.py` — no compilation cost is
included for any of the three.

| Benchmark | mojo (ms) | julia (ms) | python (ms) | mojo/julia | python/julia | python/mojo |
|:---|---:|---:|---:|---:|---:|---:|
| 10M | 178.2 ± 3.1 | 158.8 ± 2.7 | 1243.6 ± 21.0 | 1.12× | 7.83× | 6.98× |
| 50M | 1135 ± 23 | 601 ± 5 | 6641 ± 144 | 1.89× | 11.05× | 5.85× |
| 100M | 2885 ± 110 | 1141 ± 8 | 13988 ± 133 | 2.53× | 12.26× | 4.85× |
| extend (10M→20M) | 386.6 ± 24.0 | 320.0 ± 5.7 | 3114.3 ± 7.0 | 1.21× | 9.73× | 8.06× |

Ratios are relative to the smaller of the two divisors (e.g. `python/mojo`
6.98× means Python took 6.98x longer than mojo). Full raw hyperfine output is
in `bench_10m.md`, `bench_50m.md`, `bench_100m.md`, and `bench_extend.md`.

Julia is fastest across the board, and its lead over Mojo grows with sieve
size (1.12× at 10M up to 2.53× at 100M). This is likely due at least in part
to `sieve.jl` using a `BitVector` (1 bit per entry) for the composite flags,
versus a byte array (`List[Bool]` / `bytearray`, 1 byte per entry) in Mojo
and Python — a memory-layout difference rather than a purely
language/compiler one.
