#!/bin/sh

#note: the port used is 8080 since the testbot on linux will not allow 80

#increase run time for tests on VM
HTTP_SERVER_RUNFOR=6000

test_http_server()
{
test_begin "http-server"
if [ $test_skip = 1 ] ; then
 return
fi

do_test "$GPAC httpout:port=8080:quit:reqlog:rdirs=$MEDIA_DIR" "http-server" &
sleep .1

myinspect=$TEMP_DIR/inspect.txt
do_test "$GPAC -i http://localhost:8080/auxiliary_files/enst_audio.aac inspect:allp:deep:test=network:interleave=false:log=$myinspect$3 -graph -stats" "client-inspect"
do_hash_test $myinspect "inspect"
test_end

}


test_http_server_dlist()
{
test_begin "http-server-dlist"
if [ $test_skip = 1 ] ; then
 return
fi

touch $TEMP_DIR/file.txt
mkdir $TEMP_DIR/mydir
touch $TEMP_DIR/mydir/other.txt

do_test "$GPAC httpout:port=8080:quit:dlist:rdirs=$TEMP_DIR" "http-server-dlist" &
sleep .1

do_test "$MP4BOX -wget http://localhost:8080/ $TEMP_DIR/listing.txt" "mp4box-get"
found=`grep file.txt $TEMP_DIR/listing.txt`
if [ "$found" = "" ] ; then
	result="listing failed"
fi
found=`grep mydir $TEMP_DIR/listing.txt`
if [ "$found" = "" ] ; then
	result="listing failed"
fi

do_test "$GPAC httpout:port=8080:quit:dlist:rdirs=$TEMP_DIR" "http-server-dlist" &
sleep .1

do_test "$MP4BOX -wget http://localhost:8080/mydir/ $TEMP_DIR/listing2.txt" "mp4box-get2"
found=`grep other.txt $TEMP_DIR/listing2.txt`
if [ "$found" = "" ] ; then
	result="listing2 failed"
fi

test_end
}


test_http_server_sink()
{
test_begin "http-server-sink"
if [ $test_skip = 1 ] ; then
 return
fi

do_test "$GPAC -i $MEDIA_DIR/auxiliary_files/enst_audio.aac -o http://localhost:8080/live.aac:gpac:hold" "http-sink" &
sleep .1

myinspect=$TEMP_DIR/inspect.txt
do_test "$GPAC -i http://localhost:8080/live.aac inspect:allp:deep:test=network:interleave=false:log=$myinspect$3 -logs=http@debug" "client-inspect"
do_hash_test $myinspect "inspect"

test_end
}




test_http_push()
{
test_begin "http-push"
if [ $test_skip = 1 ] ; then
 return
fi

do_test "$GPAC httpout:port=8080:quit:wdir=$TEMP_DIR" "http-server-rec" &
sleep .1

do_test "$GPAC -i $MEDIA_DIR/auxiliary_files/enst_audio.aac -o http://localhost:8080/mydir/test.aac:gpac:hmode=push" "http-push"

wait

$DIFF $MEDIA_DIR/auxiliary_files/enst_audio.aac $TEMP_DIR/mydir/test.aac > /dev/null
rv=$?
if [ $rv != 0 ] ; then
  result="source and copied files differ"
fi

test_end
}

test_http_source()
{
test_begin "http-source"
if [ $test_skip = 1 ] ; then
 return
fi

do_test "$GPAC httpout:port=8080:quit:hmode=source -o $TEMP_DIR/mydir/test.aac" "http-source" &
sleep .1

do_test "$GPAC -i $MEDIA_DIR/auxiliary_files/enst_audio.aac -o http://localhost:8080/test.aac:gpac:hmode=push" "http-push"

wait

$DIFF $MEDIA_DIR/auxiliary_files/enst_audio.aac $TEMP_DIR/mydir/test.aac > /dev/null
rv=$?
if [ $rv != 0 ] ; then
  result="source and copied files differ"
fi

test_end
}

