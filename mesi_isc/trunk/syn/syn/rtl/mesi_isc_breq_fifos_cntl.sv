`include "mesi_isc_define.sv"


module mesi_isc_breq_fifos_cntl #(parameter MBUS_CMD_WIDTH = 3,
parameter ADDR_WIDTH = 32,
parameter BROAD_TYPE_WIDTH = 2,
parameter BROAD_ID_WIDTH = 7) (
    // Inputs
    input logic clk,  // System clock
    input logic rst,  // Active high system reset
    input logic [4*MBUS_CMD_WIDTH-1:0] mbus_cmd_array_i,
    input logic [3:0] fifo_status_empty_array_i,
    input logic [3:0] fifo_status_full_array_i,
    input logic broad_fifo_status_full_i,
    input logic [4*ADDR_WIDTH-1:0] broad_addr_array_i,
    input logic [4*BROAD_TYPE_WIDTH-1:0] broad_type_array_i,
    input logic [4*BROAD_ID_WIDTH-1:0] broad_id_array_i,

    // Outputs
    output logic [3:0] mbus_ack_array_o,
    output logic [3:0] fifo_wr_array_o,
    output logic [3:0] fifo_rd_array_o,
    output logic broad_fifo_wr_o,
    output logic [ADDR_WIDTH-1:0] broad_addr_o,
    output logic [BROAD_TYPE_WIDTH-1:0] broad_type_o,
    output logic [1:0] broad_cpu_id_o,
    output logic [BROAD_ID_WIDTH-1:0] broad_id_o,
    output logic [4*BROAD_TYPE_WIDTH-1:0] breq_type_array_o,
    output logic [4*2-1:0] breq_cpu_id_array_o,
    output logic [4*BROAD_ID_WIDTH-1:0] breq_id_array_o
);

// Regs & wires
logic [3:0] mbus_ack_array;
logic [3:0] fifos_priority; // One hot priority between the breq fifos toward the broad fifo
logic [3:0] fifos_priority_barrel_shiftl_1, fifos_priority_barrel_shiftl_2, fifos_priority_barrel_shiftl_3;
logic [3:0] fifo_select_oh; // One hot control of the mux between breq fifos toward the broad fifo
logic [MBUS_CMD_WIDTH-1:0] mbus_cmd_array_i_3, mbus_cmd_array_i_2, mbus_cmd_array_i_1, mbus_cmd_array_i_0;
logic [BROAD_ID_WIDTH-3:0] breq_id_base;


// Assigns for outputs
//================================
assign mbus_ack_array_o   = mbus_ack_array;


// fifo_rd_array_o, broad_fifo_wr_o
// Read the breq from one of the breq fifos and write it to the broad fifo.   
assign fifo_rd_array_o = {4{~broad_fifo_status_full_i}} & // There is space in
			              // the broad fifo
		         fifo_select_oh[3:0]; // The highest priority
			              // fifo that has a valid breq.
assign broad_fifo_wr_o = |fifo_rd_array_o[3:0]; // Write to the broad fifo is 
                                      // done in parallel to Read from one of
                                      // the breq fifo The values set
   
// fifos_priority, fifos_priority_barrel_shift_1/2/3 (one hot)
// The priority between the CPU is done in round robin order.
// The breq which is sent to the broad fifo is selected according to 
// the value of the fifos_priority register, from the low value to the high 
// value.
// For example when fifos_priority == 2 then the priority order is:
//  2 -> 3 -> 0 -> 1. The breq is sent from the first breq fifo, in that order,
// that has a valid breq.
// The priority is change whenever a breq is sent to the broad fifo  
always @(posedge clk or posedge rst)
 if (rst)
   fifos_priority <= 1;
 else if (broad_fifo_wr_o)
   fifos_priority[3:0] <= fifos_priority_barrel_shiftl_1[3:0];

assign fifos_priority_barrel_shiftl_3[3:0] =
                                    {fifos_priority[0]  , fifos_priority[3:1]};
assign fifos_priority_barrel_shiftl_2[3:0] =
                                    {fifos_priority[1:0], fifos_priority[3:2]};
assign fifos_priority_barrel_shiftl_1[3:0] =
                                    {fifos_priority[2:0], fifos_priority[3]};
   
// fifo_select_oh (one hot)
// Points to the highest priority fifo (see fifos_priority) that
// has a valid breq.
// The control of the mux from the breq fifos to the broad fifo.
assign fifo_select_oh[3:0] =
          // If the 1st highest priority fifo is not empty then select it
	  // Or the bit-wise results of the following formula to one result   
	  // Bit-wise set for fifos that are not empty 
          |(~fifo_status_empty_array_i[3:0] &
	     // Bit-wise one hot priority for the 1st highest priority
             fifos_priority[3:0]                 ) ?
                                          fifos_priority[3:0]                 :
          |(~fifo_status_empty_array_i[3:0] &
             fifos_priority_barrel_shiftl_1[3:0] ) ?
                                          fifos_priority_barrel_shiftl_1[3:0] :
          |(~fifo_status_empty_array_i[3:0] &
             fifos_priority_barrel_shiftl_2[3:0] ) ?
                                          fifos_priority_barrel_shiftl_2[3:0] :
          |(~fifo_status_empty_array_i[3:0] &
             fifos_priority_barrel_shiftl_3[3:0] ) ?
                                          fifos_priority_barrel_shiftl_3[3:0] :
                                          4'd0;
   
// broad_addr_o, broad_type_o, broad_cpu_id_o, broad_id_o
// One hot mux
assign broad_addr_o[ADDR_WIDTH-1:0] = 
            broad_addr_array_i[(3+1)*ADDR_WIDTH-1 : 3*ADDR_WIDTH] &
                                              {ADDR_WIDTH{fifo_select_oh[3]}} |
            broad_addr_array_i[(2+1)*ADDR_WIDTH-1 : 2*ADDR_WIDTH] &
                                              {ADDR_WIDTH{fifo_select_oh[2]}} |
            broad_addr_array_i[(1+1)*ADDR_WIDTH-1 : 1*ADDR_WIDTH] &
                                              {ADDR_WIDTH{fifo_select_oh[1]}} |
            broad_addr_array_i[(0+1)*ADDR_WIDTH-1 : 0*ADDR_WIDTH] &
                                              {ADDR_WIDTH{fifo_select_oh[0]}};
assign broad_type_o[BROAD_TYPE_WIDTH-1:0] = 
            broad_type_array_i[(3+1)*BROAD_TYPE_WIDTH-1 : 3*BROAD_TYPE_WIDTH] &
                                        {BROAD_TYPE_WIDTH{fifo_select_oh[3]}} |
            broad_type_array_i[(2+1)*BROAD_TYPE_WIDTH-1 : 2*BROAD_TYPE_WIDTH] &
                                        {BROAD_TYPE_WIDTH{fifo_select_oh[2]}} |
            broad_type_array_i[(1+1)*BROAD_TYPE_WIDTH-1 : 1*BROAD_TYPE_WIDTH] &
                                        {BROAD_TYPE_WIDTH{fifo_select_oh[1]}} |
            broad_type_array_i[(0+1)*BROAD_TYPE_WIDTH-1 : 0*BROAD_TYPE_WIDTH] &
                                        {BROAD_TYPE_WIDTH{fifo_select_oh[0]}};
// Each CPU has a fixed ID
assign broad_cpu_id_o[1:0] = 2'd3 & {2{fifo_select_oh[3]}} |
	                     2'd2 & {2{fifo_select_oh[2]}} |  
		             2'd1 & {2{fifo_select_oh[1]}} |  
			     2'd0 & {2{fifo_select_oh[0]}};
   
assign broad_id_o[BROAD_ID_WIDTH-1:0] =
            broad_id_array_i[(3+1)*BROAD_ID_WIDTH-1 : 3*BROAD_ID_WIDTH] &
                                          {BROAD_ID_WIDTH{fifo_select_oh[3]}} |
            broad_id_array_i[(2+1)*BROAD_ID_WIDTH-1 : 2*BROAD_ID_WIDTH] &
                                          {BROAD_ID_WIDTH{fifo_select_oh[2]}} |
            broad_id_array_i[(1+1)*BROAD_ID_WIDTH-1 : 1*BROAD_ID_WIDTH] &
                                          {BROAD_ID_WIDTH{fifo_select_oh[1]}} |
            broad_id_array_i[(0+1)*BROAD_ID_WIDTH-1 : 0*BROAD_ID_WIDTH] &
                                          {BROAD_ID_WIDTH{fifo_select_oh[0]}};
		    
//fifo_wr_array
// Write the breq into the fifo.
// When an acknowledge is sent to the mbus the breq is written to the fifo.
assign fifo_wr_array_o[3:0] = mbus_ack_array[3:0];
   
// mbus_ack_array
// The mbus ack is an indication for the mbus that the (broadcast) transaction
// was received and it can proceed to the next transaction (or to nop).
// The acknowledge is sent to the mbus when the breq can be stored in the fifo.
// The acknowledge can't be asserted for more then one cycle for simplification
// of the protocol and timing paths. 
always @(posedge clk or posedge rst)
  if (rst)
     mbus_ack_array[3:0] <= 0;
  else
  begin
     mbus_ack_array[3] <= ~mbus_ack_array[3] &
                          (mbus_cmd_array_i_3 == `MESI_ISC_MBUS_CMD_WR_BROAD |
                           mbus_cmd_array_i_3 == `MESI_ISC_MBUS_CMD_RD_BROAD )&
                          fifo_status_full_array_i[3] == 0;
     mbus_ack_array[2] <= ~mbus_ack_array[2] &
                          (mbus_cmd_array_i_2 == `MESI_ISC_MBUS_CMD_WR_BROAD |
                           mbus_cmd_array_i_2 == `MESI_ISC_MBUS_CMD_RD_BROAD )&
                          fifo_status_full_array_i[2] == 0;
     mbus_ack_array[1] <= ~mbus_ack_array[1] &
                          (mbus_cmd_array_i_1 == `MESI_ISC_MBUS_CMD_WR_BROAD |
                           mbus_cmd_array_i_1 == `MESI_ISC_MBUS_CMD_RD_BROAD )&
                          fifo_status_full_array_i[1] == 0;
     mbus_ack_array[0] <= ~mbus_ack_array[0] &
                          (mbus_cmd_array_i_0 == `MESI_ISC_MBUS_CMD_WR_BROAD |
                           mbus_cmd_array_i_0 == `MESI_ISC_MBUS_CMD_RD_BROAD )&
                          fifo_status_full_array_i[0] == 0;
     
  end

assign mbus_cmd_array_i_3[MBUS_CMD_WIDTH-1:0] =
                   mbus_cmd_array_i[(3+1)*MBUS_CMD_WIDTH-1 : 3*MBUS_CMD_WIDTH];
assign mbus_cmd_array_i_2[MBUS_CMD_WIDTH-1:0] =
                   mbus_cmd_array_i[(2+1)*MBUS_CMD_WIDTH-1 : 2*MBUS_CMD_WIDTH];
assign mbus_cmd_array_i_1[MBUS_CMD_WIDTH-1:0] =
                   mbus_cmd_array_i[(1+1)*MBUS_CMD_WIDTH-1 : 1*MBUS_CMD_WIDTH];
assign mbus_cmd_array_i_0[MBUS_CMD_WIDTH-1:0] =
                   mbus_cmd_array_i[(0+1)*MBUS_CMD_WIDTH-1 : 0*MBUS_CMD_WIDTH];
   
// The breq type depends on the mbus command.
// Mbus: Write broadcast - breq type: wr
// Mbus: Read broadcast  - breq type: rd
// Mbus: else            - breq type: nop
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        breq_type_array_o[4*BROAD_TYPE_WIDTH-1:0] <= '0; // Reset all bits to zero
    end else begin
        // Assign values based on command inputs
        breq_type_array_o[(3+1)*BROAD_TYPE_WIDTH-1: 3*BROAD_TYPE_WIDTH] <=
            (mbus_cmd_array_i_3 == `MESI_ISC_MBUS_CMD_WR_BROAD) ? `MESI_ISC_BREQ_TYPE_WR :
            (mbus_cmd_array_i_3 == `MESI_ISC_MBUS_CMD_RD_BROAD) ? `MESI_ISC_BREQ_TYPE_RD :
                                                                   `MESI_ISC_BREQ_TYPE_NOP;

        breq_type_array_o[(2+1)*BROAD_TYPE_WIDTH-1: 2*BROAD_TYPE_WIDTH] <=
            (mbus_cmd_array_i_2 == `MESI_ISC_MBUS_CMD_WR_BROAD) ? `MESI_ISC_BREQ_TYPE_WR :
            (mbus_cmd_array_i_2 == `MESI_ISC_MBUS_CMD_RD_BROAD) ? `MESI_ISC_BREQ_TYPE_RD :
                                                                   `MESI_ISC_BREQ_TYPE_NOP;

        breq_type_array_o[(1+1)*BROAD_TYPE_WIDTH-1: 1*BROAD_TYPE_WIDTH] <=
            (mbus_cmd_array_i_1 == `MESI_ISC_MBUS_CMD_WR_BROAD) ? `MESI_ISC_BREQ_TYPE_WR :
            (mbus_cmd_array_i_1 == `MESI_ISC_MBUS_CMD_RD_BROAD) ? `MESI_ISC_BREQ_TYPE_RD :
                                                                   `MESI_ISC_BREQ_TYPE_NOP;

        breq_type_array_o[(0+1)*BROAD_TYPE_WIDTH-1: 0*BROAD_TYPE_WIDTH] <=
            (mbus_cmd_array_i_0 == `MESI_ISC_MBUS_CMD_WR_BROAD) ? `MESI_ISC_BREQ_TYPE_WR :
            (mbus_cmd_array_i_0 == `MESI_ISC_MBUS_CMD_RD_BROAD) ? `MESI_ISC_BREQ_TYPE_RD :
                                                                   `MESI_ISC_BREQ_TYPE_NOP;
    end
end
// The CPU IDs have fixed values
assign breq_cpu_id_array_o[(3+1)*2-1 : 3*2] = 3;
assign breq_cpu_id_array_o[(2+1)*2-1 : 2*2] = 2;
assign breq_cpu_id_array_o[(1+1)*2-1 : 1*2] = 1;
assign breq_cpu_id_array_o[(0+1)*2-1 : 0*2] = 0;

// breq_id_array_o
// In a cycle that at least on breq is received there are 4 unique numbers -
// one for each fifo. These numbers are the breq ID. In a cycle that a certain
// fifo does not receive a breq (but there is at least one more fifos that  
// receives) then its unique number in that cycle is not used.
// The values of breq_id are cyclic and every specific amount of breqs its  
// value go back to 0. The possible different values of breq_id are much bigger
// then 4*(the latency of mesi_isc). In that way it is not possible that the
// same ID is used for more then one request in the same time.
// 
// fifo 0 ID (for each cycle) is breq_id_base*4
// fifo 1 ID is breq_id_base*4 + 1
// fifo 1 ID is breq_id_base*4 + 2
// fifo 1 ID is breq_id_base*4 + 3
assign breq_id_array_o[(3+1)*BROAD_ID_WIDTH-1 : 3*BROAD_ID_WIDTH] =
                                   {breq_id_base[BROAD_ID_WIDTH-3 : 0], 2'b00};
assign breq_id_array_o[(2+1)*BROAD_ID_WIDTH-1 : 2*BROAD_ID_WIDTH] =
                                   {breq_id_base[BROAD_ID_WIDTH-3 : 0], 2'b01};
assign breq_id_array_o[(1+1)*BROAD_ID_WIDTH-1 : 1*BROAD_ID_WIDTH] =
                                   {breq_id_base[BROAD_ID_WIDTH-3 : 0], 2'b10};
assign breq_id_array_o[(0+1)*BROAD_ID_WIDTH-1 : 0*BROAD_ID_WIDTH] =
                                   {breq_id_base[BROAD_ID_WIDTH-3 : 0], 2'b11};
							       
// The least significant bits of breq_id_base are always 0
always @(posedge clk or posedge rst)
 if (rst)
   breq_id_base[BROAD_ID_WIDTH-3 : 0] <= 0;
 else if (|fifo_wr_array_o)
  //  breq_id_base+1 is analogous to  breq_id+4
  breq_id_base[BROAD_ID_WIDTH-3 : 0] <= breq_id_base[BROAD_ID_WIDTH-3 : 0] + 1;
   

endmodule
