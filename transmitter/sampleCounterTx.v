module sampleCounterTx(
input sampleSignal,
input clk,
input reset,
input clear,
output reg [3:0]sampleCountTx
);

always@(posedge clk or posedge reset)
begin
    if(reset)
    sampleCountTx<=0;
    else if(clear)
    sampleCountTx<=0;
    else if(sampleSignal)
    begin
        sampleCountTx<=sampleCountTx+1;
    end
end

endmodule