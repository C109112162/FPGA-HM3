`timescale 1ns / 1ps
module HM3(LED,button1,button2,clk,rst);
output [7:0] LED;
input button1;		//右player
input button2;		//左player
input clk,rst;
wire divclk;
wire click1,click2;

div d1(divclk,clk,rst);
button b1(click1,button1,clk,rst);
button b2(click2,button2,clk,rst);
FSM f1(LED,click1,click2,divclk,clk,rst);
endmodule

//除頻
module div(divclk,clk,rst);

output divclk;
input clk,rst;
reg [25:0] divclkcnt;

assign divclk = divclkcnt[24];

always@(posedge clk or negedge rst)
begin
	if(rst)
		divclkcnt = 0;
	else
		divclkcnt = divclkcnt+1;
end
endmodule

//解彈跳
module button(click,in,clk,rst);
output reg click;
input in,clk,rst;
	
reg [23:0] decnt;
parameter bound =24'hffffff;
always@(posedge clk or negedge rst)
begin
	if(rst)
	begin
		decnt <= 0;
		click <= 0;
	end
	else 
	begin
		if(in)
		begin
		if(decnt < bound)
		begin
			decnt <= decnt+1;
			click <= 0;
		end
		else 
		begin
			decnt <= decnt;
			click <= 1;
		end
	end
	else 
	begin
		decnt <= 0;
		click <= 0;
	end
	end
end
endmodule

//FSM
module FSM(LED,button1,button2,divclk,clk,rst);
output [7:0] LED;
reg [7:0] LED;
input button1,button2;
input divclk,clk,rst;
parameter S0 = 3'b000 ,			//初始發球
			 S1 = 3'b001 ,		//判斷右player是否擊中
			 S2 = 3'b010 ,		//判斷左player是否擊中
			 S3 = 3'b011 ,		//顯示分數，等待右發
			 S4 = 3'b100 ;		//顯示分數，等待左發
parameter LED_S0 = 2'b00 ,		//初始 LED <= 8'b0000_0000
			 LED_S1 = 2'b01 ,	//LED 右移
			 LED_S2 = 2'b10 ,	//LED 左移
			 LED_S3 = 2'b11 ;	//顯示分數
reg [2:0] state;					//FSM狀態
reg [1:0] LED_state;				//LED狀態
reg [3:0] score1 = 0;			//右player分數
reg [3:0] score2 = 0;			//左player分數
reg model = 0;					//判斷LED移動模式或LED顯示分數模式

always@(posedge clk or negedge rst)
begin
if(rst)
begin
	state <= S0;
	score1 <= 0;
	score2 <= 0;
end
else
	case(state)
		S0:begin
			if(button1 == 1)			//右發
			begin
				LED_state <= LED_S2;
				state <= S2;
			end
			else if(button2 == 1)	    //左發
				  begin
					  LED_state <= LED_S1;
					  state <= S1;
				  end				
				  else					//等待發球
				  begin
					  LED_state <= LED_S0;
					  state <= state;
					  score1 <= 0;
	                  score2 <= 0;
				  end
			end
			
		S1:begin
		    if((LED < 8'b1000_0000) && (button1 == 1))      //右早
			begin
				LED_state <= LED_S0;
				score2 <= score2+1;
				state <= S4;
			end
			else if((LED == 8'b0000_0000) && (button2 == 0)) //右漏
			begin
				LED_state <= LED_S0;
				score2 <= score2+1;
				state <= S4;
			end
			if((LED == 8'b1000_0000) && (button1 == 1))		 //判斷右player是否打中
			begin
				LED_state <= LED_S2;
				state <= S2;
			end
			end
			
		S2:begin
		    if((LED > 8'b0000_0001) && (button2 == 1))      //左早
			begin
				LED_state <= LED_S0;
				score1 <= score1+1;
				state <= S3;
			end
			else if((LED == 8'b0000_0000) && (button1 == 0)) //左漏
			begin
				LED_state <= LED_S0;
				score1 <= score1+1;
				state <= S3;
			end
			if((LED == 8'b0000_0001) && (button2 == 1))		 //判斷左player是否打中
			begin
				LED_state <= LED_S1;
				state <= S1;
			end
			end
			
		S3:begin
			if(button1 == 1)		//右發
			begin
				LED_state <= LED_S2;
				state <= S2;
			end
			else
				LED_state <= LED_S3;
			end
			
		S4:begin
			if(button2 == 1)		//左發
			begin
				LED_state <= LED_S1;
				state <= S1;
			end
			else
				LED_state <= LED_S3;
			end	
	endcase
end

//LED_state		
always@(posedge divclk or negedge rst)
begin
if(rst)
    model <= 0;
else
begin
case(LED_state)
	LED_S0:begin		//初始狀態
		LED <= 8'b0000_0000;
		end
	LED_S1:begin		//LED右移
	    if(model)
	    begin
	        LED <= 8'b0000_0001;
	        model <= 0;
	    end
	    else if(LED == 8'b1000_0000)
	        LED <= 8'b0000_0000;
		else if(LED == 8'b0000_0000)
			LED <= {LED[6:0],1'b1};
		else
			LED <= {LED[6:0],LED[7]};
		end
	LED_S2:begin		//LED左移
	    if(model)
	    begin
	        LED <= 8'b1000_0000;
	        model <= 0;
	    end
	    else if(LED == 8'b0000_0001)
	        LED <= 8'b0000_0000;
		else if(LED == 8'b0000_0000)
			LED <= {1'b1,LED[7:1]};
		else
			LED <= {LED[0],LED[7:1]};
	    end
   LED_S3:begin		//LED顯示分數
        LED[7:4] <= score1;
        LED[3:0] <= score2;
        model <= 1;
       end
endcase
end
end
endmodule
