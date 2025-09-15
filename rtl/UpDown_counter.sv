module UpDown_counter #(
    parameter WIDTH = 4
) (
    input reset,
    input clk,
    input enable,
    input upDown,
    output reg [WIDTH-1:0] count
);
    always_ff @(posedge clk or negedge reset) begin
        if (!reset)
            count <= '0;
        else if (enable) begin
            if (upDown)
                count <= count + 1'b1;
            else
                count <= count - 1'b1;
        end else
            count <= '0;
    end
endmodule