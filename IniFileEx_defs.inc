{$IF defined(CPU64) or defined(CPU64BITS)}
  {$DEFINE 64bit}
{$ELSEIF defined(CPU16)}
  {$MESSAGE FATAL '16bit CPU not supported'}
{$ELSE}
  {$DEFINE 32bit}
{$IFEND}

{$IFDEF FPC}
  {$MODE ObjFPC}{$H+}
  {$MODESWITCH CLASSICPROCVARS+}
  {$INLINE ON}
  {$DEFINE CanInline}
  {$DEFINE FPC_DisableWarns}
  {$MACRO ON}
{$ELSE}
  {$IF CompilerVersion >= 17 then}  // Delphi 2005+
    {$DEFINE CanInline}
  {$ELSE}
    {$UNDEF CanInline}
  {$IFEND}
{$ENDIF}

{.$DEFINE AllowLowLevelAccess}
