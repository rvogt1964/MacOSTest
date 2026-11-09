unit CatalogSeed;

interface

uses FireDAC.Comp.Client;

procedure InitializeCatalog(AConnection: TFDConnection);

implementation

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, System.StrUtils, System.Math,
  FMX.Types, FMX.Graphics, FMX.Surfaces, FireDAC.Stan.Param, Data.DB, AppLogger;

{ Zweck: Kodiert ABitmap als JPEG in AStream und setzt den Stream zum Lesen zurück. }
procedure EncodeJPEG(ABitmap: TBitmap; AStream: TStream);
var
  Surface: TBitmapSurface;
begin
  Surface := TBitmapSurface.Create;
  try
    Surface.Assign(ABitmap);
    if not TBitmapCodecManager.SaveToStream(AStream, Surface, '.jpg') then
      raise EStreamError.Create('JPEG-Kodierung fehlgeschlagen.');
    AStream.Position := 0;
  finally
    Surface.Free;
  end;
end;

{
  Zweck:
    Zeichnet ein schematisches, produktspezifisches Schraubenbild als JPEG für die Artikeldatenbank.

  Parameter:
    Siehe Signatur; nicht vorhandene Parameter entfallen.

  Rückgabe:
    Siehe Signatur, soweit vorhanden.

  Hinweise:
    Fehler werden an die aufrufende Schicht weitergereicht.
}
function CreateScrewImage(const ACountersunk: Boolean; const ADiameter, ALength: Integer;
  const AStainless: Boolean): TMemoryStream;
var
  B: TBitmap;
  C: TCanvas;
  X, EndX, HeadX, ShaftY: Single;
  I: Integer;
  LColor: TAlphaColor;
begin
  B := TBitmap.Create(360, 180);
  try
    C := B.Canvas;
    if C.BeginScene then
    try
      C.Clear($FFF8FAFC);
      HeadX := 44;
      ShaftY := 92;
      EndX := 310;
      if AStainless then LColor := $FFB1BBC8 else LColor := $FF8B9DAA;
      C.Fill.Color := LColor;
      C.FillRect(TRectF.Create(HeadX + 48, ShaftY - 13, EndX, ShaftY + 13), 3, 3, AllCorners, 1);
      C.Stroke.Kind := TBrushKind.Solid;
      C.Stroke.Thickness := 1.5;
      C.Stroke.Color := $FF526273;
      for I := 0 to 17 do
      begin
        X := HeadX + 54 + I * 12;
        C.DrawLine(PointF(X, ShaftY + 12), PointF(X + 7, ShaftY - 12), 0.8);
      end;
      if ACountersunk then
      begin
        C.Fill.Color := LColor;
        C.FillPolygon([PointF(HeadX - 3, ShaftY - 29), PointF(HeadX + 12, ShaftY - 29),
          PointF(HeadX + 52, ShaftY - 13), PointF(HeadX + 52, ShaftY + 13),
          PointF(HeadX + 12, ShaftY + 29), PointF(HeadX - 3, ShaftY + 29)], 1);
      end
      else
      begin
        C.Fill.Color := LColor;
        C.FillRect(TRectF.Create(HeadX, ShaftY - 32, HeadX + 53, ShaftY + 32), 8, 8, AllCorners, 1);
      end;
      C.Fill.Color := $FF506070;
      C.FillEllipse(TRectF.Create(HeadX + 10, ShaftY - 17, HeadX + 38, ShaftY + 17), 1);
      C.Fill.Color := $FFDCE3EA;
      C.FillPolygon([PointF(HeadX + 15, ShaftY - 6), PointF(HeadX + 27, ShaftY - 13),
        PointF(HeadX + 35, ShaftY - 4), PointF(HeadX + 35, ShaftY + 7),
        PointF(HeadX + 23, ShaftY + 13), PointF(HeadX + 15, ShaftY + 5)], 1);
    finally
      C.EndScene;
    end;
    Result := TMemoryStream.Create;
    try
      EncodeJPEG(B, Result);
    except
      Result.Free;
      raise;
    end;
  finally
    B.Free;
  end;
