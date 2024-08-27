function statsjob_gFactor(version,runs,num_runs,discardFirstVols,num_trials,num_TRperBlock,pROI)
%This function computes PSC and delta maps for VASO and BOLD
%Load data into cell containing all runs of current condition, both for VASO and BOLD:
for run=runs
    %Full timeseries:
    info_VASO=niftiinfo(sprintf('./%s_run%d_VASO_LN.nii',version,run));
    Y_VASO_tmp=niftiread(sprintf('./%s_run%d_VASO_LN.nii',version,run));
    
    info_BOLD=niftiinfo(sprintf('./%s_moco_run%d_INV2_magn.nii',version,run));
    Y_BOLD_tmp=niftiread(sprintf('./%s_moco_run%d_INV2_magn.nii',version,run));
    
    
    %Reshape and store runs in same data matrix
    s=size(Y_VASO_tmp);
    Y_VASO(run,:,:)=single(reshape(Y_VASO_tmp,s(1)*s(2)*s(3),s(4)));
    Y_BOLD(run,:,:)=single(reshape(Y_BOLD_tmp,s(1)*s(2)*s(3),s(4)));
    
end

%We want to compute PSC and delta on each voxel individually
%, and also on the average timeseries across
%ROI-voxels. So load ROI and make average timeseries:
ROI=niftiread(pROI);
ROI=reshape(ROI,s(1)*s(2)*s(3),1); %vector format
idx=find(ROI>0); %Get voxel indicies for within-ROI voxels

avgTS_VASO=Y_VASO(:,idx,:); %Only get voxels in ROI
avgTS_BOLD=Y_BOLD(:,idx,:);
avgTS_VASO=squeeze(mean(avgTS_VASO,2)); %Average across voxels
avgTS_BOLD=squeeze(mean(avgTS_BOLD,2));

%Get mean of each block where transition vols have been removed, assuming
%first block is rest:
num_blocks=num_trials*2;
trialCounter=1;
for run=runs
lower=discardFirstVols+1;
upper=num_TRperBlock;
counter=1;
for block=1:num_blocks
    if mod(block,2)==1 %odd blocks  
    restBlocks_VASO(:,trialCounter)=mean(Y_VASO(run,:,lower:upper),3);
    restBlocks_BOLD(:,trialCounter)=mean(Y_BOLD(run,:,lower:upper),3);

    restBlocks_avgTS_VASO(trialCounter)=mean(avgTS_VASO(run,lower:upper),2);
    restBlocks_avgTS_BOLD(trialCounter)=mean(avgTS_BOLD(run,lower:upper),2);
    
    
    elseif mod(block,2)==0 %Even blocks
    onBlocks_VASO(:,trialCounter)=mean(Y_VASO(run,:,lower:upper),3);
    onBlocks_BOLD(:,trialCounter)=mean(Y_BOLD(run,:,lower:upper),3);

    onBlocks_avgTS_VASO(trialCounter)=mean(avgTS_VASO(run,lower:upper),2);
    onBlocks_avgTS_BOLD(trialCounter)=mean(avgTS_BOLD(run,lower:upper),2);

    counter=counter+1;
    trialCounter=trialCounter+1;
    end

    lower=lower+num_TRperBlock;
    upper=upper+num_TRperBlock;
end
end

%Get percent change for each trial:
PSCs_VASO=((onBlocks_VASO-restBlocks_VASO)./restBlocks_VASO)*100;
PSCs_VASO=-1*PSCs_VASO;

PSCs_BOLD=((onBlocks_BOLD-restBlocks_BOLD)./restBlocks_BOLD)*100;

PSCs_avgTS_VASO=((onBlocks_avgTS_VASO-restBlocks_avgTS_VASO)./restBlocks_avgTS_VASO)*100;
PSCs_avgTS_VASO=-1*PSCs_avgTS_VASO;

PSCs_avgTS_BOLD=((onBlocks_avgTS_BOLD-restBlocks_avgTS_BOLD)./restBlocks_avgTS_BOLD)*100;


%Also make map of raw difference which is used for profiles:
deltas_VASO=onBlocks_VASO-restBlocks_VASO;
deltas_VASO=-1*deltas_VASO;

