# Weight Optimization Strategies & 3×3 Expansion Analysis

## Current Status: 2×2 Pattern Recognition

**Manual Weights:** 58.3% accuracy (L-shape: 75%, Cross: 75%, T-shape: 25%)

**Problem:** T-shape is highly confusable with Cross and L-shape

- T-shape [1,1,0,1]: 3 pixels active
- Cross [0,1,1,1]: 3 pixels active (differs by 1 pixel)
- L-shape [1,0,1,1]: 3 pixels active (differs by 1 pixel)

---

## Optimization Approaches for 2×2

### Approach 1: **Evolutionary Algorithm** (Implemented) 🧬

**Algorithm:** Genetic Algorithm with hardware-in-the-loop evaluation

**How it works:**

1. **Population:** 15-20 weight sets (each = 56 weights)
2. **Fitness:** Run actual hardware simulation, measure accuracy
3. **Selection:** Keep top 20% (elites), tournament select parents
4. **Crossover:** Combine parent weights at random point
5. **Mutation:** Randomly perturb 15-20% of weights by ±3
6. **Evolution:** Repeat for 20-30 generations

**Advantages:**

- ✓ No gradient needed (spike non-differentiability doesn't matter)
- ✓ Directly optimizes hardware metric (accuracy)
- ✓ Explores non-convex solution space
- ✓ Can escape local optima via mutation
- ✓ Proven effective for small parameter spaces

**Disadvantages:**

- ✗ Slow: ~15 individuals × 20 gens × 20s/eval = 100 minutes
- ✗ Stochastic: Different runs may find different solutions
- ✗ No convergence guarantee

**Expected improvement:** 58% → 70-80%

---

### Approach 2: **Grid Search** (Brute Force)

**Algorithm:** Systematic exploration of weight combinations

**How it works:**

1. Identify critical weights (hidden→output layer: 24 weights)
2. Test discrete values: {0, 3, 6, 9, 12, 15} (6 levels)
3. For each output neuron, try all combinations
4. Keep input→hidden fixed (less critical for discrimination)

**Advantages:**

- ✓ Exhaustive: Guaranteed to find best in search space
- ✓ Deterministic: Reproducible results
- ✓ Simple to implement and understand

**Disadvantages:**

- ✗ Combinatorial explosion: 6^24 = 4.7×10^18 combinations (infeasible)
- ✗ Even with pruning: 6^6 = 46,656 for just output layer
- ✗ Very slow for hardware evaluation

**Feasibility:** Only practical if search space reduced to ~100-1000 candidates

---

### Approach 3: **Analytical Tuning** (Manual with Insight)

**Algorithm:** Analyze failures, adjust discriminatively

**Current failure analysis:**

```
T-shape [1,1,0,1] misclassified as:
  - Cross [0,1,1,1]: Both have pixels 1,3 active
  - L-shape [1,0,1,1]: Both have pixels 0,2,3 active

Key difference: T-shape is ONLY pattern with pixels 0,1,3 all active
```

**Strategy:**

1. **Increase T-shape uniqueness:**
   - Boost weight on pixel 1 → hidden layer
   - Suppress output 0 and 2 from hidden neurons sensing pixel 1
2. **Sharpen Cross discrimination:**
   - Cross has pixel 1,2,3 (lacks pixel 0)
   - Increase penalty for pixel 0 activation on Cross output

3. **Maintain L-shape:**
   - L-shape has 0,2,3 (lacks pixel 1)
   - Already working well (75%)

**Advantages:**

- ✓ Fast: Minutes, not hours
- ✓ Interpretable: Know why each weight changes
- ✓ Targeted: Fix specific failure modes

**Disadvantages:**

- ✗ Requires domain expertise
- ✗ May miss non-obvious solutions
- ✗ Trial-and-error iteration

**Expected improvement:** 58% → 65-75%

---

### Approach 4: **Supervised Learning** (Perceptron/Delta Rule)

**Algorithm:** Gradient-based weight update (if we approximate gradients)

**How it works:**

```python
for each pattern:
    output = forward_pass(pattern)
    error = target - output
    for each weight:
        weight += learning_rate * error * input_activation
```

**Challenges with SNNs:**

- ✗ Spike rate not differentiable (discrete events)
- ✗ Temporal dynamics complicate backprop
- ✗ Would need spike-timing gradient approximation

**Workaround: Rate-based approximation**

- Treat spike count as continuous value
- Use final spike counts instead of timing
- Apply standard perceptron learning

**Expected improvement:** 58% → 75-85%

---

## 3×3 Mesh Expansion Analysis 📐

### Impact of Scaling to 3×3

**Current 2×2:**

- Input dimension: 4 pixels
- Pattern space: 2^4 = **16 total possible patterns**
- Classes: 3 (L, T, Cross)
- Patterns per class: ~5 maximum

**Proposed 3×3:**

- Input dimension: 9 pixels
- Pattern space: 2^9 = **512 total possible patterns**
- Classes: Multiple (can expand to 10+ classes)
- Patterns per class: 50+ easily achievable

### Architectural Changes

**Network size:**

```
2×2 version: 4 → 8 → 3 = 56 weights
3×3 version: 9 → 16 → 10 = 304 weights (5.4× larger)
```

**Patterns:**

```
2×2: Simple geometric shapes (limited)
  ✓ L-shape
  ✓ T-shape
  ✓ Cross
  ✓ Corner
  ✓ Line

3×3: Rich pattern library
  ✓ Digits 0-9
  ✓ Letters A-Z
  ✓ Arrows (↑↓←→)
  ✓ Geometric shapes (square, diamond, etc.)
  ✓ 100+ meaningful patterns
```

### Would STDP Work with 3×3?

**YES** - Here's why:

**1. Sufficient Pattern Diversity**

- 512 possible patterns vs. 16 (32× increase)
- Room for meaningful augmentation (rotation, noise, translation)
- Can generate 100+ unique training examples per class

**2. Feature Learning Becomes Viable**

- 9-dimensional space allows edge detection, corner detection
- Hidden layer (16 neurons) can specialize to local features
- Similar to how MNIST (28×28) works with SNNs

**3. Class Separability**

- Larger Hamming distance between classes
- Less confusion between similar patterns
- More robust to noise and occlusions

**4. STDP Has Room to Learn**

- Weight space: 304 dimensions
- Rich feature combinations possible
- Biological plausibility restored (realistic input dimensions)

### STDP Performance Estimate (3×3)

**With proper setup:**

- Dataset: 50-100 samples per class, 10 classes
- Augmentation: Rotation, shift, noise
- Training: 100-200 epochs
- **Expected STDP accuracy: 60-75%**

**With supervision (R-STDP):**

- Reward-modulated STDP
- Reinforcement signal for correct classifications
- **Expected accuracy: 75-85%**

**With supervised backprop:**

- Standard gradient descent through spike rates
- **Expected accuracy: 85-95%**

### Implementation Effort (2×2 → 3×3)

**Hardware changes (Moderate):**

- Scale neurons: 4→9 input, 8→16 hidden, 3→10 output
- Update AER encoder: 2-bit → 4-bit addressing
- Adjust testbench for new patterns
- **Estimated: 2-3 hours**

**Training infrastructure (Minor):**

- Update pattern dataset (already have augmentation code)
- Adjust network dimensions in Python
- **Estimated: 1 hour**

**STDP viability (Major improvement):**

- 512-pattern space makes STDP actually usable
- Worth revisiting STDP approach
- **Potential: STDP becomes primary training method**

---

## Recommendation Summary

### For 2×2 (Current Project):

**Short term (1-2 hours):**

1. ✅ **Run Analytical Tuning** - Quick wins by fixing T-shape weights
2. ✅ **Run Evolutionary Optimization** - Overnight run for optimal solution

**Expected Result:** 65-80% accuracy

**Best ROI:** Analytical tuning (fast, 65-75% likely)

### For 3×3 (Future Expansion):

**If you want to demonstrate STDP working:**

1. Expand to 3×3 mesh
2. Create digit recognition dataset (0-9)
3. Implement proper STDP training
4. Document: "STDP works when problem is right-sized"

**Expected Result:** 70-85% with STDP, proving the approach

**Timeline:** 1-2 days of work, publishable results

---

## My Recommendation 🎯

**For immediate accuracy improvement:**

```bash
# Option A: Quick analytical fix (30 min)
# Manually adjust T-shape weights in weight_parameters.vh
# Target: 65-75% accuracy

# Option B: Automated optimization (2 hours)
cd /home/arvind/FPGA_SNN/SNN2_AER/python
python optimize_weights.py  # Runs evolutionary algorithm
# Target: 70-80% accuracy
```

**For demonstrating STDP properly:**

```bash
# Expand to 3×3, implement digit recognition
# STDP will actually work with 512-pattern space
# Target: 75% with STDP, 90% with supervised learning
```

**What would you like to do?**

1. Optimize 2×2 now (run evolutionary algorithm)?
2. Quick manual fix for T-shape?
3. Expand to 3×3 for proper STDP demonstration?