end;

{
  Zweck:
    Konvertiert gegebenenfalls vorhandene PNG-BLOBs einer älteren Datenbank in JPEG-BLOBs.

  Parameter:
    AConnection - Offene SQLite-Verbindung.

  Hinweise:
    Die Konvertierung erfolgt nur für Datensätze ohne JPEG und belässt Altbestände als Backup.
}
procedure MigrateLegacyImages(AConnection: TFDConnection);
var
  Q, UpdateQ: TFDQuery;
  InputStream, OutputStream: TMemoryStream;
  Bitmap: TBitmap;
begin
  if AConnection.ExecSQLScalar(
       'SELECT count(*) FROM pragma_table_info(''articles'') WHERE name = ''image_png''') = 0 then Exit;
  Q := nil;
  UpdateQ := nil;
  Bitmap := nil;
  try
    Q := TFDQuery.Create(nil);
    UpdateQ := TFDQuery.Create(nil);
    Bitmap := TBitmap.Create;
    Q.Connection := AConnection;
    UpdateQ.Connection := AConnection;
    Q.SQL.Text := 'SELECT id, image_png FROM articles WHERE image_jpg IS NULL AND image_png IS NOT NULL';
    UpdateQ.SQL.Text := 'UPDATE articles SET image_jpg = :img WHERE id = :id';
    Q.Open;
    while not Q.Eof do
    begin
      InputStream := nil;
      OutputStream := nil;
      try
        InputStream := TMemoryStream.Create;
        OutputStream := TMemoryStream.Create;
        TBlobField(Q.FieldByName('image_png')).SaveToStream(InputStream);
        InputStream.Position := 0;
        try
          Bitmap.LoadFromStream(InputStream);
        except
          on E: EBitmapLoadingFailed do
          begin
            TAppLogger.Instance.AddError('Altbild Artikel-ID ' +
              Q.FieldByName('id').AsString, E);
            Q.Next;
            Continue;
          end;
        end;
        EncodeJPEG(Bitmap, OutputStream);
        UpdateQ.ParamByName('id').AsInteger := Q.FieldByName('id').AsInteger;
        UpdateQ.ParamByName('img').LoadFromStream(OutputStream, ftBlob);
        UpdateQ.ExecSQL;
      finally
        OutputStream.Free;
        InputStream.Free;
      end;
      Q.Next;
    end;
  finally
    Bitmap.Free;
    UpdateQ.Free;
    Q.Free;
  end;
end;

{
  Zweck:
    Erzeugt die SQLite-Tabelle und ihre Indizes; bestückt einen leeren Katalog
    transaktional mit Schraubenartikeln und JPEG-BLOBs.

  Parameter:
    AConnection - Geöffnete und beschreibbare FireDAC-SQLite-Verbindung.

  Hinweise:
    Eine vorhandene Artikeltabelle wird nicht überschrieben.
}
procedure InitializeCatalog(AConnection: TFDConnection);
const
  Diameters: array[0..7] of Integer = (3, 4, 5, 6, 8, 10, 12, 16);
  Lengths: array[0..9] of Integer = (8, 10, 12, 16, 20, 25, 30, 35, 40, 50);
  Pitch: array[0..7] of Double = (0.5, 0.7, 0.8, 1.0, 1.25, 1.5, 1.75, 2.0);
var
  Q: TFDQuery;
  D, L, Head, Finish: Integer;
  HType, Std, MaterialName, Coating, Strength, SKU, TitleText: string;
  Img: TMemoryStream;
  DMM, LMM: Integer;
