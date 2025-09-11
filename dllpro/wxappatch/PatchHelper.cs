using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;


namespace application
{
    class PatchHelper
    {
        private delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

        [DllImport("user32.dll")]
        private static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        private static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);

        [DllImport("user32.dll")]
        private static extern bool PostMessage(IntPtr hWnd, uint Msg, int wParam, int lParam);

        public static List<IntPtr> FindAllWindowsByClass(string className)
        {
            List<IntPtr> result = new List<IntPtr>();

            EnumWindows(delegate (IntPtr hWnd, IntPtr lParam)
            {
                StringBuilder sb = new StringBuilder(256);
                GetClassName(hWnd, sb, sb.Capacity);
                if (sb.ToString() == className)
                {
                    result.Add(hWnd);
                }
                return true; // 继续枚举
            }, IntPtr.Zero);

            return result;
        }

        public static void BroadcastPatch(uint cmd)
        {
            var windows = FindAllWindowsByClass("RevokePatchMsgWnd");
            if (windows.Count == 0)
            {
                System.Windows.MessageBox.Show("未找到任何 RevokePatchMsgWnd 窗口，DLL 可能未注入");
                return;
            }

            foreach (var hWnd in windows)
            {
                PostMessage(hWnd, cmd, 0, 0);
            }
        }
    }

}


