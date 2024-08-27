clear; clc; close all;
%Call script for factor error evaluation. 
%Run with runningmode="saveMode" first so files dont have to be loaded and
%"preprocessed" everytime. Then run with runningMode="loadMode".

ARG.versions=["wE0.5" "wE0.9" "w" "wE1.1" "wE1.2" "wE1.3" "wE1.4" "wE1.5" "wE2.5" "wE5"]; 
ARG.rootDir='/Volumes/china2/nordicVASO/testNORDICvaso/';

%Set adjustable arguments:
ARG.runningMode="loadMode";
ARG.contrast='VASO';
ARG.num_vol=144;
ARG.num_TRperBlock=6;
ARG.num_blocks=24; %Per run (twice the number of trials)
ARG.pROI=[ARG.rootDir 'ROI1.nii'];

%Set whether you want to save figures when in loadMode:
if ARG.runningMode=="loadMode"
    saveFigs=0;
end

%get paths and corresponding Inversion file: 
if ARG.contrast=='VASO'
    ARG.inversion='INV1';
elseif ARG.contrast=='BOLD'
    ARG.inversion='INV2';
end

%Run function:
if ARG.runningMode=="loadMode"
evalFE(ARG,saveFigs)
else
evalFE(ARG)
end

