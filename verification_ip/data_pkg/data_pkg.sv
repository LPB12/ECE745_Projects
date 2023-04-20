package data_pkg;
   typedef enum bit{
     I2C_WRITE,
     I2C_READ
   } i2c_op_t;

   typedef enum bit [2:0]{
    CLEAR,
    START,
    ADDRESS,
    WRITEDATA,
    READDATA
   } rcvState_t;


   typedef enum bit [2:0]{
    WAIT,
    ADDR,
    DATA
   } predictorState_t;

  parameter CSR = 8'h00;
  parameter DPR = 8'h01;
  parameter CMDR = 8'h02;
  parameter FSMR = 8'h03;
  parameter WRITE = 1'b0;
  parameter READ = 1'b1;
  parameter CMDR_WRITE = 8'bxxxxx001;
  parameter CMDR_READACK = 8'bxxxx_x010;
  parameter CMDR_READNACK = 8'bxxxx_x011;
  parameter CMDR_START = 8'bxxxxx100;
  parameter CMDR_STOP = 8'bxxxxx101;



endpackage


