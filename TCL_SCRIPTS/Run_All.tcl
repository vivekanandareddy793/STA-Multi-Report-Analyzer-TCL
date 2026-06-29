# Display project title
puts "====================================================================================="
puts "                            STA TIMING REPORT ANALYSER                               "

# Create the master summary CSV file
set out1 [open "SUMMARIES/MASTER_SUMMARY.csv" w]

# Write the header for the master summary file
puts $out1 "Report Name,Module,Analysis,scenario,Best Slack(ns),WNS(ns),TNS(ns),TotalPaths,ViolatedPaths,HoldViolations,SetupViolations,ReportStatus \n"

# Close the file
close $out1


# Ask the user to enter the slack value
puts "ENTER SLACK TO CHECK:"
gets stdin SLACK

# Create the violation summary CSV file
set out2 [open "SUMMARIES/VIOLATION_SUMMARY.csv" w]

# Display the entered slack value
puts "GIVEN SLACK TO CHECK: $SLACK"

# Write the header for the violation summary file
puts $out2 "REPORT NAME,START POINT,END POINT,SLACK(ns)\n"

# Close the file
close $out2


# Process all timing report files
foreach rpt [glob TIMINGREPORTS/*.rpt] {

    # Display the current report name
    puts "Running  $rpt"

    # Call the report parser and pass report name and slack value
    puts [exec tclsh TCL_SCRIPTS/report_parser.tcl $rpt $SLACK]

    # Display completion message for the report
    puts "$rpt Completed\n"
}


# List to store all paths from every report
set AllPaths {}

# Read every generated CSV file
foreach csv [glob OUTPUT_REPORTS/*.csv] {

    # Open the CSV file
    set fp [open "$csv" r]

    # Variable to skip the header line
    set head 1

    # Read the file line by line
    while {[gets $fp line] >= 0} {

         # Skip the first line (header)
         if {$head} {
              set head 0
              continue
         }

         # Stop reading when violation details section starts
         if {[string match "*VIOLATED PATH DETAILS*" $line]} {
              break
         }

         # Split the CSV line into fields
         set seperate [split $line ","]

         # Get the report name from the CSV file name
         set rptname [file rootname [file tail $csv]]

         # Store report name, start point, end point and slack
         lappend AllPaths [list ${rptname}.rpt [lindex $seperate 0] [lindex $seperate 1] [lindex $seperate 2]]
    }

    # Close the CSV file
    close $fp
}

# Sort all paths based on slack (lowest slack first)
set SortedPaths [lsort -index 3 -real -increasing $AllPaths]

# Create the Top 5 Worst Paths CSV file
set out4 [open "SUMMARIES/TOP_5_WORST_PATHS.csv" w]

# Write the header
puts $out4 "S.No,Report Name,Start Point,End Point,Slack(ns)\n"

# Write the top 5 worst paths
for {set i 1} {$i <= 5} {incr i} {

       # Get one path from the sorted list
       set path [lindex $SortedPaths [expr $i-1]]

       # Write the path details to the CSV file
       puts $out4 "$i,[lindex $path 0],[lindex $path 1],[lindex $path 2],[lindex $path 3]"
}

# Close the file
close $out4


# Display completion messages
puts "ALL Timing Reports Parsed Successfully"
puts "CSV Files Generated Successfully"
puts "====================================================================================="