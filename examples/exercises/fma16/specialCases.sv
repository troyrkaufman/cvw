 // specialCases.sv
 // Troy Kaufman
 // tkaufman@g.hmc.edu
 // 4/13/25
 // Purpose: Half Precision floating point module that handles special cases

 module specialCases(input logic [15:0] x, y, z, product, sum,
                output logic [15:0] result,
                output logic        specialCaseFlag, anyNaN);

   logic [15:0]   infP;           // positive infinity value
   logic [15:0]   infN;           // negative infinity value
   logic [15:0]   zeroP;          // positive zero
   logic [15:0]   zeroN;          // negative zero
   logic [15:0]   NaN;            // NaN value
   logic [1:0]    of;             // overflow flag variants
   logic [1:0]    uf;             // underflow flag variants
   logic          checkXNaN;      // checks if X is NaN
   logic          checkYNaN;      // checks if Y is NaN
   logic          checkZNaN;      // checks if Z is NaN
   logic          anyNaN          // checks if any inputs are NaN
   logic          underFlowFlag;  // checks if the product produces an underflow

   assign checkXNaN = (x[14:10] == 5'h1f) & (x[9:0] != 10'h000);
   assign checkYNaN = (y[14:10] == 5'h1f) & (y[9:0] != 10'h000);
   assign checkZNaN = (z[14:10] == 5'h1f) & (z[9:0] != 10'h000);

   assign anyNaN = checkXNaN | checkYNaN | checkZNaN;

   assign zeroP = 'h0000;
   assign zeroN = 'h8000;

   assign infP = 'h7c00;
   assign infN = 'hfc00;

   assign NaN  = 'h7e00;

   // overflow logic inf: 2'b00 and 2'b11 (not an overflow), 2'b01 (product overflowed), 2'b10 (sum overflowed)
   assign of = (product[14:10]==5'h1f) ? 2'b01 : (sum[14:10]==5'h1f) ? 2'b10 : 2'b00; 

   // underflow product logic
   assign underFlowFlag = ($signed(x[14:10] + y[14:10] -'d15) <= 0);

   always_comb begin : checkSpecialCases
    // check for NaN input
    if (anyNaN) begin result = NaN; specialCaseFlag = '1; end

    // NaN indeterminate multiplication
    else if (((x == (zeroP|zeroN))&(y == (infP|infN))||(((x == (infP|infN))&(y == (zeroP|zeroN)))))) begin result = NaN; specialCaseFlag = '1; end

    // NaN indeterminate subtraction
    else if ((product == infP) & (z == infN) || (product == infN) & (z == infP)) begin result = NaN; specialCaseFlag = '1; end
    
    // check overflow flag
    else if (of == 2'b01) begin result = (product[15]) ? infN : infP; specialCaseFlag = '1; end
    else if (of == 2'b10) begin result = (sum[15]) ? infN : infP; specialCaseFlag = '1; end 

    // check underflow flag
    else if(underFlowFlag) begin result = z; specialCaseFlag = 'b1; end

    // at least one of the inputs are inf
    else if ((x == infP | y == infP) & (x[15] ^ y[15])) begin result = infN; specialCaseFlag = '1; end
    else if ((x == infP | y == infP) & (x[15] ~^ y[15])) begin result = infP; specialCaseFlag = '1; end
    else if ((x == infN | y == infN) & (x[15] ^ y[15])) begin result = infN; specialCaseFlag = '1; end
    else if ((x == infN | y == infN) & (x[15] ~^ y[15])) begin result = infP; specialCaseFlag = '1; end
    else                                              begin result = sum; specialCaseFlag = '0; end
   end
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
