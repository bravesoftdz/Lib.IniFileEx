unit IniFileEx_Nodes;

{$INCLUDE '.\IniFileEx_defs.inc'}

interface

uses
  AuxClasses,
  IniFileEx_Common;

type
  // forward declarations
  TIFXKeyNode     = class;
  TIFXSectionNode = class;

  TIFXKeyNodeEvent = procedure(Sender: TObject; Section: TIFXSectionNode; Key: TIFXKeyNode) of object;
  TIFXSectionNodeEvent = procedure(Sender: TObject; Section: TIFXSectionNode) of object;

  TIFXKeyNode = class(TCustomObject)
  private
    fSettingsPtr:   PIFXSettings;
    fName:          TIFXHashedString;
    fComment:       String;
    fValueStr:      String;
    fValueEncoding: TIFXValueEncoding;
    fValueState:    TIFXValueState;
    fValueData:     TIFXValueData;
    procedure SetNameStr(const Value: String);
  protected
  public
    constructor Create(const KeyName: String; SettingsPtr: PIFXSettings); overload;
    constructor Create(SettingsPtr: PIFXSettings); overload;
    destructor Destroy; override;
    property SettingsPtr: PIFXSettings read fSettingsPtr;
    property Name: TIFXHashedString read fName write fName;
    property NameStr: String read fName.Str write SetNameStr;
    property Comment: String read fComment write fComment;
    //property ValueStr: String
    //property ValueEncoding: fValueEncoding
    //property ValueState: TIFXValueState
    property ValueType: TIFXValueType read fValueData.ValueType write fValueData.ValueType;
    property ValueData: TIFXValueData read fValueData;
  end;

  TIFXSectionNode = class(TCustomListObject)
  private
    fKeys:          array of TIFXKeyNode;
    fCount:         Integer;
    fSettingsPtr:   PIFXSettings;
    fName:          TIFXHashedString;
    fComment:       String;
    fOnKeyCreate:   TIFXKeyNodeEvent;
    fOnKeyDestroy:  TIFXKeyNodeEvent;
    Function GetKey(Index: Integer): TIFXKeyNode;
    procedure SetNameStr(const Value: String);
  protected
    Function GetCapacity: Integer; override;
    procedure SetCapacity(Value: Integer); override;
    Function GetCount: Integer; override;
    procedure SetCount(Value: Integer); override;
  public
    constructor Create(const SectionName: String; SettingsPtr: PIFXSettings); overload;
    constructor Create(SettingsPtr: PIFXSettings); overload;
    destructor Destroy; override;
    Function LowIndex: Integer; override;
    Function HighIndex: Integer; override;
    Function IndexOfKey(const KeyName: String): Integer; virtual;
    Function FindKey(const KeyName: String; out KeyNode: TIFXKeyNode): Boolean; overload; virtual;
    Function FindKey(const KeyName: String): TIFXKeyNode; overload; virtual;
    Function AddKey(const KeyName: String): Integer; virtual;
    procedure ExchangeKeys(Idx1, Idx2: Integer); virtual;
    Function RemoveKey(const KeyName: String): Integer; virtual;
    procedure DeleteKey(Index: Integer); virtual;
    procedure ClearKeys; virtual;
    procedure SortKeys(Reversed: Boolean = False); virtual;
    property Keys[Index: Integer]: TIFXKeyNode read GetKey; default;
    property KeyCount: Integer read GetCount write SetCount;
    property SettingsPtr: PIFXSettings read fSettingsPtr;
    property Name: TIFXHashedString read fName write fName;
    property NameStr: String read fName.Str write SetNameStr;
    property Comment: String read fComment write fComment;
    property OnKeyCreate: TIFXKeyNodeEvent read fOnKeyCreate write fOnKeyCreate;
    property OnKeyDestroy: TIFXKeyNodeEvent read fOnKeyDestroy write fOnKeyDestroy;
  end;


  TIFXFileNode = class(TCustomListObject)
  private
    fSections:          array of TIFXSectionNode;
    fCount:             Integer;
    fSettingsPtr:       PIFXSettings;
    fComment:           String;
    fOnKeyCreate:       TIFXKeyNodeEvent;
    fOnKeyDestroy:      TIFXKeyNodeEvent;
    fOnSectionCreate:   TIFXSectionNodeEvent;
    fOnSectionDestroy:  TIFXSectionNodeEvent;
    Function GetSection(Index: Integer): TIFXSectionNode;
  protected
    Function GetCapacity: Integer; override;
    procedure SetCapacity(Value: Integer); override;
    Function GetCount: Integer; override;
    procedure SetCount(Value: Integer); override;
    procedure KeyCreateHandler(Sender: TObject; Section: TIFXSectionNode; Key: TIFXKeyNode); virtual;
    procedure KeyDestroyHandler(Sender: TObject; Section: TIFXSectionNode; Key: TIFXKeyNode); virtual;
  public
    constructor Create(SettingsPtr: PIFXSettings);
    destructor Destroy; override;
    Function LowIndex: Integer; override;
    Function HighIndex: Integer; override;
    Function IndexOfSection(const SectionName: String): Integer; virtual;
    Function FindSection(const SectionName: String; out SectionNode: TIFXSectionNode): Boolean; overload; virtual;
    Function FindSection(const SectionName: String): TIFXSectionNode; overload; virtual;
    Function AddSection(const SectionName: String): Integer; virtual;
    procedure ExchangeSections(Idx1, Idx2: Integer); virtual;
    Function RemoveSection(const SectionName: String): Integer; virtual;
    procedure DeleteSection(Index: Integer); virtual;
    procedure ClearSections; virtual;
    procedure SortSections(Reversed: Boolean = False); virtual;
    Function IndexOfKey(const SectionName, KeyName: String): TIFXNodeIndices; virtual;
    Function FindKey(const SectionName, KeyName: String; out KeyNode: TIFXKeyNode): Boolean; overload; virtual;
    Function FindKey(const SectionName, KeyName: String): TIFXKeyNode; overload; virtual;
    Function AddKey(const SectionName, KeyName: String): TIFXNodeIndices; virtual;
    procedure ExchangeKeys(const SectionName: String; KeyIdx1, KeyIdx2: Integer); virtual;
    Function RemoveKey(const SectionName, KeyName: String): TIFXNodeIndices; virtual;
    procedure DeleteKey(SectionIndex, KeyIndex: Integer); virtual;
    procedure ClearKeys(const SectionName: String); virtual;
    procedure SortKeys(const SectionName: String; Reversed: Boolean = False); virtual;  
    procedure Clear; virtual; abstract;
    property Sections[Index: Integer]: TIFXSectionNode read GetSection; default;
    property SectionCount: Integer read GetCount write SetCount;
    property SettingsPtr: PIFXSettings read fSettingsPtr;
    property Comment: String read fComment write fComment;
    property OnKeyCreate: TIFXKeyNodeEvent read fOnKeyCreate write fOnKeyCreate;
    property OnKeyDestroy: TIFXKeyNodeEvent read fOnKeyDestroy write fOnKeyDestroy;
    property OnSectionCreate: TIFXSectionNodeEvent read fOnSectionCreate write fOnSectionCreate;
    property OnSectionDestroy: TIFXSectionNodeEvent read fOnSectionDestroy write fOnSectionDestroy;
  end;

