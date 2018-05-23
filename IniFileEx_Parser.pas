unit IniFileEx_Parser;

{$INCLUDE '.\IniFileEx_defs.inc'}

interface

uses
  Classes,
  AuxTypes, ExplicitStringLists,
  IniFileEx_Common, IniFileEx_Nodes;

{===============================================================================
--------------------------------------------------------------------------------
                                   TIFXParser
--------------------------------------------------------------------------------
===============================================================================}
type
  TIFXBiniFileHeader = packed record
    Signature:  UInt32;
    Structure:  UInt16;
    Flags:      UInt16;
    DataSize:   UInt64;
  end;

  TIFXTextLineType = (tltEmpty,tltComment,tltSection,tltKey);

const
  IFX_UTF8BOM: packed array[0..2] of Byte = ($EF,$BB,$BF);

  IFX_BINI_SIGNATURE_FILE    = UInt32($494E4942); // BINI
  IFX_BINI_SIGNATURE_SECTION = UInt32($54434553); // SECT
  IFX_BINI_SIGNATURE_KEY     = UInt32($5659454B); // KEYV

  IFX_BINI_MINFILESIZE = SizeOf(TIFXBiniFileHeader);

  IFX_BINI_STRUCT_0 = UInt16(0);  // more may be added in the future

  IFX_BINI_FLAGS_ZLIB_COMPRESS = UInt16($0001); // not yet implemented
  IFX_BINI_FLAGS_AES_ENCRYPT   = UInt16($0002); // not yet implemented

{===============================================================================
    TIFXParser - class declaration
===============================================================================}
type
  TIFXParser = class(TObject)
  private
    fSettingsPtr:         PIFXSettings;
    fFileNode:            TIFXFileNode;
    fStream:              TStream;
    // for textual processing...
    fEmptyLinePos:        Int64;
    fIniStrings:          TUTF8StringList;
    fLastComment:         TIFXString;
    fFileCommentSet:      Boolean;
    fLastTextLineType:    TIFXTextLineType;
    fCurrentSectionNode:  TIFXSectionNode;
    // for binary processing...
    fBinFileHeader:       TIFXBiniFileHeader;
  protected
    // writing textual ini
    Function Text_WriteEmptyLine: TMemSize; virtual;
    Function Text_WriteString(const Str: TIFXString): TMemSize; virtual;
    Function Text_WriteSection(SectionNode: TIFXSectionNode): TMemSize; virtual;
    Function Text_WriteKey(KeyNode: TIFXKeyNode): TMemSize; virtual;
    // reading textual ini
    procedure Text_AddToLastComment(const Comment: TIFXString); virtual;
    Function Text_ConsumeLastComment: TIFXString; virtual;
    procedure Text_ReadLine; virtual;
    procedure Text_ReadCommentLine; virtual;
    procedure Text_ReadSectionLine; virtual;
    procedure Text_ReadKeyLine; virtual;
    // writing binary ini of structure 0x0000
    Function Binary_0000_WriteString(const Str: TIFXString): TMemSize; virtual;
    Function Binary_0000_WriteSection(SectionNode: TIFXSectionNode): TMemSize; virtual;
    Function Binary_0000_WriteKey(KeyNode: TIFXKeyNode): TMemSize; virtual;
    // reading binary ini of structure 0x0000
    Function Binary_0000_ReadString: TIFXString; virtual;
    procedure Binary_0000_ReadData; virtual;
    Function Binary_0000_ReadSection(out SectionNode: TIFXSectionNode): Boolean; virtual;
    Function Binary_0000_ReadKey(SectionNode: TIFXSectionNode; out KeyNode: TIFXKeyNode): Boolean; virtual;
  public
    constructor Create(SettingsPtr: PIFXSettings; FileNode: TIFXFileNode);
    // auxiliary methods
    Function ConstructCommentBlock(const CommentStr: TIFXString): TIFXString; virtual;
    Function ConstructSectionName(SectionNode: TIFXSectionNode): TIFXString; virtual;
    Function ConstructKeyValueLine(KeyNode: TIFXKeyNode): TIFXString; virtual;
    // writing to stream
    procedure WriteTextual(Stream: TStream); virtual;
    procedure ReadTextual(Stream: TStream); virtual;
    procedure WriteBinary(Stream: TStream); virtual;
    procedure ReadBinary(Stream: TStream); virtual;
  end;

implementation

uses
  SysUtils,
  BinaryStreaming,
  IniFileEx_Utils;

{
  Binary INI format:
    UInt32    - signature (BINI)
    UInt16    - file structure (number)
    UInt16    - flags
    UInt64    - data size
    []        - data

  Data:
    String[]  - file comment
    UInt32    - section count
    Section[] - array of sections

  Section:
    UInt32    - signature (SECT)
    String[]  - section name
    String[]  - section comment
    UInt32    - key count
    Key[]     - array of keys

  Key:
    UInt32    - signature (KEYV)
    String[]  - key name
    String[]  - key comment
    UInt8     - value encoding
    UInt8     - value type
    []        - data (size depending on value type)

  String:
    UInt32      - string length
    UTF8Char[]  - array of UTF8 characters
}

{===============================================================================
--------------------------------------------------------------------------------
                                   TIFXParser                                                                         
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TIFXParser - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TIFXParser - protected methods
-------------------------------------------------------------------------------}

Function TIFXParser.Text_WriteEmptyLine: TMemSize;
var
  TempStr:  UTF8String;
