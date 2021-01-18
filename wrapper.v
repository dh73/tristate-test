`default_nettype none
`ifdef FORMAL
    `define MPRJ_IO_PADS 40
`endif
module wrapper (
    // interface as user_proj_example.v
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wbs_stb_i,
    input wire wbs_cyc_i,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [31:0] wbs_dat_i,
    input wire [31:0] wbs_adr_i,
    output wire wbs_ack_o,
    output wire [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    // only provide first 32 bits to reduce wiring congestion
    input  wire [31:0] la_data_in,
    output wire [31:0] la_data_out,
    input  wire [31:0] la_oen,

    // IOs
    input  wire [`MPRJ_IO_PADS-1:0] io_in,
    output wire [`MPRJ_IO_PADS-1:0] io_out,
    output wire [`MPRJ_IO_PADS-1:0] io_oeb,

    // active input, only connect tristated outputs if this is high
    input wire active
);

    // all outputs must be tristated before being passed onto the project
    wire buf_wbs_ack_o;
    wire [31:0] buf_wbs_dat_o;
    wire [31:0] buf_la_data_out;
    wire [`MPRJ_IO_PADS-1:0] buf_io_out;
    wire [`MPRJ_IO_PADS-1:0] buf_io_oeb;

    // tristate buffers
`ifndef FORMAL
    assign wbs_ack_o    = active ? buf_wbs_ack_o    : 1'bz;
    assign wbs_dat_o    = active ? buf_wbs_dat_o    : 32'bz;
    assign la_data_out  = active ? buf_la_data_out  : 32'bz;
    assign io_out       = active ? buf_io_out       : `MPRJ_IO_PADS'bz;
    assign io_oeb       = active ? buf_io_oeb       : `MPRJ_IO_PADS'bz;
`else
    assign wbs_ack_o    = active ? buf_wbs_ack_o    : 1'b0;
    assign wbs_dat_o    = active ? buf_wbs_dat_o    : 32'b0;
    assign la_data_out  = active ? buf_la_data_out  : 32'b0;
    assign io_out       = active ? buf_io_out       : `MPRJ_IO_PADS'b0;
    assign io_oeb       = active ? buf_io_oeb       : `MPRJ_IO_PADS'b0;

    isunknown_checker _isunknown_wbs_ack_o_ (active, buf_wbs_ack_o, wbs_ack_o);
    /* Since the rest of the buses are parallel, it may be probably best to use
     * the simmetry abstraction and check for only one bit. */
    genvar i;
     generate
	for (i = 0; i < 32; i = i + 1) begin: highz_checkers
	   isunknown_checker _isunknown_wbs_dat_o_ (active, buf_wbs_dat_o[i], wbs_dat_o[i]);
	   isunknown_checker _isunknown_la_data_out_o_ (active, buf_la_data_out[i], la_data_out[i]);
	end
     endgenerate

    genvar j;
     generate
	for (j = 0; j < `MPRJ_IO_PADS; j = j + 1'b1) begin: highz_checkers_io
	   isunknown_checker _isunknown_io_out_ (active, buf_io_out[j], io_out[j]);
	   isunknown_checker _isunknown_io_oeb_ (active, buf_io_oeb[j], io_oeb[j]);
	end
     endgenerate

`endif
    // permanently set oeb so that outputs are always enabled: 0 is output, 1 is high-impedance
    assign buf_io_oeb = `MPRJ_IO_PADS'h0;
    // instantiate your module here, connecting what you need of the above signals
    seven_segment_seconds seven_segment_seconds (.clk(wb_clk_i), .reset(la_data_in[25]), .led_out(buf_io_out[14:8]), .compare_in(la_data_in[23:0]), .update_compare(la_data_in[24]));

endmodule
`default_nettype wire
