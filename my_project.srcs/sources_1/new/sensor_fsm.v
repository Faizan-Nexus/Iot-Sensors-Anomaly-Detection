//==============================================================================
// Module: sensor_fsm.v
// Description: 4-State FSM with 4-cycle timing
//              States: IDLE -> VALIDATE -> (ANOMALY/NORMAL) -> IDLE
//              Output label appears in ANOMALY/NORMAL state (Cycle 3)
// Author: Sibau Students 
// Date: November 2025
//==============================================================================
`timescale 1ns / 1ps

module sensor_fsm (
    input  wire        clk,           // System clock
    input  wire        rst,           // Synchronous reset (active high)
    input  wire [7:0]  temp_in,       // Temperature input
    input  wire [7:0]  hum_in,        // Humidity input
    input  wire [7:0]  pres_in,       // Pressure input
    input  wire        valid_in,      // Valid data signal
    output reg  [2:0]  label_out      // 3-bit label: Bit2=Temp, Bit1=Hum, Bit0=Pres (1=anomalous)
);

    //==========================================================================
    // FSM State Encoding (4 states exactly)
    //==========================================================================
    localparam [1:0] IDLE      = 2'b00,
                     VALIDATE  = 2'b01,
                     ANOMALY   = 2'b10,
                     NORMAL    = 2'b11;

    reg [1:0] current_state, next_state;

    //==========================================================================
    // Threshold Parameters
    //==========================================================================
    parameter [7:0] TEMP_LOW_NORMAL  = 8'd48;   // 48°F
    parameter [7:0] TEMP_HIGH_NORMAL = 8'd92;   // 92°F
    
    parameter [7:0] HUM_LOW_NORMAL   = 8'd20;   // 20%
    parameter [7:0] HUM_HIGH_NORMAL  = 8'd77;   // 77%
    
    parameter [7:0] PRES_LOW_NORMAL  = 8'd18;   // 18
    parameter [7:0] PRES_HIGH_NORMAL = 8'd52;   // 52

    //==========================================================================
    // Internal Registers to Store Anomaly Results
    //==========================================================================
    reg temp_anomaly_reg;
    reg hum_anomaly_reg;
    reg pres_anomaly_reg;

    //==========================================================================
    // Anomaly Detection Logic (Combinational)
    //==========================================================================
    wire temp_anomaly_detected, hum_anomaly_detected, pres_anomaly_detected;
    wire any_anomaly_detected;
    
    assign temp_anomaly_detected = (temp_in < TEMP_LOW_NORMAL) || (temp_in > TEMP_HIGH_NORMAL);
    assign hum_anomaly_detected  = (hum_in < HUM_LOW_NORMAL)   || (hum_in > HUM_HIGH_NORMAL);
    assign pres_anomaly_detected = (pres_in < PRES_LOW_NORMAL) || (pres_in > PRES_HIGH_NORMAL);
    assign any_anomaly_detected = temp_anomaly_detected || hum_anomaly_detected || pres_anomaly_detected;

    //==========================================================================
    // State Register (Synchronous)
    //==========================================================================
    always @(posedge clk) begin
        if (rst) begin
            current_state <= IDLE;
            temp_anomaly_reg <= 1'b0;
            hum_anomaly_reg <= 1'b0;
            pres_anomaly_reg <= 1'b0;
        end else begin
            current_state <= next_state;
            
            // Store anomaly results when in VALIDATE state
            if (current_state == VALIDATE) begin
                temp_anomaly_reg <= temp_anomaly_detected;
                hum_anomaly_reg <= hum_anomaly_detected;
                pres_anomaly_reg <= pres_anomaly_detected;
            end
        end
    end

    //==========================================================================
    // Next State Logic (Combinational) - 4-Cycle Timing
    //==========================================================================
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (valid_in)
                    next_state = VALIDATE;  // Cycle 1: IDLE -> VALIDATE
                else
                    next_state = IDLE;      // Stay in IDLE
            end

            VALIDATE: begin
                // Cycle 2: VALIDATE -> ANOMALY/NORMAL based on detection
                if (any_anomaly_detected)
                    next_state = ANOMALY;
                else
                    next_state = NORMAL;
            end

            ANOMALY: begin
                // Cycle 3: ANOMALY -> IDLE
                next_state = IDLE;
            end

            NORMAL: begin
                // Cycle 3: NORMAL -> IDLE
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    //==========================================================================
    // Output Logic (Sequential - Moore Style)
    // Output appears in Cycle 3 (ANOMALY/NORMAL states)
    //==========================================================================
    always @(posedge clk) begin
        if (rst) begin
            label_out <= 3'b000;
        end else begin
            case (current_state)
                IDLE: begin
                    label_out <= 3'b000;      // Cycle 1 & 4: No output
                end

                VALIDATE: begin
                    label_out <= 3'b000;      // Cycle 2: Still no output
                end

                ANOMALY: begin
                    // Cycle 3: Output anomaly results
                    label_out <= {temp_anomaly_reg, hum_anomaly_reg, pres_anomaly_reg};
                end

                NORMAL: begin
                    // Cycle 3: All sensors normal
                    label_out <= 3'b000;
                end

                default: begin
                    label_out <= 3'b000;
                end
            endcase
        end
    end

endmodule