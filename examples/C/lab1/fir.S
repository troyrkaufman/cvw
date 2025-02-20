// fir.S
// Troy Kaufman
// troykaufman28@gmail.com

/*  Q3.8
    The optimized version of this assembly code took 1597 cycles to complete. 
    My hand coded assembly was far slower than the optimized C code implementation.
    My code was slower than the optimized C code because my assembly implementation
    used lots of stores and loads that were in fact unnecessary. Additionally, I see that
    the C code objdump has a more efficient algorithm than my assembly version. 
*/

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

loop_i:
    bge t0, s0, end_i    # if j >= (n-m+1), exit loop
   
    li t3, 0          # Initialize sum = 0
    li t1, 0          # i counter (inner loop)

loop_j:
    bgt t1, s1, end_j    # if i > m-1, exit inner loop
   
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
    j loop_j


end_j:
    # Store result
    slli t6, t0, 2     # Convert j to byte offset
    add t6, s4, t6     # Address of y[j]
    sw t3, 0(t6)       # Store sum to y[j]
   
    addi t0, t0, 1     # j++
    j loop_i


end_i:
    ld s4, 0(sp)       # Restore callee-saved registers
    ld s3, 8(sp)
    ld s2, 16(sp)
    ld s1, 24(sp)
    ld s0, 32(sp)
    ld ra, 40(sp)      # Restore return address
    addi sp, sp, 48    # Deallocate stack space
    ret
