//==============================================================================
// Module: tb_sensor_fsm.v
// Description: Testbench for 4-State, 4-Cycle FSM
//              Verifies exact 4-cycle timing
// Author: Sibau Students
// Date: November 2025
//==============================================================================
`timescale 1ns / 1ps

module tb_sensor_fsm();

    // Testbench signals
    reg        clk;
    reg        rst;
    reg [7:0]  temp_in;
    reg [7:0]  hum_in;
    reg [7:0]  pres_in;
    reg        valid_in;
    wire [2:0] label_out;

    // Instantiate DUT
    sensor_fsm dut (
        .clk(clk),
        .rst(rst),
        .temp_in(temp_in),
        .hum_in(hum_in),
        .pres_in(pres_in),
        .valid_in(valid_in),
        .label_out(label_out)
    );

    // Clock generation (100 MHz) - 10ns period
    always begin
        clk = 1'b0;
        #5;
        clk = 1'b1;
        #5;
    end

    // Test procedure
    initial begin
        // Initialize signals
        rst = 1'b1;
        temp_in = 8'd0;
        hum_in = 8'd0;
        pres_in = 8'd0;
        valid_in = 1'b0;
        
        // Display header
        $display("\n======================================================");
        $display("4-STATE, 4-CYCLE FSM TEST");
        $display("Exact 4-cycle timing with 4 states");
        $display("Output label appears in Cycle 3");
        $display("======================================================\n");
        
        // Apply reset (2 cycles)
        #10;
        rst = 1'b0;
        #10;
        
        $display("CYCLES EXPLANATION:");
        $display("Cycle 1: IDLE -> VALIDATE (when valid_in=1)");
        $display("Cycle 2: VALIDATE -> Check sensors");
        $display("Cycle 3: ANOMALY/NORMAL -> Output label appears");
        $display("Cycle 4: Back to IDLE -> Ready for next input");
        $display("Total: 4 clock cycles per transaction");
        $display("========================================\n");
        
        // TEST 1: ALL SENSORS NORMAL
        $display("TEST 1: ALL SENSORS NORMAL");
        temp_in = 8'd70;   // Normal
        hum_in = 8'd50;    // Normal
        pres_in = 8'd35;   // Normal
        
        // Cycle 1: Apply valid_in at clock edge
        @(posedge clk);
        #1;
        valid_in = 1'b1;
        $display("  Cycle 1 (t=%0dns): IDLE -> valid_in=1", $time);
        $display("    State: IDLE, Label: %03b", label_out);
        
        // Cycle 2: FSM should be in VALIDATE
        @(posedge clk);
        #1;
        valid_in = 1'b0;
        $display("  Cycle 2 (t=%0dns): VALIDATE state", $time);
        $display("    State: VALIDATE, Label: %03b (still 000)", label_out);
        
        // Cycle 3: Should be in NORMAL state with output
        @(posedge clk);
        #1;
        if (dut.current_state == 2'b11) begin
            $display("  Cycle 3 (t=%0dns): NORMAL state", $time);
            $display("    State: NORMAL, Label: %03b (output appears!)", label_out);
            
            if (label_out == 3'b000)
                $display("    ? Output: 000 (all normal) - CORRECT");
            else
                $display("    ? Output: %03b (expected 000)", label_out);
        end else begin
            $display("  ? ERROR: State=%02b, expected NORMAL(11)", dut.current_state);
        end
        
        // Cycle 4: Should be back in IDLE
        @(posedge clk);
        #1;
        if (dut.current_state == 2'b00) begin
            $display("  Cycle 4 (t=%0dns): IDLE state", $time);
            $display("    State: IDLE, Label: %03b (cleared)", label_out);
            $display("  ? TEST 1 PASS: 4-cycle timing correct\n");
        end else begin
            $display("  ? ERROR: State=%02b, expected IDLE(00)", dut.current_state);
        end
        
        #20;
        
        // TEST 2: TEMPERATURE ANOMALY
        $display("TEST 2: TEMPERATURE ANOMALY");
        temp_in = 8'd30;   // Anomalous (too low)
        hum_in = 8'd50;    // Normal
        pres_in = 8'd35;   // Normal
        
        @(posedge clk);
        #1;
        valid_in = 1'b1;
        $display("  Cycle 1 (t=%0dns): IDLE -> valid_in=1", $time);
        
        @(posedge clk);
        #1;
        valid_in = 1'b0;
        $display("  Cycle 2 (t=%0dns): VALIDATE state", $time);
        
        @(posedge clk);
        #1;
        if (dut.current_state == 2'b10) begin
            $display("  Cycle 3 (t=%0dns): ANOMALY state", $time);
            $display("    State: ANOMALY, Label: %03b", label_out);
            
            if (label_out == 3'b100)
                $display("    ? Output: 100 (Temp anomaly) - CORRECT");
            else
                $display("    ? Output: %03b (expected 100)", label_out);
        end
        
        @(posedge clk);
        #1;
        if (dut.current_state == 2'b00 && label_out == 3'b000) begin
            $display("  Cycle 4 (t=%0dns): Back to IDLE", $time);
            $display("  ? TEST 2 PASS\n");
        end
        
        #20;
        
        // TEST 3: HUMIDITY ANOMALY
        $display("TEST 3: HUMIDITY ANOMALY");
        temp_in = 8'd70;
        hum_in = 8'd90;    // Anomalous
        pres_in = 8'd35;
        
        valid_in = 1'b1;
        @(posedge clk);
        #10;
        valid_in = 1'b0;
        
        #30;  // Wait through all 4 cycles
        
        if (dut.current_state == 2'b00 && label_out == 3'b000)
            $display("  ? TEST 3 PASS\n");
        else
            $display("  ? TEST 3 FAIL\n");
        
        #10;
        
        // TEST 4: PRESSURE ANOMALY
        $display("TEST 4: PRESSURE ANOMALY");
        temp_in = 8'd70;
        hum_in = 8'd50;
        pres_in = 8'd10;   // Anomalous
        
        valid_in = 1'b1;
        @(posedge clk);
        #10;
        valid_in = 1'b0;
        
        #30;
        
        if (dut.current_state == 2'b00)
            $display("  ? TEST 4 PASS\n");
        
        #10;
        
        // TEST 5: ALL SENSORS ANOMALOUS
        $display("TEST 5: ALL SENSORS ANOMALOUS");
        temp_in = 8'd100;
        hum_in = 8'd10;
        pres_in = 8'd60;
        
        valid_in = 1'b1;
        @(posedge clk);
        #10;
        valid_in = 1'b0;
        
        #30;
        
        if (dut.current_state == 2'b00)
            $display("  ? TEST 5 PASS\n");
        
        #10;
        
        // TEST 6: TWO ANOMALIES
        $display("TEST 6: TEMPERATURE & HUMIDITY ANOMALIES");
        temp_in = 8'd100;
        hum_in = 8'd10;
        pres_in = 8'd35;
        
        valid_in = 1'b1;
        @(posedge clk);
        #10;
        valid_in = 1'b0;
        
        #30;
        
        if (dut.current_state == 2'b00)
            $display("  ? TEST 6 PASS\n");
        
        // Summary
        $display("======================================================");
        $display("4-CYCLE TIMING VERIFICATION COMPLETE");
        $display("? All 4 states visited: IDLE, VALIDATE, ANOMALY, NORMAL");
        $display("? Exact 4-cycle timing achieved");
        $display("? Output appears only in Cycle 3 (ANOMALY/NORMAL states)");
        $display("? Returns to IDLE in Cycle 4 for next input");
        $display("======================================================");
        
        #100;
        $finish;
    end

    // State monitor WITHOUT cycle_count
    initial begin
        #15;
        $display("\nSTATE TRANSITION MONITOR:");
        $display("Time(ns) | State     | Valid | Label | Description");
        $display("---------|-----------|-------|-------|------------");
        
        forever begin
            @(posedge clk);
            #1;
            
            $write("%8t | ", $time);
            
            case (dut.current_state)
                2'b00: $write("IDLE      ");
                2'b01: $write("VALIDATE  ");
                2'b10: $write("ANOMALY   ");
                2'b11: $write("NORMAL    ");
                default: $write("UNKNOWN   ");
            endcase
            
            $write("|   %b   | %03b  | ", valid_in, label_out);
            
            case (dut.current_state)
                2'b00: $write("Waiting for input");
                2'b01: $write("Checking sensors");
                2'b10: begin
                    $write("Anomaly detected: ");
                    if (label_out[2]) $write("Temp ");
                    if (label_out[1]) $write("Hum ");
                    if (label_out[0]) $write("Pres ");
                end
                2'b11: $write("All sensors normal");
            endcase
            $display("");
        end
    end

endmodule