module buzzer_test (
    input  wire hw_clk,
    output reg  buzzer
);

    // Simple clock divider for audible on/off
    reg [23:0] cnt;

    always @(posedge hw_clk) begin
        cnt <= cnt + 1'b1;

        // Toggle buzzer roughly every second
        if (cnt[23])
            buzzer <= 1'b1;   // ON
        else
            buzzer <= 1'b0;   // OFF
    end

endmodule