begin
If fStream.Position <> fEmptyLinePos then
  begin
    TempStr := IFXStrToUTF8(fSettingsPtr.IniFormat.LineBreak);
    Result := TMemSize(Stream_WriteBuffer(fStream,PUTF8Char(TempStr)^,Length(TempStr) * SizeOf(UTF8Char)));
    fEmptyLinePos := fStream.Position;
  end
else Result := 0;
end;

//------------------------------------------------------------------------------

Function TIFXParser.Text_WriteString(const Str: TIFXString): TMemSize;
var
  TempStr:  UTF8String;
begin
If Length(Str) > 0 then
  begin
    TempStr := IFXStrToUTF8(Str + fSettingsPtr.IniFormat.LineBreak);
    If Length(TempStr) > 0 then
      Result := TMemSize(Stream_WriteBuffer(fStream,PUTF8Char(TempStr)^,Length(TempStr) * SizeOf(UTF8Char)))
    else
      Result := 0;
  end
else Result := 0;
end;

//------------------------------------------------------------------------------

Function TIFXParser.Text_WriteSection(SectionNode: TIFXSectionNode): TMemSize;
var
  i:  Integer;
begin
Result := Text_WriteEmptyLine;
Inc(Result,Text_WriteString(ConstructCommentBlock(SectionNode.Comment)));
Inc(Result,Text_WriteString(ConstructSectionName(SectionNode)));
For i := SectionNode.LowIndex to SectionNode.HighIndex do
  Inc(Result,Text_WriteKey(SectionNode[i]));
end;

//------------------------------------------------------------------------------

Function TIFXParser.Text_WriteKey(KeyNode: TIFXKeyNode): TMemSize;
begin
Result := Text_WriteString(ConstructCommentBlock(KeyNode.Comment));
Inc(Result,Text_WriteString(ConstructKeyValueLine(KeyNode)));
end;

//------------------------------------------------------------------------------

procedure TIFXParser.Text_AddToLastComment(const Comment: TIFXString);
begin
If Length(fLastComment) > 0 then
  fLastComment := fLastComment + fSettingsPtr^.IniFormat.LineBreak + Comment
else
  fLastComment := Comment;
end;
//------------------------------------------------------------------------------

Function TIFXParser.Text_ConsumeLastComment: TIFXString;
begin
Result := fLastComment;
fLastComment := '';
end;

//------------------------------------------------------------------------------

procedure TIFXParser.Text_ReadLine;
var
  FirstLineChar:  TIFXChar;
begin
// select how to parse the line according to first character
If Length(fIniStrings[fIniStrings.UserData]) > 0 then
  begin
    // there should be no need for conversion, so just typecast
    FirstLineChar := TIFXChar(fIniStrings[fIniStrings.UserData][1]);
    If FirstLineChar = fSettingsPtr^.IniFormat.CommentChar then
      Text_ReadCommentLine
    else If FirstLineChar = fSettingsPtr^.IniFormat.SectionStartChar then
      Text_ReadSectionLine
    else
      // invalid lines will fall to key parser
      Text_ReadKeyLine;
  end
else fLastTextLineType := tltEmpty;
end;

//------------------------------------------------------------------------------

procedure TIFXParser.Text_ReadCommentLine;
begin
If (fLastTextLineType <> tltComment) and (Length(fLastComment) > 0) then
  begin
    If not fFileCommentSet then
      begin
        fFileNode.Comment := fLastComment;
        fFileCommentSet := True;
      end
    else
      begin
        If not Assigned(fCurrentSectionNode) then
          begin
            fCurrentSectionNode := TIFXSectionNode.Create('',fFileNode.SettingsPtr);
            fCurrentSectionNode.Comment := fLastComment;
            fFileNode.AddSectionNode(fCurrentSectionNode);
          end;
      end;
    fLastComment := '';
  end;
Text_AddToLastComment(UTF8ToIFXStr(Copy(fIniStrings[fIniStrings.UserData],2,
  Length(fIniStrings[fIniStrings.UserData]) - 1)));
fLastTextLineType := tltComment;
end;

//------------------------------------------------------------------------------

procedure TIFXParser.Text_ReadSectionLine;
var
  TempStr:  TIFXString;
  i,p:      TStrSize;
  Cntr:     Integer;
begin
TempStr := UTF8ToIFXStr(fIniStrings[fIniStrings.UserData]);
// find closing character; if not present, discard line
p := -1;
For i := 1 to Length(TempStr) do
  If TempStr[i] = fSettingsPtr^.IniFormat.SectionEndChar then
    begin
      p := i;
      Break{For i};
    end;
