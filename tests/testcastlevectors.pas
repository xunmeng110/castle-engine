{
  Copyright 2004-2017 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

unit TestCastleVectors;

{ $define VECTOR_MATH_SPEED_TESTS}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, CastleVectors,
  CastleBaseTestCase;

type
  TTestCastleVectors = class(TCastleBaseTestCase)
  published
    procedure TestPlaneOdcCollision;
    procedure TestCollisions;
    procedure TestArea;
    procedure TestPerpParallel;
    procedure TestPlanesIntersection;
    procedure TestOther;
    procedure TestVectorStr;
    procedure TestMatrixInverse;
    procedure TestMultMatrixTranslation;
    procedure TestMultMatricesTranslation;
    procedure TestIndexedPolygonNormalArea;
    procedure TestSphereRayIntersection;
    procedure TestMatrixMultiplication;
    procedure TestMatrixTranspose;
    procedure TestVector3FromStr;
    procedure TestVector4FromStr;
    procedure TestPlaneTransform;
    procedure TestTransformToFromCoordsMatrix;
    procedure Test2D;
    procedure TestApproximateScale;
    procedure TestXYZ;
    procedure TestPlaneMove;
    procedure TestPlaneMoveRandom;
  end;

function RandomVector: TVector3;
function RandomMatrix: TMatrix4;
function RandomNonProjectionMatrix: TMatrix4;

implementation

uses Math,
  CastleUtils, CastleStringUtils, CastleTimeUtils, CastleTriangles;

const
  {$ifdef VECTOR_MATH_SPEED_TESTS}
  SPEED_TEST_1_CYCLES = 1000000;
  SPEED_TEST_2_CYCLES = 10000000;
  SPEED_TEST_3_CYCLES = 1000;
  {$else}
  { speed testy przeprowadzaja przy okazji normalne testy ktore
    zawsze bedziesz chcial wykonac. Wiec jesli VECTOR_MATH_SPEED_TESTS
    nie jest zdefiniowane to po prostu SPEED_TEST_x_CYCLES beda
    mniejsze (ale nie zerowe) i nie bedzie Writelnow wynikow. }
  SPEED_TEST_1_CYCLES = 1000;
  SPEED_TEST_2_CYCLES = 1000;
  SPEED_TEST_3_CYCLES = 1000;
  {$endif}

procedure TTestCastleVectors.TestPlaneOdcCollision;
{ test below caught once fpc 1.0.10 bugs in inlines }
var Intersection: TVector3;
    T: Single;
begin
 T := TVector3.DotProduct(Vector3(0, 0, 1), Vector3(0, 0, 6));
 AssertSameValue(6, T);

 AssertTrue(TryPlaneLineIntersection(T,
   Vector4(0, 0, 1, 1),
   Vector3(2, 2, -3),
   Vector3(0, 0, 6) ));
 AssertSameValue(1/3, T, 0.0000001);

 AssertTrue(TryPlaneSegmentDirIntersection(Intersection, T,
   Vector4(0, 0, 1, 1),
   Vector3(2, 2, -3),
   Vector3(0, 0, 6) ));
 AssertVectorEquals(Vector3(2, 2, -1), Intersection);
 AssertSameValue(1/3, T, 0.0000001);
end;

procedure WritelnSpeedTest(const s: string);
begin
 {$ifdef VECTOR_MATH_SPEED_TESTS}
 Writeln(s);
 {$endif}
end;

procedure TTestCastleVectors.TestCollisions;
const
  TriConst: TTriangle3 = (Data: (
    (Data: (2, 2, -1)),
    (Data: (3, 3, -1)),
    (Data: (3, 2, -1)) ));
  TriPlaneConst: TVector4 = (Data: (0, 0, 1, 1));
  Pos1Const: TVector3 = (Data: (2, 2, -3));
  Pos2Const: TVector3 = (Data: (2, 2, 3));
  Coll: TVector3 = (Data: (2, 2, -1));
var
  Intersection, Intersection2: TVector3;
begin
 { czy dziala TryTriangleSegmentCollision na tym naszym skonstruowanym
   przykladzie ? }
 AssertTrue( TryTriangleSegmentCollision(Intersection, TriConst, TriPlaneConst,
   Pos1Const, Pos2Const) and TVector3.Equals(Intersection, Coll));
 { czy dziala tak samo gdy sam musi sobie wyliczyc place (test TTriangle3.Plane) ? }
 AssertTrue( TryTriangleSegmentCollision(Intersection2, TriConst, TriConst.Plane,
   Pos1Const, Pos2Const) and TVector3.Equals(Intersection2, Coll));
end;

procedure TTestCastleVectors.TestArea;
const
  Tri: TTriangle3 = (Data: (
    (Data: (0, 0, 0)),
    (Data: (10, 0, 0)),
    (Data: (0, 25, 0)) ));
  CCWPoly: array [0..4] of TVector2 = (
    (Data: (5, 4)),
    (Data: (2, 3)),
    (Data: (4, 3)),
    (Data: (2, 1)),
    (Data: (6, 2)) );
  CWPoly: array [0..4] of TVector2 = (
    (Data: (6, 2)),
    (Data: (2, 1)),
    (Data: (4, 3)),
    (Data: (2, 3)),
    (Data: (5, 4)) );
begin
 AssertTrue(Tri.Area = 10*25/2);

 AssertTrue(Polygon2dArea(CCWPoly) = 5.5);
 AssertTrue(Polygon2dArea(CWPoly) = 5.5);
 AssertTrue(IsPolygon2dCCW(CCWPoly) > 0);
 AssertTrue(IsPolygon2dCCW(CWPoly) < 0);
end;

procedure TTestCastleVectors.TestPerpParallel;
var v: TVector3;
    i: integer;
begin
 for i := 1 to 10 do
 try
  v := RandomVector;
  AssertTrue( VectorsPerp(AnyOrthogonalVector(v), v) );
  { I has to comment it out -- it fails too often due to floating point
    inaccuracy. }
  { AssertTrue( VectorsParallel(v * (Random * 10)), v) ); }
  AssertTrue( VectorsPerp(TVector3.Zero, v) );
  AssertTrue( VectorsParallel(TVector3.Zero, v) );
 except
  Writeln('and failed : v = ',v.ToString,
    ' anyPerp = ',AnyOrthogonalVector(v).ToString);
  raise;
 end;

 AssertTrue( VectorsPerp(TVector3.Zero, TVector3.Zero) );
 AssertTrue( VectorsParallel(TVector3.Zero, TVector3.Zero) );

 AssertTrue( VectorsPerp(TVector3.One[0], TVector3.One[1]) );
 AssertTrue( VectorsPerp(TVector3.One[0], TVector3.One[2]) );
 AssertTrue( VectorsPerp(TVector3.One[1], TVector3.One[2]) );
 AssertTrue( not VectorsPerp(TVector3.One[0], TVector3.One[0]) );

 AssertTrue( not VectorsParallel(TVector3.One[0], TVector3.One[1]) );
 AssertTrue( not VectorsParallel(TVector3.One[0], TVector3.One[2]) );
 AssertTrue( not VectorsParallel(TVector3.One[1], TVector3.One[2]) );
 AssertTrue( VectorsParallel(TVector3.One[0], TVector3.One[0]) );
