unit Unit1;
{
 This is free programm under GPLv2 and GPLv3 licenses.
 Authors: Anton Gladyshev, Egor Shishkin
 version 1.0.0.9 date 2016-10-27
                     (YYYY-MM-DD)
}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, db, FileUtil, Forms, Controls,
  Graphics, Dialogs, DbCtrls, DBGrids, StdCtrls, ExtCtrls, LazUtils, LConvEncoding,
  Menus{$IFDEF WINDOWS}, MMSystem;{$ELSE};{$ENDIF}
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
    EditInterval: TEdit;
    EditStatus: TEdit;
    EditComment: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    ButtonSound: TMenuItem;
    Label4: TLabel;
    PopupMenu1: TPopupMenu;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    Timer1: TTimer;
    timerDelayed: TTimer;
    ToggleBox1: TToggleBox;
    TrayIcon1: TTrayIcon;
    procedure btnApplyDelayedClick(Sender: TObject);
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
    procedure timerDelayedTimer(Sender: TObject);
    procedure ToggleBox1Change(Sender: TObject);
    procedure ToggleBox1Click(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
  private
    { private declarations }
    IsClosed:Boolean;
  public
    { public declarations }
    procedure checking();
    procedure logging();
    procedure updatedb();
  end;

//const


var
  Form1:          TForm1;
  BlShowMessage:  boolean;
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
  captions_local: array[0..16] of widestring; //total 17 lines
  i:              integer; //cycle counter
  d1:             integer; //debug purpose
  f_log:          text; //log file
  LogEvent:       widestring;
  ErrorMsg:       widestring;
  LogString:      widestring; //result string to write to file
  DT:             TDateTime;
  pwd_ansi:       ansistring;
  pwd:            boolean;
  LogSettings:    integer;
  msg:            string;

implementation

{$R *.lfm}

{ TForm1 }
procedure TForm1.logging();
begin
  AssignFile(f_log, 'log.txt');
  Try
    Append(f_log);
    LogString := FormatDateTime('dd-mm-yyyy hh:nn', Now)+' , '+role+' , '+LogEvent+' , '+ErrorMsg;
    writeln(f_log, LogString);
    //ShowMessage('should be written '+LogString);
    CloseFile(f_log);
  Except
    ShowMessage('log.txt '+captions_local[11]);
    TrayIcon1.Destroy;
    Halt;
  end;
end;

procedure TForm1.checking();
begin
  //checking
  SQLQuery1.Close;
  SQLQuery1.SQL.Clear;
  SQLQuery1.SQL.Text         := 'SELECT * FROM MAIN';
  Try
    DBConnection.Connected   := True;
  Except
    // something went wrong, get out of here
    ShowMessage(captions_local[10]);
    TrayIcon1.Destroy;
    ErrorMsg := captions_local[10];
    LogEvent := 'stop';
    if LogSettings=0 Then
    begin
     logging();
    end;
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
    ErrorMsg := captions_local[10];
    LogEvent := 'stop';
    if LogSettings=0 Then
    begin
     logging();
    end;
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

  if BlShowMessage then
  begin
    if (cnt mod 5 = 0) then
    //if (cnt mod 5 = 0) or ShowMessageUserReq then
    begin
          TrayIcon1.ShowBalloonHint;
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
                ErrorMsg := 'green.wav '+captions_local[11];
                LogEvent := 'stop';
                if LogSettings=0 Then
                begin
                  logging();
                end;
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
                ErrorMsg := 'red.wav '+captions_local[11];
                LogEvent := 'stop';
                if LogSettings=0 Then
                begin
                  logging();
                end;
                end;
             end;
             {$ELSE}
             {$ENDIF}
          end;
    end;
  end;
  cnt:=cnt+1;
end;
procedure TForm1.updatedb();
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

procedure TForm1.FormCreate(Sender: TObject);
begin
  //logging a start
  LogSettings:=0;
  LogEvent:='start';
  ErrorMsg:='';
  logging();

  // Initialize parameters such as show message user, counters, icons,
  DBConnection.HostName      := 'localhost';
  DBConnection.DatabaseName  := 'mydb';
  AssignFile(f,'settings.txt');//this should be universal
  //AssignFile(f,'/settings.txt');//linux //though works fine on Windows too
  Try
    // try to open file, read variables and close file
    reset(f);
    readln(f, role); //now we keep calm and load our role
    role := UTF8BOMToUTF8(role);
    readln(f, IntSound);
    readln(f, lang);
    readln(f, HostNameDB);
    readln(f, DBName);
    readln(f, DBUsername);
    readln(f, DBPassword);
    readln(f, LogSettings);
    CloseFile(f);
  Except
    // something went wrong, get out of here
    ErrorMsg := 'settings.txt'+' file is corrupted, please re-install app';
    LogEvent := 'stop';
    ShowMessage(ErrorMsg);
    if LogSettings=0 Then
    begin
      logging();
    end;
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
    While cnt<18 Do //total lines count(17) + 1
    begin
      readln(f_lang,captions_local[cnt]);
      cnt:=cnt+1;
    end;
    CloseFile(f_lang);
  Except
    // something went wrong, get out of here
    ErrorMsg := lang+'.txt'+' file is corrupted, please re-install app';
    LogEvent := 'stop';
    ShowMessage(ErrorMsg);
    logging();
    Halt;
  end;

  Form1.Caption            := captions_local[0];
  Label1.Caption           := captions_local[1];
  Label2.Caption           := captions_local[2];
  Label3.Caption           := captions_local[3];
  BtnUpdate.Caption        := captions_local[4];
  BtnCheck.Caption         := captions_local[5];
  ButtonCheck.Caption      := captions_local[6];
  ButtonHide.Caption       := captions_local[7];
  ButtonSound.Caption      := captions_local[8];
  ButtonExit.Caption       := captions_local[9];
  label4.Caption           := captions_local[15];
  ToggleBox1.Caption       := captions_local[16];
  //captions_local[10] is error message for DB Connection error
  //captions_local[11] is error message for icon and audio assets loading error
  //captions_local[12] is used to be TrayIcon1.Hint

  A1  :=200;
  cnt :=0;
  BlShowMessage         := true;

  TrayIcon1.Icons       := TImageList.Create(Self);
  TrayIcon1.Hint        := captions_local[12];
  MyIconGreen           := TIcon.Create;
  Try
    MyIconGreen.LoadFromFile('traffic2-green.ico');
  Except
    ErrorMsg := 'traffic2-green.ico '+captions_local[11];
    LogEvent := 'stop';
    ShowMessage(ErrorMsg);
    if LogSettings=0 Then
    begin
      logging();
    end;
    Halt;
  end;

  MyIconRed             := TIcon.Create;
  Try
    MyIconRed.LoadFromFile('traffic2-red.ico');
  Except
    ErrorMsg := 'traffic2-red.ico '+captions_local[11];
    LogEvent := 'stop';
    ShowMessage(ErrorMsg);
    if LogSettings=0 Then
    begin
      logging();
    end;
    Halt;
  end;

  IsClosed:=False;
  ButtonCheckClick(Self); // Hack for show icon on Windows 7. On Windows 8 and later works fine
  //d1 := WideCompareText(role,'admin-dba');
  //!!! req uses LazUtils, LConvEncoding !!!
  If  role <> 'admin-dba' then  //If DBConnection.UserName <> 'SYSDBA' then //WORKS ONLY WHEN SETTINGS.TXT IS ANSI
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

procedure TForm1.btnApplyDelayedClick(Sender: TObject);
begin
  timerDelayed.Interval := StrToInt(EditInterval.Text)*1000*60;
  timerDelayed.Enabled  := True;
end;

procedure TForm1.BtnUpdateClick(Sender: TObject);
begin
  update();
end;

procedure TForm1.ButtonHideClick(Sender: TObject);
begin
  //ButtonHideMessage
  BlShowMessage := false;
end;

procedure TForm1.ButtonExitClick(Sender: TObject);
begin
  If  role <> 'admin-dba' then  //If DBConnection.UserName <> 'SYSDBA' then //WORKS ONLY WHEN SETTINGS.TXT IS ANSI
  begin
    pwd := InputQuery(captions_local[0], captions_local[13], pwd_ansi);
    If pwd_ansi = 'GhjuhfvvbcnsHerbRh.rb' Then
    begin
      TrayIcon1.Destroy;
      ErrorMsg := '';
      LogEvent := 'stop';
      if LogSettings=0 Then
      begin
        logging();
      end;
      Halt;
    end
    else
    begin
      ShowMessage(captions_local[14]);
    end;
  end
  else
  begin
    TrayIcon1.Destroy;
    ErrorMsg := '';
    LogEvent := 'stop';
    if LogSettings=0 Then
    begin
      logging();
    end;
    Halt;
  end;
End;

procedure TForm1.ButtonCheckClick(Sender: TObject);
begin
   //ButtonCheck! Popup menu
   //User want to check message
   BlShowMessage := true;
   cnt:=0;
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
  ErrorMsg := '';
  LogEvent := 'stop';
  if LogSettings=0 Then
  begin
    logging();
  end;
  Halt;
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
    rewrite(f);
    role := UTF8ToUTF8BOM(role);
    writeln(f, role);
    role := UTF8BOMToUTF8(role);
    writeln(f, IntSound);
    writeln(f, lang);
    writeln(f, HostNameDB);
    writeln(f, DBName);
    writeln(f, DBUsername);
    writeln(f, DBPassword);
    writeln(f, LogSettings);
    CloseFile(f);
  Except
   ShowMessage(captions_local[10]);
   TrayIcon1.Destroy;
   ErrorMsg := 'captions_local[10]';
   LogEvent := 'stop';
   if LogSettings=0 Then
   begin
      logging();
   end;
   Halt;
  end;
end;



procedure TForm1.Timer1Timer(Sender: TObject);
begin
  checking();
end;

procedure TForm1.timerDelayedTimer(Sender: TObject);
begin
  updatedb();
  timerDelayed.Enabled := False;
end;

procedure TForm1.ToggleBox1Change(Sender: TObject);
begin
  if ToggleBox1.Checked = True then
  begin
    timerDelayed.Interval := StrToInt(EditInterval.Text)*1000*60;
    timerDelayed.Enabled  := True;
  end;
  if ToggleBox1.Checked = False then
  begin
    timerDelayed.Interval := StrToInt(EditInterval.Text)*1000*60;
    timerDelayed.Enabled  := False;
  end;

end;

procedure TForm1.ToggleBox1Click(Sender: TObject);
begin
 // if ToggleBox1.Checked = True then
 //   ShowMessage('do it!');
 // if ToggleBox1.Checked = False then
 //   ShowMessage('don''t do it');
end;

procedure TForm1.TrayIcon1Click(Sender: TObject);
begin
  TrayIcon1.BalloonTimeout :=0;
  BlShowMessage := false;
end;

end.

