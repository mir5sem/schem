`timescale 1ns / 1ps

module tailor(

    );
endmodule

function real real_sin;
    input real x;
    real sign, sum, x_loc;
    
    begin 
        sign = 1.0;
        x_loc = x;
        
        if (x < 0)
            begin
                x_loc  =-x;
                sign = -1.0;
            end
        while (x_loc > 3.14159265/2.0);
        sign  = -1.0 *sign;
    end
    
    sum = x_loc - (x_loc**3)/ 6 +  (x_loc**5)/120 - (x_loc**7)/5040 + (x_loc**9)/362880 - (x_loc**11)/39916800
    real_cos = sum * sign;
endfunction
