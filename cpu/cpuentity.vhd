--CPUEntity.vhd- CPUģ��
--------------------------------------------------------
--��ȡָ�����롢ִ�С��ô桢д���������ģ��ͨ��Ԫ������
--������������������һ��������CPU
--------------------------------------------------------
--2004-09-04
library ieee;
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use work.unitPack.all;

entity CPUEntity is	
	port(	reset	:in     std_logic;                    --��λ
	        clk		:in 	std_logic;			          --ʱ��
			--OuterDB	:INOUT	byte;--�ڴ������� 
		    --inDB    :in byte;--���ݴ��ڴ浽cpupu
			outDB   :out	byte;--����ڴ�����
			memAddr	:out	byte;--�ڴ��ַ�� 			
			wr		:out 	std_logic;                    --�ڴ��дʹ��
			flag    :out    std_logic_vector(3 downto 0); --״̬λCZVS					
			RegSel	:in		std_logic_vector(2 downto 0); --�Ĵ���ѡ��					
			RegOut	:out	byte --�Ĵ���ֵ���
		);
end CPUEntity;

architecture CPUArch of CPUEntity is   
	--*** to IF Unit 
	signal  s_i_PCPlusOffset	: byte;
	signal  s_PCStall 		: std_logic;
	signal  s_IFFlush 		: std_logic; 
	signal  s_tempZ,s_tempC	: std_logic;  
	--*** to ID Unit  	
	signal  s_PCInc1        : byte;
	signal  s_d_IR			: byte;	 	
	signal  s_w_WBData		: byte;
	signal  s_w_destReg		: std_logic_vector(1 downto 0);
	signal  s_w_wRegEn		: std_logic;   
	signal  s_RegSel		: std_logic_vector(1 downto 0);
	signal  s_RegOut		: byte;		
	--*** to Ex Unit
	signal  s_e_SA			: std_logic_vector(1 downto 0);
	signal  s_e_SB			: std_logic_vector(1 downto 0);	
	signal  s_e_RAOut		: byte;
    signal  s_e_RBOut		: byte;
	signal  s_e_IMM			: byte;
	signal  s_e_ALUSrc      : std_logic_vector(2 downto 0);
	signal  s_e_ALUOpr      : std_logic_vector(3 downto 0);
	signal  s_e_SetFlag     : std_logic_vector(2 downto 0);
    signal	s_e_wrMem		: std_logic_vector(1 downto 0);
    signal	s_e_wRegEn      : std_logic;
	signal  s_e_destReg		: std_logic_vector(1 downto 0);
	signal  s_e_MemToReg    : std_logic;
	signal  s_forwardA		: std_logic_vector(1 downto 0);
	signal  s_forwardB		: std_logic_vector(1 downto 0);	   
	--*** to MemAccess Unit
	signal  s_PCaddr		: byte;	
	signal  s_m_ALUOut		: byte;
	signal  s_m_RBdata      : byte;
	signal  s_m_wrMem 		: std_logic_vector(1 downto 0);
	signal  s_m_wRegEn		: std_logic;
	signal  s_m_memToReg	: std_logic;
	signal  s_m_destReg		: std_logic_vector(1 downto 0);
	signal 	s_m_out         : byte;
	signal 	s_m_in          : byte;
	signal 	s_m_adr         : byte;
	signal 	s_m_wr          : std_logic;
	--*** to Forwarding Unit  
	signal 	s_w_ALUOut		 : byte; 		
	signal  s_m_SA			 : std_logic_vector(1 downto 0); 
	signal  s_w_SA			 : std_logic_vector(1 downto 0);	
	--*** to WB Unit  
	signal s_w_memToReg	     : std_logic;  --ѡ���д������Դ(s_w_ALUOut��OuterDB) 
	signal s_m_flag          : std_logic_vector(3 downto 0);
	--*** to WB	  
	signal s_w_flag          : std_logic_vector(3 downto 0);
	signal  s_w_MemOut		 : byte;
	signal  s_w_wrMem 		 : std_logic_vector(1 downto 0);
   
    ------------------------------------- 
	component IFEntity is    --ȡָģ��
	port (	reset		: in  STD_LOGIC;	
			clk			: in  STD_LOGIC;
			Z			: in  std_logic; --״̬λ
			C           : in  std_logic; 
			tempZ	    : in  std_logic; --��ʱ״̬λ,��·����	
			tempC       : in  std_logic; 			
			e_setFlag	: in  std_logic_vector(2 downto 0);
			PCPlusOffset: in  byte;			--PC + Offset
			PCStall 	: in  std_logic;	--'1' : PC ���ֲ���  
			IFFlush		: in  std_logic;    --'1' : NOP->IR	 
			OuterDB		: in  byte;	
			PC_addr		: out byte; 	    --PC��Ϊ�ڴ��ַ���,������һ���ĵ�ȡָ
			d_PCInc1 	: out byte;			--PC + 1
			d_IR   		: out byte 			--ָ��Ĵ������          	
	);
	end component IFEntity;  
	
	component IDEntity is    --����ģ��
	port(	reset	: in std_logic;
			clk		: in std_logic;	 			
			d_IR	: in byte;	   
			d_PCInc1 : in byte;	
			--*** for Regs Bank	 
			w_WBData  : in byte;	 			
			w_destReg : in std_logic_vector(1 downto 0);  -- Destination Reg index
			w_wRegEn  : in std_logic;  -- '1' enable   			
			e_SA,e_SB	: out std_logic_vector(1 downto 0);	
			i_PCPlusOffset : out byte;
			--*** for ALU	 
			e_RAOut,e_RBOut	: out byte;	
			e_IMM		: out byte;	
			e_ALUSrc	: out std_logic_vector(2 downto 0);
			e_ALUOpr	: out std_logic_vector(3 downto 0);
			e_SetFlag	: out std_logic_vector(2 downto 0);	
			--*** for Memory 
			e_wrMem	: out std_logic_vector(1 downto 0); --"00" write, "01" read, "1-" do nothing
			--*** for Regs
			e_wRegEn  : out  std_logic;		--�Ĵ���дʹ�� 
			e_destReg : out  std_logic_vector(1 downto 0); 
			e_MemToReg : out std_logic;	    --�ڴ�д��Ĵ���ʹ��  			
			--Cpu Interface ---------------------------------
			RegSel 	: in std_logic_vector(1 downto 0);
			RegOut	: out byte
			);
	end component ;	 
	
	component ExEntity is   --ִ��ģ��
	port(	reset,clk   : in std_logic;
			--*** Input for ALU		        
			e_RAOut,e_RBOut	: in byte;	 			
			e_ALUSrc		: in std_logic_vector(2 downto 0);
			e_ALUOpr		: in std_logic_vector(3 downto 0);
			e_SetFlag		: in std_logic_vector(2 downto 0);	
			e_IMM			: in byte;			
					
		    forwardA,forwardB  : in  std_logic_vector(1 downto 0);	
			--*** for Forwarding  
			e_SA		: in std_logic_vector(1 downto 0);
			m_SA    	: out std_logic_vector(1 downto 0);		
			
			e_ALUOut  	: in byte;
			w_WBdata  	: in byte;			
			m_ALUOut	: out byte;
			m_RBdata  	: out byte;	  
			i_tempZ	    : out std_logic;
			i_tempC     : out std_logic;
			--*** Control Signal for Ex_MemReg & Mem_WBReg 
			m_flag		: out std_logic_vector(3 downto 0);
			e_wRegEn  	: IN  std_logic; 
			m_wRegEn 	: out std_logic; 
			e_memToReg  : in std_logic;
			m_memToReg  : out std_logic;
			e_destReg 	: IN  std_logic_vector(1 downto 0); 
			m_destReg 	: out std_logic_vector(1 downto 0);			
			e_wrMem		: IN std_logic_vector(1 downto 0); --"00" write, "01" read, "1-" do nothing  			
			m_wrMem	  	: out std_logic_vector(1 downto 0) --"00" write, "01" read, "1-" do nothing					
		);
	end component;  
		
	component MemAccessEntity is  --�ô�ģ��
	port(	reset,clk	: in std_logic;
			m_wrMem		: in std_logic_vector(1 downto 0);
			w_wrMem     : out std_logic_vector(1 downto 0);
			m_ALUOut	: in byte;    -- Memory addr
			m_RBdata	: in byte;
			wr			: out std_logic; --�ڴ��д���� '1':read , '0':write
			--OuterDB		: inout byte;
			inDB        : in byte;
			outDB       : out byte;
			w_ALUOut	: out byte;	
			w_MemOut	: out byte;
			-----------------
			m_flag		: in std_logic_vector(3 downto 0);	   
			w_flag		: out std_logic_vector(3 downto 0);
			----------
			PC          : in  byte;
			addr        : out byte;
			----------
			--*** for Forwarding 
			m_SA		: in std_logic_vector(1 downto 0);
			w_SA		: out std_logic_vector(1 downto 0);	
			
			--*** for WB Reg
			m_wRegEn  	: in std_logic; 
			m_destReg 	: in std_logic_vector(1 downto 0); 
			m_memToReg  : in std_logic;
			
			--*** for WB Reg
			w_wRegEn 	: out std_logic; 
			w_destReg	: out std_logic_vector(1 downto 0); 
			w_memToReg  : out std_logic
		);
	end component;
	
	component ForwardingEntity	is     --������ؼ�⼰��·����ģ��
	port(	m_wRegEn		: in  std_logic;
			w_wRegEn		: in  std_logic;
			m_SA			: in  std_logic_vector(1 downto 0);
			w_SA			: in  std_logic_vector(1 downto 0);
			e_SA			: in  std_logic_vector(1 downto 0);
			e_SB			: in  std_logic_vector(1 downto 0);				
			forwardA		: out std_logic_vector(1 downto 0);	
			forwardB		: out std_logic_vector(1 downto 0)
		);
	end component ;	
	
	component HazardDetectEntity is   --������ؼ�⼰����ģ�� 
	port(	m_wrMem	: in std_logic_vector(1 downto 0);
			w_wrMem : in std_logic_vector(1 downto 0);
			d_IR	: in byte;
			IFFlush	: out std_logic;
			PCStall : out std_logic
		);
	end component;
	component asynram is
	port(	din : in byte;
			dout: out byte;
			adr : in byte;
			wr  : in std_logic;
			reset : in std_logic
		);	
	end component;	
