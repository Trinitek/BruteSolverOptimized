
format PE64 DLL
entry DllMain

include 'include/win64a.inc'
include 'salesman_defs.inc'     ; Contains loopCount definition

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
    ; loopCount is defined in 'salesman_defs.inc'
    repeat loopCount
        ; v += distances[(a * mul) + (a = array[z++])]
        addv1
        
        ; if (v > shortestDistance) return
        ucomisd shortestDistance, v
        jc return
    end repeat
        
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
proc permute s_arrayLength, h_heap
    
    ; Save nonvolatile registers, as required by the calling convention
    save_nonvolatile
    
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
    
    ; Create a handle to a new private heap
    save_volatile
    invoke HeapCreate, 0, 0, 0
    mov [h_heap], rax
    
    ; int[] p = new int[arrayLength];
    mov z, [s_arrayLength]
    shl z, 3
    invoke HeapAlloc, rax, 0x8, z
    mov i, rax                  ; Save pointer to p[] to non-volatile register
    restore_volatile
    mov p_array, i              ; p_array = p[]
    
    ; double shortestDistance = 150000.0
    movlpd shortestDistance, [const.shortest]
    
    ; Handle permutation for initial array value
    handle
    
    ; int i = 1
    mov i, 1
    
    mov p_active, p_array
    add p_active, 8             ; p_active = &p[1]
    mov rdx, [p_active]         ; rdx = p[1]
    
    ; while (i < arrayLength)
    while_1:
    
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
        
        cmp i, [s_arrayLength]
        jb while_1
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
