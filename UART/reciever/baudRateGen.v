module baudRateGen #(
    parameter integer clkFreq  = 50000000,
    parameter integer baudRate = 9600
)(
    input clk,
    input reset,
    output reg sampleSignal
);

 parameter integer divisor=clkFreq / (baudRate *16) ;//325
 
 reg [12:0]clkCount;

 always @(posedge clk) begin
    if(reset)begin
        clkCount<=0;
        sampleSignal<=0;
    end
    else if(clkCount==divisor-1)begin
        clkCount<=0;
        sampleSignal<=1;
    end
    else begin
        clkCount<=clkCount+1;
        sampleSignal<=0;
    end
 end

endmodule