.model  small
.386
.stack  100h
.data	

GAME_STATE			db		0	
GAME_LEVEL			db		1
PERCENT_TO_WIN		equ		70
CURRENT_PERCENT		db		0

CURRENT_PAGE		db 		0	
DISPLAING_PAGE		db 		1	
MENU_PAGE			db		2
	
WINDOW_X			db		0
WINDOW_Y			db		0
WINDOW_WIDTH		db	    80
WINDOW_HEIGHT		db	    24

BALL1_X				db		40
BALL1_Y				db		12
BALL2_X				db		10
BALL2_Y				db		10
BALL_X				db		0
BALL_Y				db		0
BALL_WIDTH			db		1
BALL_HEIGHT			db		1
BALL_VELOCITY_X	db		0
BALL_VELOCITY_Y	db		0
BALL_VELOCITY1_X	db		1
BALL_VELOCITY1_Y	db		1
BALL_VELOCITY2_X	db		-1
BALL_VELOCITY2_Y	db		-1

HERO_X				db		40
HERO_Y				db		0
HERO_WIDTH			db		1
HERO_HEIGHT			db		1
HERO_VELOCITY_X		db		0	
HERO_VELOCITY_Y		db		0

BEACH_TILES_NUMBER	equ		1920
BEACH_TILES			db		BEACH_TILES_NUMBER dup (0)

PATH_TILES_NUMBER	equ		1920
PATH_TILES			db		BEACH_TILES_NUMBER dup (0)
PATH_BOOLEAN		db		0

TEXT_GAME_OVER		db		"GAME OVER                    $"	
TEXT_VICTORI		db		"WINNER, WINNER, WINNER!$"
TEXT_RESTART		db		"Press R to restart$"
TEXT_EXIT			db		"Press E to exit$"
TEXT_FILLED			db		"Filled: $"
TEXT_SPACE			db		"    $"
TEXT_PERCENT		db		"%$"
    .code  	
start:	
	mov		ax, DGROUP
	mov		ds, ax
	
	call	PRIMAL_SETUP
	
	MAIN_LOOP:
		call	DO_DELAY
		call	GAME_UPDATE
		call	CLEAN_SCREEN
		call	GAME_DRAW
		call	DISPLAY_GAME
		jmp		MAIN_LOOP
		
	mov		ax, 4C00h
	int		21h

;===========================================
;===========================================
;============MAIN PROCEDURES================
;===========================================
;===========================================
DISPLAY_GAME PROC FAR
	mov		ah, 5
	mov		al, DISPLAING_PAGE
	int		10h
	
	call 	HIDE_CURSOR
	
	mov		al, DISPLAING_PAGE
	mov		ah, CURRENT_PAGE
	mov		DISPLAING_PAGE, ah
	mov		CURRENT_PAGE, al
	ret
DISPLAY_GAME ENDP

PRIMAL_SETUP PROC FAR
	mov		ah, 00h
	mov		al, 03h
	int 	10h
	call	BEACH_PRIMAL_SETUP
	
	mov		ah, 5
	mov		al, CURRENT_PAGE
	int		10h
	
	push	0B800h
	pop		es
	ret
PRIMAL_SETUP ENDP	

DO_DELAY PROC FAR
	cmp		GAME_LEVEL, 1
	je		DELAY_1
	cmp		GAME_LEVEL, 2
	je		DELAY_2
	cmp		GAME_LEVEL, 3
	je		DELAY_3
	
	DELAY_1:
		mov 	ah, 86h
		mov		al, 0
		mov		cx, 0
		mov 	dx, 64000
		int 	15h
		ret
	DELAY_2:
		mov 	ah, 86h
		mov		al, 0
		mov		cx, 0
		mov 	dx, 32000
		int 	15h
		ret
	DELAY_3:
		mov 	ah, 86h
		mov		al, 0
		mov		cx, 0
		mov 	dx, 16000
		int 	15h
		ret
		
DO_DELAY ENDP

GAME_UPDATE PROC FAR
	call	UPDATE_PATH
	call	UPDATE_BALL
	call	UPDATE_HERO
	call	CHECK_GAME_OVER
	call	CHECK_VICTORY
	ret
GAME_UPDATE ENDP

