# fma.do 
#
# run with vsim -do "do fma.do"
# add -c before -do for batch simulation

onbreak {resume}

# create library
vlib worklib

#vlog -lint -sv -work worklib fma16.sv testbench.sv  - missing fmamult.sv
vlog -lint -sv -work worklib fma16.sv testbench.sv fmamult.sv fmaadd.sv
vopt +acc worklib.testbench_fma16 -work worklib -o testbenchopt
vsim -lib worklib testbenchopt

add wave sim:/testbench_fma16/clk
add wave sim:/testbench_fma16/reset
add wave sim:/testbench_fma16/x
add wave sim:/testbench_fma16/y
add wave sim:/testbench_fma16/z
add wave sim:/testbench_fma16/result
add wave sim:/testbench_fma16/rexpected

add wave sim:/testbench_fma16/dut/addunit/product
add wave sim:/testbench_fma16/dut/negz
add wave sim:/testbench_fma16/dut/negp
add wave sim:/testbench_fma16/dut/mul
add wave sim:/testbench_fma16/dut/add
add wave sim:/testbench_fma16/dut/flipZ
add wave sim:/testbench_fma16/dut/addunit/Pe
add wave sim:/testbench_fma16/dut/addunit/Ze
add wave sim:/testbench_fma16/dut/addunit/signedZe
add wave sim:/testbench_fma16/dut/addunit/signedPe
add wave sim:/testbench_fma16/dut/addunit/unsignedZe
add wave sim:/testbench_fma16/dut/addunit/unsignedPe
add wave sim:/testbench_fma16/dut/addunit/debugSignificance
add wave sim:/testbench_fma16/dut/addunit/flipPeFlag

add wave sim:/testbench_fma16/dut/addunit/Pm
add wave sim:/testbench_fma16/dut/addunit/Zm


add wave sim:/testbench_fma16/dut/addunit/Acnt
add wave sim:/testbench_fma16/dut/addunit/nsig
add wave sim:/testbench_fma16/dut/addunit/ZmPreShift
add wave sim:/testbench_fma16/dut/addunit/ZmShift
add wave sim:/testbench_fma16/dut/addunit/addType

#add wave sim:/testbench_fma16/dut/addunit/compExp
#add wave sim:/testbench_fma16/dut/addunit/compMant 

add wave sim:/testbench_fma16/dut/addunit/shiftPmFlag 

add wave sim:/testbench_fma16/dut/addunit/debugAm
add wave sim:/testbench_fma16/dut/addunit/debugPm

#add wave sim:/testbench_fma16/dut/addunit/multProd
#add wave sim:/testbench_fma16/dut/addunit/debugMultProd
add wave sim:/testbench_fma16/dut/addunit/shiftPm
add wave sim:/testbench_fma16/dut/addunit/Am
add wave sim:/testbench_fma16/dut/addunit/Sm 

#add wave sim:/testbench_fma16/dut/addunit/Amshifted

add wave sim:/testbench_fma16/dut/addunit/checkSm 
add wave sim:/testbench_fma16/dut/addunit/i
add wave sim:/testbench_fma16/dut/addunit/ZeroCnt


#add wave sim:/testbench_fma16/dut/addunit/tempMm
add wave sim:/testbench_fma16/dut/addunit/Mm
add wave sim:/testbench_fma16/dut/addunit/Me
add wave sim:/testbench_fma16/dut/addunit/sign


#run 300 ns
run -all
