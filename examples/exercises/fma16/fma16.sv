// fma16.sv
// Troy Kaufman
// tkaufman@g.hmc.edu
// 2/6/25
/*
    Top level module that will implement a power optimized half precision FMA functional unit
    Acronyms to be aware of:
        - NV = iNValid opeation
        - OF = OverFlow 
        - UF = UnderFlow 
        - NX = iNeXact 
        - RZ = Round towards Zero
*/

module fma16(input logic  [15:0]    x, y, z, 
             input logic            mul, add, negp, negz, 
             input logic  [1:0]          roundmode, 
             output logic [15:0]    result, 
             output logic [3:0]     flags);

logic           sign;
logic [4:0]     exp;
logic [19:0]    multmant;
logic [9:0]     shiftmant;
logic [15:0]    finalmant;

assign flags = 4'b0;

always_comb begin : fma16
    multmant = {1'b1, x[9:0]} * {1'b1, y[9:0]};
    
    shiftmant = multmant[19:10];
    
    sign = x[15] ^ y[15];
    
    exp = (x[14:10] + y[14:10]) - 4'd15;
    
    result = {sign, exp, shiftmant};

    $display("X: %b", x[14:10]);
    $display("Y: %b", y[14:10]);
    $display("Multmant: %b ", multmant);
    $display("Shiftmant: %b ", shiftmant);
    $display("exp: %b ", exp);
    $display("Result: %b ", result);
end
endmodule