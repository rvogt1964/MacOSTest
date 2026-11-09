unit CatalogFrame;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls,
  FMX.Layouts, FMX.ListBox, FMX.Edit, FMX.Objects, FMX.Memo,
  CatalogDatabase, CatalogModel;

type
  TCatalogFrame = class(TFrame)
    LayoutToolbar: TLayout;
    EditSearch: TEdit;
    ButtonSearch: TButton;
    ComboHead: TComboBox;
    LayoutBody: TLayout;
    ListArticles: TListBox;
    LayoutDetails: TLayout;
    LabelTitle: TLabel;
    ImageProduct: TImage;
    MemoDetails: TMemo;
    LabelCount: TLabel;
    procedure ButtonSearchClick(Sender: TObject);
    procedure ComboHeadChange(Sender: TObject);
    procedure ListArticlesChange(Sender: TObject);
  private
    FDatabase: TCatalogDatabase;
    FUpdatingList: Boolean;
    FArticles: TArray<TScrewArticle>;
    procedure RefreshArticles;
    procedure ShowArticle(AIndex: Integer);
  public
    procedure Initialize(ADatabase: TCatalogDatabase);
  end;

implementation

uses AppLogger;

{$R *.fmx}

{
  Zweck:
    Verknüpft die Katalogansicht mit dem Datenbankdienst.

  Parameter:
    Siehe Signatur; nicht vorhandene Parameter entfallen.

  Rückgabe:
    Siehe Signatur, soweit vorhanden.

  Hinweise:
    Fehler werden an die aufrufende Schicht weitergereicht.
}
procedure TCatalogFrame.Initialize(ADatabase: TCatalogDatabase);
begin
  FDatabase := ADatabase;
  TAppLogger.Instance.Add('KATALOG', 'Katalogframe initialisiert.');
  RefreshArticles;
end;

{
  Zweck:
    Füllt die Artikelauflistung entsprechend Suche und Kopfart neu.

  Parameter:
    Siehe Signatur; nicht vorhandene Parameter entfallen.

  Rückgabe:
    Siehe Signatur, soweit vorhanden.

  Hinweise:
    Fehler werden an die aufrufende Schicht weitergereicht.
}
procedure TCatalogFrame.RefreshArticles;
var
  A: TScrewArticle;
  HeadFilter: string;
begin
  if FDatabase = nil then Exit;
  HeadFilter := '';
  if ComboHead.ItemIndex = 1 then HeadFilter := 'Zylinderkopf';
  if ComboHead.ItemIndex = 2 then HeadFilter := 'Senkkopf';
  try
    FArticles := FDatabase.Search(EditSearch.Text, HeadFilter);
  except
    on E: Exception do
    begin
      TAppLogger.Instance.AddError('Artikelsuche', E);
      raise;
    end;
  end;
  FUpdatingList := True;
  ListArticles.BeginUpdate;
  try
    ListArticles.Clear;
    for A in FArticles do
      // Daten kommen ausschließlich aus den als Text gelesenen SQLite-Feldern.
      // Keine DB-gebundene Memo-Feldrepräsentation in die Liste übernehmen.
      ListArticles.Items.Add(A.SKU + '  |  ' + A.Title + '  |  ' +
        A.Standard + '  |  ' + A.Material);
  finally
    ListArticles.EndUpdate;
    FUpdatingList := False;
  end;
  TAppLogger.Instance.Add('SUCHE', Format('Suchtext=%s; Kopfart=%s; Treffer=%d',
    [EditSearch.Text, HeadFilter, Length(FArticles)]));
  LabelCount.Text := Format('%d Artikel angezeigt, insgesamt %d', [Length(FArticles), FDatabase.ArticleCount]);
  if Length(FArticles) > 0 then
  begin
    FUpdatingList := True;
    try
      ListArticles.ItemIndex := 0;
    finally
      FUpdatingList := False;
    end;
    ShowArticle(0);
  end
  else
  begin
    LabelTitle.Text := 'Keine Artikel gefunden';
    MemoDetails.Lines.Clear;
    ImageProduct.Bitmap.Clear(TAlphaColors.Null);
  end;
end;

{
  Zweck:
    Zeigt alle technischen Angaben und das JPEG des markierten Artikels.

  Parameter:
    Siehe Signatur; nicht vorhandene Parameter entfallen.

  Rückgabe:
    Siehe Signatur, soweit vorhanden.

  Hinweise:
    Fehler werden an die aufrufende Schicht weitergereicht.
}
procedure TCatalogFrame.ShowArticle(AIndex: Integer);
var
  A: TScrewArticle;
  S: TMemoryStream;
  Header: array[0..2] of Byte;
