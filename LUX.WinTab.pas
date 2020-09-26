﻿unit LUX.WinTab;

interface //#################################################################### ■

uses FMX.Forms,
     Winapi.Windows,
     WINTAB;

type //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【型】

     //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【レコード】

     //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TTabletPacket

     TTabletPacket = packed record
     { Context         :HCTX;         // PK_CONTEXT       }
       Status          :UINT;         // PK_STATUS
     { Time            :DWORD;        // PK_TIME          }
     { Changed         :WTPKT;        // PK_CHANGED       }
     { SerialNumber    :UINT;         // PK_SERIAL_NUMBER }
       Cursor          :UINT;         // PK_CURSOR
       Buttons         :DWORD;        // PK_BUTTONS
       X               :LONG;         // PK_X
       Y               :LONG;         // PK_Y
       Z               :LONG;         // PK_Z
       NormalPressure  :UINT;         // PK_NORMAL_PRESSURE
       TangentPressure :UINT;         // PK_TANGENT_PRESSURE
       Orientation     :ORIENTATION;  // PK_ORIENTATION
     end;

     //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【クラス】

     //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TPenTablet

     TPacketEvent = reference to procedure( const Packet_:TTabletPacket );

     TPenTablet = class
     private
     protected
       _Tablet  :HCTX;
       _PosMinX :Integer;
       _PosMinY :Integer;
       _PosMaxX :Integer;
       _PosMaxY :Integer;
       _ResX    :Integer;
       _ResY    :Integer;
       _UniX    :Integer;
       _UniY    :Integer;
       _PreMin  :Integer;
       _PreMax  :Integer;
       _WheMin  :Integer;
       _WheMax  :Integer;
       _AziMin  :Integer;
       _AziMax  :Integer;
       _AltMin  :Integer;
       _AltMax  :Integer;
       _TwiMin  :Integer;
       _TwiMax  :Integer;
       ///// イベント
       _OnPacket :TPacketEvent;
       ///// メソッド
       procedure GetInfos;
       procedure BeginTablet( const Form_:TCommonCustomForm );
       procedure EndTablet;
       procedure OnMessage( const MSG_:TMsg );
     public
       constructor Create( const Form_:TCommonCustomForm );
       destructor Destroy; override;
       ///// プロパティ
       property PosMinX :Integer read _PosMinX;
       property PosMinY :Integer read _PosMinY;
       property PosMaxX :Integer read _PosMaxX;
       property PosMaxY :Integer read _PosMaxY;
       property ResX    :Integer read _ResX;
       property ResY    :Integer read _ResY;
       property UniX    :Integer read _UniX;
       property UniY    :Integer read _UniY;
       property PreMin  :Integer read _PreMin;
       property PreMax  :Integer read _PreMax;
       property WheMin  :Integer read _WheMin;
       property WheMax  :Integer read _WheMax;
       property AziMin  :Integer read _AziMin;
       property AziMax  :Integer read _AziMax;
       property AltMin  :Integer read _AltMin;
       property AltMax  :Integer read _AltMax;
       property TwiMin  :Integer read _TwiMin;
       property TwiMax  :Integer read _TwiMax;
       ///// イベント
       property OnPacket :TPacketEvent read _OnPacket write _OnPacket;
     end;

const //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【定数】

      // this constant is used to define PACKET record
      PACKETDATA = PK_STATUS
                or PK_CURSOR
                or PK_BUTTONS
                or PK_X
                or PK_Y
                or PK_Z
                or PK_NORMAL_PRESSURE
                or PK_TANGENT_PRESSURE
                or PK_ORIENTATION;

      // this constant is used to define PACKET record
      PACKETMODE = 0; //This means all values are reported "absoulte"

//var //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【変数】

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【ルーチン】

implementation //############################################################### ■

uses FMX.Platform.Win,
     LUX.FMX.Messaging.Win;

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【レコード】

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【クラス】

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TPenTablet

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& private

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& protected

procedure TPenTablet.GetInfos;
var
   A :AXIS;
   A3 :array [ 1..3 ] of AXIS;
begin
     WTInfo( WTI_DEVICES, DVC_X, @A );
     _PosMinX :=         A.axMin;                  // Ｘ座標の最小値
     _PosMaxX :=         A.axMax;                  // Ｘ座標の最大値
     _UniX    :=         A.axUnits;                // Ｘ座標の単位
     _ResX    := HIWORD( A.axResolution );         // Ｘ座標の分解能（line/inch）

     WTInfo( WTI_DEVICES, DVC_Y, @A );
     _PosMinY :=         A.axMin;                  // Ｙ座標の最小値
     _PosMaxY :=         A.axMax;                  // Ｙ座標の最大値
     _UniY    :=         A.axUnits;                // Ｙ座標の単位
     _ResY    := HIWORD( A.axResolution );         // Ｙ座標の分解能（line/inch）

     WTInfo( WTI_DEVICES, DVC_NPRESSURE, @A );
     _PreMin := A.axMin;                          // 筆圧の最小値
     _PreMax := A.axMax;                          // 筆圧の最大値

     WTInfo( WTI_DEVICES, DVC_TPRESSURE, @A );
     _WheMin := A.axMin;                          // ホイールの最小値
     _WheMax := A.axMax;                          // ホイールの最大値

     WTInfo( WTI_DEVICES, DVC_ORIENTATION, @A3 );
     _AziMin := A3[ 1 ].axMin;                    // ペンの方位の最小値
     _AziMax := A3[ 1 ].axMax;                    // ペンの方位の最大値
     _AltMin := A3[ 2 ].axMin;                    // ペンの傾きの最小値
     _AltMax := A3[ 2 ].axMax;                    // ペンの傾きの最大値
     _TwiMin := A3[ 3 ].axMin;                    // ペンの捩れの最小値
     _TwiMax := A3[ 3 ].axMax;                    // ペンの捩れの最大値
end;

//------------------------------------------------------------------------------

procedure TPenTablet.BeginTablet( const Form_:TCommonCustomForm );
var
   C :LOGCONTEXT;
begin
     WTInfo( WTI_DEFSYSCTX, 0, @C );

     with C do
     begin
          lcOptions   := lcOptions or CXO_MESSAGES;
          lcMsgBase   := WT_DEFBASE;
          lcPktData   := PACKETDATA;
          lcPktMode   := PACKETMODE;
          lcMoveMask  := PACKETDATA;
          lcBtnUpMask := lcBtnDnMask;

          lcInOrgX    := _PosMinX;  // 入力Ｘ座標の最小値
          lcInOrgY    := _PosMinY;  // 入力Ｙ座標の最小値
          lcInExtX    := _PosMaxX;  // 入力Ｘ座標の最大値
          lcInExtY    := _PosMaxY;  // 入力Ｙ座標の最大値
          lcOutOrgX   := _PosMinX;  // ウィンドウＸ座標の最小値
          lcOutOrgY   := _PosMinY;  // ウィンドウＹ座標の最小値
          lcOutExtX   := _PosMaxX;  // ウィンドウＸ座標の最大値
          lcOutExtY   := _PosMaxY;  // ウィンドウＹ座標の最大値
     end;

     _Tablet := WTOpen( FormToHWND( Form_ ), @C, True );  // Wintab の初期化

     Assert( _Tablet > 0, '_Tablet = 0' );
end;

procedure TPenTablet.EndTablet;
begin
     WTClose( _Tablet );
end;

//------------------------------------------------------------------------------

procedure TPenTablet.OnMessage( const MSG_:TMsg );
var
   P :TTabletPacket;
begin
     WTPacket( MSG_.lParam, MSG_.wParam, @P );

     if Assigned( _OnPacket ) then _OnPacket( P );
end;

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& public

constructor TPenTablet.Create( const Form_:TCommonCustomForm );
begin
     inherited Create;

     GetInfos;

     BeginTablet( Form_ );

     TMessageService.EventList.Add( WT_PACKET, OnMessage );
end;

destructor TPenTablet.Destroy;
begin
     EndTablet;

     inherited;
end;

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【ルーチン】

//############################################################################## □

initialization //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ 初期化

finalization //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ 最終化

end. //######################################################################### ■