# Chroma Keying implemented on DE10 Standard (Camera → SDRAM → Chroma Keying → VGA)

This project implements a real-time video processing pipeline on FPGA.  
The system captures image data from an OV7670 camera, stores frames into SDRAM, performs Chroma Keying by using RGB Color format comparing, and outputs the processed video to a VGA/HDMI display.

## 📌 Features
- Real-time capture from **OV7670** camera (RGB565 → RGB888).
- SDRAM controller operating at **133 MHz** (256 burst length customization).
- Dual-pipeline processing:
  - Camera → SDRAM → VGA
  - Camera → Chroma Keying → RAM 2 port Final (Storing the result of chroma keying process) → VGA
- Designed for **DE10 Cyclone V** platforms.

## 🏗 System Architecture
Camera → FIFO → RGB Converter → Grayscale → 3-Line Buffer → Sobel
↓ ↑
SDRAM Write ←→ SDRAM Controller ←→ SDRAM Read
↓
VGA

## 🚀 Getting Started

### Requirements
- Quartus 20.1 Lite Edition
- ModelSim 20.1 Starter Edition (optional for testbenches)  
- FPGA board: DE10 Standard (Cyclone V 5CSXFC6D6F31C6)

### Build & Run
1. Open the project in Quartus (Recommend using the right version)
2. Assign the pin constraints for your board  
3. Compile design  
4. Load bitstream to FPGA  (Quartus/Program)
5. Connect OV7670 and VGA/HDMI to FPGA
6. View live processed video  

Notes: Remember that you should create your own PLL for the specific frequency and system files. For timing checking, you can use the references from the .sdc files, but I suggest you should generate one your own.

## 🧪 Testbench
Includes tests for:
- The main program (Beginning with the sample data from camera, endding with the output color for the VGA output (using RGB888 format))
- Customize SDRAM simulation testbench for the main testbench

## 📝 Notes
- SDRAM runs at **133 MHz (CL2)** depending on configuration.  
- Supports switching between raw camera feed and Sobel mode.  
- DDR3 version for Zynq-7020 uses **AXI HP port** for high-speed frame transfer.

## 📜 License
None

## ✨ Author
**Huy Nguyen Gia** – Graduated Electronics Engineering Student  
Specialized in FPGA, digital design, and real-time video systems.