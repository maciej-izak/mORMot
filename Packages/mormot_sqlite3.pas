{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit mORMot_SQLite3;

{$warn 5023 off : no warning about unused units}
interface

uses
  mORMot, mORMotSQLite3, SynSQLite3, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('mORMot_SQLite3', @Register);
end.
