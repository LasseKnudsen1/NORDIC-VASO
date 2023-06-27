%Wrapper to run NORDIC on VASO data (NIFTI_NORDIC.m) https://github.com/SteenMoeller/NORDIC_Raw.
%It runs NORDIC on nulled and not-nulled timeseries separately using magnitude-only, 
%and using appended noise-volume(s) (see link: ). 
%% Set paths and parameters:
clc; clear; close all

%Path to directory containing noNORDIC nifti files. These files are here
%assumed to be named noNORDIC_runX_INV1_magn.nii or
%noNORDIC_runX_INV2_magn.nii (INV referring to nulled/notNulled). Naming can be changed in next section. 
%The folder containing input files is also output directory (can be changed with ARG.DIROUT below). 
dataDir='/Users/Lasse/Desktop/data';

%Specify runs:
runs=[1 2 3 4];

%Set number of appended noise-volumes at the end of each timeseries 
% here it is 2 as we had 2 noise-volumes for each run and contrast (nulled
% or not-nulled). If you want thermal noise-level to be estimated by NORDIC
% instead, remove noise-volumes from input-timeseries and set this
% parameter to 0.
num_noiseVolumesLast=2;  

%Make ARG structure for NORDIC containing denoising parameters:
ARG.magnitude_only = 1; %only use magnitude images.
ARG.temporal_phase=1;
ARG.phase_filter_width=10;
ARG.gfactor_patch_overlap=6;
ARG.save_gfactor_map=1;
ARG.save_add_info=1;
ARG.save_residual_matlab=1;
ARG.factor_error=1; %Threshold scaling (1 is default).
ARG.noise_volume_last=num_noiseVolumesLast;
ARG.DIROUT=[dataDir '/'];

%####If you want to change patch-size:
%ARG.kernel_size_PCA=[28 28 1]; %patch size.

%####If you want to run NORDIC on complex-valued data :
%ARG.magnitude_only = 0; %Use both magnitude and phase 
%ARG.make_complex_nii=1; %Also output denoised phase timeseries


%% run NORDIC
%Make sure NIFTI_NORDIC.m is on matlab path. 
for run=runs
    %Note, even if ARG.magnitude_only=1 we still need to provide path to
    %both magnitude images (1st argument) and phase images (2nd argument).
    %NORDIC will just ignore the second argument.

    %INV1
    NIFTI_NORDIC([dataDir '/noNORDIC_run' num2str(run) '_INV1_magn.nii'], ...
                 [dataDir '/noNORDIC_run' num2str(run) '_INV1_phase.nii'], ...
                 ['NORDIC_run' num2str(run) '_INV1'],ARG);
    
    %INV2
    NIFTI_NORDIC([dataDir '/noNORDIC_run' num2str(run) '_INV2_magn.nii'], ...
                 [dataDir '/noNORDIC_run' num2str(run) '_INV2_phase.nii'], ...
                 ['NORDIC_run' num2str(run) '_INV2'],ARG);

end