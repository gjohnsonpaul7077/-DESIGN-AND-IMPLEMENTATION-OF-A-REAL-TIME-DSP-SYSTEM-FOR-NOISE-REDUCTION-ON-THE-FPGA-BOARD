`timescale 1ns / 1ps

module tb_dlms_adaptive_filter;

    //=========================================================
    // Testbench Signals
    //=========================================================
    reg clk;
    reg reset;
    reg sample_tick;

    reg signed [15:0] primary_in;
    reg signed [15:0] reference_in;

    wire signed [15:0] error_out;

    //=========================================================
    // Instantiate DUT
    //=========================================================
    dlms_adaptive_filter dut (
        .clk(clk),
        .reset(reset),
        .sample_tick(sample_tick),
        .primary_in(primary_in),
        .reference_in(reference_in),
        .error_out(error_out)
    );

    //=========================================================
    // 100 MHz Clock
    //=========================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    //=========================================================
    // 50 kHz Sample Tick Generator
    //=========================================================
    reg [11:0] tick_counter;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            tick_counter <= 12'd0;
            sample_tick <= 1'b0;
        end
        else if(tick_counter == 12'd1999) begin
            tick_counter <= 12'd0;
            sample_tick <= 1'b1;
        end
        else begin
            tick_counter <= tick_counter + 1'b1;
            sample_tick <= 1'b0;
        end
    end

    //=========================================================
    // Stimulus
    //=========================================================
    integer i;
    reg signed [15:0] clean_signal;
    reg signed [15:0] noise;

    initial begin

        reset = 1'b1;
        primary_in = 16'sd0;
        reference_in = 16'sd0;

        #100;
        reset = 1'b0;

        // Apply 500 audio samples
        for(i = 0; i < 500; i = i + 1) begin

            // Clean square wave
            if(i % 20 < 10)
                clean_signal = 16'sd4000;
            else
                clean_signal = -16'sd4000;

            // Noise signal
            case(i % 3)
                0: noise = 16'sd8000;
                1: noise = -16'sd6000;
                2: noise = 16'sd2000;
            endcase

            // Inputs must be stable BEFORE sample_tick
            reference_in = noise;
            primary_in   = clean_signal + (noise >>> 1);

            @(posedge sample_tick);

            // Display results
            $display("Sample=%0d  Ref=%0d  Primary=%0d  Error=%0d",
                     i, reference_in, primary_in, error_out);
        end

        repeat(10)
            @(posedge sample_tick);

        $finish;
    end

endmodule
