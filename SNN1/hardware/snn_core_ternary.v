// =============================================================================
// Module: snn_core_ternary
// Description: XOR SNN with TERNARY WEIGHTS {-1, 0, +1} ONLY
//              Extreme weight quantization experiment
// Author: Senior FPGA Engineer
// Date: February 2, 2026
// =============================================================================

module snn_core_ternary #(
    // Neuron parameters - optimized for ternary weights
    parameter THRESHOLD = 3,       // Much lower threshold (weights are small)
    parameter LEAK = 0,            // CRITICAL: No leak! (weight+1, leak-1 = net 0)
    parameter POTENTIAL_WIDTH = 8,
    
    // TERNARY WEIGHTS: ALL must be in {-1, 0, +1}
    // Input to Hidden layer
    parameter signed WEIGHT_I0_H0 = 1,   // +1
    parameter signed WEIGHT_I1_H0 = 1,   // +1
    parameter signed WEIGHT_I0_H1 = 1,   // +1
    parameter signed WEIGHT_I1_H1 = 1,   // +1
    
    // Hidden to Output layer
    parameter signed WEIGHT_H0_O = 1,    // +1
    parameter signed WEIGHT_H1_O = 1,    // +1
    
    // Lateral inhibition (still critical for XOR)
    parameter signed WEIGHT_H0_H1 = -1,  // -1
    parameter signed WEIGHT_H1_H0 = -1,  // -1
    
    // Direct output inhibition when both inputs active
    parameter signed WEIGHT_BOTH_INHIB = -1  // -1 (subtle but effective)
)(
    input  wire clk,              // Clock signal
    input  wire rst_n,            // Active low reset
    input  wire spike_in_0,       // Input spike from encoder 0
    input  wire spike_in_1,       // Input spike from encoder 1
    input  wire switch_0,         // Raw switch state 0
    input  wire switch_1,         // Raw switch state 1
    output wire spike_out         // Output spike
);

    // Compile-time assertions to verify ternary constraint
    initial begin
        if (WEIGHT_I0_H0 < -1 || WEIGHT_I0_H0 > 1) $fatal(1, "WEIGHT_I0_H0=%0d violates ternary constraint!", WEIGHT_I0_H0);
        if (WEIGHT_I1_H0 < -1 || WEIGHT_I1_H0 > 1) $fatal(1, "WEIGHT_I1_H0=%0d violates ternary constraint!", WEIGHT_I1_H0);
        if (WEIGHT_I0_H1 < -1 || WEIGHT_I0_H1 > 1) $fatal(1, "WEIGHT_I0_H1=%0d violates ternary constraint!", WEIGHT_I0_H1);
        if (WEIGHT_I1_H1 < -1 || WEIGHT_I1_H1 > 1) $fatal(1, "WEIGHT_I1_H1=%0d violates ternary constraint!", WEIGHT_I1_H1);
        if (WEIGHT_H0_O < -1 || WEIGHT_H0_O > 1) $fatal(1, "WEIGHT_H0_O=%0d violates ternary constraint!", WEIGHT_H0_O);
        if (WEIGHT_H1_O < -1 || WEIGHT_H1_O > 1) $fatal(1, "WEIGHT_H1_O=%0d violates ternary constraint!", WEIGHT_H1_O);
        if (WEIGHT_H0_H1 < -1 || WEIGHT_H0_H1 > 1) $fatal(1, "WEIGHT_H0_H1=%0d violates ternary constraint!", WEIGHT_H0_H1);
        if (WEIGHT_H1_H0 < -1 || WEIGHT_H1_H0 > 1) $fatal(1, "WEIGHT_H1_H0=%0d violates ternary constraint!", WEIGHT_H1_H0);
        if (WEIGHT_BOTH_INHIB < -1 || WEIGHT_BOTH_INHIB > 1) $fatal(1, "WEIGHT_BOTH_INHIB=%0d violates ternary constraint!", WEIGHT_BOTH_INHIB);
        
        if (LEAK != 0) $warning("LEAK=%0d is non-zero! Ternary weights work best with LEAK=0", LEAK);
    end

    // Hidden layer spike signals
    wire spike_hidden_0;
    wire spike_hidden_1;
    
    // Weighted spike signals for Hidden 0
    wire signed [POTENTIAL_WIDTH-1:0] weighted_i0_h0;
    wire signed [POTENTIAL_WIDTH-1:0] weighted_i1_h0;
    wire signed [POTENTIAL_WIDTH-1:0] weighted_h1_h0_inhib;
    
    // Weighted spike signals for Hidden 1
    wire signed [POTENTIAL_WIDTH-1:0] weighted_i0_h1;
    wire signed [POTENTIAL_WIDTH-1:0] weighted_i1_h1;
    wire signed [POTENTIAL_WIDTH-1:0] weighted_h0_h1_inhib;
    
    // Weighted spike signals for Output
    wire signed [POTENTIAL_WIDTH-1:0] weighted_h0_o;
    wire signed [POTENTIAL_WIDTH-1:0] weighted_h1_o;
    wire signed [POTENTIAL_WIDTH-1:0] weighted_both_inhib;
    
    // Combined input currents
    wire signed [POTENTIAL_WIDTH:0] current_hidden_0;
    wire signed [POTENTIAL_WIDTH:0] current_hidden_1;
    wire signed [POTENTIAL_WIDTH:0] current_output;
    
    // Display network initialization
    initial begin
        $display("========================================================================");
        $display("[SNN_TERNARY] XOR Network with TERNARY WEIGHTS {-1, 0, +1}");
        $display("========================================================================");
        $display("[SNN_TERNARY] Network Topology: 2 Inputs -> 2 Hidden -> 1 Output");
        $display("[SNN_TERNARY] Neuron Parameters:");
        $display("[SNN_TERNARY]   THRESHOLD = %0d (optimized for ternary)", THRESHOLD);
        $display("[SNN_TERNARY]   LEAK = %0d (MUST be 0 for ternary!)", LEAK);
        $display("[SNN_TERNARY]   POTENTIAL_WIDTH = %0d bits", POTENTIAL_WIDTH);
        $display("[SNN_TERNARY] ");
        $display("[SNN_TERNARY] TERNARY WEIGHTS (constrained to {-1, 0, +1}):");
        $display("[SNN_TERNARY]   Input->Hidden:");
        $display("[SNN_TERNARY]     I0->H0: %+2d  |  I1->H0: %+2d", WEIGHT_I0_H0, WEIGHT_I1_H0);
        $display("[SNN_TERNARY]     I0->H1: %+2d  |  I1->H1: %+2d", WEIGHT_I0_H1, WEIGHT_I1_H1);
        $display("[SNN_TERNARY]   Hidden->Output:");
        $display("[SNN_TERNARY]     H0->O: %+2d  |  H1->O: %+2d", WEIGHT_H0_O, WEIGHT_H1_O);
        $display("[SNN_TERNARY]   Lateral Inhibition:");
        $display("[SNN_TERNARY]     H0->H1: %+2d  |  H1->H0: %+2d", WEIGHT_H0_H1, WEIGHT_H1_H0);
        $display("[SNN_TERNARY]   Direct Inhibition:");
        $display("[SNN_TERNARY]     Both_Active->Output: %+2d", WEIGHT_BOTH_INHIB);
        $display("[SNN_TERNARY] ");
        $display("[SNN_TERNARY] Key Insight: With weight=1 and leak=0:");
        $display("[SNN_TERNARY]   Net gain = +1 per spike (accumulates to threshold)");
        $display("[SNN_TERNARY]   If leak=1, net gain = 0 (would never fire!)");
        $display("========================================================================");
    end
    
    // =========================================================================
    // Weight Application Logic
    // =========================================================================
    
    // Inputs to Hidden 0
    assign weighted_i0_h0 = spike_in_0 ? WEIGHT_I0_H0 : 0;
    assign weighted_i1_h0 = spike_in_1 ? WEIGHT_I1_H0 : 0;
    assign weighted_h1_h0_inhib = spike_hidden_1 ? WEIGHT_H1_H0 : 0;
    assign current_hidden_0 = weighted_i0_h0 + weighted_i1_h0 + weighted_h1_h0_inhib;
    
    // Inputs to Hidden 1
    assign weighted_i0_h1 = spike_in_0 ? WEIGHT_I0_H1 : 0;
    assign weighted_i1_h1 = spike_in_1 ? WEIGHT_I1_H1 : 0;
    assign weighted_h0_h1_inhib = spike_hidden_0 ? WEIGHT_H0_H1 : 0;
    assign current_hidden_1 = weighted_i0_h1 + weighted_i1_h1 + weighted_h0_h1_inhib;
    
    // Inputs to Output
    assign weighted_h0_o = spike_hidden_0 ? WEIGHT_H0_O : 0;
    assign weighted_h1_o = spike_hidden_1 ? WEIGHT_H1_O : 0;
    // Direct inhibition when both switches active
    assign weighted_both_inhib = (switch_0 && switch_1) ? WEIGHT_BOTH_INHIB : 0;
    assign current_output = weighted_h0_o + weighted_h1_o + weighted_both_inhib;
    
    // =========================================================================
    // Neuron Instantiations
    // =========================================================================
    
    lif_neuron_weighted #(
        .WEIGHT(0),  // Weight handled externally
        .THRESHOLD(THRESHOLD),
        .LEAK(LEAK),
        .POTENTIAL_WIDTH(POTENTIAL_WIDTH)
    ) hidden_neuron_0 (
        .clk(clk),
        .rst_n(rst_n),
        .input_current(current_hidden_0),
        .spike_out(spike_hidden_0),
        .neuron_id(8'd0)
    );
    
    lif_neuron_weighted #(
        .WEIGHT(0),
        .THRESHOLD(THRESHOLD),
        .LEAK(LEAK),
        .POTENTIAL_WIDTH(POTENTIAL_WIDTH)
    ) hidden_neuron_1 (
        .clk(clk),
        .rst_n(rst_n),
        .input_current(current_hidden_1),
        .spike_out(spike_hidden_1),
        .neuron_id(8'd1)
    );
    
    lif_neuron_weighted #(
        .WEIGHT(0),
        .THRESHOLD(THRESHOLD),
        .LEAK(LEAK),
        .POTENTIAL_WIDTH(POTENTIAL_WIDTH)
    ) output_neuron (
        .clk(clk),
        .rst_n(rst_n),
        .input_current(current_output),
        .spike_out(spike_out),
        .neuron_id(8'd2)
    );
    
    // =========================================================================
    // Debug Monitoring
    // =========================================================================
    
    // Monitor hidden neuron firing
    always @(posedge clk) begin
        if (spike_hidden_0) begin
            $display("[%0t] [SNN_TERNARY] *** HIDDEN_0 FIRED! ***", $time);
        end
        if (spike_hidden_1) begin
            $display("[%0t] [SNN_TERNARY] *** HIDDEN_1 FIRED! ***", $time);
        end
    end
    
    // Monitor input spikes
    always @(posedge clk) begin
        if (spike_in_0 || spike_in_1) begin
            $display("[%0t] [SNN_TERNARY] Input Spikes: I0=%0d I1=%0d", $time, spike_in_0, spike_in_1);
        end
    end
    
    // Monitor output spikes
    always @(posedge clk) begin
        if (spike_out) begin
            $display("[%0t] [SNN_TERNARY] ======> OUTPUT SPIKE! <======", $time);
        end
    end
    
    // Monitor both-input inhibition
    always @(posedge clk) begin
        if (switch_0 && switch_1) begin
            $display("[%0t] [SNN_TERNARY] Both inputs active - direct inhibition enabled!", $time);
        end
    end

endmodule


// =============================================================================
// Module: lif_neuron_weighted
// Description: LIF neuron that accepts external current (for ternary weights)
// =============================================================================

module lif_neuron_weighted #(
    parameter signed WEIGHT = 0,               // Not used (for compatibility)
    parameter signed THRESHOLD = 3,            // Firing threshold
    parameter signed LEAK = 0,                 // Leak value per cycle
    parameter POTENTIAL_WIDTH = 8              // Bit width for membrane potential
)(
    input  wire clk,                           // Clock signal
    input  wire rst_n,                         // Active low reset
    input  wire signed [POTENTIAL_WIDTH:0] input_current,  // Pre-calculated current
    output reg  spike_out,                     // Output spike (1-cycle pulse)
    input  wire [7:0] neuron_id                // For debug messages
);

    // Internal membrane potential register
    reg signed [POTENTIAL_WIDTH-1:0] membrane_potential;
    
    // Temporary variable for next membrane potential
    reg signed [POTENTIAL_WIDTH:0] next_potential;
    
    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            membrane_potential <= {POTENTIAL_WIDTH{1'b0}};
            spike_out <= 1'b0;
            $display("[%0t] [NEURON_%0d] Reset", $time, neuron_id);
        end else begin
            // Calculate next potential
            next_potential = membrane_potential;
            
            // Add input current (already weighted externally)
            next_potential = next_potential + input_current;
            
            // Apply leak
            next_potential = next_potential - LEAK;
            
            // Check if threshold reached
            if (membrane_potential >= THRESHOLD) begin
                spike_out <= 1'b1;
                membrane_potential <= {POTENTIAL_WIDTH{1'b0}};
                $display("[%0t] [NEURON_%0d] FIRED! Potential was %0d, reset to 0", 
                         $time, neuron_id, membrane_potential);
            end else begin
                spike_out <= 1'b0;
                
                // Clamp to zero (no negative potentials)
                if (next_potential < 0) begin
                    membrane_potential <= {POTENTIAL_WIDTH{1'b0}};
                    $display("[%0t] [NEURON_%0d] Potential clamped: %0d -> 0 (input=%0d)", 
                             $time, neuron_id, next_potential, input_current);
                end else begin
                    // Show potential changes
                    if (membrane_potential != next_potential[POTENTIAL_WIDTH-1:0]) begin
                        $display("[%0t] [NEURON_%0d] V: %0d -> %0d (current=%0d)", 
                                 $time, neuron_id, membrane_potential, 
                                 next_potential[POTENTIAL_WIDTH-1:0], input_current);
                    end
                    membrane_potential <= next_potential[POTENTIAL_WIDTH-1:0];
                end
            end
        end
    end

endmodule
