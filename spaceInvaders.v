module spaceInvaders(
    input CLOCK_50,
	 input [9:0] SW,
	 output [9:0] LEDR,
    input [3:0] KEY,          // KEY[3] for right, KEY[2] for left, KEY[1] for start
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_BLANK_N,
    output VGA_SYNC_N,
    output VGA_CLK,
	 output [6:0] HEX0,
	 output [6:0] HEX1,
	 output [6:0] HEX2,
	 output [6:0] HEX3,
	 output [6:0] HEX4,
	 output [6:0] HEX5,
	 inout PS2_CLK,
	inout PS2_DAT
	 
);

	//ps2 keyboard inputs 
	wire		[7:0]	ps2_key_data;
	wire				ps2_key_pressed;
	
	reg keyIsPressed; //used to flag if the key is pressed
	reg leftKey; //used to flag if the a key is pressed
	reg rightKey; //used to flag if d key is presssed
	reg shoot; //used to flag if p key is pressed
	reg space;
	
    parameter Akey = 8'h1c; //code for a
	 parameter Dkey = 8'h23; //code for d
	 parameter breakKey = 8'hF0;
	 parameter Pkey = 8'h4D;
	 parameter spaceKey = 8'h29;

// Internal Registers
	reg			[7:0]	last_data_received;
	
	reg[1:0] stateOfKey;
	parameter IDLE = 2'b00;
	parameter BREAK = 2'b01;
	parameter MAKE = 2'b10;
	
	
	
	always @(posedge CLOCK_50) begin
		if (SW[9]) begin//RESET
			leftKey<=0;
			rightKey<=0;
			shoot<=0;
			space<=0;
			stateOfKey<=IDLE;
		end
		else if(ps2_key_pressed) begin
			case(stateOfKey)
			IDLE: begin
				if (ps2_key_data==Akey) begin
						leftKey<=1;
				stateOfKey<=MAKE;
					end
				else if(ps2_key_data==Dkey)begin
				rightKey<=1;
				stateOfKey<=MAKE;
				end
				else if (ps2_key_data==Pkey)begin
				shoot<=1;
				stateOfKey<=MAKE;
				end
				else if (ps2_key_data==spaceKey)begin
				space<=1;
				stateOfKey<=MAKE;
				end
			end
			MAKE: begin
			if (ps2_key_data == breakKey)begin
				stateOfKey<=BREAK;
				end
				end
			BREAK: begin
			if (ps2_key_data == Akey) begin
			leftKey<=0;
			stateOfKey<=IDLE;
			end
			else if (ps2_key_data == Dkey) begin
			rightKey<=0;
			stateOfKey<=IDLE;
			end
			else if (ps2_key_data == Pkey) begin
			shoot<=0;
			stateOfKey<=IDLE;
			end
			else if (ps2_key_data == spaceKey) begin
			space<=0;
			stateOfKey<=IDLE;
			end
			end
			endcase
			end
			end
	//score count logic - counts up to 15 - copied from lab2
	wire [3:0] V, zout, a, M; 
	
	assign zout[3] = 0;
	assign zout[2] = 0;
	assign zout[1] = 0;

	assign V[3:0] = score[3:0];
	
	seg7score s1(zout, HEX1);
	
	mux m1(V, a, zout[0], M);
	
	seg7score s2(M,HEX0);
	
	zcomparison z1(V, zout[0]); 
	
	acircuit a1(V, a);
	

    // Screen parameters
    parameter SCREEN_WIDTH = 160;
    parameter SCREEN_HEIGHT = 120;
    
    // Spaceship parameters
    parameter SHIP_WIDTH = 8;
    parameter SHIP_HEIGHT = 8;
    parameter SHIP_Y = SCREEN_HEIGHT - SHIP_HEIGHT - 2;
    parameter SHIP_SPEED = 1;
    parameter SHIP_START_X = SCREEN_WIDTH >> 1;
	 parameter BULLET_START_X = SHIP_START_X;
	 parameter BULLET_START_Y = SHIP_Y + 3; 
	 parameter BULLET_HEIGHT = 2; 
    
    // Enemy parameters
    parameter ENEMY_WIDTH = 8;
    parameter ENEMY_HEIGHT = 8;
    parameter ENEMY_SPEED = 1;
    parameter NUM_ENEMIES = 3;
    
    // Game state registers
    reg [7:0] ship_x;         // Ship position //utilize this to move the keyboard and input
	 reg [7:0] bullet_x; 
	 reg [6:0] bullet_y; 
    reg [7:0] enemy_x[0:NUM_ENEMIES-1];  // Enemy X positions
    reg [6:0] enemy_y[0:NUM_ENEMIES-1];  // Enemy Y positions
    reg game_started;         // Game start flag
    reg [2:0] color;          // Color for drawing
    reg plot;                 // Plot signal for VGA
	 reg reset[1:0];
	 reg [3:0] score; //i want to take a look at the value of score
	 reg [6:0] lives;  
	 
	 wire resetCheck; 
	 
	 initial begin
		score <= 0;
	end
	 //game_started = 0;
    
    // Screen position counters
    reg [7:0] current_x;
    reg [6:0] current_y;
    reg bullet_active; 
	 reg collision_detected0;
	 reg collision_detected1;
	 reg collision_detected2; 
	 
    // Frame counter for controlling update speed
    reg [19:0] frame_counter;
    wire frame_update;
    
    // States for the game FSM
    reg [1:0] current_state;
    reg [1:0] next_state;
    parameter UPDATE_POSITION = 2'b00;
    parameter DRAW_FRAME = 2'b01;
    
    // Generate slower clock for frame updates
    assign frame_update = (frame_counter == 20'd833333); // ~60Hz
	 
	 wire w_collision0, w_collision1, w_collision2;
	 
	 assign w_collision0 = collision_detected0; 
	 assign w_collision1 = collision_detected1;
	 assign w_collision2 = collision_detected2;
	 
	 assign LEDR[9] = w_collision0;
	 assign LEDR[8] = w_collision1;
	 assign LEDR[7] = w_collision2; 
	 
	 reg gameEnd; //flags for gameEnd
	 reg gameWin; //flags for gameWin 
	 
	 wire checkGameWin = gameWin; //check if this is the peroper input 
	 wire checkGameLose = gameEnd;
	 
	 reg start;
	
	 
	 //One-second logic
	 counter1 clockCounter(CLOCK_50, !SW[9], Qbig[28:0], start);
	 counter2 clockCounter2(CLOCK_50, !SW[9], Qbig[28:0], Qsmall[3:0], start);
	 //counter 2 displays the values into the hex displays
	 
	 wire [28:0] Qbig;
	 wire [3:0] Qsmall;
	 
	 
	 
	 //seg7 display0(Qsmall[3:0], HEX2); //was hex4 before
	 
	 
	 //10-second logic
	 counter10 clockCounter3(CLOCK_50, !SW[9], Qbig10[28:0], start);
	 counter20 clockCounter4(CLOCK_50, !SW[9], Qbig10[28:0], Qsmall2[3:0], start);
	//this counter displays the values into the hex displays
	//i want to observe when Qsmall2 = 6 or 9, whatever the timer is set to
	 
	 //wire [25:0] Qbig10;
	 wire [29:0] Qbig10;
	 wire [3:0] Qsmall2;
	 //seg7 display1(Qsmall2[3:0], HEX3); //was hex 5 before
	 
	 seg7EndDisplay u9(Qsmall2[3:0], Qsmall[3:0], HEX5,HEX4, HEX3, HEX2, checkGameWin, checkGameLose);
	 
	 
	 
	
	 
	 
	 reg [2:0] spaceShip[0:7][0:7];
	 reg [2:0] greenEnemy[0:7][0:7];
	 reg [2:0] blueEnemy[0:7][0:7]; 
	 reg [2:0] redEnemy[0:7][0:7]; 
	 
	initial begin
		spaceShip[0][0] = 3'b000; spaceShip[0][1] = 3'b000; spaceShip[0][2] = 3'b000; spaceShip[0][3] = 3'b100;
		spaceShip[0][4] = 3'b000; spaceShip[0][5] = 3'b000; spaceShip[0][6] = 3'b000; spaceShip[0][7] = 3'b000;
		
		spaceShip[1][0] = 3'b000; spaceShip[1][1] = 3'b000; spaceShip[1][2] = 3'b100; spaceShip[1][3] = 3'b100;
		spaceShip[1][4] = 3'b100; spaceShip[1][5] = 3'b000; spaceShip[1][6] = 3'b000; spaceShip[1][7] = 3'b000;
		
		spaceShip[2][0] = 3'b000; spaceShip[2][1] = 3'b000; spaceShip[2][2] = 3'b100; spaceShip[2][3] = 3'b100;
		spaceShip[2][4] = 3'b100; spaceShip[2][5] = 3'b000; spaceShip[2][6] = 3'b000; spaceShip[2][7] = 3'b000;
		
		spaceShip[3][0] = 3'b001; spaceShip[3][1] = 3'b000; spaceShip[3][2] = 3'b100; spaceShip[3][3] = 3'b100;
		spaceShip[3][4] = 3'b100; spaceShip[3][5] = 3'b000; spaceShip[3][6] = 3'b001; spaceShip[3][7] = 3'b000;
		
		spaceShip[4][0] = 3'b100; spaceShip[4][1] = 3'b000; spaceShip[4][2] = 3'b100; spaceShip[4][3] = 3'b011;
		spaceShip[4][4] = 3'b100; spaceShip[4][5] = 3'b000; spaceShip[4][6] = 3'b100; spaceShip[4][7] = 3'b000;
		
		spaceShip[5][0] = 3'b100; spaceShip[5][1] = 3'b000; spaceShip[5][2] = 3'b100; spaceShip[5][3] = 3'b100;
		spaceShip[5][4] = 3'b100; spaceShip[5][5] = 3'b000; spaceShip[5][6] = 3'b100; spaceShip[5][7] = 3'b000;
		
		spaceShip[6][0] = 3'b100; spaceShip[6][1] = 3'b100; spaceShip[6][2] = 3'b010; spaceShip[6][3] = 3'b100;
		spaceShip[6][4] = 3'b010; spaceShip[6][5] = 3'b100; spaceShip[6][6] = 3'b100; spaceShip[6][7] = 3'b000;
		
		spaceShip[7][0] = 3'b000; spaceShip[7][1] = 3'b010; spaceShip[7][2] = 3'b000; spaceShip[7][3] = 3'b000;
		spaceShip[7][4] = 3'b000; spaceShip[7][5] = 3'b010; spaceShip[7][6] = 3'b000; spaceShip[7][7] = 3'b000;
		
		
		
		
		
		
		
		greenEnemy[0][0] = 3'b000; greenEnemy[0][1] = 3'b000; greenEnemy[0][2] = 3'b000; greenEnemy[0][3] = 3'b000;
		greenEnemy[0][4] = 3'b000; greenEnemy[0][5] = 3'b000; greenEnemy[0][6] = 3'b000; greenEnemy[0][7] = 3'b000;
		
		greenEnemy[1][0] = 3'b000; greenEnemy[1][1] = 3'b010; greenEnemy[1][2] = 3'b000; greenEnemy[1][3] = 3'b000;
		greenEnemy[1][4] = 3'b000; greenEnemy[1][5] = 3'b010; greenEnemy[1][6] = 3'b000; greenEnemy[1][7] = 3'b000;
		
		greenEnemy[2][0] = 3'b000; greenEnemy[2][1] = 3'b000; greenEnemy[2][2] = 3'b010; greenEnemy[2][3] = 3'b000;
		greenEnemy[2][4] = 3'b010; greenEnemy[2][5] = 3'b000; greenEnemy[2][6] = 3'b000; greenEnemy[2][7] = 3'b000;
		
		greenEnemy[3][0] = 3'b000; greenEnemy[3][1] = 3'b010; greenEnemy[3][2] = 3'b010; greenEnemy[3][3] = 3'b010;
		greenEnemy[3][4] = 3'b010; greenEnemy[3][5] = 3'b010; greenEnemy[3][6] = 3'b000; greenEnemy[3][7] = 3'b000;
		
		greenEnemy[4][0] = 3'b010; greenEnemy[4][1] = 3'b010; greenEnemy[4][2] = 3'b000; greenEnemy[4][3] = 3'b010;
		greenEnemy[4][4] = 3'b000; greenEnemy[4][5] = 3'b010; greenEnemy[4][6] = 3'b010; greenEnemy[4][7] = 3'b000;
		
		greenEnemy[5][0] = 3'b000; greenEnemy[5][1] = 3'b010; greenEnemy[5][2] = 3'b010; greenEnemy[5][3] = 3'b010;
		greenEnemy[5][4] = 3'b010; greenEnemy[5][5] = 3'b010; greenEnemy[5][6] = 3'b000; greenEnemy[5][7] = 3'b000;
		
		greenEnemy[6][0] = 3'b000; greenEnemy[6][1] = 3'b000; greenEnemy[6][2] = 3'b010; greenEnemy[6][3] = 3'b000;
		greenEnemy[6][4] = 3'b010; greenEnemy[6][5] = 3'b000; greenEnemy[6][6] = 3'b000; greenEnemy[6][7] = 3'b000;
		
		greenEnemy[7][0] = 3'b000; greenEnemy[7][1] = 3'b000; greenEnemy[7][2] = 3'b000; greenEnemy[7][3] = 3'b000;
		greenEnemy[7][4] = 3'b000; greenEnemy[7][5] = 3'b000; greenEnemy[7][6] = 3'b000; greenEnemy[7][7] = 3'b000;
		
		
		
		
		blueEnemy[0][0] = 3'b000; blueEnemy[0][1] = 3'b000; blueEnemy[0][2] = 3'b000; blueEnemy[0][3] = 3'b000;
		blueEnemy[0][4] = 3'b000; blueEnemy[0][5] = 3'b000; blueEnemy[0][6] = 3'b000; blueEnemy[0][7] = 3'b000;
		
		blueEnemy[1][0] = 3'b000; blueEnemy[1][1] = 3'b101; blueEnemy[1][2] = 3'b000; blueEnemy[1][3] = 3'b000;
		blueEnemy[1][4] = 3'b000; blueEnemy[1][5] = 3'b101; blueEnemy[1][6] = 3'b000; blueEnemy[1][7] = 3'b000;
		
		blueEnemy[2][0] = 3'b000; blueEnemy[2][1] = 3'b000; blueEnemy[2][2] = 3'b101; blueEnemy[2][3] = 3'b000;
		blueEnemy[2][4] = 3'b101; blueEnemy[2][5] = 3'b000; blueEnemy[2][6] = 3'b000; blueEnemy[2][7] = 3'b000;
		
		blueEnemy[3][0] = 3'b000; blueEnemy[3][1] = 3'b101; blueEnemy[3][2] = 3'b101; blueEnemy[3][3] = 3'b101;
		blueEnemy[3][4] = 3'b101; blueEnemy[3][5] = 3'b101; blueEnemy[3][6] = 3'b000; blueEnemy[3][7] = 3'b000;
		
		blueEnemy[4][0] = 3'b101; blueEnemy[4][1] = 3'b101; blueEnemy[4][2] = 3'b000; blueEnemy[4][3] = 3'b101;
		blueEnemy[4][4] = 3'b000; blueEnemy[4][5] = 3'b101; blueEnemy[4][6] = 3'b101; blueEnemy[4][7] = 3'b000;
		
		blueEnemy[5][0] = 3'b000; blueEnemy[5][1] = 3'b101; blueEnemy[5][2] = 3'b101; blueEnemy[5][3] = 3'b101;
		blueEnemy[5][4] = 3'b101; blueEnemy[5][5] = 3'b101; blueEnemy[5][6] = 3'b000; blueEnemy[5][7] = 3'b000;
		
		blueEnemy[6][0] = 3'b000; blueEnemy[6][1] = 3'b000; blueEnemy[6][2] = 3'b101; blueEnemy[6][3] = 3'b000;
		blueEnemy[6][4] = 3'b101; blueEnemy[6][5] = 3'b000; blueEnemy[6][6] = 3'b000; blueEnemy[6][7] = 3'b000;
		
		blueEnemy[7][0] = 3'b000; blueEnemy[7][1] = 3'b000; blueEnemy[7][2] = 3'b000; blueEnemy[7][3] = 3'b000;
		blueEnemy[7][4] = 3'b000; blueEnemy[7][5] = 3'b000; blueEnemy[7][6] = 3'b000; blueEnemy[7][7] = 3'b000;
		
		
		
		
		redEnemy[0][0] = 3'b000; redEnemy[0][1] = 3'b000; redEnemy[0][2] = 3'b000; redEnemy[0][3] = 3'b000;
		redEnemy[0][4] = 3'b000; redEnemy[0][5] = 3'b000; redEnemy[0][6] = 3'b000; redEnemy[0][7] = 3'b000;
		
		redEnemy[1][0] = 3'b000; redEnemy[1][1] = 3'b100; redEnemy[1][2] = 3'b000; redEnemy[1][3] = 3'b000;
		redEnemy[1][4] = 3'b000; redEnemy[1][5] = 3'b100; redEnemy[1][6] = 3'b000; redEnemy[1][7] = 3'b000;
		
		redEnemy[2][0] = 3'b000; redEnemy[2][1] = 3'b000; redEnemy[2][2] = 3'b100; redEnemy[2][3] = 3'b000;
		redEnemy[2][4] = 3'b100; redEnemy[2][5] = 3'b000; redEnemy[2][6] = 3'b000; redEnemy[2][7] = 3'b000;
		
		redEnemy[3][0] = 3'b000; redEnemy[3][1] = 3'b100; redEnemy[3][2] = 3'b100; redEnemy[3][3] = 3'b100;
		redEnemy[3][4] = 3'b100; redEnemy[3][5] = 3'b100; redEnemy[3][6] = 3'b000; redEnemy[3][7] = 3'b000;
		
		redEnemy[4][0] = 3'b100; redEnemy[4][1] = 3'b100; redEnemy[4][2] = 3'b000; redEnemy[4][3] = 3'b100;
		redEnemy[4][4] = 3'b000; redEnemy[4][5] = 3'b100; redEnemy[4][6] = 3'b100; redEnemy[4][7] = 3'b000;
		
		redEnemy[5][0] = 3'b000; redEnemy[5][1] = 3'b100; redEnemy[5][2] = 3'b100; redEnemy[5][3] = 3'b100;
		redEnemy[5][4] = 3'b100; redEnemy[5][5] = 3'b100; redEnemy[5][6] = 3'b000; redEnemy[5][7] = 3'b000;
		
		redEnemy[6][0] = 3'b000; redEnemy[6][1] = 3'b000; redEnemy[6][2] = 3'b100; redEnemy[6][3] = 3'b000;
		redEnemy[6][4] = 3'b100; redEnemy[6][5] = 3'b000; redEnemy[6][6] = 3'b000; redEnemy[6][7] = 3'b000;
		
		redEnemy[7][0] = 3'b000; redEnemy[7][1] = 3'b000; redEnemy[7][2] = 3'b000; redEnemy[7][3] = 3'b000;
		redEnemy[7][4] = 3'b000; redEnemy[7][5] = 3'b000; redEnemy[7][6] = 3'b000; redEnemy[7][7] = 3'b000;
	 end
	 
	 
	 
	 /*
	 always  @(posedge CLOCK_50) begin
		if (SW[9] == 1'b1)begin
			reset[0] <= reset[1];
			reset[1] <= 1'b1;
			end
		else if (SW[9] == 1'b0)begin
			reset[0] <= reset[1];
			reset [1] <= 1'b0;
			end
		if ((reset[0] == 1'b1) && (reset[1] == 1'b0)) 
			assign resetCheck = 1'b1;
		end
		*/
		

	//score logic 
	/*always @(posedge CLOCK_50) begin
		if(w_collision0 || w_collision1 || w_collision2) begin
			score <= score + 1;
		end
		else begin 
			score <= score; 
		end
	end
	*/
	
	
	
	
    
    // Frame counter logic
    always @(posedge CLOCK_50) begin
        if (SW[9]) begin //changed !KEY[0]
            frame_counter <= 20'd0;
        end
        else if (frame_counter == 20'd833333) begin
            frame_counter <= 20'd0;
        end
        else begin
            frame_counter <= frame_counter + 1'd1;
        end
    end
    
    // Game start logic
    always @(posedge CLOCK_50) begin
        if (SW[9]) begin //chaneged KEY[0]
            game_started <= 1'b0;
        end
        else if (space) begin //!KEY[1]
            game_started <= 1'b1;
				//gameWin <= 0;
				//gameEnd <= 0;
				//start <= 1; ///////////ADDDDDEDDDD THISSSSS S
        end
    end
    
    // State machine for game logic
    always @(posedge CLOCK_50) begin
        if (SW[9]) //changed KEY[0]
            current_state <= UPDATE_POSITION;
        else
            current_state <= next_state;
    end
    
    // Next state logic
    always @(*) begin
        case (current_state)
            UPDATE_POSITION: 
                if (frame_update)
                    next_state = DRAW_FRAME;
                else
                    next_state = UPDATE_POSITION;
                    
            DRAW_FRAME:
                if (current_x == SCREEN_WIDTH - 1 && current_y == SCREEN_HEIGHT - 1)
                    next_state = UPDATE_POSITION;
                else
                    next_state = DRAW_FRAME;
                    
            default: next_state = UPDATE_POSITION;
        endcase
    end
    
    // Initialize enemy positions
    integer i;
    initial begin
        for (i = 0; i < NUM_ENEMIES; i = i + 1) begin
            enemy_x[i] = (SCREEN_WIDTH / (NUM_ENEMIES + 1)) * (i + 1);
            enemy_y[i] = 10 + (i * 15); // Stagger initial heights
        end
    end
    
    // Coordinate and color update logic
    always @(posedge CLOCK_50) begin
        if (SW[9]) begin  // Reset //changed KEY[0]
            ship_x <= SHIP_START_X;
				bullet_x <= BULLET_START_X; 
				bullet_y <= BULLET_START_Y; 
            current_x <= 0;
            current_y <= 0;
            plot <= 0;
				score <= 0; 
				bullet_active <= 1'b0;
				collision_detected0 <= 1'b0; 	
				collision_detected1 <= 1'b0;
				collision_detected2 <= 1'b0; 
				gameEnd<=1'b0;
				gameWin<=1'b0;
            color <= 3'b000; //WANT THIS BECAUSE MEAN GAME RESTART
				start<=1'b0;
            // Reset enemy positions
            for (i = 0; i < NUM_ENEMIES; i = i + 1) begin
                enemy_x[i] <= (SCREEN_WIDTH / (NUM_ENEMIES + 1)) * (i + 1);
                enemy_y[i] <= 10 + (i * 15);
            end
        end
		  //END OF IF STATEMENT
        else begin
            case (current_state)
				
                UPDATE_POSITION: begin
					 if((Qsmall2 == 4 | score == 15)) begin //changed this
					 start<=0;
						if(score == 15)begin
							gameWin <= 1'b1;
							//start<=0;
							end
						else begin
							gameEnd <= 1'b1;
							//start<=0;
							end
					 end
					 
                   else if (frame_update) begin
                        // Update ship position based on key inputs (only if game started)
                        if (game_started | !gameEnd | !gameWin) begin
                            if (rightKey && ship_x < SCREEN_WIDTH-SHIP_WIDTH) //!KEY[2]
                                ship_x <= ship_x + SHIP_SPEED;
                            else if (leftKey && ship_x > 0)//!KEY[3]
                                ship_x <= ship_x - SHIP_SPEED;
										  
									if(shoot && (bullet_active == 1'b0)) begin 	//!KEY[0]
										bullet_active <= 1'b1;
										bullet_x <= ship_x; 
										bullet_y <= BULLET_START_Y; 
                             end
									
										
									if (bullet_active == 1'b1) begin
										if(bullet_y < 2) begin
											bullet_active <= 1'b0;
										end
										else begin
											bullet_y <= (bullet_y > 2)?(bullet_y - 2):0;
										end
									end
									
									if(bullet_active && (bullet_y > enemy_y[0] && bullet_y < enemy_y[0] + ENEMY_HEIGHT) && 
										(bullet_x > enemy_x[0] && bullet_x < enemy_x[0] + ENEMY_WIDTH))begin 
										collision_detected0 = 1'b1; 
										score <= score + 1;
									end
									
									if(bullet_active && (bullet_y > enemy_y[1] && bullet_y < enemy_y[1] + ENEMY_HEIGHT) && 
										(bullet_x > enemy_x[1] && bullet_x < enemy_x[1] + ENEMY_WIDTH))begin 
										collision_detected1 = 1'b1; 	
										score <= score + 1;
									end
									
									if(bullet_active && (bullet_y > enemy_y[2] && bullet_y < enemy_y[2] + ENEMY_HEIGHT) && 
										(bullet_x > enemy_x[2] && bullet_x < enemy_x[2] + ENEMY_WIDTH))begin 
										collision_detected2 = 1'b1; 
										score <= score + 1;
									end
									
                            // Update enemy positions
                            for (i = 0; i < NUM_ENEMIES; i = i + 1) begin
                                if (enemy_y[i] >= SCREEN_HEIGHT) begin
                                    // Reset enemy to top when it reaches bottom
                                    enemy_y[i] <= 0;
                                    // Random-like new X position based on current position
                                    enemy_x[i] <= ((enemy_x[i] * 7 + 13) % (SCREEN_WIDTH - ENEMY_WIDTH));
                                end
                                else begin
                                    enemy_y[i] <= enemy_y[i] + ENEMY_SPEED;
                                end
                            end
                        end //END OF FRAME_UPDATE
                            
                        // Reset drawing position for new frame
                        current_x <= 0;
                        current_y <= 0;
                        plot <= 1;
                    end//END OF ELSE STATEMENT MAYBLE
						  
                end //I THINK THIS IS THE END FOR UPDATE POSITION
                
                DRAW_FRAME: begin
                    plot <= 1;
                    //added all this to see if it updates the background
                    if (!game_started || gameWin == 1'b1 || gameEnd == 1'b1) begin
						  //ended
						  if (gameWin == 1'b1) begin
						  color<=3'b001; //blue color for win
						  gameEnd<=0;
						  //start<=0; //added this
						  end
						  
						  else if (gameEnd == 1'b1) begin
						  color<=3'b100; //red color for lose
						  gameWin<=0;
						  //start<=0;
						  end
                        // Show blank screen before game starts
                        //color <= 3'b001; /////I CHANGED THIS I COMMENTED IT OUT TO TEST THE BACKGROUND
							else 	
								plot<=0;
								//ITERATE THROUGH THE BACKGROUND HERE
								//plot<=1;
                    end
                    else begin
						  start<=1;
                        // Check if current pixel is within ship boundaries
                        if (current_x >= ship_x && current_x < ship_x + SHIP_WIDTH &&
                            current_y >= SHIP_Y && current_y < SHIP_Y + SHIP_HEIGHT) begin
                            //color <= 3'b111;  // White for ship
									 color <= spaceShip[current_y - SHIP_Y][current_x - ship_x];
                        end
                        else begin
                            // Check if current pixel is within any enemy boundaries
                            color <= 3'b000;  // Default to black
									 
									 if(current_x == ship_x && current_y >= bullet_y && current_y < bullet_y + BULLET_HEIGHT)
										color <= 3'b100; 
										
									 if(collision_detected0 == 1'b1)begin
										if (current_x >= enemy_x[0] && current_x < enemy_x[0] + ENEMY_WIDTH &&
                                    current_y >= enemy_y[0] && current_y < enemy_y[0] + ENEMY_HEIGHT)begin
												color <= 3'b111; 
											end
											
										if(current_x == SCREEN_WIDTH-1 && current_y == SCREEN_HEIGHT - 1) begin
										collision_detected0 = 1'b0; 
										enemy_y[0] <= 0; 
										enemy_x[0] <= ((enemy_x[0] * 7 + 13) % (SCREEN_WIDTH - ENEMY_WIDTH));
									end
								end
										
									 
									 if(collision_detected1 == 1'b1)begin
										if (current_x >= enemy_x[1] && current_x < enemy_x[1] + ENEMY_WIDTH &&
                                    current_y >= enemy_y[1] && current_y < enemy_y[1] + ENEMY_HEIGHT)begin
												color <= 3'b111; 
											end
											
										if(current_x == SCREEN_WIDTH-1 && current_y == SCREEN_HEIGHT - 1) begin
										collision_detected1 = 1'b0; 
										enemy_y[1] <= 0; 
										enemy_x[1] <= ((enemy_x[1] * 7 + 13) % (SCREEN_WIDTH - ENEMY_WIDTH));
									end
								end
										
										 if(collision_detected2 == 1'b1)begin
										if (current_x >= enemy_x[2] && current_x < enemy_x[2] + ENEMY_WIDTH &&
                                    current_y >= enemy_y[2] && current_y < enemy_y[2] + ENEMY_HEIGHT)begin
												color <= 3'b111; 
											end
											
										if(current_x == SCREEN_WIDTH-1 && current_y == SCREEN_HEIGHT - 1) begin
										collision_detected2 = 1'b0; 
										enemy_y[2] <= 0; 
										enemy_x[2] <= ((enemy_x[2] * 7 + 13) % (SCREEN_WIDTH - ENEMY_WIDTH));
									end
								end
										
									
									  
									 
									 
									 if(current_x == ship_x && current_y < 5)begin 
										//if(bullet_active)begin 
											color <= 3'b000; 
											//end
									end
									 
                            for (i = 0; i < NUM_ENEMIES; i = i + 1) begin
                                if (current_x >= enemy_x[i] && current_x < enemy_x[i] + ENEMY_WIDTH &&
                                    current_y >= enemy_y[i] && current_y < enemy_y[i] + ENEMY_HEIGHT) begin
                                    //color <= 3'b100;  // Red for enemies
												if (i==0) //this makes it different colors
													color<= greenEnemy[current_y - enemy_y[i]][current_x - enemy_x[i]];
												else if (i==1)
													color<= blueEnemy[current_y - enemy_y[i]][current_x - enemy_x[i]];
												else if (i==2)
													color<= redEnemy[current_y - enemy_y[i]][current_x - enemy_x[i]];
                                end
                            end
                        end
                    end
                        
                    // Update screen coordinates
                    if (current_x == SCREEN_WIDTH-1) begin
                        current_x <= 0;
                        current_y <= current_y + 1;
                    end
                    else begin
                        current_x <= current_x + 1;
                    end
                end
            endcase
        end
    end
    
    // VGA controller instance
    vga_adapter VGA (
        .resetn(!SW[9]),
        .clock(CLOCK_50),
        .colour(color),
        .x(current_x),
        .y(current_y),
        .plot(plot),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );
    
    defparam VGA.RESOLUTION = "160x120";
    defparam VGA.MONOCHROME = "FALSE";
    defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
   // defparam VGA.BACKGROUND_IMAGE = "black.mif";
	 defparam VGA.BACKGROUND_IMAGE = "background.mif";
	 
PS2_Controller PS2 (
	// Inputs
	.CLOCK_50				(CLOCK_50),
	.reset				(SW[9]),

	// Bidirectionals
	.PS2_CLK			(PS2_CLK),
 	.PS2_DAT			(PS2_DAT),

	// Outputs
	.received_data		(ps2_key_data),
	.received_data_en	(ps2_key_pressed)
);
	 
endmodule

module hex7seg (hex, display);
    input [3:0] hex;
    output [6:0] display;

    reg [6:0] display;

    /*
     *       0  
     *      ---  
     *     |   |
     *    5|   |1
     *     | 6 |
     *      ---  
     *     |   |
     *    4|   |2
     *     |   |
     *      ---  
     *       3  
     */
    always @ (hex)
        case (hex)
            4'h0: display = 7'b1000000;
            4'h1: display = 7'b1111001;
            4'h2: display = 7'b0100100;
            4'h3: display = 7'b0110000;
            4'h4: display = 7'b0011001;
            4'h5: display = 7'b0010010;
            4'h6: display = 7'b0000010;
            4'h7: display = 7'b1111000;
            4'h8: display = 7'b0000000;
            4'h9: display = 7'b0011000;
            4'hA: display = 7'b0001000;
            4'hB: display = 7'b0000011;
            4'hC: display = 7'b1000110;
            4'hD: display = 7'b0100001;
            4'hE: display = 7'b0000110;
            4'hF: display = 7'b0001110;
        endcase
endmodule





//utizing clk_50
module counter1(input clk, input reset, output [25:0] Qout, input start);//don't need input enab
	//output [6:0] Qout;
	reg [25:0] q; //creates an internal register of q
	always @ (posedge clk) //got rid of enable
		begin
			if (reset == 0 || q == 26'b10111110101111000010000000 || start==0) begin//this resets everythoing
				q<=0;
				end
			//else if (enable  == 1)
			// begin 
				else if (q == 26'b10111110101111000010000000 && start==1) begin //if q is all 1, then reset it{1'b1}
				q<=0;
				end
				else if(start==1) begin
					q <= q + 1;//q+ 1'b1; //no enable to control it
					end
			//	if (enable1==1) //also acounts for enable, and now we toggle
			end
		assign Qout = q;
endmodule


//working on this one
module counter2(input clk, input reset, input[25:0] enable1, output [3:0] Qout2, input start);//don't need input enab
	reg [3:0] q2; 
	always @ (posedge clk) 
		begin
			if (reset == 0 || start == 0) 
				begin
				q2 <= 4'b0;
				end
				
			else if (enable1 == 26'b10111110101111000010000000) 
				begin
			
					if (q2 == 9) begin
						q2 <= 0;
					end
					
					else begin
					q2 <= q2 + 1;
					end
				end
		end
		assign Qout2 = q2;
endmodule



module seg7 (s, display);
	input [3:0] s; 
	output [6:0] display;
	wire s0, s1, s2, s3;
	assign s3 = s[0];
	assign s2 = s[1];
	assign s1 = s[2];
	assign s0 = s[3];	
	
	assign display[0] = ~(s2 | s0 | (~s1 & ~s3) | (s1 & s3));
	assign display[1] = ~((~s1) | (s2 & s3) | (~s2 & ~s3));
	assign display[2] = ~((~s2) | (s1) | (s3));
	assign display[3] = ~((~s1 & ~s3) | (~s1 & s2) | (s2 & ~s3) | (s1 & ~s2 & s3));
	assign display[4] = ~((~s1 & ~s3) | (s2 & ~s3));
	assign display[5] = ~(s0 | (s1 & ~s3) | (~s2 & ~s3) | (s1 & ~s2));
	assign display[6] = ~(s0 | (~s1 & s2) | (s1 & ~s3) | (s1 & ~s2));
endmodule


//utizing clk_50
module counter10(input clk, input reset, output [28:0] Qout, input start);//don't need input enab
	//output [6:0] Qout;
	reg [28:0] q; //creates an internal register of q
	always @ (posedge clk) //got rid of enable
		begin
			if (reset == 0 || q == 29'b11101110011010110010100000000 || start==0) begin//this resets everythoing
				q<=0;
				end
			//else if (enable  == 1)
			// begin 
				else if (q == 29'b11101110011010110010100000000 && start == 1) begin //if q is all 1, then reset it{1'b1}
				q<=0;
				end
				else if(start==1) begin
					q <= q + 1;//q+ 1'b1; //no enable to control it
					end
			//	if (enable1==1) //also acounts for enable, and now we toggle
			end
		assign Qout = q;
endmodule


//working on this one
module counter20(input clk, input reset, input[28:0] enable1, output [3:0] Qout2, input start);//don't need input enab
	reg [3:0] q2; 
	always @ (posedge clk) 
		begin
			if (reset == 0||start==0) 
				begin
				q2 <= 4'b0;
				end
				
			else if (enable1 == 29'b11101110011010110010100000000) 
				begin
			
					if (q2 == 4) begin //i changed this used to be q2 == 9 and q2<=0
						q2 <= 4; //continosly make it equal to 2 or whatever max value is
					end
					
					else begin
					q2 <= q2 + 1;
					end
				end
		end
		assign Qout2 = q2;
endmodule




module zcomparison(V, zout);
	input [3:0] V;
	output zout; 
	assign zout = ((V[3] & V[2]) | (V[1] & V[3])); 
endmodule


module acircuit(V, aout);
	input [3:0] V;
	output [3:0] aout; 
	assign aout[0] = V[0];
	assign aout[1] = (V[2] & ~V[1]);
	assign aout[2] = (V[2] & V[1]);
	assign aout[3] = 0;
endmodule

module mux(V, aout, zout, M);
	input [3:0] V, aout, zout;
	output [3:0] M; 
	assign M[0] = (~zout & V[0]) | (zout & aout[0]);
	assign M[1] = (~zout & V[1]) | (zout & aout[1]);
	assign M[2] = (~zout & V[2]) | (zout & aout[2]);
	assign M[3] = (~zout & V[3]) | (zout & aout[3]);
endmodule

module seg7score(s, display);
	input [3:0] s; 
	output [6:0] display;
	wire s0, s1, s2, s3;
	assign s3 = s[0];
	assign s2 = s[1];
	assign s1 = s[2];
	assign s0 = s[3];		
	assign display[0] = ~(s2 | s0 | (~s1 & ~s3) | (s1 & s3));
	assign display[1] = ~((~s1) | (s2 & s3) | (~s2 & ~s3));
	assign display[2] = ~((~s2) | (s1) | (s3));
	assign display[3] = ~((~s1 & ~s3) | (~s1 & s2) | (s2 & ~s3) | (s1 & ~s2 & s3));
	assign display[4] = ~((~s1 & ~s3) | (s2 & ~s3));
	assign display[5] = ~(s0 | (s1 & ~s3) | (~s2 & ~s3) | (s1 & ~s2));
	assign display[6] = ~(s0 | (~s1 & s2) | (s1 & ~s3) | (s1 & ~s2));
endmodule
	

	
//updateWhichModule I call!!!!!
module seg7EndDisplay(s, s2_2, display1,display2, display3, display4, win, lose);
	//input [3:0] s;
	
	input [3:0] s; 
	//output [6:0] display;
	wire s0, s1, s2, s3;
	assign s3 = s[0];
	assign s2 = s[1];
	assign s1 = s[2];
	assign s0 = s[3];	
	
	input [3:0] s2_2; 
	//output [6:0] display;
	wire s4, s5, s6, s7;
	assign s7 = s2_2[0];
	assign s6 = s2_2[1];
	assign s5 = s2_2[2];
	assign s4 = s2_2[3];

	
	
	
	output reg [6:0] display1;
	output reg [6:0] display2;
	output reg [6:0] display3;
	output reg [6:0] display4;
	input win; 
	input lose;
	
	//lose letters
	//parameter [6:0] d = 7'b0011111;
	//parameter [6:0] d = 7'b1100000;
	//parameter [6:0] d = 7'b1000010;
	parameter [6:0] d = 7'b0100001;
	//parameter [6:0] d = 7'b0011111;
	//parameter [6:0] I = 7'b0110000;
	parameter [6:0] I = 7'b1001111;
	//parameter [6:0] E = 7'b1111001;
	parameter [6:0] E = 7'b0000110;
	parameter [6:0] BLANK  = 7'b1111111;
	
	//win letters
	//parameter [6:0] A= 7'b1110111; // "A"
	parameter [6:0] A= 7'b0001000; // "A"
 //  parameter [6:0] C = 7'b1001111; // "C"
   //parameter [6:0] C = 7'b0110000; // "C"
   parameter [6:0] C = 7'b1000110;
  // parameter [6:0] E2 = 7'b1111001; // "E"
 ///  parameter [6:0] D = 7'b0011111; // "D"
	
	always@(*) begin
	if (lose==1'b1) begin
	/////ADD THE WIN CONDITION ONE
	display1= d;
	display2=I;
	display3=E;
	display4=BLANK;
	end
	
	else if (win==1'b1)begin
	display1 = A;
	display2= C;
	display3= E;
	display4= d;
	end
	else if (lose==0 && win ==0)begin //display the timer
	display1= BLANK;
	display2= BLANK;
	display3[0] = ~(s2 | s0 | (~s1 & ~s3) | (s1 & s3));
	display3[1] = ~((~s1) | (s2 & s3) | (~s2 & ~s3));
	display3[2] = ~((~s2) | (s1) | (s3));
	display3[3] = ~((~s1 & ~s3) | (~s1 & s2) | (s2 & ~s3) | (s1 & ~s2 & s3));
	display3[4] = ~((~s1 & ~s3) | (s2 & ~s3));
	display3[5] = ~(s0 | (s1 & ~s3) | (~s2 & ~s3) | (s1 & ~s2));
	display3[6] = ~(s0 | (~s1 & s2) | (s1 & ~s3) | (s1 & ~s2));
	
	display4[0] = ~(s6 | s4 | (~s5 & ~s7) | (s5 & s7));
	display4[1] = ~((~s5) | (s6 & s7) | (~s6 & ~s7));
	display4[2] = ~((~s6) | (s5) | (s7));
	display4[3] = ~((~s5 & ~s7) | (~s5 & s6) | (s6 & ~s7) | (s5 & ~s6 & s7));
	display4[4] = ~((~s5 & ~s7) | (s6 & ~s7));
	display4[5] = ~(s4 | (s5 & ~s7) | (~s6 & ~s7) | (s5 & ~s6));
	display4[6] = ~(s4 | (~s5 & s6) | (s5 & ~s7) | (s5 & ~s6));
	
	
	end
	end
	
	
endmodule


	

	


