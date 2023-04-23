class test_i2cmb_reg_addrs extends ncsu_component; 
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
        env.run();
        gen.run_reg_addrs();
    endtask
endclass