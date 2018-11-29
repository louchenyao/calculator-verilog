module debounce(clk, in, out);
	input clk, in;
	output out;
	reg out;
	
	parameter N=11;
	reg [N-1:0] hold_time;
	reg last, now;
	
	always @ (posedge clk) begin
		last <= now;
		now <= in;
		if (last == now) begin
			if (hold_time != 11'b11111111111) begin
				hold_time <= hold_time + 1;
			end else begin
				out <= now;
			end
		end else begin
			hold_time = 11'b0;
		end
	end
endmodule

module switch(clk, key, out);
	input clk, key;
	output out;
	wire press;
	reg out;
	
	debounce d(clk, key, press);
	always @ (posedge press) begin
		out <= ~out;
	end
endmodule

module alu(A, B, k, C);
	input [3:0] A, B;
	input [1:0] k;
	output [7:0] C;
	reg [7:0] C;
	
	always @ * begin
		case(k)
			2'b00:
				C = {4'b0, A} + {4'b0, B};
			2'b01:
				C = {4'b0, A} - {4'b0, B};
			2'b10:
				C = {4'b0, A} * {4'b0, B};
			2'b11:
				C = {4'b0, A} / {4'b0, B};
		endcase
	end
	
endmodule

module show(clk, D, dig_sel, dig);
	input clk;
	input [7:0] D;
	output [3:0] dig_sel;
	output [6:0] dig;
	reg [3:0] dig_sel;
	reg [6:0] dig;
	
	// We assume -256 <= D <= 255;
	reg [7:0] abs;
	reg [3:0] now;
	reg [1:0] count;
	reg [15:0] count_1;
	
	always @ (posedge clk) begin
		count_1 = count_1 + 1;
		if (count_1 == 0) begin
			count = count + 1;
		end
		
		//dig_sel = 4'b0101;
		//dig = 7'b1111001;
		//now = 4'b0001;
		
		abs = D[7] ? -D : D;
		case (count)
			2'b00: begin
				dig_sel <= 4'b0001;
				now = abs % 10;
			end
			2'b01: begin
				dig_sel <= 4'b0010;
				now = abs / 10 % 10;
			end
			2'b10: begin
				dig_sel <= 4'b0100;
				now = abs / 100 % 10;
			end
			2'b11: begin
				dig_sel <= 4'b1000;
				now = D[7] ? 4'b1111 : 14; // minus sign
			end
		endcase

		case(now)
			0: dig <= 7'b1111110;
			1: dig <= 7'b0110000;
			2: dig <= 7'b1101101;
			3: dig <= 7'b1111001;
			4: dig <= 7'b0110011;
			5: dig <= 7'b1011011;
			6: dig <= 7'b1011111;
			7: dig <= 7'b1110000;
			8: dig <= 7'b1111111;
			9: dig <= 7'b1111011;
			15: dig <= 7'b0000001;
			default:	dig <= 0;
		endcase
	end
endmodule

module main(clk, A, B, inp_k0, inp_k1, inp_k2, k0, k1, D, C, dig_sel, dig);
	input [3:0] A, B;
	input clk, inp_k0, inp_k1, inp_k2;
	output [3:0] dig_sel;
	output [6:0] dig;
	output k0, k1;
	output [2:0] D;
	output [7:0] C;
	
	switch(clk, inp_k0, k0);
	switch(clk, inp_k1, k1);
	
	alu a1(~A, ~B, {k1, k0}, C);
	
	reg [1:0] showing;
	wire k2_press;
	debounce(clk, inp_k2, k2_press);
	always @ (posedge k2_press) begin
		if (showing == 2'b10) begin
			showing <= 2'b00;
		end else begin
			showing <= showing + 1;
		end
	end
	
	reg [2:0] D;
	reg [7:0] num;
	show s(clk, num, dig_sel, dig);
	always @ * begin
		case (showing)
			2'b00: begin
				num = {4'b0, ~A};
				D = 3'b100;
			end
			2'b01: begin
				num = {4'b0, ~B};
				D = 3'b010;
			end
			2'b10: begin
				num = C;
				D = 3'b001;
			end
		endcase
	end
endmodule
