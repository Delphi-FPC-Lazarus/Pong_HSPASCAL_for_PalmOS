unit BitmapUtil;

{$R LogoImagesC.ro}

interface

procedure FullScreenBMP(iNr:integer);
procedure PaintBMP(iNr:integer; x,y:integer);

implementation

uses
  Window, Form, Menu, Rect, Event, SysEvent, SystemMgr, FloatMgr, HSUtils,
  TimeMgr, Preferences, SystemResources, Bitmap, DataMgr, MemoryMgr, Crt;

resource
  DlgResError=(ResTalt,,1,0,1,'Error','Resourcefehler!','Ok');

// ----------------------------------------------------

procedure FullScreenBMP(iNr:integer);
var
  bmpH: MemHandle;
  Bitmap: BitmapPtr;
  Err: Integer;
begin
  bmpH := DmGetResource( s2u32('Tbmp'), iNr);
  if bmpH=NIL then
  begin
   if frmAlert(DlgResError)=1 then
   begin
   end;
   exit;
  end;
  BitMap := BitMapPtr(MemHandleLock(bmpH));
  WinDrawBitMap(BitMap, 0,0);
  Err := MemHandleUnlock(bmpH);
  Err := DmReleaseResource(bmpH);
end;

// ----------------------------------------------------

procedure PaintBMP(iNr:integer; x,y:integer);
var
  bmpH: MemHandle;
  Bitmap: BitmapPtr;
  Err: Integer;
begin
  bmpH := DmGetResource( s2u32('Tbmp'), iNr);
  if bmpH=NIL then
  begin
   if frmAlert(DlgResError)=1 then
   begin
   end;
   exit;
  end;
  BitMap := BitMapPtr(MemHandleLock(bmpH));
  WinDrawBitMap(BitMap, x,y);
  Err := MemHandleUnlock(bmpH);
  Err := DmReleaseResource(bmpH);
end;

// ----------------------------------------------------

end.