end;

procedure TTestCastleVectors.TestPlanesIntersection;
const
  P1: TVector4 = (Data: (-1.9935636520385742, -0.00000009909226151, 0.25691652297973633, -30.014257431030273));
  P2: TVector4 = (Data: (-1.2131816148757935, 1.90326225890658E-008, -1.5900282859802246, 1.5900282859802246));
var
  Line0, LineVector: TVector3;
begin
 TwoPlanesIntersectionLine(P1, P2, Line0, LineVector);
 { Writeln(Line0.ToRawString, ' ', LineVector.ToRawString); }
end;

procedure TTestCastleVectors.TestOther;
var
  I1, I2, RayOrigin, RayDirection: TVector3;
  Plane: TVector4;
// PlaneDir: TVector3 absolute Plane;
  PlaneConstCoord: integer;
  PlaneConstVal: Single;
  b1, b2: boolean;
// t1, t2: Double;

  function RandomVector3: TVector3;
  begin
   result[0] := Random*1000 -500.0;
   result[1] := Random*1000 -500.0;
   result[2] := Random*1000 -500.0;
  end;

const VConst: TVector3 = (Data: (1.0, 2.0, 3.0));

var
  i: integer;
  V: TVector3;
  Time0, Time1, Time2: Double;
  StartTime: TProcessTimerResult;
