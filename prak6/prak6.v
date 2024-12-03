`timescale 1ns / 1ps

module testbench;

class seq_item;
    randc bit [7:0] value1;
    randc bit [7:0] value2;
endclass


logic clk = 0;
always #5 clk = ~clk;

logic [7:0] a, b;
logic [8:0] c;

sum uut (
    .clk(clk),
    .a(a),
    .b(b),
    .c(c)
);

seq_item seq_obj;

covergroup seq_cg @(posedge clk);
    cp_value1 : coverpoint seq_obj.value1;
    cp_value2 : coverpoint seq_obj.value2;
    cp_value_sum : coverpoint seq_obj.value1 + seq_obj.value2;
endgroup

seq_cg cg;


sequence sum_seq;
    (c == a + b);
endsequence

property sum_prop;
    @(posedge clk) ##1 sum_seq;
endproperty

property carry_prop;
    @(posedge clk) ##1 ((a + b) > 255 == c[8]);
endproperty

assert property (sum_prop) 
    $info("%d + %d = %d", a, b, c);
else
    $fatal("Error sum: %d + %d = %d", a, b, c);    

assert property (carry_prop)
    $info("Carry %d", c[8]);       
else
    $warning("Carry must exists");

initial
begin
    seq_obj = new();
    cg = new();
    repeat(256)
    begin
        seq_obj.randomize();
        
        a = seq_obj.value1;
        b = seq_obj.value2;
        
        @(posedge clk);
        
        $display("value1 = %d, value2 = %d", seq_obj.value1, seq_obj.value2);
        $display("Coverage: %0.2f %%", cg.get_inst_coverage());
        $display("Coverage cp_value1: %0.2f %%", cg.cp_value1.get_inst_coverage());
        $display("Coverage cp_value2: %0.2f %%", cg.cp_value2.get_inst_coverage());
        $display("Coverage cp_value_sum: %0.2f %% \n", cg.cp_value_sum.get_inst_coverage());
    end    
    
    $display("Coverage: %0.2f %%", cg.get_inst_coverage());
    $finish;
end



endmodule
