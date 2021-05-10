unit uLocalization;

interface

uses
  TntIniFiles, SysUtils, TntClasses;

type
  TLanguageCode = String[2];

  TLanguageInfo = record
    Code: TLanguageCode;
    Name, NativeName: WideString;
    FileName: String;
    AlternativeFor: array of TLanguageCode;
    Author: WideString;
  end;

  TLanguagesArray = array of TLanguageInfo;

  ELocalizerException = class(Exception);

  TLocalizer = class
  private
    LangInfo: TLanguageInfo;
    Strings: TTntStringList;
    LangsDir: String;
    UseAltsForMissedStrings: Boolean; // Try or not read missed strings from default or alternative languages

    function GetLanguageInfo: TLanguageInfo;
    class function GetLanguageInfoFromIni(const AnIni: TTntMemIniFile): TLanguageInfo;
    procedure ClearLangInfoAndStrings;
  public
    constructor Create(ALangsDir: String; AnUseAltsForMissedStrings: Boolean = True);
    destructor Destroy; override;

    //procedure LoadByCode(ALang: TLanguageCode);
    procedure LoadFromFile(AFileName: String);
    function I18N(StrID: String): WideString;
    procedure GetLanguages(var LangsArr: TLanguagesArray);

    property LanguageInfo: TLanguageInfo read GetLanguageInfo;
  end;

var
  Localizer: TLocalizer;

implementation

uses uUtils, Classes, StrUtils;

{ TLocalizer }

procedure TLocalizer.ClearLangInfoAndStrings;
begin
  with LangInfo do
  begin
    Code       := '';
    Name       := '';
    NativeName := '';
    FileName   := '';
    SetLength(AlternativeFor, 0);
    Author     := '';
  end;

  Strings.Clear;
end;

constructor TLocalizer.Create(ALangsDir: String; AnUseAltsForMissedStrings: Boolean);
begin
  Strings := TTntStringList.Create;
  Strings.NameValueSeparator := '=';
  LangInfo.AlternativeFor := nil;
  ClearLangInfoAndStrings;
  LangsDir := IncludeTrailingBackslash(ALangsDir);
  UseAltsForMissedStrings := AnUseAltsForMissedStrings;
end;

destructor TLocalizer.Destroy;
begin
  //FreeAndNil(LangInfo.AlternativeFor);
  LangInfo.AlternativeFor := nil;
  FreeAndNil(Strings);

  inherited;
end;

function TLocalizer.GetLanguageInfo: TLanguageInfo;
begin
  Result := LangInfo;
end;

class function TLocalizer.GetLanguageInfoFromIni(
  const AnIni: TTntMemIniFile): TLanguageInfo;
const
  IniSection = 'info';
var
  AlternativeForStr: TStringList;
  I: integer;
begin
  Result.Code := {Wide}LowerCase(AnIni.ReadString(IniSection, 'LangCode', ''));
  Result.Name := AnIni.ReadString(IniSection, 'LangName', '');
  Result.NativeName := AnIni.ReadString(IniSection, 'LangNativeName', '');
  Result.FileName := AnIni.FileName;

  AlternativeForStr := TStringList.Create;
  AlternativeForStr.CommaText := AnIni.ReadString(IniSection, 'AlternativeFor', '');
  SetLength(Result.AlternativeFor, AlternativeForStr.Count);
  for I := 0 to AlternativeForStr.Count - 1 do
    Result.AlternativeFor[I] := AlternativeForStr.Strings[I];
  AlternativeForStr.Free;

  Result.Author := AnIni.ReadString(IniSection, 'Author', '');
end;

procedure TLocalizer.GetLanguages(var LangsArr: TLanguagesArray);
var
  SearchRes: TSearchRec;
  LangsCount: integer;
  Idx: integer;
  Ini: TTntMemIniFile;
