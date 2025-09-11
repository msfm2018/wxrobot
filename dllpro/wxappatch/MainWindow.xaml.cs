using application;
using Microsoft.Win32; // Required for OpenFileDialog
using MultiWeixin.Assist;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;       // Required for Path operations
using System.Reflection.Metadata;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices; // Required for DllImport
using System.Text.Json;
using System.Windows;



public class PatchInfo
{
    //[JsonConverter(typeof(HexStringToIntArrayConverter))]
    public string position { get; set; }
}




namespace WpfAppMultiPatch
{

    public class ProcessInfo
    {
        public uint ProcessId { get; set; }
        public IntPtr WindowHandle { get; set; }
    }

    public partial class MainWindow : Window
    {
        // DLL imports
        [DllImport("wxstart.dll", CharSet = CharSet.Unicode)]
        public static extern int StartWeChatAndInject(string dllPath);

        [DllImport("wxstart.dll", CharSet = CharSet.Unicode)]
        public static extern int InjectToWeChat(uint pid, string dllPath);

        [DllImport("myfilemopen.dll", CharSet = CharSet.Unicode)]
        [return: MarshalAs(UnmanagedType.Bool)]

        public static extern bool ApplyPatchToFile(
        [MarshalAs(UnmanagedType.LPWStr)] string dllPath, // wchar_t* 对应 C# 的 string，需要 MarshalAs 指定类型
         [MarshalAs(UnmanagedType.LPWStr)] string patchData  );

        [DllImport("wxstart.dll", CharSet = CharSet.Unicode, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I1)] // 确保 C++ bool 正确映射
        public static extern bool InjectDLL(uint pid, string dllPath);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr FindWindowEx(IntPtr hwndParent, IntPtr hwndChildAfter, string lpszClass, string lpszWindow);
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool PostMessage(IntPtr hWnd, uint Msg, int wParam, int lParam);
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        static extern IntPtr FindWindow(string lpClassName, string lpWindowName);



        private const uint WM_USER = 0x0400;

        private const string RegistRoot = @"HKEY_CURRENT_USER\Software\Tencent";
        private const string WeixinSubKey = "Weixin";
        string installPath = "";
        string decodedVersion="";


        public List<int> FindAllProcessIdsByWindowTitle1(string windowTitle)
        {
            List<int> pids = new List<int>();
            Process[] processes = Process.GetProcesses();
            List<ProcessInfo> processInfos = new List<ProcessInfo>();
            foreach (var proc in processes)
            {
                try
                {
                    // 检查主窗口标题是否包含指定文字
                    //if (!string.IsNullOrEmpty(proc.MainWindowTitle) && proc.MainWindowTitle.Contains(windowTitle))
                    if (!string.IsNullOrEmpty(proc.MainWindowTitle) && proc.MainWindowTitle.Equals(windowTitle, StringComparison.OrdinalIgnoreCase))
                    {
                        pids.Add(proc.Id);
                    }
                }
                catch
                {
                    // 有些进程可能无法访问，会抛异常，忽略它们
                }
            }

            return pids;
        }

        public List<ProcessInfo> FindAllProcessIdsByWindowTitle(string windowTitle)
        {
            List<ProcessInfo> processInfos = new List<ProcessInfo>();
            Process[] processes = Process.GetProcesses();

            foreach (var proc in processes)
            {
                try
                {
                    // 检查主窗口标题是否包含指定文字
                    if (!string.IsNullOrEmpty(proc.MainWindowTitle) && proc.MainWindowTitle.Equals(windowTitle, StringComparison.OrdinalIgnoreCase))
                    {
                        // 获取窗口句柄
                        IntPtr hWnd = proc.MainWindowHandle;

                        // 将进程 ID 和窗口句柄加入列表
                        processInfos.Add(new ProcessInfo
                        {
                            ProcessId = ((uint)proc.Id),
                            WindowHandle = hWnd
                        });
                    }
                }
                catch
                {
                    // 有些进程可能无法访问，会抛异常，忽略它们
                }
            }
            return processInfos;
        }

