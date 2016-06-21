{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit mORMot_Commons;

{$warn 5023 off : no warning about unused units}
interface

uses
  PasZip, SynBidirSock, SynBigTable, SynCommons, SynCrtSock, SynCrypto, 
  SynFastWideString, SynFPCTypInfo, SynLog, SynLZ, SynLZO, SynMustache, 
  SynSSPIAuth, SynWinSock, SynZip, SynZipFiles, SynTests, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('mORMot_Commons', @Register);
end.
