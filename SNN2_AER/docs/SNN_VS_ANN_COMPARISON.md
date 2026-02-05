# SNN vs Traditional ANN: Architecture Comparison

## Quick Answer Summary

### Is Backpropagation Used?
**NO** ❌ - This system uses STDP (Spike-Timing-Dependent Plasticity), a biologically-inspired local learning rule.

### Two-Phase Operation
```
PHASE 1: TRAINING (Python/NumPy)
  - STDP algorithm runs offline
  - Weights learned from spike timing
  - Supervised signal added for guidance
  - Result: 56 trained weights
  
PHASE 2: INFERENCE (Verilog/Hardware)
  - Fixed weights (no learning)
  - Real-time spike processing
  - Event-driven classification
  - Pure feed-forward
```

---

## Detailed Comparison Table

| Aspect | Traditional ANN (CNN/MLP) | This SNN (SNN2_AER) |
|--------|---------------------------|---------------------|
| **Learning Algorithm** | Backpropagation + SGD | STDP (spike-timing) |
| **Gradient Calculation** | Yes (chain rule) | No (local Hebbian) |
| **Error Signal** | Global (from output layer) | Local (spike timing) |
| **Weight Update** | w -= η∇L | w += f(Δt_spike) |
| **Biological Plausibility** | No | Yes |
| **Training Location** | GPU/CPU (Python) | CPU (Python) |
| **Inference Location** | GPU/CPU | FPGA (Verilog) |
| **On-Chip Learning** | Possible | Not implemented |
| **Activation Function** | ReLU, Sigmoid, Tanh | LIF dynamics (spikes) |
| **Signal Type** | Continuous (floats) | Binary (spike/no-spike) |
| **Time Representation** | Implicit (layer-by-layer) | Explicit (cycles) |
| **Power Consumption** | High (always computing) | Low (event-driven) |
| **Precision** | 32-bit float | 4-bit weights, 8-bit states |

---

## Learning Algorithm Deep Dive

### Backpropagation (NOT USED)
```python
# How traditional neural networks learn:

# Forward pass
h = ReLU(W1 @ x + b1)
y = softmax(W2 @ h + b2)

# Loss
L = cross_entropy(y, y_true)

# Backward pass (gradient via chain rule)
dL/dW2 = dL/dy × dy/dW2
dL/dW1 = dL/dy × dy/dh × dh/dW1

# Update
W2 -= learning_rate × dL/dW2
W1 -= learning_rate × dL/dW1

# Issues:
# ❌ Not biologically plausible (brain doesn't do backprop)
# ❌ Requires global error signal
# ❌ Needs gradient storage (memory intensive)
```

### STDP (ACTUALLY USED)
```python
# How this SNN learns:

# Forward pass (simulation in time)
for t in range(duration):
    # Pre-synaptic neuron spikes at time t_pre
    if pre_neuron.spike:
        pre_trace += A_plus
    
    # Post-synaptic neuron spikes at time t_post
    if post_neuron.spike:
        post_trace += A_minus
        
    # Local weight update (no backprop needed!)
    if pre_neuron.spike and post_trace > 0:
        # Pre fired AFTER post → Depression
        w -= post_trace
        
    if post_neuron.spike and pre_trace > 0:
        # Pre fired BEFORE post → Potentiation
        w += pre_trace
    
    # Exponential decay
    pre_trace *= exp(-dt/tau)
    post_trace *= exp(-dt/tau)

# Supervised modification (teaching signal)
if output_neuron == correct_class:
    w += 0.01  # Reward
else:
    w -= 0.01  # Punish

# Advantages:
# ✅ Biologically plausible
# ✅ Local learning (no global error)
# ✅ Online learning (incremental updates)
# ❌ BUT: Slower convergence, needs more data
```

---

## Step-by-Step Comparison: Processing One Pattern

