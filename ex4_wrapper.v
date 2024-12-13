/* Note this is a skeleton that does not have everything implemented.  It is
* a guide for you, but you do not have to follow it.  Feel free to change
* things, and focus on getting the design working.
*
* When I solved this problem, I did the following:
* 1. Implement C FSM with steps ... 26 States for Me - TEST
* 2. Implement the Memory Mux for all the signals - TEST
* 3. Instantiate the simple functions like random and abs - TEST
* 4. Instantiate the memory functions (they have similarities) - TEST
* 5. TEST
* */

module ex4_wrapper(
  	//////////// ADC //////////
	//output		          		ADC_CONVST,
	//output		          		ADC_DIN,
	//input 		          		ADC_DOUT,
	//output		          		ADC_SCLK,

	//////////// Audio //////////
	input 		          		AUD_ADCDAT,
	inout 		          		AUD_ADCLRCK,
	inout 		          		AUD_BCLK,
	output		          		AUD_DACDAT,
	inout 		          		AUD_DACLRCK,
	output		          		AUD_XCK,

	//////////// CLOCK //////////
	//input 		          		CLOCK2_50,
	//input 		          		CLOCK3_50,
	//input 		          		CLOCK4_50,
	input 		          		CLOCK_50,

	//////////// SDRAM //////////
	//output		    [12:0]		DRAM_ADDR,
	//output		     [1:0]		DRAM_BA,
	//output		          		DRAM_CAS_N,
	//output		          		DRAM_CKE,
	//output		          		DRAM_CLK,
	//output		          		DRAM_CS_N,
	//inout 		    [15:0]		DRAM_DQ,
	//output		          		DRAM_LDQM,
	//output		          		DRAM_RAS_N,
	//output		          		DRAM_UDQM,
	//output		          		DRAM_WE_N,

	//////////// I2C for Audio and Video-In //////////
	output		          		FPGA_I2C_SCLK,
	inout 		          		FPGA_I2C_SDAT,

	//////////// SEG7 //////////
	output		     [6:0]		HEX0,
	output		     [6:0]		HEX1,
	output		     [6:0]		HEX2,
	output		     [6:0]		HEX3,
	output		     [6:0]		HEX4,
	output		     [6:0]		HEX5,

	//////////// IR //////////
	//input 		          		IRDA_RXD,
	//output		          		IRDA_TXD,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// PS2 //////////
	//inout 		          		PS2_CLK,
	//inout 		          		PS2_CLK2,
	//inout 		          		PS2_DAT,
	//inout 		          		PS2_DAT2,


	//////////// Video-In //////////
	//input 		          		TD_CLK27,
	//input 		     [7:0]		TD_DATA,
	//input 		          		TD_HS,
	//output		          		TD_RESET_N,
	//input 		          		TD_VS,

	//////////// VGA //////////
	//output		          		VGA_BLANK_N,
	//output		     [7:0]		VGA_B,
	//output		          		VGA_CLK,
	//output		     [7:0]		VGA_G,
	//output		          		VGA_HS,
	//output		     [7:0]		VGA_R,
	//output		          		VGA_SYNC_N,
	//output		          		VGA_VS,

	//////////// GPIO_0, GPIO_0 connect to GPIO Default //////////
	//inout 		    [35:0]		GPIO_0,

	//////////// GPIO_1, GPIO_1 connect to GPIO Default //////////
	//inout 		    [35:0]		GPIO_1

	//////////// SW //////////
	input 		     [9:0]		SW
);

wire clk;
assign clk = CLOCK_50;
wire rst;
assign rst = KEY[0];
assign LEDR[7:0] = mem_V_S;
assign LEDR[8] = system_s_select_mem_path[0];
assign LEDR[9] = done;

reg [15:0]value_2_hex;
reg [6:0]memory_read_address;

// See various items out to the hex display - these are your numbers converted to decimals
fivedigit_decimal_twos_diplay display(
value_2_hex,
HEX5,
HEX4,
HEX3,
HEX2,
HEX1,
HEX0);

/*****************************************************************************
 *                 This the control for the system
 * 1) It is an FSM that runs your system if you press KEY[1] it starts to run, the second press of KEY[1] reads in1 from the switches, the third press of KEY[1] reads in2 and runs the code showing the output1 when done
 * 2) It reads a memory address based on SW[6:0] if you press KEY[2]
 * 3) It shows the algorithmic_ticks, and variables at the end of run (you have tracked) if you press KEY[3] and it cycles through them
 *
 * Don't change any of this code!!!
 *****************************************************************************/

reg [7:0] mem_V_S;
reg [7:0] mem_V_NS;

