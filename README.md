# FPGA-Lock-Project
# FPGA Digital Password Lock with RGB LED & Buzzer

A 3-bit digital password lock implemented on the **VSDSquadron FPGA Mini (iCE40 UP5K)** using **Verilog**.  
The system accepts a binary password through push buttons and provides feedback using an RGB LED and an active buzzer.

---

## Project Overview

This project demonstrates a complete FPGA-based digital locking system built around a **Finite State Machine (FSM)**.  
Users enter a 3-bit password using buttons, with clear visual (LED) and audio (buzzer) indications for correct or incorrect entry.

---

## Features

- 3-bit binary password entry  
- FSM-based control logic  
- Button-based input (Toggle, Enter, Next, Reset)  
- RGB LED status indication  
- Active buzzer feedback  
- Designed for real hardware deployment  

---

## Hardware Requirements

- VSDSquadron FPGA Mini (iCE40 UP5K)  
- 4 Push Buttons  
- RGB LED (onboard)  
- Active Buzzer (5V)  
- Resistors, breadboard, jumper wires  

---

## Button Functions

| Button | Function |
|------|----------|
| BTN0 | Toggle current bit (0 ↔ 1) |
| BTN1 | Enter / Finish password entry |
| BTN2 | Move to next bit |
| BTN3 | Reset system to LOCKED state |

---

## Password Entry Rule

Password bits are entered **in order: Bit0 → Bit1 → Bit2**

1. Press **ENTER**
2. If bit = `1`, press **TOGGLE**
3. Press **NEXT** to move forward (except after last bit)
4. After Bit2, press **ENTER** to submit

---

## Example Button Sequences

| Password | Button Sequence |
|--------|----------------|
| 101 | ENTER → TOGGLE → NEXT → NEXT → TOGGLE → ENTER |
| 010 | ENTER → NEXT → TOGGLE → NEXT → ENTER |
| 111 | ENTER → TOGGLE → NEXT → TOGGLE → NEXT → TOGGLE → ENTER |
| 000 | ENTER → NEXT → NEXT → ENTER |

---

## LED Status Indication

- **Red** → Locked  
- **Blue** → Entering / Error  
- **Green** → Unlocked  

---

## Buzzer Feedback

- Short beep → Correct password  
- Long beep → Incorrect password  

---

## FSM States
## FSM States

The control logic of the digital password lock is implemented using a **Finite State Machine (FSM)**.  
Each state represents a distinct phase of operation, ensuring deterministic behavior and clear transitions.

### State Descriptions

- **LOCKED**  
  Default idle state. The system remains locked with the red LED ON.  
  Pressing **ENTER (BTN1)** moves the system to password entry.

- **ENTER0**  
  Entry state for **Bit 0** of the password.  
  - **TOGGLE (BTN0)** flips the current bit value  
  - **NEXT (BTN2)** advances to `ENTER1`

- **ENTER1**  
  Entry state for **Bit 1** of the password.  
  - **TOGGLE (BTN0)** flips the current bit value  
  - **NEXT (BTN2)** advances to `ENTER2`

- **ENTER2**  
  Entry state for **Bit 2** of the password.  
  - **TOGGLE (BTN0)** flips the current bit value  
  - **ENTER (BTN1)** moves to `LATCH`

- **LATCH**  
  Captures the entered 3-bit password into a register for comparison.

- **CHECK**  
  Compares the entered password with the stored password.

- **UNLOCKED**  
  Entered when the password matches.  
  Green LED turns ON and a short buzzer beep is generated.  
  Pressing **ENTER** returns the system to `LOCKED`.

- **ERROR**  
  Entered when the password does not match.  
  Blue LED turns ON and a long buzzer beep is generated.  
  Pressing **ENTER** returns the system to `LOCKED`.

- **RESET (Global)**  
  Pressing **BTN3** from any state forces the system back to `LOCKED`.

---

### FSM Transition Summary

| Current State | Input | Next State |
|-------------|-------|-----------|
| LOCKED | ENTER | ENTER0 |
| ENTER0 | NEXT | ENTER1 |
| ENTER1 | NEXT | ENTER2 |
| ENTER2 | ENTER | LATCH |
| LATCH | — | CHECK |
| CHECK | Match | UNLOCKED |
| CHECK | No Match | ERROR |
| UNLOCKED | ENTER | LOCKED |
| ERROR | ENTER | LOCKED |
| Any | RESET | LOCKED |





---

## Pin Mapping

| Component | FPGA Pin |
|--------|----------|
| Clock | 20 |
| BTN0 (Toggle) | 11 |
| BTN1 (Enter) | 12 |
| BTN2 (Next) | 13 |
| BTN3 (Reset) | 14 |
| Red LED | 39 |
| Green LED | 40 |
| Blue LED | 41 |
| Buzzer | 19 |

---

## Build & Program Commands

```bash
yosys -p "synth_ice40 -top lock_fsm -json lock_fsm.json" lock_fsm.v
nextpnr-ice40 --up5k --package sg48 --json lock_fsm.json --pcf vsdfm.pcf --asc lock_fsm.asc
icepack lock_fsm.asc lock_fsm.bin
iceprog lock_fsm.bin
