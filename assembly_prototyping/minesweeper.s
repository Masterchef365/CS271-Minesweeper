%include 'Along32.inc'

; Note that this is NOT MASM code, nor does it use the 
; Ievine libraries. It's just a test bed for concepts.

extern exit

global main

section .data
    greeting db "Greetings, Duncan", 0x00 
    greeting_len equ $-greeting

section .bss

section .text
    
main:
    ; Align the stack pointer before C calls. THIS IS NECESSARY.
    mov eax, 90
    call WriteInt
    call Crlf

stop:
    ; Exit with EXIT_SUCCESS
    mov edi, 0
    call exit
