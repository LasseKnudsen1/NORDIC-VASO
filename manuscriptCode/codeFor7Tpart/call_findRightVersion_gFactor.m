%Call script for compareNORDICversions_testNORDICvaso
%Run with runningmode="saveMode" first so files dont have to be loaded and
%"preprocessed" everytime. Then run with runningMode="loadMode". If E.g.
%ROI or depthmap changes then run again in saveMode first. 

% for version=["wf" "w" "wf_gSame" "wf_gNearest"]
for version=["wf_gNearest"]
clearvars -except version; clc; close all
ARG.rootDir='/Volumes/china2/nordicVASO/20230519_EMM/updated/';

%Set adjustable arguments:d
ARG.version=convertStringsToChars(version); 
ARG.runningMode="loadMode";
ARG.contrast='VASO';
ARG.num_vol=144;
ARG.num_TRperBlock=6;
ARG.num_blocks=24; %Per run (twice the number of trials)
ARG.discardFirstVols=2;
ARG.runs=3:6;

if ARG.runningMode=="loadMode"
    saveFigs=0;
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
ARG.pPSCs_noNORDIC=[ARG.rootDir 'w_noNORDIC/analysis/w_noNORDIC_PSCs_' ARG.contrast '.nii'];
ARG.pdeltas_NORDIC_resample=[ARG.analysisDir '/' ARG.version '_deltas_' ARG.contrast '_resample.nii'];
ARG.pdeltas_noNORDIC_resample=[ARG.rootDir 'w_noNORDIC/analysis/w_noNORDIC_deltas_' ARG.contrast '_resample.nii'];
ARG.pROI=[ARG.rootDir 'ROI1.nii'];
ARG.pdepthmap=[ARG.rootDir 'rim2_metric_equidist.nii'];

%paths to motion corrected timeseries:
for run = 1:numel(ARG.runs) %(made compatible with runs not starting from 1):
    if ARG.contrast=="VASO"
        ARG.pMoco_NORDIC{run}=[ARG.resultsDir '/' ARG.version '_run' num2str(ARG.runs(run)) '_VASO_LN.nii'];
        ARG.pMoco_noNORDIC{run}=[ARG.rootDir 'w_noNORDIC/w_noNORDIC' '_run' num2str(ARG.runs(run)) '_VASO_LN.nii'];
    elseif ARG.contrast=="BOLD"
        ARG.pMoco_NORDIC{run}=[ARG.resultsDir '/' ARG.version '_moco_run' num2str(ARG.runs(run)) '_INV2_magn.nii'];
        ARG.pMoco_noNORDIC{run}=[ARG.rootDir 'w_noNORDIC/w_noNORDIC' '_moco_run' num2str(ARG.runs(run)) '_INV2_magn.nii'];
    end
end

cd(ARG.resultsDir)


%Run:
if ARG.runningMode=="loadMode"
    findRightVersion_gFactor(ARG,saveFigs)
else
    findRightVersion_gFactor(ARG)
end


end
