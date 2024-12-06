`include "mesi_isc_define.sv"

module mesi_isc_broad_cntl #(parameter CBUS_CMD_WIDTH = 3,
parameter BROAD_TYPE_WIDTH = 2,
parameter BROAD_ID_WIDTH = 5)(
    // Inputs
    input logic clk,  // System clock
    input logic rst,  // Active high system reset
    input logic [3:0] cbus_ack_array_i,
    input logic fifo_status_empty_i,
    input logic fifo_status_full_i,
    input logic [BROAD_TYPE_WIDTH-1:0] broad_snoop_type_i, // The type of the broad
    input logic [1:0] broad_snoop_cpu_id_i, // The ID of the initiator CPU
    input logic [BROAD_ID_WIDTH-1:0] broad_snoop_id_i, // The ID of the broad

    // Outputs
    output logic [4*CBUS_CMD_WIDTH-1:0] cbus_cmd_array_o, // Command for coherence bus.
    output logic broad_fifo_rd_o
);


// Regs & wires
logic [CBUS_CMD_WIDTH-1:0] cbus_cmd3;  // Command for coherence bus.
logic [CBUS_CMD_WIDTH-1:0] cbus_cmd2;  // Command for coherence bus.
logic [CBUS_CMD_WIDTH-1:0] cbus_cmd1;  // Command for coherence bus.
logic [CBUS_CMD_WIDTH-1:0] cbus_cmd0;  // Command for coherence bus.
logic broadcast_in_progress; // A broadcast process contains 2 stages.
logic [3:0] cbus_active_broad_array; 
logic [3:0] cbus_active_en_access_array;
logic [3:0] cbus_active_en_access_and_not_cbus_ack_array;

//cbus_cmd
assign cbus_cmd_array_o[(3+1)*CBUS_CMD_WIDTH-1 : 3*CBUS_CMD_WIDTH] = cbus_cmd3;
assign cbus_cmd_array_o[(2+1)*CBUS_CMD_WIDTH-1 : 2*CBUS_CMD_WIDTH] = cbus_cmd2;
assign cbus_cmd_array_o[(1+1)*CBUS_CMD_WIDTH-1 : 1*CBUS_CMD_WIDTH] = cbus_cmd1;
assign cbus_cmd_array_o[(0+1)*CBUS_CMD_WIDTH-1 : 0*CBUS_CMD_WIDTH] = cbus_cmd0;

// The command of the coherence bus is define according to the state of 
// cbus_active_broad_array and cbus_active_en_access_array
       //     \ /
assign cbus_cmd3 =
         // The broadcast proccess is active. Send the broadcast request 
         //                     \ /
         cbus_active_broad_array[3] ?
           broad_snoop_type_i == `MESI_ISC_BREQ_TYPE_WR ?
                                           `MESI_ISC_CBUS_CMD_WR_SNOOP:
                                           `MESI_ISC_CBUS_CMD_RD_SNOOP     :
         // All the broadcast proccesses were done. This CPU is the initiator
	 // of the request. Enable it to continue by send en_wr/en_rd
	 !(|cbus_active_broad_array)    &
         //                         \ /
         cbus_active_en_access_array[3] &
         ~broad_fifo_rd_o ?
           broad_snoop_type_i == `MESI_ISC_BREQ_TYPE_WR ?
                                           `MESI_ISC_CBUS_CMD_EN_WR:
                                           `MESI_ISC_CBUS_CMD_EN_RD        :
	                                   `MESI_ISC_CBUS_CMD_NOP;
       //     \ /
assign cbus_cmd2 =
         //                     \ /
         cbus_active_broad_array[2] ?
           broad_snoop_type_i == `MESI_ISC_BREQ_TYPE_WR ?
                                           `MESI_ISC_CBUS_CMD_WR_SNOOP:
                                           `MESI_ISC_CBUS_CMD_RD_SNOOP     :
	 !(|cbus_active_broad_array)    &
         //                         \ /
         cbus_active_en_access_array[2] &
         ~broad_fifo_rd_o ?
           broad_snoop_type_i == `MESI_ISC_BREQ_TYPE_WR ?
                                           `MESI_ISC_CBUS_CMD_EN_WR:
                                           `MESI_ISC_CBUS_CMD_EN_RD        :
	                                   `MESI_ISC_CBUS_CMD_NOP;
       //     \ /
assign cbus_cmd1 =
         //                     \ /
         cbus_active_broad_array[1] ?
           broad_snoop_type_i == `MESI_ISC_BREQ_TYPE_WR ?
                                           `MESI_ISC_CBUS_CMD_WR_SNOOP:
                                           `MESI_ISC_CBUS_CMD_RD_SNOOP     :
	 !(|cbus_active_broad_array)    &
         //                         \ /
         cbus_active_en_access_array[1] &
         ~broad_fifo_rd_o ?
           broad_snoop_type_i == `MESI_ISC_BREQ_TYPE_WR ?
                                           `MESI_ISC_CBUS_CMD_EN_WR:
                                           `MESI_ISC_CBUS_CMD_EN_RD        :
	                                   `MESI_ISC_CBUS_CMD_NOP;
       //     \ /