CLEAN_SCREEN PROC far
	mov		cx, 1920
	CLEAN_SCREEN_LOOP:
		push	cx	
		mov		ax, cx
		call 	NUMBER_TO_COORD
		mov		dl, ah
		mov		dh, al
		mov		ah, 2
		mov		bh, DISPLAING_PAGE		
		int		10h
		
		mov		ah, 09
		mov		bh, DISPLAING_PAGE		
		mov		al, ' '
		mov		bl, 00000000b
		mov		cx, 1
		int 	10h
		
		pop		cx
		loop	CLEAN_SCREEN_LOOP
	ret
CLEAN_SCREEN ENDP

GAME_DRAW PROC FAR
	call	DRAW_PATH	
	call	DRAW_BEACH	
	call	DRAW_BALL	
	call	DRAW_HERO	
	call	DRAW_UI
	ret
GAME_DRAW ENDP

HIDE_CURSOR PROC FAR
	mov		ah, 2
	mov		bh, DISPLAING_PAGE
	mov		dh, 25
	mov		dl, 0
	int		10h
	ret
HIDE_CURSOR ENDP

SHOW_GAME_MENU PROC FAR
	call	CLEAN_SCREEN
	
	mov		ah, 05h
	mov		al, MENU_PAGE
	int 	10h

	mov		ah, 2
	mov		bh, MENU_PAGE
	mov		dl, 30
	mov		dh, 11
	int		10h
	
	mov		dx, offset TEXT_GAME_OVER
	cmp		GAME_STATE, 0
	je		NOT_SET_VICTORY_TEXT
	mov		dx, offset TEXT_VICTORI	
	NOT_SET_VICTORY_TEXT:
		mov		ah, 09h
		int		21h
		
	mov		ah, 2
	mov		bh, MENU_PAGE
	mov		dl, 30
	mov		dh, 12
	int		10h
	
	mov		ah, 09h
	mov		dx, offset TEXT_RESTART
	int		21h
	
	mov		ah, 2
	mov		bh, MENU_PAGE
	mov		dl, 30
	mov		dh, 13
	int		10h
	
	mov		ah, 09h
	mov		dx, offset TEXT_EXIT
	int		21h
	
	GAME_MENU_INPUT:
		mov		ah, 08h
		int 	21h
		
		cmp		al, 'R'
		je		RESTART_GAME_SIGN
		cmp		al, 'r'
		je		RESTART_GAME_SIGN
		cmp		al, 'E'
		je		EXIT_GAME
		cmp		al, 'e'
		je		EXIT_GAME
		jmp		GAME_MENU_INPUT
			
		RESTART_GAME_SIGN:
			call 	RESTART_GAME
			mov		ah, 05h
			mov		al, DISPLAING_PAGE
			int 	10h
			ret
		EXIT_GAME:
			call 	CLEAN_SCREEN
			mov		ah, 00h
			mov		al, 02h
			int 	10h
			mov		ax, 4C00h
			int 	21h
			ret
SHOW_GAME_MENU ENDP

;===========================================
;===========================================
;============UPDATE PROCEDURES==============
;===========================================
;===========================================
HANDLER_INPUT PROC FAR
	mov		ah, 01h
	int 	16h
	jz		CLEAR_KEYBOARD
	
	mov		ah, 00h
	int 	16h
	
	cmp 	al, 77h;w
	je		SET_DIRECTION_UP
	cmp 	al, 57h;W
	je		SET_DIRECTION_UP
	cmp 	al, 73h;s
	je		SET_DIRECTION_DOWN
	cmp 	al, 53h;S
	je		SET_DIRECTION_DOWN
	cmp 	al, 61h;a
	je		SET_DIRECTION_LEFT
	cmp 	al, 41h;A
	je		SET_DIRECTION_LEFT
	cmp 	al, 64h;d
	je		SET_DIRECTION_RIGHT
	cmp 	al, 44h;D
	je		SET_DIRECTION_RIGHT
	ret
	
	SET_DIRECTION_UP:
		;cmp		HERO_VELOCITY_Y, 1
		;je		CLEAR_KEYBOARD
		mov		HERO_VELOCITY_X, 0
		mov		HERO_VELOCITY_Y, -1
		jmp		CLEAR_KEYBOARD
		
	SET_DIRECTION_DOWN:
		;cmp		HERO_VELOCITY_Y, -1
		;je		CLEAR_KEYBOARD
		mov		HERO_VELOCITY_X, 0
		mov		HERO_VELOCITY_Y, 1
		jmp		CLEAR_KEYBOARD
		
	SET_DIRECTION_LEFT:
		;cmp		HERO_VELOCITY_X, 1
		;je		CLEAR_KEYBOARD
		mov		HERO_VELOCITY_X, -1
		mov		HERO_VELOCITY_Y, 0
		jmp		CLEAR_KEYBOARD
		
	SET_DIRECTION_RIGHT:
		;cmp		HERO_VELOCITY_X, -1
		;je		CLEAR_KEYBOARD
		mov		HERO_VELOCITY_X, 1
		mov		HERO_VELOCITY_Y, 0
		jmp		CLEAR_KEYBOARD
	
	CLEAR_KEYBOARD:
		mov		ah, 01h
		int 	16h
		jZ		EXIT_UPDATE_HERO
	
		mov		ah, 00h
		int 	16h
		jmp		CLEAR_KEYBOARD
		ret
	EXIT_UPDATE_HERO:
		ret
