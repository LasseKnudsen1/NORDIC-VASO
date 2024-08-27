%Pipeline to run NORDIC with different input parameters. Made to run 1
%subject at the time but multiple runs.
%% Set paths and parameters:
clc; clear; close all
%Create structure with path for current subject and sessions:   
current_study='testNORDICvaso';
versStruc.rootDir=['/Volumes/USA2/' current_study];
versStruc.noNORDICDir=[versStruc.rootDir '/noNORDIC'];
versStruc.runs=1:4;
versStruc.num_noiseVolumesLast=4; %in full timeseries (nulled+not-nulled combined). 
  
%Set parameters for how to run NORDIC:
% 'cwf' 'cw' 'wf' 'cf' 'c' 'w' 'f' 'allOff'
versStruc.param.useCombinedInversions=0; %Set to 1 for combined ("c"), 0 for separate.
versStruc.param.useNoiseVol=1; %Set to 1 if you want to append noise volume(s) ("w"), 0 if not.
versStruc.param.useFullComplex=0; %Set to 1 if you want to use both magn and phase images ("f"), 0 if magn only.


%Make ARG structure for NORDIC containing denoising parameters:
versStruc.ARG.temporal_phase=1;
versStruc.ARG.phase_filter_width=10;
versStruc.ARG.gfactor_patch_overlap=6;
versStruc.ARG.save_gfactor_map=1;
versStruc.ARG.save_add_info=1;
versStruc.ARG.save_residual_matlab=1;
versStruc.ARG.factor_error=1;


%% Get prefix associated with output:
%c means nulled/notNulled combined (no c is separate), w is with noise
%volumes appended (no w is without), f is complex-valued denoising (no f is
%magnitude only). 
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

%Set number of noise volumes which depends on whether we want to denoise
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
%% If the timeseries was combined-denoised, then split into INV1 and INV2
if  sum(versStruc.prefix=='c') == 1
    clc; close all
    clearvars -except versStruc
    cd(versStruc.resultsDir)
    for run=versStruc.runs
        %Load magnitude file:
        fileName_magn=[versStruc.prefix '_run' num2str(run) '_magn.nii'];
        %If phase was used and denoised, also load that:
        if sum(versStruc.prefix=='f') == 1
        fileName_phase=[versStruc.prefix '_run' num2str(run) '_phase.nii'];
        end

        %This part is just to avoid problems with scaling/offset when using
        %the niftiread function, in many cases it can be ignored, and if the
        %error occurs, make sure scaling and offset is multiplied/added on
        %appropriately. 
        info=niftiinfo(fileName_magn);
        if info.MultiplicativeScaling~=0 && info.MultiplicativeScaling~=1 || info.AdditiveOffset~=0
            error('make sure niftiread function works as it should, you might need to account for scaling/offset')
        end

        Y_magn=niftiread(fileName_magn);
        if sum(versStruc.prefix=='f') == 1
        Y_phase=niftiread(fileName_phase);
        end

        %Split into INV1 and INV2:
        s=size(Y_magn);
        INV1_magn=Y_magn(:,:,:,1:2:s(4));
        INV2_magn=Y_magn(:,:,:,2:2:s(4));
        if sum(versStruc.prefix=='f') == 1
        INV1_phase=Y_phase(:,:,:,1:2:s(4));
        INV2_phase=Y_phase(:,:,:,2:2:s(4));
        end


        %Write timeseries:
        info.ImageSize(4)=info.ImageSize(4)/2;
        niftiwrite(INV1_magn,[versStruc.prefix '_run' num2str(run) '_INV1_magn.nii'],info)
        niftiwrite(INV2_magn,[versStruc.prefix '_run' num2str(run) '_INV2_magn.nii'],info)
        if sum(versStruc.prefix=='f') == 1
        niftiwrite(INV1_phase,[versStruc.prefix '_run' num2str(run) '_INV1_phase.nii'],info)
        niftiwrite(INV2_phase,[versStruc.prefix '_run' num2str(run) '_INV2_phase.nii'],info)
        end
    end