begin
 { ------------------------------------------------------------
   testuj TrySimplePlaneRayIntersection przy uzyciu TryPlaneRayIntersection }
 for i := 1 to 100000 do
 begin
  RayOrigin := RandomVector3;
  RayDirection := RandomVector3;

  PlaneConstCoord := Random(3);
  PlaneConstVal := Random*1000 - 500;
  FillChar(Plane, SizeOf(Plane), 0);
  Plane[PlaneConstCoord] := -1;
  Plane[3] := PlaneConstVal;

  { czasami uczyn promien rownoleglym do [Simple]Plane (zeby zobaczyc
    czy sobie z tym radzi) }
  if Random(10) = 1 then
  begin
   RayDirection[PlaneConstCoord] := 0;
   b1 := TrySimplePlaneRayIntersection(I1, PlaneConstCoord, PlaneConstVal, RayOrigin, RayDirection);
   b2 := TryPlaneRayIntersection(I2, Plane, RayOrigin, RayDirection);
   Check( (not b1) and (not b2) ,'intersect with parallel plane');
  end else
  begin
   { nie wykonuj testu jesli wylosowalimy niepoprawne dane }
   if not TVector3.Equals(RayDirection, Vector3(0, 0, 0)) then
   begin
    b1 := TrySimplePlaneRayIntersection(I1, PlaneConstCoord, PlaneConstVal, RayOrigin, RayDirection);
    b2 := TryPlaneRayIntersection(I2, Plane, RayOrigin, RayDirection);
    AssertEquals(b1, b2);
    if b1 then
    begin
{     if not TVector3.Equals(I1, I2) or
        not SameValue(I1[PlaneConstCoord], PlaneConstVal) or
	not SameValue(I2[PlaneConstCoord], PlaneConstVal) then
     begin
      t1:=(PlaneConstVal-RayOrigin[PlaneConstCoord]) / RayDirection[PlaneConstCoord];
      t2 := -(plane[0]*RayOrigin[0] + plane[1]*RayOrigin[1] + plane[2]*RayOrigin[2] + plane[3])/
          TVector3.DotProduct(PlaneDir, RayDirection);
      Writeln('I1 = ',I1.ToString, ' I2 = ',I2.ToString, nl,
        'PlaneConst Coord = ',PlaneConstCoord, ' Value = ',PlaneConstVal, nl,
	'Plane = ',Plane.ToString, nl,
	'RayOrigin = ',RayOrigin.ToString, ' RayDirection = ',RayDirection.ToString, nl,
	t1:1:2, nl,
	t2:1:2, nl,
	(RayOrigin + RayDirection * t1).ToString, nl,
	(RayOrigin + RayDirection * t2).ToString
      );
     end; }
     AssertSameValue(PlaneConstVal, I1[PlaneConstCoord]);
     AssertSameValue(PlaneConstVal, I2[PlaneConstCoord]);
     AssertVectorEquals(I1, I2);
    end;
   end;
  end;
 end;

 { testuj szybkosc TrySimplePlaneRayIntersection w porownaniu z
   TryPlaneRayIntersection }
 WritelnSpeedTest('SPEED TEST 1 ----------------------------------------------');

 StartTime := ProcessTimer;
 for i := 1 to SPEED_TEST_1_CYCLES do ;
 Time0 := ProcessTimerSeconds(ProcessTimer, StartTime);
 WritelnSpeedTest(Format('Empty loop = %f',[Time0]));

 StartTime := ProcessTimer;
 for i := 1 to SPEED_TEST_1_CYCLES do
  TrySimplePlaneRayIntersection(I1, PlaneConstCoord, PlaneConstVal, RayOrigin, RayDirection);
 Time1 := ProcessTimerSeconds(ProcessTimer, StartTime);
 WritelnSpeedTest(Format('TrySimplePlaneRayIntersection = %f',[Time1]));

 StartTime := ProcessTimer;
 for i := 1 to SPEED_TEST_1_CYCLES do
  TryPlaneRayIntersection(I1, Plane, RayOrigin, RayDirection);
 Time2 := ProcessTimerSeconds(ProcessTimer, StartTime);
 WritelnSpeedTest(Format('TryPlaneRayIntersection = %f',[Time2]));

 {$ifdef VECTOR_MATH_SPEED_TESTS}
 { nie uzywam tutaj WritelnSpeedTest. Jesli VECTOR_MATH_SPEED_TESTS
   not defined to stale SPEED_TEST_x_CYCLES sa tak male ze nie moge
   wykonac dzielenia przez Time1-Time0 bo Time1-Time0 = 0. }
 Writeln(Format('SimplePlane is faster than Plane by %f', [(Time2-Time0)/(Time1-Time0)]));
 {$endif}

 WritelnSpeedTest('SPEED TEST 2 ----------------------------------------------');

 StartTime := ProcessTimer;
 for i := 1 to SPEED_TEST_2_CYCLES do ;
 Time0 := ProcessTimerSeconds(ProcessTimer, StartTime);
 WritelnSpeedTest(Format('Empty loop = %f',[Time0]));

 StartTime := ProcessTimer;
 for i := 1 to SPEED_TEST_2_CYCLES do
 begin
  V := VConst;
  V := V * Pi;
 end;
 Time1 := ProcessTimerSeconds(ProcessTimer, StartTime);
 WritelnSpeedTest(Format('Using assignment + VectorScaleVar = %f',[Time1]));

 StartTime := ProcessTimer;
 for i := 1 to SPEED_TEST_2_CYCLES do
 begin
  V := VConst * Pi;
 end;
 Time2 := ProcessTimerSeconds(ProcessTimer, StartTime);
 WritelnSpeedTest(Format('Using VectorScale = %f',[Time2]));

 {$ifdef VECTOR_MATH_SPEED_TESTS}
 { nie uzywam tutaj WritelnSpeedTest. Jesli VECTOR_MATH_SPEED_TESTS
   not defined to stale SPEED_TEST_x_CYCLES sa tak male ze nie moge
   wykonac dzielenia przez Time1-Time0 bo Time1-Time0 = 0. }
 Writeln(Format('Assignment+Var is faster by %f', [(Time2-Time0)/(Time1-Time0)]));
 {$endif}
