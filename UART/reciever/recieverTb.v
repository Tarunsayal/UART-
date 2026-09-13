`timescale 1ns/1ps

module recieverTb;

    reg serialData;
    reg clk;
    reg reset;

    wire [7:0] parallelData;
    wire error;
    wire dataValid;

    integer i;

    parameter integer divisor  = 50000000 / (9600 * 16);
    parameter integer bitClocks = divisor * 16;

    reciever dut (
        .serialData(serialData),
        .parallelData(parallelData),
        .error(error),
        .dataValid(dataValid),
        .clk(clk),
        .reset(reset)
    );

    initial begin
        clk = 1'b0;
    end

    always #10 clk = ~clk;

    // Sends one complete UART bit.
    // Data changes on the falling edge so it does not race the DUT.
    task send_bit;
        input bitValue;

        begin
            @(negedge clk);
            serialData = bitValue;

            repeat(bitClocks)
                @(negedge clk);
        end
    endtask

    // Check the received result when dataValid pulses.
    always @(posedge dataValid) begin

        $display("Received parallelData = %b", parallelData);

        if (parallelData == 8'h57 && error == 1'b0)
            $display("TEST PASSED");

        else
            $display("TEST FAILED");

        $finish;
    end

    initial begin

        reset      = 1'b1;
        serialData = 1'b1;       // idle line is high

        repeat(5)
            @(negedge clk);

        reset = 1'b0;

        // Start bit
        send_bit(1'b0);

        // Data bits, LSB first
        // Received value = 01010111 = 8'h57
        send_bit(1'b1);   // bit 0
        send_bit(1'b1);   // bit 1
        send_bit(1'b1);   // bit 2
        send_bit(1'b0);   // bit 3
        send_bit(1'b1);   // bit 4
        send_bit(1'b0);   // bit 5
        send_bit(1'b1);   // bit 6
        send_bit(1'b0);   // bit 7

        // Stop bit
        send_bit(1'b1);

        // Leave the line idle
        serialData = 1'b1;
    end

    // Prevent the simulation from hanging if dataValid never occurs.
    initial begin
        #(bitClocks * 20 * 12);

        $display("TEST TIMEOUT");
        $finish;
    end

endmodule