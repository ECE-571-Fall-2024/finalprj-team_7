`include "../rtl/mesi_isc_define.sv"

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

// Internal registers and wires
logic [DATA_WIDTH-1:0] entry [FIFO_SIZE-1:0];  // The fifo entries
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
// ptr_wr
// entry array
always @(posedge clk or posedge rst)
  if (rst)
  begin
     for(i=0; i < FIFO_SIZE; i = i + 1 )
       entry[i]    <= 0;
     ptr_wr        <= 0;
  end	
  else if (wr_i)
  begin
     entry[ptr_wr] <= data_i;        // Store the data_i to entry ptr_wr
     ptr_wr[FIFO_SIZE_LOG2-1:0] <= ptr_wr[FIFO_SIZE_LOG2-1:0] + 1; // Increase
                                     // the write pointer
  end


// Read from the fifo
//================================
// data_o
// The fifo output data_o is sampled. It always contains the data of 
// the entry[ptr_rd]; 
always @(posedge clk or posedge rst)
  if (rst)
    data_o[DATA_WIDTH-1:0] <= 0;
  else if (status_empty)
    data_o[DATA_WIDTH-1:0] <= data_i[DATA_WIDTH-1:0]; // When the fifo is empty
                                       // the write data
                                       // (if exists) is sampled to the fifo and
                                       // to the fifo output. In a case that in
                                       // the current cycle there is a write and
                                       // in the next cycle there is a read, the
                                       // data is ready in the output
  else if (rd_i)
    data_o[DATA_WIDTH-1:0] <= entry[ptr_rd_plus_1]; // Output the next data if this
                                       //  is a read cycle.
  else 
    data_o[DATA_WIDTH-1:0] <= entry[ptr_rd]; // The first data is sampled and
                                       //  ready for a read
// ptr_rd
always @(posedge clk or posedge rst)
  if (rst)
    ptr_rd[FIFO_SIZE_LOG2-1:0] <= 0;
  else if (rd_i)
    ptr_rd[FIFO_SIZE_LOG2-1:0] <= ptr_rd[FIFO_SIZE_LOG2-1:0] + 1; // Increase the
                                       //  read pointer
		
assign ptr_rd_plus_1 = ptr_rd + 1;

// Status
//================================
assign  status_empty_o        = status_empty;
assign  status_full_o         = status_full;

// status_empty
// status_empty is set when there are no any valid entries
always @(posedge clk or posedge rst)
  // On reset the fifo is empty
  if (rst)
                                                    status_empty <= 1;
  // There is one valid entry which is read (without write another entry)
  else if (fifo_depth == 1 & fifo_depth_decrease)
                                                    status_empty <= 1;
  // The fifo is empty and it is in a write cycle (without read)
  // The fifo_depth == 0 when the fifo is empty and when it is full
  else if (fifo_depth == 0   &
           status_empty      &    
           fifo_depth_increase)
                                                    status_empty <= 0;
	
always @(posedge clk or posedge rst)
  // On reset the fifo not full
  if (rst)
                                                    status_full  <= 0;
  // There is free entry which is written (without read other entry)
  else if (fifo_depth == FIFO_SIZE-1 & fifo_depth_increase)
                                                    status_full  <= 1;
  // The fifo is full and it is in a read cycle (without write)
  // The fifo_depth == 0 when the fifo is empty and when it is full
  else if (fifo_depth == 0 &
           status_full     &
           fifo_depth_decrease)
                                                    status_full  <= 0;
	

// The depth of the used fifo's entries is increased when there is a write
// and there is no a read
assign fifo_depth_increase     = wr_i & !rd_i;

// The depth of the used fifo's entries is decreased when there is a write
// and there is no a read
assign fifo_depth_decrease     = !wr_i & rd_i;
// In other cases (ptr_wr & ptr_rd) or (!ptr_wr & !ptr_rd) the number of the
// valid entries remains the same

// Because the buffer is cyclic the depth is always correct
assign fifo_depth[FIFO_SIZE_LOG2-1:0] = ptr_wr[FIFO_SIZE_LOG2-1:0] -
                                        ptr_rd[FIFO_SIZE_LOG2-1:0];
   
`ifdef mesi_isc_debug
// Debug
//================================
// dbg_fifo_overflow is a sticky bit which is set when writing (without reading)
// to a full fifo
// dbg_fifo_underflow is a sticky bit which is set when reading from an empty
// fifo
always @(posedge clk or posedge rst)
  if (rst)
    begin
     dbg_fifo_overflow   <= 0;
     dbg_fifo_underflow  <= 0;
    end
  else
  begin
     dbg_fifo_overflow   <= dbg_fifo_overflow | 
                            (status_full & fifo_depth_increase);
     dbg_fifo_underflow  <= dbg_fifo_underflow  | 
                            (status_empty & fifo_depth_decrease);
  end
`endif

endmodule
    