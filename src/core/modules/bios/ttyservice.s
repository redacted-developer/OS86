; print: SI = null-terminated string, AL = color
print:
    push si
    push ax
    mov al, bl
    mov bh, 0
    
.done:
    ret