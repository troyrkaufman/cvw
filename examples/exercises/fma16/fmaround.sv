// Troy Kaufman
// tkaufman@g.hmc.edu
// 4/16/2025
// Purpose: Half precision floating point rounding module
// RNE: 'b01 RP: 'b11 RN: 'b01 RZ: 'b00

module fmaround(input logic     [15:0]  product, sum,
                input logic     [33:0]  fullSum,
                input logic             overFlowFlag,
                input logic     [1:0]   roundmode,
                output logic    [15:0]  rndFloat,
                output logic            nonZeroResults, takeRound);

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

    logic [14:0]    maxNum; 

    logic [15:0]   infP;           // positive infinity value
    logic [15:0]   infN;           // negative infinity value

    assign sign = sum[15];
    assign maxNum = 'h7bff;

   assign infP = 'h7c00;
   assign infN = 'hfc00;

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
        if (roundmode == 2'b00)
            if (overFlowFlag & sign)
                begin rndFloat = infP; takeRound = '1; end
            else if (overFlowFlag & ~sign)
                begin rndFloat = infN; takeRound = '1; end
            else if (rndPrime & (lsbPrime | stickyPrime))
                begin rndFloat = {sign, sum[14:0] + 15'd1}; takeRound = '1; end
            else    
                begin rndFloat = sum; takeRound = '0; end
    // RZ 
        else if (roundmode == 2'b01) 
            if (overFlowFlag & sign) 
                begin rndFloat = {sign, maxNum}; takeRound = '1; end
            else if (overFlowFlag & ~sign)
                begin rndFloat = infP; takeRound = '1; end
            else 
            begin rndFloat = 'h0; takeRound = 0; end
    // RP
        else if (roundmode == 2'b11) 
            if (overFlowFlag & sign)
                begin rndFloat = {sign, maxNum}; takeRound = '1; end
            else if (overFlowFlag & ~sign)
                begin rndFloat = infP; takeRound = '1; end
            else if (~sign)
                if (rndPrime | stickyPrime)
                    begin rndFloat = {sign, sum[14:0] + 15'd1}; takeRound = '1; end
                else 
                    begin rndFloat = sum; takeRound = '0; end
            else
                begin rndFloat = sum; takeRound = '0; end
    // RN
        else if (roundmode == 2'b10)
            if (overFlowFlag & sign)
                begin rndFloat = infN; takeRound = '1; end
            else if (overFlowFlag & ~sign)
                begin rndFloat = {sign, maxNum}; takeRound = '1; end
            else if (sign)
                if (rndPrime | stickyPrime)
                    begin rndFloat = {sign, sum[14:0] - 15'd1}; takeRound = '1; end
                else 
                    begin rndFloat = sum; takeRound = '0; end
            else
                begin rndFloat = sum; takeRound = '0; end
        else 
            begin rndFloat = sum; takeRound = '0; end
    end

    assign nonZeroResults = rndPrime | stickyPrime; 
endmodule