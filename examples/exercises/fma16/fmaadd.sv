
// fmaadd.sv
// Troy Kaufman
// tkaufman@g.hmc.edu
// 3/14/17
/*
    Halfprecision floating point addition with postive and negative numbers with exponents that are nonzero and/or zero
*/



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

    logic [4:0]     Mcnt;    // num count for leading 1 normalization shift
    logic [4:0]     normalMcnt;
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

    logic [33:0]    checkSm;
    logic           compExp;
    logic           compMant;

    logic           shiftPmFlag;
    logic [33:0]    shiftPm;

    //assign debugPm = {23'b0, Pm}; 
    //assign debugAm = ~Am + 1'b1;

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

    // general comparison GREATER THAN OR GREATER THAN OR EQUAL TO
    assign compExp = ($unsigned(Pe) >= $unsigned(Ze)) ? 1'b1 : 1'b0;
    assign compMant = ($unsigned(Pm) >= $unsigned(Zm)) ? 1'b1 : 1'b0;

    //logic [33:0] shiftPm;
    //assign shiftPm = {1'b0, Pm, 22'b0};

    // Z mantissa alignment shift alogrithm. First align the shift amount.
    // Then preshift Z's mantissa all the way to the left then back to the right by Acnt.
    always_comb begin : alignmentShift
        // if Ze is larger than Pe, shift Pm down by Acnt
        if (compExp) begin Acnt = {2'b0, Pe} - {2'b0, Ze}; shiftPmFlag = 1'b0; end 
        else         begin Acnt = {2'b0, Ze} - {2'b0, Pe}; shiftPmFlag = 1'b1; end 
        ZmPreShift = {Zm, 12'b0}; 
        if (shiftPmFlag) begin  shiftPm = {1'b0, Pm, 22'b0} >> Acnt; ZmShift = {ZmPreShift, 21'b0}; end
        else begin              shiftPm = {1'b0, Pm, 22'b0}; ZmShift = {ZmPreShift, 21'b0} >> Acnt; end
        Am = ZmShift[43:10];
        //ZmShift = {ZmPreShift, 21'b0} >> Acnt;
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
            begin Sm = shiftPm - (Am>>1); addType = 2'b01; end 
        else if ((Ps ^ Zs) == 1'b1 && Zs == 1'b0)    
            //begin Sm = (~{Pm, 23'b0} + 1'b1) + Am; addType = 2'b10; end 
             begin Sm = (~shiftPm + 1'b1) + (Am>>1); addType = 2'b10; end 
        else if ((Ps ^ Zs) == 1'b0 && Zs == 1'b0)    
            begin Sm = shiftPm + (Am>>1);  addType = 2'b00; end
        else                                                        
            begin Sm = -shiftPm - (Am>>1);addType = 2'b11; end
    end

    
    // logic [33:0] debugAm;
    assign debugAm = ((-Am)>>1);
    assign debugPm = (~shiftPm + 1'b1);

    // compute sign...need to introduce negz logic here too which will add a little bit more work
    always_comb begin : computeSign
        if (addType == 2'b00) sign = '0;
        else if (($unsigned({Pe, Pm}) > $unsigned({Ze, Zm})) && addType == 2'b01) sign = '0;
        else if (($unsigned({Pe, Pm}) > $unsigned({Ze, Zm})) && addType == 2'b10) sign = '1;
        else if (($unsigned({Ze, Zm}) > $unsigned({Pe, Pm})) && addType == 2'b01) sign = '1;
        else if (($unsigned({Ze, Zm}) > $unsigned({Pe, Pm})) && addType == 2'b10) sign = '0;
        else sign = '0; 
    end

    // prepare Sm for normalization phase
    assign checkSm = (Sm[33] && addType != 2'b00) ? ~Sm + 1'b1 : Sm;

    integer i;
    logic [$clog2(35)-1:0]  ZeroCnt;

    // leading zero counter
    always_comb begin : LZC
        i = 0;
        while ((i < 34) & ~checkSm[33-i]) i = i+1;  // search for leading one
        ZeroCnt = i[$clog2(35)-1:0];
    end

    always_comb begin : calculateMantExp
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
            if (addType == 2'b00 && checkSm[33] && ~(shiftPmFlag)) begin 
                tempMm = checkSm << ZeroCnt;
                Mm = tempMm[32:23];
                Me = Pe + 1'b1;
            end
            else begin
                tempMm = checkSm << ZeroCnt;
                Mm = tempMm[32:23];
                if (shiftPmFlag)    Me = Pe - ZeroCnt[4:0] + Acnt[4:0] + 'b1;
                else                Me = Pe - ZeroCnt[4:0] + 'b1;
            end
        end
    end

    // bit swizzle results together
    assign sum = {sign,Me,Mm};
endmodule



    // // find the leading 1 for normalization shift
    // always_comb begin : priorityEncoder
    //     if (checkSm[33])         begin   Mcnt = 'd23;    left = 1;   end     
    //     else if (checkSm[32])    begin   Mcnt = 'd22;    left = 1;   end
    //     else if (checkSm[31])    begin   Mcnt = 'd21;    left = 1;   end
    //     else if (checkSm[30])    begin   Mcnt = 'd20;    left = 1;   end
    //     else if (checkSm[29])    begin   Mcnt = 'd19;    left = 1;   end
    //     else if (checkSm[28])    begin   Mcnt = 'd18;    left = 1;   end
    //     else if (checkSm[27])    begin   Mcnt = 'd17;    left = 1;   end
    //     else if (checkSm[26])    begin   Mcnt = 'd16;    left = 1;   end
    //     else if (checkSm[25])    begin   Mcnt = 'd15;    left = 1;   end
    //     else if (checkSm[24])    begin   Mcnt = 'd14;    left = 1;   end
    //     else if (checkSm[23])    begin   Mcnt = 'd13;    left = 1;   end
    //     else if (checkSm[22])    begin   Mcnt = 'd12;    left = 1;   end
    //     else if (checkSm[21])    begin   Mcnt = 'd11;    left = 1;   end
    //     else if (checkSm[20])    begin   Mcnt = 'd10;    left = 1;   end
    //     else if (checkSm[19])    begin   Mcnt = 9;       left = 1;   end
    //     else if (checkSm[18])    begin   Mcnt = 8;       left = 1;   end
    //     else if (checkSm[17])    begin   Mcnt = 7;       left = 1;   end
    //     else if (checkSm[16])    begin   Mcnt = 6;       left = 1;   end
    //     else if (checkSm[15])    begin   Mcnt = 5;       left = 1;   end
    //     else if (checkSm[14])    begin   Mcnt = 4;       left = 1;   end
    //     else if (checkSm[13])    begin   Mcnt = 3;       left = 1;   end
    //     else if (checkSm[12])    begin   Mcnt = 2;       left = 1;   end
    //     else if (checkSm[11])    begin   Mcnt = 1;       left = 1;   end
    //     else if (checkSm[10])    begin   Mcnt = 0;       left = 0;   end
    //     else if (checkSm[9])     begin   Mcnt = 1;       left = 0;   end
    //     else if (checkSm[8])     begin   Mcnt = 2;       left = 0;   end
    //     else if (checkSm[7])     begin   Mcnt = 3;       left = 0;   end
    //     else if (checkSm[6])     begin   Mcnt = 4;       left = 0;   end
    //     else if (checkSm[5])     begin   Mcnt = 5;       left = 0;   end
    //     else if (checkSm[4])     begin   Mcnt = 6;       left = 0;   end
    //     else if (checkSm[3])     begin   Mcnt = 7;       left = 0;   end
    //     else if (checkSm[2])     begin   Mcnt = 8;       left = 0;   end
    //     else if (checkSm[1])     begin   Mcnt = 9;       left = 0;   end
    //     else                begin   Mcnt = 'd10;    left = 0;   end
    // end

    // // shift to renormalize
    // always_comb begin

    //     //normalMcnt = subMcnt ? Mcnt - 1'b1 : Mcnt; 

    //     if (nsig == 2'b01) begin 
    //         Mm = product[9:0];
    //         Me = product[14:10];
    //         tempMm = '0;
    //     end
    //     else if (nsig == 2'b10) begin
    //         Mm = z[9:0];
    //         Me = z[14:10];
    //         tempMm = '0;
    //     end
    //     else begin
    //         if (left) begin 
    //             tempMm = Sm >> Mcnt;
    //             Mm = tempMm[9:0];
    //             Me = Pe + Mcnt;
    //         end 
    //         else begin
    //             tempMm = Sm << Mcnt;
    //             Mm = tempMm[9:0];
    //             Me = Pe - Mcnt;
    //         end 
    //     end
    // end

    // // bit swizzle results together
    // assign sum = {sign,Me,Mm[9:0]};

































// module fmaadd(  input logic [15:0] product, x, y, z,
//                 input logic         negz,
//                 output logic [15:0] sum);

//     logic [4:0]     Pe;     // sum of the product's exponents
//     logic [4:0]     Ze;     // z's exponent
//     //logic [4:0]     Acnt;    // alignment shift count
//     logic [6:0]     Acnt;    // alignment shift count

//     logic           Zs;     // Z's sign bit
//     logic           Ps;     // product's sign

//     logic [10:0]    Zm;
//     logic [10:0]    Pm;
//     //logic [33:0]    Am;      // shifted significand Perhaps it should be U915.21)?
//     //logic [33:0]    Sm;      // sum of aligned significands
//     logic [33:0]    Am;      // shifted significand Perhaps it should be U915.21)?
//     logic [33:0]    Sm;      // sum of aligned significands

//     //logic [22:0]    ZmPreShift; //Perhaps it should be U915.21)?
//     logic [43:0]    ZmPreShift;

//     logic [43:0]    ZmShift;    //Perhaps it should be U915.21)?
//     logic [43:0]    tempZmShift;
//     logic [33:0]    preSum;

//     logic [4:0]     Mcnt;    // num count for leading 1 normalization shift
//     logic [4:0]     normalMcnt;
//     logic [33:0]    tempMm;
//     logic [33:0]    tempMe;
//     logic [9:0]     Mm;  
//     logic [4:0]     Me;

//     logic           left;   // bit decides whether to shift to the left or right
//     logic [1:0]     nsig;   // one of the addends or insignificant
//     logic           sign;

//     logic [15:0]    tempZ;

//     logic [1:0]     addType;    // type of addition being performed

//     logic [33:0]    debugPm;
//     logic [33:0]    debugAm;

//     logic [33:0]    checkSm;
//     logic           subMcnt;

//     assign debugPm = {23'b0, Pm}; 
//     assign debugAm = ~Am + 1'b1;

//     assign tempZ = negz ? (~z + 1'b1) : z;

//     logic [21:0] multProd;
//     assign multProd = {1'b1, x[9:0]} * {1'b1, y[9:0]};

//     logic [33:0] debugMultProd;
//     assign debugMultProd = {multProd, 12'b0};


//     // add the exponents of x and y
//     assign Pe = x[14:10] + y[14:10] - 4'd15;
//     assign Ze = tempZ[14:10];

//     // product's mantissa
//     assign Pm = {1'b1,product[9:0]};
//     assign Zm = {1'b1, tempZ[9:0]};

//     // addend's sign
//     assign Zs = tempZ[15];
//     assign Ps = product[15];

//     // Z mantissa alignment shift alogrithm. First align the shift amount.
//     // Then preshift Z's mantissa all the way to the left then back to the right by Acnt.
//     always_comb begin : alignmentShift
//         Acnt = {2'b0, Pe} - {2'b0, Ze};// + 'd12;
//         ZmPreShift = {Zm, 33'b0};
//         ZmShift = ZmPreShift >> Acnt;
//         Am = ZmShift[43:10];
//     end

//     // Check for unecessary addition then assign the nsig flag a specific value to either telling the program that either
//     // the product dominates (transmit product), addend dominates (transmit addend), or neither dominates and perform normal floating point addition
//     always_comb begin : checkSignificance
//         if (($unsigned(Pe) > $unsigned(Ze)) && (($unsigned(Pe) - $unsigned(Ze)) >= 11))         nsig = 2'b01;  
//         else if (($unsigned(Ze) > $unsigned(Pe)) && (($unsigned(Ze) - $unsigned(Pe)) >= 11))    nsig = 2'b10; 
//         else                                                                                    nsig = 2'b00;
//     end

//     // compute mantissa's magnitude
//     // addType = 2'b00: unsigned addition
//     // addType = 2'b01: unsigned product and signed addend
//     // addType = 2'b10: signed product and unsigned addend
//     // addType = 2'b11: signed product and signed addend
//     always_comb begin : computeMantissas
//         if ((Ps ^ Zs) == 1'b1 && Zs == 1'b1)         
//             begin Sm = {Pm, 23'b0} - Am; addType = 2'b01; end 
//         else if ((Ps ^ Zs) == 1'b1 && Zs == 1'b0)    
//             begin Sm = (~{Pm, 23'b0} + 1'b1) + Am; addType = 2'b10; end 
//         else if ((Ps ^ Zs) == 1'b0 && Zs == 1'b0)    
//             begin Sm = {Pm, 23'b0} + Am;  addType = 2'b00; end
//         else                                                        
//             begin Sm = (~{Pm, 23'b0}+1'b1) + (~Am + 1'b1);addType = 2'b11; end
//     end


//     // always_comb begin : computeMantissas
//     //     if ((Ps ^ Zs) == 1'b1 && Zs == 1'b1)         
//     //         begin Sm = {1'b1, multProd, 11'b0} - Am; addType = 2'b01; end 
//     //     else if ((Ps ^ Zs) == 1'b1 && Zs == 1'b0)    
//     //         begin Sm = (~{multProd, 12'b0} + 1'b1) + Am; addType = 2'b10; end 
//     //     else if ((Ps ^ Zs) == 1'b0 && Zs == 1'b0)    
//     //         begin Sm = {1'b1, multProd, 11'b0} + Am; addType = 2'b00; end
//     //     else                                                        
//     //         begin Sm = (~{multProd, 12'b0}+1'b1) + (~Am + 1'b1); addType = 2'b11; end
//     // end

//     // compute sign...need to introduce negz logic here too which will add a little bit more work
//     always_comb begin : computeSign
//         if (addType == 2'b00) sign = '0;
//         else if (($unsigned({Pe, Pm}) > $unsigned({Ze, Zm})) && addType == 2'b01) sign = '0;
//         else if (($unsigned({Pe, Pm}) > $unsigned({Ze, Zm})) && addType == 2'b10) sign = '1;
//         else if (($unsigned({Ze, Zm}) > $unsigned({Pe, Pm})) && addType == 2'b01) sign = '1;
//         else if (($unsigned({Ze, Zm}) > $unsigned({Pe, Pm})) && addType == 2'b10) sign = '0;
//         else sign = '0; //(addType == 2'b11) sign = '0; 
//     end

//     // prepare Sm for normalization phase
//     always_comb begin : prepSm
//         if (Sm[33]) begin
//             checkSm = ~Sm + 1'b1;
//             subMcnt = 'b1;
//         end
//         else begin
//             checkSm = Sm;
//             subMcnt = 'b0;
//         end
//     end

//     integer i;
//     logic [$clog2(35)-1:0]  ZeroCnt;
//     // leading zero counter
//     always_comb begin : LZC
//         i = 0;
//         while ((i < 34) & ~checkSm[33-i]) i = i+1;  // search for leading one
//         ZeroCnt = i[$clog2(35)-1:0];
//     end

//     always_comb begin : calculateMantExp
//         if (nsig == 2'b01) begin 
//             Mm = product[9:0];
//             Me = product[14:10];
//             tempMm = '0;
//         end
//         else if (nsig == 2'b10) begin
//             Mm = z[9:0];
//             Me = z[14:10];
//             tempMm = '0;
//         end
//         else begin
//             tempMm = checkSm << ZeroCnt[5:0];
//             Mm = tempMm[33:24];
//             Me = Pe - ZeroCnt[4:0];
//         end
//     end

//     // bit swizzle results together
//     assign sum = {sign,Me,Mm};
// endmodule




















































// always_comb begin
    //     if (nsig == 2'b01) begin 
    //         Mm = product[9:0];
    //         Me = product[14:10];
    //         tempMm = '0;
    //     end
    //     else if (nsig == 2'b10) begin
    //         Mm = z[9:0];
    //         Me = z[14:10];
    //         tempMm = '0;
    //     end
    //     else begin
    //         if (left) begin 
    //             tempMm = Sm >> Mcnt;
    //             Mm = tempMm[19:10];
    //             Me = Pe + Mcnt;
    //         end 
    //         else begin
    //             tempMm = Sm << Mcnt;
    //             Mm = tempMm[19:10];
    //             Me = Pe - Mcnt;
    //         end 
    //     end
    // end




































// always_comb begin : computeMantissas
    //     if ((Ps ^ Zs) == 1'b1 && Zs == 1'b1)         
    //         begin Sm = {23'b0, Pm} - Am; addType = 2'b01; end 
    //     else if ((Ps ^ Zs) == 1'b1 && Zs == 1'b0)    
    //         begin Sm = (~{23'b0, Pm} + 1'b1) + Am; addType = 2'b10; end 
    //     else if ((Ps ^ Zs) == 1'b0 && Zs == 1'b0)    
    //         begin Sm = {23'b0, Pm} + Am;  addType = 2'b00; end
    //     else                                                        
    //         begin Sm = (~{23'b0, Pm}+1'b1) + (~Am + 1'b1);addType = 2'b11; end
    // end



    // shift to renormalize
    

// always_comb begin
//     if (nsig == 2'b01) begin 
//         // When one operand dominates, just pass through its values.
//         lz_int = 0;
//         calc_offset = 0;
//         Mm            = product[9:0];
//         Me            = product[14:10];
//         normalized_sm = 34'b0;
//         first_one_index = 0;
//         temp_exp = 0;
//     end else if (nsig == 2'b10) begin
//         lz_int = 0;
//         calc_offset = 0;
//         Mm            = z[9:0];
//         Me            = z[14:10];
//         first_one_index = 0;
//         normalized_sm = 34'b0;
//         temp_exp = 0;
//     end else begin
//         if (Sm[33]) begin
//             // When there's an extra carry bit, shift right and increment exponent.
//             lz_int = 0;
//             calc_offset = 0;
//             normalized_sm = Sm >> 1;
//             Mm            = normalized_sm[19:10];
//             Me            = Pe + 1;
//             first_one_index = 0;
//             temp_exp = 0;
//         end else begin
//             // Calculate the leading-zero count from checkSm.
//             lz_int = count_leading_zeros(checkSm);
//             // The index of the first '1' is (33 - lz_int).
//             first_one_index = 33 - lz_int;
//             // Determine the offset to position the first '1' at bit 19.
//             calc_offset = 20 - first_one_index;
            
//             if (calc_offset >= 0) begin
//                 // Shift left if the first '1' is too far right.
//                 normalized_sm = Sm << calc_offset;
//                 temp_exp = int'(Pe) - calc_offset;
//                 Me = temp_exp[4:0]; // Truncate to 5 bits for the exponent.
//             end else begin
//                 // Shift right if the first '1' is too far left.
//                 normalized_sm = Sm >> (-calc_offset);
//                 temp_exp = int'(Pe) + (-calc_offset);
//                 Me = temp_exp[4:0];
//             end
//             Mm = normalized_sm[19:10];
//         end
//     end
//end

//  // Function to count leading zeros in a 34-bit input.
//   // It iterates from the MSB (bit 33) down to bit 0, counting zeros until the first 1.
//     int i;
//     int count;
//   function automatic int count_leading_zeros(input logic [33:0] checkSm);
//     begin
//       count = 0;
//       for(i = 33; i >= 0; i--) begin
//          if(checkSm[i] == 1'b1) begin
//             break;  
//          end
//          count++;
//       end
//       return count;
//     end
//   endfunction

//     logic [33:0] normalized_sm;

//     int         lz_int;
//     logic [4:0] lz;
//     int         first_one_index;
//     int calc_offset; 
//     int temp_exp;


    //    // find the leading 1 for normalization shift
    // always_comb begin : priorityEncoder
    //     if (checkSm[33])         begin   Mcnt = 'd14;    left = 1;   end    // 22
    //     else if (checkSm[32])    begin   Mcnt = 'd13;    left = 1;   end    // 21
    //     else if (checkSm[31])    begin   Mcnt = 'd12;    left = 1;   end    // 20
    //     else if (checkSm[30])    begin   Mcnt = 'd11;    left = 1;   end    // 19 
    //     else if (checkSm[29])    begin   Mcnt = 'd10;    left = 1;   end    // 18
    //     else if (checkSm[28])    begin   Mcnt = 9;    left = 1;   end    // 17
    //     else if (checkSm[27])    begin   Mcnt = 8;    left = 1;   end    // 16
    //     else if (checkSm[26])    begin   Mcnt = 7;    left = 1;   end    // 15
    //     else if (checkSm[25])    begin   Mcnt = 6;    left = 1;   end    // 14
    //     else if (checkSm[24])    begin   Mcnt = 5;    left = 1;   end    // 13
    //     else if (checkSm[23])    begin   Mcnt = 4;    left = 1;   end    // 12
    //     else if (checkSm[22])    begin   Mcnt = 3;    left = 1;   end    // 11
    //     else if (checkSm[21])    begin   Mcnt = 2;    left = 1;   end    // 10
    //     else if (checkSm[20])    begin   Mcnt = 1;    left = 1;   end    // 9
    //     else if (checkSm[19])    begin   Mcnt = 0;       left = 0;   end    // 8
    //     else if (checkSm[18])    begin   Mcnt = 1;       left = 0;   end    // 7 
    //     else if (checkSm[17])    begin   Mcnt = 2;       left = 0;   end    // 6
    //     else if (checkSm[16])    begin   Mcnt = 3;       left = 0;   end    // 5
    //     else if (checkSm[15])    begin   Mcnt = 4;       left = 0;   end    // 4
    //     else if (checkSm[14])    begin   Mcnt = 5;       left = 0;   end    // 3
    //     else if (checkSm[13])    begin   Mcnt = 6;       left = 0;   end    // 2
    //     else if (checkSm[12])    begin   Mcnt = 7;       left = 0;   end    // 1
    //     else if (checkSm[11])    begin   Mcnt = 8;       left = 0;   end    // 0
    //     else if (checkSm[10])    begin   Mcnt = 0;       left = 0;   end // end of significant bits for rounding
    //     else if (checkSm[9])     begin   Mcnt = 1;       left = 0;   end
    //     else if (checkSm[8])     begin   Mcnt = 2;       left = 0;   end
    //     else if (checkSm[7])     begin   Mcnt = 3;       left = 0;   end
    //     else if (checkSm[6])     begin   Mcnt = 4;       left = 0;   end
    //     else if (checkSm[5])     begin   Mcnt = 5;       left = 0;   end
    //     else if (checkSm[4])     begin   Mcnt = 6;       left = 0;   end
    //     else if (checkSm[3])     begin   Mcnt = 7;       left = 0;   end
    //     else if (checkSm[2])     begin   Mcnt = 8;       left = 0;   end
    //     else if (checkSm[1])     begin   Mcnt = 9;       left = 0;   end
    //     else                begin   Mcnt = 'd10;    left = 0;   end
    // end

    // // find the leading 1 for normalization shift
    // always_comb begin : priorityEncoder
    //     if (checkSm[33])         begin   Mcnt = 'd23;    left = 1;   end     
    //     else if (checkSm[32])    begin   Mcnt = 'd22;    left = 1;   end
    //     else if (checkSm[31])    begin   Mcnt = 'd21;    left = 1;   end
    //     else if (checkSm[30])    begin   Mcnt = 'd20;    left = 1;   end
    //     else if (checkSm[29])    begin   Mcnt = 'd19;    left = 1;   end
    //     else if (checkSm[28])    begin   Mcnt = 'd18;    left = 1;   end
    //     else if (checkSm[27])    begin   Mcnt = 'd17;    left = 1;   end
    //     else if (checkSm[26])    begin   Mcnt = 'd16;    left = 1;   end
    //     else if (checkSm[25])    begin   Mcnt = 'd15;    left = 1;   end
    //     else if (checkSm[24])    begin   Mcnt = 'd14;    left = 1;   end
    //     else if (checkSm[23])    begin   Mcnt = 'd13;    left = 1;   end
    //     else if (checkSm[22])    begin   Mcnt = 'd12;    left = 1;   end
    //     else if (checkSm[21])    begin   Mcnt = 'd11;    left = 1;   end
    //     else if (checkSm[20])    begin   Mcnt = 'd10;    left = 1;   end
    //     else if (checkSm[19])    begin   Mcnt = 9;       left = 1;   end
    //     else if (checkSm[18])    begin   Mcnt = 8;       left = 1;   end
    //     else if (checkSm[17])    begin   Mcnt = 7;       left = 1;   end
    //     else if (checkSm[16])    begin   Mcnt = 6;       left = 1;   end
    //     else if (checkSm[15])    begin   Mcnt = 5;       left = 1;   end
    //     else if (checkSm[14])    begin   Mcnt = 4;       left = 1;   end
    //     else if (checkSm[13])    begin   Mcnt = 3;       left = 1;   end
    //     else if (checkSm[12])    begin   Mcnt = 2;       left = 1;   end
    //     else if (checkSm[11])    begin   Mcnt = 1;       left = 1;   end
    //     else if (checkSm[10])    begin   Mcnt = 0;       left = 0;   end
    //     else if (checkSm[9])     begin   Mcnt = 1;       left = 0;   end
    //     else if (checkSm[8])     begin   Mcnt = 2;       left = 0;   end
    //     else if (checkSm[7])     begin   Mcnt = 3;       left = 0;   end
    //     else if (checkSm[6])     begin   Mcnt = 4;       left = 0;   end
    //     else if (checkSm[5])     begin   Mcnt = 5;       left = 0;   end
    //     else if (checkSm[4])     begin   Mcnt = 6;       left = 0;   end
    //     else if (checkSm[3])     begin   Mcnt = 7;       left = 0;   end
    //     else if (checkSm[2])     begin   Mcnt = 8;       left = 0;   end
    //     else if (checkSm[1])     begin   Mcnt = 9;       left = 0;   end
    //     else                begin   Mcnt = 'd10;    left = 0;   end
    // end


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