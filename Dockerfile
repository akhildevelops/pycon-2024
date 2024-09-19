FROM debian:12.7
WORKDIR /home

RUN apt update && apt upgrade

#Install Python
RUN apt install -y curl \
    python3 \
    python3-pip \
    python3-venv

# Install Rust toolchain
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
# RUN echo 'source $HOME/.cargo/env' >> /etc/profile
# Add Cargo to PATH
ENV PATH="/root/.cargo/bin:${PATH}"
RUN ["cargo", "install", "hyperfine"]


# Install Zig
RUN curl https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz --output zig-linux.tar.gz
RUN tar -xf zig-linux.tar.gz
ENV PATH="/home/zig-linux-x86_64-0.13.0:${PATH}"

# Install tiktoken and transformers packages
RUN python3 -m venv .venv
ENV PATH="/home/.venv/bin:$PATH"
COPY requirements.txt /home/requirements.txt
RUN pip install -r requirements.txt

# Copy Source code files
COPY fancy-regex /home/fancy-regex
COPY fasttokenizer /home/fasttokenizer
COPY scripts /home/scripts
COPY data /home/data

# Build Fancy Regex
WORKDIR /home/fancy-regex
RUN cargo build --release

# Build Zig library
WORKDIR /home/fasttokenizer
RUN zig build -Doptimize=ReleaseFast

# Validate tokens genarated from all scripts on data/lorem.txt file
WORKDIR /home
ENV RAYON_NUM_THREADS=1
ENV TOKENIZERS_PARALLELISM=false
RUN python scripts/validate.py

# Run benchamrk using hyperfine
ENTRYPOINT ["hyperfine", "--warmup", "2"]
CMD ["python scripts/tt.py coc.txt","python scripts/zig.py coc.txt","python scripts/pure.py coc.txt"]





