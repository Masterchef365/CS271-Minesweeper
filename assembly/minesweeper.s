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
    PERCENT_MINES equ 10

; Internal constants
    ; Field map codes
    FIELD_CLEAR equ 0
    FIELD_MINE equ 9

    ; Interactive map codes
    INTER_UNDISCOVERED equ 0
    INTER_DISCOVERED equ 1
    INTER_FLAGGED equ 2

    ; Display characters
    UNDISCOVERED_CHAR equ '-'
    FLAG_CHAR equ 'F'
    CLEAR_CHAR equ ' '
    MINE_CHAR equ '*'

    ; Kernel lengths
    FULL_AREA_KERNEL_LEN equ 8
    ADJACENT_KERNEL_LEN equ 4

; Internal variables
section .data
    rng dd 15
    FULL_AREA_KERNEL_X dd -1, 0, 1, -1, 1, -1, 0, 1
    FULL_AREA_KERNEL_Y dd -1, -1, -1, 0, 0, 1, 1, 1
    ADJACENT_KERNEL_X dd -1, 0, 0, 1
    ADJACENT_KERNEL_Y dd 0, -1, 1, 0

section .bss
    field resb (WIDTH * HEIGHT)
    interactive resb (WIDTH * HEIGHT)

section .text


; Clobbers: eax, edi, edx
; Operation: rng += 1103515245 * rng
; Notes:
;   eax is set to the value of RNG.
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

    ; field[eax] = FIELD_MINE
    mov bl, FIELD_MINE
    mov [field + eax], bl

    ret


; Generates a new map
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
            cmp edx, esi
            jge gm_clear

            ; else, place a mine at (ebx, ecx)
            push ebx
            push ecx
            call place_mine_at_xy
            pop ecx
            pop ebx
            
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


; Prints the current map
print_map:

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

            ; Write a space
            mov eax, ' '
            call WriteChar
            
            ; Write [esi]
            mov al, [esi]
            call WriteDec

        ; if (++x > WIDTH) break;
        add ebx, 1
        cmp ebx, WIDTH
        jl print_x_loop

    ; Write a newline
    call Crlf

    ; if (++y > HEIGHT) break;
    add ecx, 1
    cmp ecx, HEIGHT
    jl print_y_loop

    ret

    
main:
    call generate_map
    call print_map


stop:
    ; Exit with EXIT_SUCCESS
    mov edi, 0
    call exit
