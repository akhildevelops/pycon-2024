import os

import time


import tiktoken
from typing import Any, cast

import site
import ctypes
from pathlib import Path
from typing import Optional, List, Dict
import transformers


LIBNAME = "libfasttokenizer.so"


def get_lib_path():
    paths = site.getsitepackages()
    for path in paths:
        lib_path = Path(path) / "fasttokenizer" / LIBNAME
        if lib_path.exists():
            return lib_path
    raise FileNotFoundError(f"{LIBNAME} cannot be found in site packages")


tokenizer_types = ["cl100k_base", "r50k_base"]


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
        num_threads = int(os.environ["RAYON_NUM_THREADS"])
        data_bytes = data.encode()
        num_bytes = len(data_bytes)
        print(f"num_threads: {num_threads}, num_bytes: {num_bytes}")

        enc = tiktoken.get_encoding("r50k_base")
        enc.encode("warmup")

        t_tokens = enc._encode_bytes(data_bytes)

        tokenizer = Tokenizer(
            "r50k_base",
            lib_path=Path("fasttokenizer/zig-out/lib/libfasttokenizer.so"),
        )
        z_tokens = tokenizer.tokenize(data_bytes)

        hf_enc = cast(Any, transformers).GPT2TokenizerFast.from_pretrained("gpt2")

        hf_enc.model_max_length = 1e30  # silence!
        hf_enc.encode("warmup")

        hf_tokens = hf_enc([data])

        print("#################################\n\n")

        assert (t_tokens == z_tokens) and (t_tokens == hf_tokens["input_ids"][0])


if __name__ == "__main__":
    # files = ["question.txt", "naatu.txt", "Dictionary.txt", "coc.txt"]
    files = ["lorem.txt"]
    data = {}
    for file in files:
        with open(f"data/{file}") as f:
            data[file] = f.read()
    # data["text"] = (
    #     "Operations on vectors shorter than the target machine's native SIMD size will typically compile to single "
    # )

    benchmark_batch(data)