test_http_origin()
{
test_begin "http-origin"
if [ $test_skip = 1 ] ; then
 return
fi
#make a 3sec input
$MP4BOX -add $MEDIA_DIR/auxiliary_files/enst_audio.aac:dur=3.4 -new $TEMP_DIR/source.mp4 2> /dev/null
do_test "$GPAC -i $TEMP_DIR/source.mp4 reframer:rt=on @ -o http://localhost:8080/live.mpd:gpac:rdirs=$TEMP_DIR --sutc --cdur=0.1 --asto=0.9 --dmode=dynamic -logs=http@debug -lu" "http-origin" &
sleep 0.01

#inspect the first segment we get
myinspect=$TEMP_DIR/inspect.txt
do_test "$GPAC -i http://localhost:8080/live.mpd inspect:dur=1:allp:deep:test=network:interleave=false:log=$myinspect -logs=dash:http@debug -lu" "dash-read"

#we don't run the hash on windows, the VM is just too slow to launch the processes and we end up missing one segment ...
if [ $GPAC_OSTYPE != "win32" ] && [ $GPAC_OSTYPE != "win64" ] ; then
do_hash_test $myinspect "inspect"
fi

test_end
}


test_http_dashraw()
{
test_begin "http-dashraw"
if [ $test_skip = 1 ] ; then
 return
fi

do_test "$GPAC -i $MEDIA_DIR/auxiliary_files/enst_audio.aac -o http://localhost:8080/file1.mpd:gpac:rdirs=$TEMP_DIR:muxtype=raw:sfile:profile=main" "http-origin"
do_hash_test $TEMP_DIR/file1.mpd "dash-sfile"

#increase run time for tests on VM
do_test "$GPAC -runfor=$HTTP_SERVER_RUNFOR httpout:port=8080:rdirs=$TEMP_DIR" "http-server" &

sleep 0.5

myinspect=$TEMP_DIR/inspect.txt
do_test "$GPAC -i http://localhost:8080/file1.mpd inspect:dur=2:allp:deep:test=network:interleave=false:log=$myinspect -logs=dash:http@debug -lu" "dash-read"
do_hash_test $myinspect "inspect"



do_test "$GPAC -i $MEDIA_DIR/auxiliary_files/enst_audio.aac -o http://localhost:8080/file2.mpd:gpac:rdirs=$TEMP_DIR:muxtype=raw" "http-origin"

do_hash_test $TEMP_DIR/file2.mpd "dash-tpl"

test_end
}


test_http_byteranges()
{
test_begin "http-byteranges"
if [ $test_skip = 1 ] ; then
 return
fi
#make a 3sec dash
$MP4BOX -add $MEDIA_DIR/auxiliary_files/enst_audio.aac:dur=3.0 -new $TEMP_DIR/source.mp4 2> /dev/null
$MP4BOX -dash 1000 -profile onDemand -out $TEMP_DIR/file.mpd $TEMP_DIR/source.mp4 2> /dev/null

#increase run time for tests on VM
do_test "$GPAC httpout:port=8080:rdirs=$TEMP_DIR -runfor=$HTTP_SERVER_RUNFOR -logs=dash:http@debug" "http-server" &
sleep 0.01

myinspect=$TEMP_DIR/inspect.txt
do_test "$GPAC -i http://localhost:8080/file.mpd inspect:allp:deep:test=network:interleave=false:log=$myinspect -logs=dash:http@debug -lu" "dash-read"
do_hash_test $myinspect "inspect"

test_end
}


