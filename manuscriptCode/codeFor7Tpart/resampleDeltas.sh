# Resample deltas and cut irrelevant slices to reduce memory hit:
rootDir="/Volumes/china2/nordicVASO/20230519_EMM/"
versions=('wf' 'w' 'wf_gSame' 'wf_gNearest' 'w_noNORDIC')

for version in ${versions[@]}; do
printf -v results_dir "${rootDir}/%s" ${version}
cd ${results_dir}
	for contrast in "VASO" "BOLD"; do
	3dresample -master ${rootDir}/rim2.nii -rmode Cu -prefix ./analysis/${version}_deltas_${contrast}_resample.nii -input ./analysis/${version}_deltas_${contrast}.nii -overwrite
	3dresample -master ${rootDir}/rim2.nii -rmode Cu -prefix ./analysis/${version}_mean_delta_${contrast}_resample.nii -input ./analysis/${version}_mean_delta_${contrast}.nii -overwrite
	done
done