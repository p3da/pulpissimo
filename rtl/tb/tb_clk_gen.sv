// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/*
 * tb_clk_gen.sv
 * Antonio Pullini <pullinia@iis.ee.ethz.ch>
 * Igor Loi <igor.loi@unibo.it>
 */

module tb_clk_gen #(
   parameter CLK_PERIOD = 1.0
) (
   output logic   clk_o,

	 /* clock with phase 90 */
	 output logic   clk90_o
);

	 logic s_clk;
	 logic s_clk90;

   initial
   begin
      s_clk  = 1'b1;

      // wait one cycle first
      #(CLK_PERIOD);

      forever s_clk = #(CLK_PERIOD/2) ~s_clk;
   end

	 assign clk_o = s_clk;

	 always @(posedge s_clk)
	 begin
	   #(CLK_PERIOD/4);

		 s_clk90 = 1'b1;
	 end


 	 always @(negedge s_clk)
	 begin
 	   #(CLK_PERIOD/4);

 		 s_clk90 = 1'b0;
 	 end

	 assign clk90_o = s_clk90;

endmodule
