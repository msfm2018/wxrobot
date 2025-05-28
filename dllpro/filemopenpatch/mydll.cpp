#include <windows.h>
#include <cstdio>
#include <vector>
#include <string>
//wx 4.0.5.18 版本
// Weixin.dll 补丁：去除互斥锁检查和窗口检查
// 补丁功能：
// 1. 去除互斥锁检查，允许多实例运行
// 2. 去除窗口检查，允许多实例运行
// // 注意：请确保在 Weixin.dll 文件未被其他进程占用时运行此补丁程序。
// // 注意：此补丁仅适用于特定版本的 Weixin.dll，可能不适用于其他版本或更新。
// // 免责声明：使用此补丁可能违反软件使用条款，请自行承担风险。
// // 版权声明：此代码仅供学习和研究使用，未经允许不得用于商业用途。
// // 版本信息：

// 
// 搜索二进制特征码并返回匹配的文件偏移
LONGLONG FindPattern(const std::vector<BYTE>& fileData, const BYTE* pattern, size_t patternSize) {
    for (size_t i = 0; i <= fileData.size() - patternSize; ++i) {
        bool found = true;
        for (size_t j = 0; j < patternSize; ++j) {
            if (fileData[i + j] != pattern[j]) {
                found = false;
                break;
            }
        }
        if (found) {
            return static_cast<LONGLONG>(i);
        }
    }
    return -1;
}

extern "C" __declspec(dllexport) bool __stdcall  PatchWeChatDllFile(const wchar_t* dllPath) {
    // 打开 Weixin.dll 文件
    HANDLE hFile = CreateFileW(dllPath, GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE) {
        char szErrorMsg[512];
        sprintf_s(szErrorMsg, sizeof(szErrorMsg), "无法打开 Weixin.dll 文件！错误代码: %lu", GetLastError());
        MessageBoxA(NULL, szErrorMsg, "补丁错误", MB_OK | MB_ICONERROR);
        return false;
    }

    // 获取文件大小
    LARGE_INTEGER fileSize;
    if (!GetFileSizeEx(hFile, &fileSize)) {
        char szErrorMsg[512];
        sprintf_s(szErrorMsg, sizeof(szErrorMsg), "无法获取文件大小！错误代码: %lu", GetLastError());
        MessageBoxA(NULL, szErrorMsg, "补丁错误", MB_OK | MB_ICONERROR);
        CloseHandle(hFile);
        return false;
    }

    // 读取文件内容
    std::vector<BYTE> fileData(fileSize.QuadPart);
    DWORD bytesRead;
    if (!ReadFile(hFile, fileData.data(), static_cast<DWORD>(fileSize.QuadPart), &bytesRead, NULL) || bytesRead != fileSize.QuadPart) {
        char szErrorMsg[512];
        sprintf_s(szErrorMsg, sizeof(szErrorMsg), "无法读取 Weixin.dll 文件！错误代码: %lu", GetLastError());
        MessageBoxA(NULL, szErrorMsg, "补丁错误", MB_OK | MB_ICONERROR);
        CloseHandle(hFile);
        return false;
    }

    // 定义特征码：cmp ebx, B7; jne 的前 8 字节（忽略 jne 的偏移以提高兼容性）
    BYTE mutexPattern[] = { 0x81, 0xFB, 0xB7, 0x00, 0x00, 0x00, 0x0F, 0x85 };
    size_t mutexPatternSize = sizeof(mutexPattern);

    // 搜索互斥锁检查特征码
    LONGLONG patchOffset = FindPattern(fileData, mutexPattern, mutexPatternSize);
    if (patchOffset == -1) {
        MessageBoxA(NULL, "未找到互斥锁检查指令特征码！请检查 Weixin.dll 版本或特征码。", "补丁错误", MB_OK | MB_ICONERROR);
        CloseHandle(hFile);
        return false;
    }

    // 构造补丁：12 字节 NOP
    BYTE nopPatch[] = { 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 };

    // 将文件指针移动到补丁偏移
    LARGE_INTEGER liOffset;
    liOffset.QuadPart = patchOffset;
    if (!SetFilePointerEx(hFile, liOffset, NULL, FILE_BEGIN)) {
        char szErrorMsg[512];
        sprintf_s(szErrorMsg, sizeof(szErrorMsg), "无法移动文件指针！错误代码: %lu", GetLastError());
        MessageBoxA(NULL, szErrorMsg, "补丁错误", MB_OK | MB_ICONERROR);
        CloseHandle(hFile);
        return false;
    }

    // 写入 NOP 补丁
    DWORD bytesWritten;
    if (!WriteFile(hFile, nopPatch, sizeof(nopPatch), &bytesWritten, NULL) || bytesWritten != sizeof(nopPatch)) {
        char szErrorMsg[512];
        sprintf_s(szErrorMsg, sizeof(szErrorMsg), "无法写入 NOP 补丁！错误代码: %lu", GetLastError());
        MessageBoxA(NULL, szErrorMsg, "补丁错误", MB_OK | MB_ICONERROR);
        CloseHandle(hFile);
        return false;
    }

    // 可选：补丁窗口检查（xWechatWindow）
    BYTE windowPattern[] = { 0xE8, 0x67, 0x2C, 0x4E, 0x00 }; // call weixin.7FFC6802CBA0
    size_t windowPatternSize = sizeof(windowPattern);
    LONGLONG windowPatchOffset = FindPattern(fileData, windowPattern, windowPatternSize);
    if (windowPatchOffset != -1) {
        BYTE windowPatch[] = { 0x31, 0xC0, 0x90, 0x90, 0x90 }; // xor eax, eax; nop; nop; nop
        liOffset.QuadPart = windowPatchOffset;
        if (SetFilePointerEx(hFile, liOffset, NULL, FILE_BEGIN)) {
            WriteFile(hFile, windowPatch, sizeof(windowPatch), &bytesWritten, NULL);
        }
    }

    CloseHandle(hFile);
    char szSuccessMsg[512];
    sprintf_s(szSuccessMsg, sizeof(szSuccessMsg),
        "Weixin.dll 文件补丁应用成功！\n互斥锁补丁偏移: 0x%llX\n窗口检查补丁偏移: %s",
        (ULONGLONG)patchOffset, windowPatchOffset != -1 ? std::to_string((ULONGLONG)windowPatchOffset).c_str() : "未应用");
    MessageBoxA(NULL, szSuccessMsg, "成功", MB_OK | MB_ICONINFORMATION);
    return true;
}

//int main() {
//    // 指定 Weixin.dll 文件路径
//    const wchar_t* dllPath = L"C:\\Program Files\\Tencent\\Weixin\\4.0.5.18\\Weixin.dll"; // 替换为实际路径
//    PatchWeChatDllFile(dllPath);
//    return 0;
//}
