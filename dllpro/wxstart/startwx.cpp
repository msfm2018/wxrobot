#include <windows.h>
#include <tlhelp32.h>
#include <tchar.h>
#include <string>
#include <vector>
#include <iostream>

DWORD FindProcessId(const std::wstring& processName) {
    PROCESSENTRY32W entry;
    entry.dwSize = sizeof(PROCESSENTRY32W);

    HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (Process32FirstW(snapshot, &entry)) {
        do {
            if (!_wcsicmp(entry.szExeFile, processName.c_str())) {
                CloseHandle(snapshot);
                return entry.th32ProcessID;
            }
        } while (Process32NextW(snapshot, &entry));
    }
    CloseHandle(snapshot);
    return 0;
}

HMODULE GetRemoteModuleHandle(DWORD pid, const std::wstring& moduleName, DWORD timeoutMs) {
    DWORD startTime = GetTickCount();
    while (GetTickCount() - startTime < timeoutMs) {
        HANDLE hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32, pid);
        if (hSnapshot == INVALID_HANDLE_VALUE) {
            Sleep(100);
            continue;
        }

        MODULEENTRY32W me;
        me.dwSize = sizeof(MODULEENTRY32W);

        if (Module32FirstW(hSnapshot, &me)) {
            do {
                if (!_wcsicmp(me.szModule, moduleName.c_str())) {
                    CloseHandle(hSnapshot);
                    return me.hModule;
                }
            } while (Module32NextW(hSnapshot, &me));
        }
        CloseHandle(hSnapshot);
        Sleep(100);
    }
    return NULL;
}