HANDLER_INPUT ENDP

UPDATE_HERO PROC FAR
	call	HANDLER_INPUT
	
	mov 	al, HERO_VELOCITY_X
	add 	HERO_X, al
	cmp		HERO_VELOCITY_X, 1
	je		MOVE_HERO_RIGHT
	cmp		HERO_VELOCITY_X, -1
	je		MOVE_HERO_LEFT
	
	mov 	al, HERO_VELOCITY_Y
	add 	HERO_Y, al
	cmp		HERO_VELOCITY_Y, 1
	je		MOVE_HERO_DOWN
	cmp		HERO_VELOCITY_Y, -1
	je		MOVE_HERO_UP
	
	mov 	al, HERO_VELOCITY_Y
	add 	HERO_Y, al
	
	mov 	al, HERO_VELOCITY_X
	add 	HERO_X, al
	ret
		
	MOVE_HERO_UP:
		mov		al, WINDOW_Y
		cmp		HERO_Y, al
		jge		SKIP_FIX_TOP_POSITION
		mov		HERO_Y, al
		mov		HERO_VELOCITY_Y, 0
		SKIP_FIX_TOP_POSITION:
			ret
			
	MOVE_HERO_DOWN:
		mov		al, WINDOW_HEIGHT
		sub		al, HERO_HEIGHT
		cmp		HERO_Y, al
		jle		SKIP_FIX_DOWN_POSITION
		mov		HERO_Y, al
		mov		HERO_VELOCITY_Y, 0
		SKIP_FIX_DOWN_POSITION:
			ret
		
	MOVE_HERO_RIGHT:
		mov		al, WINDOW_WIDTH
		sub		al, HERO_WIDTH
		cmp		HERO_X, al
		jle		SKIP_FIX_RIGHT_POSITION
		mov		HERO_X, al
		mov		HERO_VELOCITY_X, 0
		SKIP_FIX_RIGHT_POSITION:
			ret
			
	MOVE_HERO_LEFT:
		mov		al, WINDOW_Y
		cmp		HERO_X, al
		jge		SKIP_FIX_LEFT_POSITION
		mov		HERO_X, al
		mov		HERO_VELOCITY_X, 0
		SKIP_FIX_LEFT_POSITION:
			ret
UPDATE_HERO ENDP	

UPDATE_PATH PROC FAR
	mov		al, HERO_Y
	mov		bl, 80
	mul		bl
	xor		bh, bh
	mov		bl, HERO_X
	add		ax, bx
	mov		di, ax
	
	cmp		BEACH_TILES + di, 0
	je		ADD_TILE_TO_PATH
	cmp		PATH_BOOLEAN, 1
	je		CAST_PATH_TO_BEACH
	ret	
	ADD_TILE_TO_PATH:
		mov		PATH_BOOLEAN, 1
		mov		PATH_TILES + di, 1
		ret
		
	CAST_PATH_TO_BEACH:
		mov		cx, PATH_TILES_NUMBER
		mov		di, 0
		CAST_PATH_TO_BEACH_LOOP:
			cmp		PATH_TILES + di, 1
			jne		SKIP_CAST_PATH_TO_BEACH_ITERATION
			mov		BEACH_TILES + di, 1
			mov		HERO_VELOCITY_X, 0
			mov		HERO_VELOCITY_Y, 0
			SKIP_CAST_PATH_TO_BEACH_ITERATION:
				mov		PATH_TILES + di, 0
				inc		di
				loop	CAST_PATH_TO_BEACH_LOOP
		call	FILL_BEACH_PIRIMETR
		mov		PATH_BOOLEAN, 0
		ret
