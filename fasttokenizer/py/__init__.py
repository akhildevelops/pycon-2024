import site
import ctypes
from pathlib import Path
from typing import Optional, List

LIBNAME = "libfasttokenizer.so"


def get_lib_path():
    paths = site.getsitepackages()
    for path in paths:
        lib_path = Path(path) / "fasttokenizer" / LIBNAME
        if lib_path.exists():
            return lib_path
    raise FileNotFoundError(f"{LIBNAME} cannot be found in site packages")


tokenizer_types = ["cl100k_base"]


class Tokenizer:
    def __init__(self, name: str, lib_path: Optional[Path] = None) -> None:
        if name not in tokenizer_types:
            raise ValueError(f"Only these tokenizers are supported: {tokenizer_types}")
        if lib_path is None:
            self.lib_path = get_lib_path()
        else:
            if not lib_path.exists():
                raise FileNotFoundError(f"Cannot find the lib_path at {lib_path}")
            self.lib_path = lib_path

        self._lib = ctypes.CDLL(self.lib_path)
        self._lib.token_ranker.restype = ctypes.c_void_p
        self._lib.encode.argtypes = (
            ctypes.c_char_p,
            ctypes.POINTER(ctypes.c_uint),
            ctypes.c_void_p,
        )
        self._lib.encode.restype = ctypes.POINTER(ctypes.c_uint)

        encoder = ctypes.c_char_p(name.encode())
        l_encoder = ctypes.c_size_t(len(name.encode()))
        self._token_ranker = self._lib.token_ranker(encoder, l_encoder)

    def tokenize(self, text: str) -> List[int]:
        text = ctypes.c_char_p(text)
        i = ctypes.pointer(ctypes.c_uint())
        result_z = self._lib.encode(text, i, self._token_ranker)
        return [result_z[k] for k in range(0, i[0])]


if __name__ == "__main__":
    tokenizer = Tokenizer(
        "cl100k_base", lib_path=Path("./zig-out/lib/libfasttokenizer.so")
    )
    tokens = tokenizer.tokenize(
        b"Operations on vectors shorter than the target machine's native SIMD size will typically compile to single "
    )
    print(tokens)
