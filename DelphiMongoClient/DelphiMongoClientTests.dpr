program DelphiMongoClientTests;
{

  Delphi DUnit Test Project
  -------------------------
  This project contains the DUnit test framework and the GUI/Console test runners.
  Add "CONSOLE_TESTRUNNER" to the conditional defines entry in the project options 
  to use the console test runner.  Otherwise the GUI test runner will be used by 
  default.

}

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  Forms,
  TestFramework,
  GUITestRunner,
  TextTestRunner,
  TestMongoDB in 'TestMongoDB.pas',
  MongoDB in '..\..\MongoDB.pas',
  TestMongoBson in 'TestMongoBson.pas',
  MongoBson in '..\..\MongoBson.pas',
  TestGridFS in 'TestGridFS.pas',
  TestCnvStreamMongoDBProvider,
  GridFS in '..\..\GridFS.pas';

{$R *.RES}

var
  GUITestRunner_ :TGUITestRunner;

begin
  Application.Initialize;
  if IsConsole then
    TextTestRunner.RunRegisteredTests
  else
  begin
    Application.CreateForm(TGUITestRunner, GUITestRunner_);
  GUITestRunner_.Suite := RegisteredTests;
    Application.Run;
  end;
end.

