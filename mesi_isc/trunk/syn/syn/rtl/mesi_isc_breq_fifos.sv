`include "mesi_isc_define.sv"
`include "mesi_isc_breq_fifos_cntl.sv"
module mesi_isc_breq_fifos  #(
    parameter MBUS_CMD_WIDTH = 3,
    parameter ADDR_WIDTH = 32,
    parameter BROAD_TYPE_WIDTH = 2,
    parameter BROAD_ID_WIDTH = 7,
    parameter BREQ_FIFO_SIZE = 2,
    parameter BREQ_FIFO_SIZE_LOG2 = 1
)(
    // Inputs
    input logic clk,  // System clock
    input logic rst,  // Active high system reset
    input logic [4*MBUS_CMD_WIDTH-1:0] mbus_cmd_array_i,  // Main bus command (array)
    input logic [4*ADDR_WIDTH-1:0] mbus_addr_array_i,  // Main bus address (array)
    input logic broad_fifo_status_full_i,  // The broad fifo is full

    // Outputs
    output logic [3:0] mbus_ack_array_o,  // Bus acknowledge for receiving the broadcast request
    output logic broad_fifo_wr_o,  // Write the broadcast request
    output logic [ADDR_WIDTH-1:0] broad_addr_o,  // Address of the broadcast request
    output logic [BROAD_TYPE_WIDTH-1:0] broad_type_o,  // Type of the broadcast request
    output logic [1:0] broad_cpu_id_o,  // ID of the initiator CPU
    output logic [BROAD_ID_WIDTH-1:0] broad_id_o  // The ID of the broadcast request
);



// Regs & wires
logic [3:0] fifo_status_empty_array;
logic [3:0] fifo_status_full_array;
logic [4*ADDR_WIDTH-1:0] broad_addr_array;
logic [4*BROAD_TYPE_WIDTH-1:0] broad_type_array;
logic [4*BROAD_ID_WIDTH-1:0] broad_id_array;
logic [3:0] fifo_wr_array;
logic [3:0] fifo_rd_array;
logic [4*BROAD_TYPE_WIDTH-1:0] breq_type_array;
logic [4*2-1:0] breq_cpu_id_array;
logic [4*BROAD_ID_WIDTH-1:0] breq_id_array;
logic [4*2-1:0] broad_cpu_id_array;

// Breq fifo control
//================================
mesi_isc_breq_fifos_cntl #(MBUS_CMD_WIDTH,
                           ADDR_WIDTH,
                           BROAD_TYPE_WIDTH,
                           BROAD_ID_WIDTH)
   mesi_isc_breq_fifos_cntl 
    (
     // Inputs
     .clk                   (clk),
     .rst                   (rst),
     .mbus_cmd_array_i      (mbus_cmd_array_i [4*MBUS_CMD_WIDTH-1     :0]),
     .fifo_status_empty_array_i (fifo_status_empty_array            [3:0]),
     .fifo_status_full_array_i  (fifo_status_full_array             [3:0]),
     .broad_fifo_status_full_i (broad_fifo_status_full_i),
     .broad_addr_array_i    (broad_addr_array  [4*ADDR_WIDTH-1        :0]),
     .broad_type_array_i    (broad_type_array  [4*BROAD_TYPE_WIDTH-1  :0]),
     .broad_id_array_i      (broad_id_array    [4*BROAD_ID_WIDTH-1    :0]),
     // Outputs
     .mbus_ack_array_o      (mbus_ack_array_o                        [3:0]),
     .fifo_wr_array_o       (fifo_wr_array                          [3:0]),
     .fifo_rd_array_o       (fifo_rd_array                          [3:0]), 
     .broad_fifo_wr_o       (broad_fifo_wr_o),
     .broad_addr_o          (broad_addr_o      [ADDR_WIDTH-1          :0]),
     .broad_type_o          (broad_type_o      [BROAD_TYPE_WIDTH-1    :0]),
     .broad_cpu_id_o        (broad_cpu_id_o                         [1:0]),
     .broad_id_o            (broad_id_o        [BROAD_ID_WIDTH-1      :0]),
     .breq_type_array_o     (breq_type_array   [4*BROAD_TYPE_WIDTH-1  :0]),
     .breq_cpu_id_array_o   (breq_cpu_id_array [4*2-1                 :0]),
     .breq_id_array_o       (breq_id_array     [4*BROAD_ID_WIDTH-1    :0])
     );

