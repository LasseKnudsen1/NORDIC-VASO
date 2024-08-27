%Call script for findRightVersion
%Run with runningmode="saveMode" first so files dont have to be loaded and
%"preprocessed" everytime. Then run with runningMode="loadMode".

% for version=["cwf" "cw" "wf" "cf" "c" "w" "f" "allOff"]
for version=["wf"]
clearvars -except version; clc; close all
ARG.rootDir='/Volumes/china2/nordicVASO/testNORDICvaso/';

%Set adjustable arguments:
ARG.version=convertStringsToChars(version); 
ARG.runningMode="loadMode";
ARG.contrast='VASO';
ARG.num_vol=144;
ARG.num_TRperBlock=6;
ARG.num_blocks=24; %Per run (twice the number of trials)

if ARG.runningMode=="loadMode"
    saveFigs=0; %put this to 1 if figures should be saved/overwritten
end

%get paths and corresponding Inversion file: 
if ARG.contrast=='VASO'
    ARG.inversion='INV1';
elseif ARG.contrast=='BOLD'
    ARG.inversion='INV2';
end

%paths to folders:
ARG.resultsDir=[ARG.rootDir ARG.version];
ARG.analysisDir=[ARG.resultsDir '/analysis'];

%paths to .nii files:
ARG.pPSCs_NORDIC=[ARG.analysisDir '/' ARG.version '_PSCs_' ARG.contrast '.nii'];
ARG.pPSCs_noNORDIC=[ARG.rootDir 'noNORDIC/analysis/noNORDIC_PSCs_' ARG.contrast '.nii'];
ARG.pdeltas_dif=[ARG.analysisDir '/dif/' ARG.version '_dif_deltas_BOLD.nii']; %Note, we only look at bold for difference delta.
ARG.pdeltas_NORDIC_resample=[ARG.analysisDir '/' ARG.version '_deltas_' ARG.contrast '_resample.nii'];
ARG.pdeltas_noNORDIC_resample=[ARG.rootDir 'noNORDIC/analysis/noNORDIC_deltas_' ARG.contrast '_resample.nii'];
ARG.praw_magn_NORDIC=[ARG.resultsDir '/' ARG.version '_run1_' ARG.inversion '_magn.nii'];
ARG.praw_magn_noNORDIC=[ARG.rootDir 'noNORDIC/noNORDIC_run1_' ARG.inversion '_magn.nii'];
ARG.ptVal_NORDIC=[ARG.analysisDir '/' ARG.version '_t_' ARG.contrast '.nii'];
ARG.ptVal_noNORDIC=[ARG.rootDir 'noNORDIC/analysis/noNORDIC_t_' ARG.contrast '.nii'];
ARG.ptSNR_NORDIC=[ARG.resultsDir '/tSNR_' ARG.version '_run1_' ARG.inversion '.nii'];
ARG.ptSNR_noNORDIC=[ARG.rootDir 'noNORDIC/tSNR_noNORDIC_run1_' ARG.inversion '.nii'];
ARG.pROI=[ARG.rootDir 'ROI1.nii'];
ARG.pdepthmap=[ARG.rootDir 'rim2_metric_equidist_Zcutup.nii'];


cd(ARG.resultsDir)
%For f-versions also set names of phase-files:
if sum(ARG.version=='f') == 1
    ARG.praw_phase_NORDIC=[ARG.resultsDir '/' ARG.version '_run1_' ARG.inversion '_phase.nii'];
    ARG.praw_phase_noNORDIC=[ARG.rootDir 'noNORDIC/noNORDIC_run1_' ARG.inversion '_phase.nii'];
end

%Run:
if ARG.runningMode=="loadMode"
    findRightVersion(ARG,saveFigs)
else
    findRightVersion(ARG)
end


end
