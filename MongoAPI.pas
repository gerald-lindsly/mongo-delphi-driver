unit MongoAPI;

interface

uses
  Windows, SysUtils;

const
  MongoCDLL = 'mongoc.dll';

type
  EMongoFatalError = class(Exception);

  { A value of TBsonType indicates the type of the data associated
    with a field within a BSON document. }
  TBsonType = (bsonEOO, // 0
    bsonDOUBLE,         // 1
    bsonSTRING,         // 2
    bsonOBJECT,         // 3
    bsonARRAY,          // 4
    bsonBINDATA,        // 5
    bsonUNDEFINED,      // 6
    bsonOID,            // 7
    bsonBOOL,           // 8
    bsonDATE,           // 9
    bsonNULL,           // 10
    bsonREGEX,          // 11
    bsonDBREF, (* Deprecated. 12 *)
    bsonCODE,           // 13
    bsonSYMBOL,         // 14
    bsonCODEWSCOPE,     // 15
    bsonINT,            // 16
    bsonTIMESTAMP,      // 17
    bsonLONG);          // 18

const
  DELPHI_MONGO_SIGNATURE = $EFEFAFAF;

type
  TMongoBaseClass = class(TInterfacedObject)
  protected
    MongoSignature : cardinal;
    procedure CheckValid;
  public
    constructor Create;
    destructor Destroy; override;
  end;

type
  TMongoNonInterfacedBaseClass = class(TObject)
  protected
    MongoSignature : cardinal;
    procedure CheckValid;
  public
    constructor Create;
    destructor Destroy; override;
  end;