end;

procedure TTestCastleVectors.TestVectorStr;

  procedure OneTestVectorFromStr;
  var v, v2: TVector3;
      s: string;
  begin
   v := RandomVector;
   s := v.ToRawString;
   v2 := Vector3FromStr(s);
   AssertVectorEquals(v2, v, 0.001); // larger epsilon for ppc64
  end;

  procedure OneTestByDeformat;
  var v, v2: TVector3;
      s: string;
  begin
   v := RandomVector;
   s := v.ToRawString;
   DeFormat(s, '%.single. %.single. %.single.', [@v2.Data[0], @v2.Data[1], @v2.Data[2]]);
   AssertVectorEquals(v2, v, 0.001); // larger epsilon for ppc64
  end;

const
  CYCLES = SPEED_TEST_3_CYCLES;
var
  Time0, Time1, Time2: Double;
  i: integer;
  StartTime: TProcessTimerResult;
begin
 WritelnSpeedTest('SPEED TEST VectorFromStr ------------------------------------------');
 StartTime := ProcessTimer;
 for i := 1 to CYCLES do ;
 Time0 := ProcessTimerSeconds(ProcessTimer, StartTime);
 WritelnSpeedTest(Format('Empty loop = %f',[Time0]));

 StartTime := ProcessTimer;
 for i := 1 to CYCLES do OneTestVectorFromStr;
 Time1 := ProcessTimerSeconds(ProcessTimer, StartTime);
 WritelnSpeedTest(Format('VectorFromStr = %f',[Time1]));

 StartTime := ProcessTimer;
 for i := 1 to CYCLES do OneTestByDeFormat;
 Time2 := ProcessTimerSeconds(ProcessTimer, StartTime);
 WritelnSpeedTest(Format('DeFormat = %f',[Time2]));

 {$ifdef VECTOR_MATH_SPEED_TESTS}
 { nie uzywam tutaj WritelnSpeedTest. Jesli VECTOR_MATH_SPEED_TESTS
   not defined to stale SPEED_TEST_x_CYCLES sa tak male ze nie moge
   wykonac dzielenia przez Time1-Time0 bo Time1-Time0 = 0. }
 Writeln(Format('VectorFromStr is faster by %f', [(Time2-Time0)/(Time1-Time0)]));
 {$endif}
end;

procedure TTestCastleVectors.TestMatrixInverse;
var
  M: TMatrix4;
begin
  M := ScalingMatrix(Vector3(2, 2, 2));

{ Tests:
  Writeln(M.ToString('  '));
  Writeln(ScalingMatrix(Vector3(0.5, 0.5, 0.5)).ToString('  '));
  Writeln(MatrixInverse(M, MatrixDeterminant(M)).ToString('  '));
}

  AssertMatrixEquals(
    ScalingMatrix(Vector3(0.5, 0.5, 0.5)),
    M.Inverse(M.Determinant),
    0.01);

  M := TranslationMatrix(Vector3(2, 2, 2));
  AssertMatrixEquals(
    TranslationMatrix(Vector3(-2, -2, -2)),
    M.Inverse(M.Determinant),
    0.01);
