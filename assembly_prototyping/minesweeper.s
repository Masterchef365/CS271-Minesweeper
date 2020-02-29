%include 'Along32.inc'

extern exit

global main

; Calling convention:
; SUITABLE FOR CALLING: ebx, ecx, esi
; OFTEN CLOBBERED: eax, edi, edx (ReadInt, and WriteString, div op)
; Functions that take x and y as arguments:
    ; Make sure to push x and y to the stack before calling them
    ; x = ebx, y = ecx
    ; Make sure to pop x and y back out

; Configurable constants
    ; Width and height of the map
    WIDTH equ 16
    HEIGHT equ 16
    PERCENT_MINES equ 80

; Internal constants
    ; Field map codes
    FIELD_CLEAR equ 0
    FIELD_MINE equ 9
    
    ; Interactive map codes
    INTER_UNDISCOVERED equ 0
    INTER_DISCOVERED equ 1
    INTER_FLAGGED equ 2

; Internal variables
section .data
    greeting db "Greetings, Duncan", 0x00 
    rng dd 15

section .bss
    field resb (WIDTH * HEIGHT)
    interactive resb (WIDTH * HEIGHT)

section .text


; Clobbers: eax, edi, edx
; Operation: rng += 1103515245 * rng
; Notes:
;   edx is also set to the value of RNG.
; https://stackoverflow.com/questions/3062746/special-simple-random-number-generator#3062783
advance_rng:
    mov edi, 1103515245
    mov eax, [rng]
    mul edi
    add eax, 12345
    mov [rng], eax
    ret

; Clobbers: ebx, ecx, eax
place_mine_at_xy:
    ; eax = (ecx * WIDTH) + ebx
    mov eax, WIDTH
    mul ecx
    add eax, ebx
    
    ; esi = &field[eax]
    lea esi, [field + eax]
    
    ; *esi = 1
    mov al, 1
    mov [esi], al
    ret

; Generates a new map
; Clobbers: Everything tbh
generate_map:
    ; Clear both of the arrays 
    mov ecx, WIDTH * HEIGHT
    gm_clear_loop:
        mov bl, 0
        mov [field + ecx], bl
        mov [interactive + ecx], bl
        loop gm_clear_loop
    
    
    ; Loop through all coordinates, populating it with mines
    mov ecx, 0 ; Y coord
    gm_y_loop:

        mov ebx, 0 ; X coord
        gm_x_loop:

            ; edx = rand() % 100
            call advance_rng
            mov eax, [rng]
            mov esi, 100
            mov edx, 0
            div esi

            ; if (edx >= PERCENT_MINES) jmp gm_clear
            mov esi, PERCENT_MINES
            cmp esi, edx
            jge gm_clear

            ; else, place a mine at (ebx, ecx)
            push ebx
            push ecx
            call place_mine_at_xy
            pop ecx
            pop ebx

            ; Print "x, y"
            ;mov eax, ebx
            ;call WriteDec
            ;mov eax, 0x20
            ;call WriteChar
            ;mov eax, ecx
            ;call WriteDec
            ;call Crlf
            
            gm_clear:

        ; if (++x > WIDTH) break;
        add ebx, 1
        cmp ebx, WIDTH
        jl gm_x_loop

    ; if (++y > HEIGHT) break;
    add ecx, 1
    cmp ecx, HEIGHT
    jl gm_y_loop
    ret

print_map:
    ; Loop through all coordinates, populating it with mines
    mov ecx, 0 ; Y coord
    print_y_loop:

        mov ebx, 0 ; X coord
        print_x_loop:

            ; eax = (ecx * WIDTH) + ebx
            mov eax, WIDTH
            mul ecx
            add eax, ebx
            
            ; esi = &field[eax]
            lea esi, [field + eax]
            
            ; *esi = 1
            mov al, 1
            mov [esi], al

        ; if (++x > WIDTH) break;
        add ebx, 1
        cmp ebx, WIDTH
        jl print_x_loop

    call Crlf

    ; if (++y > HEIGHT) break;
    add ecx, 1
    cmp ecx, HEIGHT
    jl print_y_loop
    ret

    
main:
    ; Align the stack pointer before C calls. THIS IS NECESSARY.
    ;mov ecx, 80
    ;mov ebx, 31
    ;lomp:
    ;    ; eax = rng % ebx
    ;    mov eax, [rng]
    ;    mov edx, 0
    ;    div ebx
    ;    mov eax, edx

    ;    call WriteDec
    ;    call Crlf
    ;    call advance_rng
    ;    loop lomp
    ;call Crlf
    call generate_map
    call print_map

stop:
    ; Exit with EXIT_SUCCESS
    mov edi, 0
    call exit
