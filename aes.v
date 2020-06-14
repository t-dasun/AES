`timescale 1ns / 1ps

module aes (
	input aclk,    // Clock
	input aresetn,  // Asynchronous reset active low

	//encryption side
	input wire [127 : 0]  key_enc,
	input wire            key_init_enc,
  	output wire           key_ready_enc,

  	input wire [127 : 0]  input_block_enc,
	output reg [127 : 0]  output_block_enc,
	output reg            block_ready_enc

	//decryption side
	input wire [127 : 0]  key_dec,
	input wire            key_init_dec,
  	output wire           key_ready_dec,

  	input wire [127 : 0]  input_block_dec,
	output reg [127 : 0]  output_block_dec,
	output reg            block_ready_dec
);
//----------------------------------------------------------------
// Parameters.
//----------------------------------------------------------------

//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//--------------------------------------------------------------------------------------------------------------------- 

//----------------------------------------------------------------
// assignments for ports.
//----------------------------------------------------------------

//---------------------------------------------------------------------------------------------------------------------
// Implementation
//---------------------------------------------------------------------------------------------------------------------

aes_encryption 
#(
)aes_encryption_dut
	.aclk,    
	.aresetn,  
	.next,
	.keylen,
	.key,
	.key_init,
	.input_block,
	.output_block,
	.block_ready
);

//----------------------------------------------------------------
//functions and sub functions.

endmodule //aes