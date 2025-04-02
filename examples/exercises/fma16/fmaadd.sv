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
    logic [33:0]    tempMm;
    logic [33:0]    tempMe;
    logic [9:0]     Mm;  
    logic [4:0]     Me;

    logic           left;   // bit decides whether to shift to the left or right
    logic [1:0]     nsig;   // one of the addends or insignificant
    logic           sign;

    // add the exponents of x and y
    assign Pe = x[14:10] + y[14:10] - 4'd15;
    assign Ze = z[14:10];

    // product's mantissa
    assign Pm = {1'b1,product[9:0]};
    assign Zm = {1'b1, z[9:0]};

    // Z mantissa alignment shift alogrithm. First align the shift amount and check for insignificant addends.
    // Then preshift Z's mantissa all the way to the left then back to the right by Acnt.
    always_comb begin : alignmentShift
        Acnt = Pe - Ze + 4'd12;
        // if ($signed($unsigned(Pe) - $unsigned(Ze)) >= 11)        nsig = 2'b01;
        // else if ($signed($unsigned(Ze) - $unsigned(Pe)) >= 11)   nsig = 2'b10;
        // else                                                     nsig = 2'b00;

        if (($unsigned(Pe) > $unsigned(Ze)) && (($unsigned(Pe) - $unsigned(Ze)) >= 11)) 
        nsig = 2'b01;  // Product dominates, return product
        else if (($unsigned(Ze) > $unsigned(Pe)) && (($unsigned(Ze) - $unsigned(Pe)) >= 11)) 
        nsig = 2'b10;  // Addend dominates, return addend
        else
        nsig = 2'b00;  // Perform normal floating-point addition

        
        // if ($unsigned(Ze) > $unsigned(Pe))
        //     if ((~$signed($unsigned(Pe) - $unsigned(Ze)) + 1'b1) >= 11)         nsig = 2'b10;
        //     else if ($signed($unsigned(Ze) - $unsigned(Pe)) >= 11)              nsig = 2'b01;
        //     else                                                                nsig = 2'b00;
        // else if ($unsigned(Pe) > $unsigned(Ze))
        //     if ((~($signed($unsigned(Ze) - $unsigned(Pe))) + 1'b1) >= 11)       nsig = 2'b01;
        //     else if (~($signed($unsigned(Pe) - $unsigned(Ze)) +1'b1) >= 11)             nsig = 2'b10;
        //     else                                                                nsig = 2'b00;
        // else                                                                    nsig = 2'b00;
        ZmPreShift = {12'b0, Zm} << 'd12; //23 bits
        ZmShift = {21'b0, ZmPreShift} >> {38'b0, Acnt};
        Am = ZmShift[33:0];
    end

    // compute mantissa's magnitude
    always_comb begin : computeMantissas
        if ((product[15] ^ z[15]) == 1'b1 && z[15] == 1'b1)         
            begin Sm = {23'b0, Pm} + ~Am; end 
        else if ((product[15] ^ z[15]) == 1'b1 && z[15] == 1'b0)    
            begin Sm = ~{23'b0, Pm} + Am; end 
        else if ((product[15] ^ z[15]) == 1'b0 && z[15] == 1'b0)    
            begin Sm = {23'b0, Pm} + Am;  end
        else                                                        
            begin Sm = ~{23'b0, Pm} + ~Am;end
    end

    // find the leading 1 for normalization shift
    always_comb begin : priorityEncoder
        if (Sm[33])         begin   Mcnt = 'd22;    left = 1;   end 
        else if (Sm[32])    begin   Mcnt = 'd21;    left = 1;   end
        else if (Sm[31])    begin   Mcnt = 'd20;    left = 1;   end
        else if (Sm[30])    begin   Mcnt = 'd19;    left = 1;   end
        else if (Sm[29])    begin   Mcnt = 'd18;    left = 1;   end
        else if (Sm[28])    begin   Mcnt = 'd17;    left = 1;   end
        else if (Sm[27])    begin   Mcnt = 'd16;    left = 1;   end
        else if (Sm[26])    begin   Mcnt = 'd15;    left = 1;   end
        else if (Sm[25])    begin   Mcnt = 'd14;    left = 1;   end
        else if (Sm[24])    begin   Mcnt = 'd14;    left = 1;   end
        else if (Sm[23])    begin   Mcnt = 'd13;    left = 1;   end
        else if (Sm[22])    begin   Mcnt = 'd12;    left = 1;   end
        else if (Sm[21])    begin   Mcnt = 'd11;    left = 1;   end
        else if (Sm[20])    begin   Mcnt = 'd10;    left = 1;   end
        else if (Sm[19])    begin   Mcnt = 9;       left = 1;   end
        else if (Sm[18])    begin   Mcnt = 8;       left = 1;   end
        else if (Sm[17])    begin   Mcnt = 7;       left = 1;   end
        else if (Sm[16])    begin   Mcnt = 6;       left = 1;   end
        else if (Sm[15])    begin   Mcnt = 5;       left = 1;   end
        else if (Sm[14])    begin   Mcnt = 4;       left = 1;   end
        else if (Sm[13])    begin   Mcnt = 3;       left = 1;   end
        else if (Sm[12])    begin   Mcnt = 2;       left = 1;   end
        else if (Sm[11])    begin   Mcnt = 1;       left = 1;   end
        else if (Sm[10])    begin   Mcnt = 0;       left = 0;   end
        else if (Sm[9])     begin   Mcnt = 1;       left = 0;   end
        else if (Sm[8])     begin   Mcnt = 2;       left = 0;   end
        else if (Sm[7])     begin   Mcnt = 3;       left = 0;   end
        else if (Sm[6])     begin   Mcnt = 4;       left = 0;   end
        else if (Sm[5])     begin   Mcnt = 5;       left = 0;   end
        else if (Sm[4])     begin   Mcnt = 6;       left = 0;   end
        else if (Sm[3])     begin   Mcnt = 7;       left = 0;   end
        else if (Sm[2])     begin   Mcnt = 8;       left = 0;   end
        else if (Sm[1])     begin   Mcnt = 9;       left = 0;   end
        else                begin   Mcnt = 10;      left = 0;   end
    end

    // shift to renormalize
    always_comb begin
        if (nsig == 2'b01) begin 
            Mm = product[9:0];
            Me = product[14:10];
            // sign = product[15];
            tempMm = '0;
        end
        else if (nsig == 2'b10) begin
            Mm = z[9:0];
            Me = z[14:10];
            // sign = z[15];
            tempMm = '0;
        end
        else begin
            if (left) begin 
                tempMm = Sm >> Mcnt;
                Mm = tempMm[9:0];
                Me = Pe + Mcnt;
            end 
            else begin
                tempMm = Sm << Mcnt;
                //Mm = Sm << Mcnt;
                Mm = tempMm[9:0];
                Me = Pe - Mcnt;
            end 
        end
    end

    // // shift to renormalize
    // always_comb begin
    //     if (left) begin 
    //         tempMm = Sm >> Mcnt;
    //         Mm = tempMm[9:0];
    //         Me = Pe + Mcnt;
    //     end 
    //     else begin
    //         tempMm = Sm << Mcnt;
    //         //Mm = Sm << Mcnt;
    //         Mm = tempMm[9:0];
    //         Me = Pe - Mcnt;
    //     end 
    // end



    // assign preSum = Sm >> ZeroCnt;
    // assign Mm = preSum[9:0];
    // assign Me = Pe - ZeroCnt[4:0];

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
