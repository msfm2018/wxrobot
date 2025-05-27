#pragma once
#include <windows.h>
#include <string>
#include <mutex>

class Debug {
private:
    Debug();  // 构造函数私有
    ~Debug();

    Debug(const Debug&) = delete;
    Debug& operator=(const Debug&) = delete;

    HANDLE hConsole;
    bool debugWin;
    bool err;
    WORD errColor;
    WORD defColor;
    std::mutex mtx;

    void NewConsole();

public:
    static Debug& Instance();  // 获取唯一实例

    void OutMsg(const std::wstring& msg);
    void SetError(bool isError = true);
};
