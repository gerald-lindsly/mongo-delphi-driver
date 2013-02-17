unit uStack;

interface

uses
  Variants, SysUtils;

type
  EStack = Exception;
  IStack = interface
    ['{F5B77BC4-2D8D-41C0-853F-A1864F7364B8}'] // do not localize
    function GetCapacity: Cardinal;
    function GetEmpty: Boolean;
    function GetGrowCapacityBy: Cardinal;
    function GetSize: Cardinal;
    function Peek: Variant;
    function Pop: Variant;
    function Push(const AValue: Variant): Variant;
    procedure SetCapacity(const Value: Cardinal);
    procedure SetGrowCapacityBy(const Value: Cardinal);
    procedure SetSize(const Value: Cardinal);
    property Capacity: Cardinal read GetCapacity write SetCapacity;
    property Empty: Boolean read GetEmpty;
    property GrowCapacityBy: Cardinal read GetGrowCapacityBy write SetGrowCapacityBy;
    property Size: Cardinal read GetSize write SetSize;
  end;

function NewStack(AInitialSize : Cardinal = 8): IStack;

implementation

// START resource string wizard section
resourcestring
  SCanTPeekStackEmpty = 'Can''t Peek. Stack empty';
  SCanTPopStackEmpty = 'Can''t Pop. Stack empty';
// END resource string wizard section


type
  TStack = class(TInterfacedObject, IStack)
  private
    FStack : array of Variant;
    FCurrentPosition: Integer;
    FGrowCapacityBy: Cardinal;
    function GetCapacity: Cardinal;
    function GetEmpty: Boolean;
    function GetGrowCapacityBy: Cardinal;
    procedure SetCapacity(const Value: Cardinal);
    procedure SetGrowCapacityBy(const Value: Cardinal);
    function GetSize: Cardinal;
    procedure SetSize(const Value: Cardinal);
  public
    constructor Create(AInitialSize: Cardinal = 8);
    function Peek: Variant;
    function Pop: Variant;
    function Push(const AValue: Variant): Variant;
    property Capacity: Cardinal read GetCapacity write SetCapacity;
    property Empty: Boolean read GetEmpty;
    property GrowCapacityBy: Cardinal read GetGrowCapacityBy write SetGrowCapacityBy default 8;
    property Size: Cardinal read GetSize write SetSize;
  end;

constructor TStack.Create(AInitialSize: Cardinal = 8);
begin
  inherited Create;
  SetLength(FStack, AInitialSize);
  FCurrentPosition := -1;
  FGrowCapacityBy := 8;
end;

function TStack.GetCapacity: Cardinal;
begin
  Result := length(FStack);
end;

function TStack.GetEmpty: Boolean;
begin
  Result := FCurrentPosition < 0;
end;

function TStack.GetGrowCapacityBy: Cardinal;
begin
  Result := FGrowCapacityBy;
end;

function TStack.GetSize: Cardinal;
begin
  Result := FCurrentPosition + 1;
end;

function TStack.Peek: Variant;
begin
  if Empty then
    raise EStack.Create(SCanTPeekStackEmpty);
  Result := FStack[FCurrentPosition];
end;

function TStack.Pop: Variant;
begin
  if Empty then
    raise EStack.Create(SCanTPopStackEmpty);
  Result := FStack[FCurrentPosition];
  dec(FCurrentPosition);
end;

function TStack.Push(const AValue: Variant): Variant;
begin
  inc(FCurrentPosition);
  if FCurrentPosition >= length(FStack) then
    SetLength(FStack, length(FStack) + integer(GrowCapacityBy));
  FStack[FCurrentPosition] := AValue;
  Result := AValue;
end;

procedure TStack.SetCapacity(const Value: Cardinal);
begin
  SetLength(FStack, Value);
  if FCurrentPosition >= integer(Value) then
    FCurrentPosition := Value - 1;
end;

procedure TStack.SetGrowCapacityBy(const Value: Cardinal);
begin
  FGrowCapacityBy := Value;
end;

procedure TStack.SetSize(const Value: Cardinal);
begin
  FCurrentPosition := Value - 1;
end;

function NewStack(AInitialSize : Cardinal = 8): IStack;
begin
  Result := TStack.Create(AInitialSize);
end;

end.

