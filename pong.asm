STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'

	WINDOW_WIDTH DW 140h   ;width of window (320px)
	WINDOW_HEIGHT DW 0C8h  ;height of window (200px)
	WINDOW_BOUNDS DW 6     ;check collisions early
	
	TIME_AUX DB 0          ;variable used when checking if the time has changed

	BALL_ORIGINAL_X DW 0A0h
	BALL_ORIGINAL_Y DW 64h
	BALL_X DW 0A0h         ;x position of the ball
	BALL_Y DW 64h          ;y position of the ball
	BALL_SIZE DW 04h       ;size of the ball (px width and height)
	BALL_VELOCITY_X DW 05h ;x velocity of the ball
	BALL_VELOCITY_Y DW 02h ;y velocity of the ball

DATA ENDS

CODE SEGMENT PARA 'CODE'
	
	MAIN PROC FAR
	ASSUME CS:CODE,DS:DATA,SS:STACK ;assume as code,data and segments the respective registers
	PUSH DS                         ;push to the stack the DS segment
	SUB AX,AX                       ;clean the AX register
	PUSH AX                         ;push AX to the stack
	MOV AX,DATA                     ;save on the AX register the contents of the DATA segment
	MOV DS,AX                       ;save on the DATA segment the contents of AX
	POP AX                          ;release the top item from the stack to the AX register
	POP AX                          ;release the top item from the stack to the AX register

		CALL CLEAR_SCREEN

		CHECK_TIME:
			MOV AH,2Ch        ;get the system time
			INT 21h           ;CH = hour CL = minute DH = second DL = 1/100 seconds

			CMP DL,TIME_AUX	  ;is the current time equal to the previous time (TIME_AUX)?
			JE CHECK_TIME     ;if it is the same, check again
			                  ;if it's different, then draw, move, etc.

			MOV TIME_AUX,DL   ;update time
			
			CALL CLEAR_SCREEN ;clear the screen

			CALL MOVE_BALL    ;move ball to new position
			CALL DRAW_BALL    ;draw ball in new position

			JMP CHECK_TIME    ;after everything checks time again

		RET
	MAIN ENDP

	MOVE_BALL PROC NEAR

		MOV AX,BALL_VELOCITY_X ;move the ball on the x
		ADD BALL_X,AX           

		MOV AX,WINDOW_BOUNDS 
		CMP BALL_X,AX
		JL RESET_POSITION      ;BALL_X < 0 + WINDOW_BOUNDS (y => collided)
    
		MOV AX,WINDOW_WIDTH
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDS
		CMP BALL_X,AX          ;BALL_X > WINDOW_WIDTH - BALL_SIZE (y => collided)
		JG RESET_POSITION

		MOV AX,BALL_VELOCITY_Y ;move the ball on the y
		ADD BALL_Y,AX

		MOV AX,WINDOW_BOUNDS
		CMP BALL_Y,AX          ;BALL_Y < 0 + WINDOW_BOUNDS (y => collided)
		JL NEG_VELOCITY_Y			  

    MOV AX,WINDOW_HEIGHT ;BALL_Y > WINDOW_WIDTH - BALL_SIZE (y => collided)
		SUB AX,BALL_SIZE     ;minus BALL_SIZE
		SUB AX,WINDOW_BOUNDS ;minus WINDOW_BOUNDS
		CMP BALL_Y,AX        ;add BALL_Y to memory
		JG NEG_VELOCITY_Y    ;reverse balls velocity

		RET

		RESET_POSITION:
			CALL RESET_BALL_POSITION
			RET

		NEG_VELOCITY_Y:
			NEG BALL_VELOCITY_Y  ;BALL_VELOCITY_Y = -BALL_VELOCITY_Y
			RET

	MOVE_BALL ENDP
	
	RESET_BALL_POSITION PROC NEAR
	
		MOV AX,BALL_ORIGINAL_X
		MOV BALL_X,AX

		MOV AX,BALL_ORIGINAL_Y
		MOV BALL_Y,AX

		RET
	RESET_BALL_POSITION ENDP

	DRAW_BALL PROC NEAR
		
		MOV CX,BALL_X ;set the initial column (x) w
		MOV DX,BALL_Y ;set the initial line (y)
		
		DRAW_BALL_HORIZONTAL:
			MOV AH,0Ch    ;set the configuration to writing a pixel
			MOV AL,0Fh    ;choose white as colour
			MOV BH,00h    ;set the page number
			INT 10h       ;execute the configuration

			INC CX        ;CX = CX + 1
			MOV AX,CX     ;CX - BALL_X > BALL_SIZE (y => we go to the next line, N => we continue to the next column)
			SUB AX,BALL_X
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL

			MOV CX,BALL_X ;the CX register goes back to the inital column
			INC DX        ;we advance one line

			MOV AX,DX     ;DX - BALL_Y > BALL_SIZE (y => we exit the procedure, N => we continue to the next line)
			SUB AX,BALL_Y
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL

		RET
	DRAW_BALL ENDP

	CLEAR_SCREEN PROC NEAR

		MOV AH,00h ;set the configuration to video mode
		MOV AL,13h ;choose the video mode (320x200 graphics 256 colours)
		INT 10h    ;execute the configuration

		MOV AH,0Bh ;set the configuration 
		MOV BH,00h ;to the background colour
		MOV BL,00h ;choose black as background colour	
		INT 10h    ;execute the configuration

		RET
	CLEAR_SCREEN ENDP

CODE ENDS
END
