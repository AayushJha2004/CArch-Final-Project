library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity optimized_divider is
    port(
        clk, reset: in std_logic;
        start: in std_logic;
        divider, dividend: in std_logic_vector (63 downto 0);
        ready: out std_logic;
        rep_check: out std_logic_vector (7 downto 0);
        quotient: out std_logic_vector (63 downto 0);
        remainder: out std_logic_vector (63 downto 0)
    );
end optimized_divider;

architecture arch of optimized_divider is
    constant WIDTH: integer := 64;
    type state_type is (idle, load, op);
    signal state_reg, state_next: state_type;
    signal divider_reg, divider_next: unsigned(WIDTH-1 downto 0);
    signal dividend_reg, dividend_next: unsigned(2*WIDTH downto 0);
    signal rep_check_reg, rep_check_next: unsigned (7 downto 0);
    signal intermediate_divider: unsigned (WIDTH downto 0);
    signal intermediate_result: unsigned (WIDTH downto 0);
    signal intermediate_result2: unsigned (WIDTH downto 0);
    signal intermediate_dividend: unsigned (2*WIDTH downto 0);

begin
    -- state and quotient register process block
    process(clk, reset)
    begin
        if (reset = '1') then 
            state_reg <= idle;
            divider_reg <= (others => '0');
            dividend_reg <= (others => '0');
            rep_check_reg <= (others => '0');
        elsif (clk'event and clk = '1') then 
            state_reg <= state_next;
            divider_reg <= divider_next;
            dividend_reg <= dividend_next;
            rep_check_reg <= rep_check_next;
        end if;
    end process;

    -- next-state combinational logic block
    process(start, state_reg, divider_reg, dividend_reg, divider, dividend, rep_check_reg, intermediate_divider, intermediate_result, intermediate_result2, intermediate_dividend)
    begin
        -- default value
        state_next <= state_reg;
        divider_next <= divider_reg;
        dividend_next <= dividend_reg;
        rep_check_next <= rep_check_reg;
        intermediate_divider <= (others => '0');
        intermediate_result <= (others => '0');
        intermediate_result2 <= (others => '0');
        intermediate_dividend <= (others => '0');
        ready <= '0';
        case state_reg is
            when idle =>
                if (start = '1') then 
                    state_next <= load;
                end if;
                ready <= '1';
            when load =>
                state_next <= op;
                divider_next <= unsigned(divider);
                dividend_next <= "00000000000000000000000000000000000000000000000000000000000000000" & unsigned(dividend);
                rep_check_next <= (others => '0');
            when op =>
                rep_check_next <= rep_check_reg + 1;  
                intermediate_divider <= ("0" & divider_reg);
                intermediate_result <= dividend_reg(2*WIDTH downto WIDTH);
                intermediate_result2 <= intermediate_result - intermediate_divider;
                if (intermediate_result < intermediate_divider) then 
                    dividend_next <= shift_left(dividend_reg, 1);
                else
                    intermediate_dividend <= intermediate_result2 & dividend_reg(WIDTH-1 downto 0);
                    dividend_next <=  intermediate_dividend(2*WIDTH-1 downto 0) & '1';
                end if;
                if (rep_check_next = to_unsigned(WIDTH+1, 8)) then 
                    state_next <= idle;
                end if;
        end case;
    end process;

    -- output logic

    quotient <= std_logic_vector(dividend_reg(WIDTH-1 downto 0));
    remainder <= std_logic_vector(shift_right(dividend_reg(2*WIDTH-1 downto WIDTH), 1));
    rep_check <= std_logic_vector(rep_check_reg);
    
end arch;