unit AddressBookForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  MongoDB, MongoBson;

type
  TForm1 = class(TForm)
    lblName: TLabel;
    txtName: TEdit;
    lblAddress: TLabel;
    txtAddress: TEdit;
    lblCity: TLabel;
    txtCity: TEdit;
    lblState: TLabel;
    txtState: TEdit;
    lblZip: TLabel;
    txtZip: TEdit;
    lblPhone: TLabel;
    txtPhone: TEdit;
    btnClear: TButton;
    btnSave: TButton;
    btnSearch: TButton;
    btnDelete: TButton;
    btnPrev: TButton;
    btnNext: TButton;
    procedure btnClearClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure btnPrevClick(Sender: TObject);
    procedure ShowRecord(b : TBson);
    procedure btnNextClick(Sender: TObject);
  end;

var
  Form1: TForm1;
  mongo: TMongo;

implementation

{$R *.dfm}

const
  db = 'test';
  ns = db + '.addresses';

procedure TForm1.btnClearClick(Sender: TObject);
begin
  txtName.Text := '';
  txtAddress.Text := '';
  txtCity.Text := '';
  txtState.Text := '';
  txtZip.Text := '';
  txtPhone.Text := '';
end;

procedure TForm1.btnDeleteClick(Sender: TObject);
  var
    query : TBson;
begin
  query := BSON(['phone', txtPhone.Text]);
  if mongo.findOne(ns, query) = nil Then
    ShowMessage('A record with that phone number does not exist.')
  else if MessageDlg('Delete record for phone number ' + txtPhone.Text + '?',
                      mtWarning, [mbYes, MbNo], 0) = mrYes then begin
    mongo.remove(ns, query);
    btnClearClick(Sender);
    ShowMessage('Record deleted.');
  end;
end;

procedure TForm1.ShowRecord(b : TBson);
 begin
  txtName.Text := b.value('name');
  txtAddress.Text := b.value('address');
  txtCity.Text := b.value('city');
  txtState.Text := b.value('state');
  txtZip.Text := b.value('zip');
  txtPhone.Text := b.value('phone');
end;

procedure TForm1.btnNextClick(Sender: TObject);
  var
    query, b : TBson;
begin
  query := BSON(['phone', '{', '$gt', txtPhone.Text, '}']);
  b := mongo.findOne(ns, query);
  if b = nil then
    ShowMessage('No previous record.')
  else
    ShowRecord(b);
end;

procedure TForm1.btnPrevClick(Sender: TObject);
  var
    query, b : TBson;
begin
  query := BSON(['phone', '{', '$lt', txtPhone.Text, '}']);
  b := mongo.findOne(ns, query);
  if b = nil then
    ShowMessage('No next record.')
  else
    ShowRecord(b);
end;


procedure TForm1.btnSaveClick(Sender: TObject);
  var
    bb : TBsonBuffer;
    b : TBson;
    query : TBson;
begin
  query := BSON(['phone', txtPhone.Text]);
  if (mongo.findOne(ns, query) = nil) Or
    (MessageDlg('A record already exists with that phone number.  Replace?', mtWarning, [mbYes, MbNo], 0) = mrYes) then begin
      bb := TbsonBuffer.Create();
      bb.append('name', txtName.Text);
      bb.append('address', txtAddress.Text);
      bb.append('city', txtCity.Text);
      bb.append('state', txtState.Text);
      bb.append('zip', txtZip.Text);
      bb.append('phone', txtPhone.Text);
      b := bb.finish();
      mongo.update(ns, query, b, updateUpsert);
      ShowMessage('Record saved.');
    end;
end;

procedure TForm1.btnSearchClick(Sender: TObject);
  var
    bb : TBsonBuffer;
    query, b : TBson;
begin
  bb := TbsonBuffer.Create();
  if txtName.Text <> '' then begin
    bb.startObject('name');
    bb.append('$regex', txtName.Text);
    bb.append('$options', 'i');
    bb.finishObject();
  end;
  if txtAddress.Text <> '' then begin
    bb.startObject('address');
    bb.append('$regex', txtAddress.Text);
    bb.append('$options', 'i');
    bb.finishObject();
  end;
  if txtCity.Text <> '' then begin
    bb.startObject('city');
    bb.append('$regex', txtCity.Text);
    bb.append('$options', 'i');
    bb.finishObject();
  end;
  if txtState.Text <> '' then begin
    bb.startObject('state');
    bb.append('$regex', txtState.Text);
    bb.append('$options', 'i');
    bb.finishObject();
  end;
  if txtZip.Text <> '' then begin
    bb.startObject('zip');
    bb.append('$regex', txtZip.Text);
    bb.append('$options', 'i');
    bb.finishObject();
  end;
  if txtPhone.Text <> '' then begin
    bb.startObject('phone');
    bb.append('$regex', txtPhone.Text);
    bb.append('$options', 'i');
    bb.finishObject();
  end;
  query := bb.finish();
  b := mongo.findOne(ns, query);
  if b = nil then
    ShowMessage('No match')
  else
    ShowRecord(b);
end;


const
  NoConnectMsg = 'Unable to connect to a MongoDB server running on localhost';

initialization
  mongo := TMongo.Create();
  if not mongo.isConnected() then begin
    ShowMessage(NoConnectMsg);
    Halt(1);
  end;
  mongo.indexCreate(ns, 'phone');


end.
