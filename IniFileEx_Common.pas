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

Function IFXStrToUTF8(const IFXStr: TIFXString): UTF8String;{$IFDEF CanInline} inline; {$ENDIF}
Function UTF8ToIFXStr(const Str: UTF8String): TIFXString;{$IFDEF CanInline} inline; {$ENDIF}

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
  TIFXValueType = (ivtUndecided,ivtBool,ivtInt8,ivtUInt8,ivtInt16,ivtUInt16,
                   ivtInt32,ivtUInt32,ivtInt64,ivtUInt64,ivtFloat32,ivtFloat64,
                   ivtDate,ivtTime,ivtDateTime,ivtString,ivtBinary);

  TIFXValueState = (ivsReady,ivsNeedsEncode,ivsNeedsDecode,ivsUndefined);

  TIFXValueEncoding = (iveBase2,iveBase64,iveBase85,iveHexadecimal,iveNumber,iveDefault);

Function IFXEncFromValueEnc(ValueEncoding: TIFXValueEncoding): TBinTextEncoding;
Function IFXValueEncFromEnc(Encoding: TBinTextEncoding): TIFXValueEncoding;

Function IFXValueTypeToByte(ValueType: TIFXValueType): Byte;
Function IFXByteToValueType(ByteValue: Byte): TIFXValueType;

Function IFXValueEncodingToByte(ValueEncoding: TIFXValueEncoding): Byte;
Function IFXByteToValueEncoding(ByteValue: Byte): TIFXValueEncoding;

const
  IFX_VALTYPE_UNDECIDED = Byte(-1);
  IFX_VALTYPE_BOOL      = 0;
  IFX_VALTYPE_INT8      = 1;
  IFX_VALTYPE_UINT8     = 2;
  IFX_VALTYPE_INT16     = 3;
  IFX_VALTYPE_UINT16    = 4;
  IFX_VALTYPE_INT32     = 5;
  IFX_VALTYPE_UINT32    = 6;
  IFX_VALTYPE_INT64     = 7;
  IFX_VALTYPE_UINT64    = 8;
  IFX_VALTYPE_FLOAT32   = 9;
  IFX_VALTYPE_FLOAT64   = 10;
  IFX_VALTYPE_DATE      = 11;
  IFX_VALTYPE_TIME      = 12;
  IFX_VALTYPE_DATETIME  = 13;
  IFX_VALTYPE_STRING    = 14;
  IFX_VALTYPE_BINARY    = 15;

  IFX_VALENC_BASE2   = 0;
  IFX_VALENC_BASE64  = 1;
  IFX_VALENC_BASE85  = 2;
  IFX_VALENC_HEXADEC = 3;
  IFX_VALENC_NUMBER  = 4;
  IFX_VALENC_DEFAULT = 5;

type
  TIFXValueData = record
    StringValue:  TIFXString;
    case ValueType: TIFXValueType of
      ivtUndecided: ();
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
      ivtString:    (); // stored in field StringValue
  end;
  PIFXValueData = ^TIFXValueData;

  TIFXDuplicityBehavior = (idbDrop,idbReplace,idbRenameOld,idbRenameNew);

  TIFXIniFormat = record
    EscapeChar:       TIFXChar;
    QuoteChar:        TIFXChar;
    NumericChar:      TIFXChar;
    ForceQuote:       Boolean;
    CommentChar:      TIFXChar;
    SectionStartChar: TIFXChar;
    SectionEndChar:   TIFXChar;
    ValueDelimChar:   TIFXChar;
    WhiteSpaceChar:   TIFXChar;
    KeyWhiteSpace:    Boolean;
    ValueWhiteSpace:  Boolean;
    //MaxValueLineLen:  Integer;
    LineBreak:        TIFXString;
  end;

  TIFXSettings = record
    FormatSettings:         TFormatSettings;
    IniFormat:              TIFXIniFormat;
    FullNameEval:           Boolean;
    ReadOnly:               Boolean;
    DuplicityBehavior:      TIFXDuplicityBehavior;
    DuplicityRenameOldStr:  TIFXString;
    DuplicityRenameNewStr:  TIFXString;
    WriteByteOrderMask:     Boolean;
  end;
  PIFXSettings = ^TIFXSettings;

procedure IFXInitSettings(var Sett: TIFXSettings);

type
  TIFXNodeIndices = record
    SectionIndex: Integer;
    KeyIndex:     Integer;
  end;

Function IFXNodeIndicesValid(Indices: TIFXNodeIndices): Boolean;

