.model tiny
.code
org 100h

start:

shrink_memory macro
    push ax
    push bx
    mov sp, length_of_program + 100h + 200h ;смещение стека на 200h после конца программы 
    mov ax, length_of_program + 100h + 200h ; 
    shr ax, 4
    inc ax
    mov bx, ax
    mov ah, 4Ah ; отрезает память 
    int 21h
    pop bx
    pop ax
endm

    call parce_command_line ; считываем файл 
    jc error_wrong_args

get_args:
    call get_args_from_file
    jc error_wrong_args

prep_for_start:
    shrink_memory
    jc error_mem_resize

init_EPB:
    mov ax, cs
    mov word ptr EPB + 4, ax ; сегмент командной строки 
    mov word ptr EPB + 8, ax ; сегмент fcb1
    mov word ptr EPB + 0Ch, ax ; сегмент fcb2
    
    mov ax, 04B00h
    mov dx, offset exec_file_path
    mov bx, offset EPB
    int 21h
    jc error_failed_to_start

    jmp _end

error_wrong_args:
    mov dx, offset error_message_wrong_args
    mov ah, 9h
    int 21h
    jmp _end
error_retrieve_data:
    mov dx, offset error_message_retrieve_data
    mov ah, 9h
    int 21h
    jmp _end
error_mem_resize:
    mov dx, offset couldnt_resize_memory 
    mov ah, 9h
    int 21h
    jmp _end
error_failed_to_start:
    mov dx, offset failed_to_start
    mov ah, 9h
    int 21h
    cmp ax, 02h
    je error_1
    cmp ax, 05h
    je error_2
    jmp error_3
error_1:
    mov dx, offset file_not_found
    jmp log_error
error_2:
    mov dx, offset access_denied
    jmp log_error
error_3:
    jmp _end
log_error:
    mov ah, 9h
    int 21h

_end:
    int 20h

EPB                 dw 0000 ; текущее окружение
                    dw offset commandline, 0 ; адрес командной строки 
                    dw 005Ch, 006Ch ; адрес fcb программы 
                    dd ? ; 
commandline         db 0
command_text        db 125 dup (?)

length_of_program   equ $-start





max_path_size               equ 124
flag                        db ?
too_big_flag                db ?
buf                         db ?
exec_file_path              db "files.exe", 0
text_file_path              db max_path_size dup (0), 0
file_not_found              db "file not found", 0Ah, 0Dh, '$'
path_not_found              db "path not found", 0Ah, 0Dh, '$'
too_much_open_files         db "too much open files", 0Ah, 0Dh, '$'
access_denied               db "access denied", 0Ah, 0Dh, '$'
unidentified_error          db "unidentified error", 0Ah, 0Dh, '$'
line_is_too_big             db "arguments list is too big", 0Ah, 0Dh, '$'
couldnt_get_exec_file_name  db "couldn't get exec file name", 0Dh, 0Ah, '$'
error_message_wrong_args    db "wrong command line argument format", 0Dh, 0Ah, "correct format:", 0Dh, 0Ah, "filename", 0Dh, 0Ah, '$'
couldnt_resize_memory       db "couldn't resize memory", 0Ah, 0Dh, '$'
failed_to_start             db "failed to launch file", 0Ah, 0Dh, '$'
error_message_retrieve_data db "couldn't retrieve data", 0Ah, 0Dh, '$'

parce_command_line proc; output: text_file_path - program path
    push bx
    push cx
    xor ah, ah
    mov al, byte ptr ds:[80h] ;длина командной строки 
    cmp al, 0
    je parce_command_line_error

    xor ch, ch
    mov cl, al
    mov di, 81h ; на начало имени файла
    call store_file_name
    jc parce_command_line_error

    jmp parce_command_line_end
    parce_command_line_error:
    stc
    parce_command_line_end:
    pop cx
    pop bx
    ret
endp

store_file_name proc; 
    push ax
    push si
    mov al, ' '
    repe scasb
    cmp cx, 0
    je store_file_name_start_error
    dec di
    inc cx
    push di
    mov si, di
    mov di, offset text_file_path
    rep movsb ; перенос из си в ди ( из командной строки в буфер )
    jmp store_file_name_end
    store_file_name_start_error:
    push di
    store_file_name_error:
    stc
    store_file_name_end:
    pop di
    pop si
    pop ax
    ret
