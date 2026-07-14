# ============================================================
# MNIST DNN ASIC baseline constraints
# ============================================================

current_design mnist_dnn_pd_top

set clk_name       core_clock
set clk_port_name  clk
set clk_period     10.0
set clk_io_pct     0.20

set clk_port [get_ports $clk_port_name]

create_clock \
    -name $clk_name \
    -period $clk_period \
    $clk_port

set_clock_uncertainty \
    0.10 \
    [get_clocks $clk_name]

# All inputs except the clock.
set non_clock_inputs \
    [lsearch -inline -all -not -exact \
        [all_inputs] \
        $clk_port]

set_input_delay \
    [expr $clk_period * $clk_io_pct] \
    -clock $clk_name \
    $non_clock_inputs

set_output_delay \
    [expr $clk_period * $clk_io_pct] \
    -clock $clk_name \
    [all_outputs]

# rst_n is an asynchronous reset input.
# Functional recovery/removal treatment is outside this first baseline.
set_false_path \
    -from [get_ports rst_n]
