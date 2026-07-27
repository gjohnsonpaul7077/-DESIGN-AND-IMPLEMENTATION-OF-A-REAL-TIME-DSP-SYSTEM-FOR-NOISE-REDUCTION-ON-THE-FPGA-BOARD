`timescale 1ns / 1ps

module basys3_dlms_top (
    input  wire clk,          // 100 MHz clock
    input  wire btnC,         // Reset button
    output wire pmod_audio,   // PWM audio output
    output wire [3:0] led     // Debug LEDs
);

    //=========================================================
    // Reset
    //=========================================================
    wire reset = btnC;

    //=========================================================
    // Sample Clock Generator (50 kHz)
    //=========================================================
    reg [11:0] sample_counter = 0;
    reg sample_tick = 0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sample_counter <= 12'd0;
            sample_tick <= 1'b0;
        end
        else if (sample_counter == 12'd1999) begin
            sample_counter <= 12'd0;
            sample_tick <= 1'b1;
        end
        else begin
            sample_counter <= sample_counter + 1'b1;
            sample_tick <= 1'b0;
        end
    end

    //=========================================================
    // Audio Signal Generator
    //=========================================================
    reg [9:0] signal_counter = 0;

    reg signed [15:0] clean_tone;
    reg signed [15:0] ambient_noise;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            signal_counter <= 10'd0;
            clean_tone <= 16'sd0;
            ambient_noise <= 16'sd0;
        end
        else if (sample_tick) begin

            signal_counter <= signal_counter + 1'b1;

            // Low-frequency square wave
            if(signal_counter[5])
                clean_tone <= 16'sd3000;
            else
                clean_tone <= -16'sd3000;

            // Simple pseudo noise
            case(signal_counter[1:0])
                2'b00: ambient_noise <= 16'sd6000;
                2'b01: ambient_noise <= -16'sd5000;
                2'b10: ambient_noise <= 16'sd2000;
                2'b11: ambient_noise <= -16'sd3000;
            endcase
        end
    end

    //=========================================================
    // Adaptive Noise Canceller Signals
    //=========================================================
    wire signed [15:0] reference_signal;
    wire signed [15:0] primary_signal;
    wire signed [15:0] filter_error_output;

    assign reference_signal = ambient_noise;
    assign primary_signal   = clean_tone + (ambient_noise >>> 1);

    //=========================================================
    // DLMS Filter
    //=========================================================
    dlms_adaptive_filter your_dlms_core (
        .clk(clk),
        .reset(reset),
        .sample_tick(sample_tick),      // <-- IMPORTANT FIX
        .primary_in(primary_signal),
        .reference_in(reference_signal),
        .error_out(filter_error_output)
    );

    //=========================================================
    // PWM Audio DAC (Sigma-Delta)
    //=========================================================
    reg [15:0] pwm_accumulator = 16'd0;

    wire [15:0] unsigned_audio =
        filter_error_output + 16'h8000;

    always @(posedge clk or posedge reset) begin
        if(reset)
            pwm_accumulator <= 16'd0;
        else
            pwm_accumulator <= pwm_accumulator[14:0] + unsigned_audio;
    end

    assign pmod_audio = pwm_accumulator[15];

    //=========================================================
    // Debug LEDs
    //=========================================================
    assign led = filter_error_output[15:12];

endmodule