Function IFXTrimStr(const Str: TIFXString; WhiteSpaceChar: TIFXChar): TIFXString; overload;
Function IFXTrimStr(const Str: TIFXString): TIFXString; overload;

const
  IFX_INVALID_NODE_INDICES: TIFXNodeIndices = (SectionIndex: -1; KeyIndex: -1);

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

Function IFXStrToUTF8(const IFXStr: TIFXString): UTF8String;
begin
{$IF Declared(StringToUTF8)}
Result := StringToUTF8(Str);
{$ELSE}
Result := UTF8Encode(IFXStr);
{$IFEND}
end;

//------------------------------------------------------------------------------

Function UTF8ToIFXStr(const Str: UTF8String): TIFXString;
begin
{$IF Declared(UTF8ToString)}
Result := UTF8ToString(IFXStr);
{$ELSE}
Result := UTF8Decode(Str);
{$IFEND}
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

Function IFXValueTypeToByte(ValueType: TIFXValueType): Byte;
begin
case ValueType of
  ivtUndecided: REsult := IFX_VALTYPE_UNDECIDED;
  ivtBool:      Result := IFX_VALTYPE_BOOL;
  ivtInt8:      Result := IFX_VALTYPE_INT8;
  ivtUInt8:     Result := IFX_VALTYPE_UINT8;
  ivtInt16:     Result := IFX_VALTYPE_INT16;
  ivtUInt16:    Result := IFX_VALTYPE_UINT16;
  ivtInt32:     Result := IFX_VALTYPE_INT32;
  ivtUInt32:    Result := IFX_VALTYPE_UINT32;
  ivtInt64:     Result := IFX_VALTYPE_INT64;
  ivtUInt64:    Result := IFX_VALTYPE_UINT64;
  ivtFloat32:   Result := IFX_VALTYPE_FLOAT32;
  ivtFloat64:   Result := IFX_VALTYPE_FLOAT64;
  ivtDate:      Result := IFX_VALTYPE_DATE;
  ivtTime:      Result := IFX_VALTYPE_TIME;
  ivtDateTime:  Result := IFX_VALTYPE_DATETIME;
  ivtString:    Result := IFX_VALTYPE_STRING;
  ivtBinary:    Result := IFX_VALTYPE_BINARY;
else
  raise Exception.CreateFmt('ValueTypeToByte: Unknown value type (%d).',[Ord(ValueType)]);
end;
end;

//------------------------------------------------------------------------------

Function IFXByteToValueType(ByteValue: Byte): TIFXValueType;
begin
case ByteValue of
  IFX_VALTYPE_UNDECIDED:  Result := ivtUndecided;
  IFX_VALTYPE_BOOL:       Result := ivtBool;
  IFX_VALTYPE_INT8:       Result := ivtInt8;
  IFX_VALTYPE_UINT8:      Result := ivtUInt8;
  IFX_VALTYPE_INT16:      Result := ivtInt16;
  IFX_VALTYPE_UINT16:     Result := ivtUInt16;
  IFX_VALTYPE_INT32:      Result := ivtInt32;
  IFX_VALTYPE_UINT32:     Result := ivtUInt32;
  IFX_VALTYPE_INT64:      Result := ivtInt32;
  IFX_VALTYPE_UINT64:     Result := ivtUInt32;
  IFX_VALTYPE_FLOAT32:    Result := ivtFloat32;
  IFX_VALTYPE_FLOAT64:    Result := ivtFloat64;
  IFX_VALTYPE_DATE:       Result := ivtDate;
  IFX_VALTYPE_TIME:       Result := ivtTime;
  IFX_VALTYPE_DATETIME:   Result := ivtDateTime;
  IFX_VALTYPE_STRING:     Result := ivtString;
  IFX_VALTYPE_BINARY:     Result := ivtBinary;
else
  raise Exception.CreateFmt('ByteToValueType: Unknown value type (%d).',[ByteValue]);
end;
end;

//------------------------------------------------------------------------------

Function IFXValueEncodingToByte(ValueEncoding: TIFXValueEncoding): Byte;
begin
case ValueEncoding of
  iveBase2:       Result := IFX_VALENC_BASE2;
  iveBase64:      Result := IFX_VALENC_BASE64;
  iveBase85:      Result := IFX_VALENC_BASE85;
  iveHexadecimal: Result := IFX_VALENC_HEXADEC;
  iveNumber:      Result := IFX_VALENC_NUMBER;
  iveDefault:     Result := IFX_VALENC_DEFAULT;
else
  raise Exception.CreateFmt('ValueEncodingToByte: Unknown value encoding (%d).',[Ord(ValueEncoding)]);
