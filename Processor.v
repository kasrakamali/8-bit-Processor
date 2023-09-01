module Processor (
    input clk
);

  // 8-bit register file with 8 registers
  reg [7:0] regs[7:0];

  // 256 x 8-bit data memory
  reg [7:0] memory[0:255];

  // 256 x 8-bit program memory
  reg [7:0] p_memory[0:255];

  // 8-bit program counter
  reg [7:0] pc;

  // 8-bit temporary register
  reg [7:0] tmp;

  // Fetch enable signal
  reg f;

  // Status flags
  // I, S, V/P, H, Z, C
  reg [7:0] flags;

  // 31 x 8-bit stack		
  reg [7:0] stk[0:30];

  // Loop index
  integer i;

  // 256 x 8-bit I/O registers
  reg [7:0] IO[0:255];

  // Initialization block
  initial begin

    // Initialize registers
    regs[0] = 8'h00;
    regs[1] = 8'h50;
    regs[2] = 8'h00;
    regs[3] = 8'h00;
    regs[4] = 8'hc9;
    regs[5] = 8'h00;
    regs[6] = 8'hd7;
    regs[7] = 8'h03;

    // Initialize data memory
    memory[0] = 8'h12;
    memory[1] = 8'h20;
    memory[2] = 8'h46;
    memory[3] = 8'hb0;
    memory[4] = 8'hf0;
    memory[5] = 8'h3e;
    memory[6] = 8'h50;
    memory[7] = 8'h73;

    // Initialize I/O registers
    IO[79] = 8'h32;  // Sample input

    // Set fetch enable
    f = 1;

    // Set zero flag
    flags[0] = 1;

    // Load program memory
    p_memory[0] = 8'b01001_010;  // LD immediate (h45 to R[2])
    p_memory[1] = 8'h45;
    p_memory[2] = 8'b01010000;  // LD memory2reg (M[3] to R[0])
    p_memory[3] = 8'h03;
    p_memory[4] = 8'b01011_101;  // LD memory2reg indirect (M[h04+R[7]] to R[5])
    p_memory[5] = 8'h04;
    p_memory[6] = 8'b10_101_010;  // MOV (R[5] to R[2])
    p_memory[7] = 8'b01100000;  // SWAP
    p_memory[8] = 8'b00000_110;  // ADC (R[0]=R[6]+R[0]+carry)
    p_memory[9] = 8'b00110_010;  // XOR (R[0]=R[2]^R[0] , carry=0)
    p_memory[10] = 8'b11001_101;  // RL (R[5]=RL(R[5]))
    p_memory[11] = 8'b01101_101;  // ST reg2memory indirect (M[hfc+R[7]]=R[5])
    p_memory[12] = 8'hfc;
    p_memory[13] = 8'b00101_101;  // ORI (R[5]=R[5]|hf5)
    p_memory[14] = 8'hf5;
    p_memory[15] = 8'b01110_000;  // PUSH R[0]
    p_memory[16] = 8'b01110_101;  // PUSH R[5]
    p_memory[17] = 8'b01111_011;  // POP R[3]
    p_memory[18] = 8'b01110_110;  // PUSH R[6]
    p_memory[19] = 8'b01010001;  // LDP (p_mem[12] to R[0])
    p_memory[20] = 8'h0c;
    p_memory[21] = 8'b01010010;  // LDP (p_mem[R[7]] to R[0])
    p_memory[22] = 8'b01010011;  // ST (R[0] to memory[hf0])
    p_memory[23] = 8'hf0;
    p_memory[24] = 8'b01010100;  // STP (R[0] to p_mem[hfe])
    p_memory[25] = 8'hfe;
    p_memory[26] = 8'b01010101;  // STP (R[0] to p_mem[R[7]])
    p_memory[27] = 8'b01100100;  // PUSHF
    p_memory[28] = 8'b00001_100;  // SBC (R[0]=R[4]-R[0]-carry)
    p_memory[29] = 8'b01100101;  // POPF
    p_memory[30] = 8'b00010_010;  // AND (R[0]=R[0] & R[2])
    p_memory[31] = 8'b01000011;  // JPNC (if carry ==0 -> JP to p_mem[36])
    p_memory[32] = 8'h24;
    p_memory[33] = 8'b01100111;  // IN (R[0]=IO[79])
    p_memory[34] = 8'h4f;
    p_memory[35] = 8'b01100010;  // RET
    p_memory[36] = 8'b00011_001;  // ANDI (R[1]=R[1] & h34)
    p_memory[37] = 8'h34;
    p_memory[38] = 8'b00100_110;  // OR (R[0]=R[0] or R[6])
    p_memory[39] = 8'b00111_011;  // NOT (R[3]=~R[3])
    p_memory[40] = 8'b11000_110;  // CPL (R[6]=-R[6])
    p_memory[41] = 8'b11010_111;  // RR (rotate right R[7])
    p_memory[42] = 8'b11011_101;  // SL (shift left R[5])
    p_memory[43] = 8'b11100_000;  // SRA (arithmatic right shift R[0])
    p_memory[44] = 8'b11101_001;  // SRL (shift right R[1])
    p_memory[45] = 8'b11110_110;  // INC (R[6]=R[6]+1)
    p_memory[46] = 8'b11111_011;  // DEC (R[3]=R[3]-1)
    p_memory[47] = 8'b01100001;  // CALL (pc=33)
    p_memory[48] = 8'h21;
    p_memory[49] = 8'b01100110;  // OUT (IO[160]=R[0])
    p_memory[50] = 8'ha0;
    p_memory[51] = 8'b01000010;  // JPC
    p_memory[52] = 8'h13;

    // Initialize program counter
    pc = 0;
  end

  // Instruction fetch stage
  always @(posedge clk) begin
    // Check fetch enable
    if (f) begin
      // Decode and execute instruction
      casex (p_memory[pc])
        8'b10xxxxxx: regs[p_memory[pc][2:0]] <= regs[p_memory[pc][5:3]];  // MOV
        8'b01100000: begin  // SWAP
          regs[0][3:0] <= regs[0][7:4];
          regs[0][7:4] <= regs[0][3:0];
        end
        8'b00000xxx: begin  // ADC
          if (regs[0] + regs[p_memory[pc][2:0]] + flags[0] > 255) flags[0] <= 1;
          else flags[0] <= 0;
          if (regs[0][3:0] + regs[p_memory[pc][2:0]][3:0] + flags[0] > 15) flags[2] <= 1;
          else flags[2] <= 0;
          regs[0] = regs[0] + regs[p_memory[pc][2:0]] + flags[0];
          if (regs[0] == 0) flags[1] = 1;
          else flags[1] = 0;
          flags[3] = regs[0][7]^regs[0][6]^regs[0][5]^regs[0][4]^regs[0][3]^regs[0][2]^regs[0][1]^regs[0][0];
          if (regs[0][7] == 1) flags[4] = 1;
          else flags[4] = 0;
        end
        8'b00110xxx: begin  // XOR
          regs[0]  = regs[0] ^ regs[p_memory[pc][2:0]];
          flags[0] = 0;
          if (regs[0] == 0) flags[1] = 1;
          else flags[1] = 0;
          flags[3] = regs[0][7]^regs[0][6]^regs[0][5]^regs[0][4]^regs[0][3]^regs[0][2]^regs[0][1]^regs[0][0];
          if (regs[0][7] == 1) flags[4] = 1;
          else flags[4] = 0;
        end
        8'b11001xxx: begin  // RL
          regs[p_memory[pc][2:0]][0] <= flags[0];
          regs[p_memory[pc][2:0]][1] <= regs[p_memory[pc][2:0]][0];
          regs[p_memory[pc][2:0]][2] <= regs[p_memory[pc][2:0]][1];
          regs[p_memory[pc][2:0]][3] <= regs[p_memory[pc][2:0]][2];
          regs[p_memory[pc][2:0]][4] <= regs[p_memory[pc][2:0]][3];
          regs[p_memory[pc][2:0]][5] <= regs[p_memory[pc][2:0]][4];
          regs[p_memory[pc][2:0]][6] <= regs[p_memory[pc][2:0]][5];
          regs[p_memory[pc][2:0]][7] <= regs[p_memory[pc][2:0]][6];
          flags[0] <= regs[p_memory[pc][2:0]][7];
          if (regs[p_memory[pc][2:0]][6:0] == 0 && flags[0] == 0) flags[1] = 1;
          else flags[1] = 0;
          if (regs[p_memory[pc][2:0]][3]) flags[2] = 1;
          else flags[2] = 0;
          flags[3] = flags[0]^regs[p_memory[pc][2:0]][6]^regs[p_memory[pc][2:0]][5]^regs[p_memory[pc][2:0]][4]^regs[p_memory[pc][2:0]][3]^regs[p_memory[pc][2:0]][2]^regs[p_memory[pc][2:0]][1]^regs[p_memory[pc][2:0]][0];
          if (regs[p_memory[pc][2:0]][6] == 1) flags[4] = 1;
          else flags[4] = 0;
        end
        8'b01110xxx: begin  // PUSH
          stk[0] <= regs[p_memory[pc][2:0]];
          for (i = 0; i < 7; i = i + 1) stk[i+1] <= stk[i];
        end
        8'b01111xxx: begin  // POP
          regs[p_memory[pc][2:0]] <= stk[0];
          for (i = 7; i > 0; i = i - 1) stk[i-1] <= stk[i];
        end
        8'b01010010: regs[0] <= p_memory[regs[7]];  // LDP pmem[r7]2r0
        8'b01010101: p_memory[regs[7]] = regs[0];  // r02pmem[r7]
        8'b01100100: begin  // PUSHF
          stk[0] <= flags;
          for (i = 0; i < 7; i = i + 1) stk[i+1] <= stk[i];
        end
        8'b01100101: begin  // POPF
          flags <= stk[0];
          for (i = 7; i > 0; i = i - 1) stk[i-1] <= stk[i];
        end
        8'b00001xxx: begin  // SBC
          if (regs[p_memory[pc][2:0]] - regs[0] - flags[0] > 255) flags[0] <= 1;
          else flags[0] <= 0;
          if (regs[p_memory[pc][2:0]][3:0] - regs[0][3:0] - flags[0] > 15) flags[2] <= 1;
          else flags[2] <= 0;
          regs[0] = regs[p_memory[pc][2:0]] - regs[0] - flags[0];
          if (regs[0] == 0) flags[1] = 1;
          else flags[1] = 0;
          flags[3] = regs[0][7]^regs[0][6]^regs[0][5]^regs[0][4]^regs[0][3]^regs[0][2]^regs[0][1]^regs[0][0];
          if (regs[0][7] == 1) flags[4] = 1;
          else flags[4] = 0;
        end
        8'b00010xxx: begin  // AND
          regs[0]  = regs[0] & regs[p_memory[pc][2:0]];
          flags[0] = 0;
          if (regs[0] == 0) flags[1] = 1;
          else flags[1] = 0;
          flags[3] = regs[0][7]^regs[0][6]^regs[0][5]^regs[0][4]^regs[0][3]^regs[0][2]^regs[0][1]^regs[0][0];
          if (regs[0][7] == 1) flags[4] = 1;
          else flags[4] = 0;
        end
        8'b00100xxx: begin  // OR
          regs[0]  = regs[0] | regs[p_memory[pc][2:0]];
          flags[0] = 1;
          if (regs[0] == 0) flags[1] = 1;
          else flags[1] = 0;
          flags[3] = regs[0][7]^regs[0][6]^regs[0][5]^regs[0][4]^regs[0][3]^regs[0][2]^regs[0][1]^regs[0][0];
          if (regs[0][7] == 1) flags[4] = 1;
          else flags[4] = 0;
        end
        8'b00111xxx: begin  // NOT
          regs[p_memory[pc][2:0]] = ~regs[p_memory[pc][2:0]];
          if (regs[p_memory[pc][2:0]] == 0) flags[1] = 1;
          else flags[1] = 0;
          flags[3] = regs[p_memory[pc][2:0]][7]^regs[p_memory[pc][2:0]][6]^regs[p_memory[pc][2:0]][5]^regs[p_memory[pc][2:0]][4]^regs[p_memory[pc][2:0]][3]^regs[p_memory[pc][2:0]][2]^regs[p_memory[pc][2:0]][1]^regs[p_memory[pc][2:0]][0];
          if (regs[p_memory[pc][2:0]][7] == 1) flags[4] = 1;
          else flags[4] = 0;
        end
        8'b11000xxx: begin  // CPL
          regs[p_memory[pc][2:0]] = -regs[p_memory[pc][2:0]];
          if (regs[p_memory[pc][2:0]] == 0) flags[1] = 1;
          else flags[1] = 0;
          flags[3] = regs[p_memory[pc][2:0]][7]^regs[p_memory[pc][2:0]][6]^regs[p_memory[pc][2:0]][5]^regs[p_memory[pc][2:0]][4]^regs[p_memory[pc][2:0]][3]^regs[p_memory[pc][2:0]][2]^regs[p_memory[pc][2:0]][1]^regs[p_memory[pc][2:0]][0];
          if (regs[p_memory[pc][2:0]][7] == 1) flags[4] = 1;
          else flags[4] = 0;
        end
        8'b11010xxx: begin  // RR
          flags[0] <= regs[p_memory[pc][2:0]][0];
          regs[p_memory[pc][2:0]][0] <= regs[p_memory[pc][2:0]][1];
          regs[p_memory[pc][2:0]][1] <= regs[p_memory[pc][2:0]][2];
          regs[p_memory[pc][2:0]][2] <= regs[p_memory[pc][2:0]][3];
          regs[p_memory[pc][2:0]][3] <= regs[p_memory[pc][2:0]][4];
          regs[p_memory[pc][2:0]][4] <= regs[p_memory[pc][2:0]][5];
          regs[p_memory[pc][2:0]][5] <= regs[p_memory[pc][2:0]][6];
          regs[p_memory[pc][2:0]][6] <= regs[p_memory[pc][2:0]][7];
          regs[p_memory[pc][2:0]][7] <= flags[0];
          if (regs[p_memory[pc][2:0]][7:1] == 0 && flags[0] == 0) flags[1] = 1;
          else flags[1] = 0;
          flags[3] = regs[p_memory[pc][2:0]][7]^regs[p_memory[pc][2:0]][6]^regs[p_memory[pc][2:0]][5]^regs[p_memory[pc][2:0]][4]^regs[p_memory[pc][2:0]][3]^regs[p_memory[pc][2:0]][2]^regs[p_memory[pc][2:0]][1]^flags[0];
          if (flags[0] == 1) flags[4] = 1;
          else flags[4] = 0;
        end
        8'b11011xxx: begin  // SL
          regs[p_memory[pc][2:0]][0] <= 0;
          regs[p_memory[pc][2:0]][1] <= regs[p_memory[pc][2:0]][0];
          regs[p_memory[pc][2:0]][2] <= regs[p_memory[pc][2:0]][1];
          regs[p_memory[pc][2:0]][3] <= regs[p_memory[pc][2:0]][2];
          regs[p_memory[pc][2:0]][4] <= regs[p_memory[pc][2:0]][3];
          regs[p_memory[pc][2:0]][5] <= regs[p_memory[pc][2:0]][4];
          regs[p_memory[pc][2:0]][6] <= regs[p_memory[pc][2:0]][5];
          regs[p_memory[pc][2:0]][7] <= regs[p_memory[pc][2:0]][6];
          flags[0] <= regs[p_memory[pc][2:0]][7];
          if (regs[p_memory[pc][2:0]][6:0] == 0) flags[1] = 1;
          else flags[1] = 0;
          if (regs[p_memory[pc][2:0]][3]) flags[2] = 1;
          else flags[2] = 0;
          flags[3] = regs[p_memory[pc][2:0]][6]^regs[p_memory[pc][2:0]][5]^regs[p_memory[pc][2:0]][4]^regs[p_memory[pc][2:0]][3]^regs[p_memory[pc][2:0]][2]^regs[p_memory[pc][2:0]][1]^regs[p_memory[pc][2:0]][0]^0;
          if (regs[p_memory[pc][2:0]][6] == 1) flags[4] = 1;
          else flags[4] = 0;
        end
        8'b11100xxx: begin  // SRA
          flags[0] <= regs[p_memory[pc][2:0]][0];
          regs[p_memory[pc][2:0]][0] <= regs[p_memory[pc][2:0]][1];
          regs[p_memory[pc][2:0]][1] <= regs[p_memory[pc][2:0]][2];
          regs[p_memory[pc][2:0]][2] <= regs[p_memory[pc][2:0]][3];
          regs[p_memory[pc][2:0]][3] <= regs[p_memory[pc][2:0]][4];
          regs[p_memory[pc][2:0]][4] <= regs[p_memory[pc][2:0]][5];
          regs[p_memory[pc][2:0]][5] <= regs[p_memory[pc][2:0]][6];
          regs[p_memory[pc][2:0]][6] <= regs[p_memory[pc][2:0]][7];
          if (regs[p_memory[pc][2:0]] == 0) flags[1] = 1;
          else flags[1] = 0;
          flags[3] = regs[p_memory[pc][2:0]][7]^regs[p_memory[pc][2:0]][7]^regs[p_memory[pc][2:0]][6]^regs[p_memory[pc][2:0]][5]^regs[p_memory[pc][2:0]][4]^regs[p_memory[pc][2:0]][3]^regs[p_memory[pc][2:0]][2]^regs[p_memory[pc][2:0]][1];
          if (regs[p_memory[pc][2:0]][7] == 1) flags[4] = 1;
          else flags[4] = 0;
        end
        8'b11101xxx: begin  // SRL (Shift Right)
          flags[0] <= regs[p_memory[pc][2:0]][0];
          regs[p_memory[pc][2:0]][0] <= regs[p_memory[pc][2:0]][1];
          regs[p_memory[pc][2:0]][1] <= regs[p_memory[pc][2:0]][2];
          regs[p_memory[pc][2:0]][2] <= regs[p_memory[pc][2:0]][3];
          regs[p_memory[pc][2:0]][3] <= regs[p_memory[pc][2:0]][4];
          regs[p_memory[pc][2:0]][4] <= regs[p_memory[pc][2:0]][5];
          regs[p_memory[pc][2:0]][5] <= regs[p_memory[pc][2:0]][6];
          regs[p_memory[pc][2:0]][6] <= regs[p_memory[pc][2:0]][7];
          regs[p_memory[pc][2:0]][7] <= 0;
          if (regs[p_memory[pc][2:0]][7:1] == 0) flags[1] = 1;
          else flags[1] = 0;
          flags[3] = regs[p_memory[pc][2:0]][7]^regs[p_memory[pc][2:0]][6]^regs[p_memory[pc][2:0]][5]^regs[p_memory[pc][2:0]][4]^regs[p_memory[pc][2:0]][3]^regs[p_memory[pc][2:0]][2]^regs[p_memory[pc][2:0]][1]^0;
          flags[4] = 0;
        end
        8'b11110xxx: begin  // INC
          regs[p_memory[pc][2:0]] = regs[p_memory[pc][2:0]] + 1;
          if (regs[p_memory[pc][2:0]] == 0) flags[1] = 1;
          else flags[1] = 0;
          flags[3] = regs[p_memory[pc][2:0]][7]^regs[p_memory[pc][2:0]][6]^regs[p_memory[pc][2:0]][5]^regs[p_memory[pc][2:0]][4]^regs[p_memory[pc][2:0]][3]^regs[p_memory[pc][2:0]][2]^regs[p_memory[pc][2:0]][1]^regs[p_memory[pc][2:0]][0];
          if (regs[p_memory[pc][2:0]][7] == 1) flags[4] = 1;
          else flags[4] = 0;
        end
        8'b11111xxx: begin  // DEC
          regs[p_memory[pc][2:0]] = regs[p_memory[pc][2:0]] - 1;
          if (regs[p_memory[pc][2:0]] == 0) flags[1] = 1;
          else flags[1] = 0;
          flags[3] = regs[p_memory[pc][2:0]][7]^regs[p_memory[pc][2:0]][6]^regs[p_memory[pc][2:0]][5]^regs[p_memory[pc][2:0]][4]^regs[p_memory[pc][2:0]][3]^regs[p_memory[pc][2:0]][2]^regs[p_memory[pc][2:0]][1]^regs[p_memory[pc][2:0]][0];
          if (regs[p_memory[pc][2:0]][7] == 1) flags[4] = 1;
          else flags[4] = 0;
        end
        8'b01100010: begin  // RET
          pc <= stk[0];
          for (i = 7; i > 0; i = i - 1) stk[i-1] <= stk[i];
        end

        8'b01001xxx: begin
          tmp = p_memory[pc];
          f   = 0;
        end  // LD immediate
        8'b01010000: begin
          tmp = p_memory[pc];
          f   = 0;
        end  // LD memory2reg
        8'b01011xxx: begin
          tmp = p_memory[pc];
          f   = 0;
        end  // LD memory2reg indirect
        8'b01101xxx: begin
          tmp = p_memory[pc];
          f   = 0;
        end  // ST reg2memory indirect
        8'b00101xxx: begin
          tmp = p_memory[pc];
          f   = 0;
        end  // ORI
        8'b01010001: begin
          tmp = p_memory[pc];
          f   = 0;
        end  // LDP pmem[n]2r0
        8'b01010011: begin
          tmp = p_memory[pc];
          f   = 0;
        end  // ST r02mem
        8'b01010100: begin
          tmp = p_memory[pc];
          f   = 0;
        end  // STP r02pmem
        8'b01100110: begin
          tmp = p_memory[pc];
          f   = 0;
        end  // OUT r02I/O
        8'b01100111: begin
          tmp = p_memory[pc];
          f   = 0;
        end  // IN I/O2r0
        8'b00011xxx: begin
          tmp = p_memory[pc];
          f   = 0;
        end  // ANDI
        8'b01010110: begin
          tmp = p_memory[pc];
          f   = 0;
        end  // JP
        8'b01000000: begin
          tmp = p_memory[pc];
          f   = 0;
        end  // JPZ
        8'b01000001: begin
          tmp = p_memory[pc];
          f   = 0;
        end  // JPNZ
        8'b01000010: begin
          tmp = p_memory[pc];
          f   = 0;
        end  // JPC
        8'b01000011: begin
          tmp = p_memory[pc];
          f   = 0;
        end  // JPNC
        8'b01000100: begin
          tmp = p_memory[pc];
          f   = 0;
        end  // JPP
        8'b01000101: begin
          tmp = p_memory[pc];
          f   = 0;
        end  // JPM
        8'b01000110: begin
          tmp = p_memory[pc];
          f   = 0;
        end  // JPV
        8'b01000111: begin
          tmp = p_memory[pc];
          f   = 0;
        end  // JPNV
        8'b01100001: begin
          tmp = p_memory[pc];
          f   = 0;
        end  // CALL
      endcase
    end  // Instruction decode and execute stage
    else begin
      // Decode and execute fetched instruction
      casex (tmp)
        8'b01001xxx: begin  // LD immediate
          regs[tmp[2:0]] = p_memory[pc];
          f = 1;
        end
        8'b01010000: begin  // LD memory2reg
          regs[0] = memory[p_memory[pc]];
          f = 1;
        end
        8'b01011xxx: begin  // LD memory2reg indirect
          regs[tmp[2:0]] = memory[p_memory[pc]+regs[7]];
          f = 1;
        end
        8'b01101xxx: begin  // ST reg2memory indirect
          memory[p_memory[pc]+regs[7]] = regs[tmp[2:0]];
          f = 1;
        end
        8'b00101xxx: begin  // ORI
          regs[tmp[2:0]] = regs[tmp[2:0]] | p_memory[pc];
          flags[0] = 1;
          if (regs[tmp[2:0]] == 0) flags[1] = 1;
          else flags[1] = 0;
          flags[3] = regs[tmp[2:0]][7]^regs[tmp[2:0]][6]^regs[tmp[2:0]][5]^regs[tmp[2:0]][4]^regs[tmp[2:0]][3]^regs[tmp[2:0]][2]^regs[tmp[2:0]][1]^regs[tmp[2:0]][0];
          if (regs[tmp[2:0]][7] == 1) flags[4] = 1;
          else flags[4] = 0;
          f = 1;
        end
        8'b01010001: begin  // LDP pmem2r0
          regs[0] = p_memory[p_memory[pc]];
          f = 1;
        end
        8'b01010011: begin  // ST r02mem
          memory[p_memory[pc]] = regs[0];
          f = 1;
        end
        8'b01010100: begin  // STP r02pmem
          p_memory[p_memory[pc]] = regs[0];
          f = 1;
        end
        8'b01100110: begin  // OUT
          IO[p_memory[pc]] = regs[0];
          f = 1;
        end
        8'b01100111: begin  // IN
          regs[0] = IO[p_memory[pc]];
          f = 1;
        end
        8'b00011xxx: begin  // ANDI
          regs[tmp[2:0]] = p_memory[pc] & regs[tmp[2:0]];
          flags[0] = 0;
          if (regs[tmp[2:0]] == 0) flags[1] = 1;
          else flags[1] = 0;
          flags[3] = regs[tmp[2:0]][7]^regs[tmp[2:0]][6]^regs[tmp[2:0]][5]^regs[tmp[2:0]][4]^regs[tmp[2:0]][3]^regs[tmp[2:0]][2]^regs[tmp[2:0]][1]^regs[tmp[2:0]][0];
          if (regs[tmp[2:0]][7] == 1) flags[4] = 1;
          else flags[4] = 0;
          f = 1;
        end
        8'b01010110: begin  // JP
          pc = p_memory[pc] - 1;
          f  = 1;
        end
        8'b01000000: begin  // JPZ
          if (flags[1]) pc = p_memory[pc] - 1;
          f = 1;
        end
        8'b01000001: begin  // JPNZ
          if (~flags[1]) pc = p_memory[pc] - 1;
          f = 1;
        end
        8'b01000010: begin  // JPC
          if (flags[0]) pc = p_memory[pc] - 1;
          f = 1;
        end
        8'b01000011: begin  // JPNC
          if (~flags[0]) pc = p_memory[pc] - 1;
          f = 1;
        end
        8'b01000100: begin  // JPP
          if (~flags[4]) pc = p_memory[pc] - 1;
          f = 1;
        end
        8'b01000101: begin  // JPM
          if (flags[4]) pc = p_memory[pc] - 1;
          f = 1;
        end
        8'b01000110: begin  // JPV
          if (flags[3]) pc = p_memory[pc] - 1;
          f = 1;
        end
        8'b01000111: begin  // JPNV
          if (~flags[3]) pc = p_memory[pc] - 1;
          f = 1;
        end
        8'b01100001: begin  // CALL
          stk[0] <= pc + 1;
          for (i = 0; i < 7; i = i + 1) stk[i+1] <= stk[i];
          pc = p_memory[pc] - 1;
          f  = 1;
        end
      endcase
    end
    // Increment program counter
    pc = pc + 1;
  end

endmodule

// Testbench
module Processor_tb ();

  // Clock
  reg clk = 1'b0;

  // Toggle clock
  always #20 clk = ~clk;

  // Instantiate design under test
  Processor u0 (clk);

  // Simulate
  initial begin
    #2120 $stop;
  end

endmodule
