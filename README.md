# Design and Implementation of a Real-Time DSP System for Noise Reduction on FPGA

## Overview

This project presents the design and implementation of a real-time Digital Signal Processing (DSP) system for noise reduction using an 8-tap Delayed Least Mean Squares (DLMS) adaptive filter. The design is implemented in Verilog HDL and deployed on FPGA to perform adaptive filtering on noisy digital signals generated within the FPGA. The functionality is verified through simulation in Xilinx Vivado and validated by observing the processed output waveform on a Digital Storage Oscilloscope (DSO). The design was successfully implemented on both the **Nexys 4 DDR** and **Boolean Spartan-7** FPGA development boards.

---

## Features

- Real-time DSP-based noise reduction
- 8-tap DLMS adaptive filter implementation
- Verilog HDL design
- FPGA-based signal generation
- Hardware implementation and validation
- Functional simulation using Xilinx Vivado
- DSO waveform verification

---

## System Architecture

```text
Desired Signal Generation
           │
           ▼
      Noise Addition
           │
           ▼
       Noisy Signal
           │
           ▼
  8-Tap DLMS Adaptive Filter
           │
           ▼
    Filtered Output Signal
           │
           ▼
      FPGA Output Pins
           │
           ▼
Digital Storage Oscilloscope
 (Waveform Verification)
```

---

## Hardware Used

- Nexys 4 DDR FPGA Board
- Boolean Spartan-7 FPGA Board

---

## Software & Tools

- Verilog HDL
- Xilinx Vivado Design Suite
- Python (Test Signal Generation)
- Digital Storage Oscilloscope (DSO)

---

## Workflow

1. A clean digital signal is generated on the FPGA.
2. Controlled noise is added to create a noisy input signal.
3. The noisy signal is processed using an 8-tap DLMS adaptive filter.
4. Functional correctness is verified through Vivado simulation.
5. The design is synthesized and implemented on the FPGA.
6. Input and filtered output waveforms are observed and verified using a Digital Storage Oscilloscope (DSO).

---

## Results

- Successfully implemented an 8-tap DLMS adaptive filter on FPGA.
- Demonstrated effective real-time digital noise reduction.
- Verified functional correctness through Vivado simulation.
- Successfully deployed the design on Nexys 4 DDR and Boolean Spartan-7 FPGA boards.
- Validated input and filtered output waveforms using a Digital Storage Oscilloscope (DSO).

---

## Future Improvements

- Increase the number of filter taps for improved noise reduction.
- Implement variable step-size adaptive filtering.
- Support higher operating frequencies.
- Optimize FPGA resource utilization and timing performance.
- Extend the design for real-time communication and biomedical signal processing applications.

---

## Skills Demonstrated

- Verilog HDL
- FPGA Design and Implementation
- Digital Signal Processing (DSP)
- DLMS Adaptive Filtering
- Digital Hardware Design
- Functional Simulation
- FPGA Verification
- Xilinx Vivado
- Digital Storage Oscilloscope (DSO) Analysis

---

## Repository Structure

```text
fpga-dsp-noise-reduction/
│
├── rtl/
│   ├── top.v
│   ├── dlms.v
│   ├── signal_generator.v
│   ├── noise_generator.v
│   └── ...
│
├── testbench/
│   └── top_tb.v
│
├── constraints/
│   ├── nexys4ddr.xdc
│   └── boolean_spartan7.xdc
│
├── simulation/
│   └── waveforms/
│
├── images/
│   ├── block_diagram.png
│   ├── simulation_waveform.png
│   ├── dso_input.png
│   ├── dso_output.png
│   └── hardware_setup.jpg
│
└── README.md
```

---

## Author

**G Johnson Paul**

**B.Tech, Electronics & Telecommunication Engineering**

Interested in **FPGA Design, Digital Signal Processing (DSP), and VLSI Verification**.
