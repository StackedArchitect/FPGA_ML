# SNN2_AER Architecture: Complete Technical Deep Dive

## I. ARCHITECTURE OVERVIEW

### System Structure
```
┌─────────────────────────────────────────────────────────────┐
│                  SNN2_AER COMPLETE SYSTEM                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  TRAINING PHASE (Python - Offline)                         │
│  ┌───────────────────────────────────────────┐             │
│  │  2x2 Pattern → STDP Learning → Weights   │             │
│  │  [Python NumPy simulation]                │             │
│  └───────────────────────────────────────────┘             │
│                     ↓                                       │
│              Weight Quantization                            │
│              Float[0,1] → Int[0,15]                        │
│                     ↓                                       │
│  ┌───────────────────────────────────────────┐             │
│  │      weight_parameters.vh (56 weights)    │             │
│  └───────────────────────────────────────────┘             │
│                     ↓                                       │
│  INFERENCE PHASE (Verilog Hardware)                        │
│  ┌───────────────────────────────────────────┐             │
│  │  AER Encoder → 3-Layer SNN → Classification            │
│  │  [FPGA Hardware with fixed weights]       │             │
│  └───────────────────────────────────────────┘             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Network Topology
```
INPUT LAYER (4)    HIDDEN LAYER (8)    OUTPUT LAYER (3)
┌────────┐         ┌────────┐          ┌────────┐
│ Pixel 0│───┐     │  H0    │───┐      │  O0    │ L-shape
└────────┘   │     └────────┘   │      │(label=0)│
             ├────→┌────────┐   │      └────────┘
┌────────┐   │     │  H1    │   ├────→┌────────┐
│ Pixel 1│───┤     └────────┘   │      │  O1    │ T-shape
└────────┘   │     ┌────────┐   │      │(label=1)│
             ├────→│  H2    │   │      └────────┘
┌────────┐   │     └────────┘   │      ┌────────┐
│ Pixel 2│───┤     ┌────────┐   └────→ │  O2    │ Cross
└────────┘   │     │  H3    │          │(label=2)│
             ├────→└────────┘          └────────┘
┌────────┐   │     ┌────────┐
│ Pixel 3│───┘     │  H4    │
└────────┘         └────────┘
                   ┌────────┐
                   │  H5    │
                   └────────┘
                   ┌────────┐
                   │  H6    │
                   └────────┘
                   ┌────────┐
                   │  H7    │
                   └────────┘

Connections:
- Input→Hidden: 4×8 = 32 synapses (fully connected)
- Hidden→Output: 8×3 = 24 synapses (fully connected)
- Total: 56 trainable synapses
```

---

## II. BACKPROPAGATION: NOT USED ❌

### What IS Used: STDP (Spike-Timing-Dependent Plasticity)

**Critical Distinction:**
- **Backpropagation**: Error propagated backward through layers (requires gradients)
- **STDP**: Local Hebbian learning based on spike timing (no backprop)

### STDP Algorithm (Used in Training)

```python
# Core STDP Rule:
if pre_spike BEFORE post_spike:
    Δw = +A_plus × exp(-Δt/τ_plus)    # Potentiation (strengthen)
    
elif post_spike BEFORE pre_spike:
    Δw = -A_minus × exp(-Δt/τ_minus)   # Depression (weaken)

# Biological Principle: "Neurons that fire together, wire together"
```

**Implementation in Code:**
```python
def update_traces(self, dt, pre_spike, post_spike):
    # Decay eligibility traces exponentially
    self.pre_trace *= exp(-dt / tau_plus)
    self.post_trace *= exp(-dt / tau_minus)
    
    if pre_spike:
        self.pre_trace += A_plus
        # If post recently spiked, depress
        if self.post_trace > 0:
            self.w -= self.post_trace
            
    if post_spike:
        self.post_trace += A_minus
        # If pre recently spiked, potentiate
        if self.pre_trace > 0:
            self.w += self.pre_trace
    
    # Hard bounds: w ∈ [0, 1]
    self.w = clip(self.w, 0, 1)
```

**Supervised STDP Modification:**
```python
# Additional teaching signal (not in pure STDP)
if o_idx == correct_label:
    i_input += 0.5    # Boost correct neuron
    synapse.w += 0.01  # Extra weight increase
else:
    i_input -= 0.4    # Suppress wrong neurons
    synapse.w -= 0.01  # Extra weight decrease
