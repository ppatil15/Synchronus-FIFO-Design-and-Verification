vlib work
vlog fifo.v
vlog fifo_tb.sv
vsim -voptargs=+acc work.fifo_tb
add wave -radix hexadecimal sim:/fifo_tb/dut/*
run -all
