
format PE64 DLL
entry DllMain

include 'include/win64a.inc'

section '.text' code readable executable

proc DllMain hinstDLL, fdwReason, lpvReserved
    mov rax, TRUE
    ret
endp

; uint64_t testcall(uint64_t x)
proc testcall
    mov rax, rcx
    inc rax
    ret
endp

; double permute(uint32_t* array, uint32_t arrayLength, double** distances, uint32_t limit)
proc permute array, arrayLength, distances, limit, h_heap, p

    ; Save parameters to stack
    mov [array], rcx
    dec rdx                     ; arrayLength--
    mov [arrayLength], rdx      ; In Java, array.length represents (numberOfElements - 1)
    mov [distances], r8
    mov [limit], r9
    
    ; double r = 0.0
    movlpd xmm7, [const.zero]
    movsd xmm1, xmm7
    
    ; double shortestDistance = 150000.0
    movlpd xmm0, [const.shortest]

    ; Allocate (8 * (arrayLength + 1)) bytes for the array, initialize to NULL
    ; int[] p = new int[array.length];
    invoke HeapCreate, 0, 0, 0
    mov [h_heap], rax
    inc rdx
    shl rdx, 3
    invoke HeapAlloc, [h_heap], 0x8, rdx
    mov [p], rax
    
    ; for (int k = 0; k < limit; k++) {
    ;     r += distances[array[k]][array[k + 1]];
    ; }
    mov rcx, [limit]            ; rcx = limit
    test rcx, rcx
    jz for_1_end                ; if rcx == 0 then skip
    mov r8, [array]             ; r8 = &array[0]
    mov r9, 1                   ; r9 = k + 1
    for_1:
        
        mov rax, [array]
        add rax, r8             ; array[] = r8 + array_ptr
        
        shl rax, 3
        add rax, [distances]    ; double_array[] = (array[k] * 8)
        
        mov rbx, r9
        shl rbx, 3
        add rax, rbx            ; &double_array[k + 1] = double_array[] + (r9 * 8)
        
        addsd xmm1, [rax]
    
        add r8, 4
        inc r9
        loop for_1
        for_1_end:
        
    ; r += distances[array[0]][array.length];
    mov rax, [array]
    mov rax, [rax]              ; rax = array[0]
    shl rax, 3
    add rax, [distances]        ; rax = distances + (array[0] * 8)
    mov rax, [rax]              ; rax = *rax
    mov rbx, [arrayLength]
    ;dec rbx
    shl rbx, 3                  ; rbx = (arrayLength - 1) * 8
    add rbx, rax                ; rbx += rax
    addsd xmm1, [rbx]
    
    ; r += distances[array[limit]][array.length];
    mov rax, [limit]
    shl rax, 3
    add rax, [array]            ; rax = array + (limit * 8)
    mov rax, [rax]              ; rax = *rax
    shl rax, 3
    add rax, [distances]        ; rax = distances + *rax
    mov rax, [rax]              ; rax = *rax
    mov rbx, [arrayLength]
    ;dec rbx
    shl rbx, 3                  ; rbx = (arrayLength - 1) * 8
    add rbx, rax                ; rbx += rax
    addsd xmm1, [rbx]
    
    ; if (r < shortestDistance) {
    ;     shortestDistance = r;
    ; }
    if_1:
        comisd xmm1, xmm0       ; if xmm1 < xmm0 then set CF
        jnc if_1_end
        movsd xmm0, xmm1        ; shortestDistance = r
        if_1_end:
    
    ; int i = 1
    mov r9, 1
    
    mov r10, [array]
    mov r11, [p]
    mov r12, [arrayLength]
    mov r13, [limit]
    mov r14, [distances]
    
    ; while (i < array.length) { ...
    while_1:
        cmp r9, r12
        jae while_1_end
        
        ; if (p[i] < i) { ...
        if_2:
            mov rax, r9
            shl rax, 3
            add rax, r10        ; rax = &p[i]
            mov r15, rax        ; r15 = rax -- save for later
            mov rbx, [rax]      ; rbx = p[i]
            cmp rbx, r9
            jb else_2
        
            ; int j = i % 2 * p[i]
            mov rax, r9
            and rax, 1          ; rax = j = (i % 2)
            mul rbx             ; rax = j = (i % 2) * p[i]
            
            ; xchg array[i], array[j]
            shr rax, 3
            add rax, r10        ; rax = &array[j]
            mov rcx, [rax]      ; rcx = array[j]
            
            mov rbx, r9
            shr rbx, 3
            add rbx, r10        ; rbx = &array[i]
            mov rdx, [rbx]      ; rdx = array[i]
            
            mov [rbx], rcx      ; array[i] = array[j]
            mov [rax], rdx      ; array[j] = array[i]
            
            ; for (r = z = 0; z < limit;)
            movsd xmm1, xmm7
            xor r8, r8
            for_2:
                cmp r8, r13
                jae for_2_end
                
                ; r += distances[array[z]][array[++z]]
                mov rax, r8
                shl rax, 3
                add rax, r10    ; rax = &array[z]
                mov rax, [rax]  ; rax = array[z]
                
                shl rax, 3
                add rax, r14    ; rax = &distances[array[z]]
                mov rax, [rax]  ; rax = distances[array[z]]
                
                inc r8
                mov rbx, r8
                shl rbx, 3
                add rbx, r10    ; rbx = &array[++z]
                mov rbx, [rbx]  ; rbx = array[++z]
                
                shl rbx, 3
                add rbx, rax    ; rbx = &(distances[array[z]][array[++z]])
                
                addsd xmm1, [rbx]
                                ; r += distances[array[z]][array[++z]]
                                
                jmp for_2
                for_2_end:
            
            ; r += distances[array.length][array[0]]
            mov rax, r12
            shl rax, 3
            add rax, r14        ; rax = &distances[array.length]
            mov rax, [rax]      ; rax = distances[array.length]
            
            mov rbx, r10
            mov rbx, [rbx]
            shl rbx, 3
            add rbx, rax        ; rbx = &(distances[array.length][array[0]])
            
            addsd xmm1, [rbx]   ; r += distances[array.length][array[0]]
            
            ; r += distances[array.length][array[limit]]
            mov rbx, r13
            shl rbx, 3
            add rbx, r10        ; rbx = &array[limit]
            mov rbx, [rbx]      ; rbx = array[limit]
            
            shl rbx, 3
            add rbx, rax        ; rbx = &(distances[array.length][array[limit]])
            
            addsd xmm1, [rbx]   ; r += distances[array.length][array[limit]]
            
            ; if (r < shortestDistance) {
            ;     shortestDistance = r
            ; }
            if_3:
                comisd xmm1, xmm0       ; if xmm1 < xmm0 then set CF
                jnc if_3_end
                movsd xmm0, xmm1        ; shortestDistance = r
                if_3_end:
            
            ; p[i]++
            inc qword [r15]
            
            ; i = 1
            mov r9, 1
            
            if_2_end:
            jmp else_2_end
        ; ... }
        ; else { ...
        else_2:
            ; p[i] = 0
            ; i++
            xor rbx, rbx
            mov [rax], rbx
            inc r9
            
            else_2_end:
        ; ... }
        
        while_1_end:
    ; ... }
    
    ; Cleanup
    invoke HeapDestroy, [h_heap]
    
    ; return shortestDistance
    ret
endp

section '.data' data readable

const:
    .zero dq 0.0
    .shortest dq 150000.0

section '.idata' import data readable writeable

library kernel32,'KERNEL32.DLL'
import kernel32,\
    HeapCreate, 'HeapCreate',\
    HeapAlloc, 'HeapAlloc',\
    HeapDestroy, 'HeapDestroy'
    
section '.edata' export data readable

export 'salesman.dll',\
    permute, 'permute',\
    testcall, 'testcall'

data fixups
end data
