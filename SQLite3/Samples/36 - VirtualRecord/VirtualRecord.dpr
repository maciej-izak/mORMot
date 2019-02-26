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

  TSynClassInterceptor = object
  private
    fClass: TClass;
    fClassName: ShortString;
  public
    procedure Init(aClass: TClass);
    procedure Done;
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
    class function GetVMTData: PSQLVirtualRecordVMT;
  public
    class function ClassCreate(const aRows: ISQLDBRows): TSQLVirtualRecordClass;
    class procedure ClassFree;
    constructor Create; override;
  end;

  TSQLVirtualPropInfo = class(TSQLPropInfo)
  public
    procedure SetValue(Instance: TObject; Value: PUTF8Char; wasString: boolean); override;
    procedure GetValueVar(Instance: TObject; ToSQL: boolean;
      var result: RawUTF8; wasSQLString: PBoolean); override;
  end;

{ TSQLVirtualPropInfo }

procedure TSQLVirtualPropInfo.GetValueVar(Instance: TObject; ToSQL: boolean;
  var result: RawUTF8; wasSQLString: PBoolean);
var wasString: boolean;
    value: Variant;
begin
  SetVariantByValue(TSQLVirtualRecord(Instance).fFields[fPropertyIndex], value);
  VariantToUTF8(value,result,wasString);
  if wasSQLString<>nil then
    // from SQL point of view, variant columns are TEXT or NULL
    wasSQLString^ := not VarIsEmptyOrNull(value);
end;

procedure TSQLVirtualPropInfo.SetValue(Instance: TObject; Value: PUTF8Char;
  wasString: boolean);
var tmp: TSynTempBuffer;
    V: Variant;
    ValueLen: integer;
begin
  ValueLen := StrLen(Value);
  if ValueLen>0 then begin
    if wasString and (GotoNextNotSpace(Value)^ in ['{','[']) then
      wasString := false; // allow to create a TDocVariant stored as DB text
    tmp.Init(Value,ValueLen);
    try
      GetVariantFromJSON(tmp.buf,wasString,V,@JSON_OPTIONS[true]);
      TSQLVirtualRecord(Instance).fFields[fPropertyIndex] := V;
    finally
      tmp.Done;
    end;
  end else begin
    TVarData(V).VType := varNull; // TEXT or NULL: see GetValueVar()
    TSQLVirtualRecord(Instance).fFields[fPropertyIndex] := V;
  end;
end;

{ TSynClassInterceptor }

procedure TSynClassInterceptor.Done;
begin

end;

procedure TSynClassInterceptor.Init(aClass: TClass);
begin

end;

class procedure TSQLVirtualRecord.ClassFree;
begin
  GarbageCollectorFreeAndNilRemove(Pointer(PtrInt(self)+vmtAutoTable)^);
  GetVMTData^.Rows := nil;
  FreeClassClone(self);
end;

constructor TSQLVirtualRecord.Create;
begin
  SetLength(fFields, GetVMTData^.Rows.ColumnCount);
  inherited;
end;

class function TSQLVirtualRecord.GetVMTData: PSQLVirtualRecordVMT;
begin
  Result := PSQLVirtualRecordVMT(GetClassCloneData(self));
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
  vr := GetClassCloneData(Self);
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

procedure TestClass(r: TSQLRecord);
var
  i: integer;
begin
  for i := 0 to r.RecordProps.Fields.Count-1 do begin
    with r.RecordProps.Fields.Items[i] do begin
      SetValue(r, '899', false);
      WriteLn(Name, ' = ', GetValue(r, false));
    end;
  end;
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
  TestClass(r);
  r.Free;
  rc.ClassFree;

  Database.Free;
  Model.Free;
  Props.Free;
end.
