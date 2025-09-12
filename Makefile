TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(shell pwd)/rtl/UART.sv \
					$(shell pwd)/rtl/UART_WRAPPER.sv
TOPLEVEL = UART_WRAPPER
MODULE = tb.test_uart
SIM = icarus
WAVES = 1

include $(shell cocotb-config --makefiles)/Makefile.sim
