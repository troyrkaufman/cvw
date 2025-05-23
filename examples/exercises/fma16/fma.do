# fma.do 
#
# run with vsim -do "do fma.do"
# add -c before -do for batch simulation

onbreak {resume}

# create library
vlib worklib

#vlog -lint -sv -work worklib fma16.sv testbench.sv  - missing fmamult.sv
vlog -lint -sv -work worklib fma16.sv testbench.sv fmamult.sv fmaadd.sv specialCases.sv fmaround.sv
vopt +acc worklib.testbench_fma16 -work worklib -o testbenchopt
vsim -lib worklib testbenchopt

add wave sim:/testbench_fma16/clk
add wave sim:/testbench_fma16/reset
add wave sim:/testbench_fma16/roundmode
add wave sim:/testbench_fma16/x
add wave sim:/testbench_fma16/y
add wave sim:/testbench_fma16/z
add wave sim:/testbench_fma16/result
add wave sim:/testbench_fma16/rexpected
add wave sim:/testbench_fma16/dut/addunit/fullSum
add wave sim:/testbench_fma16/dut/roundunit/fullPm
add wave sim:/testbench_fma16/dut/addunit/Acnt
add wave sim:/testbench_fma16/dut/addunit/nsig
add wave sim:/testbench_fma16/dut/addunit/addType
add wave sim:/testbench_fma16/dut/addunit/debugNegPm
add wave sim:/testbench_fma16/dut/addunit/debugNegAm
add wave sim:/testbench_fma16/dut/addunit/checkSm 
add wave sim:/testbench_fma16/dut/addunit/Mm
add wave sim:/testbench_fma16/dut/addunit/Me
add wave sim:/testbench_fma16/dut/addunit/sign
add wave sim:/testbench_fma16/dut/addunit/checkPe


add wave sim:/testbench_fma16/flags
add wave sim:/testbench_fma16/flagsexpected
add wave sim:/testbench_fma16/dut/specCase/specialCaseFlag
add wave sim:/testbench_fma16/dut/roundunit/roundFlag


#####Put relevant signals above######

# Mult unit
add wave sim:/testbench_fma16/dut/multunit/multMant
add wave sim:/testbench_fma16/dut/multunit/shiftMant
add wave sim:/testbench_fma16/dut/multunit/exp
add wave sim:/testbench_fma16/dut/multunit/sign
add wave sim:/testbench_fma16/dut/multunit/checkExpFlag
add wave sim:/testbench_fma16/dut/multunit/checkExpHigh
add wave sim:/testbench_fma16/dut/multunit/checkExpLow
add wave sim:/testbench_fma16/dut/multunit/zeroExp
add wave sim:/testbench_fma16/dut/addunit/product

# General signals for +- and operations
add wave sim:/testbench_fma16/dut/negz
add wave sim:/testbench_fma16/dut/negp
add wave sim:/testbench_fma16/dut/mul
add wave sim:/testbench_fma16/dut/add
add wave sim:/testbench_fma16/dut/flipZ
add wave sim:/testbench_fma16/dut/flipX
add wave sim:/testbench_fma16/dut/addunit/Pe
add wave sim:/testbench_fma16/dut/addunit/Ze

add wave sim:/testbench_fma16/dut/addunit/Ps
add wave sim:/testbench_fma16/dut/addunit/Zs
add wave sim:/testbench_fma16/dut/addunit/sum

# signals for from specialCases.sv

add wave sim:/testbench_fma16/dut/specCase/oFFlag 
#add wave sim:/testbench_fma16/dut/specCase/uFFlag 
add wave sim:/testbench_fma16/dut/specCase/inVFlag
add wave sim:/testbench_fma16/dut/specCase/inXFlag  
add wave sim:/testbench_fma16/dut/specCase/flags
add wave sim:/testbench_fma16/dut/specCase/result
add wave sim:/testbench_fma16/dut/addunit/tempMm
#add wave sim:/testbench_fma16/dut/specCase/nonZeroResults
#add wave sim:/testbench_fma16/dut/specCase/of

# fmaround signals

add wave sim:/testbench_fma16/dut/roundunit/lsb
add wave sim:/testbench_fma16/dut/roundunit/lsbPrime
add wave sim:/testbench_fma16/dut/roundunit/guard
add wave sim:/testbench_fma16/dut/roundunit/rndPrime
add wave sim:/testbench_fma16/dut/roundunit/rnd
add wave sim:/testbench_fma16/dut/roundunit/sticky
add wave sim:/testbench_fma16/dut/roundunit/stickyPrime 
add wave sim:/testbench_fma16/dut/roundunit/roundResult
add wave sim:/testbench_fma16/dut/roundunit/nonZeroMantFlag
add wave sim:/testbench_fma16/dut/roundunit/fullPm



#add wave sim:/testbench_fma16/dut/addunit/signedPe
#add wave sim:/testbench_fma16/dut/addunit/unsignedZe
#add wave sim:/testbench_fma16/dut/addunit/unsignedPe
#add wave sim:/testbench_fma16/dut/addunit/debugSignificance


add wave sim:/testbench_fma16/dut/addunit/Pm
add wave sim:/testbench_fma16/dut/addunit/Zm


add wave sim:/testbench_fma16/dut/addunit/Acnt
add wave sim:/testbench_fma16/dut/addunit/nsig
add wave sim:/testbench_fma16/dut/addunit/flipPeFlag
#add wave sim:/testbench_fma16/dut/addunit/ZmPreShift
#add wave sim:/testbench_fma16/dut/addunit/ZmShift
add wave sim:/testbench_fma16/dut/addunit/addType

#add wave sim:/testbench_fma16/dut/addunit/compExp
#add wave sim:/testbench_fma16/dut/addunit/compMant 

add wave sim:/testbench_fma16/dut/addunit/shiftPmFlag 

add wave sim:/testbench_fma16/dut/addunit/shiftPm
add wave sim:/testbench_fma16/dut/addunit/Am
#add wave sim:/testbench_fma16/dut/addunit/PeTemp
#add wave sim:/testbench_fma16/dut/addunit/Sm 

#add wave sim:/testbench_fma16/dut/addunit/Amshifted

add wave sim:/testbench_fma16/dut/addunit/checkSm 
#add wave sim:/testbench_fma16/dut/addunit/i
add wave sim:/testbench_fma16/dut/addunit/ZeroCnt


#add wave sim:/testbench_fma16/dut/addunit/tempMm
add wave sim:/testbench_fma16/dut/addunit/Mm
add wave sim:/testbench_fma16/dut/addunit/Me
add wave sim:/testbench_fma16/dut/addunit/sign

run -all
