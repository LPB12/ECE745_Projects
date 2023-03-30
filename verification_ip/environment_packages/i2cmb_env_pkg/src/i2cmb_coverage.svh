class i2cmb_coverage extends ncsu_component#(.T(wb_transaction));
    i2cmb_env_configuration configuration;
    bit [7:0] i2cmb_data;
    bit [7:0] i2cmb_bus_id;
    bit [8:0] i2cmb_state;

    covergroup i2cmbFSM_cg;
        write_data: coverpoint i2cmb_data;
        bus_set: coverpoint i2cmb_bus_id;
        check_wait: coverpoint i2cmb_state;
    endgroup

    function void set_configuration(i2cmb_env_configuration cfg);
    configuration = cfg;
    endfunction

    function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    i2cmbFSM_cg = new;
    endfunction
    
    virtual function void nb_put(T trans);
        //$display({get_full_name()," ",trans.convert2string()});
        //i2cmb_data = trans.data;
        //i2cmb_state =;
        //i2cmb_bus_id = trans.addr;
        i2cmbFSM_cg.sample();
        
    endfunction

endclass