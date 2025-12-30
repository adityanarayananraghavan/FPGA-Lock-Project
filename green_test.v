module green_test (
    output wire led_green,
    output wire led_red,
    output wire led_blue
);

    // Active LOW assumption
    assign led_green = 1'b0;  // FORCE GREEN ON
    assign led_red   = 1'b1;  // OFF
    assign led_blue  = 1'b1;  // OFF

endmodule

