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

##Recipe
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