test_http_dashpush_live()
{
test_begin "http-dashpush"
if [ $test_skip = 1 ] ; then
 return
fi

$MP4BOX -add $MEDIA_DIR/auxiliary_files/enst_audio.aac -new $TEMP_DIR/source.mp4 2> /dev/null

#increase run time for tests on VM
do_test "$GPAC  -runfor=$HTTP_SERVER_RUNFOR httpout:port=8080:wdir=$TEMP_DIR -logs=http@debug" "http-server" &
sleep .1

do_test "$MP4BOX -run-for 3000 -dash-live 1000 -subdur 1000 -profile live $TEMP_DIR/source.mp4 -out http://localhost:8080/live.mpd:hmode=push -logs=http@debug" "dash_push"

wait

do_hash_test $TEMP_DIR/source_dash3.m4s "dash-seg3"

if [ -f $TEMP_DIR/source_dash1.m4s ] ; then
 result="HTTP DELETE failed on segment 1"
fi

test_end
}


test_http_dashpush_vod()
{
test_begin "http-dashpush-vod"
if [ $test_skip = 1 ] ; then
 return
fi

$MP4BOX -add $MEDIA_DIR/auxiliary_files/enst_audio.aac:dur=4 -new $TEMP_DIR/source.mp4 2> /dev/null

#increase run time for tests on VM
do_test "$GPAC  -runfor=$HTTP_SERVER_RUNFOR httpout:port=8080:wdir=$TEMP_DIR -logs=http@debug" "http-server" &
sleep .1

#we are in test mode which triggers vodcache=true (no sidx patching), force vodcache=false to test on the fly patching of sidx
do_test "$MP4BOX -dash 1000 -profile onDemand $TEMP_DIR/source.mp4 -out http://localhost:8080/live.mpd:hmode=push:vodcache=false -logs=http@debug" "dash_push"

wait

do_hash_test $TEMP_DIR/source_dashinit.mp4 "dash-vod"

test_end
}


test_https_server()
{
test_begin "https-server"
if [ $test_skip = 1 ] ; then
 return
fi

do_test "$GPAC httpout:port=8080:quit:rdirs=$MEDIA_DIR:cert=$MEDIA_DIR/tls/localhost.crt:pkey=$MEDIA_DIR/tls/localhost.key" "https-server" &
sleep .1

myinspect=$TEMP_DIR/inspect.txt
do_test "$GPAC -i https://localhost:8080/auxiliary_files/enst_audio.aac inspect:allp:deep:test=network:interleave=false:log=$myinspect$3 -graph -stats" "client-inspect"
do_hash_test $myinspect "inspect"
test_end

}



test_http_server_push_pull()
{
test_begin "http-server-push-pull"
if [ $test_skip = 1 ] ; then
 return
fi

tmp_aac=$TEMP_DIR/test.aac
do_test "$GPAC -i $MEDIA_DIR/auxiliary_files/enst_audio.aac reframer @ -o $tmp_aac:dur=2" "make-input"

#increase run time for tests on VM
do_test "$GPAC -runfor=$HTTP_SERVER_RUNFOR httpout:port=8080:quit:rdirs=$TEMP_DIR:wdir=$TEMP_DIR" "http-server" &
sleep .1
do_test "$GPAC -i $tmp_aac reframer:rt=on @ -o http://localhost:8080/live.mpd:hmode=push:dmode=dynamic" "dash-push" &
sleep .1

myinspect=$TEMP_DIR/inspect.txt
do_test "$GPAC -i http://localhost:8080/live.mpd inspect:dur=1:allp:deep:test=network:interleave=false:log=$myinspect" "client-inspect"
do_hash_test $myinspect "inspect"
test_end

}


#test server mode
test_http_server
#test server mode directory listing
test_http_server_dlist
#test server sink mode (icecast-like)
test_http_server_sink
#test push mode on write server
test_http_push
#test push mode on source server
test_http_source
#test low latency push
test_http_origin

#test ondemand dash served (for byte ranges)
test_http_byteranges

#test dash with raw format on http (for seg size messages)
test_http_dashraw

#test live dash output to http with PUT and DELETE
test_http_dashpush_live

#test live dash output to http with PUT and byte range update for SIDX
test_http_dashpush_vod

#test https server
test_https_server

#test http server + push instance + client
test_http_server_push_pull