If p > 0 then
  begin
    // extract section name from the line
    TempStr := Copy(TempStr,2,p - 2);
    i := fFileNode.IndexOfSection(TempStr);
    If i >= 0 then
      // section of this name is already present
      case fSettingsPtr^.DuplicityBehavior of
        idbReplace:
          begin
            fCurrentSectionNode := fFileNode[i];
            fCurrentSectionNode.Comment := Text_ConsumeLastComment;
          end;
        idbRenameOld:
          begin
            If fFileNode.IndexOfSection(TempStr + fSettingsPtr^.DuplicityRenameOldStr) >= 0 then
              begin
                Cntr := 0;
                while fFileNode.IndexOfSection(TempStr + fSettingsPtr^.DuplicityRenameOldStr +
                  StrToIFXStr(IntToStr(Cntr))) >= 0 do Inc(Cntr);
                fFileNode[i].NameStr := TempStr + fSettingsPtr^.DuplicityRenameOldStr +
                  StrToIFXStr(IntToStr(Cntr));
              end
            else fFileNode[i].NameStr := TempStr + fSettingsPtr^.DuplicityRenameOldStr;
            fCurrentSectionNode := TIFXSectionNode.Create(TempStr,fFileNode.SettingsPtr);
            fCurrentSectionNode.Comment := Text_ConsumeLastComment;
            fFileNode.AddSectionNode(fCurrentSectionNode);
          end;
        idbRenameNew:
          begin
            If fFileNode.IndexOfSection(TempStr + fSettingsPtr^.DuplicityRenameNewStr) >= 0 then
              begin
                Cntr := 0;
                while fFileNode.IndexOfSection(TempStr + fSettingsPtr^.DuplicityRenameNewStr +
                  StrToIFXStr(IntToStr(Cntr))) >= 0 do Inc(Cntr);
                TempStr := TempStr + fSettingsPtr^.DuplicityRenameNewStr + StrToIFXStr(IntToStr(Cntr));
              end
            else TempStr := TempStr + fSettingsPtr^.DuplicityRenameNewStr;
            fCurrentSectionNode := TIFXSectionNode.Create(TempStr,fFileNode.SettingsPtr);
            fCurrentSectionNode.Comment := Text_ConsumeLastComment;
            fFileNode.AddSectionNode(fCurrentSectionNode);
          end;
      else
        {idbDrop}
        fCurrentSectionNode := fFileNode[i];
        Text_ConsumeLastComment;
      end
    else
      begin
        // section of this name does not yet exist, create node and add it
        fCurrentSectionNode := TIFXSectionNode.Create(TempStr,fFileNode.SettingsPtr);
        fCurrentSectionNode.Comment := Text_ConsumeLastComment;
        fFileNode.AddSectionNode(fCurrentSectionNode);
      end;
    fLastTextLineType := tltSection;  
  end
else fLastTextLineType := tltEmpty;
end;

//------------------------------------------------------------------------------

procedure TIFXParser.Text_ReadKeyLine;
var
  TempStr:  TIFXString;
  i,p:      TSTrSize;
  KeyName:  TIFXString;
  KeyCmnt:  TIFXString;
  KeyNode:  TIFXKeyNode;
  Cntr:     Integer;
begin
TempStr := UTF8ToIFXStr(fIniStrings[fIniStrings.UserData]);
// get position of value delimiter
p := -1;
For i := 1 to Length(TempStr) do
  If TempStr[i] = fSettingsPtr^.IniFormat.ValueDelimChar then
    begin
      p := i;
      Break{For i};
    end;
If p > 0 then
  begin
    // everything in front of delimiter is key, everything behind is value
    KeyName := IFXTrimStr(Copy(TempStr,1,p - 1),fSettingsPtr^.IniFormat.WhiteSpaceChar);
    TempStr := IFXTrimStr(Copy(TempStr,p + 1,Length(TempStr) - p),fSettingsPtr^.IniFormat.WhiteSpaceChar);
    KeyCmnt := Text_ConsumeLastComment;
    If not Assigned(fCurrentSectionNode) then
      begin
        // section-less key
        fCurrentSectionNode := TIFXSectionNode.Create('',fFileNode.SettingsPtr);
        fFileNode.AddSectionNode(fCurrentSectionNode);
      end;
    i := fCurrentSectionNode.IndexOfKey(KeyName);
    If i >= 0 then
      // key of this name is already present
      case fSettingsPtr^.DuplicityBehavior of
        idbReplace:
          begin
            fCurrentSectionNode[i].Comment := KeyCmnt;
            fCurrentSectionNode[i].ValueStr := TempStr;
          end;
        idbRenameOld:
          begin
            If fCurrentSectionNode.IndexOfKey(KeyName + fSettingsPtr^.DuplicityRenameOldStr) >= 0 then
              begin
                Cntr := 0;
                while fCurrentSectionNode.IndexOfKey(KeyName + fSettingsPtr^.DuplicityRenameOldStr +
                  StrToIFXStr(IntToStr(Cntr))) >= 0 do Inc(Cntr);
                fCurrentSectionNode[i].NameStr := KeyName + fSettingsPtr^.DuplicityRenameOldStr +
                  StrToIFXStr(IntToStr(Cntr));
              end
            else fCurrentSectionNode[i].NameStr := KeyName + fSettingsPtr^.DuplicityRenameOldStr;
            KeyNode := TIFXKeyNode.Create(KeyName,fCurrentSectionNode.SettingsPtr);
            KeyNode.Comment := KeyCmnt;
            KeyNode.ValueStr := TempStr;
            fCurrentSectionNode.AddKeyNode(KeyNode);
          end;
        idbRenameNew:
          begin
            If fCurrentSectionNode.IndexOfKey(KeyName + fSettingsPtr^.DuplicityRenameNewStr) >= 0 then
              begin
                Cntr := 0;
                while fCurrentSectionNode.IndexOfKey(KeyName + fSettingsPtr^.DuplicityRenameNewStr +
                  StrToIFXStr(IntToStr(Cntr))) >= 0 do Inc(Cntr);
                KeyName := KeyName + fSettingsPtr^.DuplicityRenameNewStr + StrToIFXStr(IntToStr(Cntr));
              end
            else KeyName := KeyName + fSettingsPtr^.DuplicityRenameNewStr;
            KeyNode := TIFXKeyNode.Create(KeyName,fCurrentSectionNode.SettingsPtr);
            KeyNode.Comment := KeyCmnt;
            KeyNode.ValueStr := TempStr;
            fCurrentSectionNode.AddKeyNode(KeyNode);
          end;
      else
        {idbDrop}
        // do nothing, discard everything
      end
    else
      begin
        KeyNode := TIFXKeyNode.Create(KeyName,fCurrentSectionNode.SettingsPtr);
        KeyNode.Comment := KeyCmnt;
        KeyNode.ValueStr := TempStr;
        fCurrentSectionNode.AddKeyNode(KeyNode);
      end;
    fLastTextLineType := tltKey;  
  end
