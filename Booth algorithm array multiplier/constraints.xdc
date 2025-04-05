# Clock signal
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]

# Input delays
set_input_delay -clock [get_clocks clk] -max 2.000 [get_ports {a[*]}]
set_input_delay -clock [get_clocks clk] -max 2.000 [get_ports {b[*]}]
set_input_delay -clock [get_clocks clk] -max 2.000 [get_ports {enable}]
set_input_delay -clock [get_clocks clk] -max 2.000 [get_ports {pipeline_en}]
set_input_delay -clock [get_clocks clk] -max 2.000 [get_ports {rst_n}]

# Output delays
set_output_delay -clock [get_clocks clk] -max 2.000 [get_ports {prod[*]}]
set_output_delay -clock [get_clocks clk] -max 2.000 [get_ports {power_saved}]

# False paths
set_false_path -from [get_ports rst_n] -to [all_registers]

# Power optimization
set_power_opt -include_cells [all_registers]
set_power_opt -include_cells [all_combinational]

# Clock gating optimization
set_power_opt -include_clock_gating true 