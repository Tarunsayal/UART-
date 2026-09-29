`timescale 1ns/1ps

module tb_uart_top;

    reg clk;
    reg reset;

    reg [7:0] tx_data;
    reg tx_start;

    wire serial_out;
    wire serial_in;

    wire [7:0] rx_data;
    wire rx_data_valid;
    wire rx_error;

    wire tx_busy;
    wire tx_done;
    wire tx_error;

    // --------------------------------------------------
    // Loopback connection
    // --------------------------------------------------

    assign serial_in = serial_out;

    // --------------------------------------------------
    // DUT
    // --------------------------------------------------

    uart_top uut (
        .clk(clk),
        .reset(reset),

        .serialDataRx(serial_in),
        .parallelDataRx(rx_data),
        .dataValidRx(rx_data_valid),
        .errorRx(rx_error),

        .parallelDataTx(tx_data),
        .startTx(tx_start),
        .serialDataTx(serial_out),
        .doneTx(tx_done),
        .busyTx(tx_busy),
        .errorTx(tx_error)
    );

    // --------------------------------------------------
    // Clock: 100 MHz
    // --------------------------------------------------

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // --------------------------------------------------
    // Monitor RX valid pulse
    // --------------------------------------------------

    always @(posedge rx_data_valid) begin

        $display("----------------------------------------");
        $display("RX DATA VALID");
        $display("Time       = %0t", $time);
        $display("RX data    = 0x%h", rx_data);
        $display("RX error   = %b", rx_error);

        if (rx_data == 8'hA5)
            $display("RESULT     = PASS");
        else
            $display("RESULT     = FAIL");

        $display("----------------------------------------");

    end

    // --------------------------------------------------
    // Monitor TX done
    // --------------------------------------------------

    always @(posedge tx_done) begin

        $display("TX DONE at time %0t", $time);

    end

    // --------------------------------------------------
    // Main test
    // --------------------------------------------------

    initial begin

        // Initial values

        reset    = 1'b1;
        tx_data  = 8'h00;
        tx_start = 1'b0;

        // Reset

        #20;
        reset = 1'b0;

        // Give the circuit some time after reset

        #20;

        // --------------------------------------------------
        // Send A5
        // --------------------------------------------------

        tx_data  = 8'hA5;
        tx_start = 1'b1;

        $display("Starting TX at time %0t", $time);

        // IMPORTANT:
        // Your transmitter only starts on sampleSignal,
        // so keep start asserted until busy becomes 1.

        wait(tx_busy == 1'b1);

        $display("TX accepted request at time %0t", $time);

        tx_start = 1'b0;

        // --------------------------------------------------
        // Wait for RECEIVER, not TX
        // --------------------------------------------------

        wait(rx_data_valid == 1'b1);

        $display("Receiver completed at time %0t", $time);

        // --------------------------------------------------
        // Wait for transmitter to finish as well
        // --------------------------------------------------

        wait(tx_done == 1'b1);

        $display("Transmitter completed at time %0t", $time);

        // --------------------------------------------------
        // Final result
        // --------------------------------------------------

        if (rx_data == 8'hA5 && rx_error == 1'b0) begin
            $display("");
            $display("========================================");
            $display("UART LOOPBACK TEST : PASS");
            $display("Expected = 0xA5");
            $display("Received = 0x%h", rx_data);
            $display("========================================");
        end
        else begin
            $display("");
            $display("========================================");
            $display("UART LOOPBACK TEST : FAIL");
            $display("Expected = 0xA5");
            $display("Received = 0x%h", rx_data);
            $display("RX error = %b", rx_error);
            $display("========================================");
        end

        #100;

        $finish;

    end

    // --------------------------------------------------
    // Watchdog
    // --------------------------------------------------

    initial begin

        // Your current UART takes about 1 ms,
        // so give the simulation several ms.

        #5000000;

        $display("");
        $display("========================================");
        $display("WATCHDOG TIMEOUT");
        $display("========================================");
        $display("TX busy   = %b", tx_busy);
        $display("TX done   = %b", tx_done);
        $display("RX valid  = %b", rx_data_valid);
        $display("RX error  = %b", rx_error);
        $display("RX data   = 0x%h", rx_data);

        $display("RX state  = %b", uut.uReceiver.state);

        $finish;

    end

endmodule