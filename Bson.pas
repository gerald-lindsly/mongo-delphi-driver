unit Bson;

interface
  type TBson = class;

  TBsonType = (
    bsonEOO = 0,
    bsonDOUBLE = 1,
    bsonSTRING = 2,
    bsonOBJECT = 3,
    bsonARRAY = 4,
    bsonBINDATA = 5,
    bsonUNDEFINED = 6,
    bsonOID = 7,
    bsonBOOL = 8,
    bsonDATE = 9,
    bsonNULL = 10,
    bsonREGEX = 11,
    bsonDBREF = 12, (* Deprecated. *)
    bsonCODE = 13,
    bsonSYMBOL = 14,
    bsonCODEWSCOPE = 15,
    bsonINT = 16,
    bsonTIMESTAMP = 17,
    bsonLONG = 18);

  TBsonIterator = class;

  TBsonOID = class(TObject)
    var
      value : array[0..11] of Byte;
    constructor Create(); overload;
    constructor Create(s : PAnsiChar); overload;
    constructor Create(i : TBsonIterator); overload;
    function AsString() : string;
  end;

  TBsonCodeWScope = class(TObject)
    var
      code : string;
      scope : TBson;
    constructor Create(code_ : string; scope_ : TBson); overload;
    constructor Create(i : TBsonIterator); overload;
  end;

  TBsonRegex = class(TObject)
    var
      pattern : string;
      options : string;
    constructor Create(pattern_ : string; options_ : string); overload;
    constructor Create(i : TBsonIterator); overload;
  end;

  TBsonTimestamp = class(TObject)
    var
      time : TDateTime;
      increment : Integer;
    constructor Create(time_ : TDateTime; increment_ : Integer); overload;
    constructor Create(i : TBsonIterator); overload;
  end;

  TBsonBinary = class(TObject)
    var
      data : Pointer;
      len  : Integer;
      kind : Integer;
    constructor Create(p : Pointer; length : Integer); overload;
    constructor Create(i : TBsonIterator); overload;
    destructor Destroy(); override;
  end;

  TBsonBuffer = class(TObject)
    private
      var handle : Pointer;
    public
      function append(name : PAnsiChar; value : PAnsiChar) : Boolean; overload;
      function append(name : PAnsiChar; value : Integer) : Boolean; overload;
      function append(name : PAnsiChar; value : Int64) : Boolean; overload;
      function append(name : PAnsiChar; value : Double) : Boolean; overload;
      function append(name : PAnsiChar; value : TDateTime) : Boolean; overload;
      function append(name : PAnsiChar; value : Boolean) : Boolean; overload;
      function append(name : PAnsiChar; value : TBsonOID) : Boolean; overload;
      function append(name : PAnsiChar; value : TBsonCodeWScope) : Boolean; overload;
      function append(name : PAnsiChar; value : TBsonRegex) : Boolean; overload;
      function append(name : PAnsiChar; value : TBsonTimestamp) : Boolean; overload;
      function append(name : PAnsiChar; value : TBsonBinary) : Boolean; overload;
      function appendCode(name : PAnsiChar; value : PAnsiChar) : Boolean;
      function appendSymbol(name : PAnsiChar; value : PAnsiChar) : Boolean;
      function appendBinary(name : PAnsiChar; kind : Integer; data : Pointer; length : Integer) : Boolean;
      function startObject(name : PAnsiChar) : Boolean;
      function startArray(name : PAnsiChar) : Boolean;
      function finishObject() : Boolean;
      function size() : Integer;
      function finish() : TBson;
      constructor Create();
      destructor Destroy(); override;
  end;

  TBson = class(TObject)
    private
       var handle : Pointer;
    public
      function size() : Integer;
      function iterator() : TBsonIterator;
      function find(name : PAnsiChar) : TBsonIterator;
      function value(name : PAnsiChar) : Variant;
      procedure display();
      constructor Create(h : Pointer);
      destructor Destroy; override;
  end;

  TBsonIterator = class(TObject)
    private
       var handle : Pointer;
    public
      function kind() : TBsonType;
      function key() : PAnsiChar;
      function next() : Boolean;
      function value() : Variant;
      function subiterator() : TBsonIterator;
      function getOID() : TBsonOID;
      function getCodeWScope() : TBsonCodeWScope;
      function getRegex() : TBsonRegex;
      function getTimestamp() : TBsonTimestamp;
      function getBinary() : TBsonBinary;
      constructor Create(); overload;
      constructor Create(b : TBson); overload;
      destructor Destroy; override;
    end;

    function ByteToHex(InByte : Byte) : string;

