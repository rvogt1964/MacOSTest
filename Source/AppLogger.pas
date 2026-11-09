unit AppLogger;

interface

uses
  System.SysUtils, System.Classes;

type
  TAppLogger = class
  private
    FEntries: TStringList;
    FLogPath: string;
    FArchivePath: string;
    FPersistenceFailed: Boolean;
    constructor Create;
  public
    destructor Destroy; override;
    class function Instance: TAppLogger;
    procedure Add(const ACategory, AMessage: string);
    procedure AddError(const ACategory: string; const E: Exception);
    procedure SaveToFile(const AFileName: string);
    procedure Clear;
    function Snapshot: string;
    property LogPath: string read FLogPath;
  end;

implementation

uses
  System.IOUtils;

var
  AppLog: TAppLogger;

const
  MaxLogBytes = 5 * 1024 * 1024;
  MaxLogEntries = 2000;

{ Zweck: Bereitet den Sitzungspuffer und die Pfade der beiden Protokolldateien vor. }
constructor TAppLogger.Create;
begin
  inherited Create;
  FEntries := TStringList.Create;
  FLogPath := TPath.Combine(TPath.Combine(TPath.GetDocumentsPath, 'MacOSTest'),
    'MacOSTest.log');
  FArchivePath := FLogPath + '.1';
end;

{ Zweck: Gibt den Sitzungspuffer nach Ende der Protokollierung frei. }
destructor TAppLogger.Destroy;
begin
  FEntries.Free;
  inherited;
end;

{ Zweck: Liefert die für die gesamte Programmlaufzeit verfügbare Logger-Instanz. }
class function TAppLogger.Instance: TAppLogger;
begin
  Result := AppLog;
end;

{ Zweck: Schreibt AMessage unter ACategory in die Sitzungsanzeige und ins rotierende Protokoll. }
procedure TAppLogger.Add(const ACategory, AMessage: string);
var
  Line: string;
begin
  TMonitor.Enter(Self);
  try
    Line := FormatDateTime('[dd.mm.yyyy hh:nn:ss.zzz]', Now) +
      ' [' + ACategory + '] ' +
      Copy(AMessage.Replace(#13, ' ').Replace(#10, ' '), 1, 2000);
    FEntries.Add(Line);
    if FEntries.Count > MaxLogEntries then
      FEntries.Delete(0);
    try
      ForceDirectories(TPath.GetDirectoryName(FLogPath));
      if TFile.Exists(FLogPath) and (TFile.GetSize(FLogPath) >= MaxLogBytes) then
      begin
        if TFile.Exists(FArchivePath) then
          TFile.Delete(FArchivePath);
        TFile.Move(FLogPath, FArchivePath);
      end;
      TFile.AppendAllText(FLogPath, Line + sLineBreak, TEncoding.UTF8);
      FPersistenceFailed := False;
    except
      FPersistenceFailed := True;
    end;
  finally
    TMonitor.Exit(Self);
  end;
end;

{ Zweck: Protokolliert Klasse und Meldung der übergebenen Ausnahme E. }
procedure TAppLogger.AddError(const ACategory: string; const E: Exception);
begin
  Add('FEHLER/' + ACategory, E.ClassName + ': ' + E.Message);
end;

{ Zweck: Exportiert die aktuelle Sitzung nach AFileName und schützt die Historie. }
procedure TAppLogger.SaveToFile(const AFileName: string);
begin
  if SameText(TPath.GetFullPath(AFileName), FLogPath) or
     SameText(TPath.GetFullPath(AFileName), FArchivePath) then
    raise EInOutError.Create('Das laufende Protokoll und sein Archiv sind keine Exportziele.');
  TFile.WriteAllText(AFileName, Snapshot, TEncoding.UTF8);
end;

{ Zweck: Leert den Sitzungspuffer und protokolliert den Vorgang. }
procedure TAppLogger.Clear;
begin
  TMonitor.Enter(Self);
  try
    FEntries.Clear;
    Add('LOG', 'Sichtbare Logeinträge gelöscht.');
  finally
    TMonitor.Exit(Self);
  end;
end;

{ Zweck: Liefert eine konsistente Textkopie für Anzeige und Export. }
function TAppLogger.Snapshot: string;
begin
  TMonitor.Enter(Self);
  try
    Result := FEntries.Text;
    if FPersistenceFailed then
      Result := Result + 'Das Protokoll konnte zuletzt nicht auf die Festplatte geschrieben werden.' + sLineBreak;
  finally
    TMonitor.Exit(Self);
  end;
end;

initialization
  AppLog := TAppLogger.Create;

finalization
  AppLog.Free;

end.
