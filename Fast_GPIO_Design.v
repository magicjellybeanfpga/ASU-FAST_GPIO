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
#(parameter integer WIDTH = 3)
(
    input wren0,
    output reg [WIDTH-1:0] outSel
);
    initial outSel = 1;

    always @ (posedge wren0) begin
        if(outSel <= 3'b100) begin
            outSel <= outSel + 1'b1;
        end
        else begin
            outSel = 1;
        end
    end
endmodule

//This module sets the enables for each individual gpio register for out and enables the counter
module w_addr_decoder
#(
    parameter  integer WIDTH = 32
)
(
    input sel,
    input w_en,
    input [WIDTH-1:0] addr,
    output reg wren0,
    output reg wren1,
    output reg wren2,
    output reg wren3,
    output reg wren4,
    output reg wren5
);

    always @(*)
    begin
        wren0 <= (addr==0) & sel & w_en ? 1'b1 : 1'b0;
        wren1 <= (addr==1) & sel & w_en ? 1'b1 : 1'b0;
        wren2 <= (addr==2) & sel & w_en ? 1'b1 : 1'b0;
        wren3 <= (addr==3) & sel & w_en ? 1'b1 : 1'b0;
        wren4 <= (addr==4) & sel & w_en ? 1'b1 : 1'b0;
        wren5 <= (addr==5) & sel & w_en ? 1'b1 : 1'b0;
    end

endmodule

//This module sets the enables for each individual gpio register for in
module r_addr_decoder
#(
    parameter  integer WIDTH = 32
)
(
    input sel,
    input rw_en,
    input [WIDTH-1:0] addr,
    output reg rden0,
    output reg rden1,
    output reg rden2,
    output reg rden3
);

    always @(*)
    begin
        rden0 <= (addr==1) & sel & rw_en ? 1'b1 : 1'b0;
        rden1 <= (addr==2) & sel & rw_en ? 1'b1 : 1'b0;
        rden2 <= (addr==3) & sel & rw_en ? 1'b1 : 1'b0;
        rden3 <= (addr==4) & sel & rw_en ? 1'b1 : 1'b0;
    end

endmodule

module wcount_addr_decoder
#(
    parameter  integer WIDTH = 32
)
(
    input [2:0] outSel,
    output reg rdwren0,
    output reg rdwren1,
    output reg rdwren2,
    output reg rdwren3
);

    always @(*)
    begin
        rdwren0 <= (outSel==1)? 1'b1 : 1'b0;
        rdwren1 <= (outSel==2)? 1'b1 : 1'b0;
        rdwren2 <= (outSel==3)? 1'b1 : 1'b0;
        rdwren3 <= (outSel==4)? 1'b1 : 1'b0;
    end

endmodule

// This module takes 4 gpio registers and groups them so the counter can easily select which one is in use
// This module needs to be able to change the number of gpio registers from 4 to whatever the desired number is through a variable
module gpio_out_mux
#(
    parameter integer N = 4,
    parameter  integer WIDTH = 32
)
(
    input rstn,
    input clk,

    input wren1,
    input wren2,
    input wren3,
    input wren4,
    input [2:0] outSel,
    input [WIDTH-1:0] wdata,
    output reg [WIDTH-1:0] dataout
);
    wire [WIDTH-1:0] data0, data1, data2, data3;

    gpio_reg #(.WIDTH(WIDTH)) out0(.rstn(rstn), .clk(clk), .en(wren1), .datain(wdata), .dataout(data0));
    gpio_reg #(.WIDTH(WIDTH)) out1(.rstn(rstn), .clk(clk), .en(wren2), .datain(wdata), .dataout(data1));
    gpio_reg #(.WIDTH(WIDTH)) out2(.rstn(rstn), .clk(clk), .en(wren3), .datain(wdata), .dataout(data2));
    gpio_reg #(.WIDTH(WIDTH)) out3(.rstn(rstn), .clk(clk), .en(wren4), .datain(wdata), .dataout(data3));

    //Prints changes to the variables being strobed
    /*always @(posedge clk)
    begin
        $strobe("GPIO-out0 Pins: %b, %b", outSel, out0.dataout);
        $strobe("GPIO-out1 Pins: %b, %b", outSel, out1.dataout);
        $strobe("GPIO-out2 Pins: %b, %b", outSel, out2.dataout);
        $strobe("GPIO-out3 Pins: %b, %b", outSel, out3.dataout);
    end*/

    always @(*) begin
        if (outSel == 1) begin
            dataout <= data0;
        end
        else if (outSel == 2) begin
            dataout <= data1;
        end
        else if (outSel == 3) begin
            dataout <= data2;
        end
        else if (outSel == 4) begin
            dataout <= data3;
        end
        /*dataout <= (outSel == 0) ? data0 : 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
        dataout <= (outSel == 1) ? data0 : 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
        dataout <= (outSel == 2) ? data0 : 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
        dataout <= (outSel == 3) ? data0 : 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;*/
    end

