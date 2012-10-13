{ -------------------------------------------------------------------------------------}
{ An "application launcher" component for Delphi32.                                    }
{ Copyright 1996, Patrick Brisacier and Jean-Fabien Connault.  All Rights Reserved.    }
{ This component can be freely used and distributed in commercial and private          }
{ environments, provided this notice is not modified in any way.                       }
{ -------------------------------------------------------------------------------------}
{ Feel free to contact us if you have any questions, comments or suggestions at        }
{ cycocrew@aol.com                                                                     }
{ -------------------------------------------------------------------------------------}
{ Date last modified:  08/07/96                                                        }
{ -------------------------------------------------------------------------------------}

{ -------------------------------------------------------------------------------------}
{ TAppExec v1.01                                                                       }
{ -------------------------------------------------------------------------------------}
{ Description:                                                                         }
{   A component that allows you to execute easily applications.                        }
{ Properties:                                                                          }
{   property ChangeDir: Boolean;                                                       }
{   property ErrNo: Integer;                                                           }
{   property ExeName: String;                                                          }
{   property ExePath: String;                                                          }
{   property ExeParams: TStringList;                                                   }
{   property Wait: Boolean;                                                            }
{   property WindowState: TWindowState;                                                }
{ Procedures and functions:                                                            }
{   procedure Clear;                                                                   }
{   procedure Execute;                                                                 }
{   function GetErrorString: string;                                                   }
{                                                                                      }
{ See example contained in example.zip file for more details.                          }
{ -------------------------------------------------------------------------------------}
{ Revision History:                                                                    }
{ 1.00:  + Initial release                                                             }
{ 1.01:  + Added support for french and english languages                              }
{ -------------------------------------------------------------------------------------}

unit appexec;

{$IFNDEF WIN32}
  // Delphi Analizer did not handle this...
  // ERROR!  This unit only available on Win32!
{$ENDIF}

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs;

