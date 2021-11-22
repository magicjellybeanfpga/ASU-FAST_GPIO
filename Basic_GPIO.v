`timescale 10 ns / 1 ns
module gpio
(
    input rstn,
    input clk,

    input sel,
    input wen,
    input [1:0] addr,
    input [15:0] datain,
    output [15:0] dataout,

    inout [15:0] gpio//output [15:0] gpio
);

    reg [15:0] gpio_out, gpio_en, gpio_in;

    /*always @(posedge clk)
        $strobe("In: %b", gpio_out);*/

    always @(posedge clk or negedge rstn)
        if(!rstn) begin
            gpio_en  <=  0;
            gpio_out <= 0;
        end
        else begin
            gpio_en <= (addr==0) & wen & sel ? datain : gpio_en;
            gpio_out <= (addr==1) & wen & sel ? datain : gpio_out;
            gpio_in <= (addr==2) & !wen & sel ? gpio : gpio_in;
        end

    genvar i;
    generate
        for(i=0;i<16;i=i+1) begin
            assign gpio[i] = gpio_en[i] ? gpio_out[i] : 1'bz;
            assign dataout[i] = ~gpio_en[i] ? gpio[i] : 1'bz;
        end
    endgenerate
endmodule

module gpio_tb
();
    reg reset, clk, select, wen;
    reg [1:0] addr;
    reg [15:0] dataIN;
    wire [15:0] dataOUT;
    wire [15:0] gpioData;

    assign  gpioData = 16'bzzzzzzzzzzzzzz10;

    gpio GPIO_REG(.rstn(reset), .clk(clk), .sel(select), .wen(wen), .addr(addr), .datain(dataIN), .dataout(dataOUT), .gpio(gpioData));

    always
        begin
	        #50 clk = ~clk;
        end

    always @(posedge clk)
        $strobe("GPIO Pins: %b, Read In: %b", gpioData, dataOUT);

    initial
        begin
	        clk = 1'b0;
	        reset = 1'b0;
            select = 1'b1;
            wen = 1'b1;

            @(negedge clk);
	        reset = 1'b1;
            addr = 0;
            dataIN = 16'b1111111111111100;

            @(negedge clk);
            addr = 1;
            dataIN = 16'b0000000000000111;

            @(negedge clk);
            dataIN = 16'bzzzzzzzzzzzzzzzz;

            @(negedge clk);

            $finish;
        end
endmodule