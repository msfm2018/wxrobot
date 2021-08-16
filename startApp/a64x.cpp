// a64x.cpp : 定义控制台应用程序的入口点。
//

#include "stdafx.h"
#include<iostream>
#include <stdio.h>
#include "cit.h"
#undef   UNICODE 
#include <sysinfoapi.h>
#include <TlHelp32.h>
#include <string>
#include <io.h>
#include<cstring>
#include<tchar.h>
#include <atlstr.h>

using namespace std;

HANDLE wxPid = NULL;		//微信的PID
//************************************************************
// 函数名称: InjectDll
// 函数说明: 注入DLL
// 作    者: GuiShou
// 时    间: 2019/6/30
// 参    数: void
// 返 回 值: void
//************************************************************


int main()
{



	if (InjectDll(wxPid) == FALSE)
	{
		ExitProcess(-1);
	}




    return 0;
}

