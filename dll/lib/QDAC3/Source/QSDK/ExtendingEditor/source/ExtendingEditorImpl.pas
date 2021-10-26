{ ******************************************************* }
{ QSDK.Wechat.iOS 1.0                                     }
{ Interfaces for libWeChatSDK 1.7.1                       }
{ Created by TU2(Ticr),and agree to share with QSDK       }
{ ******************************************************* }

{
    编辑器增强  by tutu (QQ: 245806497)
}
unit ExtendingEditorImpl;

interface

uses
  SysUtils, Classes, ToolsAPI, CodeTemplateAPI, System.RegularExpressionsCore;

type
  /// <summary>简单的属性代码自动生成工具</summary>
  /// <remarks>
  /// 1、属性成员需使用 FXXX: Type; 形式定义
  /// 2、属性自动添加到类结尾end行上一行
  /// 3、支持生成三种属性：Alt+P(读写)、Alt+M(只写)、Alt+L(只读)
  /// </remarks>
  TExtendingEditorWizardBinding = class(TNotifierObject, IOTAKeyboardBinding)
  private
  protected
    FRegEx : TPerlRegEx ;
    function GetPropertyInfo(const Expression: string;out nameStr: string; out typeStr: string):Boolean;
    function GetClassRegions(const Module: IOTAModule; var Regions:TOTARegions): Integer;
    procedure AutoGenerateProperty(const Context: IOTAKeyContext; KeyCode: TShortCut; var BindingResult: TKeyBindingResult);
  public
    constructor Create;
    destructor Destroy; override;
    // IOTAKeyBoardBinding
    function GetBindingType: TBindingType;
    function GetDisplayName: string;
    function GetName: string;
    procedure BindKeyboard(const BindingServices: IOTAKeyBindingServices);
  end;

  /// <summary>模板值插入引擎</summary>
  TInsertValueScriptEngine = class(TNotifierObject, IOTACodeTemplateScriptEngine)
  protected
    {IOTACodeTemplateScriptEngine}
    function GetIDString: WideString;
    function GetLanguage: WideString;
    procedure Execute(const ATemplate: IOTACodeTemplate; const APoint: IOTACodeTemplatePoint;
      const ASyncPoints: IOTASyncEditPoints; const AScript: IOTACodeTemplateScript; var Cancel: Boolean);
  end;

procedure Register;

implementation

uses SyncObjs, Windows, Vcl.Menus, Vcl.Dialogs, Vcl.Clipbrd;

procedure Register;
begin
  (BorlandIDEServices as IOTAKeyBoardServices).AddKeyboardBinding(TExtendingEditorWizardBinding.Create);
  (BorlandIDEServices as IOTACodeTemplateServices).RegisterScriptEngine(TInsertValueScriptEngine.Create);
end;

{ TExtendingEditorExpertBinding }

procedure TExtendingEditorWizardBinding.BindKeyboard(const BindingServices: IOTAKeyBindingServices);
begin
  //自动生成属性快捷键
  BindingServices.AddKeyBinding([Shortcut(Ord('P'), [ssAlt])],
    AutoGenerateProperty, nil);

  BindingServices.AddKeyBinding([Shortcut(Ord('L'), [ssAlt])],
    AutoGenerateProperty, nil);

  BindingServices.AddKeyBinding([Shortcut(Ord('M'), [ssAlt])],
    AutoGenerateProperty, nil);
end;

constructor TExtendingEditorWizardBinding.Create;
begin
    inherited;
    FRegEx := TPerlRegEx.Create;
    FRegEx.Options := [preCaseLess];
end;

destructor TExtendingEditorWizardBinding.Destroy;
begin
  FRegEx.Free;
  inherited;
end;

function TExtendingEditorWizardBinding.GetBindingType: TBindingType;
begin
    Result := btPartial;
end;

function TExtendingEditorWizardBinding.GetDisplayName: string;
begin
// The way it should appear in the IDE's Editor Options, Key Mappings
    Result := 'ExtendingEditorWizard By TU2';
end;

function TExtendingEditorWizardBinding.GetName: string;
begin
    Result := 'ExtendingEditorWizard By TU2';
end;

procedure TExtendingEditorWizardBinding.AutoGenerateProperty(
  const Context: IOTAKeyContext; KeyCode: TShortCut;
  var BindingResult: TKeyBindingResult);
const
    CS_P = 'property %s: %s read F%0:s write F%0:s;';
    CS_W = 'property %s: %s write F%0:s;';
    CS_R = 'property %s: %s read F%0:s;';
var
    IEditBuffer: IOTAEditBuffer;
    IEditPos: IOTAEditPosition;
    IEditBlock: IOTAEditBlock;
    ClassRegions: TOTARegions;
    liv_Ret,I,curRow: Integer;
    LineText,nameStr,TypeStr: string;
    Key: Word;
    ShiftState: TShiftState;
