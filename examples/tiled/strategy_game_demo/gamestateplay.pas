{
  Copyright 2018-2018 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Display the game map, play the game. }
unit GameStatePlay;

interface

uses CastleUIState, CastleControls, CastleTiledMap, CastleUIControls,
  CastleVectors, CastleKeysMouse,
  GameUnit;

type
  TStatePlay = class(TUIState)
  strict private
    MapControl: TCastleTiledMapControl;
    ButtonQuit: TCastleButton;
    ButtonInstructions: TCastleButton;
    ButtonEndTurn: TCastleButton;
    LabelStatus, LabelTurnStatus: TCastleLabel;
    TileUnderMouseImage: TCastleImageControl;
    TileUnderMouseExists: Boolean;
    TileUnderMouse: TVector2Integer;
    UnitsOnMap: TUnitsOnMap;
    HumanTurn: Boolean;
    SelectedUnit: TUnit;
    procedure ClickQuit(Sender: TObject);
    procedure ClickInstructions(Sender: TObject);
    procedure ClickEndTurn(Sender: TObject);
    procedure MapPress(const Sender: TInputListener;
      const Event: TInputPressRelease; var Handled: Boolean);
    procedure UpdateTurnStatus;
  public
    { Set this before starting this state. }
    MapName: String;
    procedure Start; override;
    procedure Stop; override;
    procedure Update(const SecondsPassed: Single;
      var HandleInput: Boolean); override;
  end;

var
  StatePlay: TStatePlay;

implementation

uses SysUtils, Classes,
  CastleComponentSerialize, CastleUtils, CastleRectangles,
  GameStateMainMenu, GameStateInstructions, GameStateWin;

procedure TStatePlay.Start;

  procedure PlaceInitialUnits;

    procedure AddUnit(const Kind: TUnitKind; const XBegin, XEnd, YBegin, YEnd: Integer);
    const
      MaxTries = 50;
    var
      I: Integer;
      Pos: TVector2Integer;
      Un: TUnit;
    begin
      { Choose a random position, within given X and Y ranges.
        Since we may play on various map sizes, with various rivers
        --- prepare that the units may not fit, and resign after MaxTries
        from adding a new unit. }
      for I := 1 to MaxTries do
      begin
        Pos.X := RandomIntRangeInclusive(XBegin, XEnd);
        Pos.Y := RandomIntRangeInclusive(YBegin, YEnd);
        if (UnitsOnMap[Pos] = nil) and
           (not UnitsOnMap.IsWater(Pos)) then
        begin
          Un := TUnit.Create(FreeAtStop);
          Un.TilePosition := Pos;
          Un.Initialize(UnitsOnMap, Kind);
          MapControl.InsertFront(Un.Ui);
          Exit;
        end;
      end;
    end;

  var
    I, W, H, YBegin, YEnd: Integer;
  begin
    W := MapControl.Map.Width;
    H := MapControl.Map.Height;
    YBegin := H div 3;
    YEnd := H - 1 - H div 3;

    for I := 0 to 2 do
      AddUnit(ukAlienHeavy, W div 8 + 0, W div 8 + 0, YBegin, YEnd);
    for I := 0 to 3 do
      AddUnit(ukAlienLight, W div 8 + 2, W div 8 + 2, YBegin, YEnd);
    for I := 0 to 2 do
      AddUnit(ukHumanHeavy, W - 1 - W div 8 - 0, W - 1 - W div 8 - 0, YBegin, YEnd);
    for I := 0 to 3 do
      AddUnit(ukHumanLight, W - 1 - W div 8 - 2, W - 1 - W div 8 - 2, YBegin, YEnd);
  end;

var
  UiOwner: TComponent;
