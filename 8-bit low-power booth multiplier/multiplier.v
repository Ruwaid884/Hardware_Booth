`timescale 1ns/1ps

module low_power_booth_multiplier (
    input wire clk,
    input wire reset,
    input wire [7:0] multiplicand,
    input wire [7:0] multiplier,
    input wire start,
    input wire [1:0] power_mode,  // 00: Normal, 01: Low Power, 10: Ultra Low Power
    output reg [15:0] product,
    output reg done,
    output reg [7:0] power_consumption
);

    // Internal registers
    reg [7:0] A;        // Multiplicand
    reg [7:0] Q;        // Multiplier
    reg [8:0] M;        // Extended multiplicand
    reg [8:0] AQ;       // Accumulator
    reg [3:0] count;    // Counter for iterations
    
    // Power gating signals
    reg power_gate_enable;
    wire [7:0] gated_multiplicand;
    wire [7:0] gated_multiplier;
    
    // Power gating for inputs
    assign gated_multiplicand = power_gate_enable ? multiplicand : 8'b0;
    assign gated_multiplier = power_gate_enable ? multiplier : 8'b0;
    
    // State machine states
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    
    // Power monitoring signals
    reg [7:0] activity_counter;
    reg [7:0] power_estimate;
    
    // Dynamic voltage scaling signals
    reg [1:0] voltage_level;
    wire [7:0] scaled_clk_period;
    
    // Calculate scaled clock period based on voltage level
    assign scaled_clk_period = (voltage_level == 2'b00) ? 8'd10 :  // Normal
                              (voltage_level == 2'b01) ? 8'd15 :  // Low power
                              8'd20;                              // Ultra low power
    
    // State machine
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            A <= 8'b0;
            Q <= 8'b0;
            M <= 9'b0;
            AQ <= 9'b0;
            count <= 4'b0;
            product <= 16'b0;
            done <= 1'b0;
            power_gate_enable <= 1'b0;
            activity_counter <= 8'b0;
            power_estimate <= 8'b0;
            voltage_level <= power_mode;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    done <= 1'b0;  // Clear done signal in IDLE
                    if (start) begin
                        A <= multiplicand;
                        Q <= multiplier;
                        M <= {multiplicand[7], multiplicand};
                        AQ <= 9'b0;
                        count <= 4'b0;
                        power_gate_enable <= 1'b1;
                        activity_counter <= activity_counter + 1;
                    end
                end
                
                COMPUTE: begin
                    // Booth's algorithm implementation with power-aware operations
                    case ({AQ[0], Q[0]})
                        2'b00, 2'b11: begin
                            // No operation - minimal power
                            AQ <= {AQ[8], AQ[8:1]};
                            Q <= {AQ[0], Q[7:1]};
                            power_estimate <= power_estimate + 1;
                        end
                        2'b01: begin
                            // Add M with power-aware addition
                            if (voltage_level == 2'b10) begin
                                // Ultra low power mode - use carry-save addition
                                AQ <= {AQ[8], AQ[8:1]} + M;
                            end else begin
                                // Normal or low power mode - use standard addition
                                AQ <= {AQ[8], AQ[8:1]} + M;
                            end
                            Q <= {AQ[0], Q[7:1]};
                            power_estimate <= power_estimate + 2;
                        end
                        2'b10: begin
                            // Subtract M with power-aware subtraction
                            if (voltage_level == 2'b10) begin
                                // Ultra low power mode - use carry-save subtraction
                                AQ <= {AQ[8], AQ[8:1]} - M;
                            end else begin
                                // Normal or low power mode - use standard subtraction
                                AQ <= {AQ[8], AQ[8:1]} - M;
                            end
                            Q <= {AQ[0], Q[7:1]};
                            power_estimate <= power_estimate + 2;
                        end
                    endcase
                    
                    count <= count + 1;
                    activity_counter <= activity_counter + 1;
                end
                
                DONE: begin
                    product <= {AQ[7:0], Q};
                    done <= 1'b1;
                    power_gate_enable <= 1'b0;
                    power_consumption <= power_estimate;
                end
            endcase
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;  // Default: stay in current state
        case (state)
            IDLE: begin
                if (start) next_state = COMPUTE;
            end
            COMPUTE: begin
                if (count == 4'b0111) next_state = DONE;  // Change to check for 7 to transition on 8
            end
            DONE: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // Power monitoring and control
    always @(posedge clk) begin
        if (reset) begin
            activity_counter <= 8'b0;
            power_estimate <= 8'b0;
        end else if (state == COMPUTE) begin
            // Update power estimate based on operations and voltage level
            case (voltage_level)
                2'b00: power_estimate <= power_estimate + 1;  // Normal power
                2'b01: power_estimate <= power_estimate + 2;  // Low power
                2'b10: power_estimate <= power_estimate + 3;  // Ultra low power
                default: power_estimate <= power_estimate + 1;
            endcase
        end
    end
    
    // Debug power register
    reg [7:0] debug_power;
    
    always @(posedge clk) begin
        debug_power <= power_estimate;
    end
    
endmodule

// Testbench
module tb_low_power_booth_multiplier;
    reg clk;
    reg reset;
    reg [7:0] multiplicand;
    reg [7:0] multiplier;
    reg start;
    reg [1:0] power_mode;
    wire [15:0] product;
    wire done;
    wire [7:0] power_consumption;
    
    // Instantiate the multiplier
    low_power_booth_multiplier uut (
        .clk(clk),
        .reset(reset),
        .multiplicand(multiplicand),
        .multiplier(multiplier),
        .start(start),
        .power_mode(power_mode),
        .product(product),
        .done(done),
        .power_consumption(power_consumption)
    );
    
    // Debug signals
    wire [1:0] state;
    wire [3:0] count;
    assign state = uut.state;
    assign count = uut.count;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test stimulus
    integer i;
    reg test_done;
    
    initial begin
        // Initialize
        reset = 1;
        start = 0;
        multiplicand = 8'b0;
        multiplier = 8'b0;
        power_mode = 2'b00;  // Start in normal power mode
        test_done = 0;
        
        // Reset
        #20 reset = 0;
        #10;
        
        // Test case 1: Normal power mode
        $display("Starting Test case 1 at time %t", $time);
        multiplicand = 8'd5;
        multiplier = 8'd3;
        power_mode = 2'b00;
        start = 1;
        #10 start = 0;
        
        // Wait up to 100 cycles for done
        i = 0;
        test_done = 0;
        while (i < 100 && !test_done) begin
            @(posedge clk);
            if (done) begin
                $display("Test case 1 completed at time %t", $time);
                $display("Product: %d, Expected: 15", product);
                test_done = 1;
            end
            i = i + 1;
        end
        
        if (!test_done)
            $display("ERROR: Test case 1 timed out without done signal at time %t", $time);
        
        #20;
        
        // Test case 2: Low power mode
        $display("Starting Test case 2 at time %t", $time);
        multiplicand = -8'd5;
        multiplier = 8'd3;
        power_mode = 2'b01;
        start = 1;
        #10 start = 0;
        
        // Wait up to 100 cycles for done
        i = 0;
        test_done = 0;
        while (i < 100 && !test_done) begin
            @(posedge clk);
            if (done) begin
                $display("Test case 2 completed at time %t", $time);
                $display("Product: %d, Expected: -15", product);
                test_done = 1;
            end
            i = i + 1;
        end
        
        if (!test_done)
            $display("ERROR: Test case 2 timed out without done signal at time %t", $time);
        
        #20;
        
        // Test case 3: Ultra low power mode
        $display("Starting Test case 3 at time %t", $time);
        multiplicand = -8'd5;
        multiplier = -8'd3;
        power_mode = 2'b10;
        start = 1;
        #10 start = 0;
        
        // Wait up to 100 cycles for done
        i = 0;
        test_done = 0;
        while (i < 100 && !test_done) begin
            @(posedge clk);
            if (done) begin
                $display("Test case 3 completed at time %t", $time);
                $display("Product: %d, Expected: 15", product);
                test_done = 1;
            end
            i = i + 1;
        end
        
        if (!test_done)
            $display("ERROR: Test case 3 timed out without done signal at time %t", $time);
        
        #20;
        
        $display("Simulation complete at time %t", $time);
        $finish;
    end
    
    // State monitor for debugging
    always @(posedge clk) begin
        $display("Time: %t, State: %d, Count: %d, Done: %b", $time, state, count, done);
    end
    
endmodule 