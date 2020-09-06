unit Logo;

//{$DEFINE MC}

{$IFDEF MC}
 {$R LogoImagesM.ro}
{$ELSE]
 {$R LogoImagesC.ro}
{$ENDIF}

interface

procedure DisplayFullScreenIntro(iWait:integer);
procedure DisplayClear;
procedure DisplayBlack;

implementation

uses Form, Rect, Window, Crt,
     BitmapUtil;

// ----------------------------------------------------

procedure DisplayFullScreenIntro(iWait:integer);
var n:integer;
    FullRect:    RectangleType;
begin
  RctSetRectangle(FullRect,0,0,160,160);
  WinDrawRectangle(FullRect,1);

{$IFDEF MC}
  n:= 1001;
  while n < 1065 do
  begin
    FullScreenBMP(n);
    inc(n, 5);
  end;
{$ELSE}
  for n:= 1001 to 1069 do
  begin
    FullScreenBMP(n);
    delay(20);
  end;
{$ENDIF}

  if iWait > 0 then
   delay(iWait);

  WinEraseRectangle(FullRect,1);
  FrmDrawForm(FrmGetActiveForm);

end;

// ----------------------------------------------------

procedure DisplayBlack;
var
    FullRect:    RectangleType;
begin
  RctSetRectangle(FullRect,0,0,160,160);
  WinDrawRectangle(FullRect,1);
end;

// ----------------------------------------------------

procedure DisplayClear;
var
    FullRect:    RectangleType;
begin
  RctSetRectangle(FullRect,0,0,160,160);
  WinEraseRectangle(FullRect,1);
end;

// ----------------------------------------------------


end.