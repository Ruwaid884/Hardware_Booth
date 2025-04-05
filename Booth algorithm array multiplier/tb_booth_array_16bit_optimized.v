`timescale 1ns/10ps

module tb_booth_array_16bit_optimized();
    reg clk;
    reg rst_n;
    reg enable;
    reg [15:0] a, b;
    reg pipeline_en;
    wire [31:0] prod;
    wire power_saved;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Instantiate the optimized multiplier
    booth_array_16bit_optimized uut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .a(a),
        .b(b),
        .pipeline_en(pipeline_en),
        .prod(prod),
        .power_saved(power_saved)
    );

    // Test stimulus
    initial begin
        // Initialize waveform dump
        $dumpfile("booth_array_16bit_optimized.vcd");
        $dumpvars(0, tb_booth_array_16bit_optimized);
        
        // Initialize signals
        rst_n = 0;
        enable = 0;
        pipeline_en = 0;
        a = 16'h0000;
        b = 16'h0000;
        
        // Release reset
        #20 rst_n = 1;
        enable = 1;
        
        // Test Case 1: Normal multiplication (no power saving)
        #20;
        a = 16'd1234;
        b = 16'd5678;
        #20;
        
        // Test Case 2: Zero multiplication (should trigger power gating)
        a = 16'd0;
        b = 16'd5678;
        #20;
        
        // Test Case 3: Another zero case
        a = 16'd1234;
        b = 16'd0;
        #20;
        
        // Test Case 4: Negative numbers
        a = -16'd3333;
        b = 16'd4444;
        #20;
        
        // Test Case 5: Both negative
        a = -16'd2222;
        b = -16'd3333;
        #20;
        
        // Test Case 6: Maximum values
        a = 16'h7FFF;
        b = 16'h7FFF;
        #20;
        
        // Test pipelined operation
        pipeline_en = 1;
        
        // Test Case 7: Pipeline test
        a = 16'd1111;
        b = 16'd2222;
        #20;
        a = 16'd3333;
        b = 16'd4444;
        #20;
        a = 16'd5555;
        b = 16'd6666;
        #20;
        
        // Disable pipeline
        pipeline_en = 0;
        
        // Test Case 8: Power gating with pipeline disabled
        a = 16'd0;
        b = 16'd9999;
        #20;
        
        // End simulation
        #20 $finish;
    end
    
    // Monitor results
    initial begin
        $monitor("Time=%0t rst_n=%b enable=%b pipeline_en=%b a=%d b=%d prod=%d power_saved=%b",
                 $time, rst_n, enable, pipeline_en, $signed(a), $signed(b), $signed(prod), power_saved);
    end

endmodule 