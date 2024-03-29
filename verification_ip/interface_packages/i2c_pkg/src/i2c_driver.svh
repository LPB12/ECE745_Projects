class i2c_driver extends ncsu_component#(.T(i2c_transaction));

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  virtual i2c_if bus;
  i2c_configuration configuration;
  i2c_transaction i2c_trans;
  bit [7:0] data[];
  bit transferComplete;


  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction

  virtual task bl_put(T trans);
    //$display({get_full_name()," ",trans.convert2string()});
    if(trans.op == 0) bus.wait_for_i2c_transfer(trans.op, trans.data);
    else begin
      fork
        bus.provide_read_data(trans.data, transferComplete);
        bus.wait_for_i2c_transfer(trans.op, trans.data);
      join
    end
  endtask



endclass
