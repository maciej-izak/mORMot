{$IFDEF LINUX}
  {$DEFINE UNIX}
{$ENDIF}

{$IFNDEF UNIX}
{$I ..\Synopse.inc}
{$ELSE}
{$I ../Synopse.inc}
{$ENDIF}