// Breq fifo 3
//================================
mesi_isc_basic_fifo #(ADDR_WIDTH         +  // DATA_WIDTH
                      BROAD_TYPE_WIDTH   +
                      2                  +  // BROAD_CPU_ID_WIDTH
                      BROAD_ID_WIDTH,
                      BREQ_FIFO_SIZE,       // FIFO_SIZE
                      BREQ_FIFO_SIZE_LOG2)  // FIFO_SIZE_LOG2
   //  \ /  (\ / marks the fifo ID) 
   fifo_3 
    (
     // Inputs
     .clk                   (clk),
     .rst                   (rst),
                            //            \ /
     .wr_i                  (fifo_wr_array[3]),
                            //            \ /
     .rd_i                  (fifo_rd_array[3]),
                            //                 \ /
     .data_i                ({mbus_addr_array_i[(3+1)*ADDR_WIDTH-1:
                            //                          \ /
                                                         3*ADDR_WIDTH],
                            //                 \ /
                              breq_type_array [(3+1)*BROAD_TYPE_WIDTH-1:
                            //                          \ /
                                                         3*BROAD_TYPE_WIDTH],
                            //                  \ /
                              breq_cpu_id_array[(3+1)*2-1:
                            //                          \ /
                                                         3*2],
                            //                 \ /
                              breq_id_array   [(3+1)*BROAD_ID_WIDTH-1:
                            //                          \ /
                                                         3*BROAD_ID_WIDTH]}),
     // Outputs
     //                     //                 \ /
     .data_o                ({broad_addr_array [(3+1)*ADDR_WIDTH-1:
                            //                          \ /
                                                         3*ADDR_WIDTH],
                            //                 \ /
                             broad_type_array  [(3+1)*BROAD_TYPE_WIDTH-1:
                            //                          \ /
                                                         3*BROAD_TYPE_WIDTH],
                            //                  \ /
                             broad_cpu_id_array[(3+1)*2-1:
                            //                          \ /
                                                         3*2],
                            //                 \ /
                             broad_id_array    [(3+1)*BROAD_ID_WIDTH-1:
                            //                          \ /
                                                         3*BROAD_ID_WIDTH]}),
                            //                             \ /
     .status_empty_o        (fifo_status_empty_array       [3]),
                            //                             \ /
     .status_full_o         (fifo_status_full_array        [3])
     );

// Breq fifo 2
//================================
mesi_isc_basic_fifo #(ADDR_WIDTH         +  // DATA_WIDTH
                      BROAD_TYPE_WIDTH   +
                      2                  +  // BROAD_CPU_ID_WIDTH
                      BROAD_ID_WIDTH,
                      BREQ_FIFO_SIZE,       // FIFO_SIZE
                      BREQ_FIFO_SIZE_LOG2)  // FIFO_SIZE_LOG2
   //  \ /  (\ / marks the fifo ID) 
   fifo_2 
    (
     // Inputs
     .clk                   (clk),
     .rst                   (rst),
                            //            \ /
     .wr_i                  (fifo_wr_array[2]),
                            //            \ /
     .rd_i                  (fifo_rd_array[2]),
                            //                 \ /
     .data_i                ({mbus_addr_array_i[(2+1)*ADDR_WIDTH-1:
                            //                          \ /
                                                         2*ADDR_WIDTH],
                            //                 \ /
                              breq_type_array [(2+1)*BROAD_TYPE_WIDTH-1:
                            //                          \ /
                                                         2*BROAD_TYPE_WIDTH],
                            //                  \ /
                              breq_cpu_id_array[(2+1)*2-1:
                            //                          \ /
                                                         2*2],
                            //                 \ /
                              breq_id_array   [(2+1)*BROAD_ID_WIDTH-1:
                            //                          \ /
                                                         2*BROAD_ID_WIDTH]}),
     // Outputs
     //                     //                 \ /
     .data_o                ({broad_addr_array [(2+1)*ADDR_WIDTH-1:
                            //                          \ /
                                                         2*ADDR_WIDTH],
                            //                 \ /
                             broad_type_array  [(2+1)*BROAD_TYPE_WIDTH-1:
                            //                          \ /
                                                         2*BROAD_TYPE_WIDTH],
                            //                  \ /
                             broad_cpu_id_array[(2+1)*2-1:
                            //                          \ /
                                                         2*2],
                            //                 \ /
                             broad_id_array    [(2+1)*BROAD_ID_WIDTH-1:
                            //                          \ /
                                                         2*BROAD_ID_WIDTH]}),
                            //                             \ /
     .status_empty_o        (fifo_status_empty_array       [2]),
                            //                             \ /
     .status_full_o         (fifo_status_full_array        [2])
     );

