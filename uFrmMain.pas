unit uFrmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Win.TaskbarCore, Vcl.Taskbar, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls,
  System.ImageList, Vcl.ImgList, Vcl.Menus, IdHTTPWebBrokerBridge, uRequestHandler, System.Notification;

type
  TTraySettings = record
    Endpoint: string;
    Title: string;
    ValueUnit: string;
    Interval: Cardinal;
    IconIndex: Integer;
    Notification: Boolean;
    Port: Word;
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
    chkNotification: TCheckBox;
    ncNotify: TNotificationCenter;
    Label7: TLabel;
    edtPort: TEdit;
    procedure btnOKClick(Sender: TObject);
    procedure tmrRequestTimer(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure mniExitClick(Sender: TObject);
    procedure mniShowClick(Sender: TObject);
    procedure chkNotificationClick(Sender: TObject);
  private
    FSettings: TTraySettings;
    FRunning: Boolean;
    FServer: TIdHTTPWebBrokerBridge;
    FSilent: Boolean;
    function GetValue(const AUrl: string): string;
    procedure SetValue();
    procedure PrepareIconList;
    procedure StartServer;
    procedure ParseSettings;
  protected
    procedure WndProc(var Message: TMessage); override;
  public
  end;

  TNotificationParser = class(TStringList)
  private
    FBody: string;
    FTitle: string;
  public
    constructor Create(const ANotification: string); reintroduce;
    property Title: string read FTitle;
    property Body: string read FBody;
  end;

  TTextMessage = record
    Msg: Cardinal;
    MsgFiller: TDWordFiller;
    WParam: Integer;
    LParam: String;
    Result: LRESULT;
  end;

var
  frmSettings: TfrmSettings;
  RequestHandler: TRequestHandler;

implementation

uses
  System.UITypes,
  System.NetEncoding,
  IdHTTP,
  IdServerIOHandler,
  XmlIntf,
  XmlDoc,
  Web.WebReq;

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
    edtPort.Text := FSettings.Port.ToString;
    if not FRunning and ParamCount.ToBoolean and ParamStr(1).ToLower.Equals('skip') then
    begin
      FSilent := True;
      ParseSettings;
      SetValue;
      FRunning := True;
      Application.ShowMainForm := False;
    end;
    if FSettings.Notification then
      StartServer;
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
  // Enable message if notifications or port has been changed
  if (chkNotification.Checked <> FSettings.Notification) or (edtPort.Text <> FSettings.Port.ToString) then
    FSilent := False;
  ParseSettings;
  FSettings.Save;
  SetValue;
  FRunning := True;
  Self.Hide;
  StartServer;
end;

procedure TfrmSettings.chkNotificationClick(Sender: TObject);
begin
  edtPort.Enabled := chkNotification.Checked;
end;

procedure TfrmSettings.mniExitClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TfrmSettings.mniShowClick(Sender: TObject);
begin
  Self.Show;
end;

procedure TfrmSettings.ParseSettings;
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
  FSettings.Port := StrToInt(edtPort.Text);
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

procedure TfrmSettings.WndProc(var Message: TMessage);
var
  Notification: TNotification;
  LContent: TNotificationParser;
begin
  if Message.Msg <> UM_NOTIFY then
    inherited WndProc(Message)
  else begin
    Notification := ncNotify.CreateNotification;
    try
      LContent := TNotificationParser.Create(TTextMessage(Message).LParam);
      try
        Notification.Title := LContent.Title;
        Notification.AlertBody := LContent.Body;
      finally
        LContent.Free;
      end;
      ncNotify.PresentNotification(Notification);
    finally
      Notification.Free;
    end;
  end;
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

end;

procedure TfrmSettings.StartServer;
begin
  try
    if WebRequestHandler <> nil then
      WebRequestHandler.WebModuleClass := MyRequestHandler;

    if not Assigned(FServer) then
      FServer := TIdHTTPWebBrokerBridge.Create(Self)
    else
      FServer.Active := False;

    FServer.DefaultPort := FSettings.Port;
    FServer.Active := True;

    if not FSilent then
      TaskMessageDlg('Server started', 'Server is listening on port ' + FSettings.Port.ToString, mtInformation, [mbOK], 0);

  except
    on E:Exception do
      TaskMessageDlg('Error starting server', E.Message, mtError, [mbOK], 0);
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
      Node := XML.DocumentElement.ChildNodes.FindNode('port');
      if Assigned(Node) then
        Port := VarAsType(Node.Attributes['value'], varWord);
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
      Node := XML.DocumentElement.AddChild('port');
      Node.Attributes['value'] := Port.ToString;
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

{ TNotificationParser }

constructor TNotificationParser.Create(const ANotification: string);
begin
  Delimiter := '&';
  DelimitedText := ANotification;
  NameValueSeparator := '=';
  Self[0] := TNetEncoding.URL.Decode(Self[0], [], TEncoding.UTF8);
  Self[1] := TNetEncoding.URL.Decode(Self[1], [], TEncoding.UTF8);
  FTitle := Values['title'];
  FBody := Values['body'];
end;

end.
