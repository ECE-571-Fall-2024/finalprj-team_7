`include "mesi_isc_define.sv"

module mesi_isc_broad #(parameter CBUS_CMD_WIDTH = 3,
parameter ADDR_WIDTH = 32,
parameter BROAD_TYPE_WIDTH = 2,
parameter BROAD_ID_WIDTH = 5,
parameter BROAD_REQ_FIFO_SIZE = 4,
parameter BROAD_REQ_FIFO_SIZE_LOG2 = 2)(
    // Inputs
    input logic clk,  // System clock
    input logic rst,  // Active high system reset
    input logic [3:0] cbus_ack_array_i,
    input logic broad_fifo_wr_i,  // Write the broadcast request
    input logic [ADDR_WIDTH-1:0] broad_addr_i,  // Broad addresses
    input logic [BROAD_TYPE_WIDTH-1:0] broad_type_i,  // Broad type
    input logic [1:0] broad_cpu_id_i,  // Initiators CPU id array
    input logic [BROAD_ID_WIDTH-1:0] broad_id_i,  // Broadcast request ID array

    // Outputs
    output logic [ADDR_WIDTH-1:0] cbus_addr_o,  // Coherence bus address
    output logic [4*CBUS_CMD_WIDTH-1:0] cbus_cmd_array_o,  // See broad_addr_i
    output logic fifo_status_full_o  // The broad fifo is full
);


// Regs & wires
logic broad_fifo_rd;  // Read broadcast
logic fifo_status_empty;  // Status empty
logic fifo_status_full;  // The broad fifo is full
logic [ADDR_WIDTH-1:0] broad_snoop_addr;  // Address of broadcast snooping
logic [BROAD_TYPE_WIDTH-1:0] broad_snoop_type;  // Type of broadcast snooping
logic [1:0] broad_snoop_cpu_id;  // ID of initiator of broadcast snooping
logic [BROAD_ID_WIDTH-1:0] broad_snoop_id;  // Broadcast snooping ID

// assign
//================================
assign cbus_addr_o[ADDR_WIDTH-1:0] = broad_snoop_addr[ADDR_WIDTH-1:0];
assign fifo_status_full_o = fifo_status_full;
   
// Breq fifo control
//================================
mesi_isc_broad_cntl #(CBUS_CMD_WIDTH,
                      BROAD_TYPE_WIDTH,
                      BROAD_ID_WIDTH)
   mesi_isc_broad_cntl 
    (
     // Inputs
     .clk                   (clk),
     .rst                   (rst),
     // Coherence buses
     .cbus_ack_array_i      (cbus_ack_array_i[3:0]),
     // broad_fifo
     .fifo_status_empty_i   (fifo_status_empty),
     .fifo_status_full_i    (fifo_status_full),
     // broad_fifo
     .broad_snoop_type_i    (broad_snoop_type[BROAD_TYPE_WIDTH-1:0]),
     .broad_snoop_cpu_id_i  (broad_snoop_cpu_id[1:0]),
     .broad_snoop_id_i      (broad_snoop_id[BROAD_ID_WIDTH-1:0]),
    
     // Outputs
     // Coherence buses
     .cbus_cmd_array_o      (cbus_cmd_array_o[4*CBUS_CMD_WIDTH-1:0]),
     // fifo
     .broad_fifo_rd_o       (broad_fifo_rd)			     
     );

// broad fifo
//================================
mesi_isc_basic_fifo #(ADDR_WIDTH         +       // DATA_WIDTH
                      BROAD_TYPE_WIDTH   +
                      2                  +       // BROAD_CPU_ID_WIDTH
                      BROAD_ID_WIDTH,
                      BROAD_REQ_FIFO_SIZE,       // FIFO_SIZE
                      BROAD_REQ_FIFO_SIZE_LOG2)  // FIFO_SIZE_LOG2
   //  \ /  (\ / marks the fifo ID) 
   broad_fifo 
    (
     // Inputs
     .clk                   (clk),
     .rst                   (rst),
     .wr_i                  (broad_fifo_wr_i),
     .rd_i                  (broad_fifo_rd),
     .data_i                ({broad_addr_i[ADDR_WIDTH-1:0],
                              broad_type_i[BROAD_TYPE_WIDTH-1:0],
                              broad_cpu_id_i[1:0],
                              broad_id_i[BROAD_ID_WIDTH-1:0]
                             }),
     // Outputs
     .data_o                ({broad_snoop_addr[ADDR_WIDTH-1:0],
                              broad_snoop_type[BROAD_TYPE_WIDTH-1:0],
                              broad_snoop_cpu_id[1:0],
                              broad_snoop_id[BROAD_ID_WIDTH-1:0]
                             }),
     .status_empty_o        (fifo_status_empty),
     .status_full_o         (fifo_status_full)
     );
endmodule
    