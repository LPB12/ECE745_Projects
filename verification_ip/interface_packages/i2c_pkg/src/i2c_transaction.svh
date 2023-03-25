class i2c_transaction extends ncsu_transaction;
  `ncsu_register_object(i2c_transaction)

  bit [7:0] data[];
  bit [6:0] addr;
  i2c_op_t op;

  function new(string name=""); 
    super.new(name);
  endfunction

  virtual function string convert2string();
     return {super.convert2string(),$sformatf("data:0x%x address:0x%x op:%s ", data, addr, op ? "READ" : "WRITE")};
  endfunction

  function bit compare(i2c_transaction rhs);
    return ((this.addr == rhs.addr ) && 
            (this.data == rhs.data) &&
            (this.op == rhs.op) );
  endfunction

  // virtual function void add_to_wave(int transaction_viewing_stream_h);
  //    super.add_to_wave(transaction_viewing_stream_h);
  //    $add_attribute(transaction_view_h,data,"i2c_data");
  //    $add_attribute(transaction_view_h,addr,"i2c_addr");
  //    $add_attribute(transaction_view_h,op,"i2c_op");
  //    $end_transaction(transaction_view_h,end_time);
  //    $free_transaction(transaction_view_h);
  // endfunction

endclass
