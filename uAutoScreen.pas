unit uAutoScreen;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ExtCtrls, StdCtrls, inifiles, Spin, FileCtrl, pngImage,
  TrayIcon, XPMan, jpeg, ShellAPI, Menus;

type
  TImageFormat = (fmtPNG=0, fmtJPG);
  TLanguage = (lngEnglish=0, lngRussian);

  TMainForm = class(TForm)
    OutputDirEdit: TEdit;
    ChooseOutputDirButton: TButton;
    Timer: TTimer;
    CaptureInterval: TSpinEdit;
    OutputDirLabel: TLabel;
    CaptureIntervalLabel: TLabel;
    TrayIcon: TTrayIcon;
    XPManifest: TXPManifest;
    ImageFormatLabel: TLabel;
    TakeScreenshotButton: TButton;
    JPEGQualityLabel: TLabel;
    JPEGQualitySpinEdit: TSpinEdit;
    OpenOutputDirButton: TButton;
    StopWhenInactiveCheckBox: TCheckBox;
    LanguageRadioGroup: TRadioGroup;
    ImageFormatComboBox: TComboBox;
    JPEGQualityPercentLabel: TLabel;
    AutoCaptureControlGroup: TGroupBox;
    StartAutoCaptureButton: TButton;
    StopAutoCaptureButton: TButton;
    TrayIconPopupMenu: TPopupMenu;
    ExitTrayMenuItem: TMenuItem;
    TakeScreenshotTrayMenuItem: TMenuItem;
    RestoreWindowTrayMenuItem: TMenuItem;
    ToggleAutoCaptureTrayMenuItem: TMenuItem;
    Separator2TrayMenuItem: TMenuItem;
    AboutButton: TButton;
    StartCaptureOnStartUpCheckBox: TCheckBox;
    StartMinimizedCheckBox: TCheckBox;
    Separator1TrayMenuItem: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ChooseOutputDirButtonClick(Sender: TObject);
    procedure OutputDirEditChange(Sender: TObject);
    procedure CaptureIntervalChange(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure ApplicationMinimize(Sender: TObject);
    procedure StartAutoCaptureButtonClick(Sender: TObject);
    procedure StopAutoCaptureButtonClick(Sender: TObject);
    procedure TakeScreenshotButtonClick(Sender: TObject);
    procedure JPEGQualitySpinEditChange(Sender: TObject);
    procedure OpenOutputDirButtonClick(Sender: TObject);
    procedure StopWhenInactiveCheckBoxClick(Sender: TObject);
    procedure ImageFormatComboBoxChange(Sender: TObject);
    procedure ToggleAutoCaptureTrayMenuItemClick(Sender: TObject);
    procedure RestoreWindowTrayMenuItemClick(Sender: TObject);
    procedure TakeScreenshotTrayMenuItemClick(Sender: TObject);
    procedure ExitTrayMenuItemClick(Sender: TObject);
    procedure AboutButtonClick(Sender: TObject);
    procedure LanguageRadioGroupClick(Sender: TObject);
    procedure StartCaptureOnStartUpCheckBoxClick(Sender: TObject);
    procedure StartMinimizedCheckBoxClick(Sender: TObject);
  private
    { Private declarations }
    FLanguage: TLanguage;
    
    procedure SetTimerEnabled(IsEnabled: Boolean);
    function GetTimerEnabled: Boolean;
    function GetFinalOutputDir: String;
    procedure MakeScreenshot;
    procedure MinimizeToTray;
    procedure RestoreFromTray;
    procedure SetLanguage(Lang: TLanguage);
    procedure TranslateForm();

    // ToDo: Why this do not work?
    //    property IsTimerEnabled: Boolean read Timer.Enabled write SetTimerEnabled;
    //    Error: Record, object or class type required

    property IsTimerEnabled: Boolean read GetTimerEnabled write SetTimerEnabled;
    property FinalOutputDir: String read GetFinalOutputDir;
    property Language: TLanguage read FLanguage write SetLanguage;
  public
    { Public declarations }
  end;

const
  ImageFormatNames: array [TImageFormat] of String = ('PNG', 'JPG');
  LanguageCodes: array [TLanguage] of String = ('en', 'ru');

var
  MainForm: TMainForm;
  ini: TIniFile;

implementation

uses uAbout{, DateUtils}, uLocalization;

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
var
  Fmt: TImageFormat;
  FmtStr: String;
  LangCode: String;
  LangId, I: TLanguage;
begin
  Application.OnMinimize := ApplicationMinimize;

  for Fmt := Low(TImageFormat) to High(TImageFormat) do
    ImageFormatComboBox.Items.Append(ImageFormatNames[Fmt]);

  ini := TIniFile.Create(ExtractFilePath(Application.ExeName) + '\config.ini');

  OutputDirEdit.Text := ini.ReadString('main', 'OutputDir', ExtractFilePath(Application.ExeName));
  CaptureInterval.Value := ini.ReadInteger('main', 'CaptureInterval', 5);
  StopWhenInactiveCheckBox.Checked := ini.ReadBool('main', 'StopWhenInactive', False);
  FmtStr := ini.ReadString('main', 'ImageFormat', ImageFormatNames[fmtPNG]);
  for Fmt := Low(TImageFormat) to High(TImageFormat) do
  begin
    if ImageFormatNames[Fmt] = FmtStr then
    begin
      ImageFormatComboBox.ItemIndex := Ord(Fmt);
      Break;
    end;
  end;
  JPEGQualitySpinEdit.MinValue := Low(TJPEGQualityRange);
  JPEGQualitySpinEdit.MaxValue := High(TJPEGQualityRange);
  JPEGQualitySpinEdit.Value := ini.ReadInteger('main', 'JPEGQuality', 80);
  ImageFormatComboBox.OnChange(ImageFormatComboBox);

  // Language
  LangCode := ini.ReadString('main', 'language', 'en');
  LangId := lngEnglish;
  for I := Low(TLanguage) to High(TLanguage) do
  begin
    if (LangCode = LanguageCodes[I]) then
    begin
      LangId := I;
      Break;
    end;
  end;
  SetLanguage(LangId);

  Timer.Interval := CaptureInterval.Value * 60 * 1000;
  StartCaptureOnStartUpCheckBox.Checked :=
      ini.ReadBool('main', 'StartCaptureOnStartUp', {True} False);
  IsTimerEnabled := StartCaptureOnStartUpCheckBox.Checked;

  if ini.ReadBool('main', 'StartMinimized', False) then
  begin
    StartMinimizedCheckBox.Checked := True;
    MinimizeToTray;
  end
  else
    RestoreFromTray;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  ini.Free;
end;

procedure TMainForm.ChooseOutputDirButtonClick(Sender: TObject);
var
  dir: string;
begin
  dir := OutputDirEdit.Text;

  if SelectDirectory(I18N('SelectOutputDirectory'), '' {savepath.Text}, dir) then
  //if SelectDirectory(dir, [sdAllowCreate, sdPerformCreate], 0) then
  begin
    OutputDirEdit.Text := dir;
    ini.WriteString('main', 'OutputDir', dir);
  end;
end;

procedure TMainForm.OutputDirEditChange(Sender: TObject);
begin
    ini.WriteString('main', 'OutputDir', OutputDirEdit.Text);
end;

procedure TMainForm.CaptureIntervalChange(Sender: TObject);
begin
  ini.WriteInteger('main', 'CaptureInterval', CaptureInterval.Value);
  Timer.Interval := CaptureInterval.Value * 60 * 1000;
end;

function LastInput: DWord; forward;

procedure TMainForm.TimerTimer(Sender: TObject);
begin
  if StopWhenInactiveCheckBox.Checked then
  begin
    // �� ��������� �������� ��� ����������� ������������
    // ToDo: ����� �������� �������� ������� ��������
    // ��� ��� ������������ ����� �� ������
    // ToDo: ����� �������� ��������� �������� ������ � ���������
    // ����������� � ���� ��� ���������, �� ��������� �������
    if Timer.Interval > LastInput then
      MakeScreenshot;
  end
  else
    MakeScreenshot;
end;

function TMainForm.GetTimerEnabled: Boolean;
begin
  Result := Timer.Enabled;
end;

procedure TMainForm.SetTimerEnabled(IsEnabled: Boolean);
begin
  Timer.Enabled := IsEnabled;
  StartAutoCaptureButton.Enabled := not IsEnabled;
  StopAutoCaptureButton.Enabled := IsEnabled;
  // Tray menu
  ToggleAutoCaptureTrayMenuItem.Checked := IsEnabled;
end;

procedure TMainForm.StartAutoCaptureButtonClick(Sender: TObject);
begin
  IsTimerEnabled := True;
end;

procedure TMainForm.StopAutoCaptureButtonClick(Sender: TObject);
begin
  IsTimerEnabled := False;
end;

procedure TMainForm.ApplicationMinimize(Sender: TObject);
begin
  MinimizeToTray;
end;

procedure TMainForm.MakeScreenshot;
var
  dirname, filename{, fullpath}: string;
  png: TPNGObject;
  bmp:TBitmap;
  jpg: TJPEGImage;
  ScreenDC: HDC;
begin
  DateTimeToString(filename, 'yyyy-mm-dd hh.mm.ss', Now());

  dirname := FinalOutputDir;


  bmp := TBitmap.Create;
  bmp.Width := Screen.Width;
  bmp.Height := Screen.Height;
  ScreenDC := GetDC(0);
  BitBlt(bmp.Canvas.Handle, 0,0, Screen.Width, Screen.Height,
           ScreenDC, 0,0,SRCCOPY);
  ReleaseDC(0, ScreenDC);

  if ImageFormatComboBox.ItemIndex = Ord(fmtPNG) then
  begin                   // PNG
    PNG := TPNGObject.Create;
    try
      PNG.Assign(bmp);
      PNG.SaveToFile(dirname + filename + '.png');
    finally
      bmp.Free;
      PNG.Free;
    end;
  end;

  if ImageFormatComboBox.ItemIndex = Ord(fmtJPG) then
  begin                 // JPG
    jpg := TJPEGImage.Create;
    try
      jpg.Assign(bmp);
      jpg.CompressionQuality := JPEGQualitySpinEdit.Value;
      jpg.Compress;
      jpg.SaveToFile(dirname + filename + '.jpg');
    finally
      jpg.Free;
      bmp.Free;
    end;
  end;
end;

procedure TMainForm.TakeScreenshotButtonClick(Sender: TObject);
begin
  Hide;
  Sleep(2000); // Add some delay in order to window has time to hide
  try
    try
      MakeScreenshot;
      Sleep(1000);
    finally
      Show;
    end;
  except
  end;
end;

procedure TMainForm.JPEGQualitySpinEditChange(Sender: TObject);
begin
  try
    ini.WriteInteger('main', 'JPEGQuality', JPEGQualitySpinEdit.Value);
  finally
  end;
end;

function TMainForm.GetFinalOutputDir: String;
var
  dirname: string;
begin
  DateTimeToString(dirname, 'yyyy-mm-dd', Now());

  dirname := IncludeTrailingPathDelimiter(ini.ReadString('main', 'OutputDir', '')) + dirname + '\';
  if not DirectoryExists(dirname) then
    CreateDir(dirname);

  Result := dirname;
end;

procedure TMainForm.OpenOutputDirButtonClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', PChar(FinalOutputDir), nil, nil, SW_SHOWNORMAL);
end;

procedure TMainForm.StopWhenInactiveCheckBoxClick(Sender: TObject);
begin
  ini.WriteBool('main', 'StopWhenInactive', StopWhenInactiveCheckBox.Checked);
end;

// �������/���������

function LastInput: DWord;
var
  LInput: TLastInputInfo;
begin
  LInput.cbSize := SizeOf(TLastInputInfo);
  GetLastInputInfo(LInput);
  Result := GetTickCount - LInput.dwTime;
end;

procedure TMainForm.ImageFormatComboBoxChange(Sender: TObject);
var
  Format: TImageFormat;
begin
  Format := TImageFormat(ImageFormatComboBox.ItemIndex);
  JPEGQualitySpinEdit.{Enabled}Visible := Format = fmtJPG;
  JPEGQualityLabel.{Enabled}Visible := Format = fmtJPG;
  JPEGQualityPercentLabel.{Enabled}Visible := Format = fmtJPG;

  ini.WriteString('main', 'ImageFormat', ImageFormatNames[Format]);
end;

procedure TMainForm.ToggleAutoCaptureTrayMenuItemClick(Sender: TObject);
begin
  IsTimerEnabled := not IsTimerEnabled;
end;

procedure TMainForm.RestoreWindowTrayMenuItemClick(Sender: TObject);
begin
  RestoreFromTray;
end;

procedure TMainForm.TakeScreenshotTrayMenuItemClick(Sender: TObject);
begin
  Sleep(2000); // Add some delay before capture
  MakeScreenshot;
end;

procedure TMainForm.ExitTrayMenuItemClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.MinimizeToTray;
begin
  TrayIcon.AppVisible := False;
  TrayIcon.FormVisible := False;
  TrayIcon.IconVisible := True;
end;

procedure TMainForm.RestoreFromTray;
begin
  TrayIcon.IconVisible := False;
  TrayIcon.AppVisible := True;
  TrayIcon.FormVisible := True;
  Application.Restore;
  Application.BringToFront();
end;

procedure TMainForm.AboutButtonClick(Sender: TObject);
begin
  with TAboutForm.Create(Application) do
  begin
    ShowModal;
  end;
end;

procedure TMainForm.LanguageRadioGroupClick(Sender: TObject);
begin
  Language := TLanguage(LanguageRadioGroup.ItemIndex)
end;

procedure TMainForm.SetLanguage(Lang: TLanguage);
begin
  {if (FLanguage = Lang) then
    Exit;}

  FLanguage := Lang;
  ini.WriteString('main', 'language', LanguageCodes[Lang]);
  LanguageRadioGroup.ItemIndex := Ord(Lang);
  I18NSetLang(LanguageCodes[Lang]);
  TranslateForm;
end;

procedure TMainForm.TranslateForm;
begin
  // Main form
  LanguageRadioGroup.Caption := I18N('Language');
  OutputDirLabel.Caption := I18N('OutputDirectory') + ':';
  //ChooseOutputDirButton.Caption := I18N('Choose') + '...';
  OpenOutputDirButton.Caption := I18N('OpenDirectory');
  CaptureIntervalLabel.Caption := I18N('CaptureInterval') + ':';
  StopWhenInactiveCheckBox.Caption := I18N('PauseCaptureWhenIdle');
  ImageFormatLabel.Caption := I18N('Format') + ':';
  JPEGQualityLabel.Caption := I18N('Quality') + ':';
  AutoCaptureControlGroup.Caption := I18N('AutoCapture');
  StartAutoCaptureButton.Caption := I18N('StartCapture');
  StopAutoCaptureButton.Caption := I18N('StopCapture');
  TakeScreenshotButton.Caption := I18N('TakeScreenshot');
  AboutButton.Caption := I18N('About');
  StartCaptureOnStartUpCheckBox.Caption := I18N('StartCaptureOnStartUp');
  StartMinimizedCheckBox.Caption := I18N('StartMinimized');

  // Tray icon
  RestoreWindowTrayMenuItem.Caption := I18N('Restore');
  ToggleAutoCaptureTrayMenuItem.Caption := I18N('EnableAutoCapture');
  TakeScreenshotTrayMenuItem.Caption := I18N('TakeScreenshot');
  ExitTrayMenuItem.Caption := I18N('Exit');
end;

procedure TMainForm.StartCaptureOnStartUpCheckBoxClick(Sender: TObject);
begin
  ini.WriteBool('main', 'StartCaptureOnStartUp', StartCaptureOnStartUpCheckBox.Checked);
end;

procedure TMainForm.StartMinimizedCheckBoxClick(Sender: TObject);
begin
  ini.WriteBool('main', 'StartMinimized', StartMinimizedCheckBox.Checked);
end;

end.
