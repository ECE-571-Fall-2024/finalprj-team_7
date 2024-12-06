`include "mesi_isc_define.sv"
`include "mesi_isc_tb_define.sv"
module mesi_isc_tb;

parameter CBUS_CMD_WIDTH = 3;
parameter ADDR_WIDTH = 32;
parameter DATA_WIDTH = 32;
parameter BROAD_TYPE_WIDTH = 2;
parameter BROAD_ID_WIDTH = 5;
parameter BROAD_REQ_FIFO_SIZE = 4;
parameter BROAD_REQ_FIFO_SIZE_LOG2 = 2;
parameter MBUS_CMD_WIDTH = 3;
parameter BREQ_FIFO_SIZE = 2;
parameter BREQ_FIFO_SIZE_LOG2 = 1;

// Regs and wires
//================================
// System
logic clk;          // System clock
logic rst;          // Active high system reset

// Main buses
logic [MBUS_CMD_WIDTH-1:0] mbus_cmd_array [3:0]; // Main bus commands
logic [ADDR_WIDTH-1:0] mbus_addr_array [3:0];    // Main bus addresses
logic [DATA_WIDTH-1:0] mbus_data_wr_array [3:0]; // Main bus data write
logic [7:0] mbus_data_rd_word_array [3:0];       // Bus data read in words
logic [DATA_WIDTH-1:0]  mbus_data_rd;
//logic cbus_ack[3:0]; // Coherence bus acknowledges
logic cbus_ack3,cbus_ack2,cbus_ack1,cbus_ack0 ;
logic [3:0]temp [3:0];
logic [ADDR_WIDTH-1:0] cbus_addr;                // Coherence bus address
//logic [CBUS_CMD_WIDTH-1:0] cbus_cmd[3:0]; // Coherence bus commands
logic [CBUS_CMD_WIDTH-1:0] cbus_cmd3,cbus_cmd2,cbus_cmd1,cbus_cmd0;

logic [3:0] mbus_ack;                            // Main bus acknowledges
logic [3:0] mbus_ack_memory;
logic [3:0] mbus_ack_mesi_isc;
logic [3:0] tb_ins_array [3:0];
logic [3:0] tb_ins_ack;
logic [3:0] tb_ins_addr_array [3:0];
logic [7:0] tb_ins_nop_period [3:0];
logic [31:0] mem   [9:0];                        // Main memory

logic [1:0] cpu_priority;
logic [3:0] cpu_selected;  
logic mem_access;

integer stimulus_rand_numb [9:0];
integer seed;
logic [1:0] stimulus_rand_cpu_select;
logic [1:0] stimulus_op;
logic [7:0] stimulus_addr;
logic [7:0] stimulus_nop_period;

integer cur_stimulus_cpu;


wire   [ADDR_WIDTH+BROAD_TYPE_WIDTH+2+BROAD_ID_WIDTH-1:0] broad_fifo_entry[4];

integer i, j, k, l, m, n, p;