end;

procedure TTestCastleVectors.TestMultMatrixTranslation;
var
  M, NewM: TMatrix4;
  I: Integer;
  V: TVector3;
begin
  for I := 1 to 100 do
  begin
    M := RandomMatrix;
    V := RandomVector;
    NewM := M * TranslationMatrix(V);
    MultMatrixTranslation(M, V);
    AssertMatrixEquals(M, NewM, 0.001);
  end;
end;

procedure TTestCastleVectors.TestMultMatricesTranslation;
var
  M, NewM, MInverse, NewMInverse: TMatrix4;
  I: Integer;
  V: TVector3;
begin
  for I := 1 to 100 do
  begin
    M := RandomMatrix;
    if not M.TryInverse(MInverse) then
      MInverse := TMatrix4.Identity;

    V := RandomVector;
    NewM := M * TranslationMatrix(V);
    NewMInverse := TranslationMatrix(-V) * MInverse;
    MultMatricesTranslation(M, MInverse, V);
    AssertMatrixEquals(M, NewM, 0.001);
    AssertMatrixEquals(MInverse, NewMInverse, 0.001);
  end;
end;

procedure TTestCastleVectors.TestIndexedPolygonNormalArea;
const
  Poly: array [0..4] of TVector3 = (
    (Data: (5, 4, 0)),
    (Data: (4, 4, 0)),
    (Data: (2, 3, 0)),
    (Data: (2, 1, 0)),
    (Data: (6, 2, 0)) );
  CCWPolyIndex: array [0..6] of LongInt = (0, 1, 5, 2, 3, 4, 999);
  CWPolyIndex: array [0..6] of LongInt = (666, 4, 105, 3, 2, 1, 0);
begin
  AssertVectorEquals(
    Vector3(0, 0, 1),
    IndexedConvexPolygonNormal(@CCWPolyIndex, High(CCWPolyIndex) + 1,
      @Poly, High(Poly) + 1, TVector3.Zero));

  AssertVectorEquals(
    Vector3(0, 0, -1),
    IndexedConvexPolygonNormal(@CWPolyIndex, High(CWPolyIndex) + 1,
      @Poly, High(Poly) + 1, TVector3.Zero));

  AssertSameValue(8,
    IndexedConvexPolygonArea(@CCWPolyIndex, High(CCWPolyIndex) + 1,
      @Poly, High(Poly) + 1));

  AssertSameValue(8,
    IndexedConvexPolygonArea(@CWPolyIndex , High(CWPolyIndex) + 1,
      @Poly, High(Poly) + 1));
end;

procedure TTestCastleVectors.TestSphereRayIntersection;
var
  Res: boolean;
  I: TVector3;
begin
  Res := TrySphereRayIntersection(I, Vector3(3, 0, 0), 10,
    Vector3(0, 0, 0), Vector3(1, 0, 0));
  AssertTrue(Res);
  AssertVectorEquals(Vector3(13, 0, 0), I);

  Res := TrySphereRayIntersection(I, Vector3(3, 0, 0), 10,
    Vector3(0, 0, 0), Vector3(-1, 0, 0));
  AssertTrue(Res);
  AssertVectorEquals(Vector3(-7, 0, 0), I);

  Res := TrySphereRayIntersection(I, Vector3(3, 0, 0), 10,
    Vector3(20, 0, 0), Vector3(1, 0, 0));
  AssertFalse(Res);

  Res := TrySphereRayIntersection(I, Vector3(3, 0, 0), 10,
    Vector3(20, 0, 0), Vector3(-1, 0, 0));
  AssertTrue(Res);
  AssertVectorEquals(Vector3(13, 0, 0), I);
end;

{ global utils --------------------------------------------------------------- }

function RandomVector: TVector3;
begin
  result[0] := Random*1000;
  result[1] := Random*1000;
  result[2] := Random*1000;
end;

function RandomMatrix: TMatrix4;
var
  I, J: Integer;
begin
  for I := 0 to 3 do
    for J := 0 to 3 do
      Result.Data[I, J] := 50 - Random * 100;
end;

function RandomNonProjectionMatrix: TMatrix4;
var
  I, J: Integer;
