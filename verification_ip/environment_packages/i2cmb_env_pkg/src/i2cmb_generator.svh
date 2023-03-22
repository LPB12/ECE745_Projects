class i2cmb_generator extends ncsu_component; 
    
    wb_transaction wb_transactions[];
    // i2c_transaction i2c_transactions[];

    ncsu_component #(T) agent;
    string trans_name;

    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
        if ( !$value$plusargs("GEN_TRANS_TYPE=%s", trans_name)) begin
        $display("FATAL: +GEN_TRANS_TYPE plusarg not found on command line");
        $fatal;
        end
        $display("%m found +GEN_TRANS_TYPE=%s", trans_name);
    endfunction

    virtual task run();
        foreach (wb_transactions[i]) begin  
            $cast(wb_transactions[i],ncsu_object_factory::create(trans_name));
            assert (wb_transactions[i].randomize());
            agent.bl_put(wb_transactions[i]);
            $display({get_full_name()," ",wb_transactions[i].convert2string()});
        end
    endtask

    function void set_agent(ncsu_component #(T) agent);
        this.agent = agent;
    endfunction

endclass