UPDATE_PATH ENDP
	
UPDATE_BALL PROC FAR	
	mov		al, BALL1_X
	mov		BALL_X, al
	mov		al, BALL1_Y
	mov		BALL_Y, al
	mov		al, BALL_VELOCITY1_X
	mov		BALL_VELOCITY_X, al
	mov		al, BALL_VELOCITY1_Y
	mov		BALL_VELOCITY_Y, al

	mov		al, BALL_VELOCITY_Y
	add		BALL_Y, al
	call	CHECK_VERTICAL_COLLISION

	mov		al, BALL_VELOCITY_X
	add		BALL_X, al
	call	CHECK_HORIZONTAL_COLLISION
	
	mov		al, BALL_X
	mov		BALL1_X, al
	mov		al, BALL_Y
	mov		BALL1_Y, al
	mov		al, BALL_VELOCITY_X
	mov		BALL_VELOCITY1_X, al
	mov		al, BALL_VELOCITY_Y
	mov		BALL_VELOCITY1_Y, al
	
	
	
	mov		al, BALL2_X
	mov		BALL_X, al
	mov		al, BALL2_Y
	mov		BALL_Y, al
	mov		al, BALL_VELOCITY2_X
	mov		BALL_VELOCITY_X, al
	mov		al, BALL_VELOCITY2_Y
	mov		BALL_VELOCITY_Y, al

	mov		al, BALL_VELOCITY_Y
	add		BALL_Y, al
	call	CHECK_VERTICAL_COLLISION

	mov		al, BALL_VELOCITY_X
	add		BALL_X, al
	call	CHECK_HORIZONTAL_COLLISION
	
	mov		al, BALL_X
	mov		BALL2_X, al
	mov		al, BALL_Y
	mov		BALL2_Y, al
	mov		al, BALL_VELOCITY_X
	mov		BALL_VELOCITY2_X, al
	mov		al, BALL_VELOCITY_Y
	mov		BALL_VELOCITY2_Y, al
	
	ret
UPDATE_BALL ENDP

CHECK_VERTICAL_COLLISION PROC FAR
	mov		cx, BEACH_TILES_NUMBER
	mov		di, 0
	CHECK_VERTICAL_COLLISION_LOOP:
		cmp		BEACH_TILES + di, 1
		jne		SKIP_CHECK_VERTICAL_COLLISION_ITERATION
		
		clc
		call	CHECK_INTERSECT
		jnc		SKIP_CHECK_VERTICAL_COLLISION_ITERATION
		
		neg		BALL_VELOCITY_Y
		mov		al, BALL_VELOCITY_Y
		add		BALL_Y, al
		mov		al, BALL_VELOCITY_X
		sub		BALL_X, al
		ret
		SKIP_CHECK_VERTICAL_COLLISION_ITERATION:
			inc		di
			loop	CHECK_VERTICAL_COLLISION_LOOP
			ret
CHECK_VERTICAL_COLLISION ENDP

CHECK_HORIZONTAL_COLLISION PROC FAR
	mov		cx, BEACH_TILES_NUMBER
	mov		di, 0
	CHECK_HORIZONTAL_COLLISION_LOOP:
		cmp		BEACH_TILES + di, 1
		jne		SKIP_CHECK_HORIZONTAL_COLLISION_ITERATION
		
		clc
		call	CHECK_INTERSECT
		jnc		SKIP_CHECK_HORIZONTAL_COLLISION_ITERATION
		
		neg		BALL_VELOCITY_X
		mov		al, BALL_VELOCITY_X
		add		BALL_X, al
		mov		al, BALL_VELOCITY_Y
		sub		BALL_Y, al
		ret
		SKIP_CHECK_HORIZONTAL_COLLISION_ITERATION:
			inc		di
			loop	CHECK_HORIZONTAL_COLLISION_LOOP
			ret
CHECK_HORIZONTAL_COLLISION ENDP

CHECK_INTERSECT PROC FAR
	mov		ax, di
	mov		bl, 80
	div		bl
	
	cmp		al, BALL_Y
	jne		EXIT_CHECK_INTERSECT	
	cmp		ah, BALL_X
	jne		EXIT_CHECK_INTERSECT	
	stc
	ret	
	EXIT_CHECK_INTERSECT:
		clc
		ret
