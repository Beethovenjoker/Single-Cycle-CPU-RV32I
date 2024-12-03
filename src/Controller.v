`define Is_R_type   (opcode == 5'b01100)
`define Is_I_load   (opcode == 5'b00000)
`define Is_I_arth   (opcode == 5'b00100)
`define Is_JALR     (opcode == 5'b11001)
`define Is_I_type   (`Is_I_load || `Is_I_arth || `Is_JALR)
`define Is_S_type   (opcode == 5'b01000)
`define Is_B_type   (opcode == 5'b11000)
`define Is_LUI      (opcode == 5'b01101)
`define Is_AUIPC    (opcode == 5'b00101)
`define Is_U_type   (`Is_LUI || `Is_AUIPC)
`define Is_J_type   (opcode == 5'b11011)


module Controller(
    input       [4:0]   opcode,
    input       [2:0]   func3,
    input               func7,
    input               aluOut_bit0,
    output reg          next_pc_sel,
    output      [3:0]   im_w_en,
    output reg          wb_en,
    output reg          jb_op1_sel,
    output reg          alu_op1_sel,
    output reg          alu_op2_sel,
    output      [4:0]   opcode_out,
    output      [2:0]   func3_out,
    output              func7_out,
    output reg          wb_sel,
    output reg  [3:0]   dm_w_en
);

    assign im_w_en = 4'b0;
    assign opcode_out = opcode;
    assign func3_out = func3;
    assign func7_out = func7;

    // next_pc_sel
    always @(opcode, aluOut_bit0)begin
        if(`Is_J_type || `Is_JALR || (`Is_B_type && aluOut_bit0))begin
            next_pc_sel <= 0;
        end
        else begin
            // pc == pc + 4
            next_pc_sel <= 1;
        end
    end

    // wb_en
    always @(opcode)begin
        if(`Is_U_type || `Is_J_type || `Is_I_type || `Is_R_type)begin
            wb_en <= 1'b1;
        end
        else begin
            wb_en <= 1'b0;
        end
    end

    // jb_op1_sel
    always @(opcode)begin
        if(`Is_JALR)begin
            // mux = rs1
            jb_op1_sel <= 0;
        end
        else begin
            // mux = pc
            jb_op1_sel <= 1;
        end
    end

    // alu_op1_sel
    always @(opcode)begin
        if(`Is_U_type || `Is_J_type || `Is_JALR)begin
            // mux = pc
            alu_op1_sel <= 1'b1;
        end
        else begin
            // mux = rs1
            alu_op1_sel <= 0;
        end
    end

    // alu_op2_sel
    always @(opcode)begin
        if(`Is_R_type || `Is_B_type)begin
            // mux = rs2
            alu_op2_sel <= 0;
        end
        else begin
            // mux = immediate data
            alu_op2_sel <= 1;
        end
    end

    // wb_sel
    always @(opcode)begin
        if(`Is_I_load)begin
            // mux = ld_data_f
            wb_sel <= 0;
        end
        else begin
            // mux = alu_out
            wb_sel <= 1;
        end
    end

    // dm_w_en
    always @(opcode , func3) begin
        if(`Is_S_type)begin
            // store
            dm_w_en[0] <= 1'b1;
            dm_w_en[1] <= (func3[0] || func3[1]);
            dm_w_en[3:2] <= {2{func3[1]}};
        end
        else begin
            dm_w_en <= 4'b0000;
        end
    end

endmodule