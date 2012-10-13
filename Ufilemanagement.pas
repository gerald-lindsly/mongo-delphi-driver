unit uFileManagement;

interface

function RemoveEntireDir (const Dir : string) : boolean;
function DeleteEntireDir (const Dir : string) : boolean;
function CreateEntireDir (const Dir : string) : boolean;

implementation

uses
  Classes, SysUtils, FileCtrl;

function DeleteEntireDir;
var
  Rec : TSearchRec;
  r, i : integer;
  FileList : TStringList;
  res : boolean;
  Filename : string;
begin
  Result := true;
  FileList := TStringList.Create;
  try
    r := FindFirst (Dir + '\*.*', faAnyFile, Rec);
    try
      while r = 0 do
        begin
          FileName := Format ('%s\%s', [Dir, Rec.Name]);
          if Rec.Attr = faDirectory
            then if (Rec.Name <> '.') and (Rec.Name <> '..')
              then
              begin
                DeleteEntireDir (FileName);
                FileList.AddObject (FileName, pointer (true));
              end
              else {}
            else FileList.AddObject (FileName, pointer (false));
          r := FindNext (Rec);
        end;
    finally
      FindClose (Rec);
    end;
    Res := true;
    for i := 0 to FileList.Count - 1 do
      if FileList.Objects [i] <> nil
        then res := RemoveDir (FileList [i])
        else res := DeleteFile (FileList [i]);
    if not res
      then Result := false;
  finally
    FileList.Free;
  end;
end;

function RemoveEntireDir;
var
  r, i : boolean;
begin
  r := DeleteEntireDir (Dir);
  i := RemoveDir (Dir);
  Result := r and i;
end;

function CreateEntireDir;
var
  DirToCreate : string;
  i : integer;
begin
  Result := false;
  i := 1;
  DirToCreate := '';
  repeat
    while (i <= length (Dir)) and (Dir [i] <> '\') do
      begin
        DirToCreate := dirToCreate + Dir [i];
        inc (i);
      end;
    DirToCreate := dirToCreate + '\';  
    inc (i);
    if not DirectoryExists (DirToCreate)
      then
      begin
        Result := CreateDir (DirToCreate);
        if not Result
          then exit;
      end;
  until i > length (Dir);
end;

end.