```

**Why STDP Instead of Backprop:**
1. ✅ Biologically plausible (occurs in real neurons)
2. ✅ Local learning rule (no global error signal needed)
3. ✅ Suitable for neuromorphic hardware
4. ❌ BUT: Requires more data and careful tuning than backprop

---

## III. STEP-BY-STEP DEMO: L-SHAPE PATTERN PROCESSING

### Pattern Definition
```
L-shape = [1, 0, 1, 1]

Visual 2x2:
  ┌───┬───┐
  │ 1 │ 0 │  Pixel 0 = 1 (ON)
  ├───┼───┤  Pixel 1 = 0 (OFF)
  │ 1 │ 1 │  Pixel 2 = 1 (ON)
  └───┴───┘  Pixel 3 = 1 (ON)
```

### Hardware Parameters
```verilog
CLOCK: 10 MHz (100ns period)
SPIKE_PERIOD: 5 cycles (active pixels)
QUIET_PERIOD: 10 cycles (inactive pixels)
THRESHOLD_HIDDEN: 20
THRESHOLD_OUTPUT: 15
LEAK: 1 per cycle
```

---

## CYCLE-BY-CYCLE EXECUTION

### **Cycle 0: Reset**
```
State:
  All neurons: V = 0
  All counters: 0
  All spikes: 0
```

### **Cycle 1-4: Counter Accumulation**
```
AER Encoder:
  counter_0: 0→1→2→3→4  (pixel_0=1, period=5)
  counter_1: 0→1→2→3→4  (pixel_1=0, period=10)
  counter_2: 0→1→2→3→4  (pixel_2=1, period=5)
  counter_3: 0→1→2→3→4  (pixel_3=1, period=5)
  
Hidden Neurons:
  All V = 0 (no input yet)
  
Output Neurons:
  All V = 0
```

### **Cycle 5: FIRST SPIKE BURST** ⚡
```
AER Encoder Decision:
  counter_0 == 4 (reached period-1)? YES → SPIKE!
  counter_1 == 9? NO → no spike
  counter_2 == 4? YES → SPIKE!
  counter_3 == 4? YES → SPIKE!

Spikes Generated:
  spike_in_0 = 1  ←
  spike_in_1 = 0
  spike_in_2 = 1  ←
  spike_in_3 = 1  ←
  
  Three active pixels spike simultaneously!
```

**Hidden Neuron H0 Calculation:**
```verilog
// Current calculation (combinational logic):
current_h0 = (spike_in_0 ? WEIGHT_I0_H0 : 0) +
             (spike_in_1 ? WEIGHT_I1_H0 : 0) +
             (spike_in_2 ? WEIGHT_I2_H0 : 0) +
             (spike_in_3 ? WEIGHT_I3_H0 : 0)

// Substituting values:
current_h0 = (1 ? 15 : 0) +   // Pixel 0 ON
             (0 ? 14 : 0) +   // Pixel 1 OFF
             (1 ? 14 : 0) +   // Pixel 2 ON
             (1 ? 15 : 0)     // Pixel 3 ON

current_h0 = 15 + 0 + 14 + 15 = 44
```

**LIF Neuron H0 Update (at posedge clk):**
```verilog
// Inside lif_neuron_stdp module:
potential_next = membrane_potential + input_current + bias_signal - LEAK
potential_next = 0 + 44 + 0 - 1
potential_next = 43

// Check threshold (uses OLD membrane_potential):
if (membrane_potential >= THRESHOLD)  // 0 >= 20? NO
    spike_out <= 0
    membrane_potential <= 43  // Store for next cycle
```

**All Hidden Neurons (same calculation):**
```
H0: V=0→43, current=44, spike=0
H1: V=0→43, current=44, spike=0
H2: V=0→43, current=44, spike=0
H3: V=0→43, current=44, spike=0
H4: V=0→43, current=44, spike=0
H5: V=0→43, current=44, spike=0
H6: V=0→43, current=44, spike=0
H7: V=0→43, current=44, spike=0

(All identical because weights are uniform!)
```

**Output Neurons:**
```
No hidden spikes yet → current=0
O0: V=0, spike=0
O1: V=0, spike=0
O2: V=0, spike=0
```

### **Cycle 6: Decay Phase**
```
AER Encoder:
  spike_in_0 = 0  (counter reset to 0, incrementing)
  spike_in_1 = 0
  spike_in_2 = 0
  spike_in_3 = 0
  
