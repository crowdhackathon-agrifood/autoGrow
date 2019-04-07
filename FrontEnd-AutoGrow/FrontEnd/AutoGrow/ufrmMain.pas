unit ufrmMain;

interface

uses
{$IFDEF MSWINDOWS}
  Windows, FMX.Platform.Win,
{$ELSE IFDEF ANDROID}
  Androidapi.Helpers,
{$ENDIF}
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms3D, FMX.Types3D, FMX.Forms, FMX.Graphics,
  FMX.Dialogs, System.Math.Vectors, FMX.Objects3D, FMX.MaterialSources,
  FMX.Controls3D, System.Diagnostics, uCmd, FMX.Viewport3D {TODO: , udmMain, uTCP};

const
  MinGridPlaneElementDistance = 10;

type
  TfrmMain = class(TForm3D)
    tmrProcessTCP: TTimer;
    GridPlane: TGrid3D;
    lmsTree: TLightMaterialSource;
    lmsGrid: TLightMaterialSource;
    mdlTree: TModel3D;
    Model3D2: TModel3D;
    Model3D3: TModel3D;
    Model3D4: TModel3D;
    CameraLight: TLight;
    Camera: TCamera;
    tmrVelocity: TTimer;
    mdlTreeLeaves: TSphere;
    lmsTreeLeaves: TLightMaterialSource;
    StyleBook: TStyleBook;
    procedure Button1Click(Sender: TObject);
    procedure tmrProcessTCPTimer(Sender: TObject);
    procedure tmrVelocityTimer(Sender: TObject);
    procedure Form3DMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure Form3DMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure Form3DMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure Form3DMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure Form3DCreate(Sender: TObject);
    procedure mdlTreeMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
    procedure mdlTreeMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Single; RayPos, RayDir: TVector3D);
    procedure mdlTreeMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
  private
    TargetFrameRate: Single;
    SW: TStopwatch;
    PrevElapsed: Int64;

    MouseIsDown: Boolean;
    LastPosition: TPointF;
    Velocity: TPointF;
    FLastDistance: Integer;
    LastZ: Single;
    procedure UpdateCameraPosition;
    procedure UpdateGridPlaneBounds(aNewElementX, aNewElementY: Single);
    procedure FormClick(Sender: TObject);
    procedure ProcessGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
    procedure WaitVerticalRetrace;
  public
    function FormatFloatGeneric(aFloat: Single): RawByteString;
    procedure Log(aStr: string);
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

procedure TfrmMain.Form3DCreate(Sender: TObject);
var
  i: Integer;
begin
  Touch.InteractiveGestures := [TInteractiveGesture.Zoom, TInteractiveGesture.Pan, TInteractiveGesture.Rotate];
  OnGesture := ProcessGesture;

{$IFDEF ANDROID}
  TargetFrameRate := TAndroidHelper.Display.getRefreshRate;
  // tmrVelocity.Interval := Trunc (1000 / TargetFrameRate / 2);
  tmrVelocity.Interval := 10; // Make it tight
{$ELSE}
  TargetFrameRate := 60;
{$ENDIF}

  // TODO: pnlSettings.Mode := TMultiViewMode.Drawer;

  // Assign materials to our reference objects
  for i := 0 to High(mdlTree.MeshCollection) do
    mdlTree.MeshCollection[i].MaterialSource := lmsTree;
end;

procedure TfrmMain.WaitVerticalRetrace;
var
  Elapsed: Int64;
