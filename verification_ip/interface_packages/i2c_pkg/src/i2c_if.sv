import data_pkg::*;
interface i2c_if       #(
			int I2C_DATA_WIDTH = 8,                                
			int I2C_ADDR_WIDTH = 7                              
			)
(
		//System Signals
		//Inputs
		input triand scl_i, 
		input triand sda_i,
		//Outputs
		output triand scl_o,
		output triand sda_o

	);

reg ackToggle = 1'b0;
reg ackToggleTo = 1'b1;
assign sda_o = ackToggle ? ackToggleTo : 1'bz;

task wait_for_i2c_transfer( output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] write_data[]);

	bit trash;
	rcvState_t tempState;
	rcvState_t fsmState;
	bit[I2C_ADDR_WIDTH-1:0] rcvAddx;
	bit[I2C_DATA_WIDTH-1:0] rcvData;
	bit opcode;
	bit ready;


	
	ready = 1'b0;
	tempState = INIT;
	fsmState = START;

	while(1)
	begin
		$display("Start of while loop");
		$display("State at Loop Start = %b", fsmState);
		case(fsmState)
			START:
			begin
				StartOrStop(fsmState, ready, tempState, trash);
				fsmState = ADDRESS;
				$display("State = %b", fsmState);
				ready = 1'b0;
			end

			ADDRESS:
			begin
				for(int i = 6; i >= 0; i--)
				begin
					StartOrStop(fsmState, ready, tempState, rcvAddx[i]);
					fsmState = tempState;
					$display("State = %b", fsmState);
				end
				ready = 1'b1;
				StartOrStop(fsmState, ready, tempState, opcode);
				fsmState = tempState;
				$display("State = %b", fsmState);
				$display("Ack %t", $time);
				ackToggler(1'b0);
				$display("ADDX RECEIVED = %h", rcvAddx);
			end

			DATA:
			begin
				for(int i = 7; i >= 0; i--)
				begin
					StartOrStop(fsmState, ready, tempState, rcvData[i]);
					$display("State = %b", fsmState);
					fsmState = tempState;
				end
				$display("Ack %t", $time);
				ackToggler(1'b0);
				$display("DATA RECEIVED = %d", rcvData);
			end

			STOP:
			begin

				StartOrStop(fsmState, ready, tempState, trash);
				fsmState = tempState;
				$display("State = %b", fsmState);
				ready = 1'b0;
			end

		endcase
		$display("end of while loop");
	end
endtask

task ackToggler(input bit setTo);
	ackToggleTo = setTo;
	@(posedge scl_i) ackToggle = 1'b1;
	@(negedge scl_i) ackToggle = 1'b0;
endtask

task StartOrStop(input rcvState_t currState, input bit readyBit, output rcvState_t outputState, output bit dataBit);
	bit startStop, startStop2;
	wait(scl_i);
	startStop = sda_i;
	wait(~scl_i);
	startStop2 = sda_i;

	if(startStop != startStop2)
	begin
		if(startStop2)
		begin
			outputState = STOP;
			return;
		end
		if(~startStop2)
		begin
			outputState = START;
			return;
		end
	end

	case(currState)
		START: outputState = ADDRESS;
		ADDRESS:begin
			outputState = ADDRESS;
			if(readyBit == 1'b1) outputState = DATA;
		end 
		
		DATA: outputState = DATA;
	endcase

	dataBit = startStop;

endtask

task provide_read_data (    input bit [I2C_DATA_WIDTH-1:0] read_data [], output bit transfer_complete);
endtask

task monitor (   output bit [I2C_ADDR_WIDTH-1:0]  addr, output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] data []);

endtask 
												
endinterface