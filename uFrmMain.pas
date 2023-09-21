unit uFrmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Win.TaskbarCore, Vcl.Taskbar, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls,
  System.ImageList, Vcl.ImgList, Vcl.Menus, System.Notification;

type
  TTraySettings = record
    Endpoint: string;
    Title: string;
    ValueUnit: string;
    Interval: Cardinal;
    IconIndex: Integer;
    Notification: Boolean;
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
    ncToast: TNotificationCenter;
    chkNotification: TCheckBox;
    procedure btnOKClick(Sender: TObject);
    procedure tmrRequestTimer(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure mniExitClick(Sender: TObject);
    procedure mniShowClick(Sender: TObject);
  private
    FSettings: TTraySettings;
    FRunning: Boolean;
    FLastValue: string;
    function GetValue(const AUrl: string): string;
    procedure SetValue();
    procedure PrepareIconList;
  public
    { Public-Deklarationen }
  end;

var
  frmSettings: TfrmSettings;

implementation

uses
  System.UITypes,
  System.NetEncoding,
  IdHTTP,
  XmlIntf,
  XmlDoc;

{$R *.dfm}
{$R iobTrayIcons.res}

const
  ICON_COUNT = 30;

procedure TfrmSettings.FormCreate(Sender: TObject);
begin
  PrepareIconList;
  cmbIcons.ItemIndex := 0;
  if FSettings.Load then
  begin
    edtEndpoint.Text := FSettings.Endpoint;
    edtTitle.Text := FSettings.Title;
    edtUnit.Text := FSettings.ValueUnit;
    edtInterval.Text := FSettings.Interval.ToString;
    cmbIcons.ItemIndex := FSettings.IconIndex;
    chkNotification.Checked := FSettings.Notification;
    if not FRunning and ParamCount.ToBoolean and ParamStr(1).ToLower.Equals('skip') then
    begin
      SetValue;
      FRunning := True;
      Application.ShowMainForm := False;
    end;
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
  FSettings.Notification := chkNotification.Checked;
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

procedure TfrmSettings.PrepareIconList;
var
  i: Integer;
  Icon: TIcon;
  IconName: string;
begin
  cmbIcons.Items.Clear;
  ilIcons.Clear;
  try
    Icon := TIcon.Create;
    try
      for i := 1 to ICON_COUNT do
      begin
        IconName := Format('ICON_%2.2d', [i]);
        Icon.LoadFromResourceName(HInstance, IconName);
        ilIcons.AddIcon(Icon);
        cmbIcons.ItemsEx.AddItem(IconName, i-1, i-1, -1, -1, nil);
      end;
    finally
      Icon.Free;
    end;
  except
    on E:Exception do
      TaskMessageDlg('Error reading icons', E.Message, mtError, [mbOK], 0);
  end;
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
  try
    HTTP := TIdHTTP.Create(nil);
    ContentStream := TStringStream.Create;
    try
      HTTP.Get(AUrl, ContentStream);
      if HTTP.ResponseCode = 200 then
        Result := AnsiDequotedStr(TNetEncoding.URL.Decode(ContentStream.DataString), '"')
      else
        Result := '-/-';
    finally
      ContentStream.Free;
      HTTP.Free;
    end;
  except
    Result := '-/-';
  end;
end;

procedure TfrmSettings.SetValue();
var
  tmpValue: string;
  Notification: TNotification;
  LValue: string;
begin
  LValue := GetValue(FSettings.Endpoint);

  if not FSettings.Title.IsEmpty then
    tmpValue := FSettings.Title + #13 + LValue
  else
    tmpValue := LValue;

  if not FSettings.ValueUnit.IsEmpty then
    tmpValue := Format('%s %s', [tmpValue, FSettings.ValueUnit]);

  trayIcon.Hint := tmpValue;

  if FSettings.Notification and not LValue.Equals(FLastValue) then
  begin
    Notification := ncToast.CreateNotification;
    try
      Notification.Name := 'ioBroker - Info';
      Notification.Title := FSettings.Title;
      Notification.AlertBody := Format('%s %s', [LValue, FSettings.ValueUnit]);
      ncToast.PresentNotification(Notification);
    finally
      Notification.Free;
    end;
    FLastValue := LValue;
  end;

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
  try
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
      Node := XML.DocumentElement.ChildNodes.FindNode('notification');
      if Assigned(Node) then
        Notification := VarAsType(Node.Attributes['value'], varBoolean);
      Result := True;
    finally
      XML := nil;
    end;
  except
    on E:Exception do
      TaskMessageDlg('Error loading settings', E.Message, mtError, [mbOK], 0);
  end;
end;

function TTraySettings.Save: Boolean;
var
  Filename: string;
  XML: IXMLDocument;
  Root, Node: IXMLNode;
begin
  Result := False;
  try
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
      Node := XML.DocumentElement.AddChild('notification');
      Node.Attributes['value'] := Notification.ToString;
      Filename := ChangeFileExt(Application.ExeName, '.cnf');
      xml.SaveToFile(Filename);
      Result := True;
    finally
      XML := nil;
    end;
  except
    on E:Exception do
      TaskMessageDlg('Error saving settings', E.Message, mtError, [mbOK], 0);
  end;
end;

end.
