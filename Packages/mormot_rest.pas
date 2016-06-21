{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit mORMot_REST;

{$warn 5023 off : no warning about unused units}
interface

uses
  mORMotHttpClient, mORMotHttpServer, mORMotWrappers, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('mORMot_REST', @Register);
end.
