// fir.S
// Troy Kaufman


// FIR filter implementation in assembly


.global fir


add_q31:
    addw a0, a0, a1    # Add a + b (word-sized)
    ret


mul_q31:
    mul a0, a0, a1     # Multiply a0 * a1
    srai a0, a0, 31    # Shift right to maintain Q31 format
    ret


fir:
    # Prologue
    addi sp, sp, -48   # Allocate stack space
    sd ra, 40(sp)      # Save return address
    sd s0, 32(sp)      # Save callee-saved registers
    sd s1, 24(sp)
    sd s2, 16(sp)
    sd s3, 8(sp)
    sd s4, 0(sp)


    # Initialize loop bounds
    sub s0, a3, a4     # s0 = n - m
    addi s0, s0, 1     # s0 = n - m + 1 (outer loop limit)
    addi s1, a4, -1    # s1 = m - 1 (inner loop limit)
   
    # Save base addresses
    mv s2, a0          # s2 = x[]
    mv s3, a1          # s3 = c[]
    mv s4, a2          # s4 = y[]
   
    li t0, 0          # j counter (outer loop)


outer_loop:
    bge t0, s0, end_outer    # if j >= (n-m+1), exit loop
   
    li t3, 0          # Initialize sum = 0
    li t1, 0          # i counter (inner loop)


inner_loop:
    bgt t1, s1, end_inner    # if i > m-1, exit inner loop
   
    # Calculate indices and load values
    sub t4, t0, t1     # t4 = j - i
    add t4, t4, s1     # t4 = j - i + (m-1)
    slli t4, t4, 2     # Convert to byte offset
    add t4, s2, t4     # Address of x[j-i+(m-1)]
    lw a1, 0(t4)       # Load x[j-i+(m-1)]
   
    slli t5, t1, 2     # Convert i to byte offset
    add t5, s3, t5     # Address of c[i]
    lw a0, 0(t5)       # Load c[i]
   
    # Multiply and accumulate
    call mul_q31       # Multiply c[i] * x[j-i+(m-1)]
    mv a1, t3          # Move current sum to a1
    call add_q31       # Add to accumulator
    mv t3, a0          # Store result back to accumulator
   
    addi t1, t1, 1     # i++
    j inner_loop


end_inner:
    # Store result
    slli t6, t0, 2     # Convert j to byte offset
    add t6, s4, t6     # Address of y[j]
    sw t3, 0(t6)       # Store sum to y[j]
   
    addi t0, t0, 1     # j++
    j outer_loop


end_outer:
    # Epilogue
    ld s4, 0(sp)       # Restore callee-saved registers
    ld s3, 8(sp)
    ld s2, 16(sp)
    ld s1, 24(sp)
    ld s0, 32(sp)
    ld ra, 40(sp)      # Restore return address
    addi sp, sp, 48    # Deallocate stack space
    ret
/*
.global fir
add:
    addw a0, a0, a1   # Add a + b (word-sized)
    ret               # Return


mult:
    #la t6, begin_signature # address of signature
    mul a0, a0, a1    # Multiply a0 * a1
    srai a0, a0, 31   # Shift right to maintain Q31 format
    #sd a0, 0(t6)      # store product in signature
    ret


fir:
    addi sp, sp, -40  # Allocate stack space
    sd s0, 0(sp)     # Save S0 on stack for i
    sd s1, 8(sp)     # Save S1 on stack for j
    sd s2, 16(sp)     # Save data for i loop condition
    sd s3, 24(sp)    # Save data for j loop condition
    sd ra, 32(sp)    # Save return address


    # Initialize i loop
    li s0, 0          # i = 0
    # a0 = a, a1 = b ||||| a0 = x[], a1 = c[], a2 = y[], a3 = n, a4 = m
    sub s2, a3, a4    # s2 = n - m
    addi s2, s2, 1    # s2 = n - m + 1 (loop limit)
    addi s3, a4, -1     # s3 = m - 1     (loop limit)
    mv t3, a0            # store X* in t3 to later allow a0 = c[j]...
    mv t5, a1            # store C* in t5


loop_i:
    bgt s0, s2, end_i  # if i > (n - m + 1), exit loop


    li t1, 0             # round_val = 0 PREV t1
    li t2, 0             # temp = 0      PREV t5
    li s1, 0             # j = 0 (Points at the current element in each array)


loop_j:
    bgt s1, s3, end_j    # if j > m - 1, exit inner loop


   
    slli t0, s1, 2       # t0 = j * 4 ...convert to bytes
    add t0, t0, t5       # Address of c[j]
    lw a0, 0(t0)         # a0 = c[j] YOOOOOO!!!!! EXCEPTION TRAP HANDLER on second pass


    sub t4, s0, s1       # t4 = i - j
    add t4, t4, s3       # t4 = i - j + (m - 1)
    slli t4, t4, 2       # convert to bytes
    add t4, t4, t3       # Address of x[i - j + (m - 1)]
    lw a1, 0(t4)         # load x[i - j + (m - 1)] in a1


    call mult            # calls mult function...pretty cool


    # At this point the 32 bit number is in the a0 register and a1 has nonsense
   
    mv a1, t1            # Moved round_val into a1  


    call add             # calls add function
    mv t1, a0            # round_val = add(temp, round_val)  
   
    addi s1, s1, 1       # j++
    j loop_j             # loop back into the nested for loop


end_j:
    addi t3, zero, 0     # reset t3 register to avoid compounding value
    slli t3, s0, 2       # Accout for offset for i
    add t3, a2, t3       # add offset to Y*'s address
    sw t1, 0(t3)         # y[i] = round_val


    addi s0, s0, 1       # i++
    j loop_i             # loop back to the outer for loop


end_i:
    ld ra, 32(sp)
    ld s3, 24(sp)
    ld s2, 16(sp)
    ld s1, 8(sp)
    ld s0, 0(sp)
    addi sp, sp, 40
    ret                  # return from fir function




*/
