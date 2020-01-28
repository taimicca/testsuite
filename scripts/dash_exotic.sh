#!/bin/sh


dash_exotic_test()
{

test_begin "dash_exotic_$1"

if [ $test_skip  = 1 ] ; then
 return
fi

do_test "$MP4BOX -dash 1000 -out $TEMP_DIR/test.mpd $2" "dash"

do_hash_test $TEMP_DIR/test.mpd "mpd"

if [ $3  = 1 ] ; then
myinspect=$TEMP_DIR/inspect.txt
do_test "$GPAC -i $TEMP_DIR/test.mpd inspect:allp:deep:interleave=false:log=$myinspect"
do_hash_test $myinspect "inspect"
fi

test_end

}

src=$MEDIA_DIR/auxiliary_files/counter.hvc
src2=$MEDIA_DIR/auxiliary_files/count_english.mp3

#using raw bitstream output format in live profile
dash_exotic_test "raw-live" "$src -profile live --muxtype=raw" 1
#using raw bitstream output format in onDemand profile
dash_exotic_test "raw-ondemand" "$src -profile onDemand --muxtype=raw" 1
#using raw bitstream output format in main profile, file list
dash_exotic_test "raw-main-files" "$src -profile main --muxtype=raw" 1
#using raw bitstream output format in main profile, single file list
dash_exotic_test "raw-main-byteranges" "$src -profile main --muxtype=raw --sfile" 1

#using raw bitstream output format with 2 inputs forcing same rep for mux output, result must be unmuxed
dash_exotic_test "raw-nomux" "$src:id=1 $src2:id=1 -profile onDemand --muxtype=raw" 1

#using ISOBMFF output format in live profile with custom extensions
dash_exotic_test "raw-isobmf-mime" "$src -profile live --segext=raw --initext=raw --muxtype=mp4" 1

#using MKV output format in live profile, detected from extension - no support for demux of mkv+dash yet
dash_exotic_test "mkv-live" "$src -profile live --initext=mkv" 0

#using MKV output format in main profile, using explicit mux type and custom extensions  - no support for demux of mkv+dash yet
dash_exotic_test "mkv-main" "$src -profile main --sfile --initext=raw --segext=raw --muxtype=mkv" 0