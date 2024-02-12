
section .data
    ;Varaibles for 1A
    new_line        db 10,0
    new_line_len    dd 1
    data_ptr        dd 0
    ;Varaibles for 1B
    infile          dd 0
    outfile         dd 1
section .bss
    buffer          resb 256 
section .text
global _start
global system_call
extern strlen
_start:
    pop    dword ecx    ; ecx = argc
    mov    esi,esp      ; esi = argv
    ;; lea eax, [esi+4*ecx+4] ; eax = envp = (4*ecx)+esi+4
    mov     eax,ecx     ; put the number of arguments into eax
    shl     eax,2       ; compute the size of argv in bytes
    add     eax,esi     ; add the size to the address of argv 
    add     eax,4       ; skip NULL at the end of argv
    push    dword eax   ; char *envp[]
    push    dword esi   ; char* argv[]
    push    dword ecx   ; int argc

    call    main        ; int main( int argc, char *argv[], char *envp[] )

    mov     ebx,eax
    mov     eax,1
    int     0x80
    nop
        
system_call:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov     eax, [ebp+8]    ; Copy function args to registers: leftmost...        
    mov     ebx, [ebp+12]   ; Next argument...
    mov     ecx, [ebp+16]   ; Next argument...
    mov     edx, [ebp+20]   ; Next argument...
    int     0x80            ; Transfer control to operating system
    mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

main:
        push        ebp
        mov         ebp, esp
        push        ebx
        mov         ecx, [ebp+8]    ; esi = argc
        mov         edx, [ebp+12]   ; edx = argv
        mov         ebx, 0          ; edi = 0
next:
        mov         eax, dword [edx+ebx*4]
        
        pushad
        mov         ecx, eax
        pushad
        cmp         byte[ecx], '-'
        jne          after_minus
        inc     ecx
        cmp     byte[ecx],'i'
        jne      out
        inc     ecx
        mov     eax, 5          
        mov     ebx, ecx        
        mov     ecx, 2
        mov     edx, 0777        
        int     0x80
        mov     [infile], eax
        jmp     after_minus

out:  cmp     byte[ecx],'o'
        jne      after_minus
        inc     ecx
        mov     eax, 5          
        mov     ebx, ecx        
        mov     ecx, 2
        mov     edx, 0777         
        int     0x80
        mov     [outfile], eax
encode:
    mov     eax, 3              ; Read from input file
    mov     ebx, [infile]
    mov     ecx, cur      
    mov     edx, 1
    int     0x80
    cmp     eax, 0           
    je      end                 ; If read returns 0, end

    cmp     byte [cur], '`'    ; Check if the input is '`'
    je      end                 ; If yes, call end

    cmp     byte [cur], 'A'
    jb      print_char          ; If below 'A', print the character
    cmp     byte [cur], 'Y'
    jbe     convert_to_next_upper   ; If between 'A' and 'Y', convert to next upper case
    cmp     byte [cur], 'Z'
    je      convert_to_lower    ; If 'Z', convert to lower case
    cmp     byte [cur], 'a'
    jb      print_char          ; If below 'a', print the character

print_char:
    mov     eax, 4              ; System call number for sys_write
    mov     ebx, [outfile]      ; File descriptor (stdout)
    mov     ecx, cur            ; Pointer to the character
    mov     edx, 1              ; Length of the character
    int     0x80                ; Call kernel to write the character
    jmp     encode              ; Continue encoding

convert_to_next_upper:
    inc     byte [cur]          ; Convert to next upper case
    jmp     print_char          ; Print the character

convert_to_next_lower:
    inc     byte [cur]          ; Convert to next lower case
    jmp     print_char          ; Print the character

convert_to_upper:
    sub     byte [cur], 25      ; Convert 'z' to 'A'
    jmp     print_char          ; Print the character

convert_to_lower:
    add     byte [cur], 25      ; Convert 'Z' to 'a'
    jmp     print_char          ; Print the character

end:
    mov     eax, 1              ; System call number for sys_exit
    xor     ebx, ebx            ; Exit status (0)
    int     0x80                ; Call kernel to exit program