{$IFDEF OnDemandMongoCLoad}
type
  // MongoDB declarations
  Tmongo_sock_init = function : Integer; cdecl;
  Tmongo_create = function : Pointer; cdecl;
  Tmongo_dispose = procedure (c: Pointer); cdecl;
  Tmongo_connect = function (c: Pointer; host: PAnsiChar; port: Integer): Integer; cdecl;
  Tmongo_destroy = procedure(c: Pointer); cdecl;
  Tmongo_replset_init = procedure (c: Pointer; Name: PAnsiChar); cdecl;
  Tmongo_replset_add_seed = procedure (c: Pointer; host: PAnsiChar; port: Integer); cdecl;
  Tmongo_replset_connect = function(c: Pointer): Integer; cdecl;
  Tmongo_is_connected = function (c: Pointer): LongBool; cdecl;
  Tmongo_get_err = function(c: Pointer): Integer; cdecl;
  Tmongo_set_op_timeout = function (c: Pointer; millis: Integer): Integer; cdecl;
  Tmongo_get_op_timeout = function (c: Pointer): Integer; cdecl;
  Tmongo_get_primary = function (c: Pointer): PAnsiChar; cdecl;
  Tmongo_check_connection = function (c: Pointer): Integer; cdecl;
  Tmongo_disconnect = procedure (c: Pointer); cdecl;
  Tmongo_reconnect = function (c: Pointer): Integer; cdecl;
  Tmongo_cmd_ismaster = function (c: Pointer; b: Pointer): Longbool; cdecl;
  Tmongo_get_socket = function (c: Pointer): Integer; cdecl;
  Tmongo_get_host_count = function (c: Pointer): Integer; cdecl;
  Tmongo_get_host = function (c: Pointer; i: Integer): PAnsiChar; cdecl;
  Tmongo_insert = function (c: Pointer; ns: PAnsiChar; b: Pointer; wc: Pointer): Integer; cdecl;
  Tmongo_insert_batch = function (c: Pointer; ns: PAnsiChar; bsons: Pointer; Count: Integer; wc: Pointer; flags: Integer): Integer; cdecl;
  Tmongo_update = function (c: Pointer; ns: PAnsiChar; cond: Pointer; op: Pointer; flags: Integer; wc: Pointer): Integer; cdecl;
  Tmongo_remove = function (c: Pointer; ns: PAnsiChar; criteria: Pointer; wc: Pointer): Integer; cdecl;
  Tmongo_find_one = function (c: Pointer; ns: PAnsiChar; query: Pointer; fields: Pointer; Result: Pointer): Integer; cdecl;
  Tbson_create = function : Pointer; cdecl;
  Tbson_dispose = procedure (b: Pointer); cdecl;
  Tbson_copy = procedure (dest: Pointer; src: Pointer); cdecl;
  Tmongo_cursor_create = function : Pointer; cdecl;
  Tmongo_cursor_dispose = procedure (Cursor: Pointer); cdecl;
  Tmongo_cursor_destroy = procedure (Cursor: Pointer); cdecl;
  Tmongo_find = function (c: Pointer; ns: PAnsiChar; query: Pointer; fields: Pointer; limit, skip, options: Integer): Pointer; cdecl;
  Tmongo_cursor_next = function (Cursor: Pointer): Integer; cdecl;
  Tmongo_cursor_bson = function (Cursor: Pointer): Pointer; cdecl;
  Tmongo_cmd_drop_collection = function (c: Pointer; db: PAnsiChar; collection: PAnsiChar; Result: Pointer): Integer; cdecl;
  Tmongo_cmd_drop_db = function (c: Pointer; db: PAnsiChar): Integer; cdecl;
  Tmongo_count = function (c: Pointer; db: PAnsiChar; collection: PAnsiChar; query: Pointer): Double; cdecl;
  Tmongo_create_index = function (c: Pointer; ns: PAnsiChar; key: Pointer; options: Integer; res: Pointer): Integer; cdecl;
  Tmongo_cmd_add_user = function (c: Pointer; db: PAnsiChar; Name: PAnsiChar; password: PAnsiChar): Integer; cdecl;
  Tmongo_cmd_authenticate = function (c: Pointer; db: PAnsiChar; Name: PAnsiChar; password: PAnsiChar): Integer; cdecl;
  Tmongo_run_command = function (c: Pointer; db: PAnsiChar; command: Pointer; res: Pointer): Integer; cdecl;
  Tmongo_cmd_get_last_error = function (c: Pointer; db: PAnsiChar; res: Pointer): Integer; cdecl;
  Tmongo_cmd_get_prev_error = function (c: Pointer; db: PAnsiChar; res: Pointer): Integer; cdecl;
  Tmongo_cmd_reset_error = procedure(c : Pointer; db : PAnsiChar); cdecl;
  Tmongo_get_server_err = function (c: Pointer): Integer; cdecl;
  Tmongo_get_server_err_string = function (c: Pointer): PAnsiChar; cdecl;
  Tmongo_write_concern_init = procedure(write_concern : pointer); cdecl;
  Tmongo_write_concern_finish = function(write_concern : pointer) : integer; cdecl;
  Tmongo_write_concern_destroy = procedure(write_concern : pointer); cdecl;
  Tmongo_set_write_concern = procedure(conn : pointer; write_concern : pointer); cdecl;
  // MongoBSON declarations
  Tbson_free = procedure (b : pointer); cdecl;
  Tbson_init = procedure (b: Pointer); cdecl;
  Tbson_destroy = procedure (b: Pointer); cdecl;
  Tbson_finish = function (b: Pointer): Integer; cdecl;
  Tbson_oid_gen = procedure (oid: Pointer); cdecl;
  Tbson_oid_to_string = procedure (oid: Pointer; s: PAnsiChar); cdecl;
  Tbson_oid_from_string = procedure (oid: Pointer; s: PAnsiChar); cdecl;
  Tbson_append_string = function (b: Pointer; Name: PAnsiChar; Value: PAnsiChar): Integer; cdecl;
  Tbson_append_code = function (b: Pointer; Name: PAnsiChar; Value: PAnsiChar): Integer; cdecl;
  Tbson_append_symbol = function (b: Pointer; Name: PAnsiChar; Value: PAnsiChar): Integer; cdecl;
  Tbson_append_int = function (b: Pointer; Name: PAnsiChar; Value: Integer): Integer; cdecl;
  Tbson_append_long = function (b: Pointer; Name: PAnsiChar; Value: Int64): Integer; cdecl;
  Tbson_append_double = function (b: Pointer; Name: PAnsiChar; Value: Double): Integer; cdecl;
  Tbson_append_date = function (b: Pointer; Name: PAnsiChar; Value: Int64): Integer; cdecl;
  Tbson_append_bool = function (b: Pointer; Name: PAnsiChar; Value: LongBool): Integer; cdecl;
  Tbson_append_null = function (b: Pointer; Name: PAnsiChar): Integer; cdecl;
  Tbson_append_undefined = function (b: Pointer; Name: PAnsiChar): Integer; cdecl;
  Tbson_append_start_object = function (b: Pointer; Name: PAnsiChar): Integer; cdecl;
  Tbson_append_start_array = function (b: Pointer; Name: PAnsiChar): Integer; cdecl;
  Tbson_append_finish_object = function (b: Pointer): Integer; cdecl;
  Tbson_append_oid = function (b: Pointer; Name: PAnsiChar; oid: Pointer): Integer; cdecl;
  Tbson_append_code_w_scope = function (b: Pointer; Name: PAnsiChar; code: PAnsiChar; scope: Pointer): Integer; cdecl;
  Tbson_append_regex = function (b: Pointer; Name: PAnsiChar; pattern: PAnsiChar; options: PAnsiChar): Integer; cdecl;
  Tbson_append_timestamp2 = function (b: Pointer; Name: PAnsiChar; Time: Integer; increment: Integer): Integer; cdecl;
  Tbson_append_binary = function (b: Pointer; Name: PAnsiChar; Kind: Byte; Data: Pointer; Len: Integer): Integer; cdecl;
  Tbson_append_bson = function (b: Pointer; Name: PAnsiChar; Value: Pointer): Integer; cdecl;
  Tbson_buffer_size = function (b: Pointer): Integer; cdecl;
  Tbson_size = function (b: Pointer): Integer; cdecl;
  Tbson_iterator_create = function (): Pointer; cdecl;
  Tbson_iterator_dispose = procedure (i: Pointer); cdecl;
  Tbson_iterator_init = procedure (i: Pointer; b: Pointer); cdecl;
  Tbson_find = function (i: Pointer; b: Pointer; Name: PAnsiChar): TBsonType; cdecl;
  Tbson_iterator_type = function (i: Pointer): TBsonType; cdecl;
  Tbson_iterator_next = function (i: Pointer): TBsonType; cdecl;
  Tbson_iterator_key = function (i: Pointer): PAnsiChar; cdecl;
  Tbson_iterator_double = function (i: Pointer): Double; cdecl;
  Tbson_iterator_long = function (i: Pointer): Int64; cdecl;
  Tbson_iterator_int = function (i: Pointer): Integer; cdecl;
  Tbson_iterator_bool = function (i: Pointer): LongBool; cdecl;
  Tbson_iterator_string = function (i: Pointer): PAnsiChar; cdecl;
  Tbson_iterator_date = function (i: Pointer): Int64; cdecl;
  Tbson_iterator_subiterator = procedure (i: Pointer; sub: Pointer); cdecl;
  Tbson_iterator_oid = function (i: Pointer): Pointer; cdecl;
  Tbson_iterator_code = function (i: Pointer): PAnsiChar; cdecl;
  Tbson_iterator_code_scope = procedure (i: Pointer; b: Pointer); cdecl;
  Tbson_iterator_regex = function (i: Pointer): PAnsiChar; cdecl;
  Tbson_iterator_regex_opts = function (i: Pointer): PAnsiChar; cdecl;
  Tbson_iterator_timestamp_time = function (i: Pointer): Integer; cdecl;
  Tbson_iterator_timestamp_increment = function (i: Pointer): Integer; cdecl;
  Tbson_iterator_bin_len = function (i: Pointer): Integer; cdecl;
  Tbson_iterator_bin_type = function (i: Pointer): Byte; cdecl;
  Tbson_iterator_bin_data = function (i: Pointer): Pointer; cdecl;
  TInt64toDouble = function (i64: Int64): Double; cdecl;
  Tset_bson_err_handler = function(newErrorHandler : Pointer) : Pointer; cdecl;
  // GridFS declarations
  Tgridfs_create = function : Pointer; cdecl;
  Tgridfs_dispose = procedure (g: Pointer); cdecl;
  Tgridfs_init = function (c: Pointer; db: PAnsiChar; prefix: PAnsiChar; g: Pointer): Integer; cdecl;
  Tgridfs_destroy = procedure (g: Pointer); cdecl;
  Tgridfs_store_file = function (g: Pointer; FileName: PAnsiChar; remoteName: PAnsiChar; contentType: PAnsiChar; Flags : Integer): Integer; cdecl;
  Tgridfs_remove_filename = procedure (g: Pointer; remoteName: PAnsiChar); cdecl;
  Tgridfs_store_buffer = function (g: Pointer; p: Pointer; size: Int64; remoteName: PAnsiChar; contentType: PAnsiChar; Flags : Integer): Integer; cdecl;
  Tgridfile_create = function : Pointer; cdecl;
  Tgridfile_dispose = procedure (gf: Pointer); cdecl;
  Tgridfile_writer_init = procedure (gf: Pointer; gfs: Pointer; remoteName: PAnsiChar; contentType: PAnsiChar; Flags : Integer); cdecl;
  Tgridfile_write_buffer = procedure (gf: Pointer; Data: Pointer; Length: Int64); cdecl;
  Tgridfile_writer_done = function (gf: Pointer): Integer; cdecl;
  Tgridfs_find_query = function (g: Pointer; query: Pointer; gf: Pointer): Integer; cdecl;
  Tgridfile_destroy = procedure (gf: Pointer); cdecl;
  Tgridfile_get_filename = function (gf: Pointer): PAnsiChar; cdecl;
  Tgridfile_get_chunksize = function (gf: Pointer): Integer; cdecl;
  Tgridfile_get_contentlength = function (gf: Pointer): Int64; cdecl;
  Tgridfile_get_contenttype = function (gf: Pointer): PAnsiChar; cdecl;
  Tgridfile_get_uploaddate = function (gf: Pointer): Int64; cdecl;
  Tgridfile_get_md5 = function (gf: Pointer): PAnsiChar; cdecl;
  Tgridfile_get_metadata = procedure (gf: Pointer; b: Pointer); cdecl;
  Tgridfile_get_numchunks = function (gf: Pointer): Integer; cdecl;
  Tgridfile_get_descriptor = procedure (gf: Pointer; b: Pointer); cdecl;
  Tgridfile_get_chunk = procedure (gf: Pointer; i: Integer; b: Pointer); cdecl;
  Tgridfile_get_chunks = function (gf: Pointer; i: Integer; Count: Integer): Pointer; cdecl;
  Tgridfile_read = function (gf: Pointer; size: Int64; buf: Pointer): Int64; cdecl;
  Tgridfile_seek = function (gf: Pointer; offset: Int64): Int64; cdecl;
  Tgridfile_init = function (gfs, meta, gfile : pointer) : integer; cdecl;
  Tgridfile_get_id = function (gfile : pointer) : pointer; cdecl;
  Tgridfile_truncate = function (gfile : Pointer; newSize : int64) : Int64; cdecl;
  Tgridfs_get_caseInsensitive = function (gf : Pointer) : LongBool; cdecl;
  Tgridfs_set_caseInsensitive = procedure (gf : Pointer; newValue : LongBool); cdecl;
  Tgridfile_set_flags = procedure(gf : Pointer; Flags : Integer); cdecl;
  Tgridfile_get_flags = function(gf : Pointer) : Integer; cdecl;
  TinitPrepostChunkProcessing = function (flags : integer) : integer; cdecl;

