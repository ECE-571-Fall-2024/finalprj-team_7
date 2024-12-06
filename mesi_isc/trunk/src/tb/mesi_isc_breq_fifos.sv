`include "mesi_isc_define.sv"

module mesi_isc_breq_fifos #(
    parameter MBUS_CMD_WIDTH = 3,
    parameter ADDR_WIDTH = 32,
    parameter BROAD_TYPE_WIDTH = 2,
    parameter BROAD_ID_WIDTH = 7,
    parameter BREQ_FIFO_SIZE = 2,
    parameter BREQ_FIFO_SIZE_LOG2 = 1
)(
    // Inputs
    input logic clk, // System clock
    input logic rst, // Active high system reset
    input logic [4*MBUS_CMD_WIDTH-1:0] mbus_cmd_array_i, // Main bus command (array)
    input logic [4*ADDR_WIDTH-1:0] mbus_addr_array_i, // Main bus address (array)
    input logic broad_fifo_status_full_i, // The broad fifo is full

    // Outputs
    output logic [3:0] mbus_ack_array_o, // Bus acknowledge for receiving the broadcast request
    output logic broad_fifo_wr_o, // Write the broadcast request
    output logic [ADDR_WIDTH-1:0] broad_addr_o, // Address of the broadcast request
    output logic [BROAD_TYPE_WIDTH-1:0] broad_type_o, // Type of the broadcast request
    output logic [1:0] broad_cpu_id_o, // ID of the initiator CPU
    output logic [BROAD_ID_WIDTH-1:0] broad_id_o // The ID of the broadcast request
);

typedef enum logic [1:0] {CPU_0 = 2'b00, CPU_1 = 2'b01, CPU_2 = 2'b10, CPU_3 = 2'b11} cpu_id_t;

logic [3:0] fifo_status_empty_array;
logic [3:0] fifo_status_full_array;
logic [4*ADDR_WIDTH-1:0] broad_addr_array;
logic [4*BROAD_TYPE_WIDTH-1:0] broad_type_array;
logic [4*BROAD_ID_WIDTH-1:0] broad_id_array;
logic [3:0] fifo_wr_array;
logic [3:0] fifo_rd_array;
logic [4*BROAD_TYPE_WIDTH-1:0] breq_type_array;
logic [4*2-1:0] breq_cpu_id_array; // Explicit width for packed array
logic [4*BROAD_ID_WIDTH-1:0] breq_id_array;
logic [4*2-1:0] broad_cpu_id_array; // Explicit width for packed array

// Breq fifo control
//================================
mesi_isc_breq_fifos_cntl #(
    .MBUS_CMD_WIDTH(MBUS_CMD_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .BROAD_TYPE_WIDTH(BROAD_TYPE_WIDTH),
    .BROAD_ID_WIDTH(BROAD_ID_WIDTH)
) mesi_isc_breq_fifos_cntl (
    .clk(clk),
    .rst(rst),
    .mbus_cmd_array_i(mbus_cmd_array_i[4*MBUS_CMD_WIDTH-1 : 0]),
    .fifo_status_empty_array_i(fifo_status_empty_array[3:0]),
    .fifo_status_full_array_i(fifo_status_full_array[3:0]),
    .broad_fifo_status_full_i(broad_fifo_status_full_i),
    .broad_addr_array_i(broad_addr_array[4*ADDR_WIDTH-1 : 0]),
    .broad_type_array_i(broad_type_array[4*BROAD_TYPE_WIDTH-1 : 0]),
    .broad_id_array_i(broad_id_array[4*BROAD_ID_WIDTH-1 : 0]),
    .mbus_ack_array_o(mbus_ack_array_o[3:0]),
    .fifo_wr_array_o(fifo_wr_array[3:0]),
    .fifo_rd_array_o(fifo_rd_array[3:0]),
    .broad_fifo_wr_o(broad_fifo_wr_o),
    .broad_addr_o(broad_addr_o[ADDR_WIDTH-1 : 0]),
    .broad_type_o(broad_type_o[BROAD_TYPE_WIDTH-1 : 0]),
    .broad_cpu_id_o(broad_cpu_id_o[1:0]),
    .broad_id_o(broad_id_o[BROAD_ID_WIDTH-1 : 0]),
    .breq_type_array_o(breq_type_array[4*BROAD_TYPE_WIDTH-1 : 0]),
    .breq_cpu_id_array_o(breq_cpu_id_array[4*2-1 : 0]),
    .breq_id_array_o(breq_id_array[4*BROAD_ID_WIDTH-1 : 0])
);

// Breq FIFOs (Instances)
//================================
// Using a generate loop to instantiate FIFOs for better optimization and scalability.
genvar i;
generate
for (i = 0; i < 4; i++) begin : gen_fifo_instances
    mesi_isc_basic_fifo #(
        .DATA_WIDTH(ADDR_WIDTH + BROAD_TYPE_WIDTH + 2 + BROAD_ID_WIDTH), // Explicit width calculation
        .FIFO_SIZE(BREQ_FIFO_SIZE),
        .FIFO_SIZE_LOG2(BREQ_FIFO_SIZE_LOG2)
    ) fifo (
        .clk(clk),
        .rst(rst),
        .wr_i(fifo_wr_array[i]),
        .rd_i(fifo_rd_array[i]),
        .data_i({
            mbus_addr_array_i[(i+1)*ADDR_WIDTH-1:i*ADDR_WIDTH],
            breq_type_array[(i+1)*BROAD_TYPE_WIDTH-1:i*BROAD_TYPE_WIDTH],
            breq_cpu_id_array[(i+1)*2-1:i*2], // Explicit range for packed array
            breq_id_array[(i+1)*BROAD_ID_WIDTH-1:i*BROAD_ID_WIDTH]
        }),
        .data_o({
            broad_addr_array[(i+1)*ADDR_WIDTH-1:i*ADDR_WIDTH],
            broad_type_array[(i+1)*BROAD_TYPE_WIDTH-1:i*BROAD_TYPE_WIDTH],
            broad_cpu_id_array[(i+1)*2-1:i*2], // Explicit range for packed array
            broad_id_array[(i+1)*BROAD_ID_WIDTH-1:i*BROAD_ID_WIDTH]
        }),
        .status_empty_o(fifo_status_empty_array[i]),
        .status_full_o(fifo_status_full_array[i])
    );
end
endgenerate

endmodule