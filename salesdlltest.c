
#include <stdio.h>
#include <windows.h>

int main(void) {
    HMODULE salesDll = WINAPI LoadLibrary("salesman.dll");
    if (salesDll == NULL) {
        printf("Could not import SALESMAN.DLL: 0x%x\n", GetLastError());
        return 1;
    } else {
        printf("SALESMAN.DLL loaded at %x\n", salesDll);
    }
    
    FARPROC permute = WINAPI GetProcAddress(salesDll, "permute");
    if (permute == NULL) {
        printf("Could not find 'permute' in library: 0x%x\n", GetLastError());
        return 1;
    } else {
        printf("'permute' found at %x\n", permute);
    }
    
    printf("%x", permute());
    
    return 0;
}
