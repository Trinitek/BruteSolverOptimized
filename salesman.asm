
format PE64 DLL
entry DllMain

include 'include/win64a.inc'

define shortestDistance xmm0

; --> All macro parameters are registers, not constants or pointers.
; --> rax, rbx, and rdx are volatile.
; --> Expects (double)0.0 to be defined in xmm7.
; void handle(
;   int array[], (PTR)
;   int arrayLength,
;   double distances2[], (PTR)
;   int limit,
;   int eA,
;   int mulv)
; TEMPS:
;   double v
;   int a
;   int z
;   int z2
macro handle array*, arrayLength*, distances2*, limit*, eA*, mulv*, v*, a*, z* {
    local return
    
    ; v += distances2[(a * mul) + (a = array[z + 1])]
    macro addv1 \{
        mov rax, a
        mul mulv                ; rax = a * mulv
        
        mov rbx, z2
        shl rbx, 3
        add rbx, array          ; rbx = &array[z + 1]
        
        mov a, [rbx]            ; a = array[z + 1]
        
        add rax, a              ; rax = (a * mul) + (a = array[z + 1])
        shl rax, 3
        add rax, distances2     ; rax = &distances2[rax]
        
        addsd v, [rax]          ; v += distances2[rax]
    \}
    
    ; double v = 0
    movsd v, xmm7
    
    ; int a = array[0]
    mov a, [array]
    
    ; for (int z = 0; z < 5; z++)
    xor z, z
    mov z2, z
    inc z2
    local for_1
    local for_1_end
    for_1:
        cmp z, 5
        jae for_1_end
        
        ; v += distances2[(a * mul) + (a = array[z + 1])]
        addv1
        
        inc z
        inc z2
        jmp for_1
        
        for_1_end:
    
    ; for (int z = 5; z < limit; z++)
    ; Using z and z2 values from previous loop
    local for_2
    local for_2_end
    for_2:
        cmp z, limit
        jae for_2_end
        
        ; if ((v += distances2[(a * mul) + (a = array[z + 1])]) > shortestDistance)
        local if_1
        local if_1_end
        if_1:
            ; v += distances2[(a * mul) + (a = array[z + 1])]
            addv1
            
            comisd shortestDistance, v
                                ; if v > shortestDistance then set CF
            jnc if_1_end        ; if CF is not set, escape
            jmp return
            
            if_1_end:
        
        for_2_end:

    ; if ((v += distances2[eA + array[0]]) < shortestDistance)
    local if_2
    local if_2_end
    if_2:
        ; v += distances2[eA + array[0]]
        mov rax, eA
        add rax, [array]
        shl rax, 3
        add rax, distances2
        addsd v, [rax]
    
        comisd v, shortestDistance
                                ; if v < shortestDistance then set CF
        jnc if_2_end
    
        ; if ((v += distances2[eA + array[limit]]) < shortestDistance)
        local if_3
        local if_3_end
        if_3:
            ; v += distances2[eA + array[limit]]
            mov rax, limit
            shl rax, 3
            add rax, array
            mov rax, [rax]      ; rax = array[limit]
            
            add rax, eA
            shl rax, 3
            add rax, distances2
            addsd v, [rax]
        
            comisd v, shortestDistance
                                ; if v < shortestDistance then set CF
            jnc if_3_end
            movsd shortestDistance, v
                                ; shortestDistance = v
        
            if_3_end:
    
        if_2_end:
    
    return:
}

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

; double permute(uint64_t* array, uint64_t arrayLength, double** distances, uint64_t limit)
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
    mov r8, [array]             ; r8 = array
    mov r9, 1                   ; r9 = k + 1
    for_1:
        
        mov rax, r8
        mov rax, [rax]          ; rax = *(array + r8)
        shl rax, 3
        add rax, [distances]    ; rax = &distances[array[k]]
        mov rax, [rax]          ; rax = distances[array[k]]
        
        mov rbx, r9
        shl rbx, 3
        add rbx, r8             ; rbx = &array[k + 1]
        mov rbx, [rbx]          ; rbx = array[k + 1]
        shl rbx, 3
        add rbx, rax            ; rbx = distances[array[k]][array[k + 1]]
        
        addsd xmm1, [rbx]
        ;;
        ;movsd xmm0, xmm1
        ;jmp cleanup
        ;;
    
        add r8, 8
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
        
        jmp while_1
        while_1_end:
    ; ... }
    
    ; Cleanup
    cleanup:
    movsd xmm6, xmm0                    ; Save return value in nonvolatile SSE register
    invoke HeapDestroy, [h_heap]        ; This will destroy xmm0 !!
    movsd xmm0, xmm6
    
    ; return shortestDistance
    ;
    ; If the function returns 0xFFFF instead, you are getting the integer value
    ; and not the (double) value as you should be. Check your code.
    mov rax, 0xFFFF
    ret
endp

section '.data' data readable

const:
    .zero dq 0.0
    .shortest dq 150000.0
    .test dq 1234.0

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
