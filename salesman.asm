
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

; v += distances[(a * mul) + (a = array[z++])]
macro addv1 {
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
}

macro m_handle_for_limit {
    addv1
    ucomisd shortestDistance, v
    jc near @f
}

; --> All macro parameters are registers, not constants or pointers.
; --> rax, rcx, and rdx are volatile.
macro m_handle_pre {
    ; global handle_ret = @@
    local start
    start:
    
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
    
    ; Duplicate handle_for_limit here!!
    
}

macro m_handle_post {
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
    
    @@:
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
proc permute s_arrayLength, h_heap, init_handle_ptr, while_ptr
    
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
    
    ; double shortestDistance = 150000.0
    movlpd shortestDistance, [const.shortest]
    
    ; Create handle to heap, execution enabled
    mov i, limit                ; Move limit into non-volatile register
    save_volatile
    invoke HeapCreate, 0x40000, 0, 0
    mov [h_heap], rax
    
    ; int[] p = new int[array.length];
    mov z, [s_arrayLength]
    shl z, 3
    invoke HeapAlloc, rax, 0x8, z
    mov i, rax                  ; Save pointer to p[] to non-volatile register
    
    ; char* init_handle_ptr =
    ;     malloc(
    ;         (handle_pre_end - handle_pre) +
    ;         (handle_for_limit_end - handle_for_limit) * (limit - 5) +
    ;         (handle_post_end - handle_post_end)
    ;     );
    mov rax, i                  ; i == limit
    sub rax, 5
    mov rdx, handle_for_limit_end - handle_for_limit
    mul rdx
    add rax, handle_pre_end - handle_pre
    add rax, handle_post_end - handle_post + 1
    push rax                    ; +1 for the RET instruction
    invoke HeapAlloc, [h_heap], 0, rax
    mov [init_handle_ptr], rax
    pop rax                     ; Size of expanded handle function preserved
    
    ; char* while_ptr =
    ;     malloc(
    ;         (handle_pre_end - handle_pre) +
    ;         (handle_for_limit_end - handle_for_limit) * (limit - 5) +
    ;         (handle_post_end - handle_post_end) +
    ;         (mainLoop_pre_end - mainLoop_pre) +
    ;         (mainLoop_post_end - mainLoop_post)
    ;     );
    add rax, mainLoop_pre_end - mainLoop_pre + mainLoop_post_end - mainLoop_post - 1
                                ; -1, no additional RET instruction
    invoke HeapAlloc, [h_heap], 0, rax
    mov [while_ptr], rax
    
    restore_volatile
    mov p_array, i              ; Restore pointer to p[] from non-volatile register

    ; String-copy handle function to heap
    push rsi
    push rdi                    ; Preserve pointer registers
    pushfq                      ; Preserve RFLAGS
    
    cld                         ; Increment pointers
    
    mov rdi, [init_handle_ptr]
    mov rsi, handle_pre
    mov rcx, handle_pre_end - handle_pre
    rep movsb                   ; Copy handle_pre
    
    mov rcx, limit
    sub rcx, 5
    copyLimit_1:
        push rcx
        
        mov rsi, handle_for_limit
        mov rcx, handle_for_limit_end - handle_for_limit
        rep movsb               ; Copy handle_for_limit (limit - 5) times
        
        pop rcx
        loop copyLimit_1
    
    mov rsi, handle_post
    mov rcx, handle_post_end - handle_post
    rep movsb                   ; Copy handle_post
    
    mov [rdi], byte 0xC3        ; 0xC3 == "ret near" instruction
    
    ; String-copy main loop to heap
    mov rdi, [while_ptr]
    mov rsi, mainLoop_pre
    mov rcx, mainLoop_pre_end - mainLoop_pre
    rep movsb                   ; Copy mainLoop_pre
    
    mov rsi, handle_pre
    mov rcx, handle_pre_end - handle_pre
    rep movsb                   ; Copy handle_pre
    
    mov rcx, limit
    sub rcx, 5
    copyLimit_2:
        push rcx
        
        mov rsi, handle_for_limit
        mov rcx, handle_for_limit_end - handle_for_limit
        rep movsb               ; Copy handle_for_limit (limit - 5) times
        
        pop rcx
        loop copyLimit_2
    
    mov rsi, handle_post
    mov rcx, handle_post_end - handle_post
    rep movsb                   ; Copy handle_post
    
    mov rsi, mainLoop_post
    mov rcx, mainLoop_post_end - mainLoop_post
    rep movsb                   ; Copy mainLoop_post
    
    ; Recalculate near jump offsets in main loop
    ; jae near while_2_end
    ; 0F 83 ?? ?? ?? ??
    ; 32-bit signed offset
    mov rdi, [while_ptr]
    add rdi, jmp_1 - mainLoop_pre ; rdi = first jump instruction
    
    mov rcx, [while_ptr]
    add rcx, handle_pre_end - mainLoop_pre + while_2_end - handle_post
    mov rax, limit
    sub rax, 5
    mov rdx, handle_for_limit_end - handle_for_limit
    mul rdx                     ; rax = size of for_limit * (limit - 5)
    add rcx, rax                ; rcx = while_2_end
    
    sub rcx, rdi                ; rcx = difference between the two
    sub rcx, 6                  ; Account for instruction length
    
    add rdi, 2
    mov [rdi], dword ecx        ; ?? ?? ?? ?? = offset
    
    ; jmp near while_2
    ; E9 ?? ?? ?? ??
    ; 32-bit signed offset
    mov rdi, [while_ptr]
    add rdi, handle_pre_end - mainLoop_pre + jmp_2 - handle_post
    add rdi, rax                ; rdi = second jump instruction
    
    mov rcx, [while_ptr]
    add rcx, while_2 - mainLoop_pre
                                ; rcx = while_2
    sub rcx, rdi                ; rcx = difference between the two
    sub rcx, 5                  ; Account for instruction length
    
    inc rdi
    mov [rdi], dword ecx        ; ?? ?? ?? ?? = offset
    
    ; jb near while_1
    ; 0F 82 ?? ?? ?? ??
    ; 32-bit signed offset
    mov rdi, [while_ptr]
    add rdi, handle_pre_end - mainLoop_pre + jmp_3 - handle_post
    add rdi, rax                ; rdi = third jump instruction
    
    mov rcx, [while_ptr]
    add rcx, while_1 - mainLoop_pre
                                ; rcx = while_1
    sub rcx, rdi                ; rcx = difference between the two
    sub rcx, 6                  ; Account for instruction length
    
    add rdi, 2
    mov [rdi], dword ecx        ; ?? ?? ?? ?? = offset
    
    ; Recalculate near jump offsets in handle_for_limit
    ; jc near @f (end of handle())
    ; 0F 82 ?? ?? ?? ??
    ; 32-bit signed offset
    mov rdi, [while_ptr]
    add rdi, handle_for_limit_end - mainLoop_pre - 4
                                ; rdi = jump instruction + 2
    mov rdx, [while_ptr]
    add rdx, handle_pre_end - mainLoop_pre + handle_post_end - handle_post
    add rdx, rax                ; rdx = end of handle()
    
    mov rcx, limit
    sub rcx, 5
    calcLimit_1:
        push rcx
        mov rcx, rdx
        sub rcx, rdi
        sub rcx, 4              ; Account for instruction length
        mov [rdi], dword ecx    ; ?? ?? ?? ?? = offset
        add rdi, handle_for_limit_end - handle_for_limit
        pop rcx                 ; Point to next jump instruction
        loop calcLimit_1
    
    ; Recalculate near jump offsets in initial handle call
    ; jc near @f (end of handle())
    ; 0F 82 ?? ?? ?? ??
    ; 32-bit signed offset
    mov rdi, [init_handle_ptr]
    add rdi, handle_for_limit_end - handle_pre - 4
                                ; rdi = jump instruction + 2
    mov rdx, [init_handle_ptr]
    add rdx, handle_pre_end - handle_pre + handle_post_end - handle_post
    add rdx, rax                ; rdx = end of handle()
    
    mov rcx, limit
    sub rcx, 5
    calcLimit_2:
        push rcx
        mov rcx, rdx
        sub rcx, rdi
        sub rcx, 4              ; Account for instruction length
        mov [rdi], dword ecx    ; ?? ?? ?? ?? = offset
        add rdi, handle_for_limit_end - handle_for_limit
        pop rcx                 ; Point to next jump instruction
        loop calcLimit_2
    
    popfq                       ; Restore RFLAGS
    pop rdi
    pop rsi                     ; Restore pointer registers
    
    ; Handle permutation for initial array value
    call near [init_handle_ptr]
    
    ; Execute main loop
    call near [while_ptr]
    
    ; Cleanup
    cleanup:
    save_volatile
    invoke HeapDestroy, [h_heap]
    restore_volatile
    
    ; return shortestDistance
    ;
    ; If the function returns 0xFFFF instead, you are getting the integer value
    ; and not the (double) value as you should be. Check your code.
    return:
    mov rax, 0xFFFF
    restore_nonvolatile
    
    ret
endp

section '.data' data readable

const:
    .shortest dq 150000.0
    
; --> Copy these to the heap and invoke this one with CALL NEAR
mainLoop_pre:
    ; int i = 1
    mov i, 1
    
    mov p_active, p_array
    add p_active, 8             ; p_active = &p[1]
    mov rdx, [p_active]         ; rdx = p[1]
    
    ; while (i < arrayLength)
    while_1:
    
        ; while (p[i] < i)
        while_2:
            cmp rdx, i          ; if (p[i] > i) goto while_2_end
            jmp_1:
                jae near while_2_end
            
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
            mov z, [rdx]
            
            mov [rax], z        ; array[j] = z = array[i]
            mov [rdx], rdi      ; array[i] = rdi = array[j]
        
            ; Handle permutation
            ; (insert handle call after here)
mainLoop_pre_end:

handle_pre:
    m_handle_pre
handle_pre_end:

handle_for_limit:
    m_handle_for_limit
handle_for_limit_end:

handle_post:
    m_handle_post
handle_post_end:

mainLoop_post:
            ; (insert handle call before here)
            
            ;p[i]++
            inc qword [p_active]
            
            ;i = 1
            mov i, 1
            
            mov p_active, p_array
            add p_active, 8     ; p_active = &p[1]
            mov rdx, [p_active] ; rdx = p[1]
            
            jmp_2:
                jmp near while_2
            while_2_end:
        
        ; p[i++] = 0
        inc i
        xor rax, rax
        mov [p_active], rax
        
        mov p_active, i
        shl p_active, 3
        add p_active, p_array
        mov rdx, [p_active]     ; rdx = p[i]
        
        cmp i, [rbp + 0x10]     ;cmp i, [s_arrayLength]
        jmp_3:
            jb near while_1
        while_1_end:
        
    ret                         ; Return from CALL procedure
mainLoop_post_end:

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
