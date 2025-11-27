//EESC427 TUTORIAL # FALL 2015

module decoder(

    // input from the IR
    input [15:0] instruction,

    // input flags
    input Z_flag_in,
    input F_flag_in,
    input N_flag_in,
    input clk,
    input global_reset,
    //input [15:0] Q_imem, // do we even need this? mk

    output [7:0] Imm_8,

    // scan chain
    input scan_en,
    input scan_in,
    output scan_out,

    // RF declarations
    output reg [15:0] Read_Addr_A,  
    output reg [15:0] Read_Addr_B,
    output reg [15:0] Write_Addr_reg,
    output reg Write_en,

    // control signals
    output reg CIN,
    output reg SEL_4,
    output reg SEL_1,
    output reg [1:0] SEL_2,
    output reg SEL_3,
    output reg [1:0] SEL_ALU,
    output reg [1:0] SEL_shifter,
    output reg [1:0] SEL31MUX,
    output reg SEL_inv_IMM,
    output reg CEB,
    output reg WEB,

    // PC control
    output reg bcond,
    output reg jcond,
    output reg jal,
    output reg [7:0] disp,
    output reg stall
);

reg [15:0] instr_reg;
reg [15:0] instr_next;

// Instruction fields
wire [3:0] opcode           = instr_reg[15:12];
wire [3:0] rdest            = instr_reg[11:8];
wire [3:0] opcode_extension = instr_reg[7:4];
wire [3:0] rsrc             = instr_reg[3:0];

wire [15:0] A_reg = 16'b1 << rsrc;
wire [15:0] B_reg = 16'b1 << rdest;

assign Imm_8 = instr_reg[7:0];

reg [3:0] ImmHi;
reg [3:0] ImmLo;
reg Z_flag_reg;
reg F_flag_reg;
reg N_flag_reg;
reg [15:0] Write_Addr;

// ============================================================
// ===============  COMBINATIONAL DECODER  ====================
// ============================================================

assign scan_out = instr_next[15];

