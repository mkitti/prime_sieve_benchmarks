# Sieve of Eratosthenes: Mojo vs. Julia vs. Python

Three implementations of the same algorithm — a sieve of Eratosthenes with a
segmented extension — for comparing language/compiler characteristics:

- `sieve.mojo` / `sieve_mojo` — Mojo, ahead-of-time compiled binary.
- `sieve.jl` / `sieve_julia` — Julia, ahead-of-time compiled via `juliac --trim`
  (using [`JuliaC.jl`](https://github.com/JuliaLang/JuliaC.jl) on Julia 1.13).
- `sieve.py` — Python (CPython), interpreted.

All three take the same CLI arguments: `<limit> [new_limit]`.

## Building

```
pixi run build-julia   # produces ./sieve_julia
pixi run build-mojo    # produces ./sieve_mojo
```

`build-julia` installs the `JuliaC` app (`pixi run install-juliac`, a
one-time step) and then invokes it to AOT-compile and trim `sieve.jl` into a
standalone executable. Neither binary is checked into git: both embed an
`RPATH` pointing at this project's local `.pixi/envs/default/lib` and
dynamically link against runtime shared libraries from that exact
environment, so they aren't portable across machines or even across a
`pixi clean` — rebuild them locally instead. (See `mojo_strace.txt` /
`pyenv_strace.txt` for how the environments were originally set up.)

## Benchmarks

Measured with `hyperfine`, comparing pre-built/AOT binaries (`sieve_mojo`,
`sieve_julia`) against the interpreted `sieve.py` — no compilation cost is
included for any of the three.

| Benchmark | mojo (ms) | julia (ms) | python (ms) | mojo/julia | python/julia | python/mojo |
|:---|---:|---:|---:|---:|---:|---:|
| 10M | 180.2 ± 3.9 | 161.9 ± 12.4 | 1228.1 ± 6.2 | 1.11× | 7.59× | 6.82× |
| 50M | 1117 ± 29 | 585 ± 7 | 6565 ± 45 | 1.91× | 11.23× | 5.88× |
| 100M | 2925 ± 25 | 1101 ± 5 | 14328 ± 517 | 2.66× | 13.01× | 4.90× |
| extend (10M→20M) | 377.7 ± 6.8 | 318.9 ± 5.0 | 3116.0 ± 6.8 | 1.18× | 9.77× | 8.25× |

Ratios are relative to the smaller of the two divisors (e.g. `python/mojo`
6.82× means Python took 6.82x longer than mojo). Full raw hyperfine output is
in `bench_10m.md`, `bench_50m.md`, `bench_100m.md`, and `bench_extend.md`.

Julia is fastest across the board, and its lead over Mojo grows with sieve
size (1.11× at 10M up to 2.66× at 100M). This is likely due at least in part
to `sieve.jl` using a `BitVector` (1 bit per entry) for the composite flags,
versus a byte array (`List[Bool]` / `bytearray`, 1 byte per entry) in Mojo
and Python — a memory-layout difference rather than a purely
language/compiler one.

### Binary size

`sieve_julia`'s trimmed binary (~1.7 MB) is roughly 25x larger than
`sieve_mojo`'s (~65 KB), even after stripping debug symbols from both
(~1.1 MB vs ~44 KB). `sieve_mojo` offloads most of its runtime into shared
libraries (`libKGENCompilerRTShared.so`, `libAsyncRTMojoBindings.so`, etc.),
while `juliac --trim` still bakes a substantial amount of the Julia
runtime/GC support directly into the executable.
