unit udmMain;

interface

uses
  System.SysUtils, System.Classes, FMX.Types, FMX.Controls, IdBaseComponent,
  IdComponent, IdTCPConnection, IdTCPClient;

type
  TdmMain = class(TDataModule)
    StyleBook: TStyleBook;
    Cnt: TIdTCPClient;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  dmMain: TdmMain;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

end.
