// WeChatKeyExtractor_Dynamic.cpp
#include <Windows.h>
#include <string>
#include <fstream>
#include <mutex>
#include <sstream>
#include <iomanip>
#include <Psapi.h>
#include "fun.h"
#include "mopen.h"
#include "minhook/include/MinHook.h"
//#include "minhook/lib/MinHook.h"
//#pragma comment(lib, "minhook/lib/libMinHook.x64.lib")

void WriteLog(const std::string& msg);
std::mutex g_logMutex;
std::string g_logPath;

// 原函数签名（需要根据目标函数确定，假设为 void Func(void* p1, void* pUnsafeData)） C:\Users\Administrator\xwechat_files com.Tencent.WCDB.Config.Cipher
  



typedef void(__fastcall* TargetFunc)(void* p1_context, void* pUnsafeData, int p3_dword, int p4_dword);
// 存储原函数地址的指针
TargetFunc pOriginalTargetFunc = nullptr;

// --- 辅助变量保持不变 ---
static std::atomic<uintptr_t> g_targetAddress{ 0 };


bool SafeReadPointer(void* addr, void** out) {
	__try { *out = *(void**)addr; return true; }
	__except (1) { return false; }
}

bool SafeReadDword(void* addr, DWORD* out) {
	__try { *out = *(DWORD*)addr; return true; }
	__except (1) { return false; }
}
void SendStringToWindow(HWND hWndTarget, const std::wstring& text)
{
	if (!IsWindow(hWndTarget)) return;

	COPYDATASTRUCT cds;
	cds.dwData = 0; // 自定义用途的标记 (可放消息类型)
	cds.cbData = static_cast<DWORD>((text.size() + 1) * sizeof(wchar_t)); // 包含终结符
	cds.lpData = (PVOID)text.c_str();

	// SendMessageW 保证同步，WM_COPYDATA 需用 SendMessage
	::SendMessageW(hWndTarget, WM_COPYDATA, (WPARAM)NULL, (LPARAM)&cds);
}

void __fastcall HookedTargetFunc(void* p1_context, void* pUnsafeData, int p3_dword, int p4_dword)
{
	// 先保存本次是否获取到 key 的标志（不要在移除 hook 之前调用 MH_Uninitialize）
	bool grabbed = false;
	std::string keyHex;

	// 尝试读取（用更安全的类型）
	SIZE_T keySize = 0;
	void* pKeyBuffer = nullptr;

	// 小心内存布局：在 x64 上大小字段可能是 8 字节（use SIZE_T）
	bool canReadSize = SafeReadDword((void*)((uintptr_t)pUnsafeData + 0x10), (DWORD*)&keySize);
	bool canReadPtr = SafeReadPointer((void*)((uintptr_t)pUnsafeData + 0x8), &pKeyBuffer);

	if (canReadSize && canReadPtr && keySize == 32 && pKeyBuffer) {
		std::stringstream ss;
		ss << std::hex << std::setfill('0');
		for (SIZE_T i = 0; i < keySize; ++i) {
			unsigned char b = 0;

			b = ((unsigned char*)pKeyBuffer)[i];

			ss << std::setw(2) << static_cast<int>(b);
		}
		keyHex = ss.str();
		WriteLog("SUCCESS:密钥获取成功 (MinHook)");
		WriteLog("KEY:" + keyHex);
		HWND hWndReceiver = FindWindowW(NULL, L"多开及防撤回补丁工具"); // 或别的查找方法
		if (hWndReceiver)
		{
			std::wstring wkey(keyHex.begin(), keyHex.end());
			SendStringToWindow(hWndReceiver, wkey);
		}
		grabbed = true;
	}

	// 调用原函数：**在移除 Hook 之前**调用原函数。
	if (pOriginalTargetFunc) {
		pOriginalTargetFunc(p1_context, pUnsafeData, p3_dword, p4_dword);
	}
	else {
		WriteLog("WARN:原函数指针为空，未能调用原函数");
	}

	// 如果成功获取并只想执行一次，则在独立线程中安全地卸载 Hook
	if (grabbed) {
		WriteLog("INFO:准备卸载 MinHook（在独立线程中）");
		// 在新线程中卸载，避免在 hook 的调用栈里破坏 trampoline
		CreateThread(nullptr, 0, [](LPVOID) -> DWORD {
			// 禁用再移除并反初始化，记录每一步返回值
			MH_STATUS st;
			st = MH_DisableHook((LPVOID)g_targetAddress.load());
			{
				std::stringstream ss; ss << "INFO:MH_DisableHook returned " << (int)st; WriteLog(ss.str());
			}
			st = MH_RemoveHook((LPVOID)g_targetAddress.load());
			{
				std::stringstream ss; ss << "INFO:MH_RemoveHook returned " << (int)st; WriteLog(ss.str());
			}
			st = MH_Uninitialize();
			{
				std::stringstream ss; ss << "INFO:MH_Uninitialize returned " << (int)st; WriteLog(ss.str());
			}
			WriteLog("INFO:MinHook 已安全卸载");
			return 0;
			}, nullptr, 0, nullptr);
	}
}
// --- Hook 函数 (新的拦截器) ---

