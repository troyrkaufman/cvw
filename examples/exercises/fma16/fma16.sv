// fma16.sv
// Troy Kaufman
// tkaufman@g.hmc.edu
// 2/6/25
/*
    Half precision floating point multiplication with positive numbers and 
    exponents of 0
*/

module fma16(input logic  [15:0]    x, y, z, 
             input logic            mul, add, negp, negz, 
             input logic  [1:0]     roundmode, 
             output logic [15:0]    result, 
             output logic [3:0]     flags);

    logic [15:0] product;       // output from floating point mult module
    logic [15:0] sum;

    // floating point multiplication
    fmamult multunit(.x(x), .y(y), .roundmode(roundmode), .product(product), .flags(flags));

    // floating point addition
    fmaadd addunit(.product(product), .x(x), .y(y), .z(z), .sum(sum));

    assign result = sum;
    
    // //For debugging. X2GO is too slow to debug with
    // $display("X: %b", x[14:10]);
    // $display("Y: %b", y[14:10]);
    // $display("Multmant: %b ", multmant);
    // $display("Shiftmant: %b ", shiftmant);
    // $display("exp: %b ", exp);
    // $display("Result: %b ", result);
//end
endmodule



















/////////////////////////////////////
// Original code for floating point multiplication
// logic           sign;
// logic [4:0]     exp;
// logic [21:0]    multmant;
// logic [9:0]     shiftmant;
// logic [15:0]    finalmant;

//assign flags = 4'b0;

// Instantiate the multiply module
// Create addition module
/*
always_comb begin : fma16
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
    
    // bit swizzle the components together
    result = {sign, exp, shiftmant};
*/