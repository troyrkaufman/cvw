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
    logic           takeRound;
    logic [15:0]    specialResult;      // result from a special case
    logic [33:0]    fullSum;
    logic           nonZeroResults;
    logic           overFlowFlag;
    logic [15:0]    roundedResult;
    logic [21:0]    fullPm;
    logic [1:0]     sigNum;


    assign flipZ = negz ? {~z[15],z[14:0]} : z; // something wrong as usual with signage
    assign flipX = negp ? {~x[15],x[14:0]} : x; // something wrong as usual with signage

    // floating point multiplication
    fmamult multunit(.x(flipX), .y(y), .negp(negp), .roundmode(roundmode),.product(product), .fullPm(fullPm));

    // floating point addition 
    fmaadd addunit(.product(product), .x(flipX), .y(y), .z(flipZ), .fullPm(fullPm), .mul(mul), .add(add), .sum(sum), .fullSum(fullSum), .sigNum(sigNum));

    // floating point special scenarios and flags
    specialCases specCase(.x(flipX), .y(y), .z(flipZ), .product(product), .sum(sum), .nonZeroResults(nonZeroResults), .result(specialResult), .specialCaseFlag(specialCaseFlag), .overFlowFlag(overFlowFlag), .flags(flags));

    // floating point rounding
    fmaround roundunit(.product(product), .z(flipZ), .sum(sum), .fullPm(fullPm), .fullSum(fullSum), .sigNum(sigNum), .overFlowFlag(overFlowFlag), .mul(mul), .add(add), .roundmode(roundmode), .rndFloat(roundedResult), .nonZeroResults(nonZeroResults), .takeRound(takeRound));

    //assign result = specialCaseFlag ? specialResult : sum;  

    always_comb begin : finalResult
        if (specialCaseFlag)    result = specialResult;
        else if (takeRound)     result = roundedResult;
        else                    result = sum;
    end
endmodule



















 // //For debugging. X2GO is too slow to debug with
    // $display("X: %b", x[14:10]);
    // $display("Y: %b", y[14:10]);
    // $display("Multmant: %b ", multmant);
    // $display("Shiftmant: %b ", shiftmant);
    // $display("exp: %b ", exp);
    // $display("Result: %b ", result);
//end

