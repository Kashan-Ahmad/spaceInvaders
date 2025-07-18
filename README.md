# 🚀 FPGA Space Invaders (Verilog on DE1-SoC)

A pixel-perfect recreation of *Space Invaders*, developed in Verilog and deployed on the **DE1-SoC FPGA board**. Built in collaboration with a teammate, this project showcases real-time game rendering using VGA, PS/2 keyboard input, finite state machines (FSMs), hardware timers, and on-board HEX displays.

---

## 🎮 Features

- **Pixel-by-Pixel VGA Rendering**  
  All visuals—including the player ship, enemies, bullets, and title screen—are manually drawn pixel-by-pixel using precise control of VGA signals at a **60 Hz refresh rate** (640×480 resolution). Sync pulses and raster scan timings were manually handled to render clean, flicker-free frames.

- **Real-Time PS/2 Keyboard Input**  
  Movement and shooting are controlled via a standard PS/2 keyboard:
  - `A` – Move Left  
  - `D` – Move Right  
  - `P` – Shoot

  Scancode decoding and edge detection were implemented to register keypresses without debouncing delays.

- **Finite State Machines (FSMs)**  
  Modular FSMs control the game flow:
  - **Intro State**: Title screen display  
  - **Gameplay State**: Real-time player/enemy interaction  
  - **Victory State/Loss State**: Triggered after defeating 15 enemies or game timer running out
  FSMs were used to cleanly separate control logic from datapath modules.

- **Collision Detection and Game Logic**  
  Real-time bullet-enemy collisions are detected using coordinate overlap comparisons. Enemies descend periodically on a timed cycle using internal counters.

- **Hardware Timer and HEX Displays**  
  - A **40-second countdown timer** is displayed on the DE1-SoC's HEX displays using **BCD-encoded multiplexed output**.
  - The number of enemies defeated is also tracked and shown live on HEX displays.
  - Timer countdown uses a **50 MHz base clock** and internal dividers.

- **Win Condition and Game Constraints**  
  Players must shoot **15 enemies** within the 40-second time limit to win. Enemies respawn in falling motion, adding challenge and pacing.

---

## 🛠️ Technologies & Concepts Used

- **Verilog HDL** – modular, synthesizable design for hardware logic
- **VGA Protocol** – 640×480 resolution @ 60 Hz with 25.175 MHz pixel clock timing
- **FSM Design** – clean separation of control logic from datapath
- **PS/2 Interface** – decoding scancodes using serial bit-level protocols
- **Debouncing and Edge Detection** – for stable keyboard interaction
- **Memory-Mapped I/O** – for display, input, and game state communication
- **Hexadecimal Display Control** – using shift registers and BCD encoding
- **Timing Logic** – hardware divider-based timer using a 50 MHz system clock

---

## 👨‍💻 What I Learned

This project solidified my understanding of:

- **Low-level graphics rendering** and VGA timing control
- **Synchronizing asynchronous inputs** (PS/2) with clocked FSMs
- **Digital system design** and modular decomposition of control logic
- **FPGA resource constraints**, hardware debugging, and testbench simulation
- **Real-time embedded system design**, including deterministic timing and parallel hardware execution

---

## 🚀 Future Improvements

- Integrate **block RAM (BRAM)** to store and render sprite images
- Add **sound effects** using the audio-out interface
- Increase difficulty using enemy patterns and levels
- Implement **pause/restart functionality**
- Add **score tracking** across multiple sessions using SRAM

---
