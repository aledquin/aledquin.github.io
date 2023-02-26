#!/depot/tk8.6.1/bin/wish
#################################################################################################
#            Blockage_Intersection
#            #####################
#
# Authors     : Moamen Maged
# Usage       : detects the intersection between blockage and drawing
# Description : Input type
#                - layer1 type1 net1 -> specifies Metal number , itstype and name of net.
#                - #example :layer1 type1 net1 ->  MTOP drawing VDDQ
#                - name of blockage layer.
#                - example : RV / MTOP / RDLVIA
#                - increment so that if we want to detect the space is enough or not.
#                - example : 0 / 1  / 0.05
#                - example for all the input arguments.
#                - example : detect MTOP drawing VDDQ RV 0.5
#################################################################################################

proc utils__script_usage_statistics {toolname version} {
    set prefix "ddr-da-"
    set reporter "/remote/cad-rep/msip/tools/bin/msip_get_usage_info"
    set cmd ""
    set script_dirname [file dirname [file normalize [info script]]]
    append cmd "$reporter --tool_name  \"${prefix}${toolname}\" "
    append cmd "--stage main --category ude_ext_1 "
    append cmd "--tool_path \"$script_dirname\" --tool_version \"$version\""

    exec sh -c $cmd &
}

set script_name [file tail [file rootname [file normalize [info script]]]]
utils__script_usage_statistics $script_name "2022ww20" 

proc detect {layer1 type1 net1 blockage1 increment} {
    
    #get the figure group of error markers and delete it 
    set oaBlock [oa::getTopBlock [ed]]
    set oaFigGroup [oa::FigGroupFind $oaBlock [oa::SimpleName [oa::CdbaNS] udeMarkers]]
    catch {le::delete $oaFigGroup}
    
    #get all the routes & polygons that are named net1 of type ( layer1 type1 ) 
    #example :layer1 type1 net1 ->  MTOP drawing VDDQ
    set IOroutes [de::getFigures -depth 4 -design [ed] -filter {%topNet.name=="$net1" && 
                                                                %LPP.lpp=="$layer1 $type1"}]
    set IOcollection [po::createCollection $IOroutes]
    
    #counting
    puts "Number of $layer1 $type1 named $net1 routes is [db::getCount $IOcollection]"
    
    #expanding the routes by the increment and append it to one collection
    set IOcollection3 [po::expandEdge $IOcollection -by $increment -dir outside -cornerFill true]
    db::foreach oaoashape $IOroutes { 
        po::append  $oaoashape -to $IOcollection3
    }
    
    ########################################################################################################
    
    #get all the shapes of blockage either it was blockage type or drawing type and append it to one group
    set IOroutes4 [de::getFigures -depth 4 -design [ed] -filter {%objType == "Blockage" && %object.layerHeader.layer.name == "$blockage1"}]
    set IOroutes2 [de::getFigures -depth 4 -design [ed] -filter {%LPP.lpp == "$blockage1 blockage"}]
    set IOcollection4 [po::createCollection $IOroutes4]
    db::foreach oashape $IOroutes2 {
        po::append  $oashape -to $IOcollection4
    }
    #counting
    puts "Number of $blockage1 layers is [db::getCount $IOcollection4]"
    #puts "Number of $blockage1 layers is [db::getCount $IOcollection2]"
    
    ##########################################################################################################
    
    #Anding the 2 collections to get intersection
    set available1 [po::and $IOcollection3 -with $IOcollection4]
    #counting
    puts "Number of intersections is [db::getCount $available1]"
    
    ##########################################################################################################
    
    #create a figuregroup oo the top level with  the name udeMarkers contains the error markers highlighting intersection areas
    set figGroup [oa::FigGroupCreate $oaBlock [oa::SimpleName [oa::CdbaNS] udeMarkers]]
    
    db::foreach shape $available1 {
        set oaMarker [le::createPolygon [db::getAttr shape.pointArray] -design [ed] -lpp {marker error}]    
        le::addToFigGroup $oaMarker -to $figGroup
    }
}

#source /remote/cad-rep/msip/tools/Shelltools/ddr-utils/dev/bin/intersection_blockage.tcl
#detect MTOP drawing VDDQ RV 0.05

################################################################################
# No Linting Area
################################################################################

# nolint Main