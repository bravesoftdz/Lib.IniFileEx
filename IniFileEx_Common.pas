unit IniFileEx_Common;

{$INCLUDE '.\IniFileEx_defs.inc'}

interface

uses
  SysUtils,
  AuxTypes, CRC32, BinTextEnc;

type
  TIFXString = UnicodeString;
  TIFXChar   = UnicodeChar;       PIFXChar = ^TIFXChar;

Function IFXStrToStr(const IFXStr: TIFXString): String;{$IFDEF CanInline} inline; {$ENDIF}
Function StrToIFXStr(const Str: String): TIFXString;{$IFDEF CanInline} inline; {$ENDIF}

type
  TIFXHashedString = record
    Str:  TIFXString;
    Hash: TCRC32;
  end;

procedure IFXHashString(var HashStr: TIFXHashedString);{$IFDEF CanInline} inline; {$ENDIF}
Function IFXHashedString(const Str: TIFXString): TIFXHashedString;{$IFDEF CanInline} inline; {$ENDIF}

Function IFXCompareStr(const S1,S2: TIFXString): Integer;{$IFDEF CanInline} inline; {$ENDIF}
Function IFXCompareText(const S1,S2: TIFXString): Integer;{$IFDEF CanInline} inline; {$ENDIF}

Function IFXSameHashString(const S1,S2: TIFXHashedString; FullEval: Boolean = True): Boolean;{$IFDEF CanInline} inline; {$ENDIF}

type
  TIFXValueType = (ivtBool,ivtInt8,ivtUInt8,ivtInt16,ivtUInt16,ivtInt32,
                   ivtUInt32,ivtInt64,ivtUInt64,ivtFloat32,ivtFloat64,
                   ivtDate,ivtTime,ivtDateTime,ivtString,ivtBinary);

  TIFXValueState = (ivsReady,ivsNeedsEncode,ivsNeedsDecode,ivsUndefined);

  TIFXValueEncoding = (iveBase2,iveBase64,iveBase85,iveHexadecimal,iveNumber,iveDefault);

Function IFXEncFromValueEnc(ValueEncoding: TIFXValueEncoding): TBinTextEncoding;
Function IFXValueEncFromEnc(Encoding: TBinTextEncoding): TIFXValueEncoding;

type
  TIFXValueData = record
    StringValue:  TIFXString;
    case ValueType: TIFXValueType of
      ivtBool:      (BoolValue:         Boolean);
      ivtInt8:      (Int8Value:         Int8);
      ivtUInt8:     (UInt8Value:        UInt8);
      ivtInt16:     (Int16Value:        Int16);
      ivtUInt16:    (UInt16Value:       UInt16);
      ivtInt32:     (Int32Value:        Int32);
      ivtUInt32:    (UInt32Value:       UInt32);
      ivtInt64:     (Int64Value:        Int64);
      ivtUInt64:    (UInt64Value:       UInt64);
      ivtFloat32:   (Float32Value:      Float32);
      ivtFloat64:   (Float64Value:      Float64);
      ivtDate:      (DateValue:         TDateTime);
      ivtTime:      (TimeValue:         TDateTime);
      ivtDateTime:  (DateTimeValue:     TDateTime);
      ivtBinary:    (BinaryValuePtr:    Pointer;
                     BinaryValueSize:   TMemSize;
                     BinaryValueOwned:  Boolean);
      ivtString:    ();
  end;

  TIFXDuplicityBehavior = (idbDrop,idbReplace,idbRenameOld,idbRenameNew);

  TIFXSettings = record
    FormatSettings:     TFormatSettings;
    FullNameEval:       Boolean;
    ReadOnly:           Boolean;
    DuplicityBehavior:  TIFXDuplicityBehavior;
  end;
  PIFXSettings = ^TIFXSettings;

procedure IFXInitSettings(var Sett: TIFXSettings);

type
  TIFXNodeIndices = record
    SectionIndex: Integer;
    KeyIndex:     Integer;
  end;

Function IFXNodeIndicesValid(Indices: TIFXNodeIndices): Boolean;