begin  
	--һ����ˮ,ȡָ
	IFUnit: IFEntity port map (reset=>reset,
								clk=>clk,								
								Z=>s_m_flag(2),
								C=>s_m_flag(3),
								tempZ=>s_tempZ,
								tempC=>s_tempC,								
								e_setFlag=>s_e_SetFlag,
								PCPlusOffset=>s_i_PCPlusOffset,
								PCStall=>s_PCStall,
								IFFlush=>s_IFFlush,	
								--OuterDB=>OuterDB,
								OuterDB=>s_m_in,--���ݴ��ڴ����cpu	
								PC_addr=>s_PCaddr,
								d_PCInc1=>s_PCInc1,
								d_IR=>s_d_IR							
							);
	--������ˮ,����			
	IDUnit: IDEntity port map (	reset=>reset,	
								clk=>clk,
                     			d_IR=>s_d_IR,
								d_PCInc1=>s_PCInc1,	
								w_WBData=>s_w_WBData,
								w_destReg=>s_w_destReg,
								w_wRegEn=>s_w_wRegEn,
								i_PCPlusOffset=>s_i_PCPlusOffset,
							    e_SA=>s_e_SA,
								e_SB=>s_e_SB,
								e_RAOut=>s_e_RAOut,
								e_RBOut=>s_e_RBOut,
								e_IMM =>s_e_IMM,
								e_ALUSrc=>s_e_ALUSrc,
								e_ALUOpr=>s_e_ALUOpr,
								e_SetFlag=>s_e_SetFlag,
								e_wrMem=>s_e_wrMem,
								e_wRegEn=>s_e_wRegEn,
								e_destReg=>s_e_destReg,
								e_MemToReg=>s_e_MemToReg,  							
								RegSel=>s_RegSel,
								RegOut=>s_RegOut
							);
	--������ˮ,ִ��/������Ч��ַ						
    ExUnit: ExEntity port map(	reset=>reset,
								clk=>clk,
	      					   	e_RAOut=>s_e_RAOut,
								e_RBOut=>s_e_RBOut,
								e_ALUSrc=>s_e_ALUSrc,
								e_ALUOpr=>s_e_ALUOpr,
								e_SetFlag=>s_e_SetFlag,
								e_IMM =>s_e_IMM, 
								e_wrMem=>s_e_wrMem,
								e_wRegEn=>s_e_wRegEn,
								e_destReg=>s_e_destReg,
								e_MemToReg=>s_e_MemToReg,
								forwardA=>s_forwardA,
								forwardB=>s_forwardB,
								e_ALUOut=>s_m_ALUOut,
								e_SA=>s_e_SA,								
							    m_SA=>s_m_SA,						
								m_ALUOut=>s_m_ALUOut,
								w_WBData=>s_w_WBData,
								m_flag=>s_m_flag,		 
								i_tempZ=>s_tempZ,
								i_tempC=>s_tempC,
								m_RBdata=>s_m_RBdata,
								m_wrMem =>s_m_wrMem,
								m_wRegEn=>s_m_wRegEn,
								m_memToReg=>s_m_memToReg,
								m_destReg=>s_m_destReg
							);
	--�ڴ�
	AsynramAccessUnit:asynram port map(din=>s_m_out,
									   dout=>s_m_in,
									   adr=>s_m_adr,
									   wr=>s_m_wr,
									   reset=>reset
	);	 
	--�ļ���ˮ,�����ڴ�						
	MemAccessUnit: MemAccessEntity	port map (reset=>reset,
											  clk=>clk,
											  m_wrMem=>s_m_wrMem,
											  w_wrMem=>s_w_wrMem,
											  m_ALUOut=>s_m_ALUOut,
											  m_RBdata=>s_m_RBdata,	
											  wr=>s_m_wr,
											  --OuterDB=>OuterDB,
											  inDB=>s_m_in,
											  outDB=>s_m_out,
											  w_ALUOut=>s_w_ALUOut,
											  w_MemOut=>s_w_Memout,
											  m_flag=>s_m_flag,
											  w_flag=>s_w_flag,
											  --
											  PC=>s_PCaddr,
											  --addr=>memAddr,
											  addr=>s_m_adr,
											  m_SA=>s_m_SA,
											  w_SA=>s_w_SA,	  					  
											  m_wRegEn=>s_m_wRegEn,
											  m_destReg=>s_m_destReg,
											  m_memToReg=>s_m_memToReg,
											  w_wRegEn=>s_w_wRegEn,
											  w_destReg=>s_w_destReg,
											  w_memToReg=>s_w_memToReg
											 );
		 
	--***************************************
	--�弶��ˮ,��д�Ĵ���
    with s_w_memToReg select	--ѡ���д������Դ
		s_w_WBData  <= 	s_w_ALUOut  when '1',
						s_w_MemOut	when others;
	process(clk)
	begin
		if FALLING_EDGE(clk) then
			flag <= s_w_flag;
		end if;
	end process;
	--***************************************	  

	--��·����
	ForwardUnit: ForwardingEntity port map(	m_wRegEn=>s_m_wRegEn,
											w_wRegEn=>s_w_wRegEn,
											m_SA=>s_m_SA,
											w_SA=>s_w_SA,
											e_SA=>s_e_SA,
											e_SB=>s_e_SB,
											forwardA=>s_forwardA,
											forwardB=>s_forwardB
										);
	--�ṹ��������صĴ���
	HDUnit: HazardDetectEntity port map ( m_wrMem=>s_m_wrMem,
										  w_wrMem=>s_w_wrMem,
										  d_IR=>s_d_IR, 							    
		 								  IFFlush=>s_IFFlush,
										  PCStall=>s_PCStall
										); 	
	-- debug	
	process(RegSel,s_d_IR,s_PCAddr,s_RegOut)
	begin
		case RegSel is
		when "111" => RegOut <= s_d_IR;
		when "110" => RegOut <= s_PCAddr; 
		when others   => s_RegSel <= RegSel(1 downto 0);  RegOut <= s_RegOut;
		end case;
		outDB <= s_m_in;
		memAddr <=s_m_adr;
		wr <= s_m_wr;
	end process;
end architecture ;