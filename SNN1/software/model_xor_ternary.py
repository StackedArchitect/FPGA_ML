#!/usr/bin/env python3
"""
XOR Spiking Neural Network with TERNARY WEIGHTS
================================================
This script tests if XOR can be implemented using ONLY {-1, 0, +1} weights.

Constraint: All synaptic weights must be in {-1, 0, +1}

Author: Senior FPGA Engineer
Date: February 2, 2026
"""

class LIF_Neuron:
    """Simple Leaky Integrate-and-Fire neuron model"""
    
    def __init__(self, threshold=10, leak=1, name="Neuron"):
        self.threshold = threshold
        self.leak = leak
        self.potential = 0
        self.name = name
        self.spike_history = []
        
    def step(self, input_current, time_step):
        """Simulate one time step"""
        # Add input current
        self.potential += input_current
        
        # Apply leak
        self.potential -= self.leak
        
        # Clamp to zero (no negative potentials)
        if self.potential < 0:
            self.potential = 0
        
        # Check for spike
        spike = 0
        if self.potential >= self.threshold:
            spike = 1
            self.spike_history.append(time_step)
            self.potential = 0  # Reset after spike
            
        return spike
    
    def reset(self):
        """Reset neuron state"""
        self.potential = 0
        self.spike_history = []


