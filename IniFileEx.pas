unit IniFileEx;

{$INCLUDE '.\IniFileEx_defs.inc'}

interface

uses
  Classes, 
  AuxClasses,
  IniFileEx_Common, IniFileEx_Nodes;

type
  TIniFileEx = class(TCustomObject)
  private
    fSettings:          TIFXSettings;
    fFileNode:          TIFXFileNode;
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
  public
    constructor Create;
    destructor Destroy; override;
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

    Function GetValueState(const Section, Key: TIFXString): TIFXValueState; virtual;
    Function GetValueEncoding(const Section, Key: TIFXString): TIFXValueEncoding; virtual;
    procedure SetValueEncoding(const Section, Key: TIFXString; Encoding: TIFXValueEncoding); virtual;
    Function GetValueType(const Section, Key: TIFXString): TIFXValueType; virtual;

    procedure ReadSections(Strings: TStrings); virtual;
    procedure ReadSectionValues(const Section: TIFXString; Strings: TStrings); virtual;
    procedure ReadSection(const Section: TIFXString; Strings: TStrings); virtual;      

  {$IFDEF AllowLowLevelAccess}
    Function GetSectionNode(const Section: TIFXString): TIFXSectionNode; virtual;
    Function GetKeyNode(const Section, Key: TIFXString): TIFXKeyNode; virtual;
    Function GetValueString(const Section, Key: TIFXString): TIFXString; virtual;
    procedure SetValueString(const Section, Key, ValueStr: TIFXString); virtual;
    property FileNode: TIFXFileNode read fFileNode;
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
  SysUtils;

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
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.Finalize;
begin
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
              If fFileNode.IndexOfSection(DestinationSection + IFX_DUPRENSTR_OLD) >= 0 then
                begin
                  Counter := 0;
                  // this can go to infinite loop, but only theoretically, look elsewhere
                  while fFileNode.IndexOfSection(DestinationSection +
                    IFX_DUPRENSTR_OLD + StrToIFXStr(IntToStr(Counter))) >= 0 do
                    Inc(Counter);
                  fFileNode[Index].NameStr := DestinationSection + IFX_DUPRENSTR_OLD + StrToIFXStr(IntToStr(Counter));
                end
              else fFileNode[Index].NameStr := DestinationSection + IFX_DUPRENSTR_OLD;
              AddNewSection(DestinationSection);
            end;
          idbRenameNew:
            If fFileNode.IndexOfSection(DestinationSection + IFX_DUPRENSTR_NEW) >= 0 then
              begin
                Counter := 0;
                while fFileNode.IndexOfSection(DestinationSection +
                  IFX_DUPRENSTR_NEW + StrToIFXStr(IntToStr(Counter))) >= 0 do
                  Inc(Counter);
                AddNewSection(DestinationSection + IFX_DUPRENSTR_NEW + StrToIFXStr(IntToStr(Counter)));
              end
            else AddNewSection(DestinationSection + IFX_DUPRENSTR_NEW);
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
                    If fFileNode[DstSectionIndex].IndexOfKey(DestinationKey + IFX_DUPRENSTR_OLD) >= 0 then
                      begin
                        Counter := 0;
                        while fFileNode[DstSectionIndex].IndexOfKey(DestinationKey +
                          IFX_DUPRENSTR_OLD + StrToIFXStr(IntToStr(Counter))) >= 0 do
                          Inc(Counter);
                        fFileNode[DstSectionIndex][Index].NameStr := DestinationKey + IFX_DUPRENSTR_OLD + StrToIFXStr(IntToStr(Counter));
                      end
                    else fFileNode[DstSectionIndex][Index].NameStr := DestinationKey + IFX_DUPRENSTR_OLD;
                    AddNewKey(DestinationKey);
                  end;
                idbRenameNew:
                  If fFileNode[DstSectionIndex].IndexOfKey(DestinationKey + IFX_DUPRENSTR_NEW) >= 0 then
                    begin
                      Counter := 0;
                      while fFileNode[DstSectionIndex].IndexOfKey(DestinationKey +
                        IFX_DUPRENSTR_NEW + StrToIFXStr(IntToStr(Counter))) >= 0 do
                        Inc(Counter);
                      AddNewKey(DestinationKey + IFX_DUPRENSTR_NEW + StrToIFXStr(IntToStr(Counter)));
                    end
                  else AddNewKey(DestinationKey + IFX_DUPRENSTR_NEW);
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

procedure TIniFileEx.ReadSectionValues(const Section: TIFXString; Strings: TStrings);
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

procedure TIniFileEx.ReadSection(const Section: TIFXString; Strings: TStrings);
var
  SectionNode:  TIFXSectionNode;
  i:            Integer;
begin
If fFileNode.FindSection(Section,SectionNode) then
  begin
    Strings.Clear;
    For i := SectionNode.LowIndex to SectionNode.HighIndex do
      ; {$message 'implement line building'}
  end;
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
