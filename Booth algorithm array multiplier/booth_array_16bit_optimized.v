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
    wire [23:0] booth_sel;  // 8 groups of 3-bit selection signals
    reg [127:0] partial_products_flat;  // 8 groups of 16-bit products flattened
    reg [15:0] temp_product;  // Temporary register for partial product calculation

    // Easier access to individual partial products
    wire [15:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7;
    assign pp0 = partial_products_flat[15:0];
    assign pp1 = partial_products_flat[31:16];
    assign pp2 = partial_products_flat[47:32];
    assign pp3 = partial_products_flat[63:48];
    assign pp4 = partial_products_flat[79:64];
    assign pp5 = partial_products_flat[95:80];
    assign pp6 = partial_products_flat[111:96];
    assign pp7 = partial_products_flat[127:112];

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
                .sel(booth_sel[3*i+2:3*i])
            );
        end
    endgenerate

    // Generate partial products with power gating
    always @(*) begin
        if (power_gate) begin
            partial_products_flat = 128'b0;
        end else begin
            // Unrolled loop for partial products generation
            case (booth_sel[2:0])  // First partial product
                3'b000: temp_product = 16'b0;  // +0
                3'b001: temp_product = a;      // +1
                3'b010: temp_product = a << 1; // +2
                3'b011: temp_product = (a << 1) + a; // +3
                3'b100: temp_product = -(a << 1) - a; // -3
                3'b101: temp_product = -(a << 1); // -2
                3'b110: temp_product = -a;     // -1
                3'b111: temp_product = 16'b0;  // +0
                default: temp_product = 16'b0;
            endcase
            partial_products_flat[15:0] = temp_product;

            case (booth_sel[5:3])  // Second partial product
                3'b000: temp_product = 16'b0;
                3'b001: temp_product = a;
                3'b010: temp_product = a << 1;
                3'b011: temp_product = (a << 1) + a;
                3'b100: temp_product = -(a << 1) - a;
                3'b101: temp_product = -(a << 1);
                3'b110: temp_product = -a;
                3'b111: temp_product = 16'b0;
                default: temp_product = 16'b0;
            endcase
            partial_products_flat[31:16] = temp_product;

            case (booth_sel[8:6])  // Third partial product
                3'b000: temp_product = 16'b0;
                3'b001: temp_product = a;
                3'b010: temp_product = a << 1;
                3'b011: temp_product = (a << 1) + a;
                3'b100: temp_product = -(a << 1) - a;
                3'b101: temp_product = -(a << 1);
                3'b110: temp_product = -a;
                3'b111: temp_product = 16'b0;
                default: temp_product = 16'b0;
            endcase
            partial_products_flat[47:32] = temp_product;

            case (booth_sel[11:9])  // Fourth partial product
                3'b000: temp_product = 16'b0;
                3'b001: temp_product = a;
                3'b010: temp_product = a << 1;
                3'b011: temp_product = (a << 1) + a;
                3'b100: temp_product = -(a << 1) - a;
                3'b101: temp_product = -(a << 1);
                3'b110: temp_product = -a;
                3'b111: temp_product = 16'b0;
                default: temp_product = 16'b0;
            endcase
            partial_products_flat[63:48] = temp_product;

            case (booth_sel[14:12])  // Fifth partial product
                3'b000: temp_product = 16'b0;
                3'b001: temp_product = a;
                3'b010: temp_product = a << 1;
                3'b011: temp_product = (a << 1) + a;
                3'b100: temp_product = -(a << 1) - a;
                3'b101: temp_product = -(a << 1);
                3'b110: temp_product = -a;
                3'b111: temp_product = 16'b0;
                default: temp_product = 16'b0;
            endcase
            partial_products_flat[79:64] = temp_product;

            case (booth_sel[17:15])  // Sixth partial product
                3'b000: temp_product = 16'b0;
                3'b001: temp_product = a;
                3'b010: temp_product = a << 1;
                3'b011: temp_product = (a << 1) + a;
                3'b100: temp_product = -(a << 1) - a;
                3'b101: temp_product = -(a << 1);
                3'b110: temp_product = -a;
                3'b111: temp_product = 16'b0;
                default: temp_product = 16'b0;
            endcase
            partial_products_flat[95:80] = temp_product;

            case (booth_sel[20:18])  // Seventh partial product
                3'b000: temp_product = 16'b0;
                3'b001: temp_product = a;
                3'b010: temp_product = a << 1;
                3'b011: temp_product = (a << 1) + a;
                3'b100: temp_product = -(a << 1) - a;
                3'b101: temp_product = -(a << 1);
                3'b110: temp_product = -a;
                3'b111: temp_product = 16'b0;
                default: temp_product = 16'b0;
            endcase
            partial_products_flat[111:96] = temp_product;

            case (booth_sel[23:21])  // Eighth partial product
                3'b000: temp_product = 16'b0;
                3'b001: temp_product = a;
                3'b010: temp_product = a << 1;
                3'b011: temp_product = (a << 1) + a;
                3'b100: temp_product = -(a << 1) - a;
                3'b101: temp_product = -(a << 1);
                3'b110: temp_product = -a;
                3'b111: temp_product = 16'b0;
                default: temp_product = 16'b0;
            endcase
            partial_products_flat[127:112] = temp_product;
        end
    end

    // Wallace Tree reduction
    wire [31:0] wallace_out;
    wallace_tree wallace (
        .pp0(pp0),
        .pp1(pp1),
        .pp2(pp2),
        .pp3(pp3),
        .pp4(pp4),
        .pp5(pp5),
        .pp6(pp6),
        .pp7(pp7),
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
            default: sel = 3'b000;
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