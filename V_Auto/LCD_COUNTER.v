module LCD_COUNTER (
input CLK ,
input VS  , 
input HS  ,
input DE  , 
output reg [15:0] V_CNT ,
output reg [15:0] H_CNT ,
output reg  LINE ,
output reg  ACTIV_C,
output reg  ACTIV_V
) ;

`include "flipdot_param.h"

reg rHS ;
reg rVS ;

reg [15:0] H_CEN  ;//12'd450 ; 
reg [15:0] V_CEN  ;//12'd250 ; 


always @( posedge CLK  ) begin 
    ACTIV_V <=  HS & VS ; 
    rHS <= HS ;
	 rVS <= VS ;
	 //--H
	 if (!rHS &&  HS  ) begin  
	      { H_CNT ,H_CEN } <= {16'h0, H_CNT  }; 
	 end
	 //else if ( HS ) H_CNT <=H_CNT+1 ; 
	 else if ( DE ) H_CNT <=H_CNT+1 ; 
	 //--V
	 if (!rVS &&  VS  ) begin  
	      { V_CNT , V_CEN} <= {16'h0 ,  V_CNT }; 
	 end
	 else if ((!rHS &&  HS  ) && (VS) )  V_CNT <=V_CNT+1 ; 
	
	//--- H TRIGGER -- DRH: The "+8" is to align the rectangle on the video image with the actual pixels on the flipdot display.
   // Note: positive (+) adjustements to "V" move things down the screen.
	LINE  <= (
	 (( V_CNT == ( V_CEN/2 -V_OFF/2+8)  ) && ( H_CNT >= ( H_CEN/2 -H_OFF/2)  )  &&  ( H_CNT < ( H_CEN/2 +H_OFF/2)  )) ||
	 (( V_CNT == ( V_CEN/2 +V_OFF/2+8)  ) && ( H_CNT >= ( H_CEN/2 -H_OFF/2)  )  &&  ( H_CNT < ( H_CEN/2 +H_OFF/2)  )) ||
	 (( H_CNT == ( H_CEN/2 -H_OFF/2)  ) && ( V_CNT >= ( V_CEN/2 -V_OFF/2+8)  )  &&  ( V_CNT < ( V_CEN/2 +V_OFF/2+8)  )) ||
	 (( H_CNT == ( H_CEN/2 +H_OFF/2)  ) && ( V_CNT >= ( V_CEN/2 -V_OFF/2+8)  )  &&  ( V_CNT < ( V_CEN/2 +V_OFF/2+8)  ))
	 ) ?
	 1:0 ; 
	//--- V TRIGGER ---	
	ACTIV_C <= ( 
	  (( H_CNT >= ( H_CEN/2 -H_OFF/2)  ) &&  ( H_CNT < ( H_CEN/2 +H_OFF/2)  ))
	   &&
	  (( V_CNT >= ( V_CEN/2 -V_OFF/2)  ) &&  ( V_CNT < ( V_CEN/2 +V_OFF/2)  ))
	  )?1:0; 
end


endmodule 