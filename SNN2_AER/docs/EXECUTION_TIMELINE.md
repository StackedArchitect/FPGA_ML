# Visual Timeline: L-Shape Pattern Processing

## Complete Execution Trace (First 20 Cycles)

```
Time    AER Encoder              Hidden Layer (H0)           Output Layer (O0)
Cycle   [Counters → Spikes]      [V, Current, Spike]        [V, Current, Spike]
────────────────────────────────────────────────────────────────────────────────

  0     RESET                    V=0, I=0, S=0              V=0, I=0, S=0
        All counters = 0         All neurons reset          All neurons reset
        
  1     cnt=[1,1,1,1]           V=0, I=0, S=0              V=0, I=0, S=0
        spk=[0,0,0,0]            No input yet               No hidden spikes
        
  2     cnt=[2,2,2,2]           V=0, I=0, S=0              V=0, I=0, S=0
        spk=[0,0,0,0]            No input yet               No hidden spikes
        
  3     cnt=[3,3,3,3]           V=0, I=0, S=0              V=0, I=0, S=0
        spk=[0,0,0,0]            No input yet               No hidden spikes
        
  4     cnt=[4,4,4,4]           V=0, I=0, S=0              V=0, I=0, S=0
        spk=[0,0,0,0]            No input yet               No hidden spikes

  5     cnt=[0,5,0,0]           V=43, I=44, S=0            V=0, I=0, S=0
        spk=[1,0,1,1] ⚡⚡⚡      Current = 15+0+14+15       Still no hidden
        Pixels 0,2,3 fire!       Potential builds up        activity yet
        
  6     cnt=[1,6,1,1]           V=42, I=0, S=0             V=0, I=0, S=0
        spk=[0,0,0,0]            Decay: 43-1=42             Waiting...
        
  7     cnt=[2,7,2,2]           V=41, I=0, S=0             V=0, I=0, S=0
        spk=[0,0,0,0]            Decay: 42-1=41             Waiting...
        
  8     cnt=[3,8,3,3]           V=40, I=0, S=0             V=0, I=0, S=0
        spk=[0,0,0,0]            Decay: 41-1=40             Waiting...
        
  9     cnt=[4,9,4,4]           V=39, I=0, S=0             V=0, I=0, S=0
        spk=[0,0,0,0]            Decay: 40-1=39             Waiting...

 10     cnt=[0,0,0,0]           V=0, I=58, S=1 ⚡          V=79, I=80, S=1 ⚡
        spk=[1,1,1,1] ⚡⚡⚡⚡     ALL PIXELS FIRE!           HIDDEN SPIKES!
        Even pixel 1!            Current = 15+14+14+15      All 8 hidden→O0
                                 V = 39+58-1 = 96           Current = 8×10=80
                                 96 >= 20 → SPIKE!          79 >= 15 → SPIKE!
                                 Reset V=0                  Reset V=0
        
 11     cnt=[1,1,1,1]           V=0, I=0, S=0              V=0, I=0, S=0
        spk=[0,0,0,0]            Post-spike refractory      Post-spike reset
        
 12     cnt=[2,2,2,2]           V=0, I=0, S=0              V=0, I=0, S=0
        spk=[0,0,0,0]            Building up again          Quiet period
        
 13     cnt=[3,3,3,3]           V=0, I=0, S=0              V=0, I=0, S=0
        spk=[0,0,0,0]            Still quiet                Still quiet
        
 14     cnt=[4,4,4,4]           V=0, I=0, S=0              V=0, I=0, S=0
        spk=[0,0,0,0]            Almost time...             Almost time...

 15     cnt=[0,5,0,0]           V=43, I=44, S=0            V=0, I=0, S=0
        spk=[1,0,1,1] ⚡⚡⚡      THIRD BURST                No hidden spikes
        Pattern repeats!         Current = 44 again         yet this cycle
        
 16     cnt=[1,6,1,1]           V=42, I=0, S=0             V=0, I=0, S=0
        spk=[0,0,0,0]            Decay phase                Waiting...
        
 17     cnt=[2,7,2,2]           V=41, I=0, S=0             V=0, I=0, S=0
        spk=[0,0,0,0]            Decay continues            Waiting...
        
 18     cnt=[3,8,3,3]           V=40, I=0, S=0             V=0, I=0, S=0
        spk=[0,0,0,0]            Decay continues            Waiting...
        
 19     cnt=[4,9,4,4]           V=39, I=0, S=0             V=0, I=0, S=0
        spk=[0,0,0,0]            Decay continues            Waiting...

 20     cnt=[0,0,0,0]           V=0, I=58, S=1 ⚡          V=79, I=80, S=1 ⚡
        spk=[1,1,1,1] ⚡⚡⚡⚡     FOURTH BURST!              Second output spike
        Cycle repeats...         Same as cycle 10           Pattern continues...
```

