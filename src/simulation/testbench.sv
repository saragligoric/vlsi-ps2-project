`include "uvm_macros.svh"
import uvm_pkg::*;

// Sequence Item
class ps2_item extends uvm_sequence_item;

    rand bit ps2data;
    bit [3:0] data1;
    bit [3:0] data2;
    bit [3:0] data3;
    bit [3:0] data4;
	
	`uvm_object_utils_begin(ps2_item)
		`uvm_field_int(ps2data, UVM_DEFAULT)
        `uvm_field_int(data1, UVM_DEFAULT)
        `uvm_field_int(data2, UVM_DEFAULT)
        `uvm_field_int(data3, UVM_DEFAULT)
        `uvm_field_int(data4, UVM_DEFAULT)
	`uvm_object_utils_end
	
	function new(string name = "ps2_item");
		super.new(name);
	endfunction
	
	virtual function string my_print();
		return $sformatf(
			"ps2data = %1b data4 = %4b data3 = %4b data2 = %4b data1 = %4b",
			ps2data, data4, data3, data2, data1
		);
	endfunction

endclass

// Generator
class generator extends uvm_sequence;

	`uvm_object_utils(generator)
	
	function new(string name = "generator");
		super.new(name);
	endfunction

	int num = 50;

	bit [7:0] byt;
	bit [7:0] donebyte;

	bit parity;
	bit newparity;

	virtual task body();
		int cnt = 1;
		for (int i = 0; i < num; i++) begin
			if (cnt == 1) begin
				//cnt = cnt + 1;
				ps2_item item = ps2_item::type_id::create("item");
				start_item(item);
				//item.randomize();
				item.ps2data = 1'b0;
				`uvm_info("Generator", $sformatf("Item %0d/%0d created", i + 1, num), UVM_LOW)
				item.print();
				cnt = cnt + 1;
				finish_item(item);
				//cnt = cnt + 1;
			end else if (cnt > 1 || cnt < 10) begin
				//cnt = cnt + 1;
				ps2_item item = ps2_item::type_id::create("item");
				start_item(item);
				item.randomize();
				byt [cnt - 2] = item.ps2data;
				`uvm_info("Generator", $sformatf("Item %0d/%0d created", i + 1, num), UVM_LOW)
				item.print();
				cnt = cnt + 1;
				finish_item(item);
				//cnt = cnt + 1;
			end else if (cnt == 10) begin
				// for (int j = 0; j < 8; j++) begin
				// 	donebyte[j]  = byt[j];
				// end

				//parity = donebyte[0] | donebyte[1];
				//for (int p = 2; p < 8; p++) begin
					//newparity = parity | donebyte[p];
					//parity = newparity;
				//end

				//cnt = cnt + 1;
				ps2_item item = ps2_item::type_id::create("item");
				start_item(item);
				//item.randomize();
				//item.ps2data = parity;
				item.ps2data = 1'b0;
				`uvm_info("Generator", $sformatf("Item %0d/%0d created", i + 1, num), UVM_LOW)
				item.print();
				cnt = cnt + 1;
				finish_item(item);
				//cnt = cnt + 1;
			end else if (cnt == 11) begin
					//cnt = 1;
					ps2_item item = ps2_item::type_id::create("item");
					start_item(item);
					//item.randomize();
					item.ps2data = 1'b1;
					`uvm_info("Generator", $sformatf("Item %0d/%0d created", i + 1, num), UVM_LOW)
					item.print();
					cnt = 1;
					finish_item(item);
					//cnt = 1;
			end
		end
	endtask
	
endclass

// Driver
class driver extends uvm_driver #(ps2_item);
	
	`uvm_component_utils(driver)
	
	function new(string name = "driver", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	virtual ps2_if vif;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual ps2_if)::get(this, "", "ps2_vif", vif))
			`uvm_fatal("Driver", "No interface.")
	endfunction
	
	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		forever begin
			ps2_item item;
			// @(posedge vif.ps2clk)
			// @(posedge vif.clk);
			seq_item_port.get_next_item(item);
			`uvm_info("Driver", $sformatf("%s", item.my_print()), UVM_LOW)
            vif.ps2data <= item.ps2data;
			@(posedge vif.ps2clk)
			@(posedge vif.clk);
			seq_item_port.item_done();
		end
	endtask
	
endclass

