// fma16.sv
// Troy Kaufman
// tkaufman@g.hmc.edu
// 2/6/25
/*
    Purpose: Half precision FMA functional unit that handles normalized, positive, and signed floating point numbers including
    special cases and rounding modes (RNE, RZ, RP, and RN)
*/

module fma16(input logic  [15:0]    x, y, z, 
             input logic            mul, add, negp, negz, 
             input logic  [1:0]     roundmode, 
             output logic [15:0]    result, 
             output logic [3:0]     flags);

    logic [15:0]    product;            // output from floating point multiplication module
    logic [15:0]    sum;                // output from floating point addition module
    logic [15:0]    flipZ;              // flip Z's sign if negz is asserted
    logic [15:0]    flipX;              // flip X's sign if negp is asserted
    logic           specialCaseFlag;    // determines if special case was carried out
    logic           roundFlag;          // determines if rounding was carried out
    logic [15:0]    specialResult;      // result from a special case
    logic [33:0]    fullSum;
    logic           nonZeroResults;
    logic           overFlowFlag;
    logic [15:0]    roundResult;
    logic [21:0]    fullPm;
    logic [1:0]     sigNum;
    logic           multOp;
    logic           addOp;
    logic           mulAddOp;

    assign multOp = (mul&~add) ? '1 : '0; 
    assign addOp  = (~mul&add) ? '1 : '0;
    assign mulAddOp = (mul&add) ? '1 : '0;

    always_comb begin : defineOperation
        if      (multOp)    begin flipX = negp ? {~x[15],x[14:0]} : x; flipZ = negz ? 16'h8000 : 16'h0000;   end
        else if (addOp)     begin flipX = negp ? 16'h8c00 : 16'h3c00;  flipZ = negz ? {~z[15],z[14:0]} : z;  end
        else if (mulAddOp)  begin flipX = negp ? {~x[15],x[14:0]} : x; flipZ = negz ? {~z[15],z[14:0]} : z;  end
        else                begin flipX = 16'h0; flipZ = 16'h0; end
    end

    // floating point multiplication module
    fmamult multunit(.x(flipX), .y(y), .negp(negp), .roundmode(roundmode),.product(product), .fullPm(fullPm));

    // floating point addition module
    fmaadd addunit(.product(product), .x(flipX), .y(y), .z(flipZ), .fullPm(fullPm), .mul(mul), .add(add), .sum(sum), .fullSum(fullSum), .sigNum(sigNum));

    // floating point special scenarios and flags module
    specialCases specCase(.x(flipX), .y(y), .z(flipZ), .product(product), .sum(sum), .nonZeroResults(nonZeroResults), .result(specialResult), .specialCaseFlag(specialCaseFlag), .overFlowFlag(overFlowFlag), .flags(flags));

    // floating point rounding module
    fmaround roundunit(.product(product), .z(flipZ), .sum(sum), .fullPm(fullPm), .fullSum(fullSum), .sigNum(sigNum), .overFlowFlag(overFlowFlag), .mul(mul), .add(add), .roundmode(roundmode), .roundResult(roundResult), .nonZeroResults(nonZeroResults), .roundFlag(roundFlag));

    // Choose which result to output based on special and rounding flags
    always_comb begin : finalResult
        if (specialCaseFlag)    result = specialResult;
        else if (roundFlag)     result = roundResult;
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

