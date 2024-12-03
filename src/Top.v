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
    // datapath
    //pc
    wire [31:0] current_pc;
    wire [31:0] pc_add_4;
    wire        no_need;
    wire [31:0] next_pc;
    wire [31:0] JB_Unit_out;
    //im
    wire [31:0] inst;
    //decoder
    wire [4:0]  dc_out_opcode;
    wire [2:0]  dc_out_func3;
    wire        dc_out_func7;
    wire [4:0]  dc_out_rs1_index;
    wire [4:0]  dc_out_rs2_index;
    wire [4:0]  dc_out_rd_index;
    // imm_ext
    wire [31:0] imm_ext_data;
    // RegFile
    wire [31:0] wb_data;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    // ALU
    wire [31:0] alu_op1_data;
    wire [31:0] alu_op2_data;
    wire [31:0] alu_Out;
    // JB_Unit
    wire [31:0] JB_Unit_op1;
    // dm
    wire [31:0] ld_data;
    // ld_filter
    wire [31:0] ld_data_f;
    // control signal
    //wire        aluOut_bit0;
    wire        next_pc_sel;
    wire [3:0]  im_w_en;
    wire        wb_en;
    wire        jb_op1_sel;
    wire        alu_op1_sel;
    wire        alu_op2_sel;
    wire [4:0]  control_opcode_out;
    wire [2:0]  control_func3_out;
    wire        control_func7_out;
    wire        wb_sel;
    wire [3:0]  dm_w_en;

    Controller controller(
        .opcode(dc_out_opcode),
        .func3(dc_out_func3),
        .func7(dc_out_func7),
        .aluOut_bit0(alu_Out[0]),
        .next_pc_sel(next_pc_sel),
        .im_w_en(im_w_en),
        .wb_en(wb_en),
        .jb_op1_sel(jb_op1_sel),
        .alu_op1_sel(alu_op1_sel),
        .alu_op2_sel(alu_op2_sel),
        .opcode_out(control_opcode_out),
        .func3_out(control_func3_out),
        .func7_out(control_func7_out),
        .wb_sel(wb_sel),
        .dm_w_en(dm_w_en)
    );

    Adder adder(
        .operand1(current_pc),
        .operand2(32'd4),
        .cin(1'b0),
        .result(pc_add_4),
        .cout(no_need)
    );

    Mux next_pc_mux(
        .input0(JB_Unit_out),
        .input1(pc_add_4),
        .select(next_pc_sel),
        .result(next_pc)
    );

    Reg_PC pc(
        .clk(clk),
        .rst(rst),
        .next_pc(next_pc),
        .current_pc(current_pc)
    );

    SRAM im(
        .clk(clk),
        .w_en(im_w_en),
        .address(current_pc[15:0]),
        .write_data(32'b0),
        .read_data(inst)
    );

    Decoder decoder(
        .inst(inst),
        .dc_out_opcode(dc_out_opcode),
        .dc_out_func3(dc_out_func3),
        .dc_out_func7(dc_out_func7),
        .dc_out_rd_index(dc_out_rd_index),
        .dc_out_rs1_index(dc_out_rs1_index),
        .dc_out_rs2_index(dc_out_rs2_index)
    );

    Imm_Ext imm_ext(
        .inst(inst),
        .imm_ext_out(imm_ext_data)
    );

    RegFile regfile(
        .clk(clk),
        .wb_en(wb_en),
        .wb_data(wb_data),
        .rd_index(dc_out_rd_index),
        .rs1_index(dc_out_rs1_index),
        .rs2_index(dc_out_rs2_index),
        .rs1_data_out(rs1_data),
        .rs2_data_out(rs2_data)
    );

    Mux alu_op1_mux(
        .input0(rs1_data),
        .input1(current_pc),
        .select(alu_op1_sel),
        .result(alu_op1_data)
    );

    Mux alu_op2_mux(
        .input0(rs2_data),
        .input1(imm_ext_data),
        .select(alu_op2_sel),
        .result(alu_op2_data)
    );

    ALU alu(
        .opcode(dc_out_opcode),
        .func3(dc_out_func3),
        .func7(dc_out_func7),
        .operand1(alu_op1_data),
        .operand2(alu_op2_data),
        .alu_out(alu_Out)
    );

    Mux jb_op1_mux(
        .input0(rs1_data),
        .input1(current_pc),
        .select(jb_op1_sel),
        .result(JB_Unit_op1)
    );

    JB_Unit jb(
        .operand1(JB_Unit_op1),
        .operand2(imm_ext_data),
        .jb_out(JB_Unit_out)
    );

    SRAM dm(
        .clk(clk),
        .w_en(dm_w_en),
        .address(alu_Out[15:0]),
        .write_data(rs2_data),
        .read_data(ld_data)
    );

    LD_Filter ld_filter(
        .func3(dc_out_func3),
        .ld_data(ld_data),
        .ld_data_f(ld_data_f)
    );

    Mux wb(
        .input0(ld_data_f),
        .input1(alu_Out),
        .select(wb_sel),
        .result(wb_data)
    );

endmodule