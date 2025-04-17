// Troy Kaufman
// tkaufman@g.hmc.edu
// 4/16/2025
// Purpose: Half precision floating point rounding module

module fmaround(input logic [15:0] x, y, z, product, sum,
                input logic [33:0] fullSum,
                input logic overFlowFlag, anyNaN
                input logic [1:0] roudnmode,
                output logic [15:0] rndFloat,
                output logic [3:0] flags);

    logic sign;
    logic lsb;
    logic rnd;
    logic guard;
    logic sticky;
    logic lsbPrime;
    logic rndPrime; 
    logic stickyPrime;

    logic inVFlag;
    logic inXFlag;
    logic underFlowFlag;

   logic [15:0]   infP;           // positive infinity value
   logic [15:0]   infN;           // negative infinity value
   logic [15:0]   zeroP;          // positive zero
   logic [15:0]   zeroN;          // negative zero
   logic [15:0]   NaN;            // NaN value

   assign sign = sum[15];

   assign zeroP = 'h0000;
   assign zeroN = 'h8000;

   assign infP = 'h7c00;
   assign infN = 'hfc00;

   assign NaN  = 'h7e00;

    // RNE logic
    assign lsb = fullSum[23];
    assign guard = fullSum[22];
    assign rnd = fullSum[21];
    assign sticky = |fullSum[20:0];

    assign lsbPrime = lsb;
    assign rndPrime = guard;
    assign stickyPrime = rnd | sticky;
        
    always_comb begin : rounding
    // RNE
        if (roundmode == 2'b01)
            if (overFlowflag & sign)
                begin result = infP; end
            else if (overFlowFlag & ~sign)
                begin result = infN; end
            else if (rndPrime & (lsbPrime | stickyPrime))
                begin result = sum[14:0] + 'd1; end
            else    
                result = sum;
    // RP
        else if (roundmode == 2'b10) 
            if (overFlowFlag & sign)
                begin result = -MAXNUM; end
            else if (overFlowFlag & ~sign)
                begin result = infP; end
            else if (~sign)
                if (rndPrime | stickyPrime)
                    begin result = sum[14:0] + 'd1; end
                else 
                    result = sum;
            else
                result = sum;
    // RZ
        else if (roundmode = 2'b11)
            if (overFlowFlag & sign)
                begin result = infN; end
            else if (overFlowFlag & ~sign)
                begin result = MAXNUM; end
            else if (sign)
                if (rndPrime | stickyPrime)
                    begin result = sum[14:0] - 'd1; end
                else 
                    result = sum;
            else
                result = sum;
        else 
            result = sum;

    always_comb begin : invalidFlag
        //if(anyNaN) begin invflag = '1
        if (x == ())
    end

    assign flags = {inVFlag, overFlowFlag, underFlowFlag, inXFlag};

    end




endmodule