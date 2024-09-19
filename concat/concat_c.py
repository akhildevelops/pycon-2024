import ctypes


def main():
    lib = ctypes.CDLL("./build/concat.so")
    lib.concat.restype = ctypes.c_char_p
    result = lib.concat(ctypes.c_char_p(b"Hello "), ctypes.c_char_p(b"World"))
    print(f"Concatted string: {result.decode('utf-8')}")


if __name__ == "__main__":
    main()
