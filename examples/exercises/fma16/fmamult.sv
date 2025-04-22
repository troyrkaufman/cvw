// fma_mul.sv
// Troy Kaufman
// tkaufman@g.hmc.edu
// 3/14/25
// Purpose: Half-precision floating point multiplication that works with normalized, positive, and signed values


module fmamult( input logic   [15:0]      x, y,
                input logic               negp,
                input logic   [1:0]       roundmode,
                output logic  [15:0]      product,
                output logic  [21:0]      fullPm);

    logic           sign;           // product's sign
    logic [4:0]     exp;            // product's exponent
    logic [21:0]    multMant;       // the factor's mantissa product
    logic [9:0]     shiftMant;      // extracts the proper upper bits from multMant
    logic           zeroInputFlag;  // flag that determines if either input is +/- 0

    // check if either X or Y are +- zero
    assign zeroInputFlag = ((x[14:0] == 15'h0) | (y[14:0] == 15'h0));

    // floating point multiplication
    always_comb begin : fpMult

        // multiply the mantissas with the implicit 1 as a prefix
        multMant = {1'b1, x[9:0]} * {1'b1, y[9:0]};
        
        // normalize mantissa product
        if (multMant[21] == 1)  begin shiftMant = multMant[20:11]; exp = (x[14:10] + y[14:10]) - 4'd15 + 1'd1; end
        else                    begin shiftMant = multMant[19:10]; exp = (x[14:10] + y[14:10]) - 4'd15; end 
        
        // calculate the number's sign
        sign = x[15] ^ y[15];

        // output product calculation
        product = (zeroInputFlag) ? 16'h0 : {sign, exp, shiftMant};
    end 

    // output the unaltered mantissa for addition and rounding purposes
    assign fullPm = multMant;
endmodule