begin
  inherited;

  { Load designed user interface }
  InsertUserInterface('castle-data:/state_play.castle-user-interface', FreeAtStop, UiOwner);

  // find components in designed user interface
  MapControl := UiOwner.FindRequiredComponent('MapControl') as TCastleTiledMapControl;
  ButtonQuit := UiOwner.FindRequiredComponent('ButtonQuit') as TCastleButton;
  ButtonInstructions := UiOwner.FindRequiredComponent('ButtonInstructions') as TCastleButton;
  ButtonEndTurn := UiOwner.FindRequiredComponent('ButtonEndTurn') as TCastleButton;
  LabelStatus := UiOwner.FindRequiredComponent('LabelStatus') as TCastleLabel;
  LabelTurnStatus := UiOwner.FindRequiredComponent('LabelTurnStatus') as TCastleLabel;

  MapControl.URL := 'castle-data:/maps/' + MapName + '.tmx';
  MapControl.OnPress := @MapPress;
  ButtonQuit.OnClick := @ClickQuit;
  ButtonInstructions.OnClick := @ClickInstructions;
  ButtonEndTurn.OnClick := @ClickEndTurn;

  UnitsOnMap := TUnitsOnMap.Create(FreeAtStop, MapControl);

  PlaceInitialUnits;

  TileUnderMouseImage := TCastleImageControl.Create(FreeAtStop);
  TileUnderMouseImage.Stretch := true;
  case MapControl.Map.Orientation of
    moOrthogonal: TileUnderMouseImage.URL := 'castle-data:/tile_hover/orthogonal.png';
    moHexagonal : TileUnderMouseImage.URL := 'castle-data:/tile_hover/hexagonal.png';
    else          TileUnderMouseImage.URL := 'castle-data:/tile_hover/isometric.png';
  end;
  TileUnderMouseImage.Exists := false;
  MapControl.InsertFront(TileUnderMouseImage);

  HumanTurn := true;
  UpdateTurnStatus;
end;

procedure TStatePlay.Stop;
begin
  { Make sure to clear fields, otherwise stopping + starting this state again
    (when you exit the game and start a new game) could have non-nil but
    invalid SelectedUnit reference. }
  TileUnderMouseExists := false;
  SelectedUnit := nil;
  inherited;
end;

procedure TStatePlay.ClickQuit(Sender: TObject);
begin
  TUIState.Current := StateMainMenu;
end;

procedure TStatePlay.ClickInstructions(Sender: TObject);
begin
  TUIState.Push(StateInstructions);
end;

procedure TStatePlay.ClickEndTurn(Sender: TObject);

  procedure ResetMovement;
  var
    I: Integer;
  begin
    for I := 0 to UnitsOnMap.UnitsCount - 1 do
      UnitsOnMap.Units[I].Movement := UnitsOnMap.Units[I].InitialMovement;
  end;

begin
  HumanTurn := not HumanTurn;
  SelectedUnit := nil;
  ResetMovement;
  UpdateTurnStatus;
end;

procedure TStatePlay.MapPress(const Sender: TInputListener;
  const Event: TInputPressRelease; var Handled: Boolean);

  procedure CheckWin;
  var
    FoundEnemy: Boolean;
    I: Integer;
  begin
    FoundEnemy := false;
    for I := 0 to UnitsOnMap.UnitsCount - 1 do
      if UnitsOnMap.Units[I].Human <> HumanTurn then
      begin
        FoundEnemy := true;
        Break;
      end;

    if not FoundEnemy then
    begin
      StateWin.HumansWin := HumanTurn;
      TUIState.Push(StateWin);
    end;
  end;

var
  UnitUnderMouse: TUnit;
