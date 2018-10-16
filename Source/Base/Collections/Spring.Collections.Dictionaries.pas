{***************************************************************************}
{                                                                           }
{           Spring Framework for Delphi                                     }
{                                                                           }
{           Copyright (c) 2009-2018 Spring4D Team                           }
{                                                                           }
{           http://www.spring4d.org                                         }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}

{$I Spring.inc}

unit Spring.Collections.Dictionaries;

interface

uses
  Generics.Collections,
  Generics.Defaults,
  Spring,
  Spring.Collections,
  Spring.Collections.Base,
  Spring.Collections.Trees,
  Spring.Events.Base;

type
  TDictionaryItem<TKey, TValue> = record
  public
    HashCode: Integer;
    Key: TKey;
    Value: TValue;
    function Removed: Boolean; inline;
  end;

  TDictionary<TKey, TValue> = class(TMapBase<TKey, TValue>,
    IEnumerable<TPair<TKey, TValue>>, IReadOnlyCollection<TPair<TKey, TValue>>,
    IReadOnlyMap<TKey, TValue>, IReadOnlyDictionary<TKey, TValue>,
    ICollection<TPair<TKey, TValue>>, IMap<TKey, TValue>, IDictionary<TKey, TValue>)
  protected
  {$REGION 'Nested Types'}
    type
      TKeyValuePair = Generics.Collections.TPair<TKey, TValue>;
      TItem = TDictionaryItem<TKey, TValue>;
      PItem = ^TItem;

      TEnumerator = class(TRefCountedObject, IEnumerator<TKeyValuePair>)
      private
        {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
        fSource: TDictionary<TKey, TValue>;
        fItemIndex: Integer;
        fVersion: Integer;
        function GetCurrent: TKeyValuePair;
      public
        constructor Create(const source: TDictionary<TKey, TValue>);
        function MoveNext: Boolean;
      end;

      TKeyCollection = class(TContainedReadOnlyCollection<TKey>,
        IEnumerable<TKey>, IReadOnlyCollection<TKey>)
      private
        {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
        fSource: TDictionary<TKey, TValue>;
      {$REGION 'Property Accessors'}
        function GetCount: Integer;
        function GetIsEmpty: Boolean;
      {$ENDREGION}
      public
        constructor Create(const source: TDictionary<TKey, TValue>);

      {$REGION 'Implements IEnumerable<TKey>'}
        function GetEnumerator: IEnumerator<TKey>;
        function Contains(const value: TKey): Boolean; overload;
        function ToArray: TArray<TKey>;
        function TryGetElementAt(out key: TKey; index: Integer): Boolean; override;
      {$ENDREGION}
      end;

      TKeyEnumerator = class(TRefCountedObject, IEnumerator<TKey>)
      private
        {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
        fSource: TDictionary<TKey, TValue>;
        fItemIndex: Integer;
        fVersion: Integer;
        function GetCurrent: TKey;
      public
        constructor Create(const source: TDictionary<TKey, TValue>);
        destructor Destroy; override;
        function MoveNext: Boolean;
      end;

      TValueCollection = class(TContainedReadOnlyCollection<TValue>,
        IEnumerable<TValue>, IReadOnlyCollection<TValue>)
      private
        {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
        fSource: TDictionary<TKey, TValue>;
      {$REGION 'Property Accessors'}
        function GetCount: Integer;
        function GetIsEmpty: Boolean;
      {$ENDREGION}
      public
        constructor Create(const source: TDictionary<TKey, TValue>);

      {$REGION 'Implements IEnumerable<TValue>'}
        function GetEnumerator: IEnumerator<TValue>;
        function Contains(const value: TValue): Boolean; overload;
        function ToArray: TArray<TValue>;
        function TryGetElementAt(out value: TValue; index: Integer): Boolean; override;
      {$ENDREGION}
      end;

      TValueEnumerator = class(TRefCountedObject, IEnumerator<TValue>)
      private
        {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
        fSource: TDictionary<TKey, TValue>;
        fItemIndex: Integer;
        fVersion: Integer;
        function GetCurrent: TValue;
      public
        constructor Create(const source: TDictionary<TKey, TValue>);
        destructor Destroy; override;
        function MoveNext: Boolean;
      end;

      TOrderedEnumerable = class(TIterator<TKeyValuePair>, IEnumerable<TKeyValuePair>)
      private
        {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
        fSource: TDictionary<TKey, TValue>;
        fSortedItemIndices: TArray<Integer>;
        fIndex: Integer;
        fVersion: Integer;
      {$REGION 'Property Accessors'}
        function GetCount: Integer;
        function GetIsEmpty: Boolean;
      {$ENDREGION}
      protected
        function Clone: TIterator<TKeyValuePair>; override;
        procedure Dispose; override;
        procedure Start; override;
        function TryMoveNext(var current: TKeyValuePair): Boolean; override;
      public
        constructor Create(const source: TDictionary<TKey, TValue>);
        destructor Destroy; override;
      end;
  public
    type
      TDictionaryItem = record
      private
        {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
        fSource: TDictionary<TKey,TValue>;
        fHashCode: Integer;
        fBucketIndex: Integer;
        fItemIndex: Integer;
        {$IFDEF ASSERTIONS_ON}
        fVersion: Integer;
        {$ENDIF}
        function GetValue: TValue;
        procedure SetValue(const value: TValue);
      public
        procedure Add(const key: TKey; const value: TValue);
        procedure Remove;
        property Value: TValue read GetValue write SetValue;
      end;
  {$ENDREGION}
  private
    fBuckets: TArray<Integer>;
    fItems: TArray<TItem>;
    fCount: Integer;
    fItemCount: Integer;
    fVersion: Integer;
    fBucketIndexMask: Integer;
    fBucketHashCodeMask: Integer;
    fKeyComparer: IEqualityComparer<TKey>;
    fValueComparer: IEqualityComparer<TValue>;
    fKeys: TKeyCollection;
    fValues: TValueCollection;
    fOwnerships: TDictionaryOwnerships;
  {$REGION 'Property Accessors'}
    function GetCapacity: Integer; inline;
    function GetCount: Integer;
    function GetIsEmpty: Boolean;
    function GetItem(const key: TKey): TValue;
    function GetKeys: IReadOnlyCollection<TKey>;
    function GetValues: IReadOnlyCollection<TValue>;
    procedure SetCapacity(value: Integer);
    procedure SetItem(const key: TKey; const value: TValue);
  {$ENDREGION}
    procedure Rehash(newCapacity: Integer);
    procedure EnsureCompact;
    procedure Grow;
    function Find(const key: TKey; hashCode: Integer;
      out bucketIndex, itemIndex: Integer): Boolean;
    function Hash(const key: TKey): Integer; inline;
    procedure DoAdd(hashCode, bucketIndex, itemIndex: Integer;
      const key: TKey; const value: TValue);
    procedure DoSetValue(itemIndex: Integer; const value: TValue);
    procedure DoRemove(bucketIndex, itemIndex: Integer;
      action: TCollectionChangedAction);
    function DoMoveNext(var itemIndex: Integer;
      iteratorVersion: Integer): Boolean;
  protected
    procedure KeyChanged(const item: TKey; action: TCollectionChangedAction); inline;
    procedure ValueChanged(const item: TValue; action: TCollectionChangedAction); inline;
    property Capacity: Integer read GetCapacity;
  public
    constructor Create; overload; override;
    constructor Create(ownerships: TDictionaryOwnerships); overload;
    constructor Create(capacity: Integer; ownerships: TDictionaryOwnerships = []); overload;
    constructor Create(const keyComparer: IEqualityComparer<TKey>;
      ownerships: TDictionaryOwnerships = []); overload;
    constructor Create(const keyComparer: IEqualityComparer<TKey>;
      const valueComparer: IEqualityComparer<TValue>;
      ownerships: TDictionaryOwnerships = []); overload;
    constructor Create(capacity: Integer; const keyComparer: IEqualityComparer<TKey>;
      ownerships: TDictionaryOwnerships = []); overload;
    constructor Create(capacity: Integer; const keyComparer: IEqualityComparer<TKey>;
      const valueComparer: IEqualityComparer<TValue>;
      ownerships: TDictionaryOwnerships = []); overload;

    destructor Destroy; override;

    function FindItem(const key: TKey; out item: TDictionaryItem): Boolean;

  {$REGION 'Implements IEnumerable<TPair<TKey, TValue>>'}
    function GetEnumerator: IEnumerator<TKeyValuePair>;
    function Contains(const value: TKeyValuePair;
      const comparer: IEqualityComparer<TKeyValuePair>): Boolean; overload;
    function Ordered: IEnumerable<TKeyValuePair>; overload;
    function ToArray: TArray<TKeyValuePair>;
    function TryGetElementAt(out item: TKeyValuePair; index: Integer): Boolean; override;
  {$ENDREGION}

  {$REGION 'Implements ICollection<TPair<TKey, TValue>>'}
    procedure Clear;
  {$ENDREGION}

  {$REGION 'Implements IMap<TKey, TValue>'}
    function TryAdd(const key: TKey; const value: TValue): Boolean;
    function Remove(const key: TKey): Boolean; overload;
    function Remove(const key: TKey; const value: TValue): Boolean; overload;
    function Extract(const key: TKey; const value: TValue): TKeyValuePair; overload;
    function Contains(const key: TKey; const value: TValue): Boolean; overload;
    function ContainsKey(const key: TKey): Boolean;
    function ContainsValue(const value: TValue): Boolean;
    property Keys: IReadOnlyCollection<TKey> read GetKeys;
    property Values: IReadOnlyCollection<TValue> read GetValues;
  {$ENDREGION}

  {$REGION 'Implements IDictionary<TKey, TValue>'}
    function Extract(const key: TKey): TValue; overload;
    function GetValueOrDefault(const key: TKey): TValue; overload;
    function GetValueOrDefault(const key: TKey; const defaultValue: TValue): TValue; overload;
    function TryExtract(const key: TKey; out value: TValue): Boolean;
    function TryGetValue(const key: TKey; out value: TValue): Boolean;
    procedure TrimExcess;
    function AsReadOnly: IReadOnlyDictionary<TKey, TValue>;

    property Items[const key: TKey]: TValue read GetItem write SetItem; default;
    property KeyComparer: IEqualityComparer<TKey> read fKeyComparer;
  {$ENDREGION}
  end;

  TContainedDictionary<TKey, TValue> = class(TDictionary<TKey, TValue>)
  private
    {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
    fController: TRefCountedObject;
  public
    constructor Create(const controller: TRefCountedObject;
      const keyComparer: IEqualityComparer<TKey>;
      ownerships: TDictionaryOwnerships);
  {$REGION 'Implements IInterface'}
    function _AddRef: Integer; override;
    function _Release: Integer; override;
  {$ENDREGION}
  end;

  TBidiDictionaryItem<TKey, TValue> = record
  public
    KeyHashCode: Integer;
    ValueHashCode: Integer;
    Key: TKey;
    Value: TValue;
    function Removed: Boolean; inline;
  end;

  TBidiDictionary<TKey, TValue> = class(TMapBase<TKey, TValue>,
    IEnumerable<TPair<TKey, TValue>>, IReadOnlyCollection<TPair<TKey, TValue>>,
    IReadOnlyMap<TKey, TValue>, IReadOnlyDictionary<TKey, TValue>,
    ICollection<TPair<TKey, TValue>>, IMap<TKey, TValue>,
    IDictionary<TKey, TValue>, IBidiDictionary<TKey, TValue>)
  protected
  {$REGION 'Nested Types'}
    type
      TKeyValuePair = Generics.Collections.TPair<TKey, TValue>;
      TValueKeyPair = Generics.Collections.TPair<TValue, TKey>;
      TItem = TBidiDictionaryItem<TKey, TValue>;
      PItem = ^TItem;

      TInverse = class(TContainedCollectionBase<TValueKeyPair>,
        IEnumerable<TValueKeyPair>, IReadOnlyCollection<TValueKeyPair>,
        IReadOnlyMap<TValue, TKey>, IReadOnlyDictionary<TValue, TKey>,
        ICollection<TValueKeyPair>, IMap<TValue, TKey>,
        IDictionary<TValue, TKey>, IBidiDictionary<TValue, TKey>)
      private type
      {$REGION 'Nested Types'}
        TEnumerator = class(TRefCountedObject, IEnumerator<TValueKeyPair>)
        private
          {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
          fSource: TBidiDictionary<TKey, TValue>;
          fItemIndex: Integer;
          fVersion: Integer;
          function GetCurrent: TValueKeyPair;
        public
          constructor Create(const source: TBidiDictionary<TKey, TValue>);
          destructor Destroy; override;
          function MoveNext: Boolean;
        end;

        TOrderedEnumerable = class(TIterator<TValueKeyPair>, IEnumerable<TValueKeyPair>)
        private
          {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
          fSource: TBidiDictionary<TKey, TValue>;
          fSortedItemIndices: TArray<Integer>;
          fIndex: Integer;
          fVersion: Integer;
        {$REGION 'Property Accessors'}
          function GetCount: Integer;
          function GetIsEmpty: Boolean;
        {$ENDREGION}
        protected
          function Clone: TIterator<TValueKeyPair>; override;
          procedure Dispose; override;
          procedure Start; override;
          function TryMoveNext(var current: TValueKeyPair): Boolean; override;
        public
          constructor Create(const source: TBidiDictionary<TKey, TValue>);
          destructor Destroy; override;
        end;
      {$ENDREGION}
      private
        {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
        fSource: TBidiDictionary<TKey, TValue>;
      {$REGION 'Property Accessors'}
        function GetCapacity: Integer;
        function GetCount: Integer;
        function GetInverse: IBidiDictionary<TKey, TValue>;
        function GetIsEmpty: Boolean;
        function GetItem(const value: TValue): TKey;
        function GetKeys: IReadOnlyCollection<TValue>;
        function GetKeyType: PTypeInfo;
        function GetOnKeyChanged: ICollectionChangedEvent<TValue>;
        function GetOnValueChanged: ICollectionChangedEvent<TKey>;
        function GetValues: IReadOnlyCollection<TKey>;
        function GetValueType: PTypeInfo;
        procedure SetCapacity(value: Integer);
        procedure SetItem(const value: TValue; const key: TKey);
      {$ENDREGION}
      protected
        procedure Changed(const item: TValueKeyPair; action: TCollectionChangedAction); override;
      public
        constructor Create(const source: TBidiDictionary<TKey, TValue>);

      {$REGION 'Implements IEnumerable<TPair<TKey, TValue>>'}
        function GetEnumerator: IEnumerator<TValueKeyPair>;
        function Contains(const value: TValueKeyPair): Boolean; overload;
        function Contains(const value: TValueKeyPair;
          const comparer: IEqualityComparer<TValueKeyPair>): Boolean; overload;
        function Ordered: IEnumerable<TValueKeyPair>; overload;
        function ToArray: TArray<TValueKeyPair>;
        function TryGetElementAt(out item: TValueKeyPair; index: Integer): Boolean; override;
      {$ENDREGION}

      {$REGION 'Implements ICollection<TPair<TKey, TValue>>'}
        function Add(const item: TValueKeyPair): Boolean; overload;
        function Remove(const item: TValueKeyPair): Boolean; overload;
        function Extract(const item: TValueKeyPair): TValueKeyPair; overload;
        procedure Clear;
      {$ENDREGION}

      {$REGION 'Implements IMap<TValue, TKey>'}
        procedure Add(const value: TValue; const key: TKey); overload;
        function TryAdd(const value: TValue; const key: TKey): Boolean;
        function Remove(const value: TValue): Boolean; overload;
        function Remove(const value: TValue; const key: TKey): Boolean; overload;
        function Extract(const value: TValue; const key: TKey): TValueKeyPair; overload;
        function Contains(const value: TValue; const key: TKey): Boolean; overload;
        function ContainsKey(const value: TValue): Boolean;
        function ContainsValue(const key: TKey): Boolean;
        property Keys: IReadOnlyCollection<TValue> read GetKeys;
        property Values: IReadOnlyCollection<TKey> read GetValues;
      {$ENDREGION}

      {$REGION 'Implements IDictionary<TValue, TKey>'}
        function Extract(const value: TValue): TKey; overload;
        function GetValueOrDefault(const value: TValue): TKey; overload;
        function GetValueOrDefault(const value: TValue; const defaultKey: TKey): TKey; overload;
        function TryExtract(const value: TValue; out key: TKey): Boolean;
        function TryGetValue(const value: TValue; out key: TKey): Boolean;
        procedure TrimExcess;
        function AsReadOnly: IReadOnlyDictionary<TValue, TKey>;
      {$ENDREGION}
      end;

      TEnumerator = class(TRefCountedObject, IEnumerator<TKeyValuePair>)
      private
        {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
        fSource: TBidiDictionary<TKey, TValue>;
        fItemIndex: Integer;
        fVersion: Integer;
        function GetCurrent: TKeyValuePair;
      public
        constructor Create(const source: TBidiDictionary<TKey, TValue>);
        destructor Destroy; override;
        function MoveNext: Boolean;
      end;

      TKeyCollection = class(TContainedReadOnlyCollection<TKey>,
        IEnumerable<TKey>, IReadOnlyCollection<TKey>)
      private
        {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
        fSource: TBidiDictionary<TKey, TValue>;
      {$REGION 'Property Accessors'}
        function GetCount: Integer;
        function GetIsEmpty: Boolean;
      {$ENDREGION}
      public
        constructor Create(const source: TBidiDictionary<TKey, TValue>);

      {$REGION 'Implements IEnumerable<TKey>'}
        function GetEnumerator: IEnumerator<TKey>;
        function Contains(const value: TKey): Boolean; overload;
        function ToArray: TArray<TKey>;
        function TryGetElementAt(out key: TKey; index: Integer): Boolean; override;
      {$ENDREGION}
      end;

      TKeyEnumerator = class(TRefCountedObject, IEnumerator<TKey>)
      private
        {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
        fSource: TBidiDictionary<TKey, TValue>;
        fItemIndex: Integer;
        fVersion: Integer;
        function GetCurrent: TKey;
      public
        constructor Create(const source: TBidiDictionary<TKey, TValue>);
        destructor Destroy; override;
        function MoveNext: Boolean;
      end;

      TValueCollection = class(TContainedReadOnlyCollection<TValue>,
        IEnumerable<TValue>, IReadOnlyCollection<TValue>)
      private
        {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
        fSource: TBidiDictionary<TKey, TValue>;
      {$REGION 'Property Accessors'}
        function GetCount: Integer;
        function GetIsEmpty: Boolean;
      {$ENDREGION}
      public
        constructor Create(const source: TBidiDictionary<TKey, TValue>);

      {$REGION 'Implements IEnumerable<TValue>'}
        function GetEnumerator: IEnumerator<TValue>;
        function Contains(const value: TValue): Boolean; overload;
        function ToArray: TArray<TValue>;
        function TryGetElementAt(out value: TValue; index: Integer): Boolean; override;
      {$ENDREGION}
      end;

      TValueEnumerator = class(TRefCountedObject, IEnumerator<TValue>)
      private
        {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
        fSource: TBidiDictionary<TKey, TValue>;
        fItemIndex: Integer;
        fVersion: Integer;
        function GetCurrent: TValue;
      public
        constructor Create(const source: TBidiDictionary<TKey, TValue>);
        destructor Destroy; override;
        function MoveNext: Boolean;
      end;

      TOrderedEnumerable = class(TIterator<TKeyValuePair>, IEnumerable<TKeyValuePair>)
      private
        {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
        fSource: TBidiDictionary<TKey, TValue>;
        fSortedItemIndices: TArray<Integer>;
        fIndex: Integer;
        fVersion: Integer;
      {$REGION 'Property Accessors'}
        function GetCount: Integer;
        function GetIsEmpty: Boolean;
      {$ENDREGION}
      protected
        function Clone: TIterator<TKeyValuePair>; override;
        procedure Dispose; override;
        procedure Start; override;
        function TryMoveNext(var current: TKeyValuePair): Boolean; override;
      public
        constructor Create(const source: TBidiDictionary<TKey, TValue>);
        destructor Destroy; override;
      end;
  {$ENDREGION}
  private
    fKeyBuckets: TArray<Integer>;
    fValueBuckets: TArray<Integer>;
    fItems: TArray<TItem>;
    fCount: Integer;
    fItemCount: Integer;
    fVersion: Integer;
    fBucketIndexMask: Integer;
    fBucketHashCodeMask: Integer;
    fKeyComparer: IEqualityComparer<TKey>;
    fValueComparer: IEqualityComparer<TValue>;
    fKeys: TKeyCollection;
    fValues: TValueCollection;
    fInverse: TInverse;
    fOwnerships: TDictionaryOwnerships;
  {$REGION 'Property Accessors'}
    function GetCapacity: Integer; inline;
    function GetCount: Integer;
    function GetInverse: IBidiDictionary<TValue, TKey>;
    function GetIsEmpty: Boolean;
    function GetItem(const key: TKey): TValue;
    function GetKeys: IReadOnlyCollection<TKey>;
    function GetValues: IReadOnlyCollection<TValue>;
    procedure SetCapacity(value: Integer);
    procedure SetItem(const key: TKey; const value: TValue);
  {$ENDREGION}
    procedure Rehash(newCapacity: Integer);
    procedure EnsureCompact;
    procedure Grow;
    function FindKey(const key: TKey; hashCode: Integer;
      out bucketIndex, itemIndex: Integer): Boolean;
    function FindValue(const value: TValue; hashCode: Integer;
      out bucketIndex, itemIndex: Integer): Boolean;
    function KeyHash(const key: TKey): Integer; inline;
    function ValueHash(const value: TValue): Integer; inline;
    procedure DoAdd(keyhashCode, keyBucketIndex, valueHashCode, valueBucketIndex,
      itemIndex: Integer; const key: TKey; const value: TValue);
    procedure DoRemove(keyBucketIndex, valueBucketIndex, itemIndex: Integer;
      action: TCollectionChangedAction);
    procedure DoSetKey(valueBucketIndex, itemIndex, keyHashCode: Integer;
      const key: TKey);
    procedure DoSetValue(keyBucketIndex, itemIndex, valueHashCode: Integer;
      const value: TValue);
    function DoMoveNext(var itemIndex: Integer;
      iteratorVersion: Integer): Boolean;

    procedure AddOrSetKey(const value: TValue; const key: TKey);
  protected
    procedure Changed(const item: TPair<TKey, TValue>; action: TCollectionChangedAction); override;
    procedure KeyChanged(const item: TKey; action: TCollectionChangedAction);
    procedure ValueChanged(const item: TValue; action: TCollectionChangedAction);
    property Capacity: Integer read GetCapacity;
  public
    constructor Create; overload; override;
    constructor Create(ownerships: TDictionaryOwnerships); overload;
    constructor Create(capacity: Integer; ownerships: TDictionaryOwnerships = []); overload;
    constructor Create(const keyComparer: IEqualityComparer<TKey>;
      ownerships: TDictionaryOwnerships = []); overload;
    constructor Create(const keyComparer: IEqualityComparer<TKey>;
      const valueComparer: IEqualityComparer<TValue>;
      ownerships: TDictionaryOwnerships = []); overload;
    constructor Create(capacity: Integer; const keyComparer: IEqualityComparer<TKey>;
      ownerships: TDictionaryOwnerships = []); overload;
    constructor Create(capacity: Integer; const keyComparer: IEqualityComparer<TKey>;
      const valueComparer: IEqualityComparer<TValue>;
      ownerships: TDictionaryOwnerships = []); overload;
    destructor Destroy; override;

  {$REGION 'Implements IEnumerable<TPair<TKey, TValue>>'}
    function GetEnumerator: IEnumerator<TKeyValuePair>;
    function Contains(const value: TKeyValuePair;
      const comparer: IEqualityComparer<TKeyValuePair>): Boolean; overload;
    function Ordered: IEnumerable<TKeyValuePair>; overload;
    function ToArray: TArray<TKeyValuePair>;
  {$ENDREGION}

  {$REGION 'Implements ICollection<TPair<TKey, TValue>>'}
    procedure Clear;
  {$ENDREGION}

  {$REGION 'Implements IMap<TKey, TValue>'}
    function TryAdd(const key: TKey; const value: TValue): Boolean;
    function Remove(const key: TKey): Boolean; overload;
    function Remove(const key: TKey; const value: TValue): Boolean; overload;
    function Extract(const key: TKey; const value: TValue): TKeyValuePair; overload;
    function Contains(const key: TKey; const value: TValue): Boolean; overload;
    function ContainsKey(const key: TKey): Boolean;
    function ContainsValue(const value: TValue): Boolean;
    property Keys: IReadOnlyCollection<TKey> read GetKeys;
    property Values: IReadOnlyCollection<TValue> read GetValues;
  {$ENDREGION}

  {$REGION 'Implements IDictionary<TKey, TValue>'}
    function Extract(const key: TKey): TValue; overload;
    function GetValueOrDefault(const key: TKey): TValue; overload;
    function GetValueOrDefault(const key: TKey; const defaultValue: TValue): TValue; overload;
    function TryExtract(const key: TKey; out value: TValue): Boolean;
    function TryGetValue(const key: TKey; out value: TValue): Boolean;
    procedure TrimExcess;
    function AsReadOnly: IReadOnlyDictionary<TKey, TValue>;

    property Items[const key: TKey]: TValue read GetItem write SetItem; default;
  {$ENDREGION}
  end;

  TSortedDictionary<TKey, TValue> = class(TMapBase<TKey, TValue>,
    IEnumerable<TPair<TKey, TValue>>, IReadOnlyCollection<TPair<TKey, TValue>>,
    IReadOnlyMap<TKey, TValue>, IReadOnlyDictionary<TKey, TValue>,
    ICollection<TPair<TKey, TValue>>, IMap<TKey, TValue>, IDictionary<TKey, TValue>)
  private
  {$REGION 'Nested Types'}
    type
      TKeyValuePair = Generics.Collections.TPair<TKey, TValue>;
      PNode = TNodes<TKey, TValue>.PRedBlackTreeNode;

      TEnumerator = class(TRefCountedObject, IEnumerator<TKeyValuePair>)
      private
        {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
        fSource: TSortedDictionary<TKey, TValue>;
        fCurrentNode: PNode;
        fFinished: Boolean;
        fVersion: Integer;
        function GetCurrent: TKeyValuePair;
      public
        constructor Create(const source: TSortedDictionary<TKey, TValue>);
        destructor Destroy; override;
        function MoveNext: Boolean;
      end;

      TKeyCollection = class(TContainedReadOnlyCollection<TKey>,
        IEnumerable<TKey>, IReadOnlyCollection<TKey>)
      private
        {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
        fSource: TSortedDictionary<TKey, TValue>;
      {$REGION 'Property Accessors'}
        function GetCount: Integer;
        function GetIsEmpty: Boolean;
      {$ENDREGION}
      public
        constructor Create(const source: TSortedDictionary<TKey, TValue>);

      {$REGION 'Implements IEnumerable<TKey>'}
        function GetEnumerator: IEnumerator<TKey>;
        function Contains(const value: TKey): Boolean; overload;
        function ToArray: TArray<TKey>;
      {$ENDREGION}
      end;

      TKeyEnumerator = class(TRefCountedObject, IEnumerator<TKey>)
      private
        {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
        fSource: TSortedDictionary<TKey, TValue>;
        fCurrentNode: PNode;
        fFinished: Boolean;
        fVersion: Integer;
        function GetCurrent: TKey;
      public
        constructor Create(const source: TSortedDictionary<TKey, TValue>);
        destructor Destroy; override;
        function MoveNext: Boolean;
      end;

      TValueCollection = class(TContainedReadOnlyCollection<TValue>,
        IEnumerable<TValue>, IReadOnlyCollection<TValue>)
      private
        {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
        fSource: TSortedDictionary<TKey, TValue>;
      {$REGION 'Property Accessors'}
        function GetCount: Integer;
        function GetIsEmpty: Boolean;
      {$ENDREGION}
      public
        constructor Create(const dictionary: TSortedDictionary<TKey, TValue>);

      {$REGION 'Implements IEnumerable<TValue>'}
        function GetEnumerator: IEnumerator<TValue>;
        function Contains(const value: TValue): Boolean; overload;
        function ToArray: TArray<TValue>;
      {$ENDREGION}
      end;

      TValueEnumerator = class(TRefCountedObject, IEnumerator<TValue>)
      private
        {$IFDEF AUTOREFCOUNT}[Unsafe]{$ENDIF}
        fSource: TSortedDictionary<TKey, TValue>;
        fCurrentNode: PNode;
        fFinished: Boolean;
        fVersion: Integer;
        function GetCurrent: TValue;
      public
        constructor Create(const source: TSortedDictionary<TKey, TValue>);
        destructor Destroy; override;
        function MoveNext: Boolean;
      end;
  {$ENDREGION}
  private
    fTree: TRedBlackTree<TKey,TValue>;
    fKeyComparer: IComparer<TKey>;
    fValueComparer: IEqualityComparer<TValue>;
    fKeyValueComparerByKey: IComparer<TKeyValuePair>;
    fVersion: Integer;
    fKeys: TKeyCollection;
    fValues: TValueCollection;
  {$REGION 'Property Accessors'}
    function GetCapacity: Integer;
    function GetCount: Integer;
    function GetIsEmpty: Boolean;
    function GetItem(const key: TKey): TValue;
    function GetKeys: IReadOnlyCollection<TKey>;
    function GetValues: IReadOnlyCollection<TValue>;
    procedure SetCapacity(value: Integer);
    procedure SetItem(const key: TKey; const value: TValue);
  {$ENDREGION}
    function DoMoveNext(var currentNode: PNode; var finished: Boolean;
      iteratorVersion: Integer): Boolean;
  public
    constructor Create; override;
    constructor Create(const keyComparer: IComparer<TKey>; const valueComparer: IEqualityComparer<TValue>); overload;
    destructor Destroy; override;

  {$REGION 'Implements IEnumerable<TPair<TKey, TValue>>'}
    function GetEnumerator: IEnumerator<TKeyValuePair>;
    function Contains(const value: TKeyValuePair;
      const comparer: IEqualityComparer<TKeyValuePair>): Boolean; overload;
    function Ordered: IEnumerable<TKeyValuePair>; overload;
    function ToArray: TArray<TKeyValuePair>;
  {$ENDREGION}

  {$REGION 'Implements ICollection<TPair<TKey, TValue>>'}
    procedure Clear;
  {$ENDREGION}

  {$REGION 'Implements IMap<TKey, TValue>'}
    function TryAdd(const key: TKey; const value: TValue): Boolean;
    function Remove(const key: TKey): Boolean; overload;
    function Remove(const key: TKey; const value: TValue): Boolean; overload;
    function Extract(const key: TKey; const value: TValue): TKeyValuePair; overload;
    function Contains(const key: TKey; const value: TValue): Boolean; overload;
    function ContainsKey(const key: TKey): Boolean;
    function ContainsValue(const value: TValue): Boolean;
    property Keys: IReadOnlyCollection<TKey> read GetKeys;
    property Values: IReadOnlyCollection<TValue> read GetValues;
  {$ENDREGION}

  {$REGION 'Implements IDictionary<TKey, TValue>'}
    function Extract(const key: TKey): TValue; overload;
    function TryExtract(const key: TKey; out value: TValue): Boolean;
    function TryGetValue(const key: TKey; out value: TValue): Boolean;
    procedure TrimExcess;
    function AsReadOnly: IReadOnlyDictionary<TKey, TValue>;

    property Items[const key: TKey]: TValue read GetItem write SetItem; default;
  {$ENDREGION}

  {$REGION 'Implements IReadOnlyDictionary<TKey, TValue>'}
    function GetValueOrDefault(const key: TKey): TValue; overload;
    function GetValueOrDefault(const key: TKey; const defaultValue: TValue): TValue; overload;
  {$ENDREGION}
  end;

implementation

uses
  Math,
  SysUtils,
  Types,
  TypInfo,
  Spring.Collections.Extensions,
  Spring.Collections.Lists,
  Spring.ResourceStrings;


{$REGION 'TDictionaryItem<TKey, TValue>'}

function TDictionaryItem<TKey, TValue>.Removed: Boolean;
begin
  Result := HashCode and RemovedFlag <> 0;
end;

{$ENDREGION}


{$REGION 'TDictionary<TKey, TValue>'}

constructor TDictionary<TKey, TValue>.Create;
begin
  Create(0, nil, nil);
end;

constructor TDictionary<TKey, TValue>.Create(ownerships: TDictionaryOwnerships);
begin
  Create(0, nil, nil, ownerships);
end;

constructor TDictionary<TKey, TValue>.Create(capacity: Integer;
  ownerships: TDictionaryOwnerships);
begin
  Create(capacity, nil, nil, ownerships);
end;

constructor TDictionary<TKey, TValue>.Create(
  const keyComparer: IEqualityComparer<TKey>;
  ownerships: TDictionaryOwnerships);
begin
  Create(0, keyComparer, nil, ownerships);
end;

constructor TDictionary<TKey, TValue>.Create(
  const keyComparer: IEqualityComparer<TKey>;
  const valueComparer: IEqualityComparer<TValue>;
  ownerships: TDictionaryOwnerships);
begin
  Create(0, keyComparer, valueComparer, ownerships);
end;

constructor TDictionary<TKey, TValue>.Create(capacity: Integer;
  const keyComparer: IEqualityComparer<TKey>;
  ownerships: TDictionaryOwnerships);
begin
  Create(capacity, keyComparer, nil, ownerships);
end;

constructor TDictionary<TKey, TValue>.Create(capacity: Integer;
  const keyComparer: IEqualityComparer<TKey>;
  const valueComparer: IEqualityComparer<TValue>;
  ownerships: TDictionaryOwnerships);
begin
{$IFDEF SPRING_ENABLE_GUARD}
  Guard.CheckRange(capacity >= 0, 'capacity');
{$ENDIF}

  if doOwnsKeys in ownerships then
    if TType.Kind<TKey> <> tkClass then
      raise Error.NoClassType(KeyType);

  if doOwnsValues in ownerships then
    if TType.Kind<TValue> <> tkClass then
      raise Error.NoClassType(ValueType);

  inherited Create;
  fOwnerships := ownerships;
  fKeys := TKeyCollection.Create(Self);
  fValues := TValueCollection.Create(Self);
  if Assigned(keyComparer) then
    fKeyComparer := keyComparer
  else
    fKeyComparer := TEqualityComparer<TKey>.Default;
  if Assigned(valueComparer) then
    fValueComparer := valueComparer
  else
    fValueComparer := TEqualityComparer<TValue>.Default;
  SetCapacity(capacity);
end;

destructor TDictionary<TKey, TValue>.Destroy;
begin
  Clear;
  fKeys.Free;
  fValues.Free;
  inherited Destroy;
end;

procedure TDictionary<TKey, TValue>.KeyChanged(const item: TKey;
  action: TCollectionChangedAction);
begin
  if fOnKeyChanged.CanInvoke then
    fOnKeyChanged.Invoke(Self, item, action);
{$IFDEF DELPHIXE7_UP}
  if GetTypeKind(TKey) = tkClass then
{$ENDIF}
  if (action = caRemoved) and (doOwnsKeys in fOwnerships) then
    FreeObject(item);
end;

procedure TDictionary<TKey, TValue>.ValueChanged(const item: TValue;
  action: TCollectionChangedAction);
begin
  if fOnValueChanged.CanInvoke then
    fOnValueChanged.Invoke(Self, item, action);
{$IFDEF DELPHIXE7_UP}
  if GetTypeKind(TValue) = tkClass then
{$ENDIF}
  if (action = caRemoved) and (doOwnsValues in fOwnerships) then
    FreeObject(item);
end;

function TDictionary<TKey, TValue>.GetCapacity: Integer;
begin
  Result := DynArrayLength(fItems);
end;

procedure TDictionary<TKey, TValue>.SetCapacity(value: Integer);
var
  newCapacity: Integer;
begin
  Guard.CheckRange(value >= fCount, 'capacity');

  if value = 0 then
    newCapacity := 0
  else
    newCapacity := Math.Max(MinCapacity, value);
  if newCapacity <> Capacity then
    Rehash(newCapacity);
end;

procedure TDictionary<TKey, TValue>.Rehash(newCapacity: Integer);
var
  newBucketCount: Integer;
  bucketIndex, itemIndex: Integer;
  sourceItemIndex, targetItemIndex: Integer;
begin
  if newCapacity = 0 then
  begin
    Assert(fCount = 0);
    Assert(fItemCount = 0);
    Assert(not Assigned(fBuckets));
    Assert(not Assigned(fItems));
    Exit;
  end;

  Assert(newCapacity >= fCount);

  IncUnchecked(fVersion);

  newBucketCount := NextPowerOf2(newCapacity * 4 div 3 - 1); // 75% load factor

  // compact the items array, if necessary
  if fItemCount > fCount then
  begin
    targetItemIndex := 0;
    for sourceItemIndex := 0 to fItemCount - 1 do
      if not fItems[sourceItemIndex].Removed then
      begin
        if targetItemIndex < sourceItemIndex then
          TArrayManager<TItem>.Move(fItems, sourceItemIndex, targetItemIndex, 1);
        Inc(targetItemIndex);
      end;
    TArrayManager<TItem>.Finalize(fItems, targetItemIndex, fItemCount - fCount);
  end;

  // resize the items array, safe now that we have compacted it
  SetLength(fItems, newBucketCount * 3 div 4);
  Assert(Capacity >= fCount);

  // repopulate the bucket array
  Assert(IsPowerOf2(newBucketCount));
  fBucketIndexMask := newBucketCount - 1;
  fBucketHashCodeMask := not fBucketIndexMask and not BucketSentinelFlag;
  SetLength(fBuckets, newBucketCount);
  for bucketIndex := 0 to newBucketCount - 1 do
    fBuckets[bucketIndex] := EmptyBucket;
  fItemCount := 0;
  while fItemCount < fCount do
  begin
    Find(fItems[fItemCount].Key, fItems[fItemCount].HashCode, bucketIndex, itemIndex);
    Assert(itemIndex = fItemCount);
    fBuckets[bucketIndex] := itemIndex or (fItems[itemIndex].HashCode and fBucketHashCodeMask);
    Inc(fItemCount);
  end;
end;

procedure TDictionary<TKey, TValue>.Grow;
var
  newCapacity: Integer;
begin
  newCapacity := Capacity;
  if newCapacity = 0 then
    newCapacity := MinCapacity
  else if 2 * fCount >= Length(fBuckets) then
    // only grow if load factor is greater than 0.5
    newCapacity := newCapacity * 2;
  Rehash(newCapacity);
end;

function TDictionary<TKey, TValue>.Find(const key: TKey; hashCode: Integer;
  out bucketIndex, itemIndex: Integer): Boolean;
var
  bucketValue: Integer;
begin
  if fItems = nil then
  begin
    bucketIndex := EmptyBucket;
    itemIndex := -1;
    Exit(False);
  end;

  bucketIndex := hashCode and fBucketIndexMask;
  while True do
  begin
    bucketValue := fBuckets[bucketIndex];

    if bucketValue = EmptyBucket then
    begin
      itemIndex := fItemCount;
      Exit(False);
    end;

    if (bucketValue <> UsedBucket)
      and (bucketValue and fBucketHashCodeMask = hashCode and fBucketHashCodeMask) then
    begin
      itemIndex := bucketValue and fBucketIndexMask;
      if fKeyComparer.Equals(fItems[itemIndex].Key, key) then
        Exit(True);
    end;

    bucketIndex := (bucketIndex + 1) and fBucketIndexMask;
  end;
end;

function TDictionary<TKey, TValue>.FindItem(const key: TKey; out item: TDictionaryItem): Boolean;
begin
  item.fSource := Self;
  item.fHashCode := Hash(key);
  Result := Find(key, item.fHashCode, item.fBucketIndex, item.fItemIndex);
{$IFDEF ASSERTIONS_ON}
  item.fVersion := fVersion;
{$ENDIF}
end;

function TDictionary<TKey, TValue>.Hash(const key: TKey): Integer;
begin
  Result := fKeyComparer.GetHashCode(key) and not RemovedFlag;
end;

procedure TDictionary<TKey, TValue>.DoAdd(hashCode, bucketIndex, itemIndex: Integer;
  const key: TKey; const value: TValue);
begin
  {$IFOPT Q+}{$DEFINE OVERFLOWCHECKS_ON}{$Q-}{$ENDIF}
  Inc(fVersion);
  {$IFDEF OVERFLOWCHECKS_ON}{$Q+}{$ENDIF}
  fBuckets[bucketIndex] := itemIndex or (hashCode and fBucketHashCodeMask);
  fItems[itemIndex].HashCode := hashCode;
  fItems[itemIndex].Key := key;
  fItems[itemIndex].Value := value;
  Inc(fCount);
  Inc(fItemCount);

  if Assigned(Notify) then
    DoNotify(key, value, caAdded);
  KeyChanged(key, caAdded);
  ValueChanged(value, caAdded);
end;

procedure TDictionary<TKey, TValue>.DoSetValue(itemIndex: Integer;
  const value: TValue);
var
  oldValue: TValue;
begin
  oldValue := fItems[itemIndex].Value;

  IncUnchecked(fVersion);
  fItems[itemIndex].Value := value;

  if Assigned(Notify) then
    DoNotify(fItems[itemIndex].Key, oldValue, caRemoved);
  ValueChanged(oldValue, caRemoved);
  if Assigned(Notify) then
    DoNotify(fItems[itemIndex].Key, value, caAdded);
  ValueChanged(value, caAdded);
end;

procedure TDictionary<TKey, TValue>.DoRemove(bucketIndex, itemIndex: Integer;
  action: TCollectionChangedAction);
var
  oldKey: TKey;
  oldValue: TValue;
begin
  oldKey := fItems[itemIndex].Key;
  oldValue := fItems[itemIndex].Value;

  IncUnchecked(fVersion);
  fBuckets[bucketIndex] := UsedBucket;
  fItems[itemIndex].Key := Default(TKey);
  fItems[itemIndex].Value := Default(TValue);
  fItems[itemIndex].HashCode := RemovedFlag;
  Dec(fCount);

  if Assigned(Notify) then
    DoNotify(oldKey, oldValue, action);
  KeyChanged(oldKey, action);
  ValueChanged(oldValue, action);
end;

function TDictionary<TKey, TValue>.DoMoveNext(var itemIndex: Integer;
  iteratorVersion: Integer): Boolean;
begin
  if iteratorVersion <> fVersion then
    raise Error.EnumFailedVersion;

  while itemIndex < fItemCount - 1 do
  begin
    Inc(itemIndex);
    if not fItems[itemIndex].Removed then
      Exit(True);
  end;
  Result := False;
end;

function TDictionary<TKey, TValue>.GetEnumerator: IEnumerator<TKeyValuePair>;
begin
  Result := TEnumerator.Create(self);
end;

procedure TDictionary<TKey, TValue>.Clear;
var
  oldItemIndex, oldItemCount: Integer;
  oldItems: TArray<TItem>;
begin
  oldItemCount := fItemCount;
  oldItems := fItems;

  IncUnchecked(fVersion);
  fCount := 0;
  fItemCount := 0;
  fBuckets := nil;
  fItems := nil;
  SetCapacity(0);

  for oldItemIndex := 0 to oldItemCount - 1 do
    if not oldItems[oldItemIndex].Removed then
    begin
      if Assigned(Notify) then
        DoNotify(oldItems[oldItemIndex].Key, oldItems[oldItemIndex].Value, caRemoved);
      KeyChanged(oldItems[oldItemIndex].Key, caRemoved);
      ValueChanged(oldItems[oldItemIndex].Value, caRemoved);
    end;
end;

function TDictionary<TKey, TValue>.Contains(const value: TKeyValuePair;
  const comparer: IEqualityComparer<TKeyValuePair>): Boolean;
var
  pair: TKeyValuePair;
begin
  pair.Key := value.Key;
  Result := TryGetValue(value.Key, pair.Value)
    and comparer.Equals(pair, value);
end;

function TDictionary<TKey, TValue>.ToArray: TArray<TKeyValuePair>;
var
  sourceIndex, targetIndex: Integer;
begin
  SetLength(Result, fCount);
  targetIndex := 0;
  for sourceIndex := 0 to fItemCount - 1 do
    if not fItems[sourceIndex].Removed then
    begin
      Result[targetIndex].Key := fItems[sourceIndex].Key;
      Result[targetIndex].Value := fItems[sourceIndex].Value;
      Inc(targetIndex);
    end;
end;

function TDictionary<TKey, TValue>.GetCount: Integer;
begin
  Result := fCount;
end;

function TDictionary<TKey, TValue>.GetIsEmpty: Boolean;
begin
  Result := fCount = 0;
end;

function TDictionary<TKey, TValue>.AsReadOnly: IReadOnlyDictionary<TKey, TValue>;
begin
  Result := Self;
end;

function TDictionary<TKey, TValue>.ContainsKey(const key: TKey): Boolean;
var
  bucketIndex, itemIndex: Integer;
begin
  Result := Find(key, Hash(key), bucketIndex, itemIndex);
end;

function TDictionary<TKey, TValue>.Contains(const key: TKey;
  const value: TValue): Boolean;
var
  item: TValue;
begin
  Result := TryGetValue(key, item)
    and fValueComparer.Equals(item, value);
end;

function TDictionary<TKey, TValue>.ContainsValue(
  const value: TValue): Boolean;
var
  itemIndex: Integer;
begin
  for itemIndex := 0 to fItemCount - 1 do
    if not fItems[itemIndex].Removed then
      if fValueComparer.Equals(fItems[itemIndex].Value, value) then
        Exit(True);
  Result := False;
end;

procedure TDictionary<TKey, TValue>.EnsureCompact;
begin
  if fCount <> fItemCount then
    Rehash(Capacity);
end;

function TDictionary<TKey, TValue>.Extract(const key: TKey): TValue;
begin
  TryExtract(key, Result);
end;

function TDictionary<TKey, TValue>.Extract(const key: TKey;
  const value: TValue): TKeyValuePair;
var
  bucketIndex, itemIndex: Integer;
  foundItem: PItem;
begin
  if Find(key, Hash(key), bucketIndex, itemIndex) then
  begin
    foundItem := @fItems[itemIndex];
    if fValueComparer.Equals(foundItem.Value, Value) then
    begin
      Result.Key := foundItem.Key;
      Result.Value := foundItem.Value;
      DoRemove(bucketIndex, itemIndex, caExtracted);
      Exit;
    end;
  end;
  Result := Default(TKeyValuePair);
end;

procedure TDictionary<TKey, TValue>.TrimExcess;
begin
  SetCapacity(fCount);
end;

function TDictionary<TKey, TValue>.TryAdd(const key: TKey;
  const value: TValue): Boolean;
var
  bucketIndex, itemIndex, hashCode: Integer;
begin
  hashCode := Hash(key);
  if Find(key, hashCode, bucketIndex, itemIndex) then
    Exit(False);
  if fItemCount = Capacity then
  begin
    Grow;
    // rehash invalidates the indices
    Find(key, hashCode, bucketIndex, itemIndex);
  end;
  DoAdd(hashCode, bucketIndex, itemIndex, key, value);
  Result := True;
end;

function TDictionary<TKey, TValue>.TryExtract(const key: TKey;
  out value: TValue): Boolean;
var
  bucketIndex, itemIndex: Integer;
begin
  Result := Find(key, Hash(key), bucketIndex, itemIndex);
  if Result then
  begin
    value := fItems[itemIndex].Value;
    DoRemove(bucketIndex, itemIndex, caExtracted);
  end
  else
    value := Default(TValue);
end;

function TDictionary<TKey, TValue>.TryGetElementAt(out item: TKeyValuePair; index: Integer): Boolean;
begin
  Result := InRange(index, 0, fCount - 1);
  if Result then
  begin
    EnsureCompact;
    item.Key := fItems[index].Key;
    item.Value := fItems[index].Value;
  end;
end;

function TDictionary<TKey, TValue>.TryGetValue(const key: TKey;
  out value: TValue): Boolean;
var
  bucketIndex, itemIndex: Integer;
begin
  Result := Find(key, Hash(key), bucketIndex, itemIndex);
  if Result then
    value := fItems[itemIndex].Value
  else
    value := Default(TValue);
end;

function TDictionary<TKey, TValue>.Remove(const key: TKey): Boolean;
var
  bucketIndex, itemIndex: Integer;
begin
  Result := Find(key, Hash(key), bucketIndex, itemIndex);
  if Result then
    DoRemove(bucketIndex, itemIndex, caRemoved);
end;

function TDictionary<TKey, TValue>.Remove(const key: TKey;
  const value: TValue): Boolean;
var
  bucketIndex, itemIndex: Integer;
begin
  Result := Find(key, Hash(key), bucketIndex, itemIndex)
    and fValueComparer.Equals(fItems[itemIndex].Value, value);
  if Result then
    DoRemove(bucketIndex, itemIndex, caRemoved);
end;

function TDictionary<TKey, TValue>.GetKeys: IReadOnlyCollection<TKey>;
begin
  Result := fKeys;
end;

function TDictionary<TKey, TValue>.GetValueOrDefault(const key: TKey): TValue;
begin
  TryGetValue(key, Result);
end;

function TDictionary<TKey, TValue>.GetValueOrDefault(const key: TKey;
  const defaultValue: TValue): TValue;
begin
  if not TryGetValue(key, Result) then
    Result := defaultValue;
end;

function TDictionary<TKey, TValue>.GetValues: IReadOnlyCollection<TValue>;
begin
  Result := fValues;
end;

function TDictionary<TKey, TValue>.GetItem(const key: TKey): TValue;
var
  bucketIndex, itemIndex: Integer;
begin
  if not Find(key, Hash(key), bucketIndex, itemIndex) then
    raise Error.KeyNotFound;
  Result := fItems[itemIndex].Value;
end;

function TDictionary<TKey, TValue>.Ordered: IEnumerable<TKeyValuePair>;
begin
  Result := TOrderedEnumerable.Create(Self);
end;

procedure TDictionary<TKey, TValue>.SetItem(const key: TKey; const value: TValue);
var
  bucketIndex, itemIndex, hashCode: Integer;
begin
  hashCode := Hash(key);
  if Find(key, hashCode, bucketIndex, itemIndex) then
    DoSetValue(itemIndex, value)
  else
  begin
    // add new value
    if fItemCount = Capacity then
    begin
      Grow;
      // rehash invalidates the indices
      Find(key, hashCode, bucketIndex, itemIndex);
    end;
    DoAdd(hashCode, bucketIndex, itemIndex, key, value);
  end;
end;

{$ENDREGION}


{$REGION 'TDictionary<TKey, TValue>.TEnumerator'}

constructor TDictionary<TKey, TValue>.TEnumerator.Create(
  const source: TDictionary<TKey, TValue>);
begin
  inherited Create;
  fSource := source;
  fItemIndex := -1;
  fVersion := fSource.fVersion;
end;

function TDictionary<TKey, TValue>.TEnumerator.GetCurrent: TKeyValuePair;
begin
  Result.Key := fSource.fItems[fItemIndex].Key;
  Result.Value := fSource.fItems[fItemIndex].Value;
end;

function TDictionary<TKey, TValue>.TEnumerator.MoveNext: Boolean;
begin
  Result := fSource.DoMoveNext(fItemIndex, fVersion);
end;

{$ENDREGION}


{$REGION 'TDictionary<TKey, TValue>.TKeyCollection'}

constructor TDictionary<TKey, TValue>.TKeyCollection.Create(
  const source: TDictionary<TKey, TValue>);
begin
  inherited Create(source);
  fSource := source;
end;

function TDictionary<TKey, TValue>.TKeyCollection.Contains(const value: TKey): Boolean;
begin
  Result := fSource.ContainsKey(value);
end;

function TDictionary<TKey, TValue>.TKeyCollection.GetCount: Integer;
begin
  Result := fSource.fCount;
end;

function TDictionary<TKey, TValue>.TKeyCollection.GetEnumerator: IEnumerator<TKey>;
begin
  Result := TKeyEnumerator.Create(fSource);
end;

function TDictionary<TKey, TValue>.TKeyCollection.GetIsEmpty: Boolean;
begin
  Result := fSource.fCount = 0;
end;

function TDictionary<TKey, TValue>.TKeyCollection.ToArray: TArray<TKey>;
var
  sourceIndex, targetIndex: Integer;
begin
  SetLength(Result, fSource.fCount);
  targetIndex := 0;
  for sourceIndex := 0 to fSource.fItemCount - 1 do
    if not fSource.fItems[sourceIndex].Removed then
    begin
      Result[targetIndex] := fSource.fItems[sourceIndex].Key;
      Inc(targetIndex);
    end;
end;

function TDictionary<TKey, TValue>.TKeyCollection.TryGetElementAt(out key: TKey; index: Integer): Boolean;
begin
  Result := InRange(index, 0, fSource.fCount - 1);
  if Result then
  begin
    fSource.EnsureCompact;
    key := fSource.fItems[index].Key;
  end;
end;

{$ENDREGION}


{$REGION 'TDictionary<TKey, TValue>.TKeyEnumerator'}

constructor TDictionary<TKey, TValue>.TKeyEnumerator.Create(
  const source: TDictionary<TKey, TValue>);
begin
  inherited Create;
  fSource := source;
  fSource._AddRef;
  fItemIndex := -1;
  fVersion := fSource.fVersion;
end;

destructor TDictionary<TKey, TValue>.TKeyEnumerator.Destroy;
begin
  fSource._Release;
  inherited Destroy;
end;

function TDictionary<TKey, TValue>.TKeyEnumerator.GetCurrent: TKey;
begin
  Result := fSource.fItems[fItemIndex].Key;
end;

function TDictionary<TKey, TValue>.TKeyEnumerator.MoveNext: Boolean;
begin
  Result := fSource.DoMoveNext(fItemIndex, fVersion);
end;

{$ENDREGION}


{$REGION 'TDictionary<TKey, TValue>.TValueCollection'}

constructor TDictionary<TKey, TValue>.TValueCollection.Create(
  const source: TDictionary<TKey, TValue>);
begin
  inherited Create(source);
  fSource := source;
end;

function TDictionary<TKey, TValue>.TValueCollection.Contains(const value: TValue): Boolean;
begin
  Result := fSource.ContainsValue(value);
end;

function TDictionary<TKey, TValue>.TValueCollection.GetCount: Integer;
begin
  Result := fSource.fCount;
end;

function TDictionary<TKey, TValue>.TValueCollection.GetEnumerator: IEnumerator<TValue>;
begin
  Result := TValueEnumerator.Create(fSource);
end;

function TDictionary<TKey, TValue>.TValueCollection.GetIsEmpty: Boolean;
begin
  Result := fSource.fCount = 0;
end;

function TDictionary<TKey, TValue>.TValueCollection.ToArray: TArray<TValue>;
var
  sourceIndex, targetIndex: Integer;
begin
  SetLength(Result, fSource.fCount);
  targetIndex := 0;
  for sourceIndex := 0 to fSource.fItemCount - 1 do
    if not fSource.fItems[sourceIndex].Removed then
    begin
      Result[targetIndex] := fSource.fItems[sourceIndex].Value;
      Inc(targetIndex);
    end;
end;

function TDictionary<TKey, TValue>.TValueCollection.TryGetElementAt(out value: TValue; index: Integer): Boolean;
begin
  Result := InRange(index, 0, fSource.fCount - 1);
  if Result then
  begin
    fSource.EnsureCompact;
    value := fSource.fItems[index].Value;
  end;
end;

{$ENDREGION}


{$REGION 'TDictionary<TKey, TValue>.TValueEnumerator'}

constructor TDictionary<TKey, TValue>.TValueEnumerator.Create(
  const source: TDictionary<TKey, TValue>);
begin
  inherited Create;
  fSource := source;
  fSource._AddRef;
  fItemIndex := -1;
  fVersion := fSource.fVersion;
end;

destructor TDictionary<TKey, TValue>.TValueEnumerator.Destroy;
begin
  fSource._Release;
  inherited Destroy;
end;

function TDictionary<TKey, TValue>.TValueEnumerator.GetCurrent: TValue;
begin
  Result := fSource.fItems[fItemIndex].Value;
end;

function TDictionary<TKey, TValue>.TValueEnumerator.MoveNext: Boolean;
begin
  Result := fSource.DoMoveNext(fItemIndex, fVersion);
end;

{$ENDREGION}


{$REGION 'TDictionary<TKey, TValue>.TOrderedEnumerable'}

constructor TDictionary<TKey, TValue>.TOrderedEnumerable.Create(
  const source: TDictionary<TKey, TValue>);
begin
  inherited Create;
  fSource := source;
  fSource._AddRef;
end;

destructor TDictionary<TKey, TValue>.TOrderedEnumerable.Destroy;
begin
  fSource._Release;
  inherited Destroy;
end;

procedure TDictionary<TKey, TValue>.TOrderedEnumerable.Dispose;
begin
  fSortedItemIndices := nil;
end;

function TDictionary<TKey, TValue>.TOrderedEnumerable.Clone: TIterator<TKeyValuePair>;
begin
  Result := TOrderedEnumerable.Create(fSource);
end;

function TDictionary<TKey, TValue>.TOrderedEnumerable.GetCount: Integer;
begin
  Result := fSource.fCount;
end;

function TDictionary<TKey, TValue>.TOrderedEnumerable.GetIsEmpty: Boolean;
begin
  Result := fSource.fCount = 0;
end;

procedure TDictionary<TKey, TValue>.TOrderedEnumerable.Start;
var
  sourceIndex, targetIndex: Integer;
  comparer: IComparer<TKey>;
begin
  fIndex := 0;
  fVersion := fSource.fVersion;

  SetLength(fSortedItemIndices, fSource.fCount);
  targetIndex := 0;
  for sourceIndex := 0 to fSource.fItemCount - 1 do
    if not fSource.fItems[sourceIndex].Removed then
    begin
      fSortedItemIndices[targetIndex] := sourceIndex;
      Inc(targetIndex);
    end;

  comparer := TComparer<TKey>.Default;
  TArray.Sort<Integer>(fSortedItemIndices,
    function(const left, right: Integer): Integer
    begin
      Result := comparer.Compare(fSource.fItems[left].Key, fSource.fItems[right].Key);
    end);
end;

function TDictionary<TKey, TValue>.TOrderedEnumerable.TryMoveNext(var current: TKeyValuePair): Boolean;
begin
  if fVersion <> fSource.fVersion then
    raise Error.EnumFailedVersion;

  if fIndex < Length(fSortedItemIndices) then
  begin
    current.Key := fSource.fItems[fSortedItemIndices[fIndex]].Key;
    current.Value := fSource.fItems[fSortedItemIndices[fIndex]].Value;
    Inc(fIndex);
    Exit(True);
  end;
  Result := False;
end;

{$ENDREGION}


{$REGION 'TDictionary<TKey, TValue>.TDictionaryItem'}

function TDictionary<TKey, TValue>.TDictionaryItem.GetValue: TValue;
begin
  Result := fSource.fItems[fItemIndex].Value
end;

procedure TDictionary<TKey, TValue>.TDictionaryItem.Add(const key: TKey; const value: TValue);
begin
{$IFDEF ASSERTIONS_ON}
  Assert(fVersion = fSource.fVersion);
  Assert(fHashCode = fSource.Hash(key));
{$ENDIF}
  if fSource.fItemCount = fSource.Capacity then
  begin
    fSource.Grow;
    // rehash invalidates the indices
    fSource.Find(key, fHashCode, fBucketIndex, fItemIndex);
  end;
  fSource.DoAdd(fHashCode, fBucketIndex, fItemIndex, key, value);
end;

procedure TDictionary<TKey, TValue>.TDictionaryItem.Remove;
begin
{$IFDEF ASSERTIONS_ON}
  Assert(fVersion = fSource.fVersion);
{$ENDIF}
  fSource.DoRemove(fBucketIndex, fItemIndex, caRemoved);
end;

procedure TDictionary<TKey, TValue>.TDictionaryItem.SetValue(const value: TValue);
begin
{$IFDEF ASSERTIONS_ON}
  Assert(fVersion = fSource.fVersion);
{$ENDIF}
  fSource.DoSetValue(fItemIndex, value);
end;

{$ENDREGION}


{$REGION 'TContainedDictionary<TKey, TValue>'}

constructor TContainedDictionary<TKey, TValue>.Create(
  const controller: TRefCountedObject; const keyComparer: IEqualityComparer<TKey>;
  ownerships: TDictionaryOwnerships);
begin
  inherited Create(keyComparer, ownerships);
  fController := controller;
end;

function TContainedDictionary<TKey, TValue>._AddRef: Integer;
begin
  Result := fController._AddRef;
end;

function TContainedDictionary<TKey, TValue>._Release: Integer;
begin
  Result := fController._Release;
end;

{$ENDREGION}


{$REGION 'TBidiDictionaryItem<TKey, TValue>' }

function TBidiDictionaryItem<TKey, TValue>.Removed: Boolean;
begin
  Result := KeyHashCode and RemovedFlag <> 0;
end;

{$ENDREGION}


{$REGION 'TBidiDictionary<TKey, TValue>'}

constructor TBidiDictionary<TKey, TValue>.Create;
begin
  Create(0, nil, nil);
end;

constructor TBidiDictionary<TKey, TValue>.Create(ownerships: TDictionaryOwnerships);
begin
  Create(0, nil, nil, ownerships);
end;

constructor TBidiDictionary<TKey, TValue>.Create(capacity: Integer;
  ownerships: TDictionaryOwnerships);
begin
  Create(capacity, nil, nil, ownerships);
end;

constructor TBidiDictionary<TKey, TValue>.Create(
  const keyComparer: IEqualityComparer<TKey>;
  ownerships: TDictionaryOwnerships);
begin
  Create(0, keyComparer, nil, ownerships);
end;

constructor TBidiDictionary<TKey, TValue>.Create(
  const keyComparer: IEqualityComparer<TKey>;
  const valueComparer: IEqualityComparer<TValue>;
  ownerships: TDictionaryOwnerships);
begin
  Create(0, keyComparer, valueComparer, ownerships);
end;

constructor TBidiDictionary<TKey, TValue>.Create(capacity: Integer;
  const keyComparer: IEqualityComparer<TKey>;
  ownerships: TDictionaryOwnerships);
begin
  Create(capacity, keyComparer, nil, ownerships);
end;

constructor TBidiDictionary<TKey, TValue>.Create(capacity: Integer;
  const keyComparer: IEqualityComparer<TKey>;
  const valueComparer: IEqualityComparer<TValue>;
  ownerships: TDictionaryOwnerships);
begin
{$IFDEF SPRING_ENABLE_GUARD}
  Guard.CheckRange(capacity >= 0, 'capacity');
{$ENDIF}

  if doOwnsKeys in ownerships then
    if TType.Kind<TKey> <> tkClass then
      raise Error.NoClassType(KeyType);

  if doOwnsValues in ownerships then
    if TType.Kind<TValue> <> tkClass then
      raise Error.NoClassType(ValueType);

  inherited Create;
  fOwnerships := ownerships;
  fKeys := TKeyCollection.Create(Self);
  fValues := TValueCollection.Create(Self);
  if Assigned(keyComparer) then
    fKeyComparer := keyComparer
  else
    fKeyComparer := TEqualityComparer<TKey>.Default;
  if Assigned(valueComparer) then
    fValueComparer := valueComparer
  else
    fValueComparer := TEqualityComparer<TValue>.Default;
  fInverse := TInverse.Create(Self);
  SetCapacity(capacity);
end;

destructor TBidiDictionary<TKey, TValue>.Destroy;
begin
  Clear;
  fInverse.Free;
  fKeys.Free;
  fValues.Free;
  inherited Destroy;
end;

procedure TBidiDictionary<TKey, TValue>.Changed(const item: TPair<TKey, TValue>;
  action: TCollectionChangedAction);
var
  inverseItem: TValueKeyPair;
begin
  inherited Changed(item, action);
  inverseItem.Key := item.Value;
  inverseItem.Value := item.Key;
  fInverse.Changed(inverseItem, action);
end;

procedure TBidiDictionary<TKey, TValue>.KeyChanged(const item: TKey;
  action: TCollectionChangedAction);
begin
  if fOnKeyChanged.CanInvoke then
    fOnKeyChanged.Invoke(Self, item, action);
{$IFDEF DELPHIXE7_UP}
  if GetTypeKind(TKey) = tkClass then
{$ENDIF}
  if (action = caRemoved) and (doOwnsKeys in fOwnerships) then
    FreeObject(item);
end;

procedure TBidiDictionary<TKey, TValue>.ValueChanged(const item: TValue;
  action: TCollectionChangedAction);
begin
  if fOnValueChanged.CanInvoke then
    fOnValueChanged.Invoke(Self, item, action);
{$IFDEF DELPHIXE7_UP}
  if GetTypeKind(TValue) = tkClass then
{$ENDIF}
  if (action = caRemoved) and (doOwnsValues in fOwnerships) then
    FreeObject(item);
end;

function TBidiDictionary<TKey, TValue>.GetCapacity: Integer;
begin
  Result := DynArrayLength(fItems);
end;

procedure TBidiDictionary<TKey, TValue>.SetCapacity(value: Integer);
var
  newCapacity: Integer;
begin
  if value = 0 then
    newCapacity := 0
  else
    newCapacity := Math.Max(MinCapacity, value);
  if newCapacity <> Capacity then
    Rehash(newCapacity);
end;

procedure TBidiDictionary<TKey, TValue>.Rehash(newCapacity: Integer);
var
  newBucketCount: Integer;
  bucketIndex, itemIndex: Integer;
  sourceItemIndex, targetItemIndex: Integer;
begin
  if newCapacity = 0 then
  begin
    Assert(fCount = 0);
    Assert(fItemCount = 0);
    Assert(not Assigned(fKeyBuckets));
    Assert(not Assigned(fValueBuckets));
    Assert(not Assigned(fItems));
    Exit;
  end;

  Assert(newCapacity >= fCount);

  IncUnchecked(fVersion);

  newBucketCount := NextPowerOf2(newCapacity * 4 div 3 - 1); // 75% load factor

  // compact the items array, if necessary
  if fItemCount > fCount then
  begin
    targetItemIndex := 0;
    for sourceItemIndex := 0 to fItemCount - 1 do
      if not fItems[sourceItemIndex].Removed then
      begin
        if targetItemIndex < sourceItemIndex then
          TArrayManager<TItem>.Move(fItems, sourceItemIndex, targetItemIndex, 1);
        Inc(targetItemIndex);
      end;
    TArrayManager<TItem>.Finalize(fItems, targetItemIndex, fItemCount - fCount);
  end;

  // resize the items array, safe now that we have compacted it
  SetLength(fItems, newBucketCount * 3 div 4);
  Assert(Capacity >= fCount);

  // repopulate the bucket array
  Assert(IsPowerOf2(newBucketCount));
  fBucketIndexMask := newBucketCount - 1;
  fBucketHashCodeMask := not fBucketIndexMask and not BucketSentinelFlag;
  SetLength(fKeyBuckets, newBucketCount);
  for bucketIndex := 0 to newBucketCount - 1 do
    fKeyBuckets[bucketIndex] := EmptyBucket;
  SetLength(fValueBuckets, newBucketCount);
  for bucketIndex := 0 to newBucketCount - 1 do
    fValueBuckets[bucketIndex] := EmptyBucket;
  fItemCount := 0;
  while fItemCount < fCount do
  begin
    FindKey(fItems[fItemCount].Key, fItems[fItemCount].KeyHashCode, bucketIndex, itemIndex);
    Assert(itemIndex = fItemCount);
    fKeyBuckets[bucketIndex] := itemIndex or (fItems[itemIndex].KeyHashCode and fBucketHashCodeMask);

    FindValue(fItems[fItemCount].Value, fItems[fItemCount].ValueHashCode, bucketIndex, itemIndex);
    Assert(itemIndex = fItemCount);
    fValueBuckets[bucketIndex] := itemIndex or (fItems[itemIndex].ValueHashCode and fBucketHashCodeMask);

    Inc(fItemCount);
  end;
end;

procedure TBidiDictionary<TKey, TValue>.Grow;
var
  newCapacity: Integer;
begin
  newCapacity := Capacity;
  if newCapacity = 0 then
    newCapacity := MinCapacity
  else if 2 * fCount >= Length(fKeyBuckets) then
    // only grow if load factor is greater than 0.5
    newCapacity := newCapacity * 2;
  Rehash(newCapacity);
end;

function TBidiDictionary<TKey, TValue>.FindKey(const key: TKey; hashCode: Integer;
  out bucketIndex, itemIndex: Integer): Boolean;
var
  bucketValue: Integer;
begin
  if fItems = nil then
  begin
    bucketIndex := EmptyBucket;
    itemIndex := -1;
    Exit(False);
  end;

  bucketIndex := hashCode and fBucketIndexMask;
  while True do
  begin
    bucketValue := fKeyBuckets[bucketIndex];

    if bucketValue = EmptyBucket then
    begin
      itemIndex := fItemCount;
      Exit(False);
    end;

    if (bucketValue <> UsedBucket)
      and (bucketValue and fBucketHashCodeMask = hashCode and fBucketHashCodeMask) then
    begin
      itemIndex := bucketValue and fBucketIndexMask;
      if fKeyComparer.Equals(fItems[itemIndex].Key, key) then
        Exit(True);
    end;

    bucketIndex := (bucketIndex + 1) and fBucketIndexMask;
  end;
end;

function TBidiDictionary<TKey, TValue>.FindValue(const value: TValue; hashCode: Integer;
  out bucketIndex, itemIndex: Integer): Boolean;
var
  bucketValue: Integer;
begin
  if fItems = nil then
  begin
    bucketIndex := EmptyBucket;
    itemIndex := -1;
    Exit(False);
  end;

  bucketIndex := hashCode and fBucketIndexMask;
  while True do
  begin
    bucketValue := fValueBuckets[bucketIndex];

    if bucketValue = EmptyBucket then
    begin
      itemIndex := fItemCount;
      Exit(False);
    end;

    if (bucketValue <> UsedBucket)
      and (bucketValue and fBucketHashCodeMask = hashCode and fBucketHashCodeMask) then
    begin
      itemIndex := bucketValue and fBucketIndexMask;
      if fValueComparer.Equals(fItems[itemIndex].Value, value) then
        Exit(True);
    end;

    bucketIndex := (bucketIndex + 1) and fBucketIndexMask;
  end;
end;

function TBidiDictionary<TKey, TValue>.KeyHash(const key: TKey): Integer;
begin
  Result := fKeyComparer.GetHashCode(key) and not RemovedFlag;
end;

function TBidiDictionary<TKey, TValue>.ValueHash(const value: TValue): Integer;
begin
  Result := fValueComparer.GetHashCode(value) and not RemovedFlag;
end;

procedure TBidiDictionary<TKey, TValue>.DoAdd(keyhashCode, keyBucketIndex, valueHashCode,
  valueBucketIndex, itemIndex: Integer; const key: TKey; const value: TValue);
begin
  IncUnchecked(fVersion);
  fKeyBuckets[keyBucketIndex] := itemIndex or (keyHashCode and fBucketHashCodeMask);
  fValueBuckets[valueBucketIndex] := itemIndex or (valueHashCode and fBucketHashCodeMask);
  fItems[itemIndex].KeyHashCode := keyHashCode;
  fItems[itemIndex].ValueHashCode := valueHashCode;
  fItems[itemIndex].Key := key;
  fItems[itemIndex].Value := value;
  Inc(fCount);
  Inc(fItemCount);

  if Assigned(Notify) then
    DoNotify(key, value, caAdded);
  KeyChanged(key, caAdded);
  ValueChanged(value, caAdded);
end;

procedure TBidiDictionary<TKey, TValue>.DoRemove(keyBucketIndex, valueBucketIndex,
  itemIndex: Integer; action: TCollectionChangedAction);
var
  oldKey: TKey;
  oldValue: TValue;
begin
  oldKey := fItems[itemIndex].Key;
  oldValue := fItems[itemIndex].Value;

  IncUnchecked(fVersion);
  fKeyBuckets[keyBucketIndex] := UsedBucket;
  fValueBuckets[valueBucketIndex] := UsedBucket;
  fItems[itemIndex].Key := Default(TKey);
  fItems[itemIndex].Value := Default(TValue);
  fItems[itemIndex].KeyHashCode := RemovedFlag;
  fItems[itemIndex].ValueHashCode := RemovedFlag;
  Dec(fCount);

  if Assigned(Notify) then
    DoNotify(oldKey, oldValue, action);
  KeyChanged(oldKey, action);
  ValueChanged(oldValue, action);
end;

procedure TBidiDictionary<TKey, TValue>.DoSetKey(valueBucketIndex, itemIndex,
  keyHashCode: Integer; const key: TKey);
var
  oldKey: TKey;
  oldValue: TValue;
  oldKeyHashCode, valueHashCode, oldKeyBucketIndex, oldKeyItemIndex, keyBucketIndex: Integer;
begin
  oldKey := fItems[itemIndex].Key;
  oldValue := fItems[itemIndex].Value;
  oldKeyHashCode := fItems[itemIndex].KeyHashCode;
  valueHashCode := fItems[itemIndex].ValueHashCode;

  IncUnchecked(fVersion);
  if fItemCount = Capacity then
  begin
    Grow;
    FindValue(oldValue, valueHashCode, valueBucketIndex, itemIndex);
  end;
  FindKey(oldKey, oldKeyHashCode, oldKeyBucketIndex, oldKeyItemIndex);
  Assert(oldKeyItemIndex = itemIndex);
  fValueBuckets[oldKeyBucketIndex] := UsedBucket;
  FindKey(key, keyHashCode, keyBucketIndex, itemIndex);
  Assert(itemIndex = fItemCount);

  fKeyBuckets[keyBucketIndex] := oldKeyItemIndex or (keyHashCode and fBucketHashCodeMask);
  fValueBuckets[valueBucketIndex] := oldKeyItemIndex or (valueHashCode and fBucketHashCodeMask);

  fItems[itemIndex].Key := Default(TKey);
  fItems[itemIndex].Value := Default(TValue);
  fItems[itemIndex].KeyHashCode := RemovedFlag;
  fItems[itemIndex].ValueHashCode := RemovedFlag;

  fItems[oldKeyItemIndex].KeyHashCode := keyHashCode;
  Assert(fItems[oldKeyItemIndex].ValueHashCode = valueHashCode);
  fItems[oldKeyItemIndex].Key := key;
  Assert(fValueComparer.Equals(fItems[oldKeyItemIndex].Value, oldValue));

  Inc(fItemCount);

  if Assigned(Notify) then
    DoNotify(oldKey, oldValue, caRemoved);
  KeyChanged(oldKey, caRemoved);
  if Assigned(Notify) then
    DoNotify(key, oldValue, caAdded);
  KeyChanged(key, caAdded);
end;

procedure TBidiDictionary<TKey, TValue>.DoSetValue(keyBucketIndex, itemIndex,
  valueHashCode: Integer; const value: TValue);
var
  oldKey: TKey;
  oldValue: TValue;
  keyHashCode, oldValueHashCode, oldValueBucketIndex, oldValueItemIndex, valueBucketIndex: Integer;
begin
  oldKey := fItems[itemIndex].Key;
  oldValue := fItems[itemIndex].Value;
  keyHashCode := fItems[itemIndex].KeyHashCode;
  oldValueHashCode := fItems[itemIndex].ValueHashCode;

  IncUnchecked(fVersion);
  if fItemCount = Capacity then
  begin
    Grow;
    FindKey(oldKey, keyHashCode, keyBucketIndex, itemIndex);
  end;
  FindValue(oldValue, oldValueHashCode, oldValueBucketIndex, oldValueItemIndex);
  Assert(oldValueItemIndex = itemIndex);
  fValueBuckets[oldValueBucketIndex] := UsedBucket;
  FindValue(value, valueHashCode, valueBucketIndex, itemIndex);
  Assert(itemIndex = fItemCount);

  fKeyBuckets[keyBucketIndex] := oldValueItemIndex or (keyHashCode and fBucketHashCodeMask);
  fValueBuckets[valueBucketIndex] := oldValueItemIndex or (valueHashCode and fBucketHashCodeMask);

  fItems[itemIndex].Key := Default(TKey);
  fItems[itemIndex].Value := Default(TValue);
  fItems[itemIndex].KeyHashCode := RemovedFlag;
  fItems[itemIndex].ValueHashCode := RemovedFlag;

  Assert(fItems[oldValueItemIndex].KeyHashCode = keyHashCode);
  fItems[oldValueItemIndex].ValueHashCode := valueHashCode;
  Assert(fKeyComparer.Equals(fItems[oldValueItemIndex].Key, oldKey));
  fItems[oldValueItemIndex].Value := value;

  Inc(fItemCount);

  if Assigned(Notify) then
    DoNotify(oldKey, oldValue, caRemoved);
  ValueChanged(oldValue, caRemoved);
  if Assigned(Notify) then
    DoNotify(oldKey, value, caAdded);
  ValueChanged(value, caAdded);
end;

function TBidiDictionary<TKey, TValue>.DoMoveNext(var itemIndex: Integer;
  iteratorVersion: Integer): Boolean;
begin
  if iteratorVersion <> fVersion then
    raise Error.EnumFailedVersion;

  while itemIndex < fItemCount - 1 do
  begin
    Inc(itemIndex);
    if not fItems[itemIndex].Removed then
      Exit(True);
  end;
  Result := False;
end;

function TBidiDictionary<TKey, TValue>.GetEnumerator: IEnumerator<TKeyValuePair>;
begin
  Result := TEnumerator.Create(self);
end;

procedure TBidiDictionary<TKey, TValue>.Clear;
var
  oldItemIndex, oldItemCount: Integer;
  oldItems: TArray<TItem>;
begin
  oldItemCount := fItemCount;
  oldItems := fItems;

  IncUnchecked(fVersion);
  fCount := 0;
  fItemCount := 0;
  fKeyBuckets := nil;
  fValueBuckets := nil;
  fItems := nil;
  SetCapacity(0);

  for oldItemIndex := 0 to oldItemCount - 1 do
    if not oldItems[oldItemIndex].Removed then
    begin
      if Assigned(Notify) then
        DoNotify(oldItems[oldItemIndex].Key, oldItems[oldItemIndex].Value, caRemoved);
      KeyChanged(oldItems[oldItemIndex].Key, caRemoved);
      ValueChanged(oldItems[oldItemIndex].Value, caRemoved);
    end;
end;

function TBidiDictionary<TKey, TValue>.Contains(const value: TKeyValuePair;
  const comparer: IEqualityComparer<TKeyValuePair>): Boolean;
var
  pair: TKeyValuePair;
begin
  pair.Key := value.Key;
  Result := TryGetValue(value.Key, pair.Value) and comparer.Equals(pair, value);
end;

function TBidiDictionary<TKey, TValue>.ToArray: TArray<TKeyValuePair>;
var
  sourceIndex, targetIndex: Integer;
begin
  SetLength(Result, fCount);
  targetIndex := 0;
  for sourceIndex := 0 to fItemCount - 1 do
    if not fItems[sourceIndex].Removed then
    begin
      Result[targetIndex].Key := fItems[sourceIndex].Key;
      Result[targetIndex].Value := fItems[sourceIndex].Value;
      Inc(targetIndex);
    end;
end;

function TBidiDictionary<TKey, TValue>.GetCount: Integer;
begin
  Result := fCount;
end;

procedure TBidiDictionary<TKey, TValue>.AddOrSetKey(const value: TValue; const key: TKey);
var
  keyHashCode, keyBucketIndex, valueHashCode, valueBucketIndex, keyItemIndex, valueItemIndex: Integer;
  keyFound, valueFound: Boolean;
begin
  valueHashCode := ValueHash(value);
  valueFound := FindValue(value, valueHashCode, valueBucketIndex, valueItemIndex);
  keyHashCode := KeyHash(key);
  keyFound := FindKey(key, keyHashCode, keyBucketIndex, keyItemIndex);

  if keyFound then
  begin
    if valueFound and (keyItemIndex = valueItemIndex) then
      Exit; // this key/value pair are already mapped to each other
    raise Error.DuplicateKey;
  end
  else if valueFound then
    // value found, but key not found, this is a replace value operation
    DoSetKey(valueBucketIndex, valueItemIndex, keyHashCode, key)
  else
  begin
    // neither value nor key found, this is an add operation
    if fItemCount = Capacity then
    begin
      Grow;
      // rehash invalidates the indices
      FindKey(key, keyHashCode, keyBucketIndex, keyItemIndex);
      FindValue(value, valueHashCode, valueBucketIndex, valueItemIndex);
    end;
    Assert(keyItemIndex = valueItemIndex);
    DoAdd(keyhashCode, keyBucketIndex, valueHashCode, valueBucketIndex, keyItemIndex, key, value);
  end;
end;

function TBidiDictionary<TKey, TValue>.AsReadOnly: IReadOnlyDictionary<TKey, TValue>;
begin
  Result := Self;
end;

function TBidiDictionary<TKey, TValue>.Contains(const key: TKey;
  const value: TValue): Boolean;
var
  item: TValue;
begin
  Result := TryGetValue(key, item) and fValueComparer.Equals(item, value);
end;

function TBidiDictionary<TKey, TValue>.ContainsKey(const key: TKey): Boolean;
var
  bucketIndex, itemIndex: Integer;
begin
  Result := FindKey(key, KeyHash(key), bucketIndex, itemIndex);
end;

function TBidiDictionary<TKey, TValue>.ContainsValue(
  const value: TValue): Boolean;
var
  bucketIndex, itemIndex: Integer;
begin
  Result := FindValue(value, ValueHash(value), bucketIndex, itemIndex);
end;

procedure TBidiDictionary<TKey, TValue>.EnsureCompact;
begin
  if fCount <> fItemCount then
    Rehash(Capacity);
end;

function TBidiDictionary<TKey, TValue>.Extract(const key: TKey): TValue;
begin
  TryExtract(key, Result);
end;

function TBidiDictionary<TKey, TValue>.Extract(const key: TKey;
  const value: TValue): TKeyValuePair;
var
  keyBucketIndex, keyItemIndex, valueBucketIndex, valueItemIndex: Integer;
  foundItem: PItem;
begin
  if FindKey(key, KeyHash(key), keyBucketIndex, keyItemIndex)
    and FindValue(value, ValueHash(value), valueBucketIndex, valueItemIndex)
    and (keyItemIndex = valueItemIndex) then
  begin
    foundItem := @fItems[keyItemIndex];
    Result.Key := foundItem.Key;
    Result.Value := foundItem.Value;
    DoRemove(keyBucketIndex, valueBucketIndex, keyItemIndex, caExtracted);
    Exit;
  end;

  Result := Default(TKeyValuePair);
end;

procedure TBidiDictionary<TKey, TValue>.TrimExcess;
begin
  SetCapacity(fCount);
end;

function TBidiDictionary<TKey, TValue>.TryAdd(const key: TKey;
  const value: TValue): Boolean;
var
  keyHashCode, keyBucketIndex, valueHashCode, valueBucketIndex, keyItemIndex, valueItemIndex: Integer;
begin
  keyHashCode := KeyHash(key);
  if FindKey(key, keyHashCode, keyBucketIndex, keyItemIndex) then
    Exit(False);
  valueHashCode := ValueHash(value);
  if FindValue(value, valueHashCode, valueBucketIndex, valueItemIndex) then
    Exit(False);
  if fItemCount = Capacity then
  begin
    Grow;
    // rehash invalidates the indices
    FindKey(key, keyHashCode, keyBucketIndex, keyItemIndex);
    FindValue(value, valueHashCode, valueBucketIndex, valueItemIndex);
  end;
  Assert(keyItemIndex = valueItemIndex);
  DoAdd(keyhashCode, keyBucketIndex, valueHashCode, valueBucketIndex, keyItemIndex, key, value);
  Result := True;
end;

function TBidiDictionary<TKey, TValue>.TryExtract(const key: TKey;
  out value: TValue): Boolean;
var
  keyBucketIndex, keyItemIndex, valueBucketIndex, valueItemIndex: Integer;
begin
  Result := FindKey(key, KeyHash(key), keyBucketIndex, keyItemIndex);
  if Result then
  begin
    value := fItems[keyItemIndex].Value;
    FindValue(value, fItems[keyItemIndex].ValueHashCode, valueBucketIndex, valueItemIndex);
    Assert(keyItemIndex = valueItemIndex);
    DoRemove(keyBucketIndex, valueBucketIndex, keyItemIndex, caExtracted);
  end
  else
    value := Default(TValue);
end;

function TBidiDictionary<TKey, TValue>.TryGetValue(const key: TKey;
  out value: TValue): Boolean;
var
  bucketIndex, itemIndex: Integer;
begin
  Result := FindKey(key, KeyHash(key), bucketIndex, itemIndex);
  if Result then
    value := fItems[itemIndex].Value
  else
    value := Default(TValue);
end;

function TBidiDictionary<TKey, TValue>.Remove(const key: TKey): Boolean;
var
  keyBucketIndex, keyItemIndex, valueBucketIndex, valueItemIndex: Integer;
begin
  Result := FindKey(key, KeyHash(key), keyBucketIndex, keyItemIndex);
  if Result then
  begin
    FindValue(fItems[keyItemIndex].Value, fItems[keyItemIndex].ValueHashCode, valueBucketIndex, valueItemIndex);
    Assert(keyItemIndex = valueItemIndex);
    DoRemove(keyBucketIndex, valueBucketIndex, keyItemIndex, caRemoved);
  end;
end;

function TBidiDictionary<TKey, TValue>.Remove(const key: TKey;
  const value: TValue): Boolean;
var
  keyBucketIndex, keyItemIndex, valueBucketIndex, valueItemIndex: Integer;
begin
  Result := FindKey(key, KeyHash(key), keyBucketIndex, keyItemIndex)
    and fValueComparer.Equals(fItems[keyItemIndex].Value, value);
  if Result then
  begin
    FindValue(value, fItems[keyItemIndex].ValueHashCode, valueBucketIndex, valueItemIndex);
    Assert(keyItemIndex = valueItemIndex);
    DoRemove(keyBucketIndex, valueBucketIndex, keyItemIndex, caRemoved);
  end;
end;

function TBidiDictionary<TKey, TValue>.GetInverse: IBidiDictionary<TValue, TKey>;
begin
  Result := fInverse;
end;

function TBidiDictionary<TKey, TValue>.GetIsEmpty: Boolean;
begin
  Result := fCount = 0;
end;

function TBidiDictionary<TKey, TValue>.GetKeys: IReadOnlyCollection<TKey>;
begin
  Result := fKeys;
end;

function TBidiDictionary<TKey, TValue>.GetValueOrDefault(const key: TKey): TValue;
begin
  TryGetValue(key, Result);
end;

function TBidiDictionary<TKey, TValue>.GetValueOrDefault(const key: TKey;
  const defaultValue: TValue): TValue;
begin
  if not TryGetValue(key, Result) then
    Result := defaultValue;
end;

function TBidiDictionary<TKey, TValue>.GetValues: IReadOnlyCollection<TValue>;
begin
  Result := fValues;
end;

function TBidiDictionary<TKey, TValue>.GetItem(const key: TKey): TValue;
var
  keyBucketIndex, keyItemIndex: Integer;
begin
  if not FindKey(key, KeyHash(key), keyBucketIndex, keyItemIndex) then
    raise Error.KeyNotFound;
  Result := fItems[keyItemIndex].Value;
end;

function TBidiDictionary<TKey, TValue>.Ordered: IEnumerable<TKeyValuePair>;
begin
  Result := TOrderedEnumerable.Create(Self);
end;

procedure TBidiDictionary<TKey, TValue>.SetItem(const key: TKey; const value: TValue);
var
  keyHashCode, keyBucketIndex, valueHashCode, valueBucketIndex, keyItemIndex, valueItemIndex: Integer;
  keyFound, valueFound: Boolean;
begin
  keyHashCode := KeyHash(key);
  keyFound := FindKey(key, keyHashCode, keyBucketIndex, keyItemIndex);
  valueHashCode := ValueHash(value);
  valueFound := FindValue(value, valueHashCode, valueBucketIndex, valueItemIndex);

  if valueFound then
  begin
    if keyFound and (keyItemIndex = valueItemIndex) then
      Exit; // this key/value pair are already mapped to each other
    raise Error.DuplicateKey;
  end
  else if keyFound then
    // key found, but value not found, this is a replace value operation
    DoSetValue(keyBucketIndex, keyItemIndex, valueHashCode, value)
  else
  begin
    // neither key nor value found, this is an add operation
    if fItemCount = Capacity then
    begin
      Grow;
      // rehash invalidates the indices
      FindKey(key, keyHashCode, keyBucketIndex, keyItemIndex);
      FindValue(value, valueHashCode, valueBucketIndex, valueItemIndex);
    end;
    Assert(keyItemIndex = valueItemIndex);
    DoAdd(keyhashCode, keyBucketIndex, valueHashCode, valueBucketIndex, keyItemIndex, key, value);
  end;
end;

{$ENDREGION}


{$REGION 'TBidiDictionary<TKey, TValue>.TInverse'}

constructor TBidiDictionary<TKey, TValue>.TInverse.Create(
  const source: TBidiDictionary<TKey, TValue>);
begin
  inherited Create(source);
  fSource := source;
end;

procedure TBidiDictionary<TKey, TValue>.TInverse.Add(const value: TValue;
  const key: TKey);
begin
  fSource.Add(key, value);
end;

function TBidiDictionary<TKey, TValue>.TInverse.Add(const item: TValueKeyPair): Boolean;
begin
  Result := fSource.TryAdd(item.Value, item.Key);
end;

function TBidiDictionary<TKey, TValue>.TInverse.AsReadOnly: IReadOnlyDictionary<TValue, TKey>;
begin
  Result := Self;
end;

procedure TBidiDictionary<TKey, TValue>.TInverse.Changed(const item: TValueKeyPair; action: TCollectionChangedAction);
begin
  if Assigned(OnChanged) and OnChanged.CanInvoke then
    OnChanged.Invoke(fSource, item, action);
end;

procedure TBidiDictionary<TKey, TValue>.TInverse.Clear;
begin
  fSource.Clear;
end;

function TBidiDictionary<TKey, TValue>.TInverse.Contains(const value: TValue;
  const key: TKey): Boolean;
begin
  Result := fSource.Contains(key, value);
end;

function TBidiDictionary<TKey, TValue>.TInverse.Contains(
  const value: TValueKeyPair): Boolean;
begin
  Result := fSource.Contains(value.Value, value.Key);
end;

function TBidiDictionary<TKey, TValue>.TInverse.Contains(
  const value: TValueKeyPair;
  const comparer: IEqualityComparer<TValueKeyPair>): Boolean;
var
  pair: TValueKeyPair;
begin
  pair.Key := value.Key;
  Result := TryGetValue(value.Key, pair.Value) and comparer.Equals(pair, value);
end;

function TBidiDictionary<TKey, TValue>.TInverse.ContainsKey(
  const value: TValue): Boolean;
begin
  Result := fSource.ContainsValue(value);
end;

function TBidiDictionary<TKey, TValue>.TInverse.ContainsValue(
  const key: TKey): Boolean;
begin
  Result := fSource.ContainsKey(key);
end;

function TBidiDictionary<TKey, TValue>.TInverse.Extract(
  const item: TValueKeyPair): TValueKeyPair;
begin
  Result := Extract(item.Key, item.Value);
end;

function TBidiDictionary<TKey, TValue>.TInverse.Extract(
  const value: TValue): TKey;
begin
  TryExtract(value, Result);
end;

function TBidiDictionary<TKey, TValue>.TInverse.Extract(const value: TValue;
  const key: TKey): TValueKeyPair;
var
  pair: TKeyValuePair;
begin
  pair := fSource.Extract(key, value);
  Result.Key := pair.Value;
  Result.Value := pair.Key;
end;

function TBidiDictionary<TKey, TValue>.TInverse.GetCapacity: Integer;
begin
  Result := fSource.Capacity;
end;

function TBidiDictionary<TKey, TValue>.TInverse.GetCount: Integer;
begin
  Result := fSource.fCount;
end;

function TBidiDictionary<TKey, TValue>.TInverse.GetEnumerator: IEnumerator<TValueKeyPair>;
begin
  Result := TEnumerator.Create(fSource);
end;

function TBidiDictionary<TKey, TValue>.TInverse.GetInverse: IBidiDictionary<TKey, TValue>;
begin
  Result := fSource;
end;

function TBidiDictionary<TKey, TValue>.TInverse.GetIsEmpty: Boolean;
begin
  Result := fSource.fCount = 0;
end;

function TBidiDictionary<TKey, TValue>.TInverse.GetItem(
  const value: TValue): TKey;
var
  valueBucketIndex, valueItemIndex: Integer;
begin
  if not fSource.FindValue(value, fSource.ValueHash(value), valueBucketIndex, valueItemIndex) then
    raise Error.KeyNotFound;
  Result := fSource.fItems[valueItemIndex].Key;
end;

function TBidiDictionary<TKey, TValue>.TInverse.GetKeys: IReadOnlyCollection<TValue>;
begin
  Result := fSource.fValues;
end;

function TBidiDictionary<TKey, TValue>.TInverse.GetKeyType: PTypeInfo;
begin
  Result := fSource.ValueType;
end;

function TBidiDictionary<TKey, TValue>.TInverse.GetOnKeyChanged: ICollectionChangedEvent<TValue>;
begin
  Result := fSource.fOnValueChanged;
end;

function TBidiDictionary<TKey, TValue>.TInverse.GetOnValueChanged: ICollectionChangedEvent<TKey>;
begin
  Result := fSource.fOnKeyChanged;
end;

function TBidiDictionary<TKey, TValue>.TInverse.GetValueOrDefault(
  const value: TValue): TKey;
begin
  TryGetValue(value, Result);
end;

function TBidiDictionary<TKey, TValue>.TInverse.GetValueOrDefault(
  const value: TValue; const defaultKey: TKey): TKey;
begin
  if not TryGetValue(value, Result) then
    Result := defaultKey;
end;

function TBidiDictionary<TKey, TValue>.TInverse.GetValues: IReadOnlyCollection<TKey>;
begin
  Result := fSource.fKeys;
end;

function TBidiDictionary<TKey, TValue>.TInverse.GetValueType: PTypeInfo;
begin
  Result := fSource.KeyType;
end;

function TBidiDictionary<TKey, TValue>.TInverse.Ordered: IEnumerable<TValueKeyPair>;
begin
  Result := TOrderedEnumerable.Create(fSource);
end;

function TBidiDictionary<TKey, TValue>.TInverse.Remove(
  const value: TValue): Boolean;
var
  keyBucketIndex, keyItemIndex, valueBucketIndex, valueItemIndex: Integer;
begin
  Result := fSource.FindValue(value, fSource.ValueHash(value), valueBucketIndex, valueItemIndex);
  if Result then
  begin
    fSource.FindKey(fSource.fItems[valueItemIndex].Key,
      fSource.fItems[valueItemIndex].KeyHashCode, keyBucketIndex, keyItemIndex);
    Assert(keyItemIndex = valueItemIndex);
    fSource.DoRemove(keyBucketIndex, valueBucketIndex, keyItemIndex, caRemoved);
  end;
end;

function TBidiDictionary<TKey, TValue>.TInverse.Remove(const value: TValue;
  const key: TKey): Boolean;
var
  keyBucketIndex, keyItemIndex, valueBucketIndex, valueItemIndex: Integer;
begin
  Result := fSource.FindValue(value, fSource.ValueHash(value), valueBucketIndex, valueItemIndex)
    and fSource.fKeyComparer.Equals(fSource.fItems[valueItemIndex].Key, key);
  if Result then
  begin
    fSource.FindKey(key, fSource.fItems[valueItemIndex].KeyHashCode, keyBucketIndex, keyItemIndex);
    Assert(keyItemIndex = valueItemIndex);
    fSource.DoRemove(keyBucketIndex, valueBucketIndex, keyItemIndex, caRemoved);
  end;
end;

function TBidiDictionary<TKey, TValue>.TInverse.Remove(
  const item: TValueKeyPair): Boolean;
begin
  Result := Remove(item.Key, item.Value);
end;

procedure TBidiDictionary<TKey, TValue>.TInverse.SetCapacity(value: Integer);
begin
  fSource.SetCapacity(value);
end;

procedure TBidiDictionary<TKey, TValue>.TInverse.SetItem(const value: TValue;
  const key: TKey);
begin
  fSource.AddOrSetKey(value, key);
end;

function TBidiDictionary<TKey, TValue>.TInverse.ToArray: TArray<TValueKeyPair>;
var
  sourceIndex, targetIndex: Integer;
begin
  SetLength(Result, fSource.fCount);
  targetIndex := 0;
  for sourceIndex := 0 to fSource.fItemCount - 1 do
    if not fSource.fItems[sourceIndex].Removed then
    begin
      Result[targetIndex].Key := fSource.fItems[sourceIndex].Value;
      Result[targetIndex].Value := fSource.fItems[sourceIndex].Key;
      Inc(targetIndex);
    end;
end;

procedure TBidiDictionary<TKey, TValue>.TInverse.TrimExcess;
begin
  fSource.TrimExcess;
end;

function TBidiDictionary<TKey, TValue>.TInverse.TryAdd(const value: TValue;
  const key: TKey): Boolean;
begin
  Result := fSource.TryAdd(key, value);
end;

function TBidiDictionary<TKey, TValue>.TInverse.TryExtract(const value: TValue;
  out key: TKey): Boolean;
var
  keyBucketIndex, keyItemIndex, valueBucketIndex, valueItemIndex: Integer;
begin
  Result := fSource.FindValue(value, fSource.ValueHash(value), valueBucketIndex, valueItemIndex);
  if Result then
  begin
    key := fSource.fItems[valueItemIndex].Key;
    fSource.FindKey(key, fSource.fItems[valueItemIndex].KeyHashCode, keyBucketIndex, keyItemIndex);
    Assert(keyItemIndex = valueItemIndex);
    fSource.DoRemove(keyBucketIndex, valueBucketIndex, keyItemIndex, caExtracted);
  end
  else
    key := Default(TKey);
end;

function TBidiDictionary<TKey, TValue>.TInverse.TryGetElementAt(out item: TValueKeyPair; index: Integer): Boolean;
var
  pair: TKeyValuePair;
begin
  Result := fSource.TryGetElementAt(pair, index);
  if Result then
  begin
   item.Key := pair.Value;
   item.Value := pair.Key;
 end;
end;

function TBidiDictionary<TKey, TValue>.TInverse.TryGetValue(const value: TValue;
  out key: TKey): Boolean;
var
  bucketIndex, itemIndex: Integer;
begin
  Result := fSource.FindValue(value, fSource.ValueHash(value), bucketIndex, itemIndex);
  if Result then
    key := fSource.fItems[itemIndex].Key
  else
    key := Default(TKey);
end;

{$ENDREGION}


{$REGION 'TBidiDictionary<TKey, TValue>.TInverse.TEnumerator'}

constructor TBidiDictionary<TKey, TValue>.TInverse.TEnumerator.Create(
  const source: TBidiDictionary<TKey, TValue>);
begin
  inherited Create;
  fSource := source;
  fSource._AddRef;
  fItemIndex := -1;
  fVersion := fSource.fVersion;
end;

destructor TBidiDictionary<TKey, TValue>.TInverse.TEnumerator.Destroy;
begin
  fSource._Release;
  inherited Destroy;
end;

function TBidiDictionary<TKey, TValue>.TInverse.TEnumerator.GetCurrent: TValueKeyPair;
begin
  Result.Key := fSource.fItems[fItemIndex].Value;
  Result.Value := fSource.fItems[fItemIndex].Key;
end;

function TBidiDictionary<TKey, TValue>.TInverse.TEnumerator.MoveNext: Boolean;
begin
  Result := fSource.DoMoveNext(fItemIndex, fVersion);
end;

{$ENDREGION}


{$REGION 'TBidiDictionary<TKey, TValue>.TInverse.TOrderedEnumerable'}

constructor TBidiDictionary<TKey, TValue>.TInverse.TOrderedEnumerable.Create(
  const source: TBidiDictionary<TKey, TValue>);
begin
  inherited Create;
  fSource := source;
  fSource._AddRef;
end;

destructor TBidiDictionary<TKey, TValue>.TInverse.TOrderedEnumerable.Destroy;
begin
  fSource._Release;
  inherited Destroy;
end;

procedure TBidiDictionary<TKey, TValue>.TInverse.TOrderedEnumerable.Dispose;
begin
  fSortedItemIndices := nil;
end;

function TBidiDictionary<TKey, TValue>.TInverse.TOrderedEnumerable.Clone: TIterator<TValueKeyPair>;
begin
  Result := TOrderedEnumerable.Create(fSource);
end;

function TBidiDictionary<TKey, TValue>.TInverse.TOrderedEnumerable.GetCount: Integer;
begin
  Result := fSource.fCount;
end;

function TBidiDictionary<TKey, TValue>.TInverse.TOrderedEnumerable.GetIsEmpty: Boolean;
begin
  Result := fSource.fCount = 0;
end;

procedure TBidiDictionary<TKey, TValue>.TInverse.TOrderedEnumerable.Start;
var
  sourceIndex, targetIndex: Integer;
  comparer: IComparer<TValue>;
begin
  fIndex := 0;
  fVersion := fSource.fVersion;

  SetLength(fSortedItemIndices, fSource.fCount);
  targetIndex := 0;
  for sourceIndex := 0 to fSource.fItemCount - 1 do
    if not fSource.fItems[sourceIndex].Removed then
    begin
      fSortedItemIndices[targetIndex] := sourceIndex;
      Inc(targetIndex);
    end;

  comparer := TComparer<TValue>.Default;
  TArray.Sort<Integer>(fSortedItemIndices,
    function(const left, right: Integer): Integer
    begin
      Result := comparer.Compare(fSource.fItems[left].Value, fSource.fItems[right].Value);
    end);
end;

function TBidiDictionary<TKey, TValue>.TInverse.TOrderedEnumerable.TryMoveNext(var current: TValueKeyPair): Boolean;
begin
  if fVersion <> fSource.fVersion then
    raise Error.EnumFailedVersion;

  if fIndex < Length(fSortedItemIndices) then
  begin
    current.Key := fSource.fItems[fSortedItemIndices[fIndex]].Value;
    current.Value := fSource.fItems[fSortedItemIndices[fIndex]].Key;
    Inc(fIndex);
    Exit(True);
  end;
  Result := False;
end;

{$ENDREGION}


{$REGION 'TBidiDictionary<TKey, TValue>.TEnumerator' }

constructor TBidiDictionary<TKey, TValue>.TEnumerator.Create(
  const source: TBidiDictionary<TKey, TValue>);
begin
  inherited Create;
  fSource := source;
  fSource._AddRef;
  fItemIndex := -1;
  fVersion := fSource.fVersion;
end;

destructor TBidiDictionary<TKey, TValue>.TEnumerator.Destroy;
begin
  fSource._Release;
  inherited Destroy;
end;

function TBidiDictionary<TKey, TValue>.TEnumerator.GetCurrent: TKeyValuePair;
begin
  Result.Key := fSource.fItems[fItemIndex].Key;
  Result.Value := fSource.fItems[fItemIndex].Value;
end;

function TBidiDictionary<TKey, TValue>.TEnumerator.MoveNext: Boolean;
begin
  Result := fSource.DoMoveNext(fItemIndex, fVersion);
end;

{$ENDREGION}


{$REGION 'TBidiDictionary<TKey, TValue>.TKeyCollection'}

constructor TBidiDictionary<TKey, TValue>.TKeyCollection.Create(
  const source: TBidiDictionary<TKey, TValue>);
begin
  inherited Create(source);
  fSource := source;
end;

function TBidiDictionary<TKey, TValue>.TKeyCollection.Contains(const value: TKey): Boolean;
begin
  Result := fSource.ContainsKey(value);
end;

function TBidiDictionary<TKey, TValue>.TKeyCollection.GetCount: Integer;
begin
  Result := fSource.fCount;
end;

function TBidiDictionary<TKey, TValue>.TKeyCollection.GetEnumerator: IEnumerator<TKey>;
begin
  Result := TKeyEnumerator.Create(fSource);
end;

function TBidiDictionary<TKey, TValue>.TKeyCollection.GetIsEmpty: Boolean;
begin
  Result := fSource.fCount = 0;
end;

function TBidiDictionary<TKey, TValue>.TKeyCollection.ToArray: TArray<TKey>;
var
  sourceIndex, targetIndex: Integer;
begin
  SetLength(Result, fSource.fCount);
  targetIndex := 0;
  for sourceIndex := 0 to fSource.fItemCount - 1 do
    if not fSource.fItems[sourceIndex].Removed then
    begin
      Result[targetIndex] := fSource.fItems[sourceIndex].Key;
      Inc(targetIndex);
    end;
end;

function TBidiDictionary<TKey, TValue>.TKeyCollection.TryGetElementAt(out key: TKey; index: Integer): Boolean;
begin
  Result := InRange(index, 0, fSource.fCount - 1);
  if Result then
  begin
    fSource.EnsureCompact;
    key := fSource.fItems[index].Key;
  end;
end;

{$ENDREGION}


{$REGION 'TBidiDictionary<TKey, TValue>.TKeyEnumerator' }

constructor TBidiDictionary<TKey, TValue>.TKeyEnumerator.Create(
  const source: TBidiDictionary<TKey, TValue>);
begin
  inherited Create;
  fSource := source;
  fSource._AddRef;
  fItemIndex := -1;
  fVersion := fSource.fVersion;
end;

destructor TBidiDictionary<TKey, TValue>.TKeyEnumerator.Destroy;
begin
  fSource._Release;
  inherited Destroy;
end;

function TBidiDictionary<TKey, TValue>.TKeyEnumerator.GetCurrent: TKey;
begin
  Result := fSource.fItems[fItemIndex].Key;
end;

function TBidiDictionary<TKey, TValue>.TKeyEnumerator.MoveNext: Boolean;
begin
  Result := fSource.DoMoveNext(fItemIndex, fVersion);
end;

{$ENDREGION}


{$REGION 'TBidiDictionary<TKey, TValue>.TValueCollection'}

constructor TBidiDictionary<TKey, TValue>.TValueCollection.Create(
  const source: TBidiDictionary<TKey, TValue>);
begin
  inherited Create(source);
  fSource := source;
end;

function TBidiDictionary<TKey, TValue>.TValueCollection.Contains(const value: TValue): Boolean;
begin
  Result := fSource.ContainsValue(value);
end;

function TBidiDictionary<TKey, TValue>.TValueCollection.GetCount: Integer;
begin
  Result := fSource.fCount;
end;

function TBidiDictionary<TKey, TValue>.TValueCollection.GetEnumerator: IEnumerator<TValue>;
begin
  Result := TValueEnumerator.Create(fSource);
end;

function TBidiDictionary<TKey, TValue>.TValueCollection.GetIsEmpty: Boolean;
begin
  Result := fSource.fCount = 0;
end;

function TBidiDictionary<TKey, TValue>.TValueCollection.ToArray: TArray<TValue>;
var
  sourceIndex, targetIndex: Integer;
begin
  SetLength(Result, fSource.fCount);
  targetIndex := 0;
  for sourceIndex := 0 to fSource.fItemCount - 1 do
    if not fSource.fItems[sourceIndex].Removed then
    begin
      Result[targetIndex] := fSource.fItems[sourceIndex].Value;
      Inc(targetIndex);
    end;
end;

function TBidiDictionary<TKey, TValue>.TValueCollection.TryGetElementAt(out value: TValue; index: Integer): Boolean;
begin
  Result := InRange(index, 0, fSource.fCount - 1);
  if Result then
  begin
    fSource.EnsureCompact;
    value := fSource.fItems[index].Value;
  end;
end;

{$ENDREGION}


{$REGION 'TBidiDictionary<TKey, TValue>.TValueEnumerator'}

constructor TBidiDictionary<TKey, TValue>.TValueEnumerator.Create(
  const source: TBidiDictionary<TKey, TValue>);
begin
  inherited Create;
  fSource := source;
  fSource._AddRef;
  fItemIndex := -1;
  fVersion := fSource.fVersion;
end;

destructor TBidiDictionary<TKey, TValue>.TValueEnumerator.Destroy;
begin
  fSource._Release;
  inherited Destroy;
end;

function TBidiDictionary<TKey, TValue>.TValueEnumerator.GetCurrent: TValue;
begin
  Result := fSource.fItems[fItemIndex].Value;
end;

function TBidiDictionary<TKey, TValue>.TValueEnumerator.MoveNext: Boolean;
begin
  Result := fSource.DoMoveNext(fItemIndex, fVersion);
end;

{$ENDREGION}


{$REGION 'TBidiDictionary<TKey, TValue>.TOrderedEnumerable'}

constructor TBidiDictionary<TKey, TValue>.TOrderedEnumerable.Create(
  const source: TBidiDictionary<TKey, TValue>);
begin
  inherited Create;
  fSource := source;
  fSource._AddRef;
end;

destructor TBidiDictionary<TKey, TValue>.TOrderedEnumerable.Destroy;
begin
  fSource._Release;
  inherited Destroy;
end;

procedure TBidiDictionary<TKey, TValue>.TOrderedEnumerable.Dispose;
begin
  fSortedItemIndices := nil;
end;

function TBidiDictionary<TKey, TValue>.TOrderedEnumerable.Clone: TIterator<TKeyValuePair>;
begin
  Result := TOrderedEnumerable.Create(fSource);
end;

function TBidiDictionary<TKey, TValue>.TOrderedEnumerable.GetCount: Integer;
begin
  Result := fSource.fCount;
end;

function TBidiDictionary<TKey, TValue>.TOrderedEnumerable.GetIsEmpty: Boolean;
begin
  Result := fSource.fCount = 0;
end;

procedure TBidiDictionary<TKey, TValue>.TOrderedEnumerable.Start;
var
  sourceIndex, targetIndex: Integer;
  comparer: IComparer<TKey>;
begin
  fIndex := 0;
  fVersion := fSource.fVersion;

  comparer := TComparer<TKey>.Default;
  SetLength(fSortedItemIndices, fSource.fCount);
  targetIndex := 0;
  for sourceIndex := 0 to fSource.fItemCount - 1 do
    if not fSource.fItems[sourceIndex].Removed then
    begin
      fSortedItemIndices[targetIndex] := sourceIndex;
      Inc(targetIndex);
    end;

  TArray.Sort<Integer>(fSortedItemIndices,
    function(const left, right: Integer): Integer
    begin
      Result := comparer.Compare(fSource.fItems[left].Key, fSource.fItems[right].Key);
    end);
end;

function TBidiDictionary<TKey, TValue>.TOrderedEnumerable.TryMoveNext(var current: TKeyValuePair): Boolean;
begin
  if fVersion <> fSource.fVersion then
    raise Error.EnumFailedVersion;

  if fIndex < Length(fSortedItemIndices) then
  begin
    current.Key := fSource.fItems[fSortedItemIndices[fIndex]].Key;
    current.Value := fSource.fItems[fSortedItemIndices[fIndex]].Value;
    Inc(fIndex);
    Exit(True);
  end;
  Result := False;
end;

{$ENDREGION}


{$REGION 'TSortedDictionary<TKey, TValue>'}

constructor TSortedDictionary<TKey, TValue>.Create;
begin
  Create(nil, nil);
end;

constructor TSortedDictionary<TKey, TValue>.Create(
  const keyComparer: IComparer<TKey>;
  const valueComparer: IEqualityComparer<TValue>);
begin
  inherited Create;

  fKeys := TKeyCollection.Create(Self);
  fValues := TValueCollection.Create(Self);

  fKeyComparer := keyComparer;
  if Assigned(keyComparer) then
    fKeyComparer := keyComparer
  else
    fKeyComparer := TComparer<TKey>.Default;
  if Assigned(valueComparer) then
    fValueComparer := valueComparer
  else
    fValueComparer := TEqualityComparer<TValue>.Default;
  fTree := TRedBlackTree<TKey,TValue>.Create(keyComparer);
end;

destructor TSortedDictionary<TKey, TValue>.Destroy;
begin
  Clear;
  fTree.Free;
  fKeys.Free;
  fValues.Free;
  inherited Destroy;
end;

function TSortedDictionary<TKey, TValue>.AsReadOnly: IReadOnlyDictionary<TKey, TValue>;
begin
  Result := Self;
end;

procedure TSortedDictionary<TKey, TValue>.Clear;
var
  node: PNode;
begin
  IncUnchecked(fVersion);

  node := fTree.Root.LeftMost;
  while Assigned(node) do
  begin
    if Assigned(Notify) then
      DoNotify(node.Key, node.Value, caRemoved);
    KeyChanged(node.Key, caRemoved);
    ValueChanged(node.Value, caRemoved);
    node := node.Next;
  end;

  fTree.Clear;
end;

function TSortedDictionary<TKey, TValue>.Contains(const value: TKeyValuePair;
  const comparer: IEqualityComparer<TKeyValuePair>): Boolean;
var
  found: TValue;
begin
  Result := fTree.Find(value.Key, found)
    and comparer.Equals(value, TKeyValuePair.Create(value.Key, found));
end;

function TSortedDictionary<TKey, TValue>.Contains(const key: TKey;
  const value: TValue): Boolean;
var
  found: TValue;
begin
  Result := fTree.Find(key, found) and fValueComparer.Equals(value, found);
end;

function TSortedDictionary<TKey, TValue>.ContainsKey(const key: TKey): Boolean;
begin
  Result := fTree.Exists(key);
end;

function TSortedDictionary<TKey, TValue>.ContainsValue(const value: TValue): Boolean;
var
  found: TKeyValuePair;
begin
  for found in fTree do
    if fValueComparer.Equals(value, found.Value) then
      Exit(True);
  Result := False;
end;

function TSortedDictionary<TKey, TValue>.DoMoveNext(var currentNode: PNode;
  var finished: Boolean; iteratorVersion: Integer): Boolean;
begin
  if iteratorVersion <> fVersion then
    raise Error.EnumFailedVersion;

  if (fTree.Count = 0) or finished then
    Exit(False);

  if not Assigned(currentNode) then
    currentNode := fTree.Root.LeftMost
  else
    currentNode := currentNode.Next;
  Result := Assigned(currentNode);
  finished := not Result;
end;

function TSortedDictionary<TKey, TValue>.Extract(const key: TKey;
  const value: TValue): TKeyValuePair;
var
  node: PNode;
begin
  node := fTree.FindNode(key);
  if Assigned(node) and fValueComparer.Equals(value, node.Value) then
  begin
    Result.Key := node.Key;
    Result.Value := node.Value;
    IncUnchecked(fVersion);
    fTree.DeleteNode(node);
    Changed(Result, caExtracted);
    KeyChanged(Result.Key, caExtracted);
    ValueChanged(Result.Value, caExtracted);
  end
  else
    Result := Default(TKeyValuePair);
end;

function TSortedDictionary<TKey, TValue>.Extract(const key: TKey): TValue;
begin
  TryExtract(key, Result);
end;

function TSortedDictionary<TKey, TValue>.GetCapacity: Integer;
begin
  Result := fTree.Capacity;
end;

function TSortedDictionary<TKey, TValue>.GetCount: Integer;
begin
  Result := fTree.Count;
end;

function TSortedDictionary<TKey, TValue>.GetEnumerator: IEnumerator<TKeyValuePair>;
begin
  Result := TEnumerator.Create(Self);
end;

function TSortedDictionary<TKey, TValue>.GetIsEmpty: Boolean;
begin
  Result := fTree.Count = 0;
end;

function TSortedDictionary<TKey, TValue>.GetItem(const key: TKey): TValue;
begin
  if not TryGetValue(key, Result) then
    raise Error.KeyNotFound;
end;

function TSortedDictionary<TKey, TValue>.GetKeys: IReadOnlyCollection<TKey>;
begin
  Result := fKeys;
end;

function TSortedDictionary<TKey, TValue>.GetValueOrDefault(const key: TKey): TValue;
begin
  if not fTree.Find(key, Result) then
    Result := Default(TValue);
end;

function TSortedDictionary<TKey, TValue>.GetValueOrDefault(const key: TKey;
  const defaultValue: TValue): TValue;
begin
  if not fTree.Find(key, Result) then
    Result := defaultValue;
end;

function TSortedDictionary<TKey, TValue>.GetValues: IReadOnlyCollection<TValue>;
begin
  Result := fValues;
end;

function TSortedDictionary<TKey, TValue>.Remove(const key: TKey): Boolean;
var
  node: PNode;
begin
  node := fTree.FindNode(key);
  Result := Assigned(node);
  if Result then
  begin
    IncUnchecked(fVersion);
    if Assigned(Notify) then
      DoNotify(node.Key, node.Value, caRemoved);
    KeyChanged(node.Key, caRemoved);
    ValueChanged(node.Value, caRemoved);
    fTree.DeleteNode(node);
  end;
end;

function TSortedDictionary<TKey, TValue>.Remove(const key: TKey;
  const value: TValue): Boolean;
var
  node: PNode;
begin
  node := fTree.FindNode(key);
  Result := Assigned(node) and fValueComparer.Equals(value, node.Value);
  if Result then
  begin
    IncUnchecked(fVersion);
    if Assigned(Notify) then
      DoNotify(node.Key, node.Value, caRemoved);
    KeyChanged(node.Key, caRemoved);
    ValueChanged(node.Value, caRemoved);
    fTree.DeleteNode(node);
  end;
end;

procedure TSortedDictionary<TKey, TValue>.SetCapacity(value: Integer);
begin
  fTree.Capacity := value;
end;

procedure TSortedDictionary<TKey, TValue>.SetItem(const key: TKey; const value: TValue);
var
  node: PNode;
begin
  IncUnchecked(fVersion);
  node := fTree.FindNode(key);
  if Assigned(node) then
  begin
    if Assigned(Notify) then
      DoNotify(key, node.Value, caRemoved);
    ValueChanged(node.Value, caRemoved);
    node.Value := value;
    if Assigned(Notify) then
      DoNotify(key, value, caAdded);
    ValueChanged(value, caAdded);
  end
  else
  begin
    fTree.Add(key, value);
    if Assigned(Notify) then
      DoNotify(key, value, caAdded);
    KeyChanged(key, caAdded);
    ValueChanged(value, caAdded);
  end;
end;

function TSortedDictionary<TKey, TValue>.Ordered: IEnumerable<TKeyValuePair>;
begin
  Result := TOrderedIterator<TKeyValuePair>.Create(this, fKeyValueComparerByKey);
end;

function TSortedDictionary<TKey, TValue>.ToArray: TArray<TKeyValuePair>;
var
  i: Integer;
  node: PNode;
begin
  SetLength(Result, fTree.Count);
  i := 0;
  node := fTree.Root.LeftMost;
  while Assigned(node) do
  begin
    Result[i].Key := node.Key;
    Result[i].Value := node.Value;
    node := node.Next;
    Inc(i);
  end;
end;

procedure TSortedDictionary<TKey, TValue>.TrimExcess;
begin
  fTree.TrimExcess;
end;

function TSortedDictionary<TKey, TValue>.TryAdd(const key: TKey;
  const value: TValue): Boolean;
begin
  if not fTree.Add(key, value) then
    Exit(False);
  IncUnchecked(fVersion);
  if Assigned(Notify) then
    DoNotify(key, value, caAdded);
  KeyChanged(key, caAdded);
  ValueChanged(value, caAdded);
  Result := True;
end;

function TSortedDictionary<TKey, TValue>.TryExtract(const key: TKey; out value: TValue): Boolean;
var
  node: PNode;
begin
  node := fTree.FindNode(key);
  Result := Assigned(node);
  if Result then
  begin
    value := node.Value;
    IncUnchecked(fVersion);
    fTree.DeleteNode(node);
    if Assigned(Notify) then
      DoNotify(key, value, caExtracted);
    KeyChanged(key, caExtracted);
    ValueChanged(value, caExtracted);
  end
  else
    value := Default(TValue);
end;

function TSortedDictionary<TKey, TValue>.TryGetValue(const key: TKey;
  out value: TValue): Boolean;
begin
  Result := fTree.Find(key, value);
end;

{$ENDREGION}


{$REGION 'TSortedDictionary<TKey, TValue>.TEnumerator'}

constructor TSortedDictionary<TKey, TValue>.TEnumerator.Create(
  const source: TSortedDictionary<TKey, TValue>);
begin
  inherited Create;
  fSource := source;
  fSource._AddRef;
  fVersion := fSource.fVersion;
end;

destructor TSortedDictionary<TKey, TValue>.TEnumerator.Destroy;
begin
  fSource._Release;
  inherited Destroy;
end;

function TSortedDictionary<TKey, TValue>.TEnumerator.GetCurrent: TKeyValuePair;
begin
  Result.Key := fCurrentNode.Key;
  Result.Value := fCurrentNode.Value;
end;

function TSortedDictionary<TKey, TValue>.TEnumerator.MoveNext: Boolean;
begin
  Result := fSource.DoMoveNext(fCurrentNode, fFinished, fVersion);
end;

{$ENDREGION}


{$REGION 'TSortedDictionary<TKey, TValue>.TKeyCollection'}

constructor TSortedDictionary<TKey, TValue>.TKeyCollection.Create(
  const source: TSortedDictionary<TKey, TValue>);
begin
  inherited Create(source);
  fSource := source;
end;

function TSortedDictionary<TKey, TValue>.TKeyCollection.Contains(
  const value: TKey): Boolean;
begin
  Result := fSource.fTree.Exists(value);
end;

function TSortedDictionary<TKey, TValue>.TKeyCollection.GetCount: Integer;
begin
  Result := fSource.fTree.Count;
end;

function TSortedDictionary<TKey, TValue>.TKeyCollection.GetEnumerator: IEnumerator<TKey>;
begin
  Result := TKeyEnumerator.Create(fSource);
end;

function TSortedDictionary<TKey, TValue>.TKeyCollection.GetIsEmpty: Boolean;
begin
  Result := fSource.fTree.Count = 0;
end;

function TSortedDictionary<TKey, TValue>.TKeyCollection.ToArray: TArray<TKey>;
var
  i: Integer;
  node: PNode;
begin
  SetLength(Result, fSource.fTree.Count);
  i := 0;
  node := fSource.fTree.Root.LeftMost;
  while Assigned(node) do
  begin
    Result[i] := node.Key;
    node := node.Next;
    Inc(i);
  end;
end;

{$ENDREGION}


{$REGION 'TSortedDictionary<TKey, TValue>.TKeyEnumerator'}

constructor TSortedDictionary<TKey, TValue>.TKeyEnumerator.Create(
  const source: TSortedDictionary<TKey, TValue>);
begin
  inherited Create;
  fSource := source;
  fSource._AddRef;
  fVersion := fSource.fVersion;
end;

destructor TSortedDictionary<TKey, TValue>.TKeyEnumerator.Destroy;
begin
  fSource._Release;
  inherited Destroy;
end;

function TSortedDictionary<TKey, TValue>.TKeyEnumerator.GetCurrent: TKey;
begin
  Result := fCurrentNode.Key;
end;

function TSortedDictionary<TKey, TValue>.TKeyEnumerator.MoveNext: Boolean;
begin
  Result := fSource.DoMoveNext(fCurrentNode, fFinished, fVersion);
end;

{$ENDREGION}


{$REGION 'TSortedDictionary<TKey, TValue>.TValueCollection'}

constructor TSortedDictionary<TKey, TValue>.TValueCollection.Create(
  const dictionary: TSortedDictionary<TKey, TValue>);
begin
  inherited Create(dictionary);
  fSource := dictionary;
end;

function TSortedDictionary<TKey, TValue>.TValueCollection.Contains(
  const value: TValue): Boolean;
begin
  Result := fSource.ContainsValue(value);
end;

function TSortedDictionary<TKey, TValue>.TValueCollection.GetCount: Integer;
begin
  Result := fSource.fTree.Count;
end;

function TSortedDictionary<TKey, TValue>.TValueCollection.GetEnumerator: IEnumerator<TValue>;
begin
  Result := TValueEnumerator.Create(fSource);
end;

function TSortedDictionary<TKey, TValue>.TValueCollection.GetIsEmpty: Boolean;
begin
  Result := fSource.fTree.Count = 0;
end;

function TSortedDictionary<TKey, TValue>.TValueCollection.ToArray: TArray<TValue>;
var
  i: Integer;
  node: PNode;
begin
  SetLength(Result, fSource.fTree.Count);
  i := 0;
  node := fSource.fTree.Root.LeftMost;
  while Assigned(node) do
  begin
    Result[i] := node.Value;
    node := node.Next;
    Inc(i);
  end;
end;

{$ENDREGION}


{$REGION 'TSortedDictionary<TKey, TValue>.TValueEnumerator'}

constructor TSortedDictionary<TKey, TValue>.TValueEnumerator.Create(
  const source: TSortedDictionary<TKey, TValue>);
begin
  inherited Create;
  fSource := source;
  fSource._AddRef;
  fVersion := fSource.fVersion;
end;

destructor TSortedDictionary<TKey, TValue>.TValueEnumerator.Destroy;
begin
  fSource._Release;
  inherited Destroy;
end;

function TSortedDictionary<TKey, TValue>.TValueEnumerator.GetCurrent: TValue;
begin
  Result := fCurrentNode.Value;
end;

function TSortedDictionary<TKey, TValue>.TValueEnumerator.MoveNext: Boolean;
begin
  Result := fSource.DoMoveNext(fCurrentNode, fFinished, fVersion);
end;

{$ENDREGION}


end.
