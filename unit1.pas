unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, db, FileUtil, Forms, Controls,
  Graphics, Dialogs, DbCtrls, DBGrids, StdCtrls, ExtCtrls, Menus, {$IFDEF WINDOWS}MMSystem;{$ELSE};{$ENDIF}
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
    procedure Timer1Timer(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
  private
    { private declarations }
    IsClosed:Boolean;
  public
    { public declarations }
     procedure checking();
  end;

const
  HostNameDB = 'localhost';

var
  Form1: TForm1;
  BlShowMessage: boolean;
  ShowMessageUserReq: boolean;
  cnt: integer;
  MyIconGreen, MyIconRed : TIcon;
  A1: integer;
  f:text;
  role:widestring;
implementation

{$R *.lfm}

{ TForm1 }
procedure TForm1.checking();
var
  msg: string;
  res: integer;
  temp: word;
begin
  //checking
  SQLQuery1.Close;
  SQLQuery1.SQL.Clear;
  SQLQuery1.SQL.Text     := 'SELECT * FROM MAIN';
  DBConnection.Connected := True;
  TrayIcon1.BalloonTimeout:=5000;
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
  IsClosed   := A1  <> SQLQuery1.Fields[1].AsInteger;
  If IsClosed then
  begin
       A1                     := SQLQuery1.Fields[1].AsInteger;
       msg                    := SQLQuery1.Fields[2].AsString;
       BlShowMessage          := True;
       TrayIcon1.BalloonHint  := msg;
  end;

  cnt:=cnt+1;
  if BlShowMessage then
  begin
     if (cnt mod 5 = 0) or ShowMessageUserReq then
     begin
          TrayIcon1.ShowBalloonHint;
          ShowMessageUserReq := false;
          A1:= A1;
          if A1 = 1 then
          begin
             TrayIcon1.Icon.Assign(MyIconGreen);
             sndPlaySound('green.wav',SND_NODEFAULT Or SND_ASYNC);
          end
          else
          begin
             TrayIcon1.Icon.Assign(MyIconRed);
             sndPlaySound('red.wav',SND_NODEFAULT Or SND_ASYNC);
          end;
     end;
  end;
 //!!
 //for merge
//!!


end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  // Initialize parameters such as show message user, counters, icons,
  A1:=200;
  cnt:=0;

  BlShowMessage := true;
  ShowMessageUserReq := true;
  DBConnection.HostName := HostNameDB;
  TrayIcon1.Icons       := TImageList.Create(Self);
  MyIconGreen           := TIcon.Create;
  MyIconGreen.LoadFromFile('traffic2-green.ico');
  MyIconRed             := TIcon.Create;
  MyIconRed.LoadFromFile('traffic2-red.ico');
  IsClosed:=False;
  //older
  //If DBConnection.UserName <> 'SYSDBA' then
  //begin
  //   Hide();
  //   WindowState := wsMinimized;
  //end;
  //newer path
  AssignFile(f,'settings.txt');//this should be universal
  //AssignFile(f,'/settings.txt');//linux //though works fine on Windows too
  //AssignFile(f,'\abc.txt');//Windows
  reset(f);
  readln(f,role);
  CloseFile(f);
  ButtonCheckClick(Self); // Hack for show icon on Windows 7. On Windows 8 and later works fine
  If role <> 'admin' then
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
var
  a0:string;
begin
  //SQLQuery1.Close;
  SQLQuery1.SQL.Clear;
//W  SQLQuery1.SQL.Text      := 'update main a set status = '+EditStatus.Text+ 'where id = 1';
  SQLQuery1.SQL.Text      := 'update main a set status = '+EditStatus.Text+' , comment = '+ QuotedStr(EditComment.Text)+' where id = 1';
  a0:= SQLQuery1.SQL.Text;
  ShowMessage(a0);
  //W  SQLQuery1.SQL.Text      := 'update main a set status = 0 where id = 1';
  DBConnection.Connected  := True;
  SQLQuery1.ExecSQL;
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
end;

procedure TForm1.DBConnectionAfterConnect(Sender: TObject);
begin

end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  checking();
end;

procedure TForm1.TrayIcon1Click(Sender: TObject);
begin
  TrayIcon1.BalloonTimeout:=0;
  BlShowMessage := false;
end;

end.

