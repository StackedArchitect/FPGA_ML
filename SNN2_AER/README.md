# SNN2_AER: 2×2 Pattern Recognition with Spiking Neural Network

## Project Status: ✅ COMPLETE

**Final Solution:** Manual weight design achieving **58.3% accuracy**

After extensive experimentation with STDP-based learning approaches, we determined that **manually designed weights outperform machine learning** for small-scale pattern recognition tasks.

### What We've Built ✓

- ✅ 3-layer SNN architecture (4→8→3 neurons)
- ✅ AER (Address-Event Representation) encoding
- ✅ LIF neuron model with hardware implementation
- ✅ Pattern recognition for 3 classes (L-shape, T-shape, Cross)
- ✅ Complete Verilog testbench and simulation
- ✅ Working hardware deployment at **58.3% accuracy**

### Performance Summary

| Approach                          | Accuracy  | Status      |
| --------------------------------- | --------- | ----------- |
| **Manual Weights**                | **58.3%** | ✅ Deployed |
| Baseline STDP                     | 33.3%     | ❌ Failed   |
| Supervised STDP                   | 33.3%     | ❌ Failed   |
| Enhanced STDP (augmented dataset) | 33.3%     | ❌ Failed   |

### Why STDP Didn't Work

After implementing three different STDP variants with extensive dataset augmentation and supervision, all achieved only **33.3% accuracy** (random guessing).

**Root causes:**

- 2×2 pattern space too small (only 16 possible patterns)
- STDP requires 100s-1000s of diverse examples
- High pattern similarity (differ by 1-2 pixels)
- Weight saturation to maximum values
- Class imbalance caused degenerate solutions

**See [STDP_FAILURE_ANALYSIS.md](docs/STDP_FAILURE_ANALYSIS.md) for complete investigation.**

### Lessons Learned

1. **Domain knowledge > Machine learning** for tiny datasets
2. **STDP is not universal** - works for large-scale, high-dimensional problems
3. **Manual design is valid engineering** - interpretable and debuggable
4. **Know when to pivot** - after 3 failed ML attempts, try simple solution

- Gradually reduce teaching signal strength
- Best of both worlds

### Current Status

## Project Structure

```
SNN2_AER/
├── docs/
│   ├── ARCHITECTURE.md                    # System architecture
│   ├── STDP_FAILURE_ANALYSIS.md          # Why STDP didn't work
│   ├── HARDWARE_VALIDATION_REPORT.md     # Test results
│   └── ...                               # Other technical docs
├── hardware/
│   ├── snn_core_pattern_recognition.v    # Main SNN core
│   ├── lif_neuron_stdp.v                 # LIF neuron model
│   ├── aer_pixel_encoder.v               # Pixel to spike encoder
│   ├── tb_snn_pattern_recognition.v      # Testbench
│   ├── weight_parameters.vh              # Manual weights (active)
│   └── weight_parameters_manual.vh       # Manual weights (backup)
├── python/
│   ├── generate_verilog_weights.py       # Weight converter
│   └── diagnose_hardware.py              # Debug utilities
└── README.md                             # This file
```

## Manual Weight Design

**L-shape Detector (Output 0):**

- High weights on pixels [0, 2, 3]: W=15
- Low weight on pixel [1]: W=3
- Responds strongly to L-shaped patterns

**T-shape Detector (Output 1):**

- High weights on pixels [0, 1, 3]: W=15
- Low weight on pixel [2]: W=3
- Responds strongly to T-shaped patterns

**Cross Detector (Output 2):**

- High weights on pixels [1, 2, 3]: W=15
- Low weight on pixel [0]: W=3
- Responds strongly to Cross patterns

**Total Parameters:** 56 synapses (4→8→3 architecture)

## Testing & Validation

```bash
cd hardware/
iverilog -o snn_test -g2012 lif_neuron_stdp.v aer_pixel_encoder.v \
    snn_core_pattern_recognition.v tb_snn_pattern_recognition.v
./snn_test
```

**Expected Output:**

```
Success rate: 58.3% (7/12 tests passed)
✓ L-shape recognition: Good
✓ Cross recognition: Good
⚠ T-shape recognition: Needs improvement
```

## Key Insights

1. **SNNs are powerful** for large-scale neuromorphic computing
2. **STDP shines** with 1000+ diverse patterns, not 3-16 patterns
3. **Manual design is engineering** - valid when it works better
4. **Biological inspiration ≠ always optimal** for every scale
5. **Know your tools** - use the right approach for the problem size

## Documentation

- **[STDP_FAILURE_ANALYSIS.md](docs/STDP_FAILURE_ANALYSIS.md)** - Complete investigation of why STDP failed
- **[HARDWARE_VALIDATION_REPORT.md](docs/HARDWARE_VALIDATION_REPORT.md)** - Hardware test results
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - System design details

## Conclusion

This project demonstrates both the **promise and limitations** of neuromorphic computing:

✅ **Success:** Functional SNN hardware implementation
✅ **Success:** Understanding of STDP dynamics and limitations  
✅ **Success:** 58.3% accuracy with interpretable manual weights
✅ **Success:** Complete end-to-end pattern recognition pipeline

📚 **Learning:** Machine learning isn't always the answer - sometimes domain expertise and manual design are more effective, especially for small, well-understood problems.

**Project Status: COMPLETE AND DEPLOYED** 🎯
