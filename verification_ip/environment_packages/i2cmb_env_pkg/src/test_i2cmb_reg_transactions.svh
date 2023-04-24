class test_i2cmb_reg_transactions extends ncsu_component; 
    i2cmb_env_configuration  cfg;
    i2cmb_environment        env;
    i2cmb_generator          gen;
    bit [7:0] test_data_writes [];



    function new(string name = "", ncsu_component_base parent = null); 
        super.new(name,parent);
        cfg = new("cfg");
        //cfg.sample_coverage();
        env = new("env",this);
        env.set_configuration(cfg);
        env.build();
        gen = new("gen",this);
        gen.wb_set_agent(env.get_wb_agent());
        gen.i2c_set_agent(env.get_i2c_agent());
        gen.gen_set_predictor(env.get_predictor());
    endfunction

    virtual task run();
        test_data_writes = new[256];
        for(int i = 0; i < 256; i++)begin
            test_data_writes[i] = i;
        end
        gen.create_trans_writes(test_data_writes, 8'h22);
        env.run();
        gen.run_all_writes_reads();
    endtask
endclass