class i2cmb_env_configuration extends ncsu_configuration; 
    bit       loopback;
    bit       invert;
    bit [3:0] port_delay;
    wb_configuration wb_config;
    // i2c_configuration i2c_config;

    covergroup env_configuration_cg;
        option.per_instance = 1;
        option.name = name;
        coverpoint loopback;
        coverpoint invert;
        coverpoint port_delay;
    endgroup

    function void sample_coverage();
        env_configuration_cg.sample();
    endfunction

    function new(string name=""); 
        super.new(name);
        //env_configuration_cg = new;
        // i2c_config = new("i2c_config");
        wb_config = new("wb_config");
        //wb_config.collect_coverage=0;
        // i2c_config.sample_coverage();
       // wb_config.sample_coverage();
    endfunction
endclass