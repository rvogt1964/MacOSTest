unit MainForm;

interface

uses
  System.SysUtils, System.Classes, FMX.Types, FMX.Controls, FMX.Forms,
  FMX.TabControl, FMX.StdCtrls, FMX.Layouts,
  CatalogFrame, AboutFrame, LogFrame, CatalogDatabase;

type
  TMainForm = class(TForm)
    TabControlMain: TTabControl;
    TabCatalog: TTabItem;
    TabLog: TTabItem;
    TabAbout: TTabItem;
    FrameCatalog: TCatalogFrame;
    FrameAbout: TAboutFrame;
    FrameLog: TLogFrame;
    procedure TabControlMainChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FDatabase: TCatalogDatabase;
  end;

var
  MainWindow: TMainForm;

implementation

uses FMX.Dialogs, AppLogger;

{$R *.fmx}

{
  Zweck:
    Öffnet die Datenbank und richtet den Katalog und die Loganzeige ein.

  Parameter:
    Siehe Signatur; nicht vorhandene Parameter entfallen.

  Rückgabe:
    Siehe Signatur, soweit vorhanden.

  Hinweise:
    Fehler werden an die aufrufende Schicht weitergereicht.
}
procedure TMainForm.FormCreate(Sender: TObject);
begin
  FrameLog.Initialize;
  TAppLogger.Instance.Add('APP', 'MacOSTest gestartet; Bundle-ID de.rvogt.macostest.');
  try
    FDatabase := TCatalogDatabase.Create;
    FDatabase.Open;
    TAppLogger.Instance.Add('DATENBANK', 'SQLite geöffnet: ' + FDatabase.DatabasePath);
    FrameCatalog.Initialize(FDatabase);
    TAppLogger.Instance.Add('KATALOG', 'Artikeldatenbank initialisiert.');
    TabControlMain.ActiveTab := TabCatalog;
  except
    on E: Exception do
    begin
      TAppLogger.Instance.AddError('Start/Datenbank', E);
      ShowMessage('Der Schraubenkatalog konnte nicht geladen werden: ' + E.Message);
      FrameCatalog.Enabled := False;
    end;
  end;
end;

{
  Zweck:
    Gibt die Datenbankverbindung beim Beenden frei.

  Parameter:
    Siehe Signatur; nicht vorhandene Parameter entfallen.

  Rückgabe:
    Siehe Signatur, soweit vorhanden.

  Hinweise:
    Fehler werden an die aufrufende Schicht weitergereicht.
}
procedure TMainForm.FormDestroy(Sender: TObject);
begin
  TAppLogger.Instance.Add('APP', 'MacOSTest wird beendet.');
  if Assigned(FrameLog) then
    FrameLog.Shutdown;
  FDatabase.Free;
end;

{ Zweck: Protokolliert jeden Wechsel zwischen Katalog, Log und Über mich. }
procedure TMainForm.TabControlMainChange(Sender: TObject);
begin
  if TabControlMain.ActiveTab <> nil then
    TAppLogger.Instance.Add('NAVIGATION', 'Tab geöffnet: ' + TabControlMain.ActiveTab.Text);
end;

end.
