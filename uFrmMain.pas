unit uFrmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Win.TaskbarCore, Vcl.Taskbar, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls,
  System.ImageList, Vcl.ImgList, Vcl.Menus;

type
  TTraySettings = record
    Endpoint: string;
    Title: string;
    ValueUnit: string;
    Interval: Cardinal;
    IconIndex: Integer;
    function Load: Boolean;
    function Save: Boolean;
  end;

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
    edtTitle: TEdit;
    Label5: TLabel;
    ilIcons: TImageList;
    cmbIcons: TComboBoxEx;
    Label6: TLabel;
    mnuPopup: TPopupMenu;
    mniExit: TMenuItem;
    mniShow: TMenuItem;
    procedure btnOKClick(Sender: TObject);
    procedure tmrRequestTimer(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure mniExitClick(Sender: TObject);
    procedure mniShowClick(Sender: TObject);
  private
    FSettings: TTraySettings;
    FRunning: Boolean;
    function GetValue(const AUrl: string): string;
    procedure SetValue();
  public
    { Public-Deklarationen }
  end;

var
  frmSettings: TfrmSettings;

implementation

uses
  IdHTTP,
  XmlIntf, XmlDoc;

{$R *.dfm}

procedure TfrmSettings.FormCreate(Sender: TObject);
begin
  cmbIcons.ItemIndex := 0;
  if FSettings.Load then
  begin
    edtEndpoint.Text := FSettings.Endpoint;
    edtTitle.Text := FSettings.Title;
    edtUnit.Text := FSettings.ValueUnit;
    edtInterval.Text := FSettings.Interval.ToString;
    cmbIcons.ItemIndex := FSettings.IconIndex;
  end;
end;

procedure TfrmSettings.btnCancelClick(Sender: TObject);
begin
  if FRunning then
    Self.Hide
  else
    Application.Terminate;
end;

procedure TfrmSettings.btnOKClick(Sender: TObject);
begin
  tmrRequest.Interval := StrToInt(edtInterval.Text);
  tmrRequest.Enabled := tmrRequest.Interval > 0;
  trayIcon.IconIndex := cmbIcons.ItemIndex;
  FSettings.Endpoint := edtEndpoint.Text;
  FSettings.Title := edtTitle.Text;
  FSettings.ValueUnit := edtUnit.Text;
  FSettings.Interval := StrToInt(edtInterval.Text);
  FSettings.IconIndex := cmbIcons.ItemIndex;
  FSettings.Save;
  SetValue;
  FRunning := True;
  Self.Hide;
end;

procedure TfrmSettings.mniExitClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TfrmSettings.mniShowClick(Sender: TObject);
begin
  Self.Show;
end;

procedure TfrmSettings.tmrRequestTimer(Sender: TObject);
begin
  SetValue;
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
      Result := '-/-';
  finally
    ContentStream.Free;
    HTTP.Free;
  end;
end;

procedure TfrmSettings.SetValue();
begin
  trayIcon.Hint := FSettings.Title + #13 + GetValue(FSettings.Endpoint) + ' ' + FSettings.ValueUnit;
end;

{ TTraySettings }

function TTraySettings.Load: Boolean;
var
  Filename: string;
  XML: IXMLDocument;
  Node: IXMLNode;
begin
  Filename := ChangeFileExt(Application.ExeName, '.cnf');
  Result := False;
  if FileExists(Filename) then
  begin
    XML := NewXMLDocument('1.0');
    try
      XML.LoadFromFile(Filename);
      Node := XML.DocumentElement.ChildNodes.FindNode('endpoint');
      if Assigned(Node) then
        Endpoint := Node.Attributes['value'];
      Node := XML.DocumentElement.ChildNodes.FindNode('title');
      if Assigned(Node) then
        Title := Node.Attributes['value'];
      Node := XML.DocumentElement.ChildNodes.FindNode('interval');
      if Assigned(Node) then
        Interval := VarAsType(Node.Attributes['value'], varInteger);
      Node := XML.DocumentElement.ChildNodes.FindNode('unit');
      if Assigned(Node) then
        ValueUnit := Node.Attributes['value'];
      Node := XML.DocumentElement.ChildNodes.FindNode('icon');
      if Assigned(Node) then
        IconIndex := VarAsType(Node.Attributes['value'], varInteger);
      Result := True;
    finally
      XML := nil;
    end;
  end;
end;

function TTraySettings.Save: Boolean;
var
  Filename: string;
  XML: IXMLDocument;
  Root, Node: IXMLNode;
begin
  XML := NewXMLDocument('1.0');
  try
    XML.Options := [doNodeAutoIndent];
    XML.ParseOptions := [poPreserveWhiteSpace];
    Root := XML.AddChild('iobTray');
    Node := XML.DocumentElement.AddChild('endpoint');
    Node.Attributes['value'] := Endpoint;
    Node := XML.DocumentElement.AddChild('title');
    Node.Attributes['value'] := Title;
    Node := XML.DocumentElement.AddChild('interval');
    Node.Attributes['value'] := Interval.ToString;
    Node := XML.DocumentElement.AddChild('unit');
    Node.Attributes['value'] := ValueUnit;
    Node := XML.DocumentElement.AddChild('icon');
    Node.Attributes['value'] := IconIndex.ToString;
    Filename := ChangeFileExt(Application.ExeName, '.cnf');
    xml.SaveToFile(Filename);
    Result := True;
  finally
    XML := nil;
  end;
end;

end.