CHECK_INTERSECT ENDP

CHECK_GAME_OVER PROC FAR
	mov		ah, BALL1_X
	mov		al, BALL1_Y
	call	COORD_TO_NUMBER
	mov		di, ax
	
	cmp		PATH_TILES + di, 1
	jne		CHECK_SECOND
	mov		GAME_STATE, 0
	mov		GAME_LEVEL, 1
	call	SHOW_GAME_MENU
	ret
	
	CHECK_SECOND:
	mov		ah, BALL2_X
	mov		al, BALL2_Y
	call	COORD_TO_NUMBER
	mov		di, ax
	
	cmp		PATH_TILES + di, 1
	jne		NOT_GAME_OVER
	mov		GAME_STATE, 0
	mov		GAME_LEVEL, 1
	call	SHOW_GAME_MENU
	NOT_GAME_OVER:
		ret
CHECK_GAME_OVER ENDP

CHECK_VICTORY PROC FAR
	call	CALCULATE_CURRENT_PERCENT
	cmp		CURRENT_PERCENT, PERCENT_TO_WIN
	jge		CHECK_VICTORY_TRUE
	ret
	
	CHECK_VICTORY_TRUE:
		call	RESTART_GAME
		inc		GAME_LEVEL
		cmp		GAME_LEVEL, 3
		jg		SHOW_VICTORY_MENU
		ret
	SHOW_VICTORY_MENU:
		mov		GAME_LEVEL, 1
		mov		GAME_STATE, 1
		call	SHOW_GAME_MENU
		ret
CHECK_VICTORY ENDP

;===========================================
;===========================================
;============DRAW PROCEDURES================
;===========================================
;===========================================
DRAW_BALL PROC FAR
	mov		ah, 2
	mov		bh, DISPLAING_PAGE
	mov		dl, BALL1_X
	mov		dh, BALL1_Y
	int		10h
	
	mov		ah, 09
	mov		bh, DISPLAING_PAGE
	mov		al, ' '
	mov		bl, 00101111b
	xor		ch, ch
	mov		cl, BALL_WIDTH
	int 	10h
	
	
	mov		ah, 2
	mov		bh, DISPLAING_PAGE
	mov		dl, BALL2_X
	mov		dh, BALL2_Y
	int		10h
	
	mov		ah, 09
	mov		bh, DISPLAING_PAGE
	mov		al, ' '
	mov		bl, 00101111b
	xor		ch, ch
	mov		cl, BALL_WIDTH
	int 	10h
	ret
DRAW_BALL ENDP	

DRAW_HERO PROC FAR
	mov		ah, 2
	mov		bh, DISPLAING_PAGE
	mov		dl, HERO_X
	mov		dh, HERO_Y
	int		10h
	
	mov		ah, 09
	mov		bh, DISPLAING_PAGE
	mov		al, '0'
	mov		bl, 01011111b
	xor		ch, ch
	mov		cl, HERO_WIDTH
	int 	10h
	ret
DRAW_HERO ENDP	

DRAW_BEACH PROC FAR
	mov		di, 0
	mov		cx, BEACH_TILES_NUMBER
	DRAW_BEACH_LOOP:
		cmp		BEACH_TILES + di, 1
		jne		SKIP_DRAW_CURRENT_BEACH_TILE
		push	cx
		mov		ax, di
		mov		bl, 80
		div		bl
		
		mov		dl, ah
		mov		dh, al
		mov		ah, 2
		mov		bh, DISPLAING_PAGE
		int		10h
		
		mov		ah, 09
		mov		bh, DISPLAING_PAGE
		mov		al, ' '
		mov		bl, 00110000b
		mov		cx, 1
		int 	10h
		pop		cx
		SKIP_DRAW_CURRENT_BEACH_TILE:
			inc		di
			loop 	DRAW_BEACH_LOOP
	ret
DRAW_BEACH ENDP

DRAW_PATH PROC FAR
	mov		di, 0
	mov		cx, PATH_TILES_NUMBER
	DRAW_PATH_LOOP:
		cmp		PATH_TILES + di, 1
		jne		SKIP_DRAW_CURRENT_PATH_TILE
		push	cx
		mov		ax, di
		mov		bl, 80
		div		bl
		
		mov		dl, ah
		mov		dh, al
		mov		ah, 2
		mov		bh, DISPLAING_PAGE
		int		10h
		
		mov		ah, 09
		mov		bh, DISPLAING_PAGE
		mov		al, ' '
		mov		bl, 01011111b
		mov		cx, 1
		int 	10h
		pop		cx
		SKIP_DRAW_CURRENT_PATH_TILE:
			inc		di
			loop 	DRAW_PATH_LOOP
			ret
