clear; clc; close all
%Here we are forced to use full complex and with noise-volume, because thats how NORDIC.m works. 
% Based on testNORDICvaso (3T analysis) we will not use combined.  
%Purpose of this script is to run NORDIC with the same g-factor map for all
%runs, versus the g-factor map that is closest to the run of interest (note
%that we only have 4).
rootDir='/Volumes/china2/nordicVASO/20230519_EMM/';
runs=[1 2 3 4 5 6];
gSpecs=[2 2 2 2 2 2;
        2 2 3 3 5 6]; %Insert the g-factor map we want to use for each corresponding run.
num_noiseVol=2; %How many noise volumes are in each file? 
versions=["wf_gSame","wf_gNearest"];
%% Download and concatenate files and save as .mat file
%This version of NORDIC is run on .mat files rather than NIFTI, so we first
%need to prepare format
versCounter=0;
for vers=versions
    version=convertStringsToChars(vers);
    mkdir([rootDir version])
    versCounter=versCounter+1;
    runCounter=0;
    for run=runs
        runCounter=runCounter+1;
        for INV=[1,2]
            V_magn=spm_vol([rootDir 'w_noNORDIC/w_noNORDIC_run' num2str(run) '_INV' num2str(INV) '_magn.nii']);
            V_phase=spm_vol([rootDir 'w_noNORDIC/w_noNORDIC_run' num2str(run) '_INV' num2str(INV) '_phase.nii']);


            V_gFactor=spm_vol([rootDir 'w_noNORDIC/gfactor/gfactor_run' num2str(gSpecs(versCounter,runCounter)) '_prep.nii']); %select specified g-factor map

            Y_magn=spm_read_vols(V_magn);
            Y_phase=spm_read_vols(V_phase);
            Y_gFactor=spm_read_vols(V_gFactor);

            %Remove residual nosie volumes so we only have 1 as required by NORDIC.m:
            Y_magn=Y_magn(:,:,:,1:end-(num_noiseVol-1));
            Y_phase=Y_phase(:,:,:,1:end-(num_noiseVol-1));

            %Convert to complex form:
            %Compute range etc. needed for scaling phase images:
            minVal=min(Y_phase(:));
            maxVal=max(Y_phase(:));
            phaseRange=maxVal-minVal;
            rangeCenter=(maxVal+minVal)/phaseRange*0.5;

            %Scale phase:
            Y_phase=(Y_phase./phaseRange-rangeCenter)*2*pi;

            %Compute complex form in variable KSP as required by NORDIC.m:
            KSP=Y_magn.* exp(1i*Y_phase);

            %Append g-factor volume:
            KSP=cat(4,KSP,Y_gFactor);

            %Generate variable required by NORDIC:
            KSP_processed=zeros(1,size(KSP,3));

            save([rootDir version '/' version '_inputMat4NORDIC_run' num2str(run) '_INV' num2str(INV) '.mat'],'KSP','KSP_processed')

        end
    end
end
%% Run NORDIC
clearvars -except rootDir runs num_noiseVol versions
mkdir([rootDir 'w'])
for vers=versions
    version=convertStringsToChars(vers);
    cd([rootDir version])
    for run=runs
        for INV=[1,2]
            NORDIC(['./' version '_inputMat4NORDIC_run' num2str(run) '_INV' num2str(INV) '.mat'])
            movefile(['./KSP_' version '_inputMat4NORDIC_run' num2str(run) '_INV' num2str(INV) 'kernel12.mat'],['./' version '_denoised_run' num2str(run) '_INV' num2str(INV) '.mat'])
        end
    end
end

%% Save denoised NORDIC data as nifti file:
clearvars -except rootDir runs num_noiseVol versions
info=niftiinfo([rootDir 'w_noNORDIC/w_noNORDIC_run1_INV1_magn.nii']);

for vers=versions
    version=convertStringsToChars(vers);
    cd([rootDir version])
    for run=runs
        for INV=[1,2]
            Y=zeros(info.ImageSize);
            load(['./' version '_denoised_run' num2str(run) '_INV' num2str(INV) '.mat'])
            Y(:,:,:,1:end-num_noiseVol)=abs(KSP_update);

            outputName=['./' version '_run' num2str(run) '_INV' num2str(INV) '_magn.nii'];
            niftiwrite(int16(Y),outputName,info)
        end
    end
end