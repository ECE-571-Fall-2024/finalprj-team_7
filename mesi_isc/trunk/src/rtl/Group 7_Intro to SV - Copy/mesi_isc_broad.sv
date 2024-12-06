`include "mesi_isc_define.sv"

module mesi_isc_broad #(
    parameter int CBUS_CMD_WIDTH = 3,
    parameter int ADDR_WIDTH = 32,
    parameter int BROAD_TYPE_WIDTH = 2,
    parameter int BROAD_ID_WIDTH = 5,
    parameter int BROAD_REQ_FIFO_SIZE = 4,
    parameter int BROAD_REQ_FIFO_SIZE_LOG2 = 2
)(
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
    output logic [4*CBUS_CMD_WIDTH-1:0] cbus_cmd_array_o,  // Coherence bus commands array
    output logic fifo_status_full_o  // The broadcast FIFO is full
);

    // Internal signals
    logic broad_fifo_rd;               // Read broadcast request from FIFO
    logic fifo_status_empty;           // FIFO empty status
    logic fifo_status_full;            // FIFO full status
    logic [ADDR_WIDTH-1:0] broad_snoop_addr;   // Address of broadcast snooping
    logic [BROAD_TYPE_WIDTH-1:0] broad_snoop_type;   // Type of broadcast snooping
    logic [1:0] broad_snoop_cpu_id;   // CPU ID of initiator for snooping
    logic [BROAD_ID_WIDTH-1:0] broad_snoop_id;   // Snooping ID

    // Assignments for outputs
    assign cbus_addr_o = broad_snoop_addr;
    assign fifo_status_full_o = fifo_status_full;

    // Broadcast control instantiation
    mesi_isc_broad_cntl #(
        .CBUS_CMD_WIDTH(CBUS_CMD_WIDTH),
        .BROAD_TYPE_WIDTH(BROAD_TYPE_WIDTH),
        .BROAD_ID_WIDTH(BROAD_ID_WIDTH)
    ) mesi_isc_broad_cntl_inst (
        .clk(clk),
        .rst(rst),
        .cbus_ack_array_i(cbus_ack_array_i),
        .fifo_status_empty_i(fifo_status_empty),
        .fifo_status_full_i(fifo_status_full),
        .broad_snoop_type_i(broad_snoop_type),
        .broad_snoop_cpu_id_i(broad_snoop_cpu_id),
        .broad_snoop_id_i(broad_snoop_id),
        .cbus_cmd_array_o(cbus_cmd_array_o),
        .broad_fifo_rd_o(broad_fifo_rd)
    );

    // Broadcast FIFO instantiation with corrected instance name
    mesi_isc_basic_fifo #(
        .DATA_WIDTH(ADDR_WIDTH + BROAD_TYPE_WIDTH + 2 + BROAD_ID_WIDTH), 
        .FIFO_SIZE(BROAD_REQ_FIFO_SIZE), 
        .FIFO_SIZE_LOG2(BROAD_REQ_FIFO_SIZE_LOG2)
    ) broad_fifo (  // Corrected instance name to match testbench expectations
        .clk(clk),
        .rst(rst),
        .wr_i(broad_fifo_wr_i),
        .rd_i(broad_fifo_rd),
        .data_i({broad_addr_i, broad_type_i, broad_cpu_id_i, broad_id_i}),
        .data_o({broad_snoop_addr, broad_snoop_type, broad_snoop_cpu_id, broad_snoop_id}),
        .status_empty_o(fifo_status_empty),
        .status_full_o(fifo_status_full)
    );

endmodule