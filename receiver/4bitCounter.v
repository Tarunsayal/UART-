module sampleCounter(
    input clk,
    input reset,
    input startEdge,
    input sampleSignal,
    input clear,
    output reg [3:0] sampleCount
);

always @(posedge clk or posedge reset) begin
    if (reset)
        sampleCount <= 4'd0;
    else if (startEdge || clear)
        sampleCount <= 4'd0;
    else if (sampleSignal)
        sampleCount <= sampleCount + 4'd1;
end

endmodule