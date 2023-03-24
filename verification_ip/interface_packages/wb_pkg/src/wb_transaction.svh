class wb_transaction extends ncsu_transaction;
//    `ncsu_register_object(wb_transaction)

   bit [7:0] data;
   bit [1:0] addr;
   bit op;


  function new(string name=""); 
    super.new(name);
  endfunction

  virtual function string convert2string();
     return {super.convert2string(),$sformatf("data:0x%x address:0x%x op:%b", data, addr, op)};
  endfunction

  function bit compare(wb_transaction rhs);
    return ((this.data  == rhs.data ) && 
            (this.addr == rhs.addr ) &&
            (this.op == rhs.op) );
  endfunction

  virtual function void add_to_wave(int transaction_viewing_stream_h);
     super.add_to_wave(transaction_viewing_stream_h);
     $add_attribute(transaction_view_h,data,"wb_data");
     $add_attribute(transaction_view_h,addr,"wb_addr");
     $add_attribute(transaction_view_h,op,"wb_op");
     $end_transaction(transaction_view_h,end_time);
     $free_transaction(transaction_view_h);
  endfunction

endclass
