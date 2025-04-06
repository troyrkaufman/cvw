 // Function to count leading zeros in a 34-bit input.
  // It iterates from the MSB (bit 33) down to bit 0, counting zeros until the first 1.
    int i;
    int count;
  function automatic int count_leading_zeros(input logic [33:0] checkSm);
    begin
      count = 0;
      for(i = 33; i >= 0; i--) begin
         if(checkSm[i] == 1'b1) begin
            break;  
         end
         count++;
      end
      return count;
    end
  endfunction


module lzc()
