library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity optimized_multplier is
    port(
        clk, reset: in std_logic;
        multiplier, multiplicand: in std_logic_vector (63 downto 0);
        start: in std_logic;
        ready: out std_logic;
        rep_check: out std_logic_vector (7 downto 0);
        product: out std_logic_vector (128 downto 0)
    );
end optimized_multplier;

architecture arch of optimized_multplier is
    -- constant to store the width of the multiplier and the multiplicand i.e. 64
    constant WIDTH: integer := 64;
    -- state transition register which stores the states that our Finite state machine is in acting as the control unit for the multiplier
    type state_type is (idle, load, op);
    signal state_reg, state_next: state_type;

    -- registers to store the current and next states of the product register in each state
    signal product_reg, product_next: unsigned(2*WIDTH downto 0);

    -- rep check register checks if 64 shifts have occured or not indicating the end of the multiplication hardware algorithm
    signal rep_check_reg, rep_check_next: unsigned (7 downto 0); 
    signal intermediate_multiplicand: unsigned (WIDTH downto 0);
    signal intermediate_product: unsigned (WIDTH downto 0);
    signal intermediate_product_reg: unsigned (2*WIDTH downto 0);
begin
    -- state and product register process block
    process(clk, reset)
    begin
        if (reset = '1') then 
            state_reg <= idle;
            product_reg <= (others => '0');
            rep_check_reg <= (others => '0');
        elsif (clk'event and clk = '1') then 
            state_reg <= state_next;
            product_reg <= product_next;
            rep_check_reg <= rep_check_next;
        end if;
    end process;

    -- next-state combinational logic block
    process(start, state_reg, product_reg, multiplier, multiplicand, rep_check_reg, intermediate_multiplicand, intermediate_product, intermediate_product_reg)
    begin
        -- default values
        state_next <= state_reg;
        product_next <= product_reg;
        rep_check_next <= rep_check_reg;
        intermediate_multiplicand <= (others => '0');
        intermediate_product <= (others => '0');
        intermediate_product_reg <= (others => '0');
        ready <= '0';
        case state_reg is
            when idle =>
                if (start = '1') then 
                    state_next <= load;
                end if;
                ready <= '1';
            when load =>
                product_next <= "00000000000000000000000000000000000000000000000000000000000000000" & unsigned(multiplier);
                rep_check_next <= (others => '0');
                state_next <= op;
            when op =>
                rep_check_next <= rep_check_reg + 1;  
                intermediate_multiplicand <= ('0' & unsigned(multiplicand));
                if (product_reg(0) = '1') then 
                    intermediate_product <= intermediate_multiplicand + product_reg(128 downto 64);
                    intermediate_product_reg <= intermediate_product & product_reg(63 downto 0);
                    product_next <= shift_right(intermediate_product_reg, 1);
                else
                    product_next <= shift_right(product_reg, 1);
                end if;
                if (rep_check_next = to_unsigned(63, 8)) then 
                    state_next <= idle;
                end if;
        end case;
    end process;

    -- output logic
    product <= std_logic_vector (product_reg);
    rep_check <= std_logic_vector (rep_check_reg);
end arch;