else fLastTextLineType := tltEmpty;
end;

//------------------------------------------------------------------------------

Function TIFXParser.Binary_0000_WriteString(const Str: TIFXString): TMemSize;
var
  TempStr:  UTF8String;
begin
If Length(Str) > 0 then
  begin
    TempStr := IFXStrToUTF8(Str);
    Result := Stream_WriteUInt32(fStream,Length(TempStr));
    Inc(Result,Stream_WriteBuffer(fStream,PUTF8Char(TempStr)^,Length(TempStr) * SizeOf(UTF8Char)));
  end
else Result := Stream_WriteUInt32(fStream,0);
end;

//------------------------------------------------------------------------------

Function TIFXParser.Binary_0000_WriteSection(SectionNode: TIFXSectionNode): TMemSize;
var
  i:  Integer;
begin
Result := Stream_WriteUInt32(fStream,IFX_BINI_SIGNATURE_SECTION);
Inc(Result,Binary_0000_WriteString(SectionNode.NameStr));
Inc(Result,Binary_0000_WriteString(SectionNode.Comment));
Inc(Result,Stream_WriteUInt32(fStream,SectionNode.KeyCount));
For i := SectionNode.LowIndex to SectionNode.HighIndex do
  Inc(Result,Binary_0000_WriteKey(SectionNode[i]));
end;

//------------------------------------------------------------------------------

Function TIFXParser.Binary_0000_WriteKey(KeyNode: TIFXKeyNode): TMemSize;
begin
Result := Stream_WriteUInt32(fStream,IFX_BINI_SIGNATURE_KEY);
Inc(Result,Binary_0000_WriteString(KeyNode.NameStr));
Inc(Result,Binary_0000_WriteString(KeyNode.Comment));
Inc(Result,Stream_WriteUInt8(fStream,UInt8(IFXValueEncodingToByte(KeyNode.ValueEncoding))));
Inc(Result,Stream_WriteUInt8(fStream,UInt8(IFXValueTypeToByte(KeyNode.ValueType))));
case KeyNode.ValueType of
  ivtBool:      Inc(Result,Stream_WriteBoolean(fStream,KeyNode.ValueData.BoolValue));
  ivtInt8:      Inc(Result,Stream_WriteInt8(fStream,KeyNode.ValueData.Int8Value));
  ivtUInt8:     Inc(Result,Stream_WriteUInt8(fStream,KeyNode.ValueData.UInt8Value));
  ivtInt16:     Inc(Result,Stream_WriteInt16(fStream,KeyNode.ValueData.Int16Value));
  ivtUInt16:    Inc(Result,Stream_WriteUInt16(fStream,KeyNode.ValueData.UInt16Value));
  ivtInt32:     Inc(Result,Stream_WriteInt32(fStream,KeyNode.ValueData.Int32Value));
  ivtUInt32:    Inc(Result,Stream_WriteUInt32(fStream,KeyNode.ValueData.UInt32Value));
  ivtInt64:     Inc(Result,Stream_WriteInt64(fStream,KeyNode.ValueData.Int64Value));
  ivtUInt64:    Inc(Result,Stream_WriteUInt64(fStream,KeyNode.ValueData.UInt64Value));
  ivtFloat32:   Inc(Result,Stream_WriteFloat32(fStream,KeyNode.ValueData.Float32Value));
  ivtFloat64:   Inc(Result,Stream_WriteFloat64(fStream,KeyNode.ValueData.Float64Value));
  ivtDate:      Inc(Result,Stream_WriteBuffer(fStream,KeyNode.ValueData.DateValue,SizeOf(TDateTime)));
  ivtTime:      Inc(Result,Stream_WriteBuffer(fStream,KeyNode.ValueData.TimeValue,SizeOf(TDateTime)));
  ivtDateTime:  Inc(Result,Stream_WriteBuffer(fStream,KeyNode.ValueData.DateTimeValue,SizeOf(TDateTime)));
  ivtBinary:    begin
                  Inc(Result,Stream_WriteUInt64(fStream,UInt64(KeyNode.ValueData.BinaryValueSize)));
                  Inc(Result,Stream_WriteBuffer(fStream,KeyNode.ValueData.BinaryValuePtr^,KeyNode.ValueData.BinaryValueSize));
                end;
  ivtString:    Inc(Result,Binary_0000_WriteString(KeyNode.ValueData.StringValue));
else
  {ivtUndecided}
  Inc(Result,Binary_0000_WriteString(KeyNode.ValueStr));
end;
end;

//------------------------------------------------------------------------------

Function TIFXParser.Binary_0000_ReadString: TIFXString;
var
  StrLen:   UInt32;
  TempStr:  UTF8String;
begin
If Stream_ReadUInt32(fStream,StrLen) = SizeOf(UInt32) then
  begin
    SetLength(TempStr,StrLen);
    If Stream_ReadBuffer(fStream,PUTF8Char(TempStr)^,StrLen * SizeOf(UTF8Char)) = (StrLen * SizeOf(UTF8Char)) then
      Result := UTF8ToIFXStr(TempStr)
    else
      raise Exception.Create('TIFXParser.Binary_0000_ReadString: Error reading string.');
  end
else raise Exception.Create('TIFXParser.Binary_0000_ReadString: Error reading string length.');
end;

//------------------------------------------------------------------------------

