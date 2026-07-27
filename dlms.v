`timescale 1ns / 1ps

module dlms_adaptive_filter(
    input  wire clk,
    input  wire reset,
    input  wire sample_tick,
    input  wire signed [15:0] primary_in,
    input  wire signed [15:0] reference_in,
    output reg  signed [15:0] error_out
);

    //=========================================================
    // Delay Line
    //=========================================================
    reg signed [15:0] x0, x1, x2, x3;
    reg signed [15:0] x0_delayed, x1_delayed, x2_delayed, x3_delayed;

    //=========================================================
    // Filter Coefficients
    //=========================================================
    reg signed [15:0] w0, w1, w2, w3;

    //=========================================================
    // Shift Register
    //=========================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            x0 <= 16'sd0;
            x1 <= 16'sd0;
            x2 <= 16'sd0;
            x3 <= 16'sd0;

            x0_delayed <= 16'sd0;
            x1_delayed <= 16'sd0;
            x2_delayed <= 16'sd0;
            x3_delayed <= 16'sd0;
        end
        else if(sample_tick) begin

            x3 <= x2;
            x2 <= x1;
            x1 <= x0;
            x0 <= reference_in;

            x3_delayed <= x3;
            x2_delayed <= x2;
            x1_delayed <= x1;
            x0_delayed <= x0;
        end
    end

    //=========================================================
    // FIR Filter
    //=========================================================
    (* use_dsp = "yes" *) wire signed [31:0] prod0 = x0 * w0;
    (* use_dsp = "yes" *) wire signed [31:0] prod1 = x1 * w1;
    (* use_dsp = "yes" *) wire signed [31:0] prod2 = x2 * w2;
    (* use_dsp = "yes" *) wire signed [31:0] prod3 = x3 * w3;

    wire signed [33:0] sum_stage1;
    wire signed [33:0] sum_stage2;
    wire signed [33:0] filter_output_extended;
    wire signed [15:0] filter_output;
    wire signed [15:0] current_error;

    assign sum_stage1 = prod0 + prod1;
    assign sum_stage2 = prod2 + prod3;

    assign filter_output_extended = sum_stage1 + sum_stage2;

    // Q15 Scaling
    assign filter_output = filter_output_extended[30:15];

    //=========================================================
    // Error Calculation
    //=========================================================
    assign current_error = primary_in - filter_output;

    always @(posedge clk or posedge reset) begin
        if(reset)
            error_out <= 16'sd0;
        else if(sample_tick)
            error_out <= current_error;
    end

    //=========================================================
    // DLMS Weight Update
    //=========================================================
    wire signed [31:0] update0;
    wire signed [31:0] update1;
    wire signed [31:0] update2;
    wire signed [31:0] update3;

    assign update0 = (error_out * x0_delayed) >>> 8;
    assign update1 = (error_out * x1_delayed) >>> 8;
    assign update2 = (error_out * x2_delayed) >>> 8;
    assign update3 = (error_out * x3_delayed) >>> 8;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            w0 <= 16'sd0;
            w1 <= 16'sd0;
            w2 <= 16'sd0;
            w3 <= 16'sd0;
        end
        else if(sample_tick) begin
            w0 <= w0 + update0[30:15];
            w1 <= w1 + update1[30:15];
            w2 <= w2 + update2[30:15];
            w3 <= w3 + update3[30:15];
        end
    end

endmodule
