unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Buttons, Menus, ShellApi, IniFiles, GifImage, Jpeg;

Const WM_IconTray = WM_User + 2006; //dummy value

type
  TForm1 = class(TForm)
    Image1: TImage;
    Timer1: TTimer;
    Timer2: TTimer;
    PopupMenu1: TPopupMenu;
    Close1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure Close1Click(Sender: TObject);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Timer1Timer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure Image1MouseEnter(Sender: TObject);
    procedure Image1MouseLeave(Sender: TObject);
  private
    { Private declarations }
    TrayIconData: ShellApi.TNotifyIconData;
    Procedure TrayMessage(Var Msg: TMessage); Message WM_IconTray;
  public
    { Public declarations }
    Rise: Boolean;
    IsVisible: Boolean;
  end;

  PLastInputInfo = ^TLastInputInfo;

  {$ExternalSym TagLastInputInfo}
  TagLastInputInfo = Record
                       cbSize: Integer;   // The size of the structure, in bytes. This member must be set to SizeOf(LastInputInfo)
                       dwTime: Cardinal;  // The tick count when the last input event was received.
                     End;
  TLastInputInfo = TagLastInputInfo;

  {$ExternalSym GetLastInputInfo}
  Function GetLastInputInfo(Var ALastInputInfo: TLastInputInfo): Integer; StdCall;

var
  Form1: TForm1;
  vIdleTime : Cardinal;
  Old: TPoint;
  MoveOn: Boolean;
  IdleSeconds, AnimationType, DistanceFromLeft, DistanceFromTop: Integer;
  AppDir, BasketFile, HintFile, TrinketFile: String;


implementation

uses Unit2;

{$R *.dfm}

Function GetLastInputInfo; StdCall; External 'user32.dll';

Function GetUserIdleDuration: Cardinal;
Var vLastInput: TLastInputInfo;
Begin
  vLastInput.cbSize := SizeOf(TLastInputInfo);

  If GetLastInputInfo(vLastInput)<> 0 Then
    Result := GetTickCount - vLastInput.dwTime
  Else
    Result := 0;
End;

procedure TForm1.TrayMessage(var Msg: TMessage);
Var p : TPoint;
begin
  Case Msg.lParam Of
    WM_LButtonDown:
      Begin
        SetForegroundWindow(Handle);
        GetCursorPos(p);
        PopupMenu1.Popup(p.x, p.y);
        PostMessage(Handle, WM_Null, 0, 0);
      End;
  End;
end;

procedure TForm1.Close1Click(Sender: TObject);
begin
  Close;
end;

procedure TForm1.FormCreate(Sender: TObject);
Var f: TIniFile;
begin
{$Region '    Read settings   '}
  AppDir       := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)));

  Rise         := False;
  IsVisible    := True;

  vIdleTime    := 0;
  IdleSeconds  := 5;
  AnimationType:= 1;   //0-rise, 1-blend
  BasketFile   := '';
  HintFile     := '';
  TrinketFile  := '';
  f:= TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
  Try
    IdleSeconds     := f.ReadInteger('Basket' , 'Idle'              , IdleSeconds);
    AnimationType   := f.ReadInteger('Basket' , 'Animation'         , AnimationType);
    BasketFile      := f.ReadString ('Basket' , 'File'              , BasketFile);
    
    TrinketFile     := f.ReadString ('Trinket', 'File'              , TrinketFile);
    DistanceFromLeft:= f.ReadInteger('Trinket', 'Distance from Left', DistanceFromLeft);
    DistanceFromTop := f.ReadInteger('Trinket', 'Distance from Top' , DistanceFromTop);

    HintFile        := f.ReadString ('Hint'   , 'File'              , HintFile);
  Finally
    f.Free;
  End;
{$EndRegion}

  If FileExists(AppDir+ TrinketFile) Then
    Image1.Picture.LoadFromFile(AppDir+ TrinketFile);

  Form1.ClientWidth := Image1.Width;
  Form1.ClientHeight:= Image1.Height;
  Form1.Left        := Screen.Width- Form1.Width- DistanceFromLeft;
  Form1.Top         := DistanceFromTop;