void WriteLog(const std::string& msg) {
	std::lock_guard<std::mutex> lock(g_logMutex);
	std::ofstream ofs(g_logPath, std::ios::app);
	if (ofs.is_open()) {
		SYSTEMTIME st; GetLocalTime(&st);
		char buf[32];
		sprintf_s(buf, "%02d:%02d:%02d", st.wHour, st.wMinute, st.wSecond);
		ofs << "[" << buf << "] " << msg << std::endl;
	}
}


DWORD WINAPI MainThread(LPVOID) {
	g_logPath = []() -> std::string {
		char p[MAX_PATH]; GetTempPathA(MAX_PATH, p);
		return std::string(p) + "wx_db_key_.log";
		}();

	HMODULE hmytest = GetModuleHandleA("Weixin.dll");
	if (!hmytest) {
		WriteLog("ERROR:未能获取mytest.dll模块句柄");
		return 0;
	}
	//0x59E2450   4.1.4.11
	// 0x4AEA40;//4.1.1.19
	// 0x5AA92D0;// 4.1.4.13
	//0x5AAB2D0  4.1.4.15
	const uintptr_t rva_setCipherKey = 0x5AAB2D0;
	g_targetAddress.store((uintptr_t)hmytest + rva_setCipherKey);
	uintptr_t targetAddr = g_targetAddress.load();
	WriteLog("SUCCESS:目标地址计算成功");

	// 1. 初始化 MinHook
	if (MH_Initialize() != MH_OK) {
		WriteLog("ERROR:MinHook初始化失败");
		return 0;
	}
	WriteLog("INFO:MinHook初始化成功");

	// 2. 创建 Hook
	// 参数：目标函数地址，Hook 函数地址，用于接收原函数指针的指针
	MH_STATUS status = MH_CreateHook(
		(LPVOID)targetAddr,           // 目标函数地址
		&HookedTargetFunc,            // 我们的 Hook 函数
		(LPVOID*)&pOriginalTargetFunc // 接收原函数指针的变量地址
	);

	if (status != MH_OK) {
		std::string msg = "ERROR:创建Hook失败, 状态码: " + std::to_string(status);
		WriteLog(msg);
		MH_Uninitialize();
		return 0;
	}
	WriteLog("SUCCESS:MinHook创建成功");

	// 3. 启用 Hook
	if (MH_EnableHook((LPVOID)targetAddr) != MH_OK) {
		WriteLog("ERROR:启用Hook失败");
		MH_RemoveHook((LPVOID)targetAddr);
		MH_Uninitialize();
		return 0;
	}

	WriteLog("SUCCESS:Hook已设置，请登录微信");
	WriteLog("INFO:MinHook版本不会导致立即崩溃，它会尝试执行原函数");

	return 0;
}

HWND g_hMsgWnd = NULL;


LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {

	if (message == 1) {
		PatchRevokeMsg41030(0x1D4C296);

		return 0;
	}

	return DefWindowProc(hWnd, message, wParam, lParam);
}
// 创建隐藏窗口用于接收消息
DWORD WINAPI MsgWindowThread(LPVOID lpParam) {
	WNDCLASS wc = { 0 };
	wc.lpfnWndProc = WndProc;
	wc.hInstance = GetModuleHandle(NULL);
	wc.lpszClassName = TEXT("RevokePatchMsgWnd");

	if (!RegisterClass(&wc)) {
		DWORD dwError = GetLastError();
		char szErrorMsg[256];
		sprintf_s(szErrorMsg, sizeof(szErrorMsg), "Failed to register window class!\nError Code: %lu", dwError);
		MessageBoxA(NULL, szErrorMsg, "Patch Error", MB_OK | MB_ICONERROR);
		return 1;
	}

	g_hMsgWnd = CreateWindow(TEXT("RevokePatchMsgWnd"), TEXT(""), WS_OVERLAPPEDWINDOW,
		0, 0, 0, 0, NULL, NULL, wc.hInstance, NULL);

	if (!g_hMsgWnd) {
		DWORD dwError = GetLastError();
		char szErrorMsg[256];
		sprintf_s(szErrorMsg, sizeof(szErrorMsg), "Failed to create message window!\nError Code: %lu", dwError);
		MessageBoxA(NULL, szErrorMsg, "Patch Error", MB_OK | MB_ICONERROR);
		UnregisterClass(TEXT("RevokePatchMsgWnd"), GetModuleHandle(NULL)); // Clean up
		return 1;
	}

	MSG msg;
	while (GetMessage(&msg, NULL, 0, 0)) {
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}

	UnregisterClass(TEXT("RevokePatchMsgWnd"), GetModuleHandle(NULL));
	return 0;
}
BOOL APIENTRY DllMain(HMODULE hModule, DWORD reason, LPVOID) {
	if (reason == DLL_PROCESS_ATTACH) {
		DisableThreadLibraryCalls(hModule);
		//getDBkey
		CreateThread(nullptr, 0, MainThread, nullptr, 0, nullptr);

		//防撤回
		HANDLE hThread = CreateThread(NULL, 0, MsgWindowThread, NULL, 0, NULL);
		if (hThread) {
			CloseHandle(hThread);
		}
	}
	else if (reason == DLL_PROCESS_DETACH) {
		if (g_hMsgWnd) {
			PostMessage(g_hMsgWnd, WM_QUIT, 0, 0);
		}
	}
	return TRUE;
}