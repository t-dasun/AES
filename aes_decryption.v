`timescale 1ns / 1ps

module aes_decryption (
	input aclk,    // Clock
	input aresetn,  // Asynchronous reset active low

	input wire            next,//next 128 data block//if key is ready and new block arrived
  
	input wire            keylen,//must be zero next clock cycle
	input wire [127 : 0]  key,
  input wire            key_init,
  output wire           key_ready,

  input wire [127 : 0]  input_block,
  output reg [127 : 0]  output_block,
  output reg            block_ready
  );

//----------------------------------------------------------------
// Parameters.
//----------------------------------------------------------------
localparam AES_128_NUM_ROUNDS   = 4'd10;

localparam STATE_IDLE           = 3'd0 ;   
localparam STATE_INIT           = 3'd1 ;             
localparam STATE_KEY_ADD        = 3'd2 ;                                           
localparam STATE_MIX_COLUMN     = 3'd3 ;                       
localparam STATE_SHIFT_ROW      = 3'd4 ;                   
localparam STATE_BYTE_SUB       = 3'd5 ;   
localparam STATE_DONE           = 3'd6 ;   

localparam STATE_SBOX_IDLE      = 3'd0 ; 
localparam STATE_SBOX_INIT      = 3'd1 ;  
localparam STATE_SBOX_0         = 3'd2 ;     
localparam STATE_SBOX_1         = 3'd3 ;      
localparam STATE_SBOX_2         = 3'd4 ;     
localparam STATE_SBOX_3         = 3'd5 ; 
localparam STATE_SBOX_4         = 3'd6 ;  
localparam STATE_SBOX_DONE      = 3'd7 ;     

//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//--------------------------------------------------------------------------------------------------------------------- 

//reg [127:0] key;     
wire         keylen ;  
//reg         key_init; 
reg [ 3 :0] round ;   
wire[ 3 :0] round_inv ;
wire [127:0] round_key;
//wire         key_ready;
wire [31 :0] sbox_feed;
wire [31 :0] new_sbox ;

reg [ 4 :0] state;  
reg [ 4 :0] state_s_box;

reg [127:0] round_block_add_key;  
reg [127:0] round_block_BYTE_S;
reg [127:0] round_block_Shift_R;
reg [127:0] round_block_Mix_C;  

reg [31 :0] sbox_inv_feed;
wire  [31 :0] new_inv_sbox;

reg s_box_sub_done;

reg [31 : 0] ws0, ws1, ws2, ws3; 
//----------------------------------------------------------------
// assignments for ports.
//----------------------------------------------------------------
//assign feed_sbox = sbox_feed; 
assign round_inv = AES_128_NUM_ROUNDS - round;
//---------------------------------------------------------------------------------------------------------------------
// Implementation
//---------------------------------------------------------------------------------------------------------------------


always @(posedge aclk) begin
  if(!aresetn) begin
    state <= STATE_IDLE;
  end else begin
    case (state)
      STATE_IDLE        :
      begin
          if (next) begin //next && 
            state   <=  STATE_INIT;
          end
        end
        STATE_INIT        :
        begin
          state    <=   STATE_KEY_ADD;
        end
        STATE_KEY_ADD     :
        begin
          if (round == AES_128_NUM_ROUNDS) begin
            state   <= STATE_DONE;
          end else if (round == 4'b0) begin
            state   <= STATE_SHIFT_ROW;
          end else begin
            state   <= STATE_MIX_COLUMN;
          end   
        end
        STATE_MIX_COLUMN  :
        begin
          state    <=   STATE_SHIFT_ROW;
        end
        STATE_SHIFT_ROW   :
        begin
          state    <=   STATE_BYTE_SUB; 
        end
        STATE_BYTE_SUB    :
        begin
          if (s_box_sub_done) begin
            state    <=   STATE_KEY_ADD;
          end
        end
        STATE_DONE        :
        begin
          state       <= STATE_IDLE;
        end
        
        default : /* default */;
      endcase
    end
  end

//init
always @(posedge aclk) 
begin 
  if(!aresetn) begin
    round_block_BYTE_S   <=  128'b0;
  end else begin
    case (state)

      STATE_IDLE        :
      begin
          //0
          round_block_BYTE_S   <=  128'b0;
        end
        STATE_INIT        :
        begin
          //1
          round_block_BYTE_S  <= input_block;
        end

        default : /* default */;
      endcase
    end
  end

//round key add
always @(posedge aclk) 
begin 
  if(!aresetn) begin
    round_block_add_key <=  128'b0;  
  end else begin
    case (state)
      STATE_IDLE        :
      begin
        round_block_add_key   <=  128'b0;
      end
      STATE_KEY_ADD     :
      begin
          //2
          round_block_add_key <= addroundkey(round_block_BYTE_S,round_key);
        end
        
        default : /* default */;
      endcase
    end
  end

//mix col
always @(posedge aclk) 
begin 
  if(!aresetn) begin
    round_block_Mix_C   <=  128'h0;  
  end else begin
    case (state)
      STATE_IDLE        :
      begin
        round_block_Mix_C   <=  128'b0;
      end
      STATE_MIX_COLUMN  :
      begin
          //3
          round_block_Mix_C <=  inv_mixcolumns(round_block_add_key);
        end
        
        default : /* default */;
      endcase
    end
  end

//shiftrow
always @(posedge aclk) 
begin 
  if(!aresetn) begin
    round_block_Shift_R  <=  128'h0;
  end else begin
    case (state)
      STATE_IDLE        :
      begin
        round_block_Shift_R   <=  128'b0;
      end
      STATE_SHIFT_ROW   :
      begin
          //4
          if (round == 4'b0) begin
            round_block_Shift_R <= inv_shiftrows(round_block_add_key);
          end else begin
            round_block_Shift_R <= inv_shiftrows(round_block_Mix_C);
          end
        end
        
        default : /* default */;
      endcase
    end
  end

//round increment
always @(posedge aclk) 
begin 
  if(!aresetn) begin
    round   <=  4'b0;
  end else begin
    case (state)
      STATE_IDLE        :
      begin
        round   <=  4'b0;
      end
      STATE_SHIFT_ROW    :
      begin
        round   <= round + 1'b1;
      end

      default : /* default */;
    endcase
  end
end

//s_box inv
always @(posedge aclk) begin
  if(!aresetn) begin
   state_s_box <= STATE_SBOX_IDLE;
   s_box_sub_done <= 1'b0;
   round_block_BYTE_S <= 128'b0;
 end else begin
  case (state_s_box)
    STATE_SBOX_IDLE   :
    begin
      if (state == STATE_BYTE_SUB && !s_box_sub_done) begin
        state_s_box <= STATE_SBOX_INIT;
      end
      s_box_sub_done     <= 1'b0;
    end
    STATE_SBOX_INIT   :
    begin
      s_box_sub_done     <= 1'b0;
      ws0 <= round_block_Shift_R[127 : 096];
      ws1 <= round_block_Shift_R[095 : 064];
      ws2 <= round_block_Shift_R[063 : 032];
      ws3 <= round_block_Shift_R[031 : 000];
        /*if (state == STATE_BYTE_SUB) begin
          state_s_box <= STATE_SBOX_0;
        end*/
        state_s_box <= STATE_SBOX_0;
      end
      STATE_SBOX_0      :
      begin
        sbox_inv_feed      <=  ws0;
        state_s_box <= STATE_SBOX_1;
      end
      STATE_SBOX_1      :
      begin
        ws0            <=  new_inv_sbox;
        sbox_inv_feed      <=  ws1;
        state_s_box <= STATE_SBOX_2;
      end
      STATE_SBOX_2      :
      begin
        ws1            <=  new_inv_sbox;
        sbox_inv_feed      <=  ws2;
        state_s_box <= STATE_SBOX_3;
      end
      STATE_SBOX_3      :
      begin  
        ws2            <=  new_inv_sbox;
        sbox_inv_feed      <=  ws3;
        state_s_box <= STATE_SBOX_4;
      end
      STATE_SBOX_4      :
      begin
        ws3            <=  new_inv_sbox;
        state_s_box    <=  STATE_SBOX_DONE;
      end
      STATE_SBOX_DONE  :
      begin
        s_box_sub_done     <= 1'b1;
        round_block_BYTE_S <= {ws0, ws1, ws2, ws3};
        state_s_box <= STATE_SBOX_IDLE;
        
      end
      
      default : ;
    endcase
  end
end

//done
always @(posedge aclk) 
begin 
  if(!aresetn) begin
    output_block      <=  128'b0;  
    block_ready       <= 1'b0;     
  end else begin
    case (state)
      STATE_IDLE        :
      begin
          if (next) begin //next && 
            block_ready <= 1'b0;
          end
        end
        STATE_DONE        :
        begin
          //6
          output_block      <=  round_block_add_key;
          block_ready       <= 1'b1;
        end
        
        default : /* default */;
      endcase
    end
  end

  aes_key_gen 
  #(
    )
  aes_key_gen_inv_dut
  (
    .aclk     (aclk     ),
    .aresetn  (aresetn  ),
    .key      (key     ),                       
    .keylen   (keylen   ),
    .key_init (key_init ),
    .round    (round_inv),
    .round_key(round_key),
    .key_ready(key_ready),
    .sbox_feed(sbox_feed),
    .new_sbox (new_sbox )

    );

  aes_sbox_inv
  #(
    )sbox_inv_dut
  (
    .sword (sbox_inv_feed),
    .new_sword (new_inv_sbox)
    );

  sbox
  #(
    )sbox_dut_1
  (
    .sboxw (sbox_feed),
    .new_sboxw (new_sbox)
    );

//----------------------------------------------------------------
//functions and sub functions.
//----------------------------------------------------------------
function [7 : 0] gm2(input [7 : 0] op);
  begin
    gm2 = {op[6 : 0], 1'b0} ^ (8'h1b & {8{op[7]}});
  end
  endfunction // gm2

  function [7 : 0] gm3(input [7 : 0] op);
    begin
      gm3 = gm2(op) ^ op;
    end
  endfunction // gm3

  function [7 : 0] gm4(input [7 : 0] op);
    begin
      gm4 = gm2(gm2(op));
    end
  endfunction // gm4

  function [7 : 0] gm8(input [7 : 0] op);
    begin
      gm8 = gm2(gm4(op));
    end
  endfunction // gm8

  function [7 : 0] gm09(input [7 : 0] op);
    begin
      gm09 = gm8(op) ^ op;
    end
  endfunction // gm09

  function [7 : 0] gm11(input [7 : 0] op);
    begin
      gm11 = gm8(op) ^ gm2(op) ^ op;
    end
  endfunction // gm11

  function [7 : 0] gm13(input [7 : 0] op);
    begin
      gm13 = gm8(op) ^ gm4(op) ^ op;
    end
  endfunction // gm13

  function [7 : 0] gm14(input [7 : 0] op);
    begin
      gm14 = gm8(op) ^ gm4(op) ^ gm2(op);
    end
  endfunction // gm14

  function [31 : 0] inv_mixw(input [31 : 0] w);
    reg [7 : 0] b0, b1, b2, b3;
    reg [7 : 0] mb0, mb1, mb2, mb3;
    begin
      b0 = w[31 : 24];
      b1 = w[23 : 16];
      b2 = w[15 : 08];
      b3 = w[07 : 00];

      mb0 = gm14(b0) ^ gm11(b1) ^ gm13(b2) ^ gm09(b3);
      mb1 = gm09(b0) ^ gm14(b1) ^ gm11(b2) ^ gm13(b3);
      mb2 = gm13(b0) ^ gm09(b1) ^ gm14(b2) ^ gm11(b3);
      mb3 = gm11(b0) ^ gm13(b1) ^ gm09(b2) ^ gm14(b3);

      inv_mixw = {mb0, mb1, mb2, mb3};
    end
  endfunction // mixw

  function [127 : 0] inv_mixcolumns(input [127 : 0] data);
    reg [31 : 0] w0, w1, w2, w3;
    reg [31 : 0] ws0, ws1, ws2, ws3;
    begin
      w0 = data[127 : 096];
      w1 = data[095 : 064];
      w2 = data[063 : 032];
      w3 = data[031 : 000];

      ws0 = inv_mixw(w0);
      ws1 = inv_mixw(w1);
      ws2 = inv_mixw(w2);
      ws3 = inv_mixw(w3);

      inv_mixcolumns = {ws0, ws1, ws2, ws3};
    end
  endfunction // inv_mixcolumns

  function [127 : 0] inv_shiftrows(input [127 : 0] data);
    reg [31 : 0] w0, w1, w2, w3;
    reg [31 : 0] ws0, ws1, ws2, ws3;
    begin
      w0 = data[127 : 096];
      w1 = data[095 : 064];
      w2 = data[063 : 032];
      w3 = data[031 : 000];

      ws0 = {w0[31 : 24], w3[23 : 16], w2[15 : 08], w1[07 : 00]};
      ws1 = {w1[31 : 24], w0[23 : 16], w3[15 : 08], w2[07 : 00]};
      ws2 = {w2[31 : 24], w1[23 : 16], w0[15 : 08], w3[07 : 00]};
      ws3 = {w3[31 : 24], w2[23 : 16], w1[15 : 08], w0[07 : 00]};

      inv_shiftrows = {ws0, ws1, ws2, ws3};
    end
  endfunction // inv_shiftrows

  function [127 : 0] addroundkey(input [127 : 0] data, input [127 : 0] rkey);
    begin
      addroundkey = data ^ rkey;
    end
  endfunction // addroundkey
endmodule //aes_encryption


