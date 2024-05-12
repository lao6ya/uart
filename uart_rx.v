`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/11 17:36:17
// Design Name: 
// Module Name: uart_rx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 接收模块需要知道什么时候开始接收数据，，也就是接收到起始位开始接收数据，，即i_uart_rx = 0 时，这个时候开始计数，用于后面统计数据
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_rx#(
    parameter      P_SYSTEM_CLK              = 50_000_000   , // 系统时钟频率
    parameter      P_UART_BUADRATE           = 9600         , // 波特率时钟
    parameter      P_UART_DATA_WIDTH         = 8            , // 传输数据位
    parameter      P_UART_STOP_WIDTH         = 1            , // 停止位 1位还是两位
    parameter      P_UART_CHECK              = 0              // 奇偶校验位 0-无校验 1-odd奇校验 2-even偶校验    
)(
    input                                   i_clk                      ,
    input                                   i_rst                      ,

    input                                   i_uart_rx                  ,

    output     [P_UART_DATA_WIDTH - 1 :0]   o_user_rx_data             , //用户接收的数据
    output                                  o_user_rx_valid              //数据有效指示信号  
    );

reg [P_UART_DATA_WIDTH - 1:0]   ro_user_rx_data     ;
reg                             ro_user_rx_valid    ;   
reg [7:0]                       r_cnt               ;   //计数器
reg                             r_tx_check          ;   //奇偶校验

assign o_user_rx_data   = ro_user_rx_data   ;
assign o_user_rx_valid  = ro_user_rx_valid  ;

//用计数器来判断接收的是什么数据
always@(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_cnt <= 'd0;
    else if(r_cnt == P_UART_DATA_WIDTH + 1 + P_UART_STOP_WIDTH && P_UART_CHECK != 0)
        r_cnt <= 'd0;
    else if(r_cnt == P_UART_DATA_WIDTH  + P_UART_STOP_WIDTH && P_UART_CHECK == 0)
        r_cnt <= 'd0;
    else if(i_uart_rx == 0 || r_cnt)    //检测到起始位开始计数
        r_cnt <= r_cnt + 1 ;
    else 
        r_cnt <= r_cnt ; 
end

always@(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_user_rx_data <= 'd0;
    else if(r_cnt >= 1 && r_cnt <= P_UART_DATA_WIDTH)
        ro_user_rx_data <= {i_uart_rx,ro_user_rx_data[P_UART_DATA_WIDTH - 1 : 1]}; //注意串口这里是先发送低位的，，约定俗成的
    else 
        ro_user_rx_data <= ro_user_rx_data ;
end

always@(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_user_rx_valid <= 'd0;
    else if(r_cnt == P_UART_DATA_WIDTH + P_UART_STOP_WIDTH - 1&& P_UART_CHECK == 0)   //无校验
        ro_user_rx_valid <= 'd1;
    else if(r_cnt == P_UART_DATA_WIDTH + 1 + P_UART_STOP_WIDTH - 1&& P_UART_CHECK == 1 && i_uart_rx == !r_tx_check)    //odd校验
        ro_user_rx_valid <= 'd1;
    else if(r_cnt == P_UART_DATA_WIDTH + 1 + P_UART_STOP_WIDTH - 1&& P_UART_CHECK == 2 && i_uart_rx == r_tx_check)     //even校验
        ro_user_rx_valid <= 'd1;
    else 
        ro_user_rx_valid <= 'd0;
end

//用异或判断传输的数据中的1的个数是计数还是偶数，，取反为奇校验，，不取反为偶校验
always@(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_tx_check <= 'd0;
    else if(r_cnt >= 1 && r_cnt <= P_UART_DATA_WIDTH)
        r_tx_check <= r_tx_check ^ i_uart_rx ;
    else 
        r_tx_check <= 'd0;
end

endmodule