parameter 
			SYSTEM_S_START 					= 8'd0,
			SYSTEM_S_WAIT 					= 8'd1,
			
			SYSTEM_S_RUN_SYSTEM 			= 8'h10,
			SYSTEM_S_GET_IN1_WAIT			= 8'h12,
			SYSTEM_S_GET_IN1				= 8'h13,
			SYSTEM_S_GET_IN2_WAIT			= 8'h14,
			SYSTEM_S_GET_IN2				= 8'h15,
			SYSTEM_S_RUN_START				= 8'h16,
			SYSTEM_S_WAIT_RUN_DONE			= 8'h17,
			
			SYSTEM_S_READ_MEM				= 8'h20,
			SYSTEM_S_READ_MEM_DELAY			= 8'h21,
			SYSTEM_S_READ_SETUP_READ		= 8'h22,
			SYSTEM_S_READ_MEM_DISPLAY		= 8'h23,
			
			SYSTEM_S_SHOW_CLOCKS			= 8'h30,
			SYSTEM_S_SHOW_CLOCKS_DO			= 8'h31,
			
			SYSTEM_S_ERROR					= 8'hFF;


/* Flip flops for S and NS with the reset state */
always @(posedge clk or negedge rst)
begin
    if (rst == 1'b0)
        mem_V_S <= SYSTEM_S_START;
    else
        mem_V_S <= mem_V_NS;
end

/* Combinational always that describes the state transitions */
always @(*)
begin
    case (mem_V_S)
			SYSTEM_S_START: mem_V_NS = SYSTEM_S_WAIT;
			SYSTEM_S_WAIT: 	
										if (KEY[1] == 1'b0)
											mem_V_NS = SYSTEM_S_RUN_SYSTEM;
										else if (KEY[2] == 1'b0)
											mem_V_NS = SYSTEM_S_READ_MEM;
										else if (KEY[3] == 1'b0)
											mem_V_NS = SYSTEM_S_SHOW_CLOCKS;
										else
											mem_V_NS = SYSTEM_S_WAIT;
			/* RUN your system */
			SYSTEM_S_RUN_SYSTEM: 
										if (KEY[1] == 1'b1)
											mem_V_NS = SYSTEM_S_GET_IN1_WAIT;
										else
											mem_V_NS = SYSTEM_S_RUN_SYSTEM;
			SYSTEM_S_GET_IN1_WAIT:		
										if (KEY[1] == 1'b0)
											mem_V_NS = SYSTEM_S_GET_IN1;
										else
											mem_V_NS = SYSTEM_S_GET_IN1_WAIT;
			SYSTEM_S_GET_IN1:
										if (KEY[1] == 1'b1)
											mem_V_NS = SYSTEM_S_GET_IN2_WAIT;
										else
											mem_V_NS = SYSTEM_S_GET_IN1;
			SYSTEM_S_GET_IN2_WAIT:
										if (KEY[1] == 1'b0)
											mem_V_NS = SYSTEM_S_GET_IN2;
										else
											mem_V_NS = SYSTEM_S_GET_IN2_WAIT;
			SYSTEM_S_GET_IN2: 
										if (KEY[1] == 1'b1)
											mem_V_NS = SYSTEM_S_RUN_START;
										else
											mem_V_NS = SYSTEM_S_GET_IN2;
			SYSTEM_S_RUN_START: mem_V_NS = SYSTEM_S_WAIT_RUN_DONE;
			SYSTEM_S_WAIT_RUN_DONE:
										if (done == 1'b1)
											mem_V_NS = SYSTEM_S_WAIT;
										else
											mem_V_NS = SYSTEM_S_WAIT_RUN_DONE;
											
			/* display a memory address to HEX */
			SYSTEM_S_READ_MEM: 
										if (KEY[2] == 1'b1)
											mem_V_NS = SYSTEM_S_READ_SETUP_READ;
										else
											mem_V_NS = SYSTEM_S_READ_MEM;
			SYSTEM_S_READ_SETUP_READ: mem_V_NS = SYSTEM_S_READ_MEM_DELAY;
			SYSTEM_S_READ_MEM_DELAY: mem_V_NS = SYSTEM_S_READ_MEM_DISPLAY;
			SYSTEM_S_READ_MEM_DISPLAY: mem_V_NS = SYSTEM_S_WAIT;
		  
			/* Show clocks to run algroithm */
			SYSTEM_S_SHOW_CLOCKS: 
										if (KEY[3] == 1'b1)
											mem_V_NS = SYSTEM_S_SHOW_CLOCKS_DO;
										else
											mem_V_NS = SYSTEM_S_SHOW_CLOCKS;
			SYSTEM_S_SHOW_CLOCKS_DO: mem_V_NS = SYSTEM_S_WAIT;
		  
			
			default: mem_V_NS = SYSTEM_S_ERROR;
         
    endcase
end

/* Sequential deal with outputs */
always @(posedge clk or negedge rst) begin
    if (rst == 1'b0) 
	 begin
        value_2_hex <= 16'd0;
		  start <= 1'b0;
		  memory_read_address <= 7'd0;
		  system_s_select_mem_path <= 2'd0;
    end
    else 
	 begin
		case (mem_V_S)
				SYSTEM_S_START:
				SYSTEM_S_WAIT: 
												begin
													start <= 1'b0;
													value_2_hex <= 16'd0;
													memory_read_address <= 7'd0;
													system_s_select_mem_path <= 2'd0;
												end
				/* RUN your system */
				SYSTEM_S_GET_IN1: begin
					in1 <= {{22{SW[9]}}, SW[9:0]};
				end
				SYSTEM_S_GET_IN2_WAIT: begin
					value_2_hex <= in1;
				end
				
				SYSTEM_S_GET_IN2: begin
					in2 <= {{22{SW[9]}}, SW[9:0]};
				end
				SYSTEM_S_RUN_START: 		
												begin
													value_2_hex <= in2;
													start <= 1'b1;
													system_s_select_mem_path <= 2'd1;
												end
				SYSTEM_S_WAIT_RUN_DONE: 		begin
													start <= 1'b0;
													if (done == 1'b1)
														value_2_hex <= output1;
												end
																
				/* display a memory address to HEX */
				SYSTEM_S_READ_SETUP_READ: memory_read_address <= SW[6:0]; 
				SYSTEM_S_READ_MEM_DISPLAY: value_2_hex <= mux_q; // Read the data from SW[6:0] to the HEX decimal viewer
			  
				/* Show clocks to run algroithm */
				SYSTEM_S_SHOW_CLOCKS_DO: value_2_hex <= algorithm_ticks;
		 endcase
    end
end

/*****************************************************************************
 *                 This is your instatiated memory base working
 * Don't change anything except the instantiation name to match up with 
 * You IP generated memory.  We also make the width big to handle the range
 * of memories that people will be given.  
 * 
 * Again, you should only change the "memory" word to your IP named specific
 * memory.
 *****************************************************************************/

/* MEMORY MUXING - this allows different signals to the memory for your code vs. the display out */
reg [35:0] mux_address;
reg [35:0] mux_in;
reg mux_wren;
wire [35:0] mux_q;

/* instantiate memory Created with IP - NOTE you need to pick the correct module name "memory" is generic */
//memory my_memory(
/* instanctiate memory Created with IP - XXX and YY need to be changed to yours */
mem_MXXX_NYY my_memory(
    .address(mux_address),
    .clock(clk),
    .data(mux_in),
    .wren(mux_wren),
    .q(mux_q)
);

reg [1:0] system_s_select_mem_path;
/* Combinational always that describes the different memory paths */
always @(*)
begin
    case (system_s_select_mem_path)
        3'd0:
				/* select the display path */
            begin
                mux_address = memory_read_address[6:0];
                mux_in = 36'd0;
                mux_wren = 1'b0; // no writing just reading
            end
			3'd1:
				/* select path based on your code running */
				begin
                mux_address = memory_run_code_address[6:0];
                mux_in = memory_run_code_data_in;
                mux_wren = memory_run_code_data_wren;
            end
        default:
            begin
                mux_address = 8'd0;
                mux_in = 36'd0;
                mux_wren = 1'b0;
            end
    endcase
end

/*****************************************************************************
 * This is some skeleton stuff for your algorithm implementation
 * Note that some signals are marked to not change, but otherwise you can
 * implement what you need here to implement the hardware of your C code
 *****************************************************************************/

/* THIS is a MUX for you to control how to hookup your memory signals to the above instantiated memory.  
Note that from your codes perspective you should attach to the memory_run_code_ named signals as they 
are controlled above into your instantiated memory.  Don't change much other than which signals go
to memory_run_code_ signals for different modules you might run. */
/* FSM for memory path selection */
reg [2:0]select_mem_path;

reg [35:0]memory_run_code_address;
reg [35:0]memory_run_code_data_in;
reg memory_run_code_data_wren;

/* PETER WILL COPY FROM HERE DOWN and PASTE INTO HIS TEST CODE ... MAKE SURE NOTHING ABOVE HAS CHANGED !!!! OR IT WON'T COMPILE */

/* Combinational always that describes the different memory paths - select_mem_path is set in the sequential always of the FSM */
/* These all hookeup to memory_run_code_... which is muxed up higher by the system - makesure to set select_mem_path to the right
case input and hookup signals appropriately */
always @(*)
begin
 	case (select_mem_path)
		MINIT_RAND:
		begin
			memory_run_code_address = mem_init_data_address[6:0];
			memory_run_code_data_in = mem_init_data_in; 
			memory_run_code_data_wren = mem_init_data_wren;
		end
		MWRITE_LOCAL:
		begin
			...
		end
		MREAD_LOCAL:
		begin
			...
		end
		MFUNCTION:
		begin
			...
		end
		default: 
		begin
			memory_run_code_address = 8'd0;
			memory_run_code_data_in = 36'd0; 
			memory_run_code_data_wren = 1'b0;
		end
	endcase
end

/*****************************************************************************
 * YOUR CODE below - noting some of the signals that attach above!!!
 *****************************************************************************/
/* HERE's where you build your C code as an FSM */
reg [:0] output1; // this is the final output from the run system
reg start; // the signal that is set by the above code to start executing your C code
reg done; // the signal that you turn on to tell the above FSM when your code is complete
reg [15:0] algorithm_ticks; // a record of how many ticks your code takes that is displayed on KEY[3] above
reg [:0] in1;
reg [:0] in2;

reg [7:0] S;
reg [7:0] NS;

/* Parameters for FSM */
parameter 	S_START = 8'd0,
		...
		S_DONE = ,
		S_ERROR = 8'hFF;

parameter 	MINIT_RAND = 3'd0,
		MWRITE_LOCAL = 3'd2,
		MREAD_LOCAL = 3'd3,
		MFUNCTION = 3'd4;
			
reg [:0] i;
reg [:0] idx;
reg [:0] x;
reg [:0] y;
...

/* MEMORY MUXING */
reg [:0]local_data_address;
reg local_data_wren;
reg [:0]local_data_in;
wire [:0]mem_init_data_address;
wire mem_init_data_wren;
wire [:0]mem_init_data_in;

...

/* signals to and from my instantiated memory function modules */
wire s_mem_init_wait_done;
reg s_mem_init_wait_start;
...

/* signals from and to my instantiated modules for various functions */
...


/* absolute value functions instantiation - 1 for each instance in code */
...

/* rand function - 1 for each instance in code - Initialize at begining */
random my_idx(clk, rst, 36'hC981AB039, , );

/* my function instantiation(s) */
...

/* my memory function instantiations */
mem_init_rand my_mem_init(
	clk, 
	rst, 
	s_mem_init_wait_start,
	s_mem_init_wait_done,
	mem_init_data_address,
	mem_init_data_in,
	mem_init_data_wren
);

/* FSM of your C CODE */
/* Flip flops for S and NS with the reset state */
always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
		S <= S_START;
	else
		S <= NS;
end

/* Combinational always that describes the state transitions */
always @(*)
begin
	case (S)
		S_START:
		begin
			if (start == 1'b1)
				NS = S_INIT;
			else
				NS = S_START;
		end
		S_INIT:
		begin
			NS = S_MEM_INIT_START;
		end
		S_MEM_INIT_START:
		begin
			NS = S_MEM_INIT_WAIT;
		end
		S_MEM_INIT_WAIT:
		begin
			if (s_mem_init_wait_done == 1'b1)
				NS = S_DO;
			else
				NS = S_MEM_INIT_WAIT;
		end
		S_DO:
		begin
			NS = S_DONE;
		end
		S_DONE:
		begin
			NS = S_DONE;
		end
		default: NS = S_ERROR;
	endcase
end

/* sequential deal with outputs */
always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
	begin
		output1 <= 
		
		i <= 
		idx <= 
		x <= 
		y <= 

		s_mem_init_wait_start <= 1'b0;
		
		select_mem_path <= 3'd0;
		local_data_address <= 7'd0;
		local_data_wren <= 1'b0;
		local_data_in <= 36'd0;

		done <= 1'b0;
		
		algorithm_ticks <= 16'd0;
	end
	else
	begin
		case (S)
			S_START:
			begin
				output1 <= 
				
				i <= 
				idx <= 
				x <= 
				y <= 

				s_mem_init_wait_start <= 1'b0;
				
				select_mem_path <= 3'd0;
				local_data_address <= 7'd0;
				local_data_wren <= 1'b0;
				local_data_in <= 36'd0;

				done <= 1'b0;
				
				algorithm_ticks <= 16'd0;
			end
			S_INIT:
			begin
			end
			S_MEM_INIT_START:
			begin
				s_mem_init_wait_start <= 1'b1;
				select_mem_path <= MINIT_RAND;  /* MINIT_RAND , MDISPLAY , MWRITE_LOCAL , MREAD_LOCAL , MFUNCTION */
			end
			S_MEM_INIT_WAIT:
			begin
				s_mem_init_wait_start <= 1'b0;
			end
			S_DO:
			begin
				output1 <= in1 + in2;
			end
			S_DONE:
			begin
				done <= 1'b1;
			end	
		endcase
		
		if (!(S == S_DONE || S == S_START))
			algorithm_ticks <= algorithm_ticks + 1'b1;
	end
end

endmodule

/* your modules for memory and functions */
...

