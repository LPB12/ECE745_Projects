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

bit finishedSet;

bit[I2C_DATA_WIDTH-1:0]data_to_write[$];

bit[I2C_ADDR_WIDTH-1:0] rcvAddx;
bit[I2C_DATA_WIDTH-1:0] rcvData;
bit opcode;

bit I2C_mon = 1'b0;

bit monFree = 1'b0;

bit firstRound;


task wait_for_i2c_transfer( output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] write_data[]);

	bit trash;
	rcvState_t tempState;
	rcvState_t fsmState;
	bit ready;
	bit[I2C_DATA_WIDTH-1:0] writeOut;

	firstRound = 1'b1;

	finishedSet = 1'b0;
	ready = 1'b0;
	//opcode = 1'b0;
	tempState = START;
	fsmState = START;

	while(1)
	begin
		//$display("Start of while loop");
		//$display("State at Loop Start = %b", fsmState);
		case(fsmState)
			START:
			begin
				StartOrStop(fsmState, ready, tempState, trash);
				fsmState = ADDRESS;
				//$display("State = %b", fsmState);
				ready = 1'b0;
			end

			ADDRESS:
			begin
				for(int i = 6; i >= 0; i--)
				begin
					StartOrStop(fsmState, ready, tempState, rcvAddx[i]);
					if(fsmState != tempState) break;
					fsmState = tempState;
					//$display("State = %b", fsmState);
				end
				ready = 1'b1;
				StartOrStop(fsmState, ready, tempState, opcode);
				ready = 1'b0;
				fsmState = tempState;
				//$display("State = %b", fsmState);
				//$display("Ack %t", $time);
				ackToggler(1'b0);
				//$display("ADDX RECEIVED = %h", rcvAddx);
			end

			WRITEDATA:
			begin
				for(int i = 7; i >= 0; i--)
				begin
					StartOrStop(fsmState, ready, tempState, rcvData[i]);
					fsmState = tempState;
					if(finishedSet == 1'b1) break;
				end
				if(finishedSet == 1'b1) break;
				ackToggler(1'b0);
				//$display("DATA RECEIVED = %d", rcvData);
			end

			READDATA:
			begin
				writeOut = data_to_write.pop_front();
				//$display("Write Out = %b", writeOut);
				for(int i = I2C_DATA_WIDTH-1; i >= 0; i--)
				begin
					ackToggler(writeOut[i]);
				end
				
				StartOrStop(fsmState, ready, tempState, trash);
				fsmState = tempState;
				if(finishedSet == 1'b1) break;
			end
		endcase
		//$display("end of while loop");
		if(finishedSet == 1'b1) break;
	end

	//$display("Outside the While loop");
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
	wait(!scl_i || (startStop != sda_i));
	startStop2 = sda_i;



	if(startStop != startStop2)
	begin
		outputState = START;

		if(startStop2 == 1'b0)
		begin 
			if(!firstRound) callMonitor();
			else firstRound = 1'b0;
			$display("START!");
			wait(!scl_i);
		end
		if(startStop2 == 1'b1)
		begin 
			callMonitor();
			$display("STOP!");
			finishedSet = 1'b1;
		end
		
	end

	
	if(finishedSet == 1'b0)begin
		case(currState)
			START: outputState = ADDRESS;
			ADDRESS:begin
				outputState = ADDRESS;
				if(readyBit == 1'b1) begin
					if(startStop == 1'b0) outputState = WRITEDATA;
					if(startStop == 1'b1) outputState = READDATA;
				end
			end 
			
			WRITEDATA: outputState = WRITEDATA;
			READDATA: begin
				outputState = READDATA;
				if(startStop == 1'b1) begin 
					outputState = START;
				end 
			end
		endcase
	end
	

	dataBit = startStop;
endtask

task provide_read_data (input bit [I2C_DATA_WIDTH-1:0] read_data [], output bit transfer_complete);
	transfer_complete = 1'b0;

	foreach(read_data[i]) begin
		data_to_write.push_back(read_data[i]);
	end

	transfer_complete = 1'b1;
endtask

task callMonitor();
	if(monFree) begin
		I2C_mon = 1'b1;
		wait(!monFree);
		I2C_mon = 1'b0;
	end
endtask

task monitor (output bit [I2C_ADDR_WIDTH-1:0]  addr, output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] data []);
	
	int dataSize;
	monFree = 1'b1;
	wait(I2C_mon);
	if(opcode == 1'b1) op = I2C_READ;
	if(opcode == 1'b0) op = I2C_WRITE;

	addr = rcvAddx;
	//DO data with queue stuff

	monFree = 1'b0;
	wait(!I2C_mon);

endtask 
												
endinterface