### Traditional CNN
```
Input: 2×2 image [1,0,1,1]
  ↓ (flatten)
x = [1, 0, 1, 1]  (4D vector)
  ↓ (matrix multiply)
h = ReLU(W1 @ x)  (8D hidden)
h = [0.7, 0.3, 0.9, 0.1, 0.5, 0.8, 0.2, 0.6]
  ↓ (matrix multiply)
y = softmax(W2 @ h)  (3D output)
y = [0.85, 0.10, 0.05]  (probabilities)
  ↓ (argmax)
class = 0  (L-shape)

Time: Single forward pass (1-2ms on CPU)
Operations: ~56 MACs (multiply-accumulate)
```

### This SNN
```
Input: 2×2 pattern [1,0,1,1]
  ↓ (AER encoding - temporal)
Spike trains over 2000 cycles:
  Pixel 0: ⚡___⚡___⚡___⚡___ (every 5 cycles)
  Pixel 1: _________⚡_________⚡ (every 10 cycles)
  Pixel 2: ⚡___⚡___⚡___⚡___ (every 5 cycles)
  Pixel 3: ⚡___⚡___⚡___⚡___ (every 5 cycles)
  ↓ (integrate over time)
Hidden neurons accumulate:
  Cycle 5: V=43 (input burst)
  Cycle 10: V=97 → ⚡ SPIKE!
  Cycle 15: V=43 again...
  ↓ (propagate spikes)
Output neurons count spikes:
  O0: 399 spikes
  O1: 399 spikes  
  O2: 399 spikes
  ↓ (winner-take-all)
class = 0  (tie-breaker)

Time: 2000 cycles (200μs @ 10MHz)
Operations: Event-driven (only when spikes occur)
```

---

## Training Process Comparison

### CNN Training (Backprop)
```python
# 1. Initialize weights randomly
W1 = np.random.randn(8, 4) * 0.01
W2 = np.random.randn(3, 8) * 0.01

# 2. For each epoch:
for epoch in range(100):
    for pattern, label in dataset:
        # Forward
        h = ReLU(W1 @ pattern)
        y = softmax(W2 @ h)
        
        # Loss
        loss = -log(y[label])
        
        # Backward (compute gradients)
        dW2 = gradient_W2(y, label, h)
        dW1 = gradient_W1(y, label, h, pattern)
        
        # Update (all weights simultaneously)
        W2 -= lr * dW2
        W1 -= lr * dW1

# Result: Optimal weights via gradient descent
```

### SNN Training (STDP)
```python
# 1. Initialize weights randomly
synapses_ih = [Synapse(w=random(0.2,0.5)) for _ in range(32)]
synapses_ho = [Synapse(w=random(0.2,0.5)) for _ in range(24)]

# 2. For each epoch:
for epoch in range(150):
    for pattern, label in dataset:
        # Simulate dynamics over time (250ms)
        for t in range(250):
            # Input spikes (Poisson encoding)
            input_spikes = encode_pattern(pattern, t)
            
            # Hidden neurons
            for h in hidden_neurons:
                current = sum(synapses_ih[i→h].w * input_spikes[i])
                h.step(current)
                
                # STDP updates (local)
                if h.spiked:
                    for syn in synapses_ih[*→h]:
                        syn.update_stdp(...)
            
            # Output neurons
            for o in output_neurons:
                current = sum(synapses_ho[h→o].w * hidden_spikes[h])
                
                # Supervised signal
                if o == label:
                    current += 0.5  # Boost
                else:
                    current -= 0.4  # Suppress
                    
                o.step(current)
                
                # STDP updates (supervised)
                if o.spiked:
                    for syn in synapses_ho[*→o]:
                        if o == label:
                            syn.w += 0.01  # Reward
                        else:
                            syn.w -= 0.01  # Punish

# Result: Weights learned via spike timing + supervision
```

---

## Key Differences in Data Flow

