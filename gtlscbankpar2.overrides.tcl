# ***NOTE***
# Do not modify SVARs in this file. Rather, save SVAR modifications to this file:
# <build>/scripts_build/conf/svar_values.tcl


## -----------------------------------------------------------------------------
##                           Block Override Script
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This script may be used to define block-specific overrides for all
## * Synopsys tool tasks. Typical overrides include tool variables, subtask
## * procedures, and modification of hidden flow-module parameters that are
## * not configurable through the 'Block Variable Editor' GUI.
##
## NOTE:
## * User-configurable flow-module parameters are expected to be modified
## * through the 'Block Variable Editor' interface and NOT in this script.
## * Parameter overrides in this script are reserved for hidden parameters
## * only, must be approved by the corresponding module owner, and are
## * subject to audit review.
## -----------------------------------------------------------------------------


## -----------------------------------------------------------------------------
##                           Tool Variable Overrides
## -----------------------------------------------------------------------------

#--- Sample tool variable override. Remember to use '::' prefix for global scoping.
# set ::toolvar false


## -----------------------------------------------------------------------------
##                       Flow-Module Parameter Overrides
## -----------------------------------------------------------------------------

#--- Sample override of parameter 'enable_stuff' in module 'foo'.
# foo::params enable_stuff 1


## -----------------------------------------------------------------------------
##                              Block Overrides
## -----------------------------------------------------------------------------

#--- Sample block method for subtask 'compile_setup'. Do NOT replace 'block' with the block name.
# proc ::block::compile_setup {} {
#     ...stuff...
#}
#--- Sample block method to be executed before a task execution from flow. Do NOT replace 'block' with the block name.
# proc ::block::compile_setup_pre_task {} {
#     ...stuff...
#}

##Central Project override
source  /p/nvlsd/gcdp192/build/scripts/nvlsd.gcdp192.rls_global_overrides.stcl

##Central XECORE oveeride
source /nfs/site/disks/nvlp_infra_env_01/build/scripts/XECORE_CENTRAL/gtxecore_nvlp_central_overrides_jonTCON.stcl

# Flow was erroring during prects_opt with DFT-FATAL.
dft::params nonscan_check_threshold 100
