class wb_monitor extends ncsu_component#(.T(wb_transaction));

  wb_configuration  configuration;
  virtual wb_if bus;

  T monitored_trans;
  ncsu_component #(T) agent;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
  endfunction

  function void set_agent(ncsu_component#(T) agent);
    this.agent = agent;
  endfunction
  
  virtual task run ();
    bus.wait_for_reset();
      forever begin
        monitored_trans = new("monitored_trans");
        if ( enable_transaction_viewing) begin
           monitored_trans.start_time = $time;
        end
        bus.master_monitor(monitored_trans.addr, monitored_trans.data, ~(monitored_trans.op));//Might need intermediary value
        // $display("%s wb_monitor::run() data 0x%x payload 0x%p trailer 0x%x delay 0x%x",
//                  get_full_name(),
//                  monitored_trans.header, 
//                  monitored_trans.payload, 
//                  monitored_trans.trailer, 
//                  monitored_trans.delay
//                  );
        agent.nb_put(monitored_trans);
        if ( enable_transaction_viewing) begin
           monitored_trans.end_time = $time;
           monitored_trans.add_to_wave(transaction_viewing_stream);
        end
    end
  endtask

endclass