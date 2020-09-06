//
// Pong (Spiel) Implementierung by YvoPet
// HSPascal 2.1.0 Compiler, PalmOS 3.5 oder höher
//
// Es ist für den Cache weder hilfreich noch nötig diesen Code zu lesen,
// ihr werdet die Koordinaten hier nicht finden! (die sind "ausgelagert")
// Die Veröffentlichung des Codes ist nur als Info für alle Technik-Interessierten gedacht.
//
// History
// -------
// 26.01.2014 v1.00 erstellt, Spielparameter müssen noch eingestellt werden
// 02.03.2014 v1.01 Spielparameter auf Hardware eingestellt
// 12.07.2014 v1.02 Startlogo implementiert
// 07.06.2015 v1.03 Start-/SpielCounter implementiert
// 14.09.2018 v1.04 Monochrome Compilerswitch
// 26.03.2019 v1.05 Nacharbeit zum Einbinden der Logoresource

Program Pong;

//{$DEFINE MC}

{$SearchPath Units; Units\UI; Units\System}
{$ApplName Pong,YVOPET}
// YVOPET is a referenced PalmOS CreatorID (http://dev.palmos.com/creatorid/)

Uses
  Window, Form, Menu, Rect, Event, SysEvent, SystemMgr, FloatMgr, HSUtils,
  TimeMgr, Preferences, SystemResources, Crt, Chars, SoundMgr, KeyMgr,
  TextConsts, Util, Eventhandler, BitmapUtil, Logo;

// ----------------------------------------------------

Resource
  (*
  MenuRes=(ResMBAR,,
    (ResMPUL,(6,14,90,38),(4,0,35,12),'Spiel',
      MenuNewGame=(,'N','Neu Starten')),
    (ResMPUL,(42,14,70,38),(40,0,30,12),'?',
      MenuAbout=(,'I','Info'))
          );
  *)

  MainForm=(ResTFRM,1000,(0,0,160,160),0,0,0(*MenuRes*), (FormTitle,'Geocache by YvoPet'),
    MainSButton=(FormButton,,(16,145,36,12),,,,'Sissi'),
    MainNButton=(FormButton,,(60,145,36,12),,,,'Normal'),
    MainPButton=(FormButton,,(104,145,36,12),,,,'Profi')
           );

// Achtung: Dialog regulär nicht verwenden, ermöglichen das herausspringen aus der Anwendung
//          da dort der normale eventhandler ohne filter greift

//  DlgDebug1  = (ResTalt,,1,0,1,'Debug','Debug Haltepunkt 1','Ok');
//  DlgDebug2  = (ResTalt,,1,0,1,'Debug','Debug Haltepunkt 2','Ok');
//  DlgDebug3  = (ResTalt,,1,0,1,'Debug','Debug Haltepunkt 3','Ok');

// ----------------------------------------------------

type RGameMode=(gmEasy,gmNormal,gmHard);
     RGameState=(gsStart,gsRun,gsLoose,gsWon);

// Programm -------

const sVersion = 'v1.05       ';
      iinfpos  = 120;

var WorkRect:    RectangleType;
    wt,wb,wr,wl: Integer;

    MyMenu:      MenuBarPtr;
    GameMode:    RGameMode;
    GameState:   RGameState;

    LastBatteryupdate: UInt32;
    StartCount:        UInt32;
    PlayCount:         UInt32;

// - Spiel -----------

const itimer       = 10;
      ksize        = 6;
      Padelsize    = 25;
      Padelwidth   = 3;
      xPadelUser   = 153;
      xPadelPC     = 4;

      // Punktestand
var   iPunktePC     : Integer;
      iPunkteUser   : Integer;

      // Padel
      x,y,xold,yold            : real;
      xi,yi                    : real;
      PadelincUser             : real;
      PadelincPC               : real;
      yPadelUser,yPadelUserold : real;
      yPadelPC,yPadelPCold     : real;
      PadelPCflag              : Boolean;
      GlobForceRepaint         : Boolean;

// - Hilfsfunktionen ------------------------------------

