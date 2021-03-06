test_begin "dash-srd-hevc"
if [ $test_skip != 1 ] ; then

do_test "$MP4BOX -add $EXTERNAL_MEDIA_DIR/counter/counter_1280_720_I_25_tiled_1mb.hevc:split_tiles -new $TEMP_DIR/file.mp4" "dash-input-preparation"
do_hash_test $TEMP_DIR/file.mp4 "split-tiles"

do_test "$MP4BOX -dash 1000 -profile live $TEMP_DIR/file.mp4 -out $TEMP_DIR/file.mpd" "basic-dash"

do_hash_test $TEMP_DIR/file.mpd "mpd"
do_hash_test $TEMP_DIR/file_set1_init.mp4 "init"
do_hash_test $TEMP_DIR/file_dash_track1_10.m4s "base_tile"
do_hash_test $TEMP_DIR/file_dash_track2_10.m4s "tt1"
do_hash_test $TEMP_DIR/file_dash_track10_10.m4s "tt9"

myinspect=$TEMP_DIR/inspect_tiles.txt
do_test "$GPAC -i $TEMP_DIR/file.mpd inspect:allp:deep:interleave=false:log=$myinspect" "inspect-tiles"
do_hash_test $myinspect "inspect-tiles"

#also do a playback test for coverage
do_test "$MP4CLIENT -blacklist=vtbdec,nvdec $TEMP_DIR/file.mpd#VR -run-for 1" "play-tiles"

myinspect=$TEMP_DIR/inspect_agg.txt
do_test "$GPAC -i $TEMP_DIR/file.mpd tileagg @ inspect:allp:deep:interleave=false:log=$myinspect" "inspect-tileagg"
do_hash_test $myinspect "inspect-agg"

test_end
fi

#same but with 2 input
test_begin "dash-srd-hevc-dual"
if [ $test_skip != 1 ] ; then

do_test "$MP4BOX -add $EXTERNAL_MEDIA_DIR/counter/counter_1280_720_I_25_tiled_1mb.hevc:split_tiles -new $TEMP_DIR/file1.mp4" "dash-input-preparation1"
do_hash_test $TEMP_DIR/file1.mp4 "split-tiles1"
do_test "$MP4BOX -add $EXTERNAL_MEDIA_DIR/counter/counter_1280_720_I_25_tiled_500kb.hevc:split_tiles -new $TEMP_DIR/file2.mp4" "dash-input-preparation2"
do_hash_test $TEMP_DIR/file2.mp4 "split-tiles2"

do_test "$MP4BOX -dash 1000 -profile live $TEMP_DIR/file1.mp4 $TEMP_DIR/file2.mp4 -out $TEMP_DIR/file.mpd" "basic-dash"

do_hash_test $TEMP_DIR/file.mpd "mpd"
do_hash_test $TEMP_DIR/file_set1_init.mp4 "init"
do_hash_test $TEMP_DIR/file1_dash_track1_10.m4s "q1_base_tile"
do_hash_test $TEMP_DIR/file1_dash_track2_10.m4s "q1_tt1"
do_hash_test $TEMP_DIR/file1_dash_track10_10.m4s "q1_tt9"
do_hash_test $TEMP_DIR/file2_dash_track1_10.m4s "q2_base_tile"
do_hash_test $TEMP_DIR/file2_dash_track2_10.m4s "q2_tt1"
do_hash_test $TEMP_DIR/file2_dash_track10_10.m4s "q2_tt9"

myinspect=$TEMP_DIR/inspect_tiles.txt
do_test "$GPAC -i $TEMP_DIR/file.mpd inspect:allp:deep:interleave=false:log=$myinspect" "inspect-tiles"
do_hash_test $myinspect "inspect-tiles"

#also do a playback test for coverage
do_test "$MP4CLIENT -blacklist=vtbdec,nvdec $TEMP_DIR/file.mpd#VR -run-for 1" "play-tiles"

myinspect=$TEMP_DIR/inspect_agg.txt
do_test "$GPAC -i $TEMP_DIR/file.mpd tileagg @ inspect:allp:deep:interleave=false:log=$myinspect" "inspect-tileagg"
do_hash_test $myinspect "inspect-agg"

test_end
fi


