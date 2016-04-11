unit Unit1;
{
 This is free programm under GPLv2 (or later - as option) license.
 Authors: Anton Gladyshev, Egor Shishkin
}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, db, FileUtil, Forms, Controls,
  Graphics, Dialogs, DbCtrls, DBGrids, StdCtrls, ExtCtrls, Menus{$IFDEF WINDOWS},MMSystem;{$ELSE};{$ENDIF}
type

  { TForm1 }

TForm1 = class(TForm)
    BtnCheck: TButton;
    BtnUpdate: TButton;
    DataSource1: TDataSource;
    DBConnection: TIBConnection;
    DBGrid1: TDBGrid;
    ButtonCheck: TMenuItem;
    ButtonExit: TMenuItem;
    ButtonHide: TMenuItem;
    EditStatus: TEdit;
    EditComment: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    ButtonSound: TMenuItem;
    PopupMenu1: TPopupMenu;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    Timer1: TTimer;
    TrayIcon1: TTrayIcon;
    procedure BtnCheckClick(Sender: TObject);
    procedure BtnUpdateClick(Sender: TObject);
    procedure ButtonHideClick(Sender: TObject);
    procedure ButtonExitClick(Sender: TObject);
    procedure ButtonCheckClick(Sender: TObject);
    procedure EditStatusChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure DBConnectionAfterConnect(Sender: TObject);
    procedure ButtonSoundClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
  private
    { private declarations }
    IsClosed:Boolean;
  public
    { public declarations }
     procedure checking();
  end;

//const


var
  Form1:          TForm1;
  BlShowMessage:  boolean;
  ShowMessageUserReq: boolean;
  cnt:            integer;
  MyIconGreen, MyIconRed : TIcon;
  A1:             integer;  //status
  A1_P:           integer; //previous status
  f:              text;     //settings
  role:           widestring;
  IntSound:       integer;
  HostNameDB:     widestring;
  DBName:         widestring;
  DBUsername:     widestring;
  DBPassword:     widestring;
  lang:           widestring;
  f_lang:         text; //localisation
  captions_local: array[0..9] of widestring;
  i:              integer; //cycle counter
  d1:             integer; //debug purpose
implementation

{$R *.lfm}

{ TForm1 }
procedure TForm1.checking();
var
  msg:  string;
  res:  integer;
  temp: word;
begin
  //checking
  SQLQuery1.Close;
  SQLQuery1.SQL.Clear;
  SQLQuery1.SQL.Text       := 'SELECT * FROM MAIN';
  DBConnection.Connected   := True;
  TrayIcon1.BalloonTimeout := 5000;
  // IF DataSet is open then transaction should be Commit and started again
  If SQLTransaction1.Active Then SQLTransaction1.Commit;
  SQLTransaction1.StartTransaction;
  Try
     // try open DataSet
     SQLQuery1.Open;
  Except
     // somthing goes wrong, get out of here and rollback transaction
     SQLTransaction1.Rollback;
  end;
  //IsClosed   := A1  <> SQLQuery1.Fields[1].AsInteger;
  //If IsClosed then
  //begin
       A1                     := SQLQuery1.Fields[1].AsInteger;
       msg                    := SQLQuery1.Fields[2].AsString;
       If A1_P <> A1 then
       begin
          A1_P                := A1;
          BlShowMessage       := true;
       end;
       TrayIcon1.BalloonHint  := msg;
  //end;

  cnt:=cnt+1;
  if BlShowMessage then
  begin
     if (cnt mod 5 = 0) or ShowMessageUserReq then
     begin
          TrayIcon1.ShowBalloonHint;
          ShowMessageUserReq := false;
          //TrayIcon1.BalloonHint := msg;
          A1:= A1;
          if A1 = 1 then
          begin
             TrayIcon1.Icon.Assign(MyIconGreen);
             {$IFDEF WINDOWS}
             if IntSound = 1 then
                sndPlaySound('green.wav',SND_NODEFAULT Or SND_ASYNC);
             {$ELSE}
             {$ENDIF}
          end
          else
          begin
             TrayIcon1.Icon.Assign(MyIconRed);
             {$IFDEF WINDOWS}
             if IntSound = 1 then
                sndPlaySound('red.wav',SND_NODEFAULT Or SND_ASYNC);
             {$ELSE}
             {$ENDIF}
          end;
     end;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  // Initialize parameters such as show message user, counters, icons,
  DBConnection.HostName      := 'localhost';
  DBConnection.DatabaseName  := 'mydb';
  AssignFile(f,'settings.txt');//this should be universal
  //AssignFile(f,'/settings.txt');//linux //though works fine on Windows too
  reset(f);
  readln(f, role);
  readln(f, IntSound);
  readln(f, lang);
  readln(f, HostNameDB);
  readln(f, DBName);
  readln(f, DBUsername);
  readln(f, DBPassword);
  CloseFile(f);

  DBConnection.HostName       := HostNameDB;
  DBConnection.DatabaseName   := DBName;
  DBConnection.UserName       := DBUsername;
  DBConnection.Password       := DBPassword;

  cnt :=0;
  AssignFile(f_lang, lang+'.txt');
  reset(f_lang);
  While cnt<10 Do
  begin
       readln(f_lang,captions_local[cnt]);
       cnt:=cnt+1;
  end;
  CloseFile(f_lang);

  Form1.Caption       := captions_local[0];
  Label1.Caption      := captions_local[1];
  Label2.Caption      := captions_local[2];
  Label3.Caption      := captions_local[3];
  BtnUpdate.Caption   := captions_local[4];
  BtnCheck.Caption    := captions_local[5];
  ButtonCheck.Caption := captions_local[6];
  ButtonHide.Caption  := captions_local[7];
  ButtonSound.Caption := captions_local[8];
  ButtonExit.Caption  := captions_local[9];

  A1  :=200;
  cnt :=0;
  BlShowMessage         := true;
  ShowMessageUserReq    := true;

  TrayIcon1.Icons       := TImageList.Create(Self);
  MyIconGreen           := TIcon.Create;
  MyIconGreen.LoadFromFile('traffic2-green.ico');
  MyIconRed             := TIcon.Create;
  MyIconRed.LoadFromFile('traffic2-red.ico');
  IsClosed:=False;
  ButtonCheckClick(Self); // Hack for show icon on Windows 7. On Windows 8 and later works fine
  d1 := AnsiCompareText(role,'admin-dba');
  //ShowMessage(IntToStr(d1));     //for debug purposes
  //some magic here. If settings.txt is UTF-8 then 'admin-dba' (from file) as variable role <> 'admin-dba' from line below...
  If role <> 'admin-dba' then  //If DBConnection.UserName <> 'SYSDBA' then //WORKS ONLY WHEN SETTINGS.TXT IS ANSI
  begin
     Hide();
     WindowState := wsMinimized;
  end;