class SNN_XOR_Ternary:
    """SNN Network for XOR with TERNARY weights {-1, 0, +1}"""
    
    def __init__(self, config=1, leak=0):
        """
        Initialize network with different ternary weight configurations
        
        config: Which weight configuration to try
        leak: Leak value (0 for no leak, allows ternary weights to work)
        """
        # Network parameters
        self.threshold = 3   # Lower threshold for ternary weights
        self.leak = leak     # With ternary weights, leak=0 may be necessary
        
        # Create neurons
        self.hidden_0 = LIF_Neuron(self.threshold, self.leak, "Hidden_0")
        self.hidden_1 = LIF_Neuron(self.threshold, self.leak, "Hidden_1")
        self.output = LIF_Neuron(self.threshold, self.leak, "Output")
        
        # TERNARY WEIGHTS: Only {-1, 0, +1} allowed!
        if config == 1:
            # Configuration 1: Standard approach
            self.w_i0_h0 = 1   # Input 0 to Hidden 0
            self.w_i1_h0 = 1   # Input 1 to Hidden 0
            self.w_i0_h1 = 1   # Input 0 to Hidden 1
            self.w_i1_h1 = 1   # Input 1 to Hidden 1
            self.w_h0_o = 1    # Hidden 0 to Output
            self.w_h1_o = 1    # Hidden 1 to Output
            self.w_h0_h1 = -1  # Lateral inhibition
            self.w_h1_h0 = -1  # Lateral inhibition
            
        elif config == 2:
            # Configuration 2: Asymmetric hidden layer
            self.w_i0_h0 = 1
            self.w_i1_h0 = 0   # H0 only responds to I0
            self.w_i0_h1 = 0   # H1 only responds to I1
            self.w_i1_h1 = 1
            self.w_h0_o = 1
            self.w_h1_o = 1
            self.w_h0_h1 = -1
            self.w_h1_h0 = -1
            
        elif config == 3:
            # Configuration 3: No lateral inhibition, use spike timing
            self.w_i0_h0 = 1
            self.w_i1_h0 = 1
            self.w_i0_h1 = 1
            self.w_i1_h1 = 1
            self.w_h0_o = 1
            self.w_h1_o = 1
            self.w_h0_h1 = 0   # No inhibition
            self.w_h1_h0 = 0
        
        # Verify all weights are ternary
        all_weights = [self.w_i0_h0, self.w_i1_h0, self.w_i0_h1, self.w_i1_h1,
                      self.w_h0_o, self.w_h1_o, self.w_h0_h1, self.w_h1_h0]
        
        for w in all_weights:
            assert w in [-1, 0, 1], f"Invalid weight {w}! Must be in {{-1, 0, +1}}"
        
        print("=" * 80)
        print(f"SNN XOR Network with TERNARY WEIGHTS (Configuration {config})")
        print("=" * 80)
        print(f"Neuron Parameters: Threshold={self.threshold}, Leak={self.leak}")
        print(f"\nConstraint: ALL WEIGHTS ∈ {{-1, 0, +1}}")
        print("\nSynaptic Weights:")
        print(f"  Input→Hidden Layer:")
        print(f"    I0→H0: {self.w_i0_h0:+2d}  |  I1→H0: {self.w_i1_h0:+2d}")
        print(f"    I0→H1: {self.w_i0_h1:+2d}  |  I1→H1: {self.w_i1_h1:+2d}")
        print(f"  Hidden→Output Layer:")
        print(f"    H0→O: {self.w_h0_o:+2d}  |  H1→O: {self.w_h1_o:+2d}")
        print(f"  Lateral Inhibition:")
        print(f"    H0→H1: {self.w_h0_h1:+2d}  |  H1→H0: {self.w_h1_h0:+2d}")
        print("=" * 80 + "\n")
    
    def simulate_spike_train(self, input_0, input_1, time_steps=100, spike_period=5):
        """
        Simulate with periodic spike trains (more realistic)
        
        Args:
            input_0: 1 if input 0 is active, 0 otherwise
            input_1: 1 if input 1 is active, 0 otherwise
            time_steps: Number of time steps to simulate
            spike_period: Generate spike every N steps when input is active
        """
        # Reset all neurons
        self.hidden_0.reset()
        self.hidden_1.reset()
        self.output.reset()
        
        output_spike_count = 0
        
        print(f"Simulating: I0={input_0}, I1={input_1} (spike period={spike_period})")
        print("-" * 80)
        
        for t in range(time_steps):
            # Generate input spikes periodically
            spike_i0 = 1 if (input_0 and t % spike_period == 0) else 0
            spike_i1 = 1 if (input_1 and t % spike_period == 0) else 0
            
            # Calculate currents for hidden layer
            h0_current = 0
            h1_current = 0
            
            if spike_i0:
                h0_current += self.w_i0_h0
                h1_current += self.w_i0_h1
            
            if spike_i1:
                h0_current += self.w_i1_h0
                h1_current += self.w_i1_h1
            
            # Process hidden neurons
            h0_spike = self.hidden_0.step(h0_current, t)
            h1_spike = self.hidden_1.step(h1_current, t)
            
            # Apply lateral inhibition
            if h0_spike:
                self.hidden_1.potential += self.w_h0_h1
                if self.hidden_1.potential < 0:
                    self.hidden_1.potential = 0
                    
            if h1_spike:
                self.hidden_0.potential += self.w_h1_h0
                if self.hidden_0.potential < 0:
                    self.hidden_0.potential = 0
            
            # Calculate current for output neuron
            o_current = 0
            if h0_spike:
                o_current += self.w_h0_o
            if h1_spike:
                o_current += self.w_h1_o
            
            # Process output neuron
            o_spike = self.output.step(o_current, t)
            if o_spike:
                output_spike_count += 1
            
            # Display state when spikes occur or every 10 steps
            if (t < 30) or (spike_i0 or spike_i1 or h0_spike or h1_spike or o_spike):
                print(f"t={t:3d} | In:[{spike_i0},{spike_i1}] | "
                      f"H0: V={self.hidden_0.potential:2d} S={h0_spike} | "
                      f"H1: V={self.hidden_1.potential:2d} S={h1_spike} | "
                      f"Out: V={self.output.potential:2d} S={o_spike}")
        
        print(f"\n{'='*40}")
        print(f"Total Output Spikes: {output_spike_count}")
        print(f"{'='*40}\n")
        
        return output_spike_count


def test_configuration(config, spike_period=5, leak=0):
    """Test a specific weight configuration"""
    
    print("\n" + "=" * 80)
    print(f" TESTING CONFIGURATION {config} (leak={leak})")
    print("=" * 80 + "\n")
    
    snn = SNN_XOR_Ternary(config=config, leak=leak)
    
    # Test cases
    test_cases = [
        (0, 0, 0),  # 0 XOR 0 = 0
        (0, 1, 1),  # 0 XOR 1 = 1
        (1, 0, 1),  # 1 XOR 0 = 1
        (1, 1, 0),  # 1 XOR 1 = 0
    ]
    
    results = []
    
    for i0, i1, expected in test_cases:
        print(f"\n{'─'*80}")
        print(f"TEST: {i0} XOR {i1} = {expected}")
        print(f"{'─'*80}")
        
        spike_count = snn.simulate_spike_train(i0, i1, time_steps=100, spike_period=spike_period)
        
        # XOR: expect output for (0,1) and (1,0), no output for (0,0) and (1,1)
        result = 1 if spike_count > 0 else 0
        
        status = "✓ PASS" if result == expected else "✗ FAIL"
        results.append((i0, i1, expected, result, spike_count, status))
        
        print(f"Expected: {expected}, Got: {result} (spikes={spike_count}) [{status}]")
    
    # Summary
    print("\n" + "=" * 80)
    print(f" CONFIGURATION {config} - SUMMARY")
    print("=" * 80)
    print(f"{'I0':^5} | {'I1':^5} | {'Expected':^10} | {'Got':^5} | {'Spikes':^8} | {'Status':^10}")
    print("-" * 80)
    
    passed = 0
    for i0, i1, expected, result, spikes, status in results:
        print(f"{i0:^5} | {i1:^5} | {expected:^10} | {result:^5} | {spikes:^8} | {status:^10}")
        if "PASS" in status:
            passed += 1
    
    print("=" * 80)
    print(f"Tests Passed: {passed}/4")
    print("=" * 80 + "\n")
    
    return passed == 4


