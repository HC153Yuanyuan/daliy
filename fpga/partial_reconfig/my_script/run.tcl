###############################################################
####flow control (1 = run step , 0 = skip step)
set run.topSynth       1 ;#synthesize static
set run.rmSynth        1 ;#synthesize RM variants
set run.prImpl         0 ;#implement each static + RM configuration
set run.prVerify       0 ;#verify RMs are compatible with static
set run.writeBitstream 0 ;#generate full and partial bitstreams


###############################################################
###  Run Settings
###############################################################
####Input Directories
set srcDir     "."
set rtlDir     "$srcDir/rtl"
set prjDir     "$srcDir/prj"
set xdcDir     "$srcDir/xdc"
set coreDir    "$srcDir/cores"
set netlistDir "$srcDir/netlist"

set synthDir  "./Synth"
set implDir   "./Implement"
set dcpDir    "./Checkpoint"
set bitDir    "./Bitstreams"



###############################################################
### Static Module Definition
###############################################################
set top "system_top"

###############################################################
### RP & RM Definitions (Repeat for each RP)
### 1. Define Reconfigurable Partition (RP) name
### 2. Associate Reconfigurable Modules (RMs) to the RP
###############################################################
set rp1 "Apb3AES_2"
set rm_variants($rp1) "Apb3AES_2"

set module1_variant1 "aes_1_2"
set rm_config(initial)   "$rp1 $module1_variant1"
#set rm_config(reconfig1)   "$rp1 $module1_variant2"



###############################################################
### Advanced Settings
###############################################################
# Load utilities
#Define location for "Tcl" directory. Defaults to "./tcl_HD"
if {[file exists "./Tcl_HD"]} { 
   set tclDir  "./Tcl_HD"
} else {
   error "ERROR: No valid location found for required Tcl scripts. Set \$tclDir in design.tcl to a valid location."
}
puts "Setting TCL dir to $tclDir"

####Source required Tcl Procs
source $tclDir/design_utils.tcl
source $tclDir/log_utils.tcl
source $tclDir/synth_utils.tcl
source $tclDir/impl_utils.tcl
source $tclDir/hd_utils.tcl
source $tclDir/pr_utils.tcl




###############################################################
### Board Settings
### -Board: default device, package and speed for selected board
###############################################################
set device       "xc7a100t"
set package      "fgg484"
set speed        "-1"

set part         $device$package$speed




check_part $part



###############################################################
###  Run Settings
###############################################################
####Report and DCP controls - values: 0-required min; 1-few extra; 2-all
set verbose      1
set dcpLevel     1

###############################################################
### Static Module Definition
###############################################################
set static "Static"
add_module $static
set_attribute module $static moduleName    $top
set_attribute module $static top_level     1
set_attribute module $static vlog          [list [glob $rtlDir/*.v]]
set_attribute module $static synth         1 





####################################################################
### RP Module Definitions
####################################################################
foreach rp [array names rm_variants] {
  foreach rm $rm_variants($rp) {
    set variant $rm
    add_module $variant
    set_attribute module $variant moduleName   $rp
    set_attribute module $variant vlog         [list [glob $rtlDir/submodule/*.v]]
    set_attribute module $variant synth        1 
  }
}

########################################################################
### Configuration (Implementation) Definition 
########################################################################
foreach cfg_name [array names rm_config] {
  if {$cfg_name=="initial"} {set state "implement"} else {set state "import"}
    
  set config "Config"
  set partition_list [list [list $static $top $state]]

  foreach {rp rm_variant} $rm_config($cfg_name) {
    set module_inst inst_${rp}
    set config "${config}_${rm_variant}"
    set partition [list $rm_variant $module_inst implement]
    lappend partition_list $partition
  }
 set config "${config}_${state}"
  
  add_implementation $config
  set_attribute impl $config top             $top
  set_attribute impl $config implXDC         [list $xdcDir/*.xdc]

  set_attribute impl $config partitions      $partition_list
  set_attribute impl $config pr.impl         1 
  set_attribute impl $config impl            ${run.prImpl} 
  set_attribute impl $config verify     	    ${run.prVerify} 
  set_attribute impl $config bitstream  	    ${run.writeBitstream} 
}


source $tclDir/run.tcl


