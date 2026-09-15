"""Sieve of Eratosthenes over the range of primes that fit in a signed 64-bit integer."""

import math
import sys

INT64_MAX = 2**63 - 1


def sieve_of_eratosthenes(limit: int) -> list[int]:
    if limit > INT64_MAX:
        raise ValueError(f"limit must fit in a signed 64-bit integer (<= {INT64_MAX})")
    if limit < 2:
        return []

    is_composite = bytearray(limit + 1)
    i = 2
    while i * i <= limit:
        if not is_composite[i]:
            for j in range(i * i, limit + 1, i):
                is_composite[j] = 1
        i += 1

    return [n for n in range(2, limit + 1) if not is_composite[n]]


def extend_sieve(primes: list[int], previous_limit: int, new_limit: int) -> list[int]:
    """Continue a previously computed sieve up to `new_limit`.

    Python has no ownership system to demonstrate here: `primes` is passed by
    object reference, mutated in place, and the caller's own binding stays
    valid (and aliased to this same list) after the call returns. Contrast
    with the Mojo version's `var` parameter, which moves the list in and
    leaves the caller's binding unusable -- a compile-time guarantee Python
    simply doesn't have.
    """
    if new_limit <= previous_limit:
        return primes
    if new_limit > INT64_MAX:
        raise ValueError(f"new_limit must fit in a signed 64-bit integer (<= {INT64_MAX})")

    low = previous_limit + 1
    high = new_limit
    sqrt_high = math.isqrt(high) + 1
    if previous_limit < sqrt_high:
        raise ValueError(
            f"previous_limit ({previous_limit}) must be >= sqrt(new_limit) ({sqrt_high}) "
            "to extend directly; extend in smaller steps"
        )

    # Segmented sieve: mark composites in (previous_limit, new_limit] using
    # the primes already known (they cover everything up to sqrt(new_limit)).
    segment = bytearray(high - low + 1)
    for p in primes:
        if p * p > high:
            break
        start = max(p * p, -(-low // p) * p)  # ceil(low / p) * p
        for m in range(start, high + 1, p):
            segment[m - low] = 1

    primes.extend(m for m in range(low, high + 1) if not segment[m - low])
    return primes


def main() -> None:
    limit = int(sys.argv[1]) if len(sys.argv) > 1 else 100
    new_limit = int(sys.argv[2]) if len(sys.argv) > 2 else 0

    primes = sieve_of_eratosthenes(limit)
    print(f"Primes up to {limit} (count: {len(primes)})")
    print(", ".join(str(p) for p in primes))

    if new_limit > limit:
        extended = extend_sieve(primes, limit, new_limit)
        print(f"Extended to {new_limit} (count: {len(extended)})")
        print(", ".join(str(p) for p in extended))


if __name__ == "__main__":
    main()
