
format PE64 DLL
entry DllMain

include 'include/win64a.inc'

define array            rcx
define arrayLength      r9
define distances        r8
define mulv             r13
define limit            r10
define eA               rbx
define a                r11
define z                r12
define p_array          r14
define p_active         rsi
define i                r15
define v                xmm1
define shortestDistance xmm0

macro save_volatile {
    push rax
    push rcx
    push rdx
    push r8
    push r9
    push r10
    push r11
    movsd xmm6, xmm0
    movsd xmm7, xmm1
}

macro restore_volatile {
    movsd xmm1, xmm7
    movsd xmm0, xmm6
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rax
}

macro save_nonvolatile {
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    movlpd [rsp], xmm6
    sub rsp, 8
    movlpd [rsp], xmm7
}

macro restore_nonvolatile {
    movlpd xmm7, [rsp]
    add rsp, 8
    movlpd xmm6, [rsp]
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
}

; --> All macro parameters are registers, not constants or pointers.
; --> rax and rdx are volatile.
; --> Expects (double)0.0 to be defined in xmm7.
macro handle {
    local return
    
    ; v += distances[(a * mul) + (a = array[z + 1])]
    macro addv1 \{
        mov rax, a
        mul mulv                ; rax = a * mulv
        
        mov rdx, z
        inc rdx
        shl rdx, 3
        add rdx, array          ; rdx = &array[z + 1]
        
        mov a, [rdx]            ; a = array[z + 1]
        
        add rax, a              ; rax = (a * mul) + (a = array[z + 1])
        shl rax, 3
        add rax, distances      ; rax = &distances[rax]
        
        addsd v, [rax]          ; v += distances[rax]
    \}
    
    ; double v = 0
    movsd v, xmm7
    
    ; int a = array[0]
    mov a, [array]
    
    ; for (int z = 0; z < 5; z++)
    xor z, z
    local for_1
    local for_1_end
    for_1:
        cmp z, 5
        jae for_1_end
        
        ; v += distances[(a * mul) + (a = array[z + 1])]
        addv1
        
        inc z
        jmp for_1
        
        for_1_end:
    
    ; for (int z = 5; z < limit; z++)
    ; Using z value from previous loop
    local for_2
    local for_2_end
    for_2:
        cmp z, limit
        jae for_2_end
        
        ; if ((v += distances[(a * mul) + (a = array[z + 1])]) > shortestDistance)
        local if_1
        local if_1_end
        if_1:
            ; v += distances[(a * mul) + (a = array[z + 1])]
            addv1
            
            comisd shortestDistance, v
                                ; if v > shortestDistance then set CF
            jnc if_1_end        ; if CF is not set, escape
            jmp return
            
            if_1_end:
        
        inc z
        jmp for_2
        
        for_2_end:
        
    ; if ((v += distances[eA + array[0]]) < shortestDistance)
    local if_2
    local if_2_end
    if_2:
        ; v += distances[eA + array[0]]
        mov rax, eA
        add rax, [array]
        shl rax, 3
        add rax, distances
        addsd v, [rax]
    
        comisd v, shortestDistance
                                ; if v < shortestDistance then set CF
        jnc if_2_end
    
        ; if ((v += distances[eA + array[limit]]) < shortestDistance)
        local if_3
        local if_3_end
        if_3:
            ; v += distances[eA + array[limit]]
            mov rax, limit
            shl rax, 3
            add rax, array
            mov rax, [rax]      ; rax = array[limit]
            
            add rax, eA
            shl rax, 3
            add rax, distances  ; rax = &distances[eA + array[limit]]
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

; double permute(uint64_t* array, uint64_t arrayLength, double* distances)
proc permute s_array, s_arrayLength, s_distances, h_heap, p
    
    ; Save nonvolatile registers, as required by the calling convention
    save_nonvolatile
    
    ; Initialize registers
    mov arrayLength, rdx        ; Move parameter out of volatile register
    mov mulv, arrayLength
    inc mulv                    ; mulv = arrayLength + 1
    mov limit, arrayLength
    dec limit                   ; limit = arrayLength - 1 = mul - 2
    mov rax, arrayLength
    mul mulv
    mov eA, rax                 ; eA = arrayLength * mulv
    
    movlpd xmm7, [const.zero]   ; Load 0.0 constant into a secondary SSE register
    
    ; double shortestDistance = 150000.0
    movlpd shortestDistance, [const.shortest]
    
    ; Handle permutation for initial array value
    handle

    ; Allocate (8 * (arrayLength)) bytes for the array, initialize to NULL
    ; int[] p = new int[array.length];
    save_volatile
    invoke HeapCreate, 0, 0, 0
    mov [h_heap], rax
    mov rdx, arrayLength
    shl rdx, 3
    invoke HeapAlloc, [h_heap], 0x8, rdx
    mov p_array, rax
    restore_volatile
    
    ; int i = 1
    mov i, 1
    
    ; while (i < arrayLength)
    while_1:
        cmp i, arrayLength
        jae while_1_end
        
        mov p_active, i
        shl p_active, 3
        add p_active, p_array   ; p_active = p[i]
        
        ; while (p[i] < i)
        while_2:
            cmp p_active, i
            jae while_2_end
            
            ; int j = i % 2 * p[i]
            mov rax, i
            and rax, 1          ; rax = i % 2
            mul qword [p_active]; rax *= *p_active
            
            ; xchg(array[i], array[j])
            shl rax, 3
            add rax, array      ; rax = &array[j]
            mov rdi, [rax]      ; rdi = array[j]
            
            mov rdx, i
            shl rdx, 3
            add rdx, array      ; rdx = &array[i]
            
            push rdi            ; save rdi
            mov rdi, [rdx]      ; rdi = array[i]
            mov [rax], rdi      ; array[j] = rdi
            
            pop rdi             ; restore rdi
            mov [rdx], rdi      ; array[i] = rdi
        
            ; Handle permutation
            handle
        
            ; p[i]++
            inc qword [p_active]
            
            ; i = 1
            mov i, 1
            
            jmp while_2
            while_2_end:
        
        ; p[i++] = 0
        inc i
        add p_active, 8
        xor rax, rax
        mov [p_active], rax
        
        jmp while_1
        while_1_end:
    
    ; Cleanup
    cleanup:
    save_volatile
    invoke HeapDestroy, [h_heap]
    restore_volatile
    
    ; return shortestDistance
    ;
    ; If the function returns 0xFFFF instead, you are getting the integer value
    ; and not the (double) value as you should be. Check your code.
    mov rax, 0xFFFF
    restore_nonvolatile
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
