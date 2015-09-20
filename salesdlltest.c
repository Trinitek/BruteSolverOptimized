
#include <stdio.h>
#include <stdint.h>
#include <windows.h>
#include <time.h>

int main(void) {
    
    typedef double (*PERMUTE)(uint64_t array[], uint64_t arrayLength, double* distances[]);
    
    HMODULE salesDll = WINAPI LoadLibrary("salesman.dll");
    if (salesDll == NULL) {
        printf("Could not import SALESMAN.DLL: 0x%x\n", GetLastError());
        return 1;
    } else {
        printf("SALESMAN.DLL loaded at %x\n", salesDll);
    }
    
    FARPROC testcall = WINAPI GetProcAddress(salesDll, "testcall");
    if (testcall == NULL) {
        printf("Could not find 'testcall' in library: 0x%x\n", GetLastError());
        return 1;
    } else {
        printf("'testcall' found at %x\n", testcall);
    }
    printf("testcall(34) returns %d\n", (uint64_t)testcall(34));
    
    PERMUTE permute = (PERMUTE) GetProcAddress(salesDll, "permute");
    if (permute == NULL) {
        printf("Could not find 'permute' in library: 0x%x\n", GetLastError());
        return 1;
    } else {
        printf("'permute' found at %x\n", permute);
    }
    
    uint64_t arrayLength = 4;
    uint64_t array[4] = {0, 1, 2, 3};
    double dist_1[2] = {4.0, 5.0};
    double dist_2[2] = {5.0, 4.0};
    double dist_3[2] = {7.0, 9.0};
    double dist_4[2] = {6.0, 2.0};
    double* distances[4] = {dist_1, dist_2, dist_3, dist_4};
    
    clock_t start, finish;
    start = clock();
    double i = permute(array, arrayLength, distances);
    finish = clock();
    
    printf("Result: %f\n", i);
    printf("Completed in %f milliseconds\n", (double) (finish - start));
    
    return 0;
}
