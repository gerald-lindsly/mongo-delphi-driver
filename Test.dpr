program Test;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Bson;

var
  bb : TBsonBuffer;
  cws : TBsonCodeWScope;
  b : TBson;
  i : TBsonIterator;
  oid : TBsonOID;
  ts : TBsonTimestamp;
  bin : TBsonBinary;

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

    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
