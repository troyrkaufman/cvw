
// fmaadd.sv
// Troy Kaufman
// tkaufman@g.hmc.edu
// 3/14/17
// Purpose: Half-precision floating point addition that works with normalized positive and signed values

module fmaadd(  input logic [15:0]  product, x, y, z,
                input logic [21:0]  fullPm,
                input logic         mul, add,
                output logic [15:0] sum,
                output logic [33:0] fullSum, 
                output logic [1:0]  nSigFlag, additionType,
                output logic        checkMSB);

    logic [4:0]     Pe;                 // sum of the product's exponents
    logic [4:0]     Ze;                 // z's exponent
    logic [6:0]     Acnt;               // alignment shift count
    logic           Zs;                 // Z's sign bit
    logic           Ps;                 // product's sign
    logic [10:0]    Zm;                 // Z's mantissa with prepended 1
    logic [21:0]    Pm;                 // product's unaltered mantissa
    logic [33:0]    Am;                 // Z's aligned mantissa
    logic [33:0]    Sm;                 // sum of aligned significands
    logic [22:0]    ZmPreShift;         // shits Z's mantissa to the MSB
    logic [43:0]    ZmShift;            // shifts  
    logic [33:0]    tempMm;             // holds shifted value for the final mantissa calculation
    logic [9:0]     Mm;                 // final shifted mantissa for sum
    logic [4:0]     Me;                 // final calculated exponent for sum 
    logic [1:0]     nsig;               // insignificant encoding for products and addends
    logic           sign;               // final calculated sign for sum
    logic [1:0]     addType;            // type of addition being performed 
    logic [33:0]    checkSm;            // takes magnitude of Sm after summation
    logic           compExpFlag;        // checks the difference between the product's and addend's exponents
    logic           shiftPmFlag;        // determines if Pm will be shifted to align with Am>>1
    logic [33:0]    shiftPm;            // the aligned Pm bus with Am>>1
    logic           flipPeFlag;         // helps determine if either the product or addend should be killed
    integer i;                          // integer counter for recording the number of 0s in a bus    
    logic [$clog2(35)-1:0]  ZeroCnt;    // logic value that holds the integer i
    logic [4:0]     productExp;          // sum of X's and Y's exponents

    assign productExp = x[14:10] + y[14:10];

    // calculate product's exponent based on operation and check for small exponential cases
    always_comb begin : calcTypePe
        if (mul && add) Pe = product[14:10];
        else            Pe = productExp - 5'd15; 

        // produces a flag that determines if the sum of the factors' exponents are less than 15 which will be used in killing the product/addend logic    
        if ((x[14:10] + y[14:10]) <= 'd15)   flipPeFlag = 1'b1;
        else                                 flipPeFlag = 1'b0;
    end
    
    // Z's exponent
    assign Ze = z[14:10];

    // product's mantissa based on the MSB in the unaltered product's mantissa
    assign Pm = fullPm[21] ? {1'b1, fullPm[20:0]} : {1'b1, fullPm[19:0], 1'b0};

    // addend's mantissa prepends the leading one if it isn't a +- zero
    assign Zm = (z == 'h0000 | z == 'h8000) ? 'h0 : {1'b1, z[9:0]};

    // Z's sign
    assign Zs = z[15];

    // product's sign
    assign Ps = product[15];

    // exponent comparison that will dictate whether the product's or addend's mantissa will be shifted during the sum calculation
    assign compExpFlag = ($unsigned(Pe) > $unsigned(Ze)); 

    // addend's and product's normalized mantissa algorithm pre-summation where the smaller exponent between the product and addend will have its mantissa shifted. 
    // Depending on the compExpFlag, the exponents will be subtracted from one another so that the result is a positive value and a shift product's mantissa 
    // flag will be asserted. The addend's mantissa will be shifted all the way to the left in the bus as shown in ZmPreShift. Depending on the shiftPmFlag, 
    // either the unaltered product's mantissa or addend's mantissa will be shifted to the right depending on the exponent difference to properly align both numbers. 
    // Then the addend's mantissa is retrieved in a smaller bus so that both the altered product's mantissa and altered addend's mantissa are the same bit width. 
    always_comb begin : alignmentShiftPreSum
        if (compExpFlag) begin Acnt = {2'b0, Pe} - {2'b0, Ze}; shiftPmFlag = 1'b0; end 
        else             begin Acnt = {2'b0, Ze} - {2'b0, Pe}; shiftPmFlag = 1'b1; end 
        ZmPreShift = {Zm, 12'b0}; 
        if (shiftPmFlag) begin  shiftPm = {1'b0, Pm, 11'b0} >> (Acnt); ZmShift = {ZmPreShift, 21'b0}; end
        else             begin  shiftPm = {1'b0, Pm, 11'b0}; ZmShift = {ZmPreShift, 21'b0} >> (Acnt); end
        Am = ZmShift[43:10];
    end

    // Check for unecessary addition then assign the nsig flag a specific value to tell the program that either the product dominates (transmit product nsig = 2'b01), 
    // Z dominates (transmit addend nsig = 2'b10), or neither dominates and perform normal floating point addition (nsig = 2'b00).
    always_comb begin : checkSignificance
        if (($unsigned(Pe) > $unsigned(Ze)) & (($unsigned(Pe) - $unsigned(Ze)) > 11) & ~flipPeFlag)   nsig = 2'b01;  
        else if (($unsigned(Ze) > (~Pe + 1'b1)) & (($unsigned(Ze) - (~Pe + 1'b1)) > 11) & flipPeFlag) nsig = 2'b10;
        else if ((Ze < Pe) & (Ze - Pe < -'d11))                                                       nsig = 2'b10;
        else                                                                                          nsig = 2'b00;
    end

    // compute mantissa's magnitude. It's necessary to right shift Am by one to account for potential overflow. addType will be used for sign computation and post 
    // summation normalization 
    // addType = 2'b00: positive product and positive addend
    // addType = 2'b01: positive product and negative addend
    // addType = 2'b10: negative product and positive addend
    // addType = 2'b11: negative product and negative addend
    always_comb begin : computeIntermediateMantissa
        if ((Ps ^ Zs) == 1'b1 & (Zs == 1'b1))         begin Sm = shiftPm - (Am>>1);     addType = 2'b01; end 
        else if (((Ps ^ Zs) == 1'b1) & (Zs == 1'b0))  begin Sm = (-shiftPm) + (Am>>1);  addType = 2'b10; end 
        else if (((Ps ^ Zs) == 1'b0) & (Zs == 1'b0))  begin Sm = shiftPm + (Am>>1);     addType = 2'b00; end
        else                                          begin Sm = shiftPm + (Am>>1);     addType = 2'b11; end
    end

    logic [33:0]    debugNegPm, debugNegAm;
    assign debugNegAm = ((~Am+1)>>1);
    assign debugNegPm = ~shiftPm + 1;

    logic [4:0] checkPe;
    assign checkPe = (flipPeFlag&(Ps^Zs)) ? productExp : Pe;

    // compute sign. Similar sign addition will result in a sign of 0 like 2'b00 and 2'b11. Mixed sign addition depends on the product's and addend's exponent and mantissa magnitudes. 
    always_comb begin : computeSign
        if (addType == 2'b00)                                                               sign = '0;
        else if (($unsigned({Pe, Pm}) > $unsigned({Ze, Zm, 11'b0})) && addType == 2'b01)    sign = '0;
        else if (($unsigned({Pe, Pm}) > $unsigned({Ze, Zm, 11'b0})) && addType == 2'b10)    sign = '1;
        else if (($unsigned({Ze, Zm, 11'b0}) >= $unsigned({Pe, Pm})) && addType == 2'b01)   sign = '1;
        else if (($unsigned({Ze, Zm, 11'b0}) > $unsigned({Pe, Pm})) && addType == 2'b10)    sign = '0;
        else if (addType == 2'b11)                                                          sign = '1;
        else                                                                                sign = '1; 
    end

    // prepare Sm for normalization phase. At this point Sm might be inverted after the summation. Checking Sm's MSB and the current addType holds enough information to properly 
    // obtain the unnormalized sum mantissa
    assign checkSm = (Sm[33] && ~(addType == 2'b00 || addType == 2'b11)) ? ~Sm + 1'b1 : Sm; 

    // leading zero counter. The output is used for normalization logic. Credit goes to me@KatherineParry.com.
    always_comb begin : LZC
        i = 0;
        while ((i < 34) & ~checkSm[33-i]) i = i+1;  
        ZeroCnt = i[$clog2(35)-1:0];
    end

    // normalize mantissa and exponent post summation. The insignificant flags describe whether we had to kill the product or addend which becomes a crucial input for the rounding logic. 
    // The default branch of the conditional checks if the addition was calculated to a value above two. Hence the exponent is incemented by one and the mantissa is shifted according to 
    // the number of leading zeros found in the LZC. The other half of this branch shifts the mantissa as before with the LZC but checks if the product's mantissa was shifted for pre sum
    // normalization. If so, the exponent difference between the product and addend is included in the sum's exponent calculation and exlcuded if the flag was set low. 
    always_comb begin : calculateMantExp
        if (nsig == 2'b01)                                      
            begin Mm = product[9:0]; Me = product[14:10]; tempMm = '0; end
        else if ((nsig == 2'b10)) 
            begin Mm = z[9:0]; Me = z[14:10]; tempMm = '0; end
        // else if ((addType == 2'b01)&(product[14:10]=='0)&(Ps^Zs)) // RZ only
        //     begin 
        //         tempMm = '0;                        // OPTIMIZE!!!!!!
        //         Mm = z[9:0] - 1; 
        //         Me = z[14:10];
        //     end
        //     else if ((addType == 2'b00)&(product[14:10]=='0)&(Ps~^Zs)) // RZ only
        //     begin 
        //         tempMm = '0;                        
        //         Mm = z[9:0]; 
        //         Me = z[14:10];
        //     end
        else 
            if (((addType == 2'b00) & checkSm[33] & ~shiftPmFlag)) // might need to get rid of the second part
                begin   tempMm = checkSm << ZeroCnt;                // Only have one of these for
                        Mm = tempMm[32:23]; 
                        Me = Pe + 1'b1; 
                end
            else                                                   
                begin   tempMm = checkSm << ZeroCnt; 
                        Mm = tempMm[32:23]; 
                if (shiftPmFlag)    Me = Pe - ZeroCnt[4:0] + Acnt[4:0] + 'b1;
                else                Me = Pe - ZeroCnt[4:0] + 'b1;
            end
    end

    /*
        outline: if product's expoenent is zero, take addend's value
        if opposite signs subtract by 1. If same sign keep addend's value. no rounding required.
    */

    // summed mantissa that is properly normalized. This value is crucial for the rounding logic.
    assign fullSum = checkSm<<ZeroCnt;
    assign checkMSB = checkSm[33];

    // Determines what type of insignficant addition took place. This is crucial information for the rounding logic.
    assign nSigFlag = nsig;

    // bit swizzle results together for the sum
    assign sum = {sign,Me,Mm};

    assign additionType = addType;
    
endmodule