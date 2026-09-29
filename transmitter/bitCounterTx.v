module bitCounterTx(
input clk,
input reset,
input enable,
input clear,
input sampleSignal,
output reg [2:0]countTx
);

always@(posedge clk or posedge reset)
begin
    if(reset)
    countTx<=0;
    else if(clear)
    countTx<=0;
    else if(sampleSignal)begin
        if(enable)
        countTx<=countTx+1;
    end
end

endmodule