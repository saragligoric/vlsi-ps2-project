module ps2 (input clk,
            input rst_n,
            input ps2clk,
            input ps2data,
            output [3:0] data1,
            output [3:0] data2,
            output [3:0] data3,
            output [3:0] data4);
    
    reg [23:0] buffer_reg, buffer_next;
    assign data1 = buffer_reg[3:0];
    assign data2 = buffer_reg[7:4];
    assign data3 = buffer_reg[11:8];
    assign data4 = buffer_reg[15:12];
    
    localparam idle         = 2'b00;
    localparam reading      = 2'b01;
    localparam done_reading = 2'b10;
    
    reg [1:0] state_reg, state_next;
    reg [3:0] n_reg, n_next;
    reg [10:0] d_reg, d_next;
    wire neg_edge;
    
    reg ff1_next, ff1_reg;
    reg ff2_next, ff2_reg;
    
    assign neg_edge = ~ff1_reg & ff2_reg;
    
    wire [7:0] byte;
    assign byte = d_reg[8:1];
    
    reg reset_reg, reset_next;
    
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            ff1_reg    <= 1'b0;
            ff2_reg    <= 1'b0;
            state_reg  <= idle;
            n_reg      <= 0;
            d_reg      <= 0;
            buffer_reg <= 24'h000000;
            
            reset_reg <= 1'b1;
        end
        else begin
            ff1_reg    <= ff1_next;
            ff2_reg    <= ff2_next;
            state_reg  <= state_next;
            n_reg      <= n_next;
            d_reg      <= d_next;
            buffer_reg <= buffer_next;
            
            reset_reg <= reset_next;
        end
    end
    
    always @(*) begin
        ff1_next = ps2clk;
        ff2_next = ff1_reg;
        
        state_next = state_reg;
        n_next     = n_reg;
        d_next     = d_reg;
        
        buffer_next = buffer_reg;
        reset_next  = reset_reg;
        
        case (state_reg)
            idle: begin
                if (neg_edge) begin
                    n_next     = 4'b1010;
                    state_next = reading;
                end
            end
            
            reading: begin
                if (neg_edge) begin
                    d_next = {ps2data, d_reg[10:1]};
                    n_next = n_reg - 1;
                end
                
                if (n_reg == 0) begin
                    state_next = done_reading;
                end
            end
            
            done_reading: begin
                if (byte == 8'hf0) begin
                    //buffer_next = 24'hf00000;
                    buffer_next   = {16'hf000, buffer_reg[7:0]};
                    end else if (byte == 8'he0) begin
                        //buffer_next = {buffer_reg[23:16], 8'he0, 8'h00};
                        buffer_next   = {buffer_reg[23:16], 8'he0, buffer_reg[7:0]};
                        end else begin  //stigne xx
                            if ((buffer_reg[15:8] > 8'he0) || (buffer_reg[15:8] < 8'he0)) begin //u drugom bajtu nema e0
                                if (buffer_reg[23:16] == 8'hf0) begin   //u trecem bajtu ima f0
                                    buffer_next = {16'h00f0, byte};
                                    end else if ((buffer_reg[23:16] > 8'hf0) || (buffer_reg[23:16] < 8'hf0)) begin  //u trecem bajtu nema f0
                                        buffer_next = {16'h0000, byte};
                                    end
                                    end else if (buffer_reg[15:8] == 8'he0) begin   //u drugom bajtu ima e0
                                        buffer_next = {buffer_reg[23:16], 8'he0, byte};
                                    end
                                end
                                
                                state_next = idle;
                            end //done_reading
                            
        endcase
    end //always @(*)
    
endmodule
    
