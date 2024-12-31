//`default_nettype none

module spictrl(
    input  wire       rst,
    input  wire       clk,
    
    // Register interface
    input  wire [7:0] txdata,
    input  wire       txstart,
    output wire [7:0] rxdata,
    output wire       busy,

    input  wire       slow,
    
    // SPI interface
    output wire       spi_sck,
    output wire       spi_mosi,
    input  wire       spi_miso);

    reg [3:0] bitcnt_r;
    assign busy = (bitcnt_r != 'd0);

    reg [7:0] tx_shift_r, rx_shift_r;

    assign spi_mosi = tx_shift_r[7];
    assign rxdata = rx_shift_r;

    reg [5:0] div_cnt_r;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            div_cnt_r <= 0;
        end else begin
            div_cnt_r <= div_cnt_r + 6'd1;
        end
    end

   reg txstart_r;
   always @(posedge clk or posedge rst) begin
      if (rst) 
	begin
           txstart_r <= 1'b0;
        end 
      else
	begin
	   if (txstart_r) 
	     begin
		if (busy)
		  begin
		     // Transmit has begun, clear registered start trigger
		     txstart_r <= 1'b0;
		  end
	     end
	   else
	     if (txstart) 
	       begin
		  txstart_r <= 1'b1;
               end
	end // else: !if(rst)
   end
   
    wire clk_speed = slow ? (div_cnt_r > 'd31) : clk;
    wire clk_gated = (bitcnt_r > 'b1) ? clk_speed : 1'b0;
   
    assign spi_sck = clk_gated;

    always @(posedge clk_speed or posedge rst) begin
        if (rst) begin
            tx_shift_r <= 0;
            rx_shift_r <= 0;
            bitcnt_r   <= 0;

        end else begin
            if (busy) begin
	       if (bitcnt_r != 4'd0) begin
		  tx_shift_r <= {tx_shift_r[6:0], 1'b0};
	       end
	       if (bitcnt_r != 4'd9) begin
		  rx_shift_r <= {rx_shift_r[6:0], spi_miso};
	       end
	       bitcnt_r <= bitcnt_r - 4'd1;

            end else begin
                if (txstart_r) begin
                    tx_shift_r <= txdata;
                    bitcnt_r <= 4'd9;
                end
            end
        end
    end

endmodule
