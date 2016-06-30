{$IFDEF LINUX}
  {$DEFINE UNIX}
{$ENDIF}

{$IFNDEF UNIX}
{$I ..\..\SynopseCommit.inc}
{$ELSE}
{$I ../../SynopseCommit.inc}
{$ENDIF}