unit OldScreenshotCleaner;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  TIntervalUnit = (iuHours, iuDays, iuWeeks, iuMonths);

  TInterval = record
    Val: Cardinal;
    Unit_: TIntervalUnit;
  end;

  TOldScreenshotCleanerChangeCallback = procedure of object;

  { TOldScreenshotCleaner }

  TOldScreenshotCleaner = class
  private
    FInterval: TInterval;
    FActive: Boolean;
    FOnChangeCallback: TOldScreenshotCleanerChangeCallback;

    procedure SetInterval(AInterval: TInterval);
    procedure SetActive(AActive: Boolean);
  public

    property Interval: TInterval read FInterval write SetInterval;
    property Active: Boolean read FActive write SetActive;
    property OnChangeCallback: TOldScreenshotCleanerChangeCallback
               read FOnChangeCallback write FOnChangeCallback;
  end;

  operator explicit (const AInterval: TInterval): String;
  operator explicit (const AStr: String): TInterval;

implementation

operator explicit (const AInterval: TInterval): String;
var
  UnitShortName: Char;
begin
  case AInterval.Unit_ of
    iuHours:  UnitShortName := 'h';
    iudays:   UnitShortName := 'd';
    iuWeeks:  UnitShortName := 'w';
    iuMonths: UnitShortName := 'm';
  end;

  Result := IntToStr(AInterval.Val) + UnitShortName;
end;

operator explicit (const AStr: String): TInterval;
var
  UnitShortName: Char;
begin
  UnitShortName := AStr[Length(AStr)];
  case UnitShortName of
    'h': Result.Unit_ := iuHours;
    'd': Result.Unit_ := iudays;
    'w': Result.Unit_ := iuWeeks;
    'm': Result.Unit_ := iuMonths;
    else raise Exception.CreateFmt('Unknown unit character ''%s''', [UnitShortName]);
  end;
  Result.Val := StrToInt(Copy(AStr, 1, Length(AStr) - 1));
end;


{ TOldScreenshotCleaner }

procedure TOldScreenshotCleaner.SetInterval(AInterval: TInterval);
begin
  //if (FInterval.Unit_ = AInterval.Unit_) and (FInterval.Val = AInterval.Val) then
  //  Exit;

  FInterval := AInterval;

  if Assigned(FOnChangeCallback) then
    FOnChangeCallback;
end;

procedure TOldScreenshotCleaner.SetActive(AActive: Boolean);
begin
  //if FActive = AActive then
  //  Exit;

  FActive := AActive;

  if Assigned(FOnChangeCallback) then
    FOnChangeCallback;
end;

end.