        private string DecodeFromInteger4(uint encodedVersion)
        {
            int encodedMajor = (int)((encodedVersion >> 24) & 0xFF);
            int encodedMinor = (int)((encodedVersion >> 16) & 0xFF);
            int encodedBuild = (int)((encodedVersion >> 8) & 0xFF);
            int encodedRevision = (int)(encodedVersion & 0xFF);

            var Major = encodedMajor - 238;
            var Minor = encodedMinor - 83;

            // 特殊规则：Build = 0x10 时表示 0
            var Build = (encodedBuild == 0x10) ? 0 : encodedBuild;

            var Revision = encodedRevision;

            if (Major < 0 || Minor < 0)
            {
                throw new ArgumentException("解码后的 Major 或 Minor 为负数，无效的编码版本号");
            }
            return $"{Major}.{Minor}.{Build}.{Revision}";
        }
        private static string GetValue(string subKey, string valueName)
        {
            var fullName = $"{RegistRoot}\\{subKey}";
            object value = Registry.GetValue(fullName, valueName, null)!;

            string result = value switch
            {
                // 关键修复：将DWORD转为无符号再转字符串
                int dword => unchecked((uint)dword).ToString(),
                long qword => new VersionCodec(unchecked((uint)qword)).ToString(),
                string str => str,
                byte[] bytes when bytes.Length == 4 =>
                    BitConverter.ToUInt32(bytes, 0).ToString(), // 处理二进制格式DWORD
                _ => string.Empty
            };

            return result;
        }

   


        private void TriggerPatch(uint cmd)
        {
            PatchHelper.BroadcastPatch(cmd);
            //IntPtr hWnd = FindWindow("RevokePatchMsgWnd", string.Empty); // Replace null with string.Empty
            //if (hWnd == IntPtr.Zero)
            //{
            //    MessageBox.Show("找不到隐藏窗口，DLL可能尚未注入或尚未初始化");
            //    return;
            //}
            //PostMessage(hWnd, cmd, 0, 0);


        }

        public MainWindow()
        {
            InitializeComponent();
            this.Loaded += MainWindow_Loaded;
        }
        string DecodeVersion(uint version)
        {
            byte v1 = (byte)((version >> 24) & 0xFF);
            byte v2 = (byte)((version >> 16) & 0xFF);
            byte v3 = (byte)((version >> 8) & 0xFF);
            byte v4 = (byte)(version & 0xFF);

            // 微信的规则：高位两个字节需要映射
            // if (v1 == 0xF2) v1 = 4;
            // if (v2 == 0x54) v2 = 1;
            return $"{v1}.{v2}.{v3}.{v4}";
           // return $"{v1}.{v2}.{v3}.{v4}";
        }



