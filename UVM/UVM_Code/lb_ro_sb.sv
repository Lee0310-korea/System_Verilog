import "DPI-C" function int unsigned addFunc(int unsigned a, int unsigned b);

`uvm_analysis_imp_decl(_in_lb_ro)
`uvm_analysis_imp_decl(_out_lb_ro)

class lb_ro_sb_c extends uvm_scoreboard;
  `uvm_component_utils(lb_ro_sb_c)

  typedef struct packed {
    bit [`RGB_WIDTH-1:0] r, g, b; 
    bit       bypass;      
    bit [`RGB_WIDTH-1:0] offset_val;  
  } rgb_set;

  uvm_analysis_imp_in_lb_ro #(lb_ro_mon_pkt_c, lb_ro_sb_c) in_lb_ro_imp_port;
  uvm_analysis_imp_out_lb_ro#(lb_ro_mon_pkt_c, lb_ro_sb_c) out_lb_ro_imp_port;

  rgb_set c_result_q[$];  
  rgb_set rtl_result_q[$];
	bit [`RGB_WIDTH-1:0] max_value = {`RGB_WIDTH{1'b1}}; 
  int match_cnt = 0;
  int mismatch_cnt = 0;
  int in_pkt_cnt = 0;
  int out_pkt_cnt = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    in_lb_ro_imp_port = new("in_lb_ro_imp_port", this);
    out_lb_ro_imp_port = new("out_lb_ro_imp_port", this);
  endfunction

  virtual function void write_in_lb_ro(lb_ro_mon_pkt_c pkt);
    if(pkt.i_de) begin
      rgb_set expected_data;
      expected_data.r          = pkt.i_r_data;
      expected_data.g          = pkt.i_g_data;
      expected_data.b          = pkt.i_b_data;
      expected_data.bypass     = pkt.i_bypass;     
      expected_data.offset_val = pkt.i_offset_val; 
      
      c_result_q.push_back(expected_data);
      in_pkt_cnt++;
    end
  endfunction

  virtual function void write_out_lb_ro(lb_ro_mon_pkt_c pkt);
    rgb_set actual_result;
    rgb_set golden_ref; 
    string  cmp_msg;
    
    out_pkt_cnt++; 
    
    actual_result.r = pkt.o_r_data;
    actual_result.g = pkt.o_g_data;
    actual_result.b = pkt.o_b_data;

    if(c_result_q.size() > 0) begin
      rgb_set stored_item = c_result_q.pop_front();
      actual_result.bypass     = stored_item.bypass;
      actual_result.offset_val = stored_item.offset_val;

      golden_ref.bypass     = stored_item.bypass;
      golden_ref.offset_val = stored_item.offset_val;

      if (stored_item.bypass) begin
        golden_ref.r = stored_item.r;
        golden_ref.g = stored_item.g;
        golden_ref.b = stored_item.b;
        cmp_msg = $sformatf("BYPASS (Orig -> Pure): {R:%h, G:%h, B:%h}", stored_item.r, stored_item.g, stored_item.b);
      end else begin
        int unsigned res_r, res_g, res_b;
        res_r = addFunc(int'(stored_item.r), int'(stored_item.offset_val));
        res_g = addFunc(int'(stored_item.g), int'(stored_item.offset_val));
        res_b = addFunc(int'(stored_item.b), int'(stored_item.offset_val));
        
        golden_ref.r = (res_r > max_value) ? max_value : res_r[9:0];
        golden_ref.g = (res_g > max_value) ? max_value : res_g[9:0];
        golden_ref.b = (res_b > max_value) ? max_value : res_b[9:0];
        cmp_msg = $sformatf("OFFSET (Orig+Off): {R:%h+%h, G:%h+%h, B:%h+%h}", 
                            stored_item.r, stored_item.offset_val, 
                            stored_item.g, stored_item.offset_val, 
                            stored_item.b, stored_item.offset_val);
      end

      if ((actual_result.r === golden_ref.r) && (actual_result.g === golden_ref.g) && (actual_result.b === golden_ref.b)) begin
        match_cnt++;
        `uvm_info("DATA_CMP", $sformatf("MATCH SUCCESS! [Pkt#%0d] %s -> Expected:%p == Actual:%p", 
                  out_pkt_cnt, cmp_msg, golden_ref, actual_result), UVM_LOW)
      end else begin
        mismatch_cnt++;
        `uvm_error("DATA_CMP", $sformatf("MATCH FAILED! [Pkt#%0d] %s -> Expected:%p != Actual:%p", 
                  out_pkt_cnt, cmp_msg, golden_ref, actual_result))
      end
    end else begin
      `uvm_error("SB_EMPTY", $sformatf("Output [#%0d] received but c_result_q is EMPTY!", out_pkt_cnt))
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), "==============================================", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf(" FINAL REPORT"), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf(" - Total Input Pixels  : %0d", in_pkt_cnt), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf(" - Total Output Pixels : %0d", out_pkt_cnt), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf(" - Match Count         : %0d", match_cnt), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf(" - Mismatch Count      : %0d", mismatch_cnt), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf(" - Remaining In Q      : %0d", c_result_q.size()), UVM_LOW)
    `uvm_info(get_type_name(), "==============================================", UVM_LOW)
  endfunction
endclass