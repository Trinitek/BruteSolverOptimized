
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
proc permute array, arrayLength, distances, limit, h_heap, temp

    ; Save parameters to stack
    mov [array], rcx
    mov [arrayLength], rdx
    mov [distances], r8
    mov [limit], r9
    
    ; double r = 0.0
    movlpd xmm1, [const.zero]
    
    ; double shortestDistance = 150000.0
    movlpd xmm0, [const.shortest]

    ; Allocate (4 * arrayLength) bytes for the array
    ; int[] p = new int[array.length];
    invoke HeapCreate, 0, 0, 0
    mov [h_heap], rax
    mov rax, 4
    mul edx
    invoke HeapAlloc, [h_heap], 0, rax
    
    ; for (int k = 0; k < limit; k++) {
    ;     r += distances[array[k]][array[k + 1]];
    ; }
    mov rcx, [limit]            ; rcx = limit
    test rcx, rcx
    jz for_1.end                 ; if rcx == 0 then skip
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
        .end:
        
    ; r += distances[array[0]][array.length];
    mov rax, [array]
    mov rax, [rax]              ; rax = array[0]
    shl rax, 3
    add rax, [distances]        ; rax = distances + (array[0] * 8)
    mov rax, [rax]              ; rax = *rax
    mov rbx, [arrayLength]
    dec rbx
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
    dec rbx
    shl rbx, 3                  ; rbx = (arrayLength - 1) * 8
    add rbx, rax                ; rbx += rax
    addsd xmm1, [rbx]
    
    ; if (r < shortestDistance) {
    ;     shortestDistance = r;
    ; }
    if_1:
        movsd xmm2, xmm1
        comisd xmm2, xmm0
        jnc .end
        movsd xmm0, xmm1
        .end:
    
    ; Cleanup
    invoke HeapDestroy, [h_heap]
    
    ;; testing return value
    movsd xmm0, [const.shortest]
    
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
