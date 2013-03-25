unit MongoAPI;

interface

{$I MongoC_defines.inc}

uses
  Windows, SysUtils;

const
  MongoCDLL = 'mongoc.dll';

type
  {$IFNDEF DELPHI2007}
  UTF8String = AnsiString;
  NativeUInt = Cardinal;
  UInt64 = Int64;
  {$ENDIF}
  PBsonOIDValue = ^TBsonOIDValue;
  TBsonOIDValue = array[0..11] of Byte;
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
  TMongoInterfacedObject = class(TInterfacedObject)
  public
    constructor Create;
    destructor Destroy; override;
  end;

type
  TMongoObject = class(TObject)
  public
    constructor Create;
    destructor Destroy; override;
  end;

{$IFDEF OnDemandMongoCLoad}
type
  // MongoDB declarations
  Tset_mem_alloc_functions = procedure (custom_bson_malloc_func,
                                        custom_bson_realloc_func,
                                        custom_bson_free_func : Pointer); cdecl;
  Tmongo_env_sock_init = function : integer; cdecl;
  Tmongo_alloc = function : Pointer; cdecl;
  Tmongo_dealloc = procedure (c: Pointer); cdecl;
  Tmongo_client = function (c: Pointer; host: PAnsiChar; port: Integer): Integer; cdecl;
  Tmongo_destroy = procedure(c: Pointer); cdecl;
  Tmongo_replica_set_init = procedure (c: Pointer; Name: PAnsiChar); cdecl;
  Tmongo_replica_set_add_seed = procedure (c: Pointer; host: PAnsiChar; port: Integer); cdecl;
  Tmongo_replica_set_client = function(c: Pointer): Integer; cdecl;
  Tmongo_is_connected = function (c: Pointer): LongBool; cdecl;
  Tmongo_get_err = function(c: Pointer): Integer; cdecl;
  Tmongo_set_op_timeout = function (c: Pointer; millis: Integer): Integer; cdecl;
  Tmongo_get_op_timeout = function (c: Pointer): Integer; cdecl;
  Tmongo_get_primary = function (c: Pointer): PAnsiChar; cdecl;
  Tmongo_check_connection = function (c: Pointer): Integer; cdecl;
  Tmongo_disconnect = procedure (c: Pointer); cdecl;
  Tmongo_reconnect = function (c: Pointer): Integer; cdecl;
  Tmongo_cmd_ismaster = function (c: Pointer; b: Pointer): Longbool; cdecl;
  Tmongo_get_socket = function (c: Pointer): Pointer; cdecl;
  Tmongo_get_host_count = function (c: Pointer): Integer; cdecl;
  Tmongo_get_host = function (c: Pointer; i: Integer): PAnsiChar; cdecl;
  Tmongo_insert = function (c: Pointer; ns: PAnsiChar; b: Pointer; wc: Pointer): Integer; cdecl;
  Tmongo_insert_batch = function (c: Pointer; ns: PAnsiChar; bsons: Pointer; Count: Integer; wc: Pointer; flags: Integer): Integer; cdecl;
  Tmongo_update = function (c: Pointer; ns: PAnsiChar; cond: Pointer; op: Pointer; flags: Integer; wc: Pointer): Integer; cdecl;
  Tmongo_remove = function (c: Pointer; ns: PAnsiChar; criteria: Pointer; wc: Pointer): Integer; cdecl;
  Tmongo_find_one = function (c: Pointer; ns: PAnsiChar; query: Pointer; fields: Pointer; Result: Pointer): Integer; cdecl;
  Tbson_alloc = function : Pointer; cdecl;
  Tbson_dealloc = procedure (b: Pointer); cdecl;
  Tbson_copy = procedure (dest: Pointer; src: Pointer); cdecl;
  Tmongo_cursor_alloc = function : Pointer; cdecl;
  Tmongo_cursor_dealloc = procedure (Cursor: Pointer); cdecl;
  Tmongo_cursor_destroy = procedure (Cursor: Pointer); cdecl;
  Tmongo_find = function (c: Pointer; ns: PAnsiChar; query: Pointer; fields: Pointer; limit, skip, options: Integer): Pointer; cdecl;
  Tmongo_cursor_next = function (Cursor: Pointer): Integer; cdecl;
  Tmongo_cursor_bson = function (Cursor: Pointer): Pointer; cdecl;
  Tmongo_cmd_drop_collection = function (c: Pointer; db: PAnsiChar; collection: PAnsiChar; Result: Pointer): Integer; cdecl;
  Tmongo_cmd_drop_db = function (c: Pointer; db: PAnsiChar): Integer; cdecl;
  Tmongo_count = function (c: Pointer; db: PAnsiChar; collection: PAnsiChar; query: Pointer): Double; cdecl;
  Tmongo_create_index = function (c: Pointer; ns: PAnsiChar; key: Pointer; name : PAnsiChar; options: Integer; res: Pointer): Integer; cdecl;
  Tmongo_cmd_add_user = function (c: Pointer; db: PAnsiChar; Name: PAnsiChar; password: PAnsiChar): Integer; cdecl;
  Tmongo_cmd_authenticate = function (c: Pointer; db: PAnsiChar; Name: PAnsiChar; password: PAnsiChar): Integer; cdecl;
  Tmongo_run_command = function (c: Pointer; db: PAnsiChar; command: Pointer; res: Pointer): Integer; cdecl;
  Tmongo_cmd_get_last_error = function (c: Pointer; db: PAnsiChar; res: Pointer): Integer; cdecl;
  Tmongo_cmd_get_prev_error = function (c: Pointer; db: PAnsiChar; res: Pointer): Integer; cdecl;
  Tmongo_cmd_reset_error = procedure(c : Pointer; db : PAnsiChar); cdecl;
  Tmongo_get_server_err = function (c: Pointer): Integer; cdecl;
  Tmongo_get_server_err_string = function (c: Pointer): PAnsiChar; cdecl;
  // WriteConcern API
  Tmongo_write_concern_alloc = function : Pointer; cdecl;
  Tmongo_write_concern_dealloc = procedure (write_concern : Pointer); cdecl;
  Tmongo_write_concern_init = procedure(write_concern : pointer); cdecl;
  Tmongo_write_concern_finish = function(write_concern : pointer) : integer; cdecl;
  Tmongo_write_concern_destroy = procedure(write_concern : pointer); cdecl;
  Tmongo_set_write_concern = procedure(conn : pointer; write_concern : pointer); cdecl;
  Tmongo_write_concern_get_w = function (write_concern : Pointer) : integer; cdecl;
  Tmongo_write_concern_get_wtimeout = function(write_concern : Pointer) : integer; cdecl;
  Tmongo_write_concern_get_j = function(write_concern : Pointer) : integer; cdecl;
  Tmongo_write_concern_get_fsync = function(write_concern : Pointer) : integer; cdecl;
  Tmongo_write_concern_get_mode = function(write_concern : Pointer) : PAnsiChar; cdecl;
  Tmongo_write_concern_get_cmd = function(write_concern : Pointer) : Pointer; cdecl;
  Tmongo_write_concern_set_w = procedure(write_concern : Pointer; w : integer); cdecl;
  Tmongo_write_concern_set_wtimeout = procedure(write_concern : Pointer; wtimeout : integer); cdecl;
  Tmongo_write_concern_set_j = procedure(write_concern : Pointer; j : integer); cdecl;
  Tmongo_write_concern_set_fsync = procedure(write_concern : Pointer; fsync : integer); cdecl;
  Tmongo_write_concern_set_mode = procedure(write_concern : Pointer; mode : PAnsiChar); cdecl;
  // MongoBSON declarations
  Tbson_free = procedure (b : pointer); cdecl;
  Tbson_init = function (b: Pointer) : integer; cdecl;
  Tbson_init_empty = function (b : Pointer) : integer; cdecl;
  Tbson_destroy = procedure (b: Pointer); cdecl;
  Tbson_finish = function (b: Pointer): Integer; cdecl;
  Tbson_oid_gen = procedure (oid: Pointer); cdecl;
  Tbson_set_oid_inc = procedure (proc : pointer); cdecl;
  Tbson_set_oid_fuzz = procedure (proc : pointer); cdecl;
  Tbson_oid_to_string = procedure (oid: Pointer; s: PAnsiChar); cdecl;
  Tbson_oid_from_string = procedure (oid: Pointer; s: PAnsiChar); cdecl;
  Tbson_append_string = function (b: Pointer; Name: PAnsiChar; Value: PAnsiChar): Integer; cdecl;
  Tbson_append_string_n = function (b: Pointer; Name: PAnsiChar; Value: PAnsiChar; Len : NativeUInt): Integer; cdecl;
  Tbson_append_code = function (b: Pointer; Name: PAnsiChar; Value: PAnsiChar): Integer; cdecl;
  Tbson_append_code_n = function (b: Pointer; Name: PAnsiChar; Value: PAnsiChar; Len : NativeUInt): Integer; cdecl;
  Tbson_append_symbol = function (b: Pointer; Name: PAnsiChar; Value: PAnsiChar): Integer; cdecl;
  Tbson_append_symbol_n = function (b: Pointer; Name: PAnsiChar; Value: PAnsiChar; Len : NativeUInt): Integer; cdecl;
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
  Tbson_append_binary = function (b: Pointer; Name: PAnsiChar; Kind: Byte; Data: Pointer; Len: NativeUInt): Integer; cdecl;
  Tbson_append_bson = function (b: Pointer; Name: PAnsiChar; Value: Pointer): Integer; cdecl;
  Tbson_buffer_size = function (b: Pointer): NativeUInt; cdecl;
  Tbson_size = function (b: Pointer): Integer; cdecl;
  Tbson_iterator_alloc = function (): Pointer; cdecl;
  Tbson_iterator_dealloc = procedure (i: Pointer); cdecl;
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
  Tbson_iterator_code_scope_init = procedure (i: Pointer; b: Pointer); cdecl;
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
  Tgridfs_alloc = function : Pointer; cdecl;
  Tgridfs_dealloc = procedure (g: Pointer); cdecl;
  Tgridfs_init = function (c: Pointer; db: PAnsiChar; prefix: PAnsiChar; g: Pointer): Integer; cdecl;
  Tgridfs_destroy = procedure (g: Pointer); cdecl;
  Tgridfs_store_file = function (g: Pointer; FileName: PAnsiChar; remoteName: PAnsiChar; contentType: PAnsiChar; Flags : Integer): Integer; cdecl;
  Tgridfs_remove_filename = procedure (g: Pointer; remoteName: PAnsiChar); cdecl;
  Tgridfs_store_buffer = function (g: Pointer; p: Pointer; size: UInt64; remoteName: PAnsiChar; contentType: PAnsiChar; Flags : Integer): Integer; cdecl;
  Tgridfile_create = function : Pointer; cdecl;
  Tgridfile_dealloc = procedure (gf: Pointer); cdecl;
  Tgridfile_writer_init = procedure (gf: Pointer; gfs: Pointer; remoteName: PAnsiChar; contentType: PAnsiChar; Flags : Integer); cdecl;
  Tgridfile_write_buffer = function (gf: Pointer; Data: Pointer; Length: UInt64) : UInt64; cdecl;
  Tgridfile_writer_done = function (gf: Pointer): Integer; cdecl;
  Tgridfs_find_query = function (g: Pointer; query: Pointer; gf: Pointer): Integer; cdecl;
  Tgridfile_destroy = procedure (gf: Pointer); cdecl;
  Tgridfile_get_filename = function (gf: Pointer): PAnsiChar; cdecl;
  Tgridfile_get_chunksize = function (gf: Pointer): Integer; cdecl;
  Tgridfile_get_contentlength = function (gf: Pointer): UInt64; cdecl;
  Tgridfile_get_contenttype = function (gf: Pointer): PAnsiChar; cdecl;
  Tgridfile_get_uploaddate = function (gf: Pointer): Int64; cdecl;
  Tgridfile_get_md5 = function (gf: Pointer): PAnsiChar; cdecl;
  Tgridfile_get_metadata = procedure (gf: Pointer; b: Pointer; copyData : LongBool); cdecl;
  Tgridfile_get_numchunks = function (gf: Pointer): Integer; cdecl;
  Tgridfile_get_descriptor = procedure (gf: Pointer; b: Pointer); cdecl;
  Tgridfile_get_chunk = procedure (gf: Pointer; i: Integer; b: Pointer); cdecl;
  Tgridfile_get_chunks = function (gf: Pointer; i: NativeUInt; Count: NativeUInt): Pointer; cdecl;
  Tgridfile_read = function (gf: Pointer; size: UInt64; buf: Pointer): UInt64; cdecl;
  Tgridfile_seek = function (gf: Pointer; offset: UInt64): UInt64; cdecl;
  Tgridfile_init = function (gfs, meta, gfile : pointer) : integer; cdecl;
  Tgridfile_get_id = function (gfile : pointer) : TBsonOIDValue; cdecl;
  Tgridfile_truncate = function (gfile : Pointer; newSize : UInt64) : UInt64; cdecl;
  Tgridfile_expand = function (gfile : Pointer; bytesToExpand : UInt64) : UInt64; cdecl;
  Tgridfile_set_size = function(gfile : Pointer; newSize : UInt64) : UInt64; cdecl;
  Tgridfs_get_caseInsensitive = function (gf : Pointer) : LongBool; cdecl;
  Tgridfs_set_caseInsensitive = procedure (gf : Pointer; newValue : LongBool); cdecl;
  Tgridfile_set_flags = procedure(gf : Pointer; Flags : Integer); cdecl;
  Tgridfile_get_flags = function(gf : Pointer) : Integer; cdecl;
  TinitPrepostChunkProcessing = function (flags : integer) : integer; cdecl;

