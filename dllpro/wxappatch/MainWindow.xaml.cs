using Microsoft.Win32; // Required for OpenFileDialog
using MultiWeixin.Assist;
using System;
using System.Diagnostics;
using System.IO;       // Required for Path operations
using System.Reflection; // Required for Assembly.GetExecutingAssembly()
using System.Runtime.InteropServices; // Required for DllImport
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using System.Text.Json;
using System.Text.Json.Serialization; // Don't forget this using directive

public class PatchInfo
{
    //[JsonConverter(typeof(HexStringToIntArrayConverter))]
    public string position { get; set; }
}


namespace WpfAppMultiPatch
{
  
    public partial class MainWindow : Window
    {
        // DLL imports
        [DllImport("wxstart.dll", CharSet = CharSet.Unicode)]
        public static extern int StartWeChatAndInject(string dllPath);

        [DllImport("wxstart.dll", CharSet = CharSet.Unicode)]
        public static extern int InjectToWeChat(string dllPath);

        [DllImport("myfilemopen.dll", CharSet = CharSet.Unicode)]
        [return: MarshalAs(UnmanagedType.Bool)]

        public static extern bool ApplyPatchToFile(
        [MarshalAs(UnmanagedType.LPWStr)] string dllPath, // wchar_t* 对应 C# 的 string，需要 MarshalAs 指定类型
         [MarshalAs(UnmanagedType.LPWStr)] string patchData 
  
    );

   


        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

        [DllImport("user32.dll")]
        static extern bool PostMessage(IntPtr hWnd, uint Msg, int wParam, int lParam);

        private const uint WM_USER = 0x0400;

        private const string RegistRoot = @"HKEY_CURRENT_USER\Software\Tencent";
        private const string WeixinSubKey = "Weixin";
        string installPath = "";
        string decodedVersion="";

        private static string GetValue(string subKey, string valueName)
        {
            var fullName = $"{RegistRoot}\\{subKey}";
            object value = Registry.GetValue(fullName, valueName, null)!;

            string result = value switch
            {
                // 关键修复：将DWORD转为无符号再转字符串
                int dword => unchecked((uint)dword).ToString(),
                string str => str,
                byte[] bytes when bytes.Length == 4 =>
                    BitConverter.ToUInt32(bytes, 0).ToString(), // 处理二进制格式DWORD
                _ => string.Empty
            };

            return result;
        }

        private void TriggerPatch(uint cmd)
        {
            IntPtr hWnd = FindWindow("RevokePatchMsgWnd", string.Empty); // Replace null with string.Empty
            if (hWnd == IntPtr.Zero)
            {
                MessageBox.Show("找不到隐藏窗口，DLL可能尚未注入或尚未初始化");
                return;
            }

            PostMessage(hWnd, cmd, 0, 0);
        }

        public MainWindow()
        {
            InitializeComponent();
            this.Loaded += MainWindow_Loaded;
        }

        private void MainWindow_Loaded(object sender, RoutedEventArgs e)
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
            try
            {

                // 启动微信进程
                Process weChatProcess = new Process
                {
                    StartInfo = new ProcessStartInfo
                    {
                        //FileName = weChatPath,
                        FileName = installPath + @"\Weixin.exe",
                        UseShellExecute = false
                    }
                };

                weChatProcess.Start();

                // 等待微信加载
                Thread.Sleep(2000);

                // 注入 DLL
                string baseDirectory = AppDomain.CurrentDomain.BaseDirectory;
                string dllPath = System.IO.Path.Combine(baseDirectory ?? "", "wxpatch.dll");

                if (!File.Exists(dllPath))
                {
                    MessageBox.Show($"错误：未找到 wxpatch.dll 于 {dllPath}", "文件缺失", MessageBoxButton.OK, MessageBoxImage.Error);
                    return;
                }

                int result = InjectToWeChat(dllPath);
                if (result == 0)
                {
                    //MessageBox.Show("微信已启动。", "成功", MessageBoxButton.OK, MessageBoxImage.Information);
                }
                else
                {
                    MessageBox.Show($"InjectToWeChat 返回: {result}", "注入失败", MessageBoxButton.OK, MessageBoxImage.Warning);
                }
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
            uint versionNumber = ConvertVersionToNumber(decodedVersion);
            TriggerPatch(WM_USER + versionNumber);
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

   
    }
}