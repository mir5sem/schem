module tb_core;

    reg clk;
    reg rst;

    core uut (
        .clk(clk),
        .rst(rst)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1;
        #10
        rst = 0;

        #100 $stop;
    end
endmodule
