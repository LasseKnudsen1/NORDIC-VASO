#Code to run motion correction and bold correction across versions, inversions etc. 
estimatorVersion="cwf"
rootDir="/Volumes/USA2/testNORDICvaso"
estimatorDir="${rootDir}/${estimatorVersion}"
num_vol=143 #Without noise volumes and in separate timeseries (INV1/INV2). Counting from 0
num_runs=6
inversions=("INV1" "INV2")
versions=("cwf" "cw" "wf" "cf" "c" "w" "f" "allOff")

#======== Estimate motion parameters =======#
#First estimate motion parameters for each run, which can then be applied to all versions.
#We chop off potentially appended noisevolumes ""[0..${num_vol}]"" 
cd ${estimatorDir}
for run in $(seq 1 ${num_runs}) ; do
for INV in ${inversions[@]}; do 
    # Register each volume to the base (I use 1 which is second volume, because first is non-steady state)
    3dvolreg -verbose -zpad 2 -base ${estimatorVersion}_run1_${INV}_magn.nii'[1]' \
        -prefix tmp.run${run}_${INV}.nii \
        -1Dfile dfile.run${run}_${INV}.1D \
        -1Dmatrix_save mat.run${run}_${INV}.vr.aff12.1D \
        ${estimatorVersion}_run${run}_${INV}_magn.nii"[0..${num_vol}]"
done
done

#trash ./tmp.run*_INV*.nii

#======== Apply motion parameters =======#
#Apply motion parameters to all versions:
for version in ${versions[@]}; do
cd ${rootDir}/${version}
for run in $(seq 1 ${num_runs}); do
for INV in ${inversions[@]}; do 

#Add the brackets in the end to discard the noiseVolumes that are appended in 'c' versions.
3dAllineate -input ${version}_run${run}_${INV}_magn.nii"[0..${num_vol}]" \
            -1Dmatrix_apply ${rootDir}/${estimatorVersion}/mat.run${run}_${INV}.vr.aff12.1D \
            -prefix ${version}_moco_run${run}_${INV}_magn.nii -overwrite 

done
done
done



#======== Compute tSNR maps =======#
for version in ${versions[@]}; do
cd ${rootDir}/${version}
for run in $(seq 1 ${num_runs}) ; do
3dTstat -overwrite -cvarinv -prefix tSNR_${version}_run${run}_INV1.nii ${version}_moco_run${run}_INV1_magn.nii
done
done


#======== BOLD correction =======#
#BOCO without temporal upsampling and shifting due to segmented acquisition:
for version in ${versions[@]}; do
cd ${rootDir}/${version}
for run in $(seq 1 ${num_runs}); do
LN_BOCO -Nulled ${version}_moco_run${run}_INV1_magn.nii -BOLD ${version}_moco_run${run}_INV2_magn.nii -trialBOCO 12

#change from LN_BOCO default naming convention to desired filenames:
mv ./VASO_LN.nii ./${version}_run${run}_VASO_LN.nii
mv ./VASO_trialAV_LN.nii ./${version}_run${run}_VASO_trialAV_LN.nii
mv ./BOLD_trialAV_LN.nii ./${version}_run${run}_BOLD_trialAV_LN.nii

done
done









