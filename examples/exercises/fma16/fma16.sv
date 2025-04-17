// fma16.sv
// Troy Kaufman
// tkaufman@g.hmc.edu
// 2/6/25
/*
    Half precision fused multiply accumulate functional unit
*/

module fma16(input logic  [15:0]    x, y, z, 
             input logic            mul, add, negp, negz, 
             input logic  [1:0]     roundmode, 
             output logic [15:0]    result, 
             output logic [3:0]     flags);

    logic [15:0]    product;            // output from floating point mult module
    logic [15:0]    sum;
    logic [15:0]    flipZ;
    logic [15:0]    flipX;
    logic           flipZs;
    logic           specialCaseFlag;    // determines if special case was carried out
    logic [15:0]    specialResult;      // result from a special case

    assign flipZ = negz ? {~z[15],z[14:0]} : z; // something wrong as usual with signage
    assign flipX = negp ? {~x[15],x[14:0]} : x; // something wrong as usual with signage

    // floating point multiplication
    fmamult multunit(.x(flipX), .y(y), .negp(negp), .roundmode(roundmode),.product(product), .flags(flags));

    // floating point addition 
    fmaadd addunit(.product(product), .x(flipX), .y(y), .z(flipZ), .mul(mul), .add(add), .sum(sum));

    // special scenarios where there interesting I/O to and out of the FMA algorithm are handled here
    specialCases specCase(.x(flipX), .y(y), .z(flipZ), .product(product), .sum(sum), .result(specialResult), .specialCaseFlag(specialCaseFlag));

    assign result = specialCaseFlag ? specialResult : sum;  
endmodule


    //assign flipZ = negz ? {~z[15],z[14:0]} : z; // check with corey...very weird inverted logic]

    //assign flipZs = negz ? ~z[15] : z[15];

    //assign flipZ = negz ? z : {~z[15],z[14:0]}; //<- This works for when negz is asserted...very odd
    //assign flipZ = {flipZs, z[14:0]};
















 // //For debugging. X2GO is too slow to debug with
    // $display("X: %b", x[14:10]);
    // $display("Y: %b", y[14:10]);
    // $display("Multmant: %b ", multmant);
    // $display("Shiftmant: %b ", shiftmant);
    // $display("exp: %b ", exp);
    // $display("Result: %b ", result);
//end

