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
                output logic  [15:0]      product,
                output logic  [3:0]       flags);

logic           tempSign;
logic           sign;
logic [4:0]     exp;
logic [21:0]    multmant;
logic [9:0]     shiftmant;
logic [15:0]    finalmant;
logic [14:0]    zeroInput;
logic           zeroInputFlag;

logic [4:0] signedExp;
logic       prodUFFlag;

// assign zeroP = 'h0000;
// assign zeroN = 'h8000;
assign zeroInput = 15'h0000;

assign zeroInputFlag = ((x[14:0] == zeroInput) | (y[14:0] == zeroInput));

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
    sign = x[15] ^ y[15];

    //signedExp = $signed(exp);
   
    // bit swizzle the components together
    //product = {sign, exp, shiftmant};
    product = (zeroInputFlag) ? 16'h0 : {sign, exp, shiftmant};
end 
    //assign signedExp = $signed(exp);
    //assign productUnderflowFlag = (signedExp <= 0) ? 'b1 : 'b0;
endmodule





    //tempSign = x[15] ^ y[15];
    //tempSign = negp ? ~x[15] : x[15];
    //sign = tempSign ^ y[15];
    //sign = negp ? tempSign : ~tempSign;