begin
  if (AIndex < 0) or (AIndex >= Length(FArticles)) or (FDatabase = nil) then Exit;
  A := FArticles[AIndex];
  TAppLogger.Instance.Add('ARTIKEL', 'Detailansicht: ' + A.SKU);
  LabelTitle.Text := A.Title;
  MemoDetails.Lines.BeginUpdate;
  try
    MemoDetails.Lines.Clear;
    MemoDetails.Lines.Add('Artikelnummer: ' + A.SKU);
    MemoDetails.Lines.Add('Norm: ' + A.Standard);
    MemoDetails.Lines.Add('Kopfart: ' + A.HeadType);
    MemoDetails.Lines.Add('Antrieb: ' + A.DriveType);
    MemoDetails.Lines.Add('Gewinde: ' + A.ThreadName);
    MemoDetails.Lines.Add(Format('Nenndurchmesser: %.1f mm', [A.DiameterMM]));
    MemoDetails.Lines.Add(Format('Länge: %.1f mm', [A.LengthMM]));
    MemoDetails.Lines.Add(Format('Kopfdurchmesser (schematisch): %.1f mm', [A.HeadDiameterMM]));
    MemoDetails.Lines.Add(Format('Kopfhöhe (schematisch): %.1f mm', [A.HeadHeightMM]));
    MemoDetails.Lines.Add(Format('Steigung: %.2f mm', [A.ThreadPitchMM]));
    MemoDetails.Lines.Add('Werkstoff: ' + A.Material);
    MemoDetails.Lines.Add('Oberfläche: ' + A.Finish);
    MemoDetails.Lines.Add('Festigkeit: ' + A.Strength);
    MemoDetails.Lines.Add('Hinweis: ' + A.Description);
  finally
    MemoDetails.Lines.EndUpdate;
  end;
  ImageProduct.Bitmap.Clear(TAlphaColors.Null);
  try
    S := FDatabase.LoadImage(A.ID);
    try
      if S.Size = 0 then
        Exit;
      if (S.Read(Header, SizeOf(Header)) <> SizeOf(Header)) or
         (Header[0] <> $FF) or (Header[1] <> $D8) or (Header[2] <> $FF) then
        raise EStreamError.Create('Produktabbildung hat keinen gültigen JPEG-Kopf.');
      S.Position := 0;
      ImageProduct.Bitmap.LoadFromStream(S);
    finally
      S.Free;
    end;
  except
    on E: Exception do
      TAppLogger.Instance.AddError('Bildladen/' + A.SKU, E);
  end;
end;

{
  Zweck:
    Startet die Suche durch Betätigen der Schaltfläche.

  Parameter:
    Siehe Signatur; nicht vorhandene Parameter entfallen.

  Rückgabe:
    Siehe Signatur, soweit vorhanden.

  Hinweise:
    Fehler werden an die aufrufende Schicht weitergereicht.
}
procedure TCatalogFrame.ButtonSearchClick(Sender: TObject);
begin
  TAppLogger.Instance.Add('BEDIENUNG', 'Suchschaltfläche betätigt.');
  RefreshArticles;
end;

{
  Zweck:
    Aktualisiert die Filterung bei Auswahl einer Kopfart.

  Parameter:
    Siehe Signatur; nicht vorhandene Parameter entfallen.

  Rückgabe:
    Siehe Signatur, soweit vorhanden.

  Hinweise:
    Fehler werden an die aufrufende Schicht weitergereicht.
}
procedure TCatalogFrame.ComboHeadChange(Sender: TObject);
begin
  TAppLogger.Instance.Add('BEDIENUNG', 'Kopfartfilter gewechselt.');
  RefreshArticles;
end;

{
  Zweck:
    Aktualisiert die Artikeldetails beim Listenwechsel.

  Parameter:
    Siehe Signatur; nicht vorhandene Parameter entfallen.

  Rückgabe:
    Siehe Signatur, soweit vorhanden.

  Hinweise:
    Fehler werden an die aufrufende Schicht weitergereicht.
}
procedure TCatalogFrame.ListArticlesChange(Sender: TObject);
begin
  if not FUpdatingList then
    ShowArticle(ListArticles.ItemIndex);
end;

end.