Function InWorkRect(var Event: EventType): Boolean;
begin
  with Event do
    InWorkRect:= RctPtInRectangle(ScreenX, ScreenY, WorkRect);
end;

Function RandomBool:Boolean;
var t:integer;
begin
  t:= random(100);
  if t > 50 then
   RandomBool:= true
  else
   RandomBool:= false;
end;

// - Visualisierung -------------------------------------

procedure VisuSpielFeld;
begin
  // - Spielfeld -

  WinEraseRectangle(WorkRect, 1);
  WinDrawChars(sVersion, length(sVersion), iInfPos, 0);

  {$IFNDEF MC}
  if WinSetForeColor(255)>0 then begin end;
  //if WinSetBackColor(0)>0 then begin end;
  {$ENDIF}

  // oben/unten
  WinDrawLine(wl+1,wt+1,wr-1,wt+1);
  WinDrawLine(wl+1,wb-1,wr-1,wb-1);

  // links+rechts
  WinDrawLine(wl+1,wt+1,wl+1,wb-1);
  WinDrawLine(wr-1,wt+1,wr-1,wb-1);
end;

procedure VisuPunkte;
var sAnz:String;
begin
  // Punkte einstellig 0-9 (bei 10 ist ja eh ende), mittig anzeigen
  sAnz:= inttostr(iPunktePC)+' / '+inttostr(iPunkteUser);
  WinDrawChars(sAnz, length(sAnz), 70, 20);

  sAnz:= 'Ich   Du';
  WinDrawChars(sAnz, length(sAnz), 65, 30);

end;

procedure VisuGame(bForceRepaint:boolean);
var rect:RectangleType;
begin
  // Ball
  if bForceRepaint or
     (abs(x-xold)>=0.1) or
     (abs(y-yold)>=0.1) then
  begin
    // "ball" löschen
    {$IFNDEF MC}
    //if WinSetForeColor(0)>0 then begin end;
    {$ENDIF}
    RctSetRectangle(Rect, round(xold-ksize div 2), round(yold-ksize div 2),ksize,ksize);
    WinEraseRectangle(Rect,1);

    // "ball" zeichnen
    {$IFNDEF MC}
    if WinSetForeColor(100)>0 then begin end;
    {$ENDIF}
    RctSetRectangle(Rect, round(x-ksize div 2), round(y-ksize div 2),ksize,ksize);
    WinDrawRectangle(Rect,1);
  end;

  // PC Padel (links)
  if bForceRepaint or
     (abs(yPadelPC-yPadelPCold)>=0.1) or
     (xold-ksize div 2 <= xPadelPC+PadelWidth) then
  begin
    // PC Padel löschen
    {$IFNDEF MC}
    if WinSetForeColor(0)>0 then begin end;
    {$ENDIF}
    RctSetRectangle(Rect, xPadelPC, round(yPadelPCold-Padelsize/2), Padelwidth, Padelsize);
    WinEraseRectangle(Rect,1);

    // PC Padel zeichnen
    {$IFNDEF MC}
    if WinSetForeColor(110)>0 then begin end;
    {$ENDIF}
    RctSetRectangle(Rect, xPadelPC, round(yPadelPC-Padelsize/2), Padelwidth, Padelsize);
    WinDrawRectangle(Rect,1);
  end;

  // User Padel (rechts)
  if bForceRepaint or
     (abs(yPadelUser-yPadelUserold)>=0.1) or
     (xold+ksize div 2 >= xPadelUser) then
  begin
    // User Padel löschen
    {$IFNDEF MC}
    if WinSetForeColor(0)>0 then begin end;
    {$ENDIF}
    RctSetRectangle(Rect, xPadelUser, round(yPadelUserold-Padelsize/2), Padelwidth, Padelsize);
    WinEraseRectangle(Rect,1);

    // User Padel zeichnen
    {$IFNDEF MC}
    if WinSetForeColor(110)>0 then begin end;
    {$ENDIF}
    RctSetRectangle(Rect, xPadelUser, round(yPadelUser-Padelsize/2), Padelwidth, Padelsize);
    WinDrawRectangle(Rect,1);
  end;

end;