## Key Observations

### 1. Spike Synchronization
```
Active pixels (0,2,3): Spike every 5 cycles
  Cycle 5, 10, 15, 20, 25, ...

Inactive pixel (1): Spikes every 10 cycles
  Cycle 10, 20, 30, 40, ...
  
Alignment: All pixels sync at cycle 10, 20, 30...
```

### 2. Membrane Potential Dynamics
```
Hidden Neuron Voltage Pattern:
  Cycle 5:  0 → 43  (input burst)
  Cycle 6:  43 → 42 (leak)
  Cycle 7:  42 → 41 (leak)
  Cycle 8:  41 → 40 (leak)
  Cycle 9:  40 → 39 (leak)
  Cycle 10: 39 + 58 = 97 → SPIKE → 0
  
Integrate-and-Fire behavior:
  - Accumulate input
  - Decay during quiet periods
  - Fire when threshold crossed
  - Hard reset to 0
```

### 3. Propagation Delay
```
Input spike (Cycle 5)
   ↓ 1 cycle delay
Hidden accumulation (Cycle 6-9)
   ↓ 4 cycles to threshold
Hidden spike (Cycle 10)
   ↓ same cycle (combinational)
Output spike (Cycle 10)

Total latency: 5 cycles (500ns @ 10MHz)
```

### 4. Spike Rate Encoding
```
Active pixel (1):
  Period = 5 cycles
  Frequency = 10MHz / 5 = 2 MHz
  Rate = 2M spikes/sec
  
Inactive pixel (0):
  Period = 10 cycles  
  Frequency = 10MHz / 10 = 1 MHz
  Rate = 1M spikes/sec
  
Ratio: 2:1 (active:inactive)
Represents pixel intensity in temporal domain
```

## Comparison: All Three Patterns

### L-Shape [1,0,1,1] - Cycle 10
```
Input Spikes:   [1, 1, 1, 1] (all align at cycle 10)
Hidden Current: 15+14+14+15 = 58
Hidden Spikes:  [1, 1, 1, 1, 1, 1, 1, 1] (all 8)
Output Current: O0=80, O1=96, O2=120
Output Spikes:  [1, 1, 1] (ALL spike!)
```

### T-Shape [1,1,0,1] - Cycle 10
```
Input Spikes:   [1, 1, 1, 1] (same at cycle 10!)
Hidden Current: 15+14+14+15 = 58 (IDENTICAL!)
Hidden Spikes:  [1, 1, 1, 1, 1, 1, 1, 1]
Output Current: O0=80, O1=96, O2=120
Output Spikes:  [1, 1, 1] (ALL spike - same as L-shape!)
```

### Cross [0,1,1,1] - Cycle 10
```
Input Spikes:   [1, 1, 1, 1] (same at cycle 10!)
Hidden Current: 14+14+14+15 = 57 (ALMOST identical!)
Hidden Spikes:  [1, 1, 1, 1, 1, 1, 1, 1]
Output Current: O0=80, O1=96, O2=120
Output Spikes:  [1, 1, 1] (ALL spike - same again!)
```

**Problem Revealed:**
At cycle 10 (and 20, 30, ...), ALL patterns look the same!
- Inactive pixels catch up and spike
- Current differences too small (57 vs 58)
- All hidden neurons spike identically
- All outputs fire equally

## Statistical Summary (2000 cycles)

```
Pattern: L-Shape [1,0,1,1]
─────────────────────────────────────
Cycle Range: 0-2000 (200μs @ 10MHz)

Input Layer:
  Pixel 0 (ON):  400 spikes (2 MHz)
  Pixel 1 (OFF): 200 spikes (1 MHz)
  Pixel 2 (ON):  400 spikes (2 MHz)
  Pixel 3 (ON):  400 spikes (2 MHz)

Hidden Layer (all identical):
  H0-H7: ~200 spikes each
  Spike every ~10 cycles
  
Output Layer (all identical):
  O0: 399 spikes
  O1: 399 spikes
  O2: 399 spikes
  
Winner: O0 (tie-breaker, not real classification)
Expected: O0
Accuracy: Correct by luck! ⚠️
```

## Hardware Resource Usage

```
Per Neuron:
  - 8-bit membrane potential register
  - 9-bit adder for current calculation
  - Comparator for threshold check
  - Reset logic
  
Total for 15 neurons:
  - 120 flip-flops (15×8 bits)
  - 15 adders
  - 15 comparators
  
Weight Storage:
  - 56 parameters (4-bit each)
  - 224 bits = 28 bytes
  - Hard-coded in Verilog (no RAM)
  
Clock: 10 MHz (100ns period)
Latency: 5 cycles = 500ns per inference
Throughput: 2M classifications/sec
Power: Event-driven (spikes only)
```
