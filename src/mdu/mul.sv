///////////////////////////////////////////
// mul.sv
//
// Written: David_Harris@hmc.edu 16 February 2021
// Modified: 
//
// Purpose: Integer multiplication
// 
// Documentation: RISC-V System on Chip Design
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module mul #(parameter XLEN) (
  input  logic                clk, reset,
  input  logic                StallM, FlushM,
  input  logic [XLEN-1:0]     ForwardedSrcAE, ForwardedSrcBE, // source A and B from after Forwarding mux
  input  logic [2:0]          Funct3E,                        // type of multiply
  output logic [XLEN*2-1:0]   ProdM                           // double-widthproduct
);

  logic [XLEN*2-1:0]  Pprime;                                  // partial products
  logic [XLEN-1:0]  PP1LE                                     // lower partial products
  logic [XLEN-1:0]  PP1UE, PP2UE, PP3UE, PP4UE;               // upper partial products
  logic [XLEN*2-1:0]  PP1M, PP2M, PP3M, PP4M;               // registered partial products
 
  //////////////////////////////
  // Execute Stage: Compute partial products
  //////////////////////////////

  // mul - [31:0] lower bits
  assign Pprime = ForwardedSrcAE[XLEN-2:0] * ForwardedSrcBE[XLEN-2:0]; 
  assign PP1LE = Pprime[XLEN-1:0];
    
  case(Funct3E) 
    // mulh - [63:32] high signed signed
    3'b001: begin
      PP1E = ForwardedSrcAE[XLEN*2-2:32] * ForwardedSrcBE[XLEN*2-2:32];
      PP2E = 
      PP3E = 
      PP4E = 
    end
    // mulhsu [63:32] high signed unsigned
    3'b010: begin 
      PP1E = ForwardedSrcAE[XLEN-2:0] * ForwardedSrcBE[XLEN-2:0];
      PP2E = 
      PP3E = 
      PP4E = 
    end
    // mulhu [63:32] high unisgned unsigned
    3'b011: begin
      PP1E = ForwardedSrcAE[XLEN-2:0] * ForwardedSrcBE[XLEN-2:0];
      PP2E = 
      PP3E = 
      PP4E = 
    end
  endcase

  //////////////////////////////
  // Memory Stage: Sum partial proudcts
  //////////////////////////////

  flopenrc #(XLEN*2) PP1Reg(clk, reset, FlushM, ~StallM, PP1E, PP1M); 
  flopenrc #(XLEN*2) PP2Reg(clk, reset, FlushM, ~StallM, PP2E, PP2M); 
  flopenrc #(XLEN*2) PP3Reg(clk, reset, FlushM, ~StallM, PP3E, PP3M); 
  flopenrc #(XLEN*2) PP4Reg(clk, reset, FlushM, ~StallM, PP4E, PP4M); 

  // add up partial products; this multi-input add implies CSAs and a final CPA
  assign ProdM = PP1M + PP2M + PP3M + PP4M; //ForwardedSrcAE * ForwardedSrcBE;
 endmodule