implementation
  uses SysUtils, Variants;

  function bson_create() : Pointer;  external 'mongoc.dll';
  procedure bson_init(b : Pointer);  cdecl; external 'mongoc.dll';
  procedure bson_destroy(b : Pointer); cdecl; external 'mongoc.dll';
  procedure bson_dispose(b : Pointer); cdecl; external 'mongoc.dll';
  procedure bson_copy(dest : Pointer; src : Pointer); cdecl; external 'mongoc.dll';
  function bson_finish(b : Pointer) : Integer; cdecl; external 'mongoc.dll';
  procedure bson_oid_gen(oid : Pointer); cdecl; external 'mongoc.dll';
  procedure bson_oid_to_string(oid : Pointer; s : PAnsiChar); cdecl; external 'mongoc.dll';
  procedure bson_oid_from_string(oid : Pointer; s : PAnsiChar); cdecl; external 'mongoc.dll';
  function bson_append_string(b : Pointer; name : PAnsiChar; value : PAnsiChar) : Integer;
    cdecl; external 'mongoc.dll';
  function bson_append_code(b : Pointer; name : PAnsiChar; value : PAnsiChar) : Integer;
    cdecl; external 'mongoc.dll';
  function bson_append_symbol(b : Pointer; name : PAnsiChar; value : PAnsiChar) : Integer;
    cdecl; external 'mongoc.dll';
  function bson_append_int(b : Pointer; name : PAnsiChar; value : Integer) : Integer;
    cdecl; external 'mongoc.dll';
  function bson_append_long(b : Pointer; name : PAnsiChar; value : Int64) : Integer;
    cdecl; external 'mongoc.dll';
  function bson_append_double(b : Pointer; name : PAnsiChar; value : Double) : Integer;
    cdecl; external 'mongoc.dll';
  function bson_append_date(b : Pointer; name : PAnsiChar; value : Int64) : Integer;
    cdecl; external 'mongoc.dll';
  function bson_append_bool(b : Pointer; name : PAnsiChar; value : Boolean) : Integer;
    cdecl; external 'mongoc.dll';
  function bson_append_start_object(b : Pointer; name : PAnsiChar) : Integer;
    cdecl; external 'mongoc.dll';
  function bson_append_start_array(b : Pointer; name : PAnsiChar) : Integer;
    cdecl; external 'mongoc.dll';
  function bson_append_finish_object(b : Pointer) : Integer; cdecl; external 'mongoc.dll';
  function bson_append_oid(b : Pointer; name : PAnsiChar; oid : Pointer) : Integer; cdecl; external 'mongoc.dll';
  function bson_append_code_w_scope(b : Pointer; name : PAnsiChar; code : PAnsiChar; scope : Pointer) : Integer;
    cdecl; external 'mongoc.dll';
  function bson_append_regex(b : Pointer; name : PAnsiChar; pattern : PAnsiChar; options : PAnsiChar) : Integer;
    cdecl; external 'mongoc.dll';
  function bson_append_timestamp2(b : Pointer; name : PAnsiChar; time : Integer; increment : Integer) : Integer;
    cdecl; external 'mongoc.dll';
  function bson_append_binary(b : Pointer; name : PAnsiChar; kind : Byte; data : Pointer; len : Integer) : Integer;
    cdecl; external 'mongoc.dll';
  function bson_buffer_size(b : Pointer) : Integer; cdecl; external 'mongoc.dll';
  function bson_size(b : Pointer) : Integer; cdecl; external 'mongoc.dll';
  function bson_iterator_create() : Pointer;  external 'mongoc.dll';
  procedure bson_iterator_dispose(i : Pointer);  external 'mongoc.dll';
  procedure bson_iterator_init(i : Pointer; b : Pointer); cdecl; external 'mongoc.dll';
  function bson_find(i : Pointer; b : Pointer; name : PAnsiChar) : TBsonType;
    cdecl; external 'mongoc.dll';
  function bson_iterator_type(i : Pointer) : TBsonType; cdecl; external 'mongoc.dll';
  function bson_iterator_next(i : Pointer) : TBsonType; cdecl; external 'mongoc.dll';
  function bson_iterator_key(i : Pointer) : PAnsiChar; cdecl; external 'mongoc.dll';
  function bson_iterator_double(i : Pointer) : Double; cdecl; external 'mongoc.dll';
  function bson_iterator_long(i : Pointer) : Int64; cdecl; external 'mongoc.dll';
  function bson_iterator_int(i : Pointer) : Integer; cdecl; external 'mongoc.dll';
  function bson_iterator_bool(i : Pointer) : Boolean; cdecl; external 'mongoc.dll';
  function bson_iterator_string(i : Pointer) : PAnsiChar; cdecl; external 'mongoc.dll';
  function bson_iterator_date(i : Pointer) : Int64; cdecl; external 'mongoc.dll';
  procedure bson_iterator_subiterator(i : Pointer; sub : Pointer);
    cdecl; external 'mongoc.dll';
  function bson_iterator_oid(i : Pointer) : Pointer; cdecl; external 'mongoc.dll';
  function bson_iterator_code(i : Pointer) : PAnsiChar; cdecl; external 'mongoc.dll';
  procedure bson_iterator_code_scope(i : Pointer; b : Pointer); cdecl; external 'mongoc.dll';
  function bson_iterator_regex(i : Pointer) : PAnsiChar; cdecl; external 'mongoc.dll';
  function bson_iterator_regex_opts(i : Pointer) : PAnsiChar; cdecl; external 'mongoc.dll';
  function bson_iterator_timestamp_time(i : Pointer) : Integer; cdecl; external 'mongoc.dll';
  function bson_iterator_timestamp_increment(i : Pointer) : Integer; cdecl; external 'mongoc.dll';
  function bson_iterator_bin_len(i : Pointer) : Integer;  cdecl; external 'mongoc.dll';
  function bson_iterator_bin_type(i : Pointer) : Byte;  cdecl; external 'mongoc.dll';
  function bson_iterator_bin_data(i : Pointer) : Pointer;  cdecl; external 'mongoc.dll';

  function Int64ToDouble(i64 : int64) : double; cdecl; external 'mongoc.dll';

  constructor TBsonOID.Create();
  begin
    bson_oid_gen(@value);
  end;

  constructor TBsonOID.Create(s : PAnsiChar);
  begin
    if length(s) <> 24 then
      Raise Exception.Create('Expected a 24 digit hex string');
    bson_oid_from_string(@value, s);
  end;

  constructor TBsonOID.Create(i : TBsonIterator);
  var
     p : PByte;
  begin
    p := bson_iterator_oid(i.handle);
    Move(p^, value, 12);
  end;

  function TBsonOID.AsString() : string;
  var
    buf : array[0..24] of AnsiChar;
  begin
    bson_oid_to_string(@value, @buf);
    Result := string(buf);
  end;

  constructor TBsonIterator.Create();
  begin
    inherited Create();
    handle := bson_iterator_create();
  end;

  constructor TBsonIterator.Create(b : TBson);
  begin
    inherited Create();
    handle := bson_iterator_create();
    bson_iterator_init(handle, b.handle);
  end;

  destructor TBsonIterator.Destroy;
  begin
    bson_iterator_dispose(handle);
  end;

  function TBsonIterator.kind() : TBsonType;
  begin
    Result := bson_iterator_type(handle);
  end;

  function TBsonIterator.next() : Boolean;
  begin
    Result := bson_iterator_next(handle) <> bsonEOO;
  end;

  function TBsonIterator.key() : PAnsiChar;
  begin
    Result := bson_iterator_key(handle);
  end;

  function TBsonIterator.value() : Variant;
    var
      k : TBsonType;
      d : TDateTime;
  begin
    k := kind();
    case k of
      bsonEOO, bsonNULL : Result := Null;
      bsonDOUBLE: Result := bson_iterator_double(handle);
      bsonSTRING, bsonCODE, bsonSYMBOL:
          Result := string(bson_iterator_string(handle));
      bsonINT: Result := bson_iterator_int(handle);
      bsonBOOL: Result := bson_iterator_bool(handle);
      bsonDATE: begin
           d := Int64ToDouble(bson_iterator_date(handle)) / (1000 * 24 * 60 * 60) + 25569;
           Result := d;
      end;
      bsonLONG: Result := bson_iterator_long(handle);
      else
        Raise Exception.Create('BsonType (' + IntToStr(Ord(k)) + ') not supported by TBsonIterator.value');
    end;
  end;

  function TBsonIterator.getOID() : TBsonOID;
  begin
    Result := TBsonOID.Create(Self);
  end;

  function TBsonIterator.getCodeWScope() : TBsonCodeWScope;
  begin
    Result := TBsonCodeWScope.Create(Self);
  end;

  function TBsonIterator.getRegex() : TBsonRegex;
  begin
    Result := TBsonRegex.Create(Self);
  end;

  function TBsonIterator.getTimestamp() : TBsonTimestamp;
  begin
    Result := TBsonTimestamp.Create(Self);
  end;

  function TBsonIterator.getBinary() : TBsonBinary;
  begin
    Result := TBsonBinary.Create(Self);
  end;

  function TBsonIterator.subiterator() : TBsonIterator;
  var
    i : TBsonIterator;
  begin
    i := TBsonIterator.Create();
    bson_iterator_subiterator(handle, i.handle);
    Result := i;
  end;

  function TBson.value(name: PAnsiChar) : Variant;
    var
      i : TBsonIterator;
  begin
    i := find(name);
    if i = nil then
      Result := Null
    else
      Result := i.value;
  end;

  function TBson.iterator() : TBsonIterator;
  begin
    Result := TBsonIterator.Create(Self);
  end;

  constructor TBsonBuffer.Create();
    begin
      inherited Create();
      handle := bson_create();
      bson_init(handle);
    end;

  destructor TBsonBuffer.Destroy();
    begin
      bson_destroy(handle);
      bson_dispose(handle);
      inherited Destroy();
    end;

  function TBsonBuffer.append(name: PAnsiChar; value: PAnsiChar) : Boolean;
  begin
    if handle = nil then
      raise Exception.Create('BsonBuffer already finished');
    Result := (bson_append_string(handle, name, value) = 0);
  end;

  function TBsonBuffer.appendCode(name: PAnsiChar; value: PAnsiChar) : Boolean;
  begin
    if handle = nil then
      raise Exception.Create('BsonBuffer already finished');
    Result := (bson_append_code(handle, name, value) = 0);
  end;

  function TBsonBuffer.appendSymbol(name: PAnsiChar; value: PAnsiChar) : Boolean;
  begin
    if handle = nil then
      raise Exception.Create('BsonBuffer already finished');
    Result := (bson_append_symbol(handle, name, value) = 0);
  end;

  function TBsonBuffer.append(name: PAnsiChar; value: Integer) : Boolean;
  begin
    if handle = nil then
      raise Exception.Create('BsonBuffer already finished');
    Result := (bson_append_int(handle, name, value) = 0);
  end;

  function TBsonBuffer.append(name: PAnsiChar; value: Int64) : Boolean;
  begin
    if handle = nil then
      raise Exception.Create('BsonBuffer already finished');
    Result := (bson_append_long(handle, name, value) = 0);
  end;

  function TBsonBuffer.append(name: PAnsiChar; value: Double) : Boolean;
  begin
    if handle = nil then
      raise Exception.Create('BsonBuffer already finished');
    Result := (bson_append_double(handle, name, value) = 0);
  end;

  function TBsonBuffer.append(name: PAnsiChar; value: TDateTime) : Boolean;
  begin
    if handle = nil then
      raise Exception.Create('BsonBuffer already finished');
    Result := (bson_append_date(handle, name, Trunc((value - 25569) * 1000 * 60 * 60 * 24)) = 0);
  end;

  function TBsonBuffer.append(name: PAnsiChar; value: Boolean) : Boolean;
  begin
    if handle = nil then
      raise Exception.Create('BsonBuffer already finished');
    Result := (bson_append_bool(handle, name, value) = 0);
  end;

  function TBsonBuffer.append(name: PAnsiChar; value: TBsonOID) : Boolean;
  begin
    if handle = nil then
      raise Exception.Create('BsonBuffer already finished');
    Result := (bson_append_oid(handle, name, @value.value) = 0);
  end;

  function TBsonBuffer.append(name: PAnsiChar; value: TBsonCodeWScope) : Boolean;
  begin
    if handle = nil then
      raise Exception.Create('BsonBuffer already finished');
    Result := (bson_append_code_w_scope(handle, name, PAnsiChar(AnsiString(value.code)), value.scope.handle) = 0);
  end;

  function TBsonBuffer.append(name: PAnsiChar; value: TBsonRegex) : Boolean;
  begin
    if handle = nil then
      raise Exception.Create('BsonBuffer already finished');
    Result := (bson_append_regex(handle, name, PAnsiChar(AnsiString(value.pattern)), PAnsiChar(AnsiString(value.options))) = 0);
  end;

  function TBsonBuffer.append(name: PAnsiChar; value: TBsonTimestamp) : Boolean;
  begin
    if handle = nil then
      raise Exception.Create('BsonBuffer already finished');
    Result := (bson_append_timestamp2(handle, name, Trunc((value.time - 25569) * 60 * 60 * 24), value.increment) = 0);
  end;

  function TBsonBuffer.append(name: PAnsiChar; value: TBsonBinary) : Boolean;
  begin
    if handle = nil then
      raise Exception.Create('BsonBuffer already finished');
    Result := (bson_append_binary(handle, name, value.kind, value.data, value.len) = 0);
  end;

  function TBsonBuffer.appendBinary(name : PAnsiChar; kind : Integer; data : Pointer; length : Integer) : Boolean;
  begin
    if handle = nil then
      raise Exception.Create('BsonBuffer already finished');
    Result := (bson_append_binary(handle, name, kind, data, length) = 0);
  end;

  function TBsonBuffer.startObject(name: PAnsiChar) : Boolean;
  begin
    if handle = nil then
      raise Exception.Create('BsonBuffer already finished');
    Result := (bson_append_start_object(handle, name) = 0);
  end;

  function TBsonBuffer.startArray(name: PAnsiChar) : Boolean;
  begin
    if handle = nil then
      raise Exception.Create('BsonBuffer already finished');
    Result := (bson_append_start_array(handle, name) = 0);
  end;

  function TBsonBuffer.finishObject() : Boolean;
  begin
    if handle = nil then
      raise Exception.Create('BsonBuffer already finished');
    Result := (bson_append_finish_object(handle) = 0);
  end;

  function TBsonBuffer.size() : Integer;
  begin
    if handle = nil then
      raise Exception.Create('BsonBuffer already finished');
    Result := bson_buffer_size(handle);
  end;

  function TBsonBuffer.finish() : TBson;
  begin
    if handle = nil then
      raise Exception.Create('BsonBuffer already finished');
    if bson_finish(handle) = 0 Then begin
        Result := TBson.Create(handle);
        handle := nil;
      end
    else
      Result := nil;
  end;

  constructor TBson.Create(h : Pointer);
  begin
    handle := h;
  end;

  destructor TBson.Destroy();
    begin
      bson_destroy(handle);
      bson_dispose(handle);
      inherited Destroy();
    end;

  function TBson.size() : Integer;
  begin
    Result := bson_size(handle);
  end;

  function TBson.find(name : PAnsiChar) : TBsonIterator;
  var
    i : TBsonIterator;
  begin
    i := TBsonIterator.Create();
    if bson_find(i.handle, handle, name) = bsonEOO Then
      i := nil;
    Result := i;
  end;

  procedure _display(i : TBsonIterator; depth : Integer);
  var
    t : TBsonType;
    j,k : Integer;
    cws : TBsonCodeWScope;
    regex : TBsonRegex;
    ts : TBsonTimestamp;
    bin : TBsonBinary;
    p : PByte;
  begin
      while i.next() do begin
          t := i.kind();
          if t = bsonEOO then
              break;
          for j:= 1 To depth do
              Write('    ');
          Write(i.key, ' (', Ord(t), ') : ');
          case t of
              bsonDOUBLE,
              bsonSTRING, bsonSYMBOL, bsonCODE,
              bsonBOOL, bsonDATE, bsonINT, bsonLONG :
                  Write(i.value);
              bsonUNDEFINED :
                  Write('UNDEFINED');
              bsonNULL :
                  Write('NULL');
              bsonOBJECT, bsonARRAY : begin
                  Writeln;
                  _display(i.subiterator, depth+1);
              end;
              bsonOID : write(i.getOID().AsString());
              bsonCODEWSCOPE : begin
                  Write('CODEWSCOPE ');
                  cws := i.getCodeWScope();
                  WriteLn(cws.code);
                  _display(cws.scope.iterator, depth+1);
              end;
              bsonREGEX: begin
                  regex := i.getRegex();
                  write(regex.pattern, ', ', regex.options);
              end;
              bsonTIMESTAMP: begin
                  ts := i.getTimestamp();
                  write(DateTimeToStr(ts.time), ' (', ts.increment, ')');
              end;
              bsonBINDATA: begin
                  bin := i.getBinary();
                  Write('BINARY (', bin.kind, ')');
                  p := bin.data;
                  for j := 0 to bin.len-1 do begin
                    if j and 15 = 0 then begin
                      WriteLn;
                      for k := 1 To depth+1 do
                        Write('    ');
                    end;
                    write(ByteToHex(p^), ' ');
                    Inc(p);
                  end;
              end;
          else
              Write('UNKNOWN');
          end;
          Writeln;
      end;
  end;

  procedure TBson.display();
  begin
    _display(iterator, 0);
  end;

  constructor TBsonCodeWScope.Create(code_ : string; scope_ : TBson);
  begin
    code := code_;
    scope := scope_;
  end;

  constructor TBsonCodeWScope.Create(i : TBsonIterator);
  var
    b, c : Pointer;
  begin
    code := string(bson_iterator_code(i.handle));
    b := bson_create();
    bson_iterator_code_scope(i.handle, b);
    c := bson_create();
    bson_copy(c, b);
    scope := TBson.Create(c);
    bson_dispose(b);
  end;

  constructor TBsonRegex.Create(pattern_ : string; options_ : string);
  begin
    pattern := pattern_;
    options := options_;
  end;

  constructor TBsonRegex.Create(i : TBsonIterator);
  begin
     pattern := string(bson_iterator_regex(i.handle));
     options := string(bson_iterator_regex_opts(i.handle));
  end;


  constructor TBsonTimestamp.Create(time_ : TDateTime; increment_ : Integer);
  begin
    time := time_;
    increment := increment_;
  end;

  constructor TBsonTimestamp.Create(i : TBsonIterator);
  begin
    time := bson_iterator_timestamp_time(i.handle) / (60.0 * 60 * 24) + 25569;
    increment := bson_iterator_timestamp_increment(i.handle);
  end;

  constructor TBsonBinary.Create(p: Pointer; length: Integer);
  begin
    GetMem(data, length);
    Move(p^, data^, length);
    kind := 0;
  end;

  constructor TBsonBinary.Create(i : TBsonIterator);
  var
    p : Pointer;
  begin
    kind := bson_iterator_bin_type(i.handle);
    len := bson_iterator_bin_len(i.handle);
    p := bson_iterator_bin_data(i.handle);
    GetMem(data, len);
    Move(p^, data^, len);
  end;

  destructor TBsonBinary.Destroy;
  begin
    FreeMem(data);
  end;

  function ByteToHex(InByte : Byte) : string;
  const digits : array[0..15] of Char = '0123456789ABCDEF';
  begin
    result := digits[InByte shr 4] + digits[InByte and $0F];
  end;

end.
