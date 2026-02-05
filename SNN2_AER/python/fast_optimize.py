#!/usr/bin/env python3
"""
Fast Gradient-Free Optimization (Coordinate Descent + Random Search)

Strategy: Fix input→hidden weights, optimize only hidden→output (24 weights)
This is 5× faster than full optimization.
"""

import numpy as np
import subprocess
import json

class FastWeightOptimizer:
    def __init__(self):
        self.n_hidden = 8
        self.n_output = 3
        self.n_weights = self.n_hidden * self.n_output  # 24 weights
        
        # Load baseline input→hidden weights (keep these fixed)
        self.baseline_input_hidden = self.load_baseline_input_hidden()
        
        # Best solution
        self.best_weights = None
        self.best_accuracy = 0.583  # Baseline
        
    def load_baseline_input_hidden(self):
        """Load and parse input→hidden weights from baseline file"""
        weights = np.zeros((4, 8), dtype=int)
        
        with open('../hardware/weight_parameters_manual.vh') as f:
            for line in f:
                if 'parameter WEIGHT_I' in line and '=' in line:
                    parts = line.split()
                    param = parts[1]  # e.g., "WEIGHT_I0_H3"
                    value = int(parts[3].rstrip(';'))
                    
                    # Parse: WEIGHT_I0_H3 -> i=0, h=3
                    tokens = param.split('_')  # ['WEIGHT', 'I0', 'H3']
                    i_idx = int(tokens[1].replace('I', ''))
                    h_idx = int(tokens[2].replace('H', ''))
                    weights[i_idx, h_idx] = value
        
        return weights
    
    def evaluate_hardware(self, hidden_output_weights):
        """Test weights on hardware, return accuracy"""
        # Generate Verilog
        with open('../hardware/weight_parameters.vh', 'w') as f:
            f.write("// Auto-optimized weights\n\n")
            
            # Input→Hidden (baseline, fixed)
            for i in range(4):
                for h in range(8):
                    w = self.baseline_input_hidden[i, h]
                    f.write(f"parameter WEIGHT_I{i}_H{h} = {w};\n")
            
            # Hidden→Output (optimizing these)
            f.write("\n")
            for h in range(8):
                for o in range(3):
                    w = hidden_output_weights[h, o]
                    f.write(f"parameter WEIGHT_H{h}_O{o} = {w};\n")
            
            f.write("\nparameter BIAS_OUTPUT_0 = 0;\n")
            f.write("parameter BIAS_OUTPUT_1 = 0;\n")
            f.write("parameter BIAS_OUTPUT_2 = 0;\n")
        
        # Compile
        result = subprocess.run(
            ['iverilog', '-o', 'opt_test', '-g2012',
             'lif_neuron_stdp.v', 'aer_pixel_encoder.v',
             'snn_core_pattern_recognition.v', 'tb_snn_pattern_recognition.v'],
            cwd='../hardware',
            capture_output=True
        )
        
        if result.returncode != 0:
            return 0.0
        
        # Run
        result = subprocess.run(
            ['./opt_test'],
            cwd='../hardware',
            capture_output=True,
            text=True,
            timeout=30
        )
        
        # Parse
        for line in result.stdout.split('\n'):
            if 'Success rate:' in line:
                rate = float(line.split(':')[1].strip().replace('%', ''))
                return rate / 100.0
        
        return 0.0
    
    def optimize_coordinate_descent(self, max_iterations=50):
        """
        Coordinate descent: Optimize one weight at a time
        Much faster than full search
        """
        print("="*60)
        print("FAST COORDINATE DESCENT OPTIMIZATION")
        print("="*60)
        print(f"Optimizing {self.n_weights} weights (hidden→output only)")
        print(f"Max iterations: {max_iterations}")
        print(f"Baseline accuracy: {self.best_accuracy*100:.1f}%")
        print("="*60)
        
        # Start with baseline hidden→output weights
        current_weights = np.array([
            [0, 0, 0],    # H0
            [0, 0, 0],    # H1
            [0, 0, 0],    # H2
            [0, 0, 0],    # H3
            [0, 15, 0],   # H4
            [15, 0, 15],  # H5
            [15, 0, 0],   # H6
            [0, 15, 15],  # H7
        ], dtype=int)
        
        self.best_weights = current_weights.copy()
        
        improvements = []
        
        for iteration in range(max_iterations):
            print(f"\n--- Iteration {iteration+1}/{max_iterations} ---")
            
            improved = False
            
            # Try perturbing each weight
            for h in range(8):
                for o in range(3):
                    current_val = current_weights[h, o]
                    
                    # Try nearby values
                    candidates = []
                    for delta in [-3, -1, +1, +3]:
                        new_val = np.clip(current_val + delta, 0, 15)
                        if new_val != current_val:
                            candidates.append(new_val)
                    
                    if not candidates:
                        continue
                    
                    # Test best candidate
                    for new_val in candidates:
                        test_weights = current_weights.copy()
                        test_weights[h, o] = new_val
                        
                        acc = self.evaluate_hardware(test_weights)
                        
                        if acc > self.best_accuracy:
                            print(f"  ✓ H{h}→O{o}: {current_val}→{new_val} = {acc*100:.1f}% (+{(acc-self.best_accuracy)*100:.1f}%)")
                            current_weights[h, o] = new_val
                            self.best_weights = current_weights.copy()
                            self.best_accuracy = acc
                            improved = True
                            improvements.append(acc)
                            break  # Take first improvement (greedy)
            
            if not improved:
                print(f"  No improvement found - converged!")
                break
        
        print(f"\n{'='*60}")
        print(f"OPTIMIZATION COMPLETE")
        print(f"{'='*60}")
        print(f"Final accuracy: {self.best_accuracy*100:.1f}%")
        print(f"Improvement: +{(self.best_accuracy-0.583)*100:.1f} percentage points")
        print(f"Total improvements: {len(improvements)}")
        
        return self.best_weights, self.best_accuracy
    
    def optimize_random_search(self, n_trials=100):
        """
        Random search: Try random weight configurations
        Simple but effective baseline
        """
        print("="*60)
        print("RANDOM SEARCH OPTIMIZATION")
        print("="*60)
        print(f"Testing {n_trials} random configurations")
        print(f"Baseline: {self.best_accuracy*100:.1f}%")
        print("="*60)
        
        # Baseline weights
        best_weights = np.array([
            [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0],
            [0, 15, 0], [15, 0, 15], [15, 0, 0], [0, 15, 15]
        ], dtype=int)
        
        for trial in range(n_trials):
            # Generate random perturbation
            weights = best_weights.copy()
            
            # Randomly perturb 3-5 weights
            n_changes = np.random.randint(3, 6)
            for _ in range(n_changes):
                h = np.random.randint(8)
                o = np.random.randint(3)
                delta = np.random.choice([-3, -2, -1, 1, 2, 3])
                weights[h, o] = np.clip(weights[h, o] + delta, 0, 15)
            
            # Test
            acc = self.evaluate_hardware(weights)
            
            if acc > self.best_accuracy:
                print(f"Trial {trial+1}: {acc*100:.1f}% ✓ NEW BEST!")
                self.best_weights = weights.copy()
                self.best_accuracy = acc
                best_weights = weights.copy()
            elif trial % 10 == 0:
                print(f"Trial {trial+1}: {acc*100:.1f}%")
        
        print(f"\n{'='*60}")
        print(f"SEARCH COMPLETE")
        print(f"{'='*60}")
        print(f"Best accuracy: {self.best_accuracy*100:.1f}%")
        
        return self.best_weights, self.best_accuracy
    
    def save_results(self):
        """Save optimized weights"""
        with open('../hardware/weight_parameters_optimized.vh', 'w') as f:
            f.write("// Optimized weights via coordinate descent\n")
            f.write(f"// Accuracy: {self.best_accuracy*100:.1f}%\n\n")
            
            # Input→Hidden (baseline)
            for i in range(4):
                for h in range(8):
                    w = self.baseline_input_hidden[i, h]
                    f.write(f"parameter WEIGHT_I{i}_H{h} = {w};\n")
            
            # Hidden→Output (optimized) 
            f.write("\n// Optimized hidden→output weights\n")
            for h in range(8):
                for o in range(3):
                    w = self.best_weights[h, o]
                    f.write(f"parameter WEIGHT_H{h}_O{o} = {w};\n")
            
            f.write("\nparameter BIAS_OUTPUT_0 = 0;\n")
            f.write("parameter BIAS_OUTPUT_1 = 0;\n")
            f.write("parameter BIAS_OUTPUT_2 = 0;\n")
        
        # Save JSON
        results = {
            'accuracy': float(self.best_accuracy),
            'improvement': float(self.best_accuracy - 0.583),
            'hidden_output': self.best_weights.tolist()
        }
        
        with open('../results/optimization_results.json', 'w') as f:
            json.dump(results, f, indent=2)
        
        print(f"\n✓ Optimized weights saved to: hardware/weight_parameters_optimized.vh")


if __name__ == "__main__":
    import sys
    
    optimizer = FastWeightOptimizer()
    
    # Choose algorithm
    if len(sys.argv) > 1 and sys.argv[1] == 'random':
        weights, acc = optimizer.optimize_random_search(n_trials=50)
    else:
        weights, acc = optimizer.optimize_coordinate_descent(max_iterations=30)
    
    optimizer.save_results()
    
    print(f"\n{'='*60}")
    print("FINAL OPTIMIZED WEIGHTS")
    print(f"{'='*60}")
    print("Hidden→Output:")
    print(weights)
    print(f"\nAccuracy: {acc*100:.1f}%")
