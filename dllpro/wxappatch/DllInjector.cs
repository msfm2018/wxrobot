
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows; // 如果是 WPF 使用 MessageBox，WinForms 请改为 System.Windows.Forms

public class DllInjector
{
    #region Win32 API 声明与常量

    private const uint PROCESS_QUERY_INFORMATION = 0x0400;
    private const uint PROCESS_CREATE_THREAD = 0x0002;
    private const uint PROCESS_VM_OPERATION = 0x0008;
    private const uint PROCESS_VM_WRITE = 0x0020;
    private const uint PROCESS_VM_READ = 0x0010;

    private const uint MEM_COMMIT = 0x00001000;
    private const uint MEM_RESERVE = 0x00002000;
    private const uint MEM_RELEASE = 0x00008000;
    private const uint PAGE_READWRITE = 0x04;
    private const uint INFINITE = 0xFFFFFFFF;

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr OpenProcess(uint processAccess, bool bInheritHandle, uint processId);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out IntPtr lpNumberOfBytesWritten);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr GetModuleHandle(string lpModuleName);

    [DllImport("kernel32.dll", CharSet = CharSet.Ansi, ExactSpelling = true, SetLastError = true)]
    private static extern IntPtr GetProcAddress(IntPtr hModule, string procName);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern uint WaitForSingleObject(IntPtr hHandle, uint dwMilliseconds);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool VirtualFreeEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint dwFreeType);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr hObject);

    #endregion

    /// <summary>
    /// 将指定的 DLL 注入到目标进程中
    /// </summary>
    /// <param name="pid">目标进程ID</param>
    /// <param name="dllPath">DLL文件的绝对路径</param>
    /// <returns>是否注入成功</returns>
    public static bool InjectDLL(uint pid, string dllPath)
    {
        uint accessFlags = PROCESS_QUERY_INFORMATION | PROCESS_CREATE_THREAD | PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ;
        IntPtr hProc = OpenProcess(accessFlags, false, pid);
        
        if (hProc == IntPtr.Zero)
        {
            MessageBox.Show($"Failed to open process. Error: {Marshal.GetLastWin32Error()}", "Injection Error", MessageBoxButton.OK, MessageBoxImage.Error);
            return false;
        }

        // 计算宽字符（Wchar_t / Unicode）所需的字节数，包含最后的结束符 \0
        // C# string 默认是 Unicode (UTF-16)，每个字符占 2 字节
        uint sizeInBytes = (uint)((dllPath.Length + 1) * sizeof(char));

        IntPtr baseAddr = VirtualAllocEx(hProc, IntPtr.Zero, sizeInBytes, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
        if (baseAddr == IntPtr.Zero)
        {
            MessageBox.Show($"Failed to allocate remote memory. Error: {Marshal.GetLastWin32Error()}", "Injection Error", MessageBoxButton.OK, MessageBoxImage.Error);
            CloseHandle(hProc);
            return false;
        }

        // 将 C# 字符串转换为等价的 C++ wchar_t 字节数组
        byte[] dllPathBytes = Encoding.Unicode.GetBytes(dllPath + "\0");

        if (!WriteProcessMemory(hProc, baseAddr, dllPathBytes, sizeInBytes, out _))
        {
            MessageBox.Show($"Failed to write DLL path. Error: {Marshal.GetLastWin32Error()}", "Injection Error", MessageBoxButton.OK, MessageBoxImage.Error);
            VirtualFreeEx(hProc, baseAddr, 0, MEM_RELEASE);
            CloseHandle(hProc);
            return false;
        }

        IntPtr hKernel32 = GetModuleHandle("kernel32.dll");
        if (hKernel32 == IntPtr.Zero)
        {
            MessageBox.Show($"Failed to get kernel32.dll handle. Error: {Marshal.GetLastWin32Error()}", "Injection Error", MessageBoxButton.OK, MessageBoxImage.Error);
            VirtualFreeEx(hProc, baseAddr, 0, MEM_RELEASE);
            CloseHandle(hProc);
            return false;
        }

        // 注意：GetProcAddress 必须使用 Ansi 编码获取 "LoadLibraryW"
        IntPtr loadLib = GetProcAddress(hKernel32, "LoadLibraryW");
        if (loadLib == IntPtr.Zero)
        {
            MessageBox.Show($"Failed to get LoadLibraryW address. Error: {Marshal.GetLastWin32Error()}", "Injection Error", MessageBoxButton.OK, MessageBoxImage.Error);
            VirtualFreeEx(hProc, baseAddr, 0, MEM_RELEASE);
            CloseHandle(hProc);
            return false;
        }

        IntPtr hThread = CreateRemoteThread(hProc, IntPtr.Zero, 0, loadLib, baseAddr, 0, IntPtr.Zero);
        if (hThread == IntPtr.Zero)
        {
            MessageBox.Show($"Failed to create remote thread. Error: {Marshal.GetLastWin32Error()}", "Injection Error", MessageBoxButton.OK, MessageBoxImage.Error);
            VirtualFreeEx(hProc, baseAddr, 0, MEM_RELEASE);
            CloseHandle(hProc);
            return false;
        }

        // 等待远程线程结束
        WaitForSingleObject(hThread, INFINITE);

        // 清理远程内存和句柄
        VirtualFreeEx(hProc, baseAddr, 0, MEM_RELEASE);
        CloseHandle(hThread);
        CloseHandle(hProc);

        return true;
    }
}