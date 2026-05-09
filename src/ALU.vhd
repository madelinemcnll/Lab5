----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
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

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
           
end ALU;

architecture Behavioral of ALU is

--declare components
    
    component ripple_adder is
        Port ( A : in STD_LOGIC_VECTOR (7 downto 0);
           B : in STD_LOGIC_VECTOR (7 downto 0);
           Cin : in STD_LOGIC;
           S : out STD_LOGIC_VECTOR (7 downto 0);
           Cout : out STD_LOGIC);
    end component ripple_adder;
        
        
            
    signal w_BtoSum : STD_LOGIC_VECTOR (7 downto 0);
    signal w_AandB : STD_LOGIC_VECTOR (7 downto 0);
    signal w_AorB : STD_LOGIC_VECTOR (7 downto 0);
    signal w_SumtoMux : STD_LOGIC_VECTOR (7 downto 0);
    signal w_cout : STD_LOGIC;
    signal w_result : STD_LOGIC_VECTOR (7 downto 0);
            
            
begin

--Port Maps--

    w_BtoSum <= i_B when i_op(0) = '0' else
                NOT i_B;
    
    w_AandB <= i_A AND i_B;
    
    w_AorB <= i_A OR i_B;

    adder: ripple_adder
    port map( A     => i_A,
              B     => w_BtoSum,
              Cin   => i_op(0),
              S     => w_SumtoMux,
              Cout  => w_cout
    );
    
    w_result <= w_SumtoMux when i_op = ("00" OR "01") else
                w_AandB when i_op = "10" else
                w_AorB when i_op = "11";
                
    o_flags(3) <= '1' when w_result(3) = '1' else
                  '0';
    
    o_flags(0) <= '1' when w_result = "0000" else
                  '0';
                  
    o_flags(2) <= '1' when (w_cout AND (NOT i_op(1))) = '1' else
                  '0';
                  
    o_flags(1) <= '1' when ((i_A(3) XOR w_SumtoMux(3)) AND (NOT i_op(1)) AND (i_op(0) XNOR i_A(3) XNOR i_B(3))) = '1' else
                  '0';         
    
end Behavioral;
