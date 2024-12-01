`include "mesi_isc_define.sv"

module mesi_isc #(
    parameter CBUS_CMD_WIDTH = 3,
    parameter ADDR_WIDTH = 32,
    parameter BROAD_TYPE_WIDTH = 2,
    parameter BROAD_ID_WIDTH = 5,
    parameter BROAD_REQ_FIFO_SIZE = 4,
    parameter BROAD_REQ_FIFO_SIZE_LOG2 = 2,
    parameter MBUS_CMD_WIDTH = 3,
    parameter BREQ_FIFO_SIZE = 2,
    parameter BREQ_FIFO_SIZE_LOG2 = 1
) (
    // Inputs
    input logic clk,  // System clock
    input logic rst,  // Active high system reset
    input logic [MBUS_CMD_WIDTH-1:0] mbus_cmd3_i,  // Main bus3 command
    input logic [MBUS_CMD_WIDTH-1:0] mbus_cmd2_i,  // Main bus2 command
    input logic [MBUS_CMD_WIDTH-1:0] mbus_cmd1_i,  // Main bus1 command
    input logic [MBUS_CMD_WIDTH-1:0] mbus_cmd0_i,  // Main bus0 command
    input logic [ADDR_WIDTH-1:0] mbus_addr3_i,     // Coherence bus3 address
    input logic [ADDR_WIDTH-1:0] mbus_addr2_i,     // Coherence bus2 address
    input logic [ADDR_WIDTH-1:0] mbus_addr1_i,     // Coherence bus1 address
    input logic [ADDR_WIDTH-1:0] mbus_addr0_i,     // Coherence bus0 address
    input logic cbus_ack3_i,                       // Coherence bus3 acknowledge
    input logic cbus_ack2_i,                       // Coherence bus2 acknowledge
    input logic cbus_ack1_i,                       // Coherence bus1 acknowledge
    input logic cbus_ack0_i,                       // Coherence bus0 acknowledge

    // Outputs
    output logic [ADDR_WIDTH-1:0] cbus_addr_o,     // Coherence bus address. All buses have the same address
    output logic [CBUS_CMD_WIDTH-1:0] cbus_cmd3_o, // Coherence bus3 command
    output logic [CBUS_CMD_WIDTH-1:0] cbus_cmd2_o, // Coherence bus2 command
    output logic [CBUS_CMD_WIDTH-1:0] cbus_cmd1_o, // Coherence bus1 command
    output logic [CBUS_CMD_WIDTH-1:0] cbus_cmd0_o, // Coherence bus0 command

    output logic mbus_ack3_o,                      // Main bus3 acknowledge
    output logic mbus_ack2_o,                      // Main bus2 acknowledge
    output logic mbus_ack1_o,                      // Main bus1 acknowledge
    output logic mbus_ack0_o                       // Main bus0 acknowledge
);

// Regs & wires
logic broad_fifo_wr;
logic [ADDR_WIDTH-1:0] broad_addr;
logic [BROAD_ID_WIDTH-1:0] broad_id;
logic [BROAD_TYPE_WIDTH-1:0] broad_type;
logic [1:0] broad_cpu_id;
logic broad_fifo_status_full;

// mesi_isc_broad instantiation
mesi_isc_broad #(CBUS_CMD_WIDTH,
                 ADDR_WIDTH,
                 BROAD_TYPE_WIDTH,  
                 BROAD_ID_WIDTH,  
                 BROAD_REQ_FIFO_SIZE,
                 BROAD_REQ_FIFO_SIZE_LOG2)
  mesi_isc_broad
    (
     // Inputs
     .clk                      (clk),
     .rst                      (rst),
     .cbus_ack_array_i         ({cbus_ack3_i,
                                 cbus_ack2_i,
                                 cbus_ack1_i,
                                 cbus_ack0_i}
                               ),
     .broad_fifo_wr_i          (broad_fifo_wr  ),
     .broad_addr_i             (broad_addr[ADDR_WIDTH-1:0]),
     .broad_type_i             (broad_type[BROAD_TYPE_WIDTH-1:0]),
     .broad_cpu_id_i           (broad_cpu_id[1:0]),
     .broad_id_i               (broad_id[BROAD_ID_WIDTH-1:0]),
     // Outputs
     .cbus_addr_o              (cbus_addr_o[ADDR_WIDTH-1:0]),
     .cbus_cmd_array_o         ({cbus_cmd3_o[CBUS_CMD_WIDTH-1:0],
                                 cbus_cmd2_o[CBUS_CMD_WIDTH-1:0],
                                 cbus_cmd1_o[CBUS_CMD_WIDTH-1:0],
                                 cbus_cmd0_o[CBUS_CMD_WIDTH-1:0]}
                               ),
     .fifo_status_full_o       (broad_fifo_status_full)
     );

// mesi_isc_breq_fifos
//================================
mesi_isc_breq_fifos #(MBUS_CMD_WIDTH,
                      ADDR_WIDTH,
                      BROAD_TYPE_WIDTH,  
                      BROAD_ID_WIDTH,  
                      BREQ_FIFO_SIZE,
                      BREQ_FIFO_SIZE_LOG2)
  mesi_isc_breq_fifos
    (
     // Inputs
     .clk                      (clk),
     .rst                      (rst),
     .mbus_cmd_array_i         ({mbus_cmd3_i[MBUS_CMD_WIDTH-1:0],
                                 mbus_cmd2_i[MBUS_CMD_WIDTH-1:0],
                                 mbus_cmd1_i[MBUS_CMD_WIDTH-1:0],
                                 mbus_cmd0_i[MBUS_CMD_WIDTH-1:0]}
                               ),
     .mbus_addr_array_i        ({mbus_addr3_i[ADDR_WIDTH-1:0],
                                 mbus_addr2_i[ADDR_WIDTH-1:0],
                                 mbus_addr1_i[ADDR_WIDTH-1:0],
                                 mbus_addr0_i[ADDR_WIDTH-1:0]}
                               ),
     .broad_fifo_status_full_i (broad_fifo_status_full),
     // Outputs
     .mbus_ack_array_o         ({mbus_ack3_o,
                                 mbus_ack2_o,
                                 mbus_ack1_o,
                                 mbus_ack0_o}
                                ),
     .broad_fifo_wr_o          (broad_fifo_wr  ),
     .broad_addr_o             (broad_addr[ADDR_WIDTH-1:0]),
     .broad_type_o             (broad_type[BROAD_TYPE_WIDTH-1:0]),
     .broad_cpu_id_o           (broad_cpu_id[1:0]),
     .broad_id_o               (broad_id[BROAD_ID_WIDTH-1:0])
     );
endmodule
