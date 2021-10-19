----------------------------------------------------------------------------------
-- Name: Daniel Hopfinger
-- Date: 10.08.2021
-- Module: bin_to_bcd.vhd
-- Description:
-- Implementation of the double dabbler algorithm.
--
-- History:
-- Version  | Date       | Information
-- ----------------------------------------
--  0.0.1   | 10.08.2021 | Initial version.
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use ieee.numeric_std.all;
use ieee.math_real.all;



entity bin_to_bcd is
    generic (
        G_BIN_BITSIZE : integer range 1 to 128 := 32; --! Amount of bits for the binary integer
        G_BCD_BITSIZE : integer range 4 to 128 := 32  --! Amount of bits for the bcd integer
    );
    port (
        i_clk        : in  std_logic;                                       --! System clock
        i_rst        : in  std_logic;                                       --! System reset
        o_busy       : out std_logic;                                       --! Bus signal indicating calculation
        i_bin_input  : in  std_logic_vector(G_BIN_BITSIZE - 1 downto 0);    --! Input of binary integer
        i_bin_vld    : in  std_logic;                                       --! Valid signal for input
        o_bcd_output : out std_logic_vector(G_BCD_BITSIZE - 1 downto 0);    --! Output of bcd integer
        o_bcd_vld    : out std_logic                                        --! Valid signal for output
    );
end bin_to_bcd;

architecture rtl of bin_to_bcd is

    --constant C_BIT_CNT_LENGTH : integer := integer(ceil(log2(real(G_BIN_BITSIZE))));
    constant C_BIT_CNT_LENGTH : integer := G_BIN_BITSIZE; --! Size of the counter iterating through the input bits
    --constant C_BCD_CNT_LENGTH : integer := integer(ceil(log2(real(G_BIN_BITSIZE / 4))));
    constant C_BCD_CNT_LENGTH : integer := G_BCD_BITSIZE / 4; --! Size of the counter interating through the bcd digits

    type conv_fsm is (
        init,       --! Initialisation
        idle,       --! Idle state waiting for i_bin_vld
        shift,      --! Shift input vector
        bcd_add,    --! Add 3 to bcd digits
        wait_cycle  --! Wait one cycle
    );
    signal conv_state : conv_fsm;

    signal busy : std_logic; --! Internal busy signal forwarded to output o_busy

    signal bcd_vld    : std_logic; --! Internal bcd_vld signal forwarded to output o_bcd_vld
    signal bcd_vld_r1 : std_logic;
    signal bcd_output : std_logic_vector(G_BCD_BITSIZE - 1 downto 0); --! Internal bcd_output signal forwarded to o_bcd_output

    signal bin_register : std_logic_vector(G_BIN_BITSIZE - 1 downto 0); --! Register storing the initial and shifted binary value
    signal bcd_register : std_logic_vector(G_BCD_BITSIZE - 1 downto 0); --! Register storing the bcd value

    --signal bin_cnt : unsigned(C_BIT_CNT_LENGTH - 1 downto 0);
    signal bin_cnt : integer range 0 to C_BIT_CNT_LENGTH; --! Counter iterating the bits of bin_register
    --signal bcd_cnt : unsigned(C_BCD_CNT_LENGTH - 1 downto 0);
    signal bcd_cnt : integer range 0 to C_BCD_CNT_LENGTH; --! Counter iterating the decimals of bcd_register


begin

    --! Set internal signals to output ports
    o_bcd_vld    <= bcd_vld;
    o_bcd_output <= bcd_output;
    o_busy       <= busy;
    busy <= '0' when conv_state = idle else '1';

    --! fsm_extract
    --! Shift state iterates through bits in bit_register and shifts left at each iteration.
    --! Add state iterates through digits of bcd_register. If digit is greater than 5 then add 3.
    process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst = '1' then
                conv_state <= init;
            else
                bcd_vld <= '0';
                bcd_output <= bcd_register;
                
                case conv_state is
                    when init =>
                        conv_state <= idle;

                    when idle =>
                        if i_bin_vld = '1' then
                            bin_register <= i_bin_input;
                            bcd_register <= (others => '0');
                            bin_cnt <= 0;
                            bcd_cnt <= 0;
                            conv_state   <= bcd_add;
                        end if;

                    when shift =>
                        bcd_register <= bcd_register(G_BCD_BITSIZE - 2 downto 0) & bin_register(G_BIN_BITSIZE - 1);
                        bin_register <= bin_register(G_BIN_BITSIZE - 2 downto 0) & '0';
                        bin_cnt <= bin_cnt + 1;
                        conv_state <= bcd_add;

                        if bin_cnt = C_BIT_CNT_LENGTH - 1 then
                            conv_state <= wait_cycle;
                        else
                            bcd_cnt <= 0;
                            conv_state <= bcd_add;
                        end if;

                    when bcd_add =>
                        if unsigned(bcd_register(bcd_cnt*4 + 3 downto 4*bcd_cnt)) >= x"5" then
                            bcd_register(bcd_cnt*4 + 3 downto 4*bcd_cnt) <= std_logic_vector(unsigned(bcd_register(bcd_cnt*4 + 3 downto 4*bcd_cnt)) + x"3");
                        end if;

                        if bcd_cnt = C_BCD_CNT_LENGTH - 1 then
                            conv_state <= shift;
                        else
                            bcd_cnt <= bcd_cnt + 1;
                        end if;
                    
                    when wait_cycle =>
                        bcd_vld    <= '1';
                        conv_state <= idle;


                    when others =>
                        null;
                end case;

            end if;
        end if;
    end process;

end rtl;