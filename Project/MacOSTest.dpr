program MacOSTest;

uses
  System.StartUpCopy,
  FMX.Forms,
  MainForm in '..\Forms\MainForm.pas' {MainWindow},
  CatalogFrame in '..\Frames\CatalogFrame.pas' {CatalogFrame: TFrame},
  AboutFrame in '..\Frames\AboutFrame.pas' {AboutFrame: TFrame},
  LogFrame in '..\Frames\LogFrame.pas' {LogFrame: TFrame},
  CatalogDatabase in '..\Source\CatalogDatabase.pas',
  CatalogSeed in '..\Source\CatalogSeed.pas',
  CatalogModel in '..\Source\CatalogModel.pas',
  AppLogger in '..\Source\AppLogger.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainWindow);
  Application.Run;
end.
