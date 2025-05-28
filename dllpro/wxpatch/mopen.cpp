
#include <windows.h>
#include <cstdio>
//多开 内存补丁 不起作用
void PatchWeChatMultiInstance(ULONG_PTR PATCH_OFFSET, ULONG_PTR JUMP_OFFSET) {
    // 获取 Weixin.dll 的模块句柄
    HMODULE hMod = GetModuleHandle(L"Weixin.dll");
    if (!hMod) {
        MessageBoxA(NULL, "无法获取 Weixin.dll 的模块句柄！", "补丁错误", MB_OK | MB_ICONERROR);
        return;
    }

    // --- 补丁 1：互斥锁检查（0x89ED7） ---
    // 计算互斥锁补丁地址
    ULONG_PTR mutexPatchAddr = (ULONG_PTR)hMod + PATCH_OFFSET;
    ULONG_PTR targetAddr = (ULONG_PTR)hMod + JUMP_OFFSET;
    LONG relativeOffset = (LONG)(targetAddr - (mutexPatchAddr + 5)); // jmp 指令长度为 5

    // 构造互斥锁补丁：jmp 指令 (5 字节) + 7 个 NOP (共 12 字节)
    BYTE mutexPatch[] = {
        0xE9, 0x00, 0x00, 0x00, 0x00, // jmp 指令
        0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 // 7 个 NOP
    };
    memcpy(mutexPatch + 1, &relativeOffset, sizeof(LONG));

    // NOP 补丁 (12 字节)
    BYTE nopPatch[] = { 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 };

    // --- 补丁 2：窗口检查（0x89F34） ---
    ULONG_PTR windowPatchAddr = (ULONG_PTR)hMod + 0x89F34;
    BYTE windowPatch[] = { 0x31, 0xC0, 0x90, 0x90, 0x90 }; // xor eax, eax; nop; nop; nop

    // 修改内存保护
    DWORD oldProtect;
    bool mutexSuccess = false, windowSuccess = false;
    char szErrorMsg[512];

    // 补丁互斥锁检查
    if (VirtualProtect((LPVOID)mutexPatchAddr, sizeof(nopPatch), PAGE_EXECUTE_READWRITE, &oldProtect)) {
        // 先写入 NOP
        memcpy((void*)mutexPatchAddr, nopPatch, sizeof(nopPatch));
        // 再写入 jmp 补丁
        memcpy((void*)mutexPatchAddr, mutexPatch, sizeof(mutexPatch));
        VirtualProtect((LPVOID)mutexPatchAddr, sizeof(nopPatch), oldProtect, &oldProtect);
        mutexSuccess = true;
    }
    else {
        DWORD dwError = GetLastError();
        sprintf_s(szErrorMsg, sizeof(szErrorMsg),
            "无法修改互斥锁补丁内存保护！\n错误代码: %lu\n补丁地址: 0x%llX", dwError, (ULONGLONG)mutexPatchAddr);
        MessageBoxA(NULL, szErrorMsg, "补丁错误", MB_OK | MB_ICONERROR);
    }

    // 补丁窗口检查
    if (VirtualProtect((LPVOID)windowPatchAddr, sizeof(windowPatch), PAGE_EXECUTE_READWRITE, &oldProtect)) {
        memcpy((void*)windowPatchAddr, windowPatch, sizeof(windowPatch));
        VirtualProtect((LPVOID)windowPatchAddr, sizeof(windowPatch), oldProtect, &oldProtect);
        windowSuccess = true;
    }
    else {
        DWORD dwError = GetLastError();
        sprintf_s(szErrorMsg, sizeof(szErrorMsg),
            "无法修改窗口补丁内存保护！\n错误代码: %lu\n补丁地址: 0x%llX", dwError, (ULONGLONG)windowPatchAddr);
        MessageBoxA(NULL, szErrorMsg, "补丁错误", MB_OK | MB_ICONERROR);
    }

    // 报告结果
    if (mutexSuccess && windowSuccess) {
        char szSuccessMsg[512];
        sprintf_s(szSuccessMsg, sizeof(szSuccessMsg),
            "微信多开补丁应用成功！\n互斥锁补丁地址: 0x%llX\n跳转目标: 0x%llX\n窗口补丁地址: 0x%llX",
            (ULONGLONG)mutexPatchAddr, (ULONGLONG)targetAddr, (ULONGLONG)windowPatchAddr);
        MessageBoxA(NULL, szSuccessMsg, "成功", MB_OK | MB_ICONINFORMATION);
    }
    else {
        sprintf_s(szErrorMsg, sizeof(szErrorMsg),
            "部分补丁失败！\n互斥锁补丁: %s\n窗口补丁: %s",
            mutexSuccess ? "成功" : "失败", windowSuccess ? "成功" : "失败");
        MessageBoxA(NULL, szErrorMsg, "补丁警告", MB_OK | MB_ICONWARNING);
    }
}


