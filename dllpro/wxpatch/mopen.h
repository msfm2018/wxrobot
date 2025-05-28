



#pragma once
#include <windows.h>
#include <cstdio>


#define PATCH_M 0x89ED7 // For Weixin 4.0.5.18 (for 64-bit) DUO KAI
#define PATCH_M_OFFSET 0x89FC9 // For Weixin 4.0.5.18 (for 64-bit)



void PatchWeChatMultiInstance(ULONG_PTR PATCH_OFFSET, ULONG_PTR JUMP_OFFSET);