const
  IFX_INVALID_NODE_INDICES: TIFXNodeIndices = (SectionIndex: -1; KeyIndex: -1);

  IFX_ENC_STR_HEXADECIMAL = TIFXChar('$');
  IFX_ENC_STR_ESCAPECHAR  = TIFXChar('\');
  IFX_ENC_STR_QUOTECHAR   = TIFXChar('"');
  IFX_ENC_STR_CHARNUM     = TIFXChar('#');

  IFX_DUPRENSTR_NEW = TIFXString('_new');
  IFX_DUPRENSTR_OLD = TIFXString('_old');

implementation

uses
  StrRect;

Function IFXStrToStr(const IFXStr: TIFXString): String;
begin
Result := UnicodeToStr(IFXStr);
end;

//------------------------------------------------------------------------------

Function StrToIFXStr(const Str: String): TIFXString;
begin
Result := StrToUnicode(Str);
end;

//------------------------------------------------------------------------------

procedure IFXHashString(var HashStr: TIFXHashedString);
begin
{$IFDEF Unicode}
HashStr.Hash := WideStringCRC32(AnsiLowerCase(HashStr.Str));
{$ELSE}
HashStr.Hash := WideStringCRC32(WideLowerCase(HashStr.Str));
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function IFXHashedString(const Str: TIFXString): TIFXHashedString;
begin
Result.Str := Str;
IFXHashString(Result);
end;

//------------------------------------------------------------------------------

Function IFXCompareStr(const S1,S2: TIFXString): Integer;
begin
{$IFDEF Unicode}
Result := AnsiCompareStr(S1,S2);
{$ELSE}
Result := WideCompareStr(S1,S2);
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function IFXCompareText(const S1,S2: TIFXString): Integer;
begin
{$IFDEF Unicode}
Result := AnsiCompareText(S1,S2);
{$ELSE}
Result := WideCompareText(S1,S2);
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function IFXSameHashString(const S1, S2: TIFXHashedString; FullEval: Boolean = True): Boolean;
begin
Result := SameCRC32(S1.Hash,S2.Hash) and (not FullEval or
{$IFDEF Unicode}
  AnsiSameText(S1.Str,S2.Str)
{$ELSE}
  WideSameText(S1.Str,S2.Str)
{$ENDIF});
end;

//------------------------------------------------------------------------------

Function IFXEncFromValueEnc(ValueEncoding: TIFXValueEncoding): TBinTextEncoding;
begin
case ValueEncoding of
  iveBase2:       Result := bteBase2;
  iveBase64:      Result := bteBase64;
  iveBase85:      Result := bteBase85;
  iveHexadecimal: Result := bteHexadecimal;
else
  raise Exception.CreateFmt('EncFromValueEnc: Unsupported value encoding (%d).',[Ord(ValueEncoding)]);
end;
end;

//------------------------------------------------------------------------------

Function IFXValueEncFromEnc(Encoding: TBinTextEncoding): TIFXValueEncoding;
begin
case Encoding of
  bteBase2:       Result := iveBase2;
  bteBase64:      Result := iveBase64;
  bteBase85:      Result := iveBase85;
  bteHexadecimal: Result := iveHexadecimal;
else
  raise Exception.CreateFmt('ValueEncFromEnc: Unsupported encoding (%d).',[Ord(Encoding)]);
end;
end;

//------------------------------------------------------------------------------

procedure IFXInitSettings(var Sett: TIFXSettings);
const
  def_ShortMonthNames: array[1..12] of String =
    ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
  def_LongMonthNames: array[1..12] of String =
    ('January','February','March','April','May','June','July','August','September','October','November','December');
  def_ShortDayNames: array[1..7] of String  =
    ('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
  def_LongDayNames: array[1..7] of String  =
    ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');
var
  i:  Integer;
begin
{
  Delphi changed order of fields in TFormatSettings somewhere along the line,
  so I cannot use constant and assign everything in one step, yay!
}
Sett.FormatSettings.ThousandSeparator := #0;
Sett.FormatSettings.DecimalSeparator := '.';
Sett.FormatSettings.DateSeparator := '-';
Sett.FormatSettings.TimeSeparator := ':';
Sett.FormatSettings.ShortDateFormat := 'yyyy"-"mm"-"dd';
Sett.FormatSettings.LongDateFormat := 'yyyy"-"mm"-"dd';
Sett.FormatSettings.ShortTimeFormat := 'hh":"nn":"ss';
Sett.FormatSettings.LongTimeFormat := 'hh":"nn":"ss';
Sett.FormatSettings.TwoDigitYearCenturyWindow := 50;
For i := Low(def_ShortMonthNames) to High(def_ShortMonthNames) do
  Sett.FormatSettings.ShortMonthNames[i] := def_ShortMonthNames[i];
For i := Low(def_LongMonthNames) to High(def_LongMonthNames) do
  Sett.FormatSettings.LongMonthNames[i] := def_LongMonthNames[i];
For i := Low(def_ShortDayNames) to High(def_ShortDayNames) do
  Sett.FormatSettings.ShortDayNames[i] := def_ShortDayNames[i];
For i := Low(def_LongDayNames) to High(def_LongDayNames) do
  Sett.FormatSettings.LongDayNames[i] := def_LongDayNames[i];
// other fields beyond formatting  
Sett.FullNameEval := True;
Sett.ReadOnly := False;
Sett.DuplicityBehavior := idbDrop;
end;

//------------------------------------------------------------------------------

Function IFXNodeIndicesValid(Indices: TIFXNodeIndices): Boolean;
begin
Result := (Indices.SectionIndex >= 0) and (Indices.KeyIndex >= 0);
end;

end.
