rootDir="/Volumes/USA2/20230519_EMM/"
num_runs=6

# Deoblique files:
cd ${rootDir}/noNORDIC
for run in $(seq 1 ${num_runs}); do
for type in "magn" "phase"; do
for INV in "INV1" "INV2"; do
3drefit -deoblique w_noNORDIC_run${run}_${INV}_${type}.nii
done
done
done

3drefit -deoblique ./gfactor/gfactor_run2.nii
3drefit -deoblique ./gfactor/gfactor_run3.nii
3drefit -deoblique ./gfactor/gfactor_run5.nii
3drefit -deoblique ./gfactor/gfactor_run6.nii

#Gfactor maps have flipped header, so resample to functional (this does not change the image):
3dresample -master w_noNORDIC_run1_INV1_magn.nii -rmode NN -prefix ./gfactor/gfactor_run2_prep.nii -input ./gfactor/gfactor_run2.nii
3dresample -master w_noNORDIC_run1_INV1_magn.nii -rmode NN -prefix ./gfactor/gfactor_run3_prep.nii -input ./gfactor/gfactor_run3.nii
3dresample -master w_noNORDIC_run1_INV1_magn.nii -rmode NN -prefix ./gfactor/gfactor_run5_prep.nii -input ./gfactor/gfactor_run5.nii
3dresample -master w_noNORDIC_run1_INV1_magn.nii -rmode NN -prefix ./gfactor/gfactor_run6_prep.nii -input ./gfactor/gfactor_run6.nii

#Divide gfactor by 10, since original was in int16 format:
3dcalc -a ./gfactor/gfactor_run2_prep.nii -prefix ./gfactor/gfactor_run2_prep.nii -expr 'a/10' -overwrite
3dcalc -a ./gfactor/gfactor_run3_prep.nii -prefix ./gfactor/gfactor_run3_prep.nii -expr 'a/10' -overwrite
3dcalc -a ./gfactor/gfactor_run5_prep.nii -prefix ./gfactor/gfactor_run5_prep.nii -expr 'a/10' -overwrite
3dcalc -a ./gfactor/gfactor_run6_prep.nii -prefix ./gfactor/gfactor_run6_prep.nii -expr 'a/10' -overwrite


