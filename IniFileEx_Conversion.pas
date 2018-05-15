unit IniFileEx_Conversion;

{$INCLUDE '.\IniFileEx_defs.inc'}

interface

uses
  AuxTypes,
  IniFileEx_Common;

Function IFXUInt64ToStr(Value: UInt64): TIFXString;
Function IFXStrToUInt64(const Str: TIFXString): UInt64;
Function IFXTryStrToUInt64(const Str: TIFXString; out Value: UInt64): Boolean;

Function IFXBoolToStr(Value: Boolean; AsString: Boolean): TIFXString;
Function IFXTryStrToBool(const Str: TIFXString; out Value: Boolean): Boolean;

Function IFXEncodeString(const Str: TIFXString): TIFXString;
Function IFXDecodeString(const Str: TIFXString): TIFXString;

implementation

uses
  SysUtils;

const
  UInt64BitTable: array[0..63] of TIFXString = (
    '00000000000000000001','00000000000000000002','00000000000000000004','00000000000000000008',
    '00000000000000000016','00000000000000000032','00000000000000000064','00000000000000000128',
    '00000000000000000256','00000000000000000512','00000000000000001024','00000000000000002048',
    '00000000000000004096','00000000000000008192','00000000000000016384','00000000000000032768',
    '00000000000000065536','00000000000000131072','00000000000000262144','00000000000000524288',
    '00000000000001048576','00000000000002097152','00000000000004194304','00000000000008388608',
    '00000000000016777216','00000000000033554432','00000000000067108864','00000000000134217728',
    '00000000000268435456','00000000000536870912','00000000001073741824','00000000002147483648',
    '00000000004294967296','00000000008589934592','00000000017179869184','00000000034359738368',
    '00000000068719476736','00000000137438953472','00000000274877906944','00000000549755813888',
    '00000001099511627776','00000002199023255552','00000004398046511104','00000008796093022208',
    '00000017592186044416','00000035184372088832','00000070368744177664','00000140737488355328',
    '00000281474976710656','00000562949953421312','00001125899906842624','00002251799813685248',
    '00004503599627370496','00009007199254740992','00018014398509481984','00036028797018963968',
    '00072057594037927936','00144115188075855872','00288230376151711744','00576460752303423488',
    '01152921504606846976','02305843009213693952','04611686018427387904','09223372036854775808');

//------------------------------------------------------------------------------

Function IFXUInt64ToStr(Value: UInt64): TIFXString;
var
  i,j:      Integer;
  CharOrd:  Integer;
  Carry:    Integer;
begin
Result := StrToIFXStr(StringOfChar('0',Length(UInt64BitTable[0])));
Carry := 0;
For i := 0 to 63 do
  If ((Value shr i) and 1) <> 0 then
    For j := Length(Result) downto 1 do
      begin
        CharOrd := (Ord(Result[j]) - Ord('0')) + (Ord(UInt64BitTable[i][j]) - Ord('0')) + Carry;
        Carry := CharOrd div 10;
        Result[j] := TIFXChar(Ord('0') + CharOrd mod 10);
      end;
// remove leading zeroes
i := 0;
repeat
  Inc(i);
until (Result[i] <> '0') or (i >= Length(Result));
Result := Copy(Result,i,Length(Result));
end;

//------------------------------------------------------------------------------

