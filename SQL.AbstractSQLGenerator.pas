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
unit SQL.AbstractSQLGenerator;

interface

uses
  SQL.Interfaces, SQL.Commands, Mapping.Attributes, SQL.Types, Generics.Collections;

const
  TBL_TEMP = 'ORM_TEMP';

type
  TAbstractSQLGenerator = class(TInterfacedObject, ISQLGenerator)
  protected
    function GetQueryLanguage(): TQueryLanguage; virtual; abstract;
    function GenerateSelect(ASelectCommand: TSelectCommand): string; virtual; abstract;
    function GenerateInsert(AInsertCommand: TInsertCommand): string; virtual; abstract;
    function GenerateUpdate(AUpdateCommand: TUpdateCommand): string; virtual; abstract;
    function GenerateDelete(ADeleteCommand: TDeleteCommand): string; virtual; abstract;
    function GenerateCreateTable(ACreateTableCommand: TCreateTableCommand): TList<string>; virtual; abstract;
    function GenerateCreateFK(ACreateFKCommand: TCreateFKCommand): TList<string>; virtual; abstract;
    function GenerateCreateSequence(ASequence: TCreateSequenceCommand): string; virtual; abstract;
    function GenerateGetNextSequenceValue(ASequence: SequenceAttribute): string; virtual; abstract;
    function GenerateGetLastInsertId(AIdentityColumn: ColumnAttribute): string; virtual; abstract;
    function GeneratePagedQuery(const ASql: string; const ALimit, AOffset: Integer): string; virtual; abstract;
    function GenerateGetQueryCount(const ASql: string): string; virtual; abstract;
    function GetSQLDataTypeName(AField: TSQLCreateField): string; virtual; abstract;
    function GetSQLTableCount(const ATablename: string): string; virtual; abstract;
    function GetSQLSequenceCount(const ASequenceName: string): string; virtual; abstract;
    function GetTableColumns(const ATableName: string): string; virtual; abstract;
    function GetSQLTableExists(const ATablename: string): string; virtual; abstract;
  end;

implementation

end.
