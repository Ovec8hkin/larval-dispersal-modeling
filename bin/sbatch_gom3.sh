#!/bin/bash
#SBATCH --job-name=WB_bit
#SBATCH --partition=compute
##SBATCH --mail-user=joshuazahner@gmail.com
##SBATCH --mail-type=ALL
#SBATCH --nodes=1
#SBATCH -n 36
##SBATCH --mem=5400
#SBATCH --mem-per-cpu=150
#SBATCH --output=WB_bit_%j.out
echo "Starting Run"
echo `date`

/bin/echo
/bin/echo Execution host: `hostname`.
/bin/echo Directory: `pwd`

module load intel/2018 netcdf/intel openmpi/intel/3.0.1

/vortexfs1/home/jzahner/fiscm_gom/trunk/fiscm model_settings.nml > ./model_log.log

echo "Finish run"
echo `date`

