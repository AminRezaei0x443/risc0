# syntax=docker/dockerfile:1.7
FROM rust:1.74.0 AS deps

WORKDIR /src/

# APT deps
RUN apt -qq update && \
  apt install -y -q apt-transport-https build-essential clang cmake curl gnupg libgmp-dev libsodium-dev m4 nasm nlohmann-json3-dev npm

WORKDIR /src/

# Build and install circom
RUN git clone https://github.com/iden3/circom.git && \
  cd circom && \
  git checkout e60c4ab8a0b55672f0f42fbc68a74203bdb6a700 && \
  cargo install --path circom

COPY groth16/risc0.circom ./groth16/risc0.circom
COPY groth16/stark_verify.circom ./groth16/stark_verify.circom

# Build the witness generation
RUN (cd groth16; circom --c stark_verify.circom) 
RUN sed -i 's/g++/clang++/' groth16/stark_verify_cpp/Makefile 
RUN sed -i 's/O3/O0/' groth16/stark_verify_cpp/Makefile
RUN (cd groth16/stark_verify_cpp; make)

# Create a final clean image with all the dependencies to perform stark->snark
FROM ubuntu:jammy-20231211.1@sha256:bbf3d1baa208b7649d1d0264ef7d522e1dc0deeeaaf6085bf8e4618867f03494 AS prover

RUN apt update -qq && \
  apt install -y libsodium23 nodejs npm && \
  npm install -g snarkjs@0.7.3

COPY scripts/bench.sh /app/bench.sh
COPY --from=deps /src/groth16/stark_verify_cpp/stark_verify /app/stark_verify
COPY --from=deps /src/groth16/stark_verify_cpp/stark_verify.dat /app/stark_verify.dat
COPY --from=deps /src/groth16/stark_verify_final.zkey /app/stark_verify_final.zkey

WORKDIR /app
RUN chmod +x bench.sh
RUN ulimit -s unlimited

ENTRYPOINT ["/app/bench.sh"]
