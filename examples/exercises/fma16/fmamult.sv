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
    logic           checkExpFlag;   // check for an exponent overflow in a 5 bit number
    logic [5:0]     exp;            // product's exponent
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
        if (multMant[21] == 1)  begin shiftMant = multMant[20:11]; exp = ({1'b0,x[14:10]} + {1'b0,y[14:10]}) - 5'd15 + 5'd1; end
        else                    begin shiftMant = multMant[19:10]; exp = ({1'b0,x[14:10]} + {1'b0,y[14:10]}) - 5'd15; end

        // check if exp is greater than or equal to 'd31 
        checkExpFlag = (exp >= 'd31) ? '1 : '0; 
        
        // calculate the number's sign
        sign = x[15] ^ y[15];

        // output product calculation depending on if an overflow in the exponent occurs and/or the product is negative. Also check if the inputs were zero. 
        if (checkExpFlag&sign)          product = 16'hfc00;
        else if (checkExpFlag&~sign)    product = 16'h7c00;
        else if (zeroInputFlag)         product = 16'h0;
        else                            product = {sign, exp[4:0], shiftMant};
    end 

    // output the unaltered mantissa for addition and rounding purposes
    assign fullPm = multMant;
endmodule