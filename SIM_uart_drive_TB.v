`timescale 1ns / 1ns    // 单位/精度
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/11 23:05:15
// Design Name: 
// Module Name: SIM_uart_drive_TB
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SIM_uart_drive_TB();

reg clk,rst;

always begin
    clk = 0;
    #10 ;
    clk = 1;
    #10 ;
end

initial begin
    rst <= 1;
    #100 @(posedge clk) rst <= 0;
end


localparam P_USER_DATA_WIDTH = 8;

    wire                                w_uart_tx         ;
    reg     [P_USER_DATA_WIDTH - 1 :0]  r_user_tx_data    ;
    reg                                 r_user_tx_valid   ;
    wire    [P_USER_DATA_WIDTH - 1 :0]  w_user_rx_data    ;
    wire                                w_user_rx_valid   ;
    wire                                w_user_clk        ;
    wire                                w_user_rst        ;
    wire                                w_user_tx_ready   ;
    wire                                w_user_active     ;

assign  w_user_active = w_user_tx_ready && r_user_tx_valid ;

uart_drive#(
    .P_SYSTEM_CLK        ( 50_000_000         ),   // 系统时钟频率
    .P_UART_BUADRATE     ( 9600               ),   // 波特率时钟
    .P_UART_DATA_WIDTH   ( P_USER_DATA_WIDTH  ),   // 传输数据位
    .P_UART_STOP_WIDTH   ( 2                  ),   // 停止位 1位还是两位
    .P_UART_CHECK        ( 1                  )    // 奇偶校验位 0-无校验 1-odd奇校验 2-even偶校验          
)
uart_drive_U0
(
    .i_clk                      (clk                ),
    .i_rst                      (rst                ),
    .i_uart_rx                  (w_uart_tx          ),
    .o_user_rx_data             (w_user_rx_data     ),
    .o_user_rx_valid            (w_user_rx_valid    ),
    .o_uart_tx                  (w_uart_tx          ),
    .i_user_tx_data             (r_user_tx_data     ),
    .i_user_tx_valid            (r_user_tx_valid    ),
    .o_user_tx_ready            (w_user_tx_ready    ),
    .o_user_clk                 (w_user_clk         ),           
    .o_user_rst                 (w_user_rst         )                            
);

always@(posedge w_user_clk or posedge w_user_rst)begin
    if(w_user_rst)
        r_user_tx_valid <= 'd0;
    else if(w_user_active) 
        r_user_tx_valid <= 'd0;
    else if(w_user_tx_ready)
        r_user_tx_valid <= 'd1;
    else 
        r_user_tx_valid <= r_user_tx_valid ;
end

always@(posedge w_user_clk or posedge w_user_rst)begin
    if(w_user_rst)
        r_user_tx_data <= 'd0;
    else if(w_user_active)
        r_user_tx_data <= r_user_tx_data + 1 ;
    else 
        r_user_tx_data <= r_user_tx_data ; 
end

endmodule