// Monitor
class monitor extends uvm_monitor;
	
	`uvm_component_utils(monitor)
	
	function new(string name = "monitor", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	virtual ps2_if vif;
	uvm_analysis_port #(ps2_item) mon_analysis_port;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual ps2_if)::get(this, "", "ps2_vif", vif))
			`uvm_fatal("Monitor", "No interface.")
		mon_analysis_port = new("mon_analysis_port", this);
	endfunction
	
	virtual task run_phase(uvm_phase phase);	
		super.run_phase(phase);
		//@(posedge vif.ps2clk);
		@(posedge vif.clk);
		forever begin
			ps2_item item = ps2_item::type_id::create("item");
			@(posedge vif.clk);
            item.ps2data = vif.ps2data;
            item.data1 = vif.data1;
            item.data2 = vif.data2;
            item.data3 = vif.data3;
            item.data4 = vif.data4;
			`uvm_info("Monitor", $sformatf("%s", item.my_print()), UVM_LOW)
			mon_analysis_port.write(item);
		end
	endtask
	
endclass

// Agent
class agent extends uvm_agent;
	
	`uvm_component_utils(agent)
	
	function new(string name = "agent", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	driver d0;
	monitor m0;
	uvm_sequencer #(ps2_item) s0;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		d0 = driver::type_id::create("d0", this);
		m0 = monitor::type_id::create("m0", this);
		s0 = uvm_sequencer#(ps2_item)::type_id::create("s0", this);
	endfunction
	
	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		d0.seq_item_port.connect(s0.seq_item_export);
	endfunction
	
endclass

// Scoreboard
class scoreboard extends uvm_scoreboard;
	
	`uvm_component_utils(scoreboard)
	
	function new(string name = "scoreboard", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	uvm_analysis_imp #(ps2_item, scoreboard) mon_analysis_imp;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		mon_analysis_imp = new("mon_analysis_imp", this);
	endfunction

	//bit [7:0] reg8 = 8'h00;
	bit [23:0] buffer = 24'h000000;
	
	virtual function write(ps2_item item);
		// if (reg8 == item.out)
		// 	`uvm_info("Scoreboard", $sformatf("PASS!"), UVM_LOW)
		// else
		// 	`uvm_error("Scoreboard", $sformatf("FAIL! expected = %8b, got = %8b", reg8, item.out))
		
		// if (item.ld)
		// 	reg8 = item.in;
		// else if (item.inc)
		// 	reg8 = reg8 + 8'h01;

        //obrni redosled azuriranja i provere

		//azuriranje
		// if (byte == 8'hf0) begin
        //             //buffer_next = 24'hf00000;
        //             buffer_next   = {16'hf000, buffer_reg[7:0]};
        //             end else if (byte == 8'he0) begin
        //                 //buffer_next = {buffer_reg[23:16], 8'he0, 8'h00};
        //                 buffer_next   = {buffer_reg[23:16], 8'he0, buffer_reg[7:0]};
        //                 end else begin  //stigne xx
        //                     if ((buffer_reg[15:8] > 8'he0) || (buffer_reg[15:8] < 8'he0)) begin //u drugom bajtu nema e0
        //                         if (buffer_reg[23:16] == 8'hf0) begin   //u trecem bajtu ima f0
        //                             buffer_next = {16'h00f0, byte};
        //                             end else if ((buffer_reg[23:16] > 8'hf0) || (buffer_reg[23:16] < 8'hf0)) begin  //u trecem bajtu nema f0
        //                                 buffer_next = {16'h0000, byte};
        //                             end
        //                             end else if (buffer_reg[15:8] == 8'he0) begin   //u drugom bajtu ima e0
        //                                 buffer_next = {buffer_reg[23:16], 8'he0, byte};
        //                             end
        //                         end

		buffer[3:0] = item.data1;
		buffer[7:4] = item.data2;
		buffer[11:8] = item.data3;
		buffer[15:12] = item.data4;

		//provera
		if (buffer[3:0] == item.data1 && buffer[7:4] == item.data2 && buffer[11:8] == item.data3 && buffer[15:12] == item.data4)
			`uvm_info("Scoreboard", $sformatf("PASS!"), UVM_LOW)
		else
			`uvm_error("Scoreboard", $sformatf("FAIL!"))

	endfunction
	
endclass

// Environment
class env extends uvm_env;
	
	`uvm_component_utils(env)
	
	function new(string name = "env", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	agent a0;
	scoreboard sb0;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		a0 = agent::type_id::create("a0", this);
		sb0 = scoreboard::type_id::create("sb0", this);
	endfunction
	
	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		a0.m0.mon_analysis_port.connect(sb0.mon_analysis_imp);
	endfunction
	
endclass

// Test
class test extends uvm_test;

	`uvm_component_utils(test)
	
	function new(string name = "test", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	virtual ps2_if vif;

	env e0;
	generator g0;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual ps2_if)::get(this, "", "ps2_vif", vif))
			`uvm_fatal("Test", "No interface.")
		e0 = env::type_id::create("e0", this);
		g0 = generator::type_id::create("g0");
	endfunction
	
	virtual function void end_of_elaboration_phase(uvm_phase phase);
		uvm_top.print_topology();
	endfunction
	
	virtual task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		
		vif.rst_n <= 0;
		#20 vif.rst_n <= 1;
		
		g0.start(e0.a0.s0);
		phase.drop_objection(this);
	endtask

endclass



// Interface
interface ps2_if (
	input bit clk,
	input bit ps2clk
);

	logic rst_n;
    logic ps2data;
    logic [3:0] data1;
    logic [3:0] data2;
    logic [3:0] data3;
    logic [3:0] data4;

endinterface

module testbench;

	reg clk;
	reg ps2clk;
	
	ps2_if dut_if (
		.clk(clk),
		.ps2clk(ps2clk)
	);
	
	ps2 dut (
		.clk(clk),
		.rst_n(dut_if.rst_n),
		.ps2clk(dut_if.ps2clk),
        .ps2data(dut_if.ps2data),
        .data1(dut_if.data1),
        .data2(dut_if.data2),
        .data3(dut_if.data3),
        .data4(dut_if.data4)
	);

	initial begin
		ps2clk = 1;
		forever begin
			#3 ps2clk = ~ps2clk;
		end
	end

	initial begin
		clk = 0;
		forever begin
			#10 clk = ~clk;
		end
	end

	initial begin
		uvm_config_db#(virtual ps2_if)::set(null, "*", "ps2_vif", dut_if);
		run_test("test");
	end

endmodule
