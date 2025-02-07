// fma16.sv
// Troy Kaufman
// tkaufman@g.hmc.edu
// 2/6/25
/*
    Top level module that will implement power a optimized half precision FMA functional unit
*/

module fma16(input  logic           clk, reset, 
             input  logic [15:0]    x, y,
             input  logic [7:0]     ctrl, 
             input  logic           mul, add, negp, negz, 
             input  logic [1:0]     roundmode,
             output logic [15:0]    z,
             output logic [3:0]     flags);

// instantiate mul exp 0 module 


endmodule