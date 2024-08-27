#MOCO, BOCO, script for gFactor analsis
estimatorVersion="wf"
rootDir="/Volumes/china2/nordicVASO/20230519_EMM"
estimatorDir="${rootDir}/${estimatorVersion}"
num_vol=143 #Without noise volumes and in separate timeseries (INV1/INV2). Counting from 0
runs=(3 4 5 6)
inversions=("INV1" "INV2")
versions=("wf" "w" "wf_gSame" "wf_gNearest" "w_noNORDIC")

#======== Estimate motion parameters =======#
#First estimate motion parameters for each run, which can then be applied to all datatypes. 
#We do this using data type where noiseVol was used and denoising was done on combined nulled/notNulled.
cd ${estimatorDir}
for run in ${runs[@]} ; do
for INV in ${inversions[@]}; do 
    # Register each volume to the base (I use 1 which is second volume, because first is non-steady state). We align to 3rd run since first two were discarded due to motion.
    3dvolreg -verbose -zpad 2 -base ${estimatorVersion}_run3_${INV}_magn.nii'[1]' \
        -prefix tmp.run${run}_${INV}.nii \
        -1Dfile dfile.run${run}_${INV}.1D \
        -1Dmatrix_save mat.run${run}_${INV}.vr.aff12.1D \
        ${estimatorVersion}_run${run}_${INV}_magn.nii"[0..${num_vol}]"
done
done

trash ./tmp.run*_INV*.nii

#======== Apply motion parameters =======#
#Apply motion parameters to all datatypes:
for version in ${versions[@]}; do
cd ${rootDir}/${version}
for run in ${runs[@]}; do
for INV in ${inversions[@]}; do 

#Add the brackets in the end to discard potential noiseVolumes.
3dAllineate -input ${version}_run${run}_${INV}_magn.nii"[0..${num_vol}]" \
            -1Dmatrix_apply ${rootDir}/${estimatorVersion}/mat.run${run}_${INV}.vr.aff12.1D \
            -prefix ${version}_moco_run${run}_${INV}_magn.nii -overwrite 


#Compute mean for quality control (just for one of the versions as we use the same parameters for all):
if  [[ ${version} == ${estimatorVersion} ]]; then
3dtstat -mean -prefix mean_moco_run${run}_${INV}.nii ${version}_moco_run${run}_${INV}_magn.nii -overwrite
fi

done
done
done



#======== Compute tSNR maps =======#
for version in ${versions[@]}; do
cd ${rootDir}/${version}
for run in ${runs[@]} ; do
for INV in ${inversions[@]}; do 
3dTstat -overwrite -cvarinv -prefix tSNR_${version}_run${run}_${INV}.nii ${version}_moco_run${run}_${INV}_magn.nii
done
done
done


#======== BOCO =======#
#BOCO without temporal upsampling and shifting due to segmented:
for version in ${versions[@]}; do
cd ${rootDir}/${version}
for run in ${runs[@]}; do
LN_BOCO -Nulled ${version}_moco_run${run}_INV1_magn.nii -BOLD ${version}_moco_run${run}_INV2_magn.nii

#change from LN_BOCO default naming convention to desired filenames:
mv ./VASO_LN.nii ./${version}_run${run}_VASO_LN.nii


done
done