procedure VisuBattery;
var sBatteryInfo:string;
begin
  // Update und Visualisierung
  sBatteryInfo:= 'Akkustatus: ' + GetBatteryInfo; // + ' / ' + inttostr(StartCount) + ' / ' + inttostr(PlayCount) + '         ';
  WinDrawChars(sBatteryInfo, length(sBatteryinfo), 1, 20);
end;

procedure VisuStartScreen;
begin

      WinEraseRectangle(WorkRect, 1);

      WinDrawChars(sVersion, length(sVersion), iInfPos, 0);
      VisuBattery;
      //Akkustatus (erste Zeile) automatisch, trotzdem hier gleich anzeigen (programmstart)

      WinDrawChars(sstart, length(sstart), 16, 50);
      WinDrawChars(sanweisung1, length(sanweisung1), 16, 70);
      WinDrawChars(sanweisung2, length(sanweisung2), 16, 82);
      WinDrawChars(sanweisung3, length(sanweisung3), 16, 94);

      WinDrawChars(sSchwierigkeit, length(sSchwierigkeit), 16, 130);

end;

// - Spiel (Start) --------------------------------------

Procedure startgame(resetpoints:boolean);
var i:integer;
    iTmp:integer;
    sdebug:string;
begin
  if resetpoints then
    inc(PlayCount);

  VisuSpielFeld;

  GameState:= gsStart;

  // - Spielvariablen -

  // Ball Position
  x:= 20; // weit links, dann muss xi beim start aber immer positiv sein
  y:= workrect.topleft.y+ksize*2+random(workrect.extent.y-ksize*4);
  xold:= x;
  yold:= y;

  // Bewegung je Zyklus definieren
  case Gamemode of
   gmEasy:   begin
              xi:= 0.5;
              yi:= 1;
              if randombool=true then yi:= -yi;
              //if randombool=true then xi:= -xi; // immer zum Spieler
              PadelincUser:= 6;
              PadelincPC:= 3;     // siehe dogamelogic, sonst trifft der PC nie da bei diesem Gamemode nur einfache Padelbewegung
             end;
   gmNormal: begin
              xi:= 0.7;
              yi:= 1.0;
              if randombool=true then yi:= -yi;
              //if randombool=true then xi:= -xi; // immer zum Spieler
              PadelincUser:= 6;
              PadelincPC:= 0.7;  // siehe dogamelogic
             end;
   gmHard:   begin
              xi:= 0.7;
              yi:= 1.5;
              if randombool=true then yi:= -yi;
              //if randombool=true then xi:= -xi; // immer zum Spieler
              PadelincUser:= 6;
              PadelincPC:= 0.9;  // siehe dogamelogic
             end;
  end;

  // Punktestand anzeigen
  if resetpoints=true then
  begin
    iPunktePC:=   0;
    iPunkteUser:= 0;
  end;
  VisuPunkte;

  // Padel Positionen
  yPadelUser:= (wt+(wb-wt) div 2);
  yPadelUserold:= yPadelUser;
  yPadelPC:= (wt+(wb-wt) div 2);
  yPadelPCold:= yPadelPC;
  PadelPCflag:= false;

  VisuGame(true);

  Delay(1000);

  Dosound(1000,250);
  Delay(750);
  Dosound(1000,250);
  Delay(750);
  Dosound(1000,250);
  Delay(750);
  Dosound(2000,1000);

  VisuSpielFeld;
  VisuGame(true);

  FlushEvents;
  GameState:= gsRun;
end;

// - Spiel (Laufzeit) -----------------------------------

procedure DoGameEndeLoose;
begin
     DoSound(600,50);
     DoSound(500,50);
     DoSound(400,50);
     DoSound(300,500);

     WinEraseRectangle(WorkRect, 1);

     WinDrawChars(sVersion, length(sVersion), iInfPos, 0);
     //Akkustatus (erste Zeile) automatisch

     WinDrawChars(sloose, length(sloose), 16, 50);
     WinDrawChars(sanweisung1, length(sanweisung1), 16, 70);
     WinDrawChars(sanweisung2, length(sanweisung2), 16, 80);
     WinDrawChars(sanweisung3, length(sanweisung3), 16, 90);

     GameState:= gsLoose;
     exit;

