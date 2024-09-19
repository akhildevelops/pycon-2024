# pycon-2024
Slides: https://slides.com/akhilg/pycon2024-blr

Run `add, concat, prime` programs by running below make commands respectively
```shell
make add
make concat
make prime
```

Run tokenizer benchmarks across pure python, rust and zig implementations through docker.
```shell
docker build -t pycon2024:latest .
docker run --rm pycon2024
```