end;
end;

//------------------------------------------------------------------------------

Function IFXByteToValueEncoding(ByteValue: Byte): TIFXValueEncoding;
begin
case ByteValue of
  IFX_VALENC_BASE2:   Result := iveBase2;
  IFX_VALENC_BASE64:  Result := iveBase64;
  IFX_VALENC_BASE85:  Result := iveBase85;
  IFX_VALENC_HEXADEC: Result := iveHexadecimal;
  IFX_VALENC_NUMBER:  Result := iveNumber;
  IFX_VALENC_DEFAULT: Result := iveDefault;
else
  raise Exception.CreateFmt('ByteToValueEncoding: Unknown value encoding (%d).',[ByteValue]);
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
Sett.FormatSettings.DecimalSeparator  := '.';
Sett.FormatSettings.DateSeparator     := '-';
Sett.FormatSettings.TimeSeparator     := ':';
Sett.FormatSettings.ShortDateFormat   := 'yyyy"-"mm"-"dd';
Sett.FormatSettings.LongDateFormat    := 'yyyy"-"mm"-"dd';
Sett.FormatSettings.ShortTimeFormat   := 'hh":"nn":"ss';
Sett.FormatSettings.LongTimeFormat    := 'hh":"nn":"ss';
Sett.FormatSettings.TwoDigitYearCenturyWindow := 50;
For i := Low(def_ShortMonthNames) to High(def_ShortMonthNames) do
  Sett.FormatSettings.ShortMonthNames[i] := def_ShortMonthNames[i];
For i := Low(def_LongMonthNames) to High(def_LongMonthNames) do
  Sett.FormatSettings.LongMonthNames[i] := def_LongMonthNames[i];
For i := Low(def_ShortDayNames) to High(def_ShortDayNames) do
  Sett.FormatSettings.ShortDayNames[i] := def_ShortDayNames[i];
For i := Low(def_LongDayNames) to High(def_LongDayNames) do
  Sett.FormatSettings.LongDayNames[i] := def_LongDayNames[i];
// ini file formatting options
Sett.IniFormat.EscapeChar       := '\';
Sett.IniFormat.QuoteChar        := '"';
Sett.IniFormat.NumericChar      := '#';
Sett.IniFormat.ForceQuote       := False;
Sett.IniFormat.CommentChar      := ';';
Sett.IniFormat.SectionStartChar := '[';
Sett.IniFormat.SectionEndChar   := ']';
Sett.IniFormat.ValueDelimChar   := '=';
Sett.IniFormat.WhiteSpaceChar   := ' ';
Sett.IniFormat.KeyWhiteSpace    := True;
Sett.IniFormat.ValueWhiteSpace  := True;
//Sett.IniFormat.MaxValueLineLen  := -1;
Sett.IniFormat.LineBreak        := StrToIFXStr(sLineBreak);
// other fields
Sett.FullNameEval          := True;
Sett.ReadOnly              := False;
Sett.DuplicityBehavior     := idbDrop;
Sett.DuplicityRenameOldStr := '_old';
Sett.DuplicityRenameNewStr := '_new';
Sett.WriteByteOrderMask    := False;
end;

//------------------------------------------------------------------------------

Function IFXNodeIndicesValid(Indices: TIFXNodeIndices): Boolean;
begin
Result := (Indices.SectionIndex >= 0) and (Indices.KeyIndex >= 0);
end;

//------------------------------------------------------------------------------

Function IFXTrimStr(const Str: TIFXString; WhiteSpaceChar: TIFXChar): TIFXString;
var
  StartIdx,EndIdx:  TStrSize;
  i:                TStrSize;
begin
If Length(Str) > 0 then
  begin
    StartIdx := -1;
    For i := 1 to Length(Str) do
      If (Ord(Str[i]) > 32) and (Str[i] <> WhiteSpaceChar) then
        begin
          StartIdx := i;
          Break{for i};
        end;
    If StartIdx > 0 then
      begin
        EndIdx := Length(Str);
        For i := Length(Str) downto 1 do
          If (Ord(Str[i]) > 32) and (Str[i] <> WhiteSpaceChar) then
            begin
              EndIdx := i;
              Break{for i};
            end;
        Result := Copy(Str,StartIdx,EndIdx - StartIdx + 1);
      end
    else Result := '';
  end
else Result := '';
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

Function IFXTrimStr(const Str: TIFXString): TIFXString;
begin
Result := IFXTrimStr(Str,TIFXChar(0));
end;

end.
