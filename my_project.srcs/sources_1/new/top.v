//==============================================================================
// Module: top.v
// Description: Top-level wrapper for sensor FSM
// Author: Sibau Students
// Date: November 2025
//==============================================================================
`timescale 1ns / 1ps

module top (
    input  wire        CLK,
    input  wire        RST,
    input  wire [7:0]  TB_TEMP_IN,
    input  wire [7:0]  TB_HUM_IN,
    input  wire [7:0]  TB_PRES_IN,
    input  wire        TB_VALID_IN,
    output wire [2:0]  LABEL
);

    // Instantiate with CORRECT port names
    sensor_fsm u_sensor_fsm (
        .clk(CLK),
        .rst(RST),
        .temp_in(TB_TEMP_IN),     // NOT tb_temp_in
        .hum_in(TB_HUM_IN),       // NOT tb_hum_in
        .pres_in(TB_PRES_IN),     // NOT tb_pres_in
        .valid_in(TB_VALID_IN),   // NOT tb_valid_in
        .label_out(LABEL)         // NOT label
    );

endmodule