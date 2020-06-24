`timescale 1ns / 1ps

module aes_encryption (
	input aclk,    // Clock
	input aresetn,  // Asynchronous reset active low

	input wire            next,//next 128 data block//if key is ready and new block arrived
  
	input wire            keylen,//must be zero next clock cycle
	input wire [127 : 0]  key,
  input wire            key_init,
  output wire           key_ready,

  input wire [127 : 0]  input_block,
  output reg [127 : 0] output_block,
  output reg            block_ready
  );

//----------------------------------------------------------------
// Parameters.
//----------------------------------------------------------------
localparam AES_128_NUM_ROUNDS   = 4'd10;

localparam STATE_IDLE           = 3'd0 ;   
localparam STATE_INIT           = 3'd1 ;             
localparam STATE_BYTE_SUB       = 3'd2 ;                                           
localparam STATE_SHIFT_ROW      = 3'd3 ;                       
localparam STATE_MIX_COLUMN     = 3'd4 ;                   
localparam STATE_KEY_ADD        = 3'd5 ;   
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
wire [127:0] round_key;
//wire         key_ready;
reg [31 :0] sbox_feed;
wire [31 :0] new_sbox ;

reg [ 4 :0] state;  
reg [ 4 :0] state_s_box;

reg [127:0] round_block_init;  
reg [127:0] round_block_BYTE_S;
reg [127:0] round_block_Shift_R;
reg [127:0] round_block_Mix_C;  

wire [31 :0] feed_sbox_keygen;
reg  [31 :0] feed_sbox_enc; 

reg s_box_sub_done;

reg [31 : 0] ws0, ws1, ws2, ws3; 
//----------------------------------------------------------------
// assignments for ports.
//----------------------------------------------------------------
//assign feed_sbox = sbox_feed; 
//---------------------------------------------------------------------------------------------------------------------
// Implementation
//---------------------------------------------------------------------------------------------------------------------

//sbox selection
always @(*) 
begin :sbox
  if (!key_ready) begin
    sbox_feed <= feed_sbox_keygen;
  end else begin
    sbox_feed <= feed_sbox_enc;
  end
end

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
          state    <=   STATE_BYTE_SUB;
        end
        STATE_BYTE_SUB    :
        begin
          if (s_box_sub_done) begin
            state    <=   STATE_SHIFT_ROW;
          end
        end
        STATE_SHIFT_ROW   :
        begin
          if (round == AES_128_NUM_ROUNDS) begin
            state   <= STATE_KEY_ADD;
          end else begin
            state   <=   STATE_MIX_COLUMN;
          end 
        end
        STATE_MIX_COLUMN  :
        begin
          state    <=   STATE_KEY_ADD;
        end
        STATE_KEY_ADD     :
        begin
          if (round == AES_128_NUM_ROUNDS) begin
            state   <= STATE_DONE;
          end else begin
            state   <= STATE_BYTE_SUB;
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

//round 
always @(posedge aclk) begin
  if(!aresetn) begin
    round   <=  4'b0;
  end else begin
    case (state)
      STATE_IDLE        :
      begin
        round   <=  4'b0;
      end
      STATE_INIT        :
      begin
        round   <= round + 1'b1;
      end
      STATE_KEY_ADD     :
      begin
        round   <= round + 1'b1;
      end
      
      default : /* default */;
    endcase
  end
end

//init
always @(posedge aclk) 
begin 
  if(!aresetn) begin
    round_block_init   <=  128'b0;
  end else begin
    case (state)

      STATE_IDLE        :
      begin
          //0
          round_block_init   <=  128'b0;
        end
        STATE_INIT        :
        begin
          //1
          round_block_init   <=  addroundkey(input_block,round_key);
        end

        default : /* default */;
      endcase
    end
  end

//s_box
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
      ws0 <= round_block_init[127 : 096];
      ws1 <= round_block_init[095 : 064];
      ws2 <= round_block_init[063 : 032];
      ws3 <= round_block_init[031 : 000];
        /*if (state == STATE_BYTE_SUB) begin
          state_s_box <= STATE_SBOX_0;
        end*/
        state_s_box <= STATE_SBOX_0;
      end
      STATE_SBOX_0      :
      begin
        feed_sbox_enc      <=  ws0;
        state_s_box <= STATE_SBOX_1;
      end
      STATE_SBOX_1      :
      begin
        ws0            <=  new_sbox;
        feed_sbox_enc      <=  ws1;
        state_s_box <= STATE_SBOX_2;
      end
      STATE_SBOX_2      :
      begin
        ws1            <=  new_sbox;
        feed_sbox_enc      <=  ws2;
        state_s_box <= STATE_SBOX_3;
      end
      STATE_SBOX_3      :
      begin  
        ws2            <=  new_sbox;
        feed_sbox_enc      <=  ws3;
        state_s_box <= STATE_SBOX_4;
      end
      STATE_SBOX_4      :
      begin
        ws3            <=  new_sbox;
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

//shiftrow
always @(posedge aclk) 
begin 
  if(!aresetn) begin
    round_block_BYTE_S  <=  128'h0;
    round_block_Shift_R <=  128'h0;
  end else begin
    case (state)
      STATE_IDLE        :
      begin
          //0
          round_block_Shift_R   <=  128'b0;
        end
        STATE_SHIFT_ROW   :
        begin
          //3
          round_block_Shift_R <= shiftrows(round_block_BYTE_S);
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
    round_block_Shift_R <=  128'h0; 
  end else begin
    case (state)
      STATE_IDLE        :
      begin
          //0
          round_block_Mix_C   <=  128'b0;
        end
        STATE_MIX_COLUMN  :
        begin
          //4
          round_block_Mix_C <=  mixcolumns(round_block_Shift_R);
        end
        
        default : /* default */;
      endcase
    end
  end

//round key add
always @(posedge aclk) 
begin 
  if(!aresetn) begin
    round_block_init  <=  128'b0; 
    round_block_Mix_C <=  128'b0;
    output_block      <=  128'b0;       
  end else begin
    case (state)
      STATE_KEY_ADD     :
      begin
          //5
          if (round == AES_128_NUM_ROUNDS) begin
            round_block_init <= addroundkey(round_block_Shift_R,round_key);
          end else begin
            round_block_init  <= addroundkey(round_block_Mix_C,round_key);
          end
        end
        
        default : /* default */;
      endcase
    end
  end

//done
always @(posedge aclk) 
begin 
  if(!aresetn) begin
    round_block_init  <=  128'b0; 
    round_block_Mix_C <=  128'b0;
    output_block      <=  128'b0; 
    block_ready      <= 1'b0;      
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
          block_ready       <=  1'b1;
          output_block      <=  round_block_init;
        end
        
        default : /* default */;
      endcase
    end
  end

  aes_key_gen 
  #(
    )
  aes_key_gen_dut_0
  (
    .aclk     (aclk     ),
    .aresetn  (aresetn  ),
    .key      (key     ),                       
    .keylen   (keylen   ),
    .key_init (key_init ),
    .round    (round    ),
    .round_key(round_key),
    .key_ready(key_ready),
    .sbox_feed(feed_sbox_keygen),
    .new_sbox (new_sbox )

    );

  sbox
  #(
    )sbox_dut_0
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

function [31 : 0] mixw(input [31 : 0] w);
  reg [7 : 0] b0, b1, b2, b3;
  reg [7 : 0] mb0, mb1, mb2, mb3;
  begin
    b0 = w[31 : 24];
    b1 = w[23 : 16];
    b2 = w[15 : 08];
    b3 = w[07 : 00];

    mb0 = gm2(b0) ^ gm3(b1) ^ b2      ^ b3;
    mb1 = b0      ^ gm2(b1) ^ gm3(b2) ^ b3;
    mb2 = b0      ^ b1      ^ gm2(b2) ^ gm3(b3);
    mb3 = gm3(b0) ^ b1      ^ b2      ^ gm2(b3);

    mixw = {mb0, mb1, mb2, mb3};
  end
endfunction // mixw

function [127 : 0] mixcolumns(input [127 : 0] data);
  reg [31 : 0] w0, w1, w2, w3;
  reg [31 : 0] wc0, wc1, wc2, wc3;
  begin
    w0 = data[127 : 096];
    w1 = data[095 : 064];
    w2 = data[063 : 032];
    w3 = data[031 : 000];

    wc0 = mixw(w0);
    wc1 = mixw(w1);
    wc2 = mixw(w2);
    wc3 = mixw(w3);

    mixcolumns = {wc0, wc1, wc2, wc3};
  end
endfunction // mixcolumns

function [127 : 0] shiftrows(input [127 : 0] data);
  reg [31 : 0] w0, w1, w2, w3;
  reg [31 : 0] wsr0, wsr1, wsr2, wsr3;
  begin
    w0 = data[127 : 096];
    w1 = data[095 : 064];
    w2 = data[063 : 032];
    w3 = data[031 : 000];

    wsr0 = {w0[31 : 24], w1[23 : 16], w2[15 : 08], w3[07 : 00]};
    wsr1 = {w1[31 : 24], w2[23 : 16], w3[15 : 08], w0[07 : 00]};
    wsr2 = {w2[31 : 24], w3[23 : 16], w0[15 : 08], w1[07 : 00]};
    wsr3 = {w3[31 : 24], w0[23 : 16], w1[15 : 08], w2[07 : 00]};

    shiftrows = {wsr0, wsr1, wsr2, wsr3};
  end
endfunction // shiftrows

function [127 : 0] addroundkey(input [127 : 0] data, input [127 : 0] rkey);
  begin
    addroundkey = data ^ rkey;
  end
endfunction // addroundkey

/*function [127 : 0] byte_s_box(input [127 : 0] data);
reg [31 : 0] ws0, ws1, ws2, ws3;  
begin
  ws0 = s_box_sub(data[127 : 096]);
  ws1 = s_box_sub(data[095 : 064]);
  ws2 = s_box_sub(data[063 : 032]);
  ws3 = s_box_sub(data[031 : 000]);

  byte_s_box = {ws0, ws1, ws2, ws3};
end
endfunction 

function [32 : 0] s_box_sub(input [32 : 0] w);

begin
  feed_sbox = w;
  s_box_sub = new_sbox;
end
endfunction */

/*task byte_s_box(
    input [127 : 0] data
  );
  begin
    s_box_sub_done = 1'b0;
    
    ws0 = data[127 : 096];
    ws1 = data[095 : 064];
    ws2 = data[063 : 032];
    ws3 = data[031 : 000];
    @(posedge aclk);
    feed_sbox_enc      =  ws0;
    @(posedge aclk);
    ws0            =  new_sbox;
    feed_sbox_enc      =  ws1;
    @(posedge aclk);
    ws1            =  new_sbox;
    feed_sbox_enc      =  ws2;
    @(posedge aclk);
    ws2            =  new_sbox;
    feed_sbox_enc      =  ws3;
    @(posedge aclk);
    ws3            =  new_sbox;

    @(posedge aclk);
    round_block_BYTE_S = {ws0, ws1, ws2, ws3};
    s_box_sub_done     = 1'b1;
    @(posedge aclk);
    s_box_sub_done = 1'b0;

  end
endtask // byte_s_box
*/



endmodule //aes_encryption


