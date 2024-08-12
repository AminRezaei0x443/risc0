#!/bin/bash

set -eoux

docker build -f docker/bench_circom.Dockerfile -m 8g . -t risc0-circom-bench
