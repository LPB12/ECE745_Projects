class i2cmb_generator extends ncsu_component #(.T(ncsu_transaction)); 
    
    wb_transaction wb_transactions[];
    wb_transaction wb_trans_q[$];
    i2c_transaction i2c_transactions[];
    i2c_transaction i2c_trans_q[$];

    i2c_agent i2cAgent;
    wb_agent wbAgent;

    string trans_name;

    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
        // if ( !$value$plusargs("GEN_TRANS_TYPE=%s", trans_name)) begin
        // $display("FATAL: +GEN_TRANS_TYPE plusarg not found on command line");
        // $fatal;
        // end
        // $display("%m found +GEN_TRANS_TYPE=%s", trans_name);
    endfunction

    virtual task run();
        
    endtask

    
    function void wb_set_agent(wb_agent agent);
        this.wbAgent = agent;
    endfunction

    function void i2c_set_agent(i2c_agent agent);
        this.i2cAgent = agent;
    endfunction

endclass