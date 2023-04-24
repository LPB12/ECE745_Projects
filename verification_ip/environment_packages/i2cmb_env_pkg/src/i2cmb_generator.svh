class i2cmb_generator extends ncsu_component #(.T(ncsu_transaction)); 
    
    //Addresses
    
    parameter CSR = 8'h00;
    parameter DPR = 8'h01;
    parameter CMDR = 8'h02;
    parameter FSMR = 8'h03;
    parameter WRITE = 1'b0;
    parameter READ = 1'b1;
    parameter CMDR_WRITE = 8'bxxxxx001;
    parameter CMDR_READACK = 8'bxxxx_x010;
    parameter CMDR_READNACK = 8'bxxxx_x011;
    int size;

    wb_transaction wb_transactions[];
    wb_transaction wb_trans_q[$];
    i2c_transaction i2c_transactions[];
    i2c_transaction i2c_trans_q[$];

    i2c_agent i2cAgent;
    wb_agent wbAgent;

    string trans_name;

    bit [7:0] dummy_data[];
    bit [7:0] reads_data[];
    bit [7:0] interleave_reads[];
    bit [7:0] interleave_writes[];


    
    i2cmb_predictor predictor;
    

    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
        // if ( !$value$plusargs("GEN_TRANS_TYPE=%s", trans_name)) begin
        // $display("FATAL: +GEN_TRANS_TYPE plusarg not found on command line");
        // $fatal;
        // end
        // $display("%m found +GEN_TRANS_TYPE=%s", trans_name);
    endfunction

    virtual task run();
        i2c_transaction writeTrans;
        wb_transaction wb_trans_start;
        reads_data = new[32];
        interleave_reads = new[64];
        interleave_writes = new[64];

        // $display("======================================");
        // $display("          Test 1 - Write 0-31         ");
        // $display("======================================");
        //WRITES
        writeTrans = new("DUMMY WRITE");
        writeTrans.op = I2C_WRITE;
        writeTrans.addr = 8'h00;
        writeTrans.data = dummy_data;

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

            i2cAgent.bl_put(writeTrans);
        join
        // $display("======================================");
        // $display("            Test 1 - ENDED            ");
        // $display("======================================");


        // $display("======================================");
        // $display("         Test 2 - Read 100-131        ");
        // $display("======================================");
        //READS
        for(int i = 0; i < 32; i++)begin
            reads_data[i] = i + 8'd100;
        end

        writeTrans = new("DUMMY READ");
        writeTrans.op = I2C_READ;
        writeTrans.addr = 8'h00;
        writeTrans.data = reads_data;

        create_trans_reads(reads_data, 8'h22);

        size = wb_trans_q.size();

        predictor.set_expected_reads(reads_data);

        fork
            for(int i = 0; i < size; i++) begin
                wbAgent.bl_put(wb_trans_q.pop_back());
            end

            i2cAgent.bl_put(writeTrans);
        join

        // $display("======================================");
        // $display("            Test 2 - Ended            ");
        // $display("======================================");

        // $display("======================================");
        // $display("   Test 3 - Alternate Reads & Writes  ");
        // $display("======================================");
        //INTERLEAVED
        for(int i = 0; i < 64; i++)begin
            interleave_writes[i] = i + 8'd64;
            interleave_reads[i] = 8'd63 - i;
        end

        writeTrans = new("DUMMY READ");
        writeTrans.op = I2C_READ;
        writeTrans.addr = 8'h00;
        writeTrans.data = interleave_reads;

        create_trans_interleaved(interleave_writes, 8'h22);

        size = wb_trans_q.size();
        
        predictor.set_expected_reads(interleave_reads);

        fork
            for(int i = 0; i < size; i++) begin
                wbAgent.bl_put(wb_trans_q.pop_back());
            end

            i2cAgent.bl_put(writeTrans);
        join
        // $display("======================================");
        // $display("            Test 3 - Ended            ");
        // $display("======================================");

    endtask

    virtual task run_double_stop();

        
        i2c_transaction writeTrans;
        wb_transaction wb_trans_start;
        
        // $display("======================================");
        // $display("          Test Double Stops           ");
        // $display("======================================");


        writeTrans = new("DUMMY WRITE");
        writeTrans.op = I2C_WRITE;
        writeTrans.addr = 8'h00;
        writeTrans.data = dummy_data;

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
        // $display("Size: %d", size);

    
        for(int i = 0; i < size; i++) begin
            $display("For: %d", i);
            wbAgent.bl_put(wb_trans_q.pop_back());
        end

        

        // $display("======================================");
        // $display("         Test Double Stops Done        ");
        // $display("======================================");


    endtask


    virtual task run_double_starts();

        
        i2c_transaction writeTrans;
        wb_transaction wb_trans_start;
        
        // $display("======================================");
        // $display("          Test Double Start           ");
        // $display("         ERROR SHOULD BE THROWN       ");
        // $display("======================================");


        writeTrans = new("DUMMY WRITE");
        writeTrans.op = I2C_WRITE;
        writeTrans.addr = 8'h00;
        writeTrans.data = dummy_data;

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
        // $display("Size: %d", size);

    
        for(int i = 0; i < size; i++) begin
            $display("For: %d", i);
            wbAgent.bl_put(wb_trans_q.pop_back());
        end


        // $display("======================================");
        // $display("        Test Double Start Done        ");
        // $display("======================================");

    endtask

    virtual task run_bus_range();
        

        wb_transaction wb_trans_start;

        // $display("======================================");
        // $display("        Test Bus Ranges - Start       ");         
        // $display("======================================");

        for(int i = 1; i < 17; i++)begin
            wb_trans_start = new("START BUS");
            wb_trans_start.op = WRITE;
            wb_trans_start.addr = CSR;
            wb_trans_start.data = 8'b11xxxxxx;
            wbAgent.bl_put(wb_trans_start);

            wb_trans_start = new("SET BUS DATA");
            wb_trans_start.op = WRITE;
            wb_trans_start.data = i;
            wb_trans_start.addr = DPR;
            // $display("Bus Set: %b", wb_trans_start.data);
            wbAgent.set_bus_id(wb_trans_start.data);
            wbAgent.bl_put(wb_trans_start);
            

            wb_trans_start = new("SET BUS CMDR");
            wb_trans_start.op = WRITE;
            wb_trans_start.data = 8'bxxxx_x110;
            wb_trans_start.addr = CMDR;
            wbAgent.bl_put(wb_trans_start);
 
        end

        // $display("======================================");
        // $display("        Test Bus Ranges - End         ");
        // $display("======================================");
    endtask

    virtual task run_all_writes_reads();
        i2c_transaction writeTrans;
        wb_transaction wb_trans_start;
        reads_data = new[256];

        // $display("======================================");
        // $display("         Test All Writes 0-255        ");
        // $display("======================================");
        //WRITES
        writeTrans = new("DUMMY WRITE");
        writeTrans.op = I2C_WRITE;
        writeTrans.addr = 8'h00;
        writeTrans.data = dummy_data;

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

            i2cAgent.bl_put(writeTrans);
        join
        // $display("======================================");
        // $display("       Test All Writes 0-255 END      ");
        // $display("======================================");

        // $display("======================================");
        // $display("          Test All Reads 0-255        ");
        // $display("======================================");
        //READS
        for(int i = 0; i < 256; i++)begin
            reads_data[i] = i;
        end

        writeTrans = new("DUMMY READ");
        writeTrans.op = I2C_READ;
        writeTrans.addr = 8'h00;
        writeTrans.data = reads_data;

        $display("Size of Reads: %d", reads_data.size);

        create_trans_reads(reads_data, 8'h22);

        size = wb_trans_q.size();

        $display("Size of Queue: %d", size);

        predictor.set_expected_reads(reads_data);

        fork
            for(int i = 0; i < size; i++) begin
                wbAgent.bl_put(wb_trans_q.pop_back());
            end

            i2cAgent.bl_put(writeTrans);
        join

        // $display("======================================");
        // $display("        Test All Reads 0-255 END      ");
        // $display("======================================");
    endtask

    virtual task run_reg_addrs();
        wb_transaction wb_trans_start;
        // $display("======================================");
        // $display("       Test Wishbone Reg Addrs        ");
        // $display("======================================");
        
        wb_trans_start = new("CSR");
        wb_trans_start.op = WRITE;
        wb_trans_start.addr = CSR;
        wb_trans_start.data = 8'b11xxxxxx;
        wbAgent.bl_put(wb_trans_start);

        wb_trans_start = new("DPR");
        wb_trans_start.op = WRITE;
        wb_trans_start.data = 8'h05;
        wb_trans_start.addr = DPR;
        wbAgent.bl_put(wb_trans_start);

        wb_trans_start = new("CMDR");
        wb_trans_start.op = WRITE;
        wb_trans_start.data = 8'bxxxx_x110;
        wb_trans_start.addr = CMDR;
        wbAgent.bl_put(wb_trans_start);

        wb_trans_start = new("FSMR");
        wb_trans_start.op = READ;
        wb_trans_start.addr = FSMR;
        wbAgent.bl_put(wb_trans_start);

        // $display("======================================");
        // $display("     Test Wishbone Reg Addrs END      ");
        // $display("======================================");

    endtask

    virtual task run_check_defaults();
        bit [7:0] data;
        // $display("======================================");
        // $display("       Test Check Default Values      ");
        // $display("======================================");
        wbAgent.bus.master_read(CSR, data);
        if(data != 8'b0) $error("CSR Default Value is not 0");
        wbAgent.bus.master_read(DPR, data);
        if(data != 8'b0) $error("DPR Default Value is not 0");
        wbAgent.bus.master_read(CMDR, data);
        if(data != 8'h80) $error("CMDR Default Value is not 80");
        wbAgent.bus.master_read(FSMR, data);
        if(data != 8'h00) $error("FSMR Default Value is not 00");
        // $display("======================================");
        // $display("     Test Check Default Values END    ");
        // $display("======================================");
    endtask


    virtual task run_faulty_addr();
        wb_transaction wb_trans_start;
        // $display("======================================");
        // $display("         Test Faulty Addresses        ");
        // $display("======================================");

        
        wb_trans_start = new("CSR");
        wb_trans_start.op = WRITE;
        wb_trans_start.addr = CSR;
        wb_trans_start.data = 8'b11xxxxxx;
        wbAgent.bl_put(wb_trans_start);

        wb_trans_start = new("DPR");
        wb_trans_start.op = WRITE;
        wb_trans_start.data = 8'h05;
        wb_trans_start.addr = DPR;
        wbAgent.bl_put(wb_trans_start);

        wb_trans_start = new("CMDR");
        wb_trans_start.op = WRITE;
        wb_trans_start.data = 8'bxxxx_x110;
        wb_trans_start.addr = CMDR;
        wbAgent.bl_put(wb_trans_start);

        wb_trans_start = new("FSMR");
        wb_trans_start.op = READ;
        wb_trans_start.addr = FSMR;
        wbAgent.bl_put(wb_trans_start);

        // $display("======================================");
        // $display("       Test Faulty Addresses END      ");
        // $display("======================================");
    endtask

    virtual task run_test_writeouts();
        bit [7:0] data;
        // $display("======================================");
        // $display("         Test Writeouts               ");
        // $display("======================================");
    
        wbAgent.bus.master_write(CSR, 8'b11xxxxxx);
        wbAgent.bus.master_read(CSR, data);
        if(data != 8'b11xxxxxx) $error("CSR has not been changed");
        // $display("CSR: %b", data);
        wbAgent.bus.master_write(DPR, 8'h05);
        wbAgent.bus.master_read(DPR, data);
        if(data != 8'h00) $error("DPR has been changed, should be 0");
        // $display("DPR: %b", data);
        wbAgent.bus.master_write(CMDR, 8'bxxxx_x110);
        wbAgent.bus.master_read(CMDR, data);
        if(data != 8'bxxxx_x110) $error("CMDR has not been changed");
        // $display("CMDR: %b", data);

        // $display("======================================");
        // $display("         Test Writeouts END           ");
        // $display("======================================");
        
    endtask



    class random_trans;
        rand bit [6:0] addr;
        rand bit [7:0] data;
        // rand bit op;
    endclass

    task create_rand_trans(int num_trans);
        random_trans random_T = new();
        wb_transaction wb_trans;
        wb_transaction wb_trans_start;
        i2c_transaction writeTrans;
        bit first_rand_trans = 1'b0;
        int size = 0;

        reads_data = new[1];
    
        // $display("======================================");
        // $display("           Random Test                ");
        // $display("======================================");


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
        
        for(int i = 0; i < num_trans; i++) begin
            random_T.randomize();
            reads_data[0] = random_T.data;
            wb_trans = new("START");
            wb_trans.op = WRITE;
            wb_trans.data = 8'bxxxxx100;
            wb_trans.addr = CMDR;
            wb_trans_q.push_front(wb_trans);

            wb_trans = new("DPR WRITE ADDRESS");
            wb_trans.op = WRITE;
            wb_trans.data = random_T.addr << 1;
            wb_trans.addr = DPR;
            wb_trans_q.push_front(wb_trans);

            wb_trans = new("WRITE TO BUS");
            wb_trans.op = WRITE;
            wb_trans.data = CMDR_WRITE;
            wb_trans.addr = CMDR;
            wb_trans_q.push_front(wb_trans);


             writeTrans = new("DUMMY WRITE");
            writeTrans.op = I2C_WRITE;
            writeTrans.addr = 8'h00;
            writeTrans.data = dummy_data;
            
            wb_trans = new("DPR WRITE DATA");
            wb_trans.op = WRITE;
            wb_trans.data = random_T.data;
            wb_trans.addr = DPR;
            wb_trans_q.push_front(wb_trans);

            wb_trans = new("WRITE TO BUS");
            wb_trans.op = WRITE;
            wb_trans.data = CMDR_WRITE;
            wb_trans.addr = CMDR;
            wb_trans_q.push_front(wb_trans);

            wb_trans = new("STOP");
            wb_trans.op = WRITE;
            wb_trans.data = CMDR_STOP;
            wb_trans.addr = CMDR;
            wb_trans_q.push_front(wb_trans);
            
            size = wb_trans_q.size();

            predictor.set_expected_reads(reads_data);

            fork
                begin
                    for(int j = 0; j < size; j++) begin
                        wbAgent.bl_put(wb_trans_q.pop_back());
                    end
                    // $display("WB %d", i);
                end
                begin 
                    i2cAgent.bl_put(writeTrans);
                    // $display("I2C %d", i);
                end
            join

        end

        for(int i = 0; i < num_trans; i++) begin
            random_T.randomize();
            reads_data[0] = random_T.data;
            // $display("Random Data %b", random_T.data);
            // $display("READ %b", reads_data[0]);
            wb_trans = new("START");
            wb_trans.op = WRITE;
            wb_trans.data = 8'bxxxxx100;
            wb_trans.addr = CMDR;
            wb_trans_q.push_front(wb_trans);

            wb_trans = new("DPR WRITE ADDRESS");
            wb_trans.op = WRITE;
            wb_trans.data = random_T.addr << 1 | 1'b1;
            wb_trans.addr = DPR;
            wb_trans_q.push_front(wb_trans);

            wb_trans = new("WRITE TO BUS");
            wb_trans.op = WRITE;
            wb_trans.data = CMDR_WRITE;
            wb_trans.addr = CMDR;
            wb_trans_q.push_front(wb_trans);

            writeTrans = new("DUMMY READ");
            writeTrans.op = I2C_READ;
            writeTrans.addr = 8'h00;
            writeTrans.data = reads_data;

            wb_trans = new("CMDR READ NACK");
            wb_trans.op = WRITE;
            wb_trans.data = CMDR_READNACK;
            wb_trans.addr = CMDR;
            wb_trans_q.push_front(wb_trans);            

            wb_trans = new("STOP");
            wb_trans.op = WRITE;
            wb_trans.data = CMDR_STOP;
            wb_trans.addr = CMDR;
            wb_trans_q.push_front(wb_trans);
            
            size = wb_trans_q.size();

            predictor.set_expected_reads(reads_data);

            fork
                for(int j = 0; j < size; j++) begin
                    wbAgent.bl_put(wb_trans_q.pop_back());
                end

                i2cAgent.bl_put(writeTrans);
            join

        end


        // $display("======================================");
        // $display("           Random Test END            ");
        // $display("======================================");

    endtask




    function void gen_set_predictor(i2cmb_predictor predictor);
        this.predictor = predictor;
    endfunction
    
    function void wb_set_agent(wb_agent agent);
        this.wbAgent = agent;
    endfunction

    function void i2c_set_agent(i2c_agent agent);
        this.i2cAgent = agent;
    endfunction

    task create_double_stop();
        wb_transaction wb_trans;

        wb_trans = new("STOP");
        wb_trans.op = WRITE;
        wb_trans.data = CMDR_STOP;
        wb_trans.addr = CMDR;
        wb_trans_q.push_front(wb_trans);

        wb_trans = new("STOP");
        wb_trans.op = WRITE;
        wb_trans.data = CMDR_STOP;
        wb_trans.addr = CMDR;
        wb_trans_q.push_front(wb_trans);
        
    endtask


    task create_double_start();
        wb_transaction wb_trans;

        wb_trans = new("START");
        wb_trans.op = WRITE;
        wb_trans.data = CMDR_START;
        wb_trans.addr = CMDR;
        wb_trans_q.push_front(wb_trans);

        wb_trans = new("START");
        wb_trans.op = WRITE;
        wb_trans.data = CMDR_START;
        wb_trans.addr = CMDR;
        wb_trans_q.push_front(wb_trans);
        
    endtask



    task create_trans_writes(bit [7:0] data[], bit[7:0] i2c_addr);
        wb_transaction wb_trans;

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

        foreach(data[i]) begin
            wb_trans = new("DPR WRITE DATA");
            wb_trans.op = WRITE;
            wb_trans.data = data[i];
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

    task create_trans_reads(bit [7:0] data[], bit[7:0] i2c_addr);
        wb_transaction wb_trans;
        int data_size;

        wb_trans = new("START");
        wb_trans.op = WRITE;
        wb_trans.data = 8'bxxxxx100;
        wb_trans.addr = CMDR;
        wb_trans_q.push_front(wb_trans);

        wb_trans = new("DPR WRITE ADDRESS");
        wb_trans.op = WRITE;
        wb_trans.data = (i2c_addr << 1) | 1'b1;
        wb_trans.addr = DPR;
        wb_trans_q.push_front(wb_trans);

        wb_trans = new("WRITE TO BUS");
        wb_trans.op = WRITE;
        wb_trans.data = CMDR_WRITE;
        wb_trans.addr = CMDR;
        wb_trans_q.push_front(wb_trans);

        data_size = data.size();

        for(int i = 0; i < data_size - 1; i++) begin
            wb_trans = new("CMDR READ ACK");
            wb_trans.op = WRITE;
            wb_trans.data = CMDR_READACK;
            wb_trans.addr = CMDR;
            wb_trans_q.push_front(wb_trans);
        end
        
        wb_trans = new("CMDR READ NACK");
        wb_trans.op = WRITE;
        wb_trans.data = CMDR_READNACK;
        wb_trans.addr = CMDR;
        wb_trans_q.push_front(wb_trans);

        wb_trans = new("STOP");
        wb_trans.op = WRITE;
        wb_trans.data = 8'bxxxxx101;
        wb_trans.addr = CMDR;
        wb_trans_q.push_front(wb_trans);
    endtask


    task create_trans_interleaved(bit [7:0] data[], bit[7:0] i2c_addr);
        wb_transaction wb_trans;

        
        for(int i = 0; i < 64; i++) begin
            
            wb_trans = new("START");
            wb_trans.op = WRITE;
            wb_trans.data = 8'bxxxxx100;
            wb_trans.addr = CMDR;
            wb_trans_q.push_front(wb_trans);

            wb_trans = new("DPR WRITE ADDRESS");
            wb_trans.op = WRITE;
            wb_trans.data = i2c_addr << 1 | 1'b0;
            wb_trans.addr = DPR;
            wb_trans_q.push_front(wb_trans);

            wb_trans = new("WRITE TO BUS");
            wb_trans.op = WRITE;
            wb_trans.data = CMDR_WRITE;
            wb_trans.addr = CMDR;
            wb_trans_q.push_front(wb_trans);

            wb_trans = new("DPR WRITE DATA");
            wb_trans.op = WRITE;
            wb_trans.data = data[i];
            wb_trans.addr = DPR;
            wb_trans_q.push_front(wb_trans);

            wb_trans = new("WRITE TO BUS");
            wb_trans.op = WRITE;
            wb_trans.data = CMDR_WRITE;
            wb_trans.addr = CMDR;
            wb_trans_q.push_front(wb_trans);

            wb_trans = new("START");
            wb_trans.op = WRITE;
            wb_trans.data = 8'bxxxxx100;
            wb_trans.addr = CMDR;
            wb_trans_q.push_front(wb_trans);

            wb_trans = new("DPR WRITE ADDRESS");
            wb_trans.op = WRITE;
            wb_trans.data = i2c_addr << 1 | 1'b1;
            wb_trans.addr = DPR;
            wb_trans_q.push_front(wb_trans);

            wb_trans = new("WRITE TO BUS");
            wb_trans.op = WRITE;
            wb_trans.data = CMDR_WRITE;
            wb_trans.addr = CMDR;
            wb_trans_q.push_front(wb_trans);

            wb_trans = new("CMDR READ NACK");
            wb_trans.op = WRITE;
            wb_trans.data = CMDR_READNACK;
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