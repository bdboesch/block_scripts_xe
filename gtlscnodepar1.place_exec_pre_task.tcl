# Execute compute_clock_latency proc prior to postcts optimization to update latency on IO
if { [core::query -is_task *postcts*] } {
   echo "JCSIPPEL-INFO: Executing compute_clock_latency via proc scon::post_cts_latencies ...."
   ::scon::post_cts_latencies
   update_timing
}

