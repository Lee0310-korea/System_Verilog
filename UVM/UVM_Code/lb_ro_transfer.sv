class lb_ro_drv_pkt_c #(
    VER_WIDTH  = 6,
    HOR_WIDTH  = 6,
    RGB_WIDTH  = 10,
    ADDR_WIDTH = 6,
    DATA_WIDTH = RGB_WIDTH * 3
) extends uvm_sequence_item;

    data_mode_e                 data_mode;  // RANDOM, FIX, INCREASE
    bit         [RGB_WIDTH-1:0] fix_r_data;  // active only in data_mode = 1
    bit         [RGB_WIDTH-1:0] fix_g_data;
    bit         [RGB_WIDTH-1:0] fix_b_data;
    bit                         i_bypass;
    bit         [RGB_WIDTH-1:0] i_offset_val;
    bit         [VER_WIDTH-1:0] i_vsw;
    bit         [VER_WIDTH-1:0] i_vbp;
    bit         [VER_WIDTH-1:0] i_vact;
    bit         [VER_WIDTH-1:0] i_vfp;
    bit         [HOR_WIDTH-1:0] i_hsw;
    bit         [HOR_WIDTH-1:0] i_hbp;
    bit         [HOR_WIDTH-1:0] i_hact;
    bit         [HOR_WIDTH-1:0] i_hfp;
    bit                         i_vsync;
    bit                         i_hsync;
    bit                         i_de;
    bit         [RGB_WIDTH-1:0] i_r_data;
    bit         [RGB_WIDTH-1:0] i_g_data;
    bit         [RGB_WIDTH-1:0] i_b_data;
    bit         [         10:0] o_result;

    `uvm_object_utils_begin(lb_ro_drv_pkt_c)
        `uvm_field_int(i_bypass, UVM_DEFAULT)
        `uvm_field_int(i_offset_val, UVM_DEFAULT)
        `uvm_field_int(i_vsw, UVM_DEFAULT)
        `uvm_field_int(i_vbp, UVM_DEFAULT)
        `uvm_field_int(i_vact, UVM_DEFAULT)
        `uvm_field_int(i_vfp, UVM_DEFAULT)
        `uvm_field_int(i_hsw, UVM_DEFAULT)
        `uvm_field_int(i_hbp, UVM_DEFAULT)
        `uvm_field_int(i_hact, UVM_DEFAULT)
        `uvm_field_int(i_hfp, UVM_DEFAULT)
        `uvm_field_int(i_vsync, UVM_DEFAULT)
        `uvm_field_int(i_hsync, UVM_DEFAULT)
        `uvm_field_int(i_de, UVM_DEFAULT)
        `uvm_field_int(i_r_data, UVM_DEFAULT)
        `uvm_field_int(i_g_data, UVM_DEFAULT)
        `uvm_field_int(i_b_data, UVM_DEFAULT)
        `uvm_field_int(o_result, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "lb_ro_drv_pkt_c");
        super.new(name);
    endfunction

endclass


