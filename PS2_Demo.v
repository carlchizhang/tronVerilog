
module PS2_Demo (
	// Inputs
	CLOCK_50,
	KEY,

	// Bidirectionals
	PS2_CLK,
	PS2_DAT,
	w,a,s,d,up,down,left,right,enter
	// Outputs
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/

// Inputs
input				CLOCK_50;
input		[3:0]	KEY;

// Bidirectionals
inout				PS2_CLK;
inout				PS2_DAT;

// Outputs

output w,a,s,d,up,down,left,right,enter;



assign w = (last_data_received==8'b00011101)?1:0;
assign a = (last_data_received==8'b00011100)?1:0;
assign s = (last_data_received==8'b00011011)?1:0;
assign d = (last_data_received==8'b00100011)?1:0;
assign up = (last_data_received==8'b01110101)?1:0;
assign down = (last_data_received==8'b01110010)?1:0;
assign right = (last_data_received==8'b01110100)?1:0;
assign left = (last_data_received==8'b01101011)?1:0;
assign enter = (last_data_received==8'b01011010)?1:0;



/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/

// Internal Wires
wire		[7:0]	ps2_key_data;
wire				ps2_key_pressed;

// Internal Registers
reg			[7:0]	last_data_received;
integer i;
// State Machine Registers

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

always @(posedge CLOCK_50)
begin
	if (KEY[0] == 1'b0)
		last_data_received <= 8'h00;
	else if (ps2_key_pressed == 1'b1)
		last_data_received <= ps2_key_data;

end

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/



/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

PS2_Controller PS2 (
	// Inputs
	.CLOCK_50				(CLOCK_50),
	.reset				(~KEY[0]),

	// Bidirectionals
	.PS2_CLK			(PS2_CLK),
 	.PS2_DAT			(PS2_DAT),

	// Outputs
	.received_data		(ps2_key_data),
	.received_data_en	(ps2_key_pressed)
);


endmodule
