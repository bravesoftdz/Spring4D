(*
* Copyright (c) 2012, Linas Naginionis
* Contacts: lnaginionis@gmail.com or support@soundvibe.net
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*     * Redistributions of source code must retain the above copyright
*       notice, this list of conditions and the following disclaimer.
*     * Redistributions in binary form must reproduce the above copyright
*       notice, this list of conditions and the following disclaimer in the
*       documentation and/or other materials provided with the distribution.
*     * Neither the name of the <organization> nor the
*       names of its contributors may be used to endorse or promote products
*       derived from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE AUTHOR ''AS IS'' AND ANY
* EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
* DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
* DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
* ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)
unit SQL.Commands.Insert;

interface

uses
  SQL.AbstractCommandExecutor, SQL.Types, SQL.Commands, SQL.Params, Generics.Collections
  , Mapping.Attributes;

type
  TInsertExecutor = class(TAbstractCommandExecutor)
  private
    FTable: TSQLTable;
    FCommand: TInsertCommand;
    FColumns: TList<Column>;
    FAutoGeneratedName: string;
    FLastInsertIdSQL: string;
  public
    constructor Create(); override;
    destructor Destroy; override;

    procedure BuildParams(AEntity: TObject); override;

    procedure Build(AClass: TClass); override;
    procedure Execute(AEntity: TObject); override;
    procedure LoadIdFromSequence(AEntity: TObject);


    property SQLTable: TSQLTable read FTable;
  end;

implementation

uses
  Core.Exceptions
  ,Mapping.RttiExplorer
  ,Core.Interfaces
  ,SysUtils
  ,Rtti
  ;

{ TInsertCommand }

procedure TInsertExecutor.Build(AClass: TClass);
var
  LAtrTable: Table;
begin
  EntityClass := AClass;
  LAtrTable := TRttiExplorer.GetTable(EntityClass);
  if not Assigned(LAtrTable) then
    raise ETableNotSpecified.Create('Table not specified');

  FTable.SetFromAttribute(LAtrTable);

  if Assigned(FColumns) then
    FreeAndNil(FColumns);
  FColumns := TRttiExplorer.GetColumns(EntityClass);
  FAutoGeneratedName := TRttiExplorer.GetAutoGeneratedColumnMemberName(EntityClass);
   //add fields to tsqltable
  FCommand.SetTable(FColumns);

  SQL := Generator.GenerateInsert(FCommand);
  FLastInsertIdSQL := Generator.GenerateGetLastInsertId();
end;

procedure TInsertExecutor.BuildParams(AEntity: TObject);
var
  LParam: TDBParam;
  LColumn: Column;
  LVal: TValue;
begin
  inherited BuildParams(AEntity);

  for LColumn in FColumns do
  begin
    if not SameText(FAutoGeneratedName, LColumn.ClassMemberName) then
    begin
      LParam := TDBParam.Create;
      LParam.Name := ':' + LColumn.Name;
      LVal := TRttiExplorer.GetMemberValue(AEntity, LColumn.ClassMemberName);
      LParam.Value := LVal.AsVariant;
      LParam.ParamType := FromTValueTypeToFieldType(LVal);
      SQLParameters.Add(LParam);
    end;
  end;
end;

constructor TInsertExecutor.Create();
begin
  inherited Create();
  FTable := TSQLTable.Create;
  FCommand := TInsertCommand.Create(FTable);
  FColumns := nil;
  FAutoGeneratedName := '';
end;

destructor TInsertExecutor.Destroy;
begin
  FTable.Free;
  FCommand.Free;
  if Assigned(FColumns) then
    FColumns.Free;

  inherited Destroy;
end;

procedure TInsertExecutor.Execute(AEntity: TObject);
var
  LTran: IDBTransaction;
  LStmt: IDBStatement;
begin
  Assert(Assigned(AEntity));

  inherited Execute(AEntity);

  LTran := Connection.BeginTransaction;
  LStmt := Connection.CreateStatement;
  LStmt.SetSQLCommand(SQL);

  BuildParams(AEntity);
  try
    LStmt.SetParams(SQLParameters);

    LStmt.Execute();

    LoadIdFromSequence(AEntity);

    LTran.Commit;
  finally
    LTran := nil;
    LStmt := nil;
  end;
end;

procedure TInsertExecutor.LoadIdFromSequence(AEntity: TObject);
var
  LStmt: IDBStatement;
  LResults: IDBResultset;
  LID: Variant;
begin
  if (FLastInsertIdSQL = '') then
    Exit;

  LStmt := Connection.CreateStatement;

  LStmt.SetSQLCommand(FLastInsertIdSQL);
  LResults := LStmt.ExecuteQuery();
  if not LResults.IsEmpty then
  begin
    LID := LResults.GetFieldValue(0);
    TRttiExplorer.SetMemberValue(AEntity, FAutoGeneratedName, TValue.FromVariant(LID));
  end;
end;

end.
