#test mpeg2 PS

srcfile=$EXTERNAL_MEDIA_DIR/import/dead_mpg.mpg

test_begin "m2ps-dmx"
if [ $test_skip != 1 ] ; then
insfile=$TEMP_DIR/dump.txt
#inpect demuxed file in non-interleave mode (pid by pid), also dumps PCR
do_test "$GPAC -i $srcfile inspect:interleave=false:deep:pcr:log=$insfile" "inspect"
do_hash_test "$insfile" "inspect"

insfile=$TEMP_DIR/dump_from10.txt
#inpect demuxed file in non-interleave mode (pid by pid), also dumps PCR
do_test "$GPAC -i $srcfile inspect:start=10.0:interleave=false:deep:pcr:log=$insfile" "inspect"
do_hash_test "$insfile" "inspect-10"

fi
test_end

