`timescale 1ns / 1ps

module aes_tb ();
  localparam      CLK                 = 4;
  localparam      HALF_CLK            = CLK/2;

  reg           aclk;
  reg           aresetn;

  reg [127 : 0]  key;

  reg [127 : 0]  key_enc;         
  reg            key_init_enc;   
  reg            key_ready_enc;
  reg [127 : 0]  input_block_enc;
  reg [127 : 0]  output_block_enc;
  reg            block_ready_enc;
  reg            next_bolck_enc;

  reg [127 : 0]  key_dec;
  reg            key_init_dec;
  reg            key_ready_dec;
  reg [127 : 0]  input_block_dec;
  reg [127 : 0]  output_block_dec;
  reg            block_ready_dec;
  reg            next_bolck_dec;

  reg [2:0]      cnt;
  reg [2:0]      state;
  reg [127 : 0]  block   [0 : 3];

  localparam STATE_IDLE         = 3'd0;        
  localparam STATE_INIT         = 3'd1;           
  localparam STATE_BLOCK        = 3'd2;       
  localparam STATE_BLOCK_NEXT   = 3'd3; 
  localparam STATE_BLOCK_NEXT_1 = 3'd4;              
  localparam STATE_DONE         = 3'd5;            

  aes
  #(
    )aes_dut
(
  .aclk(aclk),
  .aresetn(aresetn),
  .key_enc(key_enc),         
  .key_init_enc(key_init_enc),    
  .key_ready_enc(key_ready_enc),
  .input_block_enc(input_block_enc),
  .output_block_enc(output_block_enc),
  .block_ready_enc(block_ready_enc),
  .next_bolck_enc(next_bolck_enc),
  .key_dec(key_dec),
  .key_init_dec(key_init_dec),
  .key_ready_dec(key_ready_dec),
  .input_block_dec(input_block_dec),
  .output_block_dec(output_block_dec),
  .block_ready_dec(block_ready_dec),
  .next_bolck_dec(next_bolck_dec)

  );

assign key_enc = key;
assign key_dec = key;


initial begin
  aclk                         = 0;
  forever begin      
    #(HALF_CLK)   aclk       = ~aclk;
  end
end

initial begin

  aresetn = 1'b0;
  /*key_init_enc = 1'b0;
  key_init_dec = 1'b0;*/
  @(negedge aclk);
  aresetn = 1'b1;
  #100

  block [0] <= 128'h6bc1bee22e409f96e93d7e117393172a; 
  block [1] <= 128'hae2d8a571e03ac9c9eb76fac45af8e51;
  block [2] <= 128'h30c81c46a35ce411e5fbc1191a0a52ef;
  block [3] <= 128'hf69f2445df4f9b17ad2b417be66c3710;

  /*expected0 = 128'h3ad77bb40d7a3660a89ecaf32466ef97;
  expected1 = 128'hf5d3d58503b9699de785895a96fdbaaf;
  expected2 = 128'h43b1cd7f598ece23881b00e3ed030688;
  expected3 = 128'h7b0c785e27e8ad3f8223207104725dd4;*/



   /* key      = 128'h2b7e151628aed2a6abf7158809cf4f3c;//128'h000102030405060708090a0b0c0d0e0f;
    key_init_enc = 1'b1;
    key_init_dec = 1'b1;
    wait(key_ready_enc);
    key_init_enc = 1'b0;
    wait(key_ready_dec);
    key_init_dec = 1'b0;
    input_block_enc = 128'h6bc1bee22e409f96e93d7e117393172a;//128'h00112233445566778899aabbccddeeff;//plain text 0
    input_block_dec = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;//cipher text 0
    next_bolck_enc = 1'b1;
    next_bolck_dec = 1'b1;
    wait(block_ready_enc);
    next_bolck_enc =1'b0;
    wait(block_ready_dec);
    next_bolck_dec =1'b0;*/
    

    end // initial

    always @(posedge aclk) begin
      if(!aresetn) begin
        cnt <= 1'b0;
        state <= STATE_IDLE;
      end else begin
        case (state)
          STATE_IDLE :
            begin
              cnt <= 3'b0;
              key_init_enc = 1'b0;
              if(!key_ready_enc) begin
                state <= STATE_INIT;
              end
            end
          STATE_INIT :
            begin
              key      <= 128'h2b7e151628aed2a6abf7158809cf4f3c;//h000102030405060708090a0b0c0d0e0f;
              key_init_enc <= 1'b1;
              state <= STATE_BLOCK;
            end
          STATE_BLOCK :
            begin
              key_init_enc <= 1'b0;
              if (key_ready_enc && cnt != 3'd4) begin
                state <= STATE_BLOCK_NEXT;
              end else if ((key_ready_enc && cnt == 3'd4)) begin
                state <= STATE_DONE;
              end
            end
          STATE_BLOCK_NEXT :
            begin
              next_bolck_enc = 1'b1;
              input_block_enc <= block[cnt];
              cnt <= cnt + 1'b1;
              /*next_bolck_enc <= 1'b0;
              cnt <= cnt + 1'b1;
              if (cnt == 3) begin
                state <= STATE_DONE;
              end else begin
                state <= STATE_BLOCK;
              end*/
              state <= STATE_BLOCK_NEXT_1;
            end
          STATE_BLOCK_NEXT_1 :
            begin
              next_bolck_enc <= 1'b0;
              if (block_ready_enc ) begin
                state <= STATE_BLOCK;
              end
            end
          STATE_DONE :
            begin
              state <= STATE_IDLE;
            end
          default : ;
        endcase


      end
    end

endmodule //aes_key_gen_tb

//128'h000102030405060708090a0b0c0d0e0f;//
//128'h00112233445566778899aabbccddeeff;//

 /*An example AES test value (from FIPS-197) is:

Key:        000102030405060708090a0b0c0d0e0f
Plaintext:  00112233445566778899aabbccddeeff
Ciphertext: 69c4e0d86a7b0430d8cdb78070b4c55a

Encrypting the plaintext with the key should give the ciphertext, decrypting the ciphertext with the key should give the plaintext.

The Trace produced looks like (at level 2):

setKey(000102030405060708090a0b0c0d0e0f)
encryptAES(00112233445566778899aabbccddeeff)
  R0 (Key = 000102030405060708090a0b0c0d0e0f)  = 00102030405060708090a0b0c0d0e0f0
  R1 (Key = d6aa74fdd2af72fadaa678f1d6ab76fe)  = 89d810e8855ace682d1843d8cb128fe4
  R2 (Key = b692cf0b643dbdf1be9bc5006830b3fe)  = 4915598f55e5d7a0daca94fa1f0a63f7
  R3 (Key = b6ff744ed2c2c9bf6c590cbf0469bf41)  = fa636a2825b339c940668a3157244d17
  R4 (Key = 47f7f7bc95353e03f96c32bcfd058dfd)  = 247240236966b3fa6ed2753288425b6c
  R5 (Key = 3caaa3e8a99f9deb50f3af57adf622aa)  = c81677bc9b7ac93b25027992b0261996
  R6 (Key = 5e390f7df7a69296a7553dc10aa31f6b)  = c62fe109f75eedc3cc79395d84f9cf5d
  R7 (Key = 14f9701ae35fe28c440adf4d4ea9c026)  = d1876c0f79c4300ab45594add66ff41f
  R8 (Key = 47438735a41c65b9e016baf4aebf7ad2)  = fde3bad205e5d0d73547964ef1fe37f1
  R9 (Key = 549932d1f08557681093ed9cbe2c974e)  = bd6e7c3df2b5779e0b61216e8b10b689
  R10 (Key = 13111d7fe3944a17f307a78b4d2b30c5)   = 69c4e0d86a7b0430d8cdb78070b4c55a
 = 69c4e0d86a7b0430d8cdb78070b4c55a
*/