unit CatalogModel;

interface

type
  TScrewArticle = record
    ID: Integer;
    SKU: string;
    Title: string;
    Standard: string;
    HeadType: string;
    DriveType: string;
    ThreadName: string;
    DiameterMM: Double;
    LengthMM: Double;
    HeadDiameterMM: Double;
    HeadHeightMM: Double;
    Material: string;
    Finish: string;
    Strength: string;
    ThreadPitchMM: Double;
    EAN: string;
    Description: string;
  end;

implementation
end.