end;

procedure DoGameEndeWon;
begin
     DoSound(600,50);
     DoSound(800,50);
     DoSound(1000,50);
     DoSound(1200,500);

     WinEraseRectangle(WorkRect, 1);

     WinDrawChars(sVersion, length(sVersion), iInfPos, 0);
     //Akkustatus (erste Zeile) automatisch

     WinDrawChars(swon1, length(swon1), 16, 40);
     WinDrawChars(swon2, length(swon2), 16, 50);
     WinDrawChars(swon3, length(swon3), 16, 60);

     WinDrawChars(swon4, length(swon4), 16, 80);
     WinDrawChars(swon5, length(swon5), 16, 90);
     WinDrawChars(swon6, length(swon6), 16, 100);

     gamestate:= gsWon;
     exit;

end;

procedure DoGameLogic;
//var sdebug:string;
begin

    //sdebug:= inttostr(t)+'/'+inttostr(b)+'/'+inttostr(l)+'/'+inttostr(r);
    //sdebug:= inttostr(x)+'/'+inttostr(y);
    //WinDrawChars(sdebug, length(sdebug), 50, 0);

    if (xi = 0) or (yi = 0) then exit; // Fehlerfall

    // Ball bewegen
    x:= x+xi;
    y:= y+yi;

    // Computer Padel mit bewegen
    if GameMode = gmEasy then
    begin
     // dumm
     if PadelPCflag then
     begin
       if yPadelPC - Padelsize div 2 > wt + PadelincPC then
        yPadelPC:= yPadelPC-PadelincPC
       else
        PadelPCflag:= not PadelPCflag;
     end
     else
     begin
       if yPadelPC + Padelsize div 2 < wb - PadelincPC then
        yPadelPC:= yPadelPC+PadelincPC
       else
        PadelPCflag:= not PadelPCflag;
     end;
    end
    else
    begin
     // interaktiv
     // Einschränkung wann sich der PC bewegen darf, sonst hat man keine Chance
     if (x <= wr div 2) and (xi < 0) then
     begin
      if y < yPadelPC then
      begin
       if yPadelPC - Padelsize div 2 > wt + PadelincPC then
        yPadelPC:= yPadelPC-PadelincPC;
      end;
      if y > yPadelPC then
      begin
       if yPadelPC + Padelsize div 2 < wb - PadelincPC then
        yPadelPC:= yPadelPC+PadelincPC;
      end;
     end;
    end;

    // Wand unten
    if (yi > 0) and (y >= wb-2-ksize div 2) then
    begin
     yi:= -yi;
     dosound(400,10);
     GlobForceRepaint:= true;
     exit;
    end;
    // Wand oben
    if (yi < 0) and (y <= wt+3+ksize div 2) then
    begin
     yi:= -yi;
     dosound(400,10);
     GlobForceRepaint:= true;
     exit;
    end;

    // Padel rechts (User)
    if (xi > 0) and (x + ksize div 2 >= xPadelUser - PadelWidth div 2 - abs(xi)) then
    begin
     if (y >= (yPadelUser-Padelsize div 2-ksize div 2)) and  // Oberkannte
        (y <= (yPadelUser+Padelsize div 2+ksize div 2)) then // Unterkannte
     begin
       // Normal
       xi:= -xi;
       if ( (yi > 0) and (y <= (yPadelUser-Padelsize div 2+ksize div 2) ) ) then // Ecke oben
         yi:= -yi; // zusätzlich yi invertieren
       if ( (yi < 0) and (y >= (yPadelUser+Padelsize div 2-ksize div 2) ) ) then // Ecke unten
         yi:= -yi; // zusätzlich yi invertieren
       dosound(600,10);
       GlobForceRepaint:= true;
       exit;
     end;
    end;

    // Padel links (PC)
    if (xi < 0) and (x - ksize div 2 <= xPadelPC + PadelWidth div 2 + abs(xi) ) then
    begin
     if (y >= (yPadelPC-Padelsize div 2-ksize div 2)) and  // Oberkannte
        (y <= (yPadelPC+Padelsize div 2+ksize div 2)) then // Unterkannte
     begin
       // Normal
       xi:= -xi;
       if ( (yi > 0) and (y <= (yPadelPC-Padelsize div 2+ksize div 2) ) ) then // Ecke oben
         yi:= -yi; // zusätzlich yi invertieren
       if ( (yi < 0) and (y >= (yPadelPC+Padelsize div 2-ksize div 2) ) ) then // Ecke unten
         yi:= -yi; // zusätzlich yi invertieren
       dosound(600,10);
       GlobForceRepaint:= true;
       exit;
     end;
    end;

    // Wand rechts
    if (xi > 0) and (x >= wr-3-ksize div 2) then
    begin
     dosound(100,50);
     delay(10);
     dosound(100,50);
     delay(10);
     inc(ipunktePC);
     if iPunktePC > 9 then
      DoGameEndeLoose
     else
      startgame(false);
     exit;
    end;

    // Wand links
    if (xi < 0) and (x <= wl+3+ksize div 2) then
    begin
     dosound(100,50);
     delay(10);
     dosound(100,50);
     delay(10);
     inc(ipunkteUser);
     if iPunkteUser > 9 then
      DoGameEndeWon
     else
      startgame(false);
     exit;
    end;

