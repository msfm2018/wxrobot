using System.Diagnostics;
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

using Microsoft.Win32; // Required for OpenFileDialog
using System;
using System.IO;       // Required for Path operations
using System.Reflection; // Required for Assembly.GetExecutingAssembly()
using System.Runtime.InteropServices; // Required for DllImport

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
        public static extern bool PatchWeChatDllFile(string dllPath);

        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

        [DllImport("user32.dll")]
        static extern bool PostMessage(IntPtr hWnd, uint Msg, int wParam, int lParam);

        private const uint WM_USER = 0x0400;

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
        }

        private void BtnMultiInstancePatch_Click(object sender, RoutedEventArgs e)
        {
            OpenFileDialog dlg = new OpenFileDialog
            {
                Filter = "DLL Files (*.dll)|*.dll",
                Title = "请选择要修补的 Weixin.dll 文件",
                InitialDirectory = @"C:\Program Files\Tencent\Weixin\" // Or Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles)
            };
            // Attempt to set a more robust initial directory
            string programFiles = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
            string weixinDir = System.IO.Path.Combine(programFiles, @"Tencent\Weixin\");
            if (Directory.Exists(weixinDir))
            {
                dlg.InitialDirectory = weixinDir;
            }


            if (dlg.ShowDialog() == true)
            {
                string dllPath = dlg.FileName;
                try
                {
                    if (PatchWeChatDllFile(dllPath))
                    {
                        MessageBox.Show("补丁应用成功！", "成功", MessageBoxButton.OK, MessageBoxImage.Information);
                    }
                    else
                    {
                        MessageBox.Show("补丁失败或DLL不兼容。", "失败", MessageBoxButton.OK, MessageBoxImage.Warning);
                    }
                }
                catch (DllNotFoundException)
                {
                    MessageBox.Show("错误：myfilemopen.dll 未找到。", "DLL加载错误", MessageBoxButton.OK, MessageBoxImage.Error);
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"应用补丁时发生未知错误: {ex.Message}", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
                }
            }
        }

        private void BtnLaunchWeChat_Click(object sender, RoutedEventArgs e)
        {
            try
            {
               
                int result = StartWeChatAndInject(""); // Passing empty string as in Delphi
                if (result == 0) // Assuming 0 means success, adjust if needed
                {


                    try
                    {
                        string baseDirectory = AppDomain.CurrentDomain.BaseDirectory;
                        string dllPath = System.IO.Path.Combine(baseDirectory ?? "", "wxpatch.dll");

                        if (!File.Exists(dllPath))
                        {
                            MessageBox.Show($"错误：未找到 wxpatch.dll于 {dllPath}", "文件缺失", MessageBoxButton.OK, MessageBoxImage.Error);
                            return;
                        }

                        int result1 = InjectToWeChat(dllPath);
                        if (result1 == 0)
                        {
                            MessageBox.Show("启动微信。", "操作提示", MessageBoxButton.OK, MessageBoxImage.Information);
                         
                        }
                        else
                        {
                            MessageBox.Show($"InjectToWeChat 返回: {result1}", "操作提示", MessageBoxButton.OK, MessageBoxImage.Warning);
                        }

                    }
                    catch (DllNotFoundException)
                    {
                        MessageBox.Show("错误：wxstart.dll 未找到。", "DLL加载错误", MessageBoxButton.OK, MessageBoxImage.Error);
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show($"准备数据（注入 wxpatch.dll）时发生错误: {ex.Message}", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
                    }


                }
                else
                {
                    MessageBox.Show($"StartWeChatAndInject 返回: {result}", "操作提示", MessageBoxButton.OK, MessageBoxImage.Warning);
                }
            }
            catch (DllNotFoundException)
            {
                MessageBox.Show("错误：wxstart.dll 未找到。", "DLL加载错误", MessageBoxButton.OK, MessageBoxImage.Error);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"启动微信时发生错误: {ex.Message}", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
            }
           
        
        }

       

        private void BtnPatch1_Click(object sender, RoutedEventArgs e)
        {
            TriggerPatch(WM_USER + 40517);
            MessageBox.Show("补丁 1 命令已发送。", "操作提示", MessageBoxButton.OK, MessageBoxImage.Information);

  
        }

        private void BtnPatch2_Click(object sender, RoutedEventArgs e)
        {
            TriggerPatch(WM_USER + 40518);
            MessageBox.Show("补丁 2 命令已发送。", "操作提示", MessageBoxButton.OK, MessageBoxImage.Information);

     
        }
    }
}