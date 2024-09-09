# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# NOTE
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Do not modify SVARs in this file. Rather, save SVAR modifications to this file:
# <build>/scripts_build/conf/svar_values.tcl
 
# Do not add app-options settings here, as this is sourced before the design is loaded. 
# Instead define a post/pre hook somewhere for a subprocess that is common for most tasks.


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

#Central Project override
source $scriptDir/PROC_TCON.io_at_40.stcl

#Central XECORE oveeride
source $scriptDir/gtxecore_nvlp_central_overrides_jonTCON.stcl

#Recipe
fcsyn::params regbank,user_exclude {
lscnodeunit1/*lscfe_rddata_bankpar_seq_map_reg*
lscnodeunit1/*lscfe_rddata_reg*
lscnodeunit1/u_lscnode_one_frag_arb*/*nopwc_single_frag_rdy_reg*
mbist_gtlscpar_wrap/gtlscpar_rtl_array_tessent_mbist_c*_controller_inst/MBISTPG_CONTROLLER_OUTPUTS_PIPELINE/*EXPECT_DATA_REG_reg*
lscnodeunit1/lsc_node_alloc_infifo_gen[*].u_lscfe_node_alloc_infifo/*lscnode_bank_req_fifo_rdy_reg*
lscnodeunit1/*lscnode_gass_rtn_tag_stg*_reg.tag.xefi_tag*
lscnodeunit1/u_lscnode_rsrc_alloc/*resources_avail_reg*
}

fcsyn::params duplicate_registers_regexp "lscnodeunit1/lscnodeunit_cgdis_xfer/cp_cgdis_pre_dft_reg:num_copies:20"

# Deactivate 1.1v max scenario.
opmanager::params opset,sifunctional_tttt_cmax_1p100v_1p100v_100c_tttt_100c_max,scenario.opt.active 0

# Limit route_auto DR iterations and change GR effort to medium (high is runtime killer).
route::params route_auto_dr_iterations 5
route::params groute_effort medium

# Limit the number of route eco iterations when fixing DRCs. This param set the app-option 
# "route.detail.eco_max_number_of_iterations" during "scripts_process/p1278/modules/route.module".
#route::params eco_snr_loops_default 15
