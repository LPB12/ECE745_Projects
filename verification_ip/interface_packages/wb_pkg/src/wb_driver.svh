class wb_driver extends ncsu_component#(.T(wb_transaction));

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  virtual wb_if bus;
  wb_configuration configuration;
  wb_transaction wb_trans;
  bit [7:0] trashData;

  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
  endfunction

  virtual task bl_put(T trans);
    //$display({get_full_name()," ",trans.convert2string()});

    bus.master_write(trans.addr, trans.data);

    if(trans.addr == 2'h2 && (trans.data != 8'bxxxx_x010 || trans.data != 8'bxxxx_x011)) begin 
      bus.wait_for_interrupt();
      if(trans.data == 8'bxxxx_x010 || trans.data == 8'bxxxx_x011) bus.master_read(2'h1, trashData);
      bus.master_read(2'h2, trashData);
    end
    
  endtask

  // virtual task bl_get(output T trans); 
    
  //   case(trans.addr) 
  //     2'h1: bus.master_read(trans.addr, trans.data);
  //     2'h2: bus.master_read(trans.addr, trans.data);
  //     default: bus.master_read(trans.addr, trans.data);
  //   endcase
    
  // endtask
endclass
