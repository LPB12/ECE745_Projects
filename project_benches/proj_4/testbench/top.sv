`timescale 1ns / 10ps

import ncsu_pkg::*;
import data_pkg::*;
import i2c_pkg::*;
import wb_pkg::*;
import i2cmb_env_pkg::*;

module top();
parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 1;
parameter int I2C_DW = 8;
parameter int I2C_AW = 7;

bit  clk;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
tri1 ack;
wire [WB_ADDR_WIDTH-1:0] adr;
wire [WB_DATA_WIDTH-1:0] dat_wr_o;
wire [WB_DATA_WIDTH-1:0] dat_rd_i;
wire irq;
tri  [NUM_I2C_BUSSES-1:0] scl;
tri  [NUM_I2C_BUSSES-1:0] sda;

//Monitor Variables
reg [WB_ADDR_WIDTH-1:0] monAddr;
reg [WB_DATA_WIDTH-1:0] monData;
bit monWE;

bit[I2C_DW-1:0] monI2cData[];
bit[I2C_AW-1:0] monI2cAddr;
i2c_op_t monI2cOp;


bit[I2C_DW-1:0] i2cData[];
bit[I2C_AW-1:0] i2cAddr;
i2c_op_t i2cOp;
bit[WB_DATA_WIDTH-1:0]read_back_data[32];

//Addresses
parameter
  CSR = 8'h00,
  DPR = 8'h01,
  CMDR = 8'h02,
  FSMR = 8'h03;



// ****************************************************************************
// Clock generator
initial begin : clk_gen
  clk = 1'b0;
  forever begin
    #5 clk = ~clk;
  end 
end

// ****************************************************************************
// Reset generator
initial begin : rst_gen
  #113 rst = 1'b0;
end




// ****************************************************************************
// Instantiate the Wishbone master Bus Functional Model
wb_if       #(
      .ADDR_WIDTH(WB_ADDR_WIDTH),
      .DATA_WIDTH(WB_DATA_WIDTH)
      )
wb_bus (
  // System sigals
  .clk_i(clk),
  .rst_i(rst),
  .irq_i(irq),
  // Master signals
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(ack),
  .adr_o(adr),
  .we_o(we),
  // Slave signals
  .cyc_i(),
  .stb_i(),
  .ack_o(),
  .adr_i(),
  .we_i(),
  // Shred signals
  .dat_o(dat_wr_o),
  .dat_i(dat_rd_i)
  );

i2c_if      #(
        .I2C_DATA_WIDTH(I2C_DW),
        .I2C_ADDR_WIDTH(I2C_AW)
      ) 
i2c_bus(
  .scl_i(scl[0]),
  .sda_i(sda[0]),
  .scl_o(scl[0]),
  .sda_o(sda[0])
);

// ****************************************************************************
// Instantiate the DUT - I2C Multi-Bus Controller
\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT
  (
    // ------------------------------------
    // -- Wishbone signals:
    .clk_i(clk),         // in    std_logic;                            -- Clock
    .rst_i(rst),         // in    std_logic;                            -- Synchronous reset (active high)
    // -------------
    .cyc_i(cyc),         // in    std_logic;                            -- Valid bus cycle indication
    .stb_i(stb),         // in    std_logic;                            -- Slave selection
    .ack_o(ack),         //   out std_logic;                            -- Acknowledge output
    .adr_i(adr),         // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
    .we_i(we),           // in    std_logic;                            -- Write enable
    .dat_i(dat_wr_o),    // in    std_logic_vector(7 downto 0);         -- Data input
    .dat_o(dat_rd_i),    //   out std_logic_vector(7 downto 0);         -- Data output
    // ------------------------------------
    // ------------------------------------
    // -- Interrupt request:
    .irq(irq),           //   out std_logic;                            -- Interrupt request
    // ------------------------------------
    // ------------------------------------
    // -- I2C interfaces:
    .scl_i(scl),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    .sda_i(sda),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    .scl_o(scl),         //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    .sda_o(sda)          //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    // ------------------------------------
  );


i2cmb_test test;
test_i2cmb_reg_addrs test2;
test_i2cmb_reg_defaults test3;
test_i2cmb_reg_faultaddrs test4;
test_i2cmb_reg_transactions test5;
test_i2cmb_reg_writeouts test6;
test_i2cmbFSM_before test7;
test_i2cmbFSM_starts test8;
test_i2cmbFSM_stops test9;
test_i2cmbFSM_writefirst test10;
test_i2cmbFSM_bus_ranges test11;
test_i2cmb_random test12;

// make     cli GEN_TRANS_TYPE=i2cmb_test
// make run_cli GEN_TRANS_TYPE=test_i2cmb_reg_addrs TEST_SEED=random
// make run_cli GEN_TRANS_TYPE=test_i2cmb_reg_defaults TEST_SEED=random
// make run_cli GEN_TRANS_TYPE=test_i2cmb_reg_faultaddrs TEST_SEED=random
// make run_cli GEN_TRANS_TYPE=test_i2cmb_reg_transactions TEST_SEED=random
// make run_cli GEN_TRANS_TYPE=test_i2cmb_reg_writeouts TEST_SEED=random
// make run_cli GEN_TRANS_TYPE=test_i2cmbFSM_before TEST_SEED=random
// make run_cli GEN_TRANS_TYPE=test_i2cmbFSM_starts TEST_SEED=random
// make run_cli GEN_TRANS_TYPE=test_i2cmbFSM_stops TEST_SEED=random
// make run_cli GEN_TRANS_TYPE=test_i2cmbFSM_writefirst TEST_SEED=random

property i2c_arblost;
  @(posedge clk) 1'b1;
endproperty

property wb_arblost;
  @(posedge clk) 1'b1;
endproperty
assert property(wb_arblost) else $error("Wishbone Arbitration Lost"); 
assert property(i2c_arblost) else $error("I2C Arbitration Lost"); 

initial begin: test_flow
 
  
  string test_name;
  $value$plusargs("GEN_TRANS_TYPE=%s", test_name);
  #1000;

  case(test_name)
    "i2cmb_test" : begin
      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH, WB_DATA_WIDTH))::set("test.env.wb_agent", wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_DW, I2C_AW))::set("test.env.i2c_agent", i2c_bus);
      test = new("test", null);
      test.run();
    end
    "test_i2cmb_reg_addrs" : begin
      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH, WB_DATA_WIDTH))::set("test2.env.wb_agent", wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_DW, I2C_AW))::set("test2.env.i2c_agent", i2c_bus);
      test2 = new("test2", null);
      test2.run();
    end
    "test_i2cmb_reg_defaults" : begin
      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH, WB_DATA_WIDTH))::set("test3.env.wb_agent", wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_DW, I2C_AW))::set("test3.env.i2c_agent", i2c_bus);
      test3 = new("test3", null);
      test3.run();
    end
    "test_i2cmb_reg_faultaddrs" : begin
      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH, WB_DATA_WIDTH))::set("test4.env.wb_agent", wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_DW, I2C_AW))::set("test4.env.i2c_agent", i2c_bus);
      test4 = new("test4", null);
      test4.run();
    end
    "test_i2cmb_reg_transactions" : begin
      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH, WB_DATA_WIDTH))::set("test5.env.wb_agent", wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_DW, I2C_AW))::set("test5.env.i2c_agent", i2c_bus);
      test5 = new("test5", null);
      test5.run();
    end
    "test_i2cmb_reg_writeouts" : begin
      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH, WB_DATA_WIDTH))::set("test6.env.wb_agent", wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_DW, I2C_AW))::set("test6.env.i2c_agent", i2c_bus);
      test6 = new("test6", null);
      test6.run();
    end
    "test_i2cmbFSM_before" : begin
      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH, WB_DATA_WIDTH))::set("test7.env.wb_agent", wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_DW, I2C_AW))::set("test7.env.i2c_agent", i2c_bus);
      test7 = new("test7", null);
      // test7.run();
    end
    "test_i2cmbFSM_starts" : begin
      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH, WB_DATA_WIDTH))::set("test8.env.wb_agent", wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_DW, I2C_AW))::set("test8.env.i2c_agent", i2c_bus);
      test8 = new("test8", null);
      test8.run();
    end
    "test_i2cmbFSM_stops" : begin
      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH, WB_DATA_WIDTH))::set("test9.env.wb_agent", wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_DW, I2C_AW))::set("test9.env.i2c_agent", i2c_bus);
      test9 = new("test9", null);
      test9.run();
    end
    "test_i2cmbFSM_writefirst" : begin
      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH, WB_DATA_WIDTH))::set("test10.env.wb_agent", wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_DW, I2C_AW))::set("test10.env.i2c_agent", i2c_bus);
      test10 = new("test10", null);
      // test10.run();
    end
    "test_i2cmbFSM_bus_ranges" : begin
      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH, WB_DATA_WIDTH))::set("test11.env.wb_agent", wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_DW, I2C_AW))::set("test11.env.i2c_agent", i2c_bus);
      test11 = new("test11", null);
      test11.run();
    end
    "test_i2cmb_random" : begin
      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH, WB_DATA_WIDTH))::set("test12.env.wb_agent", wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_DW, I2C_AW))::set("test12.env.i2c_agent", i2c_bus);
      test12 = new("test12", null);
      test12.run();
    end
    default : begin
      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH, WB_DATA_WIDTH))::set("test.env.wb_agent", wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_DW, I2C_AW))::set("test.env.i2c_agent", i2c_bus);
      test = new("test", null);
      test.run();
    end
  endcase



  #2000
  // $display("Scoreboard and predictor instantiated, connected, and pass data as per project specification but are not fully implemented as per professor's instructions on forum");
  $finish;

end

endmodule
