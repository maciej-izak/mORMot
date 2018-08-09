program VirtualRecord;

{$APPTYPE CONSOLE}

uses
  SynCommons,
  SynDB,
  SynSQLite3,
  SynSQLite3Static,
  SynDBSQLite3,
  mORMot,
  mORMotDB,
  mORMotSQLite3
  ;

var
  Database: TSQLRestServerDB;
  Model: TSQLModel;

type
  TSQLSampleRecord = class(TSQLRecord)
  private
    fQuestion: RawUTF8;
    fName: RawUTF8;
    fTime: TModTime;
  published
    property Time: TModTime read fTime write fTime;
    property Name: RawUTF8 read fName write fName;
    property Question: RawUTF8 read fQuestion write fQuestion;
  end;

  PSQLVirtualRecordVMT = ^TSQLVirtualRecordVMT;
  TSQLVirtualRecordVMT = record
    Rows: ISQLDBRows;
  end;

  TSQLVirtualRecordClass = class of TSQLVirtualRecord;
  TSQLVirtualRecord = class(TSQLRecord)
  protected
    fFields: TVariantDynArray;
    class procedure InternalRegisterCustomProperties(Props: TSQLRecordProperties); override;
  public
    class function ClassCreate(const aRows: ISQLDBRows): TSQLVirtualRecordClass;
    class procedure ClassFree;
  end;

  TSQLVirtualPropInfo = class(TSQLPropInfo)
  end;

class procedure TSQLVirtualRecord.ClassFree;
begin
  GarbageCollectorFreeAndNilRemove(Pointer(PtrInt(self)+vmtAutoTable)^);
  PSQLVirtualRecordVMT(ClassCloneData(self))^.Rows := nil;
  FreeClassClone(self);
end;

const
  DBTOFIELDTYPE: array[TSQLDBFieldType] of TSQLFieldType  = (sftUnknown,
    sftUnknown,sftInteger,sftFloat,sftCurrency,sftDateTime,sftUTF8Text,sftBlob);

class procedure TSQLVirtualRecord.InternalRegisterCustomProperties(Props: TSQLRecordProperties);
var
  vr: PSQLVirtualRecordVMT;
  i: integer;
  width: integer;
  colname: RawUTF8;
begin
  vr := ClassCloneData(Self);
  for i := 0 to vr.Rows.ColumnCount - 1 do with vr.Rows do begin
    colname := ColumnName(i);
    if IdemPropNameU(colname,'ID') then
      continue;
    Props.Fields.Add(
      TSQLVirtualPropInfo.Create(colname, DBTOFIELDTYPE[ColumnType(i, @width)], [], width, i));
  end;
end;

type
  PRegisterProps = ^TRegisterProps;
  TRegisterProps = procedure(const aRows: ISQLDBRows) of object;

class function TSQLVirtualRecord.ClassCreate(const aRows: ISQLDBRows): TSQLVirtualRecordClass;
var
  vr: PSQLVirtualRecordVMT;
begin
  result := TSQLVirtualRecordClass(CreateClassClone(Self, SizeOf(TSQLVirtualRecordVMT), @vr));
  PPointer(PtrInt(result)+vmtAutoTable)^ := nil;
  Pointer(vr^.Rows) := nil;
  vr^.Rows := aRows;
end;

var
  rows: ISQLDBRows;
  r: TSQLVirtualRecord;
  rc: TSQLVirtualRecordClass;
  Props: TSQLDBSQLite3ConnectionProperties;
begin
  ReportMemoryLeaksOnShutdown := true;
  Props := TSQLDBSQLite3ConnectionProperties.Create(SQLITE_MEMORY_DATABASE_NAME,'','','');
  Model := TSQLModel.Create([TSQLSampleRecord]);
  VirtualTableExternalRegisterAll(Model,Props,[]);
  Database := TSQLRestServerDB.Create(Model, SQLITE_MEMORY_DATABASE_NAME);
  Database.CreateMissingTables;

  rows := Props.ExecuteInlined('select * from SampleRecord', true);
  rc := TSQLVirtualRecord.ClassCreate(rows);
  r := rc.Create;
  r.Free;
  rc.ClassFree;

  Database.Free;
  Model.Free;
  Props.Free;
end.
