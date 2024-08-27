function statsjob_dif_testNORDICvaso(version,num_runs,discardFirstVols,num_trials,num_TRperBlock)
%This function computes delta maps for BOLD
%Load data into cell containing all runs:
counter=0;
for run=1:num_runs
    counter=counter+1;
    %Full timeseries:
    info_BOLD=niftiinfo(sprintf('./%s_dif_run%d_INV2.nii',version,run));
    Y_BOLD_tmp=niftiread(sprintf('./%s_dif_run%d_INV2.nii',version,run));
    
    %Reshape and store runs in same data matrix
    s=size(Y_BOLD_tmp);
    Y_BOLD(counter,:,:)=single(reshape(Y_BOLD_tmp,s(1)*s(2)*s(3),s(4)));
    
end


%Get mean of each block where transition vols have been removed, assuming
%first block is rest:
num_blocks=num_trials*2;
trialCounter=1;
for run=1:num_runs
lower=discardFirstVols+1;
upper=num_TRperBlock;
counter=1;
for block=1:num_blocks
    if mod(block,2)==1 %odd blocks  
    restBlocks_BOLD(:,trialCounter)=mean(Y_BOLD(run,:,lower:upper),3);
    
    elseif mod(block,2)==0 %Even blocks
    onBlocks_BOLD(:,trialCounter)=mean(Y_BOLD(run,:,lower:upper),3);

    counter=counter+1;
    trialCounter=trialCounter+1;
    end

    lower=lower+num_TRperBlock;
    upper=upper+num_TRperBlock;
end
end

%Get delta for each trial:
deltas_BOLD=onBlocks_BOLD-restBlocks_BOLD;

%Get mean delta:
num_totalTrials=num_trials*num_runs; %Total number of trials across runs

mean_delta_BOLD=mean(deltas_BOLD,2);

%Reshape back:
deltas_BOLD=reshape(deltas_BOLD,s(1),s(2),s(3),num_totalTrials);

mean_delta_BOLD=reshape(mean_delta_BOLD,s(1),s(2),s(3),1);


%Write files:
%deltas, mean_delta and tval:
info_BOLD.Datatype='single';
info_BOLD.ImageSize(4)=size(deltas_BOLD,4);
niftiwrite(deltas_BOLD,sprintf('./analysis/dif/%s_dif_deltas_BOLD.nii',version),info_BOLD)

V_BOLD=spm_vol(sprintf('./%s_dif_run%d_INV2.nii',version,run));
V_BOLD=V_BOLD(1);
V_BOLD.fname=sprintf('./analysis/dif/%s_dif_mean_delta_BOLD.nii',version);
spm_write_vol(V_BOLD,mean_delta_BOLD);
end