var
  HMongoDBDll : HMODULE;
  // MongoDB declarations
  mongo_sock_init : Tmongo_sock_init;
  mongo_create : Tmongo_create;
  mongo_dispose : Tmongo_dispose;
  mongo_connect : Tmongo_connect;
  mongo_destroy : Tmongo_destroy;
  mongo_replset_init : Tmongo_replset_init;
  mongo_replset_add_seed : Tmongo_replset_add_seed;
  mongo_replset_connect : Tmongo_replset_connect;
  mongo_is_connected : Tmongo_is_connected;
  mongo_get_err : Tmongo_get_err;
  mongo_set_op_timeout : Tmongo_set_op_timeout;
  mongo_get_op_timeout : Tmongo_get_op_timeout;
  mongo_get_primary : Tmongo_get_primary;
  mongo_check_connection : Tmongo_check_connection;
  mongo_disconnect : Tmongo_disconnect;
  mongo_reconnect : Tmongo_reconnect;
  mongo_cmd_ismaster : Tmongo_cmd_ismaster;
  mongo_get_socket : Tmongo_get_socket;
  mongo_get_host_count : Tmongo_get_host_count;
  mongo_get_host : Tmongo_get_host;
  mongo_insert : Tmongo_insert;
  mongo_insert_batch : Tmongo_insert_batch;
  mongo_update : Tmongo_update;
  mongo_remove : Tmongo_remove;
  mongo_find_one : Tmongo_find_one;
  bson_create : Tbson_create;
  bson_dispose : Tbson_dispose;
  bson_copy : Tbson_copy;
  mongo_cursor_create : Tmongo_cursor_create;
  mongo_cursor_dispose : Tmongo_cursor_dispose;
  mongo_cursor_destroy : Tmongo_cursor_destroy;
  mongo_find : Tmongo_find;
  mongo_cursor_next : Tmongo_cursor_next;
  mongo_cursor_bson : Tmongo_cursor_bson;
  mongo_cmd_drop_collection : Tmongo_cmd_drop_collection;
  mongo_cmd_drop_db : Tmongo_cmd_drop_db;
  mongo_count : Tmongo_count;
  mongo_create_index : Tmongo_create_index;
  mongo_cmd_add_user : Tmongo_cmd_add_user;
  mongo_cmd_authenticate : Tmongo_cmd_authenticate;
  mongo_run_command : Tmongo_run_command;
  mongo_cmd_get_last_error : Tmongo_cmd_get_last_error;
  mongo_cmd_get_prev_error : Tmongo_cmd_get_prev_error;
  mongo_cmd_reset_error : Tmongo_cmd_reset_error;
  mongo_get_server_err : Tmongo_get_server_err;
  mongo_get_server_err_string : Tmongo_get_server_err_string;
  mongo_write_concern_init : Tmongo_write_concern_init;
  mongo_write_concern_finish : Tmongo_write_concern_finish;
  mongo_write_concern_destroy : Tmongo_write_concern_destroy;
  mongo_set_write_concern : Tmongo_set_write_concern;
  // MongoBson declarations
  bson_free : Tbson_free;
  bson_init : Tbson_init;
  bson_destroy : Tbson_destroy;
  bson_finish : Tbson_finish;
  bson_oid_gen : Tbson_oid_gen;
  bson_oid_to_string : Tbson_oid_to_string;
  bson_oid_from_string : Tbson_oid_from_string;
  bson_append_string : Tbson_append_string;
  bson_append_code : Tbson_append_code;
  bson_append_symbol : Tbson_append_symbol;
  bson_append_int : Tbson_append_int;
  bson_append_long : Tbson_append_long;
  bson_append_double : Tbson_append_double;
  bson_append_date : Tbson_append_date;
  bson_append_bool : Tbson_append_bool;
  bson_append_null : Tbson_append_null;
  bson_append_undefined : Tbson_append_undefined;
  bson_append_start_object : Tbson_append_start_object;
  bson_append_start_array : Tbson_append_start_array;
  bson_append_finish_object : Tbson_append_finish_object;
  bson_append_oid : Tbson_append_oid;
  bson_append_code_w_scope : Tbson_append_code_w_scope;
  bson_append_regex : Tbson_append_regex;
  bson_append_timestamp2 : Tbson_append_timestamp2;
  bson_append_binary : Tbson_append_binary;
  bson_append_bson : Tbson_append_bson;
  bson_buffer_size : Tbson_buffer_size;
  bson_size : Tbson_size;
  bson_iterator_create : Tbson_iterator_create;
  bson_iterator_dispose : Tbson_iterator_dispose;
  bson_iterator_init : Tbson_iterator_init;
  bson_find : Tbson_find;
  bson_iterator_type : Tbson_iterator_type;
  bson_iterator_next : Tbson_iterator_next;
  bson_iterator_key : Tbson_iterator_key;
  bson_iterator_double : Tbson_iterator_double;
  bson_iterator_long : Tbson_iterator_long;
  bson_iterator_int : Tbson_iterator_int;
  bson_iterator_bool : Tbson_iterator_bool;
  bson_iterator_string : Tbson_iterator_string;
  bson_iterator_date: Tbson_iterator_date;
  bson_iterator_subiterator : Tbson_iterator_subiterator;
  bson_iterator_oid : Tbson_iterator_oid;
  bson_iterator_code : Tbson_iterator_code;
  bson_iterator_code_scope : Tbson_iterator_code_scope;
  bson_iterator_regex : Tbson_iterator_regex;
  bson_iterator_regex_opts : Tbson_iterator_regex_opts;
  bson_iterator_timestamp_time : Tbson_iterator_timestamp_time;
  bson_iterator_timestamp_increment : Tbson_iterator_timestamp_increment;
  bson_iterator_bin_len : Tbson_iterator_bin_len;
  bson_iterator_bin_type : Tbson_iterator_bin_type;
  bson_iterator_bin_data : Tbson_iterator_bin_data;
  set_bson_err_handler : Tset_bson_err_handler;
  // GridFS declarations
  gridfs_create : Tgridfs_create;
  gridfs_dispose : Tgridfs_dispose;
  gridfs_init : Tgridfs_init;
  gridfs_destroy : Tgridfs_destroy;
  gridfs_store_file : Tgridfs_store_file;
  gridfs_remove_filename : Tgridfs_remove_filename;
  gridfs_store_buffer : Tgridfs_store_buffer;
  gridfile_create : Tgridfile_create;
  gridfile_dispose : Tgridfile_dispose;
  gridfile_writer_init : Tgridfile_writer_init;
  gridfile_write_buffer : Tgridfile_write_buffer;
  gridfile_writer_done : Tgridfile_writer_done;
  gridfs_find_query : Tgridfs_find_query;
  gridfile_destroy : Tgridfile_destroy;
  gridfile_get_filename : Tgridfile_get_filename;
  gridfile_get_chunksize : Tgridfile_get_chunksize;
  gridfile_get_contentlength : Tgridfile_get_contentlength;
  gridfile_get_contenttype: Tgridfile_get_contenttype;
  gridfile_get_uploaddate : Tgridfile_get_uploaddate;
  gridfile_get_md5 : Tgridfile_get_md5;
  gridfile_get_metadata : Tgridfile_get_metadata;
  gridfile_get_numchunks : Tgridfile_get_numchunks;
  gridfile_get_descriptor : Tgridfile_get_descriptor;
  gridfile_get_chunk: Tgridfile_get_chunk;
  gridfile_get_chunks : Tgridfile_get_chunks;
  gridfile_read : Tgridfile_read;
  gridfile_seek : Tgridfile_seek;
  gridfile_init : Tgridfile_init;
  gridfile_get_id : Tgridfile_get_id;
  gridfile_truncate : Tgridfile_truncate;
  gridfs_get_caseInsensitive : Tgridfs_get_caseInsensitive;
  gridfs_set_caseInsensitive : Tgridfs_set_caseInsensitive;
  gridfile_set_flags : Tgridfile_set_flags;
  gridfile_get_flags : Tgridfile_get_flags;
  initPrepostChunkProcessing : TinitPrepostChunkProcessing;

  Int64toDouble : TInt64toDouble;

  procedure InitMongoDBLibrary;
  procedure DoneMongoDBLibrary;

