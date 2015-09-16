
format PE64 DLL
entry DllMain

include 'include/win64a.inc'

section '.text' code readable executable

proc DllMain hinstDLL, fdwReason, lpvReserved
    mov rax, TRUE
    ret
endp

; double permute(uint32_t* array, uint32_t arrayLength)
proc permute array, arrayLength, h_heap

    ; Save parameters to stack
    mov [array], rcx
    mov [arrayLength], rdx

    ; Allocate memory for the array
    invoke HeapCreate, 0, 0, 0
    mov [h_heap], rax
    mov rax, 32
    mul edx
    invoke HeapAlloc, [h_heap], 0, rax
    
    ; Cleanup
    invoke HeapDestroy, [h_heap]

    ret
endp

;section '.data' data readable

section '.idata' import data readable writeable

library kernel32,'KERNEL32.DLL'
import kernel32,\
    HeapCreate, 'HeapCreate',\
    HeapAlloc, 'HeapAlloc',\
    HeapDestroy, 'HeapDestroy'
    
section '.edata' export data readable

export 'salesman.dll',\
permute, 'permute'

data fixups
end data