bool InjectDLL(DWORD pid, const std::wstring& dllPath) {
    HANDLE hProc = OpenProcess(
        PROCESS_QUERY_INFORMATION | PROCESS_CREATE_THREAD | PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ,
        FALSE,
        pid
    );
    if (!hProc) {
        MessageBoxW(NULL, (L"Failed to open process. Error: " + std::to_wstring(GetLastError())).c_str(), L"Injection Error", MB_OK | MB_ICONERROR);
        return false;
    }

    LPVOID baseAddr = VirtualAllocEx(hProc, 0, (dllPath.size() + 1) * sizeof(wchar_t), MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (!baseAddr) {
        MessageBoxW(NULL, (L"Failed to allocate remote memory. Error: " + std::to_wstring(GetLastError())).c_str(), L"Injection Error", MB_OK | MB_ICONERROR);
        CloseHandle(hProc);
        return false;
    }

    if (!WriteProcessMemory(hProc, baseAddr, dllPath.c_str(), (dllPath.size() + 1) * sizeof(wchar_t), nullptr)) {
        MessageBoxW(NULL, (L"Failed to write DLL path. Error: " + std::to_wstring(GetLastError())).c_str(), L"Injection Error", MB_OK | MB_ICONERROR);
        VirtualFreeEx(hProc, baseAddr, 0, MEM_RELEASE);
        CloseHandle(hProc);
        return false;
    }

    HMODULE hKernel32 = GetModuleHandleW(L"kernel32.dll");
    if (!hKernel32) {
        MessageBoxW(NULL, (L"Failed to get kernel32.dll handle. Error: " + std::to_wstring(GetLastError())).c_str(), L"Injection Error", MB_OK | MB_ICONERROR);
        VirtualFreeEx(hProc, baseAddr, 0, MEM_RELEASE);
        CloseHandle(hProc);
        return false;
    }

    LPTHREAD_START_ROUTINE loadLib = (LPTHREAD_START_ROUTINE)GetProcAddress(hKernel32, "LoadLibraryW");
    if (!loadLib) {
        MessageBoxW(NULL, (L"Failed to get LoadLibraryW address. Error: " + std::to_wstring(GetLastError())).c_str(), L"Injection Error", MB_OK | MB_ICONERROR);
        VirtualFreeEx(hProc, baseAddr, 0, MEM_RELEASE);
        CloseHandle(hProc);
        return false;
    }

    HANDLE hThread = CreateRemoteThread(hProc, NULL, 0, loadLib, baseAddr, 0, NULL);
    if (!hThread) {
        MessageBoxW(NULL, (L"Failed to create remote thread. Error: " + std::to_wstring(GetLastError())).c_str(), L"Injection Error", MB_OK | MB_ICONERROR);
        VirtualFreeEx(hProc, baseAddr, 0, MEM_RELEASE);
        CloseHandle(hProc);
        return false;
    }

    WaitForSingleObject(hThread, INFINITE);
    VirtualFreeEx(hProc, baseAddr, 0, MEM_RELEASE);
    CloseHandle(hThread);
    CloseHandle(hProc);
    return true;
}

// ** Ľ     GetWeChatInstallPath     **
std::wstring GetWeChatInstallPath() {
    HKEY hKey;
    DWORD dwType = REG_SZ;
    wchar_t szPath[MAX_PATH];
    DWORD dwSize;
    std::wstring installPath;

    // ---    ȼ   Uninstall ·   ---

    // 1.    Դ  HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Weixin (32λӦ    64λϵͳ)
    dwSize = sizeof(szPath);
    if (RegOpenKeyExW(HKEY_LOCAL_MACHINE, L"SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Weixin", 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
        if (RegQueryValueExW(hKey, L"InstallLocation", NULL, &dwType, (LPBYTE)szPath, &dwSize) == ERROR_SUCCESS) {
            installPath = szPath;
        }
        RegCloseKey(hKey);
        if (!installPath.empty()) {
            return installPath;
        }
    }

    // 2.    Դ  HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Weixin (64λӦ    64λϵͳ)
    dwSize = sizeof(szPath);
    if (RegOpenKeyExW(HKEY_LOCAL_MACHINE, L"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Weixin", 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
        if (RegQueryValueExW(hKey, L"InstallLocation", NULL, &dwType, (LPBYTE)szPath, &dwSize) == ERROR_SUCCESS) {
            installPath = szPath;
        }
        RegCloseKey(hKey);
        if (!installPath.empty()) {
            return installPath;
        }
    }

    // --- Ȼ     Tencent\WeChat ·   (  Ϊ    ) ---

    // 3.    Դ  HKEY_CURRENT_USER\Software\Tencent\WeChat
    dwSize = sizeof(szPath);
    if (RegOpenKeyExW(HKEY_CURRENT_USER, L"Software\\Tencent\\WeChat", 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
        if (RegQueryValueExW(hKey, L"InstallPath", NULL, &dwType, (LPBYTE)szPath, &dwSize) == ERROR_SUCCESS) {
            installPath = szPath;
        }
        RegCloseKey(hKey);
        if (!installPath.empty()) {
            return installPath;
        }
    }

    // 4.    Դ  HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Tencent\WeChat
    dwSize = sizeof(szPath);
    if (RegOpenKeyExW(HKEY_LOCAL_MACHINE, L"SOFTWARE\\WOW6432Node\\Tencent\\WeChat", 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
        if (RegQueryValueExW(hKey, L"InstallPath", NULL, &dwType, (LPBYTE)szPath, &dwSize) == ERROR_SUCCESS) {
            installPath = szPath;
        }
        RegCloseKey(hKey);
        if (!installPath.empty()) {
            return installPath;
        }
    }

    // 5.    Դ  HKEY_LOCAL_MACHINE\SOFTWARE\Tencent\WeChat
    dwSize = sizeof(szPath);
    if (RegOpenKeyExW(HKEY_LOCAL_MACHINE, L"SOFTWARE\\Tencent\\WeChat", 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
        if (RegQueryValueExW(hKey, L"InstallPath", NULL, &dwType, (LPBYTE)szPath, &dwSize) == ERROR_SUCCESS) {
            installPath = szPath;
        }
        RegCloseKey(hKey);
        if (!installPath.empty()) {
            return installPath;
        }
    }

    return L""; // δ ҵ   װ·  
}


//    ΢ Ų ע   ( Ľ   )
extern "C" __declspec(dllexport) int StartWeChatAndInject(const wchar_t* dllPath) {
    STARTUPINFOW si = { sizeof(si) };
    PROCESS_INFORMATION pi;
    std::wstring exePath;
    std::wstring installDir; // Declare installDir here

    //    Ի ȡ΢ Ű װ·  
    installDir = GetWeChatInstallPath();
    if (installDir.empty()) {
        MessageBoxW(NULL, L"Failed to find WeChat installation path in registry.", L"Injection Error", MB_OK | MB_ICONERROR);
        return 1; //    ʧ  
    }

    //     ΢  ִ   ļ ·  

    if (!installDir.empty() && installDir.back() != L'\\') {
        installDir += L"\\";
    }
    exePath = installDir + L"Weixin.exe";


    if (!CreateProcessW(exePath.c_str(), NULL, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
        MessageBoxW(NULL, (L"Failed to launch WeChat from " + exePath + L". Error: " + std::to_wstring(GetLastError())).c_str(), L"Injection Error", MB_OK | MB_ICONERROR);
        return 1; //    ʧ  
    }

    CloseHandle(pi.hThread);


    CloseHandle(pi.hProcess);
    return 0;
}


std::vector<DWORD> FindAllProcessIds(const std::wstring& processName) {
    std::vector<DWORD> pids;
    PROCESSENTRY32W entry;
    entry.dwSize = sizeof(PROCESSENTRY32W);

    HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snapshot == INVALID_HANDLE_VALUE) {
        return pids;
    }

    if (Process32FirstW(snapshot, &entry)) {
        do {
            if (!_wcsicmp(entry.szExeFile, processName.c_str())) {
                pids.push_back(entry.th32ProcessID);
            }
        } while (Process32NextW(snapshot, &entry));
    }
    CloseHandle(snapshot);
    return pids;
}


extern "C" __declspec(dllexport) int InjectToWeChat(const wchar_t* dllPath) {
    auto pids = FindAllProcessIds(L"Weixin.exe");
    if (pids.empty()) {
        MessageBoxW(NULL, L"WeChat process (Weixin.exe) not found.", L"Injection Error", MB_OK | MB_ICONERROR);
        return 1;
    }

    bool allOk = true;
    for (DWORD pid : pids) {
        InjectDLL(pid, dllPath);
        //if (!InjectDLL(pid, dllPath)) {
        //    allOk = false;
        //    // 这里可以选择是否遇到失败就提前退出
        //    // return 2;
        //}
    }

    return allOk ? 0 : 2;
}

extern "C" __declspec(dllexport) int InjectToWeChat2(const wchar_t* dllPath) {
    DWORD pid = FindProcessId(L"Weixin.exe"); 
    if (pid == 0) {
        MessageBoxW(NULL, L"WeChat process (Weixin.exe) not found.", L"Injection Error", MB_OK | MB_ICONERROR);
        return 1;
    }

    if (!InjectDLL(pid, dllPath)) {
        return 2;
    }

    return 0;
}
