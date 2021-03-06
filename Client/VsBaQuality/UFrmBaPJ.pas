{*******************************************************}
{                                                       }
{       病案终末评价                                    }
{                                                       }
{       版权所有 (C) 2016 武汉雕龙软件医疗数据服务      }
{                                                       }
{*******************************************************}

unit UFrmBaPJ;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFrmSuiDBForm, DB, ActnList, DBClient, UDlClientDataset, DosMove,
  AdvPanel, AdvAppStyler, AdvToolBar, AdvToolBarStylers, AdvOfficeStatusBar,
  AdvOfficeStatusBarStylers, ExtCtrls, AdvSplitter, StdCtrls, SUIEdit,
  EllipsLabel, TFlatGroupBoxUnit, AdvGlowButton, DBGridEhGrouping, GridsEh,
  DBGridEh, TFlatPanelUnit;

type
  TFrmBaPJ = class(TFrmSuiDBForm)
    AdvPanel2: TAdvPanel;
    AdvSplitter1: TAdvSplitter;
    FlatGroupBox1: TFlatGroupBox;
    EllipsLabel1: TEllipsLabel;
    suiedtZYH: TsuiEdit;
    AdvbtnActLocate: TAdvGlowButton;
    dbgrdhBaList: TDBGridEh;
    FlatPanel1: TFlatPanel;
    FlatPanel2: TFlatPanel;
    AdvbtnacSave: TAdvGlowButton;
    dbgrdhPJDetail: TDBGridEh;
    clientdtPJDetail: TClientDataSet;
    dsPJDetail: TDataSource;
    AdvbtnClose: TAdvGlowButton;
    procedure ActLocateExecute(Sender: TObject);
    procedure suiedtZYHKeyPress(Sender: TObject; var Key: Char);
    procedure suiedtZYHKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure AdvbtnacSaveClick(Sender: TObject);

    procedure dbgrdhBaListCellClick(Column: TColumnEh);
  private
    { Private declarations }
    CH0A00:string;    //住院号

  public
    { Public declarations }
     constructor Create(Aower:TComponent);override;
  end;

var
  FrmBaPJ: TFrmBaPJ;

implementation
  uses
    UGFun,UVsMidClassList,UVsBaSx,UMidProxy;
{$R *.dfm}

{ TFrmBaPJ }

procedure TFrmBaPJ.ActLocateExecute(Sender: TObject);
var
 StrCH0A00:string; //住院号
begin
  inherited;
  if suiedtZYH.Text = '' then Exit;
  if not DLCDS.Active then Exit;
  if DLCDS.IsEmpty then Exit;
  StrCH0A00 := suiedtZYH.Text;
  if not DLCDS.Locate('CH0A00',StrCH0A00,[loCaseInsensitive]) then
  begin
    ShowMsgSure('这条记录不存在!');
  end;

end;

procedure TFrmBaPJ.AdvbtnacSaveClick(Sender: TObject);
var

  sql:string;
  FCode,SCode,TCode,Code:string;
  Score:Double;
  Remark:string;
  mark:Pointer;
begin
  inherited;
  //判断师傅存在数据
  if not clientdtPJDetail.Active then Exit;
  if clientdtPJDetail.IsEmpty then Exit;
  if not DLCDS.Active then Exit;
  if DLCDS.IsEmpty then Exit;
  if clientdtPJDetail.ChangeCount <1 then 
  begin
    ShowMsgSure('数据没有被修改，不用保存!');
    Exit;
  end;
   //获取住院号
  CH0A00:=DLCDS.FieldByName('CH0A00').AsString;
  sql := Format('delete from VsBAZmPj where CH0A00=%s',[CH0A00]);
  try
    //删除上次评价
    TMidProxy.SqlExecute(sql);
    mark := clientdtPJDetail.GetBookmark;
    with clientdtPJDetail do
    begin
      try
        DisableControls;
        First;
        while not Eof do
        begin
          FCode := FieldByName('Fcode').AsString; //主项目编号
          SCode := FieldByName('Scode').AsString;//次项目编号
          TCode := FieldByName('Tcode').AsString;//细项目编号
          Score := FieldByName('Score').AsFloat; //分数
          Remark := DelStrTabDot(FieldByName('Remark').AsString);      //其他问题
          if TCode = '' then
          begin
            if SCode = '' then
              Code := FCode
            else
              Code := SCode;
          end
          else
            Code := TCode;

          sql := Format('insert into VsBAZmPj(CH0A00,Code,Score,Remark) values(^%s^,^%s^,%f,^%s^)',[CH0A00,Code,Score,Remark]) ;
          TMidProxy.SqlExecute(sql);
          Next;
        end;
      finally
        EnableControls;
      end;
    end;
    ShowMsgSure('保存完成');
  finally
    clientdtPJDetail.GotoBookmark(mark);
    clientdtPJDetail.FreeBookmark(mark);
  end;

end;

constructor TFrmBaPJ.Create(Aower: TComponent);
const
  sql = 'select * from VSPJBA0A';

begin
  inherited Create(Aower,EuVsBaZmPj,sql);
  if DLCDS.Active then
  begin
    if DLCDS.IsEmpty then
    begin
      ShowMsgSure('尚未筛选病历,无法评价质量!');
      Exit;
    end
    else
      SetSbSimpleText(Format('共计：%d条数据',[DLCDS.RecordCount]));
  end;
end;

procedure TFrmBaPJ.dbgrdhBaListCellClick(Column: TColumnEh);
const
  execSql ='exec PBAzmpj ^%s^' ;
var
 sql:string;

begin
  inherited;
  try
    if not DLCDS.Active then Exit;
    if DLCDS.IsEmpty then Exit;
    CH0A00 := DLCDS.FieldByName('CH0A00').AsString;
    if clientdtPJDetail.Active then
      clientdtPJDetail.EmptyDataSet;
    sql := Format(execSql,[CH0A00]);
    TMidProxy.SqlOpen(sql,clientdtPJDetail);
    WriteDeBug(Format('获取%s病历质量评价信息',[CH0A00]));
  finally

  end;

end;


procedure TFrmBaPJ.suiedtZYHKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  inherited;
  if Key =VK_RETURN then
    ActLocateExecute(nil);
//     SendMessage(Handle, WM_KEYDOWN, VK_TAB, 0);
end;

procedure TFrmBaPJ.suiedtZYHKeyPress(Sender: TObject; var Key: Char);
begin
  inherited;
  if Key in ['!','@','#','$','%','^','&','*','(',')','`',',','.','/','[',']','\','|'] then
    Key := #0;
end;

initialization
  Classes.RegisterClass(TFrmBaPJ);
finalization
  Classes.UnRegisterClass(TFrmBaPJ);

end.
