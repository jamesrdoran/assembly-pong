STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'

	WINDOW_WIDTH DW 140h                  ;width of window (320px)
	WINDOW_HEIGHT DW 0C8h                 ;height of window (200px)
	WINDOW_BOUNDS DW 6                    ;check collisions early
	
	TIME_AUX DB 0                         ;variable used when checking if the time has changed

	BALL_ORIGINAL_X DW 0A0h               ;x position of ball at start of game
	BALL_ORIGINAL_Y DW 64h                ;y position of ball at start of game
	BALL_X DW 0A0h                        ;current x position of the ball
	BALL_Y DW 64h                         ;current y position of the ball
	BALL_SIZE DW 04h                      ;size of the ball (px width and height)
	BALL_VELOCITY_X DW 05h                ;x velocity of the ball
	BALL_VELOCITY_Y DW 02h                ;y velocity of the ball

	PADDLE_LEFT_X DW 0Ah                  ;current x position of the left paddle
	PADDLE_LEFT_Y DW 0Ah                  ;current y position of the left paddle
	PADDLE_LEFT_POINTS DB 0               ;current point of the left player (player one)

	PADDLE_RIGHT_X DW 130h                ;current x position of the right paddle
	PADDLE_RIGHT_Y DW 0Ah                 ;current y position of the right paddle
	PADDLE_RIGHT_POINTS DB 0              ;current point of the right player (player two)

	PADDLE_WIDTH DW 05h                   ;paddle width (5px)
	PADDLE_HEIGHT DW 22h                  ;paddle height (34px)
	PADDLE_VELOCITY DW 05h                ;paddle velocity

DATA ENDS

CODE SEGMENT PARA 'CODE'
	
	MAIN PROC FAR
	ASSUME CS:CODE,DS:DATA,SS:STACK       ;assume as code,data and segments the respective registers
	PUSH DS                               ;push to the stack the DS segment
	SUB AX,AX                             ;clean the AX register
	PUSH AX                               ;push AX to the stack
	MOV AX,DATA                           ;save on the AX register the contents of the DATA segment
	MOV DS,AX                             ;save on the DATA segment the contents of AX
	POP AX                                ;release the top item from the stack to the AX register
	POP AX                                ;release the top item from the stack to the AX register

		CALL CLEAR_SCREEN                   ;set initial video mode configuration

		CHECK_TIME:                         ;time checking loop

			MOV AH,2Ch                        ;get the system time
			INT 21h                           ;CH = hour CL = minute DH = second DL = 1/100 seconds

			CMP DL,TIME_AUX	                  ;is the current time equal to the previous time (TIME_AUX)?
			JE CHECK_TIME                     ;if it is the same, check again

;     if it reaches this point, time has passed

			MOV TIME_AUX,DL                   ;update time

			CALL CLEAR_SCREEN                 ;clear the screen by restarting the video mode

			CALL MOVE_BALL                    ;move ball the ball
			CALL DRAW_BALL                    ;draw ball the ball

			CALL MOVE_PADDLES                 ;move the two paddles (check for a key press)
			CALL DRAW_PADDLES                 ;draw the paddles with updated positions

			JMP CHECK_TIME                    ;check time again

		RET
	MAIN ENDP

	MOVE_BALL PROC NEAR                   ;processes the movement of the ball

;   move the ball horizontally
		MOV AX,BALL_VELOCITY_X              ;move the ball on the x
		ADD BALL_X,AX           

;   check if the ball has passed the left boundries (BALL_X < 0 + WINDOWS_BOUNDS)
;   if is colliding, reset its position
		MOV AX,WINDOW_BOUNDS          
		CMP BALL_X,AX                       ;BALL_X is compared with the left boundries of the screen (0 + WINDOW_BOUNDS)
		JL GIVE_POINT_TO_PLAYER_TWO         ;if it is less, give one point to player two and reset ball position
    
;   check if the ball has passed the right boundries (BALL_X > WINDOW_WIDTH - BALL_SIZE - WINDOW_BOUNDS)
;   if is colliding, reset its position
		MOV AX,WINDOW_WIDTH
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDS
		CMP BALL_X,AX                        ;BALL_X is compared with the right boundries of the screen (BALL_X > WINDOW_WIDTH - BALL_SIZE - WINDOW_BOUNDS)
		JG GIVE_POINT_TO_PLAYER_ONE          ;if it is less, give one point to player one and reset ball position
		JMP MOVE_BALL_VERTICALLY

		GIVE_POINT_TO_PLAYER_ONE:            ;give one point to player one and reset ball position
			INC PADDLE_LEFT_POINTS             ;increment player one points
			CALL RESET_BALL_POSITION           ;reset ball position to the centre of the screen

			CMP PADDLE_LEFT_POINTS,05h         ;check of this player has reached 5 points
			JGE GAME_OVER                      ;if this player is 5 or more, the game is over
			RET
		
		GIVE_POINT_TO_PLAYER_TWO:            ;give one point to player one and reset ball position
			INC PADDLE_RIGHT_POINTS            ;increment player two points
			CALL RESET_BALL_POSITION           ;reset ball position to the centre of the screen

			CMP PADDLE_RIGHT_POINTS,05h         ;check of this player has reached 5 points
			JGE GAME_OVER                      ;if this player is 5 or more, the game is over
			RET

		GAME_OVER:                           ;someone has reached 5 points
			MOV PADDLE_LEFT_POINTS,00h         ;reset player one points
			MOV PADDLE_RIGHT_POINTS,00h        ;reset player two points
			RET

