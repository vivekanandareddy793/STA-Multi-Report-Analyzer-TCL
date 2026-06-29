# Get report file from command line
set filename [lindex $argv 0]
set SLACK [lindex $argv 1]
# Open the timing report
set fp [open "$filename" r]

# Get report name without extension
set rptname [file rootname [file tail $filename]]

# Run this section for all reports except processor
if {![string match "processor_setup" $rptname]} {

# Variables to store report details
set startpoints {}
set endpoints {}
set slacks {}
set PathStatus {}
set Pathtypes {}
set data_arrival {}
set data_required {}
set scenario {}
set AnalysisType {}

# Variables used for report summary
set met 0
set violated 0
set WNS 0
set TNS 0
set BestSlack 0
set ReportStatus {}
set c 0

# Read report line by line
while {[gets $fp line] >= 0} {

    # Get startpoint
    if {[regexp {Startpoint\s*:\s*(.*)} $line match start]} {
        puts "startpoint    : $start"
        lappend startpoints $start
    }

    # Get endpoint
    if {[regexp {Endpoint\s*:\s*(.*)} $line match end]} {
        puts "endpoint      : $end"
        lappend endpoints $end
    }

    # Get scenario
    if {[regexp {Scenario\s*:\s*(.*)} $line match type]} {
        puts "scenario      : $type"
        lappend scenario $type
    }

    # Get analysis type
    if {[regexp {Analysis Type\s*:\s*(.*)} $line match type]} {
        puts "Analysis Type : $type"
        lappend AnalysisType $type
    }

    # Get path type
    if {[regexp {Path Type\s*:\s*(.*)} $line match type]} {
        puts "PathType      : $type"
        lappend Pathtypes $type
    }

    # Get slack and check path status
    if {[regexp {Slack\s*\(.*\)\s*(-?[0-9.]*)} $line match slack]} {
        lappend slacks $slack

        if {$slack < 0} {
            puts "SLACK         :$slack     violated \n"
            lappend PathStatus "violated"
        } else {
            puts "SLACK         :$slack     not violated \n"
            lappend PathStatus "MET"
        }
    }

    # Get data arrival time
    if {[regexp {Data Arrival Time \s*(-?[0-9.]*)} $line match arrival]} {
        puts "Data Arrival Time  : $arrival"
        lappend data_arrival $arrival
    }

    # Get data required time
    if {[regexp {Data Required Time \s*(-?[0-9.]*)} $line match required]} {
        puts "Data Required Time : $required"
        lappend data_required $required
    }
}

# Display extracted values
puts "Startpoints        :$startpoints \n"
puts "Endpoints          :$endpoints \n"
puts "Slacks             :$slacks \n"
puts "Path Status        :$PathStatus \n"
puts "Path type          :$Pathtypes \n"
puts "Scenario           :$scenario \n"
puts "Data Arrival Time  :$data_arrival \n"
puts "Data Required Time :$data_required \n"
puts "Analysis Type      :$AnalysisType \n"

# Create output CSV
set out [open "OUTPUT_REPORTS/${rptname}.csv" w]

# Write all paths into CSV
puts $out "STARTPOINT,ENDPOINT,SLACKS(ns),PATHTYPE,PATHSTATUS,Arrival(ns),Required(ns)"

for {set i 0} {$i< [llength $startpoints]} {incr i} {
    puts $out "[lindex $startpoints $i],[lindex $endpoints $i],[lindex $slacks $i],[lindex $Pathtypes $i],[lindex $PathStatus $i],[lindex $data_arrival $i],[lindex $data_required $i]"
}
# Write violated paths
puts $out "                      VIOLATED PATH DETAILS         "

for {set i 0} {$i< [llength $startpoints]} {incr i} {
    if {[lindex $slacks $i] < 0} {
        puts $out "[lindex $startpoints $i],[lindex $endpoints $i],[lindex $slacks $i],[lindex $Pathtypes $i],[lindex $PathStatus $i],[lindex $data_arrival $i],[lindex $data_required $i]"
    }
}

# Count violated and met paths
for {set i 0} {$i < [llength $startpoints]} {incr i} {
    if {[lindex $slacks $i] < 0} {
        incr violated
    } else {
        incr met
    }
}

# Calculate WNS and TNS
for {set i 0} {$i < [llength $startpoints]} {incr i} {

    # Find worst negative slack
    if {$WNS > [lindex $slacks $i]} {
        set WNS [lindex $slacks $i]
    }

    # Add all negative slacks for TNS
    if {[lindex $slacks $i] < 0} {
        set TNS [expr [lindex $slacks $i] + $TNS]
    }
}

# Find best positive slack
for {set i 0} {$i < [llength $startpoints]} {incr i} {
    if {([lindex $slacks $i] > 0) && ([lindex $slacks $i] > $BestSlack)} {
        set BestSlack [lindex $slacks $i]
    }
}

# Set overall report status
if {$violated > 0} {
    set ReportStatus "Fail"
} else {
    set ReportStatus "Pass"
}

# Print critical path details
for {set i 0} {$i < [llength $startpoints]} {incr i} {
    if {[lindex $slacks $i] == $WNS} {

        puts $out "           CRITICAL PATH DETAILS"
        puts $out "critical start point : [lindex $startpoints $i]"
        puts $out "critical end point   : [lindex $endpoints $i]"
        puts $out "critical slack       : $WNS"
        puts $out "Arrival Time         : [lindex $data_arrival $i]"
        puts $out "Required Time        : [lindex $data_required $i]\n"
    }
}


# Print critical path details
for {set i 0} {$i < [llength $startpoints]} {incr i} {
    if {[lindex $slacks $i] < $SLACK} {
        set out2 [open "SUMMARIES/VIOLATION_SUMMARY.csv" a] 
        puts $out2  " ${rptname}.rpt ,[lindex $startpoints $i],[lindex $endpoints $i],[lindex $slacks $i]\n"     
        close $out2
        }
}
# Print report summary
puts $out "Analysis             : [lindex $AnalysisType 0]"
puts $out "Total paths          : [llength $startpoints ]"
puts $out "Total Violated Paths : $violated"
puts $out "Total MET Paths      : $met"
puts $out "WNS                  : $WNS"
puts $out "TNS                  : $TNS"
puts $out "Path Status          : [lindex $PathStatus 0]"
puts $out "Report Status        : [lindex $ReportStatus 0]"
puts $out "Best Slack           : $BestSlack"
puts $out "Arrival Time         : [lindex $data_arrival 0]"
puts $out "Required Time        : [lindex $data_required 0]"

# Update master summary
set out1 [open "SUMMARIES/MASTER_SUMMARY.csv" a]

puts $out1 "${rptname}.rpt,${rptname},[lindex $AnalysisType 0],[lindex $scenario 0],$BestSlack,$WNS,$TNS,[llength $startpoints],$violated,$c,$violated,[lindex $ReportStatus 0]"

# Close all files
close $out1
close $out
close $fp




} else {


    

# Processor report
# Variables to store extracted values
set startpoints {}
set endpoints {}
set slacks {}
set PathStatus {}
set ReportStatus {}
set Pathtypes {}
set data_arrival {}
set data_required {}
set AnalysisType {}
set scenario {}

# Summary variables
set met 0
set violated 0
set BestSlack 0
set WNS 0
set TNS 0
set TotalPaths 0
set ViolatedPaths 0

# Read processor report line by line
while {[gets $fp line] >= 0} {

    # Get startpoint
    if {[regexp {Startpoint\s*:\s*(.*)} $line match start]} {
        puts "startpoint    : $start"
        lappend startpoints $start
    }

    # Get endpoint
    if {[regexp {Endpoint\s*:\s*(.*)} $line match end]} {
        puts "endpoint      : $end"
        lappend endpoints $end
    }

    # Get scenario
    if {[regexp {Scenario\s*:\s*(.*)} $line match type]} {
        puts "scenario      : $type"
        lappend scenario $type
    }

    # Get analysis type
    if {[regexp {Analysis Type\s*:\s*(.*)} $line match type]} {
        puts "Analysis Type : $type"
        lappend AnalysisType $type
    }

    # Get path type
    if {[regexp {Path Type\s*:\s*(.*)} $line match type]} {
        puts "PathType      : $type"
        lappend Pathtypes $type
    }

    # Get slack and path status
    if {[regexp {Slack\s*\(.*\)\s*(-?[0-9.]*)} $line match slack]} {
        lappend slacks $slack

        if {$slack < 0} {
            puts "SLACK         :$slack     violated \n"
            lappend PathStatus "violated"
        } else {
            puts "SLACK         :$slack     not violated \n"
            lappend PathStatus "MET"
        }
    }

    # Get arrival time
    if {[regexp {Data Arrival Time\s+(-?[0-9.]+)} $line match arrival]} {
        puts "Data Arrival Time  : $arrival"
        lappend data_arrival $arrival
    }

    # Get required time
    if {[regexp {Data Required Time\s+(-?[0-9.]+)} $line match required]} {
        puts "Data Required Time : $required"
        lappend data_required $required
    }

    # Get WNS
    if {[regexp {Worst Negative Slack \(WNS\)\s*:\s*(-?[0-9.]+)} $line match wns]} {
        puts "WNS : $wns"
        set WNS $wns
    }

    # Get TNS
    if {[regexp {Total Negative Slack \(TNS\)\s*:\s*(-?[0-9.]+)} $line match tns]} {
        puts "TNS : $tns"
        set TNS $tns
    }

    # Get total analyzed paths
    if {[regexp {Total Paths Analyzed\s*:\s*([0-9]+)} $line match total_paths]} {
        puts "Total Paths : $total_paths"
        set TotalPaths [expr {int($total_paths)}]
    }

    # Get total violated paths
    if {[regexp {Number of Violating Paths\s*:\s*([0-9]+)} $line match violated_paths]} {
        puts "Violated Paths : $violated_paths"
        set ViolatedPaths [expr {int($violated_paths)}]
    }
}

# Display extracted values
puts "Startpoints        :$startpoints \n"
puts "Endpoints          :$endpoints \n"
puts "Slacks             :$slacks \n"
puts "Path Status        :$PathStatus \n"
puts "Path type          :$Pathtypes \n"
puts "Scenario           :$scenario \n"
puts "Data Arrival Time  :$data_arrival \n"
puts "Data Required Time :$data_required \n"
puts "Analysis Type      :$AnalysisType \n"

# Create processor output CSV
set out [open "OUTPUT_REPORTS/$rptname.csv" w]

# Write all path details
puts $out "STARTPOINT,ENDPOINT,SLACKS,PATHTYPE,PATHSTATUS,Arrival,Required"

for {set i 0} {$i < [llength $startpoints]} {incr i} {
    puts $out "[lindex $startpoints $i],[lindex $endpoints $i],[lindex $slacks $i],[lindex $Pathtypes $i],[lindex $PathStatus $i],[lindex $data_arrival $i],[lindex $data_required $i]"
}

# Print violated paths
puts $out "                  VIOLATED PATH DETAILS"

for {set i 0} {$i < [llength $startpoints]} {incr i} {
    if {[lindex $slacks $i] < 0} {
        puts $out "[lindex $startpoints $i],[lindex $endpoints $i],[lindex $slacks $i],[lindex $Pathtypes $i],[lindex $PathStatus $i],[lindex $data_arrival $i],[lindex $data_required $i]"
    }
}

# Count met and violated paths
for {set i 0} {$i < [llength $startpoints]} {incr i} {
    if {[lindex $slacks $i] < 0} {
        incr violated
    } else {
        incr met
    }
}

# Find best positive slack
for {set i 0} {$i < [llength $startpoints]} {incr i} {
    if {([lindex $slacks $i] > 0) && ([lindex $slacks $i] > $BestSlack)} {
        set BestSlack [lindex $slacks $i]
    }
}

# Set report status
if {$violated > 0} {
    set ReportStatus "Fail"
} else {
    set ReportStatus "Pass"
}

# Print critical path
puts $out "CRITICAL PATH DETAILS"

for {set i 0} {$i < [llength $startpoints]} {incr i} {
    if {[lindex $slacks $i] == $WNS} {
        puts $out "critical start point       : [lindex $startpoints $i]"
        puts $out "critical end point         : [lindex $endpoints $i]"
        puts $out "critical slack             : $WNS"
        puts $out "Arrival Time               : [lindex $data_arrival $i]"
        puts $out "Required Time              : [lindex $data_required $i]\n"
    }
}

# Print processor summary
puts $out "SUMMARY"
puts $out "Analysis                         : [lindex $AnalysisType 0]"
puts $out "Total MET Paths                  : $met"
puts $out "WNS                              : $WNS"
puts $out "TNS                              : $TNS"
puts $out "Total Paths (from report)        : $TotalPaths"
puts $out "Violated Paths (from report)     : $ViolatedPaths"
puts $out "Path Status                      : [lindex $PathStatus 0]"
puts $out "Report Status                    : $ReportStatus"
puts $out "Best Slack                       : $BestSlack"

# Update master summary
set out1 [open "SUMMARIES/MASTER_SUMMARY.csv" a]

puts $out1 "${rptname}.rpt,${rptname},[lindex $AnalysisType 0],[lindex $scenario 0],$BestSlack,$WNS,$TNS,$TotalPaths,$ViolatedPaths,0,$ViolatedPaths,$ReportStatus"

# Close all files
close $out
close $out1
close $fp

}