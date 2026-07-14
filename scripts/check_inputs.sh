#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(
    cd "$(dirname "${BASH_SOURCE[0]}")/.."
    pwd
)"

cd "$PROJECT_ROOT"

required_files=(
    "config/sky130hd/config.mk"
    "constraints/mnist_dnn_core_10ns.sdc"
    "pd/mnist_dnn_pd_top.v"

    "third_party/MNIST_DNN_RTL/rtl/sync_signed_rom.v"
    "third_party/MNIST_DNN_RTL/rtl/sync_unsigned_ram.v"
    "third_party/MNIST_DNN_RTL/rtl/dense_engine.v"
    "third_party/MNIST_DNN_RTL/rtl/requantize_relu.v"
    "third_party/MNIST_DNN_RTL/rtl/layer1.v"
    "third_party/MNIST_DNN_RTL/rtl/layer2.v"
    "third_party/MNIST_DNN_RTL/rtl/layer3.v"
    "third_party/MNIST_DNN_RTL/rtl/argmax10.v"
    "third_party/MNIST_DNN_RTL/rtl/mnist_dnn_top.v"

    "third_party/MNIST_DNN_RTL/weights/layer1_weight.mem"
    "third_party/MNIST_DNN_RTL/weights/layer1_bias.mem"
    "third_party/MNIST_DNN_RTL/weights/layer2_weight.mem"
    "third_party/MNIST_DNN_RTL/weights/layer2_bias.mem"
    "third_party/MNIST_DNN_RTL/weights/layer3_weight.mem"
    "third_party/MNIST_DNN_RTL/weights/layer3_bias.mem"
)

failure=0

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "OK: $file"
    else
        echo "MISSING: $file"
        failure=1
    fi
done

echo
echo "===== WEIGHT / BIAS DEPTH ====="

wc -l \
    third_party/MNIST_DNN_RTL/weights/layer1_weight.mem \
    third_party/MNIST_DNN_RTL/weights/layer1_bias.mem \
    third_party/MNIST_DNN_RTL/weights/layer2_weight.mem \
    third_party/MNIST_DNN_RTL/weights/layer2_bias.mem \
    third_party/MNIST_DNN_RTL/weights/layer3_weight.mem \
    third_party/MNIST_DNN_RTL/weights/layer3_bias.mem

echo
echo "===== DOCKER ====="

docker info \
    --format 'Docker Root Dir: {{.DockerRootDir}}'

echo
echo "===== DISK ====="

df -h /media/joo/eda-data

if [[ "$failure" -ne 0 ]]; then
    echo
    echo "Input check failed."
    exit 1
fi

echo
echo "All ASIC physical-design inputs are present."
