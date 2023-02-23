`timescale 1ns / 10ps

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
bit[I2C_DW-1:0] i2cData[];
bit[I2C_AW-1:0] i2cAddr;
bit i2cOp;
bit transferComplete;
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
// Monitor Wishbone bus and display transfers in the transcript
initial begin : wb_monitoring
  wb_bus.master_monitor(monAddr, monData, monWE);  
  $display("%x\n%x\n%x\n",monAddr,monData,monWE);
end





// ****************************************************************************
// Define the flow of the simulation
initial begin : test_flow
  reg [WB_DATA_WIDTH-1:0] tmp;
  bit[WB_DATA_WIDTH-1:0]data_bytes[32];
  bit[I2C_DW-1:0]data_for_read_one[32];

  while(rst) @ (clk);
  #1000;

  for(int i = 0; i < 32; i++) begin
    data_bytes[i] = i;
  end

  for(int i = 0; i < 32; i++) begin
    data_for_read_one[i] = 8'd100 + i;
  end

  wb_bus.master_write(CSR, 8'b11xx_xxxx);
  wb_bus.master_write(DPR, 8'h05);
  wb_bus.master_write(CMDR, 8'bxxxx_x110);//Set bus
  wait(irq);


  $display("======================================");
  $display("          Test 1 - Write 0-31         ");
  $display("======================================");

  fork
   begin
      wb_bus.master_write(CMDR, 8'bxxxx_x100);//Start sending
      wait(irq);
      wb_bus.master_read(CMDR, tmp);
      wait(irq);
      wb_bus.master_write(DPR, ((7'h22 << 1) | 0));
      wb_bus.master_write(CMDR, 8'bxxxx_x001);//Write
      wait(irq);
      wb_bus.master_read(CMDR, tmp);
      wait(irq);
      WB_Write(data_bytes);
      wb_bus.master_write(CMDR, 8'bxxxx_x101); //Stop sending
      wait(irq);
      wb_bus.master_read(CMDR, tmp);
   end

   begin
     i2c_bus.wait_for_i2c_transfer(i2cOp, i2cData);
   end
  join
  
  $display("======================================");
  $display("            Test 1 - ENDED            ");
  $display("======================================");



  $display("======================================");
  $display("         Test 2 - Read 100-131        ");
  $display("======================================");
  fork
    begin
      wb_bus.master_write(CMDR, 8'bxxxx_x100);//Start sending
      wait(irq);
      wb_bus.master_read(CMDR, tmp);
      wait(irq);
      wb_bus.master_write(DPR, ((7'h22 << 1) | 1));
      wb_bus.master_write(CMDR, 8'bxxxx_x001);//Write
      wait(irq);
      wb_bus.master_read(CMDR, tmp);
      wait(irq);
      WB_Read(read_back_data);
      wb_bus.master_write(CMDR, 8'bxxxx_x101); //Stop sending
      wait(irq);
      wb_bus.master_read(CMDR, tmp);
    end

    begin
        i2c_bus.provide_read_data(data_for_read_one, transferComplete);
    end

    begin
        i2c_bus.wait_for_i2c_transfer(i2cOp, i2cData);
    end
  join


  foreach(read_back_data[i])begin
    $display("Data Read = %b", read_back_data[i]);
  end
  $display("======================================");
  $display("            Test 2 - Ended            ");
  $display("======================================");


end



task I2C_Start_Address(input bit[I2C_AW-1:0]address, input bit op);
    reg [WB_DATA_WIDTH-1:0] start_tmp;
    wb_bus.master_write(CMDR, 8'bxxxx_x100);//Start sending
    wait(irq);
    wb_bus.master_read(CMDR, start_tmp);
    wait(irq);

    wb_bus.master_write(DPR, address);
    wb_bus.master_write(CMDR, 8'bxxxx_x001);//Write
    wait(irq);
    wb_bus.master_read(CMDR, start_tmp);
endtask

task WB_Write(input bit[I2C_DW-1:0]data[]);
  reg [WB_DATA_WIDTH-1:0] write_tmp;
  foreach(data[i]) begin
    wb_bus.master_write(DPR, data[i]);//Set data
    wb_bus.master_write(CMDR, 8'bxxxx_x001);//Write data
    wait(irq);
    wb_bus.master_read(CMDR, write_tmp);
    wait(irq);
  end
endtask //WB_Write


task WB_Read(input bit[I2C_DW-1:0]data[]);
  bit [WB_DATA_WIDTH-1:0] read_tmp;
  for(int i = 0; i < 31; i++) begin
    wb_bus.master_write(CMDR, 8'bxxxx_x010);//Read Ack
    wait(irq);
    wb_bus.master_read(DPR, read_tmp);
    read_back_data[i] = read_tmp;
    wb_bus.master_read(CMDR, read_tmp);
    wait(irq);
  end


  wb_bus.master_write(CMDR, 8'bxxxx_x011);//Read Nack
  wait(irq);
  wb_bus.master_read(DPR, read_tmp);
  read_back_data[31] = read_tmp;
  wb_bus.master_read(CMDR, read_tmp);
  wait(irq);

  
endtask //WB_Write

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


endmodule