procedure TIFXParser.Binary_0000_ReadData;
var
  i:            Integer;
  SectionNode:  TIFXSectionNode;
begin
fFileNode.Comment := Binary_0000_ReadString;
If (fStream.Size - fStream.Position) >= SizeOf(UInt32) then
  begin
    For i := 0 to Pred(Integer(Stream_ReadUInt32(fStream))) do
      If Binary_0000_ReadSection(SectionNode) then
        fFileNode.AddSectionNode(SectionNode);
  end
else raise Exception.Create('TIFXParser.Binary_0000_ReadData: Not enough data for section count.');
end;

//------------------------------------------------------------------------------

Function TIFXParser.Binary_0000_ReadSection(out SectionNode: TIFXSectionNode): Boolean;
var
  SectName: TIFXString;
  i,Cntr:   Integer;
  KeyNode:  TIFXKeyNode;
begin
Result := True;
SectionNode := TIFXSectionNode.Create(fFileNode.SettingsPtr);
try
  If (fStream.Size - fStream.Position) >= (SizeOf(UInt32) * 4) then
    begin
      If Stream_ReadUInt32(fStream) = IFX_BINI_SIGNATURE_SECTION then
        begin
          SectName := Binary_0000_ReadString;
          i := fFileNode.IndexOfSection(SectName);
          If i >= 0 then
            // section with the same name is already present, decide what to
            // do next according to duplicity behavior
            case fSettingsPtr^.DuplicityBehavior of
              idbReplace:
                begin
                  // discard created node, use the one present, replace comment
                  SectionNode.Free;
                  SectionNode := fFileNode[i];
                  SectionNode.Comment := Binary_0000_ReadString;
                  Result := False;
                end;
              idbRenameOld:
                begin
                  // use the new node, rename the old one
                  SectionNode.NameStr := SectName;
                  SectionNode.Comment := Binary_0000_ReadString;
                  If fFileNode.IndexOfSection(SectName + fSettingsPtr^.DuplicityRenameOldStr) >= 0 then
                    begin
                      Cntr := 0;
                      while fFileNode.IndexOfSection(SectName + fSettingsPtr^.DuplicityRenameOldStr +
                        StrToIFXStr(IntToStr(Cntr))) >= 0 do Inc(Cntr);
                      fFileNode[i].NameStr := SectName + fSettingsPtr^.DuplicityRenameOldStr +
                        StrToIFXStr(IntToStr(Cntr));
                    end
                  else fFileNode[i].NameStr := SectName + fSettingsPtr^.DuplicityRenameOldStr;
                end;
              idbRenameNew:
                begin
                  // rename the new node, don't touch the old one
                  If fFileNode.IndexOfSection(SectName + fSettingsPtr^.DuplicityRenameNewStr) >= 0 then
                    begin
                      Cntr := 0;
                      while fFileNode.IndexOfSection(SectName + fSettingsPtr^.DuplicityRenameNewStr +
                        StrToIFXStr(IntToStr(Cntr))) >= 0 do Inc(Cntr);
                      SectionNode.NameStr := SectName + fSettingsPtr^.DuplicityRenameNewStr +
                        StrToIFXStr(IntToStr(Cntr));
                    end
                  else SectionNode.NameStr := SectName + fSettingsPtr^.DuplicityRenameNewStr;
                  SectionNode.Comment := Binary_0000_ReadString;
                end;
            else
              {idbDrop}
              // discard created node, use the one already present, discard comment
              SectionNode.Free;
              SectionNode := fFileNode[i];
              Binary_0000_ReadString;
              Result := False;
            end
          else
            begin
              // section is not yet in the file
              SectionNode.NameStr := SectName;
              SectionNode.Comment := Binary_0000_ReadString;
            end;
          If (fStream.Size - fStream.Position) >= SizeOf(UInt32) then
            begin
              For i := 0 to Pred(Integer(Stream_ReadUInt32(fStream))) do
                If Binary_0000_ReadKey(SectionNode,KeyNode) then
                  SectionNode.AddKeyNode(KeyNode);
            end
          else raise Exception.Create('TIFXParser.Binary_0000_ReadSection: Not enough data for key count.');
        end
      else raise Exception.Create('TIFXParser.Binary_0000_ReadSection: Wrong section signature.');
    end
  else raise Exception.Create('TIFXParser.Binary_0000_ReadSection: Not enough data for section.');
except
  FreeAndNil(SectionNode);
  raise;
end;
end;

//------------------------------------------------------------------------------

Function TIFXParser.Binary_0000_ReadKey(SectionNode: TIFXSectionNode; out KeyNode: TIFXKeyNode): Boolean;
var
  KeyName:    TIFXString;
  BinSize:    UInt64;
  Index:      Integer;
  Cntr:       Integer;
  FreeNode:   Boolean;
  ValueType:  TIFXValueType;
  TempValue:  TIFXValueData;

  procedure ValReadCheckAndRaise(Val,Exp: TMemSize);
  begin
    If Val <> Exp then
      raise Exception.Create('TIFXParser.Binary_0000_ReadKey: Not enough data for key value.');
  end;