Function IFXStrToUInt64(const Str: TIFXString): UInt64;
var
  TempStr:  TIFXString;
  ResStr:   TIFXString;
  i:        Integer;

  Function CompareValStr(const S1,S2: TIFXString): Integer;
  var
    ii: Integer;
  begin
    Result := 0;
    For ii := 1 to Length(S1) do
      If Ord(S1[ii]) < Ord(S2[ii]) then
        begin
          Result := 1;
          Break{For ii};
        end
      else If Ord(S1[ii]) > Ord(S2[ii]) then
        begin
          Result := -1;
          Break{For ii};
        end      
  end;

  Function SubtractValStr(const S1,S2: TIFXString; out Res: TIFXString): Integer;
  var
    ii:       Integer;
    CharVal:  Integer;
  begin
    SetLength(Res,Length(S1));
    Result := 0;
    For ii := Length(S1) downto 1 do
      begin
        CharVal := Ord(S1[ii]) - Ord(S2[ii]) + Result;
        If CharVal < 0 then
          begin
            CharVal := CharVal + 10;
            Result := -1;
          end
        else Result := 0;
        Res[ii] := TIFXChar(Abs(CharVal) + Ord('0'));
      end;
    If Result < 0 then
      Res := S1;  
  end;

begin
Result := 0;
// rectify string
If Length(Str) < Length(UInt64BitTable[0]) then
  TempStr := StrToIFXStr(StringOfChar('0',Length(UInt64BitTable[0]) - Length(Str))) + Str
else If Length(Str) > Length(UInt64BitTable[0]) then
  raise EConvertError.CreateFmt('IFXStrToUInt64: "%s" is not a valid integer string.',[Str])
else
  TempStr := Str;
// check if string contains only numbers  
For i := 1 to Length(TempStr) do
  If not(Ord(TempStr[i]) in [Ord('0')..Ord('9')]) then
    raise EConvertError.CreateFmt('IFXStrToUInt64: "%s" is not a valid integer string.',[Str]);
For i := 63 downto 0 do
  If SubtractValStr(TempStr,UInt64BitTable[i],ResStr) >= 0 then
    If CompareValStr(ResStr,UInt64BitTable[i]) > 0 then
      begin
        Result := Result or (UInt64(1) shl i);
        TempStr := ResStr;
      end
    else raise EConvertError.CreateFmt('IFXStrToUInt64: "%s" is not a valid integer string.',[Str]);
end;

//------------------------------------------------------------------------------

Function IFXTryStrToUInt64(const Str: TIFXString; out Value: UInt64): Boolean;
begin
try
  Value := IFXStrToUInt64(Str);
  Result := True;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function IFXBoolToStr(Value: Boolean; AsString: Boolean): TIFXString;
begin
If AsString then
  begin
    If Value then Result := 'True'
      else Result := 'False';
  end
else
  begin
    If Value then Result := '1'
      else Result := '0';
  end;
end;

//------------------------------------------------------------------------------

Function IFXTryStrToBool(const Str: TIFXString; out Value: Boolean): Boolean;
begin
Result := True;
If IFXCompareText(Str,'true') = 0 then
  Value := True
else If IFXCompareText(Str,'false') = 0 then
  Value := False
else
  Result := False;
end;
 
//------------------------------------------------------------------------------

Function IFXEncodeString(const Str: TIFXString): TIFXString;
var
  i:        TStrSize;
  Temp:     TStrSize;
  Quoted:   Boolean;
  StrTemp:  TIFXString;
begin
// scan string
Temp := 0; 
Quoted := False;
For i := 1 to Length(Str) do
  case Str[i] of
    #32:        // space
      begin
        Inc(Temp);
        Quoted := True;
      end;
    #1..#6,#14..#31:
      begin     // chars replaced by \#xxxx
        Inc(Temp,6);
        Quoted := True;
      end;
    #0,#7..#13,
    IFX_ENC_STR_ESCAPECHAR,
    IFX_ENC_STR_QUOTECHAR:
      begin     // replaced by \C or doubled
        Inc(Temp,2);
        Quoted := True;
     end;
  else
    Inc(Temp);
  end;
If Quoted then
  begin
    SetLength(Result,Temp + 2);
    Result[1] := IFX_ENC_STR_QUOTECHAR;
    Result[Length(result)] := IFX_ENC_STR_QUOTECHAR;
  end
else SetLength(Result,Temp);
// encode string
If Quoted then
  Temp := 2
else
  Temp := 1;
