
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <windows.h>

typedef double (*PERMUTE)(uint64_t array[], uint64_t arrayLength, double distances[]);
int testPermute(uint64_t array[], uint64_t arrayLength, double distances[]);

LARGE_INTEGER frequency;

int main(void) {
    
    QueryPerformanceFrequency(&frequency);
    
    uint64_t arrayLength_AB = 11;
    uint64_t array_A[11] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
	double distances_A[144] = {0.0, 242.3984323381651, 144.5856147754679, 227.79376637651873, 223.70739817896055, 130.4837154590564, 164.7573974060042, 137.44089638822936, 129.0968628588627, 295.526648544594, 289.33890163612637, 191.36614120580475, 
        242.3984323381651, 0.0, 267.5256997000475, 299.47453981933086, 378.88520688989695, 345.0811498763733, 188.52055590836773, 255.38402455909414, 370.59546678285204, 77.10382610480494, 49.47726750741192, 253.0138336138955, 
        144.5856147754679, 267.5256997000475, 0.0, 368.229547972457, 366.3495598468763, 261.22212769977966, 88.60022573334675, 278.792037189013, 217.3407462948446, 284.5434940391363, 300.12330799189857, 327.2583077631491, 
        227.79376637651873, 299.47453981933086, 368.229547972457, 0.0, 115.52056094046635, 184.62935844550833, 356.7253845747454, 90.35485598461214, 266.8107943843352, 376.3960679922148, 343.9026024908797, 48.54894437575342, 
        223.70739817896055, 378.88520688989695, 366.3495598468763, 115.52056094046635, 0.0, 118.10588469674151, 382.4682993399584, 124.02015965156633, 201.0696396774013, 452.58479868418027, 427.09483724343943, 140.03570973148243, 
        130.4837154590564, 345.0811498763733, 261.22212769977966, 184.62935844550833, 118.10588469674151, 0.0, 295.05423230314796, 121.67168939404104, 85.44003745317531, 409.48015824945657, 394.44264475332784, 175.88916964952674, 
        164.7573974060042, 188.52055590836773, 88.60022573334675, 356.7253845747454, 382.4682993399584, 295.05423230314796, 0.0, 274.3082208028042, 274.14777037211155, 196.78668654154427, 215.60148422494683, 310.46416862497995, 
        137.44089638822936, 255.38402455909414, 278.792037189013, 90.35485598461214, 124.02015965156633, 121.67168939404104, 274.3082208028042, 0.0, 192.4162155328911, 328.60006086426705, 303.99506574942956, 59.64059020499378, 
        129.0968628588627, 370.59546678285204, 217.3407462948446, 266.8107943843352, 201.0696396774013, 85.44003745317531, 274.14777037211155, 192.4162155328911, 0.0, 424.4455206501772, 418.09687872549347, 251.07170290576354, 
        295.526648544594, 77.10382610480494, 284.5434940391363, 376.3960679922148, 452.58479868418027, 409.48015824945657, 196.78668654154427, 328.60006086426705, 424.4455206501772, 0.0, 44.28317965096906, 329.6316125616595, 
        289.33890163612637, 49.47726750741192, 300.12330799189857, 343.9026024908797, 427.09483724343943, 394.44264475332784, 215.60148422494683, 303.99506574942956, 418.09687872549347, 44.28317965096906, 0.0, 298.52973051272465, 
        191.36614120580475, 253.0138336138955, 327.2583077631491, 48.54894437575342, 140.03570973148243, 175.88916964952674, 310.46416862497995, 59.64059020499378, 251.07170290576354, 329.6316125616595, 298.52973051272465, 0.0};
    uint64_t array_B[11] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
    double distances_B[144] = {0.0, 173.0, 296.346081465573, 229.26840166058645, 178.21616088334974, 122.8087944733601, 130.60245020672468, 282.3047998175022, 354.98309818919546, 259.268200904006, 153.21879780235844, 43.04648650006177, 
        173.0, 0.0, 468.8219278148154, 271.9797786601055, 346.5977495599185, 287.6751640305433, 144.5060552364502, 445.2875475465264, 520.0384601161726, 246.0995733437992, 264.9698096010185, 213.92522057952868, 
        296.346081465573, 468.8219278148154, 0.0, 410.03048667141815, 152.48606493709516, 187.8430195668713, 394.4109531947611, 97.51410154434076, 161.5239920259526, 480.7629353433977, 272.44265451650557, 254.9078264785136, 
        229.26840166058645, 271.9797786601055, 410.03048667141815, 0.0, 258.30408436569485, 314.21330334662787, 131.54847015454038, 445.9820624195552, 369.1950703896248, 81.58431221748455, 380.3682426281143, 251.33443854752576, 
        178.21616088334974, 346.5977495599185, 152.48606493709516, 258.30408436569485, 0.0, 128.08200498118384, 249.35917869611296, 195.90048494069634, 177.1383639983163, 328.29407548720707, 235.28068344001383, 147.13938969562162, 
        122.8087944733601, 287.6751640305433, 187.8430195668713, 314.21330334662787, 128.08200498118384, 0.0, 246.22144504490262, 159.70597985047397, 288.76461001999536, 363.41986737106157, 107.56393447619885, 80.2807573457052, 
        130.60245020672468, 144.5060552364502, 394.4109531947611, 131.54847015454038, 249.35917869611296, 246.22144504490262, 0.0, 400.85034613930424, 406.95208563171167, 133.60014970051492, 280.79351844371337, 167.83920876839238, 
        282.3047998175022, 445.2875475465264, 97.51410154434076, 445.9820624195552, 195.90048494069634, 159.70597985047397, 400.85034613930424, 0.0, 258.0174412709342, 507.1528369239395, 209.3895890439637, 239.42639787625757, 
        354.98309818919546, 520.0384601161726, 161.5239920259526, 369.1950703896248, 177.1383639983163, 288.76461001999536, 406.95208563171167, 258.0174412709342, 0.0, 449.87220407577973, 393.30013984233466, 323.9320916488516, 
        259.268200904006, 246.0995733437992, 480.7629353433977, 81.58431221748455, 328.29407548720707, 363.41986737106157, 133.60014970051492, 507.1528369239395, 449.87220407577973, 0.0, 412.02912518413063, 290.93126335957777, 
        153.21879780235844, 264.9698096010185, 272.44265451650557, 380.3682426281143, 235.28068344001383, 107.56393447619885, 280.79351844371337, 209.3895890439637, 393.30013984233466, 412.02912518413063, 0.0, 130.74020039758238, 
        43.04648650006177, 213.92522057952868, 254.9078264785136, 251.33443854752576, 147.13938969562162, 80.2807573457052, 167.83920876839238, 239.42639787625757, 323.9320916488516, 290.93126335957777, 130.74020039758238, 0.0};
    uint64_t arrayLength_C = 11;	
    uint64_t array_C[11] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
    double distances_C[144] = {0.0, 39.05124837953327, 158.45504094221806, 142.04224723651762, 241.6278129686233, 292.92490505247247, 127.283148923964, 160.3807968554839, 162.00308639035245, 95.26804291051643, 193.6620768245554, 213.76856644511605, 
        39.05124837953327, 0.0, 167.93153366774212, 180.87841220001906, 233.62576912660984, 327.47824355214806, 89.8443097808648, 162.00308639035245, 160.3807968554839, 71.19691004531025, 161.15210206509875, 197.40820651634522, 
        158.45504094221806, 167.93153366774212, 0.0, 185.31055015837603, 115.6027681329474, 382.12694225872116, 191.637678967368, 33.015148038438355, 320.4075529696515, 130.38404810405297, 196.51208614230322, 365.32861919099633, 
        142.04224723651762, 180.87841220001906, 185.31055015837603, 0.0, 300.0266654815868, 197.25364381932212, 265.0, 210.10949526377908, 243.28789530101986, 217.00691233230336, 318.6989174754128, 319.25068519895143, 
        241.6278129686233, 233.62576912660984, 115.6027681329474, 300.0266654815868, 0.0, 495.8275910031631, 208.90428430264421, 90.78546139112804, 393.9098881724093, 168.1071087134628, 166.68833192518306, 419.30537797648145, 
        292.92490505247247, 327.47824355214806, 382.12694225872116, 197.25364381932212, 495.8275910031631, 0.0, 416.88607556501574, 405.2024185515185, 281.60255680657446, 386.4932082197564, 486.5757906020397, 362.9931128823245, 
        127.283148923964, 89.8443097808648, 191.637678967368, 265.0, 208.90428430264421, 416.88607556501574, 0.0, 170.41420128616042, 213.71476317746513, 62.42595614005443, 80.2122185206219, 216.9469981354893, 
        160.3807968554839, 162.00308639035245, 33.015148038438355, 210.10949526377908, 90.78546139112804, 405.2024185515185, 170.41420128616042, 0.0, 320.0140621910231, 112.29425630903836, 166.43617395265971, 357.94552658190884, 
        162.00308639035245, 160.3807968554839, 320.4075529696515, 243.28789530101986, 393.9098881724093, 281.60255680657446, 213.71476317746513, 320.0140621910231, 0.0, 227.98464860599717, 293.62561196189955, 83.57032966310472, 
        95.26804291051643, 71.19691004531025, 130.38404810405297, 217.00691233230336, 168.1071087134628, 386.4932082197564, 62.42595614005443, 112.29425630903836, 227.98464860599717, 0.0, 102.20078277586722, 251.9622987670973, 
        193.6620768245554, 161.15210206509875, 196.51208614230322, 318.6989174754128, 166.68833192518306, 486.5757906020397, 80.2122185206219, 166.43617395265971, 293.62561196189955, 102.20078277586722, 0.0, 290.13100489261745, 
        213.76856644511605, 197.40820651634522, 365.32861919099633, 319.25068519895143, 419.30537797648145, 362.9931128823245, 216.9469981354893, 357.94552658190884, 83.57032966310472, 251.9622987670973, 290.13100489261745, 0.0};
    
    testPermute(array_A, arrayLength_AB, distances_A);  // = 1335
    testPermute(array_B, arrayLength_AB, distances_B);  // = 1667
    testPermute(array_C, arrayLength_C, distances_C);   // = 1504
    
    return 0;
}

