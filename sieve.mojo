"""Sieve of Eratosthenes over the range of primes that fit in a signed 64-bit integer."""

from std.math import sqrt
from std.sys import argv

comptime INT64_MAX: Int64 = 9223372036854775807


def sieve_of_eratosthenes(limit: Int64) raises -> List[Int64]:
    var primes = List[Int64]()
    if limit > INT64_MAX:
        raise Error("limit must fit in a signed 64-bit integer (<= " + String(INT64_MAX) + ")")
    if limit < 2:
        return primes^

    var n = Int(limit)
    var is_composite = List[Bool](capacity=n + 1)
    for _ in range(n + 1):
        is_composite.append(False)

    var i = 2
    while i * i <= n:
        if not is_composite[i]:
            var j = i * i
            while j <= n:
                is_composite[j] = True
                j += i
        i += 1

    for k in range(2, n + 1):
        if not is_composite[k]:
            primes.append(Int64(k))

    return primes^


def extend_sieve(var primes: List[Int64], previous_limit: Int64, new_limit: Int64) raises -> List[Int64]:
    """Continue a previously computed sieve up to `new_limit`.

    `primes` uses Mojo's `var` argument convention: it moves the caller's list
    into this function instead of copying it, so the caller must relinquish
    their binding by passing it as `extend_sieve(primes^, ...)`. After that
    call, the compiler treats the caller's `primes` as uninitialized -- trying
    to read it again is a compile error, not a runtime bug. This function
    grows the same list in place with a segmented sieve over
    (previous_limit, new_limit] and moves it back out via `return primes^`,
    so the whole round trip never copies the prime list.
    """
    if new_limit <= previous_limit:
        return primes^
    if new_limit > INT64_MAX:
        raise Error("new_limit must fit in a signed 64-bit integer (<= " + String(INT64_MAX) + ")")

    var low = Int(previous_limit) + 1
    var high = Int(new_limit)
    var sqrt_high = Int(sqrt(Float64(high))) + 1
    if Int(previous_limit) < sqrt_high:
        raise Error(
            "previous_limit (" + String(previous_limit) + ") must be >= sqrt(new_limit) ("
            + String(sqrt_high) + ") to extend directly; extend in smaller steps"
        )

    # Segmented sieve: mark composites in (previous_limit, new_limit] using
    # the primes already known (they cover everything up to sqrt(new_limit)).
    var segment_size = high - low + 1
    var is_composite = List[Bool](capacity=segment_size)
    for _ in range(segment_size):
        is_composite.append(False)

    for idx in range(len(primes)):
        var p = Int(primes[idx])
        if p * p > high:
            break
        var start = max(p * p, ((low + p - 1) // p) * p)
        var m = start
        while m <= high:
            is_composite[m - low] = True
            m += p

    for m in range(low, high + 1):
        if not is_composite[m - low]:
            primes.append(Int64(m))

    return primes^


def format_primes(primes: List[Int64]) -> String:
    # Default `def` argument convention is an immutable borrow: `primes` is
    # only read here, and the caller keeps ownership after this call returns.
    var line = String("")
    for i in range(len(primes)):
        line += String(primes[i])
        if i != len(primes) - 1:
            line += ", "
    return line


def main() raises:
    var limit: Int64 = 100
    var new_limit: Int64 = 0
    var args = argv()
    if len(args) > 1:
        limit = Int64(atol(args[1]))
    if len(args) > 2:
        new_limit = Int64(atol(args[2]))

    var primes = sieve_of_eratosthenes(limit)
    print("Primes up to", limit, "(count:", len(primes), ")")
    print(format_primes(primes))

    if new_limit > limit:
        # `primes^` moves ownership of the list into extend_sieve; `primes`
        # is no longer valid after this line.
        var extended = extend_sieve(primes^, limit, new_limit)
        # Uncomment the next line to see the compiler reject the
        # use-after-move at compile time, not at runtime:
        # print(len(primes))
        print("Extended to", new_limit, "(count:", len(extended), ")")
        print(format_primes(extended))
