
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
                output logic [1:0]  sigNum);

    logic [4:0]     Pe;                 // sum of the product's exponents
    logic [4:0]     Ze;                 // z's exponent
    logic [6:0]     Acnt;               // alignment shift count
    logic           Zs;                 // Z's sign bit
    logic           Ps;                 // product's sign
    logic [10:0]    Zm;                 // Z's mantissa with prepended 1
    logic [21:0]    Pm;
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

    // calculate Pe and check for small exponential cases
    always_comb begin : calcTypePe
        if (mul && add) Pe = product[14:10];
        else            Pe = x[14:10] + y[14:10] - 4'd15;     

        if (x[14:10] + y[14:10] < 15)   flipPeFlag = 1'b1;
        else                            flipPeFlag = 1'b0;
    end
    
    // Z's exponent
    assign Ze = z[14:10];

    // product's mantissa
    assign Pm = fullPm[21] ? {1'b1, fullPm[20:0]} : {1'b1, fullPm[19:0], 1'b0};
    assign Zm = (z == 'h0000 | z == 'h8000) ? 'h0 : {1'b1, z[9:0]};

    // Z's and product's signs
    assign Zs = z[15];
    assign Ps = product[15];

    // exponent comparison that will dictate how Pm or Am will be shifted
    assign compExpFlag = ($unsigned(Pe) > $unsigned(Ze)) ? 1'b1 : 1'b0;

    // Z mantissa alignment shift alogrithm. First compute difference between Pe and Ze and set/reset Pm shifting flag.
    // Then preshift Z's mantissa all the way to the left then shift Pm or Am to the right by Acnt.
    always_comb begin : alignmentShift
        if (compExpFlag) begin Acnt = {2'b0, Pe} - {2'b0, Ze}; shiftPmFlag = 1'b0; end 
        else             begin Acnt = {2'b0, Ze} - {2'b0, Pe}; shiftPmFlag = 1'b1; end 
        ZmPreShift = {Zm, 12'b0}; 
        if (shiftPmFlag) begin  shiftPm = {1'b0, Pm, 11'b0} >> (Acnt); ZmShift = {ZmPreShift, 21'b0}; end
        else begin              shiftPm = {1'b0, Pm, 11'b0}; ZmShift = {ZmPreShift, 21'b0} >> (Acnt); end
        Am = ZmShift[43:10];
    end

    // Check for unecessary addition then assign the nsig flag a specific value to tell the program that either
    // the product dominates (transmit product), Z dominates (transmit addend), or neither dominates and perform normal floating point addition.
    always_comb begin : checkSignificance
        if (($unsigned(Pe) > $unsigned(Ze)) && (($unsigned(Pe) - $unsigned(Ze)) > 11) && ~flipPeFlag)   nsig = 2'b01;  
        else if (($unsigned(Ze) > (~Pe + 1'b1)) && (($unsigned(Ze) - (~Pe + 1)) > 11) && flipPeFlag)    nsig = 2'b10;
        else if ((Ze < Pe) && (Ze - Pe < -'d11))                                                        nsig = 2'b10;
        else                                                                                            nsig = 2'b00;
    end

    // compute mantissa's magnitude
    // addType = 2'b00: positive addition
    // addType = 2'b01: positive product and negative addend
    // addType = 2'b10: negative product and positive addend
    // addType = 2'b11: negative product and negative addend
    always_comb begin : computeIntermediateMantissa
        if ((Ps ^ Zs) == 1'b1 && Zs == 1'b1)         
            begin Sm = shiftPm - (Am>>1);           addType = 2'b01; end 
        else if ((Ps ^ Zs) == 1'b1 && Zs == 1'b0)    
            begin Sm = (~shiftPm + 1'b1) + (Am>>1); addType = 2'b10; end 
        else if ((Ps ^ Zs) == 1'b0 && Zs == 1'b0)    
            begin Sm = shiftPm + (Am>>1);           addType = 2'b00; end
        else                                                        
            begin Sm = shiftPm + (Am>>1);           addType = 2'b11;end
    end

    // compute sign
    always_comb begin : computeSign
        if (addType == 2'b00) sign = '0;
        else if (($unsigned({Pe, Pm}) > $unsigned({Ze, Zm, 11'b0})) && addType == 2'b01) sign = '0;
        else if (($unsigned({Pe, Pm}) > $unsigned({Ze, Zm, 11'b0})) && addType == 2'b10) sign = '1;
        else if (($unsigned({Ze, Zm, 11'b0}) > $unsigned({Pe, Pm})) && addType == 2'b01) sign = '1;
        else if (($unsigned({Ze, Zm, 11'b0}) > $unsigned({Pe, Pm})) && addType == 2'b10) sign = '0;
        else if (addType == 2'b11)                                                sign = '1;
        else                                                                      sign = '0; 
    end

    // prepare Sm for normalization phase
    assign checkSm = (Sm[33] && ~(addType == 2'b00 || addType == 2'b11)) ? ~Sm + 1'b1 : Sm; 

    // leading zero counter
    always_comb begin : LZC
        i = 0;
        while ((i < 34) & ~checkSm[33-i]) i = i+1;  
        ZeroCnt = i[$clog2(35)-1:0];
    end

    // calculate the real mantissa and exponent
    always_comb begin : calculateMantExp
        if (nsig == 2'b01)                                      begin Mm = product[9:0]; Me = product[14:10]; tempMm = '0; end
        else if ((nsig == 2'b10) | (product[14:0] == 15'h0000)) begin Mm = z[9:0]; Me = z[14:10]; tempMm = '0; end
        else begin
            if (addType == 2'b00 && checkSm[33] && ~(shiftPmFlag)) begin 
                tempMm = checkSm << ZeroCnt; Mm = tempMm[32:23]; Me = Pe + 1'b1;
            end
            else begin
                tempMm = checkSm << ZeroCnt; Mm = tempMm[32:23];
                if (shiftPmFlag)    Me = Pe - ZeroCnt[4:0] + Acnt[4:0] + 'b1;
                else                Me = Pe - ZeroCnt[4:0] + 'b1;
            end
        end
    end

    assign fullSum = checkSm<<ZeroCnt;
    assign sigNum = nsig;
    // bit swizzle results together
    assign sum = {sign,Me,Mm};
endmodule