`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    rtc_test 
// set and read the time from rtc, and send the time to uart port 
//////////////////////////////////////////////////////////////////////////////////

module rtc_test
(
    input          CLK_50M,
	 input          RSTn,
	 
	 input          rx,                  //uart rx
    output         tx,                  //uart tx 
	
	 output         DS1302_RST,                 //ds1302 CE/RST
	 output         DS1302_SCLK,                //ds1302 SCLK
	 inout          DS1302_SIO                  //ds1302 SIO
	 

);


	 
/*******************************/
wire [7:0] Time_second;
wire [7:0] Time_munite;
wire [7:0] Time_hour;

reg [7:0] Time_second_reg;

wire clk;

reg [7:0] time_disp [17:0];                        //洢ַ

reg [15:0] uart_cnt;
reg [2:0] uart_stat;

reg  [7:0]  txdata;             //ڷַ
reg         wrsig;               //ڷЧź

reg [8:0] k;
			  
/********************************************/
//洢͵ʱַ
/********************************************/
always @(*)
begin     //巢͵ַ
	 time_disp[0]<=84;                           //洢ַT 
	 time_disp[1]<=105;                          //洢ַi
    time_disp[2]<=109;                          //洢ַm
	 time_disp[3]<=101;                          //洢ַe 	 
	 time_disp[4]<=32;                           //洢ַո                           
	 time_disp[5]<=105;                          //洢ַi 
	 time_disp[6]<=115;                          //洢ַs
	 time_disp[7]<=32;                           //洢ַո 
	 time_disp[8]<=Time_hour[7:4]+48;            //洢ַСʱʮλ
	 time_disp[9]<=Time_hour[3:0]+48;            //洢ַСʱ
	 time_disp[10]<=58;                           //洢ַ:
	 time_disp[11]<=Time_munite[7:4]+48;         //洢ַʮλ
	 time_disp[12]<=Time_munite[3:0]+48;         //洢ַ
	 time_disp[13]<=58;                          //洢ַ:
	 time_disp[14]<=Time_second[7:4]+48;         //洢ַʮλ
	 time_disp[15]<=Time_second[3:0]+48;         //洢ַ
	 time_disp[16]<=10;                          //з
	 time_disp[17]<=13;                          //س 
end 

/********************************************/
//ڷʱַ
/********************************************/
always @(posedge clk )
begin
  if(!RSTn) begin   
		uart_cnt <= 0;
		uart_stat <= 3'b000;	
		k<=0;
  end
  else begin
  	 case(uart_stat)
	 3'b000: begin               
       if (Time_second_reg != Time_second) begin          //б仯,򴮿ڷʱϢtime_disp[0]~time_disp[17]
		    uart_stat <= 3'b001; 
			 Time_second_reg<=Time_second;
		 end
		 else begin
			 uart_stat <= 3'b000; 
			 Time_second_reg<=Time_second;
		 end
	 end	
	 3'b001: begin                      //͵18ַtime_disp[17]  
         if (k == 17 ) begin          		 
				 if(uart_cnt ==0) begin
					txdata <= time_disp[17]; 
					uart_cnt <= uart_cnt + 1'b1;
					wrsig <= 1'b1;                	//uartЧ			
				 end	
				 else if(uart_cnt ==254) begin      //һַĵȴʱΪ255ʱ,ȴʱֻҪ168ʱ(һֽڷ͵ʱ)
					uart_cnt <= 0;
					wrsig <= 1'b0; 				
					uart_stat <= 3'b010; 
					k <= 0;
				 end
				 else	begin			
					 uart_cnt <= uart_cnt + 1'b1;
					 wrsig <= 1'b0;  
				 end
		 end
	    else begin
				 if(uart_cnt ==0) begin      //ǰ17ַ 
					txdata <= time_disp[k]; 
					uart_cnt <= uart_cnt + 1'b1;
					wrsig <= 1'b1;                			
				 end	
				 else if(uart_cnt ==254) begin //һַĵȴʱΪ255ʱ,ȴʱֻҪ168ʱ(һֽڷ͵ʱ)
					uart_cnt <= 0;
					wrsig <= 1'b0; 
					k <= k + 1'b1;				
				 end
				 else	begin			
					 uart_cnt <= uart_cnt + 1'b1;
					 wrsig <= 1'b0;  
				 end
		 end	 
	 end
	 3'b010: begin       //finish	 
		 	uart_stat <= 3'b000; 
	 end
	 default:uart_stat <= 3'b000;
    endcase 
  end
end
	 
/**********ʱ***********/
clkdiv u0 (
		.clk50                   (CLK_50M),                           
		.clkout                  (clk)             //ڷʱ                 
 );

/**********ڷͳ***********/
uarttx u1 (
		.clk                     (clk),                           
		.datain                  (txdata),
      .wrsig                   (wrsig), 
      .idle                    (idle), 	
	   .tx                      (tx)		
 );
 
/**********RTCʱӿƳ***********/	 
rtc_time U2 (

      .CLK( CLK_50M ), 
	   .RSTn( RSTn ),
		 
	   .Time_second( Time_second ),             //DS1302
	   .Time_munite( Time_munite ),             //DS1302ķ
	   .Time_hour( Time_hour ),                 //DS1302ʱ

	   .RST( DS1302_RST ),
	   .SCLK( DS1302_SCLK ),
	   .SIO( DS1302_SIO )	 

);
	 

wire [35:0]   CONTROL0;
wire [255:0]  TRIG0;
                                                  

assign  TRIG0[7:0]=Time_second;                                               
assign  TRIG0[15:8]=Time_munite;           
assign  TRIG0[23:16]=Time_hour;           

assign  TRIG0[24]=DS1302_RST; 
assign  TRIG0[25]=DS1302_SCLK; 
assign  TRIG0[26]=DS1302_SIO; 
	 

endmodule
