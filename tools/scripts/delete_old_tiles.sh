cd /home/admin/SSD/tiles
tile_dirs=`find -maxdepth 2 -name "15" -o -name "16" -o  -name "17" -o -name "18" -type d`
for tile_dir in $tile_dirs; do
	echo $tile_dir
	find $tile_dir -type f -mtime +120 -delete | wc -l
# 120 days
done
