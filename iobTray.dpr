program iobTray;

uses
  Vcl.Forms,
  uFrmMain in 'uFrmMain.pas' {frmSettings};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmSettings, frmSettings);
  Application.Run;
end.
