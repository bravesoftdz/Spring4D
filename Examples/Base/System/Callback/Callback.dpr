{***************************************************************************}
{                                                                           }
{           Delphi Spring Framework                                         }
{                                                                           }
{           Copyright (C) 2009-2010 Delphi Spring Framework                 }
{                                                                           }
{           http://delphi-spring-framework.googlecode.com                   }
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

program Callback;

{$APPTYPE CONSOLE}

uses
  Classes,
  SysUtils,
  Windows,
  Rtti,
  Spring.System;

type
  TWindowsEnumerator = class
  private
    fCallback: TCallbackFunc;
    { The class instance method must be declared as "stdcall". }
    procedure AddWindowCaption(handle: THandle; list: TStrings); stdcall;
  public
    procedure GetWindowNames(list: TStrings);
  end;

{ TWindowsEnumerator }

procedure TWindowsEnumerator.AddWindowCaption(handle: THandle; list: TStrings);
var
  caption: array[0..256] of Char;
begin
  if GetWindowText(handle, caption, Length(caption)) > 0 then
  begin
    list.Add(Format('Handle: %8x, Caption: %s', [handle, caption]));
  end;
end;

procedure TWindowsEnumerator.GetWindowNames(list: TStrings);
begin
  TArgument.CheckNotNull(list, 'list');
  if not Assigned(fCallback) then
  begin
    fCallback := TCallBack.Create(Self, @TWindowsEnumerator.AddWindowCaption);
  end;
  Windows.EnumWindows(fCallback, lParam(list));
end;

var
  enumerator: TWindowsEnumerator;
  list: TStrings;

begin
  try
    list := TStringList.Create;
    try
      enumerator := TWindowsEnumerator.Create;
      try
        enumerator.GetWindowNames(list);
      finally
        enumerator.Free;
      end;
      Writeln(list.Text);
    finally
      list.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Readln;
end.