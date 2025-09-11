using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System;
using System.Runtime.InteropServices;

namespace application
{
     class FindRemoteDll
    {
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct MODULEENTRY32
        {
            public uint dwSize;
            public uint th32ModuleID;
            public uint th32ProcessID;
            public uint GlblcntUsage;
            public uint ProccntUsage;
            public IntPtr modBaseAddr;
            public uint modBaseSize;
            public IntPtr hModule;

            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
            public string szModule;

            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
            public string szExePath;
        }

        private const uint TH32CS_SNAPMODULE = 0x00000008;
        private const uint TH32CS_SNAPMODULE32 = 0x00000010;
        private static readonly IntPtr INVALID_HANDLE_VALUE = new IntPtr(-1);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern IntPtr CreateToolhelp32Snapshot(uint dwFlags, uint th32ProcessID);

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        private static extern bool Module32First(IntPtr hSnapshot, ref MODULEENTRY32 lpme);

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        private static extern bool Module32Next(IntPtr hSnapshot, ref MODULEENTRY32 lpme);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool CloseHandle(IntPtr hObject);

        /// <summary>
        /// 获取远程进程中模块的句柄
        /// </summary>
        public static IntPtr GetRemoteModuleHandle(uint pid, string moduleName, int timeoutMs = 2000)
        {
            uint start = (uint)Environment.TickCount;

            while ((uint)Environment.TickCount - start < timeoutMs)
            {
                IntPtr hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32, pid);
                if (hSnapshot == INVALID_HANDLE_VALUE)
                {
                    System.Threading.Thread.Sleep(100);
                    continue;
                }

                MODULEENTRY32 me32 = new MODULEENTRY32();
                me32.dwSize = (uint)Marshal.SizeOf(typeof(MODULEENTRY32));

                if (Module32First(hSnapshot, ref me32))
                {
                    do
                    {
                        if (string.Equals(me32.szModule, moduleName, StringComparison.OrdinalIgnoreCase))
                        {
                            CloseHandle(hSnapshot);
                            return me32.hModule;
                        }
                    } while (Module32Next(hSnapshot, ref me32));
                }

                CloseHandle(hSnapshot);
                System.Threading.Thread.Sleep(100);
            }

            return IntPtr.Zero; // 没找到
        }
    }
}