begin
  repeat
    Elapsed := SW.ElapsedTicks;
    if Elapsed - PrevElapsed < SW.Frequency / TargetFrameRate / 2 then
    begin
      // if TargetFrameRate > 200 then
      // Sleep(0)
      // else // Merely allow the system to context switch
      // if TargetFrameRate > 100 then
      // Sleep(1)
      // else
      // // Has jitter of almost 10 ms some times
      Sleep(500 * (PrevElapsed + Round(SW.Frequency / TargetFrameRate) - Elapsed) div SW.Frequency);
      // Sleep(1); // Has jitter of almost 10 ms some times
      // Sleep(0); // Has jitter of almost 10 ms some times
      Elapsed := SW.ElapsedTicks;
    end;
  until Elapsed - PrevElapsed >= SW.Frequency / TargetFrameRate;
  if (PrevElapsed <> 0) and (Elapsed - PrevElapsed <= 8 * SW.Frequency / TargetFrameRate) then
    Elapsed := PrevElapsed + Round(SW.Frequency / TargetFrameRate);
  // FPS := 1 / ((Elapsed - PrevElapsed) / SW.Frequency);
  PrevElapsed := Elapsed;
end;

procedure TfrmMain.tmrProcessTCPTimer(Sender: TObject);
begin
  // TODO: ProcessTCP;
end;

function TfrmMain.FormatFloatGeneric(aFloat: Single): RawByteString;
begin
  Result := RawByteString(FloatToStrF(aFloat, ffFixed, 7, 7, TFormatSettings.Invariant));
end;

procedure TfrmMain.Log(aStr: string);
begin
  // TODO: memLog.Lines.Add(aStr);
end;

procedure TfrmMain.mdlTreeMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
begin
  Form3DMouseDown(Sender, Button, Shift, X, Y);
end;

procedure TfrmMain.mdlTreeMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Single; RayPos, RayDir: TVector3D);
begin
  Form3DMouseMove(Sender, Shift, X, Y);
end;

procedure TfrmMain.mdlTreeMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
begin
  if True then  // Need to do something
  begin
    // TODO: Whatever one does clicking a tree
    Caption := IntToStr ((Sender as TComponent).Tag);
    MouseIsDown := False;
  end
  else
    // Continue as nothing happened
    Form3DMouseUp(Sender, Button, Shift, X, Y);
end;

procedure TfrmMain.ProcessGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
var
  Zoom: Single;
begin
  Handled := True;
  // if EventInfo.GestureID = igiPan then
  // Caption := 'handlePan(EventInfo)'
  // else
  if EventInfo.GestureID = igiZoom then
  begin
    if EventInfo.Distance = 0 then Exit;

    if not(TInteractiveGestureFlag.gfBegin in EventInfo.Flags) then
    begin
      Zoom := LastZ * FLastDistance / EventInfo.Distance;
      if (Zoom < -1) and (Zoom > -100) then
      begin
        Camera.Position.Z := Zoom;
        Camera.Position.Y := -Zoom;
      end;
    end
    else
    begin
      LastZ := Camera.Position.Z;
      FLastDistance := EventInfo.Distance;
    end;

  end
  // else if EventInfo.GestureID = igiRotate then
  // Caption := 'handleRotate(EventInfo)';
end;

procedure TfrmMain.UpdateCameraPosition;
begin
  if (Camera.Position.X + Velocity.X <= GridPlane.Width / 2) and (Camera.Position.X + Velocity.X >= -GridPlane.Width / 2) then
    Camera.Position.X := Camera.Position.X + Velocity.X;

  if (Camera.Position.Y + Velocity.Y <= GridPlane.Height / 2) and (Camera.Position.Y + Velocity.Y >= -GridPlane.Height / 2) then
    Camera.Position.Y := Camera.Position.Y + Velocity.Y;
end;

procedure TfrmMain.UpdateGridPlaneBounds(aNewElementX, aNewElementY: Single);
begin
  if GridPlane.Width / 2 - Abs(aNewElementX) < MinGridPlaneElementDistance then
    GridPlane.Width := GridPlane.Width + MinGridPlaneElementDistance * 2;

  if GridPlane.Height / 2 - Abs(aNewElementY) < MinGridPlaneElementDistance then
    GridPlane.Height := GridPlane.Height + MinGridPlaneElementDistance * 2;
end;

procedure TfrmMain.Form3DMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  MouseIsDown := True;
  LastPosition.X := X;
  LastPosition.Y := Y;
  Velocity := PointF(0, 0);
end;

