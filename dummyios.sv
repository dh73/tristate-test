`default_nettype none
module dummyios (output wire dout,
		 input bit din,
		 input bit en);

`ifndef FORMAL
   assign dout = en ? din : 1'bz;
`else
   assign dout = en ? din : 1'b0;
   isunknown_checker _isunknown_ (en, din, dout);
`endif  
endmodule // dummyios
