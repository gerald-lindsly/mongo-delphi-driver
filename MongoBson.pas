{
     Copyright 2009-2011 10gen Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
}

{ Use define OnDemandMongoCLoad if you want the MongoC.dll library to be loaded dynamically upon first use of a TMongo or
  TMongoReplset object }

{ This unit implements BSON, a binary JSON-like document format.
  It is used to represent documents in MongoDB and also for network traffic.
  See http://www.mongodb.org/display/DOCS/BSON }

unit MongoBson;

{$I MongoC_defines.inc}

interface

uses
  MongoAPI;

type
  IBsonIterator = interface;
  IBson = interface;
  TIntegerArray = array of Integer;
  TDoubleArray  = array of Double;
  TBooleanArray = array of Boolean;
  TStringArray  = array of AnsiString;
  {$IFNDEF DELPHI2007}
  PByte = ^Byte;
  {$ENDIF}

  PBsonOIDValue = ^TBsonOIDValue;
  TBsonOIDValue = array[0..11] of Byte;

  { A TBsonOID is used to store BSON Object IDs.
    See http://www.mongodb.org/display/DOCS/Object+IDs }
  IBsonOID = interface
    procedure setValue(const AValue: TBsonOIDValue);
    function getValue: PBsonOIDValue;
    { Convert this Object ID to a 24-digit hex string }
    function AsString: AnsiString;
    { the oid data }
    property Value : PBsonOIDValue read getValue;
  end;

  { A TBsonCodeWScope is used to hold javascript code and its associated scope.
    See TBsonIterator.getCodeWScope() }
  IBsonCodeWScope = interface
    function getCode: AnsiString;
    function getScope: IBson;
    procedure setCode(const ACode: AnsiString);
    procedure setScope(AScope: IBson);
    property Code : AnsiString read getCode write setCode;
    property Scope : IBson read getScope write setScope;
  end;

  { A TBsonRegex is used to hold a regular expression string and its options.
    See TBsonIterator.getRegex(). }
  IBsonRegex = interface
    function getPattern: AnsiString;
    function getOptions: AnsiString;
    procedure setPattern(const APattern: AnsiString);
    procedure setOptions(const AOptions: AnsiString);
    property Pattern : AnsiString read getPattern write setPattern;
    property Options : AnsiString read getOptions write setOptions;
  end;

  { A TBsonTimestamp is used to hold a TDateTime and an increment value.
    See http://www.mongodb.org/display/DOCS/Timestamp+data+type and
    TBsonIterator.getTimestamp() }
  IBsonTimestamp = interface
    function getTime: TDateTime;
    function getIncrement: Integer;
    procedure setTime(ATime: TDateTime);
    procedure setIncrement(AIncrement: Integer);
    property Time : TDateTime read getTime write setTime;
    property Increment : integer read getIncrement write setIncrement;
  end;

  { A TBsonBinary is used to hold the contents of BINDATA fields.
    See TBsonIterator.getBinary() }
  IBsonBinary = interface
    function getData: Pointer;
    function getLen: Integer;
    function getKind: Integer;
    procedure setData(AData: Pointer; ALen: Integer);
    procedure setKind(AKind: Integer);
    { Pointer to the data }
    property Data : Pointer read getData;
    { The length of the data in bytes }
    property Len : Integer read getLen;
    { The subtype of the BINDATA (usually 0) }
    property Kind : integer read getKind write setKind;
  end;

  { A TBsonBuffer is used to build a BSON document by appending the
    names and values of fields.  Call finish() when done to convert
    the buffer to a TBson which can be used in database operations.
    Example: @longcode(#
      var
        bb : TBsonBuffer;
        b  : TBson;
      begin
        bb := TBsonBuffer.Create();
        bb.append('name', 'Joe');
        bb.append('age', 33);
        bb.append('city', 'Boston');
        b := bb.finish();
      end;
    #) }
  IBsonBuffer = interface
    { Append a string (PAnsiChar) to the buffer }
    {$IFDEF DELPHI2009}
    function Append(Name: PAnsiChar; Value: PAnsiChar): Boolean; overload;
    {$ENDIF}
    function AppendStr(Name: PAnsiChar; Value: PAnsiChar): Boolean;
    { Append an Integer to the buffer }
    function Append(Name: PAnsiChar; Value: Integer): Boolean; overload;
    { Append an Int64 to the buffer }
    function Append(Name: PAnsiChar; Value: Int64): Boolean; overload;
    { Append a Double to the buffer }
    function Append(Name: PAnsiChar; Value: Double): Boolean; overload;
    { Append a TDateTime to the buffer; converted to 64-bit POSIX time }
    {$IFDEF DELPHI2009}
    function Append(Name: PAnsiChar; Value: TDateTime): Boolean; overload;
    {$ENDIF}
    function appendDate(Name: PAnsiChar; Value: TDateTime): Boolean;
    { Append a Boolean to the buffer }
    function Append(Name: PAnsiChar; Value: Boolean): Boolean; overload;
    { Append an Object ID to the buffer }
    function Append(Name: PAnsiChar; Value: IBsonOID): Boolean; overload;
    { Append a CODEWSCOPE to the buffer }
    function Append(Name: PAnsiChar; Value: IBsonCodeWScope): Boolean; overload;
    { Append a REGEX to the buffer }
    function Append(Name: PAnsiChar; Value: IBsonRegex): Boolean; overload;
    { Append a TIMESTAMP to the buffer }
    function Append(Name: PAnsiChar; Value: IBsonTimestamp): Boolean; overload;
    { Append BINDATA to the buffer }
    function Append(Name: PAnsiChar; Value: IBsonBinary): Boolean; overload;
    { Append a TBson document as a subobject }
    function Append(Name: PAnsiChar; Value: IBson): Boolean; overload;
    { Generic version of append.  Calls one of the other append functions
      if the type contained in the variant is supported. }
    {$IFDEF DELPHI2007}
    function Append(Name: PAnsiChar; const Value: Variant): Boolean; overload;
    {$ENDIF}
    function AppendVariant(Name: PAnsiChar; const Value: Variant): Boolean;
    { Append an array of Integers }
    function appendArray(Name: PAnsiChar; const Value: TIntegerArray): Boolean; overload;
    { Append an array of Double }
    function appendArray(Name: PAnsiChar; const Value: TDoubleArray): Boolean; overload;
    { Append an array of Booleans }
    function appendArray(Name: PAnsiChar; const Value: TBooleanArray): Boolean; overload;
    { Append an array of strings }
    function appendArray(Name: PAnsiChar; const Value: TStringArray): Boolean; overload;
    { Append a NULL field to the buffer }
    function appendNull(Name: PAnsiChar): Boolean;
    { Append an UNDEFINED field to the buffer }
    function appendUndefined(Name: PAnsiChar): Boolean;
    { Append javascript code to the buffer }
    function appendCode(Name: PAnsiChar; Value: PAnsiChar): Boolean;
     { Append a SYMBOL to the buffer }
    function appendSymbol(Name: PAnsiChar; Value: PAnsiChar): Boolean;
    { Alternate way to append BINDATA directly without first creating a
      TBsonBinary value }
    function appendBinary(Name: PAnsiChar; Kind: Integer; Data: Pointer; Length: Integer): Boolean;
    { Indicate that you will be appending more fields as a subobject }
    function startObject(Name: PAnsiChar): Boolean;
    { Indicate that you will be appending more fields as an array }
    function startArray(Name: PAnsiChar): Boolean;
    { Indicate that a subobject or array is done. }
    function finishObject: Boolean;
    { Return the current size of the BSON document you are building }
    function size: Integer;
    { Call this when finished appending fields to the buffer to turn it into
      a TBson for network transport. }
    function finish: IBson;
  end;

  { TBsonIterators are used to step through the fields of a TBson document. }
  IBsonIterator = interface
    function GetAsInt64: Int64;
    function getHandle: Pointer;
    { Get a TBsonBinary object for the BINDATA field pointed to by this
      iterator. }
    function getBinary: IBsonBinary;
    { Get an array of Booleans.  This iterator must point to ARRAY field
      which has each component type as Boolean }
    function getBooleanArray: TBooleanArray;
    { Get a TBsonCodeWScope object for a CODEWSCOPE field pointed to by this
      iterator. }
    function getCodeWScope: IBsonCodeWScope;
    { Get an array of Doubles.  This iterator must point to ARRAY field
      which has each component type as Double }
    function getDoubleArray: TDoubleArray;
    { Get an array of Integers.  This iterator must point to ARRAY field
      which has each component type as Integer }
    function getIntegerArray: TIntegerArray;
    { Get an Object ID from the field pointed to by this iterator. }
    function getOID: IBsonOID;
    { Get a TBsonRegex for a REGEX field }
    function getRegex: IBsonRegex;
    { Get an array of strings.  This iterator must point to ARRAY field
      which has each component type as string }
    function getStringArray: TStringArray;
    { Get a TBsonTimestamp object for a TIMESTAMP field pointed to by this
      iterator. }
    function getTimestamp: IBsonTimestamp;
    { Return the key (or name) of the field pointed to by this iterator. }
    function key: AnsiString;
    { Return the TBsonType of the field pointed to by this iterator. }
    function Kind: TBsonType;
    { Step to the first or next field of a TBson document.  Returns True
        if there is a next field; otherwise, returns false at the end of the
        document (or subobject).
        Example: @longcode(#
          iter := b.iterator;
          while i.next() do
             if i.kind = bsonNULL then
                WriteLn(i.key, ' is a NULL field.');
        #) }
    function Next: Boolean;
    { Get an TBsonIterator pointing to the first field of a subobject or array.
      kind() must be bsonOBJECT or bsonARRAY. }
    function subiterator: IBsonIterator;
    { Get the value of the field pointed to by this iterator.  This function
      does not support all BSON field types and will throw an exception for
      those it does not.  Use one of the 'get' functions to extract one of these
      special types. }
    function Value: Variant;
    property AsInt64: Int64 read GetAsInt64;
    { Pointer to externally managed data. }
    property Handle : Pointer read getHandle;
  end;

  { A TBson holds a BSON document.  BSON is a binary, JSON-like document format.
    It is used to represent documents in MongoDB and also for network traffic.
    See http://www.mongodb.org/display/DOCS/BSON   }
  IBson = interface
    { Display this BSON document on the console.  subobjects and arrays are
     appropriately indented. }
    procedure display;
    { Get a TBsonIterator that points to the field with the given name.
      If name is not found, nil is returned. }
    function find(Name: PAnsiChar): IBsonIterator;
    function getHandle: Pointer;
    { Get a TBsonIterator that points to the first field of this BSON }
    function iterator: IBsonIterator;
    { Return the size of this BSON document in bytes }
    function size: Integer;
    { Get the value of a field given its name.  This function does not support
      all BSON field types.  Use find() and one of the 'get' functions of
      TBsonIterator to retrieve special values. }
    function Value(Name: PAnsiChar): Variant;
    function ValueAsInt64(Name: PAnsiChar): Int64;
    { Pointer to externally managed data.  User code should not modify this.
      It is public only because the MongoDB and GridFS units must access it. }
    property Handle: Pointer read getHandle;
  end;

function MkIntArray(const Arr : array of Integer): TIntegerArray;
function MkDoubleArray(const Arr : array of Double): TDoubleArray;
function MkBoolArray(const Arr : array of Boolean): TBooleanArray;
function MkStrArray(const Arr : array of AnsiString): TStringArray;

(* The idea for this shorthand way to build a BSON
   document from an array of variants came from Stijn Sanders
   and his TMongoWire, located here:
   https://github.com/stijnsanders/TMongoWire

   Subobjects are started with '{' and ended with '}'

   Example: @longcode(#
     var b : TBson;
     begin
       b := BSON(['name', 'Albert', 'age', 64,
                   'address', '{',
                      'street', '109 Vine Street',
                      'city', 'New Haven',
                      '}' ]);
#) *)

function BSON(const x: array of Variant): IBson;

{ Create an empty TBsonBuffer ready to have fields appended. }
function NewBsonBuffer: IBsonBuffer;

{ Create a TBsonBinary from a pointer and a length.  The data
  is copied to the heap.  kind is initialized to 0 }
function NewBsonBinary(p: Pointer; Length: Integer): IBsonBinary; overload;
{ Create a TBsonBinary from a TBsonIterator pointing to a BINDATA
  field. }
function NewBsonBinary(i: IBsonIterator): IBsonBinary; overload;

{ Create a TBsonCodeWScope from a javascript string and a TBson scope }
function NewBsonCodeWScope(const acode: AnsiString; ascope: IBson): IBsonCodeWScope; overload;
{ Create a TBsonCodeWScope from a TBSonIterator pointing to a
  CODEWSCOPE field. }
function NewBsonCodeWScope(i: IBsonIterator): IBsonCodeWScope; overload;

{ Generate an Object ID }
function NewBsonOID: IBsonOID; overload;
{ Create an ObjectID from a 24-digit hex string }
function NewBsonOID(const s : AnsiString): IBsonOID; overload;
{ Create an Object ID from a TBsonIterator pointing to an oid field }
function NewBsonOID(i : IBsonIterator): IBsonOID; overload;

{ Create a TBsonRegex from reqular expression and options strings }
function NewBsonRegex(const apattern, aoptions: AnsiString): IBsonRegex; overload;
{ Create a TBsonRegex from a TBsonIterator pointing to a REGEX field }
function NewBsonRegex(i : IBsonIterator): IBsonRegex; overload;

{ Create a TBsonTimestamp from a TDateTime and an increment }
function NewBsonTimestamp(atime: TDateTime; aincrement: Integer): IBsonTimestamp; overload;
{ Create a TBSonTimestamp from a TBsonIterator pointing to a TIMESTAMP
  field. }
function NewBsonTimestamp(i : IBsonIterator): IBsonTimestamp; overload;

{ Internal usage only.  Create an uninitialized TBsonIterator }
function NewBsonIterator: IBsonIterator; overload;
{ Create a TBsonIterator that points to the first field of the given
  TBson }
function NewBsonIterator(ABson: IBson): IBsonIterator; overload;

{ Create a TBson given a pointer to externally managed data describing
  the document.  User code should not instantiate TBson directly.  Use
  TBsonBuffer and finish() to create BSON documents. }
function NewBson(AHandle: Pointer): IBson;

{ Convert a byte to a 2-digit hex string }
function ByteToHex(InByte: Byte): AnsiString;
function bsonEmpty: IBson;

{$IFDEF DELPHIXE2}
function Pos(const SubStr, Str: AnsiString): Integer;
function IntToStr(i : integer) : AnsiString;
{$ENDIF}

implementation

uses
  SysUtils, Variants, Windows, MongoDB;

resourcestring
// START resource string wizard section
  SIteratorHandleIsNil = 'Iterator Handle is nil';
  STBsonHandleIsNil = 'TBson handle is nil';
  {$IFNDEF DELPHI2007}
  SCanTAccessAnInt64UsingAVariantOn = 'Can''t access an Int64 using a variant on old version of Delphi. Use AsInt64 instead';
  {$ENDIF}
  SDatatypeNotSupported = 'Datatype not supported calling IterateAndFillArray';
  SExpectedA24DigitHexString = 'Expected a 24 digit hex string';
  SBsonType = 'BsonType (';
  SNotSupportedByTBsonIteratorValue = ') not supported by TBsonIterator.value';
  SIteratorDoesNotPointToAnArray = 'Iterator does not point to an array';
  SArrayComponentIsNotAnInteger = 'Array component is not an Integer';
  SArrayComponentIsNotADouble = 'Array component is not a Double';
  SArrayComponentIsNotAString = 'Array component is not a string';
  SArrayComponentIsNotABoolean = 'Array component is not a Boolean';
  SBsonBufferAlreadyFinished = 'BsonBuffer already finished';
  STBsonAppendVariantTypeNotSupport = 'TBson.append(variant): type not supported (';
  SUNDEFINED = 'UNDEFINED';
  SNULL = 'NULL';
  SCODEWSCOPE = 'CODEWSCOPE ';
  SBINARY = 'BINARY (';
  SUNKNOWN = 'UNKNOWN';
  SNilBSON = 'nil BSON';
  SBSONUnexpected = 'BSON(): unexpected "}"';
  SBSONExpectedValueFor = 'BSON(): expected value for ';
  SBSONOpenSubobject = 'BSON: open subobject';
// END resource string wizard section

const
  MONGOC_DLL = 'mongoc.dll';
  DATE_ADJUSTER = 25569;

type
  TBsonOID = class(TMongoInterfacedObject, IBsonOID)
  private
    Value: TBsonOIDValue;
  public
    constructor Create; overload;
    constructor Create(const s: AnsiString); overload;
    constructor Create(i: IBsonIterator); overload;
    function AsString: AnsiString;
    function getValue: PBsonOIDValue;
    procedure setValue(const AValue: TBsonOIDValue);
  end;

  TBsonBinary = class(TMongoInterfacedObject, IBsonBinary)
  private
    Data: Pointer;
    Len: Integer;
    Kind: Integer;
  public
    constructor Create(p: Pointer; Length: Integer); overload;
    constructor Create(i: IBsonIterator); overload;
    destructor Destroy; override;
    function getData: Pointer;
    function getKind: Integer;
    function getLen: Integer;
    procedure setData(AData: Pointer; ALen: Integer);
    procedure setKind(AKind: Integer);
  end;

  TBsonIterator = class(TMongoInterfacedObject, IBsonIterator)
  private
    Handle: Pointer;
    procedure CheckValidHandle;
    function GetAsInt64: Int64;
    procedure IterateAndFillArray(i: IBsonIterator; var Result; var j: Integer;
        BSonType: TBsonType);
    procedure PrepareArrayIterator(var i: IBsonIterator; var j, count: Integer;
        BSonType: TBsonType; const ATypeErrorMsg: AnsiString);
  public
    function getHandle: Pointer;
    function Kind: TBsonType;
    function key: AnsiString;
    function Next: Boolean;
    function Value: Variant;
    function subiterator: IBsonIterator;
    function getOID: IBsonOID;
    function getCodeWScope: IBsonCodeWScope;
    function getRegex: IBsonRegex;
    function getTimestamp: IBsonTimestamp;
    function getBinary: IBsonBinary;
    function getIntegerArray: TIntegerArray;
    function getDoubleArray: TDoubleArray;
    function getStringArray: TStringArray;
    function getBooleanArray: TBooleanArray;
    constructor Create; overload;
    constructor Create(b: IBson); overload;
    destructor Destroy; override;
  end;

  TBsonCodeWScope = class(TMongoInterfacedObject, IBsonCodeWScope)
  private
    code: AnsiString;
    scope: IBson;
  public
    constructor Create(const acode: AnsiString; ascope: IBson); overload;
    constructor Create(i: IBsonIterator); overload;
    function getCode: AnsiString;
    function getScope: IBson;
    procedure setCode(const ACode: AnsiString);
    procedure setScope(AScope: IBson);
  end;

  TBsonRegex = class(TMongoInterfacedObject, IBsonRegex)
  private
    pattern: AnsiString;
    options: AnsiString;
  public
    constructor Create(const apattern, aoptions: AnsiString); overload;
    constructor Create(i: IBsonIterator); overload;
    function getOptions: AnsiString;
    function getPattern: AnsiString;
    procedure setOptions(const AOptions: AnsiString);
    procedure setPattern(const APattern: AnsiString);
  end;

  TBsonTimestamp = class(TMongoInterfacedObject, IBsonTimestamp)
  private
    Time: TDateTime;
    increment: Integer;
  public
    constructor Create(atime: TDateTime; aincrement: Integer); overload;
    constructor Create(i: IBsonIterator); overload;
    function getIncrement: Integer;
    function getTime: TDateTime;
    procedure setIncrement(AIncrement: Integer);
    procedure setTime(ATime: TDateTime);
  end;

  TBsonBuffer = class(TMongoInterfacedObject, IBsonBuffer)
  private
    Handle: Pointer;
    function AppendIntCallback(i: Integer; const Arr): Boolean;
    function AppendDoubleCallback(i: Integer; const Arr): Boolean;
    function AppendBooleanCallback(i: Integer; const Arr): Boolean;
    function AppendStringCallback(i: Integer; const Arr): Boolean;
    procedure CheckBsonBuffer;
    function InternalAppendArray(Name: PAnsiChar; const Arr; Len: Integer; AppendElementCallback: Pointer): Boolean;
  public
    constructor Create;
    {$IFDEF DELPHI2009}
    function Append(Name: PAnsiChar; Value: PAnsiChar): Boolean; overload;
    {$EndIf}
    function AppendStr(Name: PAnsiChar; Value: PAnsiChar): Boolean;
    function Append(Name: PAnsiChar; Value: Integer): Boolean; overload;
    function Append(Name: PAnsiChar; Value: Int64): Boolean; overload;
    function Append(Name: PAnsiChar; Value: Double): Boolean; overload;
    {$IFDEF DELPHI2009}
    function Append(Name: PAnsiChar; Value: TDateTime): Boolean; overload;
    {$ENDIF}
    function appendDate(Name: PAnsiChar; Value: TDateTime): Boolean;
    function Append(Name: PAnsiChar; Value: Boolean): Boolean; overload;
    function Append(Name: PAnsiChar; Value: IBsonOID): Boolean; overload;
    function Append(Name: PAnsiChar; Value: IBsonCodeWScope): Boolean; overload;
    function Append(Name: PAnsiChar; Value: IBsonRegex): Boolean; overload;
    function Append(Name: PAnsiChar; Value: IBsonTimestamp): Boolean; overload;
    function Append(Name: PAnsiChar; Value: IBsonBinary): Boolean; overload;
    function Append(Name: PAnsiChar; Value: IBson): Boolean; overload;
    {$IFDEF DELPHI2007}
    function Append(Name: PAnsiChar; const Value: Variant): Boolean; overload;
    {$ENDIF}
    function AppendVariant(Name: PAnsiChar; const Value: Variant): Boolean;
    function appendArray(Name: PAnsiChar; const Value: TIntegerArray): Boolean; overload;
    function appendArray(Name: PAnsiChar; const Value: TDoubleArray): Boolean; overload;
    function appendArray(Name: PAnsiChar; const Value: TBooleanArray): Boolean; overload;
    function appendArray(Name: PAnsiChar; const Value: TStringArray): Boolean; overload;
    function appendNull(Name: PAnsiChar): Boolean;
    function appendUndefined(Name: PAnsiChar): Boolean;
    function appendCode(Name: PAnsiChar; Value: PAnsiChar): Boolean;
    function appendSymbol(Name: PAnsiChar; Value: PAnsiChar): Boolean;
    function appendBinary(Name: PAnsiChar; Kind: Integer; Data: Pointer; Length: Integer): Boolean;
    function startObject(Name: PAnsiChar): Boolean;
    function startArray(Name: PAnsiChar): Boolean;
    function finishObject: Boolean;
    function size: Integer;
    function finish: IBson;
    destructor Destroy; override;
  end;

  TBson = class(TMongoInterfacedObject, IBson)
  private
    FHandle: Pointer;
    procedure CheckHandle;
  protected
    function getHandle: Pointer;
  public
    function size: Integer;
    function iterator: IBsonIterator;
    function find(Name: PAnsiChar): IBsonIterator;
    function Value(Name: PAnsiChar): Variant;
    procedure display;
    function ValueAsInt64(Name: PAnsiChar): Int64;
    constructor Create(h: Pointer);
    destructor Destroy; override;
    property Handle: Pointer read getHandle;
  end;

{$IFDEF DELPHIXE2}
function Pos(const SubStr, Str: AnsiString): Integer;
begin
  Result := System.Pos(String(SubStr), String(Str));
end;

function IntToStr(i : integer) : AnsiString;
begin
  Result := AnsiString(SysUtils.IntToStr(i));
end;
{$ENDIF}

{ TBsonOID }

constructor TBsonOID.Create;
begin
  inherited Create;
  {$IFDEF OnDemandMongoCLoad}
  InitMongoDBLibrary;
  {$ENDIF}
  bson_oid_gen(@Value);
end;

constructor TBsonOID.Create(const s: AnsiString);
begin
  inherited Create;
  {$IFDEF OnDemandMongoCLoad}
  InitMongoDBLibrary;
  {$ENDIF}
  if Length(s) <> 24 then
    raise Exception.Create(SExpectedA24DigitHexString);
  bson_oid_from_string(@Value, PAnsiChar(s));
end;

constructor TBsonOID.Create(i: IBsonIterator);
var
  p: PByte;
begin
  inherited Create;
  {$IFDEF OnDemandMongoCLoad}
  InitMongoDBLibrary;
  {$ENDIF}
  p := bson_iterator_oid(i.getHandle);
  Move(p^, Value, 12);
end;

function TBsonOID.AsString: AnsiString;
var
  buf: array[0..24] of AnsiChar;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  bson_oid_to_string(@Value, @buf);
  Result := AnsiString(buf);
end;

function TBsonOID.getValue: PBsonOIDValue;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := @Value;
end;

procedure TBsonOID.setValue(const AValue: TBsonOIDValue);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Value := AValue;
end;

{ TBsonIterator }

constructor TBsonIterator.Create;
begin
  inherited Create;
  {$IFDEF OnDemandMongoCLoad}
  InitMongoDBLibrary;
  {$ENDIF}
  Handle := bson_iterator_create;
end;

constructor TBsonIterator.Create(b: IBson);
begin
  inherited Create;
  {$IFDEF OnDemandMongoCLoad}
  InitMongoDBLibrary;
  {$ENDIF}
  Handle := bson_iterator_create;
  bson_iterator_init(Handle, b.Handle);
end;

destructor TBsonIterator.Destroy;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if Handle <> nil then
    begin
      bson_iterator_dispose(Handle);
      Handle := nil;
    end;
  inherited;
end;

procedure TBsonIterator.CheckValidHandle;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if Handle = nil then
    raise EMongo.Create(SIteratorHandleIsNil);
end;

function TBsonIterator.GetAsInt64: Int64;
begin
  CheckValidHandle;
  Result := bson_iterator_long(Handle);
end;

function TBsonIterator.Kind: TBsonType;
begin
  CheckValidHandle;
  Result := bson_iterator_type(Handle);
end;

function TBsonIterator.Next: Boolean;
begin
  CheckValidHandle;
  Result := bson_iterator_next(Handle) <> bsonEOO;
end;

function TBsonIterator.key: AnsiString;
begin
  CheckValidHandle;
  Result := AnsiString(bson_iterator_key(Handle));
end;

function TBsonIterator.Value: Variant;
var
  k: TBsonType;
  d: TDateTime;
begin
  CheckValidHandle;
  k := Kind();
  case k of
    bsonEOO, bsonNULL:
      Result := Null;
    bsonUNDEFINED : VarClear(Result);
    bsonDOUBLE:
      Result := bson_iterator_double(Handle);
    bsonSTRING, bsonCODE, bsonSYMBOL:
      Result := AnsiString(bson_iterator_string(Handle));
    bsonINT:
      Result := bson_iterator_int(Handle);
    bsonBOOL:
      Result := bson_iterator_bool(Handle);
    bsonDATE:
      begin
        d := Int64toDouble(bson_iterator_date(Handle)) / (1000 * 24 * 60 * 60) + DATE_ADJUSTER;
        Result := d;
      end;
    bsonLONG:
      {$IFNDEF DELPHI2007}
      raise Exception.Create(SCanTAccessAnInt64UsingAVariantOn);
      {$ELSE}
      Result := bson_iterator_long(Handle);
      {$ENDIF}
    else raise Exception.Create(SBsonType + IntToStr(Ord(k)) + SNotSupportedByTBsonIteratorValue);
  end;
end;

function TBsonIterator.getOID: IBsonOID;
begin
  CheckValidHandle;
  Result := NewBsonOID(Self);
end;

function TBsonIterator.getCodeWScope: IBsonCodeWScope;
begin
  CheckValidHandle;
  Result := NewBsonCodeWScope(Self);
end;

function TBsonIterator.getRegex: IBsonRegex;
begin
  CheckValidHandle;
  Result := NewBsonRegex(Self);
end;

function TBsonIterator.getTimestamp: IBsonTimestamp;
begin
  CheckValidHandle;
  Result := NewBsonTimestamp(Self);
end;

function TBsonIterator.getBinary: IBsonBinary;
begin
  CheckValidHandle;
  Result := NewBsonBinary(Self);
end;

function TBsonIterator.subiterator: IBsonIterator;
var
  i: IBsonIterator;
begin
  CheckValidHandle;
  i := NewBsonIterator;
  bson_iterator_subiterator(Handle, i.getHandle);
  Result := i;
end;

function TBsonIterator.getIntegerArray: TIntegerArray;
var
  i: IBsonIterator;
  j, Count: Integer;
begin
  CheckValidHandle;
  PrepareArrayIterator(i, j, count, bsonINT, AnsiString(SArrayComponentIsNotAnInteger));
  SetLength(Result, Count);
  IterateAndFillArray(i, Result, j, bsonINT);
end;

function TBsonIterator.getDoubleArray: TDoubleArray;
var
  i: IBsonIterator;
  j, Count: Integer;
begin
  CheckValidHandle;
  PrepareArrayIterator(i, j, count, bsonDOUBLE, AnsiString(SArrayComponentIsNotADouble));
  SetLength(Result, Count);
  IterateAndFillArray(i, Result, j, bsonDOUBLE);
end;

function TBsonIterator.getStringArray: TStringArray;
var
  i: IBsonIterator;
  j, Count: Integer;
begin
  CheckValidHandle;
  PrepareArrayIterator(i, j, count, bsonSTRING, AnsiString(SArrayComponentIsNotAString));
  SetLength(Result, Count);
  IterateAndFillArray(i, Result, j, bsonSTRING);
end;

function TBsonIterator.getBooleanArray: TBooleanArray;
var
  i: IBsonIterator;
  j, Count: Integer;
begin
  CheckValidHandle;
  PrepareArrayIterator(i, j, count, bsonBOOL, AnsiString(SArrayComponentIsNotABoolean));
  SetLength(Result, Count);
  IterateAndFillArray(i, Result, j, bsonBOOL);
end;

function TBsonIterator.getHandle: Pointer;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := Handle;
end;

procedure TBsonIterator.IterateAndFillArray(i: IBsonIterator; var Result; var
    j: Integer; BSonType: TBsonType);
begin
  CheckValidHandle;
  while i.Next() do
  begin
    case BSonType of
      bsonDOUBLE : TDoubleArray(Result)[j] := i.Value;
      bsonSTRING : TStringArray(Result)[j] := AnsiString(i.Value);
      bsonBOOL : TBooleanArray(Result)[j] := i.Value;
      bsonINT : TIntegerArray(Result)[j] := i.Value;
      else raise Exception.Create(SDatatypeNotSupported);
    end;
    Inc(j);
  end;
end;

procedure TBsonIterator.PrepareArrayIterator(var i: IBsonIterator; var j,
    count: Integer; BSonType: TBsonType; const ATypeErrorMsg: AnsiString);
begin
  CheckValidHandle;
  if Kind <> bsonArray then
    raise Exception.Create(SIteratorDoesNotPointToAnArray);
  i := subiterator;
  Count := 0;
  while i.Next do
  begin
    if i.Kind <> BSonType then
      raise Exception.Create(ATypeErrorMsg);
    Inc(Count);
  end;
  i := subiterator;
  j := 0;
end;

{ TBsonBuffer }

constructor TBsonBuffer.Create;
begin
  inherited Create;
  {$IFDEF OnDemandMongoCLoad}
  InitMongoDBLibrary;
  {$ENDIF}
  Handle := bson_create;
  bson_init(Handle);
end;

destructor TBsonBuffer.Destroy;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if Handle <> nil then
    begin
      bson_destroy(Handle);
      bson_dispose(Handle);
      Handle := nil;
    end;
  inherited Destroy;
end;

{$IFDEF DELPHI2009}
function TBsonBuffer.Append(Name: PAnsiChar; Value: PAnsiChar): Boolean;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := AppendStr(Name, Value);
end;
{$EndIf}

function TBsonBuffer.AppendStr(Name: PAnsiChar; Value: PAnsiChar): Boolean;
begin
  CheckBsonBuffer;
  Result := (bson_append_string(Handle, Name, Value) = 0);
end;

function TBsonBuffer.appendCode(Name: PAnsiChar; Value: PAnsiChar): Boolean;
begin
  CheckBsonBuffer;
  Result := (bson_append_code(Handle, Name, Value) = 0);
end;

function TBsonBuffer.appendSymbol(Name: PAnsiChar; Value: PAnsiChar): Boolean;
begin
  CheckBsonBuffer;
  Result := (bson_append_symbol(Handle, Name, Value) = 0);
end;

function TBsonBuffer.Append(Name: PAnsiChar; Value: Integer): Boolean;
begin
  CheckBsonBuffer;
  Result := (bson_append_int(Handle, Name, Value) = 0);
end;

function TBsonBuffer.Append(Name: PAnsiChar; Value: Int64): Boolean;
begin
  CheckBsonBuffer;
  Result := (bson_append_long(Handle, Name, Value) = 0);
end;

function TBsonBuffer.Append(Name: PAnsiChar; Value: Double): Boolean;
begin
  CheckBsonBuffer;
  Result := (bson_append_double(Handle, Name, Value) = 0);
end;

{$IFDEF DELPHI2009}
function TBsonBuffer.Append(Name: PAnsiChar; Value: TDateTime): Boolean;
begin
  Result := AppendDate(Name, Value);
end;
{$ENDIF}

function TBsonBuffer.appendDate(Name: PAnsiChar; Value: TDateTime): Boolean;
begin
  CheckBsonBuffer;
  Result := (bson_append_date(Handle, Name, Trunc((Value - DATE_ADJUSTER) * 1000 * 60 * 60 * 24)) = 0);
end;

function TBsonBuffer.Append(Name: PAnsiChar; Value: Boolean): Boolean;
begin
  CheckBsonBuffer;
  Result := (bson_append_bool(Handle, Name, Value) = 0);
end;

function TBsonBuffer.Append(Name: PAnsiChar; Value: IBsonOID): Boolean;
begin
  CheckBsonBuffer;
  Result := (bson_append_oid(Handle, Name, Value.getValue) = 0);
end;

function TBsonBuffer.Append(Name: PAnsiChar; Value: IBsonCodeWScope): Boolean;
begin
  CheckBsonBuffer;
  Result := (bson_append_code_w_scope(Handle, Name, PAnsiChar(Value.getCode), Value.getScope.Handle) = 0);
end;

function TBsonBuffer.Append(Name: PAnsiChar; Value: IBsonRegex): Boolean;
begin
  CheckBsonBuffer;
  Result := (bson_append_regex(Handle, Name, PAnsiChar(Value.getPattern), PAnsiChar(Value.getOptions)) = 0);
end;

function TBsonBuffer.Append(Name: PAnsiChar; Value: IBsonTimestamp): Boolean;
begin
  CheckBsonBuffer;
  Result := (bson_append_timestamp2(Handle, Name, Trunc((Value.getTime - DATE_ADJUSTER) * 60 * 60 * 24), Value.getIncrement) = 0);
end;

function TBsonBuffer.Append(Name: PAnsiChar; Value: IBsonBinary): Boolean;
begin
  CheckBsonBuffer;
  Result := (bson_append_binary(Handle, Name, Value.getKind, Value.getData, Value.getLen) = 0);
end;

{$IFDEF DELPHI2007}
function TBsonBuffer.Append(Name: PAnsiChar; const Value: Variant): Boolean;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := AppendVariant(Name, Value);
end;
{$ENDIF}

function TBsonBuffer.AppendVariant(Name: PAnsiChar; const Value: Variant): Boolean;
var
  d: Double;
  {$IFDEF DELPHI2007}
  {$IFNDEF DELPHI2009}
  vint64 : Int64;
  {$ENDIF}
  {$ENDIF}
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  case VarType(Value) of
    varNull:
      Result := appendNull(Name);
    varByte, varInteger:
      Result := Append(Name, Integer(Value));
    varSingle, varDouble, varCurrency:
      begin
        d := Value;
        Result := Append(Name, d);
      end;
    varDate:
      Result := appendDate(Name, TDateTime(Value));
    {$IFDEF DELPHI2007}
    varInt64:
      begin
        {$IFDEF DELPHI2009}
        Result := Append(Name, Int64(Value));
        {$ELSE}
        vint64 := Value;
        Result := Append(Name, vint64);
        {$ENDIF}
      end;
    {$ENDIF}
    varBoolean:
      Result := Append(Name, Boolean(Value));
    varString, varOleStr {$IFDEF DELPHI2009}, varUString {$ENDIF}:
      Result := AppendStr(Name, PAnsiChar(AnsiString(Value)));
    else
      raise Exception.Create(STBsonAppendVariantTypeNotSupport +
        IntToStr(VarType(Value)) + ')');
  end;
end;

function TBsonBuffer.appendNull(Name: PAnsiChar): Boolean;
begin
  CheckBsonBuffer;
  Result := (bson_append_null(Handle, Name) = 0);
end;

function TBsonBuffer.appendUndefined(Name: PAnsiChar): Boolean;
begin
  CheckBsonBuffer;
  Result := (bson_append_undefined(Handle, Name) = 0);
end;

function TBsonBuffer.appendBinary(Name: PAnsiChar; Kind: Integer; Data: Pointer; Length: Integer): Boolean;
begin
  CheckBsonBuffer;
  Result := (bson_append_binary(Handle, Name, Kind, Data, Length) = 0);
end;

function TBsonBuffer.Append(Name: PAnsiChar; Value: IBson): Boolean;
begin
  CheckBsonBuffer;
  Result := (bson_append_bson(Handle, Name, Value.Handle) = 0);
end;

type
  TAppendElementCallback = function (i: Integer; const Arr): Boolean of object;

function TBsonBuffer.AppendIntCallback(i: Integer; const Arr): Boolean;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := bson_append_int(Handle, PAnsiChar(IntToStr(i)), TIntegerArray(Arr)[i]) = 0;
end;

function TBsonBuffer.AppendDoubleCallback(i: Integer; const Arr): Boolean;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := bson_append_double(Handle, PAnsiChar(IntToStr(i)), TDoubleArray(Arr)[i]) = 0;
end;

function TBsonBuffer.AppendBooleanCallback(i: Integer; const Arr): Boolean;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := bson_append_bool(Handle, PAnsiChar(IntToStr(i)), TBooleanArray(Arr)[i]) = 0;
end;

function TBsonBuffer.AppendStringCallback(i: Integer; const Arr): Boolean;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := bson_append_string(Handle, PAnsiChar(IntToStr(i)), PAnsiChar(TStringArray(Arr)[i])) = 0;
end;

function TBsonBuffer.InternalAppendArray(Name: PAnsiChar; const Arr; Len:
    Integer; AppendElementCallback: Pointer): Boolean;
var
  success: Boolean;
  i : Integer;
  AppendElementMethod : TAppendElementCallback;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  success := (bson_append_start_array(Handle, Name) = 0);
  i := 0;
  TMethod(AppendElementMethod).Data := Self;
  TMethod(AppendElementMethod).Code := AppendElementCallback;
  while success and (i < Len) do
  begin
    success := AppendElementMethod(i, Arr);
    Inc(i);
  end;
  if success then
    success := (bson_append_finish_object(Handle) = 0);
  Result := success;
end;

function TBsonBuffer.appendArray(Name: PAnsiChar; const Value: TIntegerArray): Boolean;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := InternalAppendArray(Name, Value, length(Value), @TBsonBuffer.AppendIntCallback);
end;

function TBsonBuffer.appendArray(Name: PAnsiChar; const Value: TDoubleArray): Boolean;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := InternalAppendArray(Name, Value, length(Value), @TBsonBuffer.AppendDoubleCallback);
end;

function TBsonBuffer.appendArray(Name: PAnsiChar; const Value: TBooleanArray): Boolean;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := InternalAppendArray(Name, Value, length(Value), @TBsonBuffer.AppendBooleanCallback);
end;

function TBsonBuffer.appendArray(Name: PAnsiChar; const Value: TStringArray): Boolean;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := InternalAppendArray(Name, Value, length(Value), @TBsonBuffer.AppendStringCallback);
end;

procedure TBsonBuffer.CheckBsonBuffer;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if Handle = nil then
    raise Exception.Create(SBsonBufferAlreadyFinished);
end;

function TBsonBuffer.startObject(Name: PAnsiChar): Boolean;
begin
  CheckBsonBuffer;
  Result := (bson_append_start_object(Handle, Name) = 0);
end;

function TBsonBuffer.startArray(Name: PAnsiChar): Boolean;
begin
  CheckBsonBuffer;
  Result := (bson_append_start_array(Handle, Name) = 0);
end;

function TBsonBuffer.finishObject: Boolean;
begin
  CheckBsonBuffer;
  Result := (bson_append_finish_object(Handle) = 0);
end;

function TBsonBuffer.size: Integer;
begin
  CheckBsonBuffer;
  Result := bson_buffer_size(Handle);
end;

function TBsonBuffer.finish: IBson;
begin
  CheckBsonBuffer;
  if bson_finish(Handle) = 0 then
  begin
    Result := NewBson(Handle);
    Handle := nil;
  end
  else
    Result := nil;
end;

{ TBson }

constructor TBson.Create(h: Pointer);
begin
  inherited Create;
  {$IFDEF OnDemandMongoCLoad}
  InitMongoDBLibrary;
  {$ENDIF}
  FHandle := h;
end;

destructor TBson.Destroy();
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if FHandle <> nil then
    begin
      bson_destroy(FHandle);
      bson_dispose(FHandle);
      FHandle := nil;
    end;
  inherited Destroy();
end;

function TBson.Value(Name: PAnsiChar): Variant;
var
  i: IBsonIterator;
begin
  i := find(Name);
  if i = nil then
    Result := Null
  else
    Result := i.Value;
end;

function TBson.iterator: IBsonIterator;
begin
  CheckHandle;
  Result := NewBsonIterator(Self);
end;

function TBson.size: Integer;
begin
  CheckHandle;
  Result := bson_size(FHandle);
end;

function TBson.find(Name: PAnsiChar): IBsonIterator;
var
  i: IBsonIterator;
begin
  CheckHandle;
  i := NewBsonIterator;
  if bson_find(i.getHandle, FHandle, Name) = bsonEOO then
    i := nil;
  Result := i;
end;

procedure _display(i: IBsonIterator; depth: Integer);
var
  t: TBsonType;
  j, k: Integer;
  cws: IBsonCodeWScope;
  regex: IBsonRegex;
  ts: IBsonTimestamp;
  bin: IBsonBinary;
  p: PByte;
begin
  while i.Next() do
  begin
    t := i.Kind();
    if t = bsonEOO then
      Break;
    for j := 1 to depth do
      Write('    ');
    Write(i.key, ' (', Ord(t), ') : ');
    case t of
      bsonDOUBLE,
      bsonSTRING, bsonSYMBOL, bsonCODE,
      bsonBOOL, bsonDATE, bsonINT, bsonLONG:
        Write(i.Value);
      bsonUNDEFINED:
        Write(SUNDEFINED);
      bsonNULL:
        Write(SNULL);
      bsonOBJECT, bsonARRAY:
        begin
          Writeln;
          _display(i.subiterator, depth + 1);
        end;
      bsonOID:
        Write(i.getOID().AsString());
      bsonCODEWSCOPE:
        begin
          Write(SCODEWSCOPE);
          cws := i.getCodeWScope();
          Writeln(cws.getCode);
          _display(cws.getScope.iterator, depth + 1);
        end;
      bsonREGEX:
        begin
          regex := i.getRegex();
          Write(regex.getPattern, ', ', regex.getOptions);
        end;
      bsonTIMESTAMP:
        begin
          ts := i.getTimestamp();
          Write(DateTimeToStr(ts.getTime), ' (', ts.getIncrement, ')');
        end;
      bsonBINDATA:
        begin
          bin := i.getBinary();
          Write(SBINARY, bin.getKind, ')');
          p := bin.getData;
          for j := 0 to bin.getLen - 1 do
          begin
            if j and 15 = 0 then
            begin
              Writeln;
              for k := 1 to depth + 1 do
                Write('    ');
            end;
            Write(ByteToHex(p^), ' ');
            Inc(p);
          end;
        end;
      else
        Write(SUNKNOWN);
    end;
    Writeln;
  end;
end;

procedure TBson.CheckHandle;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if FHandle = nil then
    raise EMongo.Create(STBsonHandleIsNil);
end;

procedure TBson.display;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if FHandle = nil then
    Writeln(SNilBSON)
  else
    _display(iterator, 0);
end;

function TBson.getHandle: Pointer;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := FHandle;
end;

function TBson.ValueAsInt64(Name: PAnsiChar): Int64;
var
  i: IBsonIterator;
begin
  i := find(Name);
  if i = nil then
    Result := 0
  else
    Result := i.AsInt64;
end;

{ TBsonCodeWScope }

constructor TBsonCodeWScope.Create(const acode: AnsiString; ascope: IBson);
begin
  inherited Create;
  {$IFDEF OnDemandMongoCLoad}
  InitMongoDBLibrary;
  {$ENDIF}
  code := acode;
  scope := ascope;
end;

constructor TBsonCodeWScope.Create(i: IBsonIterator);
var
  b, c: Pointer;
begin
  inherited Create;
  {$IFDEF OnDemandMongoCLoad}
  InitMongoDBLibrary;
  {$ENDIF}
  code := AnsiString(bson_iterator_code(i.getHandle));
  b := bson_create();
  try
    bson_iterator_code_scope(i.getHandle, b);
    c := bson_create();
    bson_copy(c, b);
    scope := NewBson(c);
  finally
    bson_dispose(b);
  end;
end;

function TBsonCodeWScope.getCode: AnsiString;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := Code;
end;

function TBsonCodeWScope.getScope: IBson;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := Scope;
end;

procedure TBsonCodeWScope.setCode(const ACode: AnsiString);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Code := ACode;
end;

procedure TBsonCodeWScope.setScope(AScope: IBson);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Scope := AScope;
end;

{ TBsonRegex }

constructor TBsonRegex.Create(const apattern, aoptions: AnsiString);
begin
  inherited Create;
  {$IFDEF OnDemandMongoCLoad}
  InitMongoDBLibrary;
  {$ENDIF}
  pattern := apattern;
  options := aoptions;
end;

constructor TBsonRegex.Create(i: IBsonIterator);
begin
  inherited Create;
  {$IFDEF OnDemandMongoCLoad}
  InitMongoDBLibrary;
  {$ENDIF}
  pattern := AnsiString(bson_iterator_regex(i.getHandle));
  options := AnsiString(bson_iterator_regex_opts(i.getHandle));
end;

function TBsonRegex.getOptions: AnsiString;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := Options;
end;

function TBsonRegex.getPattern: AnsiString;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := Pattern;
end;

procedure TBsonRegex.setOptions(const AOptions: AnsiString);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Options := AOptions;
end;

procedure TBsonRegex.setPattern(const APattern: AnsiString);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Pattern := APattern;
end;

{ TBsonTimestamp }

constructor TBsonTimestamp.Create(atime: TDateTime; aincrement: Integer);
begin
  inherited Create;
  {$IFDEF OnDemandMongoCLoad}
  InitMongoDBLibrary;
  {$ENDIF}
  Time := atime;
  increment := aincrement;
end;

constructor TBsonTimestamp.Create(i: IBsonIterator);
begin
  inherited Create;
  {$IFDEF OnDemandMongoCLoad}
  InitMongoDBLibrary;
  {$ENDIF}
  Time := bson_iterator_timestamp_time(i.getHandle) / (60 * 60 * 24) + DATE_ADJUSTER;
  increment := bson_iterator_timestamp_increment(i.getHandle);
end;

function TBsonTimestamp.getIncrement: Integer;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := Increment;
end;

function TBsonTimestamp.getTime: TDateTime;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := Time;
end;

procedure TBsonTimestamp.setIncrement(AIncrement: Integer);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Increment := AIncrement;
end;

procedure TBsonTimestamp.setTime(ATime: TDateTime);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Time := ATime;
end;

{ TBsonBinary }

constructor TBsonBinary.Create(p: Pointer; Length: Integer);
begin
  inherited Create;
  {$IFDEF OnDemandMongoCLoad}
  InitMongoDBLibrary;
  {$ENDIF}
  GetMem(Data, Length);
  Move(p^, Data^, Length);
  Kind := 0;
  Len := Length;
end;

constructor TBsonBinary.Create(i: IBsonIterator);
var
  p: Pointer;
begin
  inherited Create;
  {$IFDEF OnDemandMongoCLoad}
  InitMongoDBLibrary;
  {$ENDIF}
  Kind := bson_iterator_bin_type(i.getHandle);
  Len := bson_iterator_bin_len(i.getHandle);
  p := bson_iterator_bin_data(i.getHandle);
  GetMem(Data, Len);
  Move(p^, Data^, Len);
end;

destructor TBsonBinary.Destroy;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if Data <> nil then
    begin
      FreeMem(Data);
      Data := nil;
      Len := 0;
    end;
  inherited;
end;

function TBsonBinary.getData: Pointer;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := Data;
end;

function TBsonBinary.getKind: Integer;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := Kind;
end;

function TBsonBinary.getLen: Integer;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := Len;
end;

procedure TBsonBinary.setData(AData: Pointer; ALen: Integer);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if ALen > Len then
    ReallocMem(Data, ALen);
  Move(AData^, Data^, ALen);
  Len := ALen;
end;

procedure TBsonBinary.setKind(AKind: Integer);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Kind := AKind;
end;

function ByteToHex(InByte: Byte): AnsiString;
const
  digits: array[0..15] of AnsiChar = '0123456789ABCDEF';
begin
  Result := digits[InByte shr 4] + digits[InByte and $0F];
end;

{ BSON object builder function }

function BSON(const x: array of Variant): IBson;
var
  Len: Integer;
  i: Integer;
  bb: IBsonBuffer;
  depth: Integer;
  key: AnsiString;
  Value: AnsiString;
  Name: PAnsiChar;
begin
  bb := NewBsonBuffer;
  Len := Length(x);
  i := 0;
  depth := 0;
  while i < Len do
  begin
    key := AnsiString(VarToStr(x[i]));
    if key = '}' then
    begin
      if depth = 0 then
        raise Exception.Create(SBSONUnexpected);
      bb.finishObject();
      Dec(depth);
    end
    else
    begin
      Name := PAnsiChar(key);
      Inc(i);
      if i = Len then
        raise Exception.Create(SBSONExpectedValueFor + key);
      Value := AnsiString(VarToStr(x[i]));
      if Value = '{' then
      begin
        bb.startObject(Name);
        Inc(depth);
      end
      else
        bb.AppendVariant(Name, x[i]);
    end;
    Inc(i);
  end;
  if depth > 0 then
    raise Exception.Create(SBSONOpenSubobject);
  Result := bb.finish();
end;

{ Factory functions }

function NewBsonBinary(p: Pointer; Length: Integer): IBsonBinary; overload;
begin
  Result := TBsonBinary.Create(p, Length);
end;

function NewBsonBinary(i: IBsonIterator): IBsonBinary; overload;
begin
  Result := TBsonBinary.Create(i);
end;

function NewBsonCodeWScope(const acode: AnsiString; ascope: IBson): IBsonCodeWScope;
begin
  Result := TBsonCodeWScope.Create(acode, ascope);
end;

function NewBsonCodeWScope(i: IBsonIterator): IBsonCodeWScope; overload;
begin
  Result := TBsonCodeWScope.Create(i);
end;

function NewBsonOID: IBsonOID; overload;
begin
  Result := TBsonOID.Create;
end;

function NewBsonOID(const s : AnsiString): IBsonOID; overload;
begin
  Result := TBsonOID.Create(s);
end;

function NewBsonOID(i : IBsonIterator): IBsonOID; overload;
begin
  Result := TBsonOID.Create(i);
end;

function NewBsonRegex(const apattern, aoptions: AnsiString): IBsonRegex; overload;
begin
  Result := TBsonRegex.Create(apattern, aoptions);
end;

function NewBsonRegex(i : IBsonIterator): IBsonRegex; overload;
begin
  Result := TBsonRegex.Create(i);
end;

function NewBsonTimestamp(i : IBsonIterator): IBsonTimestamp; overload;
begin
  Result := TBsonTimestamp.Create(i);
end;

function NewBsonTimestamp(atime: TDateTime; aincrement: Integer):
    IBsonTimestamp; overload;
begin
  Result := TBsonTimestamp.Create(atime, aincrement);
end;

function NewBsonIterator: IBsonIterator; overload;
begin
  Result := TBsonIterator.Create;
end;

function NewBsonIterator(ABson: IBson): IBsonIterator;
begin
  Result := TBsonIterator.Create(ABson);
end;

function NewBsonBuffer: IBsonBuffer;
begin
  Result := TBsonBuffer.Create;
end;

function NewBson(AHandle: Pointer): IBson;
begin
  Result := TBson.Create(AHandle);
end;

var
  { An empty BSON document }
  absonEmpty: IBson;

function bsonEmpty: IBson;
begin
  if absonEmpty = nil then
    absonEmpty := BSON([]);
  Result := absonEmpty;
end;

{ Utility functions to create Dynamic Arrays from Open Array parameters }

function MkIntArray(const Arr : array of Integer): TIntegerArray;
{$i MongoBsonArrayBuilder.inc}

function MkDoubleArray(const Arr : array of Double): TDoubleArray;
{$i MongoBsonArrayBuilder.inc}

function MkBoolArray(const Arr : array of Boolean): TBooleanArray;
{$i MongoBsonArrayBuilder.inc}

function MkStrArray(const Arr : array of AnsiString): TStringArray;
{$i MongoBsonArrayBuilder.inc}

initialization
finalization
  absonEmpty := nil;
end.


