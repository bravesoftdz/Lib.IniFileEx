unit IniFileEx_Common;

{$INCLUDE '.\IniFileEx_defs.inc'}

interface

uses
  SysUtils,
  AuxTypes, CRC32, BinTextEnc;

type
  TIFXString = UnicodeString;

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

  TIFXSettings = record
    FormatSettings: TFormatSettings;
    FullNameEval:   Boolean;
  end;
  PIFXSettings = ^TIFXSettings;

procedure IFXInitSettings(var Sett: TIFXSettings);

type
  TIFXNodeIndices = record
    SectionIndex: Integer;
    KeyIndex:     Integer;
  end;

const
  IFX_INVALID_NODE_INDICES: TIFXNodeIndices = (SectionIndex: -1; KeyIndex: -1);

  IFX_ENC_STR_HEXADECIMAL = UnicodeChar('$');
  IFX_ENC_STR_ESCAPECHAR  = UnicodeChar('\');
  IFX_ENC_STR_QUOTECHAR   = UnicodeChar('"');
  IFX_ENC_STR_CHARNUM     = UnicodeChar('#');

implementation

uses
  Windows;

procedure IFXHashString(var HashStr: TIFXHashedString);
begin
HashStr.Hash := WideStringCRC32(HashStr.Str);
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
{$IFDEF Unicode}AnsiSameText(S1.Str,S2.Str){$ELSE}WideSameText(S1.Str,S2.Str){$ENDIF});
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
begin
{$WARN SYMBOL_PLATFORM OFF}
GetLocaleFormatSettings(LOCALE_USER_DEFAULT,Sett.FormatSettings);
{$WARN SYMBOL_PLATFORM ON}
Sett.FormatSettings.ThousandSeparator := #0;
Sett.FormatSettings.DecimalSeparator := '.';
Sett.FormatSettings.DateSeparator := '-';
Sett.FormatSettings.TimeSeparator := ':';
Sett.FormatSettings.ShortDateFormat := 'yyyy"-"mm"-"dd';
Sett.FormatSettings.LongDateFormat := 'yyyy"-"mm"-"dd';
Sett.FormatSettings.ShortTimeFormat := 'hh":"nn":"ss';
Sett.FormatSettings.LongTimeFormat := 'hh":"nn":"ss';
Sett.FullNameEval := True;
end;

end.
