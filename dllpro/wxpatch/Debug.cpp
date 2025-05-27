#include "Debug.h"
#include <format>
#include <chrono>
#include <iostream>
#include <windows.h> // 需要包含此头文件来使用 Windows API 函数
#include <mutex>     // 需要包含此头文件来使用 std::mutex

Debug::Debug()
    : hConsole(NULL),
    debugWin(true),
    err(false),
    errColor(FOREGROUND_RED | FOREGROUND_INTENSITY),
    defColor(FOREGROUND_GREEN | FOREGROUND_INTENSITY) {
    // 默认启用调试窗口
}

Debug::~Debug() {
    if (hConsole != NULL) {
        FreeConsole();
        hConsole = NULL;
    }
}

void Debug::NewConsole() {
    if (hConsole != NULL) {
        FreeConsole();
        hConsole = NULL;
    }

    if (!AllocConsole()) {
        return;
    }

    hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
    if (hConsole == INVALID_HANDLE_VALUE) {
        FreeConsole();
        return;
    }

    SetConsoleMode(hConsole, ENABLE_PROCESSED_OUTPUT | ENABLE_WRAP_AT_EOL_OUTPUT);
    SetConsoleTitle(L"WeChat Multi-Instance Debug Console");
    SetConsoleTextAttribute(hConsole, defColor);

    // 设置控制台窗口样式
    HWND hc = FindWindow(L"ConsoleWindowClass", NULL);
    if (hc != NULL) {
        // 隐藏关闭按钮
        HMENU hMenu = GetSystemMenu(hc, FALSE);
        if (hMenu != NULL) {
            DeleteMenu(hMenu, SC_CLOSE, MF_BYCOMMAND);
            DrawMenuBar(hc);
        }

        // 设置窗口样式为工具窗口
        LONG_PTR exStyle = GetWindowLongPtr(hc, GWL_EXSTYLE);
        SetWindowLongPtr(hc, GWL_EXSTYLE, exStyle | WS_EX_TOOLWINDOW);
    }
}

void Debug::SetError(bool isError) {
    err = isError;
}

Debug& Debug::Instance() {
    static Debug instance;
    return instance;
}

void Debug::OutMsg(const std::wstring& msg) {
    // 移除或注释掉 #ifdef _DEBUG 和 #endif
    // 这样，OutMsg 函数的代码在任何编译配置下都会被编译和执行。

    // if (!debugWin) return; // 如果你确定要始终显示调试窗口，这个可以继续注释

    std::lock_guard<std::mutex> lock(mtx);

    if (hConsole == NULL) {
        NewConsole();
        if (hConsole == NULL) return;
    }

    // 获取当前时间
    auto now = std::chrono::system_clock::now();
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()) % 1000;
    auto time_t = std::chrono::system_clock::to_time_t(now);
    std::tm tm;
    localtime_s(&tm, &time_t);
    std::wstring timestamp = std::format(L"{:02}:{:02}:{:02}:{:03} ",
        tm.tm_hour, tm.tm_min, tm.tm_sec, ms.count());

    // 设置颜色
    if (err) {
        SetConsoleTextAttribute(hConsole, errColor);
    }
    else {
        SetConsoleTextAttribute(hConsole, defColor);
    }

    // 输出时间戳 + 消息
    std::wstring fullMsg = timestamp + msg;
    DWORD written;
    WriteConsoleW(hConsole, fullMsg.c_str(), static_cast<DWORD>(fullMsg.length()), &written, nullptr);
    WriteConsoleW(hConsole, L"\r\n", 2, &written, nullptr);

    // 恢复默认颜色
    SetConsoleTextAttribute(hConsole, defColor);
    err = false;
}