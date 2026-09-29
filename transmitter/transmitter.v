module transmitter(
input clk,
input reset,
input [7:0] parallelData,
input start,//start signal
output reg serialData,
output reg done,
output reg busy,
output reg error
);

localparam s0=2'b00,//idle
           s1=2'b01,//start
           s2=2'b10,//data
           s3=2'b11;//stop

wire [2:0] countTx;
wire [3:0] sampleCountTx;
wire sampleSignal;
wire enable = (state == s2) && (sampleCountTx == 4'd15);
wire clearCounters = (state == s0) && start && sampleSignal;


baudRateGen baud
(
.clk(clk),
.reset(reset),
.sampleSignal(sampleSignal)
);

bitCounterTx count
(
.clk(clk),
.reset(reset),
.enable(enable),
.clear(clearCounters),
.sampleSignal(sampleSignal),
.countTx(countTx)
);

sampleCounterTx sampleCount
(
.clk(clk),
.reset(reset),
.clear(clearCounters),
.sampleSignal(sampleSignal),
.sampleCountTx(sampleCountTx)
);

reg [1:0] state,nextState;
reg [7:0] storage;

always@(posedge clk or posedge reset)
begin
    if(reset)
    begin
        state<=s0;
        storage<=8'h00;
    end

    else
    begin
        if(sampleSignal)
            state<=nextState;

        if(clearCounters)
            storage<=parallelData;
    end
end

always@(*)begin
    serialData=1'b1;
    done=1'b0;
    busy=1'b0;
    error=0;
    nextState=state;

    case(state)
        s0://idle
        begin
            if(start && sampleSignal)
                nextState=s1;
        end

        s1://start
        begin
            serialData=1'b0;
            busy=1'b1;
            if(sampleSignal && sampleCountTx==4'd15)
            begin
                nextState=s2;
            end
        end

        s2://data
        begin
            serialData=storage[countTx];
            busy=1'b1;
            if(sampleSignal && sampleCountTx==4'd15 && countTx == 3'd7)
                nextState=s3;
        end

        s3://stop
        begin
            serialData=1'b1;
            busy=1'b1;
            if(sampleSignal && sampleCountTx==4'd15) begin
                nextState=s0;
                done=1'b1;
            end
        end

        default:
            nextState=s0;
    endcase

end

endmodule