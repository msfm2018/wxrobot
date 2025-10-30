#include <windows.h>
#include <cstdio>
#include <vector>
#include <string>
#include <sstream>
#include <algorithm>

// 定义 BYTE 为 unsigned char（如果未使用 windows.h）
typedef unsigned char BYTE;

// 将宽字符十六进制字符串解析为 BYTE 数组
void ParseWCharHexStringToByteArray(const wchar_t* hexString, BYTE* outArray, size_t& outSize) {
    std::vector<BYTE> temp;
    std::wstringstream ss(hexString);
    std::wstring token;

    while (std::getline(ss, token, L',')) {
        token.erase(std::remove_if(token.begin(), token.end(), iswspace), token.end());
        if (token.substr(0, 2) == L"0x" || token.substr(0, 2) == L"0X")
            token = token.substr(2);

        unsigned int value;
        std::wstringstream hexStream(token);
        hexStream >> std::hex >> value;
        if (value <= 0xFF)
            temp.push_back(static_cast<BYTE>(value));
    }

    outSize = temp.size();
    for (size_t i = 0; i < outSize; ++i)
        outArray[i] = temp[i];
}

// 搜索二进制特征码并返回偏移
LONGLONG FindPattern(const std::vector<BYTE>& fileData, const BYTE* pattern, size_t patternSize) {
    for (size_t i = 0; i <= fileData.size() - patternSize; ++i) {
        bool found = true;
        for (size_t j = 0; j < patternSize; ++j) {
            if (fileData[i + j] != pattern[j]) {
                found = false;
                break;
            }
        }
        if (found)
            return static_cast<LONGLONG>(i);
    }
    return -1;
}

// DLL 导出函数：修改 JE → JNE
extern "C" __declspec(dllexport) bool ApplyPatchToFile(const wchar_t* dllPath, const wchar_t* hexString) {
    BYTE patternArray[256];
    size_t patternSize = 0;
    ParseWCharHexStringToByteArray(hexString, patternArray, patternSize);

    if (patternSize == 0) {
        MessageBoxA(NULL, "输入的十六进制字符串无效！", "补丁错误", MB_OK | MB_ICONERROR);
        return false;
    }

    HANDLE hFile = CreateFileW(dllPath, GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE) {
        char msg[256];
        sprintf_s(msg, sizeof(msg), "无法打开文件！错误代码: %lu", GetLastError());
        MessageBoxA(NULL, msg, "补丁错误", MB_OK | MB_ICONERROR);
        return false;
    }

    LARGE_INTEGER fileSize;
    if (!GetFileSizeEx(hFile, &fileSize)) {
        MessageBoxA(NULL, "无法获取文件大小！", "补丁错误", MB_OK | MB_ICONERROR);
        CloseHandle(hFile);
        return false;
    }

    std::vector<BYTE> fileData(fileSize.QuadPart);
    DWORD bytesRead;
    if (!ReadFile(hFile, fileData.data(), static_cast<DWORD>(fileSize.QuadPart), &bytesRead, NULL) || bytesRead != fileSize.QuadPart) {
        MessageBoxA(NULL, "无法读取文件！", "补丁错误", MB_OK | MB_ICONERROR);
        CloseHandle(hFile);
        return false;
    }

    // 查找输入的 JE 指令
    LONGLONG offset = FindPattern(fileData, patternArray, patternSize);
    if (offset == -1) {
        MessageBoxA(NULL, "未找到匹配的 JE 指令！请检查输入特征码。", "补丁错误", MB_OK | MB_ICONERROR);
        CloseHandle(hFile);
        return false;
    }

    // 修改第二个字节 0x84 -> 0x85（JE → JNE）
    LARGE_INTEGER liOffset;
    liOffset.QuadPart = offset + 1; // 第二个字节
    if (!SetFilePointerEx(hFile, liOffset, NULL, FILE_BEGIN)) {
        MessageBoxA(NULL, "无法移动文件指针！", "补丁错误", MB_OK | MB_ICONERROR);
        CloseHandle(hFile);
        return false;
    }

    BYTE newByte = 0x85; // JNE
    DWORD bytesWritten;
    if (!WriteFile(hFile, &newByte, 1, &bytesWritten, NULL) || bytesWritten != 1) {
        MessageBoxA(NULL, "无法写入补丁！", "补丁错误", MB_OK | MB_ICONERROR);
        CloseHandle(hFile);
        return false;
    }

    CloseHandle(hFile);



    MessageBoxA(NULL, "已成功修改", "补丁成功", MB_OK | MB_ICONINFORMATION);

    return true;
}

// 示例 main（调试用）
//int main() {
//    const wchar_t* dllPath = L"C:\\Program Files\\Tencent\\Weixin\\4.0.5.18\\Weixin.dll";
//    const wchar_t* hexStr = L"0F,84,94,01,00,00"; // JE 指令
//    ApplyPatchToFile(dllPath, hexStr);
//    return 0;
//}
