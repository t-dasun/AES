`timescale 1ns / 1ps

module aes (
	input aclk,    // Clock
	input aresetn,  // Asynchronous reset active low

	//encryption side
	input wire [127 : 0]  key_enc,          //for 1st block , when key ready input next block and high next
	input wire            key_init_enc,		// then when last block is ready input next 
	output wire           key_ready_enc,

	input wire [127 : 0]  input_block_enc,
	output wire [127 : 0] output_block_enc,
	output wire           block_ready_enc,

	input wire 			  next_bolck_enc,

	//decryption side
	input wire [127 : 0]  key_dec,
	input wire            key_init_dec,
	output wire           key_ready_dec,

	input wire [127 : 0]  input_block_dec,
	output wire [127 : 0] output_block_dec,
	output wire           block_ready_dec,

	input wire 			  next_bolck_dec
	);
//----------------------------------------------------------------
// Parameters.
//----------------------------------------------------------------

//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//--------------------------------------------------------------------------------------------------------------------- 
wire keylen;

//----------------------------------------------------------------
// assignments for ports.
//----------------------------------------------------------------
assign keylen = 1'b0;
//---------------------------------------------------------------------------------------------------------------------
// Implementation
//---------------------------------------------------------------------------------------------------------------------

aes_encryption 
#(
	)aes_encryption_dut
(
	.aclk(aclk),    
	.aresetn(aresetn),  
	.next(next_bolck_enc),
	.keylen(keylen),
	.key(key_enc),
	.key_init(key_init_enc),
	.key_ready(key_ready_enc),
	.input_block(input_block_enc),
	.output_block(output_block_enc),
	.block_ready(block_ready_enc)
	);

aes_decryption 
#(
	)aes_decryption_dut
(
	.aclk(aclk),    
	.aresetn(aresetn),  
	.next(next_bolck_dec),
	.keylen(keylen),
	.key(key_dec),
	.key_init(key_init_dec),
	.key_ready(key_ready_dec),
	.input_block(input_block_dec),
	.output_block(output_block_dec),
	.block_ready(block_ready_dec)
	);


//----------------------------------------------------------------
//functions and sub functions.

endmodule //aes