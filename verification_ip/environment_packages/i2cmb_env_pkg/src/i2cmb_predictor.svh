class i2cmb_predictor extends ncsu_component#(.T(wb_transaction)); 
  i2cmb_scoreboard scoreboard;
  i2c_transaction i2c_output_trans, i2c_predicted_trans;
  i2cmb_env_configuration configuration;
  bit [7:0] i2c_data[$];
  bit [7:0] read_vals[$];
  int q_size;

  bit transfer_complete = 1'b0;
  predictorState_t pred_state = WAIT;
  bit[7:0] DPR_data;

   parameter CSR = 8'h00;
  parameter DPR = 8'h01;
  parameter CMDR = 8'h02;
  parameter FSMR = 8'h03;
  parameter WRITE = 1'b0;
  parameter READ = 1'b1;
  parameter CMDR_WRITE = 8'bxxxxx001;
  parameter CMDR_READACK = 8'bxxxx_x010;
  parameter CMDR_READNACK = 8'bxxxx_x011;
  parameter CMDR_START = 8'bxxxxx100;
  parameter CMDR_STOP = 8'bxxxxx101;
  

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  function void set_configuration(i2cmb_env_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void set_scoreboard(i2cmb_scoreboard scoreboard);
      this.scoreboard = scoreboard;
  endfunction

  virtual function void nb_put(T trans);
 
    
    
  

    case(pred_state)
      WAIT: begin
        // $display("Wait");
        
        transfer_complete = 1'b0;
        if({5'bxxxxx, trans.data[2:0]} === CMDR_START && trans.addr == CMDR) pred_state = ADDR;
      end
      ADDR: begin
        // $display("Addr");
        
        if(trans.addr == DPR && trans.op == WRITE) begin
          i2c_output_trans = new("real");
          i2c_predicted_trans = new("predicted");
          i2c_predicted_trans.addr = trans.data[7:1];
          i2c_predicted_trans.op = (trans.data[0]) ? I2C_READ : I2C_WRITE;
        end
        if(trans.addr == CMDR && {5'bxxxxx, trans.data[2:0]} === CMDR_WRITE) begin
            pred_state = DATA;
        end
      end
      DATA: begin
        // $display("Data");
        if(trans.addr == DPR && trans.op == WRITE) begin
          DPR_data = trans.data;
        end
        if(trans.addr == CMDR && {5'bxxxxx, trans.data[2:0]} === CMDR_WRITE && trans.op == WRITE)begin
          //$display("DPR Data: %b", DPR_data);
          i2c_data.push_back(DPR_data);
        end

        if(trans.addr == CMDR && ({5'bxxxxx, trans.data[2:0]} === CMDR_READACK || {5'bxxxxx, trans.data[2:0]} === CMDR_READNACK) && trans.op == WRITE)begin
          //$display("DPR Data: %b", DPR_data);
          i2c_data.push_back(read_vals.pop_front());
        end

        if(trans.addr == CMDR && {5'bxxxxx, trans.data[2:0]} === CMDR_STOP && trans.op == WRITE) begin
          transfer_complete = 1'b1;
          pred_state = WAIT;
        end

        if(trans.addr == CMDR && {5'bxxxxx, trans.data[2:0]} === CMDR_START && trans.op == WRITE)begin
          transfer_complete = 1'b1;
          pred_state = ADDR;
        end
      end
      default: pred_state = WAIT;
    endcase

    



    //$display({get_full_name()," ",trans.convert2string()});
    if(transfer_complete == 1'b1) begin
      $display("Transfer Complete");
      q_size = i2c_data.size();
      i2c_predicted_trans.data = new[q_size];
      for(int i = 0; i < q_size; i++) begin
        //$display("i2c_data: %b", i2c_data.pop_front());
        i2c_predicted_trans.data[i] = i2c_data.pop_front();
      end
      $display({get_full_name()," ",i2c_predicted_trans.convert2string()});
      scoreboard.nb_transport(i2c_predicted_trans, i2c_output_trans);
      transfer_complete = 1'b0;
      $display("Transfer Complete Finished");
    end
  endfunction


  function void set_expected_reads(bit[7:0] read_data []);
    for(int i = 0; i < read_data.size(); i++) begin
      read_vals.push_back(read_data[i]);
    end
  endfunction



endclass