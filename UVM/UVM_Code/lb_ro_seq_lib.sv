class lb_ro_base_seq_c extends uvm_sequence#(lb_ro_drv_pkt_c);
  `uvm_object_utils(lb_ro_base_seq_c)
  
  lb_ro_seq_item_c rnd_item;
  virtual lb_ro_if lb_ro_vif;

  rand data_mode_e data_mode;
  rand bit [`RGB_WIDTH-1:0] fix_r_data, fix_g_data, fix_b_data;
  rand bit user_bypass;
  rand bit [`RGB_WIDTH-1:0] user_offset_val;
  rand bit [`VER_WIDTH-1:0] user_vsw, user_vbp, user_vact, user_vfp;
  rand bit [`HOR_WIDTH-1:0] user_hsw, user_hbp, user_hact, user_hfp;

  function new (string name = "lb_ro_base_seq_c");
    super.new(name);
    rnd_item = new();
  endfunction

  task send_signal();
    `uvm_create(req);
    req.i_bypass       = rnd_item.i_bypass;
    req.i_offset_val   = rnd_item.i_offset_val;
    req.i_vsw          = rnd_item.i_vsw;
    req.i_vbp          = rnd_item.i_vbp;
    req.i_vact         = rnd_item.i_vact;
    req.i_vfp          = rnd_item.i_vfp;
    req.i_hsw          = rnd_item.i_hsw;
    req.i_hbp          = rnd_item.i_hbp;
    req.i_hact         = rnd_item.i_hact;
    req.i_hfp          = rnd_item.i_hfp;    
    req.i_vsync        = rnd_item.i_vsync;
    req.i_hsync        = rnd_item.i_hsync;
    req.i_de           = rnd_item.i_de;
    req.i_r_data       = rnd_item.i_r_data;
    req.i_g_data       = rnd_item.i_g_data;
    req.i_b_data       = rnd_item.i_b_data;
    `uvm_send(req);
  endtask

  task send_init(input int size=1);
    for (int i=1; i<=size; i++) begin
      rnd_item.i_bypass = 0;
      rnd_item.i_offset_val = 0;
      rnd_item.i_vsw = 0;
      rnd_item.i_vbp = 0;
      rnd_item.i_vact = 0;
      rnd_item.i_vfp = 0;
      rnd_item.i_hsw = 0;
      rnd_item.i_hbp = 0;
      rnd_item.i_hact = 0;
      rnd_item.i_hfp = 0;    
      rnd_item.i_vsync = 0;
      rnd_item.i_hsync = 0;
      rnd_item.i_de = 0;
      rnd_item.i_r_data = 0;
      rnd_item.i_g_data = 0;
      rnd_item.i_b_data = 0;
      send_signal();
    end
  endtask
endclass



class lb_ro_user_seq_c extends lb_ro_base_seq_c;
    `uvm_object_utils(lb_ro_user_seq_c)
    `uvm_declare_p_sequencer(lb_ro_sequencer_c)
    data_mode_e data_mode;
  
    bit [`RGB_WIDTH-1:0] fix_r_data, fix_g_data, fix_b_data;
    bit user_bypass;
    bit [`RGB_WIDTH-1:0] user_offset_val;
    bit [`VER_WIDTH-1:0] user_vsw, user_vbp, user_vact, user_vfp;
    bit [`HOR_WIDTH-1:0] user_hsw, user_hbp, user_hact, user_hfp;
  bit [`RGB_WIDTH-1:0] s_r_data,s_g_data,s_b_data; 

    function new(string name = "lb_ro_user_seq_c");
        super.new(name);
    endfunction

    virtual task body();
        if (rnd_item == null) rnd_item = new();
      repeat (5) begin
            vtiming();
        end
        vtiming_end();
        send_signal();
    endtask

    virtual task vtiming();
        `uvm_info(get_type_name(), "vtiming starts..", UVM_MEDIUM)
        if (data_mode == INCREASE) begin
            s_r_data = 0;
            s_g_data = 0;
            s_g_data = 0;
        end
        rnd_item.i_vsync = 1;
        rnd_item.i_hsync = 1;
        send_signal();
        repeat (rnd_item.i_hsw - 1) @(posedge p_sequencer.lb_ro_vif.i_clk);
        rnd_item.i_hsync = 0;
        send_signal();
        repeat (rnd_item.i_vsw - 1) begin
            repeat (rnd_item.i_hact + rnd_item.i_hfp + rnd_item.i_hbp - 1) begin
                @(posedge p_sequencer.lb_ro_vif.i_clk);
            end
            rnd_item.i_hsync = 1;
            send_signal();
            repeat (rnd_item.i_hsw - 1) @(posedge p_sequencer.lb_ro_vif.i_clk);
            rnd_item.i_hsync = 0;
            send_signal();
        end
        repeat (rnd_item.i_hact + rnd_item.i_hfp + rnd_item.i_hbp - 1) begin
            @(posedge p_sequencer.lb_ro_vif.i_clk);
        end
        repeat (rnd_item.i_vbp) begin
            rnd_item.i_hsync = 1;
            rnd_item.i_de    = 0;
            rnd_item.i_vsync = 0;
            repeat (rnd_item.i_hsw) begin
                send_signal();
            end
            rnd_item.i_hsync = 0;
            repeat ((rnd_item.i_hact + rnd_item.i_hfp + rnd_item.i_hbp)) begin
                send_signal();
            end
        end

        rnd_item.i_vsync = 0;
        for (int v = 0; v < rnd_item.i_vact; v++) begin

            rnd_item.i_hsync = 1;
            send_signal();
            repeat (rnd_item.i_hsw - 1) @(posedge p_sequencer.lb_ro_vif.i_clk);
            rnd_item.i_hsync = 0;
            send_signal();
            repeat (rnd_item.i_hbp - 1) @(posedge p_sequencer.lb_ro_vif.i_clk);
            rnd_item.i_de = 1;
            for (int h = 0; h < rnd_item.i_hact; h++) begin
                if (data_mode == FIX) begin
                    rnd_item.i_r_data = fix_r_data;
                    rnd_item.i_g_data = fix_g_data;
                    rnd_item.i_b_data = fix_b_data;
                end else if (data_mode == RANDOM) begin
                    {rnd_item.i_r_data, rnd_item.i_g_data, rnd_item.i_b_data} = $urandom();
                end else if (data_mode == INCREASE ) begin
                  if(h == 0 & v == 0)begin
                     rnd_item.i_r_data = 0;
            		 rnd_item.i_g_data = 0;
                     rnd_item.i_b_data = 0;
                  end else begin
                    rnd_item.i_r_data = s_r_data + 5;
                    rnd_item.i_g_data = s_g_data + 5;
                    rnd_item.i_b_data = s_g_data + 5;
                   	s_r_data = rnd_item.i_r_data;
                    s_g_data = rnd_item.i_g_data;
                    s_b_data = rnd_item.i_b_data;
                  end
                end 
                send_signal();
            end
            rnd_item.i_de = 0;
          	rnd_item.i_r_data = 0;
            rnd_item.i_g_data = 0;
            rnd_item.i_b_data = 0;
            repeat (rnd_item.i_hfp) begin
                send_signal();
            end
        end
			
        repeat (rnd_item.i_vfp) begin
            rnd_item.i_hsync = 1;
            send_signal();
            repeat (rnd_item.i_hsw - 1) @(posedge p_sequencer.lb_ro_vif.i_clk);
            rnd_item.i_hsync = 0;
            send_signal();
            for (
                int v = 0;
                v < (rnd_item.i_hact + rnd_item.i_hfp + rnd_item.i_hbp - 1);
                v++
            ) begin
                send_signal();
            end
        end
        `uvm_info(get_type_name(), "vtiming ends..", UVM_MEDIUM)
    endtask

    virtual task vtiming_end();
        `uvm_info(get_type_name(), "vtiming starts..", UVM_MEDIUM)
        rnd_item.i_vsync = 1;
        rnd_item.i_hsync = 1;
        send_signal();
        repeat (rnd_item.i_hsw - 1) @(posedge p_sequencer.lb_ro_vif.i_clk);
        rnd_item.i_hsync = 0;
        send_signal();
      	repeat (rnd_item.i_hact + rnd_item.i_hfp + rnd_item.i_hbp - 1) begin
                @(posedge p_sequencer.lb_ro_vif.i_clk);
            end
//         forever begin //edaplayground에서 동작  x
        repeat(5) begin
            rnd_item.i_hsync = 1;
            send_signal();
            repeat (rnd_item.i_hsw - 1) @(posedge p_sequencer.lb_ro_vif.i_clk);
            rnd_item.i_hsync = 0;
            send_signal();
            repeat (rnd_item.i_hact + rnd_item.i_hfp + rnd_item.i_hbp - 1) begin
                @(posedge p_sequencer.lb_ro_vif.i_clk);
            end
        end

        `uvm_info(get_type_name(), "vtiming ends..", UVM_MEDIUM)
    endtask
endclass


