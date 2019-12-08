m="/home/admin/src/meta2tile/./meta2tile"

$m --verbose --bbox -5,42,8,51.5 --mbtiles /home/admin/Planet/tools/meta2tile_links/ /var/tmp/france_pistes_only.mbt

mv /var/tmp/france_pistes_only.mbt /home/admin/downloadable/france_pistes_only.mbt

$m --verbose --mbtiles /home/admin/Planet/tools/meta2tile_links/ /var/tmp/world_pistes_only.mbt

mv /var/tmp/world_pistes_only.mbt /home/admin/downloadable/world_pistes_only.mbt
