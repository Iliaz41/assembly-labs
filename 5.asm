	.model small
	.data
	
WRONG_ARGS		db 		"Wrong args in cmd", 0Dh, 0Ah, '$'
FILE_ERROR		db		"Files not found", 0Dh, 0Ah, '$'
DIR_ERROR		db		"Directory not found", 0Dh, 0Ah, '$'
PATH 			db 		128 dup (0)
TEMPLATE		db		128 dup (0)
NEW_DTA 		db 		50 dup (?)
TEMPLATE_SIZE	dw		0
FLAG_EQUAL		db		0
COUNT_OF_FILES	dw		0
	.code
start:
	mov 	ax, DGROUP
	mov 	ds, ax

	call	SCAN_CMD	
	
	mov 	ah,	1Ah
	lea 	dx,	NEW_DTA
	int 	21h
	call 	FILE_FIRST_FILE
	jc 		ERROR_PARSING
	
	MAIN_LOOP:
		call 	FIND_REMAINING_FILES
		jc 		END_OF_SEARCHING
		call	COMPARE_NAME
		cmp		FLAG_EQUAL, 0
		je		MAIN_LOOP
		call 	PRINT_NAME
		inc		COUNT_OF_FILES
		jmp 	MAIN_LOOP
		
	END_OF_SEARCHING:
		cmp		COUNT_OF_FILES, 0
		jne		EXIT_PROGRAM
		mov		ah, 09h
		mov		dx, offset FILE_ERROR
		int		21h
		jmp		EXIT_PROGRAM
		
	ERROR_PARSING:		
		mov		ah, 09h
		mov		dx, offset DIR_ERROR
		int		21h
		jmp		EXIT_PROGRAM
		
	EXIT_PROGRAM:
		mov 	ax,4C00h
		int 	21h
;procedures
SCAN_CMD PROC		
	mov		bx, 80h
	xor		ch ,ch	
	mov		cl, es:[bx]
	cmp		cl, 1
	jle		EXIT_SCAN_CMD
	
	mov		di, 81h
	
	SKIP_SPACES:
		cmp		byte ptr es:[di], 0Dh
		je		EXIT_SCAN_CMD
		cmp		byte ptr es:[di], ' '
		jne		END_SKIP_SPACES
		inc		di
		jmp		SKIP_SPACES
	END_SKIP_SPACES:
		mov		bx, 0
		
	SCAN_PATH:
		cmp		byte ptr es:[di], 0Dh
		je		EXIT_SCAN_CMD
		cmp		byte ptr es:[di], ' '
		je		END_SCAN_PATH
		mov		dl, es:[di]
		mov		PATH + bx, dl
		inc		bx
		inc		di
		jmp		SCAN_PATH
	END_SCAN_PATH:
	
	mov		PATH + bx, '*'
	inc		bx
	mov		PATH + bx, '.'
	inc		bx
	mov		PATH + bx, '*'
	
	SKIP_SPACES1:
		cmp		byte ptr es:[di], 0Dh
		je		EXIT_SCAN_CMD
		cmp		byte ptr es:[di], ' '
		jne		END_SKIP_SPACES1
		inc		di
		jmp		SKIP_SPACES1
	END_SKIP_SPACES1:
		mov		bx, 0
		
	SCAN_TEMPLATE:
		cmp		byte ptr es:[di], 0Dh
		je		END_SCAN_TEMPLATE
		cmp		byte ptr es:[di], ' '
		je		END_SCAN_TEMPLATE
		mov		dl, byte ptr es:[di]
		mov		TEMPLATE + bx, dl
		inc		bx
		inc		di
		jmp		SCAN_TEMPLATE
	END_SCAN_TEMPLATE:
	
	;dec		bx
	mov		TEMPLATE_SIZE, bx
	
	
	ret
	EXIT_SCAN_CMD:
		mov		ah, 09h
		mov		dx, offset WRONG_ARGS
		int		21h
		
		mov		ax, 4C00h
		int 	21h
SCAN_CMD ENDP

FILE_FIRST_FILE PROC
	mov 	ah,	4Eh
	lea 	dx, PATH
	mov 	cx,	110101b
	int 	21h
	ret
FILE_FIRST_FILE ENDP

FIND_REMAINING_FILES proc
	lea 	dx, NEW_DTA
	mov 	ah, 4Fh
	int 	21h
	ret
FIND_REMAINING_FILES endp

COMPARE_NAME PROC
	mov		FLAG_EQUAL, 1
	
	mov 	bx, 1Eh
	mov		cx, 0
	CHECK_DTA_LENGTH:
		cmp		NEW_DTA + bx, 0
		je		END_CHECK_DTA_LENGTH
		inc		cx
		inc		bx
		jmp		CHECK_DTA_LENGTH
		
	END_CHECK_DTA_LENGTH:
		cmp		cx, TEMPLATE_SIZE
		jne		COMPARE_NAME_FALSE
		
	mov 	bx, 1Eh
	mov		di, 0	
	COMPARE_NAME_LOOP:
		cmp 	TEMPLATE + di, '*'
		je		SKIP_COMPARATION
		mov 	dl, NEW_DTA + bx
		cmp 	dl, TEMPLATE + di
		jne		COMPARE_NAME_FALSE		
		SKIP_COMPARATION:
			inc		di
			inc 	bx
			cmp		di, TEMPLATE_SIZE
			jb		COMPARE_NAME_LOOP
		
	ret
	COMPARE_NAME_FALSE:
		mov		FLAG_EQUAL, 0
		ret
COMPARE_NAME ENDP

PRINT_NAME PROC
	mov 	bx, 1Eh
	mov 	ah, 2
	PRINT_NAME_LOOP:
		mov 	dl, [NEW_DTA + bx]
		cmp 	dl,0
		jz 		END_OF_NAME
		int 	21h
		inc 	bx
		jmp 	PRINT_NAME_LOOP
	END_OF_NAME:
		mov 	dl, 13
		int 	21h
		mov 	dl, 10
		int 	21h
		ret
PRINT_NAME ENDP
	end 	start