end;

// ----------------------------------------------------

Function HandleEvent(var Event: EventType): Boolean;
var
  N: Integer;
  OldMenu: Pointer;
  PForm: FormPtr;

  CurX: Integer;
  CurY: Integer;

begin
  HandleEvent:=False;

  with Event do
  Case eType of
  // ----------
  frmLoadEvent:
    begin
      PForm:=FrmInitForm(data.frmLoad.FormID);
      FrmSetActiveForm(PForm); //Load the Form resource
      FrmSetEventHandlerNONE(PForm); //Is in Form.pas

      HandleEvent:= true;
    end;
  frmOpenEvent: //Main Form
    begin
      FrmDrawForm(FrmGetActiveForm);

      VisuStartScreen;

      HandleEvent:= true;
    end;
  // ----------
  (*
  menuEvent:
    begin;
      Case Data.Menu.ItemID of
        MenuNewGame:  begin

                       if FrmAlert(DlgNewGame)=0 then begin
                         //
                       end;
                      end;
        MenuAbout:   begin
                       if FrmAlert(DlgInfo)=0 then begin
                        //
                       end;
                     end;
      end;
      HandleEvent:= true;
    end;
  *)
  // ----------
  penDownEvent:
    begin
      PenDown:=True;
      if InWorkRect(Event) then begin
        HandleEvent:= true;
      end;
    end;
  penUpEvent:
    begin
      if PenDown and InWorkRect(Event) then begin
        //
        HandleEvent:= true;
      end;
    end;
  penMoveEvent:
    if PenDown and InWorkRect(Event) then begin
      //
      HandleEvent:= true;
    end;
  keyDownEvent:
    begin
      // up/down
      if (data.keydown.chr = chrPageUp) or
         (data.keydown.chr = vchrhard3) or
         (data.keydown.chr = vchrhard4) then
      begin
       HandleEvent:= true;
       if yPadelUser - Padelsize div 2 > wt + PadelincUser then
         yPadelUser:= yPadelUser-PadelincUser;
      end;

      if (data.keydown.chr = chrPageDown) or
         (data.keydown.chr = vchrhard1) or
         (data.keydown.chr = vchrhard2) then
      begin
       HandleEvent:= true;
       if yPadelUser + Padelsize div 2 < wb - PadelincUser then
         yPadelUser:= yPadelUser+PadelincUser;
      end;

      lastbatteryupdate:= 0; // löst sofortigen refresh bei taste ein/aus
      // vchrPower kommt bei Tastenbetätigung
      // vchrLateWakeup kommt beim reaktivieren
      // vchrAutoOff kommt beim Timer aus

      if data.keydown.chr = vchrLateWakeup then
      begin
        inc(StartCount);
        DisplayFullScreenIntro(500);

        WinEraseRectangle(WorkRect, 1);

        FrmDrawForm(FrmGetActiveForm);

        gamestate:= gsStart;
        gamemode:= gmNormal;
        Visustartscreen;

        FlushEvents;
      end;

      if (data.keydown.chr = vchrPowerOff) or
         (data.keydown.chr = vchrAutoOff) then
      begin
        // Achtung: hier nur mit Bedacht Code einfügen, sonst blockiert man ggf. den Standby, fatal!
        DisplayBlack;
      end;

    end;
  // ----------
  ctlSelectEvent: //Control button
    begin
      case Data.CtlEnter.ControlID of
        MainSButton: begin;
                        GameMode:= gmEasy;
                        StartGame(true);
                     end;
        MainNButton: begin;
                        GameMode:= gmNormal;


                        StartGame(true);
                     end;
        MainPButton: begin;
                        GameMode:= gmHard;
                        StartGame(true);
                     end;
      end;
      HandleEvent:= true;
    end;
  // ----------
  else
    HandleEvent:=False;
  end;
