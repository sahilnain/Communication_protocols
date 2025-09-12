module cocotb_iverilog_dump();
initial begin
    $dumpfile("sim_build/UART_WRAPPER.fst");
    $dumpvars(0, UART_WRAPPER);
end
endmodule
