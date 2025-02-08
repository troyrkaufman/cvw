// fma16.sv
// Troy Kaufman
// tkaufman@g.hmc.edu
// 2/6/25
/*
    Top level module that will implement power a optimized half precision FMA functional unit
    Acronyms to be aware of:
        - NV = iNValid opeation
        - OF = OverFlow 
        - UF = UnderFlow 
        - NX = iNeXact 
        - RZ = Round towards Zero
*/

module fma16(input logic  [15:0]    x, y, z, 
             input logic            mul, add, negp, negz, 
             input logic            roundmode, 
             output logic [15:0]    result, 
             output logic [3:0]     flags);

logic           sign;
logic [2:0]     exp;
logic [21:0]    mantproduct;
logic [9:0]     shiftfrac;
logic [15:0]    finalmant;

// perform multiplication between mantissas
assign mantproduct = {1'b1, x[9:0]} * {1'b1, y[9:0]};

// Adjust product to be 10 bits
assign shiftmant = mantproduct[21:12];

// eXclusive or signed bits
assign sign = x[15] ^ y[15];

// add exponents
assign exp = (x[14:10]-4'd15) + (y[14:10]-4'd15);

// finally multiply product of mantissas to sum of exponents
assign finalmant = shiftmant * (2**exp);

// bit swizzle parts together
assign result = {sign, exp, finalmant};
endmodule