### CNN (Spatial Processing)
```
Layer 0 (Input)     Layer 1 (Hidden)    Layer 2 (Output)
┌─────────┐         ┌─────────┐         ┌─────────┐
│ x[0]=1  │────┬───→│ h[0]=σ  │────┬───→│ y[0]=P  │
│ x[1]=0  │────┼───→│ h[1]=σ  │────┼───→│ y[1]=P  │
│ x[2]=1  │────┼───→│ h[2]=σ  │────┼───→│ y[2]=P  │
│ x[3]=1  │────┘    │  ...    │    └───→│         │
└─────────┘         └─────────┘         └─────────┘
   (4 values)         (8 values)         (3 probs)
   
All values computed simultaneously
Matrix operations: h = σ(Wx)
```

### SNN (Temporal Processing)
```
Time →

t=0   t=5   t=10  t=15  t=20  ...
│     │     │     │     │
Input Layer (spikes)
⚡─────⚡─────⚡─────⚡─────⚡     Pixel 0
──────────────⚡──────────⚡     Pixel 1
⚡─────⚡─────⚡─────⚡─────⚡     Pixel 2
⚡─────⚡─────⚡─────⚡─────⚡     Pixel 3
│     │     │     │     │
Hidden Layer (accumulate V, spike)
──────────────⚡──────────⚡     H0
──────────────⚡──────────⚡     H1
 ...
│     │     │     │     │
Output Layer (count spikes)
──────────────⚡──────────⚡     O0
──────────────⚡──────────⚡     O1
──────────────⚡──────────⚡     O2

Values emerge over time
Event-driven: V += I only when spike occurs
```

---

## Why STDP Instead of Backprop?

### Advantages of STDP
1. **Biological Realism**: Matches how real neurons learn
2. **Local Learning**: No need to propagate errors backward
3. **Online Learning**: Can update weights during inference
4. **Hardware Efficient**: Simple addition, no multiplications
5. **Asynchronous**: Works with event-driven systems

### Disadvantages of STDP
1. **Slower Convergence**: Needs more epochs than backprop
2. **Data Hungry**: Small datasets → poor discrimination
3. **Hyperparameter Sensitive**: A+, A-, τ need careful tuning
4. **Supervision Needed**: Pure STDP often fails (need teaching signal)
5. **Not Optimal**: Doesn't minimize a global loss function

### Why It Failed Here
```
Dataset: Only 3 patterns (L, T, Cross)
Problem: Insufficient diversity for weight differentiation

With 3 patterns:
  - Input 0 appears in 2 of them (L and T)
  - Input 1 appears in 1 of them (T)
  - STDP can't decide: "Strengthen I0→O0 or I0→O1?"
  - Result: Strengthens both equally → homogeneous weights

With 10+ patterns:
  - Input 0 would appear in different contexts
  - Correlations become clearer
  - STDP can differentiate → specialized weights
```

---

## Hardware Implementation Difference

### CNN on FPGA
```verilog
// Typical CNN accelerator:
always @(posedge clk) begin
    // MAC (Multiply-Accumulate) units
    for (i=0; i<N; i++) begin
        acc[i] <= acc[i] + weight[i] * input[i];
    end
    
    // Activation
    if (acc > 0) 
        output <= acc;  // ReLU
    else
        output <= 0;
end

// Characteristics:
// - Always computing (high power)
// - Dense operations (many multipliers)
// - Fixed precision (16/32-bit)
```

### This SNN on FPGA
```verilog
// Event-driven SNN:
always @(posedge clk) begin
    // Only compute when spike occurs
    if (spike_in) begin
        V <= V + weight - leak;  // Simple addition
    end else begin
        V <= V - leak;  // Just decay
    end
    
    // Spike generation
    if (V >= threshold) begin
        spike_out <= 1;
        V <= 0;
    end
end

// Characteristics:
// - Event-driven (low power)
// - Sparse operations (only additions)
// - Low precision (4-bit weights, 8-bit states)
```

---

## Bottom Line

**This SNN uses STDP, not backpropagation.**

It's a fundamentally different approach:
- **Backprop**: Global optimization via gradients
- **STDP**: Local adaptation via spike timing

The architecture demonstrates cutting-edge neuromorphic computing but reveals that STDP needs larger datasets or stronger constraints to compete with backprop on classification tasks.
