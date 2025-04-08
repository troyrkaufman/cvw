// fma_mul.sv
// Troy Kaufman
// tkaufman@g.hmc.edu
// 3/14/25
/*
    Half precision floating point multiplication with positive and negative numbers with exponents that are nonzero and/or zero
*/

module fmamult( input logic   [15:0]      x, y,
                input logic               negp,
                input logic   [1:0]       roundmode,
                output logic              killProd,
                output logic  [15:0]      product,
                output logic  [3:0]       flags);

logic           tempSign;
logic           sign;
logic [4:0]     exp;
logic [21:0]    multmant;
logic [9:0]     shiftmant;
logic [15:0]    finalmant;

assign flags = 4'b0;

always_comb begin : fpMult
    // Multiply the mantissas with the implicit 1 as a prefix
    multmant = {1'b1, x[9:0]} * {1'b1, y[9:0]};
    
    // Normalize mantissa product
    if (multmant[21] == 1) 
        begin
            shiftmant = multmant[20:11];
            exp = (x[14:10] + y[14:10]) - 4'd15 + 1'd1;
        end
    else 
        begin
            shiftmant = multmant[19:10];
            exp = (x[14:10] + y[14:10]) - 4'd15;
        end 
    
    // Calculate the number's sign
    tempSign = x[15] ^ y[15];
    sign = negp ? ~tempSign : tempSign;
    
    // bit swizzle the components together
    product = {sign, exp, shiftmant};

    assign killProd = ({exp, shiftmant} == '0) ? '1 : '0;
end 
endmodule