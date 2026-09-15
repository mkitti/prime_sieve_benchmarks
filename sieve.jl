"""Sieve of Eratosthenes over the range of primes that fit in a signed 64-bit integer."""

const INT64_MAX = typemax(Int64)

function sieve_of_eratosthenes(limit::Int64)::Vector{Int64}
    limit > INT64_MAX && error("limit must fit in a signed 64-bit integer (<= $INT64_MAX)")
    limit < 2 && return Int64[]

    n = Int(limit)
    is_composite = falses(n + 1)  # index k+1 holds status for value k

    i = 2
    while i * i <= n
        if !is_composite[i + 1]
            j = i * i
            while j <= n
                is_composite[j + 1] = true
                j += i
            end
        end
        i += 1
    end

    return Int64[k for k in 2:n if !is_composite[k + 1]]
end

"""
    extend_sieve(primes, previous_limit, new_limit) -> Vector{Int64}

Continue a previously computed sieve up to `new_limit`.

Julia arrays are reference types like Python's list: `primes` is passed by
reference, appended to in place with `push!`/`append!`, and the caller's own
binding stays valid (and aliased to this same array) after the call returns.
Contrast with the Mojo version's `var` parameter, which moves the list in and
leaves the caller's binding unusable -- a compile-time guarantee neither
Julia nor Python has.
"""
function extend_sieve(primes::Vector{Int64}, previous_limit::Int64, new_limit::Int64)::Vector{Int64}
    new_limit <= previous_limit && return primes
    new_limit > INT64_MAX && error("new_limit must fit in a signed 64-bit integer (<= $INT64_MAX)")

    low = Int(previous_limit) + 1
    high = Int(new_limit)
    sqrt_high = isqrt(high) + 1
    if Int(previous_limit) < sqrt_high
        error(
            "previous_limit ($previous_limit) must be >= sqrt(new_limit) ($sqrt_high) " *
            "to extend directly; extend in smaller steps",
        )
    end

    # Segmented sieve: mark composites in (previous_limit, new_limit] using
    # the primes already known (they cover everything up to sqrt(new_limit)).
    segment = falses(high - low + 1)
    for p64 in primes
        p = Int(p64)
        p * p > high && break
        start = max(p * p, cld(low, p) * p)
        m = start
        while m <= high
            segment[m - low + 1] = true
            m += p
        end
    end

    append!(primes, Int64(m) for m in low:high if !segment[m - low + 1])
    return primes
end

function format_primes(primes::Vector{Int64})::String
    return join(primes, ", ")
end

function (@main)(args::Vector{String})::Cint
    limit = length(args) > 0 ? parse(Int64, args[1]) : Int64(100)
    new_limit = length(args) > 1 ? parse(Int64, args[2]) : Int64(0)

    primes = sieve_of_eratosthenes(limit)
    println(Core.stdout, "Primes up to $limit (count: $(length(primes)))")
    println(Core.stdout, format_primes(primes))

    if new_limit > limit
        extended = extend_sieve(primes, limit, new_limit)
        println(Core.stdout, "Extended to $new_limit (count: $(length(extended)))")
        println(Core.stdout, format_primes(extended))
    end

    return 0
end
