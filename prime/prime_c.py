import ctypes
import sys


def main():
    n = 10
    if (len(sys.argv)) > 1:
        n = int(sys.argv[1])
    lib = ctypes.CDLL("./build/prime.so")
    lib.primes.restype = ctypes.POINTER(ctypes.c_int)
    result = lib.primes(n)
    print(f"Displaying partial primes from first {n} primes:")
    print([result[i] for i in range(n)][:10])


if __name__ == "__main__":
    main()