end;

// ----------------------------------------------------

procedure Main;
Var
  initDelayP, periodP, doubleTapDelayP: UInt16;
  queueAheadP:Boolean;
  ret: err;

  Event:         EventType;
  Error:         UInt16;
  DoStop:        Boolean;
  i:             Integer;
  s:             String;
begin
  // if sndinit > 0 then exit;
  // SndPlaySystemSound(sndStartUp);

  // Tastenwiederholrate und init delay herab setzen
  initdelayP:= 0;
  periodP:= itimer;
  doubleTapDelayP:= 0;
  queueAheadP:= false;
  ret:= KeyRates(true, initDelayP, periodP, doubleTapDelayP, queueAheadP);

  // init zufallsgenerator
  Randomize;

  // init Variablen
  lastbatteryupdate:= 0;
  StartCount:= 0;
  PlayCount:= 0;

  // workrect init
  RctSetRectangle(WorkRect,0,17,159,125);
  wt:= workrect.topleft.y;
  wb:= workrect.topleft.y+workrect.extent.y;
  wl:= workrect.topleft.x;
  wr:= workrect.topleft.x+workrect.extent.x;

  // Form
  FrmGotoForm(MainForm);

  // preset hauptstruktur
  LastBatteryupdate:=0;
  gamestate:= gsStart;
  gamemode:= gmNormal;
  // startscreen wird von formload aufgerufen
  // init der spielvariablen siehe startgame

  DoStop:= false;
  GlobForceRepaint:= false;
  Repeat
    // Variablen kopieren
    xold:= x;
    yold:= y;
    yPadelUserold:= yPadelUser;
    yPadelPCold:= yPadelPC;

    // Event über eigenen Eventhandler holen,
    // der filtert und führt eigenständig SysHandleEvent() aus
    EventHandlerGetEvent(false, 0, Event);

    if not MenuHandleEvent(MyMenu,Event,Error) then
    begin
    end;
    if not FrmDispatchEvent(Event) then
    begin
    end;

    if not HandleEvent(Event) then begin
    end;

    if gamestate=gsRun then
    begin
      // Spiellogic
      DoGameLogic;

      // wenn immer noch run state visualisieren
      if gamestate=gsRun then
      begin
        if GlobForceRepaint then
        begin
         VisuGame(true);
         GlobForceRepaint:= false;
        end
        else
        begin
         VisuGame(false);
        end;
      end;

      // kein FlushEvents !
    end;

    if (gamestate <> gsrun) then
    begin
      if abs(TimGetSeconds - lastbatteryupdate) >= 3 then
      begin
       lastBatteryUpdate:= TimGetSeconds;
       VisuBattery;
      end;
    end;

    delay(itimer);
  Until DoStop or (Event.eType=appStopEvent);
  if FrmGetActiveForm<>nil then begin
    FrmEraseForm(FrmGetActiveForm);
    FrmDeleteForm(FrmGetActiveForm);
  end;
end;

// ----------------------------------------------------

begin
  Main;
end.
