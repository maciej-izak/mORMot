{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit mORMot_SQLite3Static;

{$warn 5023 off : no warning about unused units}
interface

uses
  SynSQLite3Static, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('mORMot_SQLite3Static', @Register);
end.
