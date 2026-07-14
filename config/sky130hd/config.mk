# ============================================================
# MNIST DNN ASIC Physical Design - Baseline Configuration
# ============================================================

export DESIGN_NICKNAME = mnist_dnn_pd
export DESIGN_NAME     = mnist_dnn_pd_top
export PLATFORM        = sky130hd

# All project files are mounted at /work inside ORFS Docker.
export VERILOG_FILES = \
	/work/third_party/MNIST_DNN_RTL/rtl/sync_signed_rom.v \
	/work/third_party/MNIST_DNN_RTL/rtl/sync_unsigned_ram.v \
	/work/third_party/MNIST_DNN_RTL/rtl/dense_engine.v \
	/work/third_party/MNIST_DNN_RTL/rtl/requantize_relu.v \
	/work/third_party/MNIST_DNN_RTL/rtl/layer1.v \
	/work/third_party/MNIST_DNN_RTL/rtl/layer2.v \
	/work/third_party/MNIST_DNN_RTL/rtl/layer3.v \
	/work/third_party/MNIST_DNN_RTL/rtl/argmax10.v \
	/work/third_party/MNIST_DNN_RTL/rtl/mnist_dnn_top.v \
	/work/pd/mnist_dnn_pd_top.v

export SDC_FILE = \
	/work/constraints/mnist_dnn_core_10ns.sdc

# Baseline physical-design settings.
# ?= allows later command-line parameter overrides.
export CORE_UTILIZATION ?= 40
export CORE_ASPECT_RATIO ?= 1
export CORE_MARGIN       ?= 10
export PLACE_DENSITY     ?= 0.55

# The current ORFS Docker image triggers an illegal-instruction
# failure during LEC on this host CPU.
export LEC_CHECK = 0

# Do not stop the exploratory baseline solely because of TNS.
export TNS_END_PERCENT = 100

# ============================================================
# Full inferred-memory synthesis experiment
# ============================================================
#
# Largest memory:
# Layer 1 Weight ROM = 50,176 × 8 = 401,408 bits
#
# ORFS default is 4,096 bits, which stops synthesis before
# mapping the large ROM to standard-cell logic.
#
# This baseline intentionally keeps the original RTL and
# permits full inferred-memory synthesis for feasibility study.
export SYNTH_MEMORY_MAX_BITS = 4096

# Do not replace large memories with one-row mock memories.
# The goal of this run is to synthesize the original memory contents.
export SYNTH_MOCK_LARGE_MEMORIES = 1