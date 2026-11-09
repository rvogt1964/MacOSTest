unit LogFrame;

interface

uses
  System.SysUtils, System.Classes, FMX.Types, FMX.Controls, FMX.Forms,
  FMX.StdCtrls, FMX.Layouts, FMX.Memo, FMX.Dialogs;

type
  TLogFrame = class(TFrame)
    LayoutActions: TLayout;
    ButtonSave: TButton;
    ButtonClear: TButton;
    ButtonCopy: TButton;
    LabelInfo: TLabel;
    MemoLog: TMemo;
    SaveDialogLog: TSaveDialog;
    TimerLog: TTimer;
    procedure TimerLogTimer(Sender: TObject);
    procedure ButtonSaveClick(Sender: TObject);
    procedure ButtonClearClick(Sender: TObject);
    procedure ButtonCopyClick(Sender: TObject);
  public
    procedure Initialize;
    procedure Shutdown;
  end;

implementation

uses
  FMX.Platform, System.Rtti, AppLogger;

{$R *.fmx}

{ Zweck: Bindet den Log-Frame an den zentralen Logger und zeigt die bisherigen Meldungen an. }
procedure TLogFrame.Initialize;
begin
  MemoLog.Lines.Text := TAppLogger.Instance.Snapshot;
  TimerLog.Enabled := True;
  LabelInfo.Text := 'Laufendes Log: ' + TAppLogger.Instance.LogPath;
end;

{ Zweck: Trennt die Ereignisweitergabe beim Schließen des Hauptformulars. }
procedure TLogFrame.Shutdown;
begin
  TimerLog.Enabled := False;
end;

{ Zweck: Aktualisiert die Protokollanzeige im FMX-Hauptthread, wenn sich ihr Inhalt geändert hat. }
procedure TLogFrame.TimerLogTimer(Sender: TObject);
var
  Text: string;
begin
  Text := TAppLogger.Instance.Snapshot;
  if MemoLog.Lines.Text <> Text then
  begin
    MemoLog.Lines.Text := Text;
    MemoLog.GoToTextEnd;
  end;
end;

{ Zweck: Exportiert die Protokollansicht in eine vom Benutzer gewählte UTF-8-Datei. }
procedure TLogFrame.ButtonSaveClick(Sender: TObject);
begin
  SaveDialogLog.FileName := 'MacOSTest-Log.txt';
  if SaveDialogLog.Execute then
  begin
    try
      TAppLogger.Instance.SaveToFile(SaveDialogLog.FileName);
      TAppLogger.Instance.Add('LOG', 'Protokoll exportiert: ' + SaveDialogLog.FileName);
    except
      on E: Exception do
        TAppLogger.Instance.AddError('Logexport', E);
    end;
  end
  else
    TAppLogger.Instance.Add('LOG', 'Logexport abgebrochen.');
end;

{ Zweck: Löscht die sichtbaren Logeinträge; die historische Datei bleibt unverändert. }
procedure TLogFrame.ButtonClearClick(Sender: TObject);
begin
  MemoLog.Lines.Clear;
  TAppLogger.Instance.Clear;
  TimerLogTimer(Sender);
end;

{ Zweck: Kopiert die aktuell sichtbaren Protokollzeilen in die Zwischenablage. }
procedure TLogFrame.ButtonCopyClick(Sender: TObject);
var
  LClipboard: IFMXClipboardService;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, LClipboard) then
  begin
    LClipboard.SetClipboard(TValue.From<string>(TAppLogger.Instance.Snapshot));
    TAppLogger.Instance.Add('LOG', 'Logansicht in die Zwischenablage kopiert.');
  end
  else
    TAppLogger.Instance.Add('LOG', 'Zwischenablage auf diesem System nicht verfügbar.');
end;

end.
