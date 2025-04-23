// fma16.sv
// Troy Kaufman
// tkaufman@g.hmc.edu
// 2/6/25
// Purpose: Half precision FMA functional unit that handles normalized, positive, and signed floating point numbers including
// special cases and rounding modes (RNE, RZ, RP, and RN)

module fma16(input logic  [15:0]    x, y, z, 
             input logic            mul, add, negp, negz, 
             input logic  [1:0]     roundmode, 
             output logic [15:0]    result, 
             output logic [3:0]     flags);

    logic [15:0]    product;            // output from floating point multiplication module
    logic [15:0]    sum;                // output from floating point addition module
    logic [15:0]    flipZ;              // flip Z's sign if negz is asserted
    logic [15:0]    flipY;              // sets the value of Y to either the input Y or a hard coded value
    logic [15:0]    flipX;              // flip X's sign if negp is asserted
    logic           specialCaseFlag;    // determines if special case was carried out
    logic           roundFlag;          // determines if rounding was carried out
    logic [15:0]    specialResult;      // result from a special case
    logic [33:0]    fullSum;            // properly normalized sum to be used in the rounding logic
    logic           nonZeroMantFlag;    // determines if there are 1s in the round or sticky bits of fullSum
    logic           overFlowFlag;       // determines if an overflow has occured
    logic [15:0]    roundResult;        // output from the floating point rounding module
    logic [21:0]    fullPm;             // the unaltered product mantissa
    logic [1:0]     nSigFlag;           // determines if either the product or Z are insignificant when it comes to the sum 
    logic           multOp;             // multiplication operation authorized
    logic           addOp;              // addition operation authorized
    logic           mulAddOp;           // fma operation authorized

    // identify which operation is authorized
    assign multOp = (mul&~add) ? '1 : '0; 
    assign addOp  = (~mul&add) ? '1 : '0;
    assign mulAddOp = (mul&add) ? '1 : '0;

    // identify which inputs are hard coded to values and/or have their signs flipped based on the operation
    always_comb begin : defineOperation
        if      (multOp)    begin flipX = negp ? {~x[15],x[14:0]} : x; flipY = y;       flipZ = negz ? 16'h8000 : 16'h0000;   end
        else if (addOp)     begin flipX = negp ? {~x[15],x[14:0]} : x;  flipY = 16'h3c00;   flipZ = negz ? {~z[15],z[14:0]} : z;  end
        else if (mulAddOp)  begin flipX = negp ? {~x[15],x[14:0]} : x; flipY = y;       flipZ = negz ? {~z[15],z[14:0]} : z;  end
        else                begin flipX = 16'h0; flipY = y; flipZ = 16'h0; end
    end

    // floating point multiplication module
    fmamult multunit(.x(flipX), .y(flipY), .negp(negp), .roundmode(roundmode),.product(product), .fullPm(fullPm));

    // floating point addition module
    fmaadd addunit(.product(product), .x(flipX), .y(flipY), .z(flipZ), .fullPm(fullPm), .mul(mul), .add(add), .sum(sum), .fullSum(fullSum), .nSigFlag(nSigFlag));

    // floating point special scenarios and flags module
    specialCases specCase(.x(flipX), .y(flipY), .z(flipZ), .product(product), .sum(sum), .nonZeroMantFlag(nonZeroMantFlag), .result(specialResult), .specialCaseFlag(specialCaseFlag), .overFlowFlag(overFlowFlag), .flags(flags));

    // floating point rounding module
    fmaround roundunit(.product(product), .z(flipZ), .sum(sum), .fullPm(fullPm), .fullSum(fullSum), .nSigFlag(nSigFlag), .overFlowFlag(overFlowFlag), .multOp(multOp), .addOp(addOp), .roundmode(roundmode), .roundResult(roundResult), .nonZeroMantFlag(nonZeroMantFlag), .roundFlag(roundFlag));

    // Choose which result to output based on special, operation, and rounding flags
    always_comb begin : finalResult
        if (specialCaseFlag)    result = specialResult;
        else if (roundFlag)     result = roundResult;
        else if (multOp)        result = product;
        else if (addOp)         result = sum;
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

