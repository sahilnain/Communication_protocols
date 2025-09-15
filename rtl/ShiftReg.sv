module ShiftReg #(
    parameter WIDTH = 32
) (
    input              reset,
    input              clk,
    input              load,
    input              serialOutEn,
    input              leftRight,
    input              parallelOutEn,
    input              serialIn,
    input [WIDTH:0]    parallelIn,
    output             serialOut,
    output [WIDTH-1:0] parallelOut
);

    // Declarations
    reg             serial_out;
    reg [WIDTH:0]   para2ser;
    reg [WIDTH-1:0] ser2para;

    // Parallel to serial
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            para2ser    <= '1;
        end else if (load) begin
            para2ser    <= parallelIn;
        end else if (serialOutEn) begin
            if (leftRight)
                para2ser <= {para2ser[WIDTH-1:0], 1'b0};
            else
                para2ser <= {1'b0, para2ser[WIDTH-1:0]};
        end
    end

    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            serial_out <= 1'b1;
        end else begin
            if(serialOutEn) begin
                if (leftRight)
                    serial_out <= para2ser[WIDTH];
                else
                    serial_out <= para2ser[0];
            end else
                serial_out <= 1'b1;
        end
    end
    
    // Serial to parallel
    always_ff @(posedge clk or negedge reset) begin
        if (!reset)
            ser2para <= '0;
        else if (parallelOutEn)
            ser2para <= {ser2para[WIDTH-2:0], serialIn};
    end

    assign parallelOut = ser2para;
    assign serialOut   = serial_out;

endmodule