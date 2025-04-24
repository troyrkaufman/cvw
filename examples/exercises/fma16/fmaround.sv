// Troy Kaufman
// tkaufman@g.hmc.edu
// 4/16/2025
// Purpose: Half precision floating point rounding module
// RNE: 'b01 RP: 'b11 RN: 'b01 RZ: 'b00

module fmaround(input logic     [15:0]  product, z, sum,
                input logic     [21:0]  fullPm,
                input logic     [33:0]  fullSum,
                input logic     [1:0]   nSigFlag,
                input logic             overFlowFlag, multOp, addOp, 
                input logic     [1:0]   roundMode,
                output logic    [15:0]  roundResult,
                output logic            nonZeroMantFlag, roundFlag);

    logic           sign;           // sum's sign since it is used so often
    logic           lsb;            // the unit in last place: ULP
    logic           guard;          // guard bit directly to the right of the lsb
    logic           rnd;            // round bit directly to the right of the guard bit 
    logic           sticky;         // the bitwise OR of the remaining bits right of the rnd bit
    logic           lsbPrime;       // the lsb bit
    logic           rndPrime;       // the guard bit
    logic           stickyPrime;    // bitwise OR between the rnd and sticky bits
    logic [14:0]    maxNum;         // the maximum number in half precision fp representation
    logic [15:0]    infP;           // positive infinity value
    logic [15:0]    infN;           // negative infinity value
    logic [15:0]    zeroP;          // positive zero
	logic [15:0]    zeroN;          // negative zero

    // general assignments for values that show up throughout the program
    assign zeroP = 'h0000;
	assign zeroN = 'h8000;
    assign maxNum = 'h7bff;
    assign infP = 'h7c00;
    assign infN = 'hfc00;
    assign sign = sum[15];

    // Important bits located in sum's full 34 bit mantissa for rounding logic
    assign lsb = fullSum[23];
    assign guard = fullSum[22];
    assign rnd = fullSum[21];
    assign sticky = |fullSum[20:0];
    assign lsbPrime = lsb;
    assign rndPrime = guard;
    assign stickyPrime = rnd | sticky;
        
    // major rounding algorithm
    always_comb begin : rounding
    // RNE rounding (currently has sign and inf vs NaN issues)
        if (roundMode == 2'b01)
            // if overflow and sign bit are set make the fma output negative infinity 
            if (overFlowFlag & sign)
                begin roundResult = infN; roundFlag = '1; end
            // if overflow and ~sign bit are set make the fma output positive infinity
            else if (overFlowFlag & ~sign)
                begin roundResult = infP; roundFlag = '1; end
            // if there was an insignificant summation while the addends weren't variations of zero make the fma output the sum
            else if((nSigFlag==2'b10|nSigFlag==2'b01)&(z!=zeroN&z!=zeroP))
                begin roundResult = sum; roundFlag = '1; end
            // if R'&(L'|T') then add 1 to the sum
            else if (rndPrime & (lsbPrime | stickyPrime))
                begin roundResult = {sign, sum[14:0] + 15'd1}; roundFlag = '1; end
            // else make the fma choose a different output that doesn't involve rounding
            else    
                begin roundResult = sum; roundFlag = '0; end
    // RZ rounding (currently has rounding down issues so fma_2 is failing)
        else if (roundMode == 2'b00) 
            // if overflow and sign bit are set make the fma output the negative maximum number
            if (overFlowFlag & sign) 
                begin roundResult = {sign, maxNum}; roundFlag = '1; end
            // if overflow and ~sign bit are set make the fma output positive infinity
            else if (overFlowFlag & ~sign)
                begin roundResult = infP; roundFlag = '1; end
            // checks if an insignificant addend will contribute to rounding the product down when the sum's mantissa is all nonzero. Outputs the appropriate result accordingly
            else if ((product[15]^z[15])&(nSigFlag==2'b10|nSigFlag==2'b01)&(fullSum[22:0]!==0)&(z[15])&(z!=zeroN&z!=zeroP)) begin roundResult = {sign, (sum[14:0] - 15'b1)}; roundFlag = '1; end
            else 
            // else make the fma choose a different output that doesn't involve rounding
            begin roundResult = 'h0; roundFlag = 0; end
    // RP rounding (currently has sign and rounding issues)
        else if (roundMode == 2'b11) 
            // if overflow and sign bit are set make the fma output the negative maximum number
            if (overFlowFlag & sign)
                begin roundResult = {sign, maxNum}; roundFlag = '1; end
            // if overflow and ~sign bit are set make the fma output the positive infinity
            else if (overFlowFlag & ~sign)
                begin roundResult = infP; roundFlag = '1; end
            // checks for if an insignificant addend will contribute to rounding the product down when the product's mantissa is all zeros. 
            // appropriate result accordingly
            else if ((product[15]^z[15])&(nSigFlag==2'b10|nSigFlag==2'b01)&(fullPm[9:0] == 10'b0)&(z!=zeroN&z!=zeroP))  
                if (~sign)  begin roundResult = sum; roundFlag = '0; end
                else begin roundResult = {sign, (sum[14:0] - 15'b1)}; roundFlag = '1;end
            // if there's no overflow flag, the sum is positive and the product is non zero then we choose to add 1 to either the sum or product based 
            // on the operation. else we let the fma choose a different output that doesn't involve rounding
            else if (~overFlowFlag & ~sign & (product!=zeroN&product!=zeroP))
                if ((rndPrime | stickyPrime) & addOp|(~multOp&~addOp))
                    begin roundResult = {sign, sum[14:0] + 15'd1}; roundFlag = '1; end
                else if ((rndPrime | stickyPrime) & multOp)
                    begin roundResult = {sign, product[14:0] + 15'd1}; roundFlag = '1; end
                else 
                    begin roundResult = sum; roundFlag = '0; end
            else
                begin roundResult = sum; roundFlag = '0; end
    // RN rounding (currently has sign and rounding issues)
        else if (roundMode == 2'b10)
            // if overflow and sign bit are set make the fma output the negative infinity
            if (overFlowFlag & sign)
                begin roundResult = infN; roundFlag = '1; end
            // if overflow and ~sign bit are set make the fma output the positive maxinum number
            else if (overFlowFlag & ~sign)
                begin roundResult = {sign, maxNum}; roundFlag = '1; end
            // checks for if an insignificant addend will contribute to rounding the product down when the product's mantissa is all zeros. The nested if statement 
            // depends on the sum's sign and will either keep sum as the output or subtract 1 from it
            else if ((product[15]^z[15])&(nSigFlag==2'b10|nSigFlag==2'b01)&(fullPm[9:0] == 10'b0)&(z!=zeroN&z!=zeroP))  
                if (sign)  begin roundResult = sum; roundFlag = '0; end
                else begin roundResult = {sign, (sum[14:0] - 15'b1)}; roundFlag = '1;end
            // if there is no overflow flag and sum is negative then round the result up if there are nonzero bits in sum's full mantissa (excluding the guard bit)
            // else we let the fma choose a different output that doesn't involve rounding
            else if (~overFlowFlag & sign)
                if (rndPrime | stickyPrime)
                    begin roundResult = {sign, sum[14:0] + 15'd1}; roundFlag = '1; end
                else 
                    begin roundResult = sum; roundFlag = '0; end
            else
                begin roundResult = sum; roundFlag = '0; end
        else 
            begin roundResult = sum; roundFlag = '0; end
    end

    // output if there are nonzero bits in sum's full mantissa. This is useful for handling special cases. 
    assign nonZeroMantFlag = rndPrime | stickyPrime; 
endmodule