endmodule

module gpio_en
#(
    parameter  integer WIDTH = 32
)
(
    input clk,
    input wren5,
    input [WIDTH-1:0] endata,
    output reg [WIDTH-1:0] pinout
);

    always @(*)
    begin
        pinout <= wren5 ? endata : 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
    end

endmodule

// This module takes 4 gpio registers and groups them so the counter can easily select which one is in use
// This module needs to be able to change the number of gpio registers from 4 to whatever the desired number is through a variable
module gpio_in_mux
#(
    parameter integer N = 4,
    parameter  integer WIDTH = 32
)
(
    input rstn,
    input clk,

    input rden0,
    input rden1,
    input rden2,
    input rden3,
    input rdwren0,
    input rdwren1,
    input rdwren2,
    input rdwren3,
    input [2:0] outSel,
    input [WIDTH-1:0] addr,
    input [WIDTH-1:0] wdata,
    output reg [WIDTH-1:0] dataout
);
    wire [WIDTH-1:0] data0, data1, data2, data3;
    reg [WIDTH-1:0] wdata0, wdata1, wdata2, wdata3;

    gpio_reg #(.WIDTH(WIDTH)) in0(.rstn(rstn), .clk(clk), .en(rden0), .datain(wdata0), .dataout(data0));
    gpio_reg #(.WIDTH(WIDTH)) in1(.rstn(rstn), .clk(clk), .en(rden1), .datain(wdata1), .dataout(data1));
    gpio_reg #(.WIDTH(WIDTH)) in2(.rstn(rstn), .clk(clk), .en(rden2), .datain(wdata2), .dataout(data2));
    gpio_reg #(.WIDTH(WIDTH)) in3(.rstn(rstn), .clk(clk), .en(rden3), .datain(wdata3), .dataout(data3));

    //Prints changes to the variables being strobed
    /*always @(posedge clk)
    begin
        $strobe("GPIO-in0 Pins: %d, %b", addr, in0.dataout);
        $strobe("GPIO-in1 Pins: %d, %b", addr, in1.dataout);
        $strobe("GPIO-in2 Pins: %d, %b", addr, in2.dataout);
        $strobe("GPIO-in3 Pins: %d, %b", addr, in3.dataout);
        $strobe("GPIO-in0 Pins: %b, %b", rden0, in0.datain);
        $strobe("GPIO-in0 Pins: %b, %b", rden1, in1.datain);
        $strobe("GPIO-in0 Pins: %b, %b", rden2, in2.datain);
        $strobe("GPIO-in0 Pins: %b, %b", rden3, in3.datain);
    end*/

    always @(*) begin
        if (addr == 1) begin
            dataout <= data0;
        end
        else if (addr == 2) begin
            dataout <= data1;
        end
        else if (addr == 3) begin
            dataout <= data2;
        end
        else if (addr == 4) begin
            dataout <= data3;
        end
        /*dataout <= (addr == 0) ? data0 : 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
        dataout <= (addr == 1) ? data1 : 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
        dataout <= (addr == 2) ? data2 : 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
        dataout <= (addr == 3) ? data3 : 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;*/
    end

    always @(*) begin
        wdata0 <= (rdwren0)? wdata : 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
        wdata1 <= (rdwren1)? wdata : 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
        wdata2 <= (rdwren2)? wdata : 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
        wdata3 <= (rdwren3)? wdata : 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
    end