end;

procedure TForm1.BtnCheckClick(Sender: TObject);
begin
    //ButtonCheck!
    checking();
end;

procedure TForm1.BtnUpdateClick(Sender: TObject);
begin
  SQLQuery1.Close;
  SQLQuery1.SQL.Clear;
  SQLQuery1.SQL.Text      := 'update main a set status = '+EditStatus.Text+' , comment = '+ QuotedStr(EditComment.Text)+' where id = 1';
  //ShowMessage(SQLQuery1.SQL.Text); for debug purpose
  DBConnection.Connected  := True;
  // IF DataSet is open then transaction should be Commit and started again
  If SQLTransaction1.Active Then SQLTransaction1.Commit;
  SQLTransaction1.StartTransaction;
  Try
     //// try open DataSet
     SQLQuery1.ExecSQL;
  Except
     // somthing goes wrong, get out of here and rollback transaction
     SQLTransaction1.Rollback;
  end;
end;

procedure TForm1.ButtonHideClick(Sender: TObject);
begin
  //ButtonHideMessage
  BlShowMessage := false;
end;

procedure TForm1.ButtonExitClick(Sender: TObject);
begin
   TrayIcon1.Destroy;
   Application.Terminate();
end;

procedure TForm1.ButtonCheckClick(Sender: TObject);
begin
   //ButtonCheck! Popup menu
   //User want to check message
   BlShowMessage := true;
   ShowMessageUserReq := true;
   checking();
end;

procedure TForm1.EditStatusChange(Sender: TObject);
begin

end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  //Good habbit to close connection and commit
  If SQLTransaction1.Active Then SQLTransaction1.Commit;
  SQLQuery1.Close;
  DBConnection.CloseTransactions;
  DBConnection.Close;
  TrayIcon1.Destroy;
end;

procedure TForm1.DBConnectionAfterConnect(Sender: TObject);
begin

end;

procedure TForm1.ButtonSoundClick(Sender: TObject);
begin
  if IntSound = 1 then
  begin
    IntSound := 0;
  end
  else
  begin
    IntSound := 1;
  end;
  AssignFile(f,'settings.txt');//this should be universal
  //AssignFile(f,'/settings.txt');//linux //though works fine on Windows too
  rewrite(f); //Append for log file
  writeln(f,role);
  writeln(f,IntSound);
  writeln(f,lang);
  writeln(f,HostNameDB);
  CloseFile(f);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  checking();
end;

procedure TForm1.TrayIcon1Click(Sender: TObject);
begin
  TrayIcon1.BalloonTimeout :=0;
  BlShowMessage := false;
end;

end.

