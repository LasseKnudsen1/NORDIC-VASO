%Pipeline to run NORDIC with different input parameters. Made to run 1
%subject at the time but multiple runs.
%% Set paths and parameters:
clc; clear; close all
%Create structure with path for current subject and sessions:   
current_study='20230519_EMM';
versStruc.rootDir=['/Volumes/china2/nordicVASO/' current_study];
versStruc.noNORDICDir=[versStruc.rootDir '/w_noNORDIC'];
versStruc.runs=1:6;
versStruc.num_noiseVolumesLast=4; %in full timeseries (nulled not-nulled combined). 
  
%Set parameters for how to run NORDIC:
% 'cwf' 'cw' 'wf' 'cf' 'c' 'w' 'f' 'allOff'
versStruc.param.useCombinedInversions=0; %Set to 1 for combined ("c"), 0 for separate.
versStruc.param.useNoiseVol=1; %Set to 1 if you want to append noise volume(s) ("w"), 0 if not.
versStruc.param.useFullComplex=1; %Set to 1 if you want to use both magn and phase images ("f"), 0 if magn only.


%Make ARG structure for NORDIC containing denoising parameters:
versStruc.ARG.temporal_phase=1;
versStruc.ARG.phase_filter_width=10;
versStruc.ARG.gfactor_patch_overlap=6;
%versStruc.ARG.kernel_size_PCA=[28 28 1];
versStruc.ARG.save_gfactor_map=1;
versStruc.ARG.save_add_info=1;
versStruc.ARG.save_residual_matlab=1;
versStruc.ARG.factor_error=1;


%% Get prefix associated with output:
tmp='';
if versStruc.param.useCombinedInversions == 1
tmp=[tmp 'c'];
end

if versStruc.param.useNoiseVol == 1
tmp=[tmp 'w'];
end

if versStruc.param.useFullComplex == 1
tmp=[tmp 'f'];
end


if isempty(tmp)
versStruc.prefix='allOff'; %if no 'c','w' or 'f', set name to allOff to avoid empty named folders/files.
else
versStruc.prefix=tmp;
end

if versStruc.ARG.factor_error~=1
versStruc.prefix=[versStruc.prefix 'E' num2str(versStruc.ARG.factor_error)]; %E for factor-error
end

%Set resultsDir
versStruc.resultsDir=[versStruc.rootDir '/' versStruc.prefix];
%% run NORDIC
clc; close all
clearvars -except versStruc
%Make directory for this version and call it by its prefix
mkdir([versStruc.rootDir '/' versStruc.prefix])
cd(versStruc.resultsDir)

%Set number of noise volumes which depends on whether we want to denoised
%combined/separate timeseries, and whether we want noise volume or not.
if  sum(versStruc.prefix=='w') == 1
    if sum(versStruc.prefix=='c') == 1
        versStruc.ARG.noise_volume_last=versStruc.num_noiseVolumesLast;
    else
        versStruc.ARG.noise_volume_last=versStruc.num_noiseVolumesLast/2;
    end
else
    versStruc.ARG.noise_volume_last=0;
end

%Set whether we want to use both magn and phase or magn only:
if sum(versStruc.prefix=='f') == 1
    versStruc.ARG.magnitude_only = 0; 
    versStruc.ARG.make_complex_nii=1;
else
    versStruc.ARG.magnitude_only = 1;    
end

%Now run NORDIC, which will use the dataset with or without noisevolumes
%appended, dependent on whether 'w' is on or off. Also, it will run it on
%combined or separate timeseries dependent on 'c'.
for run=versStruc.runs
    if sum(versStruc.prefix=='c') == 1
        if sum(versStruc.prefix=='w') == 1
            %Combined with noisevol
            NIFTI_NORDIC([versStruc.noNORDICDir '/w_noNORDIC_run' num2str(run) '_magn.nii'], ...
                               [versStruc.noNORDICDir '/w_noNORDIC_run' num2str(run) '_phase.nii'], ...
                               [versStruc.prefix '_run' num2str(run) '_'],versStruc.ARG);
        else
            %Combined without noisevol
            NIFTI_NORDIC([versStruc.noNORDICDir '/noNORDIC_run' num2str(run) '_magn.nii'], ...
                             [versStruc.noNORDICDir '/noNORDIC_run' num2str(run) '_phase.nii'], ...
                             [versStruc.prefix '_run' num2str(run) '_'],versStruc.ARG);
        end
    else
        if sum(versStruc.prefix=='w') == 1
            %INV1 with noisevol
            NIFTI_NORDIC([versStruc.noNORDICDir '/w_noNORDIC_run' num2str(run) '_INV1_magn.nii'], ...
                             [versStruc.noNORDICDir '/w_noNORDIC_run' num2str(run) '_INV1_phase.nii'], ...
                             [versStruc.prefix '_run' num2str(run) '_INV1_'],versStruc.ARG);
            %INV2 with noisevol
            NIFTI_NORDIC([versStruc.noNORDICDir '/w_noNORDIC_run' num2str(run) '_INV2_magn.nii'], ...
                             [versStruc.noNORDICDir '/w_noNORDIC_run' num2str(run) '_INV2_phase.nii'], ...
                             [versStruc.prefix '_run' num2str(run) '_INV2_'],versStruc.ARG);
        else
            %INV1 without noisevol
            NIFTI_NORDIC([versStruc.noNORDICDir '/noNORDIC_run' num2str(run) '_INV1_magn.nii'], ...
                             [versStruc.noNORDICDir '/noNORDIC_run' num2str(run) '_INV1_phase.nii'], ...
                             [versStruc.prefix '_run' num2str(run) '_INV1_'],versStruc.ARG);
            %INV2 without noisevol
            NIFTI_NORDIC([versStruc.noNORDICDir '/noNORDIC_run' num2str(run) '_INV2_magn.nii'], ...
                             [versStruc.noNORDICDir '/noNORDIC_run' num2str(run) '_INV2_phase.nii'], ...
                             [versStruc.prefix '_run' num2str(run) '_INV2_'],versStruc.ARG);
        end
    end
end

%Add 'magn' to the output name of files when magnitude_only is used (it will not by default):
for run=versStruc.runs
    if sum(versStruc.prefix=='f') == 0 || versStruc.prefix=="allOff"
        if sum(versStruc.prefix=='c') == 1
            movefile([versStruc.prefix '_run' num2str(run) '_.nii'],[versStruc.prefix '_run' num2str(run) '_magn.nii'])
        else
            movefile([versStruc.prefix '_run' num2str(run) '_INV1_.nii'],[versStruc.prefix '_run' num2str(run) '_INV1_magn.nii'])
            movefile([versStruc.prefix '_run' num2str(run) '_INV2_.nii'],[versStruc.prefix '_run' num2str(run) '_INV2_magn.nii'])
        end
    end
end


%Save the parameters used for this version:
save('parameters.mat', 'versStruc')
