unit IniFileEx_Common;

{$INCLUDE '.\IniFileEx_defs.inc'}

interface

uses
  AuxTypes, CRC32;

type
  TIFXHashedString = record
    Str:  String;
    Hash: TCRC32;
  end;

procedure HashString(var HashStr: TIFXHashedString);{$IFDEF CanInline} inline; {$ENDIF}
Function HashedString(const Str: String): TIFXHashedString;{$IFDEF CanInline} inline; {$ENDIF}

Function SameHashString(const S1,S2: TIFXHashedString; FullEval: Boolean = True): Boolean;{$IFDEF CanInline} inline; {$ENDIF}

type
  TIFXValueType = (ivtBool,ivtInt8,ivtUInt8,ivtInt16,ivtUInt16,ivtInt32,
                   ivtUInt32,ivtInt64,ivtUInt64,ivtFloat32,ivtFloat64,ivtDate,
                   ivtTime,ivtDateTime,ivtString,ivtBinary,ivtUnknown);

  TIFXValueState = (ivsNeedsEncode,ivsNeedsDecode,ivsReady,ivsUndefined);

  TIFXValueEncoding = (iveDefault,iveBase2,iveBase8,iveBase10,iveNumber,
                       iveBase16,iveHexadecimal,iveBase32,iveBase32Hex,
                       iveBase64,iveBase85,iveUnknown);

  TIFXValueData = record
    StringValue:  String; // managed type cannot be in a variant section
    case ValueType: TIFXValueType of
      ivtBool:      (BoolValue:       Boolean);
      ivtInt8:      (Int8Value:       Int8);
      ivtUInt8:     (UInt8Value:      UInt8);
      ivtInt16:     (Int16Value:      Int16);
      ivtUInt16:    (UInt16Value:     UInt16);
      ivtInt32:     (Int32Value:      Int32);
      ivtUInt32:    (UInt32Value:     UInt32);
      ivtInt64:     (Int64Value:      Int64);
      ivtUInt64:    (UInt64Value:     UInt64);
      ivtFloat32:   (Float32Value:    Float32);
      ivtFloat64:   (Float64Value:    Float64);
      ivtDate:      (DateValue:       TDateTime);
      ivtTime:      (TimeValue:       TDateTime);
      ivtDateTime:  (DateTimeValue:   TDateTime);
      ivtString:    ();                           // stored in field StringValue
      ivtBinary:    (BinaryValueSize: Integer;
                     BinaryValuePtr:  Pointer);
      ivtUnknown:   ();
  end;

  TIFXSettings = record
  end;
  PIFXSettings = ^TIFXSettings;

  TIFXNodeIndices = record
    SectionIndex: Integer;
    KeyIndex:     Integer;
  end;

const
  IFX_INVALID_NODE_INDICES: TIFXNodeIndices = (SectionIndex: -1; KeyIndex: -1);

implementation

uses
  SysUtils;

procedure HashString(var HashStr: TIFXHashedString);
begin
HashStr.Hash := StringCRC32(HashStr.Str);
end;

//------------------------------------------------------------------------------

Function HashedString(const Str: String): TIFXHashedString;
begin
Result.Str := Str;
HashString(Result);
end;

//------------------------------------------------------------------------------

Function SameHashString(const S1, S2: TIFXHashedString; FullEval: Boolean = True): Boolean;
begin
Result := SameCRC32(S1.Hash,S2.Hash) and (not FullEval or AnsiSameText(S1.Str,S2.Str));
end;

end.