begin
FreeNode := False;
Result := True;
KeyNode := TIFXKeyNode.Create(fFileNode.SettingsPtr);
try
  If (fStream.Size - fStream.Position) >= ((SizeOf(UInt32) * 3) + 2{value enc. and type}) then
    begin
      If Stream_ReadUInt32(fStream) = IFX_BINI_SIGNATURE_KEY then
        begin
          KeyName := Binary_0000_ReadString;
          Index := SectionNode.IndexOfKey(KeyName);
          If Index >= 0 then
            // key with the same name is already present, decide what to do next
            // according to duplicity behavior
            case fSettingsPtr^.DuplicityBehavior of
              idbReplace:
                begin
                  // discard created node, use the one present, replace content
                  KeyNode.Free;
                  KeyNode := SectionNode[Index];
                  KeyNode.NameStr := KeyName;
                  Result := False;
                end;
              idbRenameOld:
                begin
                  // use the new node, rename the old one
                  KeyNode.NameStr := KeyName;
                  If SectionNode.IndexOfKey(KeyName + fSettingsPtr^.DuplicityRenameOldStr) >= 0 then
                    begin
                      Cntr := 0;
                      while SectionNode.IndexOfKey(KeyName + fSettingsPtr^.DuplicityRenameOldStr +
                        StrToIFXStr(IntToStr(Cntr))) >= 0 do Inc(Cntr);
                      SectionNode[Index].NameStr := KeyName + fSettingsPtr^.DuplicityRenameOldStr +
                        StrToIFXStr(IntToStr(Cntr));
                    end
                  else SectionNode[Index].NameStr := KeyName + fSettingsPtr^.DuplicityRenameOldStr;
                end;
              idbRenameNew:
                begin
                  // rename the new node, don't touch the old one
                  If SectionNode.IndexOfKey(KeyName + fSettingsPtr^.DuplicityRenameNewStr) >= 0 then
                    begin
                      Cntr := 0;
                      while SectionNode.IndexOfKey(KeyName + fSettingsPtr^.DuplicityRenameNewStr +
                        StrToIFXStr(IntToStr(Cntr))) >= 0 do Inc(Cntr);
                      KeyNode.NameStr := KeyName + fSettingsPtr^.DuplicityRenameNewStr +
                        StrToIFXStr(IntToStr(Cntr));
                    end
                  else KeyNode.NameStr := KeyName + fSettingsPtr^.DuplicityRenameNewStr;
                end;
            else
              {idbDrop}
              // discard created node (will be freed at the end of this funtion
              // since the actual reading must be performed)
              Result := False;
              FreeNode := True;
            end
          else
            begin
              // key is not yet in the section
              KeyNode.NameStr := KeyName;
            end;
          KeyNode.Comment := Binary_0000_ReadString;
          KeyNode.ValueEncoding := IFXByteToValueEncoding(Stream_ReadUInt8(fStream));
          ValueType := IFXByteToValueType(Stream_ReadUInt8(fStream));
          // read value data to temporary storage
          case ValueType of
            ivtBool:      ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.BoolValue,SizeOf(Boolean)),SizeOf(Boolean));
            ivtInt8:      ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.Int8Value,SizeOf(Int8)),SizeOf(Int8));
            ivtUInt8:     ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.UInt8Value,SizeOf(UInt8)),SizeOf(UInt8));
            ivtInt16:     ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.Int16Value,SizeOf(Int16)),SizeOf(Int16));
            ivtUInt16:    ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.UInt16Value,SizeOf(UInt16)),SizeOf(UInt16));
            ivtInt32:     ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.Int32Value,SizeOf(Int32)),SizeOf(Int32));
            ivtUInt32:    ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.UInt32Value,SizeOf(UInt32)),SizeOf(UInt32));
            ivtInt64:     ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.Int64Value,SizeOf(Int64)),SizeOf(Int64));
            ivtUInt64:    ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.UInt64Value,SizeOf(UInt64)),SizeOf(UInt64));
            ivtFloat32:   ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.Float32Value,SizeOf(Float32)),SizeOf(Float32));
            ivtFloat64:   ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.Float64Value,SizeOf(Float64)),SizeOf(Float64));
            ivtDate:      ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.DateValue,SizeOf(TDateTime)),SizeOf(TDateTime));
            ivtTime:      ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.TimeValue,SizeOf(TDateTime)),SizeOf(TDateTime));
            ivtDateTime:  ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.DateTimeValue,SizeOf(TDateTime)),SizeOf(TDateTime));
            ivtBinary:    begin
                            ValReadCheckAndRaise(Stream_ReadUInt64(fStream,BinSize),SizeOf(UInt64));
                            If BinSize > UInt64(High(TMemSize)) then
                              raise Exception.Create('TIFXParser.Binary_0000_ReadKey: Too much raw data.');
                            TempValue.BinaryValueSize := TMemSize(BinSize);
                            GetMem(TempValue.BinaryValuePtr,TempValue.BinaryValueSize);
                            try
                              ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.BinaryValuePtr^,TempValue.BinaryValueSize),
                                                   TempValue.BinaryValueSize);
                              TempValue.BinaryValueOwned := True;
                            except
                              FreeMem(TempValue.BinaryValuePtr,TempValue.BinaryValueSize);
                              TempValue.BinaryValuePtr := nil;
                              raise;
                            end;
                          end;
            ivtString:    TempValue.StringValue := Binary_0000_ReadString;
          else
            {ivtUndecided}
            KeyNode.ValueStr := Binary_0000_ReadString;
          end;
          // assign values to key
          case ValueType of
            ivtBool:      KeyNode.SetValueBool(TempValue.BoolValue);
            ivtInt8:      KeyNode.SetValueInt8(TempValue.UInt8Value);
            ivtUInt8:     KeyNode.SetValueUInt8(TempValue.UInt8Value);
            ivtInt16:     KeyNode.SetValueInt16(TempValue.Int16Value);
            ivtUInt16:    KeyNode.SetValueUInt16(TempValue.UInt16Value);
            ivtInt32:     KeyNode.SetValueInt32(TempValue.Int32Value);
            ivtUInt32:    KeyNode.SetValueUInt32(TempValue.UInt32Value);
            ivtInt64:     KeyNode.SetValueInt64(TempValue.Int64Value);
            ivtUInt64:    KeyNode.SetValueUInt64(TempValue.UInt64Value);
            ivtFloat32:   KeyNode.SetValueFloat32(TempValue.Float32Value);
            ivtFloat64:   KeyNode.SetValueFloat64(TempValue.Float64Value);
            ivtDate:      KeyNode.SetValueDate(TempValue.DateValue);
            ivtTime:      KeyNode.SetValueTime(TempValue.TimeValue);
            ivtDateTime:  KeyNode.SetValueDateTime(TempValue.DateTimeValue);
            ivtBinary:    begin
                            KeyNode.SetValueBinary(TempValue.BinaryValuePtr,TempValue.BinaryValueSize,False);
                            KeyNode.ValueDataPtr^.BinaryValueOwned := True;
                          end;
            ivtString:    KeyNode.SetValueString(TempValue.StringValue);
          else
            {ivtUndecided}
            // do nothing, already assigned to key
          end;
        end
      else raise Exception.Create('TIFXParser.Binary_0000_ReadKey: Wrong key signature.');
    end
  else raise Exception.Create('TIFXParser.Binary_0000_ReadKey: Not enough data for key.');
