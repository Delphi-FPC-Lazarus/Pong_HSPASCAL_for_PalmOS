// Eventhandler mit Filter (Hard/Softkey) für Weitergabe an HandleSysEvent()
// Rückgabeparameter Event beinhaltet alle Events

unit eventhandler;

interface

uses crt, chars, event, sysevent, SystemMgr,
     util;

procedure EventHandlerGetEvent(bWait:boolean; iDelay:integer; var Event:Eventtype);

implementation

procedure EventHandlerGetEvent(bWait:boolean; iDelay:integer; var Event:Eventtype);
var bSkipEvent:boolean;
begin
  Event.etype:= nilEvent;

  if bWait=true then
    EvtGetEvent(Event,evtWaitForever) // Achtung: wartet auf Event, Programm "steht" sonst
  else
    EvtGetEvent(Event,evtNoWait);     // Achtung: nicht warten, programm muss per delay gebremst werden

  if iDelay > 0 then
    Delay(iDelay);

  bSkipEvent:= false;
  if Event.eType <> nilEvent then
  begin
    Case Event.eType of
      penDownEvent: begin
                     // if ScreenY > 160 then  // unterhalb display
                     // begin
                     //   bskipevent:= true;
                     // end;
                    end;
      keyDownEvent: begin
                     // tastencodes siehe unit chars
                     // up/down
                     if (Event.data.keydown.chr = chrPageUp) or
                        (Event.data.keydown.chr = chrPageDown) then
                     begin
                      bskipevent:= true;
                     end;

                     // hardkeys 1-4
                     if (Event.data.keydown.chr = vchrhard1) or
                        (Event.data.keydown.chr = vchrhard2) or
                        (Event.data.keydown.chr = vchrhard3) or
                        (Event.data.keydown.chr = vchrhard4) then
                     begin
                      bskipevent:= true;
                     end;

                     // softkeys
                     if (Event.data.keydown.chr = vchrfind) or
                        (Event.data.keydown.chr = vchrcalc) or
                        (Event.data.keydown.chr = vchrMenu) or
                        (Event.data.keydown.chr = vchrLaunch) then
                     begin
                      bskipevent:= true;
                     end;

                     // grafitti bereich
                     if (Event.data.keydown.chr = vchrGraffitiReference) or
                        (Event.data.keydown.chr = vchrKeyboardAlpha) or
                        (Event.data.keydown.chr = vchrKeyboardNumeric) or
                        (Event.data.keydown.chr = vchrRonamatic) then
                     begin
                      bskipevent:= true;
                     end;

		     // Sondertasten andere Geräte, Uhr Symbol (m505) 0x1701
                     if (Event.data.keydown.chr >= vchrThumperMin) then
                     begin
                      bskipevent:= true;
                     end;                      

                     // vchrPower kommt bei Tastenbetätigung
                     // vchrLateWakeup kommt beim reaktivieren
                     // vchrAutoOff kommt beim Timer aus
                    end;
    end;
  end;

  if not bSkipEvent then
  begin
    if not SysHandleEvent(Event) then
    begin
    end;
  end
  else
  begin
   //dosound(440,50);  
  end;

end;

end.