unit CatalogDatabase;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  FireDAC.Comp.Client, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Def, FireDAC.Stan.Param, FireDAC.Stan.Async, FireDAC.DApt,
  CatalogModel;

type
  TCatalogDatabase = class
  private
    FConnection: TFDConnection;
    FDriverLink: TFDPhysSQLiteDriverLink;
    FDatabasePath: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Open;
    function Search(const ASearch, AHead: string): TArray<TScrewArticle>;
    function LoadImage(AArticleID: Integer): TMemoryStream;
    function ArticleCount: Integer;
    property Connection: TFDConnection read FConnection;
    property DatabasePath: string read FDatabasePath;
  end;

implementation

uses
  System.IOUtils, Data.DB, FireDAC.FMXUI.Wait, CatalogSeed, AppLogger
  {$IFDEF MSWINDOWS}
  , FireDAC.Phys.SQLiteWrapper.Stat
  {$ENDIF}
  ;

{
  Zweck:
    Erzeugt die datenbankbezogenen FireDAC-Objekte.

  Parameter:
    Siehe Signatur; nicht vorhandene Parameter entfallen.

  Rückgabe:
    Siehe Signatur, soweit vorhanden.

  Hinweise:
    Fehler werden an die aufrufende Schicht weitergereicht.
}
constructor TCatalogDatabase.Create;
begin
  inherited Create;
  FConnection := TFDConnection.Create(nil);
  FDriverLink := TFDPhysSQLiteDriverLink.Create(nil);
  FConnection.LoginPrompt := False;
end;

{
  Zweck:
    Schließt die Datenbankverbindung und gibt Ressourcen frei.

  Parameter:
    Siehe Signatur; nicht vorhandene Parameter entfallen.

  Rückgabe:
    Siehe Signatur, soweit vorhanden.

  Hinweise:
    Fehler werden an die aufrufende Schicht weitergereicht.
}
destructor TCatalogDatabase.Destroy;
begin
  try
    if Assigned(FConnection) and FConnection.Connected then
    begin
      FConnection.Close;
      TAppLogger.Instance.Add('DATENBANK', 'SQLite-Verbindung geschlossen.');
    end;
  except
    on E: Exception do
      TAppLogger.Instance.AddError('Datenbank schließen', E);
  end;
  FConnection.Free;
  FDriverLink.Free;
  inherited;
end;

{
  Zweck:
    Öffnet die beschreibbare SQLite-Datenbank und initialisiert bei Bedarf den Katalog.

  Parameter:
    Siehe Signatur; nicht vorhandene Parameter entfallen.

  Rückgabe:
    Siehe Signatur, soweit vorhanden.

  Hinweise:
    Fehler werden an die aufrufende Schicht weitergereicht.
}
procedure TCatalogDatabase.Open;
var
  LDir: string;
begin
  LDir := TPath.Combine(TPath.GetDocumentsPath, 'MacOSTest');
  ForceDirectories(LDir);
  FDatabasePath := TPath.Combine(LDir, 'MacOSTest.sqlite3');
  FConnection.DriverName := 'SQLite';
  FConnection.Params.Clear;
  FConnection.Params.Values['DriverID'] := 'SQLite';
  FConnection.Params.Values['Database'] := FDatabasePath;
  FConnection.Params.Values['LockingMode'] := 'Normal';
  FConnection.Params.Values['OpenMode'] := 'CreateUTF8';
  FConnection.Connected := True;
  TAppLogger.Instance.Add('DATENBANK', 'SQLite-Verbindung hergestellt.');
  FConnection.StartTransaction;
  try
    if FConnection.ExecSQLScalar(
         'SELECT count(*) FROM sqlite_master WHERE type = ''table'' AND name = ''articles''') > 0 then
      if FConnection.ExecSQLScalar(
           'SELECT count(*) FROM pragma_table_info(''articles'') WHERE name = ''image_jpg''') = 0 then
        FConnection.ExecSQL('ALTER TABLE articles ADD COLUMN image_jpg BLOB');
    InitializeCatalog(FConnection);
    if Integer(FConnection.ExecSQLScalar('PRAGMA user_version')) = 0 then
      FConnection.ExecSQL('PRAGMA user_version = 1');
    FConnection.Commit;
  except
    FConnection.Rollback;
    raise;
  end;
  TAppLogger.Instance.Add('DATENBANK', 'Schema/Migrationsprüfung abgeschlossen.');
end;

{
  Zweck:
    Sucht Artikel mit parametrisierten SQL-Filtern und liefert Datensätze zurück.

  Parameter:
    Siehe Signatur; nicht vorhandene Parameter entfallen.

  Rückgabe:
    Siehe Signatur, soweit vorhanden.

  Hinweise:
    Fehler werden an die aufrufende Schicht weitergereicht.
}
function TCatalogDatabase.Search(const ASearch, AHead: string): TArray<TScrewArticle>;
var
  Q: TFDQuery;
  A: TScrewArticle;
  LItems: TList<TScrewArticle>;