Hidden Neurons:
  current = 0 (no input spikes)
  
H0 Update:
  potential_next = 43 + 0 + 0 - 1 = 42
  membrane_potential = 42
  spike_out = 0
  
All Hidden: V=43→42 (decay by leak)
All Output: V=0 (no activity yet)
```

### **Cycle 7: More Decay**
```
Hidden Neurons:
  V = 42 - 1 = 41
  Still no spikes (41 < 20 threshold)
```

### **Cycle 8: Continued Decay**
```
Hidden Neurons:
  V = 41 - 1 = 40
```

### **Cycle 9: Still Decaying**
```
Hidden Neurons:
  V = 40 - 1 = 39
```

### **Cycle 10: SECOND SPIKE BURST** ⚡⚡
```
AER Encoder:
  counter_0 = 5 → SPIKE! (period=5)
  counter_1 = 10 → SPIKE! (period=10, first time)
  counter_2 = 5 → SPIKE!
  counter_3 = 5 → SPIKE!
  
Spikes:
  spike_in_0 = 1
  spike_in_1 = 1  ← Inactive pixel spikes at half rate
  spike_in_2 = 1
  spike_in_3 = 1
  
ALL FOUR pixels spike!

Hidden Neuron H0:
  current_h0 = 15 + 14 + 14 + 15 = 58
  potential_next = 39 + 58 + 0 - 1 = 96
  
  Check threshold: 39 >= 20? YES! → SPIKE!
  spike_h0 = 1
  membrane_potential = 0 (RESET)
```

**All hidden neurons spike:**
```
H0: SPIKE! ⚡ V→0
H1: SPIKE! ⚡ V→0
H2: SPIKE! ⚡ V→0
H3: SPIKE! ⚡ V→0
H4: SPIKE! ⚡ V→0
H5: SPIKE! ⚡ V→0
H6: SPIKE! ⚡ V→0
H7: SPIKE! ⚡ V→0
```

**Output Layer (combinational current calculation):**
```verilog
// Output O0 (L-shape detector):
current_o0 = (spike_h0 ? WEIGHT_H0_O0 : 0) +
             (spike_h1 ? WEIGHT_H1_O0 : 0) +
             ... +
             (spike_h7 ? WEIGHT_H7_O0 : 0)

current_o0 = 10 + 10 + 10 + 10 + 10 + 10 + 10 + 10
current_o0 = 80

// Output O1 (T-shape detector):
current_o1 = 12 + 12 + 12 + 12 + 12 + 12 + 12 + 12 = 96

// Output O2 (Cross detector):
current_o2 = 15 + 15 + 15 + 15 + 15 + 15 + 15 + 15 = 120
```

**Output Neuron Updates:**
```
O0: potential_next = 0 + 80 + 0 - 1 = 79
    79 >= 15? YES → SPIKE! ⚡ V→0
    
O1: potential_next = 0 + 96 + 0 - 1 = 95
    95 >= 15? YES → SPIKE! ⚡ V→0
    
O2: potential_next = 0 + 120 + 0 - 1 = 119
    119 >= 15? YES → SPIKE! ⚡ V→0
```

### **Problem Revealed:**
```
ALL THREE output neurons spike!
Spike counts after 2000 cycles:
  O0: 399 spikes
  O1: 399 spikes  ← Same!
  O2: 399 spikes  ← Same!

Winner: O0 (default, first checked)
Expected: O0 (L-shape)
Result: CORRECT by luck (tie-breaker)
```

### **Cycle 11-15: Pattern Repeats**
```
Cycle 11-14: Decay phase
Cycle 15: Third spike burst
  - Hidden neurons accumulate V=0→43
  - Process repeats every 5 cycles
  
After 100 cycles:
  Total spikes from each output: ~20 each
