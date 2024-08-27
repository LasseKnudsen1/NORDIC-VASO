# Deoblique raw files:
rootDir="/Volumes/USA2/testNORDICvaso/"
num_runs=6

cd ${rootDir}/noNORDIC
for run in $(seq 1 ${num_runs}); do
for type in "magn" "phase"; do
3drefit -deoblique w_noNORDIC_run${run}_${type}.nii
done
done
