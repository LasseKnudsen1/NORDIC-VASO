# Resample deltas for laminar analysis and cut irrelevant slices to reduce memory hit:
rootDir="/Volumes/USA2/testNORDICvaso"
versions=('cwf' 'cw' 'wf' 'cf' 'c' 'w' 'f' 'allOff' 'noNORDIC')
slicesOfInterest=(28 32)

for version in ${versions[@]}; do
printf -v results_dir "${rootDir}/%s" ${version}
cd ${results_dir}
	for contrast in "VASO" "BOLD"; do
	3dresample -master ${rootDir}/rim.nii -rmode Cu -prefix ./analysis/${version}_deltas_${contrast}_resample.nii -input ./analysis/${version}_deltas_${contrast}.nii -overwrite
	3dresample -master ${rootDir}/rim.nii -rmode Cu -prefix ./analysis/${version}_mean_delta_${contrast}_resample.nii -input ./analysis/${version}_mean_delta_${contrast}.nii -overwrite

	#Cut slices:
	3dZcutup -keep ${slicesOfInterest[0]} ${slicesOfInterest[1]} -prefix ./analysis/${version}_deltas_${contrast}_resample.nii -overwrite ./analysis/${version}_deltas_${contrast}_resample.nii 
	done
done

#Get cut version of depthmap as well:
3dZcutup -keep ${slicesOfInterest[0]} ${slicesOfInterest[1]} -prefix ${rootDir}/rim_metric_equidist_Zcutup.nii -overwrite ${rootDir}/rim_metric_equidist.nii 