```

---

## IV. WEIGHT FLOW DIAGRAM

### Training Phase (Python)
```
┌─────────────────────────────────────────────────────┐
│  STDP TRAINING (Python, Offline)                    │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Input: L-shape [1,0,1,1], label=0                │
│     ↓                                               │
│  1. Encode as Poisson spike train (250ms)         │
│     Pixel ON → 40Hz spikes                         │
│     Pixel OFF → 0Hz spikes                         │
│     ↓                                               │
│  2. Simulate LIF dynamics (float precision)        │
│     V[t+1] = V[t] + I_syn - leak                  │
│     ↓                                               │
│  3. Detect spikes, record times                    │
│     pre_spike_time, post_spike_time               │
│     ↓                                               │
│  4. STDP weight update                             │
│     If Δt>0: w += A_plus × exp(-Δt/τ)            │
│     If Δt<0: w -= A_minus × exp(Δt/τ)            │
│     ↓                                               │
│  5. Supervised modulation                          │
│     w[hidden→output0] += 0.01  (correct)          │
│     w[hidden→output1,2] -= 0.01 (wrong)           │
│     ↓                                               │
│  6. Repeat for 150 epochs                          │
│     → Weights converge to [0,1] range             │
│     ↓                                               │
│  7. Quantize to 4-bit integers                     │
│     w_hardware = round(w_float × 15)              │
│     ↓                                               │
│  8. Save to weight_parameters.vh                   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Inference Phase (Verilog Hardware)
```
┌─────────────────────────────────────────────────────┐
│  HARDWARE INFERENCE (Verilog, Real-time)            │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Input: L-shape [1,0,1,1] (static pattern)        │
│     ↓                                               │
│  AER Encoder (aer_pixel_encoder.v)                 │
│  ├─ Counter-based spike generation                 │
│  ├─ Active pixels: spike every 5 cycles            │
│  └─ Output: spike_in[3:0] (1-bit pulses)          │
│     ↓                                               │
│  Hidden Layer (8× lif_neuron_stdp.v)               │
│  ├─ current = Σ(spike_in[i] × weight[i])          │
│  ├─ V[t+1] = V[t] + current - leak                │
│  ├─ if V >= threshold: spike=1, V=0               │
│  └─ Output: spike_h[7:0]                          │
│     ↓                                               │
│  Output Layer (3× lif_neuron_stdp.v)               │
│  ├─ current = Σ(spike_h[j] × weight[j])           │
│  ├─ V[t+1] = V[t] + current + bias - leak         │
│  ├─ if V >= threshold: spike=1, V=0               │
│  └─ Output: spike_out[2:0]                        │
│     ↓                                               │
│  Winner-Take-All (counter logic)                   │
│  ├─ Count spikes over 2000 cycles                  │
│  ├─ winner = argmax(spike_count[i])               │
│  └─ Output: 2-bit classification result            │
│                                                     │
│  NO LEARNING - Weights are constants!              │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## V. KEY INSIGHTS

### 1. Two-Phase System
```
TRAINING (Python):  Learn weights with STDP
   ↓
DEPLOYMENT (Hardware):  Use fixed weights for inference
```

### 2. No On-Chip Learning
- Hardware does NOT implement STDP
- Weights are hard-coded parameters
- To retrain: Must go back to Python

### 3. Current Problems
```
Issue: Weight homogeneity
  Input→Hidden: All weights ≈14-15 (only 2 unique values)
  Hidden→Output: Uniform per output (10, 12, or 15)
  
Effect: All neurons respond identically
  → All outputs spike equally
  → Classification fails (33% accuracy)
  
Root Cause: Dataset too small for STDP
  Only 3 patterns insufficient for weight differentiation
```

### 4. Temporal Encoding
```
Spatial → Temporal conversion:
  2D pattern [1,0,1,1] → spike train over time
  
Advantage: Neuromorphic efficiency
  - Only active when spikes occur
  - Event-driven processing
  - Low power consumption
```

### 5. Synchronous vs Asynchronous
```
Current: Fully synchronous (10MHz clock)
  Pro: Easy to implement in FPGA
  Con: Not truly neuromorphic (always running)
  
True neuromorphic: Asynchronous event-driven
  (Like Intel Loihi, IBM TrueNorth)
```

---

## VI. DATA FLOW SUMMARY

```
Pattern In → AER Encoding → Spike Trains → Neural Dynamics → Spike Counting → Classification

[1,0,1,1]  →  Rate Coding  →  [⚡,0,⚡,⚡]  →  V += I - leak  →  399/399/399  →  O0 (tie)
              5/10 cycles      every 5 cyc     spike@thresh    (all equal!)     (wrong!)
```

This architecture successfully demonstrates:
✅ Multi-layer SNN implementation
✅ STDP training algorithm
✅ AER temporal encoding
✅ Hardware deployment pipeline

But reveals research challenge:
❌ STDP weight discrimination fails on small datasets
❌ Requires supervised signal (not pure unsupervised)
❌ Hardware inference dependent on training methodology
