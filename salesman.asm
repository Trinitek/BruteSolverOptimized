
format PE64 DLL
entry DllMain

include 'include/win64a.inc'

define array            r14
define distances        r8
define mulv             r13
define limit            r10
define eA               rbx
define a                r11
define z                r12
define p_array          r9
define p_active         rsi
define i                r15
define v                xmm1
define shortestDistance xmm0

macro save_nonvolatile {
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
}

macro restore_nonvolatile {
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
}

; --> All macro parameters are registers, not constants or pointers.
; --> rax, rcx, and rdx are volatile.
macro handle {
    local return
    
    ; v += distances[(a * mul) + (a = array[z++])]
    macro addv1 \{
        mov rax, a
        mul mulv                ; rax = a * mulv
        
        mov rdx, z
        shl rdx, 3
        add rdx, array          ; rdx = &array[z]
        
        mov a, [rdx]            ; a = array[z]
        
        add rax, a              ; rax = (a * mul) + (a = array[z])
        shl rax, 3
        add rax, distances      ; rax = &distances[rax]
        
        addsd v, [rax]          ; v += distances[rax]
        
        inc z                   ; z++
    \}
    
    ; double v = 0
    xorpd v, v
    
    ; int a = array[0]
    mov a, [array]
    
    ; for (int z = 1; z <= 5; z++)
    mov z, 1
    repeat 5
        ; v += distances[(a * mul) + (a = array[z++])]
        addv1
    end repeat
    
    ; for (; z <= limit; z++)
    ; Using z value from previous loop
    local for_1
    local for_1_end
    for_1:
        ; if ((v += distances[(a * mul) + (a = array[z++])]) > shortestDistance)
        local if_1
        local if_1_end
        if_1:
            ; v += distances[(a * mul) + (a = array[z++])]
            addv1
            
            ucomisd shortestDistance, v
                                ; if v > shortestDistance then set CF
            jc return           ; if CF is set, return
            
            if_1_end:
        
        cmp z, limit
        jbe for_1
        
        for_1_end:
        
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
    
        ucomisd v, shortestDistance
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
        
            ucomisd v, shortestDistance
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

; double permute(uint64_t* array, uint64_t arrayLength, double* distances, LPVOID heap_ptr)
proc permute s_arrayLength
    
    ; Save nonvolatile registers, as required by the calling convention
    save_nonvolatile
    
    nop                         ; This boosts speed somehow. Alignment black magic?
    
    ; Initialize registers
    mov array, rcx              ; Move parameters out of volatile registers
    mov [s_arrayLength], rdx    ; ...
    mov mulv, rdx
    inc mulv                    ; mulv = arrayLength + 1
    mov limit, rdx
    dec limit                   ; limit = arrayLength - 1 = mul - 2
    mov rax, rdx
    mul mulv
    mov eA, rax                 ; eA = arrayLength * mulv
    
    ; Prefetch array[] into CPU cache
    mov rcx, [s_arrayLength]
    shl rcx, 8
    prefetchArray:
        mov rax, array
        prefetchnta [rax]
        inc rax
        loop prefetchArray
        prefetchArray_end:
    
    ; double shortestDistance = 150000.0
    movlpd shortestDistance, [const.shortest]
    
    ; Handle permutation for initial array value
    handle
    
    ;;;
    ;jmp $
    ;;;
    
    ; int i = 1
    mov i, 1
    
    mov p_active, p_array
    add p_active, 8             ; p_active = &p[1]
    mov rdx, [p_active]         ; rdx = p[1]
    
    ; while (i < arrayLength)
    while_1:
        cmp i, [s_arrayLength]
        jae while_1_end
        
        ; while (p[i] < i)
        while_2:
            cmp rdx, i          ; if (p[i] < i) goto while_2_end
            jae while_2_end
            
            ; int j = i % 2 * p[i]
            mov rax, i
            and rax, 1          ; rax = i % 2
            mul rdx             ; rax *= p[i]
            
            ; xchg(array[i], array[j])
            shl rax, 3
            add rax, array      ; rax = &array[j]
            mov rdi, [rax]      ; rdi = array[j]
            
            mov rdx, i
            shl rdx, 3
            add rdx, array      ; rdx = &array[i]
            mov rcx, [rdx]
            
            mov [rax], rcx      ; array[j] = rcx = array[i]
            mov [rdx], rdi      ; array[i] = rdi = array[j]
        
            ; Handle permutation
            handle
        
            ; p[i]++
            inc qword [p_active]
            
            ; i = 1
            mov i, 1
            
            mov p_active, p_array
            add p_active, 8     ; p_active = &p[1]
            mov rdx, [p_active] ; rdx = p[1]
            
            jmp while_2
            while_2_end:
        
        ; p[i++] = 0
        inc i
        xor rax, rax
        mov [p_active], rax
        
        mov p_active, i
        shl p_active, 3
        add p_active, p_array
        mov rdx, [p_active]     ; rdx = p[i]
        
        jmp while_1
        while_1_end:
    
    ; Cleanup
    cleanup:
    
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
    .shortest dq 150000.0

;section '.idata' import data readable writeable
;
;library kernel32,'KERNEL32.DLL'
;import kernel32,\
;    HeapCreate, 'HeapCreate',\
;    HeapAlloc, 'HeapAlloc',\
;    HeapDestroy, 'HeapDestroy'
    
section '.edata' export data readable

export 'salesman.dll',\
    permute, 'permute',\
    testcall, 'testcall'

data fixups
end data