begin
  if Event.IsMouseButton(buttonLeft) and TileUnderMouseExists then
  begin
    Handled := true;
    UnitUnderMouse := UnitsOnMap[TileUnderMouse];
    if (UnitUnderMouse <> nil) and (UnitUnderMouse.Human = HumanTurn) then
    begin
      // select new unit
      SelectedUnit := UnitUnderMouse;
      UpdateTurnStatus;
    end else
    if (SelectedUnit <> nil) and
       // CanMove also checks that SelectedUnit.Movement > 0
       (SelectedUnit.CanMove(TileUnderMouse)) then
    begin
      if UnitUnderMouse <> nil then
      begin
        // hurt enemy UnitUnderMouse.
        UnitUnderMouse.Life := UnitUnderMouse.Life - SelectedUnit.Attack;
        // Above operation *maybe* freed and removed enemy from the map,
        // so UnitUnderMouse pointer afterwards is no longer valid.
        UnitUnderMouse := nil;
        SelectedUnit.Movement := 0;
        CheckWin;
      end else
      begin
        // move
        SelectedUnit.TilePosition := TileUnderMouse;
        SelectedUnit.Movement := SelectedUnit.Movement - 1;
      end;
    end;
  end;
end;

procedure TStatePlay.UpdateTurnStatus;
var
  SideName: String;
begin
  if HumanTurn then
    SideName := 'Human'
  else
    SideName := 'Alien';
  LabelTurnStatus.Caption := SideName + ' Turn';
  LabelTurnStatus.Text.Add(''); // newline

  if SelectedUnit <> nil then
  begin
    LabelTurnStatus.Text.Add('Selected: ' + SelectedUnit.ToString);
    LabelTurnStatus.Text.Add('Move or attack');
    LabelTurnStatus.Text.Add('  or select another ' + SideName + ' unit');
    LabelTurnStatus.Text.Add('  or press "End Turn".');
  end else
  begin
    LabelTurnStatus.Text.Add('No unit selected.');
    LabelTurnStatus.Text.Add('Select ' + SideName + ' unit');
    LabelTurnStatus.Text.Add('  or press "End Turn".');
  end;
end;

procedure TStatePlay.Update(const SecondsPassed: Single;
  var HandleInput: Boolean);
var
  TileStr: String;
  TileRect: TFloatRectangle;
  UnitUnderMouse: TUnit;
begin
  { update TileUnderMouseExists, TileUnderMouse }
  TileUnderMouseExists := MapControl.PositionToTile(
    Container.MousePosition, true, TileUnderMouse);

  { update TileUnderMouseImage, UnitUnderMouse }
  TileUnderMouseImage.Exists := TileUnderMouseExists;
  if TileUnderMouseExists then
  begin
    TileRect := MapControl.TileRectangle(TileUnderMouse, false);
    TileUnderMouseImage.Left := TileRect.Left;
    TileUnderMouseImage.Bottom := TileRect.Bottom;
    TileUnderMouseImage.Width := TileRect.Width;
    TileUnderMouseImage.Height := TileRect.Height;
    UnitUnderMouse := UnitsOnMap[TileUnderMouse];
  end else
    UnitUnderMouse := nil;

  { update TileUnderMouseImage.Color }
  if SelectedUnit = nil then
    TileUnderMouseImage.Color := Vector4(1, 1, 1, 0.75)
  else
  if SelectedUnit.CanMove(TileUnderMouse) then
    // can move by clicking here
    TileUnderMouseImage.Color := Vector4(0, 1, 0, 0.75)
  else
  if (UnitUnderMouse <> nil) and
     (UnitUnderMouse.Human = HumanTurn) then
    // can select by clicking here
    TileUnderMouseImage.Color := Vector4(1, 1, 1, 0.75)
  else
    // cannot do anything by clicking here
    TileUnderMouseImage.Color := Vector4(1, 0, 0, 0.75);

  { update LabelStatus }
  if TileUnderMouseExists then
  begin
    TileStr := TileUnderMouse.ToString;
    if UnitsOnMap.IsWater(TileUnderMouse) then
      TileStr += NL + ' Water';
    if UnitUnderMouse <> nil then
      TileStr += NL + ' Unit: ' + UnitUnderMouse.ToString;
  end else
    TileStr := 'none';
  LabelStatus.Caption := Format('FPS: %s' + NL + 'Tile: %s', [
    Container.Fps.ToString,
    TileStr
  ]);
end;

end.
