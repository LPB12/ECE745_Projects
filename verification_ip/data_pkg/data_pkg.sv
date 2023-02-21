package data_pkg;
   typedef enum bit{
     I2C_WRITE,
     I2C_READ
   } i2c_op_t;

   typedef enum bit [2:0]{
    INIT,
    START,
    ADDRESS,
    DATA,
    STOP
   } rcvState_t;
endpackage


