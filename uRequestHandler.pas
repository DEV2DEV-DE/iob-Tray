unit uRequestHandler;

interface

uses
  System.SysUtils, System.Classes, Web.HTTPApp, System.Notification, Winapi.Windows, Winapi.Messages;

type
  TRequestHandler = class(TWebModule)
    procedure WebModuleCreate(Sender: TObject);
    procedure WebModuleDestroy(Sender: TObject);
    procedure RequestHandlerActionBrokerAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
  private
    procedure Notify(ATitle, ABody: string);
  end;

const
  UM_NOTIFY = WM_USER + 1;

var
  MyRequestHandler: TComponentClass = TRequestHandler;

implementation

{$R *.dfm}

uses
  Winapi.ActiveX, ufrmMain, System.Messaging;

{ TRequestHandler }

procedure TRequestHandler.Notify(ATitle, ABody: string);
begin
  PostMessage(frmSettings.Handle, UM_NOTIFY, 0, LongInt(PChar(ABody)));
end;

procedure TRequestHandler.RequestHandlerActionBrokerAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  Notify('', Request.Query);
  Response.StatusCode := 200;
end;

procedure TRequestHandler.WebModuleCreate(Sender: TObject);
begin
//
end;

procedure TRequestHandler.WebModuleDestroy(Sender: TObject);
begin
//
end;

end.
