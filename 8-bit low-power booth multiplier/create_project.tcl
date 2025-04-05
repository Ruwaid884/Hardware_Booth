# Create project
create_project low_power_multiplier ./vivado_project -part xc7a100tcsg324-1

# Add source files
add_files -norecurse multiplier.v

# Set top module
set_property top low_power_booth_multiplier [current_fileset]

# Create simulation fileset
create_fileset -simset sim_1
add_files -fileset sim_1 -norecurse multiplier.v

# Set simulation top
set_property top tb_low_power_booth_multiplier [get_filesets sim_1]

# Set power optimization settings
set_property STEPS.POWER_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.POWER_OPT_DESIGN.TCL.PRE {} [get_runs impl_1]
set_property STEPS.POWER_OPT_DESIGN.TCL.POST {} [get_runs impl_1]

# Set implementation strategy
set_property strategy Performance_Explore [get_runs impl_1]

# Set power optimization directives
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]

# Enable power optimization
set_property STEPS.POWER_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]

# Save project
save_project_as -force low_power_multiplier 