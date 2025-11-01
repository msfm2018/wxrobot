#include <windows.h>
#include <cstdio> 
#include "fun.h"
#include "mopen.h"


HWND g_hMsgWnd = NULL;


LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {

	if (message == 1) {
		PatchRevokeMsg41030(0x1D1A706);
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

BOOL APIENTRY DllMain(HMODULE hModule, DWORD reason, LPVOID lpReserved) {
	if (reason == DLL_PROCESS_ATTACH) {
		DisableThreadLibraryCalls(hModule);

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


