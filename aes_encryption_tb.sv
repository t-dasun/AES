`timescale 1ns / 1ps

module aes_encryption_tb ();
  localparam      CLK                 = 4;
    localparam      HALF_CLK            = CLK/2;

  reg           aclk;
  reg           aresetn;

  reg           next;
  reg           keylen;
  reg [127 : 0] key;
  reg           key_init;
  reg           key_ready;
  reg [127 : 0] input_block;
  reg [127 : 0] output_block;
  reg           block_ready;
  integer c;

  aes_decryption 
  #(
  ) 
  aes_decryption_dut 
  (
  .aclk(aclk),    
  .aresetn(aresetn),  
  .next(next),
  .keylen(keylen),
  .key(key),
  .key_init(key_init),
  .key_ready(key_ready),
  .input_block(input_block),
  .output_block(output_block),
  .block_ready(block_ready)
);
  


    initial begin
        aclk                         = 0;
        forever begin      
            #(HALF_CLK)   aclk       = ~aclk;
        end
    end

    initial begin

  aresetn = 1'b0;
  key_init = 1'b0;
    @(negedge aclk);
    aresetn = 1'b1;
    #100
    key      = 128'h000102030405060708090a0b0c0d0e0f;//128'h2b7e151628aed2a6abf7158809cf4f3c;//128'b0;//{15'b0,1'b1,112'b0}; 
    keylen   = 1'b1; 
    key_init = 1'b1;
    #10
    //next     = 1'b1;
    key_init = 1'b0;
    input_block = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;//128'h6bc1bee22e409f96e93d7e117393172a;
    #10
    next     = 1'b0; 
    c=1'b1;

    end // initial

    always @(posedge aclk) begin
      if(!aresetn) begin
        
      end else begin
        /*if (key_ready) begin
          for (int i = 0; i < 10; i=i+1) begin
            round     <= i;
            #10;
          $display("TEST PASSE,expected %h,result %d",round_key,i+1);
          end
        end*/
        if (key_ready && c) begin
          next     <= 1'b1;
          c        <=1'b0;
        end else begin
          next     <= 1'b0;
        end
        /*if (block_ready) begin
          $display("result %d",output_block);
        end*/
        
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