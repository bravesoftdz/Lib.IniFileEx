{$IFDEF FPC}
  {$MODE ObjFPC}{$H+}
  {$INLINE ON}
  {$DEFINE CanInline}
  //{$DEFINE FPC_DisableWarns}
  //{$MACRO ON}
{$ELSE}
  {$IF CompilerVersion >= 17 then}  // Delphi 2005+
    {$DEFINE CanInline}
  {$ELSE}
    {$UNDEF CanInline}
  {$IFEND}
{$ENDIF}