begin
  Q := TFDQuery.Create(nil);
  LItems := TList<TScrewArticle>.Create;
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT id, CAST(sku AS VARCHAR(128)) AS sku, ' +
      'CAST(title AS VARCHAR(255)) AS title, ' +
      'CAST(standard AS VARCHAR(128)) AS standard, ' +
      'CAST(head_type AS VARCHAR(64)) AS head_type, ' +
      'CAST(drive_type AS VARCHAR(64)) AS drive_type, ' +
      'CAST(thread_name AS VARCHAR(32)) AS thread_name, ' +
      'diameter_mm, length_mm, head_diameter_mm, head_height_mm, ' +
      'CAST(material AS VARCHAR(128)) AS material, ' +
      'CAST(finish AS VARCHAR(128)) AS finish, ' +
      'CAST(strength_class AS VARCHAR(64)) AS strength_class, ' +
      'thread_pitch_mm, CAST(ean AS VARCHAR(32)) AS ean, ' +
      'CAST(description AS VARCHAR(2048)) AS description FROM articles ' +
      'WHERE (:head = '''' OR head_type = :head) AND (:search = '''' OR lower(sku) LIKE :pattern OR lower(title) LIKE :pattern ' +
      'OR lower(standard) LIKE :pattern OR lower(thread_name) LIKE :pattern OR lower(description) LIKE :pattern) ' +
      'ORDER BY diameter_mm, length_mm, head_type, finish';
    Q.ParamByName('head').AsString := AHead;
    Q.ParamByName('search').AsString := Trim(ASearch);
    Q.ParamByName('pattern').AsString := '%' + LowerCase(Trim(ASearch)) + '%';
    Q.Open;
    while not Q.Eof do
    begin
      A.ID := Q.FieldByName('id').AsInteger;
      A.SKU := Q.FieldByName('sku').AsString;
      A.Title := Q.FieldByName('title').AsString;
      A.Standard := Q.FieldByName('standard').AsString;
      A.HeadType := Q.FieldByName('head_type').AsString;
      A.DriveType := Q.FieldByName('drive_type').AsString;
      A.ThreadName := Q.FieldByName('thread_name').AsString;
      A.DiameterMM := Q.FieldByName('diameter_mm').AsFloat;
      A.LengthMM := Q.FieldByName('length_mm').AsFloat;
      A.HeadDiameterMM := Q.FieldByName('head_diameter_mm').AsFloat;
      A.HeadHeightMM := Q.FieldByName('head_height_mm').AsFloat;
      A.Material := Q.FieldByName('material').AsString;
      A.Finish := Q.FieldByName('finish').AsString;
      A.Strength := Q.FieldByName('strength_class').AsString;
      A.ThreadPitchMM := Q.FieldByName('thread_pitch_mm').AsFloat;
      A.EAN := Q.FieldByName('ean').AsString;
      A.Description := Q.FieldByName('description').AsString;
      LItems.Add(A);
      Q.Next;
    end;
    Result := LItems.ToArray;
    TAppLogger.Instance.Add('SQL', Format('Artikelsuche ausgeführt: %d Treffer.', [Length(Result)]));
  finally
    LItems.Free;
    Q.Free;
  end;
end;

{
  Zweck:
    Liest die zu einem Artikel gehörende JPEG-Abbildung als Stream.

  Parameter:
    Siehe Signatur; nicht vorhandene Parameter entfallen.

  Rückgabe:
    Siehe Signatur, soweit vorhanden.

  Hinweise:
    Fehler werden an die aufrufende Schicht weitergereicht.
}
function TCatalogDatabase.LoadImage(AArticleID: Integer): TMemoryStream;
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Result := TMemoryStream.Create;
    try
      Q.Connection := FConnection;
      Q.SQL.Text := 'SELECT image_jpg FROM articles WHERE id = :id';
      Q.ParamByName('id').AsInteger := AArticleID;
      Q.Open;
      if (not Q.Eof) and not Q.FieldByName('image_jpg').IsNull then
        TBlobField(Q.FieldByName('image_jpg')).SaveToStream(Result);
      Result.Position := 0;
      TAppLogger.Instance.Add('BILD', Format('JPEG-BLOB geladen: Artikel-ID %d, %d Bytes.', [AArticleID, Result.Size]));
    except
      Result.Free;
      raise;
    end;
  finally
    Q.Free;
  end;
end;

{
  Zweck:
    Ermittelt die Gesamtzahl der gespeicherten Artikel.

  Parameter:
    Siehe Signatur; nicht vorhandene Parameter entfallen.

  Rückgabe:
    Siehe Signatur, soweit vorhanden.

  Hinweise:
    Fehler werden an die aufrufende Schicht weitergereicht.
}
function TCatalogDatabase.ArticleCount: Integer;
begin
  Result := Integer(FConnection.ExecSQLScalar('SELECT count(*) FROM articles'));
end;

end.