deltas_BOLD=onBlocks_BOLD-restBlocks_BOLD;

%Save PSCs_avgTS into mat file:
save(['./analysis/' convertStringsToChars(version) '_PSCs_avgTS_VASO.mat'],'PSCs_avgTS_VASO')
save(['./analysis/' convertStringsToChars(version) '_PSCs_avgTS_BOLD.mat'],'PSCs_avgTS_BOLD')


%Get mean PSC and t-value across trials as well as mean delta:
num_totalTrials=num_trials*num_runs; %Total number of trials across runs

mean_PSC_VASO=mean(PSCs_VASO,2);
mean_PSC_BOLD=mean(PSCs_BOLD,2);

tval_VASO=mean(PSCs_VASO,2) ./ (std(PSCs_VASO,[],2)/sqrt(num_totalTrials));
tval_BOLD=mean(PSCs_BOLD,2) ./ (std(PSCs_BOLD,[],2)/sqrt(num_totalTrials));

mean_delta_VASO=mean(deltas_VASO,2);
mean_delta_BOLD=mean(deltas_BOLD,2);

%Reshape back:
PSCs_VASO=reshape(PSCs_VASO,s(1),s(2),s(3),num_totalTrials);
PSCs_BOLD=reshape(PSCs_BOLD,s(1),s(2),s(3),num_totalTrials);

mean_PSC_VASO=reshape(mean_PSC_VASO,s(1),s(2),s(3),1);
mean_PSC_BOLD=reshape(mean_PSC_BOLD,s(1),s(2),s(3),1);

tval_VASO=reshape(tval_VASO,s(1),s(2),s(3),1);
tval_BOLD=reshape(tval_BOLD,s(1),s(2),s(3),1);

deltas_VASO=reshape(deltas_VASO,s(1),s(2),s(3),num_totalTrials);
deltas_BOLD=reshape(deltas_BOLD,s(1),s(2),s(3),num_totalTrials);

mean_delta_VASO=reshape(mean_delta_VASO,s(1),s(2),s(3),1);
mean_delta_BOLD=reshape(mean_delta_BOLD,s(1),s(2),s(3),1);

%Write files:
%PSCs, mean_PSC and tval:
info_VASO.ImageSize(4)=size(PSCs_VASO,4);
niftiwrite(PSCs_VASO,sprintf('./analysis/%s_PSCs_VASO.nii',version),info_VASO)

info_BOLD.Datatype='single';
info_BOLD.ImageSize(4)=size(PSCs_BOLD,4);
niftiwrite(PSCs_BOLD,sprintf('./analysis/%s_PSCs_BOLD.nii',version),info_BOLD)

V_VASO=spm_vol(sprintf('./%s_run%d_VASO_LN.nii',version,run));
V_VASO=V_VASO(1);
V_VASO.fname=sprintf('./analysis/%s_mean_PSC_VASO.nii',version);
spm_write_vol(V_VASO,mean_PSC_VASO);

V_VASO.fname=sprintf('./analysis/%s_t_VASO.nii',version);
spm_write_vol(V_VASO,tval_VASO);

V_BOLD=V_VASO;
V_BOLD.fname=sprintf('./analysis/%s_mean_PSC_BOLD.nii',version);
spm_write_vol(V_BOLD,mean_PSC_BOLD);

V_BOLD.fname=sprintf('./analysis/%s_t_BOLD.nii',version);
spm_write_vol(V_BOLD,tval_BOLD);

%deltas and mean_delta:
niftiwrite(deltas_VASO,sprintf('./analysis/%s_deltas_VASO.nii',version),info_VASO)
niftiwrite(deltas_BOLD,sprintf('./analysis/%s_deltas_BOLD.nii',version),info_BOLD)

V_VASO.fname=sprintf('./analysis/%s_mean_delta_VASO.nii',version);
spm_write_vol(V_VASO,mean_delta_VASO);
V_BOLD.fname=sprintf('./analysis/%s_mean_delta_BOLD.nii',version);
spm_write_vol(V_BOLD,mean_delta_BOLD);

end