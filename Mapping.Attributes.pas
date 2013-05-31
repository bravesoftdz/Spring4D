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
unit Mapping.Attributes;

interface

uses
  Generics.Collections, Rtti, TypInfo;

type
  TFetchType = (ftEager, ftLazy);

  TCascadeType = (ctCascadeAll, ctCascadeMerge, ctCascadeRefresh, ctCascadeRemove);

  TForeignStrategy = (fsOnDeleteSetNull, fsOnDeleteSetDefault, fsOnDeleteCascade, fsOnDeleteNoAction
                      ,fsOnUpdateSetNull, fsOnUpdateSetDefault, fsOnUpdateCascade, fsOnUpdateNoAction);

  TForeignStrategies = set of TForeignStrategy;

  TCascadeTypes = set of TCascadeType;

  TColumnProperty = (cpRequired, cpUnique, cpDontInsert, cpDontUpdate, cpPrimaryKey, cpNotNull, cpHidden);

  TColumnProperties = set of TColumnProperty;

  TDiscriminatorType = (dtString, dtInteger);
  {TODO -oLinas -cGeneral : finish defining enums}
  TInheritenceStrategy = (isJoined, isSingleTable, isTablePerClass);

  TMemberType = (mtField, mtProperty, mtClass);

  TORMAttribute = class(TCustomAttribute)
  private
    FMemberType: TMemberType;
    FClassMemberName: string;
    FTypeInfo: PTypeInfo;
    function GetBaseEntityClass: TClass;
  public
    function AsRttiObject(ATypeInfo: PTypeInfo): TRttiNamedObject; overload;
    function AsRttiObject(): TRttiNamedObject; overload;
    function GetTypeInfo(AEntityTypeInfo: PTypeInfo): PTypeInfo;
    function GetColumnTypeInfo(): PTypeInfo;

    property BaseEntityClass: TClass read GetBaseEntityClass;
    property EntityTypeInfo: PTypeInfo read FTypeInfo write FTypeInfo;
    property ClassMemberName: string read FClassMemberName write FClassMemberName;
    property MemberType: TMemberType read FMemberType write FMemberType;
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Specifies that the class is an entity.
  ///	</summary>
  {$ENDREGION}
  EntityAttribute = class(TORMAttribute);

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Specifies the primary key property or field of an entity.
  ///	</summary>
  {$ENDREGION}
  Id = class(TORMAttribute);

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  This annotation specifies the primary table for the annotated entity.
  ///	</summary>
  {$ENDREGION}
  TableAttribute = class(TORMAttribute)
  private
    FTable: string;
    FSchema: string;
    function GetTableName: string;
  public
    constructor Create(); overload;
    constructor Create(const ATablename: string; const ASchema: string = ''); overload;

    property TableName: string read GetTableName;
    property Schema: string read FSchema;
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Specifies that field or property value should be autoincremented.
  ///	</summary>
  {$ENDREGION}
  AutoGenerated = class(TORMAttribute);

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  This annotation is used to specify that a unique constraint is to be
  ///	  included in the generated DDL for a primary or secondary table.
  ///	</summary>
  {$ENDREGION}
  UniqueConstraint = class(TORMAttribute)
  public
    constructor Create(); virtual;
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Specifies properties for databases which uses sequences instead of
  ///	  identities.
  ///	</summary>
  {$ENDREGION}
  SequenceAttribute = class(TORMAttribute)
  private
    FSeqName: string;
    FInitValue: NativeInt;
    FIncrement: Integer;
  public
    constructor Create(const ASeqName: string; AInitValue: NativeInt; AIncrement: Integer);

    property SequenceName: string read FSeqName;
    property InitialValue: NativeInt read FInitValue;
    property Increment: Integer read FIncrement;
  end;

  Association = class(TORMAttribute)
  private
    FRequired: Boolean;
    FCascade: TCascadeTypes;
  public
    constructor Create(ARequired: Boolean; ACascade: TCascadeTypes);

    property Required: Boolean read FRequired;
    property Cascade: TCascadeTypes read FCascade;
  end;

  ManyValuedAssociation = class(Association)
  private
    FMappedBy: string;
  public
    constructor Create(ARequired: Boolean; ACascade: TCascadeTypes; const AMappedBy: string); overload;

    property MappedBy: string read FMappedBy;
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Defines a many-valued association with one-to-many multiplicity.
  ///	</summary>
  {$ENDREGION}
  OneToManyAttribute = class(ManyValuedAssociation)

  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  This annotation defines a single-valued association to another entity
  ///	  class that has many-to-one multiplicity.
  ///	</summary>
  {$ENDREGION}
  ManyToOneAttribute = class(ManyValuedAssociation)

  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Is used to specify a mapped column for joining an entity association.
  ///	</summary>
  {$ENDREGION}
  JoinColumn = class(TORMAttribute)
  private
    FName: string;
   // FProperties: TColumnProperties;
    FReferencedColName: string;
    FReferencedTableName: string;
  public
    constructor Create(const AName: string; const AReferencedTableName, AReferencedColumnName: string);

    property Name: string read FName;
   // property Properties: TColumnProperties read FProperties;
    property ReferencedColumnName: string read FReferencedColName;
    property ReferencedTableName: string read FReferencedTableName;
  end;

  ForeignJoinColumnAttribute = class(JoinColumn)
  private
    FForeignStrategies: TForeignStrategies;
  public
    constructor Create(const AName: string; const AReferencedTableName, AReferencedColumnName: string;
      AForeignStrategies: TForeignStrategies); overload;

    property ForeignStrategies: TForeignStrategies read FForeignStrategies write FForeignStrategies;
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Is used to specify a mapped column for a persistent property or field.
  ///	</summary>
  {$ENDREGION}
  ColumnAttribute = class(TORMAttribute)
  private
    FName: string;
    FProperties: TColumnProperties;
    FLength: Integer;
    FPrecision: Integer;
    FScale: Integer;
    FDescription: string;
    FIsIdentity: Boolean;
    function GetName: string;
  public
    constructor Create(); overload;
    constructor Create(AProperties: TColumnProperties); overload;
    constructor Create(AProperties: TColumnProperties; ALength: Integer; APrecision: Integer;
      AScale: Integer; const ADescription: string = ''); overload;
    constructor Create(const AName: string; AProperties: TColumnProperties = []); overload;
    constructor Create(const AName: string; AProperties: TColumnProperties; ALength: Integer; APrecision: Integer;
      AScale: Integer; const ADescription: string = ''); overload;

    function CanInsert(): Boolean; virtual;
    function CanUpdate(): Boolean; virtual;

    function IsDiscriminator(): Boolean; virtual;

    property IsIdentity: Boolean read FIsIdentity write FIsIdentity;
    property Name: string read GetName;
    property Properties: TColumnProperties read FProperties;
    property Length: Integer read FLength;
    property Precision: Integer read FPrecision;
    property Scale: Integer read FScale;
    property Description: string read FDescription;
  end;

  TColumnData = record
  public
    Properties: TColumnProperties;
    Name: string;
    ColTypeInfo: PTypeInfo;
    ClassMemberName: string;
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Is used to specify the value of the discriminator column for entities
  ///	  of the given type.
  ///	</summary>
  {$ENDREGION}
  DiscriminatorValue = class(TORMAttribute)
  private
    FValue: TValue;
  public
    constructor Create(const AValue: TValue);

    property Value: TValue read FValue;
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Is used to define the discriminator column for the SINGLE_TABLE and
  ///	  JOINED inheritance mapping strategies.
  ///	</summary>
  {$ENDREGION}
  DiscriminatorColumn = class(ColumnAttribute)
  private
    FName: string;
    FDiscrType: TDiscriminatorType;
    FLength: Integer;
  public
    constructor Create(const AName: string; ADiscrType: TDiscriminatorType; ALength: Integer);

    function IsDiscriminator(): Boolean; override;

    property Name: string read FName;
    property DiscrType: TDiscriminatorType read FDiscrType;
    property Length: Integer read FLength;
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Defines the inheritance strategy to be used for an entity class
  ///	  hierarchy.
  ///	</summary>
  {$ENDREGION}
  Inheritence = class(TORMAttribute)
  private
    FStrategy: TInheritenceStrategy;
  public
    constructor Create(AStrategy: TInheritenceStrategy);

    property Strategy: TInheritenceStrategy read FStrategy;
  end;

  {TODO -oLinas -cGeneral : OrderBy attribute. see: http://docs.oracle.com/javaee/5/api/javax/persistence/OrderBy.html}
  {TODO -oLinas -cGeneral : ManyToMany attribute. see: http://docs.oracle.com/javaee/5/api/javax/persistence/ManyToMany.html}


implementation


{ TableAttribute }

constructor TableAttribute.Create;
begin
  inherited Create;
  FTable := '';
  FSchema := '';
end;

constructor TableAttribute.Create(const ATablename: string; const ASchema: string);
begin
  Create;
  FTable := ATablename;
  FSchema := ASchema;
end;

function TableAttribute.GetTableName: string;
begin
  Result := FTable;
  if (Result = '') then
  begin
    Result := ClassMemberName;
    if (Result[1] = 'T') and (Length(Result) > 1) then
    begin
      Result := Copy(Result, 2, Length(Result));
    end;
  end;
end;

{ UniqueConstraint }

constructor UniqueConstraint.Create();
begin
  inherited Create;
end;

{ Sequence }

constructor SequenceAttribute.Create(const ASeqName: string; AInitValue: NativeInt; AIncrement: Integer);
begin
  inherited Create;
  FSeqName := ASeqName;
  FInitValue := AInitValue;
  FIncrement := AIncrement;
end;

{ Association }

constructor Association.Create(ARequired: Boolean; ACascade: TCascadeTypes);
begin
  inherited Create;
  FRequired := ARequired;
  FCascade := ACascade;
end;

{ ManyValuedAssociation }

constructor ManyValuedAssociation.Create(ARequired: Boolean; ACascade: TCascadeTypes;
  const AMappedBy: string);
begin
  Create(ARequired, ACascade);
  FMappedBy := AMappedBy;
end;

{ JoinColumn }

constructor JoinColumn.Create(const AName: string; const AReferencedTableName, AReferencedColumnName: string);
begin
  inherited Create;
  FName := AName;
  //FProperties := AProperties;
  FReferencedColName := AReferencedColumnName;
  FReferencedTableName := AReferencedTableName;
end;

{ Column }

function ColumnAttribute.CanInsert: Boolean;
begin
  Result := not (cpDontInsert in Properties);
end;

function ColumnAttribute.CanUpdate: Boolean;
begin
  Result := not (cpDontUpdate in Properties);
end;

constructor ColumnAttribute.Create(const AName: string; AProperties: TColumnProperties; ALength, APrecision, AScale: Integer;
  const ADescription: string);
begin
  Create(AName, AProperties);
  FLength := ALength;
  FPrecision := APrecision;
  FScale := AScale;
  FDescription := ADescription;
end;

constructor ColumnAttribute.Create(AProperties: TColumnProperties; ALength, APrecision, AScale: Integer;
  const ADescription: string);
begin
  Create();
  FProperties := AProperties;
  FLength := ALength;
  FPrecision := APrecision;
  FScale := AScale;
  FDescription := ADescription;
end;

function ColumnAttribute.GetName: string;
begin
  Result := FName;
  if Result = '' then
    Result := ClassMemberName;
end;

constructor ColumnAttribute.Create(const AName: string; AProperties: TColumnProperties);
begin
  Create();
  FName := AName;
  FProperties := AProperties;
end;

constructor ColumnAttribute.Create;
begin
  inherited Create;
  FName := '';
  FLength := 50;
  FPrecision := 10;
  FScale := 2;
  FDescription := '';
end;

constructor ColumnAttribute.Create(AProperties: TColumnProperties);
begin
  Create();
  FProperties := AProperties;
end;

function ColumnAttribute.IsDiscriminator: Boolean;
begin
  Result := False;
end;

{ DiscriminatorValue }

constructor DiscriminatorValue.Create(const AValue: TValue);
begin
  inherited Create;
  FValue := AValue;
end;

{ DiscriminatorColumn }

constructor DiscriminatorColumn.Create(const AName: string; ADiscrType: TDiscriminatorType; ALength: Integer);
begin
  inherited Create(AName, [], ALength, 0, 0, '');
  FName := AName;
  FDiscrType := ADiscrType;
  FLength := ALength;
end;

function DiscriminatorColumn.IsDiscriminator: Boolean;
begin
  Result := True;
end;

{ Inheritence }

constructor Inheritence.Create(AStrategy: TInheritenceStrategy);
begin
  inherited Create;
  FStrategy := AStrategy;
end;

{ TORMAttribute }

function TORMAttribute.AsRttiObject(ATypeInfo: PTypeInfo): TRttiNamedObject;
var
  LType: TRttiType;
begin
  LType := TRttiContext.Create.GetType(ATypeInfo);
  Result := LType.GetField(ClassMemberName);
  if not Assigned(Result) then
    Result := LType.GetProperty(ClassMemberName);
end;

function TORMAttribute.AsRttiObject: TRttiNamedObject;
begin
  Result := AsRttiObject(FTypeInfo);
end;

function TORMAttribute.GetBaseEntityClass: TClass;
begin
  Result := TRttiContext.Create.GetType(EntityTypeInfo).AsInstance.MetaclassType;
end;

function TORMAttribute.GetColumnTypeInfo: PTypeInfo;
begin
  Result := GetTypeInfo(FTypeInfo);
end;

function TORMAttribute.GetTypeInfo(AEntityTypeInfo: PTypeInfo): PTypeInfo;
var
  LRttiObj: TRttiNamedObject;
begin
  Result := nil;

  LRttiObj := AsRttiObject(AEntityTypeInfo);
  if LRttiObj is TRttiField then
  begin
    Result := TRttiField(LRttiObj).FieldType.Handle;
  end
  else if LRttiObj is TRttiProperty then
  begin
    Result := TRttiProperty(LRttiObj).PropertyType.Handle;
  end;
end;

{ ForeignJoinColumnAttribute }

constructor ForeignJoinColumnAttribute.Create(const AName, AReferencedTableName, AReferencedColumnName: string;
  AForeignStrategies: TForeignStrategies);
begin
  inherited Create(AName, AReferencedTableName, AReferencedColumnName);
  FForeignStrategies := AForeignStrategies;
end;



end.
