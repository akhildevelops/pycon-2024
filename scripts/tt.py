import os
import sys

import tiktoken
from typing import Dict


def benchmark_batch(documents: Dict[str, str]) -> None:
    for _, data in documents.items():
        # num_threads = int(os.environ["RAYON_NUM_THREADS"])
        data_bytes = data.encode()
        # num_bytes = len(data_bytes)
        # print(f"num_threads: {num_threads}, num_bytes: {num_bytes}")

        enc = tiktoken.get_encoding("r50k_base")

        t_tokens = enc._encode_bytes(data_bytes)
        # print(t_tokens)


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
