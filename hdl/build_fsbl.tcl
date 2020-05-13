set app_name "fsbl"
set app_type "zynq_fsbl"
set hwspec_file "fft_rtl/design_1_wrapper.xsa"
set proc_name "ps7_cortexa9_0"
set project_name "project"
set project_directory [file dirname [info script]]
set sdk_workspace [file join $project_directory $project_name.sdk]
set app_dir [file join $sdk_workspace $app_name]
set app_release_elf $app_name.elf
set app_release_dir $project_directory
set hw_design [hsi open_hw_design $hwspec_file]
hsi generate_app -hw $hw_design -os standalone -proc $proc_name -app $app_type -compile -sw fsbl -dir $app_dir
file copy -force [file join $app_dir "executable.elf"] [file join $app_release_dir $app_release_elf]
exit
