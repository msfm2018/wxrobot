using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Diagnostics;
using System.Runtime.InteropServices;


namespace application
{
    class WeChatWindowFinder
    {
        private const string TargetClassName = "RevokePatchMsgWnd";

        // 定义回调委托
        private delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

        [DllImport("user32.dll")]
        private static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

        [DllImport("user32.dll")]
        private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        private static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);

        public static IntPtr FindRevokePatchMsgWnd(uint targetPid)
        {
            IntPtr foundHwnd = IntPtr.Zero;

            EnumWindows(delegate (IntPtr hWnd, IntPtr lParam)
            {
                GetWindowThreadProcessId(hWnd, out uint pid);

                if (pid == targetPid)
                {
                    StringBuilder className = new StringBuilder(256);
                    if (GetClassName(hWnd, className, className.Capacity) > 0)
                    {
                        if (className.ToString() == TargetClassName)
                        {
                            foundHwnd = hWnd;
                            return false; // 停止枚举
                        }
                    }
                }
                return true; // 继续枚举
            }, IntPtr.Zero);

            return foundHwnd;
        }
    }
}