For i := 1 to Length(Str) do
  case Str[i] of
    #1..#6,#14..#31:
      begin
        Result[Temp] := IFX_ENC_STR_ESCAPECHAR;
        Result[Temp + 1] := IFX_ENC_STR_CHARNUM;
        StrTemp := StrToIFXStr(IntToHex(Ord(Str[i]),4));
        Result[Temp + 2] := StrTemp[1];
        Result[Temp + 3] := StrTemp[2];
        Result[Temp + 4] := StrTemp[3];
        Result[Temp + 5] := StrTemp[4];
        Inc(Temp,6);
      end;
    #0,#7..#13:
      begin
        Result[Temp] := IFX_ENC_STR_ESCAPECHAR;
        case Str[i] of
          #0:   Result[Temp + 1] := '0';  // null
          #7:   Result[Temp + 1] := 'a';
          #8:   Result[Temp + 1] := 'b';
          #9:   Result[Temp + 1] := 't';  // horizontal tab
          #10:  Result[Temp + 1] := 'n';  // line feed
          #11:  Result[Temp + 1] := 'v';  // vertical tab
          #12:  Result[Temp + 1] := 'f';
          #13:  Result[Temp + 1] := 'r';  // carriage return
        end;
        Inc(Temp,2);
      end;
    IFX_ENC_STR_ESCAPECHAR,
    IFX_ENC_STR_QUOTECHAR:
      begin
        Result[Temp] := IFX_ENC_STR_ESCAPECHAR;
        Result[Temp + 1] := Str[i];
        Inc(Temp,2);
      end;
  else
    Result[Temp] := Str[i];
    Inc(Temp);
  end;
end;
 
//------------------------------------------------------------------------------

Function IFXDecodeString(const Str: TIFXString): TIFXString;
var
  Quoted:   Boolean;
  i,ResPos: TStrSize;
  Temp:     Integer;

  procedure SetAndAdvance(NewChar: TIFXChar; SrcShift, ResShift: Integer);
  begin
    Result[ResPos] := NewChar;
    Inc(i,SrcShift);
    Inc(ResPos,resShift);
  end;

begin
If Length(Str) > 0 then
  begin
    SetLength(Result,Length(Str));
    Quoted := Str[1] = IFX_ENC_STR_QUOTECHAR;
    If Quoted then i := 2
      else i := 1;
    ResPos := 1;
    while i <= Length(Str) do
      case Str[i] of
        IFX_ENC_STR_ESCAPECHAR:
          If i < Length(Str) then
            case Str[i + 1] of
              IFX_ENC_STR_ESCAPECHAR,
              IFX_ENC_STR_QUOTECHAR:
                SetAndAdvance(Str[i + 1],2,1);
              IFX_ENC_STR_CHARNUM:
                If (i + 4) < Length(Str) then
                  begin
                    If TryStrToInt(IFXStrToStr(IFX_ENC_STR_HEXADECIMAL + Copy(Str,i + 2,4)),Temp) then
                      SetAndAdvance(TIFXChar(Temp),6,1)
                    else
                      Break{while...};
                  end
                else Break{while...};
              '0':  SetAndAdvance(#0,2,1);
              'a':  SetAndAdvance(#7,2,1);
              'b':  SetAndAdvance(#8,2,1);
              't':  SetAndAdvance(#9,2,1);
              'n':  SetAndAdvance(#10,2,1);
              'v':  SetAndAdvance(#11,2,1);
              'f':  SetAndAdvance(#12,2,1);
              'r':  SetAndAdvance(#13,2,1);
            else
              Break{while...};
            end
          else Break{while...};
        IFX_ENC_STR_QUOTECHAR:
          begin
            If Quoted then
              Break{while...};
            SetAndAdvance(Str[i],1,1);
          end;
      else
        SetAndAdvance(Str[i],1,1);
      end;
    SetLength(Result,ResPos - 1);
  end
else Result := '';
end;
 
end.