except
  FreeAndNil(KeyNode);
  raise;
end;
If FreeNode then FreeAndNil(KeyNode); 
end;

{-------------------------------------------------------------------------------
    TIFXParser - public methods
-------------------------------------------------------------------------------}

constructor TIFXParser.Create(SettingsPtr: PIFXSettings; FileNode: TIFXFileNode);
begin
inherited Create;
fSettingsPtr := SettingsPtr;
fFileNode := FileNode;
end;

//------------------------------------------------------------------------------

Function TIFXParser.ConstructCommentBlock(const CommentStr: TIFXString): TIFXString;
var
  i,j:  TStrSize;
  Temp: TStrSize;
begin
If Length(CommentStr) > 0 then
  begin
    // first pass - count how many characters the result should have
    Temp := 1{first comment mark};
    i := 1;
    while i <= Length(CommentStr) do
      begin
        If Ord(CommentStr[i]) in [10,13] then
          begin
            Inc(Temp,1{comment mark} + Length(fSettingsPtr^.IniFormat.LineBreak));
            If i < Length(CommentStr) then
              If (Ord(CommentStr[i + 1]) in [10,13]) and
                (CommentStr[i] <> CommentStr[i + 1]) then
                Inc(i);
          end
        else Inc(Temp);
        Inc(i);
      end;
    // second pass - build result, replace current linebreaks with the one
    // specified in settings
    SetLength(Result,Temp);
    i := 1;
    Temp := 2;  // will be used to index result string
    Result[1] := fSettingsPtr.IniFormat.CommentChar;
    while i <= Length(CommentStr) do
      begin
        If Ord(CommentStr[i]) in [10,13] then
          begin
            If i < Length(CommentStr) then
              If (Ord(CommentStr[i + 1]) in [10,13]) and
                (CommentStr[i] <> CommentStr[i + 1]) then
                Inc(i);
            For j := 0 to Pred(Length(fSettingsPtr^.IniFormat.LineBreak)) do
              Result[Temp + j] := fSettingsPtr^.IniFormat.LineBreak[j + 1];
            Inc(Temp,Length(fSettingsPtr^.IniFormat.LineBreak));
            Result[Temp] := fSettingsPtr.IniFormat.CommentChar;
          end
        else Result[Temp] := CommentStr[i];
        Inc(i);
        Inc(Temp);
      end;
  end;
end;

//------------------------------------------------------------------------------

Function TIFXParser.ConstructSectionName(SectionNode: TIFXSectionNode): TIFXString;
begin
SetLength(Result,Length(SectionNode.NameStr) + 2{section name start and end char});
Result[1] := fSettingsPtr.IniFormat.SectionStartChar;
Result[Length(Result)] := fSettingsPtr.IniFormat.SectionEndChar;
Move(PIFXChar(SectionNode.NameStr)^,Result[2],Length(SectionNode.NameStr) * SizeOf(TIFXChar));
end;

//------------------------------------------------------------------------------

Function TIFXParser.ConstructKeyValueLine(KeyNode: TIFXKeyNode): TIFXString;
var
  Temp: TStrSize;
begin
// get length of the resulting string
Temp := Length(KeyNode.NameStr) + Length(KeyNode.ValueStr) + 1{ValueDelimChar};
If fSettingsPtr^.IniFormat.KeyWhiteSpace then
  Inc(Temp{WhiteSpaceChar});
If fSettingsPtr^.IniFormat.ValueWhiteSpace then
  Inc(Temp{WhiteSpaceChar});
SetLength(Result,Temp);
// build resulting string
Temp := 1;
Move(KeyNode.NameStr[1],Result[Temp],Length(KeyNode.NameStr) * SizeOf(TIFXChar));
Inc(Temp,Length(KeyNode.NameStr));
If fSettingsPtr^.IniFormat.KeyWhiteSpace then
  begin
    Result[Temp] := fSettingsPtr^.IniFormat.WhiteSpaceChar;
    Inc(Temp{WhiteSpaceChar});
  end;
Result[Temp] := fSettingsPtr^.IniFormat.ValueDelimChar;
Inc(Temp{ValueDelimChar});
If fSettingsPtr^.IniFormat.KeyWhiteSpace then
  begin
    Result[Temp] := fSettingsPtr^.IniFormat.WhiteSpaceChar;
    Inc(Temp{WhiteSpaceChar});
  end;