begin
  AConnection.ExecSQL('CREATE TABLE IF NOT EXISTS articles (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT, sku TEXT NOT NULL UNIQUE, ' +
    'title TEXT NOT NULL, standard TEXT NOT NULL, head_type TEXT NOT NULL, ' +
    'drive_type TEXT NOT NULL, thread_name TEXT NOT NULL, ' +
    'diameter_mm REAL NOT NULL, length_mm REAL NOT NULL, ' +
    'head_diameter_mm REAL NOT NULL, head_height_mm REAL NOT NULL, ' +
    'material TEXT NOT NULL, finish TEXT NOT NULL, strength_class TEXT NOT NULL, ' +
    'thread_pitch_mm REAL NOT NULL, ean TEXT, description TEXT, image_jpg BLOB)');
  AConnection.ExecSQL('CREATE INDEX IF NOT EXISTS idx_articles_type ON articles(head_type)');
  AConnection.ExecSQL('CREATE INDEX IF NOT EXISTS idx_articles_size ON articles(diameter_mm, length_mm)');
  if Integer(AConnection.ExecSQLScalar('SELECT count(*) FROM articles')) > 0 then
  begin
    MigrateLegacyImages(AConnection);
    Exit;
  end;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := AConnection;
    Q.SQL.Text := 'INSERT INTO articles (sku,title,standard,head_type,drive_type,thread_name,' +
      'diameter_mm,length_mm,head_diameter_mm,head_height_mm,material,finish,' +
      'strength_class,thread_pitch_mm,ean,description,image_jpg) VALUES (' +
      ':sku,:title,:standard,:head_type,:drive_type,:thread_name,:diameter_mm,' +
      ':length_mm,:head_diameter_mm,:head_height_mm,:material,:finish,' +
      ':strength_class,:thread_pitch_mm,:ean,:description,:image_jpg)';
    Q.ParamByName('ean').DataType := ftWideString;
    for Head := 0 to 1 do
      for D := Low(Diameters) to High(Diameters) do
        for L := Low(Lengths) to High(Lengths) do
          for Finish := 0 to 1 do
          begin
            DMM := Diameters[D];
            LMM := Lengths[L];
            if (Head = 1) and (LMM < DMM) then Continue;
            if Head = 0 then
            begin
              HType := 'Zylinderkopf';
              Std := 'ISO 4762 / DIN 912';
            end
            else
            begin
              HType := 'Senkkopf';
              Std := 'ISO 10642 / DIN 7991';
            end;
            if Finish = 0 then
            begin
              MaterialName := 'Stahl';
              Coating := 'verzinkt';
              Strength := '8.8 (Beispiel)';
            end
            else
            begin
              MaterialName := 'Edelstahl A2';
              Coating := 'blank';
              Strength := 'A2-70 (Beispiel)';
            end;
            SKU := Format('%s-M%dX%d-%s', [IfThen(Head = 0, 'ZK', 'SK'),
              DMM, LMM, IfThen(Finish = 0, 'ZN', 'A2')]);
            TitleText := Format('%sschraube M%d x %d', [HType, DMM, LMM]);
            Q.ParamByName('sku').AsString := SKU;
            Q.ParamByName('title').AsString := TitleText;
            Q.ParamByName('standard').AsString := Std;
            Q.ParamByName('head_type').AsString := HType;
            Q.ParamByName('drive_type').AsString := 'Innensechskant';
            Q.ParamByName('thread_name').AsString := 'M' + DMM.ToString;
            Q.ParamByName('diameter_mm').AsFloat := DMM;
            Q.ParamByName('length_mm').AsFloat := LMM;
            Q.ParamByName('head_diameter_mm').AsFloat := DMM * IfThen(Head = 0, 1.6, 2.0);
            Q.ParamByName('head_height_mm').AsFloat := DMM * IfThen(Head = 0, 1.0, 0.55);
            Q.ParamByName('material').AsString := MaterialName;
            Q.ParamByName('finish').AsString := Coating;
            Q.ParamByName('strength_class').AsString := Strength;
            Q.ParamByName('thread_pitch_mm').AsFloat := Pitch[D];
            Q.ParamByName('ean').Clear;
            Q.ParamByName('description').AsString :=
              'Demonstrationsartikel – technische Maße/Nennungen vor Beschaffung gegen Herstellerdaten prüfen.';
            Img := CreateScrewImage(Head = 1, DMM, LMM, Finish = 1);
            try
              Q.ParamByName('image_jpg').LoadFromStream(Img, ftBlob);
              Q.ExecSQL;
            finally
              Img.Free;
            end;
          end;
  finally
    Q.Free;
  end;
end;

end.