begin
  // Get amount of available languages
  LangsCount := 0;
  if FindFirst(LangsDir + '*.ini', faAnyFile, SearchRes) = 0 then
  begin
    repeat
      Inc(LangsCount);
    until FindNext(SearchRes) <> 0;

    FindClose(SearchRes);
  end;

  // Allocate memory for array of languages
  SetLength(LangsArr, LangsCount);

  // Write language info in array
  Idx := -1;
  if FindFirst(LangsDir + '*.ini', faAnyFile, SearchRes) = 0 then
  begin
    repeat
      Ini := TTntMemIniFile.Create(LangsDir + SearchRes.Name);
      try
        try
          Inc(Idx);

          LangsArr[Idx] := TLocalizer.GetLanguageInfoFromIni(Ini);
        finally
          //Ini.Free;
          FreeAndNil(Ini);
        end;
      except
      end;
    until FindNext(SearchRes) <> 0;

    FindClose(SearchRes);
  end;
end;

function TLocalizer.I18N(StrID: String): WideString;
begin
  if LangInfo.Code = '' then
    raise ELocalizerException.Create('No localization loaded');

  Result := Strings.Values[StrID];
  if Result = '' then
    Result := '<unknown>';

  Result := DecodeControlCharacters(Result);
end;

procedure TLocalizer.LoadFromFile(AFileName: String);
// ToDo: Optimization needed - reduce the number of file reading operations
const
  TranslationIniSection = 'translation';
var
  FileName: String;
  Ini: TTntMemIniFile;
  TmpStr: TTntStringList;
  AllLangs: TLanguagesArray;
  AltLang: TLanguageCode;

  procedure CombineValues(L1: TTntStrings; const L2: TTntStrings);
  var
    Idx: integer;
  begin
    for Idx := 0 to L2.Count - 1 do
      L1.Values[L2.Names[Idx]] := L2.ValueFromIndex[Idx];
  end;
begin
  ClearLangInfoAndStrings;

  { Check if selected translation file exists }
  if not FileExists(AFileName) then
    raise ELocalizerException.CreateFmt('Can`t open localization file "%s"', [FileName]);

  { Read language info }
  Ini := TTntMemIniFile.Create(AFileName);
  try
    LangInfo := GetLanguageInfoFromIni(Ini);
  finally
    FreeAndNil(Ini);
  end;

  if UseAltsForMissedStrings then
  begin
    { Read strings from default (English) translation }
    if not AnsiEndsStr('en.ini', AFileName) then // Skip for English
    begin
      Ini := TTntMemIniFile.Create(LangsDir + 'en.ini');
      try
        Ini.ReadSectionValues(TranslationIniSection, Strings);
      finally
        FreeAndNil(Ini);
      end;
    end;

    { Read and update strings from alternative of specified translation }
    GetLanguages(AllLangs);
    AltLang := GetAlternativeLanguage(AllLangs, LangInfo.Code);
    if AltLang <> '' then
    begin
      Ini := TTntMemIniFile.Create(LangsDir + AltLang + '.ini');
      TmpStr := TTntStringList.Create;
      try
        Ini.ReadSectionValues(TranslationIniSection, TmpStr);
        CombineValues(Strings, TmpStr);
      finally
        FreeAndNil(TmpStr);
      end;
    end;
  end;

  { Read and update strings from specified translation }
  Ini := TTntMemIniFile.Create(AFileName);
  try
    // Combine translation strings with defaults
    TmpStr := TTntStringList.Create;
    try
      Ini.ReadSectionValues(TranslationIniSection, TmpStr);
      CombineValues(Strings, TmpStr);
    finally
      FreeAndNil(TmpStr);
    end;
  finally
    FreeAndNil(Ini);
  end;
end;

initialization
begin
  // ToDo: Use alternatives only in Release build
  Localizer := TLocalizer.Create(ExtractFilePath(ParamStr(0)) + 'lang' + PathDelim, True);
end;

finalization
begin
  FreeAndNil(Localizer);
end;

end.
 