Move(KeyNode.ValueStr[1],Result[Temp],Length(KeyNode.ValueStr) * SizeOf(TIFXChar));
end;

//------------------------------------------------------------------------------

procedure TIFXParser.WriteTextual(Stream: TStream);
var
  SectionNode:  TIFXSectionNode;
  i:            Integer;
begin
fStream := Stream;
// write BOM if requested
If fSettingsPtr.WriteByteOrderMask then
  Stream_WriteBuffer(fStream,IFX_UTF8BOM,SizeOf(IFX_UTF8BOM));
fEmptyLinePos := fStream.Position;
// write file comment
Text_WriteString(ConstructCommentBlock(fFileNode.Comment));
If fFileNode.Count > 0 then
  begin
    // write section-less values if any present
    If fFileNode.FindSection('',SectionNode) then
      begin
        Text_WriteEmptyLine;
        Text_WriteString(ConstructCommentBlock(SectionNode.Comment));
        If SectionNode.Count > 0 then
          Text_WriteEmptyLine;
        // write values
        For i := SectionNode.LowIndex to SectionNode.HighIndex do
          Text_WriteKey(SectionNode[i]);
      end;
    // write other sections
    For i := fFileNode.LowIndex to fFileNode.HighIndex do
      If IFXCompareText('',fFileNode[i].NameStr) <> 0 then
        Text_WriteSection(fFileNode[i]);
  end;
end;

//------------------------------------------------------------------------------

procedure TIFXParser.ReadTextual(Stream: TStream);
var
  i:  Integer;
begin
// clear file node
fFileNode.ClearSections;
fFileNode.Comment := '';
// prepare stringlist for parsing of lines
fIniStrings := TUTF8StringList.Create;
try
  fLastComment := '';
  fFileCommentSet := False;
  fIniStrings.LoadFromStream(Stream);
  If fIniStrings.Count > 0 then
    begin
      // remove any leading whitespaces
      For i := fIniStrings.LowIndex to fIniStrings.HighIndex do
        fIniStrings[i] := IFXTrimStr(fIniStrings[i]);
      // traverse and parse lines  
      fIniStrings.UserData := 0;
      fLastTextLineType := tltEmpty;
      fCurrentSectionNode := nil;
      while fIniStrings.UserData < fIniStrings.Count do
        begin
          Text_ReadLine;
          fIniStrings.UserData := fIniStrings.UserData + 1;
        end;
    end;
finally
  FreeAndNil(fIniStrings);
end;
fCurrentSectionNode := nil;
end;

//------------------------------------------------------------------------------

procedure TIFXParser.WriteBinary(Stream: TStream);
var
  i:  Integer;
begin
// prepare file header, size will be filled later
fBinFileHeader.Signature := IFX_BINI_SIGNATURE_FILE;
fBinFileHeader.Structure := IFX_BINI_STRUCT_0;  // later implement selectable
fBinFileHeader.Flags := 0;
// prepare stream for data
fStream := TMemoryStream.Create;
try
  case fBinFileHeader.Structure of
    IFX_BINI_STRUCT_0:
      begin
        // write data to temp stream
        Binary_0000_WriteString(fFileNode.Comment);
        Stream_WriteUInt32(fStream,UInt32(fFileNode.SectionCount));
        For i := fFileNode.LowIndex to fFileNode.HighIndex do
          Binary_0000_WriteSection(fFileNode[i]);
        fBinFileHeader.DataSize := UInt64(fStream.Size);
        // save header and complete data to output stream
        Stream_WriteBuffer(Stream,fBinFileHeader,SizeOf(TIFXBiniFileHeader));
      {
        data compression and encryption goes here <<<
      }
        Stream_WriteBuffer(Stream,TMemoryStream(fStream).Memory^,fStream.Size);
      end;
  else
    raise Exception.CreateFmt('TIFXParser.WriteBinary: Unknown binary format (%d).',[fBinFileHeader.Structure]);
  end;
finally
  FreeAndNil(fStream);
end
end;

//------------------------------------------------------------------------------

procedure TIFXParser.ReadBinary(Stream: TStream);
begin
// clear file node
fFileNode.ClearSections;
fFileNode.Comment := '';
If (Stream.Size - Stream.Position) >= SizeOf(TIFXBiniFileHeader) then
  begin
    Stream_ReadBuffer(Stream,fBinFileHeader,SizeOf(TIFXBiniFileHeader));
    // check signature
    If fBinFileHeader.Signature = IFX_BINI_SIGNATURE_FILE then
      begin
        If (Stream.Size - Stream.Position) >= fBinFileHeader.DataSize then
          begin
            fStream := TMemoryStream.Create;
            try
              fStream.CopyFrom(Stream,fBinFileHeader.DataSize);
              fStream.Seek(0,soBeginning);
            {
              data decompression and decryption goes here <<<
            }
              case fBinFileHeader.Structure of
                IFX_BINI_STRUCT_0:  Binary_0000_ReadData;
              else
                raise Exception.CreateFmt('TIFXParser.ReadBinary: Unknown binary format (%d).',[fBinFileHeader.Structure]);
              end;
            finally
              fStream.Free;
            end;
          end
        else raise Exception.Create('TIFXParser.ReadBinary: Stream is too small for declared data.');
      end
    else raise Exception.CreateFmt('TIFXParser.ReadBinary: Wrong file signature (0x%.8x).',[fBinFileHeader.Signature]);
  end
else raise Exception.CreateFmt('TIFXParser.ReadBinary: Not enough data (%d) for file header.',[Stream.Size - Stream.Position]);
end;

end.
