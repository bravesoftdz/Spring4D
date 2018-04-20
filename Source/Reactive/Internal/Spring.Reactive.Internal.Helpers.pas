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

unit Spring.Reactive.Internal.Helpers;

interface

uses
  Spring,
  Spring.Collections;

type
  Helpers = record
    class function GetLength<T>(const source: IEnumerable<T>): Nullable<Integer>; static;
  end;

implementation

uses
  Spring.Collections.Base,
  Spring.Collections.Extensions;


{$REGION 'Helpers'}

class function Helpers.GetLength<T>(
  const source: IEnumerable<T>): Nullable<Integer>;
begin
  if source is TArrayIterator<T> then
    Result := source.Count
  else if source is TListBase<T> then
    Result := source.Count
  else
    Result := nil;
end;

{$ENDREGION}


end.
