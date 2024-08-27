%% call statsjob
clear; clc; close all
discardFirstVols=2;
num_TRperBlock=6; %insert number of VASO/BOLD pairs per block.
num_trials=12; %Per run
runs=3:6;
num_runs=numel(runs);
pROI='/Volumes/china2/nordicvASO/20230519_EMM/ROI1.nii';

for version=["wf" "w" "wf_gSame" "wf_gNearest" "w_noNORDIC"]
cd(['/Volumes/china2/nordicVASO/20230519_EMM/' convertStringsToChars(version)])
mkdir ./analysis
statsjob_gFactor(version,runs,num_runs, discardFirstVols,num_trials,num_TRperBlock,pROI)
end