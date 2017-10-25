--IFEntity.vhd- ȡָģ��
----------------------------------------------------------
--�����ڴ��ַ����ȡָ�����ָ��Ĵ�����Ϊ��һ��׼������
--������PC
----------------------------------------------------------
--2004-09-04
library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use work.unitpack.all;

entity IFEntity is
	port (	reset		: in  STD_LOGIC;	
			clk			: in  STD_LOGIC;	  	
			Z,C			: in  std_logic; 	--״̬�Ĵ�������
			tempZ,tempC : in  std_logic; 	--��ʱ״̬λ,��·����	
			e_setFlag	: in  std_logic_vector(2 downto 0);
			PCPlusOffset: in  byte;			--PC + Offset
			PCStall 	: in  std_logic;	--'1' : PC ���ֲ���  
			IFFlush		: in  std_logic;    --'1' : NOP->IR	 
			OuterDB		: in  byte;	   
			PC_addr		: out byte; 	    --PC��Ϊ�ڴ��ַ���,������һ���ĵ�ȡָ
			d_PCInc1 	: out byte;			--PC + 1
			d_IR   		: out byte 			--ָ��Ĵ������          	
	);
end IFEntity; 

architecture IFArch of IFEntity is
	signal PC,IR		: std_logic_vector(7 downto 0);
	signal PCIncSel		: std_logic; 
	signal s_PCInc1,PCnext : std_logic_vector(7 downto 0);	
	signal op		: std_logic_vector(3 downto 0);
	signal s_flag   : std_logic_vector(3 downto 0);
	signal s_selZ,s_selC : std_logic;
	signal ZZ,CC : std_logic;
begin 	
 	--������������� *****************************************	
    op <= IR(7 downto 4);	--������		
	with e_setFlag select 
		ZZ <=  Z		when flag_hold,
			   tempZ    when others;
	with e_setFlag select 
		CC <=  C		when flag_hold,
			   tempC    when others;
	s_selZ <= '1' WHEN( op=JRZ  AND ZZ='1')  --�ж��Ƿ���ת
	 			   --OR ( op=JRNZ AND ZZ='0')
	               OR op=JR
	              else
	          '0'; 	
	s_selC <= '1' WHEN( op=JRC  AND CC='1')  --�ж��Ƿ���ת
	 			   --OR ( op=JRNC AND CC='0')
	              else
	          '0'; 		 		
 	PCIncSel <= '1'  WHEN s_selZ='1' or s_selC='1'  	 				 
				      ELSE
 			    '0';
 	s_PCInc1 <= PC + x"01";		        
 	WITH PCIncSel SELECT
 			PCnext <= s_PCInc1 	    WHEN '0',
 				      PCPlusOffset  WHEN '1',                    
                      s_PCInc1  	when others;  	 
   
	process(reset,clk,PCStall)
	begin
		if reset = '0' then
			PC <= x"00";								 
		elsif FALLING_EDGE(clk) and (PCStall='0') then	 
		    PC <= PCnext;
		end if;
	end process; 
	--*******************************************	
	PC_addr <= PC;	--PC��Ϊ�ڴ��ַ	
	d_IR    <= IR;
	--*******************************************
	--ȡָ
	process(reset,clk,OuterDB,IFFlush)	
	begin
		if reset='0' then	
			IR <= NopIns;	-- NULL operation 
		elsif RISING_EDGE(clk) then
			case IFFlush is
				when '0' 	=> IR <= OuterDB;
				when others => IR <= NOPIns;
			end case;
			d_PCInc1 <= s_PCInc1;
		end if;	
	end process;
	--*******************************************	
end IFArch;