procedure TfrmMain.Form3DMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  if MouseIsDown then
  begin
    Velocity.X := (X - LastPosition.X) / (Width / Camera.Position.Z);
    Velocity.Y := (Y - LastPosition.Y) / (Height / Camera.Position.Z);
    UpdateCameraPosition;
  end;

  LastPosition.X := X;
  LastPosition.Y := Y;
end;

procedure TfrmMain.Form3DMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  MouseIsDown := False;
  FormClick(Sender);
end;

procedure TfrmMain.FormClick(Sender: TObject);
var
  NewTree: TModel3D;
  RayDir, RayPos: TVector3D;
  Intersection: TPoint3D;
  i: Integer;
  // TreeID: Integer;
begin
  GridPlane.Context.Pick(LastPosition.X, LastPosition.Y, Camera.Projection, RayPos, RayDir);
  RayPos := TPoint3D(GridPlane.AbsoluteToLocalVector(RayPos));
  RayDir := GridPlane.AbsoluteToLocalDirection(RayDir);

  if GridPlane.RayCastIntersect(TPoint3D(RayPos), TPoint3D(RayDir), Intersection) then
    if { TODO: btnPlaceTree.IsPressed and } Velocity.IsZero then
    begin
      // TODO: TreeID := StrToInt (string (ExecCmd(cmdInsertTree, FormatFloatGeneric (Intersection.X) + ':' + FormatFloatGeneric (Intersection.Y))));
      // NewTree := TModel3D(mdlTree.Clone(Viewport));
      NewTree := TModel3D(mdlTree.Clone(Self));
      NewTree.OnMouseDown := mdlTreeMouseDown;
      NewTree.OnMouseUp := mdlTreeMouseUp;
      NewTree.OnMouseMove := mdlTreeMouseMove;
      for i := 0 to NewTree.ChildrenCount - 1 do
        if NewTree.Children.Items[i] is TShape3D then
        begin
          TShape3D (NewTree.Children.Items[i]).OnMouseDown := mdlTreeMouseDown;
          TShape3D (NewTree.Children.Items[i]).OnMouseUp := mdlTreeMouseUp;
          TShape3D (NewTree.Children.Items[i]).OnMouseMove := mdlTreeMouseMove;
        end;

      // TODO: NewTree.Tag := TreeID;
      NewTree.Tag := Random (1000);
      NewTree.Position.X := GridPlane.LocalToAbsolute3D(Intersection).X + 0.03;
      NewTree.Position.Y := GridPlane.LocalToAbsolute3D(Intersection).Y + 0.2;
      NewTree.Position.Z := GridPlane.LocalToAbsolute3D(Intersection).Z - 0.2;
      NewTree.Visible := True;
      // NewTree.Parent := ViewPort;
      NewTree.Parent := Self;
      UpdateGridPlaneBounds(NewTree.Position.X, NewTree.Position.Y);
      Self.Invalidate;
    end;
end;

procedure TfrmMain.tmrVelocityTimer(Sender: TObject);
begin
  tmrVelocity.Enabled := False;
  try
{$IFDEF MSWINDOWS}
    while not Application.Terminated do
{$ENDIF}
    begin
      Velocity := (4 * TargetFrameRate - 1) * Velocity / (4 * TargetFrameRate);
      UpdateCameraPosition;
      Application.ProcessMessages;
      WaitVerticalRetrace;
    end;
  finally
    tmrVelocity.Enabled := True;
  end;
end;

procedure TfrmMain.Form3DMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
var
  Zoom: double;
begin
  Zoom := Camera.Position.Z * WheelDelta / 1024;
  if Camera.Position.Z - Zoom < -1 then
  begin
    Camera.Position.Z := Camera.Position.Z - Zoom;
    Camera.Position.Y := Camera.Position.Y + Zoom;
  end;

  Handled := True;
end;

procedure TfrmMain.Button1Click(Sender: TObject);
begin
  // TODO: Log(string(ExecCmd(1, 'This is Data')));
end;

end.
