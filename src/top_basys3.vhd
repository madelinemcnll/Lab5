--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        btnR    :   in std_logic; -- clock reset
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
	component clock_divider is
	   generic ( constant k_DIV : natural := 2	);
	   port ( 	i_clk    : in std_logic;		   -- basys3 clk
			    i_reset  : in std_logic;		   -- asynchronous
			    o_clk    : out std_logic		   -- divided (slow) clock
	            );
    end component clock_divider;
    
    component controller_fsm is
        port ( i_reset : in STD_LOGIC;
               i_adv   : in STD_LOGIC;
               o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
    end component controller_fsm;
    
    component ALU is
        Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
               i_B : in STD_LOGIC_VECTOR (7 downto 0);
               i_op : in STD_LOGIC_VECTOR (2 downto 0);
               o_result : out STD_LOGIC_VECTOR (7 downto 0);
               o_flags : out STD_LOGIC_VECTOR (3 downto 0));
    end component ALU;
    
    component twos_comp is
        Port (
            i_bin: in std_logic_vector(7 downto 0);
            o_sign: out std_logic;
            o_hund: out std_logic_vector(3 downto 0);
            o_tens: out std_logic_vector(3 downto 0);
            o_ones: out std_logic_vector(3 downto 0)
        );
    end component twos_comp;
    
    component TDM4 is
        port (  i_clk		: in  STD_LOGIC;
                i_reset		: in  STD_LOGIC; -- asynchronous
                i_D3 		: in  STD_LOGIC_VECTOR (3 downto 0);
		        i_D2 		: in  STD_LOGIC_VECTOR (3 downto 0);
		        i_D1 		: in  STD_LOGIC_VECTOR (3 downto 0);
		        i_D0 		: in  STD_LOGIC_VECTOR (3 downto 0);
		        o_data		: out STD_LOGIC_VECTOR (3 downto 0);
		        o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
        );
    end component TDM4;
    
    component sevenseg_decoder is
    Port ( i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
           o_seg_n : out STD_LOGIC_VECTOR (6 downto 0));
    end component sevenseg_decoder;
	
	
	signal w_clkreset : STD_LOGIC;
	signal w_clk : STD_LOGIC;
	signal w_fsmcycle : STD_LOGIC_VECTOR (3 downto 0);
	signal w_regA : STD_LOGIC_VECTOR (7 downto 0);
	signal w_regB : STD_LOGIC_VECTOR (7 downto 0);
	signal w_regIN : STD_LOGIC_VECTOR (7 downto 0);
	signal w_ALUtoMUX : STD_LOGIC_VECTOR (7 downto 0);
	signal w_MUXtoTC : STD_LOGIC_VECTOR (7 downto 0);
	signal w_sign : STD_LOGIC;
	signal w_sign1 : STD_LOGIC_VECTOR (3 downto 0);
	signal w_hund : STD_LOGIC_VECTOR (3 downto 0);
	signal w_tens : STD_LOGIC_VECTOR (3 downto 0);
	signal w_ones : STD_LOGIC_VECTOR (3 downto 0);
	signal w_TDMtoDec : STD_LOGIC_VECTOR (3 downto 0);
	

  
begin
	-- PORT MAPS ----------------------------------------
	w_clkreset <= (btnU or btnR); 
	
	clkdiv_inst : clock_divider 		--instantiation of clock_divider to take 
        generic map ( k_DIV => 12500000) -- 4 Hz clock from 100 MHz
        port map (						  
            i_clk   => clk,
            i_reset => w_clkreset,
            o_clk   => w_clk
        );  
        
    controller : controller_fsm
        port map (
            i_reset => btnU,
            i_adv   => btnC,
            o_cycle => w_fsmcycle
        );
        
    led(3) <= w_fsmcycle(3);
    led(2) <= w_fsmcycle(2);
    led(1) <= w_fsmcycle(1);
    led(0) <= w_fsmcycle(0);
    
    w_regIN(7) <= sw(7);
    w_regIN(6) <= sw(6);
    w_regIN(5) <= sw(5);
    w_regIN(4) <= sw(4);
    w_regIN(3) <= sw(3);
    w_regIN(2) <= sw(2);
    w_regIN(1) <= sw(1);
    w_regIN(0) <= sw(0);
    
    register_procA : process (w_fsmcycle(0), btnU)
    begin
        if btnU = '1' then
            w_regA <= "00000000";        -- reset state
        elsif (rising_edge(w_fsmcycle(0))) then
            w_regA <= w_regIN;    -- next state becomes current state
        end if;
    end process register_procA;
    
    register_procB : process (w_fsmcycle(1), btnU)
    begin
        if btnU = '1' then
            w_regB <= "00000000";        -- reset state
        elsif (rising_edge(w_fsmcycle(1))) then
            w_regB <= w_regIN;    -- next state becomes current state
        end if;
    end process register_procB;
    
    alu1 : ALU
    port map (
        i_A => w_regA,
        i_B => w_regB,
        i_op(2) => sw(15),
        i_op(1) => sw(14),
        i_op(0) => sw(13),
        o_result => w_ALUtoMUX,
        o_flags(3) => led(15),
        o_flags(2) => led(14),
        o_flags(1) => led(13),
        o_flags(0) => led(12)
    );
    
    w_MUXtoTC <= w_regA when w_fsmcycle = "0010" else
                 w_regB when w_fsmcycle = "0100" else
                 w_ALUtoMUX when w_fsmcycle = "1000" else
                 "00000000";
    
    twocomp : twos_comp
    port map (
        i_bin => w_MUXtoTC,
        o_sign => w_sign,
        o_hund => w_hund,
        o_tens => w_tens,
        o_ones => w_ones
    );

    w_sign1 <= "0001" when (w_sign = '1') else
               "0000";
    
    tdm : TDM4
    port map (  i_clk		=> w_clk,
                i_reset		=> btnU,
                i_D3 		=> w_sign1,
		        i_D2 		=> w_hund,
		        i_D1 		=> w_tens,
		        i_D0 		=> w_ones,
		        o_data		=> w_TDMtoDec,
		        o_sel(3)		=> an(3),	-- selected data line (one-cold)
		        o_sel(2)		=> an(2),
		        o_sel(1)		=> an(1),
		        o_sel(0)		=> an(0)
    );
    
    decoder : sevenseg_decoder
    port map ( i_Hex => w_TDMtoDec,
               o_seg_n => seg     
    );
    
    
    
	

	
	
	-- CONCURRENT STATEMENTS ----------------------------
	
	
	-- PROCESSES ----------------------------------------
	led(0) <= '0';
	led(1) <= '0';
	led(2) <= '0';
	led(3) <= '0';
	led(4) <= '0';
	led(5) <= '0';
	led(6) <= '0';
	led(7) <= '0';
	led(8) <= '0';
	led(9) <= '0';
	led(10) <= '0';
	led(11) <= '0';
 
	
	
end top_basys3_arch;
