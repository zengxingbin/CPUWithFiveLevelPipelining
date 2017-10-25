--ExEntity.vhd- ִ��ģ��
----------------------------------------------------------------------
--��������߼����㡢������Ч��ַ���ṩ����ͨ��
----------------------------------------------------------------------
--2004-09-04
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.unitPack.all;

entity ExEntity is
	port(	reset,clk   		: in std_logic;
			--*** Input for ALU		        
			e_RAOut,e_RBOut		: in byte;	 			
			e_ALUSrc			: in std_logic_vector(2 downto 0);
			e_ALUOpr			: in std_logic_vector(3 downto 0);
			e_SetFlag			: in std_logic_vector(2 downto 0);	
			e_IMM				: in byte;			
		    forwardA,forwardB	: in  std_logic_vector(1 downto 0);--��·ѡ��	
			--*** for Forwarding  
			e_SA				: in std_logic_vector(1 downto 0);
			m_SA    			: out std_logic_vector(1 downto 0);				
			e_ALUOut  			: in byte;
			w_WBdata  			: in byte;			
			m_ALUOut			: out byte;
			m_RBdata  			: out byte;			
			i_tempZ	    		: out std_logic;
			i_tempC     		: out std_logic;
			--*** Control Signal for Ex_MemReg & Mem_WBReg 
			m_flag				: out std_logic_vector(3 downto 0);
			e_wRegEn  			: IN  std_logic; 
			m_wRegEn 			: out std_logic; 
			e_memToReg  		: in std_logic;
			m_memToReg  		: out std_logic;
			e_destReg 			: IN  std_logic_vector(1 downto 0); 
			m_destReg 			: out std_logic_vector(1 downto 0);			
			e_wrMem				: IN std_logic_vector(1 downto 0); --"00" write, "01" read, "1-" do nothing  			
			m_wrMem	  			: out std_logic_vector(1 downto 0) --"00" write, "01" read, "1-" do nothing					
		);
end entity ;  

architecture ExArch of ExEntity is
signal ALUaIn,ALUbIn : byte;   
signal dout			 : byte; 	   
signal C,Z,V,S		 : STD_LOGIC;
signal tempFlag		 : std_logic_vector(3 downto 0);  
begin
	--ѡ��������A,B��������Դ ******************
	with forwardA select
		ALUaIn	<= e_RAOut  when "00",
				   e_ALUOut when "10",
				   w_WBdata when "01",
				   e_RAOut  when others;
	with forwardB select
		ALUbIn	<= e_RBOut  when "00",
				   e_ALUOut when "10",
				   w_WBdata when "01",
				   e_RBOut  when others;
	--******************************************
	ALUActivity:process(ALUaIn,ALUbIn,e_ALUSrc,e_ALUOpr,e_setFlag,e_IMM,tempFlag)
	variable ALUResult,opR,opS : std_logic_vector(8 downto 0); -- 9 bits	
	variable cx,tempC,tempZ,tempV,tempS : std_logic; 	
	begin
		case e_ALUSrc is  --ѡ��ALU�����������
			when selA0	=>	opR := '0'&ALUaIn;	opS := ZERO9;
			when selAB	=>	opR := '0'&ALUaIn;	opS := '0'&ALUbIn;
			when selA1	=>	opR := '0'&ALUaIn;	opS := '0'&(X"01");
            when sel0B	=>	opR := ZERO9	;	opS := '0'&ALUbIn;
			when selAF	=>	opR := '0'&ALUaIn;	opS := '1'&(X"FF");
			when selAD	=>	opR := '0'&ALUaIn;	opS := '0'&e_IMM;				
			when others =>  opR := ZERO9;		opS := ZERO9;
		end case;
		case e_ALUOpr is  --ѡ��ALU������
			when aluAdd	  => ALUResult := opR + opS;
							 tempV := ((not opR(7))and(not opS(7))and ALUResult(7)) or (opR(7)and opS(7)and (not ALUResult(7)));  				
			when aluSub	  => ALUResult := opR - opS;
							 --tempV := ( opS(7)and(not opR(7))and (not ALUResult(7))) or ((NOT opS(7))and opR(7)and ALUResult(7));
							 tempV := ( opR(7)and(not opS(7))and (not ALUResult(7))) or ((NOT opR(7))and opS(7)and ALUResult(7));--Ӧ���������Ŷ� 
							 --tempV := ( opR(7)and(not opS(7))and (not ALUResult(7))) or ((NOT opS(7))and opR(7)and ALUResult(7)); 				
			when aluAnd	  => ALUResult := opR and opS;
			when aluOr	  => ALUResult := opR or  opS;
			when aluXor	  => ALUResult := opR xor opS;
			when aluShl	  => ALUResult(7 downto 1) := opR(6 downto 0);
							 ALUResult(0) := '0';	cx := opR(7);
			when aluShr	  => ALUResult(6 downto 0) := opR(7 downto 1);
							 ALUResult(7) := '0';	cx := opR(0); 
			when aluSar	  => ALUResult(6 downto 0) := opR(7 downto 1);
							 ALUResult(7) := opR(7); cx := opR(0);	
			when aluLOADH => ALUResult := opS(4 downto 0)&opR(3 downto 0); 
			when aluLOADL => ALUResult := '0'&opR(7 downto 4)&opS(3 downto 0);
			--when aluMOVI  => ALUResult := "00000"&opS(3 downto 0);
			when others   => null;
		end case; 	
		dout <= ALUResult(7 downto 0);		
		------- Set Flag ------------------------------------------
		case e_ALUOpr is
			when aluAdd|aluSub            =>   tempC := ALUResult(8);			
			when aluShl|aluShr|aluSar     =>   tempC := cx;	
			when aluAnd|aluOr|aluXor 	  =>   tempC := '0'; tempV:= '0'; --�߼�����,״̬λC,Z����
			when others					  =>   null;						
		end case;	
		i_tempC <= tempC;		
		if ALUResult = ZERO9 then	tempZ := '1';
		else tempZ := '0';	end if;	 
		i_tempZ <= tempZ;
		tempS := ALUResult(7);			
		case e_setFlag is
			when flag_hold	  => (C,Z,V,S)<= tempFLAG; 
			when flag_update  => C<=tempC;	Z <= tempZ;	V <= tempV;	S <= tempS;
		    when flag_InnerDB => (C,Z,V,S) <= e_IMM(3 downto 0);
			when flag_clear	  => C<='0'; Z<='0'; V<='0'; S<='0';
			when others		  => (C,Z,V,S)<= tempFLAG; 
		end case;	
	end process;
	--******************************************
	--�޸�״̬�Ĵ���
	WriteFlag:process(reset,clk)
	begin
		if reset = '0' then							
			tempFlag <= "0000";			
		elsif RISING_EDGE(clk) then
			tempFlag <= C&Z&V&S;  		
		end if;
		m_flag <= tempFlag;
	end process;   
	--******************************************
	--�����ź�Ex to Mem
	process(reset,clk)
	begin  
		if reset='0' then 
			m_wrMem <= "10";
			m_wRegEn <= '0';
		elsif RISING_EDGE(clk) then
			m_SA <= e_SA;
			m_ALUOut <= dout;
			m_RBdata <= ALUbIn;
			m_wRegEn <= e_wRegEn; 
			m_memToReg <= e_memToReg;
			m_destReg  <= e_destReg;
			m_wrMem  <= e_wrMem;
	    end if;	
	end process;
end architecture ;