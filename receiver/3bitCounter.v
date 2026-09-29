module counter3bit(input enable,input sampleSignal,input clk ,input reset ,input clear ,output reg [2:0]count );

    always@(posedge clk or posedge reset)begin

        if(reset)
        count<=0;
        else if(clear)
        count<=0;
        else if (sampleSignal)begin
            if(enable)
            count<=count+1;
    end
    
    end
endmodule