begin
  for I := 0 to 3 do
    for J := 0 to 2 do
      Result.Data[I, J] := 50 - Random * 100;

  Result.Data[0, 3] := 0;
  Result.Data[1, 3] := 0;
  Result.Data[2, 3] := 0;
  Result.Data[3, 3] := 1;
end;

procedure TTestCastleVectors.TestMatrixMultiplication;
var
  M1, M2, M3, Result1, Result2: TMatrix4;
begin
  M1.Data[0] := Vector4(1, 0, 0, 0).Data;
  M1.Data[1] := Vector4(0, 1, 0, 0).Data;
  M1.Data[2] := Vector4(0, 0, 1, 0).Data;
  M1.Data[3] := Vector4(-0.31, 1.26, -0.03, 1).Data;

  M2.Data[0] := Vector4( 0.58,  0.75, 0.31, 0.00).Data;
  M2.Data[1] := Vector4(-0.81,  0.52, 0.26, 0.00).Data;
  M2.Data[2] := Vector4( 0.03, -0.40, 0.92, 0.00).Data;
  M2.Data[3] := Vector4( 0.00,  0.00, 0.00, 1.00).Data;

  M3.Data[0] := Vector4(1.00, 0.00, 0.00,  0.31).Data;
  M3.Data[1] := Vector4(0.00, 1.00, 0.00, -1.26).Data;
  M3.Data[2] := Vector4(0.00, 0.00, 1.00,  0.03).Data;
  M3.Data[3] := Vector4(0.00, 0.00, 0.00,  1.00).Data;

  Result1 := M1 * M2;
  Result2 := M1 * M2;
  AssertMatrixEquals(Result1, Result2, 0.1);

  Result2 := M1 * M2 * M3;

  Result1 := M1 * M2;
  Result1 := Result1 * M3;
  AssertMatrixEquals(Result1, Result2, 0.1);

  Result1 := M1 * M2 * M3;
  AssertMatrixEquals(Result1, Result2, 0.1);
end;

procedure TTestCastleVectors.TestMatrixTranspose;
var
  M1, M2: TMatrix3;
begin
  M1.Data[0] := Vector3(1, 2, 3).Data;
  M1.Data[1] := Vector3(4, 5, 6).Data;
  M1.Data[2] := Vector3(7, 8, 9).Data;

  M2.Data[0] := Vector3(1, 4, 7).Data;
  M2.Data[1] := Vector3(2, 5, 8).Data;
  M2.Data[2] := Vector3(3, 6, 9).Data;

  M1 := M1.Transpose;
  AssertTrue(TMatrix3.PerfectlyEquals(M1, M2));
end;

procedure TTestCastleVectors.TestVector3FromStr;
var
  V: TVector3;
begin
  try
    V := Vector3FromStr('1 2 abc');
    Fail('Above should fail with EConvertError');
  except on EConvertError do ; end;

  try
    V := Vector3FromStr('1 2 3 4');
    Fail('Above should fail with EConvertError');
  except on EConvertError do ; end;

  try
    V := Vector3FromStr('1 2');
    Fail('Above should fail with EConvertError');
  except on EConvertError do ; end;

  try
    V := Vector3FromStr('');
    Fail('Above should fail with EConvertError');
  except on EConvertError do ; end;

  V := Vector3FromStr('  11       22 ' + NL + ' 33    ');
  AssertSameValue(11, V[0]);
  AssertSameValue(22, V[1]);
  AssertSameValue(33, V[2]);
end;

procedure TTestCastleVectors.TestVector4FromStr;
var
  V: TVector4;
begin
  try
    V := Vector4FromStr('1 2 3 abc');
    Fail('Above should fail with EConvertError');
  except on EConvertError do ; end;

  try
    V := Vector4FromStr('1 2 3 4 5');
    Fail('Above should fail with EConvertError');
  except on EConvertError do ; end;

  try
    V := Vector4FromStr('1 2 3');
    Fail('Above should fail with EConvertError');
  except on EConvertError do ; end;

  try
    V := Vector4FromStr('');
    Fail('Above should fail with EConvertError');
  except on EConvertError do ; end;

  V := Vector4FromStr('  11       22 ' + NL + ' 33    44');
  AssertSameValue(11, V[0]);
  AssertSameValue(22, V[1]);
  AssertSameValue(33, V[2]);
  AssertSameValue(44, V[3]);
end;