end

%% Get difference timeseries 
% Get difference timeseries, i.e. what NORDIC removes, so 
% magnitude of complex difference for 'f' and difference of magnitude images if not).
clc; close all
clearvars -except versStruc
cd(versStruc.resultsDir)

if sum(versStruc.prefix=='f') == 1 %If full complex:
    for run=versStruc.runs
        for inversion=[1,2]

            fileName_noNORDIC_magn=[versStruc.noNORDICDir '/noNORDIC_run' num2str(run) '_INV' num2str(inversion) '_magn.nii'];
            fileName_NORDIC_magn=[versStruc.prefix '_run' num2str(run) '_INV' num2str(inversion) '_magn.nii'];

            fileName_noNORDIC_phase=[versStruc.noNORDICDir '/noNORDIC_run' num2str(run) '_INV' num2str(inversion) '_phase.nii'];
            fileName_NORDIC_phase=[versStruc.prefix '_run' num2str(run) '_INV' num2str(inversion) '_phase.nii'];

            info=niftiinfo(fileName_magn);
            if info.MultiplicativeScaling~=0 && info.MultiplicativeScaling~=1 || info.AdditiveOffset~=0
                error('make sure niftiread function works as it should, you might need to account for scaling/offset')
            end

            %Read files:
            Y_noNORDIC_magn=single(niftiread(fileName_noNORDIC_magn));
            Y_NORDIC_magn=single(niftiread(fileName_NORDIC_magn));
            Y_noNORDIC_phase=single(niftiread(fileName_noNORDIC_phase));
            Y_NORDIC_phase=single(niftiread(fileName_NORDIC_phase));

            %Ignore appended noisevolumes (if this version has noise volumes, noNORDIC is loaded without)
            if sum(versStruc.prefix=='w') == 1
                Y_NORDIC_magn=Y_NORDIC_magn(:,:,:,1:end-versStruc.num_noiseVolumesLast/2);
                Y_NORDIC_phase=Y_NORDIC_phase(:,:,:,1:end-versStruc.num_noiseVolumesLast/2);
            end

            %Compute range etc. needed for scaling phase images (as in NORDIC_NIFTI.m):
            minVal_noNORDIC=min(Y_noNORDIC_phase(:));
            maxVal_noNORDIC=max(Y_noNORDIC_phase(:));
            phaseRange_noNORDIC=maxVal_noNORDIC-minVal_noNORDIC;
            rangeCenter_noNORDIC=(maxVal_noNORDIC+minVal_noNORDIC)/phaseRange_noNORDIC*0.5;

            minVal_NORDIC=min(Y_NORDIC_phase(:));
            maxVal_NORDIC=max(Y_NORDIC_phase(:));
            phaseRange_NORDIC=maxVal_NORDIC-minVal_NORDIC;
            rangeCenter_NORDIC=(maxVal_NORDIC+minVal_NORDIC)/phaseRange_NORDIC*0.5;

            %Scale phase:
            Y_noNORDIC_phase=(Y_noNORDIC_phase./phaseRange_noNORDIC-rangeCenter_noNORDIC)*2*pi;
            Y_NORDIC_phase=(Y_NORDIC_phase./phaseRange_NORDIC-rangeCenter_NORDIC)*2*pi;

            %Compute complex form:
            Z_noNORDIC=Y_noNORDIC_magn.* exp(1i*Y_noNORDIC_phase);
            Z_NORDIC=Y_NORDIC_magn.* exp(1i*Y_NORDIC_phase);

            %Compute magnitude of complex difference:
            dif_timeseries=abs(Z_NORDIC-Z_noNORDIC);

            info.Datatype='single';
            niftiwrite(dif_timeseries,[versStruc.prefix '_dif_run' num2str(run) '_INV' num2str(inversion) '.nii'],info);

            %Write mean image of the difference across the first 100 images:
            %I load it again with spm to avoid complaints about file size
            %with nifti write.
            V=spm_vol([versStruc.prefix '_dif_run' num2str(run) '_INV' num2str(inversion) '.nii']);
            Y=spm_read_vols((V));

            mean_dif=mean(Y(:,:,:,2:101),4); %dont include first non-steadystate volume (although it shouldnt really matter for dif).

            V=V(1);
            V.fname=[versStruc.prefix '_meanDif_run' num2str(run) '_INV' num2str(inversion) '.nii'];
            spm_write_vol(V,mean_dif);

        end
    end
