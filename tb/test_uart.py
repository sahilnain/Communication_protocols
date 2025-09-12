# Sahil: Test script for UART module

import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer

async def generate_clock(dut):
    """Generate clock pulses."""
    for _ in range(100):
        dut.clk.value = 0
        await Timer(1, units="ns")
        dut.clk.value = 1
        await Timer(1, units="ns")
    
@cocotb.test()
async def test_uart(dut):
    # Initialization
    dut.reset.value  = 0
    dut.TxData.value = 0
    dut.TxReq.value  = 0

    await cocotb.start(generate_clock(dut))  # run the clock "in the background"
    await Timer(5, units="ns")  # wait a bit
    # await FallingEdge(dut.clk)  # wait for falling edge/"negedge"

    # Pull out of reset
    dut.reset.value = 1

    # Testing
    test_byte           = 0xDEADBEEF
    dut.TxData.value    = test_byte

    dut.TxReq.value     = 1
    # await Timer(2, units="ns")  # wait a bit
    # dut.TxReq.value     = 0
    
    await FallingEdge(dut.TxBusy)  # wait for falling edge/"negedge"

    dut._log.info("UART transmitted 0x%02X", test_byte) 
    dut._log.info("UART Received 0x%02X", dut.RxData.value) 
