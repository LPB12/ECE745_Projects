class i2cmb_generator extends ncsu_component #(.T(ncsu_transaction)); 
    
    //Addresses
    
    parameter CSR = 8'h00;
    parameter DPR = 8'h01;
    parameter CMDR = 8'h02;
    parameter FSMR = 8'h03;
    parameter WRITE = 1'b0;
    parameter READ = 1'b1;
    parameter CMDR_WRITE = 8'bxxxxx001;
    int size;

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
        wb_transaction wb_trans_start;

        wb_trans_start = new("START BUS");
        wb_trans_start.op = WRITE;
        wb_trans_start.addr = CSR;
        wb_trans_start.data = 8'b11xxxxxx;
        wbAgent.bl_put(wb_trans_start);

        wb_trans_start = new("SET BUS DATA");
        wb_trans_start.op = WRITE;
        wb_trans_start.data = 8'h05;
        wb_trans_start.addr = DPR;
        wbAgent.bl_put(wb_trans_start);

        wb_trans_start = new("SET BUS CMDR");
        wb_trans_start.op = WRITE;
        wb_trans_start.data = 8'bxxxx_x110;
        wb_trans_start.addr = CMDR;
        wbAgent.bl_put(wb_trans_start);

        

        
        size = wb_trans_q.size();


        fork
            for(int i = 0; i < size; i++) begin
                wbAgent.bl_put(wb_trans_q.pop_back());
            end
        join
    endtask

    
    function void wb_set_agent(wb_agent agent);
        this.wbAgent = agent;
    endfunction

    function void i2c_set_agent(i2c_agent agent);
        this.i2cAgent = agent;
    endfunction


    task create_trans_writes(bit [7:0] data[], bit[7:0] i2c_addr);
        wb_transaction wb_trans;
        i2c_transaction i2c_trans;

        wb_trans = new("START");
        wb_trans.op = WRITE;
        wb_trans.data = 8'bxxxxx100;
        wb_trans.addr = CMDR;
        wb_trans_q.push_front(wb_trans);

        wb_trans = new("DPR WRITE ADDRESS");
        wb_trans.op = WRITE;
        wb_trans.data = i2c_addr << 1;
        wb_trans.addr = DPR;
        wb_trans_q.push_front(wb_trans);

        wb_trans = new("WRITE TO BUS");
        wb_trans.op = WRITE;
        wb_trans.data = CMDR_WRITE;
        wb_trans.addr = CMDR;
        wb_trans_q.push_front(wb_trans);

        for(int i = 0; i < 32; i++) begin
            wb_trans = new("DPR WRITE DATA");
            wb_trans.op = WRITE;
            wb_trans.data = i;
            wb_trans.addr = DPR;
            wb_trans_q.push_front(wb_trans);

            wb_trans = new("WRITE TO BUS");
            wb_trans.op = WRITE;
            wb_trans.data = CMDR_WRITE;
            wb_trans.addr = CMDR;
            wb_trans_q.push_front(wb_trans);
        end

        
        wb_trans = new("STOP");
        wb_trans.op = WRITE;
        wb_trans.data = 8'bxxxxx101;
        wb_trans.addr = CMDR;
        wb_trans_q.push_front(wb_trans);
    endtask

endclass