procedure TTestCastleVectors.TestPlaneTransform;

  function PointLiesOnPlane(const Point: TVector3; const Plane: TVector4): boolean;
  var
    PlaneDir: TVector3 absolute Plane;
  begin
    // Writeln('point ', Point.ToString, ' gives ',
    //   (TVector3.DotProduct(Point, PlaneDir) + Plane[3]):1:2);
    Result := IsZero(TVector3.DotProduct(Point, PlaneDir) + Plane[3], 0.001);
  end;

  procedure DoTest(const Plane: TVector4; const Matrix: TMatrix4;
    const PointsYes: array of TVector3;
    const PointsNo: array of TVector3);
  var
    I: Integer;
    NewPlane: TVector4;
  begin
    NewPlane := PlaneTransform(Plane, Matrix);
    // Writeln('New plane ', NewPlane.ToString);
    for I := 0 to High(PointsYes) do
      AssertTrue(PointLiesOnPlane(PointsYes[I], NewPlane));
    for I := 0 to High(PointsNo) do
      AssertTrue(not PointLiesOnPlane(PointsNo[I], NewPlane));
  end;

begin
  { x = 0 plane }
  DoTest(Vector4(1, 0, 0, 0),
    TMatrix4.Identity,
    [ Vector3(0,  10,  10),
      Vector3(0, -10,  10),
      Vector3(0,  10, -10),
      Vector3(0, -10, -10) ],
    [ Vector3( 10,  10, 123),
      Vector3(-10,  10, 2),
      Vector3( 10, -10, -3),
      Vector3(1, 0, 0) ]);

  { rotate x = 0 plane to make z = 0 }
  DoTest(Vector4(1, 0, 0, 0),
    RotationMatrixDeg(90, 0, 1, 0),
    [ Vector3( 10,  10, 0),
      Vector3(-10,  10, 0),
      Vector3( 10, -10, 0),
      Vector3(-10, -10, 0) ],
    [ Vector3( 10,  10, 123),
      Vector3(-10,  10, 2),
      Vector3( 10, -10, -3),
      Vector3(0, 0, 1) ]);

  { rotate and move x = 0 plane to make z = 10 }
  DoTest(Vector4(1, 0, 0, 0),
    TranslationMatrix(Single(0), 0, 10) * RotationMatrixDeg(90, 0, 1, 0),
    [ Vector3( 10,  10, 10),
      Vector3(-10,  10, 10),
      Vector3( 10, -10, 10),
      Vector3(-10, -10, 10) ],
    [ Vector3( 10,  10, 0),
      Vector3(-10,  10, 0),
      Vector3( 10, -10, 0),
      Vector3(-10, -10, 0),
      Vector3( 10,  10, 123),
      Vector3(-10,  10, 2),
      Vector3( 10, -10, -3),
      Vector3(0, 0, 1) ]);

  { rotate and move and scale x = 0 plane to make z = 100 }
  DoTest(Vector4(1, 0, 0, 0),
    ScalingMatrix(Vector3(10, 10, 10)) *
    TranslationMatrix(Single(0), 0, 10) *
    RotationMatrixDeg(90, 0, 1, 0),
    [ Vector3( 10,  10, 100),
      Vector3(-10,  10, 100),
      Vector3( 10, -10, 100),
      Vector3(-10, -10, 100) ],
    [ Vector3( 10,  10, 10),
      Vector3(-10,  10, 10),
      Vector3( 10, -10, 0),
      Vector3(-10, -10, 0),
      Vector3( 10,  10, 123),
      Vector3(-10,  10, 2),
      Vector3( 10, -10, -3),
      Vector3(0, 0, 1) ]);
end;

procedure TTestCastleVectors.TestTransformToFromCoordsMatrix;
var
  M, MInverse: TMatrix4;
  NewOrigin, NewX, NewY, NewZ: TVector3;
begin
  NewOrigin := RandomVector;
  repeat NewX := RandomVector.Normalize until not NewX.IsZero;
  NewY := AnyOrthogonalVector(NewX).Normalize;
  NewZ := TVector3.CrossProduct(NewX, NewY);

  M        := TransformToCoordsMatrix  (NewOrigin, NewX, NewY, NewZ);
  MInverse := TransformFromCoordsMatrix(NewOrigin, NewX, NewY, NewZ);

  try
    AssertMatrixEquals(TMatrix4.Identity, M * MInverse, 0.01);
    AssertMatrixEquals(TMatrix4.Identity, MInverse * M, 0.01);
  except
    Writeln('Failed for origin=', NewOrigin.ToRawString,
      ' newX=', NewX.ToRawString);
    raise;
  end;
end;

