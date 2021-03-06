LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE work.unitPack.all;
ENTITY asynram IS
GENERIC(ram_width: POSITIVE :=8; --定义类属参数，ram_width即为m
        adr_width : POSITIVE :=8); --(2**3)×4位的RAM，其中"**"代表指数运算
PORT (
        din	 : IN  STD_LOGIC_VECTOR((ram_width-1) DOWNTO 0);
		dout : OUT STD_LOGIC_VECTOR((ram_width-1) DOWNTO 0);
		adr  : IN  STD_LOGIC_VECTOR((adr_width -1) DOWNTO 0);
		wr  : IN  STD_LOGIC;
		reset : IN STD_LOGIC
);
END asynram;

ARCHITECTURE rtl OF asynram IS
SUBTYPE ram_word IS STD_LOGIC_VECTOR(0 TO (ram_width-1) ); --自定义类型
TYPE ram_type IS ARRAY (0 TO (2**adr_width -1)) OF ram_word;--数组，"**"代表指数运算
SIGNAL ram:ram_type;--数组，即ram的存储单元
BEGIN
	PROCESS(wr,ram,reset) 	
BEGIN
		IF reset='0' THEN
			--ram(0) <=LOADH&"0000";--1011&"0000";将0写入R3寄存器的高四位 	
			--ram(1) <=LOADL&"0011";--1110&"0011";将3写入R3寄存器的第低思维
			--ram(2) <=MOV&R0&R3;   --0010&R0&R3;R3 -> R0
			--由前三条指令完成MOVI R0,3    
			--ram(3) <= MOV&R1&R3;  --00100111 R1 = R0 = 3
			--ram(4) <= SHRins&R0&"00";--0110 R0 r0=1
			--ram(5) <= ADD&R1&R0;-- 0000 R1=4
			--ram(6) <= JRC&"0100";--0101 如果C=1，跳到第条指令
			--ram(7) <= SHLins&R0&"00";--0111 R0=2
			--ram(8) <= ORins&R1&R0;  -- 1000 R1=6
			--ram(9) <= SUBB&R1&R0;   --0001 R1=4
			--ram(10) <= JRZ&"0001"; -- 1101 z=1 jump to 12
			--ram(11) <= ANDins&R1&R0; --0011 R1=0
			--ram(12) <= STORE&R1&R1;--1010
			--ram(13) <= LOAD&R3&R0; --1001 R3=[R0]=0
			--ram(14) <= NOPins; --nop 11000000
			--ram(15) <= JR&"1110";--0100 jump to the 14
			
			---------------------------------
			ram(0) <=LOADL&"0001";--R3.l4="0001"
			ram(1) <=LOADH&"1000";--R3.h4="1000",->R3="10000001"->complement of -127
			ram(2) <=MOV&R0&R3;--R3=R0="10000001" ->-127
			
			ram(3) <=LOADL&"1000";--R3.l4="1000"
			ram(4) <=LOADH&"0000";--R3.h4="0000"->R3=8 LOADH=1011
			ram(5) <=MOV&R1&R3;--R3=R1="00001000"->8
			
			ram(6) <=SUBB&R0&R1;--R0=-127,R1=8,R0 = R0-R1=-135->overflow v=1
			
			ram(7) <=MOV&R0&R1;--R0=R1="00001000"->8
			ram(8) <=CMP&R0&R1;--R0=R1->Z=0
			ram(9) <=JRZ&"0010";--Z=0,so jump to the 12th instruction PC=10->PC+2->PC = 12
			--the next two instruction will be ignored
			ram(10) <=MOV&R0&R1;
			ram(11) <=MOV&R0&R1;
			
			ram(12) <=ADD&R0&R1;--R0=8 R1=8 R0=R0+R1="00010000"->16
			ram(13) <=JRC&"0001";-- C!=0,don't jump
			ram(14) <=SHRins&R1&"00";--R1=8->shift right->R1="00000100"=4
			ram(15) <=ORins&R0&R1;--R0=16 R1=4 then R0="00010100"=20
			ram(16) <=ANDins&R0&R1;--R0=20 R1=4 then R0="00000100"=4
			ram(17) <=SUBB&R0&R1;--R1=R0=4 then R0 = 0 Z=0
			ram(18) <=LOAD&R2&R1;--R1=4 [R1]->R2,R2=ram(4)="10110000"
			ram(19) <=STORE&R1&R0;--R0=0,R1=4,R0->[R1],ram(4)="00000000"
			ram(20) <=LOAD&R2&R1;--R1=4 [R1]->R2,R2=ram(4)="00000000"
		END IF;	
			
		IF wr='0' THEN  --写
			ram(conv_integer(adr)) <= din; --conv_integer函数将二进制地址转换为十进制（例，0，1，3等）
		ELSE--读
			--din <= Z8;
		    dout <= ram(conv_integer(adr));                 
		END IF;
	END PROCESS;
	
END rtl;

