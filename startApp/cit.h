#pragma once
#pragma once
#include "stdafx.h"


#include <direct.h>
#include <stdlib.h>
#include <TlHelp32.h>
#include <stdio.h>

#include <string>
#pragma comment(lib,"advapi32")
//DWORD ProcessNameFindPID(const char* ProcessName);	//通过进程名获取进程ID
BOOL InjectDll(HANDLE& wxPid); //注入dll
BOOL CheckIsInject(DWORD dwProcessid);	//检测DLL是否已经注入