DRAW_PATH ENDP

DRAW_UI	PROC FAR
	mov		ah, 05h
	mov		al, DISPLAING_PAGE
	int 	10h

	mov		ah, 2
	mov		bh, DISPLAING_PAGE
	mov		dl, 35
	mov		dh, 24
	int		10h
	
	mov		ah, 9
	mov		dx, offset TEXT_FILLED
	int		21h
	
	mov		ah, 9
	mov		dx, offset TEXT_SPACE
	int		21h
	
	mov		ah, 2
	mov		bh, DISPLAING_PAGE
	mov		dl, 43
	mov		dh, 24
	int		10h
	
	xor		ax, ax
	mov		al, CURRENT_PERCENT
	call	SHOW_INT16
	
	mov		ah, 9
	mov		dx, offset TEXT_PERCENT
	int		21h
	ret
DRAW_UI ENDP
;===========================================
;===========================================
;============ADDITIONAL PROCEDURES==========
;===========================================
;===========================================
;ax -> ah(x), al(y)
NUMBER_TO_COORD PROC FAR
	mov		bl, 80
	div		bl
	ret
NUMBER_TO_COORD ENDP	

;ah(x), al(y)	- > ax
COORD_TO_NUMBER PROC FAR
	mov		bh, ah
	mov		bl, 80
	mul		bl  
	mov		bl, bh
	xor		bh, bh
	add		ax, bx
	ret
COORD_TO_NUMBER ENDP	

RESTART_GAME PROC FAR
	mov		BALL1_X, 40
	mov		BALL1_Y, 12
	
	mov		BALL2_X, 10
	mov		BALL2_Y, 10
	
	mov		HERO_X, 40
	mov		HERO_Y, 0
	mov		HERO_VELOCITY_X, 0
	mov		HERO_VELOCITY_Y, 0
	
	mov		cx, PATH_TILES_NUMBER
	mov		di, 0
	CLEAN_PATH_LOOP:
		mov		PATH_TILES + di, 0
		inc		di
		loop 	CLEAN_PATH_LOOP
	
	call	BEACH_PRIMAL_SETUP
	ret
RESTART_GAME ENDP

FILL_BEACH_PIRIMETR PROC FAR
	mov		ah, BALL1_X
	mov		al, BALL1_Y
	call	COORD_TO_NUMBER
	mov		di, ax
	call	INFECT_NEIGHBORS
	
	mov		ah, BALL2_X
	mov		al, BALL2_Y
	call	COORD_TO_NUMBER
	mov		di, ax
	call	INFECT_NEIGHBORS
	
	xor		cx, BEACH_TILES_NUMBER
	mov		di, 0
	FILL_BEACH_PIRIMETR_LOOP:
		cmp		BEACH_TILES + di, 0
		je		SETUP_1
		cmp		BEACH_TILES + di, 2
		je		SETUP_0
		jmp		FILL_BEACH_PIRIMETR_LOOP_ITERATION
		SETUP_1:
			mov		BEACH_TILES + di, 1 
			jmp		FILL_BEACH_PIRIMETR_LOOP_ITERATION
		SETUP_0:
			mov		BEACH_TILES + di, 0 
			jmp		FILL_BEACH_PIRIMETR_LOOP_ITERATION
		FILL_BEACH_PIRIMETR_LOOP_ITERATION:
			inc		di
			loop	FILL_BEACH_PIRIMETR_LOOP
	ret
FILL_BEACH_PIRIMETR ENDP

