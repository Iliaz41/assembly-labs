.model small
.stack 100h
.data


msg1 db "Enter the string: ", 0dh, 0ah, "$"
msg2 db 0dh, 0ah, "Enter the word from string: ", 0dh, 0ah, "$"
msg3 db 0dh, 0ah, "Enter the word for insert: ", 0dh, 0ah, "$"
error_msg db 0dh, 0ah, "Invalid input", "$"
full_msg db 0dh, 0ah, "Overflow", "$"
space db 0dh, 0ah, "$"

str db 255 dup("$")
word1 db 255 dup("$")
word2 db 255 dup("$")


                        
                       
.code
main proc  
    
    mov ax, @data
    mov ds, ax
    mov es, ax 
               
    mov str[0], 200
    mov word1[0], 200
    mov word2[0], 200
                                  
    lea dx, msg1  
    call puts
    lea dx, str  
    call gets  
    cmp str[1], 0
    je error  
    cmp str[1], 199
    je last  
    
    lea dx, msg2
    call puts
    lea dx, word1
    call gets  
    
    mov al, word1[1]
    mov ah, str[1]
    cmp ah, al
    jb last  
    
    cmp word1[1], 0
    je error
    
    lea dx, msg3
    call puts
    lea dx, word2
    call gets 
    
    cmp word2[1], 0
    je error     
    
    mov al, str[1]
    add al, word2[1]
    cmp al, 199
    jae full
                                                                           
    xor cx, cx
    mov cl, str[1] 
    lea si, str[2]    
    cycle:
        push cx   
        push si  
        xor cx, cx
        mov cl, word1[1]
        lea di, word1[2]
        mov bx, si 
        repe cmpsb
        je found
        jne not_found    
        found:        
            mov di, bx 
            dec di
            xor ax, ax
            mov al, [di] 
    
            xor dx ,dx
            mov dl, [si] 
            check0:
                cmp dl, 0dh
                jne check1
            next_check0:
                cmp ax, 48
                jb  continuation                  
            check1:
            cmp dl, "$"
            jne check2
            next_check1:
                cmp ax, 48
                jb continuation                
            check2:    
                cmp dl, " " 
                jne check3
            next_check2:
                cmp ax, " "
                je continuation
            check3:
                cmp dx, " "  
                jne not_found
            next_check3:
                cmp ax, 48
                jb continuation
                jmp not_found                                                   

            continuation:
            lea si, str[2] 
            xor ax, ax 
            mov al, str[1]    
            add si, ax 
            dec si 
            
            mov di, si      
            xor ax, ax 
            mov al, word2[1]    
            add di, ax 
            inc di 
           
            lea ax, str[2]
            cmp bx, ax
            jne not_first
            je first
    
            not_first:
                dec bx
                dec bx 
                          
            
                shift:                  
                    xor ax, ax
                    mov al, [si] 
                    mov [di], al
                    dec si
                    dec di
                    cmp si, bx
                    jne shift
                      
                
                lea si, word2[2]
                mov di, bx 
                inc di
                inc di
                xor cx, cx
                mov cl, word2[1]
                rep movsb
                
                pop si
                pop cx
                xor ax, ax 
                mov al, word2[1]
                add si, ax
                inc si
                inc si  
                
                xor ax, ax
                mov al, word2[1]
                add str[1], al
                inc str[1]
                
                
                cmp cx, 1
                je last
                loop cycle
                
               
            first:
                dec bx
                
                shift2:                   
                    xor ax, ax
                    mov al, [si]  
                    mov [di], al
                    dec si
                    dec di
                    cmp si, bx
                    jne shift2
                        
                lea si, word2[2]
                mov di, bx
                inc di
                xor cx, cx
                mov cl, word2[1]
                rep movsb 
                mov [di], " "
                
                pop si
                pop cx
                xor ax, ax 
                mov al, word2[1]
                add si, ax
                inc si
                inc si
           
                xor ax, ax
                mov al, word2[1]
                add str[1], al
                inc str[1]
                
                cmp cx, 1
                je last
                loop cycle   
                      
        not_found:
            pop si
            pop cx
            inc si
            loop cycle 
                
last: 
    lea dx, space
    call puts                                        
    lea dx, str[2]    
    call puts
    jmp endd   
error:
    lea dx, error_msg
    call puts 
    jmp endd        
full:
    lea dx, full_msg
    call puts
    jmp endd
endd:                                                                                                           
    mov ah, 4ch
    int 21h
    ret   
endp main    

         
gets proc   
mov ah, 0Ah
int 21h
ret
endp gets

puts proc
mov ah, 9 
int 21h
ret
endp puts