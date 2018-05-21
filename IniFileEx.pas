unit IniFileEx;

{$INCLUDE '.\IniFileEx_defs.inc'}

interface

uses
  Classes, 
  AuxTypes, AuxClasses,
  IniFileEx_Common, IniFileEx_Nodes, IniFileEx_Parsing;

type
  TIniFileEx = class(TCustomObject)
  private
    fSettings:          TIFXSettings;
    fFileNode:          TIFXFileNode;
    fParser:            TIFXParser;
    fOnSectionCreate:   TIFXSectionNodeEvent;
    fOnSectionDestroy:  TIFXSectionNodeEvent;
    fOnKeyCreate:       TIFXKeyNodeEvent;
    fOnKeyDestroy:      TIFXKeyNodeEvent;
    Function GetSettingsPtr: PIFXSettings;
    Function GetSectionCount: Integer;
    Function GetSectionKeyCount(Index: Integer): Integer;
    Function GetKeyCount: Integer;
  {$IFDEF AllowLowLevelAccess}
    Function GetSectionNodeIdx(SectionIndex: Integer): TIFXSectionNode;
    Function GetKeyNodeIdx(SectionIndex, KeyIndex: Integer): TIFXKeyNode;
  {$ENDIF}
  protected
    procedure Initialize; virtual;
    procedure Finalize; virtual;
    procedure SectionCreateHandler(Sender: TObject; Section: TIFXSectionNode); virtual;
    procedure SectionDestroyHandler(Sender: TObject; Section: TIFXSectionNode); virtual;
    procedure KeyCreateHandler(Sender: TObject; Section: TIFXSectionNode; Key: TIFXKeyNode); virtual;
    procedure KeyDestroyHandler(Sender: TObject; Section: TIFXSectionNode; Key: TIFXKeyNode); virtual;
    Function WritingValue(const Section, Key: TIFXString): TIFXKeyNode; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    // file/stream manipulation
    procedure SaveToTextualStream(Stream: TStream); virtual;
    procedure SaveToBinaryStream(Stream: TStream); virtual;
    procedure SaveToStream(Stream: TStream); virtual;    
    procedure SaveToTextualFile(const FileName: String); virtual;
    procedure SaveToBinaryFile(const FileName: String); virtual;
    procedure SaveToFile(const FileName: String); virtual;
    // structure access
    Function IndexOfSection(const Section: TIFXString): Integer; virtual;
    Function IndexOfKey(const Section, Key: TIFXString): TIFXNodeIndices; overload; virtual;
    Function IndexOfKey(SectionIndex: Integer; const Key: TIFXString): Integer; overload; virtual;
    Function SectionExists(const Section: TIFXString): Boolean; virtual;
    Function KeyExists(const Section, Key: TIFXString): Boolean; overload; virtual;
    Function KeyExists(SectionIndex: Integer; const Key: TIFXString): Boolean; overload; virtual;
    procedure AddSection(const Section: TIFXString); virtual;
    procedure AddKey(const Section, Key: TIFXString); overload; virtual;
    procedure AddKey(SectionIndex: Integer; const Key: TIFXString); overload; virtual;
    procedure DeleteSection(const Section: TIFXString); virtual;
    procedure DeleteKey(const Section, Key: TIFXString); overload; virtual;
    procedure DeleteKey(SectionIndex: Integer; const Key: TIFXString); overload; virtual;
    procedure ExchangeSections(const Section1, Section2: TIFXString); virtual;
    procedure ExchangeKeys(const Section, Key1, Key2: TIFXString); overload; virtual;
    procedure ExchangeKeys(SectionIndex: Integer; const Key1, Key2: TIFXString); overload; virtual;
    Function CopySection(const SourceSection, DestinationSection: TIFXString): Boolean; virtual;
    Function CopyKey(const SourceSection, DestinationSection, SourceKey, DestinationKey: TIFXString): Boolean; virtual;
    procedure Clear; virtual;
    procedure SortSections; virtual;
    procedure SortSection(const Section: TIFXString); virtual;
    procedure SortKeys(const Section: TIFXString); overload; virtual;
    procedure SortKeys; overload; virtual;
    procedure Sort; virtual;
    // comments
    Function GetFileComment: TIFXString; virtual;
    Function GetSectionComment(const Section: TIFXString): TIFXString; virtual;
    Function GetKeyComment(const Section, Key: TIFXString): TIFXString; virtual;
    procedure SetFileComment(const Text: TIFXString); virtual;
    procedure SetSectionComment(const Section: TIFXString; const Text: TIFXString); virtual;
    procedure SetKeyComment(const Section, Key: TIFXString; const Text: TIFXString); virtual;
    procedure RemoveFileComment; virtual;
    procedure RemoveSectionComment(const Section: TIFXString; RemoveKeysComments: Boolean = False); virtual;
    procedure RemoveKeyComment(const Section, Key: TIFXString); virtual;
    procedure RemoveAllComment; virtual;
    // mid-level properties access
    Function GetValueState(const Section, Key: TIFXString): TIFXValueState; virtual;
    Function GetValueEncoding(const Section, Key: TIFXString): TIFXValueEncoding; virtual;
    procedure SetValueEncoding(const Section, Key: TIFXString; Encoding: TIFXValueEncoding); virtual;
    Function GetValueType(const Section, Key: TIFXString): TIFXValueType; virtual;
    procedure ReadSections(Strings: TStrings); virtual;
    procedure ReadSection(const Section: TIFXString; Strings: TStrings); virtual;    
    procedure ReadSectionValues(const Section: TIFXString; Strings: TStrings); virtual;
    // values writing
    procedure WriteBool(const Section, Key: TIFXString; Value: Boolean); overload; virtual;
    procedure WriteBool(const Section, Key: TIFXString; Value: Boolean; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteInt8(const Section, Key: TIFXString; Value: Int8); overload; virtual;
    procedure WriteInt8(const Section, Key: TIFXString; Value: Int8; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteUInt8(const Section, Key: TIFXString; Value: UInt8); overload; virtual;
    procedure WriteUInt8(const Section, Key: TIFXString; Value: UInt8; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteInt16(const Section, Key: TIFXString; Value: Int16); overload; virtual;
    procedure WriteInt16(const Section, Key: TIFXString; Value: Int16; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteUInt16(const Section, Key: TIFXString; Value: UInt16); overload; virtual;
    procedure WriteUInt16(const Section, Key: TIFXString; Value: UInt16; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteInt32(const Section, Key: TIFXString; Value: Int32); overload; virtual;
    procedure WriteInt32(const Section, Key: TIFXString; Value: Int32; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteUInt32(const Section, Key: TIFXString; Value: UInt32); overload; virtual;
    procedure WriteUInt32(const Section, Key: TIFXString; Value: UInt32; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteInt64(const Section, Key: TIFXString; Value: Int64); overload; virtual;
    procedure WriteInt64(const Section, Key: TIFXString; Value: Int64; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteUInt64(const Section, Key: TIFXString; Value: UInt64); overload; virtual;
    procedure WriteUInt64(const Section, Key: TIFXString; Value: UInt64; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteInteger(const Section, Key: TIFXString; Value: Integer); overload; virtual;
    procedure WriteInteger(const Section, Key: TIFXString; Value: Integer; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteFloat32(const Section, Key: TIFXString; Value: Float32); overload; virtual;
    procedure WriteFloat32(const Section, Key: TIFXString; Value: Float32; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteFloat64(const Section, Key: TIFXString; Value: Float64); overload; virtual;
    procedure WriteFloat64(const Section, Key: TIFXString; Value: Float64; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteFloat(const Section, Key: TIFXString; Value: Double); overload; virtual;
    procedure WriteFloat(const Section, Key: TIFXString; Value: Double; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteTime(const Section, Key: TIFXString; Value: TDateTime); overload; virtual;
    procedure WriteTime(const Section, Key: TIFXString; Value: TDateTime; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteDate(const Section, Key: TIFXString; Value: TDateTime); overload; virtual;
    procedure WriteDate(const Section, Key: TIFXString; Value: TDateTime; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteDateTime(const Section, Key: TIFXString; Value: TDateTime); overload; virtual;
    procedure WriteDateTime(const Section, Key: TIFXString; Value: TDateTime; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteString(const Section, Key: TIFXString; const Value: String); overload; virtual;
    procedure WriteString(const Section, Key: TIFXString; const Value: String; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteBinaryBuffer(const Section, Key: TIFXString; const Buffer; Size: TMemSize; MakeCopy: Boolean = False); overload; virtual;
    procedure WriteBinaryBuffer(const Section, Key: TIFXString; const Buffer; Size: TMemSize; Encoding: TIFXValueEncoding; MakeCopy: Boolean = False); overload; virtual;
    procedure WriteBinaryMemory(const Section, Key: TIFXString; Value: Pointer; Size: TMemSize; MakeCopy: Boolean = False); overload; virtual;
    procedure WriteBinaryMemory(const Section, Key: TIFXString; Value: Pointer; Size: TMemSize; Encoding: TIFXValueEncoding; MakeCopy: Boolean = False); overload; virtual;
    procedure WriteBinaryStream(const Section, Key: TIFXString; Stream: TStream; Position, Count: Int64); overload; virtual;
    procedure WriteBinaryStream(const Section, Key: TIFXString; Stream: TStream; Position, Count: Int64; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteBinaryStream(const Section, Key: TIFXString; Stream: TStream); overload; virtual;
    procedure WriteBinaryStream(const Section, Key: TIFXString; Stream: TStream; Encoding: TIFXValueEncoding); overload; virtual;
    // values reading
    procedure PrepareReading(const Section, Key: TIFXString; ValueType: TIFXValueType); virtual;
    Function ReadBool(const Section, Key: TIFXString; Default: Boolean = False): Boolean; virtual;
    Function ReadInt8(const Section, Key: TIFXString; Default: Int8 = 0): Int8; virtual;
    Function ReadUInt8(const Section, Key: TIFXString; Default: UInt8 = 0): UInt8; virtual;
    Function ReadInt16(const Section, Key: TIFXString; Default: Int16 = 0): Int16; virtual;
    Function ReadUInt16(const Section, Key: TIFXString; Default: UInt16 = 0): UInt16; virtual;
    Function ReadInt32(const Section, Key: TIFXString; Default: Int32 = 0): Int32; virtual;
    Function ReadUInt32(const Section, Key: TIFXString; Default: UInt32 = 0): UInt32; virtual;
    Function ReadInt64(const Section, Key: TIFXString; Default: Int64 = 0): Int64; virtual;
    Function ReadUInt64(const Section, Key: TIFXString; Default: UInt64 = 0): UInt64; virtual;
    Function ReadInteger(const Section, Key: TIFXString; Default: Integer = 0): Integer; virtual;
    Function ReadFloat32(const Section, Key: TIFXString; Default: Float32 = 0.0): Float32; virtual;
    Function ReadFloat64(const Section, Key: TIFXString; Default: Float64 = 0.0): Float64; virtual;
    Function ReadFloat(const Section, Key: TIFXString; Default: Double = 0.0): Double; virtual;
    Function ReadTime(const Section, Key: TIFXString; Default: TDateTime = 0.0): TDateTime; virtual;
    Function ReadDate(const Section, Key: TIFXString; Default: TDateTime = 0.0): TDateTime; virtual;
    Function ReadDateTime(const Section, Key: TIFXString; Default: TDateTime = 0.0): TDateTime; virtual;
    Function ReadString(const Section, Key: TIFXString; Default: String = ''): String; virtual;
    Function ReadBinarySize(const Section, Key: TIFXString): TMemSize; virtual;
    Function ReadBinaryBuffer(const Section, Key: TIFXString; var Buffer; Size: TMemSize): TMemSize; virtual;
    Function ReadBinaryMemory(const Section, Key: TIFXString; out Ptr: Pointer; MakeCopy: Boolean = False): TMemSize; overload; virtual;
    Function ReadBinaryMemory(const Section, Key: TIFXString; Ptr: Pointer; Size: TMemSize): TMemSize; overload; virtual;
    Function ReadBinaryStream(const Section, Key: TIFXString; Stream: TStream; ClearStream: Boolean = False): Int64; virtual;
  {$IFDEF AllowLowLevelAccess}
    // low level stuff
    Function GetSectionNode(const Section: TIFXString): TIFXSectionNode; virtual;
    Function GetKeyNode(const Section, Key: TIFXString): TIFXKeyNode; virtual;
    Function GetValueString(const Section, Key: TIFXString): TIFXString; virtual;
    procedure SetValueString(const Section, Key, ValueStr: TIFXString); virtual;
    property FileNode: TIFXFileNode read fFileNode;
    property Parser: TIFXParser read fParser; 
    property SectionNodes[SectionIndex: Integer]: TIFXSectionNode read GetSectionNodeIdx;
    property KeyNodes[SectionIndex, KeyIndex: Integer]: TIFXKeyNode read GetKeyNodeIdx;
    property OnSectionCreate: TIFXSectionNodeEvent read fOnSectionCreate write fOnSectionCreate;
    property OnSectionDestroy: TIFXSectionNodeEvent read fOnSectionDestroy write fOnSectionDestroy;
    property OnKeyCreate: TIFXKeyNodeEvent read fOnKeyCreate write fOnKeyCreate;
    property OnKeyDestroy: TIFXKeyNodeEvent read fOnKeyDestroy write fOnKeyDestroy;
  {$ENDIF}
    property Settings: TIFXSettings read fSettings write fSettings;
    property SettingsPtr: PIFXSettings read GetSettingsPtr;
    property SectionCount: Integer read GetSectionCount;
    property SectionKeyCount[Index: Integer]: Integer read GetSectionKeyCount;
    property KeyCount: Integer read GetKeyCount;
  end;

implementation

uses
  SysUtils,
  StrRect;

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W5024:={$WARN 5024 OFF}} // Parameter "$1" not used
{$ENDIF}

Function TIniFileEx.GetSettingsPtr: PIFXSettings;
begin
Result := Addr(fSettings);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetSectionCount: Integer;
begin
Result := fFileNode.SectionCount;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetSectionKeyCount(Index: Integer): Integer;
begin
If fFileNode.CheckIndex(Index) then
  Result := fFileNode[Index].KeyCount
else
  raise Exception.CreateFmt('TIniFileEx.GetSectionKeyCount: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetKeyCount: Integer;
var
  i:  Integer;
begin
Result := 0;
For i := fFileNode.LowIndex to fFileNode.HighIndex do
  Inc(Result,fFileNode[i].KeyCount);
end;

{$IFDEF AllowLowLevelAccess}
//------------------------------------------------------------------------------

Function TIniFileEx.GetSectionNodeIdx(SectionIndex: Integer): TIFXSectionNode;
begin
If fFileNode.CheckIndex(SectionIndex) then
  Result := fFileNode[SectionIndex]
else
  raise Exception.CreateFmt('TIniFileEx.GetSectionNodeIdx: Section index (%d) out of bounds.',[SectionIndex]);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetKeyNodeIdx(SectionIndex, KeyIndex: Integer): TIFXKeyNode;
begin
If fFileNode.CheckIndex(SectionIndex) then
  begin
    If fFileNode[SectionIndex].CheckIndex(KeyIndex) then
      Result := fFileNode[SectionIndex][KeyIndex]
    else
      raise Exception.CreateFmt('TIniFileEx.GetSectionNodeIdx: Key index (%d) out of bounds.',[KeyIndex]);
  end
else raise Exception.CreateFmt('TIniFileEx.GetSectionNodeIdx: Section index (%d) out of bounds.',[SectionIndex]);
end;

{$ENDIF}

//==============================================================================

procedure TIniFileEx.Initialize;
begin
IFXInitSettings(fSettings);
fFileNode := TIFXFileNode.Create(Addr(fSettings));
fFileNode.OnSectionCreate := SectionCreateHandler;
fFileNode.OnSectionDestroy := SectionDestroyHandler;
fFileNode.OnKeyCreate := KeyCreateHandler;
fFileNode.OnKeyDestroy := KeyDestroyHandler;
fParser := TIFXParser.Create(@fSettings,fFileNode);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.Finalize;
begin
fParser.Free;
fFileNode.Free;
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TIniFileEx.SectionCreateHandler(Sender: TObject; Section: TIFXSectionNode);
begin
If Assigned(fOnSectionCreate) then
  fOnSectionCreate(Self,Section);
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TIniFileEx.SectionDestroyHandler(Sender: TObject; Section: TIFXSectionNode);
begin
If Assigned(fOnSectionDestroy) then
  fOnSectionDestroy(Self,Section);
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TIniFileEx.KeyCreateHandler(Sender: TObject; Section: TIFXSectionNode; Key: TIFXKeyNode);
begin
If Assigned(fOnKeyCreate) then
  fOnKeyCreate(Self,Section,Key);
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TIniFileEx.KeyDestroyHandler(Sender: TObject; Section: TIFXSectionNode; Key: TIFXKeyNode);
begin
If Assigned(fOnKeyDestroy) then
  fOnKeyDestroy(Self,Section,Key);
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

Function TIniFileEx.WritingValue(const Section, Key: TIFXString): TIFXKeyNode;
var
  SectionIndex: Integer;
  KeyIndex:     Integer;
begin
SectionIndex := fFileNode.AddSection(Section);
KeyIndex := fFileNode[SectionIndex].AddKey(Key);
Result := fFileNode[SectionIndex][KeyIndex];
end;

//==============================================================================

constructor TIniFileEx.Create;
begin
inherited Create;
Initialize;
end;

//------------------------------------------------------------------------------

destructor TIniFileEx.Destroy;
begin
Finalize;
inherited;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SaveToTextualStream(Stream: TStream);
begin
fParser.WriteTextual(Stream);
end;

procedure TIniFileEx.SaveToBinaryStream(Stream: TStream);
begin
fParser.WriteBinary(Stream);
end;

procedure TIniFileEx.SaveToStream(Stream: TStream);
begin
SaveToTextualStream(Stream);
end;

procedure TIniFileEx.SaveToTextualFile(const FileName: String);
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmCreate or fmShareDenyWrite);
try
  SaveToTextualStream(FileStream);
finally
  FileStream.Free;
end;
end;

procedure TIniFileEx.SaveToBinaryFile(const FileName: String);
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmCreate or fmShareDenyWrite);
try
  SaveToBinaryStream(FileStream);
finally
  FileStream.Free;
end;
end;

procedure TIniFileEx.SaveToFile(const FileName: String);
begin
SaveToTextualFile(FileName);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.IndexOfSection(const Section: TIFXString): Integer;
begin
Result := fFileNode.IndexOfSection(Section);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.IndexOfKey(const Section, Key: TIFXString): TIFXNodeIndices;
begin
Result := fFileNode.IndexOfKey(Section,Key);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.IndexOfKey(SectionIndex: Integer; const Key: TIFXString): Integer;
begin
If fFileNode.CheckIndex(SectionIndex) then
  Result := fFileNode[SectionIndex].IndexOfKey(Key)
else
  raise Exception.CreateFmt('TIniFileEx.IndexOfKey: Section index (%d) out of bounds.',[SectionIndex]);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.SectionExists(const Section: TIFXString): Boolean;
begin
Result := IndexOfSection(Section) >= 0;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.KeyExists(const Section, Key: TIFXString): Boolean;
begin
Result := IFXNodeIndicesValid(IndexOfKey(Section,Key));
end;

//------------------------------------------------------------------------------

Function TIniFileEx.KeyExists(SectionIndex: Integer; const Key: TIFXString): Boolean;
begin
Result := IndexOfKey(SectionIndex,Key) >= 0;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.AddSection(const Section: TIFXString);
begin
If not fSettings.ReadOnly then
  fFileNode.AddSection(Section);
end;
 
//------------------------------------------------------------------------------

procedure TIniFileEx.AddKey(const Section, Key: TIFXString);
var
  SectionIndex: Integer;
begin
If not fSettings.ReadOnly then
  begin
    SectionIndex := fFileNode.AddSection(Section);
    fFileNode[SectionIndex].AddKey(Key);
  end;
end;
 
//------------------------------------------------------------------------------

procedure TIniFileEx.AddKey(SectionIndex: Integer; const Key: TIFXString);
begin
If not fSettings.ReadOnly then
  begin
    If fFileNode.CheckIndex(SectionIndex) then
      fFileNode[SectionIndex].AddKey(Key)
    else
      raise Exception.CreateFmt('TIniFileEx.AddKey: Section index (%d) out of bounds.',[SectionIndex]);
  end;
end;
 
//------------------------------------------------------------------------------

procedure TIniFileEx.DeleteSection(const Section: TIFXString);
begin
If not fSettings.ReadOnly then
  fFileNode.RemoveSection(Section);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.DeleteKey(const Section, Key: TIFXString);
begin
If not fSettings.ReadOnly then
  fFileNode.RemoveKey(Section,Key);
end;
 
//------------------------------------------------------------------------------

procedure TIniFileEx.DeleteKey(SectionIndex: Integer; const Key: TIFXString);
begin
If not fSettings.ReadOnly then
  begin
    If fFileNode.CheckIndex(SectionIndex) then
      fFileNode[SectionIndex].RemoveKey(Key)
    else
      raise Exception.CreateFmt('TIniFileEx.DeleteKey: Section index (%d) out of bounds.',[SectionIndex]);
  end;
end;
  
//------------------------------------------------------------------------------

procedure TIniFileEx.ExchangeSections(const Section1, Section2: TIFXString);
var
  SectIdx1,SectIdx2:  Integer;
begin
If not fSettings.ReadOnly then
  begin
    SectIdx1 := fFileNode.IndexOfSection(Section1);
    SectIdx2 := fFileNode.IndexOfSection(Section2);
    If (SectIdx1 <> SectIdx2) and fFileNode.CheckIndex(SectIdx1) and fFileNode.CheckIndex(SectIdx2) then
      fFileNode.ExchangeSections(SectIdx1,SectIdx2);
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.ExchangeKeys(const Section, Key1, Key2: TIFXString);
var
  SectionNode:      TIFXSectionNode;
  KeyIdx1,KeyIdx2:  Integer;
begin
If not fSettings.ReadOnly then
  If fFileNode.FindSection(Section,SectionNode) then
    begin
      KeyIdx1 := SectionNode.IndexOfKey(Key1);
      KeyIdx2 := SectionNode.IndexOfKey(Key2);
      If (KeyIdx1 <> KeyIdx2) and SectionNode.CheckIndex(KeyIdx1) and SectionNode.CheckIndex(KeyIdx2) then
        SectionNode.ExchangeKeys(KeyIdx1,KeyIdx2);
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.ExchangeKeys(SectionIndex: Integer; const Key1, Key2: TIFXString);
var
  KeyIdx1,KeyIdx2:  Integer;
begin
If not fSettings.ReadOnly then
  begin
    If fFileNode.CheckIndex(SectionIndex) then
      begin
        KeyIdx1 := fFileNode[SectionIndex].IndexOfKey(Key1);
        KeyIdx2 := fFileNode[SectionIndex].IndexOfKey(Key2);
        If (KeyIdx1 <> KeyIdx2) and fFileNode[SectionIndex].CheckIndex(KeyIdx1) and fFileNode[SectionIndex].CheckIndex(KeyIdx2) then
          fFileNode[SectionIndex].ExchangeKeys(KeyIdx1,KeyIdx2);
      end
    else raise Exception.CreateFmt('TIniFileEx.ExchangeKeys: Section index (%d) out of bounds.',[SectionIndex]);
  end;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.CopySection(const SourceSection, DestinationSection: TIFXString): Boolean;
var
  SrcSectionNode: TIFXSectionNode;
  Index:          Integer;
  Counter:        Integer;

  procedure AddNewSection(const NewSectionName: TIFXString);
  var
    NewSectionNode: TIFXSectionNode;
  begin
    NewSectionNode := TIFXSectionNode.CreateCopy(SrcSectionNode);
    NewSectionNode.NameStr := NewSectionName;
    fFileNode.AddSectionNode(NewSectionNode);
    SectionCreateHandler(Self,NewSectionNode);
    CopySection{Result} := True;
  end;

begin
Result := False;
If not fSettings.ReadOnly and (IFXCompareText(SourceSection,DestinationSection) <> 0) then
  If fFileNode.FindSection(SourceSection,SrcSectionNode) then
    begin
      Index := fFileNode.IndexOfSection(DestinationSection);
      If Index >= 0 then
        // section with the same name already exists, decide what to do
        case fSettings.DuplicityBehavior of
          idbReplace:
            begin
              fFileNode.DeleteSection(Index);
              AddNewSection(DestinationSection);
            end;
          idbRenameOld:
            begin
              If fFileNode.IndexOfSection(DestinationSection + fSettings.DuplicityRenameOldStr) >= 0 then
                begin
                  Counter := 0;
                  // this can go to infinite loop, but only theoretically, look elsewhere
                  while fFileNode.IndexOfSection(DestinationSection +
                    fSettings.DuplicityRenameOldStr + StrToIFXStr(IntToStr(Counter))) >= 0 do
                    Inc(Counter);
                  fFileNode[Index].NameStr := DestinationSection + fSettings.DuplicityRenameOldStr + StrToIFXStr(IntToStr(Counter));
                end
              else fFileNode[Index].NameStr := DestinationSection + fSettings.DuplicityRenameOldStr;
              AddNewSection(DestinationSection);
            end;
          idbRenameNew:
            If fFileNode.IndexOfSection(DestinationSection + fSettings.DuplicityRenameNewStr) >= 0 then
              begin
                Counter := 0;
                while fFileNode.IndexOfSection(DestinationSection +
                  fSettings.DuplicityRenameNewStr + StrToIFXStr(IntToStr(Counter))) >= 0 do
                  Inc(Counter);
                AddNewSection(DestinationSection + fSettings.DuplicityRenameNewStr + StrToIFXStr(IntToStr(Counter)));
              end
            else AddNewSection(DestinationSection + fSettings.DuplicityRenameNewStr);
        else
          {idbDrop}
        end
      else AddNewSection(DestinationSection);
    end;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.CopyKey(const SourceSection, DestinationSection, SourceKey, DestinationKey: TIFXString): Boolean;
var
  SrcSectionIndex:  Integer;
  DstSectionIndex:  Integer;
  SrcKeyNode:       TIFXKeyNode;
  Index:            Integer;
  Counter:          Integer;

  procedure AddNewKey(const NewKeyName: TIFXString);
  var
    NewKeyNode: TIFXKeyNode;
  begin
    NewKeyNode := TIFXKeyNode.CreateCopy(SrcKeyNode);
    NewKeyNode.NameStr := NewKeyName;
    fFileNode[DstSectionIndex].AddKeyNode(NewKeyNode);
    KeyCreateHandler(Self,fFileNode[DstSectionIndex],NewKeyNode);
    CopyKey{Result} := True;
  end;

begin
Result := False;
If not fSettings.ReadOnly and ((IFXCompareText(SourceSection,DestinationSection) <> 0) or
  (IFXCompareText(SourceKey,DestinationKey) <> 0)) then
  begin
    SrcSectionIndex := fFileNode.IndexOfSection(SourceSection);
    If SrcSectionIndex >= 0 then
      begin
        DstSectionIndex := fFileNode.AddSection(DestinationSection);
        If fFileNode[SrcSectionIndex].FindKey(SourceKey,SrcKeyNode) then
          begin
            Index := fFileNode[DstSectionIndex].IndexOfKey(DestinationKey);
            If Index >= 0 then
              // key with the same name already exists in the destination section
              case fSettings.DuplicityBehavior of
                idbReplace:
                  begin
                    fFileNode[DstSectionIndex].DeleteKey(Index);
                    AddNewKey(DestinationKey);
                  end;
                idbRenameOld:
                  begin
                    If fFileNode[DstSectionIndex].IndexOfKey(DestinationKey + fSettings.DuplicityRenameOldStr) >= 0 then
                      begin
                        Counter := 0;
                        while fFileNode[DstSectionIndex].IndexOfKey(DestinationKey +
                          fSettings.DuplicityRenameOldStr + StrToIFXStr(IntToStr(Counter))) >= 0 do
                          Inc(Counter);
                        fFileNode[DstSectionIndex][Index].NameStr := DestinationKey + fSettings.DuplicityRenameOldStr + StrToIFXStr(IntToStr(Counter));
                      end
                    else fFileNode[DstSectionIndex][Index].NameStr := DestinationKey + fSettings.DuplicityRenameOldStr;
                    AddNewKey(DestinationKey);
                  end;
                idbRenameNew:
                  If fFileNode[DstSectionIndex].IndexOfKey(DestinationKey + fSettings.DuplicityRenameNewStr) >= 0 then
                    begin
                      Counter := 0;
                      while fFileNode[DstSectionIndex].IndexOfKey(DestinationKey +
                        fSettings.DuplicityRenameNewStr + StrToIFXStr(IntToStr(Counter))) >= 0 do
                        Inc(Counter);
                      AddNewKey(DestinationKey + fSettings.DuplicityRenameNewStr + StrToIFXStr(IntToStr(Counter)));
                    end
                  else AddNewKey(DestinationKey + fSettings.DuplicityRenameNewStr);
              else
                {idbDrop}
              end
            else AddNewKey(DestinationKey);
          end;
      end;
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.Clear;
begin
If not fSettings.ReadOnly then
  fFileNode.ClearSections;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SortSections;
begin
If not fSettings.ReadOnly then
  fFileNode.SortSections;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SortSection(const Section: TIFXString);
var
  SectionNode:  TIFXSectionNode;
begin
If not fSettings.ReadOnly then
  If fFileNode.FindSection(Section,SectionNode) then
    SectionNode.SortKeys;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SortKeys(const Section: TIFXString);
begin
If not fSettings.ReadOnly then
  SortSection(Section);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SortKeys;
var
  i:  Integer;
begin
If not fSettings.ReadOnly then
  For i := fFileNode.LowIndex to fFileNode.HighIndex do
    fFileNode[i].SortKeys;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.Sort;
begin
If not fSettings.ReadOnly then
  begin
    SortKeys;
    SortSections;
  end;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetFileComment: TIFXString;
begin
Result := fFileNode.Comment;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetSectionComment(const Section: TIFXString): TIFXString;
var
  SectionNode:  TIFXSectionNode;
begin
If fFileNode.FindSection(Section,SectionNode) then
  Result := SectionNode.Comment
else
  Result := '';
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetKeyComment(const Section, Key: TIFXString): TIFXString;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  Result := KeyNode.Comment
else
  Result := '';
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SetFileComment(const Text: TIFXString);
begin
If not fSettings.ReadOnly then
  fFileNode.Comment := Text;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SetSectionComment(const Section: TIFXString; const Text: TIFXString);
var
  SectionNode:  TIFXSectionNode;
begin
If not fSettings.ReadOnly then
  If fFileNode.FindSection(Section,SectionNode) then
    SectionNode.Comment := Text;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SetKeyComment(const Section, Key: TIFXString; const Text: TIFXString);
var
  KeyNode:  TIFXKeyNode;
begin
If not fSettings.ReadOnly then
  If fFileNode.FindKey(Section,Key,KeyNode) then
    KeyNode.Comment := Text;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.RemoveFileComment;
begin
If not fSettings.ReadOnly then
  fFileNode.Comment := '';
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.RemoveSectionComment(const Section: TIFXString; RemoveKeysComments: Boolean = False);
var
  SectionNode:  TIFXSectionNode;
  i:            Integer;
begin
If not fSettings.ReadOnly then
  If fFileNode.FindSection(Section,SectionNode) then
    begin
      SectionNode.Comment := '';
      If RemoveKeysComments then
        For i := SectionNode.LowIndex to SectionNode.HighIndex do
          SectionNode[i].Comment := '';
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.RemoveKeyComment(const Section, Key: TIFXString);
var
  KeyNode:  TIFXKeyNode;
begin
If not fSettings.ReadOnly then
  If fFileNode.FindKey(Section,Key,KeyNode) then
    KeyNode.Comment := '';
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.RemoveAllComment;
var
  i,j:  Integer;
begin
If not fSettings.ReadOnly then
  begin
    RemoveFileComment;
    For i := fFileNode.LowIndex to fFileNode.HighIndex do
      begin
        fFileNode[i].Comment := '';
        For j := fFileNode[i].LowIndex to fFileNode[i].HighIndex do
          fFileNode[i][j].Comment := '';
      end;
  end;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetValueState(const Section, Key: TIFXString): TIFXValueState;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  Result := KeyNode.ValueState
else
  raise Exception.CreateFmt('TIniFileEx.GetValueState: Key (%s:%s) not found.',[Section,Key]);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetValueEncoding(const Section, Key: TIFXString): TIFXValueEncoding;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  Result := KeyNode.ValueEncoding
else
  raise Exception.CreateFmt('TIniFileEx.GetValueEncoding: Key (%s:%s) not found.',[Section,Key]);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SetValueEncoding(const Section, Key: TIFXString; Encoding: TIFXValueEncoding);
var
  KeyNode:  TIFXKeyNode;
begin
If not fSettings.ReadOnly then
  If fFileNode.FindKey(Section,Key,KeyNode) then
    KeyNode.ValueEncoding := Encoding;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetValueType(const Section, Key: TIFXString): TIFXValueType;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  Result := KeyNode.ValueType
else
  raise Exception.CreateFmt('TIniFileEx.GetValueType: Key (%s:%s) not found.',[Section,Key]);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.ReadSections(Strings: TStrings);
var
  i:  Integer;
begin
Strings.Clear;
For i := fFileNode.LowIndex to fFileNode.HighIndex do
  Strings.Add(IFXStrToStr(fFileNode[i].NameStr));
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.ReadSection(const Section: TIFXString; Strings: TStrings);
var
  SectionNode:  TIFXSectionNode;
  i:            Integer;
begin
If fFileNode.FindSection(Section,SectionNode) then
  begin
    Strings.Clear;
    For i := SectionNode.LowIndex to SectionNode.HighIndex do
      Strings.Add(IFXStrToStr(SectionNode[i].NameStr));
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.ReadSectionValues(const Section: TIFXString; Strings: TStrings);
var
  SectionNode:  TIFXSectionNode;
  i:            Integer;
begin
If fFileNode.FindSection(Section,SectionNode) then
  begin
    Strings.Clear;
    For i := SectionNode.LowIndex to SectionNode.HighIndex do
      Strings.Add(IFXStrToStr(fParser.ConstructKeyValueLine(SectionNode[i])));
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteBool(const Section, Key: TIFXString; Value: Boolean);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueBool(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteBool(const Section, Key: TIFXString; Value: Boolean; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueBool(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteInt8(const Section, Key: TIFXString; Value: Int8);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueInt8(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteInt8(const Section, Key: TIFXString; Value: Int8; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueInt8(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteUInt8(const Section, Key: TIFXString; Value: UInt8);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueUInt8(Value);
end;
 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteUInt8(const Section, Key: TIFXString; Value: UInt8; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueUInt8(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteInt16(const Section, Key: TIFXString; Value: Int16);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueInt16(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteInt16(const Section, Key: TIFXString; Value: Int16; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueInt16(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteUInt16(const Section, Key: TIFXString; Value: UInt16);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueUInt16(Value);
end;
  
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteUInt16(const Section, Key: TIFXString; Value: UInt16; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueUInt16(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteInt32(const Section, Key: TIFXString; Value: Int32);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueInt32(Value);
end;
 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteInt32(const Section, Key: TIFXString; Value: Int32; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueInt32(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteUInt32(const Section, Key: TIFXString; Value: UInt32);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueUInt32(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteUInt32(const Section, Key: TIFXString; Value: UInt32; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueUInt32(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteInt64(const Section, Key: TIFXString; Value: Int64);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueInt64(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteInt64(const Section, Key: TIFXString; Value: Int64; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueInt64(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteUInt64(const Section, Key: TIFXString; Value: UInt64);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueUInt64(Value);
end;
 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteUInt64(const Section, Key: TIFXString; Value: UInt64; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueUInt64(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteInteger(const Section, Key: TIFXString; Value: Integer);
begin
If not fSettings.ReadOnly then
{$IF SizeOf(Integer) = 2}
  WritingValue(Section,Key).SetValueInt16(Value);
{$ELSEIF SizeOf(Integer) = 4}
  WritingValue(Section,Key).SetValueInt32(Value);
{$ELSEIF SizeOf(Integer) = 8}
  WritingValue(Section,Key).SetValueInt64(Value);
{$ELSE}
  {$MESSAGE FATAL 'Unsupported integer size'}
{$IFEND}
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteInteger(const Section, Key: TIFXString; Value: Integer; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
    {$IF SizeOf(Integer) = 2}
      SetValueInt16(Value);
    {$ELSEIF SizeOf(Integer) = 4}
     SetValueInt32(Value);
    {$ELSEIF SizeOf(Integer) = 8}
      SetValueInt64(Value);
    {$ELSE}
      {$MESSAGE FATAL 'Unsupported integer size'}
    {$IFEND}
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteFloat32(const Section, Key: TIFXString; Value: Float32);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueFloat32(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteFloat32(const Section, Key: TIFXString; Value: Float32; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueFloat32(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteFloat64(const Section, Key: TIFXString; Value: Float64);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueFloat64(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteFloat64(const Section, Key: TIFXString; Value: Float64; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueFloat64(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteFloat(const Section, Key: TIFXString; Value: Double);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueFloat64(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteFloat(const Section, Key: TIFXString; Value: Double; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueFloat64(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteTime(const Section, Key: TIFXString; Value: TDateTime);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueTime(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteTime(const Section, Key: TIFXString; Value: TDateTime; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueTime(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteDate(const Section, Key: TIFXString; Value: TDateTime);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueDate(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteDate(const Section, Key: TIFXString; Value: TDateTime; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueDate(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteDateTime(const Section, Key: TIFXString; Value: TDateTime);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueDateTime(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteDateTime(const Section, Key: TIFXString; Value: TDateTime; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueDateTime(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteString(const Section, Key: TIFXString; const Value: String);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueString(StrToUnicode(Value));
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteString(const Section, Key: TIFXString; const Value: String; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueString(StrToUnicode(Value));
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteBinaryBuffer(const Section, Key: TIFXString; const Buffer; Size: TMemSize; MakeCopy: Boolean = False);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueBinary(@Buffer,Size,MakeCopy);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteBinaryBuffer(const Section, Key: TIFXString; const Buffer; Size: TMemSize; Encoding: TIFXValueEncoding; MakeCopy: Boolean = False);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueBinary(@Buffer,Size,MakeCopy);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteBinaryMemory(const Section, Key: TIFXString; Value: Pointer; Size: TMemSize; MakeCopy: Boolean = False);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueBinary(Value,Size,MakeCopy);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteBinaryMemory(const Section, Key: TIFXString; Value: Pointer; Size: TMemSize; Encoding: TIFXValueEncoding; MakeCopy: Boolean = False);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueBinary(Value,Size,MakeCopy);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteBinaryStream(const Section, Key: TIFXString; Stream: TStream; Position, Count: Int64);
var
  TempMem:  Pointer;
begin
If not fSettings.ReadOnly then
  begin
    GetMem(TempMem,Count);
    try
      Stream.Seek(Position,soBeginning);
      Stream.ReadBuffer(TempMem^,Count);
      with WritingValue(Section,Key) do
        begin
          SetValueBinary(TempMem,TMemSize(Count),False);
          ValueDataPtr^.BinaryValueOwned := True;
        end;
    except
      FreeMem(TempMem,Stream.Size)
    end;
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteBinaryStream(const Section, Key: TIFXString; Stream: TStream; Position, Count: Int64; Encoding: TIFXValueEncoding);
var
  TempMem:  Pointer;
begin
If not fSettings.ReadOnly then
  begin
    GetMem(TempMem,Count);
    try
      Stream.Seek(Position,soBeginning);
      Stream.ReadBuffer(TempMem^,Count);
      with WritingValue(Section,Key) do
        begin
          SetValueBinary(TempMem,TMemSize(Count),False);
          ValueDataPtr^.BinaryValueOwned := True;
          ValueEncoding := Encoding;
        end;
    except
      FreeMem(TempMem,Stream.Size)
    end;
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteBinaryStream(const Section, Key: TIFXString; Stream: TStream);
var
  TempMem:  Pointer;
begin
If not fSettings.ReadOnly then
  begin
    GetMem(TempMem,Stream.Size);
    try
      Stream.Seek(0,soBeginning);
      Stream.ReadBuffer(TempMem^,Stream.Size);
      with WritingValue(Section,Key) do
        begin
          SetValueBinary(TempMem,Stream.Size,False);
          ValueDataPtr^.BinaryValueOwned := True;
        end;
    except
      FreeMem(TempMem,Stream.Size)
    end;
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteBinaryStream(const Section, Key: TIFXString; Stream: TStream; Encoding: TIFXValueEncoding);
var
  TempMem:  Pointer;
begin
If not fSettings.ReadOnly then
  begin
    GetMem(TempMem,Stream.Size);
    try
      Stream.Seek(0,soBeginning);
      Stream.ReadBuffer(TempMem^,Stream.Size);
      with WritingValue(Section,Key) do
        begin
          SetValueBinary(TempMem,Stream.Size,False);
          ValueDataPtr^.BinaryValueOwned := True;
          ValueEncoding := Encoding;
        end;
    except
      FreeMem(TempMem,Stream.Size)
    end;
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.PrepareReading(const Section, Key: TIFXString; ValueType: TIFXValueType);
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  KeyNode.GetValuePrepare(ValueType)
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadBool(const Section, Key: TIFXString; Default: Boolean = False): Boolean;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  KeyNode.GetValueBool(Result)
else
  Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadInt8(const Section, Key: TIFXString; Default: Int8 = 0): Int8;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  KeyNode.GetValueInt8(Result)
else
  Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadUInt8(const Section, Key: TIFXString; Default: UInt8 = 0): UInt8;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  KeyNode.GetValueUInt8(Result)
else
  Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadInt16(const Section, Key: TIFXString; Default: Int16 = 0): Int16;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  KeyNode.GetValueInt16(Result)
else
  Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadUInt16(const Section, Key: TIFXString; Default: UInt16 = 0): UInt16;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  KeyNode.GetValueUInt16(Result)
else
  Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadInt32(const Section, Key: TIFXString; Default: Int32 = 0): Int32;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  KeyNode.GetValueInt32(Result)
else
  Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadUInt32(const Section, Key: TIFXString; Default: UInt32 = 0): UInt32;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  KeyNode.GetValueUInt32(Result)
else
  Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadInt64(const Section, Key: TIFXString; Default: Int64 = 0): Int64;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  KeyNode.GetValueInt64(Result)
else
  Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadUInt64(const Section, Key: TIFXString; Default: UInt64 = 0): UInt64;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  KeyNode.GetValueUInt64(Result)
else
  Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadInteger(const Section, Key: TIFXString; Default: Integer = 0): Integer;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
{$IF SizeOf(Integer) = 2}
  KeyNode.GetValueInt16(Result)
{$ELSEIF SizeOf(Integer) = 4}
  KeyNode.GetValueInt32(Result)
{$ELSEIF SizeOf(Integer) = 8}
  KeyNode.GetValueInt64(Result)
{$ELSE}
  {$MESSAGE FATAL 'Unsupported integer size'}
{$IFEND}
else
  Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadFloat32(const Section, Key: TIFXString; Default: Float32 = 0.0): Float32;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  KeyNode.GetValueFloat32(Result)
else
  Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadFloat64(const Section, Key: TIFXString; Default: Float64 = 0.0): Float64;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  KeyNode.GetValueFloat64(Result)
else
  Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadFloat(const Section, Key: TIFXString; Default: Double = 0.0): Double;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  KeyNode.GetValueFloat64(Result)
else
  Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadTime(const Section, Key: TIFXString; Default: TDateTime = 0.0): TDateTime;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  KeyNode.GetValueDate(Result)
else
  Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadDate(const Section, Key: TIFXString; Default: TDateTime = 0.0): TDateTime;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  KeyNode.GetValueTime(Result)
else
  Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadDateTime(const Section, Key: TIFXString; Default: TDateTime = 0.0): TDateTime;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  KeyNode.GetValueDateTime(Result)
else
  Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadString(const Section, Key: TIFXString; Default: String = ''): String;
var
  KeyNode:  TIFXKeyNode;
  OutTemp:  TIFXString;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    KeyNode.GetValueString(OutTemp);
    Result := IFXStrToStr(OutTemp);
  end
else Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadBinarySize(const Section, Key: TIFXString): TMemSize;
var
  KeyNode:  TIFXKeyNode;
  Dummy:    Pointer;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  KeyNode.GetValueBinary(Dummy,Result,False)
else
  Result := 0;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadBinaryBuffer(const Section, Key: TIFXString; var Buffer; Size: TMemSize): TMemSize;
var
  KeyNode:    TIFXKeyNode;
  ValuePtr:   Pointer;
  ValueSize:  TMemSize;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    KeyNode.GetValueBinary(ValuePtr,ValueSize,False);
    If Size < ValueSize then Result := Size
      else Result := ValueSize;
    Move(ValuePtr^,Buffer,Result); 
  end
else Result := 0;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadBinaryMemory(const Section, Key: TIFXString; out Ptr: Pointer; MakeCopy: Boolean = False): TMemSize;
var
  KeyNode:  TIFXKeyNode;
begin
If not fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    Ptr := nil;  
    Result := 0;
  end
else KeyNode.GetValueBinary(Ptr,Result,MakeCopy);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadBinaryMemory(const Section, Key: TIFXString; Ptr: Pointer; Size: TMemSize): TMemSize;
begin
Result := ReadBinaryBuffer(Section,Key,Ptr^,Size);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadBinaryStream(const Section, Key: TIFXString; Stream: TStream; ClearStream: Boolean = False): Int64;
var
  KeyNode:    TIFXKeyNode;
  ValuePtr:   Pointer;
  ValueSize:  TMemSize;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    If ClearStream then
      Stream.Size := 0;
    KeyNode.GetValueBinary(ValuePtr,ValueSize,False);
    Stream.WriteBuffer(ValuePtr^,ValueSize);
    Result := Int64(ValueSize);
  end
else Result := 0;
end;

{$IFDEF AllowLowLevelAccess}
//------------------------------------------------------------------------------

Function TIniFileEx.GetSectionNode(const Section: TIFXString): TIFXSectionNode;
begin
If not fFileNode.FindSection(Section,Result) then
  Result := nil;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetKeyNode(const Section, Key: TIFXString): TIFXKeyNode;
begin
If not fFileNode.FindKey(Section,Key,Result) then
  Result := nil;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetValueString(const Section, Key: TIFXString): TIFXString;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  Result := KeyNode.ValueStr
else
  raise Exception.CreateFmt('TIniFileEx.GetValueString: Key (%s:%s) not found',[Section,Key]);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SetValueString(const Section, Key, ValueStr: TIFXString);
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  KeyNode.ValueStr := ValueStr
else
  raise Exception.CreateFmt('TIniFileEx.SetValueString: Key (%s:%s) not found',[Section,Key]);
end;

{$ENDIF}
end.
