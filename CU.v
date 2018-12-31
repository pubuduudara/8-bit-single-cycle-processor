	module CU(instruction, OUT1addr, OUT2addr, INaddr,Imd,muxI,muxII,muxIII,muxs,CLK);
		input [31:0] instruction;
		output [2:0] OUT1addr, OUT2addr, INaddr;
		output [7:0] Imd;
		output reg muxI,muxII,muxIII;
		output [2:0] muxs;
		input CLK;
		//wire [7:0] RESULT;
		reg [7:0] opcode,dest_reg,source_reg1,source_reg2;
		
		assign muxs=opcode[2:0];
		assign imd=source_reg1;
		assign OUT1addr=source_reg2;
		assign OUT2addr=source_reg1;
		assign INaddr=dest_reg;	
			
		always @ (posedge CLK)
		begin
		#10	 $display("CLK = %b\ninstruction = %b\nop_code = %b\ndest_reg = %b\nsrc1 = %b\nsrc2 = %b\n",CLK, instruction,opcode,dest_reg,source_reg1,source_reg2);
			opcode <= instruction[31:24];
			dest_reg <=instruction[23:16];
			source_reg2<=instruction[15:8];
			source_reg1<=instruction[7:0];
		
			
			case(muxs)
			3'b000:	//loadi
				begin
					muxI=0;
					muxII=0;
					muxIII=0;
				end
			3'b001:	//mov
				begin
					muxI=0;
					muxII=0;
					muxIII=1;
				end
			3'b010:	//add
				begin
					muxI=0;
					muxII=0;
					muxIII=1;
				end
			3'b011:	//sub
				begin
					muxI=0;
					muxII=1;
					muxIII=1;
				end
			3'b100:	//and
				begin
					muxI=0;
					muxII=0;
					muxIII=1;
				end
			3'b101:	//or
				begin
					muxI=0;
					muxII=0;
					muxIII=1;
				end
			
		endcase
		end
	endmodule

	module reg_file(IN, OUT1, OUT2, INaddr, OUT1addr, OUT2addr, CLK, RESET);
		input [7:0] IN;
		input [2:0] OUT1addr, OUT2addr, INaddr;	
		input [1:0] RESET;	
		output [7:0] OUT1;
		output [7:0] OUT2;
		reg OUT1;
		reg OUT2;
		reg [7:0] registers[7:0];
		input CLK;
		always @ (posedge CLK)
			begin
				OUT1 <= registers[OUT1addr];
				OUT2 <= registers[OUT2addr];
				$display("*********Read %b in register %b", OUT1, OUT1addr);
        		$display("*********Read %b in register %b\n", OUT2, OUT2addr);	
			end
		
		always @ (negedge CLK)
			begin
				registers[INaddr]=IN;
				$display("*********Store %b in register %b\n", IN, INaddr);
			end
	endmodule

	module ALU(RESULT,DATA1,DATA2,SELECT);
		input [7:0] DATA1, DATA2;
		output [7:0] RESULT;
		input [2:0] SELECT;
		reg RESULT;
		always @ * begin
			case(SELECT)
			3'b000:	//loadi
				begin
					RESULT = DATA1;
					$display("Forward %b", DATA1);
				end
			3'b001:	//mov
				begin
					RESULT=DATA2;
				end
			3'b010:	//add
				begin
					RESULT = DATA1+DATA2;
					$display("ADD %b, %b", DATA1, DATA2);
				end
			3'b011:	//sub
				begin
					RESULT = DATA1-DATA2;
				end
			3'b100:	//and
				begin
					RESULT = DATA1 & DATA2;
					$display("AND %b, %b", DATA1, DATA2);
				end
			3'b101:	//or
				begin
					RESULT = DATA1 | DATA2;
					$display("OR %b, %b", DATA1, DATA2);
				end
			
			default: RESULT = 0;
			endcase
		end
	endmodule
			
	module mux2to1(out,i0,i1,s); //2:1 mux
		input [7:0] i0,i1;
		input s;
		output [7:0] out;
		assign out=s?i0:i1;
	endmodule
	
	module twosComp(in,out); //twos complement
		input [7:0] in;
		output [7:0] out;
		assign out=~in+1;
	endmodule
	
	module stimulus;
		reg [31:0] instruction;
		wire [2:0] OUT1addr, OUT2addr, INaddr;
		wire [7:0] Imd;
		wire muxI,muxII,muxIII;
		wire [7:0] RESULT;
		wire [2:0] muxs;
		reg CLK;
		wire [7:0] IN;
		wire [7:0] OUT1,OUT2;
		reg [1:0] RESET;
		wire [7:0] out_1;
		wire [7:0] out_2;
		wire [7:0] mux_1_out;
		wire [7:0] DATA1,DATA2;
		CU mycu(instruction, OUT1addr, OUT2addr, INaddr,Imd,muxI,muxII,muxIII,muxs,CLK);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		reg_file myreg(RESULT, OUT1, OUT2, INaddr, OUT1addr, OUT2addr, CLK, RESET);
		/////////////////////////////////////////////
		
		twosComp mytwo1(OUT1,out_1);
		twosComp mytwo2(OUT2,out_2);
		////////////////////////////////////////////////
		
		mux2to1 mymux1(mux_1_out,OUT1,out_1,muxI);
		mux2to1 mymux2(DATA2,OUT2,out_2,muxII);
		mux2to1 mymux3(DATA1,Imd,mux_1_out,muxIII);	
		////////////////////////
		
		
		ALU myalu(RESULT,DATA1,DATA2,muxs);
		
		initial	
		begin
				
			CLK=0;
			//	op			des			src2		src1	
			//	00000000	00000000	00000000	00000110;
			//	loadi		Addr		x			6
		
			//	00000000	00000001	00000000	00000010;
			//	loadi		Addr		x			2
		
			//  00000001	00000010	00000000	00000001;
			//	ADD			RESULT		DATA1		DATA2
		
			//  00000011	00000011	00000000	00000001;
			//	SUB			RESULT		DATA1		DATA2
			
			//  00000100	00000100	00000000	00000001;
			//	AND			RESULT		DATA1		DATA2
		
			//  00000101	00000101	00000000	00000001;
			//	OR			RESULT		DATA1		DATA2
		
			#1  instruction = 32'b00000000000000000000000000000110;
			#15 instruction = 32'b00000000000000010000000000000010;
			#15 instruction = 32'b00000001000000100000000000000001;
			#15 instruction = 32'b00000011000000110000000000000001;
			#15 instruction = 32'b00000011000000110000000000000001;
			#15 instruction = 32'b00000100000001000000000000000001;
			#15 instruction = 32'b00000101000001010000000000000001;
			#20;
			$finish;	
				
		end

		always #5 CLK=~CLK;
		always @(DATA1,DATA2,RESULT) begin
			$display("DATA1: %b = %d\nDATA2: %b = %d\nRSULT: %b = %d\n", DATA1,DATA1,DATA2,DATA2,RESULT,RESULT);		
		end
			
	endmodule	
	