type
  EAppExec = class(Exception);
  EAppExecChDir = class(EAppExec);
  EAppExecWinExec = class(EAppExec);

  TAppExec = class(TComponent)
  private
    { Private-déclarations }
    FErrNo: Integer;
    FExeName: String;
    FExePath: String;
    FExeParams: TStringList;
    FWindowState: TWindowState;
    FMode: Word;
    FChangeDir: Boolean;
    FWait: Boolean;
    procedure SetWindowState(AWindowState: TWindowState);
    procedure SetExeParams(AExeParams: TStringList);
    procedure SetExePath(AExePath: String);
  protected
    { Protected-déclarations }
  public
    { Public-déclarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Execute;
    function GetErrorString: string;
    procedure Clear;
  published
    { Published-déclarations }
    property ChangeDir: Boolean read FChangeDir write FChangeDir default True;
    property ErrNo: Integer read FErrNo;
    property ExeName: String read FExeName write FExeName;
    property ExeParams: TStringList read FExeParams write SetExeParams;
    property ExePath: String read FExePath write SetExePath;
    property Wait:Boolean read FWait write FWait;
    property WindowState: TWindowState read FWindowState write SetWindowState;
  end;

const
 { French Messages }
 MSG_ERROR_DASH_1 = 'Pas d''exécution';
 MSG_ERROR_0 = 'Système dépassé en capacité mémoire, exécutable corrompu, ou réallocations invalides';
 MSG_ERROR_2 = 'Fichier non trouvé';
 MSG_ERROR_3 = 'Chemin non trouvé';
 MSG_ERROR_5 = 'Tentative de liaison dynamique à une tâche, ou erreur de partage, ou erreur de protection réseau';
 MSG_ERROR_6 = 'Librairie nécessitant des segments de données séparés pour chaque tâche';
 MSG_ERROR_8 = 'Mémoire insuffisante pour démarrer l''application';
 MSG_ERROR_10 = 'Version de Windows incorrecte';
 MSG_ERROR_11 = 'Exécutable invalide, application non Windows, ou erreur dans l''image du fichier .EXE';
 MSG_ERROR_12 = 'Application écrite pour un système d''exploitation différent';
 MSG_ERROR_13 = 'Application écrite pour MS-DOS 4.0';
 MSG_ERROR_14 = 'Type d''exécutable inconnu';
 MSG_ERROR_15 = 'Tentative de chargement d''une application en mode réel (développée pour une version antérieure de Windows)';
 MSG_ERROR_16 = 'Tentative de chargement d''une seconde instance d''un exécutable contenant plusieurs segments de données non marqués en lecture seule';
 MSG_ERROR_19 = 'Tentative de chargement d''un exécutable compressé. Le fichier doit être décompressé avant de pouvoir être chargé';
 MSG_ERROR_20 = 'Fichier Dynamic-link library (DLL) invalide. Une des DLLs requises pour exécuter cette application est corrompue';
 MSG_ERROR_21 = 'Application nécessitant des extensions 32-bit';
 MSG_ERROR_32_AND_MORE = 'Pas d''erreur';

 { English Messages }
 {MSG_ERROR_DASH_1 = 'No execution';
 MSG_ERROR_0 = 'System was out of memory, executable file was corrupt, or relocations were invalid';
 MSG_ERROR_2 = 'File was not found';
 MSG_ERROR_3 = 'Path was not found';
 MSG_ERROR_5 = 'Attempt was made to dynamically link to a task, or there was a sharing or network-protection error';
 MSG_ERROR_6 = 'Library required separate data segments for each task';
 MSG_ERROR_8 = 'There was insufficient memory to start the application';
 MSG_ERROR_10 = 'Windows version was incorrect';
 MSG_ERROR_11 = 'Executable file was invalid. Either it was not a Windows application or there was an error in the .EXE image';
 MSG_ERROR_12 = 'Application was designed for a different operating system';
 MSG_ERROR_13 = 'Application was designed for MS-DOS 4.0';
 MSG_ERROR_14 = 'Type of executable file was unknown';
 MSG_ERROR_15 = 'Attempt was made to load a real-mode application (developed for an earlier version of Windows)';
 MSG_ERROR_16 = 'Attempt to load second instance of an executable containing multiple data segments not marked read-only';
 MSG_ERROR_19 = 'Attempt was made to load a compressed executable file. The file must be decompressed before it can be loaded';
 MSG_ERROR_20 = 'Dynamic-link library (DLL) file was invalid. One of the DLLs required to run this application was corrupt';
 MSG_ERROR_21 = 'Application requires 32-bit extensions';
 MSG_ERROR_32_AND_MORE = 'No error';}

procedure Register;

implementation


procedure Register;
begin
  RegisterComponents('Misc', [TAppExec]);
end;

constructor TAppExec.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FExeParams := TStringList.Create;
  FMode := SW_SHOWNORMAL;
  FErrNo := -1;
  FChangeDir := True;
end;

destructor TAppExec.Destroy;
begin
  FExeParams.Free;
  inherited Destroy;
end;

procedure TAppExec.Execute;
var
  //InstanceID : THandle;
  buffer: array[0..511] of Char;
  TmpStr: String;
  i: Integer;
  StartupInfo:TStartupInfo;
  ProcessInfo:TProcessInformation;
begin
  { Création de la ligne de commande }
  TmpStr := FExeName;
  for i := 0 to FExeParams.Count - 1 do
    TmpStr := TmpStr + ' ' + FExeParams.Strings[i];
  StrPCopy(buffer,TmpStr);
  { Changement de répertoire }
  if FChangeDir and (FExePath <> '') then
  begin
    try
      ChDir(FExePath);
    except
      On E:Exception do raise EAppExecChDir.Create(E.Message);
    end;
  end;

  { Execution }
  FillChar(StartupInfo,Sizeof(StartupInfo),#0);
  StartupInfo.cb := Sizeof(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow := FMode;
  if not CreateProcess(nil,
    buffer,                        { pointer to command line string }
    nil,                           { pointer to process security attributes }
    nil,                           { pointer to thread security attributes }
    false,                         { handle inheritance flag }
    CREATE_NEW_CONSOLE or          { creation flags }
    NORMAL_PRIORITY_CLASS,
    nil,                           { pointer to new environment block }
    nil,                           { pointer to current directory name }
    StartupInfo,                   { pointer to STARTUPINFO }
    ProcessInfo) then begin        { pointer to PROCESS_INF }
    FErrNo := GetLastError();
    raise EAppExecWinExec.Create(GetErrorString);
  end
  else if FWait then begin
    WaitforSingleObject(ProcessInfo.hProcess,INFINITE);
    { GetExitCodeProcess(ProcessInfo.hProcess, ErrNo); }
    FErrNo := 0;
  end;
end;

procedure TAppExec.SetWindowState(AWindowState: TWindowState);
const
  Mode: array[wsNormal..wsMaximized] of Word =
    (SW_SHOWNORMAL, SW_SHOWMINIMIZED, SW_SHOWMAXIMIZED);
begin
  if FWindowState <> AWindowState then
  begin
    FMode := Mode[AWindowState];
    FWindowState := AWindowState;
  end;
end;

procedure TAppExec.SetExeParams(AExeParams: TStringList);
begin
  FExeParams.Assign(AExeParams);
end;

procedure TAppExec.SetExePath(AExePath: String);
begin
  if FExePath <> AExePath then
  begin
    FExePath := AExePath;
    if ((FExePath[Length(FExePath)] = '\') and
        (FExePath <> '\') and
        (not ((Length(FExePath) = 3) and (FExePath[2] = ':') and (FExePath[3] = '\')) )
        ) then
      FExePath := Copy(FExePath, 1, Length(FExePath) - 1);
  end;
end;

procedure TAppExec.Clear;
begin
  FErrNo := -1;
  FExeName := '';
  FExePath := '';
  FExeParams.Clear;
end;

function TAppExec.GetErrorString: string;
begin
  case FErrNo of
    -1:
      Result := MSG_ERROR_DASH_1;
    0:
      Result := MSG_ERROR_0;
    2:
      Result := MSG_ERROR_2;
    3:
      Result := MSG_ERROR_3;
    5:
      Result := MSG_ERROR_5;
    6:
      Result := MSG_ERROR_6;
    8:
      Result := MSG_ERROR_8;
    10:
      Result := MSG_ERROR_10;
    11:
      Result := MSG_ERROR_11;
    12:
      Result := MSG_ERROR_12;
    13:
      Result := MSG_ERROR_13;
    14:
      Result := MSG_ERROR_14;
    15:
      Result := MSG_ERROR_15;
    16:
      Result := MSG_ERROR_16;
    19:
      Result := MSG_ERROR_19;
    20:
      Result := MSG_ERROR_20;
    21:
      Result := MSG_ERROR_21;
    32..MaxInt:
      Result := MSG_ERROR_32_AND_MORE;
  end;
end;

end.
