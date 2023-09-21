program iobTray;



uses
  Vcl.Forms,
  uFrmMain in 'uFrmMain.pas' {frmSettings},
  Vcl.Themes,
  Vcl.Styles,
  uRequestHandler in 'uRequestHandler.pas' {RequestHandler: TWebModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'ioBroker - Info';
  TStyleManager.TrySetStyle('Windows10 SlateGray');
  Application.CreateForm(TfrmSettings, frmSettings);
  Application.Run;
end.