;   move the ball veritcally
		MOVE_BALL_VERTICALLY:
			MOV AX,BALL_VELOCITY_Y
			ADD BALL_Y,AX

;   check if the ball has passed the top boundries (BALL_Y < 0 + WINDOW_BOUNDS)
;   if is colliding, reverse the y velocity
		MOV AX,WINDOW_BOUNDS
		CMP BALL_Y,AX                       ;BALL_Y is compared with the top boundries of the screen (BALL_Y < 0 + WINDOW_BOUNDS)
		JL NEG_VELOCITY_Y			              ;if it is less, reverse the y velocity

;   check if the ball has passed the bottom boundries (BALL_Y > WINDOW_WIDTH - BALL_SIZE - WINDOW_BOUNDS)
;   if is colliding, reverse the y velocity
    MOV AX,WINDOW_HEIGHT
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDS
		CMP BALL_Y,AX                       ;BALL_Y is compared with the bottom boundries of the screen (BALL_Y > WINDOW_WIDTH - BALL_SIZE - WINDOW_BOUNDS)
		JG NEG_VELOCITY_Y			              ;if it is greater, reverse the y velocity

;   check if ball is colliding with right paddle
;   maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny2 && miny1 < maxy2
;   BALL_X + BALL_SIZE > PADDLE_RIGHT_X && BALL_X < PADDLE_RIGHT_X + PADDLE_WIDTH && BALL_Y + BALL_SIZE > PADDLE_RIGHT_Y && BALL_Y < PADDLE_RIGHT_Y + PADDLE_HEIGHT
		MOV AX,BALL_X
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_RIGHT_X
		JNG CHECK_COLLISION_WITH_LEFT_PADDLE  ;if there is no collision check for the left paddle collisions

		MOV AX,PADDLE_RIGHT_X
		ADD AX,PADDLE_WIDTH
		CMP BALL_X,AX
		JNL CHECK_COLLISION_WITH_LEFT_PADDLE  ;if there is no collision check for the left paddle collisions

		MOV AX,BALL_Y
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_RIGHT_Y
		JNG CHECK_COLLISION_WITH_LEFT_PADDLE  ;if there is no collision check for the left paddle collisions

		MOV AX,PADDLE_RIGHT_Y
		ADD AX,PADDLE_HEIGHT
		CMP BALL_Y,AX
		JNL CHECK_COLLISION_WITH_LEFT_PADDLE  ;if there is no collision check for the left paddle collisions

;   if it reaches this point, the ball is colliding with the right paddle
		JMP NEG_VELOCITY_X

;   check if ball is colliding with left paddle
;   maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny2 && miny1 < maxy2
;   BALL_X + BALL_SIZE > PADDLE_LEFT_X && BALL_X < PADDLE_LEFT_X + PADDLE_WIDTH && BALL_Y + BALL_SIZE > PADDLE_LEFT_Y && BALL_Y < PADDLE_LEFT_Y + PADDLE_HEIGHT
		CHECK_COLLISION_WITH_LEFT_PADDLE:
			MOV AX,BALL_X
			ADD AX,BALL_SIZE
			CMP AX,PADDLE_LEFT_X
			JNG EXIT_COLLISION_CHECK  ;if there is no collision exit the procedure

			MOV AX,PADDLE_LEFT_X
			ADD AX,PADDLE_WIDTH
			CMP BALL_X,AX
			JNL EXIT_COLLISION_CHECK  ;if there is no collision exit the procedure

			MOV AX,BALL_Y
			ADD AX,BALL_SIZE
			CMP AX,PADDLE_LEFT_Y
			JNG EXIT_COLLISION_CHECK  ;if there is no collision exit the procedure

			MOV AX,PADDLE_LEFT_Y
			ADD AX,PADDLE_HEIGHT
			CMP BALL_Y,AX
			JNL EXIT_COLLISION_CHECK  ;if there is no collision exit the procedure

