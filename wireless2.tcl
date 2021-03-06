# ======================================================================
set val(chan)           Channel/WirelessChannel    ;# channel type
set val(prop)           Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)          Phy/WirelessPhy            ;# network interface type
set val(mac)            Mac/802_11                 ;# MAC type
set val(ifq)            Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# antenna model
set val(ifqlen)         50                         ;# max packet in ifq
set val(nn)             6                          ;# number of mobilenodes
set val(rp)             DSDV                       ;# routing protocol

# ======================================================================
# Main Program
# ======================================================================


#
# Initialize Global Variables
#
set ns_		[new Simulator]
set tracefd     [open project2.tr w]
$ns_ trace-all $tracefd

# set up topography object
set topo       [new Topography]

$topo load_flatgrid 500 500

# Create God
create-god $val(nn)

# configure node
$ns_ node-config -adhocRouting $val(rp) \
		 -llType $val(ll) \
		 -macType $val(mac) \
		 -ifqType $val(ifq) \
		 -ifqLen $val(ifqlen) \
		 -antType $val(ant) \
		 -propType $val(prop) \
		 -phyType $val(netif) \
		 -channelType $val(chan) \
		 -topoInstance $topo \
		 -agentTrace ON \
		 -routerTrace ON \
		 -macTrace ON \
		 -movementTrace ON			
			 
for {set i 0} {$i < $val(nn) } {incr i} {
	set node_($i) [$ns_ node]	
	$node_($i) random-motion 0		;# disable random motion
}

# Provide initial (X,Y, Z=0) co-ordinates for mobilenodes
# We put odd numbered nodes on left and even numbered nodes on right
# Nodes are placed 100 away from each other verticaly

# I tried to use a for loop to set this up, but I was not obtaining the correct topology
#set inc_dist 100
#for {set i 0} {$i <= 2} {incr i} {
#	$node_($i) set X_ 10.0
#	$node_($i) set Y_ 50.0 + $i*$inc_dist
#	$node_($i) set Z_ 0.0
#	$node_([expr $i + 1]) set X_ 490.0
#	$node_([expr $i + 1]) set Y_ 50.0 + $i*$inc_dist
#	$node_([expr $i + 1]) set Z_ 0.0
#}

$node_(0) set X_ 10.0 
$node_(0) set Y_ 50.0 
$node_(1) set X_ 490.0
$node_(1) set Y_ 50.0 

$node_(2) set X_ 10.0 
$node_(2) set Y_ 150.0 
$node_(3) set X_ 490.0
$node_(3) set Y_ 150.0 

$node_(4) set X_ 10.0 
$node_(4) set Y_ 250.0 
$node_(5) set X_ 490.0
$node_(5) set Y_ 250.0 



# Node Movements
# Odd Nodes move toward left all with same speed
# Even nodes move toward right with varying speeds
$ns_ at 50.0 "$node_(1) setdest 25.0 50.0 15.0"
$ns_ at 60.0 "$node_(0) setdest 490.0 50.0 3.0"

$ns_ at 50.0 "$node_(3) setdest 25.0 150.0 15.0"
$ns_ at 60.0 "$node_(2) setdest 490.0 150.0 9.0"

$ns_ at 50.0 "$node_(5) setdest 25.0 250.0 15.0"
$ns_ at 60.0 "$node_(4) setdest 490.0 250.0 15.0"


# Setup traffic flow between nodes
# TCP connections between node_(0) and node_(1)

set tcp [new Agent/TCP]
$tcp set class_ 2
set sink [new Agent/TCPSink]
$ns_ attach-agent $node_(0) $tcp
$ns_ attach-agent $node_(1) $sink
$ns_ connect $tcp $sink
set ftp [new Application/FTP]
$ftp attach-agent $tcp

# Setup traffic flow between nodes
# TCP connections between node_(2) and node_(3)

set tcp1 [new Agent/TCP]
$tcp1 set class_ 2
set sink1 [new Agent/TCPSink]
$ns_ attach-agent $node_(2) $tcp1
$ns_ attach-agent $node_(3) $sink1
$ns_ connect $tcp1 $sink1
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1

# Setup traffic flow between nodes
# TCP connections between node_(4) and node_(5)

set tcp2 [new Agent/TCP]
$tcp2 set class_ 2
set sink2 [new Agent/TCPSink]
$ns_ attach-agent $node_(4) $tcp2
$ns_ attach-agent $node_(5) $sink2
$ns_ connect $tcp2 $sink2
set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2

#File Transfer protocol at application layer
$ns_ at 10.0 "$ftp start" 

$ns_ at 10.0 "$ftp1 start" 

$ns_ at 10.0 "$ftp2 start" 

#
# Tell nodes when the simulation ends
#
for {set i 0} {$i < $val(nn) } {incr i} {
    $ns_ at 150.0 "$node_($i) reset";
}
$ns_ at 150.0 "stop"
$ns_ at 150.01 "puts \"NS EXITING...\" ; $ns_ halt"
proc stop {} {
    global ns_ tracefd
    $ns_ flush-trace
    exec awk -f throughput_v4.awk project2.tr
    close $tracefd
}

puts "Starting Simulation..."
$ns_ run

