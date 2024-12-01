`timescale 1ns / 1ps

// Main Bus commands
`define MESI_ISC_MBUS_CMD_NOP      3'd0
`define MESI_ISC_MBUS_CMD_WR       3'd1
`define MESI_ISC_MBUS_CMD_RD       3'd2
`define MESI_ISC_MBUS_CMD_WR_BROAD 3'd3
`define MESI_ISC_MBUS_CMD_RD_BROAD 3'd4

// Coherence Bus commands
`define MESI_ISC_CBUS_CMD_NOP      3'd0
`define MESI_ISC_CBUS_CMD_WR_SNOOP 3'd1
`define MESI_ISC_CBUS_CMD_RD_SNOOP 3'd2
`define MESI_ISC_CBUS_CMD_EN_WR    3'd3
`define MESI_ISC_CBUS_CMD_EN_RD    3'd4
  
// BREQ_TYPE  
`define MESI_ISC_BREQ_TYPE_NOP 2'd0
`define MESI_ISC_BREQ_TYPE_WR  2'd1
`define MESI_ISC_BREQ_TYPE_RD  2'd2