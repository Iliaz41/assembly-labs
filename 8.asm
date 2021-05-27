	.model  tiny
	.386
	.code
	org 100h
;code
start:	
	push	cs
	pop		ds
	call	INSTALL_HANDLER
		
;data	
FILE_NAME				db		"Print.txt", 0	
FILE_DESCRIPTOR			dw		0
OLD_KEYBOARD_HANDLER	dd		0

BUFFER					db		BUFFER_SIZE dup (?)
BUFFER_SIZE				equ		80 * 25 * 2;count of rows(25) *  count of columns(80) * each char on screen is 2 byte size(2)

TEXT_ERROR_OF_OPENING	db		"Error of file opening$"
ERROR_OF_REMOVE			db		"Can't remove memory$"


		
;procedures
NEW_KEYBOARD_HANDLER PROC FAR
	pushf                         
	pusha                         
	push  	es                      
	push  	ds
	push  	cs                      
	pop   	ds
	
	in 		al, 60h
	cmp		al, 40h
	je		SAVE_SCREEN
	cmp		al, 3Fh
	je		SHOW_SCREEN
	jmp		CALL_OLD_HANDLER
	
	SAVE_SCREEN:
		call	SCAN_SCREEN	
		call	OPEN_FILE
		call	WRITE_BUFFER_IN_FILE
		call	CLOSE_FILE
		jmp		CALL_OLD_HANDLER
	
	SHOW_SCREEN:	
		call	OPEN_FILE
		call	READ_FILE_IN_BUFFER
		jc		FILE_IS_EMPTY
		call	MOVE_POINTER
		call	PRINT_BUFFER_ON_SCREEN
		FILE_IS_EMPTY:
			call	CLOSE_FILE
			jmp		CALL_OLD_HANDLER
		
	CALL_OLD_HANDLER:
		pushf
		call	cs:dword ptr OLD_KEYBOARD_HANDLER	
		
	pop   	ds
	pop   	es
	popa
	popf                     	
	iret
NEW_KEYBOARD_HANDLER ENDP

MOVE_POINTER PROC FAR
	push	ds
	push	cs
	pop		ds

	mov		ah, 02h
	mov		bh, 0
	mov		dh, 24;row
	mov		dl, 0;column
	int		10h
		
	pop		ds
	ret
MOVE_POINTER ENDP

SCAN_SCREEN PROC FAR
	push	ds
	push	cs
	pop		ds

	mov 	ax, 0B800h 
	mov 	es, ax 
	xor 	si, si
	xor 	di, di
	SCAN_SCREEN_LOOP: 
		mov		al, byte ptr es:si 
		mov		BUFFER + di, al
		inc	 	si
		inc		di
		cmp 	di, BUFFER_SIZE
		jne 	SCAN_SCREEN_LOOP
		
	pop		ds
	ret
SCAN_SCREEN ENDP

PRINT_BUFFER_ON_SCREEN PROC FAR
	push	ds
	push	cs
	pop		ds

	mov 	ax, 0B800h 
	mov 	es, ax 
	xor 	si, si
	xor 	di, di
	PRINT_BUFFER_ON_SCREEN_LOOP: 
		mov		al, BUFFER + si
		mov		es:di, byte ptr al 
		inc	 	si
		inc		di
		cmp 	di, BUFFER_SIZE
		jne 	PRINT_BUFFER_ON_SCREEN_LOOP
		
	pop		ds
	ret
PRINT_BUFFER_ON_SCREEN ENDP

READ_FILE_IN_BUFFER PROC FAR
	push	ds
	push	cs
	pop		ds
	
	;pointer to start of file
	mov		ax, 4200h
	mov		bx, FILE_DESCRIPTOR
	xor		cx, cx
	xor		dx, dx
	int		21h

	;read file in buffer
	mov		ah, 3Fh
	mov		bx, FILE_DESCRIPTOR
	mov		cx, BUFFER_SIZE
	mov		dx, offset BUFFER
	int		21h
	
	;if file is empty set flag
	cmp		ax, 0
	jne		FILE_IS_NOT_EMPTY
	stc
	FILE_IS_NOT_EMPTY:
		pop		ds
		ret
READ_FILE_IN_BUFFER ENDP

WRITE_BUFFER_IN_FILE PROC FAR
	push	ds
	push	cs
	pop		ds
	
	;pointer to start of file
	mov		ax, 4200h
	mov		bx, FILE_DESCRIPTOR
	xor		cx, cx
	xor		dx, dx
	int		21h

	;write buffer in file
	mov		ah, 40h
	mov		bx, FILE_DESCRIPTOR
	mov		cx, BUFFER_SIZE
	mov		dx, offset BUFFER
	int		21h
	
	pop		ds
	ret
WRITE_BUFFER_IN_FILE ENDP

OPEN_FILE PROC FAR
	push	ds
	push	cs
	pop		ds
	
	mov		dx, offset FILE_NAME
	mov		ah, 3Dh
	mov		al, 2
	int 	21h
	jc		ERROR_OF_FILE_OPENING
	mov		FILE_DESCRIPTOR, ax
	
	pop		ds
	ret
	
	ERROR_OF_FILE_OPENING:
		mov		ah, 09h
		mov		dx, offset TEXT_ERROR_OF_OPENING
		int		21h
		mov		ax, 4C00h
		int		21h
OPEN_FILE ENDP

CLOSE_FILE PROC FAR
	push	ds
	push	cs
	pop		ds
	
	mov		ah, 3Eh
	mov		bx, FILE_DESCRIPTOR
	int 	21h
	
	pop		ds
	ret
CLOSE_FILE ENDP

END_OF_RESIDENT:
INSTALL_HANDLER PROC FAR
	call	CREATE_FILE
	
	;set new handler
	mov		ax, 3509h
	int		21h
	mov		cs:word ptr OLD_KEYBOARD_HANDLER, bx
	mov		cs:word ptr OLD_KEYBOARD_HANDLER + 2, es
	mov 	dx, offset NEW_KEYBOARD_HANDLER
	mov		ax, 2509h;
	int		21h
	
	;set a resident
	mov		ax, 3100h
	mov		dx, (END_OF_RESIDENT - start + 0FFFh) / 16
	int		21h
INSTALL_HANDLER ENDP
  
CREATE_FILE PROC FAR
	mov 	ax, 3D01h
	lea   	dx, FILE_NAME
	int   	21h                     
	mov   	FILE_DESCRIPTOR, ax     
	jnc   	FILE_IS_EXISTS
 	
	mov 	ah, 3Ch                 
	mov   	cx, 02h                 
	lea   	dx, FILE_NAME
	int   	21h
	mov   	FILE_DESCRIPTOR, ax
 
	FILE_IS_EXISTS: 
		call	CLOSE_FILE
		ret
CREATE_FILE ENDP

    end     start 	
