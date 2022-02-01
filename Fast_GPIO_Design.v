`timescale 10 ns / 1 ns

// This module is a basic register used for individual GPIO_IN# and GPIO_OUT# in the diagram, each holding 32 bits
module gpio_reg
#(parameter integer WIDTH = 32)
(
    input rstn,
    input clk,
    input en,
    input [WIDTH-1:0] datain,
    output reg [WIDTH-1:0] dataout
);

    always @(posedge clk or negedge rstn)
        if(!rstn) begin
            dataout <= 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
        end
        else begin
            dataout <= en ? datain : 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
        end
endmodule

// Counter module can count from 0 to 2^(WIDTH)-1 and will be circular going back to 0 when max is hit
module counter
#(parameter integer WIDTH = 2)
(
    input clk,
    output reg [WIDTH-1:0] count
);
    initial count = 0;

    /*always @(posedge clk)
        $strobe("Count: %b", count);*/

    always @ (posedge clk) begin
        count <= count + 1'b1;
    end
endmodule

// This module takes 4 gpio registers and groups them so the counter can easily select which one is in use
// This module needs to be able to change the number of gpio registers from 4 to whatever the desired number is through a variable
module gpio_out
#(
    parameter integer N = 4,
    parameter  integer WIDTH = 32
)
(
    input rstn,
    input clk,

    input sel,
    input wen,
    input [1:0] addr,
    input [WIDTH-1:0] datain,
    output [WIDTH-1:0] dataout,

    inout [WIDTH-1:0] gpio
);
    reg en0, en1, en2, en3;

    gpio_reg #(.WIDTH(WIDTH)) out0(.rstn(reset), .clk(clk), .en(en0), .datain(datain), .dataout(dataout));
    gpio_reg #(.WIDTH(WIDTH)) out1(.rstn(reset), .clk(clk), .en(en1), .datain(datain), .dataout(dataout));
    gpio_reg #(.WIDTH(WIDTH)) out2(.rstn(reset), .clk(clk), .en(en2), .datain(datain), .dataout(dataout));
    gpio_reg #(.WIDTH(WIDTH)) out3(.rstn(reset), .clk(clk), .en(en3), .datain(datain), .dataout(dataout));

    //Prints changes to the variables being strobed
    always @(posedge clk)
    begin
        $strobe("GPIO-out0 Pins: %b, %b", en0, out0.dataout);
        $strobe("GPIO-out1 Pins: %b, %b", en1, out1.dataout);
        $strobe("GPIO-out2 Pins: %b, %b", en2, out2.dataout);
        $strobe("GPIO-out3 Pins: %b, %b", en3, out3.dataout);
    end

    always @(posedge clk) begin
        en0 <= (addr==0) & sel & wen ? 1'b1 : 1'b0;
        en1 <= (addr==1) & sel & wen ? 1'b1 : 1'b0;
        en2 <= (addr==2) & sel & wen ? 1'b1 : 1'b0;
        en3 <= (addr==3) & sel & wen ? 1'b1 : 1'b0;
    end
endmodule

// This module takes 4 gpio registers and groups them so the counter can easily select which one is in use
// This module needs to be able to change the number of gpio registers from 4 to whatever the desired number is through a variable
module gpio_in
#(
    parameter integer N = 4,
    parameter  integer WIDTH = 32
)
(
    input rstn,
    input clk,

    input sel,
    input wen,
    input [1:0] addr,
    input [WIDTH-1:0] datain,
    output [WIDTH-1:0] dataout,

    inout [WIDTH-1:0] gpio
);
    reg en0, en1, en2, en3;

    gpio_reg #(.WIDTH(WIDTH)) in0(.rstn(reset), .clk(clk), .en(en0), .datain(datain), .dataout(dataout));
    gpio_reg #(.WIDTH(WIDTH)) in1(.rstn(reset), .clk(clk), .en(en1), .datain(datain), .dataout(dataout));
    gpio_reg #(.WIDTH(WIDTH)) in2(.rstn(reset), .clk(clk), .en(en2), .datain(datain), .dataout(dataout));
    gpio_reg #(.WIDTH(WIDTH)) in3(.rstn(reset), .clk(clk), .en(en3), .datain(datain), .dataout(dataout));

    //Prints changes to the variables being strobed
    always @(posedge clk)
    begin
        $strobe("GPIO-in0 Pins: %b, %b", en0, in0.dataout);
        $strobe("GPIO-in1 Pins: %b, %b", en1, in1.dataout);
        $strobe("GPIO-in2 Pins: %b, %b", en2, in2.dataout);
        $strobe("GPIO-in3 Pins: %b, %b", en3, in3.dataout);
    end

    always @(posedge clk) begin
        en0 <= (addr==0) & sel & wen ? 1'b1 : 1'b0;
        en1 <= (addr==1) & sel & wen ? 1'b1 : 1'b0;
        en2 <= (addr==2) & sel & wen ? 1'b1 : 1'b0;
        en3 <= (addr==3) & sel & wen ? 1'b1 : 1'b0;
    end
endmodule

//Manages the counter, in and out groups and simulates gpio activity using an initial block
module gpio
#(parameter integer WIDTH = 32,
parameter integer N = 4)
();
    reg clk;
    wire [1:0] count;
    reg reset, select, wen, ren;
    //eg [1:0] addr;
    reg [WIDTH-1:0] dataIN;
    wire [WIDTH-1:0] dataOUT;
    wire [WIDTH-1:0] gpioData;

    assign  gpioData = 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
    assign  dataOUT = 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;

    always begin
	    #50 clk = ~clk;
    end

    //Prints changes to the variables being strobed
    always @(negedge clk)
    begin
        $strobe("\nClock Edge\n");
        $strobe("GPIODATA: %b", gpioData);
        $strobe("DATAOUT: %b", dataOUT);
    end

    //Connect modules with regs and wires
    counter #() counter1(.clk(clk), .count(count));
    gpio_out #(.WIDTH(WIDTH), .N(N)) out(.rstn(reset), .clk(clk), .sel(select), .wen(wen), .addr(count), .datain(dataIN), .dataout(gpioData));
    gpio_in #(.WIDTH(WIDTH), .N(N)) in(.rstn(reset), .clk(clk), .sel(select), .wen(ren), .addr(count), .datain(gpioData), .dataout(dataOUT));

    //GPIO simulation
    initial
        begin
            dataIN = 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
	        clk = 1'b0;
            reset = 1'b0;
            select = 1'b0;
            wen = 1'b0;
            ren = 1'b0;

            @(negedge clk);
            reset = 1'b1;

            @(negedge clk);
            select = 1'b1;
            wen = 1'b1;
            dataIN = 32'b11111111111111111111111111111111;

            @(negedge clk);

            @(negedge clk);

            @(negedge clk);

            $finish;
        end
endmodule