var
  HMongoDBDll : HMODULE;
  // MongoDB declarations
  set_mem_alloc_functions : Tset_mem_alloc_functions;
  mongo_env_sock_init : Tmongo_env_sock_init;
  mongo_alloc : Tmongo_alloc;
  mongo_dealloc : Tmongo_dealloc;
  mongo_client : Tmongo_client;
  mongo_destroy : Tmongo_destroy;
  mongo_replica_set_init : Tmongo_replica_set_init;
  mongo_replica_set_add_seed : Tmongo_replica_set_add_seed;
  mongo_replica_set_client : Tmongo_replica_set_client;
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
  bson_alloc : Tbson_alloc;
  bson_dealloc : Tbson_dealloc;
  bson_copy : Tbson_copy;
  mongo_cursor_alloc : Tmongo_cursor_alloc;
  mongo_cursor_dealloc : Tmongo_cursor_dealloc;
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
  // WriteConcern API
  mongo_write_concern_alloc : Tmongo_write_concern_alloc;
  mongo_write_concern_dealloc : Tmongo_write_concern_dealloc;
  mongo_write_concern_init : Tmongo_write_concern_init;
  mongo_write_concern_finish : Tmongo_write_concern_finish;
  mongo_write_concern_destroy : Tmongo_write_concern_destroy;
  mongo_set_write_concern : Tmongo_set_write_concern;
  mongo_write_concern_get_w : Tmongo_write_concern_get_w;
  mongo_write_concern_get_wtimeout : Tmongo_write_concern_get_wtimeout;
  mongo_write_concern_get_j : Tmongo_write_concern_get_j;
  mongo_write_concern_get_fsync : Tmongo_write_concern_get_fsync;
  mongo_write_concern_get_mode : Tmongo_write_concern_get_mode;
  mongo_write_concern_get_cmd : Tmongo_write_concern_get_cmd;
  mongo_write_concern_set_w : Tmongo_write_concern_set_w;
  mongo_write_concern_set_wtimeout : Tmongo_write_concern_set_wtimeout;
  mongo_write_concern_set_j : Tmongo_write_concern_set_j;
  mongo_write_concern_set_fsync : Tmongo_write_concern_set_fsync;
  mongo_write_concern_set_mode : Tmongo_write_concern_set_mode;
  // MongoBson declarations
  bson_free : Tbson_free;
  bson_init : Tbson_init;
  bson_init_empty : Tbson_init_empty;
  bson_destroy : Tbson_destroy;
  bson_finish : Tbson_finish;
  bson_oid_gen : Tbson_oid_gen;
  bson_set_oid_inc : Tbson_set_oid_inc;
  bson_set_oid_fuzz : Tbson_set_oid_fuzz;
  bson_oid_to_string : Tbson_oid_to_string;
  bson_oid_from_string : Tbson_oid_from_string;
  bson_append_string : Tbson_append_string;
  bson_append_string_n : Tbson_append_string_n;
  bson_append_code : Tbson_append_code;
  bson_append_code_n : Tbson_append_code_n;
  bson_append_symbol : Tbson_append_symbol;
  bson_append_symbol_n : Tbson_append_symbol_n;
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
  bson_iterator_alloc : Tbson_iterator_alloc;
  bson_iterator_dealloc : Tbson_iterator_dealloc;
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
  bson_iterator_code_scope_init : Tbson_iterator_code_scope_init;
  bson_iterator_regex : Tbson_iterator_regex;
  bson_iterator_regex_opts : Tbson_iterator_regex_opts;
  bson_iterator_timestamp_time : Tbson_iterator_timestamp_time;
  bson_iterator_timestamp_increment : Tbson_iterator_timestamp_increment;
  bson_iterator_bin_len : Tbson_iterator_bin_len;
  bson_iterator_bin_type : Tbson_iterator_bin_type;
  bson_iterator_bin_data : Tbson_iterator_bin_data;
  set_bson_err_handler : Tset_bson_err_handler;
  // GridFS declarations
  gridfs_alloc : Tgridfs_alloc;
  gridfs_dealloc : Tgridfs_dealloc;
  gridfs_init : Tgridfs_init;
  gridfs_destroy : Tgridfs_destroy;
  gridfs_store_file : Tgridfs_store_file;
  gridfs_remove_filename : Tgridfs_remove_filename;
  gridfs_store_buffer : Tgridfs_store_buffer;
  gridfile_create : Tgridfile_create;
  gridfile_dealloc : Tgridfile_dealloc;
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
  gridfile_expand : Tgridfile_expand;
  gridfile_set_size : Tgridfile_set_size;
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
  procedure set_mem_alloc_functions (custom_bson_malloc_func,
                                     custom_bson_realloc_func,
                                     custom_bson_free_func : Pointer); cdecl; external MongoCDLL;
  function mongo_env_sock_init : integer; cdecl; external MongoCDLL;
  function mongo_alloc: Pointer; cdecl; external MongoCDLL;
  procedure mongo_dealloc(c: Pointer); cdecl; external MongoCDLL;
  function mongo_client(c: Pointer; host: PAnsiChar; port: Integer): Integer; cdecl; external MongoCDLL;
  procedure mongo_destroy(c: Pointer); cdecl; external MongoCDLL;
  procedure mongo_replica_set_init(c: Pointer; Name: PAnsiChar); cdecl; external MongoCDLL;
  procedure mongo_replica_set_add_seed(c: Pointer; host: PAnsiChar; port: Integer); cdecl; external MongoCDLL;
  function mongo_replica_set_client(c: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_is_connected(c: Pointer): Longbool; cdecl; external MongoCDLL;
  function mongo_get_err(c: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_set_op_timeout(c: Pointer; millis: Integer): Integer; cdecl; external MongoCDLL;
  function mongo_get_op_timeout(c: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_get_primary(c: Pointer): PAnsiChar; cdecl; external MongoCDLL;
  function mongo_check_connection(c: Pointer): Integer; cdecl; external MongoCDLL;
  procedure mongo_disconnect(c: Pointer); cdecl; external MongoCDLL;
  function mongo_reconnect(c: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_cmd_ismaster(c: Pointer; b: Pointer): Longbool; cdecl; external MongoCDLL;
  function mongo_get_socket(c: Pointer): Pointer; cdecl; external MongoCDLL;
  function mongo_get_host_count(c: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_get_host(c: Pointer; i: Integer): PAnsiChar; cdecl; external MongoCDLL;
  function mongo_insert(c: Pointer; ns: PAnsiChar; b: Pointer; wc: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_insert_batch(c: Pointer; ns: PAnsiChar; bsons: Pointer; Count: Integer; wc: Pointer; flags: Integer): Integer; cdecl; external MongoCDLL;
  function mongo_update(c: Pointer; ns: PAnsiChar; cond: Pointer; op: Pointer; flags: Integer; wc: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_remove(c: Pointer; ns: PAnsiChar; criteria: Pointer; wc: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_find_one(c: Pointer; ns: PAnsiChar; query: Pointer; fields: Pointer; Result: Pointer): Integer; cdecl; external MongoCDLL;
  function bson_alloc: Pointer; cdecl; external MongoCDLL;
  procedure bson_dealloc(b: Pointer); cdecl; external MongoCDLL;
  procedure bson_copy(dest: Pointer; src: Pointer); cdecl; external MongoCDLL;
  function mongo_cursor_alloc: Pointer; cdecl; external MongoCDLL;
  procedure mongo_cursor_dealloc(Cursor: Pointer); cdecl; external MongoCDLL;
  procedure mongo_cursor_destroy(Cursor: Pointer); cdecl; external MongoCDLL;
  function mongo_find(c: Pointer; ns: PAnsiChar; query: Pointer; fields: Pointer; limit, skip, options: Integer): Pointer; cdecl; external MongoCDLL;
  function mongo_cursor_next(Cursor: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_cursor_bson(Cursor: Pointer): Pointer; cdecl; external MongoCDLL;
  function mongo_cmd_drop_collection(c: Pointer; db: PAnsiChar; collection: PAnsiChar; Result: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_cmd_drop_db(c: Pointer; db: PAnsiChar): Integer; cdecl; external MongoCDLL;
  function mongo_count(c: Pointer; db: PAnsiChar; collection: PAnsiChar; query: Pointer): Double; cdecl; external MongoCDLL;
  function mongo_create_index(c: Pointer; ns: PAnsiChar; key: Pointer; name : PAnsiChar; options: Integer; res: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_cmd_add_user(c: Pointer; db: PAnsiChar; Name: PAnsiChar; password: PAnsiChar): Integer; cdecl; external MongoCDLL;
  function mongo_cmd_authenticate(c: Pointer; db: PAnsiChar; Name: PAnsiChar; password: PAnsiChar): Integer; cdecl; external MongoCDLL;
  function mongo_run_command(c: Pointer; db: PAnsiChar; command: Pointer; res: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_cmd_get_last_error(c: Pointer; db: PAnsiChar; res: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_cmd_get_prev_error(c: Pointer; db: PAnsiChar; res: Pointer): Integer; cdecl; external MongoCDLL;
  procedure mongo_cmd_reset_error(c : Pointer; db : PAnsiChar); cdecl; external MongoCDLL;
  function mongo_get_server_err(c: Pointer): Integer; cdecl; external MongoCDLL;
  function mongo_get_server_err_string(c: Pointer): PAnsiChar; cdecl; external MongoCDLL;
  // WriteConcern API functions
  function mongo_write_concern_alloc : Pointer; cdecl; external MongoCDLL;
  procedure mongo_write_concern_dealloc(write_concern : Pointer); cdecl; external MongoCDLL;
  procedure mongo_write_concern_init(write_concern : pointer); cdecl; external MongoCDLL;
  function mongo_write_concern_finish(write_concern : pointer) : integer; cdecl; external MongoCDLL;
  procedure mongo_write_concern_destroy(write_concern : pointer); cdecl; external MongoCDLL;
  procedure mongo_set_write_concern(conn : pointer; write_concern : pointer); cdecl; external MongoCDLL;
  function mongo_write_concern_get_w(write_concern : Pointer) : integer; cdecl; external MongoCDLL;
  function mongo_write_concern_get_wtimeout(write_concern : Pointer) : integer; cdecl; external MongoCDLL;
  function mongo_write_concern_get_j(write_concern : Pointer) : integer; cdecl; external MongoCDLL;
  function mongo_write_concern_get_fsync(write_concern : Pointer) : integer; cdecl; external MongoCDLL;
  function mongo_write_concern_get_mode(write_concern : Pointer) : PAnsiChar; cdecl; external MongoCDLL;
  function mongo_write_concern_get_cmd(write_concern : Pointer) : Pointer; cdecl; external MongoCDLL;
  procedure mongo_write_concern_set_w(write_concern : Pointer; w : integer); cdecl; external MongoCDLL;
  procedure mongo_write_concern_set_wtimeout(write_concern : Pointer; wtimeout : integer); cdecl; external MongoCDLL;
  procedure mongo_write_concern_set_j(write_concern : Pointer; j : integer); cdecl; external MongoCDLL;
  procedure mongo_write_concern_set_fsync(write_concern : Pointer; fsync : integer); cdecl; external MongoCDLL;
  procedure mongo_write_concern_set_mode(write_concern : Pointer; mode : PAnsiChar); cdecl; external MongoCDLL;
  // MongoBson declarations
  procedure bson_free(b : pointer); cdecl; external MongoCDLL;
  function bson_init(b: Pointer) : integer; cdecl; external MongoCDLL;
  function bson_init_empty(b : Pointer) : integer; cdecl; external MongoCDLL;
  procedure bson_destroy(b: Pointer); cdecl; external MongoCDLL;
  function bson_finish(b: Pointer): Integer; cdecl; external MongoCDLL;
  procedure bson_oid_gen(oid: Pointer); cdecl; external MongoCDLL;
  procedure bson_set_oid_inc (proc : pointer); cdecl; external MongoCDLL;
  procedure bson_set_oid_fuzz (proc : pointer); cdecl; external MongoCDLL;
  procedure bson_oid_to_string(oid: Pointer; s: PAnsiChar); cdecl; external MongoCDLL;
  procedure bson_oid_from_string(oid: Pointer; s: PAnsiChar); cdecl; external MongoCDLL;
  function bson_append_string(b: Pointer; Name: PAnsiChar; Value: PAnsiChar): Integer; cdecl; external MongoCDLL;
  function bson_append_string_n(b: Pointer; Name: PAnsiChar; Value: PAnsiChar; Len : NativeUInt): Integer; cdecl; external MongoCDLL;
  function bson_append_code(b: Pointer; Name: PAnsiChar; Value: PAnsiChar): Integer; cdecl; external MongoCDLL;
  function bson_append_code_n(b: Pointer; Name: PAnsiChar; Value: PAnsiChar; Len : NativeUInt): Integer; cdecl; external MongoCDLL;
  function bson_append_symbol(b: Pointer; Name: PAnsiChar; Value: PAnsiChar): Integer; cdecl; external MongoCDLL;
  function bson_append_symbol_n (b: Pointer; Name: PAnsiChar; Value: PAnsiChar; Len : NativeUInt): Integer; cdecl; external MongoCDLL;
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
  function bson_append_binary(b: Pointer; Name: PAnsiChar; Kind: Byte; Data: Pointer; Len: NativeUInt): Integer; cdecl; external MongoCDLL;
  function bson_append_bson(b: Pointer; Name: PAnsiChar; Value: Pointer): Integer; cdecl; external MongoCDLL;
  function bson_buffer_size(b: Pointer): NativeUInt; cdecl; external MongoCDLL;
  function bson_size(b: Pointer): Integer; cdecl; external MongoCDLL;
  function bson_iterator_alloc(): Pointer; cdecl; external MongoCDLL;
  procedure bson_iterator_dealloc(i: Pointer); cdecl; external MongoCDLL;
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
  procedure bson_iterator_code_scope_init(i: Pointer; b: Pointer); cdecl; external MongoCDLL;
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
  function gridfs_alloc: Pointer; cdecl; external MongoCDLL;
  procedure gridfs_dealloc(g: Pointer); cdecl; external MongoCDLL;
  function gridfs_init(c: Pointer; db: PAnsiChar; prefix: PAnsiChar; g: Pointer): Integer; cdecl; external MongoCDLL;
  procedure gridfs_destroy(g: Pointer); cdecl; external MongoCDLL;
  function gridfs_store_file(g: Pointer; FileName: PAnsiChar; remoteName: PAnsiChar; contentType: PAnsiChar; Flags : Integer): Integer; cdecl; external MongoCDLL;
  procedure gridfs_remove_filename(g: Pointer; remoteName: PAnsiChar); cdecl; external MongoCDLL;
  function gridfs_store_buffer(g: Pointer; p: Pointer; size: UInt64; remoteName: PAnsiChar; contentType: PAnsiChar; Flags : Integer): Integer; cdecl; external MongoCDLL;
  function gridfile_create: Pointer; cdecl; external MongoCDLL;
  procedure gridfile_dealloc(gf: Pointer); cdecl; external MongoCDLL;
  procedure gridfile_writer_init(gf: Pointer; gfs: Pointer; remoteName: PAnsiChar; contentType: PAnsiChar; Flags : Integer); cdecl; external MongoCDLL;
  function gridfile_write_buffer(gf: Pointer; Data: Pointer; Length: UInt64) : UInt64; cdecl; external MongoCDLL;
  function gridfile_writer_done(gf: Pointer): Integer; cdecl; external MongoCDLL;
  function gridfs_find_query(g: Pointer; query: Pointer; gf: Pointer): Integer; cdecl; external MongoCDLL;
  procedure gridfile_destroy(gf: Pointer); cdecl; external MongoCDLL;
  function gridfile_get_filename(gf: Pointer): PAnsiChar; cdecl; external MongoCDLL;
  function gridfile_get_chunksize(gf: Pointer): Integer; cdecl; external MongoCDLL;
  function gridfile_get_contentlength(gf: Pointer): UInt64; cdecl; external MongoCDLL;
  function gridfile_get_contenttype(gf: Pointer): PAnsiChar; cdecl; external MongoCDLL;
  function gridfile_get_uploaddate(gf: Pointer): Int64; cdecl; external MongoCDLL;
  function gridfile_get_md5(gf: Pointer): PAnsiChar; cdecl; external MongoCDLL;
  procedure gridfile_get_metadata(gf: Pointer; b: Pointer; copyData : LongBool); cdecl; external MongoCDLL;
  function gridfile_get_numchunks(gf: Pointer): Integer; cdecl; external MongoCDLL;
  procedure gridfile_get_descriptor(gf: Pointer; b: Pointer); cdecl; external MongoCDLL;
  procedure gridfile_get_chunk(gf: Pointer; i: Integer; b: Pointer); cdecl; external MongoCDLL;
  function gridfile_get_chunks(gf: Pointer; i: NativeUInt; Count: NativeUInt): Pointer; cdecl; external MongoCDLL;
  function gridfile_read(gf: Pointer; size: UInt64; buf: Pointer): UInt64; cdecl; external MongoCDLL;
  function gridfile_seek(gf: Pointer; offset: UInt64): UInt64; cdecl; external MongoCDLL;
  function gridfile_init(gfs, meta, gfile : pointer) : integer; cdecl; external MongoCDLL;
  function gridfile_get_id(gfile : pointer) : TBsonOIDValue; cdecl; external MongoCDLL;
  function gridfile_truncate(gfile : Pointer; newSize : UInt64) : UInt64; cdecl; external MongoCDLL;
  function gridfile_expand(gfile : Pointer; bytesToExpand : UInt64) : UInt64; cdecl; external MongoCDLL;
  function gridfile_set_size(gfile : Pointer; newSize : UInt64) : UInt64; cdecl; external MongoCDLL;
  function gridfs_get_caseInsensitive (gf : Pointer) : LongBool; cdecl; external MongoCDLL;
  procedure gridfs_set_caseInsensitive(gf : Pointer; newValue : LongBool); cdecl; external MongoCDLL;
  procedure gridfile_set_flags(gf : Pointer; Flags : Integer); cdecl; external MongoCDLL;
  function gridfile_get_flags(gf : Pointer) : Integer; cdecl; external MongoCDLL;
  function initPrepostChunkProcessing(flags : integer) : integer; cdecl; external MongoCDLL;

{$EndIf}

function mongo_write_concern_create: Pointer;
procedure bson_dealloc_and_destroy(bson : Pointer);
function bson_create: pointer;

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

function delphi_malloc(size : NativeUInt) : Pointer; cdecl;
begin
  GetMem(Result, Size);
end;

function delphi_realloc(p : Pointer; size : NativeUInt) : Pointer; cdecl;
begin
  Result := p;
  ReallocMem(Result, size);
end;

procedure delphi_free(p : pointer); cdecl;
begin
  FreeMem(p);
end;

procedure MongoAPIInit;
begin
  set_mem_alloc_functions(@delphi_malloc, @delphi_realloc, @delphi_free);
  mongo_env_sock_init;
  initPrepostChunkProcessing(0);
  set_bson_err_handler(@DefaultMongoErrorHandler);
end;

{$IFDEF OnDemandMongoCLoad}
procedure InitMongoDBLibrary;
  function GetProcAddress(h : HMODULE; const FnName : UTF8String) : Pointer;
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
  set_mem_alloc_functions := GetProcAddress(HMongoDBDll, 'set_mem_alloc_functions');
  mongo_env_sock_init := GetProcAddress(HMongoDBDll, 'mongo_env_sock_init');
  mongo_alloc := GetProcAddress(HMongoDBDll, 'mongo_alloc');
  mongo_dealloc := GetProcAddress(HMongoDBDll, 'mongo_dealloc');
  mongo_client := GetProcAddress(HMongoDBDll, 'mongo_client');
  mongo_destroy := GetProcAddress(HMongoDBDll, 'mongo_destroy');
  mongo_replica_set_init := GetProcAddress(HMongoDBDll, 'mongo_replica_set_init');
  mongo_replica_set_add_seed := GetProcAddress(HMongoDBDll, 'mongo_replica_set_add_seed');
  mongo_replica_set_client := GetProcAddress(HMongoDBDll, 'mongo_replica_set_client');
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
  bson_alloc := GetProcAddress(HMongoDBDll, 'bson_alloc');
  bson_dealloc := GetProcAddress(HMongoDBDll, 'bson_dealloc');
  bson_copy := GetProcAddress(HMongoDBDll, 'bson_copy');
  mongo_cursor_alloc := GetProcAddress(HMongoDBDll, 'mongo_cursor_alloc');
  mongo_cursor_dealloc := GetProcAddress(HMongoDBDll, 'mongo_cursor_dealloc');
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
  // WriteConcern API
  mongo_write_concern_alloc := GetProcAddress(HMongoDBDll, 'mongo_write_concern_alloc');
  mongo_write_concern_dealloc := GetProcAddress(HMongoDBDll, 'mongo_write_concern_dealloc');
  mongo_write_concern_init := GetProcAddress(HMongoDBDll, 'mongo_write_concern_init');
  mongo_write_concern_finish := GetProcAddress(HMongoDBDll, 'mongo_write_concern_finish');
  mongo_write_concern_destroy := GetProcAddress(HMongoDBDll, 'mongo_write_concern_destroy');
  mongo_set_write_concern := GetProcAddress(HMongoDBDll, 'mongo_set_write_concern');
  mongo_write_concern_get_w := GetProcAddress(HMongoDBDll, 'mongo_write_concern_get_w');
  mongo_write_concern_get_wtimeout := GetProcAddress(HMongoDBDll, 'mongo_write_concern_get_wtimeout');
  mongo_write_concern_get_j := GetProcAddress(HMongoDBDll, 'mongo_write_concern_get_j');
  mongo_write_concern_get_fsync := GetProcAddress(HMongoDBDll, 'mongo_write_concern_get_fsync');
  mongo_write_concern_get_mode := GetProcAddress(HMongoDBDll, 'mongo_write_concern_get_mode');
  mongo_write_concern_get_cmd := GetProcAddress(HMongoDBDll, 'mongo_write_concern_get_cmd');
  mongo_write_concern_set_w := GetProcAddress(HMongoDBDll, 'mongo_write_concern_set_w');
  mongo_write_concern_set_wtimeout := GetProcAddress(HMongoDBDll, 'mongo_write_concern_set_wtimeout');
  mongo_write_concern_set_j := GetProcAddress(HMongoDBDll, 'mongo_write_concern_set_j');
  mongo_write_concern_set_fsync := GetProcAddress(HMongoDBDll, 'mongo_write_concern_set_fsync');
  mongo_write_concern_set_mode := GetProcAddress(HMongoDBDll, 'mongo_write_concern_set_mode');
  // MongoBson initializations
  bson_free := GetProcAddress(HMongoDBDll, 'bson_free');
  bson_alloc := GetProcAddress(HMongoDBDll, 'bson_alloc');
  bson_init := GetProcAddress(HMongoDBDll, 'bson_init');
  bson_init_empty := GetProcAddress(HMongoDBDll, 'bson_init_empty');
  bson_destroy := GetProcAddress(HMongoDBDll, 'bson_destroy');
  bson_dealloc := GetProcAddress(HMongoDBDll, 'bson_dealloc');
  bson_copy := GetProcAddress(HMongoDBDll, 'bson_copy');
  bson_finish := GetProcAddress(HMongoDBDll, 'bson_finish');
  bson_oid_gen := GetProcAddress(HMongoDBDll, 'bson_oid_gen');
  bson_set_oid_inc := GetProcAddress(HMongoDBDll, 'bson_set_oid_inc');
  bson_set_oid_fuzz := GetProcAddress(HMongoDBDll, 'bson_set_oid_fuzz');
  bson_oid_to_string := GetProcAddress(HMongoDBDll, 'bson_oid_to_string');
  bson_oid_from_string := GetProcAddress(HMongoDBDll, 'bson_oid_from_string');
  bson_append_string := GetProcAddress(HMongoDBDll, 'bson_append_string');
  bson_append_string_n := GetProcAddress(HMongoDBDll, 'bson_append_string_n');
  bson_append_code := GetProcAddress(HMongoDBDll, 'bson_append_code');
  bson_append_code_n := GetProcAddress(HMongoDBDll, 'bson_append_code_n');
  bson_append_symbol := GetProcAddress(HMongoDBDll, 'bson_append_symbol');
  bson_append_symbol_n := GetProcAddress(HMongoDBDll, 'bson_append_symbol_n');
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
  bson_iterator_alloc := GetProcAddress(HMongoDBDll, 'bson_iterator_alloc');
  bson_iterator_dealloc := GetProcAddress(HMongoDBDll, 'bson_iterator_dealloc');
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
  bson_iterator_code_scope_init := GetProcAddress(HMongoDBDll, 'bson_iterator_code_scope_init');
  bson_iterator_regex := GetProcAddress(HMongoDBDll, 'bson_iterator_regex');
  bson_iterator_regex_opts := GetProcAddress(HMongoDBDll, 'bson_iterator_regex_opts');
  bson_iterator_timestamp_time := GetProcAddress(HMongoDBDll, 'bson_iterator_timestamp_time');
  bson_iterator_timestamp_increment := GetProcAddress(HMongoDBDll, 'bson_iterator_timestamp_increment');
  bson_iterator_bin_len := GetProcAddress(HMongoDBDll, 'bson_iterator_bin_len');
  bson_iterator_bin_type := GetProcAddress(HMongoDBDll, 'bson_iterator_bin_type');
  bson_iterator_bin_data := GetProcAddress(HMongoDBDll, 'bson_iterator_bin_data');
  set_bson_err_handler := GetProcAddress(HMongoDBDll, 'set_bson_err_handler');
  // GridFS functions
  gridfs_alloc := GetProcAddress(HMongoDBDll, 'gridfs_alloc');
  gridfs_dealloc := GetProcAddress(HMongoDBDll, 'gridfs_dealloc');
  gridfs_init := GetProcAddress(HMongoDBDll, 'gridfs_init');
  gridfs_destroy := GetProcAddress(HMongoDBDll, 'gridfs_destroy');
  gridfs_store_file := GetProcAddress(HMongoDBDll, 'gridfs_store_file');
  gridfs_remove_filename := GetProcAddress(HMongoDBDll, 'gridfs_remove_filename');
  gridfs_store_buffer := GetProcAddress(HMongoDBDll, 'gridfs_store_buffer');
  gridfile_create := GetProcAddress(HMongoDBDll, 'gridfile_create');
  gridfile_dealloc := GetProcAddress(HMongoDBDll, 'gridfile_dealloc');
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
  gridfile_expand := GetProcAddress(HMongoDBDll, 'gridfile_expand');
  gridfile_set_size := GetProcAddress(HMongoDBDll, 'gridfile_set_size');
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

{ TMongoInterfacedObject }

constructor TMongoInterfacedObject.Create;
begin
  inherited;
end;

destructor TMongoInterfacedObject.Destroy;
begin
  inherited;
end;

{ TMongoObject }

constructor TMongoObject.Create;
begin
  inherited;
end;

destructor TMongoObject.Destroy;
begin
  inherited;
end;

procedure bson_dealloc_and_destroy(bson : Pointer);
begin
  bson_destroy(bson);
  bson_dealloc(bson);
end;

function mongo_write_concern_create: Pointer;
begin
  Result := mongo_write_concern_alloc;
  mongo_write_concern_init(Result);
end;

function bson_create: pointer;
begin
  Result := bson_alloc;
  if bson_init_empty(Result) <> 0 then
    raise EMongoFatalError.Create('Call to bson_init_empty failed');
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

