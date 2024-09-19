import sys


def is_prime(num):
    i: int = 2
    while i * i <= num:
        if num % i == 0:
            return False
        i += 1
    return True


def main():
    n = 10
    if len(sys.argv) > 1:
        n = int(sys.argv[1])
    primes = []
    counter = 2
    while len(primes) < n:
        if is_prime(counter):
            primes.append(counter)
        counter += 1
    print(f"Displaying partial primes from first {n} primes:")
    print(primes[:10])


if __name__ == "__main__":
    main()
