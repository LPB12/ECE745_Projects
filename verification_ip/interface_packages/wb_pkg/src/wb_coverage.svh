class wb_coverage extends ncsu_component#(.T(wb_transaction));
    wb_configuration configuration;
    bit [7:0] wb_data_in;
    bit [6:0] wb_set_address;
    bit wb_ops;

    covergroup wb_cg;
        data: coverpoint wb_data_in;
        ops: coverpoint wb_ops;
        addr: coverpoint wb_set_address; 
        data_x_op: cross wb_data_in, wb_ops;
    endgroup

    function void set_configuration(wb_configuration cfg);
        configuration = cfg;
    endfunction

    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
        wb_cg = new;
    endfunction
    

    virtual function void nb_put(T trans);
        //$display({get_full_name()," ",trans.convert2string()});
        wb_ops = trans.op;
        wb_data_in = trans.data;
        //wb_set_address = trans.data;
        wb_cg.sample();
    endfunction


endclass