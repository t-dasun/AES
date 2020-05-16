`timescale 1ns / 1ps

module rng512LFSR2_tb ();
 
  parameter c_NUM_BITS = 128;
  localparam      CLK                 = 4;
  localparam      HALF_CLK            = CLK/2;
   
  reg aclk;
  reg aresetn;


   
  wire [c_NUM_BITS-1:0] pq_fifo_dout;//din to pq fifo
  wire o_LFSR_Done;
  wire pq_fifo_wr_en ;
  wire pq_fifo_full ;
  wire pq_fifo_empty;
  wire pq_fifo_rd_en ;
  wire [c_NUM_BITS-1:0] pq_fifo_din;//din to Primality test
  wire [c_NUM_BITS-1:0] prime_out;

  initial begin
    aclk                         = 0;
    forever begin      
        #(HALF_CLK)   aclk       = ~aclk;
    end
  end

  initial begin
        // Initialize Registers
        aresetn <= 1'b0;
        // Wait 100 ns for global reset to finish
        #100;
        @(posedge aclk);
        aresetn <=1'b1;
      
         

  end
   
  rng512LFSR2 
  #(
    .NUM_BITS(c_NUM_BITS)
    ) LFSR_inst
         (
          .aclk(aclk),
          .aresetn(aresetn),
          .pq_fifo_dout(pq_fifo_dout),
          .pq_fifo_wr_en(pq_fifo_wr_en),  
          .pq_fifo_full (pq_fifo_full),
          .o_LFSR_Done(o_LFSR_Done)
       
          );

  fifo_generator_0 your_instance_name (//asyncross clk
  .clk(aclk),      // input wire clk
  .srst(!aresetn),    // input wire srst
  .din(pq_fifo_dout),      // input wire [127 : 0] din
  .wr_en(pq_fifo_wr_en),  // input wire wr_en
  .rd_en(pq_fifo_rd_en),  // input wire rd_en
  .dout(pq_fifo_din),    // output wire [127 : 0] dout
  .full(pq_fifo_full),    // output wire full
  .empty(pq_fifo_empty)  // output wire empty
);


  primality_test
  #(
    .NUM_BITS(c_NUM_BITS)
    )primality_test_inst
  (
    .aclk(aclk),
    .aresetn(aresetn),
    .prime_out(prime_out),
    .pq_fifo_rd_en(pq_fifo_rd_en),
    .pq_fifo_din(pq_fifo_din),
    .pq_fifo_empty(pq_fifo_empty)
    
    );

   
endmodule // rng512LFSR2_tb