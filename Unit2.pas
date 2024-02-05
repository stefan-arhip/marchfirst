unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, GifImage, jpeg;

type
  TForm2 = class(TForm)
    Image1: TImage;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    Rise: Boolean;
    IsVisible: Boolean;
  protected
    procedure CreateParams (Var Params: TCreateParams); Override;
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

Uses Unit1;

procedure TForm2.FormCreate(Sender: TObject);
begin
  If FileExists(AppDir+ BasketFile) Then
    Form2.Image1.Picture.LoadFromFile(AppDir+ BasketFile);

  Form2.AlphaBlend:= True;
  Rise:= True;
  IsVisible:= False;
  Form2.ClientWidth:= Image1.Width;
  Form2.ClientHeight:= Image1.Height;
  Case AnimationType Of
    0:
      Begin
        Form2.AlphaBlend:= False;
        Form2.AlphaBlendValue:= 255;
        Form2.Left:= (Screen.Width- Form2.Width) Div 2;
        Form2.Top:= Screen.Height;
      End;
    1:
      Begin
        Form2.AlphaBlend:= True;
        Form2.AlphaBlendValue:= 0;
        Form2.Left:= (Screen.Width- Form2.Width) Div 2;
        Form2.Top:= Screen.Height- Form2.Height;
      End;
  End;
end;

procedure TForm2.Timer1Timer(Sender: TObject);
begin
{$Region '    Show basket   '}
  If Form2.Rise Then
    Case AnimationType Of
      0:
        Begin
          Form2.Top:= Form2.Top- 10;
          Form2.Refresh;
          If Form2.Top<= Screen.Height- Form2.Height Then
            Timer1.Enabled:= False;
        End;
      1:
        Begin
          If Not Form2.IsVisible Then
            Begin
              Form2.AlphaBlend:= True;
              Form2.AlphaBlendValue:= 0;
              Form2.Show;
              Form2.IsVisible:= True;
            End;
          Form2.AlphaBlendValue:= Form2.AlphaBlendValue+ 5;
          Form2.Refresh;
          If Form2.AlphaBlendValue>= 255 Then
            Timer1.Enabled:= False;
        End;
    End
{$EndRegion}

{$Region '    Hide basket   '}
  Else
    Case AnimationType Of
      0:
        Begin
          Form2.Top:= Form2.Top+ 10;
          Form2.Refresh;
          If Form2.Top> Screen.Height Then
            Begin
              Timer1.Enabled:= False;
              Form2.IsVisible:= False;
              Close;
            End;
        End;
      1:
        Begin
          Form2.AlphaBlend:= True;
          Form2.AlphaBlendValue:= Form2.AlphaBlendValue- 5;
          Form2.Refresh;
          If Form2.AlphaBlendValue<= 0 Then
            Begin
              Form2.IsVisible:= False;
              Timer1.Enabled:= False;
              Form2.Close;
            End;
        End;
    End;
{$EndRegion}
end;

procedure TForm2.CreateParams(var Params: TCreateParams);
begin
  Inherited CreateParams(Params);
{$Region '   Stay on top + Hide taskbar button + Transparent + No title bar   }
  With Params Do
    Begin
      WndParent := GetDesktopWindow;
      Style := Style And Not WS_Caption;
      ExStyle := ExStyle Or WS_EX_TopMost Or WS_EX_ToolWindow Or WS_EX_Transparent;
    End;
{$EndRegion}
end;

end.
