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
//upadted to not need address - needs clarification (new design functions sequantially rather than by address by shifting on clk and en)
module w_addr_decoder
#(
    parameter  integer WIDTH = 32

)
(
    input sel,
    input w_en,
    input clk,
    input rst,
    input [WIDTH-1:0] addr,
    output  reg [WIDTH-1:0] wren
);
    initial wren 32'b00000000000000000000000000000001;
    always @(posedge clk or negedge rst and w_en)
    begin
        if (wren[WIDTH-1] <= 1'b1) begin
            wren = 1;
        end
        else begin 
	         wren <= wren << 1;
	      end
    end

endmodule

//This module sets the enables for each individual gpio register for in
//upadted to not need address - needs clarification (new design functions sequantially rather than by address by shifting on clk and en)
module r_addr_decoder
#(
    parameter  integer WIDTH = 32
)
(
    input sel,
    input rw_en,
    input rst,
    input clk,
    input [WIDTH-1:0] addr,
    output reg [WIDTH-1:0] rden
);
    initial  rden 32'b00000000000000000000000000000001;
    always @(posedge clk or negedge rst and rw_en)
    begin
        if (rden[WIDTH-1] <= 1'b1) begin
            rden = 1;
        end
        else begin 
	          rden <= rden << 1;
	      end
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

//-------------------------------

//replaced gpio_in_mux and gpio_out_mux with this - Ian

module gpio_create  //propagates N gpio in modules and M gpio out modules
#(
    parameter integer N = 4,
    parameter  integer WIDTH = 32
)
(
    input rst,
    input clk,

    input wren,
    input rden,
    
    input [WIDTH-1:0] addr,
    input [WIDTH-1:0] wdata,
    output reg [WIDTH-1:0] dataout
);

    genvar gi;
    generate
	for (gi = 0; gi&lt;N; gi = gi + 1) begin : gpio_in
	    wire [WIDTH-1:0] data;
	    reg [WIDTH-1:0] wdata;
	    
	    gpio_reg #(.WIDTH(WIDTH)) in(.rstn(rst), .clk(clk), .en(rden), .datain(wdata), .dataout(data));
	end

	for (gi = 0; gi&lt;M; gi = gi + 1) begin : gpio_out
	    wire [WIDTH-1:0] data;

            gpio_reg #(.WIDTH(WIDTH)) out(.rstn(rst), .clk(clk), .en(wren), .datain(wdata), .dataout(data));
	end
	
    endgenerate

    //needs testing module still

endmodule




//--------------------------------

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
