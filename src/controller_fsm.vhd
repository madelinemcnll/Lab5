----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           i_clk : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is

    component button_debounce is 
    	Port(	 clk: in  STD_LOGIC;
			     reset : in  STD_LOGIC;
			     button: in STD_LOGIC;
			     action: out STD_LOGIC);
    end component button_debounce;


	signal f_Q  : std_logic_vector (1 downto 0) := "00";
	--signal f_Q_next : std_logic_vector (1 downto 0) :="00";
	signal w_adv : std_logic;

begin
    
    debounce : button_debounce
    port map (
        clk => i_clk,
	    reset => i_reset,
        button => i_adv,
	    action => w_adv
    );
    
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_reset = '1' then
                f_Q <= "00";
            elsif w_adv = '1' then
                if (f_Q = "00") then f_Q <= "01";
                    elsif (f_Q = "01") then f_Q <= "10";
                    elsif (f_Q = "10") then f_Q <= "11";
                    elsif (f_Q = "11") then f_Q <= "00";
            end if;
            end if;
            end if;
    end process;
    
    
    --Next state logic
    --f_Q_next(0) <= ((NOT f_Q(1)) AND (NOT f_Q(0)) AND w_adv AND (NOT i_reset)) OR ((f_Q(1)) AND (NOT f_Q(0)) AND w_adv AND (NOT i_reset)) ;
    --f_Q_next(1) <= ((NOT f_Q(1)) AND (f_Q(0)) AND w_adv AND (NOT i_reset)) OR ((f_Q(1)) AND (NOT f_Q(0)) AND w_adv AND (NOT i_reset)) ;
    
    
    
    --Output logic
    o_cycle(3) <= '1' when f_Q = "11" else '0';
    o_cycle(2) <= '1' when f_Q = "10" else '0';
    o_cycle(1) <= '1' when f_Q = "01" else '0';
    o_cycle(0) <= '1' when f_Q = "00" else '0';
    

end FSM;
