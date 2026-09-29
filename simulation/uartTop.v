module uart_top
(
input clk,
input reset,

//receiver ports
input serialDataRx,
output wire [7:0] parallelDataRx,
output wire errorRx,
output wire dataValidRx,

//transmitter ports
input [7:0] parallelDataTx,
input startTx,//start signal
output wire serialDataTx,
output wire doneTx,
output wire busyTx,
output wire errorTx
);

receiver uReceiver
(
.clk(clk),
.reset(reset),
.serialData(serialDataRx),
.parallelData(parallelDataRx),
.error(errorRx),
.dataValid(dataValidRx)
);

transmitter uTransmitter
(
.clk(clk),
.reset(reset),
.parallelData(parallelDataTx),
.start(startTx),
.serialData(serialDataTx),
.done(doneTx),
.busy(busyTx),
.error(errorTx)
);
endmodule