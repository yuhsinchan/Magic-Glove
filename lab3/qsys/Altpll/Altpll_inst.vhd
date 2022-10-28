	component Altpll is
		port (
			reset_reset_n : in std_logic := 'X'; -- reset_n
			clk_clk       : in std_logic := 'X'  -- clk
		);
	end component Altpll;

	u0 : component Altpll
		port map (
			reset_reset_n => CONNECTED_TO_reset_reset_n, -- reset.reset_n
			clk_clk       => CONNECTED_TO_clk_clk        --   clk.clk
		);