else %If magnitude only
    for run=versStruc.runs
        for inversion=[1,2]

            fileName_noNORDIC_magn=[versStruc.noNORDICDir '/noNORDIC_run' num2str(run) '_INV' num2str(inversion) '_magn.nii'];
            fileName_NORDIC_magn=[versStruc.prefix '_run' num2str(run) '_INV' num2str(inversion) '_magn.nii'];
            info=niftiinfo(fileName_noNORDIC_magn);
            if info.MultiplicativeScaling~=0 && info.MultiplicativeScaling~=1 || info.AdditiveOffset~=0
                error('make sure niftiread function works as it should, could be problem with scaling/offset')
            end

            %Read files:
            Y_noNORDIC_magn=single(niftiread(fileName_noNORDIC_magn));
            Y_NORDIC_magn=single(niftiread(fileName_NORDIC_magn));

            %Ignore appended noisevolumes (if this version has noise volumes, noNORDIC is loaded without)
            if sum(versStruc.prefix=='w') == 1
                Y_NORDIC_magn=Y_NORDIC_magn(:,:,:,1:end-versStruc.num_noiseVolumesLast/2);
            end

            %Compute difference timeseries:
            dif_timeseries=Y_NORDIC_magn-Y_noNORDIC_magn;

            info.Datatype='single';
            niftiwrite(dif_timeseries,[versStruc.prefix '_dif_run' num2str(run) '_INV' num2str(inversion) '.nii'],info);

            %Write mean image of the difference across the first 100 images:
            V=spm_vol([versStruc.prefix '_dif_run' num2str(run) '_INV' num2str(inversion) '.nii']);
            Y=spm_read_vols((V));

            mean_dif=mean(Y(:,:,:,2:101),4); %dont include first non-steadystate volume (although it shouldnt really matter for dif).

            V=V(1);
            V.fname=[versStruc.prefix '_meanDif_run' num2str(run) '_INV' num2str(inversion) '.nii'];
            spm_write_vol(V,mean_dif);

        end
    end
end

%% Realign and BOCO
%Run the MOCOBOCO_test_NORDICvaso.sh script when all NORDIC versions are computed and been through the rest of the code above.
%We first use one of the versions to estimate motion parameters and then
%apply these to all other data versions. 


%% Statsjob
%Get percent signal change and t-value maps
clear; clc; close all
discardFirstVols=2;
num_TRperBlock=6; %insert number of VASO/BOLD pairs per block.
num_trials=12; %Per run
num_runs=6;
pROI='/Volumes/USA2/testNORDICvaso/ROI.nii';

for version=["cwf" "cw" "wf" "cf" "c" "w" "f" "allOff" "noNORDIC"]
cd(['/Volumes/USA2/testNORDICvaso/' convertStringsToChars(version)])
mkdir ./analysis
statsjob_testNORDICvaso(version,num_runs,discardFirstVols,num_trials,num_TRperBlock,pROI)
end

%% Statsjob dif
clear; clc; close all
discardFirstVols=2;
num_TRperBlock=6; %insert number of VASO/BOLD pairs per block.
num_trials=12; %Per run
num_runs=6;

for version=["cwf" "cw" "wf" "cf" "c" "w" "f" "allOff"]
cd(['/Volumes/USA2/testNORDICvaso/' convertStringsToChars(version)])
mkdir ./analysis/dif
statsjob_dif_testNORDICvaso(version,num_runs,discardFirstVols,num_trials,num_TRperBlock)
end