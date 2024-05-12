`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/11 17:32:42
// Design Name: 
// Module Name: uart_drive
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 接收模块不能直接简单的将数据打两拍来跨时钟，因为有时钟频差，多个周期后，累计误差加大，会产生亚稳态，
//如果每次接收数据时，产生一个接收时钟，，这样即使有时钟频差，但是只有10个左右的时钟周期，累计误差不会很大，时钟有效沿不会采集到数据的变化时刻，就不会产生亚稳态，，故采用过采样的方法
//过采样，用比波特率的快的时钟来采样接收的数据i_uart_rx，当检测到起始位后就可以生成 接收时钟了（和波特率时钟频率一样大），也就是过采样主要用来确定生成接收时钟的范围，，即复位信号，，将该信号送到时钟生成模块，，产生接收时钟
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_drive#(
    parameter      P_SYSTEM_CLK        = 50_000_000  ,   // 系统时钟频率
    parameter      P_UART_BUADRATE     = 9600        ,   // 波特率时钟
    parameter      P_UART_DATA_WIDTH   = 8           ,   // 传输数据位
    parameter      P_UART_STOP_WIDTH   = 1           ,   // 停止位 1位还是两位
    parameter      P_UART_CHECK        = 0               // 奇偶校验位 0-无校验 1-odd奇校验 2-even偶校验          
)(
    input                                   i_clk                      ,
    input                                   i_rst                      ,

    input                                   i_uart_rx                  ,
    output     [P_UART_DATA_WIDTH - 1 : 0]  o_user_rx_data             ,
    output                                  o_user_rx_valid            ,

    output                                  o_uart_tx                  ,
    input      [P_UART_DATA_WIDTH - 1 : 0]  i_user_tx_data             ,
    input                                   i_user_tx_valid            ,
    output                                  o_user_tx_ready            ,

    output                                  o_user_clk                 ,           
    output                                  o_user_rst  
);

localparam  P_CLK_DIV_NUMBER = P_SYSTEM_CLK/P_UART_BUADRATE ;

    wire                                            w_uart_buadclk             ;
    wire                                            w_uart_buadclk_rst         ;
    wire               [P_UART_DATA_WIDTH - 1:0]    w_user_rx_data             ;
    wire                                            w_user_rx_valid            ;
    wire                                            w_uart_rx_clk              ;

    reg                                             r_uart_rx_clk_rst          ;
    reg                [   2: 0]                    r_rx_overvalue             ;
    reg                [   2: 0]                    r_rx_overvalue_1d          ;
    reg                                             r_rx_overlock              ;
    reg                                             r_user_rx_valid            ;
    reg                [P_UART_DATA_WIDTH - 1:0]    r_user_rx_data_1d          ;
    reg                                             r_user_rx_valid_1d         ;
    reg                [P_UART_DATA_WIDTH - 1:0]    r_user_rx_data_2d          ;
    reg                                             r_user_rx_valid_2d         ;

assign o_user_clk       = w_uart_buadclk      ;
assign o_user_rst       = w_uart_buadclk_rst  ;
assign o_user_rx_data   = r_user_rx_data_2d   ;
assign o_user_rx_valid  = r_user_rx_valid_2d  ;


//用户时钟（发送时钟，波特率时钟）复位
CLK_DIV_module#(
    .P_CLK_DIV_CNT              (P_CLK_DIV_NUMBER   )    
)
CLK_DIV_module_U0
(
    .i_clk                      (i_clk              ),
    .i_rst                      (i_rst              ),
    .o_clk_div                  (w_uart_buadclk     )
    );

rst_gen_module#(
    .P_RST_CYCLE                (10                 )
)
rst_gen_module_U0
(
    .i_clk                      (w_uart_buadclk     ),
    .o_rst                      (w_uart_buadclk_rst ) 
    );


//接收时钟，复位
CLK_DIV_module#(
    .P_CLK_DIV_CNT              (P_CLK_DIV_NUMBER   )    
)
CLK_DIV_module_U1
(
    .i_clk                      (i_clk              ),
    .i_rst                      (r_uart_rx_clk_rst  ),
    .o_clk_div                  (w_uart_rx_clk      )
    );


uart_rx#(
    .P_SYSTEM_CLK               ( P_SYSTEM_CLK      )  , // 系统时钟频率
    .P_UART_BUADRATE            ( P_UART_BUADRATE   )  , // 波特率时钟
    .P_UART_DATA_WIDTH          ( P_UART_DATA_WIDTH )  , // 传输数据位
    .P_UART_STOP_WIDTH          ( P_UART_STOP_WIDTH )  , // 停止位 1位还是两位
    .P_UART_CHECK               ( P_UART_CHECK      )    // 奇偶校验位 0-无校验 1-odd奇校验 2-even偶校验    
)
uart_rx_U0
(
    .i_clk                      (w_uart_rx_clk       ),
    .i_rst                      (w_uart_buadclk_rst  ), //r_uart_rx_clk_rst
    .i_uart_rx                  (i_uart_rx           ),
    .o_user_rx_data             (w_user_rx_data      ), //用户接收的数据
    .o_user_rx_valid            (w_user_rx_valid     )  //数据有效指示信号  
    );

uart_tx#(
    .P_SYSTEM_CLK               ( P_SYSTEM_CLK       ),   // 系统时钟频率
    .P_UART_BUADRATE            ( P_UART_BUADRATE    ),   // 波特率时钟
    .P_UART_DATA_WIDTH          ( P_UART_DATA_WIDTH  ),   // 传输数据位
    .P_UART_STOP_WIDTH          ( P_UART_STOP_WIDTH  ),   // 停止位 1位还是两位
    .P_UART_CHECK               ( P_UART_CHECK       )    // 奇偶校验位 0-无校验 1-odd奇校验 2-even偶校验          
)
uart_tx_U0
(
    .i_clk                      (w_uart_buadclk     ),
    .i_rst                      (w_uart_buadclk_rst ),
    .o_uart_tx                  (o_uart_tx          ),
    .i_user_tx_data             (i_user_tx_data     ),    //用户要发送的数据
    .i_user_tx_valid            (i_user_tx_valid    ),    //用户发送数据的有效信号
    .o_user_tx_ready            (o_user_tx_ready    )     //准备信号
    );

//过采样，，利用比波特率快的时钟来采样，，这里使用的是系统时钟
always@(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_rx_overvalue <= 'd0;
    else if(!r_rx_overlock)
        r_rx_overvalue <= {r_rx_overvalue[1:0],i_uart_rx};
    else 
        r_rx_overvalue <= 3'b111;
end

//锁信号，，锁信号为低时，，开始过采样，采集到起始位之后，拉高锁信号，，接收到数据之后，，拉低锁信号
always@(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_rx_overlock <= 'd0;
    else if(!w_user_rx_valid && r_user_rx_valid)
        r_rx_overlock <= 'd0;
    else if(r_rx_overvalue_1d != 3'b000 && r_rx_overvalue == 3'b000)
        r_rx_overlock <= 1;
    else 
        r_rx_overlock <= r_rx_overlock;
end

always@(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_rx_overvalue_1d <= 'd0;
    else 
        r_rx_overvalue_1d <= r_rx_overvalue;
end

always@(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_user_rx_valid <= 'd0;
    else 
        r_user_rx_valid <= w_user_rx_valid  ; 
end

// 过采样主要用来确定生成接收时钟的范围，，即复位信号，，将该信号送到时钟生成模块，，产生接收时钟
always@(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_uart_rx_clk_rst <= 'd1;
    else if(!w_user_rx_valid && r_user_rx_valid)
        r_uart_rx_clk_rst <= 'd1;
    else if(r_rx_overvalue_1d != 3'b000 && r_rx_overvalue == 3'b000) 
        r_uart_rx_clk_rst <= 'd0;
    else 
        r_uart_rx_clk_rst <= r_uart_rx_clk_rst ;
end

//接收的数据与接收时钟同步，与用户时钟（发送时钟，波特率时钟）不同步，，但是相差不大，要求不严格，可以直接采用打两拍的方式将接收到的数据同步到用户时钟
always@(posedge w_uart_buadclk or posedge w_uart_buadclk_rst)begin
    if(w_uart_buadclk_rst)begin
        r_user_rx_data_1d  <= 'd0;
        r_user_rx_valid_1d <= 'd0;
        r_user_rx_data_2d  <= 'd0;
        r_user_rx_valid_2d <= 'd0;
    end else begin
        r_user_rx_data_1d  <= w_user_rx_data    ;
        r_user_rx_valid_1d <= w_user_rx_valid   ;
        r_user_rx_data_2d  <= r_user_rx_data_1d ;
        r_user_rx_valid_2d <= r_user_rx_valid_1d;        
    end
end


endmodule
