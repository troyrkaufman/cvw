// Troy Kaufman
// tkaufman@g.hmc.edu
// 4/16/2025
// Purpose: Half precision floating point rounding module
// RNE: 'b01 RP: 'b11 RN: 'b01 RZ: 'b00

module fmaround(input logic     [15:0]  product, z, sum,
                input logic     [21:0]  fullPm,
                input logic     [33:0]  fullSum,
                input logic     [1:0]   sigNum,
                input logic             overFlowFlag, mul, add, 
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

    logic [15:0]   zeroP;          // positive zero
	logic [15:0]   zeroN;          // negative zero
    logic          zeros;

    assign zeroP = 'h0000;
	assign zeroN = 'h8000;
    //assign zeros = zeroP | zeroN;

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
            else if((product[15]^z[15])&(sigNum==2'b10|sigNum==2'b01)&(fullPm[9:0] == 10'b0)&(z!=zeroN&z!=zeroP))
                begin rndFloat = sum; takeRound = '1; end
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
            else if ((product[15]^z[15])&(sigNum==2'b10|sigNum==2'b01)&(fullPm[9:0] == 10'b0)&(z!=zeroN&z!=zeroP)) begin rndFloat = {sign, (sum[14:0] - 15'b1)}; takeRound = '1;end
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
                    begin rndFloat = {sign, sum[14:0] + 15'd1}; takeRound = '1; end
                else 
                    begin rndFloat = sum; takeRound = '0; end
            else
                begin rndFloat = sum; takeRound = '0; end
        else 
            begin rndFloat = sum; takeRound = '0; end
    end

    assign nonZeroResults = rndPrime | stickyPrime; 
endmodule





            // else if (rndPrime & (lsbPrime | stickyPrime) & (sigNum == 2'b01))
            //     begin rndFloat = product; takeRound = '1; end 
            // else if (rndPrime & (lsbPrime | stickyPrime) & (sigNum == 2'b10))
            //     begin rndFloat = z; takeRound = '1; end 
           // else if ((sigNum==2'b10|sigNum==2'b01)&())
            // else if (rndPrime & (lsbPrime | stickyPrime))
            //     begin rndFloat = {sign, sum[14:0] + 15'd1}; takeRound = '1; end 

            //else if ((sigNum == 2'b10 | sigNum == 2'b01)& (rndPrime|stickyPrime == '0)) begin rndFloat = {sign, sum[14:10], (fullSum[33:24] - 1'b1)}; takeRound = '1; end
            //else if ((lsbPrime == 'b1) & (sigNum == 2'b10)) 
                //if (sign) begin rndFloat = {sign, (sum[14:0] - 15'b1)}; takeRound = '1; end
                     //begin rndFloat = {sign, (sum[14:0] - 15'b1)}; takeRound = '1; end