{$Else}
  // MongoDB declarations
  function mongo_sock_init: Integer; cdecl; external MongoCDLL;
  function mongo_create: Pointer; cdecl; external MongoCDLL;
  procedure mongo_dispose(c: Pointer); cdecl; external MongoCDLL;
  function mongo_connect(c: Pointer; host: PAnsiChar; port: Integer): Integer; cdecl; external MongoCDLL;
  procedure mongo_destroy(c: Pointer); cdecl; external MongoCDLL;
  procedure mongo_replset_init(c: Pointer; Name: PAnsiChar); cdecl; external MongoCDLL;
  procedure mongo_replset_add_seed(c: Pointer; host: PAnsiChar; port: Integer); cdecl; external MongoCDLL;
  function mongo_replset_connect(c: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_is_connected(c: Pointer): Longbool; cdecl; external MongoCDLL;
  function mongo_get_err(c: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_set_op_timeout(c: Pointer; millis: Integer): Integer; cdecl; external MongoCDLL;
  function mongo_get_op_timeout(c: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_get_primary(c: Pointer): PAnsiChar; cdecl; external MongoCDLL;
  function mongo_check_connection(c: Pointer): Integer; cdecl; external MongoCDLL;
  procedure mongo_disconnect(c: Pointer); cdecl; external MongoCDLL;
  function mongo_reconnect(c: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_cmd_ismaster(c: Pointer; b: Pointer): Longbool; cdecl; external MongoCDLL;
  function mongo_get_socket(c: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_get_host_count(c: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_get_host(c: Pointer; i: Integer): PAnsiChar; cdecl; external MongoCDLL;
  function mongo_insert(c: Pointer; ns: PAnsiChar; b: Pointer; wc: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_insert_batch(c: Pointer; ns: PAnsiChar; bsons: Pointer; Count: Integer; wc: Pointer; flags: Integer): Integer; cdecl; external MongoCDLL;
  function mongo_update(c: Pointer; ns: PAnsiChar; cond: Pointer; op: Pointer; flags: Integer; wc: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_remove(c: Pointer; ns: PAnsiChar; criteria: Pointer; wc: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_find_one(c: Pointer; ns: PAnsiChar; query: Pointer; fields: Pointer; Result: Pointer): Integer; cdecl; external MongoCDLL;
  function bson_create: Pointer; cdecl; external MongoCDLL;
  procedure bson_dispose(b: Pointer); cdecl; external MongoCDLL;
  procedure bson_copy(dest: Pointer; src: Pointer); cdecl; external MongoCDLL;
  function mongo_cursor_create: Pointer; cdecl; external MongoCDLL;
  procedure mongo_cursor_dispose(Cursor: Pointer); cdecl; external MongoCDLL;
  procedure mongo_cursor_destroy(Cursor: Pointer); cdecl; external MongoCDLL;
  function mongo_find(c: Pointer; ns: PAnsiChar; query: Pointer; fields: Pointer; limit, skip, options: Integer): Pointer; cdecl; external MongoCDLL;
  function mongo_cursor_next(Cursor: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_cursor_bson(Cursor: Pointer): Pointer; cdecl; external MongoCDLL;
  function mongo_cmd_drop_collection(c: Pointer; db: PAnsiChar; collection: PAnsiChar; Result: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_cmd_drop_db(c: Pointer; db: PAnsiChar): Integer; cdecl; external MongoCDLL;
  function mongo_count(c: Pointer; db: PAnsiChar; collection: PAnsiChar; query: Pointer): Double; cdecl; external MongoCDLL;
  function mongo_create_index(c: Pointer; ns: PAnsiChar; key: Pointer; options: Integer; res: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_cmd_add_user(c: Pointer; db: PAnsiChar; Name: PAnsiChar; password: PAnsiChar): Integer; cdecl; external MongoCDLL;
  function mongo_cmd_authenticate(c: Pointer; db: PAnsiChar; Name: PAnsiChar; password: PAnsiChar): Integer; cdecl; external MongoCDLL;
  function mongo_run_command(c: Pointer; db: PAnsiChar; command: Pointer; res: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_cmd_get_last_error(c: Pointer; db: PAnsiChar; res: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_cmd_get_prev_error(c: Pointer; db: PAnsiChar; res: Pointer): Integer; cdecl; external MongoCDLL;
  procedure mongo_cmd_reset_error(c : Pointer; db : PAnsiChar); cdecl; external MongoCDLL;
  function mongo_get_server_err(c: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_get_server_err_string(c: Pointer): PAnsiChar; cdecl; external MongoCDLL;
  procedure mongo_write_concern_init(write_concern : pointer); cdecl; external MongoCDLL;
  function mongo_write_concern_finish(write_concern : pointer) : integer; cdecl; external MongoCDLL;
  procedure mongo_write_concern_destroy(write_concern : pointer); cdecl; external MongoCDLL;
  procedure mongo_set_write_concern(conn : pointer; write_concern : pointer); cdecl; external MongoCDLL;
  // MongoBson declarations
  procedure bson_free(b : pointer); cdecl; external MongoCDLL;
  procedure bson_init(b: Pointer); cdecl; external MongoCDLL;
  procedure bson_destroy(b: Pointer); cdecl; external MongoCDLL;
  function bson_finish(b: Pointer): Integer; cdecl; external MongoCDLL;
  procedure bson_oid_gen(oid: Pointer); cdecl; external MongoCDLL;
  procedure bson_oid_to_string(oid: Pointer; s: PAnsiChar); cdecl; external MongoCDLL;
  procedure bson_oid_from_string(oid: Pointer; s: PAnsiChar); cdecl; external MongoCDLL;
  function bson_append_string(b: Pointer; Name: PAnsiChar; Value: PAnsiChar): Integer; cdecl; external MongoCDLL;
  function bson_append_code(b: Pointer; Name: PAnsiChar; Value: PAnsiChar): Integer; cdecl; external MongoCDLL;
  function bson_append_symbol(b: Pointer; Name: PAnsiChar; Value: PAnsiChar): Integer; cdecl; external MongoCDLL;
  function bson_append_int(b: Pointer; Name: PAnsiChar; Value: Integer): Integer; cdecl; external MongoCDLL;
  function bson_append_long(b: Pointer; Name: PAnsiChar; Value: Int64): Integer; cdecl; external MongoCDLL;
  function bson_append_double(b: Pointer; Name: PAnsiChar; Value: Double): Integer; cdecl; external MongoCDLL;
  function bson_append_date(b: Pointer; Name: PAnsiChar; Value: Int64): Integer; cdecl; external MongoCDLL;
  function bson_append_bool(b: Pointer; Name: PAnsiChar; Value: LongBool): Integer; cdecl; external MongoCDLL;
  function bson_append_null(b: Pointer; Name: PAnsiChar): Integer; cdecl; external MongoCDLL;
  function bson_append_undefined(b: Pointer; Name: PAnsiChar): Integer; cdecl; external MongoCDLL;
  function bson_append_start_object(b: Pointer; Name: PAnsiChar): Integer; cdecl; external MongoCDLL;
  function bson_append_start_array(b: Pointer; Name: PAnsiChar): Integer; cdecl; external MongoCDLL;
  function bson_append_finish_object(b: Pointer): Integer; cdecl; external MongoCDLL;
  function bson_append_oid(b: Pointer; Name: PAnsiChar; oid: Pointer): Integer; cdecl; external MongoCDLL;
  function bson_append_code_w_scope(b: Pointer; Name: PAnsiChar; code: PAnsiChar; scope: Pointer): Integer; cdecl; external MongoCDLL;
  function bson_append_regex(b: Pointer; Name: PAnsiChar; pattern: PAnsiChar; options: PAnsiChar): Integer; cdecl; external MongoCDLL;
  function bson_append_timestamp2(b: Pointer; Name: PAnsiChar; Time: Integer; increment: Integer): Integer; cdecl; external MongoCDLL;
  function bson_append_binary(b: Pointer; Name: PAnsiChar; Kind: Byte; Data: Pointer; Len: Integer): Integer; cdecl; external MongoCDLL;
  function bson_append_bson(b: Pointer; Name: PAnsiChar; Value: Pointer): Integer; cdecl; external MongoCDLL;
  function bson_buffer_size(b: Pointer): Integer; cdecl; external MongoCDLL;
  function bson_size(b: Pointer): Integer; cdecl; external MongoCDLL;
  function bson_iterator_create(): Pointer; cdecl; external MongoCDLL;
  procedure bson_iterator_dispose(i: Pointer); cdecl; external MongoCDLL;
  procedure bson_iterator_init(i: Pointer; b: Pointer); cdecl; external MongoCDLL;
  function bson_find(i: Pointer; b: Pointer; Name: PAnsiChar): TBsonType; cdecl; external MongoCDLL;
  function bson_iterator_type(i: Pointer): TBsonType; cdecl; external MongoCDLL;
  function bson_iterator_next(i: Pointer): TBsonType; cdecl; external MongoCDLL;
  function bson_iterator_key(i: Pointer): PAnsiChar; cdecl; external MongoCDLL;
  function bson_iterator_double(i: Pointer): Double; cdecl; external MongoCDLL;
  function bson_iterator_long(i: Pointer): Int64; cdecl; external MongoCDLL;
  function bson_iterator_int(i: Pointer): Integer; cdecl; external MongoCDLL;
  function bson_iterator_bool(i: Pointer): LongBool; cdecl; external MongoCDLL;
  function bson_iterator_string(i: Pointer): PAnsiChar; cdecl; external MongoCDLL;
  function bson_iterator_date(i: Pointer): Int64; cdecl; external MongoCDLL;
  procedure bson_iterator_subiterator(i: Pointer; sub: Pointer); cdecl; external MongoCDLL;
  function bson_iterator_oid(i: Pointer): Pointer; cdecl; external MongoCDLL;
  function bson_iterator_code(i: Pointer): PAnsiChar; cdecl; external MongoCDLL;
  procedure bson_iterator_code_scope(i: Pointer; b: Pointer); cdecl; external MongoCDLL;
  function bson_iterator_regex(i: Pointer): PAnsiChar; cdecl; external MongoCDLL;
  function bson_iterator_regex_opts(i: Pointer): PAnsiChar; cdecl; external MongoCDLL;
  function bson_iterator_timestamp_time(i: Pointer): Integer; cdecl; external MongoCDLL;
  function bson_iterator_timestamp_increment(i: Pointer): Integer; cdecl; external MongoCDLL;
  function bson_iterator_bin_len(i: Pointer): Integer; cdecl; external MongoCDLL;
  function bson_iterator_bin_type(i: Pointer): Byte; cdecl; external MongoCDLL;
  function bson_iterator_bin_data(i: Pointer): Pointer; cdecl; external MongoCDLL;
  function Int64toDouble(i64: Int64): Double; cdecl; external MongoCDLL Name 'bson_int64_to_double';
  function set_bson_err_handler(newErrorHandler : Pointer) : Pointer; cdecl; external MongoCDLL;
  // GridFS declarations
  function gridfs_create: Pointer; cdecl; external MongoCDLL;
  procedure gridfs_dispose(g: Pointer); cdecl; external MongoCDLL;
  function gridfs_init(c: Pointer; db: PAnsiChar; prefix: PAnsiChar; g: Pointer): Integer; cdecl; external MongoCDLL;
  procedure gridfs_destroy(g: Pointer); cdecl; external MongoCDLL;
  function gridfs_store_file(g: Pointer; FileName: PAnsiChar; remoteName: PAnsiChar; contentType: PAnsiChar; Flags : Integer): Integer; cdecl; external MongoCDLL;
  procedure gridfs_remove_filename(g: Pointer; remoteName: PAnsiChar); cdecl; external MongoCDLL;
  function gridfs_store_buffer(g: Pointer; p: Pointer; size: Int64; remoteName: PAnsiChar; contentType: PAnsiChar; Flags : Integer): Integer; cdecl; external MongoCDLL;
  function gridfile_create: Pointer; cdecl; external MongoCDLL;
  procedure gridfile_dispose(gf: Pointer); cdecl; external MongoCDLL;
  procedure gridfile_writer_init(gf: Pointer; gfs: Pointer; remoteName: PAnsiChar; contentType: PAnsiChar; Flags : Integer); cdecl; external MongoCDLL;
  procedure gridfile_write_buffer(gf: Pointer; Data: Pointer; Length: Int64); cdecl; external MongoCDLL;
  function gridfile_writer_done(gf: Pointer): Integer; cdecl; external MongoCDLL;
  function gridfs_find_query(g: Pointer; query: Pointer; gf: Pointer): Integer; cdecl; external MongoCDLL;
  procedure gridfile_destroy(gf: Pointer); cdecl; external MongoCDLL;
  function gridfile_get_filename(gf: Pointer): PAnsiChar; cdecl; external MongoCDLL;
  function gridfile_get_chunksize(gf: Pointer): Integer; cdecl; external MongoCDLL;
  function gridfile_get_contentlength(gf: Pointer): Int64; cdecl; external MongoCDLL;
  function gridfile_get_contenttype(gf: Pointer): PAnsiChar; cdecl; external MongoCDLL;
  function gridfile_get_uploaddate(gf: Pointer): Int64; cdecl; external MongoCDLL;
  function gridfile_get_md5(gf: Pointer): PAnsiChar; cdecl; external MongoCDLL;
  procedure gridfile_get_metadata(gf: Pointer; b: Pointer); cdecl; external MongoCDLL;
  function gridfile_get_numchunks(gf: Pointer): Integer; cdecl; external MongoCDLL;
  procedure gridfile_get_descriptor(gf: Pointer; b: Pointer); cdecl; external MongoCDLL;
  procedure gridfile_get_chunk(gf: Pointer; i: Integer; b: Pointer); cdecl; external MongoCDLL;
  function gridfile_get_chunks(gf: Pointer; i: Integer; Count: Integer): Pointer; cdecl; external MongoCDLL;
  function gridfile_read(gf: Pointer; size: Int64; buf: Pointer): Int64; cdecl; external MongoCDLL;
  function gridfile_seek(gf: Pointer; offset: Int64): Int64; cdecl; external MongoCDLL;
  function gridfile_init(gfs, meta, gfile : pointer) : integer; cdecl; external MongoCDLL;
  function gridfile_get_id(gfile : pointer) : pointer; cdecl; external MongoCDLL;
  function gridfile_truncate(gfile : Pointer; newSize : int64) : Int64; cdecl; external MongoCDLL;
  function gridfs_get_caseInsensitive (gf : Pointer) : LongBool; cdecl; external MongoCDLL;
  procedure gridfs_set_caseInsensitive(gf : Pointer; newValue : LongBool); cdecl; external MongoCDLL;
  procedure gridfile_set_flags(gf : Pointer; Flags : Integer); cdecl; external MongoCDLL;
  function gridfile_get_flags(gf : Pointer) : Integer; cdecl; external MongoCDLL;
  function initPrepostChunkProcessing(flags : integer) : integer; cdecl; external MongoCDLL;

{$EndIf}

implementation

{$IFDEF OnDemandMongoCLoad}
resourcestring
  SFailedLoadingMongocDll = 'Failed loading mongoc.dll';
  SFunctionNotFoundOnMongoCLibrary = 'Function "%s" not found on MongoC library';
{$ENDIF}

procedure DefaultMongoErrorHandler(const Msg : PAnsiChar); cdecl;
begin
  raise EMongoFatalError.Create(string(Msg));
end;

procedure MongoAPIInit;
begin
  mongo_sock_init;
  initPrepostChunkProcessing(0);
  set_bson_err_handler(@DefaultMongoErrorHandler);
end;

{$IFDEF OnDemandMongoCLoad}
procedure InitMongoDBLibrary;
  function GetProcAddress(h : HMODULE; const FnName : AnsiString) : Pointer;
  begin
    Result := Windows.GetProcAddress(h, PAnsiChar(FnName));
    if Result = nil then
      raise Exception.CreateFmt(SFunctionNotFoundOnMongoCLibrary, [FnName]);
  end;
begin
  if HMongoDBDll <> 0 then
    exit;
  HMongoDBDll := LoadLibrary(MongoCDLL);
  if HMongoDBDll = 0 then
    raise Exception.Create(SFailedLoadingMongocDll);
  // MongoDB initializations
  mongo_sock_init := GetProcAddress(HMongoDBDll, 'mongo_sock_init');
  mongo_create := GetProcAddress(HMongoDBDll, 'mongo_create');
  mongo_dispose := GetProcAddress(HMongoDBDll, 'mongo_dispose');
  mongo_connect := GetProcAddress(HMongoDBDll, 'mongo_connect');
  mongo_destroy := GetProcAddress(HMongoDBDll, 'mongo_destroy');
  mongo_replset_init := GetProcAddress(HMongoDBDll, 'mongo_replset_init');
  mongo_replset_add_seed := GetProcAddress(HMongoDBDll, 'mongo_replset_add_seed');
  mongo_replset_connect := GetProcAddress(HMongoDBDll, 'mongo_replset_connect');
  mongo_is_connected := GetProcAddress(HMongoDBDll, 'mongo_is_connected');
  mongo_get_err := GetProcAddress(HMongoDBDll, 'mongo_get_err');
  mongo_set_op_timeout := GetProcAddress(HMongoDBDll, 'mongo_set_op_timeout');
  mongo_get_op_timeout := GetProcAddress(HMongoDBDll, 'mongo_get_op_timeout');
  mongo_get_primary := GetProcAddress(HMongoDBDll, 'mongo_get_primary');
  mongo_check_connection := GetProcAddress(HMongoDBDll, 'mongo_check_connection');
  mongo_disconnect := GetProcAddress(HMongoDBDll, 'mongo_disconnect');
  mongo_reconnect := GetProcAddress(HMongoDBDll, 'mongo_reconnect');
  mongo_cmd_ismaster := GetProcAddress(HMongoDBDll, 'mongo_cmd_ismaster');
  mongo_get_socket := GetProcAddress(HMongoDBDll, 'mongo_get_socket');
  mongo_get_host_count := GetProcAddress(HMongoDBDll, 'mongo_get_host_count');
  mongo_get_host := GetProcAddress(HMongoDBDll, 'mongo_get_host');
  mongo_insert := GetProcAddress(HMongoDBDll, 'mongo_insert');
  mongo_insert_batch := GetProcAddress(HMongoDBDll, 'mongo_insert_batch');
  mongo_update := GetProcAddress(HMongoDBDll, 'mongo_update');
  mongo_remove := GetProcAddress(HMongoDBDll, 'mongo_remove');
  mongo_find_one := GetProcAddress(HMongoDBDll, 'mongo_find_one');
  bson_create := GetProcAddress(HMongoDBDll, 'bson_create');
  bson_dispose := GetProcAddress(HMongoDBDll, 'bson_dispose');
  bson_copy := GetProcAddress(HMongoDBDll, 'bson_copy');
  mongo_cursor_create := GetProcAddress(HMongoDBDll, 'mongo_cursor_create');
  mongo_cursor_dispose := GetProcAddress(HMongoDBDll, 'mongo_cursor_dispose');
  mongo_cursor_destroy := GetProcAddress(HMongoDBDll, 'mongo_cursor_destroy');
  mongo_find := GetProcAddress(HMongoDBDll, 'mongo_find');
  mongo_cursor_next := GetProcAddress(HMongoDBDll, 'mongo_cursor_next');
  mongo_cursor_bson := GetProcAddress(HMongoDBDll, 'mongo_cursor_bson');
  mongo_cmd_drop_collection := GetProcAddress(HMongoDBDll, 'mongo_cmd_drop_collection');
  mongo_cmd_drop_db := GetProcAddress(HMongoDBDll, 'mongo_cmd_drop_db');
  mongo_count := GetProcAddress(HMongoDBDll, 'mongo_count');
  mongo_create_index := GetProcAddress(HMongoDBDll, 'mongo_create_index');
  mongo_cmd_add_user := GetProcAddress(HMongoDBDll, 'mongo_cmd_add_user');
  mongo_cmd_authenticate := GetProcAddress(HMongoDBDll, 'mongo_cmd_authenticate');
  mongo_run_command := GetProcAddress(HMongoDBDll, 'mongo_run_command');
  mongo_cmd_get_last_error := GetProcAddress(HMongoDBDll, 'mongo_cmd_get_last_error');
  mongo_cmd_get_prev_error := GetProcAddress(HMongoDBDll, 'mongo_cmd_get_prev_error');
  mongo_cmd_reset_error := GetProcAddress(HMongoDBDll, 'mongo_cmd_reset_error');
  mongo_get_server_err := GetProcAddress(HMongoDBDll, 'mongo_get_server_err');
  mongo_get_server_err_string := GetProcAddress(HMongoDBDll, 'mongo_get_server_err_string');
  mongo_write_concern_init := GetProcAddress(HMongoDBDll, 'mongo_write_concern_init');
  mongo_write_concern_finish := GetProcAddress(HMongoDBDll, 'mongo_write_concern_finish');
  mongo_write_concern_destroy := GetProcAddress(HMongoDBDll, 'mongo_write_concern_destroy');
  mongo_set_write_concern := GetProcAddress(HMongoDBDll, 'mongo_set_write_concern');
  // MongoBson initializations
  bson_free := GetProcAddress(HMongoDBDll, 'bson_free');
  bson_create := GetProcAddress(HMongoDBDll, 'bson_create');
  bson_init := GetProcAddress(HMongoDBDll, 'bson_init');
  bson_destroy := GetProcAddress(HMongoDBDll, 'bson_destroy');
  bson_dispose := GetProcAddress(HMongoDBDll, 'bson_dispose');
  bson_copy := GetProcAddress(HMongoDBDll, 'bson_copy');
  bson_finish := GetProcAddress(HMongoDBDll, 'bson_finish');
  bson_oid_gen := GetProcAddress(HMongoDBDll, 'bson_oid_gen');
  bson_oid_to_string := GetProcAddress(HMongoDBDll, 'bson_oid_to_string');
  bson_oid_from_string := GetProcAddress(HMongoDBDll, 'bson_oid_from_string');
  bson_append_string := GetProcAddress(HMongoDBDll, 'bson_append_string');
  bson_append_code := GetProcAddress(HMongoDBDll, 'bson_append_code');
  bson_append_symbol := GetProcAddress(HMongoDBDll, 'bson_append_symbol');
  bson_append_int := GetProcAddress(HMongoDBDll, 'bson_append_int');
  bson_append_long := GetProcAddress(HMongoDBDll, 'bson_append_long');
  bson_append_double := GetProcAddress(HMongoDBDll, 'bson_append_double');
  bson_append_date := GetProcAddress(HMongoDBDll, 'bson_append_date');
  bson_append_bool := GetProcAddress(HMongoDBDll, 'bson_append_bool');
  bson_append_null := GetProcAddress(HMongoDBDll, 'bson_append_null');
  bson_append_undefined := GetProcAddress(HMongoDBDll, 'bson_append_undefined');
  bson_append_start_object := GetProcAddress(HMongoDBDll, 'bson_append_start_object');
  bson_append_start_array := GetProcAddress(HMongoDBDll, 'bson_append_start_array');
  bson_append_finish_object := GetProcAddress(HMongoDBDll, 'bson_append_finish_object');
  bson_append_oid := GetProcAddress(HMongoDBDll, 'bson_append_oid');
  bson_append_code_w_scope := GetProcAddress(HMongoDBDll, 'bson_append_code_w_scope');
  bson_append_regex := GetProcAddress(HMongoDBDll, 'bson_append_regex');
  bson_append_timestamp2 := GetProcAddress(HMongoDBDll, 'bson_append_timestamp2');
  bson_append_binary := GetProcAddress(HMongoDBDll, 'bson_append_binary');
  bson_append_bson := GetProcAddress(HMongoDBDll, 'bson_append_bson');
  bson_buffer_size := GetProcAddress(HMongoDBDll, 'bson_buffer_size');
  bson_size := GetProcAddress(HMongoDBDll, 'bson_size');
  bson_iterator_create := GetProcAddress(HMongoDBDll, 'bson_iterator_create');
  bson_iterator_dispose := GetProcAddress(HMongoDBDll, 'bson_iterator_dispose');
  bson_iterator_init := GetProcAddress(HMongoDBDll, 'bson_iterator_init');
  bson_find := GetProcAddress(HMongoDBDll, 'bson_find');
  bson_iterator_type := GetProcAddress(HMongoDBDll, 'bson_iterator_type');
  bson_iterator_next := GetProcAddress(HMongoDBDll, 'bson_iterator_next');
  bson_iterator_key := GetProcAddress(HMongoDBDll, 'bson_iterator_key');
  bson_iterator_double := GetProcAddress(HMongoDBDll, 'bson_iterator_double');
  bson_iterator_long := GetProcAddress(HMongoDBDll, 'bson_iterator_long');
  bson_iterator_int := GetProcAddress(HMongoDBDll, 'bson_iterator_int');
  bson_iterator_bool := GetProcAddress(HMongoDBDll, 'bson_iterator_bool');
  bson_iterator_string := GetProcAddress(HMongoDBDll, 'bson_iterator_string');
  bson_iterator_date:= GetProcAddress(HMongoDBDll, 'bson_iterator_date');
  bson_iterator_subiterator := GetProcAddress(HMongoDBDll, 'bson_iterator_subiterator');
  bson_iterator_oid := GetProcAddress(HMongoDBDll, 'bson_iterator_oid');
  bson_iterator_code := GetProcAddress(HMongoDBDll, 'bson_iterator_code');
  bson_iterator_code_scope := GetProcAddress(HMongoDBDll, 'bson_iterator_code_scope');
  bson_iterator_regex := GetProcAddress(HMongoDBDll, 'bson_iterator_regex');
  bson_iterator_regex_opts := GetProcAddress(HMongoDBDll, 'bson_iterator_regex_opts');
  bson_iterator_timestamp_time := GetProcAddress(HMongoDBDll, 'bson_iterator_timestamp_time');
  bson_iterator_timestamp_increment := GetProcAddress(HMongoDBDll, 'bson_iterator_timestamp_increment');
  bson_iterator_bin_len := GetProcAddress(HMongoDBDll, 'bson_iterator_bin_len');
  bson_iterator_bin_type := GetProcAddress(HMongoDBDll, 'bson_iterator_bin_type');
  bson_iterator_bin_data := GetProcAddress(HMongoDBDll, 'bson_iterator_bin_data');
  set_bson_err_handler := GetProcAddress(HMongoDBDll, 'set_bson_err_handler');
  // GridFS functions
  gridfs_create := GetProcAddress(HMongoDBDll, 'gridfs_create');
  gridfs_dispose := GetProcAddress(HMongoDBDll, 'gridfs_dispose');
  gridfs_init := GetProcAddress(HMongoDBDll, 'gridfs_init');
  gridfs_destroy := GetProcAddress(HMongoDBDll, 'gridfs_destroy');
  gridfs_store_file := GetProcAddress(HMongoDBDll, 'gridfs_store_file');
  gridfs_remove_filename := GetProcAddress(HMongoDBDll, 'gridfs_remove_filename');
  gridfs_store_buffer := GetProcAddress(HMongoDBDll, 'gridfs_store_buffer');
  gridfile_create := GetProcAddress(HMongoDBDll, 'gridfile_create');
  gridfile_dispose := GetProcAddress(HMongoDBDll, 'gridfile_dispose');
  gridfile_writer_init := GetProcAddress(HMongoDBDll, 'gridfile_writer_init');
  gridfile_write_buffer := GetProcAddress(HMongoDBDll, 'gridfile_write_buffer');
  gridfile_writer_done := GetProcAddress(HMongoDBDll, 'gridfile_writer_done');
  gridfs_find_query := GetProcAddress(HMongoDBDll, 'gridfs_find_query');
  gridfile_destroy := GetProcAddress(HMongoDBDll, 'gridfile_destroy');
  gridfile_get_filename := GetProcAddress(HMongoDBDll, 'gridfile_get_filename');
  gridfile_get_chunksize := GetProcAddress(HMongoDBDll, 'gridfile_get_chunksize');
  gridfile_get_contentlength := GetProcAddress(HMongoDBDll, 'gridfile_get_contentlength');
  gridfile_get_contenttype:= GetProcAddress(HMongoDBDll, 'gridfile_get_contenttype');
  gridfile_get_uploaddate := GetProcAddress(HMongoDBDll, 'gridfile_get_uploaddate');
  gridfile_get_md5 := GetProcAddress(HMongoDBDll, 'gridfile_get_md5');
  gridfile_get_metadata := GetProcAddress(HMongoDBDll, 'gridfile_get_metadata');
  gridfile_get_numchunks := GetProcAddress(HMongoDBDll, 'gridfile_get_numchunks');
  gridfile_get_descriptor := GetProcAddress(HMongoDBDll, 'gridfile_get_descriptor');
  gridfile_get_chunk:= GetProcAddress(HMongoDBDll, 'gridfile_get_chunk');
  gridfile_get_chunks := GetProcAddress(HMongoDBDll, 'gridfile_get_chunks');
  gridfile_read := GetProcAddress(HMongoDBDll, 'gridfile_read');
  gridfile_seek := GetProcAddress(HMongoDBDll, 'gridfile_seek');
  gridfile_init := GetProcAddress(HMongoDBDll, 'gridfile_init');
  gridfile_get_id := GetProcAddress(HMongoDBDll, 'gridfile_get_id');
  gridfile_truncate := GetProcAddress(HMongoDBDll, 'gridfile_truncate');
  gridfs_get_caseInsensitive := GetProcAddress(HMongoDBDll, 'gridfs_get_caseInsensitive');
  gridfs_set_caseInsensitive := GetProcAddress(HMongoDBDll, 'gridfs_set_caseInsensitive');
  gridfile_set_flags := GetProcAddress(HMongoDBDll, 'gridfile_set_flags');
  gridfile_get_flags := GetProcAddress(HMongoDBDll, 'gridfile_get_flags');
  initPrepostChunkProcessing := GetProcAddress(HMongoDBDll, 'initPrepostChunkProcessing');

  Int64toDouble := GetProcAddress(HMongoDBDll, 'bson_int64_to_double');
  MongoAPIInit;
end;

procedure DoneMongoDBLibrary;
begin
  if HMongoDBDll <> 0 then
    begin
      FreeLibrary(HMongoDBDll);
      HMongoDBDll := 0;
    end;
end;

{$ENDIF}

{ TMongoBaseClass }

constructor TMongoBaseClass.Create;
begin
  inherited;
  MongoSignature := DELPHI_MONGO_SIGNATURE;
end;

destructor TMongoBaseClass.Destroy;
begin
  CheckValid;
  inherited;
  MongoSignature := 0;
end;

procedure TMongoBaseClass.CheckValid;
begin
  if (Self = nil) or (MongoSignature <> DELPHI_MONGO_SIGNATURE) then
    raise EMongoFatalError.Create('Delphi Mongo error failed signature validation');
end;

{ TMongoNonInterfacedBaseClass }

constructor TMongoNonInterfacedBaseClass.Create;
begin
  inherited;
  MongoSignature := DELPHI_MONGO_SIGNATURE;
end;

destructor TMongoNonInterfacedBaseClass.Destroy;
begin
  CheckValid;
  inherited;
  MongoSignature := 0;
end;

procedure TMongoNonInterfacedBaseClass.CheckValid;
begin
  if (Self = nil) or (MongoSignature <> DELPHI_MONGO_SIGNATURE) then
    raise EMongoFatalError.Create('Delphi Mongo error failed signature validation');
end;

initialization
{$IFNDEF OnDemandMongoCLoad}
  MongoAPIInit;
{$ENDIF}
finalization
{$IFDEF OnDemandMongoCLoad}
  DoneMongoDBLibrary;
{$ENDIF}
end.
