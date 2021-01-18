`default_nettype none
/* Problem statement: Create a static functional verification checker
 *                    that is able to determine if a signal is in
 *                    don't care or high-impedance state.
 *
 *                    Normally, using SystemVerilog and a X-prop
 *                    app, we could write something like this:
 *
 *                    ap0: assert property (!en |-> $isunknow (port));
 *                    or
 *                    ap0: assert property (!en |-> $countbits (port, 1'bz) == 1'b1);
 *
 *                    But since SymbiYosys does not have something that can deal with
 *                    those problems atm, a manual checker can be developed that emulates
 *                    the use of $isunknow or $countbits.
 */
module isunknown_checker (input bit enable_condition,
			  input bit data_in,
			  input bit output_isunknown);

   always @(*) data_in_size: assert ($bits(data_in) == 1);
   /* else $error ("Data input must be one bit wide. If \
    *               data input is bigger than this size \
    *               consider using a for-generate to instantiate
    *               one checker per bit); */

   /* Following the simulation semantics of a don't care value, or
    * a high impedance value, that is, a value that is undefined,
    * we will mimic the behaviour by treating the signal of interest as both
    * 1 and 0. The value of 0 will drive the original don't care or
    * high impedance signal, whereas the checker will drive the opposite
    * logic value. */
   reg [1:0] output_isunknown_emul;

   always @(*) begin
      /* The output_isunknown_emul[0] takes the value of the signal connected at the
       * input of the checker. */
      output_isunknown_emul [0] <= output_isunknown;

      /* If the enable condition is deasserted, the output_isunknown_emul[1]
       * takes the opposite value of output_isunknown_emul [0]. */
      if (enable_condition)
	output_isunknown_emul[1] <= 1'b0;
      else
	output_isunknown_emul[1] <= 1'b1;
   end

   /* By doing this, we can check that if the drivers of the signal of
    * interest are correct, output_isunknown_emul is in both 0 and 1, therefore
    * indicating an undefined value. */
   always @(*)
     if (!enable_condition)
       isunknown_check: assert ({output_isunknown_emul[1], output_isunknown_emul[0]} == 2'b10);

   // NOTE: This is a rudimentary implementation that *does not check* for X propagation.

endmodule // isunknown_checker