class lb_ro_mon_pkt_c #(
    VER_WIDTH  = 6,
    HOR_WIDTH  = 6,
    RGB_WIDTH  = 10,
    ADDR_WIDTH = 6,
    DATA_WIDTH = RGB_WIDTH * 3
) extends uvm_sequence_item;

    bit                 i_bypass;
    bit [RGB_WIDTH-1:0] i_offset_val;
    bit [VER_WIDTH-1:0] i_vsw;
    bit [VER_WIDTH-1:0] i_vbp;class lb_ro_drv_pkt_c extends uvm_sequence_item;

  bit                         i_bypass    ;
  bit         [`RGB_WIDTH-1:0] i_offset_val;
  bit         [`VER_WIDTH-1:0] i_vsw       ;
  bit         [`VER_WIDTH-1:0] i_vbp       ;
  bit         [`VER_WIDTH-1:0] i_vact      ;
  bit         [`VER_WIDTH-1:0] i_vfp       ;
  bit         [`HOR_WIDTH-1:0] i_hsw       ;
  bit         [`HOR_WIDTH-1:0] i_hbp       ;
  bit         [`HOR_WIDTH-1:0] i_hact      ;
  bit         [`HOR_WIDTH-1:0] i_hfp       ;
  bit                         i_vsync     ;
  bit                         i_hsync     ;
  bit                         i_de        ;
  bit         [`RGB_WIDTH-1:0] i_r_data    ;
  bit         [`RGB_WIDTH-1:0] i_g_data    ;
  bit         [`RGB_WIDTH-1:0] i_b_data    ;

  `uvm_object_utils_begin(lb_ro_drv_pkt_c)
  	`uvm_field_int(i_bypass   		  , UVM_DEFAULT)
    `uvm_field_int(i_offset_val       , UVM_DEFAULT)
  	`uvm_field_int(i_vsw        	  , UVM_DEFAULT)
  	`uvm_field_int(i_vbp        	  , UVM_DEFAULT)
  	`uvm_field_int(i_vact        	  , UVM_DEFAULT)
  	`uvm_field_int(i_vfp        	  , UVM_DEFAULT)
  	`uvm_field_int(i_hsw        	  , UVM_DEFAULT)
  	`uvm_field_int(i_hbp        	  , UVM_DEFAULT)
  	`uvm_field_int(i_hact        	  , UVM_DEFAULT)
  	`uvm_field_int(i_hfp        	  , UVM_DEFAULT)
  	`uvm_field_int(i_vsync        	  , UVM_DEFAULT)
  	`uvm_field_int(i_hsync        	  , UVM_DEFAULT)
  	`uvm_field_int(i_de        	  	  , UVM_DEFAULT)
  	`uvm_field_int(i_r_data        	  , UVM_DEFAULT)
  	`uvm_field_int(i_g_data        	  , UVM_DEFAULT)
  	`uvm_field_int(i_b_data        	  , UVM_DEFAULT)
  `uvm_object_utils_end

  function new (string name="lb_ro_drv_pkt_c");
    super.new(name);
  endfunction

endclass


