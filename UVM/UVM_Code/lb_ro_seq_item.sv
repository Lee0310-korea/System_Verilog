class lb_ro_seq_item_c extends uvm_sequence_item;

  rand bit                         i_bypass    ;
  rand bit         [`RGB_WIDTH-1:0] i_offset_val;
  rand bit         [`VER_WIDTH-1:0] i_vsw       ;
  rand bit         [`VER_WIDTH-1:0] i_vbp       ;
  rand bit         [`VER_WIDTH-1:0] i_vact      ;
  rand bit         [`VER_WIDTH-1:0] i_vfp       ;
  rand bit         [`HOR_WIDTH-1:0] i_hsw       ;
  rand bit         [`HOR_WIDTH-1:0] i_hbp       ;
  rand bit         [`HOR_WIDTH-1:0] i_hact      ;
  rand bit         [`HOR_WIDTH-1:0] i_hfp       ;
  bit                         		i_vsync     ;
  bit                         		i_hsync     ;
  bit                         		i_de        ;
  rand bit         [`RGB_WIDTH-1:0] i_r_data    ;
  rand bit         [`RGB_WIDTH-1:0] i_g_data    ;
  rand bit         [`RGB_WIDTH-1:0] i_b_data    ;

  `uvm_object_utils_begin(lb_ro_seq_item_c)
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

  function new (string name="lb_ro_seq_item_c");
    super.new(name);
  endfunction

  

endclass
