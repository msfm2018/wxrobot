#include <Windows.h>
#include <string>
#include <fstream>
#include <mutex>
#include <sstream>
#include <iomanip>
#include <Psapi.h>
#include "mopen.h"
HWND g_hMsgWnd = NULL;

void PatchRevokeMsg(ULONG_PTR PATCH_OFFSET) {
	// 将 HMODULE 转换为 DWORD_PTR 以兼容64位地址 revokemsg
	HMODULE hMod = GetModuleHandle(L"Weixin.dll"); // GetModuleHandle 返回 HMODULE，在64位下是64位的
	if (!hMod) {
		MessageBoxA(NULL, "Failed to get module handle for Weixin.dll", "Patch Error", MB_OK | MB_ICONERROR);
		return;
	}

	ULONG_PTR patchAddr = (ULONG_PTR)hMod + PATCH_OFFSET;


	 BYTE patch[] = { 0xB0, 0x01, 0x90, 0x90, 0x90 }; // MOV AL, 0; NOP x3
	//BYTE patch[] = { 0xB0, 0x00, 0x90, 0x90, 0x90 }; // MOV AL, 0; NOP x3

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
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {

	if (message == 1) {
		PatchRevokeMsg(0x23D97E7);
		
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