{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit mORMot_DB;

{$warn 5023 off : no warning about unused units}
interface

uses
  mORMotDB, mORMotMongoDB, SynDB, SynDBODBC, SynDBOracle, SynDBRemote, 
  SynDBSQLite3, SynMongoDB, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('mORMot_DB', @Register);
end.
