`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/11 17:32:42
// Design Name: 
// Module Name: uart_tx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 思路： uart发送模块，需要发送什么数据（i_user_tx_data ，i_user_tx_valid），什么时候发送（o_user_tx_ready）
// 一般ready先为高，等待valid与data一起过来，ready与valid同时为高,数据发送出去，发送数据时ready为低
//怎么发送数据，利用计数器按照帧格式将数据发出去
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_tx#(
    parameter      P_SYSTEM_CLK        = 50_000_000  ,   // 系统时钟频率
    parameter      P_UART_BUADRATE     = 9600        ,   // 波特率时钟
    parameter      P_UART_DATA_WIDTH   = 8           ,   // 传输数据位
    parameter      P_UART_STOP_WIDTH   = 1           ,   // 停止位 1位还是两位
    parameter      P_UART_CHECK        = 0               // 奇偶校验位 0-无校验 1-odd奇校验 2-even偶校验          
)(
    input                               i_clk                      ,
    input                               i_rst                      ,

    output                              o_uart_tx                  ,

    input  [P_UART_DATA_WIDTH - 1 : 0]  i_user_tx_data             ,    //用户要发送的数据
    input                               i_user_tx_valid            ,    //用户发送数据的有效信号
    output                              o_user_tx_ready                 //准备信号
    );

    reg                                 ro_uart_tx                 ;    //输出寄存器隔离组合逻辑
    reg                                 ro_user_tx_ready           ;    //输出寄存器隔离组合逻辑
    reg    [P_UART_DATA_WIDTH - 1 : 0]  r_tx_data                  ;    //发送数据寄存
    reg                [  15: 0]        r_cnt                      ;    //利用计数器来判断要发送什么数据
    reg                                 r_tx_check                 ;    //异或结果，用作判断1的个数，计数还是偶偶数

    wire                                w_user_active              ;    //发送数据激活信号


    assign                              o_uart_tx         = ro_uart_tx                          ;
    assign                              o_user_tx_ready   = ro_user_tx_ready                    ;
    assign                              w_user_active     = i_user_tx_valid && o_user_tx_ready  ;

//停止位拉高的同时，拉高ready信号，以减小两包数据传输间隔
always@(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_user_tx_ready <= 'd1;
    else if(w_user_active)
        ro_user_tx_ready <= 'd0;
    else if(r_cnt == P_UART_DATA_WIDTH + P_UART_STOP_WIDTH - 1 && P_UART_CHECK == 0)    //这里减1 可以使得串口一直在传输数据（将空闲位卡掉了），提高带宽利用率
        ro_user_tx_ready <= 'd1;
    else if(r_cnt == P_UART_DATA_WIDTH + 1 + P_UART_STOP_WIDTH - 1 && P_UART_CHECK > 0)
        ro_user_tx_ready <= 'd1;
    else 
        ro_user_tx_ready <= ro_user_tx_ready;
end

//计数器用来给ro_uart_tx赋值，，0的时候赋值数据最低位，，1的时候次低位，，，，7的时候数据最高位了
always@(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_cnt <= 'd0;
    else if(r_cnt == P_UART_DATA_WIDTH + P_UART_STOP_WIDTH - 1 && P_UART_CHECK == 0)            //这里 -1 
        r_cnt <= 'd0;
    else if(r_cnt == P_UART_DATA_WIDTH + 1 + P_UART_STOP_WIDTH - 1 && P_UART_CHECK != 0)        //这里 -1 对后续结果没有啥影响
        r_cnt <= 'd0;
    else if(!ro_user_tx_ready)
        r_cnt <= r_cnt + 1;
    else 
        r_cnt <= r_cnt ;
end

always@(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_tx_data <= 'd0;
    else if(w_user_active)
        r_tx_data <= i_user_tx_data ;
    else if(!ro_user_tx_ready)
        r_tx_data <= r_tx_data >> 1 ;
    else 
        r_tx_data <= r_tx_data ;
end

always@(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_uart_tx <= 'd1 ;
    else if(w_user_active)
        ro_uart_tx <= 'd0 ;
    else if(r_cnt == P_UART_DATA_WIDTH && P_UART_CHECK > 0)    //有校验，，添加校验位
        ro_uart_tx <= P_UART_CHECK == 1 ? ~r_tx_check : r_tx_check ;    //进一步判断奇校验还是偶校验
    else if(r_cnt >= P_UART_DATA_WIDTH && P_UART_CHECK == 0)    //无校验，，直接停止位
        ro_uart_tx <= 'd1 ;
    else if(r_cnt >= P_UART_DATA_WIDTH + 1  && P_UART_CHECK > 0)   //有校验，，发送完校验位开始发送停止位
        ro_uart_tx <= 'd1 ;
    else if(!ro_user_tx_ready)
        ro_uart_tx <= r_tx_data[0];
    else 
        ro_uart_tx <= 'd1;
end

//奇偶校验： 这里通过异或的方式判断传输数据的1的个数
always@(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_tx_check <= 'd0;
    else if(r_cnt == P_UART_DATA_WIDTH)
        r_tx_check <= 'd0;   
    else 
        r_tx_check <= r_tx_check ^ r_tx_data[0];
end


endmodule