class lb_ro_mon_pkt_c extends uvm_sequence_item;

  bit                         i_bypass    ;
  bit         [`RGB_WIDTH-1:0] i_offset_val;
  bit         [`VER_WIDTH-1:0] i_vsw       ;
  bit         [`VER_WIDTH-1:0] i_vbp       ;
  bit         [`VER_WIDTH-1:0] i_vact      ;
  bit         [`VER_WIDTH-1:0] i_vfp       ;
  bit         [`HOR_WIDTH-1:0] i_hsw       ;
  bit         [`HOR_WIDTH-1:0] i_hbp       ;
  bit         [`HOR_WIDTH-1:0] i_hact      ;
  bit         [`HOR_WIDTH-1:0] i_hfp       ;
  bit                         i_vsync     ;
  bit                         i_hsync     ;
  bit                         i_de        ;
  bit         [`RGB_WIDTH-1:0] i_r_data    ;
  bit         [`RGB_WIDTH-1:0] i_g_data    ;
  bit         [`RGB_WIDTH-1:0] i_b_data    ;
  bit                         o_vsync     ;
  bit                         o_hsync     ;
  bit                         o_de        ;
  bit         [`RGB_WIDTH-1:0] o_r_data    ;
  bit         [`RGB_WIDTH-1:0] o_g_data    ;
  bit         [`RGB_WIDTH-1:0] o_b_data    ;  
  
  `uvm_object_utils_begin(lb_ro_mon_pkt_c)
  	`uvm_field_int(i_bypass   		  , UVM_DEFAULT)
    `uvm_field_int(i_offset_val       , UVM_DEFAULT)
  	`uvm_field_int(i_vsw        	  , UVM_DEFAULT)
  	`uvm_field_int(i_vbp        	  , UVM_DEFAULT)
  	`uvm_field_int(i_vact        	  , UVM_DEFAULT)
  	`uvm_field_int(i_vfp        	  , UVM_DEFAULT)
  	`uvm_field_int(i_hsw        	  , UVM_DEFAULT)
  	`uvm_field_int(i_hbp        	  , UVM_DEFAULT)
  	`uvm_field_int(i_hact        	  , UVM_DEFAULT)
  	`uvm_field_int(i_hfp        	  , UVM_DEFAULT)
  	`uvm_field_int(i_vsync        	  , UVM_DEFAULT)
  	`uvm_field_int(i_hsync        	  , UVM_DEFAULT)
  	`uvm_field_int(i_de        	  	  , UVM_DEFAULT)
  	`uvm_field_int(i_r_data        	  , UVM_DEFAULT)
  	`uvm_field_int(i_g_data        	  , UVM_DEFAULT)
  	`uvm_field_int(i_b_data        	  , UVM_DEFAULT)
    `uvm_field_int(o_vsync        	  , UVM_DEFAULT)
    `uvm_field_int(o_hsync        	  , UVM_DEFAULT)
    `uvm_field_int(o_de        	  	  , UVM_DEFAULT)
    `uvm_field_int(o_r_data        	  , UVM_DEFAULT)
    `uvm_field_int(o_g_data        	  , UVM_DEFAULT)
    `uvm_field_int(o_b_data        	  , UVM_DEFAULT)  
  `uvm_object_utils_end

  function new (string name="lb_ro_mon_pkt_c");
    super.new(name);
  endfunction

endclass

    bit [VER_WIDTH-1:0] i_vact;
    bit [VER_WIDTH-1:0] i_vfp;
    bit [HOR_WIDTH-1:0] i_hsw;
    bit [HOR_WIDTH-1:0] i_hbp;
    bit [HOR_WIDTH-1:0] i_hact;
    bit [HOR_WIDTH-1:0] i_hfp;
    bit                 i_vsync;
    bit                 i_hsync;
    bit                 i_de;
    bit [RGB_WIDTH-1:0] i_r_data;
    bit [RGB_WIDTH-1:0] i_g_data;
    bit [RGB_WIDTH-1:0] i_b_data;

    bit                 o_vsync;
    bit                 o_hsync;
    bit                 o_de;
    bit [RGB_WIDTH-1:0] o_r_data;
    bit [RGB_WIDTH-1:0] o_g_data;
    bit [RGB_WIDTH-1:0] o_b_data;

    `uvm_object_utils_begin(lb_ro_mon_pkt_c)
        `uvm_field_int(i_bypass, UVM_DEFAULT)
        `uvm_field_int(i_offset_val, UVM_DEFAULT)
        `uvm_field_int(i_vsw, UVM_DEFAULT)
        `uvm_field_int(i_vbp, UVM_DEFAULT)
        `uvm_field_int(i_vact, UVM_DEFAULT)
        `uvm_field_int(i_vfp, UVM_DEFAULT)
        `uvm_field_int(i_hsw, UVM_DEFAULT)
        `uvm_field_int(i_hbp, UVM_DEFAULT)
        `uvm_field_int(i_hact, UVM_DEFAULT)
        `uvm_field_int(i_hfp, UVM_DEFAULT)
        `uvm_field_int(i_vsync, UVM_DEFAULT)
        `uvm_field_int(i_hsync, UVM_DEFAULT)
        `uvm_field_int(i_de, UVM_DEFAULT)
        `uvm_field_int(i_r_data, UVM_DEFAULT)
        `uvm_field_int(i_g_data, UVM_DEFAULT)
        `uvm_field_int(i_b_data, UVM_DEFAULT)

        `uvm_field_int(o_vsync, UVM_DEFAULT)
        `uvm_field_int(o_hsync, UVM_DEFAULT)
        `uvm_field_int(o_de, UVM_DEFAULT)
        `uvm_field_int(o_r_data, UVM_DEFAULT)
        `uvm_field_int(o_g_data, UVM_DEFAULT)
        `uvm_field_int(o_b_data, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "lb_ro_mon_pkt_c");
        super.new(name);
    endfunction

endclass
