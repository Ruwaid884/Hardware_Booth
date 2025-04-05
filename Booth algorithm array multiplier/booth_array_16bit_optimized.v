// Power-optimized 16-bit Booth Multiplier with Modified Booth Encoding
// Features:
// 1. Radix-4 Modified Booth Encoding (MBE)
// 2. Wallace Tree partial product reduction
// 3. Clock and power gating
// 4. Zero-detection optimization
// 5. Optional pipelining

`timescale 1ns/10ps

module booth_array_16bit_optimized (
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [15:0] a,
    input wire [15:0] b,
    input wire pipeline_en,  // Enable pipelining
    output reg [31:0] prod,
    output wire power_saved  // Indicates when power saving is active
);

    // Power gating control
    wire power_gate;
    assign power_gate = (a == 16'b0 || b == 16'b0);
    assign power_saved = power_gate;

    // Modified Booth Encoding signals
    reg [16:0] booth_b;  // Extended by 1 bit
    wire [7:0][2:0] booth_sel;  // Booth selection signals
    reg [7:0][15:0] partial_products;  // 8 partial products instead of 16

    // Pipeline registers
    reg [15:0] a_pipe, b_pipe;
    reg [31:0] inter_result;
    
    // Clock gating cell
    wire gated_clk;
    clock_gating_cell clock_gate (
        .clk(clk),
        .enable(enable & ~power_gate),
        .gated_clk(gated_clk)
    );

    // Modified Booth Encoding
    always @(*) begin
        booth_b = {b[15:0], 1'b0};  // Extend with 0
    end

    // Generate Booth selection signals
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : BOOTH_SEL_GEN
            booth_encoder booth_enc (
                .bits({booth_b[2*i+2], booth_b[2*i+1], booth_b[2*i]}),
                .sel(booth_sel[i])
            );
        end
    endgenerate

    // Generate partial products with power gating
    integer j;
    always @(*) begin
        if (power_gate) begin
            for (j = 0; j < 8; j = j + 1)
                partial_products[j] = 16'b0;
        end else begin
            for (j = 0; j < 8; j = j + 1) begin
                case (booth_sel[j])
                    3'b000: partial_products[j] = 16'b0;  // +0
                    3'b001: partial_products[j] = a;      // +1
                    3'b010: partial_products[j] = a << 1; // +2
                    3'b011: partial_products[j] = (a << 1) + a; // +3
                    3'b100: partial_products[j] = -(a << 1) - a; // -3
                    3'b101: partial_products[j] = -(a << 1); // -2
                    3'b110: partial_products[j] = -a;     // -1
                    3'b111: partial_products[j] = 16'b0;  // +0
                endcase
            end
        end
    end

    // Wallace Tree reduction
    wire [31:0] wallace_out;
    wallace_tree wallace (
        .pp0(partial_products[0]),
        .pp1(partial_products[1]),
        .pp2(partial_products[2]),
        .pp3(partial_products[3]),
        .pp4(partial_products[4]),
        .pp5(partial_products[5]),
        .pp6(partial_products[6]),
        .pp7(partial_products[7]),
        .sum(wallace_out)
    );

    // Pipeline stages
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            a_pipe <= 16'b0;
            b_pipe <= 16'b0;
            inter_result <= 32'b0;
            prod <= 32'b0;
        end else if (pipeline_en) begin
            // Pipeline stage 1
            a_pipe <= a;
            b_pipe <= b;
            // Pipeline stage 2
            inter_result <= wallace_out;
            // Pipeline stage 3
            prod <= inter_result;
        end else begin
            prod <= wallace_out;
        end
    end

endmodule

// Clock gating cell
module clock_gating_cell (
    input wire clk,
    input wire enable,
    output wire gated_clk
);
    reg enable_latch;
    
    always @(*) begin
        if (!clk)
            enable_latch <= enable;
    end
    
    assign gated_clk = clk & enable_latch;
endmodule

// Modified Booth Encoder
module booth_encoder (
    input wire [2:0] bits,
    output reg [2:0] sel
);
    always @(*) begin
        case (bits)
            3'b000: sel = 3'b000;  // 0
            3'b001: sel = 3'b001;  // +1
            3'b010: sel = 3'b001;  // +1
            3'b011: sel = 3'b010;  // +2
            3'b100: sel = 3'b101;  // -2
            3'b101: sel = 3'b110;  // -1
            3'b110: sel = 3'b110;  // -1
            3'b111: sel = 3'b000;  // 0
        endcase
    end
endmodule

// Wallace Tree for partial product reduction
module wallace_tree (
    input wire [15:0] pp0,
    input wire [15:0] pp1,
    input wire [15:0] pp2,
    input wire [15:0] pp3,
    input wire [15:0] pp4,
    input wire [15:0] pp5,
    input wire [15:0] pp6,
    input wire [15:0] pp7,
    output wire [31:0] sum
);
    // Level 1: Reduce 8 partial products to 6
    wire [31:0] l1_sum [5:0];
    wallace_csa #(32) csa_l1_1 (
        .a({16'b0, pp0}),
        .b({15'b0, pp1, 1'b0}),
        .c({14'b0, pp2, 2'b0}),
        .sum(l1_sum[0]),
        .carry(l1_sum[1])
    );
    
    wallace_csa #(32) csa_l1_2 (
        .a({13'b0, pp3, 3'b0}),
        .b({12'b0, pp4, 4'b0}),
        .c({11'b0, pp5, 5'b0}),
        .sum(l1_sum[2]),
        .carry(l1_sum[3])
    );
    
    assign l1_sum[4] = {10'b0, pp6, 6'b0};
    assign l1_sum[5] = {9'b0, pp7, 7'b0};

    // Level 2: Reduce 6 operands to 4
    wire [31:0] l2_sum [3:0];
    wallace_csa #(32) csa_l2_1 (
        .a(l1_sum[0]),
        .b(l1_sum[1]),
        .c(l1_sum[2]),
        .sum(l2_sum[0]),
        .carry(l2_sum[1])
    );
    
    wallace_csa #(32) csa_l2_2 (
        .a(l1_sum[3]),
        .b(l1_sum[4]),
        .c(l1_sum[5]),
        .sum(l2_sum[2]),
        .carry(l2_sum[3])
    );

    // Level 3: Final reduction to 2 operands
    wire [31:0] final_sum, final_carry;
    wallace_csa #(32) csa_final (
        .a(l2_sum[0]),
        .b(l2_sum[1]),
        .c(l2_sum[2]),
        .sum(final_sum),
        .carry(final_carry)
    );

    // Final addition
    assign sum = final_sum + {final_carry[30:0], 1'b0};
endmodule

// Carry-Save Adder for Wallace Tree
module wallace_csa #(
    parameter WIDTH = 32
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire [WIDTH-1:0] c,
    output wire [WIDTH-1:0] sum,
    output wire [WIDTH-1:0] carry
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : CSA_CELL
            assign sum[i] = a[i] ^ b[i] ^ c[i];
            assign carry[i] = (a[i] & b[i]) | (b[i] & c[i]) | (c[i] & a[i]);
        end
    endgenerate
endmodule 