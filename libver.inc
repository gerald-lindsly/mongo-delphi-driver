{$IFDEF VER120} { Delphi 4.0 }
  {$DEFINE LEVEL4 }
  {$DEFINE DELPHI }
{$ENDIF}
{$IFDEF VER125} { C++Builder 4.0 }
  {$DEFINE LEVEL4 }
  {$DEFINE CBUILDER }
{$ENDIF}
{$IFDEF VER130} { Delphi 5.0/C++Builder 5.0 }
  {$DEFINE LEVEL4 }
  {$DEFINE LEVEL5 }
{$ENDIF}
{$IFDEF ConditionalExpressions}
  {$DEFINE LEVEL4 }
  {$DEFINE LEVEL5 }
  {$IF CompilerVersion >= 14.0} { Delphi 6.0/C++Builder 6.0 }
    {$DEFINE LEVEL6 }
  {$IFEND}
  {$IF CompilerVersion >= 15.0} { Delphi 7.0 }
    {$DEFINE LEVEL7 }
  {$IFEND}
{$ENDIF}
{$IFDEF BCB}
  {$DEFINE CBUILDER }
{$ELSE}
  {$DEFINE DELPHI }
{$ENDIF}
{$IFDEF VER180}
  {$DEFINE LEVEL4}
  {$DEFINE LEVEL5}
  {$DEFINE LEVEL7}
  {$DEFINE LEVEL10}
{$ENDIF}