always @(*) begin
    
    if (global_reset) begin
    
        Read_Addr_A = 4'b0000;
        Read_Addr_B = 4'b0000;
        Write_Addr  = 4'b0000;
        Write_en    = 1'b0;
        CIN = 1'b0;
        SEL_1 = 1'b0;
        SEL_2 = 2'b00;
        SEL_3 = 1'b0;
        SEL_4 = 1'b0;
        SEL_ALU = 2'b00;
        SEL_shifter = 2'b00;
        SEL31MUX = 2'b00;
        SEL_inv_IMM = 1'b0;
        CEB = 1'b1;
        WEB = 1'b1;
        ImmHi = Imm_8[7:4];
        ImmLo = Imm_8[3:0];
        stall = 1'b0;
        bcond = 1'b0;
        jcond = 1'b0;
        jal = 1'b0;
    end 

        else begin

    Read_Addr_A = A_reg;
    Read_Addr_B = B_reg;

    end

    if (scan_en) begin
        instr_next = {instr_reg[14:0], scan_in};
        Read_Addr_A = 1'b0;
        Read_Addr_B = 1'b0;
        Write_Addr  = 1'b0;
        Write_en    = 1'b0;
        CIN = 1'b0;
        SEL_1 = 1'b0;
        SEL_2 = 2'b00;
        SEL_3 = 1'b0;
        SEL_4 = 1'b0;
        SEL_ALU = 2'b00;
        SEL_shifter = 2'b00;
        SEL31MUX = 2'b00;
        SEL_inv_IMM = 1'b0;
        CEB = 1'b1;
        WEB = 1'b1;
        ImmHi = Imm_8[7:4];
        ImmLo = Imm_8[3:0];

    end else begin
        instr_next = instruction;
    end

    case (opcode)

        // ======================================================
        // ALU register-register group (opcode = 0000)
        // ======================================================
        4'b0000: begin
            Read_Addr_A = A_reg;
            Read_Addr_B = B_reg;
            Write_Addr  = B_reg;
            Write_en    = 1'b1;
            SEL_1       = 1'b0;
            SEL_4       = 1'b0;
            SEL_2       = 2'b00;
            SEL31MUX    = 2'b01;
            CIN         = 1'b0;

            case (opcode_extension)
                4'b0101 : SEL_ALU = 2'b00; // ADD
                4'b1001: begin // SUB
                    SEL_ALU = 2'b00;
                    SEL_2   = 2'b01;
                    CIN     = 1'b1;
                end
                4'b1011: begin // CMP
                    SEL_ALU = 2'b00;
                    SEL_2   = 2'b01;
                    CIN     = 1'b1;
                    Write_en = 1'b0;
                end
                4'b1101: begin // MOV
                    SEL_ALU = 2'b00;
                    SEL_1   = 1'b1;
                end
                4'b0001: SEL_ALU = 2'b01; // AND
                4'b0010: SEL_ALU = 2'b10; // OR
                4'b0011: SEL_ALU = 2'b11; // XOR

                default: SEL_ALU = 2'b00;
            endcase
        end

        // ======================================================
        // Immediate ALU ops
        // ======================================================
        4'b0101, 4'b1001, 4'b0001, 4'b0010, 4'b0011, 4'b1011: begin
            Read_Addr_B = B_reg;
            Write_Addr  = B_reg;
            Write_en    = 1'b1;
            SEL_1       = 1'b0;
            SEL_4       = 1'b0;
            SEL_2       = 2'b10;
            SEL_inv_IMM = 1'b0;
            SEL31MUX    = 2'b01;
            CIN         = 1'b0;

            case (opcode)
                4'b0101: SEL_ALU = 2'b00; // ADDI
                4'b1001: begin // SUBI
                    SEL_ALU = 2'b00;
                    SEL_inv_IMM = 1'b1;
                    CIN = 1'b1;
                end
                4'b0001: SEL_ALU = 2'b01; // ANDI
                4'b0010: SEL_ALU = 2'b10; // ORI
                4'b0011: SEL_ALU = 2'b11; // XORI
                4'b1011: begin // CMP
                    SEL_inv_IMM = 1'b1;
                    CIN = 1'b1;
                    Write_en = 1'b0;
                end
            endcase
        end

        // ======================================================
        // MOVI (1101)
        // ======================================================
        4'b1101: begin
            //Read_Addr_B = B_reg;
            Write_Addr = B_reg;
            Write_en    = 1'b1;
            SEL_1       = 1'b1;
            SEL_4       = 1'b0;
            SEL_2       = 2'b10;
            SEL_inv_IMM = 1'b0;
            SEL31MUX    = 2'b01;
            SEL_ALU     = 2'b00;
        end

        // ======================================================
        // LSH / LSHI (1000)
        // ======================================================
        4'b1000: begin
            Read_Addr_A = A_reg;
            Read_Addr_B = B_reg;
            Write_en    = 1'b1;
            SEL_4       = 1'b0;
            SEL_3       = 1'b0;
            SEL31MUX    = 2'b10;

            casez(opcode_extension)
                4'b0100: SEL_shifter = 2'b00; // LSH
                4'b000?: SEL_shifter = 2'b01; // LSHI
            endcase
        end

        // ======================================================
        // LUI (1111)
        // ======================================================
        4'b1111: begin
            Write_Addr  = B_reg;
            Write_en    = 1'b1;
            SEL_4       = 1'b0;
            SEL_inv_IMM = 1'b0;
            SEL_3       = 1'b1;
            SEL31MUX    = 2'b10;
            SEL_shifter = 2'b10;
        end

        // ======================================================
        // LOAD / STOR / JCOND (0100)
        // ======================================================
        4'b0100: begin
            case (opcode_extension)

                // LOAD
                4'b0000: begin
                    Read_Addr_A = A_reg;
                    Write_Addr  = B_reg;
                    Write_en    = 1'b1;
                    SEL_4       = 1'b0;
                    SEL31MUX    = 2'b00;
                    CEB         = 1'b0;
                    WEB         = 1'b1;
                end

                // STOR
                4'b0100: begin
                    Read_Addr_A = A_reg;
                    Read_Addr_B = B_reg;
                    CEB         = 1'b0;
                    WEB         = 1'b0;
                    Write_en    = 1'b0;
                end

                // JAL
                4'b1000: begin
                    Write_en = 1'b1;
                    Write_Addr = B_reg;
                    SEL_4 = 1'b1;
                    jal = 1'b1;
                end
                //jcond
                4'b1100: begin
                    Write_en = 1'b0;
                    Read_Addr_A = A_reg;
                    jal = 1'b0;

                    case (instr_reg[11:8])
                        4'b0000: jcond = Z_flag_reg;
                        4'b0001: jcond = ~Z_flag_reg;
                        4'b1101: jcond = N_flag_reg | Z_flag_reg;
                        4'b0110: jcond = N_flag_reg;
                        4'b0111: jcond = ~N_flag_reg;
                        4'b1000: jcond = F_flag_reg;
                        4'b1001: jcond = ~F_flag_reg;
                        4'b1100: jcond = ~N_flag_reg & ~Z_flag_reg;
                        4'b1110: jcond = 1'b1;
                        4'b1111: jcond = 1'b0;
                        default: jcond = 1'b0;
                    endcase
                end
            endcase
        end


        // ======================================================
        // BCOND
        // ======================================================
        4'b1100: begin
            case (instr_reg[11:8])
                4'b0000: bcond = Z_flag_reg;
                4'b0001: bcond = ~Z_flag_reg;
                4'b1101: bcond = N_flag_reg | Z_flag_reg;
                4'b0110: bcond = N_flag_reg;
                4'b0111: bcond = ~N_flag_reg;
                4'b1000: bcond = F_flag_reg;
                4'b1001: bcond = ~F_flag_reg;
                4'b1100: bcond = ~N_flag_reg & ~Z_flag_reg;
                4'b1110: bcond = 1'b1;
                4'b1111: bcond = 1'b0;
                default: bcond = 1'b0;
            endcase

            disp = instr_reg[7:0];
        end

    endcase
end


// ============================================================
// ===============  FLAG + BRANCH SEQUENTIAL LOGIC  ============
// ============================================================

always @(posedge clk) begin

    if (global_reset) begin
        instr_reg <= 0;
        Z_flag_reg <= 0;
        F_flag_reg <= 0;
        N_flag_reg <= 0;
        
    end 
    else if (opcode == 0000 || opcode == 1011) begin
        Z_flag_reg <= Z_flag_in;
        F_flag_reg <= F_flag_in;
        N_flag_reg <= N_flag_in;
        instr_reg <= instr_next;
    end
    else begin
        instr_reg <= instr_next;
    end

end

always @(negedge clk) begin

    if (global_reset) begin
        Write_Addr_reg <= 0;
    end 

    else begin
        Write_Addr_reg <= Write_Addr;
    end

end

endmodule
