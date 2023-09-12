program iobTray;

uses
  Vcl.Forms,
  uFrmMain in 'uFrmMain.pas' {frmSettings},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Charcoal Dark Slate');
  Application.CreateForm(TfrmSettings, frmSettings);
  Application.Run;
end.
