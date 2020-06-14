`timescale 1ns / 1ps

module aes_key_gen (
	input aclk,    // Clock
	input aresetn,  // Asynchronous reset active low

	input wire [127 : 0]  key,
    input wire            keylen,
    input wire            key_init,
 
    input wire    [3 : 0] round,
    output  reg [127 : 0] round_key,
    output  reg           key_ready,
 
 
    output  reg [31 : 0]  sbox_feed,
    input wire  [31 : 0]  new_sbox
 
);
//----------------------------------------------------------------
// Parameters.
//----------------------------------------------------------------

localparam STATE_IDLE        	= 3'd0;   
localparam STATE_INIT        	= 3'd1;   
localparam STATE_KEYGEN      	= 3'd2; 
localparam STATE_KEYGEN_MID     = 3'd3;
localparam STATE_KEYGEN_MID_1   = 3'd4;
localparam STATE_KEYGEN_ROUND	= 3'd5;  
localparam STATE_DONE        	= 3'd6; 
localparam STATE_KEYGEN_ROUND_1 = 3'd7;

localparam AES_128_NUM_ROUNDS 	= 4'd10;

//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//--------------------------------------------------------------------------------------------------------------------- 
 reg [127 : 0] key_mem   [0 : 14];
 reg [127 : 0] temp_key;
 reg [ 3  : 0] round_counter;

 reg [ 2  : 0] state;

 reg [ 31 : 0] w0, w1, w2, w3;
 reg [ 31 : 0] k0, k1, k2, k3;
 reg [ 31 : 0] g_transfered;
 reg [ 7  : 0] temp_RCi;
 reg [ 31 : 0] RC_i; 
 reg [ 7  : 0] RC_i7;
 reg [ 31 : 0] temp; 

//----------------------------------------------------------------
// assignments for ports.
//----------------------------------------------------------------
 
//---------------------------------------------------------------------------------------------------------------------
// Implementation
//---------------------------------------------------------------------------------------------------------------------

always @*
begin : key_mem_take
  round_key = key_mem[round];
end // key_mem_read

//FSM
always @(posedge aclk ) 
begin 
	if(!aresetn) begin
		state <= STATE_IDLE;
	end else begin
		case (state)
			STATE_IDLE			:
				begin
					if (key_init) begin
						state <= STATE_INIT;
					end
				end
			STATE_INIT			:
				begin
					state <= STATE_KEYGEN;
				end
			STATE_KEYGEN 		:
				begin
					state <= STATE_KEYGEN_MID;
				end
			STATE_KEYGEN_MID	:
				begin
					state <= STATE_KEYGEN_MID_1;
				end
			STATE_KEYGEN_MID_1  :
				begin
					state <= STATE_KEYGEN_ROUND;
				end
			STATE_KEYGEN_ROUND  :
				begin
					state <= STATE_KEYGEN_ROUND_1;
				end
			STATE_KEYGEN_ROUND_1:
				begin
					if (round_counter == AES_128_NUM_ROUNDS) begin
						state <= STATE_DONE;
					end else begin
						state <= STATE_KEYGEN;
					end
				end
			STATE_DONE			:
				begin
					state <= STATE_IDLE;
				end
			default : /* default */;
		endcase
	end
end

//key generation
always @(posedge aclk ) 
begin 
	if(!aresetn) begin
		w0 		 <= 32'd0; 
		w1 		 <= 32'd0;
		w2 		 <= 32'd0;
		w3 		 <= 32'd0;
		k0 		 <= 32'd0; 
		k1 		 <= 32'd0;
		k2 		 <= 32'd0;
		k3 		 <= 32'd0;
		temp_key <= 128'd0;

		RC_i 		 <= 32'd0;  
		RC_i7 		 <=  7'd0;  
		sbox_feed    <= 32'd0;
		g_transfered <= 32'd0; 
		temp 		 <= 32'd0;  
		temp_RCi     <=  7'd0; 
	end else begin
		case (state)
			STATE_IDLE			:
				begin
					w0 		 <= 32'd0; 
					w1 		 <= 32'd0;
					w2 		 <= 32'd0;
					w3 		 <= 32'd0;
					k0 		 <= 32'd0; 
					k1 		 <= 32'd0;
					k2 		 <= 32'd0;
					k3 		 <= 32'd0;
					temp_key <= 128'd0;
				end
			STATE_INIT			:
				begin
					temp_key <= key;
					RC_i7	 <= 8'h8d;//10001101
				end
			STATE_KEYGEN 		:
				begin
					$display("TEST PASSE,expected %h,result %d",temp_key,round_counter);
					key_mem [round_counter] <= temp_key;
					w0 <= temp_key [127 : 096];
					w1 <= temp_key [095 : 064];
					w2 <= temp_key [063 : 032];
					w3 <= temp_key [031 : 000];

					sbox_feed    <= temp_key [031 : 000];

					temp_RCi <= {RC_i7[6 : 0], 1'b0} ^ (8'h1b & {8{RC_i7[7]}});//00011011
				end
			STATE_KEYGEN_MID	:
				begin
					RC_i 		 <= {temp_RCi, 24'h0};
					RC_i7 		 <= temp_RCi;
				    g_transfered <= {new_sbox[23 : 00], new_sbox[31 : 24]};
				    
				end
			STATE_KEYGEN_MID_1	:
				begin
					temp 		 <= g_transfered ^ RC_i;
				end
			STATE_KEYGEN_ROUND	:
				begin
					k0 <= w0^temp; 
					k1 <= w1^w0^temp;
					k2 <= w2^w1^w0^temp;
					k3 <= w3^w2^w1^w0^temp;					
					
				end
			STATE_KEYGEN_ROUND_1:
				begin
					temp_key <= {k0, k1, k2, k3};
				end
			STATE_DONE			:
				begin
					key_mem [round_counter] <= temp_key;
					$display("TEST expected %h,temp key %h",key_mem[10],temp_key);
				end
			default : /* default */;
		endcase
	end
end

//round counter
always @(posedge aclk ) 
begin 
	if(!aresetn) begin
		round_counter <= 4'd0;
	end else begin
		case (state)

			STATE_KEYGEN_MID 		:
				begin
					round_counter <= round_counter + 1'b1;
				end
			
		endcase
	end
end

//ready key
always @(posedge aclk ) 
begin 
	if(!aresetn) begin
		key_ready <= 1'b0;
	end else begin
		case (state)
			STATE_INIT			:
				begin
					key_ready <= 1'b0;
				end
			
			STATE_DONE			:
				begin
					key_ready <= 1'b1;
				end
			default : /* default */;
		endcase
	end
end

endmodule //aes_key_gen

