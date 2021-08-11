unit GGlobal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Generics.Collections, Vcl.StdCtrls;

var
  g_userinfolist: TDictionary<string, string>;    //存储好友信息 wxid  nickname

function get_space(h: THandle; hf: HFont; v2,v1_standard: string): string;

const
  v1_standard = 'WXID_ABCDEFHIJKLMNH'; //微信id19个字符

const
  v2_standard = '北京地铁品牌车门广告独家运营李大山'; // 昵称假设这么30个汉字宽

implementation

//计算空格 对齐使用
function get_space(h: THandle; hf: HFont; v2,v1_standard: string): string;
begin

  var hdc := GetDC(h);

  var sz: tsize;
  SelectObject(hdc, hf);
  GetTextExtentPoint32(hdc, v2, v2.Length, sz);
  var v2width := sz.Width;
  GetTextExtentPoint32(hdc, v1_standard, v1_standard.Length, sz);
  var v1width := sz.Width;
  var v3: string;
  v3 := ' ';
  GetTextExtentPoint32(hdc, v3, v3.Length, sz);
  var v3width := sz.Width;
  var vvwidth :=Round( (v1width - v2width) div v3width) + 10; //后拉10个空格

  ReleaseDC(h, hdc);

  var i: Integer;
  for i := 0 to vvwidth - 1 do
    v2 := v2 + v3;

  result := v2;
end;

initialization
  g_userinfolist := TDictionary<string, string>.create;


finalization
  g_userinfolist.free;

end.

