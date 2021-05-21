.model tiny
org 100h   

.data
params db 20 dup('$')
matrix dw 30 dup(0) 
wp equ word ptr
msg1 db "Enter number of columns: $"
msg2 db 0Ah,0Dh,"Enter number of rows: $"   
msg3 db 0Dh, 0Ah,"Enter the matrix: ",0Dh, 0Ah,'$'
msg4 db 0Dh, 0Ah,"Minimum amount: ",0Dh, 0Ah,'$'
msg_err1 db 0Dh,0Ah,"Invalid value!$"
clears db 5 dup(8),5 dup(32),5 dup(8),'$'
clears2 db 6 dup(8),6 dup(32),6 dup(8),'$'
x dw 0
y dw 0
length dw 0
x_length dw 0
summs dw 60 dup(00h)

.code     
jmp start

out_str macro 
    mov ah,9
    int 21h
endm
in_str macro 
    mov ah, 0Ah
    int 21h
endm
out_sym macro 
    mov ah, 02h
    int 21h
endm

in_sym macro 
    mov ah, 01h
    int 21h
endm

err1:
    lea dx, msg_err1
    out_str
    int 20h
ret

input_number proc
m1:
    mul     si                      
    mov     bl,[di]                 
    cmp     bl, 30h                
    jl      err1                     
    cmp     bl, 39h                
    jg      err1                    
    sub     bl,30h                  
    add     ax,bx                   
    inc     di                      
    loop    m1                      
    ret    
input_number endp

new_line proc 
    mov dl, 0Ah
    out_sym
    mov dl, 0Dh
    out_sym
    xor bp, bp
ret
new_line endp

space proc
mov dl, ' '                                   
    out_sym
ret 
space endp
clear2:
    lea dx, clears
    inc cx
    cmp si, 1
    jne clear
    lea dx, clears2
    neg wp [di]
    cmp wp [di], -32768
    jne clear
    call space
    je next1
clear:
     cmp cx, 1
     je clear2 
     mov [di], wp 0
     out_str    
jmp loop1
   
minus:
    inc si   
jmp loop2

minus2:
    neg wp [di]
    mov ax, wp [di]
jmp next2                                                  
start:
    
    lea dx, msg1
    out_str
    lea dx, params 
    in_str
 
    xor     ax,ax                   
    lea     di,params[2]               
    xor     ch,ch                   
    mov     cl, params[1]           
    mov     si,10                   
    xor     bh,bh
    call input_number                   
    
    mov     x, ax 
    
    lea dx, msg2
    out_str
    lea dx, params 
    in_str
     
    xor     ax,ax                   
    lea     di,params[2]               
    xor     ch,ch                  
    mov     cl, params[1]                  
    mov     si,10                   
    xor     bh,bh
    call input_number                   
    
    mov     y, ax
   
    mov ax, 2				  
    mul x					  
    mul y					  
    add ax, offset matrix	  
    mov length, ax			  
    mov ax, 2				  
    mul x					  
    add ax, offset matrix	  
    mov x_length, ax        

    lea dx, msg3
    out_str
    lea di, matrix
loop1:
    mov cx, 5
    xor ax, ax
    xor dx, dx
    xor si, si
    loop2:
        in_sym
        mov bl, al
        cmp bl, ' '
        je next1
        cmp bl, '-'
        je minus 
        cmp bl, 48
        jl err1
        cmp bl, 57
        jg err1
        sub bl, '0'
        xor ah, ah
        mov ax, 10
        imul wp [di]
        mov [di+1], dx
        jo clear
        add ax, bx
        mov [di], ax
        jo clear                                                              
    loop loop2                                    
    call space                                        
next1:                                                 
    cmp si, 1                                      
    je minus2                                      
next2:                                                       
    add di, 2
    inc bp				
    cmp bp, x		
    jl continue
    call new_line		
    continue:
    cmp di, length    
jl loop1


    lea dx, msg4
    out_str

    xor cx, cx
    lea di, matrix
    lea si, summs
loop3:
    xor bp, bp
    push di 
    loop4:       
        mov dx, [di] 
        add [si+2],dx 
        jno no_overflow 
        cmp wp [di],0 
        jns no_minus
        add wp [si], -1
        jmp no_overflow
        no_minus:
        add wp [si], 1 
        no_overflow:
        add di, x
        add di, x 
        inc bp
        cmp bp, y
    jne loop4
    pop di
    add si, 4 
    inc cx
    add di, 2
    cmp cx, x
jne loop3

mov cx, x
lea di, summs
mov ax, wp [di]
mov dx, wp [di+2]
findMin:
    cmp wp [di+2], dx
    jg next3         
    cmp wp [di], ax
    jg next3
    mov dx, wp [di+2]
    mov ax, wp [di]            
next3:
    add di, 4
loop findMin

xor cx, cx
lea di, summs
mov bp, ax 
mov bx, dx

output:
    cmp wp [di+2], bx
    jne next4
    cmp wp [di], bp    
    jne next4
    mov dl, '0'+1         
    add dl, cl
    out_sym
	mov dl, ' '
	out_sym
next4:
    add di, 4 
    inc cx
    cmp cx, x
jl output

ret
end start