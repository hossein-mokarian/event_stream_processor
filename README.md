**1. Event Stream Processor (ESP)**

The Event Stream Processor receives asynchronous events from a pixel array via an Address-Event Representation (AER) interface, filters them spatially and temporally, timestamps the survivors, and transmits them as serial packets over a UART to a host PC for visualisation.


**2. System Clocking**

- pix_clk – drives the event generator side (e.g., 100 MHz).

- sys_clk – drives the processing pipeline and UART (e.g., 50 MHz).

**Note:** Crossing between them is done by an asynchronous FIFO.


**3. Input Interface: AER Handshake**

| Signal | Width | Direction (into ESP) | Description |
| :---     | :---:    | :---:     | :---     |
| aer_req | 1 | input | 1 = event ready |
| aer_addr | 16 | input | 8‑bit X (bits 15:8) + 8‑bit Y (bits 7:0) |
| aer_pol | 1 | input | 0 = OFF event, 1 = ON event |
| aer_ack | 1 | output | 1 = accept event |

**4. Spatiotemporal Noise Filter**

- **Purpose:** Remove isolated background noise (hot pixels, shot noise). A real event caused by a moving edge will have spatial and temporal correlation; noise typically does not.

- **Algorithm:** For each incoming event, check if there was any prior event in its 3×3 spatial neighbourhood (Manhattan distance ≤ 1 in X and Y) within the last 50 µs.

  - If yes → pass the event through.

  - If no → drop the event.

- **Implementation note:** You'll need to store recent events. For Day 1, it's enough to specify that a small internal memory (ring buffer) holds the last N events, and the check is performed on all of them. The value of N will be decided based on expected event rate, but we can start with N=16.

**5. Timestamping**

- A free‑running 32‑bit counter increments every 1 µs (derived from sys_clk).

- Each event that passes the filter is latched with the current counter value.

- The counter wraps around gracefully (you'll handle wrap‑around in the scoreboard later).

 **6. Packet Format (Serialised over UART)**

    Byte 0:   Start of packet   = 0xAA
    Byte 1-4: Timestamp[31:0]   (little‑endian)
    Byte 5:   X coordinate[7:0]
    Byte 6:   Y coordinate[7:0]
    Byte 7:   Flags             = {6'b0, polarity}
    Byte 8:   End of packet     = 0x55

Total 9 bytes per event.
UART configuration: 921600 baud, 8 data bits, no parity, 1 stop bit.
(At 921600 baud, one byte takes ~10.8 µs; a full packet takes ~97 µs, which is ~10,000 events/sec – a good match for a filtered event stream.)

**7. Output Interface: UART TX**

- The UART transmitter takes parallel bytes from a FIFO and serialises them.

- It should assert a busy signal while shifting, to stall the upstream packetiser if the FIFO is full.

**8. Pipeline Behaviour & Backpressure**

- If the filter drops an event, no packet is generated.

- If the UART is busy, the packetiser must wait. A small FIFO (e.g., 16 entries deep) between packetiser and UART TX smooths out bursts.

- The system must not lose filtered events due to internal backpressure; hence the FIFO depth must be chosen carefully (we'll calculate it later).

**What is NOT in Scope (for now)**

- No external sensor – the event generator will be a synthesizable Verilog test module that mimics a moving bar or random noise.

- No configuration interface (like I²C). The filter time window and baud rate can be parameters.

- No pixel‑level analog modelling – we'll treat the AER interface as purely digital.
