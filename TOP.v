`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/11 22:20:19
// Design Name: 
// Module Name: TOP
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 这个顶层模块主要做一个uart回环，，上位机给板卡发送数据，板卡接收到数据后在将数据发送会上位机
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module TOP#(
    parameter                           P_SYSTEM_CLK              = 50_000_000,   // 系统时钟频率
    parameter                           P_UART_BUADRATE           = 9600  ,   // 波特率时钟
    parameter                           P_UART_DATA_WIDTH         = 8     ,   // 传输数据位
    parameter                           P_UART_STOP_WIDTH         = 1     ,   // 停止位 1位还是两位
    parameter                           P_UART_CHECK              = 0     // 奇偶校验位 0-无校验 1-odd奇校验 2-even偶校验          
)(
    input                               i_clk_p                      ,
    input                               i_clk_n                      ,
    input                               i_uart_rx                    ,
    output                              o_uart_tx                   
    );


    reg                                     r_user_tx_ready            ;
    reg                                     r_fifo_rden                ;
    reg                                     r_uart_tx_valid            ;

    wire                                    w_clk_rst                  ;
    wire                                    w_clk_50Mhz                ;
    wire     [P_UART_DATA_WIDTH - 1 : 0]    w_user_rx_data             ; 
    wire                                    w_user_rx_valid            ;
    wire                                    w_user_clk                 ;
    wire                                    w_user_rst                 ;
    wire     [P_UART_DATA_WIDTH - 1 : 0]    w_fifo_dout                ;
    wire                                    w_fifo_full                ;
    wire                                    w_fifo_empty               ;
    wire                                    w_user_tx_ready            ;



assign w_clk_rst = ~w_locked ;

//板载时钟过一次锁相环
CLK_GEN CLK_GEN_U0
   (
    .clk_in1_p                  (i_clk_p            ), 
    .clk_in1_n                  (i_clk_n            ),
    .clk_out1                   (w_clk_50Mhz        ),    
    .locked                     (w_locked           )     
);   

//这里用一个fifo将接收到的数据缓存一下，，防止当前数据没发送完，又接收到另外一个数据
//修改数据位宽时，这里fifo也需要修改
FIFO_8x64 FIFO_8x64_U0 (    
    .clk                        (w_user_clk         ),
    .din                        (w_user_rx_data     ),
    .wr_en                      (w_user_rx_valid    ),
    .rd_en                      (r_fifo_rden        ),
    .dout                       (w_fifo_dout        ),
    .full                       (w_fifo_full        ),
    .empty                      (w_fifo_empty       ) 
);


uart_drive#(
    .P_SYSTEM_CLK        ( P_SYSTEM_CLK      ),   // 系统时钟频率
    .P_UART_BUADRATE     ( P_UART_BUADRATE   ),   // 波特率时钟
    .P_UART_DATA_WIDTH   ( P_UART_DATA_WIDTH ),   // 传输数据位
    .P_UART_STOP_WIDTH   ( P_UART_STOP_WIDTH ),   // 停止位 1位还是两位
    .P_UART_CHECK        ( P_UART_CHECK      )    // 奇偶校验位 0-无校验 1-odd奇校验 2-even偶校验          
)
uart_drive_U0
(
    .i_clk                      (w_clk_50Mhz        ),
    .i_rst                      (w_clk_rst          ),
    .i_uart_rx                  (i_uart_rx          ),
    .o_user_rx_data             (w_user_rx_data     ),
    .o_user_rx_valid            (w_user_rx_valid    ),
    .o_uart_tx                  (o_uart_tx          ),
    .i_user_tx_data             (w_fifo_dout        ),
    .i_user_tx_valid            (r_uart_tx_valid    ),
    .o_user_tx_ready            (w_user_tx_ready    ),
    .o_user_clk                 (w_user_clk         ),           
    .o_user_rst                 (w_user_rst         )                                 
);

always@(posedge w_clk_50Mhz or posedge w_clk_rst)begin
    if(w_clk_rst)
        r_user_tx_ready <= 'd0;
    else 
        r_user_tx_ready <= w_user_tx_ready  ; 
end

//这里读使能只能拉高一个时钟周期，读出一个数据，发送完，才可以发送另外的数据
always@(posedge w_clk_50Mhz or posedge w_clk_rst)begin
    if(w_clk_rst)
        r_fifo_rden <= 'd0;
    else if (r_fifo_rden)   
        r_fifo_rden <= 'd0;
    else if(!w_fifo_empty && r_user_tx_ready)
        r_fifo_rden <= 'd1;
    else 
        r_fifo_rden <= 'd0;
end

always@(posedge w_clk_50Mhz or posedge w_clk_rst)begin
    if(w_clk_rst)
        r_uart_tx_valid <= 'd0;
    else if(r_fifo_rden)
        r_uart_tx_valid <= r_fifo_rden; 
end


endmodule
