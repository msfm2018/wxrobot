#include <windows.h>
#include <cstdio> 
#include "fun.h"



void PatchRevokeMsg41030(ULONG_PTR PATCH_OFFSET) {
    // 将 HMODULE 转换为 DWORD_PTR 以兼容64位地址 revokemsg
    HMODULE hMod = GetModuleHandle(L"Weixin.dll"); // GetModuleHandle 返回 HMODULE，在64位下是64位的
    if (!hMod) {
        MessageBoxA(NULL, "Failed to get module handle for Weixin.dll", "Patch Error", MB_OK | MB_ICONERROR);
        return;
    }

    // 计算目标地址。使用 ULONG_PTR 或 DWORD_PTR 来存储地址，确保它是64位的
    ULONG_PTR patchAddr = (ULONG_PTR)hMod + PATCH_OFFSET;


    BYTE patch[] = { 0xB0, 0x00, 0x90, 0x90, 0x90 }; // MOV AL, 0; NOP x3

    // 修改内存保护
    DWORD oldProtect;
    if (VirtualProtect((LPVOID)patchAddr, sizeof(patch), PAGE_EXECUTE_READWRITE, &oldProtect)) {
        memcpy((void*)patchAddr, patch, sizeof(patch));
        VirtualProtect((LPVOID)patchAddr, sizeof(patch), oldProtect, &oldProtect);


    }
    else {
        // 获取错误代码
        DWORD dwError = GetLastError();
        char szErrorMsg[512]; // 增大缓冲区以容纳64位地址的十六进制表示
        sprintf_s(szErrorMsg, sizeof(szErrorMsg),
            "Failed to change memory protection!\nError Code: %lu\nWeixin.dll Base: 0x%llX\nCalculated Patch Address: 0x%llX\nOffset: 0x%llX",
            dwError, (ULONGLONG)hMod, (ULONGLONG)patchAddr, (ULONGLONG)PATCH_OFFSET);
        MessageBoxA(NULL, szErrorMsg, "Patch Error", MB_OK | MB_ICONERROR);
    }
}