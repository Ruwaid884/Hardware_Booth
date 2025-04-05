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
    reg [15:0] A;        // Accumulator
    reg [7:0] Q;         // Multiplier
    reg Q_1;             // Extra bit for Booth algorithm
    reg [7:0] M;         // Multiplicand
    reg [3:0] count;     // Counter for iterations
    
    // State machine states
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    
    // Power monitoring signals
    reg [7:0] power_estimate;
    
    // State machine
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            A <= 16'b0;
            Q <= 8'b0;
            Q_1 <= 1'b0;
            M <= 8'b0;
            count <= 4'b0;
            product <= 16'b0;
            done <= 1'b0;
            power_estimate <= 8'b0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        A <= 16'b0;         // Clear accumulator
                        M <= multiplicand;   // Load multiplicand
                        Q <= multiplier;     // Load multiplier
                        Q_1 <= 1'b0;        // Clear extra bit
                        count <= 4'b0;      // Clear counter
                        power_estimate <= 8'b0;
                    end
                end
                
                COMPUTE: begin
                    // Booth's algorithm
                    case ({Q[0], Q_1})
                        2'b01: begin    // Add multiplicand
                            A <= A + {{8{M[7]}}, M};
                            power_estimate <= power_estimate + 2;
                        end
                        2'b10: begin    // Subtract multiplicand
                            A <= A - {{8{M[7]}}, M};
                            power_estimate <= power_estimate + 2;
                        end
                        default: begin   // No operation needed
                            power_estimate <= power_estimate + 1;
                        end
                    endcase
                    
                    // Arithmetic right shift
                    A <= {A[15], A[15:1]};
                    Q_1 <= Q[0];
                    Q <= {A[0], Q[7:1]};
                    count <= count + 1;
                end
                
                DONE: begin
                    product <= {A[7:0], Q};
                    done <= 1'b1;
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
                if (count == 4'b0111) next_state = DONE;
            end
            DONE: begin
                next_state = IDLE;
            end
        endcase
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