INFECT_NEIGHBORS PROC FAR
	push	di
	mov		BEACH_TILES + di, 2
	pop		di
	
	push	di
	inc		di
	cmp		BEACH_TILES + di, 1
	je		SKIP1
	cmp		BEACH_TILES + di, 2
	je		SKIP1
	call	INFECT_NEIGHBORS
	SKIP1:
		pop		di
	
	push	di	
	dec		di
	cmp		BEACH_TILES + di, 1
	je		SKIP2
	cmp		BEACH_TILES + di, 2
	je		SKIP2
	call	INFECT_NEIGHBORS
	SKIP2:
		pop		di
	
	push	di	
	add		di, 80
	cmp		BEACH_TILES + di, 1
	je		SKIP3
	cmp		BEACH_TILES + di, 2
	je		SKIP3
	call	INFECT_NEIGHBORS
	SKIP3:
		pop		di
	
	push	di	
	sub		di, 80
	cmp		BEACH_TILES + di, 1
	je		SKIP4
	cmp		BEACH_TILES + di, 2
	je		SKIP4
	call	INFECT_NEIGHBORS
	SKIP4:
		pop		di
	
	push	di	
	add		di, 80
	dec		di
	cmp		BEACH_TILES + di, 1
	je		SKIP5
	cmp		BEACH_TILES + di, 2
	je		SKIP5
	call	INFECT_NEIGHBORS
	SKIP5:
		pop		di
	
	push	di	
	add		di, 80
	inc		di
	cmp		BEACH_TILES + di, 1
	je		SKIP6
	cmp		BEACH_TILES + di, 2
	je		SKIP6
	call	INFECT_NEIGHBORS
	SKIP6:
		pop		di
	
	push	di	
	sub		di, 80
	dec		di
	cmp		BEACH_TILES + di, 1
	je		SKIP7
	cmp		BEACH_TILES + di, 2
	je		SKIP7
	call	INFECT_NEIGHBORS
	SKIP7:
		pop		di
	
	push	di	
	sub		di, 80
	inc		di
	cmp		BEACH_TILES + di, 1
	je		SKIP8
	cmp		BEACH_TILES + di, 2
	je		SKIP8
	call	INFECT_NEIGHBORS
	SKIP8:
		pop		di
	ret
INFECT_NEIGHBORS ENDP	
	
BEACH_PRIMAL_SETUP PROC FAR
	mov		cx, BEACH_TILES_NUMBER
	mov		di, 0
	BEACH_PRIMAL_SETUP_LOOP:
		mov		ax, di
		mov		bl, 80
		div		bl
		cmp		ah, 0
		je		FILL_BEACH
		cmp		ah, 79
		je		FILL_BEACH
		cmp		di, 80
		jl		FILL_BEACH
		cmp		di, 1839
		jg		FILL_BEACH
		mov		BEACH_TILES + di, 0
		inc		di
		loop	BEACH_PRIMAL_SETUP_LOOP
		FILL_BEACH:
			mov		BEACH_TILES + di, 1
			inc		di
			loop	BEACH_PRIMAL_SETUP_LOOP
	ret
BEACH_PRIMAL_SETUP ENDP

CALCULATE_CURRENT_PERCENT PROC ENDP
	mov		cx, BEACH_TILES_NUMBER
	mov		di, 0
	mov		dx, 0
	CALCULATE_CURRENT_PERCENT_LOOP:
		cmp		BEACH_TILES + di, 1
		jne 	SKIP_CALCULATE_CURRENT_PERCENT_ITERATION
		inc		dx
		SKIP_CALCULATE_CURRENT_PERCENT_ITERATION:
			inc		di
			loop	CALCULATE_CURRENT_PERCENT_LOOP 
			
	mov		ax, dx
	sub		ax, 184
	mov		bx, 100
	mul		bx
	
	mov		bx, BEACH_TILES_NUMBER 
	sub		bx, 184
	div		bx
	
	sub		al, 1
	mov     CURRENT_PERCENT, al
	ret
CALCULATE_CURRENT_PERCENT ENDP

SHOW_INT16 PROC FAR
    push    ax
    push    bx
    push    cx
    push    dx
    mov     bx, 10    
     
    xor     cx, cx     
    or      ax, ax     
    jns     @@div
    neg     ax     
    push    ax     
    mov     ah, 02h
    mov     dl, '-'
    int     21h
    pop     ax
@@div:                 
    xor     dx, dx
    div     bx
    push    dx     
    inc     cx     
    or      ax, ax
    jnz     @@div  
            
    mov     ah, 02h
@@store:
    pop     dx     

    cmp     dx, 9
    ja      @@In_hex
    add     dl, '0'
    jmp     @@Skip_hex_output 
    
    @@In_hex:       
    add     dl, 55   
    
    @@Skip_hex_output:
    int     21h     
    loop    @@store
    
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    ret
SHOW_INT16 ENDP  
    end     start       							