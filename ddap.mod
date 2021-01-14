param maxNode, >= 0, integer;

set Nodes=1..maxNode;

set Links;
param link_nodeA { Links }, in Nodes;
param link_nodeZ { Links }, in Nodes;

param link_fibreMax { Links }, >= 0, default 1000; # number of modules c(e)
param link_fibreSignalMax { Links }, >= 0, default 2; # module M
param link_fibreUsageCost { Links }, >= 0, default 1; # module cost ksi(e)


set Demands;
param demand_volume { Demands }, >= 0, default 0; # h(d)

param demand_maxPath { Demands }, >= 0, default 0; # number of available paths for each demand
set Demand_pathLinks { d in Demands, dp in 1..demand_maxPath[d] } within Links; # paths as sets of links


var demandPath_signalCount { d in Demands, 1..demand_maxPath[d]}, >= 0, integer; # flow x_dp

var link_signalCount { Links }, >= 0; # link load l(e,x)
var link_fibreCount { Links }, >= 0, integer; # y(e, x)

var z, integer; # link overload

# new variable /Project
var u_dp { d in Demands, dp in 1..demand_maxPath[d]}, >=0, binary;


subject to demand_satisfaction_constraint_ddap { d in Demands}:
  sum { dp in 1..demand_maxPath[ d] } demandPath_signalCount[ d, dp ] = demand_volume[ d ];
  
subject to link_signalCount_constraint { l in Links }:
  link_signalCount[ l ] = sum { d in Demands, dp in 1..demand_maxPath[ d ]: sum{ k in Demand_pathLinks[ d, dp ]: k = l } 1 > 0 } demandPath_signalCount[ d, dp ];
  	
subject to link_fibreCount_constraint { l in Links }: 
  link_fibreCount[ l ] >= link_signalCount[ l] / link_fibreSignalMax[ l] ;

subject to link_signalCount_constraint2 { l in Links }:
  link_fibreMax[ l ] * link_fibreSignalMax[ l] + z >= sum { d in Demands, dp in 1..demand_maxPath[ d ]: sum{ k in Demand_pathLinks[ d, dp ]: k = l } 1 > 0 } demandPath_signalCount[ d, dp ];
  
# new constraints /Project

subject to single_path_constraint { d in Demands }:
  sum { dp in 1..demand_maxPath[ d ] } u_dp[ d, dp ] = 1;
  
subject to demand_satisfaction_constraint_dap { d in Demands, dp in 1..demand_maxPath[ d] }:
  demandPath_signalCount[ d, dp ] = u_dp [d, dp] * demand_volume[ d ];
  
  # sum demandPath_signalCount missing. Do we need this? /TODO
  
minimize capitalCost:
  sum { l in Links } link_fibreCount[ l ] * link_fibreUsageCost[ l];

problem ddap:
  capitalCost,
  
  demandPath_signalCount, link_signalCount, link_fibreCount,
  demand_satisfaction_constraint_ddap, link_signalCount_constraint, link_fibreCount_constraint
;

 
minimize maxLinkOverload:
  z;

problem dap:
  maxLinkOverload,
   
  demandPath_signalCount, z, 
  
  # new variable /Project
  u_dp,
  
  demand_satisfaction_constraint_dap, link_signalCount_constraint2,
   
   # new constraints
   single_path_constraint
;
