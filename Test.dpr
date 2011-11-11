program Test;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Variants,
  MongoBson, MongoDB, GridFS;

var
  bb : TBsonBuffer;
  cws : TBsonCodeWScope;
  b, b2, x, y, z, criteria, query, cmd : TBson;
  i : TBsonIterator;
  oid : TBsonOID;
  ts : TBsonTimestamp;
  bin : TBsonBinary;
  sing : Single;
  mongo : TMongo;
  count : Integer;
  j : Integer;
  cursor : TMongoCursor;
  databases : TStringArray;
  gfs : TGridFS;
  gfw : TGridfileWriter;
  gf : TGridfile;
  buf : array[0..100] of AnsiChar;

const
  db = 'test';
  ns = db + '.people';

procedure displayCollections(db : string);
var
  collections : TStringArray;
  j : Integer;
begin
   collections := mongo.getDatabaseCollections(db);
   for j := 0 to Length(collections)-1 do
     Writeln(collections[j]);
end;

begin
  try
    bb := TBsonBuffer.Create();
    bb.append('test', 'testing');
    cws := TBsonCodeWScope.Create('Code for scope', bb.finish());

    bb := TBsonBuffer.Create();
    bb.append('name', 'Gerald');
    bb.append('age', 35);
    bb.append('long', Int64(89));
    bb.append('bool', True);
    bb.append('date', StrToDate('1/3/1970'));
    bb.startObject('object');
    bb.append('sub1', 'sub1');
    bb.append('sub2', False);
    bb.finishObject();
    oid := TBsonOID.Create();
    writeln(oid.AsString());
    bb.append('oid1', oid);
    bb.append('oid2', TBsonOID.Create('4eb6a93dad14000000000099'));
    bb.appendCode('code', '{ this = is + code; }');
    bb.appendSymbol('symbol', 'symbol');
    bb.append('cws', cws);
    bb.append('regex', TBsonRegex.Create('pattern', 'options'));
    ts := TBsonTimestamp.Create(now, 21);
    bb.append('timestamp', ts);
    bb.appendBinary('binary', 0, @ts, sizeof(ts));

    b := bb.finish;
    Writeln(b.size());

    b.display();

    Writeln(b.value('long'));
    i := b.find('oid1');
    WriteLn(i.getOID().AsString());

    i := b.find('binary');
    bin := i.getBinary();

    WriteLn(bin.len);
    sing := 3.14159;

    b2 := BSON(['test', 'testing', 'age', 32,
               'subobj', '{',
                  'single', sing,
               '}',
               'int64', Int64(1234567890123),
               'double', 98.7, 'null', Null, 'logical', False, 'now', now ]);
    b2.display();

    mongo := TMongo.Create();
    if mongo.isConnected() then begin
      mongo.setTimeout(0);
      WriteLn('Timeout = ', mongo.getTimeout());
      WriteLn('Primary = ', mongo.getPrimary());
      WriteLn('IsMaster = ', mongo.isMaster());
      WriteLn('Socket = ', mongo.getSocket());
      WriteLn('Check = ', mongo.checkConnection());
      WriteLn('disconnect');
      mongo.disconnect();
      WriteLn(' Check = ', mongo.checkConnection());
      WriteLn('reconnect');
      mongo.reconnect();
      WriteLn(' Check = ', mongo.checkConnection());

      databases := mongo.getDatabases();
      for j := 0 to Length(databases)-1 do
        Writeln(databases[j]);

      displayCollections(db);
      mongo.rename(ns, 'test.renamed');
      displayCollections(db);
      mongo.rename('test.renamed', ns);
      displayCollections(db);


      WriteLn('Drop = ', mongo.drop(ns));

      mongo.indexCreate(ns, 'name', mongo.indexUnique);

      (* display hosts for a TMongoReplset
      Count := mongo.getHostCount();
      WriteLn('Replset Host Count = ', Count);
      for j := 0 to count - 1 do
        WriteLn('Host = ', mongo.getHost(j));
      *)

      (* insert the collage document *)
      mongo.insert(ns, b);

      (* Insert a couple more people *)
      bb := TBsonBuffer.Create();
      bb.append('name', 'Abe');
      bb.append('age', 32);
      bb.append('city', 'Washington');
      x := bb.finish;
      x.display();
      Writeln(mongo.insert(ns, x));

      bb := TBsonBuffer.Create();
      bb.append('name', 'Joe');
      bb.append('age', 35);
      bb.append('city', 'Natick');
      x := bb.finish;
      x.display();
      Writeln(mongo.insert(ns, x));

      (* Batch insert 3 people *)
      bb := TBsonBuffer.Create();
      bb.append('name', 'Jeff');
      bb.append('age', 19);
      bb.append('city', 'Florence');
      x := bb.finish;
      x.display();

      bb := TBsonBuffer.Create();
      bb.append('name', 'Harry');
      bb.append('age', 36);
      bb.append('city', 'Fort Aspenwood');
      y := bb.finish;
      y.display();

      bb := TBsonBuffer.Create();
      bb.append('name', 'John');
      bb.append('age', 21);
      bb.append('city', 'Cincinnati');
      z := bb.finish;
      z.display();
      Writeln(mongo.insert(ns, [x, y, z]));

      (* update Joe's document with a new one *)
      bb := TBsonBuffer.Create();
      bb.append('name', 'Joe');
      bb.append('age', 36);
      bb.append('city', 'Natick');
      x := bb.finish;
      criteria := BSON(['name', 'Joe']);
      x.display();
      Writeln(mongo.update(ns, criteria, x));

      (* do an upsert *)
      bb := TBsonBuffer.Create();
      bb.append('name', 'Paul');
      bb.append('age', 53);
      bb.append('city', 'Seattle');
      x := bb.finish;
      criteria := BSON(['name', 'Paul']);
      criteria.display();
      x.display();
      Writeln(mongo.update(ns, criteria, x, mongo.updateUpsert));

      (* Remove a record *)
      WriteLn(mongo.remove(ns, BSON(['name', 'John'])));

      (* successful findOne *)
      x := mongo.findOne(ns, criteria);
      x.display();

      (* unsuccessful findOne *)
      x := mongo.findOne(ns, BSON(['name', 'unknown']));
      x.display();

      (* display all people *)
      cursor := TMongoCursor.Create();
      if mongo.find(ns, cursor) then
        while cursor.next() do
          cursor.value.display();

      (* display all people age 36 *)
      query := BSON(['age', 36]);
      cursor := TMongoCursor.Create(query);
      if mongo.find(ns, cursor) then
        while cursor.next() do
          cursor.value.display();

      WriteLn(mongo.count(ns));
      cmd := BSON(['count', 'people']);
      b := mongo.command(db, cmd);
      WriteLn(b.value('n'));
      b := mongo.command(db, 'count', 'people');
      WriteLn(b.value('n'));

      WriteLn(mongo.count(ns, query));

      (* add a user to database 'admin' *)
      mongo.addUser('Gerald', 'P97gwep16');

      (* authenticate with correct credentials *)
      WriteLn(mongo.authenticate('Gerald', 'P97gwep16'));

      (* try authenicate with bad password *)
      WriteLn(mongo.authenticate('Gerald', 'BadPass21'));

      (* try authenticate with bad user *)
      WriteLn(mongo.authenticate('Unsub', 'BadUser67'));

      b := BSON(['name', 'dupkey']);
      mongo.insert(ns, b);
      mongo.insert(ns, b);
      b := mongo.getLastErr(db);
      b.display();

      b := BSON(['name', '{', '$badop', true, '}' ]);
      b2 := mongo.findOne(ns, b);
      b2.display();
      b := mongo.getLastErr(db);
      b.display();
      b := mongo.getPrevErr(db);
      b.display();
      WriteLn(mongo.getServerErr());
      WriteLn(mongo.getServerErrString());

      mongo.resetErr(db);
      b := mongo.getLastErr(db);
      b.display();

      gfs := TGridFS.Create(mongo, 'grid');
      WriteLn('Store test.exe = ', gfs.storeFile('test.exe'));

      WriteLn('Store bin = ', gfs.store(bin.data, bin.len, 'bin'));

      gfs.removeFile('bin');

      gfw := gfs.writerCreate('writer');
      gfw.write(bin.data, bin.len);
      gfw.write(bin.data, bin.len);
      gfw.finish();

      gf := gfs.find('writer');

      WriteLn('name = ', gf.getFilename());
      WriteLn('length = ', gf.getLength());
      WriteLn('chunkSize = ', gf.getChunkSize());
      WriteLn('chunkCount = ', gf.getChunkCount());
      WriteLn('contentType = ', gf.getContentType());
      WriteLN('uploadDate = ', DateTimeToStr(gf.getUploadDate()));
      WriteLN('md5 = ', gf.getMD5());
      b := gf.getDescriptor();
      b.display();

      gf.read(@j, sizeof(j));
      WriteLn(j);

      gf := gfs.find('test.exe');
      cursor := gf.getChunks(1, 5);
      while cursor.next() do
        Writeln(cursor.value.size());

      WriteLn(gf.seek(100000));

      gfs.storeFile('../../MongoDB.pas', 'MongoDB.pas');
      gf := gfs.find('MongoDB.pas');
      gf.seek(100);
      gf.read(@buf, 20);
      buf[20] := Chr(0);
      WriteLn(buf);



      WriteLn('Done');
      ReadLn;
    end
      else
        WriteLn('No Connection, Err = ', mongo.getErr());

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
