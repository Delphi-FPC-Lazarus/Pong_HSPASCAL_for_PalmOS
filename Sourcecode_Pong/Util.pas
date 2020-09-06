// Utility

unit util;

interface

function inttostr(i:integer):string;
function realtostr(r:real;d:integer):string;

procedure DoSound(frq, len:Integer);
function getBatteryInfo:String;
procedure FlushEvents;

implementation

uses Crt, SoundMgr, Event, SysEvent, SystemMgr;

// ----------------------------------------------------

function getBatteryInfo:string;
var iThreadsholdP, iciritcalThreadsholdP:UInt16;
    imaxTicksP:Int16;
    kindP:SysBatteryKind;
    bPluggedIn:Boolean;
    iPercent:UInt8;
    iVolt:real;
    sRes:String;
begin
  GetBatteryInfo:= '';

  if SysBatteryInfo(false,
                    iThreadsholdP, iciritcalThreadsholdP,
                    imaxTicksP,
                    kindP,
                    bPluggedIn,
                    iPercent) <> 0 then
  begin
  end;

  // Akkustand (iPercent) bezieht sich auf Li Ionen Akku, der hat nominal 3.7V
  // LiIonn Akku ist leer bei bei 3.5-3.6V und voll bei 4.2V
  //
  // Ersatz mit 3x NiCd Akku mit nominal 1.2V => 3.6V möglich, hat aber einen anderen Spannungsverlauf!
  // Typischer Arbeitsbereich 3*1.3V -> 3.9V -> ca. 65% in der Anzeige
  // Daher macht die Anzeige der Betriebsspannung mehr Sinn!

  sRes:= '';
  case iPercent of  // bezogen auf iPercent da bei < 10% das PalmOS eh noch ne Meldung bringt
    0.. 15:  sRes:= 'Schwach';
   16.. 39:  sRes:= 'Gut';
   40..100:  sRes:= 'Super';
  end;

  // ofset 3.60V entspricht 0% - da läut der PDA aber noch, scale 4.20V entspricht 100%
  // iVolt:= 3.60+iPercent*6.0E-3;
  // sRes:= sRes + ' ('+realtostr(iVolt,1)+'V/'+inttostr(iPercent)+')        ';
  // sRes:= sRes + '[' + inttostr(iPercent)+']';

  GetBatteryInfo:= sRes;
end;

// ----------------------------------------------------

procedure DoSound(frq, len:Integer);
var snd:SndCommandType;
begin
  snd.cmd:= sndCmdFrqOn;
  snd.param1:= frq;
  snd.param2:= len;
  snd.param3:= sndMaxAmp;

  if SndDoCmd(pointer(0), @snd, false)<>0 then exit;
  delay(len);
end;

// ----------------------------------------------------

procedure FlushEvents;
var i:integer;
    event:EventType;
begin
  // flush events
  i:= 0;
  repeat
    EvtGetEvent(Event,evtnoWait); // Achtung: nicht warten!
    inc(i);
  until (event.etype=nilevent); // or i > 100
end;

// ----------------------------------------------------

function inttostr(i:integer):string;
var s:string;
begin
 inttostr:= '';
 str(i,s);
 inttostr:= s;
end;

// ----------------------------------------------------

function realtostr(r:real;d:integer):string;
var s:string;
begin
 realtostr:= '';
 str(r:1:d,s);
 realtostr:= s;
end;

// ----------------------------------------------------


end.