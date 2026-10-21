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
using System.Windows.Interop;



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
        private const int WM_COPYDATA = 0x004A;
        [StructLayout(LayoutKind.Sequential)]
        private struct COPYDATASTRUCT
        {
            public IntPtr dwData;   // 自定义标记
            public int cbData;      // 数据字节长度
            public IntPtr lpData;   // 指向数据（在发送端的内存）
        }


        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr FindWindowEx(IntPtr hwndParent, IntPtr hwndChildAfter, string lpszClass, string lpszWindow);


    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
        static extern IntPtr FindWindow(string lpClassName, string lpWindowName);



        private const uint WM_USER = 0x0400;

        private const string RegistRoot = @"HKEY_CURRENT_USER\Software\Tencent";
        private const string WeixinSubKey = "Weixin";
        string installPath = "";
        string decodedVersion = "";


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



        public MainWindow()
        {
            InitializeComponent();
            this.Loaded += MainWindow_Loaded;
            var contentToSet = GetValue(WeixinSubKey, "Version");


            if (!uint.TryParse(contentToSet, out uint encodedVersion))
            {
                MessageBox.Show("版本号格式无效，无法解析。", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            decodedVersion = encodedVersion.ToString("X8");
            decodedVersion = HexToVersion(decodedVersion);

            VersionLabel.Content = $"wx版本号：{decodedVersion}";


        }

       
        private HwndSource _hwndSource;

        private void MainWindow_Loaded(object sender, RoutedEventArgs e)
        {
            var contentToSet = GetValue(WeixinSubKey, "Version");


            if (!uint.TryParse(contentToSet, out uint encodedVersion))
            {
                MessageBox.Show("版本号格式无效，无法解析。", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            decodedVersion = encodedVersion.ToString("X8");
            decodedVersion = HexToVersion(decodedVersion);

            VersionLabel.Content = $"wx版本号：{decodedVersion}";
            var helper = new WindowInteropHelper(this);
            _hwndSource = HwndSource.FromHwnd(helper.Handle);
            if (_hwndSource != null)
            {
                _hwndSource.AddHook(WndProc);
            }
        }

        private IntPtr WndProc(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
        {
            if (msg == WM_COPYDATA)
            {
                try
                {
                    // 把 lParam 转为 COPYDATASTRUCT
                    COPYDATASTRUCT cds = Marshal.PtrToStructure<COPYDATASTRUCT>(lParam);

                    if (cds.cbData > 0 && cds.lpData != IntPtr.Zero)
                    {
                        // 假设发送端发的是 Unicode (wchar_t*, SendMessageW)
                        // cbData 是字节数，除以 2 得到字符数（UTF-16）
                        int charCount = cds.cbData / 2;
                        // 去掉可能的终结符：若最后是 '\0'，PtrToStringUni 会自动处理
                        string received = Marshal.PtrToStringUni(cds.lpData, charCount);
                        // 如果收到字符串末尾有多余的 '\0'，可以 TrimEnd('\0')

                        // 在 UI 线程上处理（必要时）
                        this.Dispatcher.Invoke(() =>
                        {
                             infoText.Text ="dbkey:"+ received;
                            
                        });
                    }
                }
                catch (Exception ex)
                {
                    // 处理解析异常
                    Debug.WriteLine("处理 WM_COPYDATA 时出错: " + ex);
                }

                handled = true; // 已处理
            }

            return IntPtr.Zero;
        }

        protected override void OnClosed(EventArgs e)
        {
            if (_hwndSource != null)
            {
                _hwndSource.RemoveHook(WndProc);
                _hwndSource = null;
            }
            base.OnClosed(e);
        }





    private void writePatch()
    {
      try
      {
        string baseDirectory = AppDomain.CurrentDomain.BaseDirectory;
        string dllPath = System.IO.Path.Combine(baseDirectory ?? "", "wxpatch.dll");

        if (!File.Exists(dllPath))
        {
          MessageBox.Show($"错误：未找到 wxpatch.dll 于 {dllPath}", "文件缺失", MessageBoxButton.OK, MessageBoxImage.Error);
          return;
        }

        // 1. 读取 config.json
        string configPath = System.IO.Path.Combine(baseDirectory, "config.json");
        ulong patchOffset=0 ; 

        if (File.Exists(configPath))
        {
          try
          {
            string jsonContent = File.ReadAllText(configPath);
            var patchConfig = JsonSerializer.Deserialize<Dictionary<string, string>>(jsonContent);

            if (patchConfig != null && patchConfig.ContainsKey(decodedVersion))
            {
              string hexStr = patchConfig[decodedVersion];
              if (hexStr.StartsWith("0x", StringComparison.OrdinalIgnoreCase))
              {
                hexStr = hexStr.Substring(2);
              }
              patchOffset = Convert.ToUInt64(hexStr, 16);
              //MessageBox.Show($"{hexStr}, {patchOffset}");
            }
            else
            {
              MessageBox.Show($"警告：未在 config.json 中找到版本 [{decodedVersion}] 的防撤回偏移量，将使用默认偏移。", "提示", MessageBoxButton.OK, MessageBoxImage.Warning);
            }
          }
          catch (Exception ex)
          {
            MessageBox.Show($"解析 config.json 失败: {ex.Message}，将使用默认偏移。", "错误", MessageBoxButton.OK, MessageBoxImage.Warning);
          }
        }
        else
        {
          MessageBox.Show("警告：未找到 config.json 配置文件，将使用默认偏移。", "提示", MessageBoxButton.OK, MessageBoxImage.Warning);
        }

        var pids = FindAllProcessIdsByWindowTitle("微信");
        if (pids.Count == 0)
        {
          MessageBox.Show("未找到微信进程。", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
          return;
        }

        foreach (var info in pids)
        {
          IntPtr hModule = FindRemoteDll.GetRemoteModuleHandle(info.ProcessId, "wxpatch.dll");
          if (hModule != IntPtr.Zero)
          {
            // 已经注入过，也可以选择重新发消息
            // continue;   // 如果想支持重复发，就注释掉这行
          }
          else
          {
            DllInjector.InjectDLL(info.ProcessId, dllPath);
          }

          // 等待消息窗口创建（重要！）
          IntPtr msgWnd = IntPtr.Zero;
          for (int i = 0; i < 20; i++)   // 最多等 2 秒
          {
            // 全局查找，不要指定父窗口
            msgWnd = FindWindow("RevokePatchMsgWnd", null);

            if (msgWnd != IntPtr.Zero)
              break;

            Thread.Sleep(100);
          }

          if (msgWnd == IntPtr.Zero)
          {
            MessageBox.Show($"未找到消息窗口，进程ID: {info.ProcessId}", "错误");
            continue;
          }

          // 发送自定义消息
          uint WM_PATCH_ACTION = 0x0400 + 1;   // WM_USER + 1
          PostMessage(msgWnd, WM_PATCH_ACTION, IntPtr.Zero, (IntPtr)patchOffset);
        }



      }
      catch (Exception ex)
      {
        MessageBox.Show($"打补丁时发生错误: {ex.Message}", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
      }
    }




    private void BtnRevoke_Click(object sender, RoutedEventArgs e)
        {

            writePatch();
            MessageBox.Show("补丁已打，正常登录", "操作提示", MessageBoxButton.OK, MessageBoxImage.Information);

        }


    static string HexToVersion(string hex)
    {
      if (string.IsNullOrWhiteSpace(hex) || hex.Length < 5)
        throw new ArgumentException("输入的十六进制字符串无效");

      // 取出最后5个字符
      string tail = hex.Substring(hex.Length - 5);

      // 每一位都当作十六进制解析并转为十进制数字
      int part1 = Convert.ToInt32(tail.Substring(0, 1), 16);
      int part2 = Convert.ToInt32(tail.Substring(1, 1), 16);
      int part3 = Convert.ToInt32(tail.Substring(2, 1), 16);
      int part4 = Convert.ToInt32(tail.Substring(3), 16); // 最后两位转十进制

      // 拼接成全十进制的版本号（例如：4.1.15.83）
      return $"{part1}.{part2}.{part3}.{part4}";
    }


  }
}