{$Region '    Display tray icon   '}
  With TrayIconData Do
    Begin
      cbSize := SizeOf(TrayIconData);
      Wnd := Handle;
      uID := 0;
      uFlags := Nif_Message + Nif_Icon + Nif_Tip;
      uCallbackMessage := WM_IconTray;
      hIcon := Application.Icon.Handle;
      StrPCopy(szTip, Application.Title);
    End;

  Shell_NotifyIcon(Nim_Add, @TrayIconData);
{$EndRegion}

{$Region  '    Hide application from taskbar   '}
  ShowWindow(Application.Handle, SW_Hide);
  SetWindowLong(Application.Handle, GWL_ExStyle, GetWindowLong(Application.Handle, GWL_ExStyle) or WS_EX_ToolWindow);
  ShowWindow(Application.Handle, SW_Show);
{$EndRegion}
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  Shell_NotifyIcon(Nim_Delete, @TrayIconData);
end;

procedure TForm1.Image1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  MoveOn:= True;
  Old.X := X;
  Old.Y := Y;
end;

procedure TForm1.Image1MouseEnter(Sender: TObject);
begin
  If FileExists(AppDir+ HintFile) Then
    Image1.Picture.LoadFromFile(AppDir+ HintFile);    

  Form1.ClientWidth := Image1.Width;
  Form1.ClientHeight:= Image1.Height;
end;

procedure TForm1.Image1MouseLeave(Sender: TObject);
begin
  If FileExists(AppDir+ TrinketFile) Then
    Image1.Picture.LoadFromFile(AppDir+ TrinketFile);

  Form1.ClientWidth := Image1.Width;
  Form1.ClientHeight:= Image1.Height;
end;

procedure TForm1.Image1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  MoveOn:= False;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
Var vLastInput: TLastInputInfo;
begin
{$Region '    Detect idle   '}
  vLastInput.cbSize:= SizeOf(TLastInputInfo);
  vLastInput.dwTime:= 0;

  If GetLastInputInfo(vLastInput)<> 0 Then
    vIdleTime:= GetTickCount- vLastInput.dwTime
  Else
    vIdleTime:= 0;
{$EndRegion}

{$Region '    Create basket   '}
  If Integer(vIdleTime Div 1000)> Integer(IdleSeconds) Then
    Begin
      If Not Form2.IsVisible Then
        Begin
          Form2.Rise:= True;
          Form2.Show;
          Form2.IsVisible:= True;
          Form2.Timer1.Enabled:= True;

          Form1.Rise:= False;
          Form1.Timer2.Enabled:= True;
        End;
    End
{$EndRegion}

{$Region '    Hide basket   '}
  Else
    Begin
      If Form2.IsVisible Then
        Begin
          Form2.Rise:= False;
          Form2.Timer1.Enabled:= True;

          Form1.Rise:= True;
          //Form1.Show;
          Form1.IsVisible:= True;
          Form1.Timer2.Enabled:= True;
        End;
    End;
{$EndRegion}

end;

procedure TForm1.Timer2Timer(Sender: TObject);
begin
{$Region '    Show trinket   '}
  If Form1.Rise Then
    Begin
      If Not Form1.IsVisible Then
        Begin
          Form1.AlphaBlend:= False;
          Form1.AlphaBlendValue:= 0;
          //Form1.Show;
          Form1.IsVisible:= True;
        End;
      Form1.AlphaBlendValue:= Form1.AlphaBlendValue+ 5;
      Form1.Refresh;
      If Form1.AlphaBlendValue>= 255 Then
        Timer2.Enabled:= False;
    End
{$EndRegion}

{$Region '    Hide trinket   '}
  Else
    Begin
      Form1.AlphaBlend:= True;
      Form1.AlphaBlendValue:= Form1.AlphaBlendValue- 5;
      Form1.Refresh;
      If Form1.AlphaBlendValue<= 0 Then
        Begin
          Form1.IsVisible:= False;
          Timer2.Enabled:= False;
          //Form1.Hide;
        End;
    End;
{$EndRegion}
end;

procedure TForm1.Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  If MoveOn Then
    Begin
      Left:= (Left- Old.X)+ X;
      Top := (Top - Old.Y)+ Y;
    End;
end;

end.
