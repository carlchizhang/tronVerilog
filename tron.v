module tron (
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		  LEDR,
		  PS2_DAT,
		  PS2_CLK,
		  HEX5,
		  HEX4,
		  HEX1,
		  HEX0,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;
	inout PS2_DAT;
	inout PS2_CLK;
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	output [9:0] LEDR;
	output [0:6] HEX5;
	output [0:6] HEX4;
	output [0:6] HEX1;
	output [0:6] HEX0;
	
	wire resetn;
	assign resetn = KEY[0];
	wire [4:0] present;
	wire [4:0] move1;
	wire Enable1;
	wire Enable2;
	wire Enable3;
	wire reset833;
	wire [7:0] p1score;
	wire [7:0] p2score;
	wire [2:0] storedColour1;
	wire [2:0] storedColour2;
	
	wire [1:0]winner;
	wire clearObjects;
	wire printWinner;
	wire w,a,s,d,up,down,left,right,enter;
	wire backupQ;
	
	wire colWrite;
	wire colQ;
	wire [13:0]colAddress;
	
	wire colWriteClear;
	wire colDataInputClear;
	wire [13:0]colAddressClear;
	
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.

	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
	
	wire [2:0] colourClear;
	wire [7:0] xClear;
	wire [6:0] yClear;
	wire writeEnClear;
	
	assign LEDR[0] = colQ;
	assign LEDR[9:5] = present[4:0];
	
	wire [2:0] colourFinal;
	wire [7:0] xFinal;
	wire [6:0] yFinal;
	wire writeEnFinal;
	
	wire colWriteFinal;
	wire colDataInputFinal;
	wire [13:0]colAddressFinal;
	
	wire [9:0] winnerAddress;
	wire [2:0] colourWinner;
	wire [7:0] xWinner;
	wire [6:0] yWinner;
	wire writeEnWinner;
	
	wire [2:0] colourTemp;
	wire [7:0] xTemp;
	wire [6:0] yTemp;
	wire writeEnTemp;
	
	assign colourTemp = (printWinner)?colourWinner:colour;
	assign xTemp = (printWinner)?xWinner:x;
	assign yTemp = (printWinner)?yWinner:y;
	assign writeEnTemp = (printWinner)?writeEnWinner:writeEn;
	
	
	assign colourFinal = (clearObjects)?colourClear:colourTemp;
	assign xFinal = (clearObjects)?xClear:xTemp;
	assign yFinal = (clearObjects)?yClear:yTemp;
	assign writeEnFinal = (clearObjects)?writeEnClear:writeEnTemp;
	assign colWriteFinal = (clearObjects)?colWriteClear:colWrite;
	assign colDataInputFinal = (clearObjects)?colDataInputClear:1'b1;
	assign colAddressFinal = (clearObjects)?colAddressClear:colAddress;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colourFinal),
			.x(xFinal),
			.y(yFinal),
			.plot(writeEnFinal),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "tronInitialize.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.
		directionControl c1(Enable2, {up,down,left,right,w,s,a,d}, move1);
		controlPath p1(resetn, KEY[1], move1, Enable2, present, winner);
		dataPath p2(present, resetn, Enable2, writeEn, x, y, colour, colAddress, winner, colQ, colWrite, clearObjects, printWinner);
		delayCounter1 d1(CLOCK_50,reset833,Enable1);
		delayCounter2 d2(Enable1,resetn,Enable2);
		delayCounter3 d3(CLOCK_50,reset833,Enable3);
		resetCounter1 d4(CLOCK_50,resetn,reset833);
		collision col1(colAddressFinal, CLOCK_50, colDataInputFinal, colWriteFinal, colQ);
		collisionBackup col2(colAddressClear+1'b1,CLOCK_50,backupQ);
		drawWinner draw1(CLOCK_50, xWinner, yWinner, colourWinner, writeEnWinner, winnerAddress, storedColour1, storedColour2, winner);
		p1 player1win(
	winnerAddress,
	CLOCK_50,
	storedColour1);
		p2 player2win(
	winnerAddress,
	CLOCK_50,
	storedColour2);
		clearField clear1(CLOCK_50, xClear, yClear, colourClear, writeEnClear, colAddressClear, colDataInputClear,  colWriteClear, backupQ);
		PS2_Demo ps2(
	// Inputs
	CLOCK_50,
	KEY[3:0],

	// Bidirectionals
	PS2_CLK,
	PS2_DAT,
	// Outputs
	w,a,s,d,up,down,left,right,enter
);

	scoreCounter score12(CLOCK_50, winner[1], winner[0], p1score, p2score, KEY[2]);
	hexDecoder h1(p2score[7:4], HEX1);
	hexDecoder h0(p2score[3:0], HEX0);
	hexDecoder h5(p1score[7:4], HEX5);
	hexDecoder h4(p1score[3:0], HEX4);
endmodule

module directionControl(clock, switch, move);
	input clock;
	input [7:0]switch;
	output reg [4:0] move;
	
	parameter [4:0] moveUp1 = 5'b00001, moveDown1 = 5'b00010, moveLeft1 = 5'b00100, moveRight1 = 5'b01000,
		moveUp2 = 5'b00011, moveDown2 = 5'b00110, moveLeft2 = 5'b01100, moveRight2 = 5'b11000;
	
	always@(*)
	begin
		case(switch)
		8'b10000000: move = moveUp2;
		8'b01000000: move = moveDown2;
		8'b00100000: move = moveLeft2;
		8'b00010000: move = moveRight2;
		8'b00001000: move = moveUp1;
		8'b00000100: move = moveDown1;
		8'b00000010: move = moveLeft1;
		8'b00000001: move = moveRight1;
		8'b00000000: move = 5'b0;
		default: move = 5'b0;
		endcase
	end
endmodule

module controlPath(reset, play, move1, clock, present, winner);
	input reset, clock, play;
	input [4:0] move1;
	input [1:0] winner;
	
	output reg [4:0] present = startGame1;
	reg [4:0] next = startGame2;
	reg [4:0] player1 = right1;
	reg [4:0] player2 = left2;
	reg [15:0] resetCount = 16'b0;
	
	parameter [5:0] moveUp1 = 5'b00001, moveDown1 = 5'b00010, moveLeft1 = 5'b00100, moveRight1 = 5'b01000,
		moveUp2 = 5'b00011, moveDown2 = 5'b00110, moveLeft2 = 5'b01100, moveRight2 = 5'b11000;
	parameter [4:0] startGame1 = 5'b01111, startGame2 = 5'b00000, up1 = 5'b01110, down1 = 5'b01101, left1 = 5'b01011, right1 = 5'b00111, up2 = 5'b00001, down2 = 5'b00010
	, left2 = 5'b00100, right2 = 5'b01000, check1 = 5'b10000, check2 = 5'b10001, winCheck1 = 5'b11111, winCheck2 = 5'b11000, winnerFound = 5'b11110, 
		updateRam1 = 5'b10101, updateRam2 = 5'b11010;
	

	
	always@(*)
	begin
		
	
	if(play == 1'b0)
	begin
		present = startGame2;
	end
	
	else if(present == winnerFound)
		present = next;
	
	else if((move1 == moveUp1)&&(player1!=down1)&&(player1!=up1))
	begin
			present = up1;
	end
	
	else if((move1 == moveDown1)&&(player1!=up1)&&(player1!=down1))
	begin
			present = down1;
	end
	
	else if((move1 == moveLeft1)&&(player1!=right1)&&(player1!=left1))
	begin
			present = left1;
	end
	
	else if((move1 == moveRight1)&&(player1!=left1)&&(player1!=right1))
	begin
			present = right1;
	end
	
	else if((move1 == moveUp2)&&(player2!=down2)&&(player2!=up2))
	begin
			present = up2;
	end
	
	else if((move1 == moveDown2)&&(player2!=up2)&&(player2!=down2))
	begin
			present = down2;
	end
	
	else if((move1 == moveLeft2)&&(player2!=right2)&&(player2!=left2))
	begin
			present = left2;
	end
	
	else if((move1 == moveRight2)&&(player2!=left2)&&(player2!=right2))
	begin
			present = right2;
	end
	
	else
		present = next;
	end
	
	always@(posedge clock)
	begin
		case(present)
		
		startGame1: begin
		player1 = right1;
		player2 = left2;
			next = startGame2;
		end
		
		startGame2: begin
		player1 = right1;
		player2 = left2;
			next = startGame1;
		end
		
		down1: begin
			player1 = down1;
			next = check1;
		end
		
		left1: begin
			player1 = left1;
			next = check1;
		end
		
		up1: begin
			player1 = up1;
			next = check1;
		end
		
		
		right1: begin
			player1 = right1;
			next = check1;
		end
		
		down2: begin
			player2=down2;
			next = check2;
		end
		
		left2: begin
			player2=left2;
			next = check2;
		end
		
		up2: begin
			player2=up2;
			next = check2;
		end
		
		right2: begin
			player2=right2;
			next = check2;
		end
		
		check1: begin
			next = winCheck1;
		end
		
		check2: begin
			next = winCheck2;
		end
		
		winCheck1: begin
			if(winner == 2'b00)
				next = updateRam1;
			else
				next = winnerFound;
		end
		
		winCheck2: begin
			if(winner == 2'b00)
				next = updateRam2;
			else
				next = winnerFound;
		end
		
		updateRam1: begin
			next = player2;
		end
		
		updateRam2: begin
			next = player1;
		end
		
		winnerFound: begin
			next = winnerFound;
		end
		
		default: begin
			next = startGame1;
		end
		endcase	
	end
endmodule

module dataPath(present, reset, clock, writeEn1, xOut, yOut, colourOut, colAddress, winner, colStored, colWrite, clearObjects, printWinner);
	input clock, reset;
	input [4:0] present;
	input colStored;

	output reg [7:0]xOut;
	output reg [6:0]yOut;
	output reg [2:0]colourOut;
	output reg writeEn1;
	output [1:0]winner;
	output reg [13:0] colAddress;
	output reg colWrite;
	output reg clearObjects;
	output reg printWinner;
	
	
	reg winner2;
	reg winner1;
	reg colQ;
	reg [7:0]xOut1 = 8'b00101000;
	reg [6:0]yOut1 = 7'b0111100;
	reg [2:0]colourOut1 = 3'b001;
	
	reg [7:0]xOut2 = 8'b01010000;
	reg [6:0]yOut2 = 7'b0111100;
	reg [2:0]colourOut2 = 3'b100;
	assign winner = {winner2, winner1};
	
	parameter [4:0] startGame1 = 5'b01111, startGame2 = 5'b00000, up1 = 5'b01110, down1 = 5'b01101, left1 = 5'b01011, right1 = 5'b00111, up2 = 5'b00001, down2 = 5'b00010
	, left2 = 5'b00100, right2 = 5'b01000, check1 = 5'b10000, check2 = 5'b10001, winCheck1 = 5'b11111, winCheck2 = 5'b11000, winnerFound = 5'b11110,
	updateRam1 = 5'b10101, updateRam2 = 5'b11010;
	
	
	always@(posedge clock)
	begin
		case(present)
		
		startGame1:
			begin
			
			writeEn1 = 1'b0;
			colourOut1 = 3'b001;
			xOut1 = 8'b00101000+2'b10;
			yOut1 = 7'b0110111+2'b10;
			xOut = xOut1;
			yOut = yOut1;
			colourOut = colourOut1;
			winner2 = 1'b0;
			winner1 = 1'b0;
			colAddress = (yOut1 - 3'b011)*8'b01110010 + (xOut1 - 3'b011);
			clearObjects = 1'b1;
			printWinner = 1'b1;
			end
		startGame2:
			begin
			
			writeEn1 = 1'b0;
			colourOut2 = 3'b100;
			xOut2 = 8'b01010000+2'b10;
			yOut2 = 7'b0110111+2'b10;
			xOut = xOut2;
			yOut = yOut2;
			colourOut = colourOut2;
			winner2 = 1'b0;
			winner1 = 1'b0;
			colAddress = (yOut2 - 3'b011)*8'b01110010 + (xOut2 - 3'b011);
			clearObjects = 1'b1;
			printWinner = 1'b1;
			
			end
		right1:
			begin
			clearObjects = 1'b0;
			printWinner = 1'b0;
			colWrite = 0;
			colQ=0;
			xOut1 = xOut1 + 1'b1;
			xOut = xOut1;
			yOut = yOut1;
			colourOut = colourOut1;
			writeEn1 = 1'b1;
			colAddress = (yOut1 - 3'b011)*8'b01110010 + (xOut1 - 3'b011);
			
			end
		up1:
			begin
			clearObjects = 1'b0;
			printWinner = 1'b0;
			colWrite = 0;
			colQ=0;
			yOut1 = yOut1 - 1'b1;
			xOut = xOut1;
			yOut = yOut1;
			colourOut = colourOut1;
			writeEn1 = 1'b1;
			colAddress = (yOut1 - 3'b011)*8'b01110010 + (xOut1 - 3'b011);
			end
			
		left1:
			begin
			clearObjects = 1'b0;
			printWinner = 1'b0;
			colWrite = 0;
			colQ=0;
			xOut1 = xOut1 - 1'b1;
			xOut = xOut1;
			yOut = yOut1;
			colourOut = colourOut1;
			writeEn1 = 1'b1;
			colAddress = (yOut1 - 3'b011)*8'b01110010 + (xOut1 - 3'b011);
			end
		down1:
			begin
			clearObjects = 1'b0;
			printWinner = 1'b0;
			colWrite = 0;
			colQ=0;
			yOut1 = yOut1 + 1'b1;
			xOut = xOut1;
			yOut = yOut1;
			colourOut = colourOut1;
			writeEn1 = 1'b1;
			colAddress = (yOut1 - 3'b011)*8'b01110010 + (xOut1 - 3'b011);
			end
			
		right2:
			begin
			clearObjects = 1'b0;
			printWinner = 1'b0;
			colWrite = 0;
			colQ=0;
			xOut2 = xOut2 + 1'b1;
			xOut = xOut2;
			yOut = yOut2;
			colourOut = colourOut2;
			writeEn1 = 1'b1;
			colAddress = (yOut2 - 3'b011)*8'b01110010 + (xOut2 - 3'b011);
			end
		up2:
			begin
			clearObjects = 1'b0;
			printWinner = 1'b0;
			colWrite = 0;
			colQ=0;
			yOut2 = yOut2 - 1'b1;
			xOut = xOut2;
			yOut = yOut2;
			colourOut = colourOut2;
			writeEn1 = 1'b1;
			colAddress = (yOut2 - 3'b011)*8'b01110010 + (xOut2 - 3'b011);
			end
		left2:
			begin
			clearObjects = 1'b0;
			printWinner = 1'b0;
			colWrite = 0;
			colQ=0;
			xOut2 = xOut2 - 1'b1;
			xOut = xOut2;
			yOut = yOut2;
			colourOut = colourOut2;
			writeEn1 = 1'b1;
			colAddress = (yOut2 - 3'b011)*8'b01110010 + (xOut2 - 3'b011);
			end
		down2:
			begin
			clearObjects = 1'b0;
			printWinner = 1'b0;
			colWrite = 0;
			colQ=0;
			yOut2 = yOut2 + 1'b1;
			xOut = xOut2;
			yOut = yOut2;
			colourOut = colourOut2;
			writeEn1 = 1'b1;
			colAddress = (yOut2 - 3'b011)*8'b01110010 + (xOut2 - 3'b011);
			end
			
		check1: begin
			clearObjects = 1'b0;
			printWinner = 1'b0;
			colAddress = (yOut1 - 3'b011)*8'b01110010 + (xOut1 - 3'b011);
			colQ = colStored;
			if (colQ == 1)
				winner2 = 1'b1;
			else
				begin
				winner2 = 1'b0;
				winner1 = 1'b0;
				end
		end
		
		winCheck1: begin
		clearObjects = 1'b0;
		printWinner = 1'b0;
		end
		
		check2: begin
			clearObjects = 1'b0;
			printWinner = 1'b0;
			colAddress = (yOut2 - 3'b011)*8'b01110010 + (xOut2 - 3'b011);
			colQ = colStored;
			if (colQ == 1)
				winner1 = 1'b1;
			else
			begin
				winner2 = 1'b0;
				winner1 = 1'b0;
			end
		end
		
		winCheck2: begin
		clearObjects = 1'b0;
		printWinner = 1'b0;
			
		end
		
		winnerFound: begin
		clearObjects = 1'b0;
		xOut1 = 8'b00101000+2'b10;
		yOut1 = 7'b0110111+2'b10;
		xOut2 = 8'b01010000+2'b10;
		yOut2 = 7'b0110111+2'b10;
		printWinner = 1'b1;
		end
		
		updateRam1: begin
			clearObjects = 1'b0;
			printWinner = 1'b0;
			colAddress = (yOut1 - 3'b011)*8'b01110010 + (xOut1 - 3'b011);
			colWrite = 1;
		end
		
		updateRam2: begin
			clearObjects = 1'b0;
			printWinner = 1'b0;
			colAddress = (yOut2 - 3'b011)*8'b01110010 + (xOut2 - 3'b011);
			colWrite = 1;
		end
		
		default:
			begin
			clearObjects = 1'b0;
			printWinner = 1'b0;
			writeEn1 = 1'b0;
			xOut = xOut1;
			yOut = yOut1;
			colourOut = colourOut1;
			end
		endcase
	end
endmodule



module delayCounter2(clock,resetn,Enable);
	input clock;
	input resetn;
	reg [3:0] count;
	output Enable;
	always @(posedge clock)
	begin 
		if(resetn == 1'b0)
			count <= 0;//8333333;
		else 
		begin
			if(count >= 4'b0001)
				count <= 0;//8333333;
			else 
				count <= count + 1'b1;
		end
	end
	assign Enable = (count >= 4'b0001)?1:0;
endmodule

module delayCounter1(clock,resetn,Enable);
	input clock;
	input resetn;
	reg [22:0] count;
	output Enable;
	always @(posedge clock)
	begin 
		if(resetn == 1'b0)
			count <= 0;//8333333;
		else 
		begin
			if(count >= 23'b00001111110010100000010)
				count <= 0;//8333333;
			else 
				count <= count + 1'b1;
		end
	end
	assign Enable = (count >= 23'b00001111110010100000010)?1:0;
endmodule

module delayCounter3(clock,resetn,Enable);
	input clock;
	input resetn;
	reg [22:0] count;
	output Enable;
	always @(posedge clock)
	begin 
		if(resetn == 1'b0)
			count <= 0;//8333333;
		else 
		begin
			if(count >= 23'b00000000000011111100101)
				count <= 0;//8333333;
			else 
				count <= count + 1'b1;
		end
	end
	assign Enable = (count >= 23'b00000000000011111100101)?1:0;
endmodule


module resetCounter1(clock,resetn,Enable);
	input clock;
	input resetn;
	reg [24:0] count;
	output Enable;
	always @(posedge clock)
	begin 
		if(resetn == 1'b0)
			count <= 0;//8333333*4;
		else 
		begin
			if(count >= 25'b0111111100101000000101010)
				count <= 0;//8333333*4;
			else 
				count <= count + 1'b1;
		end
	end
	assign Enable = (count >= 25'b0111111100101000000101010)?0:1;
endmodule

module clearField(clock, xOut, yOut, colourOut, writeEn, addressOut, dataOut,  writeOut, backupQ);
	input clock;
	input backupQ;
	output reg [13:0]addressOut;
	
	output reg [7:0]xOut;
	output reg [6:0]yOut;
	output reg [2:0]colourOut;
	output writeEn;
	output dataOut;
	output writeOut;
	assign writeOut = 1'b1;
	assign writeEn = 1'b1;
	assign dataOut = backupQ;
	always@(posedge clock)
	begin
		addressOut <= addressOut + 1'b1;
		if (addressOut >= 14'b11001011000100)
		begin
			addressOut <= 0;
		end
		else if ((addressOut < 8'b01110011) || (addressOut >= 14'b11001001010001))
		begin
			xOut = (addressOut % 8'b01110010) + 2'b11;
			yOut = (addressOut / 8'b01110010) + 2'b11;
			colourOut = 3'b011;
		end
		
		else if (addressOut == 13'b1100000110011)
		begin
			xOut = (addressOut % 8'b01110010) + 2'b11;
			yOut = (addressOut / 8'b01110010) + 2'b11;
			colourOut = 3'b001;
		end
		
		else if (addressOut == 13'b1100001011011)
		begin
			xOut = (addressOut % 8'b01110010) + 2'b11;
			yOut = (addressOut / 8'b01110010) + 2'b11;
			colourOut = 3'b100;
		end
		
		else if(addressOut%114 == 0)
		begin
			xOut = (addressOut % 8'b01110010) + 2'b11;
			yOut = (addressOut / 8'b01110010) + 2'b11;
			colourOut = 3'b011;
		end
		
		else if((addressOut+1'b1)%114 == 0)
		begin
			xOut = (addressOut % 8'b01110010) + 2'b11;
			yOut = (addressOut / 8'b01110010) + 2'b11;
			colourOut = 3'b011;
		end
		
		else
		begin
			xOut = (addressOut % 8'b01110010) + 2'b11;
			yOut = (addressOut / 8'b01110010) + 2'b11;
			colourOut = 3'b000;
		end
	end
endmodule

module drawWinner(clock, xOut, yOut, colourOut, writeEn, addressOut, storedColour1, storedColour2, winner);
	input clock;
	input [1:0] winner;
	input [2:0] storedColour1;
	input [2:0] storedColour2;
	
	output writeEn;
	output reg [7:0] xOut;
	output reg [6:0] yOut;
	output reg [2:0]colourOut;
	output reg [9:0]addressOut;
	assign writeEn = 1'b1;
	always@(posedge clock)
	begin
		addressOut <= addressOut + 1;
		if(addressOut >= 10'b1001000000)
			addressOut <= 0;
		else
			begin
			xOut = (addressOut % 5'b11000) + 8'b10000000;
			yOut = (addressOut / 5'b11000) + 6'b111010;
			if(winner == 2'b01)
				colourOut = storedColour1;
			else if(winner == 2'b10)
				colourOut = storedColour2;
			else
				colourOut = 3'b000;
			end
	end
endmodule

module scoreCounter(clock, winner2, winner1, p1score, p2score, resetScore);
	input winner2;
	input winner1;
	input resetScore;
	input clock;
	output reg [7:0] p1score;
	output reg [7:0] p2score;

	always @(posedge winner2 or posedge winner1 or negedge resetScore)
	begin
		
		
		if(resetScore == 1'b0)
		begin
			p1score = 8'b0;
			p2score = 8'b0;
		end
			
		else if(winner1 == 1'b1)
			p1score = p1score + 1;
			
		else if(winner2 == 1'b1)
			p2score = p2score + 1;
			
		else 
		begin
			p1score = p1score;
			p2score = p2score;
		end
			
	end
endmodule

module hexDecoder (switch, HEX);
	input [3:0]switch;
	output reg[0:6]HEX;
	always@(*)
		case(switch[3:0])
		0:HEX=7'b0000001;
		1:HEX=7'b1001111;
		2:HEX=7'b0010010;
		3:HEX=7'b0000110;
		4:HEX=7'b1001100;
		5:HEX=7'b0100100;
		6:HEX=7'b0100000;
		7:HEX=7'b0001111;
		8:HEX=7'b0000000;
		9:HEX=7'b0001100;
		10:HEX=7'b0001000;
		11:HEX=7'b1100000;
		12:HEX=7'b0110001;
		13:HEX=7'b1000010;
		14:HEX=7'b0110000;
		15:HEX=7'b0111000;
	endcase
endmodule
	