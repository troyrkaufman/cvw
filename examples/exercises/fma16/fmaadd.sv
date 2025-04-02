// fmaadd.sv
// Troy Kaufman
// tkaufman@g.hmc.edu
// 3/14/17
/*
    Halfprecision floating point addition with postive and negative numbers with exponents that are nonzero and/or zero
*/

module fmaadd(  input logic [15:0] product, x, y, z,
                input logic         negz,
                output logic [15:0] sum);

    logic [4:0]     Pe;     // sum of the product's exponents
    logic [4:0]     Ze;     // z's exponent
    logic [4:0]     Acnt;    // alignment shift count

    logic [10:0]    Zm;
    logic [10:0]    Pm;
    logic [33:0]    Am;      // shifted significand
    logic [33:0]    Sm;      // sum of aligned significands
    logic [22:0]    ZmPreShift;
    logic [43:0]    ZmShift;
    logic [43:0]    tempZmShift;
    logic [33:0]    preSum;

    logic [4:0]     Mcnt;    // num count for leading 1 normalization shift
    logic [9:0]     Mm;  
    logic [4:0]     Me;

    logic [37-1:0]            num;    // number to count the leading zeroes of
    logic [$clog2(37+1)-1:0]  ZeroCnt; // the number of leading zeroes

    //logic           left;   // bit decides whether to shift to the left or right

    // add the exponents of x and y
    assign Pe = x[14:10] + y[14:10] - 4'd15;
    assign Ze = z[14:10];

    // product's mantissa
    assign Pm = {1'b1,product[9:0]};
    assign Zm = {1'b1, z[9:0]};

    // Z mantissa alignment shift alogrithm
    always_comb begin : alignmentShift
    // allignment shift amount
        Acnt = Pe - Ze + 4'd12;

    // Preshift Z manitssa
        ZmPreShift = {12'b0, Zm} << 'd12; //23 bits

    // Variable alignment
        ZmShift = {21'b0, ZmPreShift} >> {38'b0, Acnt};

    // shift Zm by Nf
     //   tempZmShift = ZmShift >> 4'd10;

    // retrieve only the necessary bits
       // Am = tempZmShift[33:0];
       Am = ZmShift[33:0];
    end

    // add or subtract mantissas
    always_comb begin : computeMantissas
        if ((product[15] ^ z[15]) == 1'b1 && z[15] == 1'b1) 
            Sm = {23'b0, Pm} + ~Am;
        else if ((product[15] ^ z[15]) == 1'b1 && z[15] == 1'b0) 
            Sm = ~{23'b0, Pm} + Am; 
        else if ((product[15] ^ z[15]) == 1'b0 && z[15] == 1'b0) 
            Sm = {23'b0, Pm} + Am; 
        else 
            Sm = ~{23'b0, Pm} + ~Am;
    end

  integer i;
  
  always_comb begin
    i = 0;
    while ((i < 34) & ~num[34-1-i]) i = i+1;  // search for leading one
    ZeroCnt = i[$clog2(34+1)-1:0];
  end

    assign preSum = Sm >> ZeroCnt;
    assign Mm = preSum[9:0];
    assign Me = Pe - ZeroCnt[4:0];


    // // determine the alighment shift count
    // assign Acnt = $signed(Pe) - $signed(Ze);

    // // shift the significand of z into alignment
    // always_comb begin
    //     if ($signed(Acnt) < 0) Am = {1'b1,z[9:0]} << $unsigned(Acnt);
    //     else Am = {1'b1,z[9:0]} >> $unsigned(Acnt);
    // end
    // //assign Am = {1'b1,z[9:0]} >> Acnt;

    // // add the aligned significands
    // // assign Sm = {11'b0,Pm} + {{(22-$unsigned(Acnt)){1'b0}},Am};
    // assign Sm = {11'b0,Pm} + {};




    // bit swizzle results together
    assign sum = {1'b0,Me,Mm[9:0]};

endmodule


    // // find the leading 1 for normalization shift
    // always_comb begin : priorityEncoder
    //     if (Sm[12])      begin   Mcnt = 2;  left = 1;        end 
    //     else if (Sm[11]) begin   Mcnt = 1;  left = 1;        end
    //     else if (Sm[10]) begin   Mcnt = 0;  left = 1;        end
    //     else if (Sm[9])  begin   Mcnt = 1;  left = 1;        end
    //     else if (Sm[8])  begin   Mcnt = 2;  left = 0;        end
    //     else if (Sm[7])  begin   Mcnt = 3;  left = 0;        end
    //     else if (Sm[6])  begin   Mcnt = 4;  left = 0;        end
    //     else if (Sm[5])  begin   Mcnt = 5;  left = 0;        end
    //     else if (Sm[4])  begin   Mcnt = 7;  left = 0;        end
    //     else if (Sm[1])  begin   Mcnt = 8;  left = 0;        end
    //     else if (Sm[0])  begin   Mcnt = 9;  left = 0;        end
    //     else             begin   Mcnt = 5;  left = 1;        end
    // end

    // // shift to renormalize
    // always_comb begin
    //     if (left) begin 
    //         Mm = Sm >> Mcnt;
    //         Me = Pe + Mcnt;
    //     end 
    //     else begin
    //         Mm = Sm << Mcnt;
    //         Me = Pe - Mcnt;
    //     end 
    // end

    // //assign Mm = Sm >> Mcnt;
    // //assign Me = Pe + Mcnt;
