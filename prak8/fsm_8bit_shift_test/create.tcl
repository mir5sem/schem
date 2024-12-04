cd [file dirname [info script]]
create_project fsm_8bit_shift_project fsm_8bit_shift_project -part xc7a100tcsg324-1
import_files -norecurse fsm_8bit_shift.v
update_compile_order -fileset sources_1
file mkdir fsm_8bit_shift_project/fsm_8bit_shift_project.srcs/constrs_1
add_files -fileset constrs_1 -norecurse ccs.xdc
import_files -fileset constrs_1 ccs.xdc
launch_runs impl_1 -to_step write_bitstream -jobs 16