# Remove any existing MW direotory
exec rm -rf ${top_design}.mw
set lib_dir /pkgs/synopsys/2020/32_28nm/SAED32_EDK/lib
set mwlib_types [list $lib_dir/stdcell_hvt/milkyway \
$lib_dir/stdcell_rvt/milkyway \
$lib_dir/stdcell_lvt/milkyway  \
$lib_dir/io_std/milkyway \
$lib_dir/sram/milkyway $lib_dir/pll/milkyway \
 ]
set sub_mwlib_type "saed32nm_?vt_* SRAM32NM saed32io_wb_* SAED32_PLL_FR*"

#creating milky way physical library linking information
# you will end up with something like this:
# /pkgs/synopsys/2020/32_28nm/SAED32_EDK/lib/stdcell_hvt/milkyway/saed32nm_hvt_1p9m /pkgs/synopsys/2020/32_28nm/SAED32_EDK/lib/stdcell_rvt/milkyway/saed32nm_rvt_1p9m /pkgs/synopsys/2020/32_28nm/SAED32_EDK/lib/stdcell_lvt/milkyway/saed32nm_lvt_1p9m /pkgs/synopsys/2020/32_28nm/SAED32_EDK/lib/sram/milkyway/SRAM32NM
# Sometimes there are two directories of milkyway directories, so try using the first one if there are more than one.  This works for now.
# Example:
#   /pkgs/synopsys/2020/32_28nm/SAED32_EDK/lib/stdcell_hvt/milkyway/saed32nm_hvt_1p9m
#   /            $lib_dir                 /lib/ $lib_type /milkyway/ first_directory_found
set mw_lib ""
foreach i $mwlib_types {
   foreach j $sub_mwlib_type { 
      set mw_lib1 [lindex [glob -nocomplain -type d $i/$j ] 0 ] 
      if { [ llength $mw_lib1 ] > 0 } {
         lappend mw_lib $mw_lib1 
      }
   }
}

# Form the Tech File and TLUplus parasitic information pointers
set tf_dir $lib_dir/../tech/milkyway
set tlu_dir $lib_dir/../tech/star_rcxt/
set_tlu_plus_files  -max_tluplus $tlu_dir/saed32nm_1p9m_Cmax.tluplus  \
                    -min_tluplus $tlu_dir/saed32nm_1p9m_Cmin.tluplus  \
                    -tech2itf_map  $tlu_dir/saed32nm_tf_itf_tluplus.map

# And create the Milkyway library for our design database storage
create_mw_lib ${top_design}.mw -technology $tf_dir/saed32nm_1p9m_mw.tf  -mw_reference_library $mw_lib -open


