`timescale 1ns/1ps

module tb_transmitter;

    reg clk;
    reg reset;
    reg [7:0] parallelData;
    reg start;

    wire serialData;
    wire done;
    wire busy;
    wire error;

    // Captured frame: [0]=start, [1..8]=data LSB first, [9]=stop
    reg [0:9] captured;
    integer   bitIdx;
    reg [3:0] localCount;
    reg       busy_prev;

    transmitter dut (
        .clk(clk),
        .reset(reset),
        .parallelData(parallelData),
        .start(start),
        .serialData(serialData),
        .done(done),
        .busy(busy),
        .error(error)
    );

    // Optional: speeds up simulation if your baudRateGen uses these parameter names.
    // Comment out or adjust if your module uses different parameter names.
    defparam dut.baud.clkFreq  = 32;
    defparam dut.baud.baudRate = 1;

    // Clock: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Self-contained capture logic.
    // Resets on the rising edge of busy (start of frame).
    // Samples serialData at the middle of each bit period.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            busy_prev  <= 1'b0;
            localCount <= 4'd0;
            bitIdx     <= 0;
            captured   <= 10'b0;
        end else begin
            busy_prev <= busy;

            if (busy && !busy_prev) begin
                // Frame just started: reset local counters, ignore this edge's sampleSignal
                localCount <= 4'd0;
                bitIdx     <= 0;
                captured   <= 10'b0;
            end else if (busy) begin
                if (dut.sampleSignal) begin
                    // Sample at the middle of the bit (count 7 of 0..15)
                    if (localCount == 4'd7) begin
                        if (bitIdx < 10)
                            captured[bitIdx] <= serialData;
                        bitIdx <= bitIdx + 1;
                    end

                    if (localCount == 4'd15)
                        localCount <= 4'd0;
                    else
                        localCount <= localCount + 1'b1;
                end
            end
        end
    end

    // Timeout watchdog
    initial begin
        #10_000_000;
        $display("[TIMEOUT] Simulation did not finish in time.");
        $finish;
    end

    task automatic reset_dut;
        begin
            reset        = 1'b1;
            start        = 1'b0;
            parallelData = 8'h00;
            repeat (4) @(negedge clk);
            reset = 1'b0;
            repeat (2) @(negedge clk);
        end
    endtask

    task automatic send_byte(input [7:0] data);
        reg [0:9] expected;
        integer i;
        begin
            // Wait until transmitter is idle
            wait (busy == 1'b0);

            @(negedge clk);
            parallelData = data;
            start        = 1'b1;

            // Wait until the frame actually starts
            wait (busy == 1'b1);
            @(negedge clk);
            start = 1'b0;

            // Wait for frame completion
            wait (done == 1'b1);
            @(negedge clk);   // allow final NBA updates to settle

            // Build expected UART frame
            expected[0] = 1'b0;               // start bit
            for (i = 0; i < 8; i = i + 1)
                expected[i+1] = data[i];      // LSB first
            expected[9] = 1'b1;               // stop bit

            if (bitIdx != 10) begin
                $display("[FAIL] data=%02h : expected 10 bits, captured %0d bits",
                         data, bitIdx);
            end else if (captured !== expected) begin
                $display("[FAIL] data=%02h : expected=%b captured=%b",
                         data, expected, captured);
            end else begin
                $display("[PASS] data=%02h : frame=%b", data, captured);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_transmitter.vcd");
        $dumpvars(0, tb_transmitter);

        reset_dut;

        send_byte(8'h00);
        send_byte(8'hFF);
        send_byte(8'hA5);
        send_byte(8'h3C);
        send_byte(8'h81);

        @(negedge clk);
        if (busy !== 1'b0)
            $display("[FAIL] busy should be low after frame completion, got %b", busy);
        if (error !== 1'b0)
            $display("[FAIL] error asserted unexpectedly, got %b", error);

        $display("All tests done.");
        $finish;
    end

endmodule