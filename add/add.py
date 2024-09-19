import ctypes


def main():
    lib = ctypes.CDLL("./build/add.so")
    lib.add.argtypes = (ctypes.c_int, ctypes.c_int)
    lib.add.restype = ctypes.c_int

    result = lib.add(ctypes.c_int(5), ctypes.c_int(10))
    print(result)


if __name__ == "__main__":
    main()
