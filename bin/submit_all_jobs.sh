#files=$1
initdir=$(pwd)

#echo $files
echo $initdir

files=$(find ../data/model_sims/warm/atlantic-cod/ -name job_submit.sh)
files=($files)

for f in ${files[@]}
do
    dir=$(dirname "${f}"); 
    cd $(echo $dir | tr -d '\r'); 
    bash ./job_submit.sh; 
    cd $(echo $initdir | tr -d '\r'); 
done 
