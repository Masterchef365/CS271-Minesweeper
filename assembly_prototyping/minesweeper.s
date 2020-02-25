; Note that this is NOT MASM code, nor does it use the 
; Irvine libraries. It's just a test bed for concepts.

extern exit
extern printf
extern scanf
extern puts
extern putchar

; C x64 calling convention, in order:
; rdi, rsi, rdx, rcx, r8, r9
; return rax

global main

section .data
    greeting db "Greetings, Duncan", 0x00 
    format_int db "%i", 0

section .bss
    outbuf resd 1

section .text
    
main:
    ; Align the stack pointer before C calls. THIS IS NECESSARY.
    sub rsp, 8

    ; Print a greeting
    mov edi, greeting
    call puts

    ; Read an integer
    mov rdi, format_int
    mov rsi, outbuf
    mov al, 0
    call scanf

    ; Write an integer
    mov rdi, format_int
    mov rsi, [outbuf]
    call printf

    ; Write a newline
    mov rdi, 0x0A
    call putchar

    ; Pop the garbage stack alloc used for alignment
    add rsp, 8

stop:
    ; Exit with EXIT_SUCCESS
    mov edi, 0
    call exit
