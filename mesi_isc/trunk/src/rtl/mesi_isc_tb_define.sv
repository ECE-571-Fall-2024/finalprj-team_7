////  Description                                                 ////
////  mesi_isc_tb_define                                          ////
////  -------------------                                         ////
////  Contains the timescale and the define declaration of the    ////
////  block tb                                                    ////
////                                                              ////

// Define a macro for debugging
`define mesi_isc_debug

// CPU instructions
`define MESI_ISC_TB_INS_NOP 4'd0
`define MESI_ISC_TB_INS_WR  4'd1
`define MESI_ISC_TB_INS_RD  4'd2

`define MESI_ISC_TB_CPU_M_STATE_IDLE        0
`define MESI_ISC_TB_CPU_M_STATE_WR_CACHE    1
`define MESI_ISC_TB_CPU_M_STATE_RD_CACHE    2
`define MESI_ISC_TB_CPU_M_STATE_SEND_WR_BR  3
`define MESI_ISC_TB_CPU_M_STATE_SEND_RD_BR  4

`define MESI_ISC_TB_CPU_C_STATE_IDLE        0
`define MESI_ISC_TB_CPU_C_STATE_WR_SNOOP    1
`define MESI_ISC_TB_CPU_C_STATE_RD_SNOOP    2
`define MESI_ISC_TB_CPU_C_STATE_EVICT_INVALIDATE 3
`define MESI_ISC_TB_CPU_C_STATE_EVICT       4
`define MESI_ISC_TB_CPU_C_STATE_RD_LINE_WR  5
`define MESI_ISC_TB_CPU_C_STATE_RD_LINE_RD  6
`define MESI_ISC_TB_CPU_C_STATE_RD_CACHE    7
`define MESI_ISC_TB_CPU_C_STATE_WR_CACHE    8


`define MESI_ISC_TB_CPU_MESI_M              4'b1001
`define MESI_ISC_TB_CPU_MESI_E              4'b0101
`define MESI_ISC_TB_CPU_MESI_S              4'b0011
`define MESI_ISC_TB_CPU_MESI_I              4'b0000