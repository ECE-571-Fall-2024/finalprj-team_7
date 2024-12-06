`include "../src/rtl/mesi_isc_define.sv"

module mesi_isc_basic_fifo #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_SIZE = 4,
    parameter FIFO_SIZE_LOG2 = 2
) (
    // Inputs
    input logic clk,  // System clock
    input logic rst,  // Active high system reset
    input logic wr_i,  // Write data to the fifo (store the data)
    input logic rd_i,  // Read data from the fifo. Data is erased afterward.
    input logic [DATA_WIDTH-1:0] data_i,  // Data in to be stored

    // Outputs
    output logic [DATA_WIDTH-1:0] data_o,  // Data out to be read
    output logic status_empty_o,  // There are no valid entries in the fifo
    output logic status_full_o  // There are no free entries in the fifo; all entries are valid
);

typedef struct packed {
    logic [DATA_WIDTH-1:0] data;
} fifo_entry_t;

// Internal registers and wires
fifo_entry_t entry [FIFO_SIZE];  // The fifo entries as an array of structs
logic [FIFO_SIZE_LOG2-1:0] ptr_wr;  // Fifo write pointer
logic [FIFO_SIZE_LOG2-1:0] ptr_rd;  // Fifo read pointer
logic [FIFO_SIZE_LOG2-1:0] ptr_rd_plus_1;
logic status_empty;
logic status_full;
logic [FIFO_SIZE_LOG2-1:0] fifo_depth;  // Number of used entries
logic fifo_depth_increase;
logic fifo_depth_decrease;

integer i;

`ifdef mesi_isc_debug
logic dbg_fifo_overflow;		       // Sticky bit for fifo overflow
logic dbg_fifo_underflow;		       // Sticky bit for fifo underflow
`endif

// Write to the fifo
//================================
always_ff @(posedge clk or posedge rst)
  if (rst) begin
     foreach (entry[i]) begin
        entry[i].data <= '0;
     end
     ptr_wr <= '0;
  end else if (wr_i) begin
     entry[ptr_wr].data <= data_i;        // Store the data_i to entry ptr_wr
     ptr_wr <= ptr_wr + 1;               // Increase the write pointer
  end

// Read from the fifo
//================================
always_ff @(posedge clk or posedge rst)
  if (rst) begin
    data_o <= '0;
  end else if (status_empty) begin
    data_o <= data_i;                    // When the fifo is empty, pass through input data
  end else if (rd_i) begin
    data_o <= entry[ptr_rd_plus_1].data; // Output the next data if this is a read cycle.
  end else begin 
    data_o <= entry[ptr_rd].data;        // The first data is sampled and ready for a read.
  end

// Update read pointer (ptr_rd)
always_ff @(posedge clk or posedge rst)
  if (rst) begin
    ptr_rd <= '0;
  end else if (rd_i) begin
    ptr_rd <= ptr_rd + 1;                // Increase the read pointer on read operation.
  end

assign ptr_rd_plus_1 = ptr_rd + 1;

// Status signals (empty/full)
//================================
assign status_empty_o = status_empty;
assign status_full_o = status_full;

always_ff @(posedge clk or posedge rst)
  if (rst) begin
    status_empty <= 1'b1;
  end else if ((fifo_depth == 'd1) && fifo_depth_decrease) begin
    status_empty <= 1'b1;
  end else if ((fifo_depth == 'd0) && status_empty && fifo_depth_increase) begin
    status_empty <= 1'b0;
  end

always_ff @(posedge clk or posedge rst)
  if (rst) begin
    status_full <= 1'b0;
  end else if ((fifo_depth == FIFO_SIZE - 'd1) && fifo_depth_increase) begin
    status_full <= 1'b1;
  end else if ((fifo_depth == 'd0) && status_full && fifo_depth_decrease) begin
    status_full <= 1'b0;
  end

assign fifo_depth_increase = wr_i && !rd_i;
assign fifo_depth_decrease = !wr_i && rd_i;

assign fifo_depth = ptr_wr - ptr_rd;

`ifdef mesi_isc_debug
// Debug signals for overflow and underflow detection.
//================================

always_ff @(posedge clk or posedge rst)
  if (rst) begin
     dbg_fifo_overflow   <= '0;
     dbg_fifo_underflow  <= '0;
  end else begin
     dbg_fifo_overflow   <= dbg_fifo_overflow | 
                            (status_full & fifo_depth_increase);
     dbg_fifo_underflow  <= dbg_fifo_underflow | 
                            (status_empty & fifo_depth_decrease);
  end

`endif

endmodule
