object main: Tmain
  Left = 0
  Top = 0
  Caption = #24494#20449#21161#25163
  ClientHeight = 619
  ClientWidth = 1310
  Color = clGray
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  DesignSize = (
    1310
    619)
  TextHeight = 16
  object pnlQr: TPanel
    Left = 0
    Top = 0
    Width = 1310
    Height = 619
    Align = alClient
    BevelOuter = bvNone
    Color = 16119285
    ParentBackground = False
    TabOrder = 2
    object imgQr: TImage
      Left = 495
      Top = 97
      Width = 257
      Height = 247
      Stretch = True
    end
    object btnQr: TButton
      Left = 559
      Top = 34
      Width = 98
      Height = 33
      Caption = #25195#25551#30331#24405
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      OnClick = btnQrClick
    end
  end
  object pnl_left: TPanel
    Left = 1
    Top = 1
    Width = 91
    Height = 616
    Anchors = [akLeft, akTop, akBottom]
    BevelEdges = []
    BevelOuter = bvNone
    Color = 16423497
    ParentBackground = False
    TabOrder = 0
    DesignSize = (
      91
      616)
    object l2: TLabel
      AlignWithMargins = True
      Left = -2
      Top = 197
      Width = 93
      Height = 40
      Cursor = crHandPoint
      Alignment = taCenter
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = #28040#24687#22238#25191
      Color = 1748250
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = True
      Layout = tlCenter
      OnClick = l2Click
      ExplicitWidth = 91
    end
    object l1: TLabel
      AlignWithMargins = True
      Left = -2
      Top = 141
      Width = 93
      Height = 40
      Cursor = crHandPoint
      Margins.Left = 8
      Margins.Top = 8
      Margins.Right = 8
      Margins.Bottom = 8
      Alignment = taCenter
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = #36890#35759#24405
      Color = 1748250
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
      Layout = tlCenter
      OnClick = l1Click
      ExplicitWidth = 91
    end
    object l5: TLabel
      Left = -2
      Top = 564
      Width = 93
      Height = 40
      Cursor = crHandPoint
      Alignment = taCenter
      Anchors = [akLeft, akRight, akBottom]
      AutoSize = False
      Caption = #35774#32622
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      OnClick = l5Click
      ExplicitTop = 583
      ExplicitWidth = 91
    end
    object l3: TLabel
      AlignWithMargins = True
      Left = -2
      Top = 252
      Width = 93
      Height = 40
      Cursor = crHandPoint
      Margins.Left = 8
      Margins.Top = 8
      Margins.Right = 8
      Margins.Bottom = 8
      Alignment = taCenter
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = #28040#24687
      Color = 1748250
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = True
      Layout = tlCenter
      OnClick = l3Click
      ExplicitWidth = 91
    end
  end
  object pnl_right: TPanel
    Left = 89
    Top = 1
    Width = 1220
    Height = 617
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelEdges = []
    BevelOuter = bvNone
    Color = 16119285
    ParentBackground = False
    TabOrder = 1
    object PageControl1: TPageControl
      Left = 0
      Top = 0
      Width = 1220
      Height = 617
      ActivePage = TabSheet1
      Align = alClient
      Style = tsFlatButtons
      TabOrder = 0
      object TabSheet1: TTabSheet
        Caption = #36890#35759#24405
        object Panel2: TPanel
          Left = 0
          Top = 0
          Width = 1212
          Height = 583
          Align = alClient
          BevelEdges = []
          BevelOuter = bvNone
          Caption = 'Panel2'
          Color = 16119285
          ParentBackground = False
          TabOrder = 0
          object Panel1: TPanel
            Left = 0
            Top = 482
            Width = 1212
            Height = 101
            Align = alBottom
            BevelEdges = []
            BevelOuter = bvNone
            Color = 16119285
            Ctl3D = False
            ParentBackground = False
            ParentCtl3D = False
            TabOrder = 0
            DesignSize = (
              1212
              101)
            object Button2: TButton
              Left = 1105
              Top = 31
              Width = 106
              Height = 45
              Anchors = [akRight, akBottom]
              Caption = #21457#36865
              Font.Charset = GB2312_CHARSET
              Font.Color = clWindowText
              Font.Height = -29
              Font.Name = #23435#20307
              Font.Style = []
              ParentFont = False
              TabOrder = 0
            end
            object Edit1: TEdit
              Left = 1
              Top = 31
              Width = 1097
              Height = 45
              Anchors = [akLeft, akRight, akBottom]
              BorderStyle = bsNone
              Font.Charset = GB2312_CHARSET
              Font.Color = clWindowText
              Font.Height = -48
              Font.Name = #23435#20307
              Font.Style = []
              ParentFont = False
              TabOrder = 1
              Text = 'ok'
              OnMouseEnter = Edit1MouseEnter
              OnMouseLeave = Edit1MouseLeave
            end
          end
          object lv1: TListView
            Left = 0
            Top = 41
            Width = 1212
            Height = 441
            Align = alClient
            BevelEdges = []
            BevelInner = bvNone
            BevelOuter = bvNone
            BorderStyle = bsNone
            Checkboxes = True
            Color = 16119285
            Columns = <
              item
                AutoSize = True
                Caption = 'WXID'
              end
              item
                Caption = #24494#20449#21495
                Width = 200
              end
              item
                Caption = #26165#31216
                Width = 300
              end
              item
                Caption = #22791#27880
                Width = 380
              end>
            Ctl3D = False
            FlatScrollBars = True
            GridLines = True
            ReadOnly = True
            RowSelect = True
            ShowWorkAreas = True
            TabOrder = 1
            ViewStyle = vsReport
            ExplicitTop = 33
            ExplicitHeight = 449
          end
          object Panel5: TPanel
            Left = 0
            Top = 0
            Width = 1212
            Height = 41
            Align = alTop
            BevelOuter = bvNone
            Caption = 'Panel5'
            TabOrder = 2
            ExplicitLeft = 560
            ExplicitTop = 104
            ExplicitWidth = 185
            object edtLookup: TSearchBox
              Left = 0
              Top = 0
              Width = 1089
              Height = 41
              Align = alClient
              Alignment = taCenter
              BevelEdges = [beBottom]
              BevelInner = bvNone
              BevelKind = bkSoft
              BevelOuter = bvNone
              BorderStyle = bsNone
              Color = 16119285
              Ctl3D = False
              Font.Charset = GB2312_CHARSET
              Font.Color = clWindowText
              Font.Height = -29
              Font.Name = #23435#20307
              Font.Style = []
              ParentCtl3D = False
              ParentFont = False
              TabOrder = 0
              TextHint = #25628#32034#20851#38190#23383#22238#36710
              StyleElements = []
              OnKeyPress = edtLookupKeyPress
              ButtonWidth = 0
              ExplicitLeft = 1
              ExplicitTop = 1
              ExplicitWidth = 1000
              ExplicitHeight = 39
            end
            object Button4: TButton
              Left = 1089
              Top = 0
              Width = 123
              Height = 41
              Align = alRight
              Caption = #21047#26032#29992#25143#25968#25454
              TabOrder = 1
              OnClick = Button4Click
              ExplicitLeft = 1088
              ExplicitTop = 1
              ExplicitHeight = 39
            end
          end
        end
      end
      object TabSheet3: TTabSheet
        Caption = #28040#24687
        ImageIndex = 2
        object lv_recv: TListView
          Left = 0
          Top = 0
          Width = 1212
          Height = 583
          Align = alClient
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          Color = clWhite
          Columns = <>
          Ctl3D = False
          DoubleBuffered = True
          Font.Charset = GB2312_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = #23435#20307
          Font.Style = []
          ReadOnly = True
          RowSelect = True
          ParentDoubleBuffered = False
          ParentFont = False
          ParentShowHint = False
          ShowWorkAreas = True
          ShowHint = True
          TabOrder = 0
        end
      end
      object TabSheet4: TTabSheet
        Caption = #35774#32622
        ImageIndex = 3
        object BtnExport: TButton
          Left = 3
          Top = 95
          Width = 126
          Height = 39
          Caption = #23548#20986#22909#21451#21015#34920#25968#25454
          Font.Charset = GB2312_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = #23435#20307
          Font.Style = []
          ParentFont = False
          TabOrder = 0
        end
        object CheckBox1: TCheckBox
          Left = 7
          Top = 44
          Width = 97
          Height = 20
          Caption = #28040#24687#20813#25171#25200
          Font.Charset = GB2312_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = #23435#20307
          Font.Style = []
          ParentFont = False
          TabOrder = 1
        end
        object Button1: TButton
          Left = 3
          Top = 161
          Width = 126
          Height = 39
          Caption = #22810#24320#24494#20449
          TabOrder = 2
        end
        object CheckBox2: TCheckBox
          Left = 162
          Top = 45
          Width = 119
          Height = 17
          Caption = #28040#24687#38450#25764#22238
          TabOrder = 3
        end
        object Button3: TButton
          Left = 3
          Top = 216
          Width = 126
          Height = 41
          Caption = #36864#20986'WX'
          TabOrder = 4
          OnClick = Button3Click
        end
      end
      object TabSheet2: TTabSheet
        Caption = #28040#24687#22238#25191
        ImageIndex = 1
        object Panel3: TPanel
          Left = 0
          Top = 499
          Width = 1212
          Height = 84
          Align = alBottom
          BevelEdges = []
          BevelOuter = bvNone
          Color = 16119285
          Ctl3D = False
          DoubleBuffered = True
          Font.Charset = GB2312_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = #23435#20307
          Font.Style = []
          ParentBackground = False
          ParentCtl3D = False
          ParentDoubleBuffered = False
          ParentFont = False
          TabOrder = 0
          DesignSize = (
            1212
            84)
          object Label5: TLabel
            Left = 5
            Top = 17
            Width = 78
            Height = 13
            Caption = #21246#36873#33258#21160#22238#22797
          end
          object Memo1: TEdit
            Left = 137
            Top = 5
            Width = 1075
            Height = 60
            Anchors = [akLeft, akTop, akRight, akBottom]
            BorderStyle = bsNone
            Color = 16119285
            Font.Charset = GB2312_CHARSET
            Font.Color = clBlack
            Font.Height = -48
            Font.Name = #23435#20307
            Font.Style = []
            ParentFont = False
            TabOrder = 0
            Text = 'ok'
            OnMouseEnter = Memo1MouseEnter
            OnMouseLeave = Memo1MouseLeave
          end
        end
        object lb__receipt: TCheckListBox
          Left = 0
          Top = 33
          Width = 1212
          Height = 466
          Align = alClient
          BevelEdges = [beBottom]
          BevelOuter = bvNone
          BevelKind = bkTile
          BorderStyle = bsNone
          Color = clWhite
          CheckBoxPadding = 6
          Font.Charset = GB2312_CHARSET
          Font.Color = clBlack
          Font.Height = -15
          Font.Name = #23435#20307
          Font.Style = []
          ItemHeight = 21
          ParentFont = False
          TabOrder = 1
        end
        object SearchBox1: TSearchBox
          Left = 0
          Top = 0
          Width = 1212
          Height = 33
          Align = alTop
          Alignment = taCenter
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          Color = 16119285
          Ctl3D = False
          DoubleBuffered = True
          Font.Charset = GB2312_CHARSET
          Font.Color = clWindowText
          Font.Height = -29
          Font.Name = #23435#20307
          Font.Style = []
          ParentCtl3D = False
          ParentDoubleBuffered = False
          ParentFont = False
          TabOrder = 2
          TextHint = #25628#32034#20851#38190#23383#22238#36710
          StyleElements = []
          ButtonWidth = 0
        end
      end
    end
  end
  object SaveTextFileDialog1: TSaveTextFileDialog
    Filter = 'txt|*.txt'
    Left = 616
    Top = 240
  end
  object XMLDoc: TXMLDocument
    Left = 824
    Top = 376
  end
end
