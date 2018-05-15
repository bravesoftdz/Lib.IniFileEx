unit IniFileEx;

{$INCLUDE '.\IniFileEx_defs.inc'}

interface

uses
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

  {$IFDEF AllowLowLevelAccess}
    Function GetSectionNode(const Section: TIFXString): TIFXSectionNode; virtual;
    Function GetKeyNode(const Section, Key: TIFXString): TIFXKeyNode; virtual;
    Function GetValueString(const Section, Key: TIFXString): TIFXString; virtual;
    procedure SetValueString(const Section, Key, ValueStr: TIFXString); virtual;
    property FileNode: TIFXFileNode read fFileNode;
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

procedure TIniFileEx.SectionCreateHandler(Sender: TObject; Section: TIFXSectionNode);
begin
If Assigned(fOnSectionCreate) then
  fOnSectionCreate(Self,Section);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SectionDestroyHandler(Sender: TObject; Section: TIFXSectionNode);
begin
If Assigned(fOnSectionDestroy) then
  fOnSectionDestroy(Self,Section);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.KeyCreateHandler(Sender: TObject; Section: TIFXSectionNode; Key: TIFXKeyNode);
begin
If Assigned(fOnKeyCreate) then
  fOnKeyCreate(Self,Section,Key);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.KeyDestroyHandler(Sender: TObject; Section: TIFXSectionNode; Key: TIFXKeyNode);
begin
If Assigned(fOnKeyDestroy) then
  fOnKeyDestroy(Self,Section,Key);
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

{$IFDEF AllowLowLevelAccess}

Function TIniFileEx.GetSectionNode(const Section: TIFXString): TIFXSectionNode;
begin
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetKeyNode(const Section, Key: TIFXString): TIFXKeyNode;
begin
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetValueString(const Section, Key: TIFXString): TIFXString;
begin
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SetValueString(const Section, Key, ValueStr: TIFXString);
begin
end;

{$ENDIF}
end.
