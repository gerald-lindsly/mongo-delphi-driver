object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'MonogDelphiDriver Address Book'
  ClientHeight = 158
  ClientWidth = 363
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object lblName: TLabel
    Left = 8
    Top = 8
    Width = 27
    Height = 13
    Caption = 'Name'
  end
  object lblAddress: TLabel
    Left = 8
    Top = 35
    Width = 39
    Height = 13
    Caption = 'Address'
  end
  object lblCity: TLabel
    Left = 8
    Top = 62
    Width = 19
    Height = 13
    Caption = 'City'
  end
  object lblState: TLabel
    Left = 175
    Top = 62
    Width = 26
    Height = 13
    Caption = 'State'
  end
  object lblZip: TLabel
    Left = 263
    Top = 62
    Width = 14
    Height = 13
    Caption = 'Zip'
  end
  object lblPhone: TLabel
    Left = 8
    Top = 88
    Width = 30
    Height = 13
    Caption = 'Phone'
  end
  object txtName: TEdit
    Left = 57
    Top = 5
    Width = 296
    Height = 21
    TabOrder = 0
  end
  object txtAddress: TEdit
    Left = 57
    Top = 32
    Width = 296
    Height = 21
    TabOrder = 1
  end
  object txtCity: TEdit
    Left = 57
    Top = 59
    Width = 112
    Height = 21
    TabOrder = 2
  end
  object txtState: TEdit
    Left = 207
    Top = 59
    Width = 50
    Height = 21
    TabOrder = 3
  end
  object txtZip: TEdit
    Left = 283
    Top = 59
    Width = 70
    Height = 21
    TabOrder = 4
  end
  object txtPhone: TEdit
    Left = 57
    Top = 86
    Width = 112
    Height = 21
    TabOrder = 5
  end
  object btnClear: TButton
    Left = 8
    Top = 125
    Width = 75
    Height = 25
    Caption = 'Clear'
    TabOrder = 6
    OnClick = btnClearClick
  end
  object btnSave: TButton
    Left = 94
    Top = 125
    Width = 75
    Height = 25
    Caption = 'Save'
    TabOrder = 7
    OnClick = btnSaveClick
  end
  object btnSearch: TButton
    Left = 280
    Top = 125
    Width = 75
    Height = 25
    Caption = 'Search'
    TabOrder = 8
    OnClick = btnSearchClick
  end
  object btnDelete: TButton
    Left = 182
    Top = 125
    Width = 75
    Height = 25
    Caption = 'Delete'
    TabOrder = 9
    OnClick = btnDeleteClick
  end
  object btnPrev: TButton
    Left = 175
    Top = 86
    Width = 18
    Height = 21
    Caption = '<'
    TabOrder = 10
    OnClick = btnPrevClick
  end
  object btnNext: TButton
    Left = 199
    Top = 86
    Width = 18
    Height = 21
    Caption = '>'
    TabOrder = 11
    OnClick = btnNextClick
  end
end