implementation

uses
  SysUtils;

procedure TIFXKeyNode.SetNameStr(const Value: String);
begin
fName := HashedString(Value);
end;

//==============================================================================

constructor TIFXKeyNode.Create(const KeyName: String; SettingsPtr: PIFXSettings);
begin
inherited Create;
fSettingsPtr := SettingsPtr;
fName := HashedString(KeyName);
fComment := '';
fValueStr := '';
fValueEncoding := iveUnknown;
fValueState := ivsUndefined;
fValueData.ValueType := ivtUnknown;
end;
 
//------------------------------------------------------------------------------

constructor TIFXKeyNode.Create(SettingsPtr: PIFXSettings);
begin
Create('',SettingsPtr);
end;

//------------------------------------------------------------------------------

destructor TIFXKeyNode.Destroy;
begin
inherited;
end;

//******************************************************************************

Function TIFXSectionNode.GetKey(Index: Integer): TIFXKeyNode;
begin
If CheckIndex(Index) then
  Result := fKeys[Index]
else
  raise Exception.CreateFmt('TIFXSectionNode.GetKey: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure TIFXSectionNode.SetNameStr(const Value: String);
begin
fName := HashedString(Value);
end;

//==============================================================================

Function TIFXSectionNode.GetCapacity: Integer;
begin
Result := Length(fKeys);
end;

//------------------------------------------------------------------------------

procedure TIFXSectionNode.SetCapacity(Value: Integer);
var
  i:  Integer;
begin
If Value <> Length(fKeys) then
  begin
    If Value < fCount then
      begin
        For i := Value to Pred(fCount) do
          begin
            If Assigned(fOnKeyDestroy) then
              fOnKeyDestroy(Self,Self,fKeys[i]);
            fKeys[i].Free;
          end;
        fCount := Value;
      end;
    SetLength(fKeys,Value);
  end;
end;
 
//------------------------------------------------------------------------------

Function TIFXSectionNode.GetCount: Integer;
begin
Result := fCount;
end;

//------------------------------------------------------------------------------

procedure TIFXSectionNode.SetCount(Value: Integer);
begin
// nothing to do here
end;

//==============================================================================

constructor TIFXSectionNode.Create(const SectionName: String; SettingsPtr: PIFXSettings);
begin
inherited Create;
SetLEngth(fKeys,0);
fCount := 0;
fSettingsPtr := SettingsPtr;
fName := HashedString(SectionName);
fComment := '';
fOnKeyCreate := nil;
fOnKeyDestroy := nil;
end;

//------------------------------------------------------------------------------

constructor TIFXSectionNode.Create(SettingsPtr: PIFXSettings);
begin
Create('',SettingsPtr);
end;

//------------------------------------------------------------------------------

destructor TIFXSectionNode.Destroy;
begin
ClearKeys;
inherited;
end;

//------------------------------------------------------------------------------

Function TIFXSectionNode.LowIndex: Integer;
begin
Result := Low(fKeys);
end;

//------------------------------------------------------------------------------

Function TIFXSectionNode.HighIndex: Integer;
begin
Result := Pred(fCount);
end;

//------------------------------------------------------------------------------

Function TIFXSectionNode.IndexOfKey(const KeyName: String): Integer;
var
  i:    Integer;
  Temp: TIFXHashedString;
begin
Result := -1;
Temp := HashedString(KeyName);
For i := LowIndex to HighIndex do
  If SameHashString(fKeys[i].Name,Temp) then
    begin
      Result := i;
      Break{For i};
    end;
end;

//------------------------------------------------------------------------------

Function TIFXSectionNode.FindKey(const KeyName: String; out KeyNode: TIFXKeyNode): Boolean;
var
  Index:  Integer;
begin
Index := IndexOfKey(KeyName);
If Index >= 0 then
  begin
    KeyNode := fKeys[Index];
    Result := True;
  end
else Result := False;
end;

//------------------------------------------------------------------------------

Function TIFXSectionNode.FindKey(const KeyName: String): TIFXKeyNode;
begin
If not FindKey(KeyName,Result) then
  Result := nil;
end;

//------------------------------------------------------------------------------

Function TIFXSectionNode.AddKey(const KeyName: String): Integer;
begin
Result := IndexOfKey(KeyName);
If Result < 0 then
  begin
    Grow;
    Result := fCount;
    fKeys[Result] := TIFXKeyNode.Create(KeyName,fSettingsPtr);
    Inc(fCount);
    If Assigned(fOnKeyCreate) then
      fOnKeyCreate(Self,Self,fKeys[Result]);
  end;
end;

//------------------------------------------------------------------------------

procedure TIFXSectionNode.ExchangeKeys(Idx1, Idx2: Integer);
var
  Temp: TIFXKeyNode;
begin
If Idx1 <> Idx2 then
  begin
    If not CheckIndex(Idx1) then
      raise Exception.CreateFmt('TIFXSectionNode.ExchangeKeys: Idx1 (%d) out of bounds.',[Idx1]);
    If not CheckIndex(Idx2) then
      raise Exception.CreateFmt('TIFXSectionNode.ExchangeKeys: Idx2 (%d) out of bounds.',[Idx2]);
    Temp := fKeys[Idx1];
    fKeys[Idx1] := fKeys[Idx2];
    fKeys[Idx2] := Temp;
  end;
end;

//------------------------------------------------------------------------------

Function TIFXSectionNode.RemoveKey(const KeyName: String): Integer;
begin
Result := IndexOfKey(KeyName);
If Result >= 0 then
  DeleteKey(Result);
end;

//------------------------------------------------------------------------------

procedure TIFXSectionNode.DeleteKey(Index: Integer);
var
  i:  Integer;
begin
If CheckIndex(Index) then
  begin
    If Assigned(fOnKeyDestroy) then
      fOnKeyDestroy(Self,Self,fKeys[Index]);
    fKeys[Index].Free;
    For i := Index to (fCount - 2) do
      fKeys[i] := fKeys[i + 1];
    Dec(fCount);
    Shrink;
  end
else raise Exception.CreateFmt('TIFXSectionNode.DeleteKey: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure TIFXSectionNode.ClearKeys;
var
  i:  Integer;
begin
For i := HighIndex downto LowIndex do
  begin
    If Assigned(fOnKeyDestroy) then
      fOnKeyDestroy(Self,Self,fKeys[i]);
    fKeys[i].Free;
  end;
fCount := 0;
Shrink;
end;

//------------------------------------------------------------------------------

procedure TIFXSectionNode.SortKeys(Reversed: Boolean = False);

  procedure QuickSort(Left,Right: Integer; Coef: Integer);
  var
    Pivot:  String;
    Idx,i:  Integer;
  begin
    If Left < Right  then
      begin
        ExchangeKeys((Left + Right) shr 1,Right);
        Pivot := fKeys[Right].NameStr;
        Idx := Left;
        For i := Left to Pred(Right) do
          If (AnsiCompareText(Pivot,fKeys[i].NameStr) * Coef) > 0 then
            begin
              ExchangeKeys(i,idx);
              Inc(Idx);
            end;
        ExchangeKeys(Idx,Right);
        QuickSort(Left,Idx - 1,Coef);
        QuickSort(Idx + 1, Right,Coef);
      end;
  end;

begin
If fCount > 1 then
  If Reversed then QuickSort(LowIndex,HighIndex,-1)
    else QuickSort(LowIndex,HighIndex,1);
end;

//******************************************************************************

Function TIFXFileNode.GetSection(Index: Integer): TIFXSectionNode;
begin
If CheckIndex(Index) then
  Result := fSections[Index]
else
  raise Exception.CreateFmt('TIFXFileNode.GetSection: Index (%d) out of bounds.',[Index]);
end;

//==============================================================================

Function TIFXFileNode.GetCapacity: Integer;
begin
Result := Length(fSections);
end;
 
//------------------------------------------------------------------------------

procedure TIFXFileNode.SetCapacity(Value: Integer);
var
  i:  Integer;
begin
If Value <> Length(fSections) then
  begin
    If Value < fCount then
      begin
        For i := Value to Pred(fCount) do
          begin
            If Assigned(fOnSectionDestroy) then
              fOnSectionDestroy(Self,fSections[i]);
            fSections[i].Free;
          end;
        fCount := Value;
      end;
    SetLength(fSections,Value);
  end;
end;
 
//------------------------------------------------------------------------------

Function TIFXFileNode.GetCount: Integer;
begin
Result := fCount;
end;

//------------------------------------------------------------------------------

procedure TIFXFileNode.SetCount(Value: Integer);
begin
// nothing to do here
end;

//------------------------------------------------------------------------------

procedure TIFXFileNode.KeyCreateHandler(Sender: TObject; Section: TIFXSectionNode; Key: TIFXKeyNode);
begin
If Assigned(fOnKeyCreate) then
  fOnKeyCreate(Self,Section,Key);
end;

//------------------------------------------------------------------------------

procedure TIFXFileNode.KeyDestroyHandler(Sender: TObject; Section: TIFXSectionNode; Key: TIFXKeyNode);
begin
If Assigned(fOnKeyDestroy) then
  fOnKeyDestroy(Self,Section,Key);
end;

//==============================================================================

constructor TIFXFileNode.Create(SettingsPtr: PIFXSettings);
begin
inherited Create;
SetLength(fSections,0);
fCount := 0;
fSettingsPtr := SettingsPtr;
fComment := '';
fOnKeyCreate := nil;
fOnKeyDestroy := nil;
fOnSectionCreate := nil;
fOnSectionDestroy := nil;
end;

//------------------------------------------------------------------------------

destructor TIFXFileNode.Destroy;
begin
Clear;
inherited;
end;
 
//------------------------------------------------------------------------------

Function TIFXFileNode.LowIndex: Integer;
begin
Result := Low(fSections);
end;
 
//------------------------------------------------------------------------------

Function TIFXFileNode.HighIndex: Integer;
begin
Result := Pred(fCount);
end;
 
//------------------------------------------------------------------------------

Function TIFXFileNode.IndexOfSection(const SectionName: String): Integer;
var
  i:    Integer;
  Temp: TIFXHashedString;
begin
Result := -1;
Temp := HashedString(SectionName);
For i := LowIndex to HighIndex do
  If SameHashString(fSections[i].Name,Temp) then
    begin
      Result := i;
      Break{For i};
    end;
end;
 
//------------------------------------------------------------------------------

Function TIFXFileNode.FindSection(const SectionName: String; out SectionNode: TIFXSectionNode): Boolean;
var
  Index:  Integer;
begin
Index := IndexOfSection(SectionName);
If Index >= 0 then
  begin
    SectionNode := fSections[Index];
    Result := True;
  end
else Result := False;
end;

//------------------------------------------------------------------------------

Function TIFXFileNode.FindSection(const SectionName: String): TIFXSectionNode;
begin
If not FindSection(SectionName,Result) then
  Result := nil;
end;

//------------------------------------------------------------------------------

Function TIFXFileNode.AddSection(const SectionName: String): Integer;
begin
Result := IndexOfSection(SectionName);
If Result < 0 then
  begin
    Grow;
    Result := fCount;
    fSections[Result] := TIFXSectionNode.Create(SectionName,fSettingsPtr);
    fSections[Result].OnKeyCreate := KeyCreateHandler;
    fSections[Result].OnKeyDestroy := KeyDestroyHandler;
    Inc(fCount);
    If Assigned(fOnSectionCreate) then
      fOnSectionCreate(Self,fSections[Result]);
  end;
end;

//------------------------------------------------------------------------------

procedure TIFXFileNode.ExchangeSections(Idx1, Idx2: Integer);
var
  Temp: TIFXSectionNode;
begin
If Idx1 <> Idx2 then
  begin
    If not CheckIndex(Idx1) then
      raise Exception.CreateFmt('TIFXFileNode.ExchangeSections: Idx1 (%d) out of bounds.',[Idx1]);
    If not CheckIndex(Idx2) then
      raise Exception.CreateFmt('TIFXFileNode.ExchangeSections: Idx2 (%d) out of bounds.',[Idx2]);
    Temp := fSections[Idx1];
    fSections[Idx1] := fSections[Idx2];
    fSections[Idx2] := Temp;
  end;
end;

//------------------------------------------------------------------------------

Function TIFXFileNode.RemoveSection(const SectionName: String): Integer;
begin
Result := IndexOfSection(SectionName);
If Result >= 0 then
  DeleteSection(Result);
end;

//------------------------------------------------------------------------------

procedure TIFXFileNode.DeleteSection(Index: Integer);
var
  i:  Integer;
begin
If CheckIndex(Index) then
  begin
    If Assigned(fOnSectionDestroy) then
      fOnSectionDestroy(Self,fSections[Index]);
    fSections[Index].Free;
    For i := Index to (fCount - 2) do
      fSections[i] := fSections[i + 1];
    Dec(fCount);
    Shrink;
  end
else raise Exception.CreateFmt('TIFXFileNode.DeleteSection: Index (%d) out of bounds.',[Index]);
end;
 
//------------------------------------------------------------------------------

procedure TIFXFileNode.ClearSections;
var
  i:  Integer;
begin
For i := HighIndex downto LowIndex do
  begin
    If Assigned(fOnSectionDestroy) then
      fOnSectionDestroy(Self,fSections[i]);
    fSections[i].Free;
  end;
fCount := 0;
Shrink;
end;

//------------------------------------------------------------------------------

procedure TIFXFileNode.SortSections(Reversed: Boolean = False);

  procedure QuickSort(Left,Right: Integer; Coef: Integer);
  var
    Pivot:  String;
    Idx,i:  Integer;
  begin
    If Left < Right  then
      begin
        ExchangeSections((Left + Right) shr 1,Right);
        Pivot := fSections[Right].NameStr;
        Idx := Left;
        For i := Left to Pred(Right) do
          If (AnsiCompareText(Pivot,fSections[i].NameStr) * Coef) > 0 then
            begin
              ExchangeSections(i,idx);
              Inc(Idx);
            end;
        ExchangeSections(Idx,Right);
        QuickSort(Left,Idx - 1,Coef);
        QuickSort(Idx + 1, Right,Coef);
      end;
  end;

begin
If fCount > 1 then
  If Reversed then QuickSort(LowIndex,HighIndex,-1)
    else QuickSort(LowIndex,HighIndex,1);
end;

//------------------------------------------------------------------------------

Function TIFXFileNode.IndexOfKey(const SectionName, KeyName: String): TIFXNodeIndices;
begin
Result := IFX_INVALID_NODE_INDICES;
Result.SectionIndex := IndexOfSection(SectionName);
If Result.SectionIndex >= 0 then
  Result.KeyIndex := fSections[Result.SectionIndex].IndexOfKey(KeyName);
end;

//------------------------------------------------------------------------------

Function TIFXFileNode.FindKey(const SectionName, KeyName: String; out KeyNode: TIFXKeyNode): Boolean;
var
  Section:  TIFXSectionNode;
begin
KeyNode := nil;
If FindSection(SectionName,Section) then
  Result := Section.FindKey(KeyName,KeyNode)
else
  Result := False;
end;

//------------------------------------------------------------------------------

Function TIFXFileNode.FindKey(const SectionName, KeyName: String): TIFXKeyNode;
begin
If not FindKey(SectionName,KeyName,Result) then
  Result := nil;
end;

//------------------------------------------------------------------------------

Function TIFXFileNode.AddKey(const SectionName, KeyName: String): TIFXNodeIndices;
begin
Result := IFX_INVALID_NODE_INDICES;
Result.SectionIndex := IndexOfSection(SectionName);
If Result.SectionIndex <= 0 then
  Result.SectionIndex := AddSection(SectionName);
Result.KeyIndex := fSections[Result.SectionIndex].IndexOfKey(KeyName);
If Result.KeyIndex < 0 then
  Result.KeyIndex := fSections[Result.SectionIndex].AddKey(KeyName);
end;

//------------------------------------------------------------------------------

procedure TIFXFileNode.ExchangeKeys(const SectionName: String; KeyIdx1, KeyIdx2: Integer);
var
  Section:  TIFXSectionNode;
begin
If FindSection(SectionName,Section) then
  Section.ExchangeKeys(KeyIdx1,KeyIdx2);
end;

//------------------------------------------------------------------------------

Function TIFXFileNode.RemoveKey(const SectionName, KeyName: String): TIFXNodeIndices;
begin
Result := IFX_INVALID_NODE_INDICES;
Result.SectionIndex := IndexOfSection(SectionName);
If Result.SectionIndex >= 0 then
  Result.KeyIndex := fSections[Result.SectionIndex].RemoveKey(KeyName);
end;

//------------------------------------------------------------------------------

procedure TIFXFileNode.DeleteKey(SectionIndex, KeyIndex: Integer);
begin
If CheckIndex(SectionIndex) then
  fSections[SectionIndex].DeleteKey(KeyIndex)
else
  raise Exception.CreateFmt('TIFXFileNode.DeleteKey: Section index (%d) out of bounds.',[SectionIndex]);
end;

//------------------------------------------------------------------------------

procedure TIFXFileNode.ClearKeys(const SectionName: String);
var
  Section:  TIFXSectionNode;
begin
If FindSection(SectionName,Section) then
  Section.ClearKeys;
end;

//------------------------------------------------------------------------------

procedure TIFXFileNode.SortKeys(const SectionName: String; Reversed: Boolean = False);
var
  Section:  TIFXSectionNode;
begin
If FindSection(SectionName,Section) then
  Section.SortKeys(Reversed);
end;

end.