begin
  try
    IEditBuffer := Context.EditBuffer;
    //检查是否是在类内
    liv_Ret := GetClassRegions(IEditBuffer.Module, ClassRegions);
    if liv_Ret=-2 then
        raise Exception.Create('还有语法错误！');
    if liv_Ret=-1 then
        raise Exception.Create('当前编辑器不支持！');
    if liv_Ret=0 then
        raise Exception.Create('未发现类型定义！');

    IEditPos := IEditBuffer.EditPosition;
    IEditBlock := IEditBuffer.EditBlock;
    if IEditBlock.Size>0 then
    begin
        curRow := IEditBlock.StartingRow;
        if curRow<>IEditBlock.EndingRow then
            Exit;
    end else
        curRow := IEditPos.Row;

    for I := 0 to liv_Ret-1 do
    with ClassRegions[i] do
    begin
        if (Start.Line<curRow) and (Stop.Line>curRow) then
            Break;
    end;

    if I=liv_Ret then
       raise Exception.Create('当前不处于类型定义之内！');

    //获取当前行内容
    IEditPos.Save;
    IEditBlock.Save;
    IEditPos.Move(curRow,1);
    IEditBlock.BeginBlock;
    IEditPos.MoveEOL;
    IEditBlock.EndBlock;
    if IEditBlock.Size>0 then
    if GetPropertyInfo(IEditBlock.Text,nameStr,typeStr) then
    begin
        //就在最后一行前面加一列
        IEditPos.Move(ClassRegions[i].Stop.Line-1,1);
        IEditPos.MoveEOL;
        ShortCutToKey(KeyCode, Key, ShiftState);
        case Chr(Key) of
        'L': LineText := CS_R;
        'M': LineText := CS_W;
        else
             LineText := CS_P;
        end;

        LineText := #13#10 + Format(LineText,[nameStr,TypeStr]);
        IEditPos.InsertText(LineText);

        BindingResult := krHandled;
    end else
        raise Exception.Create('当前行未发现标准格式的成员声明！');
    IEditPos.Restore;
    IEditBlock.Restore;
  except
    on E:Exception do
        ApplicationShowException(E);
  end;
  ClassRegions := nil;
end;

function TExtendingEditorWizardBinding.GetClassRegions(const Module: IOTAModule;
  var Regions: TOTARegions): Integer;
var
    ModuleErrors: IOTAModuleErrors;
    Errors: TOTAErrors;
    ModuleRegions: IOTAModuleRegions;
    AllRegions: TOTARegions;
    I: Integer;
begin
    if Supports(Module, IOTAModuleErrors, ModuleErrors) then
    begin
        Errors := ModuleErrors.GetErrors(Module.CurrentEditor.FileName);
        if Length(Errors)>0 then
        begin
            Errors := nil;
            Exit(-2);    //语法错
        end;
        Errors := nil;
    end;

    Result := -1;   //不支持

    if Supports(Module, IOTAModuleRegions, ModuleRegions) then
    begin
        Result := 0;
        AllRegions := ModuleRegions.GetRegions(Module.CurrentEditor.FileName);

        for I := 0 to Length(AllRegions)-1 do
        begin
            if AllRegions[i].RegionKind = rkType then
            begin
                Inc(Result);
                SetLength(Regions,Result);
                Regions[0] := AllRegions[i];
            end;
        end;

        AllRegions := nil;
    end;
end;

function TExtendingEditorWizardBinding.GetPropertyInfo(const Expression: string;
    out nameStr: string; out typeStr: string):Boolean;
begin
    //'^(\s*)(?:(.))';
    typeStr := '';
    nameStr := '';
    Result := False;
    FRegEx.Subject := Expression;
    // FA: Type; 形如此类
    FRegEx.RegEx := '^\s*F\w+\s*:\s*\w+\s*;\s*';
    if FRegEx.Match then
    begin
        FRegEx.Subject := FRegEx.MatchedText;
        FRegEx.RegEx := '\s+';
        FRegEx.Replacement := '';
        FRegEx.ReplaceAll;
        FRegEx.RegEx := '^F\w+:';
        if FRegEx.Match then
        begin
            nameStr := FRegEx.MatchedText.Substring(1,
                FRegEx.MatchedText.Length-2);

            FRegEx.RegEx := ':\w+;$';
            if FRegEx.Match then
            begin
                typeStr := FRegEx.MatchedText.Substring(1,
                    FRegEx.MatchedText.Length-2);
                Result := True;
            end;
        end;
    end;
end;

{ TInsertValueScriptEngine }

procedure TInsertValueScriptEngine.Execute(const ATemplate: IOTACodeTemplate;
  const APoint: IOTACodeTemplatePoint; const ASyncPoints: IOTASyncEditPoints;
  const AScript: IOTACodeTemplateScript; var Cancel: Boolean);
var
  sType, sFormat: string;

  procedure InsertGuid;
  var
    AGuid: TGUID;
    sTemp: string;
  begin
    CreateGUID(AGuid);
    sTemp := GUIDToString(AGuid);
    if sFormat<>'' then
      sTemp := Format(sFormat, [sTemp]);
    APoint.Value := sTemp;
  end;

  procedure InsertNow;
  begin
    if sFormat='' then
      APoint.Value := DateTimeToStr(Now)
    else APoint.Value := FormatDateTime(sFormat, Now);
  end;

var
  AStrList: TStringList;
begin
  Cancel := True;
  try
    AStrList := TStringList.Create;
    try
      AStrList.Delimiter := ';';
      AStrList.StrictDelimiter := True;
      AStrList.DelimitedText := AScript.Script;
      sType := AStrList.Values['Type'];
      sFormat := AStrList.Values['Format'];
      if CompareText(sType, 'GUID')=0 then
        InsertGuid
      else if CompareText(sType, 'DateTime')=0 then
        InsertNow;
    finally
      AStrList.Free;
    end;
    Cancel := False;
  except
  end;
end;

function TInsertValueScriptEngine.GetIDString: WideString;
begin
  Result := '{98731108-92C9-4AA3-9EA3-AF018BF44309}';
end;

function TInsertValueScriptEngine.GetLanguage: WideString;
begin
  Result := 'InsertValue';
end;

end.