procedure TTestCastleVectors.Test2D;
const
  P1: TVector3 = (Data: (1, 2, 3));
  P2: TVector3 = (Data: (2, 5, 13));
begin
  AssertSameValue(Sqr(1) + Sqr(3) + Sqr(10), PointsDistanceSqr(P1, P2), 0.01);
  AssertSameValue(Sqr(3) + Sqr(10), PointsDistance2DSqr(P1, P2, 0), 0.01);
  AssertSameValue(Sqr(1) + Sqr(10), PointsDistance2DSqr(P1, P2, 1), 0.01);
  AssertSameValue(Sqr(1) + Sqr(3), PointsDistance2DSqr(P1, P2, 2), 0.01);
  try
    PointsDistance2DSqr(P1, P2, 3);
    Fail('Above PointsDistance2DSqr with IgnoreIndex = 3 should raise exception');
  except end;
end;

procedure TTestCastleVectors.TestApproximateScale;
const
  Epsilon = 0.0001;
begin
  AssertSameValue(2, Approximate3DScale(2, 2, 2), Epsilon);
  AssertSameValue(-2, Approximate3DScale(-2, -2, -2), Epsilon);
  AssertSameValue(1, Approximate3DScale(1, 1, 1), Epsilon);
  AssertSameValue(-1, Approximate3DScale(-1, -1, -1), Epsilon);
  AssertSameValue(7/3, Approximate3DScale(1, 3, 3), Epsilon);
  AssertSameValue(-7/3, Approximate3DScale(-1, -3, -3), Epsilon);
  AssertSameValue(1, Approximate3DScale(-1, 1, 1), Epsilon);
end;

procedure TTestCastleVectors.TestXYZ;
const
  V2Const: TVector2 = (Data: (1, 2));
  V3Const: TVector3 = (Data: (1, 2, 3));
  V4Const: TVector4 = (Data: (1, 2, 3, 4));
var
  V2: TVector2;
  V3: TVector3;
  V4: TVector4;
begin
  V2 := V2Const;
  V3 := V3Const;
  V4 := V4Const;

  AssertEquals(1, V2.X);
  V2.X := 33;
  AssertEquals(33, V2.X);
  AssertEquals(2, V2.Y);

  AssertEquals(1, V3.X);
  AssertEquals(2, V3.Y);
  AssertEquals(3, V3.Z);
  V3.Z := 44;
  AssertEquals(1, V3.X);
  AssertEquals(2, V3.Y);
  AssertEquals(44, V3.Z);

  AssertEquals(1, V4.X);
  AssertEquals(2, V4.Y);
  AssertEquals(3, V4.Z);
  AssertEquals(4, V4.W);
end;

procedure TTestCastleVectors.TestPlaneMove;
var
  Plane: TVector4;
begin
  Plane := Vector4(1, 0, 0, 10); // x = -10
  AssertVectorEquals(Vector4(1, 0, 0, 9), PlaneMove(Plane, Vector3(1, 2, 3)));

  Plane := Vector4(1, 0, 0, 10); // x = -10
  PlaneMoveVar(Plane, Vector3(1, 2, 3));
  AssertVectorEquals(Vector4(1, 0, 0, 9), Plane);

  Plane := Vector4(0, 1, 0, 10); // y = -10
  AssertVectorEquals(Vector4(0, 1, 0, 8), PlaneMove(Plane, Vector3(1, 2, 3)));

  Plane := Vector4(0, 1, 0, 10); // y = -10
  PlaneMoveVar(Plane, Vector3(1, 2, 3));
  AssertVectorEquals(Vector4(0, 1, 0, 8), Plane);

  Plane := Vector4(0, 1, 0, 8); // y = -10
  AssertVectorEquals(Vector4(0, 1, 0, 10), PlaneAntiMove(Plane, Vector3(1, 2, 3)));
end;

procedure TTestCastleVectors.TestPlaneMoveRandom;
var
  I: Integer;
  Plane: TVector4;
  Move, PlaneDir: TVector3;
begin
  for I := 1 to 100 do
  begin
    repeat
      PlaneDir := RandomVector;
    until not PlaneDir.IsZero;
    Plane := Vector4(PlaneDir, Random * 100);
    Move := RandomVector;
    // "PlaneAntiMove + PlaneMove" should zero each other out
    AssertVectorEquals(Plane, PlaneAntiMove(PlaneMove(Plane, Move), Move), 1.0);
  end;
end;

initialization
  RegisterTest(TTestCastleVectors);
end.
