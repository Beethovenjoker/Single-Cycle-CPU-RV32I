`include "./src/SRAM.v"
`include "./src/RegFile.v"
`include "./src/Adder.v"
`include "./src/ALU.v"
`include "./src/Controller.v"
`include "./src/Decoder.v"
`include "./src/Imm_Ext.v"
`include "./src/JB_Unit.v"
`include "./src/LD_Filter.v"
`include "./src/Mux.v"
`include "./src/Reg_PC.v"

module Top (
    input clk,
    input rst
);

    Controller controller(
        //input
        .opcode(decoder.dc_out_opcode),
        .func3(decoder.dc_out_func3),
        .func7(decoder.dc_out_func7),
        .aluOut_bit0(alu.alu_out[0]),
        //output
        .next_pc_sel(),
        .im_w_en(),
        .wb_en(),
        .jb_op1_sel(),
        .alu_op1_sel(),
        .alu_op2_sel(),
        .opcode_out(),
        .func3_out(),
        .func7_out(),
        .wb_sel(),
        .dm_w_en()
    );

    Adder adder(
        //input
        .operand1(pc.current_pc),
        .operand2(32'd4),
        .cin(1'b0),
        //output
        .result(),
        .cout()
    );

    Mux next_pc_mux(
        //input
        .input0(jb.jb_out),
        .input1(adder.result),
        .select(controller.next_pc_sel),
        //output
        .result()
    );

    Reg_PC pc(
        //input
        .clk(clk),
        .rst(rst),
        .next_pc(next_pc_mux.result),
        //output
        .current_pc()
    );

    SRAM im(
        //input
        .clk(clk),
        .w_en(controller.im_w_en),
        .address(pc.current_pc[15:0]),
        .write_data(32'b0),
        //output
        .read_data()
    );

    Decoder decoder(
        //input
        .inst(im.read_data),
        //output
        .dc_out_opcode(),
        .dc_out_func3(),
        .dc_out_func7(),
        .dc_out_rd_index(),
        .dc_out_rs1_index(),
        .dc_out_rs2_index()
    );

    Imm_Ext imm_ext(
        //input
        .inst(im.read_data),
        //output
        .imm_ext_out()
    );

    RegFile regfile(
        //input
        .clk(clk),
        .wb_en(controller.wb_en),
        .wb_data(wb.result),
        .rd_index(decoder.dc_out_rd_index),
        .rs1_index(decoder.dc_out_rs1_index),
        .rs2_index(decoder.dc_out_rs2_index),
        //output
        .rs1_data_out(),
        .rs2_data_out()
    );

    Mux alu_op1_mux(
        //input
        .input0(regfile.rs1_data_out),
        .input1(pc.current_pc),
        .select(controller.alu_op1_sel),
        //output
        .result()
    );

    Mux alu_op2_mux(
        //input
        .input0(regfile.rs2_data_out),
        .input1(imm_ext.imm_ext_out),
        .select(controller.alu_op2_sel),
        //output
        .result()
    );

    ALU alu(
        //input
        .opcode(controller.opcode_out),
        .func3(controller.func3_out),
        .func7(controller.func7_out),
        .operand1(alu_op1_mux.result),
        .operand2(alu_op2_mux.result),
        //output
        .alu_out()
    );

    Mux jb_op1_mux(
        //input
        .input0(regfile.rs1_data_out),
        .input1(pc.current_pc),
        .select(controller.jb_op1_sel),
        //output
        .result()
    );

    JB_Unit jb(
        //input
        .operand1(jb_op1_mux.result),
        .operand2(imm_ext.imm_ext_out),
        //output
        .jb_out()
    );

    SRAM dm(
        //input
        .clk(clk),
        .w_en(controller.dm_w_en),
        .address(alu.alu_out[15:0]),
        .write_data(regfile.rs2_data_out),
        //output
        .read_data()
    );

    LD_Filter ld_filter(
        //input
        .func3(controller.func3_out),
        .ld_data(dm.read_data),
        //output
        .ld_data_f()
    );

    Mux wb(
        //input
        .input0(ld_filter.ld_data_f),
        .input1(alu.alu_out),
        .select(controller.wb_sel),
        //output
        .result()
    );

endmodule