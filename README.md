# Real-Time Audio Noise Suppression on FPGA Using a DLMS Adaptive Filter

## Overview

This project implements a real-time audio noise suppression system on FPGA using an 8-tap Delayed Least Mean Squares (DLMS) adaptive filter. The design is written in Verilog HDL and performs adaptive noise cancellation on streamed audio samples. The system was implemented and tested on both the **Nexys 4 DDR** and **Boolean Spartan-7** FPGA development boards.

---

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

---

## Repository Structure

```
fpga-dlms-noise-reduction/
│
├── rtl/
│   ├── top.v
│   ├── dlms.v
│   ├── uart_rx.v
│   ├── bram.v
│   ├── pwm_audio.v
│   └── ...
│
├── testbench/
│   └── top_tb.v
│
├── constraints/
│   └── *.xdc
│
├── audio/
│   ├── input_audio.wav
│   ├── noisy_audio.wav
│   └── output_audio.wav
│
├── images/
│   ├── block_diagram.png
│   ├── simulation.png
│   ├── hardware_setup.jpg
│   └── dso_waveform.jpg
│
└── README.md
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
