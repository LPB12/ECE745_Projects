class wb_driver extends ncsu_component#(.T(wb_transaction));

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  virtual wb_if bus;
  wb_configuration configuration;
  wb_transaction wb_trans;
  bit [7:0] trashData;
  bit [7:0] FSMR_data;
  bit [7:0] FSMR_queue[$];
  bit [7:0] FSMR_write_data;

  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
  endfunction

  virtual task bl_put(T trans);
    //$display({get_full_name()," ",trans.convert2string()});
    FSMR_write_data = trans.data;
    bus.master_write(trans.addr, trans.data);

    if(trans.addr == 2'h2) begin 
      bus.wait_for_interrupt();
      if({5'bxxxxx, trans.data[2:0]} == CMDR_READACK || {5'bxxxxx, trans.data[2:0]} == CMDR_READNACK)begin 
        bus.master_read(FSMR, FSMR_data);
        FSMR_queue.push_back(FSMR_data);
        bus.master_read(2'h1, trashData);
      end

      if({5'bxxxxx, trans.data[2:0]} == CMDR_STOP) begin
        bus.master_read(FSMR, FSMR_data);
        FSMR_queue.push_back(FSMR_data);
      end

      if({5'bxxxxx, trans.data[2:0]} == CMDR_START)begin
        bus.master_read(FSMR, FSMR_data);
        FSMR_queue.push_back(FSMR_data);
      end


      bus.master_read(2'h2, trashData);
    end

    bus.master_read(FSMR, FSMR_data);
    FSMR_queue.push_back(FSMR_data);

  endtask

  // virtual task bl_get(output T trans); 
    
  //   case(trans.addr) 
  //     2'h1: bus.master_read(trans.addr, trans.data);
  //     2'h2: bus.master_read(trans.addr, trans.data);
  //     default: bus.master_read(trans.addr, trans.data);
  //   endcase
    
  // endtask
endclass
