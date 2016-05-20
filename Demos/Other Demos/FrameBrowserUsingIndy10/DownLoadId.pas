{
Version   11.7
Copyright (c) 1995-2008 by L. David Baldwin
Copyright (c) 2008-2016 by HtmlViewer Team

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Note that the source modules HTMLGIF1.PAS and DITHERUNIT.PAS
are covered by separate copyright notices located in those modules.

Special thanks go to the Indy Pit Crew that updated *Id9 to *Id10.
}
unit DownLoadId;

{$include htmlcons.inc}
{$include options.inc}

interface

uses
{$ifdef Compiler24_Plus}
  System.Types,
{$endif}
{$ifdef TScrollStyleInSystemUITypes}
  System.UITypes,
{$endif}
{$ifdef LCL}
  LCLIntf, LCLType, LMessages,
{$ELSE}
  WinTypes, WinProcs,
{$ENDIF}
  Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls,
  URLSubs, UrlConn;

const
  wm_DoIt = wm_User + 111;

type
  TDownLoadForm = class(TForm)
    Label2: TLabel;
    Label3: TLabel;
    Status: TLabel;
    TimeLeft: TLabel;
    CancelButton: TButton;
    procedure FormShow(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
  private
    { Private declarations }
    FStartTick: Cardinal;
    FDownLoad: ThtUrlDoc;
    FConnection: ThtConnection;
    procedure WMDoIt(var Message: TMessage); message WM_DoIt;
    procedure DocData(Sender: TObject);
    procedure DocBegin(Sender: TObject);
  public
    { Public declarations }
    DownLoadURL, Filename, Proxy, ProxyPort, UserAgent: string;
    Connections: ThtConnectionManager;

    destructor Destroy; override;
  end;

var
  DownLoadForm: TDownLoadForm;

implementation
{$ifdef HasSystemUITypes}
uses System.UITypes;
{$endif}

{$IFnDEF FPC}
  {$R *.dfm}
{$ELSE}
  {$R *.lfm}
{$ENDIF}

procedure TDownLoadForm.FormShow(Sender: TObject);
begin
  PostMessage(Handle, wm_DoIt, 0, 0);
end;

procedure TDownLoadForm.WMDoIt(var Message: TMessage);
var
  Msg: String;
begin
  try
    try
      FDownLoad := ThtUrlDoc.Create;
      FDownLoad.Url := DownLoadURL;

      FConnection := Connections.CreateConnection(GetProtocol(DownLoadURL));
      FConnection.OnDocData := DocData;
      FConnection.OnDocBegin := DocBegin;
      FConnection.LoadDoc(FDownLoad);     {download it}
      FDownLoad.SaveToFile(Filename);
    except
      on E: Exception do
      begin
        SetLength(Msg, 0);
        if FConnection <> nil then
          Msg := FConnection.ReasonPhrase;
        if Length(Msg) + Length(E.Message) > 0 then
          Msg := Msg + ' ';
        Msg := Msg + E.Message;
        MessageDlg(Msg, mtError, [mbOK], 0);
      end;
    end;
  finally
    Close;
  end;
end;

procedure TDownLoadForm.DocData(Sender: TObject);
var
  ReceivedSize: Int64;
  ExpectedSize: Int64;
  Elapsed: Int64;
  H, M, S: Integer;
begin
  ReceivedSize := FConnection.ReceivedSize;
  ExpectedSize := FConnection.ExpectedSize;
  Elapsed := GetTickCount - FStartTick;
  if Elapsed > 0 then
  begin
    Status.Caption := Format('%dKiB of %dKiB (at %4.1fKiB/sec)', [ReceivedSize div 1024, ExpectedSize div 1024, ReceivedSize/Elapsed]);

    if (ReceivedSize > 0) and (ExpectedSize > 0) then
    begin
      S := Round(((ExpectedSize - ReceivedSize) * (Elapsed / 1000)) / ReceivedSize);
      H := S div 3600;
      S := S mod 3600;
      M := S div 60;
      S := S mod 60;
      TimeLeft.Caption := Format('%2.2d:%2.2d:%2.2d', [H, M, S]);
      TimeLeft.Update;
    end;
  end;
end;

procedure TDownLoadForm.CancelButtonClick(Sender: TObject);
begin
  FConnection.Abort;
end;

//-- BG ---------------------------------------------------------- 18.05.2016 --
destructor TDownLoadForm.Destroy;
begin
  FDownLoad.Free;
  inherited;
end;

procedure TDownLoadForm.DocBegin(Sender: TObject);
begin
  FStartTick := GetTickCount;
end;

end.