;     if it reaches this point, the ball is colliding with the left paddle
			JMP NEG_VELOCITY_X

			NEG_VELOCITY_Y:
				NEG BALL_VELOCITY_Y               ;reverse the velocity in the y (BALL_VELOCITY_Y = -BALL_VELOCITY_Y)
				RET
			
			NEG_VELOCITY_X:
				NEG BALL_VELOCITY_X                   ;reverse ball x velocity
				RET

			EXIT_COLLISION_CHECK:
				RET
				
		RET

	MOVE_BALL ENDP

	MOVE_PADDLES PROC NEAR
		
;   left paddle movement
;   check if a key is being pressed (if not check the other paddle)
		MOV AH,01h                          ;add keyboard status to register
		INT 16h                             ;execute the configuration
		JZ CHECK_RIGHT_PADDLE_MOVEMENT      ;ZF = 1, JZ => jump if zero

		                                    ;check which key is being pressed (AL = ASCII character)
	  MOV AH,00h
		INT 16h

		                                    ;if it is 'w' or 'W' move up
		CMP AL,77h                          ;lowercase 'w'
		JE MOVE_LEFT_PADDLE_UP
		CMP AL,57h                          ;uppercase 'W'
		JE MOVE_LEFT_PADDLE_UP
		                                    ;if it is 's' or 'S' move down
		CMP AL,73h                          ;lowercase 's'
		JE MOVE_LEFT_PADDLE_DOWN
		CMP AL,53h                          ;uppercase 'S'
		JE MOVE_LEFT_PADDLE_DOWN
		JMP CHECK_RIGHT_PADDLE_MOVEMENT

		MOVE_LEFT_PADDLE_UP:
			MOV AX,PADDLE_VELOCITY
			SUB PADDLE_LEFT_Y,AX
			
			MOV AX,WINDOW_BOUNDS
			CMP PADDLE_LEFT_Y,AX
			JL FIX_PADDLE_LEFT_TOP_POSITION
			JMP CHECK_RIGHT_PADDLE_MOVEMENT

			FIX_PADDLE_LEFT_TOP_POSITION:
				MOV PADDLE_LEFT_Y,AX
				JMP CHECK_RIGHT_PADDLE_MOVEMENT


		MOVE_LEFT_PADDLE_DOWN:
			MOV AX,PADDLE_VELOCITY
			ADD PADDLE_LEFT_Y,AX
			MOV AX,WINDOW_HEIGHT
			SUB AX,WINDOW_BOUNDS
			SUB AX,PADDLE_HEIGHT
			CMP PADDLE_LEFT_Y,AX
			JG FIX_PADDLE_LEFT_BOTTOM_POSITION
			JMP CHECK_RIGHT_PADDLE_MOVEMENT

			FIX_PADDLE_LEFT_BOTTOM_POSITION:
				MOV PADDLE_LEFT_Y,AX
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
;   right paddle movement
		CHECK_RIGHT_PADDLE_MOVEMENT:
																			
																			  ;if it is 'o' or 'O' move up
			CMP AL,6Fh                        ;lowercase 'o'
			JE MOVE_RIGHT_PADDLE_UP
			CMP AL,4Fh                        ;uppercase 'O'
			JE MOVE_RIGHT_PADDLE_UP
																			
		                                    ;if it is 'l' or 'L' move down
			CMP AL,6Ch                        ;lowercase 'l'
			JE MOVE_RIGHT_PADDLE_DOWN
			CMP AL,4Ch                        ;uppercase 'L'
			JE MOVE_RIGHT_PADDLE_DOWN
			JMP EXIT_PADDLE_MOVEMENT
			
			MOVE_RIGHT_PADDLE_UP:
				MOV AX,PADDLE_VELOCITY
				SUB PADDLE_RIGHT_Y,AX
				
				MOV AX,WINDOW_BOUNDS
				CMP PADDLE_RIGHT_Y,AX
				JL FIX_PADDLE_RIGHT_TOP_POSITION
				JMP EXIT_PADDLE_MOVEMENT

				FIX_PADDLE_RIGHT_TOP_POSITION:
					MOV PADDLE_RIGHT_Y,AX
					JMP EXIT_PADDLE_MOVEMENT

			MOVE_RIGHT_PADDLE_DOWN:
				MOV AX,PADDLE_VELOCITY
				ADD PADDLE_RIGHT_Y,AX
				MOV AX,WINDOW_HEIGHT
				SUB AX,WINDOW_BOUNDS
				SUB AX,PADDLE_HEIGHT
				CMP PADDLE_RIGHT_Y,AX
				JG FIX_PADDLE_RIGHT_BOTTOM_POSITION
				JMP EXIT_PADDLE_MOVEMENT

				FIX_PADDLE_RIGHT_BOTTOM_POSITION:
					MOV PADDLE_RIGHT_Y,AX
					JMP EXIT_PADDLE_MOVEMENT

		EXIT_PADDLE_MOVEMENT:

			RET

	MOVE_PADDLES ENDP
	
	RESET_BALL_POSITION PROC NEAR         ;reset ball position to the original position               
	
		MOV AX,BALL_ORIGINAL_X
		MOV BALL_X,AX

		MOV AX,BALL_ORIGINAL_Y
		MOV BALL_Y,AX

		RET
	RESET_BALL_POSITION ENDP

	DRAW_BALL PROC NEAR
		
		MOV CX,BALL_X                       ;set the initial column (x)
		MOV DX,BALL_Y                       ;set the initial line (y)
		
		DRAW_BALL_HORIZONTAL:
			MOV AH,0Ch                        ;set the configuration to writing a pixel
			MOV AL,0Fh                        ;choose white as colour
			MOV BH,00h                        ;set the page number
			INT 10h                           ;execute the configuration

			INC CX                            ;CX = CX + 1
			MOV AX,CX                         ;CX - BALL_X > BALL_SIZE (y => we go to the next line, N => we continue to the next column)
			SUB AX,BALL_X
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL

			MOV CX,BALL_X                     ;the CX register goes back to the inital column
			INC DX                            ;we advance one line

			MOV AX,DX                         ;DX - BALL_Y > BALL_SIZE (y => we exit the procedure, N => we continue to the next line)
			SUB AX,BALL_Y
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL

		RET
	DRAW_BALL ENDP

	DRAW_PADDLES PROC NEAR
		
		MOV CX,PADDLE_LEFT_X                ;set the initial column (x) w
		MOV DX,PADDLE_LEFT_Y                ;set the initial line (y)

		DRAW_PADDLE_LEFT_HORIZONTAL:
			MOV AH,0Ch                        ;set the configuration to writing a pixel
			MOV AL,0Fh                        ;choose white as colour
			MOV BH,00h                        ;set the page number
			INT 10h                           ;execute the configuration

			INC CX                            ;CX = CX + 1
			MOV AX,CX                         ;CX - PADDLE_LEFT_X > PADDLE_WIDTH (y => we go to the next line, N => we continue to the next column)
			SUB AX,PADDLE_LEFT_X
			CMP AX,PADDLE_WIDTH
			JNG DRAW_PADDLE_LEFT_HORIZONTAL

			MOV CX,PADDLE_LEFT_X              ;the CX register goes back to the inital column
			INC DX                            ;we advance one line

			MOV AX,DX                         ;DX - PADDLE_LEFT_Y > PADDLE_WIDTH (y => we exit the procedure, N => we continue to the next line)
			SUB AX,PADDLE_LEFT_Y
			CMP AX,PADDLE_HEIGHT
			JNG DRAW_PADDLE_LEFT_HORIZONTAL
 
		MOV CX,PADDLE_RIGHT_X               ;set the initial column (x)
		MOV DX,PADDLE_RIGHT_Y               ;set the initial line (y)

		DRAW_PADDLE_RIGHT_HORIZONTAL:
			
			MOV AH,0Ch                        ;set the configuration to writing a pixel
			MOV AL,0Fh                        ;choose white as colour
			MOV BH,00h                        ;set the page number
			INT 10h                           ;execute the configuration

			INC CX                            ;CX = CX + 1
			MOV AX,CX                         ;CX - PADDLE_RIGHT_X > PADDLE_WIDTH (y => we go to the next line, N => we continue to the next column)
			SUB AX,PADDLE_RIGHT_X
			CMP AX,PADDLE_WIDTH
			JNG DRAW_PADDLE_RIGHT_HORIZONTAL

			MOV CX,PADDLE_RIGHT_X             ;the CX register goes back to the inital column
			INC DX                            ;we advance one line

			MOV AX,DX                         ;DX - PADDLE_RIGHT_Y > PADDLE_WIDTH (y => we exit the procedure, N => we continue to the next line)
			SUB AX,PADDLE_RIGHT_Y
			CMP AX,PADDLE_HEIGHT
			JNG DRAW_PADDLE_RIGHT_HORIZONTAL

		RET
	DRAW_PADDLES ENDP

	CLEAR_SCREEN PROC NEAR                ;clear screen by resetting the video mode

		MOV AH,00h                          ;set the configuration to video mode
		MOV AL,13h                          ;choose the video mode (320x200 graphics 256 colours)
		INT 10h                             ;execute the configuration

		MOV AH,0Bh                          ;set the configuration 
		MOV BH,00h                          ;to the background colour
		MOV BL,00h                          ;choose black as background colour	
		INT 10h                             ;execute the configuration

		RET
	CLEAR_SCREEN ENDP

CODE ENDS
END
