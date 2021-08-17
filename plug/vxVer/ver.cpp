#include "pch.h"

#include <direct.h>
#include <stdlib.h>
#include <TlHelp32.h>
#include <stdio.h>
#include <strstream>
#include <iostream>
#include <windows.h>
#include <string>

#pragma comment(lib,"Version.lib")
using namespace std;

extern "C" _declspec(dllexport) BOOL IsWxVersionValid()
{
	

	DWORD wxBaseAddress = (DWORD)GetModuleHandle(TEXT("WeChatWin.dll"));
	//DWORD wxBaseAddress = (DWORD)GetModuleHandle(szProductType.c_str());
	const string wxVersoin = "3.2.1.154";

	WCHAR VersionFilePath[MAX_PATH];
	if (GetModuleFileName((HMODULE)wxBaseAddress, VersionFilePath, MAX_PATH) == 0)
	{
		return FALSE;
	}

	string asVer = "";
	VS_FIXEDFILEINFO* pVsInfo;
	unsigned int iFileInfoSize = sizeof(VS_FIXEDFILEINFO);
	int iVerInfoSize = GetFileVersionInfoSize(VersionFilePath, NULL);
	if (iVerInfoSize != 0) {
		char* pBuf = new char[iVerInfoSize];
		if (GetFileVersionInfo(VersionFilePath, 0, iVerInfoSize, pBuf)) {
			if (VerQueryValue(pBuf, TEXT("\\"), (void**)&pVsInfo, &iFileInfoSize)) {

				int s_major_ver = (pVsInfo->dwFileVersionMS >> 16) & 0x0000FFFF;

				int s_minor_ver = pVsInfo->dwFileVersionMS & 0x0000FFFF;

				int s_build_num = (pVsInfo->dwFileVersionLS >> 16) & 0x0000FFFF;

				int s_revision_num = pVsInfo->dwFileVersionLS & 0x0000FFFF;

				//把版本变成字符串
				strstream wxVer;
				wxVer << s_major_ver << "." << s_minor_ver << "." << s_build_num << "." << s_revision_num;
				wxVer >> asVer;

			}
		}
		delete[] pBuf;
	}

	//版本匹配
	if (asVer == wxVersoin)
	{
		return TRUE;
	}

	//版本不匹配
	return FALSE;
}

