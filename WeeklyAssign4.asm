INCLUDE Irvine32.inc

; Calling convention:
; SUITABLE FOR CALLING: ebx, ecx, esi
; OFTEN CLOBBERED: eax, edi, edx (ReadInt, and WriteString, div op)
; Functions that take x and y as arguments:
    ; Make sure to push x and y to the stack before calling them
    ; x = ebx, y = ecx
    ; Make sure to pop x and y back out

; Configurable constants
    ; MAP_WIDTH and height of the map
    MAP_WIDTH = 16
    MAP_HEIGHT = 16
    PERCENT_MINES = 10

; Internal constants
    ; Field map codes
    FIELD_CLEAR = 0
    FIELD_MINE = 9

    ; Interactive map codes
    INTER_UNDISCOVERED = 0
    INTER_DISCOVERED = 1
    INTER_FLAGGED = 2

    ; Display characters
    UNDISCOVERED_CHAR = '-'
    FLAG_CHAR = 'F'
    CLEAR_CHAR = ' '
    MINE_CHAR = '*'

    ; Kernel lengths
    FULL_AREA_KERNEL_LEN = 8
    ADJACENT_KERNEL_LEN = 4
.data
; Internal variables
    rng dd 15
    full_area_kernel_x dd -1, 0, 1, -1, 1, -1, 0, 1
    full_area_kernel_y dd -1, -1, -1, 0, 0, 1, 1, 1
    adjacent_kernel_x dd -1, 0, 0, 1
    adjacent_kernel_y dd 0, -1, 1, 0
    field BYTE (MAP_WIDTH * MAP_HEIGHT) DUP(0)
    interactive BYTE (MAP_WIDTH * MAP_HEIGHT) DUP(0)

.code
main PROC

call generate_map
mov ebx, 4
mov ecx, 5
call seed_and_grow_clear
call print_map


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
;   x >= 0 && y >= 0 && MAP_WIDTH - 1 >= x && MAP_HEIGHT - 1 >= y;
; Clobbers: eax
bounds_check:
    cmp ebx, 0
    jl bounds_check_break  
    cmp ecx, 0
    jl bounds_check_break  
    mov eax, MAP_WIDTH - 1
    cmp eax, ebx
    jl bounds_check_break  
    mov eax, MAP_HEIGHT - 1
    cmp eax, ecx
    bounds_check_break:
    ret

; Clobbers: eax, edi
place_mine_at_xy:
    ; eax = (ecx * MAP_WIDTH) + ebx
    mov eax, MAP_WIDTH
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
        add ebx, [full_area_kernel_x + edi*4]

        ; ecx += full_area_kernel_y[edi]
        add ecx, [full_area_kernel_y + edi*4]

        ; if (!bounds_check(ebx, ecx)) continue 
        call bounds_check
        jl pm_area_loop_continue

        ; eax = ecx * MAP_WIDTH + ebx
        mov eax, MAP_WIDTH
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
     jl pm_area_loop

    ret


; Generates a new map
generate_map:
    ; Clear both of the arrays 
    mov ecx, MAP_WIDTH * MAP_HEIGHT
    gm_clear_loop:
        mov [field + ecx], FIELD_CLEAR
        mov [interactive + ecx], INTER_UNDISCOVERED
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

        ; if (++x > MAP_WIDTH) break;
        add ebx, 1
        cmp ebx, MAP_WIDTH
        jl gm_x_loop

    ; if (++y > MAP_HEIGHT) break;
    add ecx, 1
    cmp ecx, MAP_HEIGHT
    jl gm_y_loop
    ret

seed_and_grow_clear:
    ; Save last position into the stack
    mov edi, 0
    seed_and_grow_adj_loop:
        push ebx
        push ecx
        push edi

        ; x, y += kernel[i]
        add ebx, [adjacent_kernel_x + edi*4]
        add ecx, [adjacent_kernel_y + edi*4]

        ; Bounds check
        call bounds_check
        jl seed_and_grow_continue

        ; position (eax) = y * WIDTH + x
        mov eax, MAP_WIDTH
        mul ecx
        add eax, ebx

        ; If the area is not undiscovered (is discovered/flagged), don't discover it
        cmp [interactive + eax], INTER_UNDISCOVERED
        jne seed_and_grow_continue

        ; If the area is a mine, continue loop
        mov dl, [field + eax]
        cmp dl, FIELD_MINE
        je seed_and_grow_continue

        ; "Discover" current location
        mov [interactive + eax], INTER_DISCOVERED

        ; If the area is not clear, don't seed-and-grow here
        cmp dl, FIELD_CLEAR
        jne seed_and_grow_continue

        call seed_and_grow_clear
        
        seed_and_grow_continue:

        pop edi
        pop ecx
        pop ebx

    add edi, 1
    cmp edi, ADJACENT_KERNEL_LEN
    jl seed_and_grow_adj_loop

    ret

write_short_hex:
    cmp eax, 10
    jl write_short_hex_int

    add eax, 'A' - 10
    call WriteChar
    ret

    write_short_hex_int:
    call WriteDec
    ret

; Prints the current map
print_map:
    mov ecx, 0
    mov eax, '-'
    call WriteChar
    mov eax, ' '
    call WriteChar
    call WriteChar
    write_x_coords:
        mov eax, ecx
        call write_short_hex
        mov eax, ' '
        call WriteChar
        inc ecx
        cmp ecx, MAP_WIDTH
        jl write_x_coords
    call CrLf
    call CrLf

    mov ecx, 0 ; Y coord
    print_y_loop:
        ; write numbers along the side
        mov eax, ecx
        call write_short_hex
        mov eax, ' '
        call WriteChar
        call WriteChar

        mov ebx, 0 ; X coord
        print_x_loop:
            ; eax = (ecx * MAP_WIDTH) + ebx
            mov edi, MAP_WIDTH
            imul edi, ecx
            add edi, ebx

            ; check interactive map for 0 or 2
            mov al, [interactive + edi]
            cmp al, INTER_UNDISCOVERED
            je print_dash
            cmp al, INTER_FLAGGED
            je F_in_the_chat

            ; case where its not 0 or 2
            mov al, [field + edi]
            cmp al, FIELD_MINE
            je print_asterisk
            cmp al, FIELD_CLEAR
            je print_space
            add al, '0'
            call im_done

            print_space:
            mov eax, CLEAR_CHAR
            jmp im_done

            print_dash:
            mov eax, UNDISCOVERED_CHAR
            jmp im_done

            F_in_the_chat:
            mov eax, FLAG_CHAR
            jmp im_done

            print_asterisk:
            mov eax, MINE_CHAR
            jmp im_done

            im_done:
            call WriteChar
            mov eax, ' '
            call WriteChar


        ; if (++x > MAP_WIDTH) break;
        add ebx, 1
        cmp ebx, MAP_WIDTH
        jl print_x_loop

    ; Write a newline
    call Crlf

    ; if (++y > MAP_HEIGHT) break;
    add ecx, 1
    cmp ecx, MAP_HEIGHT
    jl print_y_loop

    ret

  


exit

main ENDP

END main


