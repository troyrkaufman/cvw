
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
    //logic [4:0]     Acnt;    // alignment shift count
    logic [6:0]     Acnt;    // alignment shift count

    logic           Zs;     // Z's sign bit
    logic           Ps;     // product's sign

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

    logic [15:0]    tempZ;

    logic [1:0]     addType;    // type of addition being performed

    logic [33:0]    debugPm;
    logic [33:0]    debugAm;

    assign debugPm = {23'b0, Pm}; 
    assign debugAm = ~Am + 1'b1;

    assign tempZ = negz ? (~z + 1'b1) : z;

    // add the exponents of x and y
    assign Pe = x[14:10] + y[14:10] - 4'd15;
    assign Ze = tempZ[14:10];

    // product's mantissa
    assign Pm = {1'b1,product[9:0]};
    assign Zm = {1'b1, tempZ[9:0]};

    // addend's sign
    assign Zs = tempZ[15];
    assign Ps = product[15];

    // Z mantissa alignment shift alogrithm. First align the shift amount.
    // Then preshift Z's mantissa all the way to the left then back to the right by Acnt.
    always_comb begin : alignmentShift
        // Acnt = Pe - Ze + 4'd12;
        // ZmPreShift = {12'b0, Zm} << 'd12; //23 bits
        // ZmShift = {21'b0, ZmPreShift} >> {38'b0, Acnt};
        // Am = ZmShift[33:0];
        Acnt = {2'b0, Pe} - {2'b0, Ze} + 'd12;
        ZmPreShift = {12'b0, Zm} << 'd12; //23 bits
        ZmShift = {21'b0, ZmPreShift} >> Acnt;
        Am = ZmShift[33:0];
    end

    // Check for unecessary addition then assign the nsig flag a specific value to either telling the program that either
    // the product dominates (transmit product), addend dominates (transmit addend), or neither dominates and perform normal floating point addition
    always_comb begin : checkSignificance
        if (($unsigned(Pe) > $unsigned(Ze)) && (($unsigned(Pe) - $unsigned(Ze)) >= 11))         nsig = 2'b01;  
        else if (($unsigned(Ze) > $unsigned(Pe)) && (($unsigned(Ze) - $unsigned(Pe)) >= 11))    nsig = 2'b10; 
        else                                                                                    nsig = 2'b00;
    end

    // compute mantissa's magnitude
    // addType = 2'b00: unsigned addition
    // addType = 2'b01: unsigned product and signed addend
    // addType = 2'b10: signed product and unsigned addend
    // addType = 2'b11: signed product and signed addend
    always_comb begin : computeMantissas
        if ((Ps ^ Zs) == 1'b1 && Zs == 1'b1)         
            begin Sm = {23'b0, Pm} + (~Am + 1'b1); addType = 2'b01; end 
        else if ((Ps ^ Zs) == 1'b1 && Zs == 1'b0)    
            begin Sm = (~{23'b0, Pm} + 1'b1) + Am; addType = 2'b10; end 
        else if ((Ps ^ Zs) == 1'b0 && Zs == 1'b0)    
            begin Sm = {23'b0, Pm} + Am;  addType = 2'b00; end
        else                                                        
            begin Sm = (~{23'b0, Pm}+1'b1) + (~Am + 1'b1);addType = 2'b11; end
    end

    // compute sign...need to introduce negz logic here too which will add a little bit more work
    always_comb begin : computeSign
        if (addType == 2'b00) sign = '0;
        else if (($unsigned({Pe, Pm}) > $unsigned({Ze, Zm})) && addType == 2'b01) sign = '0;
        else if (($unsigned({Pe, Pm}) > $unsigned({Ze, Zm})) && addType == 2'b10) sign = '1;
        else if (($unsigned({Ze, Zm}) > $unsigned({Pe, Pm})) && addType == 2'b01) sign = '1;
        else if (($unsigned({Ze, Zm}) > $unsigned({Pe, Pm})) && addType == 2'b10) sign = '0;
        else sign = '0; //(addType == 2'b11) sign = '0; 
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
        else                begin   Mcnt = 'd10;    left = 0;   end
    end

    // shift to renormalize
    always_comb begin
        if (nsig == 2'b01) begin 
            Mm = product[9:0];
            Me = product[14:10];
            tempMm = '0;
        end
        else if (nsig == 2'b10) begin
            Mm = z[9:0];
            Me = z[14:10];
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
                Mm = tempMm[9:0];
                Me = Pe - Mcnt;
            end 
        end
    end

    // bit swizzle results together
    assign sum = {sign,Me,Mm[9:0]};
endmodule







/*
module fmaadd(  input logic [15:0] product, x, y, z,
                input logic         negz,
                output logic [15:0] sum);

    logic [4:0]     Pe;     // sum of the product's exponents
    logic [4:0]     Ze;     // z's exponent

    logic [6:0]     Acnt;    // alignment shift count

    logic           Zs;     // Z's sign bit
    logic           Ps;     // product's sign

    logic           inv;    // checks for a difference in signs
    logic [35:0]    tempAm;

    logic [9:0]     Zm;
    logic [20:0]    Pm;
    logic [35:0]    Am;      // shifted significand U(15.21)
    logic [35:0]    Sm;      // sum of aligned significands

    logic [45:0]    ZmPreShift;
    logic [45:0]    ZmShift;
    logic [45:0]    tempZmShift;

    logic [4:0]     Mcnt;    // num count for leading 1 normalization shift
    logic [35:0]    tempMm;
   
    logic [9:0]     Mm;  
    logic [4:0]     Me;

    logic           left;   // bit decides whether to shift to the left or right
    logic [1:0]     nsig;   // one of the addends or insignificant
    logic           sign;

    logic [15:0]    tempZ;

    logic [1:0]     addType;    // type of addition being performed

    // add the exponents of x and y
    assign Pe = x[14:10] + y[14:10] - 4'd15;
    assign Ze = z[14:10];

    // product's mantissa
    assign Pm = {1'b1,x[9:0]} * {1'b1, y[9:0]};
    assign Zm = z[9:0];

    // addend's sign
    assign Zs = z[15];
    assign Ps = product[15];

    // Z mantissa alignment shift alogrithm. First align the shift amount.
    // Then preshift Z's mantissa all the way to the left then back to the right by Acnt.
    always_comb begin : alignmentShift
        Acnt = {2'b0, Pe} - {2'b0, Ze} + 7'd13;
        ZmPreShift = {Zm, 36'b0};
        ZmShift = ZmPreShift >> Acnt;
        Am = ZmShift[45:10];
    end

    // Check for unecessary addition then assign the nsig flag a specific value to either telling the program that either
    // the product dominates (transmit product), addend dominates (transmit addend), or neither dominates and perform normal floating point addition
    always_comb begin : checkSignificance
        if (($unsigned(Pe) > $unsigned(Ze)) && (($unsigned(Pe) - $unsigned(Ze)) >= 11))         nsig = 2'b01;  
        else if (($unsigned(Ze) > $unsigned(Pe)) && (($unsigned(Ze) - $unsigned(Pe)) >= 11))    nsig = 2'b10; 
        else                                                                                    nsig = 2'b00;
    end

    // compute mantissa
    assign inv = Zs ^ Ps;
    assign tempAm = inv ? ~Am : Am;

    always_comb begin : computeMantissas
        Sm = Am + {13'b0, Pm, 2'b0};
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
        else                begin   Mcnt = 'd10;    left = 0;   end
    end

    // shift to renormalize
    always_comb begin
        if (nsig == 2'b01) begin 
            Mm = product[9:0];
            Me = product[14:10];
            tempMm = '0;
        end
        else if (nsig == 2'b10) begin
            Mm = z[9:0];
            Me = z[14:10];
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
                Mm = tempMm[9:0];
                Me = Pe - Mcnt;
            end 
        end
    end

    // bit swizzle results together
    assign sum = {1'b0,Me,Mm[9:0]};
endmodule









    // compute mantissa's magnitude
    // addType = 2'b00: unsigned addition
    // addType = 2'b01: unsigned product and signed addend
    // addType = 2'b10: signed product and unsigned addend
    // addType = 2'b11: signed product and signed addend
    // always_comb begin : computeMantissas
    //     if ((Ps ^ Zs) == 1'b1 && Zs == 1'b1)         
    //         begin Sm = {23'b0, Pm} + (~Am + 1'b1); addType = 2'b01; end 
    //     else if ((Ps ^ Zs) == 1'b1 && Zs == 1'b0)    
    //         begin Sm = (~{23'b0, Pm} + 1'b1) + Am; addType = 2'b10; end 
    //     else if ((Ps ^ Zs) == 1'b0 && Zs == 1'b0)    
    //         begin Sm = {23'b0, Pm} + Am;  addType = 2'b00; end
    //     else                                                        
    //         begin Sm = (~{23'b0, Pm}+1'b1) + (~Am + 1'b1);addType = 2'b11; end
    // end

    // // compute sign...need to introduce negz logic here too which will add a little bit more work
    // always_comb begin : computeSign
    //     if (addType == 2'b00) sign = '0;
    //     else if (($unsigned({Pe, Pm}) > $unsigned({Ze, Zm})) && addType == 2'b01) sign = '0;
    //     else if (($unsigned({Pe, Pm}) > $unsigned({Ze, Zm})) && addType == 2'b10) sign = '1;
    //     else if (($unsigned({Ze, Zm}) > $unsigned({Pe, Pm})) && addType == 2'b01) sign = '1;
    //     else if (($unsigned({Ze, Zm}) > $unsigned({Pe, Pm})) && addType == 2'b10) sign = '0;
    //     else sign = '0; //(addType == 2'b11) sign = '0; 
    // end

*/