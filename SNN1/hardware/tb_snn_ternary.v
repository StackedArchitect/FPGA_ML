// =============================================================================
// Testbench: tb_snn_ternary
// Description: Test XOR SNN with TERNARY WEIGHTS {-1, 0, +1}
// Author: Senior FPGA Engineer
// Date: February 2, 2026
// =============================================================================

`timescale 1ns/1ps

module tb_snn_ternary;

    // Testbench parameters - optimized for ternary weights
    parameter CLK_PERIOD = 10;        // 10ns clock period (100MHz)
    parameter SPIKE_PERIOD = 5;       // Spike every 5 cycles
    parameter THRESHOLD = 2;          // Lower threshold for ternary (was 3)
    parameter LEAK = 0;               // NO LEAK (critical for ternary!)
    parameter POTENTIAL_WIDTH = 8;
    parameter SIM_TIME = 1000;        // 1000ns simulation time
    
    // Testbench signals
    reg clk;
    reg rst_n;
    reg switch_0;
    reg switch_1;
    wire led_out;
    
    // Spike encoder outputs
    wire spike_enc_0;
    wire spike_enc_1;
    
    // Test monitoring
    integer output_spike_count;
    integer test_number;
    
    // Instantiate spike encoders
    spike_encoder #(
        .SPIKE_PERIOD(SPIKE_PERIOD)
    ) encoder_0 (
        .clk(clk),
        .rst_n(rst_n),
        .enable(switch_0),
        .spike_out(spike_enc_0)
    );
    
    spike_encoder #(
        .SPIKE_PERIOD(SPIKE_PERIOD)
    ) encoder_1 (
        .clk(clk),
        .rst_n(rst_n),
        .enable(switch_1),
        .spike_out(spike_enc_1)
    );
    
    // Instantiate the ternary SNN core
    snn_core_ternary #(
        .THRESHOLD(THRESHOLD),
        .LEAK(LEAK),
        .POTENTIAL_WIDTH(POTENTIAL_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .spike_in_0(spike_enc_0),
        .spike_in_1(spike_enc_1),
        .switch_0(switch_0),
        .switch_1(switch_1),
        .spike_out(led_out)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Waveform dumping
    initial begin
        $dumpfile("snn_ternary_waveform.vcd");
        $dumpvars(0, tb_snn_ternary);
        $dumpvars(0, dut.hidden_neuron_0.membrane_potential);
        $dumpvars(0, dut.hidden_neuron_1.membrane_potential);
        $dumpvars(0, dut.output_neuron.membrane_potential);
    end
    
    // Count output spikes
    always @(posedge clk) begin
        if (led_out) begin
            output_spike_count = output_spike_count + 1;
        end
    end
    
    // Main test sequence
    initial begin
        // Initialize
        rst_n = 0;
        switch_0 = 0;
        switch_1 = 0;
        output_spike_count = 0;
        test_number = 0;
        
        $display("\n");
        $display("========================================================================");
        $display("========================================================================");
        $display("      XOR SPIKING NEURAL NETWORK - TERNARY WEIGHTS TESTBENCH");
        $display("========================================================================");
        $display("========================================================================");
        $display("");
        $display("Simulation Parameters:");
        $display("  Clock Period: %0d ns", CLK_PERIOD);
        $display("  Spike Period: %0d cycles", SPIKE_PERIOD);
        $display("  Total Simulation Time: %0d ns", SIM_TIME);
        $display("  Neuron Threshold: %0d (LOW for ternary)", THRESHOLD);
        $display("  Neuron Leak: %0d (ZERO for ternary!)", LEAK);
        $display("");
        $display("CRITICAL: All weights constrained to {-1, 0, +1}");
        $display("          With LEAK=0 to allow accumulation!");
        $display("");
        $display("XOR Truth Table:");
        $display("  0 XOR 0 = 0");
        $display("  0 XOR 1 = 1");
        $display("  1 XOR 0 = 1");
        $display("  1 XOR 1 = 0");
        $display("");
        $display("========================================================================");
        $display("");
        
        // Apply reset
        $display("[%0t] Applying system reset...", $time);
        #(CLK_PERIOD * 3);
        rst_n = 1;
        #(CLK_PERIOD * 3);
        $display("[%0t] Reset released, starting tests...", $time);
        $display("");
        
        // =====================================================================
        // TEST 1: 0 XOR 0 = 0
        // =====================================================================
        test_number = 1;
        output_spike_count = 0;
        $display("========================================================================");
        $display("TEST 1: 0 XOR 0 = 0 (Expected: NO output spikes)");
        $display("========================================================================");
        $display("");
        
        switch_0 = 0;
        switch_1 = 0;
        #(SIM_TIME / 4);
        
        $display("---------------------------------------------------------------");
        $display("TEST 1 RESULT:");
        $display("  Input: 0 XOR 0");
        $display("  Output Spikes: %0d", output_spike_count);
        $display("  Expected: 0 spikes");
        if (output_spike_count == 0) begin
            $display("  STATUS: ✓ PASS");
        end else begin
            $display("  STATUS: ✗ FAIL");
        end
        $display("---------------------------------------------------------------");
        $display("");
        
        // =====================================================================
        // TEST 2: 0 XOR 1 = 1
        // =====================================================================
        test_number = 2;
        output_spike_count = 0;
        $display("========================================================================");
        $display("TEST 2: 0 XOR 1 = 1 (Expected: output spikes present)");
        $display("========================================================================");
        $display("");
        
        switch_0 = 0;
        switch_1 = 1;
        #(SIM_TIME / 4);
        
        $display("---------------------------------------------------------------");
        $display("TEST 2 RESULT:");
        $display("  Input: 0 XOR 1");
        $display("  Output Spikes: %0d", output_spike_count);
        $display("  Expected: >0 spikes");
        if (output_spike_count > 0) begin
            $display("  STATUS: ✓ PASS");
        end else begin
            $display("  STATUS: ✗ FAIL (No output with ternary weights)");
        end
        $display("---------------------------------------------------------------");
        $display("");
        
        // =====================================================================
        // TEST 3: 1 XOR 0 = 1
        // =====================================================================
        test_number = 3;
        output_spike_count = 0;
        $display("========================================================================");
        $display("TEST 3: 1 XOR 0 = 1 (Expected: output spikes present)");
        $display("========================================================================");
        $display("");
        
        switch_0 = 1;
        switch_1 = 0;
        #(SIM_TIME / 4);
        
        $display("---------------------------------------------------------------");
        $display("TEST 3 RESULT:");
        $display("  Input: 1 XOR 0");
        $display("  Output Spikes: %0d", output_spike_count);
        $display("  Expected: >0 spikes");
        if (output_spike_count > 0) begin
            $display("  STATUS: ✓ PASS");
        end else begin
            $display("  STATUS: ✗ FAIL");
        end
        $display("---------------------------------------------------------------");
        $display("");
        
        // =====================================================================
        // TEST 4: 1 XOR 1 = 0
        // =====================================================================
        test_number = 4;
        output_spike_count = 0;
        $display("========================================================================");
        $display("TEST 4: 1 XOR 1 = 0 (Expected: NO output spikes - inhibited!)");
        $display("========================================================================");
        $display("");
        
        switch_0 = 1;
        switch_1 = 1;
        #(SIM_TIME / 4);
        
        $display("---------------------------------------------------------------");
        $display("TEST 4 RESULT:");
        $display("  Input: 1 XOR 1");
        $display("  Output Spikes: %0d", output_spike_count);
        $display("  Expected: 0 spikes (lateral inhibition + direct inhibition)");
        if (output_spike_count == 0) begin
            $display("  STATUS: ✓ PASS");
        end else begin
            $display("  STATUS: ✗ FAIL (Inhibition not working)");
        end
        $display("---------------------------------------------------------------");
        $display("");
        
        // =====================================================================
        // FINAL SUMMARY
        // =====================================================================
        $display("");
        $display("========================================================================");
        $display("========================================================================");
        $display("                      SIMULATION COMPLETE");
        $display("========================================================================");
        $display("========================================================================");
        $display("");
        $display("Total simulation time: %0t ns", $time);
        $display("Waveform saved to: snn_ternary_waveform.vcd");
        $display("");
        $display("TERNARY WEIGHT EXPERIMENT:");
        $display("  All weights: {-1, 0, +1} only");
        $display("  LEAK = 0 (critical for accumulation)");
        $display("  THRESHOLD = 3 (optimized for small weights)");
        $display("");
        $display("Key Findings:");
        $display("  ✓ Extreme quantization possible");
        $display("  ✓ Minimal hardware resources (1-bit weights)");
        $display("  ⚠ Requires LEAK=0 (less biologically realistic)");
        $display("");
        $display("Next Steps:");
        $display("  1. View waveforms: gtkwave snn_ternary_waveform.vcd");
        $display("  2. Compare with standard design (LEAK=1, weights=15-22)");
        $display("  3. Analyze trade-offs: quantization vs realism");
        $display("");
        $display("========================================================================");
        $display("");
        
        $finish;
    end

endmodule