int testPermute(uint64_t array[], uint64_t arrayLength, double distances[]) {
    
    const char* incName = "salesman_defs.inc";
    char dllName[128];
    char cmdLine[192];
    DWORD dllAttrib;
    STARTUPINFO cmdStartup = { sizeof(cmdStartup) };
    PROCESS_INFORMATION cmdInfo;
    HMODULE dllHandle;
    FILE* salesdef;
    PERMUTE permute;
    LARGE_INTEGER start, finish;
    double i;
    
    printf("==============================\n");
    
    sprintf(dllName, "sales_node_%d.dll\0", arrayLength + 1);
    sprintf(cmdLine, "fasm salesman.asm %s\0", dllName);
    FILE* testForDll = fopen(dllName, "r");
    if (testForDll == NULL) {
        printf("No DLL found for %d-node problems. Creating %s...\n", arrayLength + 1, dllName);
        
        salesdef = fopen(incName, "w");
        if (salesdef == NULL) {
            printf("Cannot open %s. Cannot continue.\n", incName);
            return 1;
        }
        fprintf(salesdef, "define loopCount %d", arrayLength - 6);
        fclose(salesdef);
        
        if (!CreateProcess(NULL, cmdLine, NULL, NULL, false, 0, NULL, NULL, &cmdStartup, &cmdInfo)) {
            printf("Cannot spawn FASM: %d. Cannot continue.\n", GetLastError());
            return 1;
        }
        WaitForSingleObject(cmdInfo.hProcess, INFINITE);
        CloseHandle(cmdInfo.hProcess);
        CloseHandle(cmdInfo.hThread);
    } else {
        fclose(testForDll);
    }
    
    dllHandle = LoadLibrary(dllName);
    if (dllHandle == NULL) {
        printf("Could not import %s: 0x%x. Cannot continue.\n", dllName, GetLastError());
        return 1;
    } else {
        printf("%s loaded at %x\n", dllName, dllHandle);
    }
    
    permute = (PERMUTE) GetProcAddress(dllHandle, "permute");
    if (permute == NULL) {
        printf("Could not find 'permute' in library: 0x%x\n", GetLastError());
        return 1;
    } else {
        printf("'permute' found at %x\n", permute);
    }
    
    QueryPerformanceCounter(&start);
    i = permute(array, arrayLength, distances);
    QueryPerformanceCounter(&finish);
    printf("Result: %f\n", i);
    printf("Completed in %f milliseconds\n", (double)((finish.QuadPart - start.QuadPart)*1000)/frequency.QuadPart);
    
    return 0;
}