reg [31:0] stat_cpu_access_nop[3:0];
reg [31:0] stat_cpu_access_rd[3:0];
reg [31:0] stat_cpu_access_wr[3:0];

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        tb_ins_array <= '{default:`MESI_ISC_TB_INS_NOP};
        tb_ins_addr_array <= '{default:'0};
        tb_ins_nop_period <= '{default:'0};
    end else begin
        for (m = 0; m < 9; m++) begin
            stimulus_rand_numb[m] = $random(seed);
        end

        stimulus_rand_cpu_select = $unsigned(stimulus_rand_numb[0]) % 4;

        for (l = 0; l < 4; l++) begin
            cur_stimulus_cpu = (stimulus_rand_cpu_select + l) % 4;

            if (tb_ins_nop_period[cur_stimulus_cpu] > 0) begin
                tb_ins_array[cur_stimulus_cpu] = `MESI_ISC_TB_INS_NOP;
                tb_ins_nop_period[cur_stimulus_cpu] -= 1;
            end else if (tb_ins_ack[cur_stimulus_cpu]) begin
                tb_ins_array[cur_stimulus_cpu] = `MESI_ISC_TB_INS_NOP;        
            end else if (tb_ins_array[cur_stimulus_cpu] == `MESI_ISC_TB_INS_NOP) begin
                stimulus_op = $unsigned(stimulus_rand_numb[1+l]) % 20 ;
                if (stimulus_op > 1) stimulus_op = 2;

                stimulus_addr = ($unsigned(stimulus_rand_numb[5+l]) % 5) + 1 ;  
                stimulus_nop_period = ($unsigned(stimulus_rand_numb[9]) % 10) + 1 ;  

                if (stimulus_op == 0) begin
                    tb_ins_nop_period[cur_stimulus_cpu] = stimulus_nop_period;
                end else begin
                    tb_ins_array[cur_stimulus_cpu] = stimulus_op;
                    tb_ins_addr_array[cur_stimulus_cpu] = stimulus_addr;          
                end
            end
        end
    end
end

// Statistic Collection
//================================
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        stat_cpu_access_nop <= '{default:'0};
        stat_cpu_access_rd <= '{default:'0};
        stat_cpu_access_wr <= '{default:'0};
    end else begin
        for (p = 0; p < 4; p++) begin

            if (tb_ins_ack[p])
 begin
temp =$past(tb_ins_array,1);
//$display("temp= %p, tb_ins_array[%d]= %d", temp,p,$past(tb_ins_array[p],1));
                case (temp[p])
                    `MESI_ISC_TB_INS_NOP:
                        stat_cpu_access_nop[p]++;
                    `MESI_ISC_TB_INS_WR:
                        stat_cpu_access_wr[p]++;
                    `MESI_ISC_TB_INS_RD:
                        stat_cpu_access_rd[p]++;
                endcase
            end
        end
    end
end

// Clock generation 
//=====================================
always #50 clk = ~clk;

// Reset and watchdog logic
//=====================================
initial
begin
  // Reset the memory
foreach (mem[j]) begin
    mem[j] = 0;
end
  clk = 1;
  rst = 1;
  repeat (10) @(negedge clk);
  rst = 0;
  repeat (20000) @(negedge clk);   // Watchdog
  $display ("Watchdog finish\n");
  $display ("Statistic\n");
  $display ("CPU 3. WR:%d RD:%d NOP:%d  \n", stat_cpu_access_wr[3],
                                            stat_cpu_access_rd[3],
                                            stat_cpu_access_nop[3]);
  $display ("CPU 2. WR:%d RD:%d NOP:%d\n", stat_cpu_access_wr[2],
                                            stat_cpu_access_rd[2],
                                            stat_cpu_access_nop[2]);
  $display ("CPU 1. WR:%d RD:%d NOP:%d\n", stat_cpu_access_wr[1],
                                            stat_cpu_access_rd[1],
                                            stat_cpu_access_nop[1]);
  $display ("CPU 0. WR: %d RD:%d NOP:%d\n", stat_cpu_access_wr[0],
                                            stat_cpu_access_rd[0],
                                            stat_cpu_access_nop[0]);
  $display ("Total rd and wr accesses: %d\n", stat_cpu_access_wr[3] +
                                              stat_cpu_access_rd[3] +
                                              stat_cpu_access_wr[2] +
                                              stat_cpu_access_rd[2] +
                                              stat_cpu_access_wr[1] +
                                              stat_cpu_access_rd[1] +
                                              stat_cpu_access_wr[0] +
                                              stat_cpu_access_rd[0]);
  $finish;
end

// Dumpfile generation for waveform viewing in GTKWave or similar tools.
//======================================================================
initial begin
    $dumpfile("./dump.vcd");
    $dumpvars(0, mesi_isc_tb);
end
// Sanity check tasks
  task automatic sanity_check_rule1_rule2(
    input logic [3:0] cpu_id,
    input logic [ADDR_WIDTH-1:0] mbus_addr,
    input logic [DATA_WIDTH-1:0] mbus_wr_data
  );
    logic [DATA_WIDTH-1:0] cur_mem_data;

    `ifdef messages
      $display("Message: check err 7. time:%d", $time);
    `endif      
    cur_mem_data = mem[mbus_addr];
    if (cur_mem_data[(3+1)*8-1 : 3*8] > mbus_wr_data[(3+1)*8-1 : 3*8] ||
        cur_mem_data[(2+1)*8-1 : 2*8] > mbus_wr_data[(2+1)*8-1 : 2*8] ||
        cur_mem_data[(1+1)*8-1 : 1*8] > mbus_wr_data[(1+1)*8-1 : 1*8] ||
        cur_mem_data[(0+1)*8-1 : 0*8] > mbus_wr_data[(0+1)*8-1 : 0*8])
    begin
      $display("ERROR 7. The current memory data is bigger than the written data");
      $display("  CPU: %h, Cur data: %h, Written data: %h, Address: %h, time:%d",
               cpu_id,
               cur_mem_data,
               mbus_wr_data,
               mbus_addr,
               $time);
      @(negedge clk) $finish();
    end
  endtask

  // Sanity Check 2 - cache states
  always_ff @(posedge clk or posedge rst) begin
    if (!rst) begin
      for (int k = 0; k < 4; k++) begin
        if (mbus_ack[k]) sanity_check_cache_status(mbus_addr_array[k]);
      end
    end
  end

  task automatic sanity_check_cache_status(
    input logic [ADDR_WIDTH-1:0] mbus_addr
  );
    logic [1:0] num_of_lines_in_m_e_state;
   
    `ifdef messages
      $display("Message: check err 6. time:%d", $time);
    `endif 
    num_of_lines_in_m_e_state = '0;
   
    if(gen_cpu_tb3.cache_state[mbus_addr] == `MESI_ISC_TB_CPU_MESI_E |

     gen_cpu_tb3.cache_state[mbus_addr] == `MESI_ISC_TB_CPU_MESI_M)
     num_of_lines_in_m_e_state = num_of_lines_in_m_e_state + 1; 

  if(gen_cpu_tb2.cache_state[mbus_addr] == `MESI_ISC_TB_CPU_MESI_E |

     gen_cpu_tb2.cache_state[mbus_addr] == `MESI_ISC_TB_CPU_MESI_M)
     num_of_lines_in_m_e_state = num_of_lines_in_m_e_state + 1; 

  if(gen_cpu_tb1.cache_state[mbus_addr] == `MESI_ISC_TB_CPU_MESI_E |

     gen_cpu_tb1.cache_state[mbus_addr] == `MESI_ISC_TB_CPU_MESI_M)
     num_of_lines_in_m_e_state = num_of_lines_in_m_e_state + 1; 

  if(gen_cpu_tb0.cache_state[mbus_addr] == `MESI_ISC_TB_CPU_MESI_E |

     gen_cpu_tb0.cache_state[mbus_addr] == `MESI_ISC_TB_CPU_MESI_M)
     num_of_lines_in_m_e_state = num_of_lines_in_m_e_state + 1;

    if (num_of_lines_in_m_e_state > 1) begin
      $display("Error 6. %d of cache lines are in M or E state. time:%d",
               num_of_lines_in_m_e_state,
               $time);
      @(negedge clk) $finish;
    end
  endtask


// Memory access simulation logic.
//=================================
always @(posedge clk or posedge rst)
  if (rst)
  begin
                     cpu_priority    = 0;
                     cpu_selected    = 0;
  end
  else
  begin
                     mbus_ack_memory = 0;
                     mem_access      = 0;
    for (i = 0; i < 4; i = i + 1)
       if ((mbus_cmd_array[cpu_priority+i] == `MESI_ISC_MBUS_CMD_WR |
            mbus_cmd_array[cpu_priority+i] == `MESI_ISC_MBUS_CMD_RD  ) &
            !mem_access)
    begin
                     mem_access      = 1;
                     cpu_selected    = cpu_priority+i;
                     mbus_ack_memory[cpu_priority+i] = 1;
      if (mbus_cmd_array[cpu_priority+i] == `MESI_ISC_MBUS_CMD_WR)
      // WR
      begin
                     sanity_check_rule1_rule2(cpu_selected,
                                            mbus_addr_array[cpu_priority+i],
                                            mbus_data_wr_array[cpu_priority+i]);
                     mem[mbus_addr_array[cpu_priority+i]] =
                                           mbus_data_wr_array[cpu_priority+i];
      end
      // RD
      else
                     mbus_data_rd =        mem[mbus_addr_array[cpu_priority+i]];
    end
  end
   
assign mbus_ack[3:0] = mbus_ack_memory[3:0] | mbus_ack_mesi_isc[3:0];

// Assigns for debugging and visualization in GTKWave or similar tools.
//======================================================================
assign broad_fifo_entry[0] = mesi_isc.mesi_isc_broad.broad_fifo.entry[0];
assign broad_fifo_entry[1] = mesi_isc.mesi_isc_broad.broad_fifo.entry[1];
assign broad_fifo_entry[2] = mesi_isc.mesi_isc_broad.broad_fifo.entry[2];
assign broad_fifo_entry[3] = mesi_isc.mesi_isc_broad.broad_fifo.entry[3];
    

// Instantiations
//================================

// mesi_isc
mesi_isc #(CBUS_CMD_WIDTH,
           ADDR_WIDTH,
           BROAD_TYPE_WIDTH,
           BROAD_ID_WIDTH,
           BROAD_REQ_FIFO_SIZE,
           BROAD_REQ_FIFO_SIZE_LOG2,
           MBUS_CMD_WIDTH,
           BREQ_FIFO_SIZE,
           BREQ_FIFO_SIZE_LOG2
          )
  mesi_isc
    (
     // Inputs
     .clk              (clk),
     .rst              (rst),
     .mbus_cmd3_i      (mbus_cmd_array[3]),
     .mbus_cmd2_i      (mbus_cmd_array[2]),
     .mbus_cmd1_i      (mbus_cmd_array[1]),
     .mbus_cmd0_i      (mbus_cmd_array[0]),
     .mbus_addr3_i     (mbus_addr_array[3]),
     .mbus_addr2_i     (mbus_addr_array[2]),
     .mbus_addr1_i     (mbus_addr_array[1]),
     .mbus_addr0_i     (mbus_addr_array[0]),
     .cbus_ack3_i      (cbus_ack3),
     .cbus_ack2_i      (cbus_ack2),
     .cbus_ack1_i      (cbus_ack1),
     .cbus_ack0_i      (cbus_ack0),
     // Outputs
     .cbus_addr_o      (cbus_addr),
     .cbus_cmd3_o      (cbus_cmd3),
     .cbus_cmd2_o      (cbus_cmd2),
     .cbus_cmd1_o      (cbus_cmd1),
     .cbus_cmd0_o      (cbus_cmd0),
     .mbus_ack3_o      (mbus_ack_mesi_isc[3]),
     .mbus_ack2_o      (mbus_ack_mesi_isc[2]),
     .mbus_ack1_o      (mbus_ack_mesi_isc[1]),
     .mbus_ack0_o      (mbus_ack_mesi_isc[0])
    );

// CPU testbench modules

        mesi_isc_tb_cpu #(
            .CBUS_CMD_WIDTH(CBUS_CMD_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH),
            .DATA_WIDTH(DATA_WIDTH),
            .BROAD_TYPE_WIDTH(BROAD_TYPE_WIDTH),
            .BROAD_ID_WIDTH(BROAD_ID_WIDTH),
            .BROAD_REQ_FIFO_SIZE(BROAD_REQ_FIFO_SIZE),
            .BROAD_REQ_FIFO_SIZE_LOG2(BROAD_REQ_FIFO_SIZE_LOG2),
            .MBUS_CMD_WIDTH(MBUS_CMD_WIDTH),
            .BREQ_FIFO_SIZE(BREQ_FIFO_SIZE),
            .BREQ_FIFO_SIZE_LOG2(BREQ_FIFO_SIZE_LOG2)
        ) gen_cpu_tb3 (
            .clk(clk),
            .rst(rst),
            .cbus_addr_i(cbus_addr),
            .cbus_cmd_i(cbus_cmd3),
            .mbus_data_i(mbus_data_rd),
            .mbus_ack_i(mbus_ack[3]),
            .cpu_id_i(2'd3),
            .tb_ins_i(tb_ins_array[3]),
            .tb_ins_addr_i(tb_ins_addr_array[3]),
            .mbus_cmd_o(mbus_cmd_array[3]),
            .mbus_addr_o(mbus_addr_array[3]),
            .mbus_data_o(mbus_data_wr_array[3]),
            .cbus_ack_o(cbus_ack3),
            .tb_ins_ack_o(tb_ins_ack[3])
        );

  mesi_isc_tb_cpu #(
            .CBUS_CMD_WIDTH(CBUS_CMD_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH),
            .DATA_WIDTH(DATA_WIDTH),
            .BROAD_TYPE_WIDTH(BROAD_TYPE_WIDTH),
            .BROAD_ID_WIDTH(BROAD_ID_WIDTH),
            .BROAD_REQ_FIFO_SIZE(BROAD_REQ_FIFO_SIZE),
            .BROAD_REQ_FIFO_SIZE_LOG2(BROAD_REQ_FIFO_SIZE_LOG2),
            .MBUS_CMD_WIDTH(MBUS_CMD_WIDTH),
            .BREQ_FIFO_SIZE(BREQ_FIFO_SIZE),
            .BREQ_FIFO_SIZE_LOG2(BREQ_FIFO_SIZE_LOG2)
        ) gen_cpu_tb2 (
            .clk(clk),
            .rst(rst),
            .cbus_addr_i(cbus_addr),
            .cbus_cmd_i(cbus_cmd2),
            .mbus_data_i(mbus_data_rd),
            .mbus_ack_i(mbus_ack[2]),
            .cpu_id_i(2'd2),
            .tb_ins_i(tb_ins_array[2]),
            .tb_ins_addr_i(tb_ins_addr_array[2]),
            .mbus_cmd_o(mbus_cmd_array[2]),
            .mbus_addr_o(mbus_addr_array[2]),
            .mbus_data_o(mbus_data_wr_array[2]),
            .cbus_ack_o(cbus_ack2),
            .tb_ins_ack_o(tb_ins_ack[2])
        );

  mesi_isc_tb_cpu #(
            .CBUS_CMD_WIDTH(CBUS_CMD_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH),
            .DATA_WIDTH(DATA_WIDTH),
            .BROAD_TYPE_WIDTH(BROAD_TYPE_WIDTH),
            .BROAD_ID_WIDTH(BROAD_ID_WIDTH),
            .BROAD_REQ_FIFO_SIZE(BROAD_REQ_FIFO_SIZE),
            .BROAD_REQ_FIFO_SIZE_LOG2(BROAD_REQ_FIFO_SIZE_LOG2),
            .MBUS_CMD_WIDTH(MBUS_CMD_WIDTH),
            .BREQ_FIFO_SIZE(BREQ_FIFO_SIZE),
            .BREQ_FIFO_SIZE_LOG2(BREQ_FIFO_SIZE_LOG2)
        ) gen_cpu_tb1 (
            .clk(clk),
            .rst(rst),
            .cbus_addr_i(cbus_addr),
            .cbus_cmd_i(cbus_cmd1),
            .mbus_data_i(mbus_data_rd),
            .mbus_ack_i(mbus_ack[1]),
            .cpu_id_i(2'd1),
            .tb_ins_i(tb_ins_array[1]),
            .tb_ins_addr_i(tb_ins_addr_array[1]),
            .mbus_cmd_o(mbus_cmd_array[1]),
            .mbus_addr_o(mbus_addr_array[1]),
            .mbus_data_o(mbus_data_wr_array[1]),
            .cbus_ack_o(cbus_ack1),
            .tb_ins_ack_o(tb_ins_ack[1])
        );

  mesi_isc_tb_cpu #(
            .CBUS_CMD_WIDTH(CBUS_CMD_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH),
            .DATA_WIDTH(DATA_WIDTH),
            .BROAD_TYPE_WIDTH(BROAD_TYPE_WIDTH),
            .BROAD_ID_WIDTH(BROAD_ID_WIDTH),
            .BROAD_REQ_FIFO_SIZE(BROAD_REQ_FIFO_SIZE),
            .BROAD_REQ_FIFO_SIZE_LOG2(BROAD_REQ_FIFO_SIZE_LOG2),
            .MBUS_CMD_WIDTH(MBUS_CMD_WIDTH),
            .BREQ_FIFO_SIZE(BREQ_FIFO_SIZE),
            .BREQ_FIFO_SIZE_LOG2(BREQ_FIFO_SIZE_LOG2)
        ) gen_cpu_tb0 (
            .clk(clk),
            .rst(rst),
            .cbus_addr_i(cbus_addr),
            .cbus_cmd_i(cbus_cmd0),
            .mbus_data_i(mbus_data_rd),
            .mbus_ack_i(mbus_ack[0]),
            .cpu_id_i(2'd0),
            .tb_ins_i(tb_ins_array[0]),
            .tb_ins_addr_i(tb_ins_addr_array[0]),
            .mbus_cmd_o(mbus_cmd_array[0]),
            .mbus_addr_o(mbus_addr_array[0]),
            .mbus_data_o(mbus_data_wr_array[0]),
            .cbus_ack_o(cbus_ack0),
            .tb_ins_ack_o(tb_ins_ack[0])
        );
        

endmodule
