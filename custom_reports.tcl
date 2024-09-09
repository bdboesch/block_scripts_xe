echo "BDBOESCH-INFO: Sourcing script: [info script]"
proc_time "CR_START"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Globals
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
global scriptDir
global in_gui_session


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Set references for needed scripts.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set violation_summary_script "/nfs/site/disks/home_user/bdboesch/xe_sd/helper_scripts/create_violation_summary"


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Ensure a scenario is specified and switch to that scenario.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if { ![info exists custom_rpt_scenario] } {
   set custom_rpt_scenario "tttt_0p650v_0p650v_100c_tttt_max"
}
set previous_scenario [current_scenario]
current_scenario $custom_rpt_scenario

# Set delay_scalar based on current scenario.
# TODO Need to add more entries when running more scenarios.
switch -glob $custom_rpt_scenario {
   tttt_0p650v_0p650v_100c_tttt_max { set delay_scalar 1.0  }
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Configure the reporting job.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Define slacks, thresholds, and scenarios to report on.
set paths_of_interest_slack_lesser_than "1"
set logical_only_internal_slack_lesser_than [expr 1 * $delay_scalar]
set logical_only_external_slack_lesser_than [expr 1 * $delay_scalar]

# Make dedicated directory for custom reports.
set build_workarea [file normalize $scriptDir/../]
file mkdir "$build_workarea/custom_reports"

# Extract current task and design names.
set task [core::query -task]
set design [core::query -design]

# Create a stage name based off the task.
# Check if running in batch mode.
if {[core::query -is_batch_run]} {
   set stage [lindex [split $task "/"] end]

# Else if running interactively.
} else {
   set stage [lindex [split $task "."] 1]
}

# Keep track of GUI status. Will close GUI at the end if not open already.
set gui_status $in_gui_session

# Make a directory to hold custom_reports.
set custom_reports_dir "$build_workarea/custom_reports/$stage/$custom_rpt_scenario"
file delete -force -- $custom_reports_dir
file mkdir $custom_reports_dir


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Suppress unwanted messages.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set list_of_messages_to_suppress [list "TIM-010" "TIM-999"]
suppress_message $list_of_messages_to_suppress


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Prep the GUI for screenshots.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Launch the GUI, if it is not open already.
if { !$in_gui_session } {
   start_gui -offscreen 1
}

# If stil not in a GUI session, then the off-screen option was not viable. Open GUI normally.
if { !$in_gui_session } {
   start_gui
}

# Reset view.
reset_view


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# If running custom_reports for init_design.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if { $stage == "init_design" } {
   redirect "$custom_reports_dir/report_exceptions.rpt" {report_exceptions}
   redirect "$custom_reports_dir/report_pvt.rpt" {report_pvt}

#   set dump_highlighted_floorplan_image_cmd "dump_highlighted_floorplan_image $size_flag -output_dir $REPORTS_DIR/custom_reports"
#   eval $dump_highlighted_floorplan_image_cmd


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Else for all other stages.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
} else {
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # Prepare the reporting job.
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # Make directories to store images and reports.
   set images_dir                    "$custom_reports_dir/images"
   set logical_only_path_reports_dir "$custom_reports_dir/logical_only_paths"
   set paths_of_interest_dir         "$custom_reports_dir/paths_of_interest"

   # Remove any previous verions of the report directory before creating new reports.
   file mkdir $images_dir
   file mkdir $logical_only_path_reports_dir
   file mkdir $paths_of_interest_dir

   # TODO Ensure custom path-groups are defined.
   #source $SCRIPTS_DIR/custom_path_groups.tcl

   # Run update_timing before reporting.
   update_timing -full
   proc_time "CR_UPDATE_TIME"


   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # Create design-wide QoR reports.
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # Generate report_qor.
   redirect "$custom_reports_dir/report_qor.rpt" { report_qor -pba_mode path -sig 4 -scenarios $custom_rpt_scenario; report_qor -pba_mode path -summary }

   # Generate timing reports for the top-10 worst paths in the design.
   redirect "$custom_reports_dir/top_ten_worst.rpt" { rt_stats -select -sig 3 -max_paths 10 -nets -cross -pba_mode path -scenarios $custom_rpt_scenario }

   # Generate report_global_timing.
   # Extract delay type from scenario name.
   set delay_type [lindex [split $custom_rpt_scenario "_"] end]
   redirect "$custom_reports_dir/report_global_timing.rpt" { report_global_timing -delay_type $delay_type -scenarios $custom_rpt_scenario -pba_mode path }

   # Generate a report_design report.
   redirect "$custom_reports_dir/report_design.rpt" { report_design -nosplit -floorplan -hierarchical -netlist -routing }

   # Generate app-options report.
   redirect "$custom_reports_dir/report_app_options.rpt" { report_app_options }
   #TODO Add code that allows for diffing app-options.
   #ryl_dump_app_options_for_diff -input_rpt "$REPORTS_DIR/$DESIGN_NAME.[rm_current_step].report_app_options.rpt"

   # Generate a printvar report.
   redirect "$custom_reports_dir/printvar.rpt" { printvar }

   # Report transformed registers.
   redirect "$custom_reports_dir/report_transformed_registers.rpt" { report_transformed_registers -summary }
   redirect -append "$custom_reports_dir/report_transformed_registers.rpt" { report_transformed_registers }
   

   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # Create stage-specific reports.
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # If running in route_opt_fc.
   if { [regexp {route_opt_fc} $stage] } {
      # TODO Remove once any code is in place in this block.
      set temp_var 0
      #Generate a hierachy_stats report.
      #TODO Need to port over script from phx_rm.
      #set hierarchy_list [get_object_name [get_cells -quiet ifu/* -filter "is_hierarchical"]]
      #hierarchy_stats -hierarchy_list $hierarchy_list > "$REPORTS_DIR/$DESIGN_NAME.[rm_current_step].hierarchy_stats.rpt"
      #Create a timing_path_stats report which can be used by DDOL.
      #TODO Need to port over script from phx_rm. 
      ##create_ddol_timing_path_stats -scenarios "${ATOM_HV_CORNER}-max" -output_rpt "$REPORTS_DIR/$DESIGN_NAME.[rm_current_step].ddol_timing_path_stats.csv" -slack_lesser_than "-0.015"
   }

   # If running in postcts_opt_fc or route_opt_fc.
   if { [regexp {postcts_opt_fc|route_opt_fc} $stage ] } {
      redirect "$custom_reports_dir/report_clock_balance_points.rpt" { report_clock_balance_points -nosplit }
   }


   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # Generate rt_stats and images for all path-groups.
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~   
   # Add congestion map before highlighting targeted paths.
   gui_show_map -map globalCongestionMap -show true
   
   # Iterate over each path-group, making a path_stats report for each.
   foreach_in_collection path_group [get_path_groups] {
      set path_group_name [get_object_name $path_group]
      
      # Skip over "**default**" path-group. This path-group is a superset of other default path-groups (**in2out_default**, **in2reg_default**, **reg2out_default**, etc...)
      if { [regexp "\\*\\*default\\*\\*" $path_group_name] } {
         continue
      }
      
      # If it's a logical-only path-group (FROM_*, LOCAL_*).
      if { [regexp "^FROM_*|^LOCAL_*" $path_group_name] } {
         set rpt_dir $logical_only_path_reports_dir
         set max_paths 3

         # Set slacks based on whether the path is external or internal.
         if { [regexp "^FROM_input_ports.*|.*TO_output_ports" $path_group_name] } {
            set slack_lesser_than $logical_only_external_slack_lesser_than
         } else {
            set slack_lesser_than $logical_only_internal_slack_lesser_than
         }
      
      # Else if it's a path-of-interest (poi_*) or some other non-standardized path-group name.
      } else {
         set rpt_dir $paths_of_interest_dir
         set max_paths 25         
         set slack_lesser_than $paths_of_interest_slack_lesser_than
      } 
      
      # Dump reports for each threshold.
      if { [sizeof_collection [get_timing_paths -scenarios $custom_rpt_scenario -pba_mode none -groups $path_group_name -slack_lesser_than $slack_lesser_than]] } {
         echo "Info: Dumping rt_stats for path_group: $path_group_name"
         redirect "$rpt_dir/$path_group_name.rpt" {rt_stats -select -sig 3 -max_paths $max_paths -nets -cross -pba_mode path -scenario $custom_rpt_scenario -group $path_group_name}

         # TODO Print out image.
         #set gui_write_window_image_cmd "gui_write_window_image $size_flag -file $images_dir/$path_group_name.png"
         #eval $gui_write_window_image_cmd
         ## Add a wait to prevent potential issues with piping and screenshots.
         #after 500
      }
   }
   proc_time "CR_RT_STATS"


   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # Generate rt_stats and images for worst paths.
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # Worst internal paths.
   set path_name "poi_worst_internal"
   echo "Info: Dumping rt_stats for paths: $path_name"
   redirect "$paths_of_interest_dir/$path_name.rpt" {rt_stats -select -sig 3 -max_paths 3 -nets -cross -pba_mode path -scenarios $custom_rpt_scenario -from [get_flat_pins * -f "port_type != power && port_type != ground && is_clock_pin"] -to [get_flat_pins * -f "port_type != power && port_type != ground && is_data_pin"]}
   # TODO Dump images.
   #set gui_write_window_image_cmd "gui_write_window_image $size_flag -file $images_dir/$path_name.png"
   #eval $gui_write_window_image_cmd

   # Worst external paths.
   set path_name "poi_worst_external"
   echo "Info: Dumping rt_stats for paths: $path_name"
   redirect "$paths_of_interest_dir/$path_name.rpt" {rt_stats -select -sig 3 -max_paths 3 -nets -cross -pba_mode path -scenarios $custom_rpt_scenario -through [get_ports * -f "port_type != power && port_type != ground"]}
   # TODO Dump images.  
   #set gui_write_window_image_cmd "gui_write_window_image $size_flag -file $images_dir/$path_name.png"
   #eval $gui_write_window_image_cmd
   
   proc_time "CR_WORST"  
   

   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # Dump floorplan images.
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   #TODO
   #echo "INFO: Dumping out images."            
   #dump_images
   #proc_time "CR_IMAGES"  


   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~   
   # Generate hierarchical pins reports.
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # TODO
   #echo "INFO: Dumping out hierarchical pin reports."   
   #set paths [filter_collection [get_timing_paths -include_hierarchical_pins -scenarios $custom_rpt_scenario -start_end_pair -slack_lesser_than 0 -pba_mode none] "num_logic_gates>$hierarchical_pin_reports_logic_level_threshold"]
   #ryl_create_hier_pins_rpt -paths $paths -ofile $hier_pin_reports_dir/$DESIGN_NAME.hier_pins.summary.rpt -include_timing_reports -limit $hierarchical_pin_reports_number_of_traces -paths_per_report 3
   #proc_time "CR_HIER_PINS"  


   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # Generate violation summary report.
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   echo "INFO: Dumping out violation summary report."
   set violation_report "$custom_reports_dir/violation_summary.rpt"
   redirect $violation_report {sh $violation_summary_script $custom_rpt_scenario -d $custom_reports_dir}


   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # Run report_status at the very end since needed reports from default 
   # reporting flow should be available at this point.
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # TODO 
   #echo "INFO: Dumping out report_status."
   #sh $report_status_script -c $custom_rpt_scenario -s [rm_current_step] > $custom_reports_dir/$DESIGN_NAME.report_status.rpt
   #proc_time "CR_RPT_STATUS"


   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # Create a touchfile.
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   echo "INFO: Creating touchfile to signify completion."      
   sh touch $custom_reports_dir/custom_reports.touch
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Archive the results. 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TODO 
# Only archieve if the following criteria is met:
#    Running in route_opt.final.
#    Running with my user name.
#    Running on on my disk.
#    Running in primary HV corner.
#if { ([rm_current_step] == "route_opt.final") && ($env(USER) == "bdboesch") && ([regexp "/nfs/site/disks/aadg.bdboesch.1" [pwd]]) && ($custom_rpt_scenario == "${ATOM_HV_CORNER}-max") } {
#   sh $archive_workarea_script "$env(WARD)/.."
#}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Restore GUI settings and scenarios to what they were originally.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Restore GUI settings.
if { !$gui_status } {
   stop_gui
}

# Restore scenario.
current_scenario $previous_scenario


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Restore message supression to what it was before invoking this script. 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
unsuppress_message $list_of_messages_to_suppress

proc_time "CR_END"
