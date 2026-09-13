module reciever(
input serialData,
input clk,
input reset,
output reg [7:0]parallelData,
output reg error,
output reg dataValid
);

localparam s0=2'b00, //ideal state
           s1 =2'b01,//start state 
           s2 =2'b10,//data collection state
           s3 =2'b11;//stop state

reg[1:0]state,nextState;
wire sampleSignal;
wire [3:0]sampleCount;//used to  keep count of sample signal
wire [2:0]count;// used to count data bits
reg rxMeta,rxSync,rxPrevious;//to avoid meta stability


wire enable = (state==s2 && sampleCount==4'd15);
wire fallingEdge;
wire startEdge;

assign fallingEdge = rxPrevious && !rxSync;//to detect the falling edge
assign startEdge   = (state == s0) && fallingEdge;
wire clearSampleCount=  ((state == s1) && sampleSignal &&(sampleCount == 4'd7))
                        ||
                        ((state == s2) && sampleSignal && (sampleCount == 4'd15))
                        ||
                        ((state == s3) && sampleSignal &&(sampleCount == 4'd15));//to clear the sample counter after 7 bit for start bit detection otherwise counter for next state will start from 8

wire clearCount=startEdge;//



baudRateGen baud(.sampleSignal(sampleSignal),
                 .reset(reset),
                 .clk(clk)
                 );

counter3bit counter(.count(count),
                    .sampleSignal(sampleSignal),
                    .reset(reset),
                    .enable(enable),
                    .clear(clearCount),
                    .clk(clk)
                    );

 sampleCounter sampleCounter(
        .sampleCount(sampleCount),
        .startEdge(startEdge),
        .clear(clearSampleCount),
        .sampleSignal(sampleSignal),
        .reset(reset),
        .clk(clk)
    );

//synchronization of the serial data 
always@(posedge clk or posedge reset)begin
    if(reset)begin
        rxMeta<=1;
        rxSync<=1;
        rxPrevious<=1;
    end
    else begin
        rxMeta<=serialData;
        rxSync<=rxMeta;
        rxPrevious<=rxSync;
    end
end


always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= s0;
        error<=0;
        parallelData<=0;
        dataValid<=0;
    end
    else begin
        state <= nextState;
        error<=0;
        dataValid<=0;

        //sampling the data at the middle of each bit period
        if (state == s2 && sampleSignal && sampleCount==4'd15) begin
            parallelData[count] <= rxSync;
        end

        //invalid start bit 
         if (state == s1 && sampleSignal && sampleCount == 4'd7 && rxSync != 1'b0) begin
            error <= 1'b1;
        end

        // verifying stop bit 
        if (state == s3 && sampleSignal && sampleCount == 4'd15) begin
            if (rxSync == 1'b1)
                dataValid <= 1'b1;
            else
                error <= 1'b1;
        end
    end
end

always@(*)
begin
    nextState=state;//kinda like a deafault case to avoid memory creation

    case(state)

    s0:begin
        if(startEdge)
        nextState= s1;
    end

    s1: begin
            // to chekc if the  start bit is in its middle
            if (sampleSignal && sampleCount == 4'd7) begin
                if (rxSync == 1'b0)
                    nextState = s2;
                else
                    nextState = s0;
            end
        end

    s2: begin
            // Sample each data bit every 16 sampleSignal pulses
            if (sampleSignal && sampleCount == 4'd15) begin
                if (count == 3'd7)
                    nextState = s3;
            end
        end

    s3: begin
            // Check the stop bit
            if (sampleSignal && sampleCount == 4'd15)
                nextState = s0;
        end

        default: begin
            nextState = s0;
        end


    endcase
end
        
endmodule