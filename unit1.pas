unit Unit1;
{
 This is free programm under GPLv2 (or later - as option) license.
 Authors: Anton Gladyshev, Egor Shishkin
 version 1.0.0.4
}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, db, FileUtil, Forms, Controls,
  Graphics, Dialogs, DbCtrls, DBGrids, StdCtrls, ExtCtrls, LazUtils, LConvEncoding,
  Menus,{$IFDEF WINDOWS}MMSystem;{$ELSE};{$ENDIF}
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
  MyIconGreen, MyIconRed:   TIcon;
  A1:             integer;  //status
  A1_P:           integer;  //previous status
  f:              text;     //settings
  role:           widestring;
  IntSound:       integer;
  HostNameDB:     widestring;
  DBName:         widestring;
  DBUsername:     widestring;
  DBPassword:     widestring;
  lang:           widestring;
  f_lang:         text; //localisation
  captions_local: array[0..12] of widestring; //total 13 lines
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
  Try
    DBConnection.Connected   := True;
  Except
    // something went wrong, get out of here
    ShowMessage(captions_local[10]);
    TrayIcon1.Destroy;
    Halt;
  end;

  TrayIcon1.BalloonTimeout := 5000;
  // IF DataSet is open then transaction should be Commit and started again
  Try
    If SQLTransaction1.Active Then SQLTransaction1.Commit;
    SQLTransaction1.StartTransaction;
  Except
    // something went wrong, get out of here
    ShowMessage(captions_local[10]);
    TrayIcon1.Destroy;
    Halt;
  end;

  Try
    // try to open DataSet
    SQLQuery1.Open;
  Except
    // something went wrong, get out of here and rollback transaction
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
             begin
                Try
                sndPlaySound('green.wav',SND_NODEFAULT Or SND_ASYNC);
                Except
                ShowMessage('green.wav '+captions_local[11]);
                TrayIcon1.Destroy;
                Halt;
                end;
             end;
             {$ELSE}
             {$ENDIF}
          end
          else
          begin
             TrayIcon1.Icon.Assign(MyIconRed);
             {$IFDEF WINDOWS}
             if IntSound = 1 then
             begin
                Try
                sndPlaySound('red.wav',SND_NODEFAULT Or SND_ASYNC);
                Except
                ShowMessage('red.wav '+captions_local[11]);
                TrayIcon1.Destroy;
                Halt;
                end;
             end;
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
  Try
    // try to open file, read variables and close file
    reset(f);
    readln(f, role); //now we keep calm and load our role
    readln(f, IntSound);
    readln(f, lang);
    readln(f, HostNameDB);
    readln(f, DBName);
    readln(f, DBUsername);
    readln(f, DBPassword);
    CloseFile(f);
  Except
    // something went wrong, get out of here
    ShowMessage('settings.txt'+' file is corrupted, please re-install app');
    Halt;
  end;

  DBConnection.HostName       := HostNameDB;
  DBConnection.DatabaseName   := DBName;
  DBConnection.UserName       := DBUsername;
  DBConnection.Password       := DBPassword;

  cnt :=0;
  AssignFile(f_lang, lang+'.txt');
  Try
    reset(f_lang);
    While cnt<14 Do //total lines count(13) + 1
    begin
      readln(f_lang,captions_local[cnt]);
      cnt:=cnt+1;
    end;
    CloseFile(f_lang);
  Except
    // something went wrong, get out of here
    ShowMessage(lang+'.txt'+' file is corrupted, please re-install app');
    Halt;
  end;

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
  //captions_local[10] is error message for DB Connection error
  //captions_local[11] is error message for icon and audio assets loading error
  //captions_local[12] is used to be TrayIcon1.Hint

  A1  :=200;
  cnt :=0;
  BlShowMessage         := true;
  ShowMessageUserReq    := true;

  TrayIcon1.Icons       := TImageList.Create(Self);
  TrayIcon1.Hint        := captions_local[12];
  MyIconGreen           := TIcon.Create;
  Try
    MyIconGreen.LoadFromFile('traffic2-green.ico');
  Except
    ShowMessage('traffic2-green.ico '+captions_local[11]);
    Halt;
  end;

  MyIconRed             := TIcon.Create;
  Try
    MyIconRed.LoadFromFile('traffic2-red.ico');
  Except
    ShowMessage('traffic2-red.ico '+captions_local[11]);
    Halt;
  end;

  IsClosed:=False;
  ButtonCheckClick(Self); // Hack for show icon on Windows 7. On Windows 8 and later works fine
  //d1 := WideCompareText(role,'admin-dba');
  //!!! req uses LazUtils, LConvEncoding !!!
  If  UTF8BOMToUTF8(role) <> 'admin-dba' then  //If DBConnection.UserName <> 'SYSDBA' then //WORKS ONLY WHEN SETTINGS.TXT IS ANSI
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
   Halt;
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

  Try
    AssignFile(f,'settings.txt');//this should be universal
    rewrite(f); //Append for log file
    writeln(f, role);
    writeln(f, IntSound);
    writeln(f, lang);
    writeln(f, HostNameDB);
    writeln(f, DBName);
    writeln(f, DBUsername);
    writeln(f, DBPassword);
    CloseFile(f);
  Except
    ShowMessage(captions_local[10]);
    TrayIcon1.Destroy;
    Halt;
  end;
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

