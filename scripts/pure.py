import sys


from typing import Any, cast

from typing import Dict
import transformers


def benchmark_batch(documents: Dict[str, str]) -> None:
    for file_name, data in documents.items():
        hf_enc = cast(Any, transformers).GPT2TokenizerFast.from_pretrained("gpt2")

        hf_enc.model_max_length = 1e30  # silence!

        hf_tokens = hf_enc([data])
        # print(hf_tokens)


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
