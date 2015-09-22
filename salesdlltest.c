
#include <stdio.h>
#include <stdint.h>
#include <windows.h>

typedef double (*PERMUTE)(uint64_t array[], uint64_t arrayLength, double distances[]);
void testPermute(uint64_t array[], uint64_t arrayLength, double distances[]);

PERMUTE permute;
LARGE_INTEGER frequency;

int main(void) {
    
    QueryPerformanceFrequency(&frequency);
    
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
    
    permute = (PERMUTE) GetProcAddress(salesDll, "permute");
    if (permute == NULL) {
        printf("Could not find 'permute' in library: 0x%x\n", GetLastError());
        return 1;
    } else {
        printf("'permute' found at %x\n", permute);
    }
    
    uint64_t arrayLength_AB = 9;
    uint64_t array_AB[9] = {0, 1, 2, 3, 4, 5, 6, 7, 8};
	double distances_A[100] = {
        0.0, 96.17692030835673, 300.66759053812234, 273.12268305653413, 292.1711826994579, 47.92702786528704, 313.0255580619576, 312.0288448204749, 227.27076362788065, 167.59773268156107
        ,96.17692030835673, 0.0, 368.9728987337688, 233.46520083301493, 197.06344156134085, 96.21330469326995, 218.27734651126764, 286.27259736132623, 292.09929818470977, 105.01904589168576
        ,300.66759053812234, 368.9728987337688, 0.0, 342.29957639471303, 518.7957208767243, 274.87451682540524, 533.8464198624919, 322.001552791287, 77.07788269017254, 464.29516473898366
        ,273.12268305653413, 233.46520083301493, 342.29957639471303, 0.0, 235.23605165875404, 228.52789764052878, 240.3018934590404, 62.81719509815764, 282.0638225650358, 323.79777639755343
        ,292.1711826994579, 197.06344156134085, 518.7957208767243, 235.23605165875404, 0.0, 278.28941769316344, 21.840329667841555, 296.7861182737495, 444.07206622349037, 202.5660386145713
        ,47.92702786528704, 96.21330469326995, 274.87451682540524, 228.52789764052878, 278.28941769316344, 0.0, 297.89259809535383, 264.9396157617807, 198.66806487203723, 190.057885919001
        ,313.0255580619576, 218.27734651126764, 533.8464198624919, 240.3018934590404, 21.840329667841555, 297.89259809535383, 0.0, 300.647634283059, 459.76189489778295, 223.64704335179573
        ,312.0288448204749, 286.27259736132623, 322.001552791287, 62.81719509815764, 296.7861182737495, 264.9396157617807, 300.647634283059, 0.0, 272.6059427085184, 381.4249598544909
        ,227.27076362788065, 292.09929818470977, 77.07788269017254, 282.0638225650358, 444.07206622349037, 198.66806487203723, 459.76189489778295, 272.6059427085184, 0.0, 388.5678833871889
        ,167.59773268156107, 105.01904589168576, 464.29516473898366, 323.79777639755343, 202.5660386145713, 190.057885919001, 223.64704335179573, 381.4249598544909, 388.5678833871889, 0.0};
    double distances_B[100] = {0.0, 220.9886874932742, 159.38004893963358, 431.9189738828337, 133.63382805263043, 122.44182292011173, 336.0133925902359, 214.40149253211834, 449.9888887517113, 213.52751579129094, 
        220.9886874932742, 0.0, 278.18339274658365, 264.3217736017977, 118.2285921425101, 130.98091464026353, 462.8876753598004, 132.015150645674, 406.07634750130427, 13.038404810405298, 
        159.38004893963358, 278.18339274658365, 0.0, 385.70973542289545, 160.52414148656894, 248.26195842295292, 191.12561314486345, 185.60711193270586, 318.7789202566569, 278.1726082848561, 
        431.9189738828337, 264.3217736017977, 385.70973542289545, 0.0, 298.563226134767, 386.1631779442468, 503.2067169662981, 219.3855054464629, 261.0900227890756, 277.35897317375543, 
        133.63382805263043, 118.2285921425101, 160.52414148656894, 298.563226134767, 0.0, 123.00406497347964, 348.1795513811803, 84.53401682163222, 353.34402499547093, 117.66052864066182, 
        122.44182292011173, 130.98091464026353, 248.26195842295292, 386.1631779442468, 123.00406497347964, 0.0, 438.1244115545264, 198.31288409984865, 475.83400466969573, 119.33985084622823, 
        336.0133925902359, 462.8876753598004, 191.12561314486345, 503.2067169662981, 348.1795513811803, 438.1244115545264, 0.0, 350.25847598594953, 327.28733553255614, 464.5352516225222, 
        214.40149253211834, 132.015150645674, 185.60711193270586, 219.3855054464629, 84.53401682163222, 198.31288409984865, 350.25847598594953, 0.0, 282.25166075685013, 139.60659010233005, 
        449.9888887517113, 406.07634750130427, 318.7789202566569, 261.0900227890756, 353.34402499547093, 475.83400466969573, 327.28733553255614, 282.25166075685013, 0.0, 416.16342943608106, 
        213.52751579129094, 13.038404810405298, 278.1726082848561, 277.35897317375543, 117.66052864066182, 119.33985084622823, 464.5352516225222, 139.60659010233005, 416.16342943608106, 0.0};
    uint64_t arrayLength_C = 10;	
    uint64_t array_C[10] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
	double distances_C[121] = {0.0, 64.89992295835181, 75.21303078589507, 65.60487786742691, 304.85406344675806, 388.33619455312174, 357.6870140220357, 389.16577444580093, 178.02527910383964, 160.262285020525, 232.07757323791543, 
        64.89992295835181, 0.0, 137.88763541376724, 95.35197952848173, 293.97278785629123, 347.2765468614315, 296.5535364820322, 325.27219370859234, 137.5245432641025, 95.70788891204319, 180.5103875127412, 
        75.21303078589507, 137.88763541376724, 0.0, 113.07077429645558, 354.54336829223024, 422.927889834662, 419.3149174546501, 463.15979963723106, 249.30302846134862, 230.6013876801265, 284.01584462842914, 
        65.60487786742691, 95.35197952848173, 113.07077429645558, 0.0, 244.0491753725056, 441.1405671665212, 386.7453942841466, 388.5794642026261, 146.16771189288008, 181.86808406094787, 275.86228448267445, 
        304.85406344675806, 293.97278785629123, 354.54336829223024, 244.0491753725056, 0.0, 605.3304882458838, 478.23425222374027, 379.8236432872498, 179.4017837146554, 315.75306807693886, 432.3563345204971, 
        388.33619455312174, 347.2765468614315, 422.927889834662, 441.1405671665212, 605.3304882458838, 0.0, 190.06577808748213, 366.0122948754591, 426.07511074926686, 290.7455932598119, 174.1866814656046, 
        357.6870140220357, 296.5535364820322, 419.3149174546501, 386.7453942841466, 478.23425222374027, 190.06577808748213, 0.0, 177.11578134090706, 311.1735849971845, 204.9780476051033, 144.9413674559475, 
        389.16577444580093, 325.27219370859234, 463.15979963723106, 388.5794642026261, 379.8236432872498, 366.0122948754591, 177.11578134090706, 0.0, 259.83263844251746, 236.63051367057463, 264.3671689147501, 
        178.02527910383964, 137.5245432641025, 249.30302846134862, 146.16771189288008, 179.4017837146554, 426.07511074926686, 311.1735849971845, 259.83263844251746, 0.0, 136.48809471891678, 252.96047122030745, 
        160.262285020525, 95.70788891204319, 230.6013876801265, 181.86808406094787, 315.75306807693886, 290.7455932598119, 204.9780476051033, 236.63051367057463, 136.48809471891678, 0.0, 116.82465493208187, 
        232.07757323791543, 180.5103875127412, 284.01584462842914, 275.86228448267445, 432.3563345204971, 174.1866814656046, 144.9413674559475, 264.3671689147501, 252.96047122030745, 116.82465493208187, 0.0};
    
    testPermute(array_AB, arrayLength_AB, distances_A);
    testPermute(array_AB, arrayLength_AB, distances_B);
    testPermute(array_C, arrayLength_C, distances_C);
    
    return 0;
}

void testPermute(uint64_t array[], uint64_t arrayLength, double distances[]) {
    LARGE_INTEGER start, finish;
    QueryPerformanceCounter(&start);
    double i = permute(array, arrayLength, distances);
    QueryPerformanceCounter(&finish);
    printf("==============================\n");
    printf("Result: %f\n", i);
    printf("Completed in %f milliseconds\n", (double)((finish.QuadPart - start.QuadPart)*1000)/frequency.QuadPart);
    return;
}
