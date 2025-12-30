module lock_fsm (
    input  wire hw_clk,
    input  wire btn_toggle,
    input  wire btn_enter,
    input  wire btn_next,
    input  wire btn_reset,

    output reg led_red,
    output reg led_green,
    output reg led_blue,
    output reg buzzer
);

    // ==================================================
    // PASSWORD (user order: bit0 bit1 bit2)
    // ==================================================
    parameter [2:0] PASSWORD = 3'b101;

    // ==================================================
    // FSM STATES
    // ==================================================
    parameter LOCKED   = 3'd0;
    parameter ENTER0   = 3'd1;
    parameter ENTER1   = 3'd2;
    parameter ENTER2   = 3'd3;
    parameter LATCH    = 3'd4;
    parameter CHECK    = 3'd5;
    parameter UNLOCKED = 3'd6;
    parameter ERROR    = 3'd7;

    reg [2:0] state = LOCKED;
    reg [2:0] next_state;

    // ==================================================
    // INPUT STORAGE
    // ==================================================
    reg [2:0] input_code;
    reg [2:0] code_latched;

    // ==================================================
    // SLOW CLOCK (BUTTON-FRIENDLY)
    // ==================================================
    reg [21:0] slow_cnt;
    always @(posedge hw_clk)
        slow_cnt <= slow_cnt + 1;

    wire slow_clk = slow_cnt[21];   // ~20–30 Hz

    // ==================================================
    // BUTTON EDGE DETECTION (SLOW CLOCK)
    // ==================================================
    reg btn_toggle_d, btn_next_d, btn_enter_d;

    wire toggle_pressed = btn_toggle_d & ~btn_toggle;
    wire next_pressed   = btn_next_d   & ~btn_next;
    wire enter_pressed  = btn_enter_d  & ~btn_enter;

    // ==================================================
    // BUZZER CONTROL
    // ==================================================
    reg [5:0] buzz_count;   // duration counter

    // ==================================================
    // SEQUENTIAL LOGIC (SLOW CLOCK)
    // ==================================================
    always @(posedge slow_clk) begin
        if (!btn_reset) begin
            state <= LOCKED;
            input_code <= 3'b000;
            code_latched <= 3'b000;

            btn_toggle_d <= 1'b1;
            btn_next_d   <= 1'b1;
            btn_enter_d  <= 1'b1;

            buzzer <= 1'b0;
            buzz_count <= 6'd0;
        end else begin
            // Sample buttons
            btn_toggle_d <= btn_toggle;
            btn_next_d   <= btn_next;
            btn_enter_d  <= btn_enter;

            state <= next_state;

            // ------------------------------
            // Toggle bits
            // ------------------------------
            if (toggle_pressed) begin
                if (state == ENTER0)
                    input_code[0] <= ~input_code[0];
                else if (state == ENTER1)
                    input_code[1] <= ~input_code[1];
                else if (state == ENTER2)
                    input_code[2] <= ~input_code[2];
            end

            // Clear code at start
            if (state == LOCKED && next_state == ENTER0)
                input_code <= 3'b000;

            // Latch input safely
            if (state == ENTER2 && next_state == LATCH)
                code_latched <= input_code;

            // ------------------------------
            // BUZZER EVENT TRIGGERS
            // ------------------------------
            if (state == CHECK && next_state == UNLOCKED)
                buzz_count <= 6'd10;   // short beep

            if (state == CHECK && next_state == ERROR)
                buzz_count <= 6'd25;   // long beep

            // ------------------------------
            // BUZZER OUTPUT CONTROL
            // ------------------------------
            if (buzz_count > 0) begin
                buzzer <= 1'b1;
                buzz_count <= buzz_count - 1'b1;
            end else begin
                buzzer <= 1'b0;
            end
        end
    end

    // ==================================================
    // NEXT STATE LOGIC
    // ==================================================
    always @(*) begin
        next_state = state;

        case (state)
            LOCKED:
                if (enter_pressed)
                    next_state = ENTER0;

            ENTER0:
                if (next_pressed)
                    next_state = ENTER1;

            ENTER1:
                if (next_pressed)
                    next_state = ENTER2;

            ENTER2:
                if (enter_pressed)
                    next_state = LATCH;

            LATCH:
                next_state = CHECK;

            CHECK:
                // Bit-order corrected comparison
                if ({code_latched[0], code_latched[1], code_latched[2]} == PASSWORD)
                    next_state = UNLOCKED;
                else
                    next_state = ERROR;

            UNLOCKED:
                if (enter_pressed)
                    next_state = LOCKED;

            ERROR:
                if (enter_pressed)
                    next_state = LOCKED;

            default:
                next_state = LOCKED;
        endcase
    end

    // ==================================================
    // LED OUTPUT LOGIC (ACTIVE LOW, PRIORITY SAFE)
    // ==================================================
    always @(*) begin
        led_red   = 1'b1;
        led_green = 1'b1;
        led_blue  = 1'b1;

        if (state == UNLOCKED)
            led_green = 1'b0;
        else if (state == LOCKED)
            led_red = 1'b0;
        else if (state == ERROR)
            led_blue = 1'b0;
        else if (state == ENTER0 || state == ENTER1 || state == ENTER2)
            led_blue = 1'b0;
    end

endmodule

