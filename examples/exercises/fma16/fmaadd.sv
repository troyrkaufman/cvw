// fmaadd.sv
// Troy Kaufman
// tkaufman@g.hmc.edu
// 3/14/17
/*
    Halfprecision floating point addition with postive and negative numbers with exponents that are nonzero and/or zero
*/

module fmaadd(  input logic [15:0] product, x, y, z,
                output logic [15:0] sum);

    logic [4:0]     Pe;     // sum of the product's exponents
    logic [4:0]     Ze;     // z's exponent
    logic [4:0]     Acnt;    // alignment shift count

    logic [10:0]    Am;      // shifted significand
    logic [11:0]    Sm;      // sum of aligned significands
    logic [10:0]    Pm;

    logic [4:0]     Mcnt;    // num count for leading 1 normalization shift
    logic [11:0]    Mm;  
    logic [4:0]     Me;

    logic           left;   // bit decides whether to shift to the left or right

    // add the exponents of x and y
    assign Pe = x[14:10] + y[14:10] - 4'd15;
    assign Ze = z[14:10];

    // product's mantissa
    assign Pm = {1'b1,product[9:0]};

    // determine the alighment shift count
    assign Acnt = Pe - Ze;

    // shift the significand of z into alignment
    assign Am = {1'b1,z[9:0]} >> Acnt;

    // add the aligned significands
    assign Sm = Pm + Am;

    // find the leading 1 for normalization shift
    always_comb begin : priorityEncoder
        if (Sm[12])      begin   Mcnt = 2;  left = 1;        end 
        else if (Sm[11]) begin   Mcnt = 1;  left = 1;        end
        else if (Sm[10]) begin   Mcnt = 0;  left = 1;        end
        else if (Sm[9])  begin   Mcnt = 1;  left = 1;        end
        else if (Sm[8])  begin   Mcnt = 2;  left = 0;        end
        else if (Sm[7])  begin   Mcnt = 3;  left = 0;        end
        else if (Sm[6])  begin   Mcnt = 4;  left = 0;        end
        else if (Sm[5])  begin   Mcnt = 5;  left = 0;        end
        else if (Sm[4])  begin   Mcnt = 7;  left = 0;        end
        else if (Sm[1])  begin   Mcnt = 8;  left = 0;        end
        else if (Sm[0])  begin   Mcnt = 9;  left = 0;        end
        else             begin   Mcnt = 5;  left = 1;        end
    end

    // shift to renormalize
    always_comb begin
        if (left) begin 
            Mm = Sm >> Mcnt;
            Me = Pe + Mcnt;
        end 
        else begin
            Mm = Sm << Mcnt;
            Me = Pe - Mcnt;
        end 
    end

    //assign Mm = Sm >> Mcnt;
    //assign Me = Pe + Mcnt;

    // bit swizzle results together
    assign sum = {1'b0,Me,Mm[9:0]};

endmodule