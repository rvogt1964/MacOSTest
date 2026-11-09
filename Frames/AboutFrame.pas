unit AboutFrame;

interface

uses
  System.SysUtils, System.Classes, FMX.Types, FMX.Controls, FMX.Forms,
  FMX.StdCtrls, FMX.Layouts, FMX.Objects;

type
  TAboutFrame = class(TFrame)
    LabelHeading: TLabel;
    LabelVersion: TLabel;
    LabelTechnology: TLabel;
    LabelDescription: TLabel;
    LabelCopyright: TLabel;
    LabelBundleID: TLabel;
    ImageAbout: TImage;
    procedure Loaded; override;
  end;

implementation

uses AppLogger;

{$R *.fmx}
{$R ..\Resources\Images\About_MacOSTest.res}

{ Zweck: Lädt das eingebundene About-JPEG in das im Designer platzierte Bild. }
procedure TAboutFrame.Loaded;
var
  ImageStream: TResourceStream;
begin
  inherited;
  if csDesigning in ComponentState then
    Exit;
  try
    ImageStream := TResourceStream.CreateFromID(HInstance, 101, PChar(10));
    try
      ImageAbout.Bitmap.LoadFromStream(ImageStream);
    finally
      ImageStream.Free;
    end;
    TAppLogger.Instance.Add('ABOUT', 'Eingebundenes About-JPEG geladen.');
  except
    on E: Exception do
      TAppLogger.Instance.AddError('About-Bild', E);
  end;
end;

end.
