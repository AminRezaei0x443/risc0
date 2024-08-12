#!/bin/bash

set -eoux

ulimit -s unlimited

mkdir -p /mnt/bench/
for i in {1..100}
do
  ./stark_verify /mnt/input.json output.wtns > /mnt/bench/cpu-${i}.txt
done