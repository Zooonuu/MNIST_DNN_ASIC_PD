`timescale 1ns / 1ps

/*
 * Physical-design integration wrapper.
 *
 * This wrapper does not modify the DNN architecture.
 * It only:
 *   1. Binds the weight/bias .mem files to paths visible in ORFS Docker.
 *   2. Removes verification-only debug ports from the external interface.
 */
module mnist_dnn_pd_top (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               start,

    output wire [9:0]         image_addr,
    input  wire [7:0]         image_data,

    output wire               prediction_valid,
    output wire [3:0]         prediction,
    output wire signed [31:0] max_logit,

    output wire               busy,
    output wire               done
);

    mnist_dnn_top #(
        .L1_WEIGHT_MEM_FILE(
            "/work/third_party/MNIST_DNN_RTL/weights/layer1_weight.mem"
        ),
        .L1_BIAS_MEM_FILE(
            "/work/third_party/MNIST_DNN_RTL/weights/layer1_bias.mem"
        ),
        .L2_WEIGHT_MEM_FILE(
            "/work/third_party/MNIST_DNN_RTL/weights/layer2_weight.mem"
        ),
        .L2_BIAS_MEM_FILE(
            "/work/third_party/MNIST_DNN_RTL/weights/layer2_bias.mem"
        ),
        .L3_WEIGHT_MEM_FILE(
            "/work/third_party/MNIST_DNN_RTL/weights/layer3_weight.mem"
        ),
        .L3_BIAS_MEM_FILE(
            "/work/third_party/MNIST_DNN_RTL/weights/layer3_bias.mem"
        )
    ) u_mnist_dnn (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),

        .image_addr(image_addr),
        .image_data(image_data),

        .prediction_valid(prediction_valid),
        .prediction(prediction),
        .max_logit(max_logit),

        .busy(busy),
        .done(done),

        /*
         * Verification-only debug outputs are intentionally
         * left unconnected in the physical-design wrapper.
         */
        .controller_state_dbg(),

        .layer1_start_dbg(),
        .layer2_start_dbg(),
        .layer3_start_dbg(),

        .layer1_busy_dbg(),
        .layer2_busy_dbg(),
        .layer3_busy_dbg(),
        .argmax_busy_dbg(),

        .layer1_done_dbg(),
        .layer2_done_dbg(),
        .layer3_done_dbg(),

        .layer1_output_valid_dbg(),
        .layer1_output_index_dbg(),
        .layer1_output_acc_dbg(),
        .layer1_output_activation_dbg(),

        .layer2_output_valid_dbg(),
        .layer2_output_index_dbg(),
        .layer2_output_acc_dbg(),
        .layer2_output_activation_dbg(),

        .layer3_output_valid_dbg(),
        .layer3_output_index_dbg(),
        .layer3_output_logit_dbg()
    );

endmodule