endmodule

//Manages the counter, in and out groups and simulates gpio activity using an initial block
module gpio
#(parameter integer WIDTH = 32,
parameter integer N = 4)
(
    output [WIDTH-1:0] rdata,
    inout [WIDTH-1:0] gpioData
);
    //AHB Bus output
    reg clk;
    reg reset, select, wen, ren;
    reg [WIDTH-1:0] address;
    reg [WIDTH-1:0] wdata;
    reg [WIDTH-1:0] endata;

    //GPIO module local variables
    wire wren0, wren1, wren2, wren3, wren4, wren5;
    wire rden0, rden1, rden2, rden3;
    wire rdwren0, rdwren1, rdwren2, rdwren3;
    wire [2:0] outSel;
    wire [WIDTH-1:0] dataOUT;
    wire [WIDTH-1:0] pinout;
    wire [WIDTH-1:0] readData;

    assign  gpioData = 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzz0zzzz;

    always begin
	    #50 clk = ~clk;
    end

    //Prints changes to the variables being strobed
    always @(negedge clk)
    begin
        $strobe("\nNegative Clock Edge");
        $strobe("GPIODATA: %b", gpioData);
        $strobe("DATAOUT: %b", dataOUT);
        $strobe("READDATA: %b", rdata);
        $strobe("PINOUT: %b", pinout);
    end

    //Connect modules with regs and wires
    counter #() counter1(.wren0(wren0), .outSel(outSel));
    w_addr_decoder #() wAddrDecode(.sel(select), .w_en(wen), .addr(address), .wren0(wren0), .wren1(wren1), .wren2(wren2), .wren3(wren3), .wren4(wren4), .wren5(wren5));
    r_addr_decoder #() rAddrDecode(.sel(select), .rw_en(ren), .addr(address), .rden0(rden0), .rden1(rden1), .rden2(rden2), .rden3(rden3));
    wcount_addr_decoder #() wCountDecode(.outSel(outSel), .rdwren0(rdwren0), .rdwren1(rdwren1), .rdwren2(rdwren2), .rdwren3(rdwren3));
    gpio_en #() gpioEnable(.wren5(wren5), .endata(endata), .pinout(pinout));
    gpio_out_mux #() outMux(.rstn(reset), .clk(clk), .wren1(wren1), .wren2(wren2), .wren3(wren3), .wren4(wren4), .outSel(outSel), .wdata(wdata), .dataout(dataOUT));
    gpio_in_mux #() inMux(.rstn(reset), .clk(clk), .rden0(rden0), .rden1(rden1), .rden2(rden2), .rden3(rden3), .rdwren0(rdwren0), .rdwren1(rdwren1),
            .rdwren2(rdwren2), .rdwren3(rdwren3), .outSel(outSel), .addr(address), .wdata(gpioData), .dataout(readData));

    genvar i;
    generate
        for(i=0;i<32;i=i+1) begin
            assign gpioData[i] = pinout[i] ? dataOUT[i] : 1'bz;
            assign rdata[i] = ~pinout[i] ? readData[i] : 1'bz;
        end
    endgenerate

    //GPIO simulation
    initial
        begin
            wdata = 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
            address = 32'b00000000000000000000000000000000;
            endata = 32'b00000000000000000000000000100001;
	        clk = 1'b0;
            reset = 1'b0;
            select = 1'b0;
            wen = 1'b0;
            ren = 1'b0;

            @(negedge clk);
            reset = 1'b1;
            wen = 1'b1;
            ren = 1'b1;
            select = 1'b1;
            address = 32'b00000000000000000000000000000001;

            @(negedge clk);
            wdata = 32'b11111111111111111111111111111111;

            @(negedge clk);
            address = 32'b00000000000000000000000000000101;

            @(negedge clk);

            $finish;
        end
endmodule