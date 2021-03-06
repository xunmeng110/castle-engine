{ -*- buffer-read-only: t -*-

  Copyright 2015-2021 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Automatically generated node properties.

  Do not edit this file manually!
  To add new properties:
  - add them to the text files in tools/internal/x3d-nodes-to-pascal/nodes-specification/ ,
  - and regenerate include files by running x3d-nodes-to-pascal .

  The documentation for properties should go to x3dnodes_documentation.txt . }

{$ifdef read_interface}

  strict private
    function GetEnabled: Boolean;
    procedure SetEnabled(const Value: Boolean);
    function GetRotation: TVector4;
    procedure SetRotation(const Value: TVector4);
    function GetTranslation: TVector3;
    procedure SetTranslation(const Value: TVector3);
    function GetBBox: TBox3D;
    procedure SetBBox(const Value: TBox3D);
  public
    procedure CreateNode; override;
    class function ClassX3DType: string; override;

    strict private FFdEnabled: TSFBool;
    { X3D field "enabled". } { }
    public property FdEnabled: TSFBool read FFdEnabled;
    { X3D field "enabled". } { }
    property Enabled: Boolean read GetEnabled write SetEnabled;

    strict private FFdRotation: TSFRotation;
    { X3D field "rotation". } { }
    public property FdRotation: TSFRotation read FFdRotation;
    { X3D field "rotation". } { }
    property Rotation: TVector4 read GetRotation write SetRotation;

    strict private FFdTranslation: TSFVec3f;
    { X3D field "translation". } { }
    public property FdTranslation: TSFVec3f read FFdTranslation;
    { X3D field "translation". } { }
    property Translation: TVector3 read GetTranslation write SetTranslation;

    strict private FFdBboxCenter: TSFVec3f;
    { X3D field "bboxCenter". } { }
    public property FdBboxCenter: TSFVec3f read FFdBboxCenter;
    { X3D fields "bboxCenter" and "bboxSize" are get/set as TBox3D. } { }
    property BBox: TBox3D read GetBBox write SetBBox;

    strict private FFdBboxSize: TSFVec3f;
    { X3D field "bboxSize". } { }
    public property FdBboxSize: TSFVec3f read FFdBboxSize;

{$endif read_interface}

{$ifdef read_implementation}

{ TAbstractNBodyCollidableNode ----------------------------------------------- }

function TAbstractNBodyCollidableNode.GetEnabled: Boolean;
begin
  Result := FdEnabled.Value;
end;

procedure TAbstractNBodyCollidableNode.SetEnabled(const Value: Boolean);
begin
  FdEnabled.Send(Value);
end;

function TAbstractNBodyCollidableNode.GetRotation: TVector4;
begin
  Result := FdRotation.Value;
end;

procedure TAbstractNBodyCollidableNode.SetRotation(const Value: TVector4);
begin
  FdRotation.Send(Value);
end;

function TAbstractNBodyCollidableNode.GetTranslation: TVector3;
begin
  Result := FdTranslation.Value;
end;

procedure TAbstractNBodyCollidableNode.SetTranslation(const Value: TVector3);
begin
  FdTranslation.Send(Value);
end;

function TAbstractNBodyCollidableNode.GetBBox: TBox3D;
begin
  Result := TBox3D.FromCenterSize(FdBBoxCenter.Value, FdBBoxSize.Value);
end;

procedure TAbstractNBodyCollidableNode.SetBBox(const Value: TBox3D);
var
  ValueCenter, ValueSize: TVector3;
begin
  Value.ToCenterSize(ValueCenter, ValueSize);
  FdBBoxCenter.Send(ValueCenter);
  FdBBoxSize.Send(ValueSize);
end;

class function TAbstractNBodyCollidableNode.ClassX3DType: String;
begin
  Result := 'X3DNBodyCollidableNode';
end;

procedure TAbstractNBodyCollidableNode.CreateNode;
begin
  inherited;

  FFdEnabled := TSFBool.Create(Self, True, 'enabled', true);
   FdEnabled.ChangeAlways := chVisibleNonGeometry;
  AddField(FFdEnabled);

  FFdRotation := TSFRotation.Create(Self, True, 'rotation', Vector3(0, 0, 1), 0);
   FdRotation.ChangeAlways := chVisibleNonGeometry;
  AddField(FFdRotation);
  { X3D specification comment: [0,1] }

  FFdTranslation := TSFVec3f.Create(Self, True, 'translation', Vector3(0, 0, 0));
   FdTranslation.ChangeAlways := chVisibleNonGeometry;
  AddField(FFdTranslation);
  { X3D specification comment: (-Inf,Inf) }

  FFdBboxCenter := TSFVec3f.Create(Self, False, 'bboxCenter', Vector3(0, 0, 0));
   FdBboxCenter.ChangeAlways := chVisibleNonGeometry;
  AddField(FFdBboxCenter);
  { X3D specification comment: (-Inf,Inf) }

  FFdBboxSize := TSFVec3f.Create(Self, False, 'bboxSize', Vector3(-1, -1, -1));
   FdBboxSize.ChangeAlways := chVisibleNonGeometry;
  AddField(FFdBboxSize);
  { X3D specification comment: [0,Inf) or -1 -1 -1 }
end;

{$endif read_implementation}
