`timescale 1ns / 1ps

module aes_key_gen_tb ();
	localparam      CLK                 = 4;
    localparam      HALF_CLK            = CLK/2;

	reg 		aclk;
    reg         aresetn;


	reg [127:0] 	key;     
	reg     		keylen ;  
	reg 		 	key_init; 
	reg [ 3 :0] 	round ;   
	reg [127:0]		round_key;
	reg 			key_ready;
	reg [31 :0]     sbox_feed;
	reg [31 :0]     new_sbox ;

    aes_key_gen 
    #(
    )
    aes_key_gen_dut
    (
    .aclk     (aclk     ),
	.aresetn  (aresetn  ),
	.key      (key     ),                       
	.keylen   (keylen   ),
	.key_init (key_init ),
	.round    (round    ),
	.round_key(round_key),
	.key_ready(key_ready),
	.sbox_feed(sbox_feed),
	.new_sbox (new_sbox )
 
	);

	sbox
	#(
	)sbox_dut
	(
	.sboxw (sbox_feed),
	.new_sboxw (new_sbox)
	);

    initial begin
        aclk                         = 0;
        forever begin      
            #(HALF_CLK)   aclk       = ~aclk;
        end
    end

    initial begin

	aresetn = 1'b0;

    @(negedge aclk);
    aresetn = 1'b1;

    key      = 128'hffffffffffffffffffffffffffffffff;//128'b0;//{15'b0,1'b1,112'b0}; 
	keylen   = 1'b1; 
	key_init = 1'b1;
	#100
	key_init = 1'b0;


    end // initial

    always @(posedge aclk) begin
    	if(!aresetn) begin
    		
    	end else begin
    		if (key_ready) begin
    			for (int i = 0; i < 10; i=i+1) begin
	    			round     <= i;
	    			#10;
					$display("TEST PASSE,expected %h,result %d",round_key,i+1);
    			end
    		end
    		
    		
    	end
    end

endmodule //aes_key_gen_tb