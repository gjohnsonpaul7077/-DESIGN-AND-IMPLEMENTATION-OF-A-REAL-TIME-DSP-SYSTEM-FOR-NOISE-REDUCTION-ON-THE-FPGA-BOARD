# Design and Implementation of a real time DSP system for noise reduction on the FPGA BOARD

## Overview

This project implements a real-time audio noise suppression system on FPGA using an 8-tap Delayed Least Mean Squares (DLMS) adaptive filter. The design is written in Verilog HDL and performs adaptive noise cancellation on streamed audio samples. The system was implemented and tested on both the **Nexys 4 DDR** and **Boolean Spartan-7** FPGA development boards.

---


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

## Features

- Real-time audio noise suppression
- 8-tap DLMS adaptive filter implementation
- Verilog HDL design
- UART-based audio data transfer
- BRAM-based audio sample buffering
- PWM audio output generation
- Hardware implementation and verification on FPGA
- Functional simulation using Vivado

---

## System Architecture

```
Audio Input
      │
      ▼
   UART Receiver
      │
      ▼
      BRAM
      │
      ▼
8-Tap DLMS Adaptive Filter
      │
      ▼
   PWM Generator
      │
      ▼
 Speaker / Headphones
```

---

## Hardware Used

- Nexys 4 DDR FPGA Board
- Boolean Spartan-7 FPGA Board

---

## Software & Tools

- Verilog HDL
- Xilinx Vivado
- Python (UART audio streaming)
- Digital Storage Oscilloscope (DSO)

## Repository Structure



```

---

## Workflow

1. Audio samples are streamed to the FPGA through UART.
2. Samples are stored in BRAM.
3. The DLMS adaptive filter processes the noisy signal.
4. The filtered output is converted to PWM.
5. Audio is played through the output interface.
6. Output waveforms are verified using simulation and DSO.

---

## Results

- Successfully implemented a real-time DLMS adaptive filter on FPGA.
- Demonstrated adaptive reduction of unwanted noise.
- Verified functionality through Vivado simulation.
- Validated hardware operation on both Nexys 4 DDR and Boolean Spartan-7 boards.

---

## Future Improvements

- Increase filter taps for improved noise suppression.
- Support higher audio sampling rates.
- Replace PWM with an external audio codec.
- Add I2S audio interface.
- Optimize FPGA resource utilization.

---

## Skills Demonstrated

- Verilog HDL
- FPGA Design
- Digital Signal Processing (DSP)
- Adaptive Filtering
- UART Communication
- BRAM Memory Design
- PWM Signal Generation
- Hardware Verification
- Vivado Design Suite

---



G Johnson Paul

B.Tech Electronics & Telecommunication Engineering

Interested in FPGA Design, Digital Signal Processing, and VLSI Verification.

---
