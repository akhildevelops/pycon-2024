import ctypes
from pathlib import Path
from typing import Optional, List, Dict
import sys

tokenizer_types = ["cl100k_base", "r50k_base"]


class Tokenizer:
    def __init__(self, name: str, lib_path: Optional[Path] = None) -> None:
        if name not in tokenizer_types:
            raise ValueError(f"Only these tokenizers are supported: {tokenizer_types}")

        self.lib_path = lib_path

        self._lib = ctypes.CDLL(self.lib_path)
        self._lib.token_ranker.argtypes = (ctypes.c_char_p, ctypes.c_size_t)
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

    def tokenize(self, text: bytes) -> List[int]:
        text = ctypes.c_char_p(text)
        i = ctypes.pointer(ctypes.c_uint())
        result_z = self._lib.encode(text, i, self._token_ranker)
        return [result_z[k] for k in range(0, i[0])]


def benchmark_batch(documents: Dict[str, str]) -> None:
    for file_name, data in documents.items():
        data_bytes = data.encode()
        tokenizer = Tokenizer(
            "r50k_base",
            lib_path=Path("/home/fasttokenizer/zig-out/lib/libfasttokenizer.so"),
        )
        z_tokens = tokenizer.tokenize(data_bytes)
        # print(z_tokens)


if __name__ == "__main__":
    # files = ["question.txt", "naatu.txt", "Dictionary.txt", "coc.txt"]
    files = [sys.argv[1]]
    data = {}
    for file in files:
        with open(f"data/{file}") as f:
            data[file] = f.read()
    # data["text"] = (
    #     "Operations on vectors shorter than the target machine's native SIMD size will typically compile to single "
    # )

    benchmark_batch(data)
