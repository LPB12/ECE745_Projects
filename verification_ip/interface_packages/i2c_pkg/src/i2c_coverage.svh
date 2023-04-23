class i2c_coverage extends ncsu_component#(.T(i2c_transaction));

    i2c_configuration configuration;
    i2c_op_t i2c_ops;
    bit [7:0] i2c_data_in;


    covergroup i2c_cg;

        data: coverpoint i2c_data_in;

        ops: coverpoint i2c_ops;

        data_x_op: cross i2c_ops, i2c_data_in;
    endgroup

    function void set_configuration(i2c_configuration cfg);
        configuration = cfg;
    endfunction

    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
        i2c_cg = new;
    endfunction

    virtual function void nb_put(T trans);
        //$display({get_full_name()," ",trans.convert2string()});
        int size = trans.data.size();
        i2c_ops = trans.op;

        for(int i = 0; i < size; i++) begin
            i2c_data_in = trans.data[i];
            i2c_cg.sample();
        end

        i2c_cg.sample();
        
        
    endfunction


endclass
