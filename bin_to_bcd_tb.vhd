----------------------------------------------------------------------------------
-- Name: Daniel Hopfinger
-- Date: 18.08.2021
-- Module: bin_to_bcd_tb.vhd
-- Description:
-- Testbench to the bin_to_bcd module.
--
-- History:
-- Version  | Date       | Information
-- ----------------------------------------
--  0.0.1   | 18.08.2021 | Initial version.
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library gen;

entity bin_to_bcd_tb is
end bin_to_bcd_tb;

architecture sim of bin_to_bcd_tb is

    constant C_CLK_PERIOD : time := 10 ns;

    constant C_BIN_BITSIZE : integer := 16; --! Amount of bits for integer
    constant C_BCD_BITSIZE : integer := C_BIN_BITSIZE + integer(4.0*ceil(real(C_BIN_BITSIZE) / 3.0)); --! Amount of necessary bits for bcd representation of integer

    constant C_INPUT_BITSIZE : integer := 16; --! Bitsize of the input data size

    signal clk : std_logic := '1';
    signal rst : std_logic := '1';

    signal busy       : std_logic;                                      --! DUT Signals
    signal bin_input  : std_logic_vector(C_BIN_BITSIZE - 1 downto 0);   --! DUT Signals
    signal bin_vld    : std_logic;                                      --! DUT Signals
    signal bcd_output : std_logic_vector(C_BCD_BITSIZE - 1 downto 0);   --! DUT Signals
    signal bcd_vld    : std_logic;                                      --! DUT Signals

begin

    clk <= not clk after C_CLK_PERIOD / 2;
    rst <= '0' after 10 * C_CLK_PERIOD;

    master_proc : process
        variable var_bcd_data : integer range 0 to 2**16 - 1 := 0;
    begin

        if rst = '1' then
            wait until rst = '0';
        end if;
        wait for 50 * C_CLK_PERIOD;
        wait until rising_edge(clk);


        --! Test 
        for i in 0 to 2**C_INPUT_BITSIZE - 1 loop
            
            bin_input <= std_logic_vector(to_unsigned(i, bin_input'length));
            bin_vld   <= '1';
            wait for 1 * C_CLK_PERIOD;
            bin_vld <= '0';
            
            --! Check if busy signal is set 
            wait for 1 * C_CLK_PERIOD;
            assert busy = '1'
            report  "Busy signal not set!"
            severity failure;

            wait until rising_edge(bcd_vld);
            wait for 1 * C_CLK_PERIOD;

            --! Convert BCD data back to standard logic vector
            var_bcd_data := 0;
            for j in 0 to (C_BCD_BITSIZE / 4) - 1 loop
                var_bcd_data := var_bcd_data + (to_integer(unsigned(bcd_output(j*4 + 3 downto 4*j))) * 10**j);
            end loop;
            

            --! Check for correct calculation
            assert var_bcd_data = to_integer(unsigned(bin_input))
            report  "Wrong BCD value calculated!" & lf &
                    "Expected: " & integer'image(to_integer(unsigned(bin_input))) & lf &
                    "Acutal: " & integer'image(var_bcd_data)
            severity failure;

            wait for 1 * C_CLK_PERIOD;

            --! Check if busy signal is set 
            wait for 1 * C_CLK_PERIOD;
            assert busy = '0'
            report  "Busy signal is still set!"
            severity failure;

            wait for 10 * C_CLK_PERIOD;

        end loop;


        std.env.stop(0);

    end process master_proc;

    dut : entity gen.bin_to_bcd(rtl)
    generic map(
        G_BIN_BITSIZE => C_BIN_BITSIZE,
        G_BCD_BITSIZE => C_BCD_BITSIZE
    )
    port map(
        i_clk        => clk,
        i_rst        => rst,
        o_busy       => busy,
        i_bin_input  => bin_input,
        i_bin_vld    => bin_vld,
        o_bcd_output => bcd_output,
        o_bcd_vld    => bcd_vld
    );

end sim;
