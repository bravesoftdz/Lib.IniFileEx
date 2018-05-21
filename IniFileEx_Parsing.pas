unit IniFileEx_Parsing;

{$INCLUDE '.\IniFileEx_defs.inc'}

interface

uses
  Classes,
  AuxTypes,
  IniFileEx_Common, IniFileEx_Nodes;

type
  TIFXBiniFileHeader = packed record
    Signature:  UInt32;
    Structure:  UInt16;
    Flags:      UInt16;
    DataSize:   UInt64;
  end;

type
  TIFXParser = class(TObject)
  private
    fSettingsPtr:   PIFXSettings;
    fFileNode:      TIFXFileNode;
    fStream:        TStream;
    // processing fields
    fEmptyLinePos:  Int64;
    fIniString:     UTF8String;
    fIniStringPos:  TStrSize;
    fBinFileHeader: TIFXBiniFileHeader;
  protected
    // writing textual ini
    Function Text_WriteEmptyLine: TMemSize; virtual;
    Function Text_WriteString(const Str: TIFXString): TMemSize; virtual;
    Function Text_WriteSection(SectionNode: TIFXSectionNode): TMemSize; virtual;
    Function Text_WriteKey(KeyNode: TIFXKeyNode): TMemSize; virtual;
    // reading textual ini
    // Text_ReadInitial
    // writing binary ini of structure 0x0000
    Function Binary_0000_WriteString(const Str: TIFXString): TMemSize; virtual;
    Function Binary_0000_WriteSection(SectionNode: TIFXSectionNode): TMemSize; virtual;
    Function Binary_0000_WriteKey(KeyNode: TIFXKeyNode): TMemSize; virtual;
    // reading binary ini of structure 0x0000
    Function Binary_0000_ReadString: TIFXString; virtual; abstract;
    Function Binary_0000_ReadSection: TIFXSectionNode; virtual; abstract;
    Function Binary_0000_ReadKey: TIFXKeyNode; virtual; abstract;
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
    //procedure ReadBinary(Stream: TStream); virtual;
  end;

implementation

uses
  SysUtils,
  BinaryStreaming;

const
  IFX_UTF8BOM: packed array[0..2] of Byte = ($EF,$BB,$BF);

  IFX_BINI_SIGNATURE_FILE    = UInt32($494E4942); // BINI
  IFX_BINI_SIGNATURE_SECTION = UInt32($54434553); // SECT
  IFX_BINI_SIGNATURE_KEY     = UInt32($5659454B); // KEYV

  IFX_BINI_MINFILESIZE = 12;

  IFX_BINI_STRUCT_0 = UInt16(0);
  
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

//------------------------------------------------------------------------------

Function TIFXParser.Text_WriteEmptyLine: TMemSize;
var
  TempStr:  UTF8String;
begin
If fStream.Position <> fEmptyLinePos then
  begin
    TempStr := IFXStrToUTF8(fSettingsPtr.IniFormat.LineBreak);
    Result := TMemSize(fStream.Write(PUTF8Char(TempStr)^,Length(TempStr) * SizeOf(UTF8Char)));
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
      Result := TMemSize(fStream.Write(PUTF8Char(TempStr)^,Length(TempStr) * SizeOf(UTF8Char)))
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

Function TIFXParser.Binary_0000_WriteString(const Str: TIFXString): TMemSize;
var
  TempStr:  UTF8String;
begin
If Length(Str) > 0 then
  begin
    TempStr := IFXStrToUTF8(Str);
    Result := Stream_WriteUInt32(fStream,Length(TempStr));
    Inc(Result,fStream.Write(PUTF8Char(TempStr)^,Length(TempStr) * SizeOf(UTF8Char)));
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
Inc(Result,Stream_WriteUInt8(fStream,UInt8(Ord(KeyNode.ValueEncoding))));
Inc(Result,Stream_WriteUInt8(fStream,UInt8(Ord(KeyNode.ValueType))));
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
  ivtBinary:    Inc(Result,Stream_WriteBuffer(fStream,KeyNode.ValueData.BinaryValuePtr^,KeyNode.ValueData.BinaryValueSize));
else
  {ivtString}
  Inc(Result,Binary_0000_WriteString(KeyNode.ValueData.StringValue));
end;
end;

//==============================================================================

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
  fStream.WriteBuffer(IFX_UTF8BOM,SizeOf(IFX_UTF8BOM));
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
  BOM_Buffer: array[0..2] of Byte;
begin
fStream := Stream;
// clear file node
fFileNode.ClearSections;
fFileNode.Comment := '';
If (fStream.Size - fStream.Position) >= IFX_BINI_MINFILESIZE then
  begin
    // read first 3 bytes and if they contain BOM, ignore them
    fStream.ReadBuffer(BOM_Buffer,SizeOf(BOM_Buffer));
    If (BOM_Buffer[0] <> IFX_UTF8BOM[0]) or (BOM_Buffer[1] <> IFX_UTF8BOM[1]) or
      (BOM_Buffer[2] <> IFX_UTF8BOM[2]) then
      fStream.Seek(-3,soCurrent);
    SetLength(fIniString,fStream.Size - fStream.Position);
    If Length(fIniString) > 0 then
      begin
        fIniStringPos := 1;


      end;
  end;
end;

//------------------------------------------------------------------------------

procedure TIFXParser.WriteBinary(Stream: TStream);
var
  i:  Integer;
begin
// preapre file header, size will be filled later
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
        Stream.WriteBuffer(fBinFileHeader,SizeOf(TIFXBiniFileHeader));
        Stream.WriteBuffer(TMemoryStream(fStream).Memory^,fStream.Size);
      end;
  else
    raise Exception.CreateFmt('TIFXParser.WriteBinary: Unknown binary format (%d).',[fBinFileHeader.Structure]);
  end;
finally
  FreeAndNil(fStream);
end
end;

end.