def main():
    """Test multiple configurations to find working ternary weights"""
    
    print("\n" + "=" * 80)
    print(" XOR WITH TERNARY WEIGHTS EXPERIMENT")
    print(" Can we implement XOR using ONLY {-1, 0, +1} weights?")
    print("=" * 80 + "\n")
    
    configurations = [1, 2, 3]
    spike_periods = [3, 5, 10]  # Try different spike frequencies
    leak_values = [0, 1]  # Try with and without leak
    
    working_configs = []
    
    for config in configurations:
        for leak in leak_values:
            for spike_period in spike_periods:
                print(f"\n{'#'*80}")
                print(f"# Testing Config {config}, leak={leak}, spike_period={spike_period}")
                print(f"{'#'*80}")
                
                success = test_configuration(config, spike_period, leak)
                
                if success:
                    working_configs.append((config, spike_period, leak))
                    print(f"\n🎉 SUCCESS! Config {config}, leak={leak}, spike_period={spike_period} works!")
                    break  # Found working params for this config
            if success:
                break  # Skip other leak values once we find one that works
    
    # Final report
    print("\n" + "=" * 80)
    print(" FINAL REPORT")
    print("=" * 80)
    
    if working_configs:
        print(f"\n✓ YES! XOR can be implemented with ternary weights {{-1, 0, +1}}")
        print(f"\nWorking configurations found:")
        for config, sp, leak in working_configs:
            print(f"  - Configuration {config} with spike_period={sp}, leak={leak}")
        
        # Show recommended configuration
        config, sp, leak = working_configs[0]
        snn = SNN_XOR_Ternary(config=config, leak=leak)
        
        print("\n" + "=" * 80)
        print(" RECOMMENDED HARDWARE PARAMETERS")
        print("=" * 80)
        print("Verilog parameters for snn_core.v:")
        print(f"  THRESHOLD    = {snn.threshold};")
        print(f"  LEAK         = {snn.leak};")
        print(f"  SPIKE_PERIOD = {sp};")
        print(f"  WEIGHT_I0_H0 = {snn.w_i0_h0};")
        print(f"  WEIGHT_I1_H0 = {snn.w_i1_h0};")
        print(f"  WEIGHT_I0_H1 = {snn.w_i0_h1};")
        print(f"  WEIGHT_I1_H1 = {snn.w_i1_h1};")
        print(f"  WEIGHT_H0_O  = {snn.w_h0_o};")
        print(f"  WEIGHT_H1_O  = {snn.w_h1_o};")
        print(f"  WEIGHT_H0_H1 = {snn.w_h0_h1};")
        print(f"  WEIGHT_H1_H0 = {snn.w_h1_h0};")
        print("=" * 80)
        
        print("\nKey insight: With ternary weights, we need:")
        print("  1. Lower threshold (since weights are smaller)")
        print("  2. Reduced or zero leak (weight=1, leak=1 → net=0!)")
        print("  3. Proper spike timing (spike_period matters)")
        print("  4. Lateral inhibition still works with weight=-1")
        
    else:
        print(f"\n✗ Could not find working configuration with tested parameters")
        print(f"  Suggestions:")
        print(f"    - Try different threshold values")
        print(f"    - Adjust spike timing")
        print(f"    - Consider 3-layer network")
        print(f"    - Use different neuron models")
    
    print("\n" + "=" * 80 + "\n")


if __name__ == "__main__":
    main()