        private void MainWindow_Loaded(object sender, RoutedEventArgs e)
        {
         
        
        }

      
            public void TryPatchWeChatDll(string wxVersionStr, string patchData)
        {


            if (string.IsNullOrWhiteSpace(wxVersionStr) || string.IsNullOrWhiteSpace(installPath))
            {
                MessageBox.Show("未找到 Weixin 版本或安装路径，请确保微信已安装。", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            string dllPath = $@"{installPath}\{wxVersionStr}\Weixin.dll";

            if (!File.Exists(dllPath))
            {
                MessageBox.Show($"未找到 Weixin.dll 文件：{dllPath}", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            try
            {
             
                if (ApplyPatchToFile(dllPath, patchData))
                {
                    MessageBox.Show("补丁应用成功！", "成功", MessageBoxButton.OK, MessageBoxImage.Information);
                }
                else
                {
                    MessageBox.Show("补丁失败或DLL不兼容。", "失败", MessageBoxButton.OK, MessageBoxImage.Warning);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"补丁过程中发生异常：{ex.Message}", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }


        private void BtnMultiInstancePatch_Click(object sender, RoutedEventArgs e)
        {
            var wxVersionStr = GetValue(WeixinSubKey, "Version");
            installPath = GetValue(WeixinSubKey, "InstallPath");

            if (string.IsNullOrWhiteSpace(wxVersionStr))
            {
                MessageBox.Show("未找到 Weixin 版本或安装路径，请确保微信已安装。", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            if (!uint.TryParse(wxVersionStr, out uint encodedVersion))
            {
                MessageBox.Show("版本号格式无效，无法解析。", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }


            try
            {
                decodedVersion = new VersionCodec(encodedVersion).ToString();

                VersionLabel.Content = $"wx版本号：{decodedVersion}";
            }
            catch (Exception ex)
            {
                MessageBox.Show($"版本解码失败：{ex.Message}", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }



            var config = LoadPatchConfig();
            if (config == null)
                return;

            if (!config.TryGetValue(decodedVersion, out PatchInfo? patchInfo) || patchInfo == null)
            {
                MessageBox.Show($"未在配置中找到版本 {decodedVersion} 的补丁信息。", "版本不支持", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

      
            TryPatchWeChatDll(decodedVersion, patchInfo.position);

     
        }

        private const string ConfigFileName = "wechat_path.txt";


        private void BtnLaunchWeChat_Click(object sender, RoutedEventArgs e)
        {
           
        }

        private void writePatch(uint cmd)
        {

            try
            {
                // 注入 DLL
                string baseDirectory = AppDomain.CurrentDomain.BaseDirectory;
                string dllPath = System.IO.Path.Combine(baseDirectory ?? "", "wxpatch.dll");

                if (!File.Exists(dllPath))
                {
                    MessageBox.Show($"错误：未找到 wxpatch.dll 于 {dllPath}", "文件缺失", MessageBoxButton.OK, MessageBoxImage.Error);
                    return;
                }
                var pids = FindAllProcessIdsByWindowTitle("微信");
              //  var pids = FindAllProcessIds("Weixin.exe");
                if (pids.Count == 0)
                {
                    MessageBox.Show("未找到微信进程。", "错误",
                        MessageBoxButton.OK, MessageBoxImage.Error);
                    return;
                }

                foreach (var info in pids)
                {
                    IntPtr hModule = FindRemoteDll.GetRemoteModuleHandle(info.ProcessId, "wxpatch.dll");
                    if (hModule != IntPtr.Zero)
                    {
                        // 已经注入过
                        continue;
                    }
                    else
                    {
                        InjectToWeChat(info.ProcessId, dllPath);
                        Thread.Sleep(500); // 等待注入完成
                        string className = "RevokePatchMsgWnd";
                        IntPtr childWindowHandle = FindWindowEx(info.WindowHandle, IntPtr.Zero, className, null);

                        PostMessage(childWindowHandle, cmd, 0, 0);
                    }
                }

                // 注入所有进程
                //foreach (uint pid in pids)
                //{
                //    IntPtr hModule = FindRemoteDll.GetRemoteModuleHandle(pid, "wxpatch.dll");
                //    if (hModule != IntPtr.Zero)
                //    {
                //        // 已经注入过
                //        continue;
                //    }
                //    else
                //    {
                //        InjectToWeChat(pid, dllPath);

                //        string className = "RevokePatchMsgWnd";
                //        IntPtr childWindowHandle = FindWindowEx(pid, IntPtr.Zero, className, null);


                //    }
                //}


            }
            catch (DllNotFoundException)
            {
                MessageBox.Show("错误：未找到 wxstart.dll。", "DLL加载错误", MessageBoxButton.OK, MessageBoxImage.Error);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"启动微信时发生错误: {ex.Message}", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
            }




        }

        private Dictionary<string, PatchInfo>? LoadPatchConfig()
        {
            try
            {
                string jsonPath = System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "patch_config.json");
                if (!File.Exists(jsonPath))
                {
                    MessageBox.Show("未找到配置文件 patch_config.json", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
                    return null;
                }

                string jsonContent = File.ReadAllText(jsonPath);
                var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                var config = JsonSerializer.Deserialize<Dictionary<string, PatchInfo>>(jsonContent, options);

                return config;
            }
            catch (Exception ex)
            {
                MessageBox.Show($"读取配置文件失败: {ex.Message}", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
                return null;
            }
        }

        uint ConvertVersionToNumber(string version)
        {
            // 假设格式始终是 major.minor.build.revision
            var parts = version.Split('.');
            if (parts.Length != 4)
                throw new FormatException("Invalid version format");

            return uint.Parse(parts[0]) * 10000u +
                   uint.Parse(parts[1]) * 1000u +
                   uint.Parse(parts[2]) * 100u +
                   uint.Parse(parts[3]);
        }

        private void BtnPatch1_Click(object sender, RoutedEventArgs e)
        {
            //writePatch();
            //Thread.Sleep(2000);

            var wxVersionStr = GetValue(WeixinSubKey, "Version");
            installPath = GetValue(WeixinSubKey, "InstallPath");

            if (string.IsNullOrWhiteSpace(wxVersionStr))
            {
                MessageBox.Show("未找到 Weixin 版本或安装路径，请确保微信已安装。", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            if (!uint.TryParse(wxVersionStr, out uint encodedVersion))
            {
                MessageBox.Show("版本号格式无效，无法解析。", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }


            try
            {
                decodedVersion = new VersionCodec(encodedVersion).ToString();

                VersionLabel.Content = $"wx版本号：{decodedVersion}";
            }
            catch (Exception ex)
            {
                MessageBox.Show($"版本解码失败：{ex.Message}", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            } 
            uint versionNumber = ConvertVersionToNumber(decodedVersion);

            writePatch(WM_USER + versionNumber);
          //  Thread.Sleep(2000);

           // TriggerPatch(WM_USER + versionNumber);
            //if (decodedVersion== "4.0.5.17")
            //{
            //    TriggerPatch(WM_USER + 40517);
            //}
            //else if (decodedVersion == "4.0.5.18")
            //{
            //    TriggerPatch(WM_USER + 40518);
            //}
            //else if (decodedVersion == "4.0.5.23")
            //{
            //    TriggerPatch(WM_USER + 40523);
            //}

            MessageBox.Show("补丁 已打。", "操作提示", MessageBoxButton.OK, MessageBoxImage.Information);

  
        }

        private void BtnMultiInstancePatch41_Click(object sender, RoutedEventArgs e)
        {
            string decodedVersion;
            var wxVersionStr = GetValue(WeixinSubKey, "Version");
            installPath = GetValue(WeixinSubKey, "InstallPath");

            if (string.IsNullOrWhiteSpace(wxVersionStr))
            {
                MessageBox.Show("未找到 Weixin 版本或安装路径，请确保微信已安装。", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            if (!uint.TryParse(wxVersionStr, out uint encodedVersion))
            {
                MessageBox.Show("版本号格式无效，无法解析。", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }


            try
            {
                decodedVersion = DecodeFromInteger4(encodedVersion).ToString();

                VersionLabel.Content = $"wx版本号：{decodedVersion}";
            }
            catch (Exception ex)
            {
                MessageBox.Show($"版本解码失败：{ex.Message}", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }


            var config = LoadPatchConfig();
            if (config == null)
                return;

            if (!config.TryGetValue(decodedVersion, out PatchInfo? patchInfo) || patchInfo == null)
            {
                MessageBox.Show($"未在配置中找到版本 {decodedVersion} 的补丁信息。", "版本不支持", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }


            TryPatchWeChatDll(decodedVersion, patchInfo.position);
        }

        private void BtnLaunchWeChat41_Click(object sender, RoutedEventArgs e)
        {

        }

        private void BtnPatch141_Click(object sender, RoutedEventArgs e)
        {

        }
    }
}