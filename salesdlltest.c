
#include <stdio.h>
#include <stdint.h>
#include <windows.h>

int main(void) {
    
    typedef double (*PERMUTE)(uint64_t array[], uint64_t arrayLength, double* distances[], uint64_t limit);
    
    HMODULE salesDll = WINAPI LoadLibrary("salesman.dll");
    if (salesDll == NULL) {
        printf("Could not import SALESMAN.DLL: 0x%x\n", GetLastError());
        return 1;
    } else {
        printf("SALESMAN.DLL loaded at %x\n", salesDll);
    }
    
    PERMUTE permute = (PERMUTE) GetProcAddress(salesDll, "permute");
    if (permute == NULL) {
        printf("Could not find 'permute' in library: 0x%x\n", GetLastError());
        return 1;
    } else {
        printf("'permute' found at %x\n", permute);
    }
    
    uint64_t arrayLength = 2;
    uint64_t array[2] = {1, 2};
    double dist_1[2] = {4.0, 5.0};
    double dist_2[2] = {8.0, 9.0};
    double* distances[2] = {dist_1, dist_2};
    uint64_t limit = 2;
    
    double i = permute(array, arrayLength, distances, limit);
    
    printf("%f\n", i);
    
    FARPROC testcall = WINAPI GetProcAddress(salesDll, "testcall");
    if (permute == NULL) {
        printf("Could not find 'testcall' in library: 0x%x\n", GetLastError());
        return 1;
    } else {
        printf("'testcall' found at %x\n", testcall);
    }
    printf("%d\n", (uint64_t)testcall(34));
    
    return 0;
}
