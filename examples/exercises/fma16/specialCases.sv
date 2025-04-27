 // specialCases.sv
 // Troy Kaufman
 // tkaufman@g.hmc.edu
 // 4/13/25
 // Purpose: Half Precision floating point module that handles special cases and flags

 module specialCases(	input logic 	[15:0] 	x, y, z, product, sum,
                      	input logic 			nonZeroMantFlag,
                		output logic 	[15:0] 	result,
                		output logic        	specialCaseFlag, overFlowFlag,
						output logic 	[3:0]	flags);

   	logic [15:0]   infP;           	// positive infinity value
	logic [15:0]   infN;           	// negative infinity value
	logic [15:0]   zeroP;          	// positive zero
	logic [15:0]   zeroN;          	// negative zero
	logic [15:0]   NaN;            	// NaN value

	logic          oFFlag;			// overflow flag
	logic          inXFlag;			// inexact flag
	logic          inVFlag;			// invalid flag

	logic          checkXNaN;      	// checks if X is NaN
	logic          checkYNaN;     	// checks if Y is NaN
	logic          checkZNaN;      	// checks if Z is NaN
	logic          anyNaN;          // checks if any inputs are NaN

	// check if any input is NaN
	assign checkXNaN = (x[14:10] == 5'h1f) & (x[9:0] != 10'h000);
	assign checkYNaN = (y[14:10] == 5'h1f) & (y[9:0] != 10'h000);
	assign checkZNaN = (z[14:10] == 5'h1f) & (z[9:0] != 10'h000);

	// create a bit signal describing if one of the inputs was NaN
	assign anyNaN = checkXNaN | checkYNaN | checkZNaN;

	// ineXact flag depends on guard, round, or sticky bits or overflow flag
	assign inXFlag = (~inVFlag) ? nonZeroMantFlag | oFFlag : '0;

	// general 16 bit values that will be used throughout the program
	assign zeroP = 'h0000;
	assign zeroN = 'h8000;
	assign infP = 'h7c00;
	assign infN = 'hfc00;
	assign NaN  = 'h7e00;

	logic checkXInfP, checkXInfN, checkXZeroP, checkXZeroN;
	logic checkYInfP, checkYInfN, checkYZeroP, checkYZeroN;
	logic checkZInfP, checkZInfN, checkZZeroP, checkZZeroN;

	logic checkXZero, checkYZero, checkZZero;
	logic checkXInf, checkYInf, checkZInf;

	assign checkXInfP = (x == infP); assign checkXInfN = (x == infN); assign checkXZeroP = (x == zeroP); assign checkXZeroN = (x == zeroN);
	assign checkYInfP = (y == infP); assign checkYInfN = (y == infN); assign checkYZeroP = (y == zeroP); assign checkYZeroN = (y == zeroN);
	assign checkZInfP = (z == infP); assign checkZInfN = (z == infN); assign checkZZeroP = (z == zeroP); assign checkZZeroN = (z == zeroN);

	assign checkXZero = checkXZeroP|checkXZeroN;
	assign checkYZero = checkYZeroP|checkYZeroN;
	assign checkZZero = checkZZeroP|checkZZeroN;

	assign checkXInf = checkXInfP|checkXInfN;
	assign checkYInf = checkYInfP|checkYInfN;
	assign checkZInf = checkZInfP|checkZInfN;

		// overflow logic depends on if sum's exponent becomes 'h1f
	always_comb begin : overFlowLogic
		if ((sum[14:10]==5'h1f)&~(checkXZero|checkYZero))	oFFlag = 'b1; 
		else 												oFFlag = 'b0; 
	end

	// checks for NaN and infinity cases and outputs the result, invalid flag, and if there was a special case found
   	always_comb begin : checkSpecialCases
		// check for NaN input
		if (anyNaN) begin result = NaN; inVFlag = '1; specialCaseFlag = '1; end

		// NaN indeterminate multiplication
		else if ((((checkXZeroN|checkXZeroP)&(checkXInfN|checkXInfP)&(~checkZInfP&~checkZInfN))|((((checkXInfN|checkXInfP)&(checkYZeroN|checkYZeroP)&(~checkZInfP&~checkZInfN)))))) begin result = NaN; inVFlag = '1; specialCaseFlag = '1; end

		else if ((checkXZero|checkYZero)&(checkZInfP)) begin result = infP; inVFlag = '0; specialCaseFlag = 1; end
		else if ((checkXZero|checkYZero)&(checkZInfN)) begin result = infN; inVFlag = '0; specialCaseFlag = 1; end

		// NaN indeterminate subtraction
		else if ((product == infP)&(z == infN)|(product == infN)&(z == infP)) begin result = NaN; inVFlag = '1;specialCaseFlag = '1; end
		
		// check overflow flag as well as if the product and addend have different signs to produce infinity variants
		else if (oFFlag) 
			if (product[15]^z[15]) 	begin result = '0; inVFlag = '0; specialCaseFlag = '0; end
			else 					begin result = (sum[15]) ? infN : infP; inVFlag = '0; specialCaseFlag = '1; end

		// product is zero and 

		// at least one of the inputs are inf
		else if ((x == infP | y == infP) & (x[15] ^ y[15])) begin result = infN; inVFlag = '0;specialCaseFlag = '1; end
		else if ((x == infP | y == infP) & (x[15] ~^ y[15])) begin result = infP; inVFlag = '0;specialCaseFlag = '1; end
		else if ((x == infN | y == infN) & (x[15] ^ y[15])) begin result = infN; inVFlag = '0;specialCaseFlag = '1; end
		else if ((x == infN | y == infN) & (x[15] ~^ y[15])) begin result = infP; inVFlag = '0; specialCaseFlag = '1; end
		else if (((x==(zeroN)&(y==zeroN))&(z==zeroN))) begin result = zeroP; inVFlag = '0; specialCaseFlag = '1; end
		else if (((x==(zeroP|zeroN)|(y==(zeroP|zeroN)))&(z==zeroP))) begin result = zeroP; inVFlag = '0; specialCaseFlag = '1; end
		else if (((x==(zeroP|zeroN)|(y==(zeroP|zeroN)))&(z==zeroN))) begin result = zeroN; inVFlag = '0; specialCaseFlag = '1; end

		// at least one input is a zero
		else if (checkXZero|checkYZero|checkZZero) begin result = sum; inVFlag = '0; specialCaseFlag = '1; end
		else                                              begin result = sum; inVFlag = '0; specialCaseFlag = '0; end
   end

	// outputs the flags
	assign flags = {inVFlag, oFFlag, 1'b0, inXFlag};

	// for readability purposes let's directly output the overflow flag
	assign overFlowFlag = oFFlag;
 endmodule































     // else if (uf == 2'b01) begin result = z; specialCaseFlag = '1; end
    // else if (uf == 2'b10) begin result = product; specialCaseFlag = '1; end 

    
   //assign uf = (product[14:10]==5'h00) ? 2'b01 : (sum[14:10]==5'h00) ? 2'b10 : 2'b00; 









     // if any inputs are infinity the output becomes infinity...need some additional logic to properly set the sign bit
    // else if ((x == infP) | (y == infP) | (z == infP)) begin //998 errors with this code
    //   specialCaseFlag = '1; 
    //   if ((x[15] ^ y[15]) & ((of == 2'b01) & z[15]))     result = infN;
    //   else                                               result = infP;
    // end
    // else if ((x == infN) | (y == infN) | (z == infN)) begin
    //   specialCaseFlag = '1; 
    //   if (x[15] ^ y[15])   result = infN;
    //   else                 result = infP;
    // end
