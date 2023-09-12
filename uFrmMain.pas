unit uFrmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Win.TaskbarCore, Vcl.Taskbar, Vcl.ExtCtrls, Vcl.StdCtrls;

type
  TfrmSettings = class(TForm)
    trayIcon: TTrayIcon;
    Label1: TLabel;
    edtEndpoint: TEdit;
    Label2: TLabel;
    edtInterval: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    edtUnit: TEdit;
    btnOK: TButton;
    btnCancel: TButton;
    tmrRequest: TTimer;
    procedure btnOKClick(Sender: TObject);
    procedure tmrRequestTimer(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    function GetValue(const AUrl: string): string;
  public
    { Public-Deklarationen }
  end;

var
  frmSettings: TfrmSettings;

implementation

uses
  IdHTTP;

{$R *.dfm}

procedure TfrmSettings.btnCancelClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TfrmSettings.btnOKClick(Sender: TObject);
begin
  tmrRequest.Interval := StrToInt(edtInterval.Text);
  tmrRequest.Enabled := tmrRequest.Interval > 0;
  trayIcon.Hint := GetValue(edtEndpoint.Text) + ' ' + edtUnit.Text;
  Self.Hide;
end;

function TfrmSettings.GetValue(const AUrl: string): string;
var
  HTTP: TIdHTTP;
  ContentStream: TStringStream;
begin
  HTTP := TIdHTTP.Create(nil);
  ContentStream := TStringStream.Create;
  try
    HTTP.Get(AUrl, ContentStream);
    if HTTP.ResponseCode = 200 then
      Result := ContentStream.DataString
    else
      Result := '?';
  finally
    ContentStream.Free;
    HTTP.Free;
  end;
end;

procedure TfrmSettings.tmrRequestTimer(Sender: TObject);
begin
  trayIcon.Hint := GetValue(edtEndpoint.Text) + ' ' + edtUnit.Text;
end;

end.