endp

put_if_needed proc; buf - char, di - dest     необходимо для переноса содержимого в командную строку
    push ax

    mov al, buf
    cmp al, 0Dh
    je put_if_needed_end
    cmp al, ' '
    jne put_if_needed_yes_not_space
    mov flag, 1
    jmp put_if_needed_end

    put_if_needed_yes_not_space:
    cmp flag, 0
    je put_if_needed_yes
    mov al, ' '
    stosb
    inc commandline
    mov al, buf
    mov flag, 0
    put_if_needed_yes:
    stosb
    mov al, 0Dh
    stosb
    inc commandline
    dec di
    cmp di, max_path_size
    jne put_if_needed_end
    stc
    jmp put_if_needed_end

    put_if_needed_end:
    pop ax
    ret
endp

get_line_from_file proc; cx - number of line, text_file_path - path to file, di - start pos; output: adds new formatted string to arguments
    push ax
    push dx
    push cx
    push bx
    push si


    mov too_big_flag, 0

    mov al, 1000010b
    mov ah, 3Dh
    mov dx, offset text_file_path
    int 21h
    jc get_line_from_file_open_error

    mov flag, 1 
    
    mov bx, ax
    mov si, cx
    dec si
    mov cx, 1
    mov ah, 3Fh
    mov dx, offset buf
    cmp si, 0
    je get_line_from_file_save_line    

    get_line_from_file_find_line:
        mov ah, 3Fh
        int 21h
        cmp ax, 0 ; пока не нуль 
        je get_line_from_file_error_no_line
        cmp buf, 0Ah
        jne get_line_from_file_find_line
        dec si
        cmp si, 0
        je get_line_from_file_save_line
    jmp get_line_from_file_find_line
    
    get_line_from_file_save_line:
        mov ah, 3Fh
        int 21h
        cmp ax, 0
        je get_line_from_file_end_of_line
        cmp buf, 0Dh
        je get_line_from_file_end_of_line
        cmp buf, 0Ah
        je get_line_from_file_end_of_line

        call put_if_needed
        jc get_line_from_file_error_too_big
    jmp get_line_from_file_save_line

    get_line_from_file_end_of_line:
    jmp get_line_from_file_end_no_error

    get_line_from_file_open_error:
    cmp ax, 02h
    je get_line_from_file_error_1
    cmp ax, 03h
    je get_line_from_file_error_2
    cmp ax, 04h
    je get_line_from_file_error_3
    cmp ax, 05h
    je get_line_from_file_error_4
    get_line_from_file_error_1:
    mov dx, offset file_not_found
    jmp get_line_from_file_log_error
    get_line_from_file_error_2:
    mov dx, offset path_not_found
    jmp get_line_from_file_log_error
    get_line_from_file_error_3:
    mov dx, offset too_much_open_files
    jmp get_line_from_file_log_error
    get_line_from_file_error_4:
    mov dx, offset access_denied
    jmp get_line_from_file_log_error
    get_line_from_file_log_error:
    mov ah, 9h
    int 21h
    stc
    jmp get_line_from_file_end_after_close

    get_line_from_file_error_no_line:
    jmp get_line_from_file_error

    get_line_from_file_error_too_big:
    mov too_big_flag, 1
    mov dx, offset line_is_too_big
    mov ah, 9h
    int 21h
    jmp get_line_from_file_error

    get_line_from_file_error:
    stc
    jmp get_line_from_file_end

    get_line_from_file_end:
    mov ah, 3Eh
    int 21h
    stc
    jmp get_line_from_file_end_after_close
    get_line_from_file_end_no_error:
    mov ah, 3Eh
    int 21h
    get_line_from_file_end_after_close:
    pop si
    pop bx
    pop cx
    pop dx
    pop ax
    ret
endp

get_args_from_file proc; 
    push cx
    push di

    mov cx, 1
    mov di, offset command_text

    get_args_from_file_loop:
        call get_line_from_file
        jc get_args_from_file_can_not_continue
        inc cx
        jmp get_args_from_file_loop

    get_args_from_file_can_not_continue:
    cmp too_big_flag, 1
    je get_args_from_file_end
    clc

    get_args_from_file_end:
    pop di
    pop cx
    ret
endp

end start