// Breq fifo 1
//================================
mesi_isc_basic_fifo #(ADDR_WIDTH         +  // DATA_WIDTH
                      BROAD_TYPE_WIDTH   +
                      2                  +  // BROAD_CPU_ID_WIDTH
                      BROAD_ID_WIDTH,
                      BREQ_FIFO_SIZE,       // FIFO_SIZE
                      BREQ_FIFO_SIZE_LOG2)  // FIFO_SIZE_LOG2
   //  \ /  (\ / marks the fifo ID) 
   fifo_1 
    (
     // Inputs
     .clk                   (clk),
     .rst                   (rst),
                            //            \ /
     .wr_i                  (fifo_wr_array[1]),
                            //            \ /
     .rd_i                  (fifo_rd_array[1]),
                            //                 \ /
     .data_i                ({mbus_addr_array_i[(1+1)*ADDR_WIDTH-1:
                            //                          \ /
                                                         1*ADDR_WIDTH],
                            //                 \ /
                              breq_type_array [(1+1)*BROAD_TYPE_WIDTH-1:
                            //                          \ /
                                                         1*BROAD_TYPE_WIDTH],
                            //                  \ /
                              breq_cpu_id_array[(1+1)*2-1:
                            //                          \ /
                                                         1*2],
                            //                 \ /
                              breq_id_array   [(1+1)*BROAD_ID_WIDTH-1:
                            //                          \ /
                                                         1*BROAD_ID_WIDTH]}),
     // Outputs
     //                     //                 \ /
     .data_o                ({broad_addr_array [(1+1)*ADDR_WIDTH-1:
                            //                          \ /
                                                         1*ADDR_WIDTH],
                            //                 \ /
                             broad_type_array  [(1+1)*BROAD_TYPE_WIDTH-1:
                            //                          \ /
                                                         1*BROAD_TYPE_WIDTH],
                            //                  \ /
                             broad_cpu_id_array[(1+1)*2-1:
                            //                          \ /
                                                         1*2],
                            //                 \ /
                             broad_id_array    [(1+1)*BROAD_ID_WIDTH-1:
                            //                          \ /
                                                         1*BROAD_ID_WIDTH]}),
                            //                             \ /
     .status_empty_o        (fifo_status_empty_array       [1]),
                            //                             \ /
     .status_full_o         (fifo_status_full_array        [1])
     );

// Breq fifo 0
//================================
mesi_isc_basic_fifo #(ADDR_WIDTH         +  // DATA_WIDTH
                      BROAD_TYPE_WIDTH   +
                      2                  +  // BROAD_CPU_ID_WIDTH
                      BROAD_ID_WIDTH,
                      BREQ_FIFO_SIZE,       // FIFO_SIZE
                      BREQ_FIFO_SIZE_LOG2)  // FIFO_SIZE_LOG2
   //  \ /  (\ / marks the fifo ID) 
   fifo_0 
    (
     // Inputs
     .clk                   (clk),
     .rst                   (rst),
                            //            \ /
     .wr_i                  (fifo_wr_array[0]),
                            //            \ /
     .rd_i                  (fifo_rd_array[0]),
                            //                 \ /
     .data_i                ({mbus_addr_array_i[(0+1)*ADDR_WIDTH-1:
                            //                          \ /
                                                         0*ADDR_WIDTH],
                            //                 \ /
                              breq_type_array [(0+1)*BROAD_TYPE_WIDTH-1:
                            //                          \ /
                                                         0*BROAD_TYPE_WIDTH],
                            //                  \ /
                              breq_cpu_id_array[(0+1)*2-1:
                            //                          \ /
                                                         0*2],
                            //                 \ /
                              breq_id_array   [(0+1)*BROAD_ID_WIDTH-1:
                            //                          \ /
                                                         0*BROAD_ID_WIDTH]}),
     // Outputs
     //                     //                 \ /
     .data_o                ({broad_addr_array [(0+1)*ADDR_WIDTH-1:
                            //                          \ /
                                                         0*ADDR_WIDTH],
                            //                 \ /
                             broad_type_array  [(0+1)*BROAD_TYPE_WIDTH-1:
                            //                          \ /
                                                         0*BROAD_TYPE_WIDTH],
                            //                  \ /
                             broad_cpu_id_array[(0+1)*2-1:
                            //                          \ /
                                                         0*2],
                            //                 \ /
                             broad_id_array    [(0+1)*BROAD_ID_WIDTH-1:
                            //                          \ /
                                                         0*BROAD_ID_WIDTH]}),
                            //                             \ /
     .status_empty_o        (fifo_status_empty_array       [0]),
                            //                             \ /
     .status_full_o         (fifo_status_full_array        [0])
     );

endmodule
