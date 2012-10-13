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
  TMongoReplset object

  VERY IMPORTANT!!! If MongoC was compiled with memory protection you have to define MONGO_MEMORY_PROTECTION to compile this file
  otherwise WriteConcerns are not going to work }

{ This unit implements the TMongo connection class for connecting to a MongoDB server
  and performing database operations on that server. }

unit MongoDB;

interface

{$I MongoC_defines.inc}

uses
  MongoBson, SysUtils, MongoAPI;

const
  updateUpsert = 1;
  updateMulti = 2;
  updateBasic = 4;

  indexUnique = 1;
  indexDropDups = 4;
  indexBackground = 8;
  indexSparse = 16;

  { Create a tailable cursor. }
  cursorTailable = 2;
  { Allow queries on a non-primary node. }
  cursorSlaveOk = 4;
  { Disable cursor timeouts. }
  cursorNoTimeout = 16;
  { Momentarily block for more data. }
  cursorAwaitData = 32;
  { Stream in multiple 'more' packages. }
  cursorExhaust = 64;
  { Allow reads even if a shard is down. }
  cursorPartial = 128;

type
  IMongoCursor = interface;
  IWriteConcern = interface;

  EMongo = class(Exception);

  { TMongo objects establish a connection to a MongoDB server and are
    used for subsequent database operations on that server. }
  TMongo = class(TMongoObject)
  private
    FAutoCheckLastError: Boolean;
    FWriteConcern: IWriteConcern;
    procedure CheckHandle;
  protected
      { Pointer to externally managed data describing the connection.
        User code should not access this.  It is public only for
        access from the GridFS unit. }
    fhandle: Pointer;
    procedure InitMongo(const AHost: AnsiString); virtual;
    procedure parseNamespace(const ns: AnsiString; var db: AnsiString; var Collection: AnsiString);
  public
    procedure autoCheckCmdLastError(const ns: AnsiString; ANeedsParsing: Boolean);
    procedure autoCmdResetLastError(const ns: AnsiString; ANeedsParsing: Boolean);
      { Create a TMongo connection object.  A connection is attempted on the
        MongoDB server running on the localhost '127.0.0.1:27017'.
        Check isConnected() to see if it was successful. }
    constructor Create; overload;
      { Create a TMongo connection object.  The host[:port] to connect to is given
        as the host string. port defaults to 27017 if not given.
        Check the result of isConnected() to see if it was successful. }
    constructor Create(const host: AnsiString); overload;
      { Determine whether this TMongo is currently connected to a MongoDB server.
        Returns True if connected; False, if not. }
    function isConnected: Boolean;
      { Check the connection.  This returns True if isConnected() and the server
        responded to a 'ping'; otherwise, False. }
    function checkConnection: Boolean;
    { Return True if the server reports that it is a master; otherwise, False. }
    function isMaster: Boolean;
      { Temporarirly disconnect from the server.  The connection may be reestablished
        by calling reconnect.  This works on both normal connections and replsets. }
    procedure disconnect;
      { Reconnect to the MongoDB server after having called disconnect to suspend
        operations. }
    function reconnect: Boolean;
      { Get an error code indicating the reason a connection or network communication
        failed. See mongo-c-driver/src/mongo.h and mongo_error_t. }
    function getErr: Integer;
      { Set the timeout in milliseconds of a network operation.  The default of 0
        indicates that there is no timeout. }
    function setTimeout(millis: Integer): Boolean;
      { Get the network operation timeout value in milliseconds.  The default of 0
        indicates that there is no timeout. }
    function getTimeout: Integer;
    { Get the host:post of the primary server that this TMongo is connected to. }
    function getPrimary: AnsiString;
    { Get the TCP/IP socket number being used for network communication }
    function getSocket: Integer;
    { Get a list of databases from the server as an array of string }
    function getDatabases: TStringArray;
      { Given a database name as a string, get the namespaces of the collections
        in that database as an array of string. }
    function getDatabaseCollections(const db: AnsiString): TStringArray;
      { Rename a collection.  from_ns is the current namespace of the collection
        to be renamed.  to_ns is the target namespace.
        The collection namespaces (from_ns, to_ns) are in the form 'database.collection'.
        Returns True if successful; otherwise, False.  Note that this function may
        be used to move a collection from one database to another. }
    function Rename(const from_ns, to_ns: AnsiString): Boolean;
      { Drop a collection.  Removes the collection of the given name from the server.
        Exercise care when using this function.
        The collection namespace (ns) is in the form 'database.collection'. }
    function drop(const ns: AnsiString): Boolean;
      { Drop a database.  Removes the entire database of the given name from the server.
        Exercise care when using this function. }
    function dropDatabase(const db: AnsiString): Boolean;
      { Insert a document into the given namespace.
        The collection namespace (ns) is in the form 'database.collection'.
        See http://www.mongodb.org/display/DOCS/Inserting.
        Returns True if successful; otherwise, False. }
    function Insert(const ns: AnsiString; b: IBson): Boolean; overload;
      { Insert a batch of documents into the given namespace (collection).
        The collection namespace (ns) is in the form 'database.collection'.
        See http://www.mongodb.org/display/DOCS/Inserting.
        Returns True if successful; otherwise, False. }
    function Insert(const ns: AnsiString; const bs: array of IBson): Boolean; overload;
      { Perform an update on the server.  The collection namespace (ns) is in the
        form 'database.collection'.  criteria indicates which records to update
        and objNew gives the replacement document.
        See http://www.mongodb.org/display/DOCS/Updating.
        Returns True if successful; otherwise, False. }
    function Update(const ns: AnsiString; criteria, objNew: IBson): Boolean; overload;
      { Perform an update on the server.  The collection namespace (ns) is in the
        form 'database.collection'.  criteria indicates which records to update
        and objNew gives the replacement document. flags is a bit mask containing update
        options; updateUpsert, updateMulti, or updateBasic.
        See http://www.mongodb.org/display/DOCS/Updating.
        Returns True if successful; otherwise, False. }
    function Update(const ns: AnsiString; criteria, objNew: IBson; flags: Integer): Boolean; overload;
      { Remove documents from the server.  The collection namespace (ns) is in the
        form 'database.collection'.  Documents that match the given criteria
        are removed from the collection.
        See http://www.mongodb.org/display/DOCS/Removing.
        Returns True if successful; otherwise, False. }
    function remove(const ns: AnsiString; criteria: IBson): Boolean;
      { Find the first document in the given namespace that matches a query.
        See http://www.mongodb.org/display/DOCS/Querying
        The collection namespace (ns) is in the form 'database.collection'.
        Returns the document as a IBson if found; otherwise, nil. }
    function findOne(const ns: AnsiString; query: IBson): IBson; overload;
      { Find the first document in the given namespace that matches a query.
        See http://www.mongodb.org/display/DOCS/Querying
        The collection namespace (ns) is in the form 'database.collection'.
        A subset of the documents fields to be returned is specified in fields.
        This can cut down on network traffic.
        Returns the document as a IBson if found; otherwise, nil. }
    function findOne(const ns: AnsiString; query, fields: IBson): IBson; overload;
      { Issue a query to the database.
        See http://www.mongodb.org/display/DOCS/Querying
        Requires a TMongoCursor that is used to specify optional parameters to
        the find and to step through the result set.
        The collection namespace (ns) is in the form 'database.collection'.
        Returns true if the query was successful and at least one document is
        in the result set; otherwise, false.
        Optionally, set other members of the TMongoCursor before calling
        find.  The TMongoCursor must be destroyed after finishing with a query.
        Instatiate a new cursor for another query.
        Example: @longcode(#
          var cursor : TMongoCursor;
          begin
          (* This finds all documents in the collection that have
             name equal to 'John' and steps through them. *)
            cursor := TMongoCursor.Create(BSON(['name', 'John']));
            if mongo.find(ns, cursor) then
              while cursor.next() do
                (* Do something with cursor.value() *)
          (* This finds all documents in the collection that have
             age equal to 32, but sorts them by name. *)
            cursor := TMongoCursor.Create(BSON(['age', 32]));
            cursor.sort := BSON(['name', True]);
            if mongo.find(ns, cursor) then
              while cursor.next() do
                (* Do something with cursor.value() *)
          end;
        #) }
    function find(const ns: AnsiString; Cursor: IMongoCursor): Boolean;
      { Return the count of all documents in the given namespace.
        The collection namespace (ns) is in the form 'database.collection'. }
    function Count(const ns: AnsiString): Double; overload;
      { Return the count of all documents in the given namespace that match
        the given query.
        The collection namespace (ns) is in the form 'database.collection'. }
    function Count(const ns: AnsiString; query: IBson): Double; overload;
      { Create an index for the given collection so that accesses by the given
        key are faster.
        The collection namespace (ns) is in the form 'database.collection'.
        key is the name of the field on which to index.
        Returns nil if successful; otherwise, a IBson document that describes the error. }
    function distinct(const ns, key: AnsiString): IBson;
      { Returns a BSON document containing a field 'values' which
        is an array of the distinct values of the key in the given collection (ns).
        Example:
          var
             b : IBson;
             names : TStringArray;
          begin
             b := mongo.distinct('test.people', 'name');
             names := b.find('values').GetStringArray();
          end
      }
    function indexCreate(const ns, key: AnsiString): IBson; overload;
      { Create an index for the given collection so that accesses by the given
        key are faster.
        The collection namespace (ns) is in the form 'database.collection'.
        key is the name of the field on which to index.
        options specifies a bit mask of indexUnique, indexDropDups, indexBackground,
        and/or indexSparse.
        Returns nil if successful; otherwise, a IBson document that describes the error. }
    function indexCreate(const ns, key: AnsiString; options: Integer): IBson; overload;
      { Create an index for the given collection so that accesses by the given
        key are faster.
        The collection namespace (ns) is in the form 'database.collection'.
        key is a IBson document that (possibly) defines a compound key.
        For example, @longcode(#
          mongo.indexCreate(ns, BSON(['age', True, 'name', True]));
          (* speed up accesses of documents by age and then name *)
        #)
        Returns nil if successful; otherwise, a IBson document that describes the error. }
    function indexCreate(const ns: AnsiString; key: IBson): IBson; overload;
      { Create an index for the given collection so that accesses by the given
        key are faster.
        The collection namespace (ns) is in the form 'database.collection'.
        key is a IBson document that (possibly) defines a compound key.
        For example, @longcode(#
          mongo.indexCreate(ns, BSON(['age', True, 'name', True]));
          (* speed up accesses of documents by age and then name *)
        #)
        options specifies a bit mask of indexUnique, indexDropDups, indexBackground,
        and/or indexSparse.
        Returns nil if successful; otherwise, a IBson document that describes the error. }
    function indexCreate(const ns: AnsiString; key: IBson; options: Integer): IBson; overload;
      { Add a user name / password to the 'admin' database.  This may be authenticated
        with the authenticate function.
        See http://www.mongodb.org/display/DOCS/Security+and+Authentication }
    function addUser(const Name, password: AnsiString): Boolean; overload;
      { Add a user name / password to the given database.  This may be authenticated
        with the authenticate function.
        See http://www.mongodb.org/display/DOCS/Security+and+Authentication }
    function addUser(const Name, password, db: AnsiString): Boolean; overload;
      { Authenticate a user name / password with the 'admin' database.
        See http://www.mongodb.org/display/DOCS/Security+and+Authentication }
    function authenticate(const Name, password: AnsiString): Boolean; overload;
      { Authenticate a user name / password with the given database.
        See http://www.mongodb.org/display/DOCS/Security+and+Authentication }
    function authenticate(const Name, password, db: AnsiString): Boolean; overload;
      { Issue a command to the server.  This supports all commands by letting you
        specify the command object as a IBson document.
        If successful, the response from the server is returned as a IBson document;
        otherwise, nil is returned.
        See http://www.mongodb.org/display/DOCS/List+of+Database+Commands }
    function command(const db: AnsiString; command: IBson): IBson; overload;
      { Issue a command to the server.  This version of the command() function
        supports that subset of commands which may be described by a cmdstr and
        an argument.
        If successful, the response from the server is returned as a IBson document;
        otherwise, nil is returned.
        See http://www.mongodb.org/display/DOCS/List+of+Database+Commands }
    function command(const db, cmdstr: AnsiString; const arg: Variant): IBson; overload;
      { Get the last error reported by the server.  Returns a IBson document describing
        the error if there was one; otherwise, nil. }
    function getLastErr(const db: AnsiString): IBson;
      { Get the previous error reported by the server.  Returns a IBson document describing
        the error if there was one; otherwise, nil. }
    function getPrevErr(const db: AnsiString): IBson;
      { Reset the error status of the server.  After calling this function, both
        getLastErr() and getPrevErr() will return nil. }
    procedure resetErr(const db: AnsiString);
      { Get the server error code.  As a convenience, this is saved here after calling
        getLastErr() or getPrevErr(). }
    function getServerErr: Integer;
      { Get the server error string.  As a convenience, this is saved here after calling
        getLastErr() or getPrevErr(). }
    function getServerErrString: AnsiString;
    { Get the specified database last error Bson object }
    function cmdGetLastError(const db: AnsiString): IBson;
    { Resets the specified database error state }
    procedure cmdResetLastError(const db: AnsiString);
      { Sets de default write concern for the connection. Pass nil on AWriteConcern to set a NULL write concern
        at the driver level }
    procedure setWriteConcern(AWriteConcern: IWriteConcern);
      { Destroy this TMongo object.  Severs the connection to the server and releases
        external resources. }
    destructor Destroy; override;
    property AutoCheckLastError: Boolean read FAutoCheckLastError write FAutoCheckLastError;
    property Handle: Pointer read FHandle;
  end;

    { TMongoReplset is a superclass of the TMongo connection class that implements
      a different constructor and several functions for connecting to a replset. }
  TMongoReplset = class(TMongo)
  protected
    procedure InitMongo(const AHost: AnsiString); override;
  public
      { Create a TMongoReplset object given the replset name.  Unlike the constructor
        for TMongo, this does not yet establish the connection.  Call addSeed() for each
        of the seed hosts and then call Connect to connect to the replset. }
    constructor Create(const Name: AnsiString);
      { Add a seed to the replset.  The host string should be in the form 'host[:port]'.
        port defaults to 27017 if not given/
        After constructing a TMongoReplset, call this for each seed and then call
        Connect(). }
    procedure addSeed(const host: AnsiString);
      { Connect to the replset.  The seeds added with addSeed() are polled to determine
        if they belong to the replset name given to the constructor.  Their hosts
        are then polled to determine the master to connect to.
        Returns True if it successfully connected; otherwise, False. }
    function Connect: Boolean;
    { Get the number of hosts reported by the seeds }
    function getHostCount: Integer;
    { Get the Ith host as a 'host:port' string. }
    function getHost(i: Integer): AnsiString;
  end;

  { Objects of interface IMongoCursor are used with TMongo.find() to specify
    optional parameters of the find and also to step though the result set.
    A IMongoCursor object is also returned by GridFS.TGridfile.getChunks() which
    is used to step through the chunks of a gridfile. }
  IMongoCursor = interface
    procedure FindCalled; // Internal. This is to flag a cursor that it was used in a Find operation
    function GetConn: TMongo;
    function GetFields: IBson;
    function GetHandle: Pointer;
    function GetLimit: Integer;
    function GetOptions: Integer;
    function GetQuery: IBson;
    function GetSkip: Integer;
    function GetSort: IBson;
    { Step to the first or next document in the result set.
        Returns True if there was a first or next document; otherwise,
        returns False when there are no more documents. }
    function Next: Boolean;
    procedure SetConn(const Value: TMongo);
    procedure SetFields(const Value: IBson);
    procedure SetHandle(const Value: Pointer);
    procedure SetLimit(const Value: Integer);
    procedure SetOptions(const Value: Integer);
    procedure SetQuery(const Value: IBson);
    procedure SetSkip(const Value: Integer);
    procedure SetSort(const Value: IBson);
    { Return the current document of the result set }
    function Value: IBson;
    { hold ref to the TMongo object of the find.  Prevents release of the
      TMongo object until after this cursor is destroyed. }
    property Conn: TMongo read GetConn write SetConn;
    { A IBson document listing those fields to be included in the result set.
      This can be used to cut down on network traffic. Defaults to nil \
      (returns all fields of matching documents). }
    property Fields: IBson read GetFields write SetFields;
    { Pointer to externally managed data.  User code should not modify this. }
    property Handle: Pointer read GetHandle write SetHandle;
    { Specifies a limiting count on the number of documents returned. The
      default of 0 indicates no limit on the number of records returned.}
    property Limit: Integer read GetLimit write SetLimit;
    { Specifies cursor options.  A bit mask of cursorTailable, cursorSlaveOk,
      cursorNoTimeout, cursorAwaitData, cursorExhaust , and/or cursorPartial.
      Defaults to 0 - no special handling. }
    property Options: Integer read GetOptions write SetOptions;
    { A IBson document describing the query.
     See http://www.mongodb.org/display/DOCS/Querying }
    property Query: IBson read GetQuery write SetQuery;
    { Specifies the number of matched documents to skip. Default is 0. }
    property Skip: Integer read GetSkip write SetSkip;
    { A IBson document describing the sort to be applied to the result set.
      See the example for TMongo.find().  Defaults to nil (no sort). }
    property Sort: IBson read GetSort write SetSort;
  end;

  IWriteConcern = interface
    { See http://api.mongodb.org/c/0.6/write_concern.html for details on the meaning of
      each property. The propery names are mapped to the actual C structure in purpose to
      keep consistency with C driver meanings }
    function Getfinished: Boolean;
    function Getfsync: Integer;
    function GetHandle: Pointer;
    function Getj: Integer;
    function Getmode: AnsiString;
    function Getw: Integer;
    function Getwtimeout: Integer;
    procedure Setfsync(const Value: Integer);
    procedure Setj(const Value: Integer);
    procedure Setmode(const Value: AnsiString);
    procedure Setw(const Value: Integer);
    procedure Setwtimeout(const Value: Integer);
    { Always call finish after you are done setting all writeconcern fields, otherwise
      you can't use the writeconcern object with TMongo object.
      The call to finish is equivalent to mongo_write_concern_finish() }
    procedure finish;
    property fsync: Integer read Getfsync write Setfsync;
    property j: Integer read Getj write Setj;
    property mode: AnsiString read Getmode write Setmode;
    property w: Integer read Getw write Setw;
    property wtimeout: Integer read Getwtimeout write Setwtimeout;
    property Handle: Pointer read GetHandle;
    property finished: Boolean read Getfinished;
  end;

  { Create a cursor with a empty query (which matches everything) }
function NewMongoCursor: IMongoCursor; overload;
  { Create a cursor with the given query. }
function NewMongoCursor(query: IBson): IMongoCursor; overload;
  { Create a WriteConcern object to be used as default write concern for the Mongo connection }
function NewWriteConcern: IWriteConcern;

implementation

uses
  Windows {$IFDEF DELPHIXE2}, AnsiStrings {$ENDIF};

// START resource string wizard section
const
  S27017 = ':27017';
  MongoCDLL = 'mongoc.dll';
  S127001 = '127.0.0.1';
  SAdmin = 'admin';
  SListDatabases = 'listDatabases';
  SLocal = 'local';
  SSystemNamespaces = '.system.namespaces';
  SName = 'name';
  SSystem = '.system.';
  SRenameCollection = 'renameCollection';
  STo = 'to';
  SQuery = '$query';
  SSort = '$orderby';
  SDistinct = 'distinct';
  SKey = 'key';
  SReseterror = 'reseterror';
  // END resource string wizard section

  // START resource string wizard section
resourcestring
  SMongoHandleIsNil = 'Mongo handle is nil';
  SCanTUseAnUnfinishedWriteConcern = 'Can''t use an unfinished WriteConcern';
  {$IFDEF OnDemandMongoCLoad}
  SFailedLoadingMongocDll = 'Failed loading mongoc.dll';
  SFunctionNotFoundOnMongoCLibrary = 'Function "%s" not found on MongoC library';
  {$ENDIF}
  STMongoDropExpectedAInTheNamespac = 'TMongo.drop: expected a ''.'' in the namespace.';
  SExpectedAInTheNamespace = 'Expected a ''.'' in the namespace';
  // END resource string wizard section

type
  Tmongo_write_concern = record
    {$IFDEF MONGO_MEMORY_PROTECTION}
    mongo_sig: Integer;
    {$ENDIF}
    w: Integer;
    wtimeout: Integer;
    j: Integer;
    fsync: Integer;
    mode: PAnsiChar;
    cmd: Pointer;
  end;

procedure parseHost(const host: AnsiString; var hosturl: AnsiString; var port: Integer);
var
  i: Integer;
begin
  i := Pos(':', host);
  if i = 0 then
  begin
    hosturl := host;
    port := 27017;
  end
  else
  begin
    hosturl := Copy(host, 1, i - 1);
    port := StrToInt(Copy(host, i + 1, Length(host) - i));
  end;
end;

type
  TMongoCursor = class(TMongoInterfacedObject, IMongoCursor)
  private
    FFindCalledFlag: Boolean;
    FHandle: Pointer;
    fquery: IBson;
    fSort: IBson;
    ffields: IBson;
    flimit: Integer;
    fskip: Integer;
    foptions: Integer;
    fconn: TMongo;
    procedure CheckHandle;
    function GetConn: TMongo;
    function GetFields: IBson;
    function GetHandle: Pointer;
    function GetLimit: Integer;
    function GetOptions: Integer;
    function GetQuery: IBson;
    function GetSkip: Integer;
    function GetSort: IBson;
    procedure Init;
    procedure SetConn(const Value: TMongo);
    procedure SetFields(const Value: IBson);
    procedure SetHandle(const Value: Pointer);
    procedure SetLimit(const Value: Integer);
    procedure SetOptions(const Value: Integer);
    procedure SetQuery(const Value: IBson);
    procedure SetSkip(const Value: Integer);
    procedure SetSort(const Value: IBson);
  protected
    procedure DestroyCursor;
  public
    constructor Create; overload;
    constructor Create(aquery: IBson); overload;
    function Next: Boolean;
    function Value: IBson;
    destructor Destroy; override;
    procedure FindCalled;
    property Conn: TMongo read GetConn write SetConn;
    property Fields: IBson read GetFields write SetFields;
    property FindCalledFlag: Boolean read FFindCalledFlag write FFindCalledFlag;
    property Handle: Pointer read GetHandle write SetHandle;
    property Limit: Integer read GetLimit write SetLimit;
    property Options: Integer read GetOptions write SetOptions;
    property Query: IBson read GetQuery write SetQuery;
    property Skip: Integer read GetSkip write SetSkip;
    property Sort: IBson read GetSort write SetSort;
  end;

  TWriteConcern = class(TMongoInterfacedObject, IWriteConcern)
  private
    FMode: AnsiString;
    FWriteConcern: Tmongo_write_concern;
    FFinished: Boolean;
    procedure finish;
    function Getfsync: Integer;
    function GetHandle: Pointer;
    function Getj: Integer;
    function Getmode: AnsiString;
    function Getw: Integer;
    function Getwtimeout: Integer;
    function Getfinished: Boolean;
    procedure Modified;
    procedure Setfsync(const Value: Integer);
    procedure Setj(const Value: Integer);
    procedure Setmode(const Value: AnsiString);
    procedure Setw(const Value: Integer);
    procedure Setwtimeout(const Value: Integer);
  public
    constructor Create;
    destructor Destroy; override;
  end;

  { TMongo }

constructor TMongo.Create;
begin
  inherited Create;
  {$IFDEF OnDemandMongoCLoad}
  InitMongoDBLibrary;
  {$ENDIF}
  AutoCheckLastError := true;
  InitMongo(S127001 + S27017);
end;

constructor TMongo.Create(const host: AnsiString);
begin
  inherited Create;
  {$IFDEF OnDemandMongoCLoad}
  InitMongoDBLibrary;
  {$ENDIF}
  AutoCheckLastError := true;
  if host = ''
    then InitMongo(S127001 + S27017)
    else InitMongo(host);
end;

destructor TMongo.Destroy;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if fhandle <> nil then
  begin
    mongo_destroy(fhandle);
    mongo_dispose(fhandle);
    fhandle := nil;
  end;
  inherited;
end;

constructor TMongoReplset.Create(const Name: AnsiString);
begin
  inherited Create(Name);
end;

procedure TMongoReplset.addSeed(const host: AnsiString);
var
  hosturl: AnsiString;
  port: Integer;
begin
  CheckHandle;
  parseHost(host, hosturl, port);
  mongo_replset_add_seed(Handle, PAnsiChar(hosturl), port);
end;

function TMongoReplset.Connect: Boolean;
var
  Ret: Integer;
  Err: Integer;
begin
  CheckHandle;
  Ret := mongo_replset_connect(Handle);
  if Ret <> 0 then
    Err := getErr
  else 
    Err := 0;
  Result := (Ret = 0) and (Err = 0);
end;

function TMongo.isConnected: Boolean;
begin
  CheckHandle;
  Result := mongo_is_connected(fhandle);
end;

function TMongo.checkConnection: Boolean;
begin
  CheckHandle;
  Result := mongo_check_connection(fhandle) = 0;
end;

function TMongo.isMaster: Boolean;
begin
  CheckHandle;
  Result := mongo_cmd_ismaster(fhandle, nil);
end;

procedure TMongo.disconnect;
begin
  CheckHandle;
  mongo_disconnect(fhandle);
end;

function TMongo.reconnect: Boolean;
begin
  CheckHandle;
  Result := mongo_reconnect(fhandle) = 0;
end;

function TMongo.getErr: Integer;
begin
  CheckHandle;
  Result := mongo_get_err(fhandle);
end;

function TMongo.setTimeout(millis: Integer): Boolean;
begin
  CheckHandle;
  Result := mongo_set_op_timeout(fhandle, millis) = 0;
end;

function TMongo.getTimeout: Integer;
begin
  CheckHandle;
  Result := mongo_get_op_timeout(fhandle);
end;

function TMongo.getPrimary: AnsiString;
var
  APrimary: PAnsiChar;
begin
  CheckHandle;
  APrimary := mongo_get_primary(fhandle);
  try
    Result := AnsiString(APrimary);
  finally
    if APrimary <> nil then
      bson_free(APrimary);
  end;
end;

function TMongo.getSocket: Integer;
begin
  CheckHandle;
  Result := mongo_get_socket(fhandle);
end;

{ TMongoReplset }

function TMongoReplset.getHostCount: Integer;
begin
  CheckHandle;
  Result := mongo_get_host_count(Handle);
end;

function TMongoReplset.getHost(i: Integer): AnsiString;
var
  AHost: PAnsiChar;
begin
  CheckHandle;
  AHost := mongo_get_host(Handle, i);
  try
    Result := AnsiString(AHost);
  finally
    if AHost <> nil then
      bson_free(AHost);
  end;
end;

procedure TMongoReplset.InitMongo(const AHost: AnsiString);
begin
  fhandle := mongo_create;
  mongo_replset_init(Handle, PAnsiChar(AHost)); // AHost contains the replicate set Name
end;

function TMongo.getDatabases: TStringArray;
var
  b: IBson;
  it, databases, database: IBsonIterator;
  Name: AnsiString;
  Count, i: Integer;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  b := command(SAdmin, SListDatabases, true);
  if b = nil then
    Result := nil
  else
  begin
    it := b.iterator;
    it.Next;
    Count := 0;
    databases := it.subiterator;
    while databases.Next do
    begin
      database := databases.subiterator;
      database.Next;
      Name := AnsiString(database.Value);
      if (Name <> SAdmin) and (Name <> SLocal) then
        Inc(Count);
    end;
    SetLength(Result, Count);
    i := 0;
    databases := it.subiterator;
    while databases.Next do
    begin
      database := databases.subiterator;
      database.Next;
      Name := AnsiString(database.Value);
      if (Name <> SAdmin) and (Name <> SLocal) then
      begin
        Result[i] := Name;
        Inc(i);
      end;
    end;
  end;
end;

function TMongo.getDatabaseCollections(const db: AnsiString): TStringArray;
var
  Cursor: IMongoCursor;
  Count, i: Integer;
  ns, Name: AnsiString;
  b: IBson;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Count := 0;
  ns := db + SSystemNamespaces;
  Cursor := NewMongoCursor;
  if find(ns, Cursor) then
    while Cursor.Next do
    begin
      b := Cursor.Value;
      Name := AnsiString(b.Value(SName));
      if (Pos(SSystem, Name) = 0) and (Pos('$', Name) = 0) then
        Inc(Count);
    end;
  SetLength(Result, Count);
  i := 0;
  Cursor := NewMongoCursor;
  if find(ns, Cursor) then
    while Cursor.Next do
    begin
      b := Cursor.Value;
      Name := AnsiString(b.Value(SName));
      if (Pos(SSystem, Name) = 0) and (Pos('$', Name) = 0) then
      begin
        Result[i] := Name;
        Inc(i);
      end;
    end;
end;

function TMongo.Rename(const from_ns, to_ns: AnsiString): Boolean;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  autoCmdResetLastError(from_ns, true);
  Result := command(SAdmin, BSON([SRenameCollection, from_ns, STo, to_ns])) <> nil;
  autoCheckCmdLastError(from_ns, true);
end;

function TMongo.drop(const ns: AnsiString): Boolean;
var
  db: AnsiString;
  collection: AnsiString;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  parseNamespace(ns, db, collection);
  if db = '' then
    raise EMongo.Create(STMongoDropExpectedAInTheNamespac);
  autoCmdResetLastError(db, false);
  Result := mongo_cmd_drop_collection(fhandle, PAnsiChar(db), PAnsiChar(collection), nil) = 0;
  autoCheckCmdLastError(db, false);
end;

function TMongo.dropDatabase(const db: AnsiString): Boolean;
begin
  CheckHandle;
  autoCmdResetLastError(db, false);
  Result := mongo_cmd_drop_db(fhandle, PAnsiChar(db)) = 0;
  autoCheckCmdLastError(db, false);
end;

function TMongo.Insert(const ns: AnsiString; b: IBson): Boolean;
begin
  CheckHandle;
  autoCmdResetLastError(ns, true);
  Result := mongo_insert(fhandle, PAnsiChar(ns), b.Handle, nil) = 0;
  autoCheckCmdLastError(ns, true);
end;

function TMongo.Insert(const ns: AnsiString; const bs: array of IBson): Boolean;
type
  PPointerClosedArray = ^TPointerClosedArray;
  TPointerClosedArray = array [0..MaxInt div SizeOf(Pointer) - 1] of Pointer;
var
  ps: PPointerClosedArray;
  i: Integer;
  Len: Integer;
begin
  CheckHandle;
  Len := Length(bs);
  GetMem(ps, Len * SizeOf(Pointer));
  try
    for i := 0 to Len - 1 do
      ps^[i] := bs[i].Handle;
    autoCmdResetLastError(ns, true);
    Result := mongo_insert_batch(fhandle, PAnsiChar(ns), ps, Len, nil, 0) = 0;
    autoCheckCmdLastError(ns, true);
  finally
    FreeMem(ps);
  end;
end;

function TMongo.Update(const ns: AnsiString; criteria, objNew: IBson; flags: Integer): Boolean;
begin
  CheckHandle;
  autoCmdResetLastError(ns, true);
  Result := mongo_update(fhandle, PAnsiChar(ns), criteria.Handle, objNew.Handle, flags, nil) = 0;
  autoCheckCmdLastError(ns, true);
end;

function TMongo.Update(const ns: AnsiString; criteria, objNew: IBson): Boolean;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := Update(ns, criteria, objNew, 0);
end;

function TMongo.remove(const ns: AnsiString; criteria: IBson): Boolean;
begin
  CheckHandle;
  autoCmdResetLastError(ns, true);
  Result := mongo_remove(fhandle, PAnsiChar(ns), criteria.Handle, nil) = 0;
  autoCheckCmdLastError(ns, true);
end;

function TMongo.findOne(const ns: AnsiString; query, fields: IBson): IBson;
var
  res: Pointer;
begin
  CheckHandle;
  res := bson_create;
  try
    autoCmdResetLastError(ns, true);
    if mongo_find_one(fhandle, PAnsiChar(ns), query.Handle, fields.Handle, res) = 0 then
      Result := NewBson(res)
    else
    begin
      bson_dispose(res);
      Result := nil;
    end;
    autoCheckCmdLastError(ns, true);
  except
    bson_dispose(res);
    raise;
  end;
end;

function TMongo.findOne(const ns: AnsiString; query: IBson): IBson;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := findOne(ns, query, NewBson(nil));
end;

function TMongo.find(const ns: AnsiString; Cursor: IMongoCursor): Boolean;
var
  q: IBson;
  bb: IBsonBuffer;
  ch: Pointer;
begin
  CheckHandle;
  if Cursor.fields = nil then
    Cursor.fields := bsonEmpty;
  q := Cursor.query;
  if q = nil then
    q := bsonEmpty;
  if Cursor.Sort <> nil then
  begin
    bb := NewBsonBuffer;
    bb.Append(SQuery, q);
    bb.Append(SSort, Cursor.Sort);
    q := bb.finish;
  end;
  Cursor.conn := Self;
  autoCmdResetLastError(ns, true);
  try
    ch := mongo_find(fhandle, PAnsiChar(ns), q.Handle, Cursor.fields.Handle, Cursor.limit, Cursor.skip, Cursor.options);
    autoCheckCmdLastError(ns, true);
    if ch <> nil then
    begin
      Cursor.Handle := ch;
      Result := true;
    end
    else
      Result := false;
  finally
    Cursor.FindCalled;
  end;
end;

function TMongo.Count(const ns: AnsiString; query: IBson): Double;
var
  db: AnsiString;
  collection: AnsiString;
begin
  CheckHandle;
  parseNamespace(ns, db, collection);
  if db = '' then
    raise EMongo.Create(SExpectedAInTheNamespace);
  autoCmdResetLastError(db, false);
  Result := mongo_count(fhandle, PAnsiChar(db), PAnsiChar(collection), query.Handle);
  autoCheckCmdLastError(db, false);
end;

function TMongo.Count(const ns: AnsiString): Double;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  autoCmdResetLastError(ns, true);
  Result := Count(ns, NewBson(nil));
  autoCheckCmdLastError(ns, true);
end;

function TMongo.indexCreate(const ns: AnsiString; key: IBson; options: Integer): IBson;
var
  res: IBson;
  created: Boolean;
  h: Pointer;
begin
  CheckHandle;
  h := bson_create;
  try
    res := NewBson(h);
  except
    bson_dispose(h);
    raise;
  end;
  autoCmdResetLastError(ns, true);
  created := mongo_create_index(fhandle, PAnsiChar(ns), key.Handle, options, res.Handle) = 0;
  autoCheckCmdLastError(ns, true);
  if not created then
    Result := res
  else
    Result := nil;
end;

function TMongo.indexCreate(const ns: AnsiString; key: IBson): IBson;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := indexCreate(ns, key, 0);
end;

function TMongo.indexCreate(const ns, key: AnsiString; options: Integer): IBson;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := indexCreate(ns, BSON([key, true]), options);
end;

function TMongo.indexCreate(const ns, key: AnsiString): IBson;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := indexCreate(ns, key, 0);
end;

function TMongo.addUser(const Name, password, db: AnsiString): Boolean;
begin
  CheckHandle;
  Result := mongo_cmd_add_user(fhandle, PAnsiChar(db), PAnsiChar(Name), PAnsiChar(password)) = 0;
end;

function TMongo.addUser(const Name, password: AnsiString): Boolean;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := addUser(Name, password, SAdmin);
end;

function TMongo.authenticate(const Name, password, db: AnsiString): Boolean;
begin
  CheckHandle;
  Result := mongo_cmd_authenticate(fhandle, PAnsiChar(db), PAnsiChar(Name), PAnsiChar(password)) = 0;
end;

function TMongo.authenticate(const Name, password: AnsiString): Boolean;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := authenticate(Name, password, SAdmin);
end;

procedure TMongo.autoCheckCmdLastError(const ns: AnsiString; ANeedsParsing: Boolean);
var
  Err: IBson;
  db: AnsiString;
  collection: AnsiString;
  it: IBsonIterator;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if not FAutoCheckLastError then
    Exit;
  if ANeedsParsing then
    parseNamespace(ns, db, collection)
  else 
    db := ns;
  Err := cmdGetLastError(db);
  if Err <> nil then
  begin
    it := Err.iterator;
    it.Next;
    raise EMongo.Create(it.Value);
  end;
end;

procedure TMongo.autoCmdResetLastError(const ns: AnsiString; ANeedsParsing: Boolean);
var
  db: AnsiString;
  collection: AnsiString;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if not FAutoCheckLastError then
    Exit;
  if ANeedsParsing then
    parseNamespace(ns, db, collection)
  else 
    db := ns;
  cmdResetLastError(db);
end;

procedure TMongo.CheckHandle;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if fhandle = nil then
    raise EMongo.Create(SMongoHandleIsNil);
end;

function TMongo.command(const db: AnsiString; command: IBson): IBson;
var
  b: IBson;
  res: Pointer;
  h: Pointer;
begin
  CheckHandle;
  res := bson_create;
  try
    if mongo_run_command(fhandle, PAnsiChar(db), command.Handle, res) = 0 then
    begin
      h := bson_create;
      try
        b := NewBson(h);
      except
        bson_dispose(h);
        raise;
      end;
      bson_copy(b.Handle, res);
      Result := b;
    end
    else
      Result := nil;
  finally
    bson_destroy(res);
    bson_dispose(res);
  end;
end;

function TMongo.distinct(const ns, key: AnsiString): IBson;
var
  b: IBson;
  buf: IBsonBuffer;
  db, collection: AnsiString;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  parseNamespace(ns, db, collection);
  if db = '' then
    raise EMongo.Create(SExpectedAInTheNamespace);
  buf := NewBsonBuffer;
  buf.AppendStr(SDistinct, PAnsiChar(collection));
  buf.AppendStr(SKey, PAnsiChar(key));
  b := buf.finish;
  Result := command(db, b);
end;

function TMongo.command(const db, cmdstr: AnsiString; const arg: Variant): IBson;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := command(db, BSON([cmdstr, arg]));
end;

function TMongo.getLastErr(const db: AnsiString): IBson;
var
  b: IBson;
  res: Pointer;
  h: Pointer;
begin
  CheckHandle;
  res := bson_create;
  try
    if mongo_cmd_get_last_error(fhandle, PAnsiChar(db), res) <> 0 then
    begin
      h := bson_create;
      try
        b := NewBson(h);
      except
        bson_dispose(h);
        raise;
      end;
      bson_copy(b.Handle, res);
      Result := b;
    end
    else
      Result := nil;
  finally
    bson_destroy(res);
    bson_dispose(res);
  end;
end;

function TMongo.cmdGetLastError(const db: AnsiString): IBson;
var
  h: Pointer;
begin
  CheckHandle;
  h := bson_create;
  if mongo_cmd_get_last_error(fHandle, PAnsiChar(db), h) = 0 then
  begin
    bson_destroy(h);
    bson_dispose(h);
    Result := nil;
  end
  else 
    Result := NewBson(h);
end;

procedure TMongo.cmdResetLastError(const db: AnsiString);
begin
  CheckHandle;
  mongo_cmd_reset_error(fHandle, PAnsiChar(db));
end;

function TMongo.getPrevErr(const db: AnsiString): IBson;
var
  b: IBson;
  res: Pointer;
  h: Pointer;
begin
  CheckHandle;
  res := bson_create;
  try
    if mongo_cmd_get_prev_error(fhandle, PAnsiChar(db), res) <> 0 then
    begin
      h := bson_create;
      try
        b := NewBson(h);
      except
        bson_dispose(h);
        raise;
      end;
      bson_copy(b.Handle, res);
      Result := b;
    end
    else
      Result := nil;
  finally
    bson_destroy(res);
    bson_dispose(res);
  end;
end;

procedure TMongo.resetErr(const db: AnsiString);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  command(db, SReseterror, true);
end;

function TMongo.getServerErr: Integer;
begin
  CheckHandle;
  Result := mongo_get_server_err(fhandle);
end;

function TMongo.getServerErrString: AnsiString;
begin
  CheckHandle;
  Result := AnsiString(mongo_get_server_err_string(fhandle));
end;

procedure TMongo.InitMongo(const AHost: AnsiString);
var
  hosturl: AnsiString;
  port: Integer;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  fhandle := mongo_create;
  parseHost(AHost, hosturl, port);
  mongo_connect(fhandle, PAnsiChar(hosturl), port);
end;

procedure TMongo.parseNamespace(const ns: AnsiString; var db: AnsiString; var Collection: AnsiString);
var
  i: Integer;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  i := Pos('.', ns);
  if i > 0 then
  begin
    db := Copy(ns, 1, i - 1);
    collection := Copy(ns, i + 1, Length(ns) - i);
  end
  else
  begin
    db := '';
    Collection := ns;
  end;
end;

procedure TMongo.setWriteConcern(AWriteConcern: IWriteConcern);
begin
  CheckHandle;
  if AWriteConcern <> nil then
    if AWriteConcern.finished then
      mongo_set_write_concern(FHandle, AWriteConcern.Handle)
    else 
      raise EMongo.Create(SCanTUseAnUnfinishedWriteConcern)
  else 
    mongo_set_write_concern(FHandle, nil);
  FWriteConcern := AWriteConcern;
end;

{ TMongoCursor }

constructor TMongoCursor.Create;
begin
  inherited Create;
  {$IFDEF OnDemandMongoCLoad}
  InitMongoDBLibrary;
  {$ENDIF}
  Init;
end;

constructor TMongoCursor.Create(aquery: IBson);
begin
  inherited Create;
  {$IFDEF OnDemandMongoCLoad}
  InitMongoDBLibrary;
  {$ENDIF}
  Init;
  query := aquery;
end;

destructor TMongoCursor.Destroy;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  DestroyCursor;
  inherited;
end;

procedure TMongoCursor.CheckHandle;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if FHandle = nil then
    raise EMongo.Create(SMongoHandleIsNil);
end;

procedure TMongoCursor.DestroyCursor;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if FHandle <> nil then
  begin
    mongo_cursor_destroy(FHandle);
    if not FFindCalledFlag then
      mongo_cursor_dispose(FHandle);
    FHandle := nil;
    FFindCalledFlag := false;
  end;
end;

procedure TMongoCursor.FindCalled;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  FindCalledFlag := true;
end;

function TMongoCursor.GetConn: TMongo;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := FConn;
end;

function TMongoCursor.GetFields: IBson;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := FFields;
end;

function TMongoCursor.GetHandle: Pointer;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := FHandle;
end;

function TMongoCursor.GetLimit: Integer;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := FLimit;
end;

function TMongoCursor.GetOptions: Integer;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := FOptions;
end;

function TMongoCursor.GetQuery: IBson;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := FQuery;
end;

function TMongoCursor.GetSkip: Integer;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := FSkip;
end;

function TMongoCursor.GetSort: IBson;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := FSort;
end;

procedure TMongoCursor.Init;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Handle := nil;
  query := nil;
  Sort := nil;
  fields := nil;
  limit := 0;
  skip := 0;
  options := 0;
  fconn := nil;
end;

function TMongoCursor.Next: Boolean;
begin
  CheckHandle;
  Result := mongo_cursor_next(Handle) = 0;
end;

procedure TMongoCursor.SetConn(const Value: TMongo);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  FConn := Value;
end;

procedure TMongoCursor.SetFields(const Value: IBson);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  FFields := Value;
end;

procedure TMongoCursor.SetHandle(const Value: Pointer);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if FHandle <> nil then
    DestroyCursor;
  FHandle := Value;
end;

procedure TMongoCursor.SetLimit(const Value: Integer);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  FLimit := Value;
end;

procedure TMongoCursor.SetOptions(const Value: Integer);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  FOptions := Value;
end;

procedure TMongoCursor.SetQuery(const Value: IBson);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  FQuery := Value;
end;

procedure TMongoCursor.SetSkip(const Value: Integer);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  FSkip := Value;
end;

procedure TMongoCursor.SetSort(const Value: IBson);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  FSort := Value;
end;

function TMongoCursor.Value: IBson;
var
  b: IBson;
  h: Pointer;
begin
  CheckHandle;
  h := bson_create;
  try
    b := NewBson(h);
  except
    bson_dispose(h);
    raise;
  end;
  bson_copy(h, mongo_cursor_bson(Handle));
  Result := b;
end;

function NewMongoCursor: IMongoCursor;
begin
  Result := TMongoCursor.Create;
end;

function NewMongoCursor(query: IBson): IMongoCursor;
begin
  Result := TMongoCursor.Create(query);
end;

function NewWriteConcern: IWriteConcern;
begin
  Result := TWriteConcern.Create;
end;

{ TWriteConcern }

constructor TWriteConcern.Create;
begin
  inherited Create;
  mongo_write_concern_init(@FWriteConcern);
end;

destructor TWriteConcern.Destroy;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  mongo_write_concern_destroy(@FWriteConcern);
  FWriteConcern.mode := nil;
  inherited;
end;

procedure TWriteConcern.finish;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  mongo_write_concern_finish(@FWriteConcern);
  FFinished := true;
end;

function TWriteConcern.Getfinished: Boolean;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := FFinished;
end;

function TWriteConcern.Getfsync: Integer;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := FWriteConcern.fsync;
end;

function TWriteConcern.GetHandle: Pointer;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := @FWriteConcern;
end;

function TWriteConcern.Getj: Integer;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := FWriteConcern.j;
end;

function TWriteConcern.Getmode: AnsiString;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  if FWriteConcern.mode <> nil then
    Result := AnsiString(FWriteConcern.mode)
  else 
    Result := '';
end;

function TWriteConcern.Getw: Integer;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := FWriteConcern.w;
end;

function TWriteConcern.Getwtimeout: Integer;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  Result := FWriteConcern.wtimeout;
end;

procedure TWriteConcern.Modified;
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  FFinished := false;
end;

procedure TWriteConcern.Setfsync(const Value: Integer);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  FWriteConcern.fsync := Value;
  Modified;
end;

procedure TWriteConcern.Setj(const Value: Integer);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  FWriteConcern.j := Value;
  Modified;
end;

procedure TWriteConcern.Setmode(const Value: AnsiString);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  FMode := Value;
  FWriteConcern.mode := PAnsiChar(FMode);
  Modified;
end;

procedure TWriteConcern.Setw(const Value: Integer);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  FWriteConcern.w := Value;
  Modified;
end;

procedure TWriteConcern.Setwtimeout(const Value: Integer);
begin
  {$IFDEF MONGO_MEMORY_PROTECTION} CheckValid; {$ENDIF}
  FWriteConcern.wtimeout := Value;
  Modified;
end;

end.
