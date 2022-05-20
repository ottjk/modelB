setenv JULIA_DEPOT_PATH /home/jkott/julia
path=`pwd`

for L in 8 ; do

 id=$RANDOM # not important -- just to provide a random seed for the start

 # create a tmp file for submission 
 TMPFILE=`mktemp tmp.XXXXXXXXXXXX`
 
 # populate teh file with needed script 
 cp run_short.sh $TMPFILE
 echo "julia -t 16 modelB_thermalizer.jl  $id $L $RANDOM  >  /home/jkott/tmp_modelB_${L}_${id}.dat"  >> $TMPFILE
 echo "rm $path/$TMPFILE "  >> $TMPFILE
 
 # submit
 cp run_short.sh $TMPFILE
 chmod u+x $TMPFILE
 bsub < $TMPFILE

done