assign cbus_cmd0 =
         // Send read or write broad according to the type of the broad.
         //                     \ /
         cbus_active_broad_array[0] ?
           broad_snoop_type_i == `MESI_ISC_BREQ_TYPE_WR ?
                                           `MESI_ISC_CBUS_CMD_WR_SNOOP:
                                           `MESI_ISC_CBUS_CMD_RD_SNOOP     :
	 !(|cbus_active_broad_array)    &
         //                         \ /
         cbus_active_en_access_array[0] &
         ~broad_fifo_rd_o ?
           broad_snoop_type_i == `MESI_ISC_BREQ_TYPE_WR ?
                                           `MESI_ISC_CBUS_CMD_EN_WR:
                                           `MESI_ISC_CBUS_CMD_EN_RD        :

	                                   `MESI_ISC_CBUS_CMD_NOP;

always @(posedge clk or posedge rst)
  if (rst)
  begin
        broadcast_in_progress       <= 0;
        cbus_active_broad_array     <= 4'b0000; 
        cbus_active_en_access_array <= 4'b0000;
        broad_fifo_rd_o             <= 0;
  end
  else if (~broadcast_in_progress & ~broad_fifo_rd_o)
    if (~fifo_status_empty_i)
    // Stage 1
      begin
        broadcast_in_progress       <= 1;
        case (broad_snoop_cpu_id_i) // The initiator does not received a
	                            // broadcast for the same line it asks the
	                            // broadcast
          0:
          begin
            cbus_active_broad_array     <= 4'b1110;
	    cbus_active_en_access_array <= 4'b0001;
          end
          1:
          begin
            cbus_active_broad_array     <= 4'b1101;
	    cbus_active_en_access_array <= 4'b0010;
          end
          2:
          begin
            cbus_active_broad_array     <= 4'b1011;
	    cbus_active_en_access_array <= 4'b0100;
          end
          3:
          begin
            cbus_active_broad_array     <= 4'b0111;
	    cbus_active_en_access_array <= 4'b1000;
          end
          default
          begin
            cbus_active_broad_array     <= 4'b0000;
	    cbus_active_en_access_array <= 4'b0000;
          end
        endcase
        broad_fifo_rd_o             <= 0;
      end
    else // if (~fifo_status_empty_i)
    begin
        broadcast_in_progress       <= 0;
        cbus_active_broad_array     <= 4'b0000;
        cbus_active_en_access_array <= 4'b0000;
        broad_fifo_rd_o             <= 0;
    end
  else // if (~broadcast_in_progress)
    // Stage 2
    if (|cbus_active_broad_array)     // There is at least on active snoop
                                      //  sub-process
      begin
        broadcast_in_progress       <= 1;
	// Clear related sub-process of a CPU then returns ack for the snoop
        // request.
        cbus_active_broad_array     <= cbus_active_broad_array &
                                       ~cbus_ack_array_i;
        cbus_active_en_access_array <= cbus_active_en_access_array;
        broad_fifo_rd_o             <= 0;
      end
    // Stage 3
    else if (broad_fifo_rd_o)         // All snoop sub-process were done
      begin
        broadcast_in_progress       <= 0;
        cbus_active_broad_array     <= 0;
        cbus_active_en_access_array <= 0;
        broad_fifo_rd_o             <= 0;
      end
    else
      broad_fifo_rd_o <= !(|(cbus_active_en_access_and_not_cbus_ack_array));

assign cbus_active_en_access_and_not_cbus_ack_array =
        cbus_active_en_access_array  & ~cbus_ack_array_i;

endmodule
