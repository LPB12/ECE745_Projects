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



endpackage


