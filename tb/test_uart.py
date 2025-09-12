# Sahil: Test script for UART module

import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer

async def reset_dut(dut):
    dut.reset.value = 0
    await Timer(5, units="ns")  # wait a bit
    # Pull out of reset
    dut.reset.value = 1

async def generate_clock(dut):
    """Generate clock pulses."""
    while(1):
        dut.clk.value = 0
        await Timer(1, units="ns")
        dut.clk.value = 1
        await Timer(1, units="ns")

async def test_case_1(dut):
    dut._log.info("Testing Tx from A to B") 
    test_byte           = 0xDEADBEEF
    dut.TxData_A.value    = test_byte

    dut.TxReq_A.value     = 1
    await Timer(2, units="ns")  # wait a bit
    dut.TxReq_A.value     = 0
    
    await FallingEdge(dut.TxBusy_A)  # wait for falling edge/"negedge"
    await Timer(2*10, units="ns")  # wait a bit

    dut._log.info("UART transmitted 0x%02X", test_byte) 
    dut._log.info("UART Received 0x%02X", dut.RxData_B.value) 

async def test_case_2(dut):
    dut._log.info("Testing Duplex") 
    test_byte           = 0xDEADBEEF
    dut.TxData_A.value    = test_byte
    dut.TxData_B.value    = test_byte

    dut.TxReq_A.value     = 1
    dut.TxReq_B.value     = 1
    await Timer(2, units="ns")  # wait a bit
    dut.TxReq_A.value     = 0
    dut.TxReq_B.value     = 0
    
    await FallingEdge(dut.TxBusy_A)  # wait for falling edge/"negedge"
    await FallingEdge(dut.TxBusy_B)  # wait for falling edge/"negedge"
    await Timer(2*10, units="ns")  # wait a bit

    dut._log.info("UART transmitted 0x%02X", test_byte)
    dut._log.info("UART Received by A 0x%02X", dut.RxData_A.value)
    dut._log.info("UART Received by B 0x%02X", dut.RxData_B.value)

@cocotb.test()
async def test_uart(dut):
    # Initialization
    dut.TxData_A.value = 0
    dut.TxReq_A.value  = 0
    dut.TxData_B.value = 0
    dut.TxReq_B.value  = 0

    # start the clock
    await cocotb.start(generate_clock(dut))  # run the clock "in the background"

    # reset the IC
    await reset_dut(dut)

    # Start tests
    await test_case_1(dut)
    await test_case_2(dut)
