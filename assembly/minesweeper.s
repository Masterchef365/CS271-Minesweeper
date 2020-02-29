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
    full_area_kernel_x dd -1, 0, 1, -1, 1, -1, 0, 1
    full_area_kernel_y dd -1, -1, -1, 0, 0, 1, 1, 1
    adjacent_kernel_x dd -1, 0, 0, 1
    adjacent_kernel_y dd 0, -1, 1, 0

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

; x = ebx, y = ecx
; Set EFLAGS so that jl jumps any of the following are unsatisfied
;   x >= 0 && y >= 0 && WIDTH - 1 >= x && HEIGHT - 1 >= y;
; Clobbers: eax
bounds_check:
    cmp ebx, 0
    jl bounds_check_break  
    cmp ecx, 0
    jl bounds_check_break  
    mov eax, WIDTH - 1
    cmp eax, ebx
    jl bounds_check_break  
    mov eax, HEIGHT - 1
    cmp eax, ecx
    bounds_check_break:
    ret

; Clobbers: eax, edi
place_mine_at_xy:
    ; eax = (ecx * WIDTH) + ebx
    mov eax, WIDTH
    mul ecx
    add eax, ebx

    ; field[eax] = FIELD_MINE
    mov dl, FIELD_MINE
    mov [field + eax], dl

    mov edi, 0 ; Loop counter for full_area_kernel_{x, y}
    pm_area_loop:
        ; We're about to clobber these two, save 'em
        push ebx
        push ecx

        ; ebx += full_area_kernel_x[edi]
        add ebx, [full_area_kernel_x + edi]

        ; ecx += full_area_kernel_y[edi]
        add ecx, [full_area_kernel_y + edi]

        ; if (!bounds_check(ebx, ecx)) continue 
        call bounds_check
        jl pm_area_loop_continue

        ; eax = ecx * WIDTH + ebx
        mov eax, WIDTH
        mul ecx
        add eax, ebx

        ; dl = field[eax]
        mov dl, [field + eax]

        ; if (dl == FIELD_MINE) continue
        cmp dl, FIELD_MINE
        je pm_area_loop_continue

        ; dl += 1
        add dl, 1

        ; field[eax] = dl
        mov [field + eax], dl

        pm_area_loop_continue:
        pop ecx
        pop ebx

     add edi, 1
     cmp edi, FULL_AREA_KERNEL_LEN
     jle pm_area_loop

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
            ; TODO: Comment out these push/pop, they're not needed!
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