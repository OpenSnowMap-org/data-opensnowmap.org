#~ cat ../all_metatiles_render_0-16.lst | render_list --num-threads=2 -f -m base_snow_map
#~ cat ../all_metatiles_render_0-16.lst | render_list --num-threads=2 -f -m base_snow_map_high_dpi

cat ../all_metatiles_render_0-16.lst | grep " 15" | render_list --num-threads=2 -f -m pistes-high-dpi
cat ../all_metatiles_render_0-16.lst | grep " 15" | render_list --num-threads=2 -f -m pistes
cat ../all_metatiles_render_0-16.lst | grep " 16" | render_list --num-threads=2 -f -m pistes-high-dpi
cat ../all_metatiles_render_0-16.lst | grep " 16" | render_list --num-threads=2 -f -m pistes
cat ../all_metatiles_render_0-16.lst | grep " 17" | render_list --num-threads=2 -f -m pistes-high-dpi
cat ../all_metatiles_render_0-16.lst | grep " 17" | render_list --num-threads=2 -f -m pistes
cat ../all_metatiles_render_0-16.lst | grep " 18" | render_list --num-threads=2 -f -m pistes
