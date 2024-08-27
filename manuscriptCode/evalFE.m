function evalFE(ARG,saveFigs)
%% Prepare files
%It takes a while to load and prepare files, so if runningMode=saveMode, we
%just load and prepare files so it only has to be done once.
if ARG.runningMode=="saveMode"
    counter=0;
    for i=ARG.versions
    counter=counter+1;
    vers=convertStringsToChars(i);
    resultsDir=[ARG.rootDir vers];
    analysisDir=[resultsDir '/analysis'];

    %Load/save files:
    tmp_PSCs_NORDIC=spm_read_vols(spm_vol([analysisDir '/' vers '_PSCs_' ARG.contrast '.nii']));
    tmp_PSCs_noNORDIC=spm_read_vols(spm_vol([ARG.rootDir 'noNORDIC/analysis/noNORDIC_PSCs_' ARG.contrast '.nii']));
    tmp_deltas_dif=spm_read_vols(spm_vol([analysisDir '/dif/' vers '_dif_deltas_BOLD.nii']));
    ROI=spm_read_vols(spm_vol(ARG.pROI));


    %reshape to vector format and get rid of potential noiseVolumes:
    s=size(tmp_PSCs_noNORDIC);

    tmp_PSCs_NORDIC=reshape(tmp_PSCs_NORDIC,s(1)*s(2)*s(3),s(4));
    tmp_PSCs_noNORDIC=reshape(tmp_PSCs_noNORDIC,s(1)*s(2)*s(3),s(4));
    tmp_deltas_dif=reshape(tmp_deltas_dif,s(1)*s(2)*s(3),s(4));
    ROI=reshape(ROI,s(1)*s(2)*s(3),1);


    %Remove voxels outside ROI:
    idx=find(ROI>0);
    tmp_PSCs_NORDIC=tmp_PSCs_NORDIC(idx,:);
    tmp_PSCs_noNORDIC=tmp_PSCs_noNORDIC(idx,:);
    tmp_deltas_dif=tmp_deltas_dif(idx,:);


    %Load .mat files containing single-trial PSCs computed from across-voxel
    %averaged timeseries:
    if ARG.contrast=='VASO'
        tmp=load([ARG.rootDir '/noNORDIC/analysis/noNORDIC_PSCs_avgTS_' ARG.contrast '.mat']);
        tmp_acrossVoxelAvg_PSCs_noNORDIC=tmp.PSCs_avgTS_VASO;

        tmp=load([analysisDir '/' vers '_PSCs_avgTS_' ARG.contrast '.mat']);
        tmp_acrossVoxelAvg_PSCs_NORDIC=tmp.PSCs_avgTS_VASO;

        %dif:
        tmp=load([analysisDir '/dif/' vers '_dif_deltas_avgTS_BOLD.mat']);
        tmp_dif_acrossVoxelAvg_deltas=tmp.deltas_avgTS_BOLD;
    elseif ARG.contrast=='BOLD'
        tmp=load([ARG.rootDir '/noNORDIC/analysis/noNORDIC_PSCs_avgTS_' ARG.contrast '.mat']);
        tmp_acrossVoxelAvg_PSCs_noNORDIC=tmp.PSCs_avgTS_BOLD;

        tmp=load([analysisDir '/' vers '_PSCs_avgTS_' ARG.contrast '.mat']);
        tmp_acrossVoxelAvg_PSCs_NORDIC=tmp.PSCs_avgTS_BOLD;

        %dif:
        tmp=load([analysisDir '/dif/' vers '_dif_deltas_avgTS_BOLD.mat']);
        tmp_dif_acrossVoxelAvg_deltas=tmp.deltas_avgTS_BOLD;
    end

    %store data from all versions in single data structure:
    data(counter).PSCs_NORDIC=tmp_PSCs_NORDIC;
    data(counter).PSCs_noNORDIC=tmp_PSCs_noNORDIC;
    data(counter).deltas_dif=tmp_deltas_dif;
    data(counter).acrossVoxelAvg_PSCs_NORDIC=tmp_acrossVoxelAvg_PSCs_NORDIC;
    data(counter).acrossVoxelAvg_PSCs_noNORDIC=tmp_acrossVoxelAvg_PSCs_noNORDIC;
    data(counter).dif_acrossVoxelAvg_deltas=tmp_dif_acrossVoxelAvg_deltas;

    end

    %Remove fields that could be set differently in loadMode:
    rmfield(ARG,'runningMode')

    save([ARG.rootDir 'dataMat_evalFE_' ARG.contrast '.mat'],'ARG','data','ROI','depthmap') 
    return
elseif ARG.runningMode=="loadMode"
    load([ARG.rootDir 'dataMat_evalFE_' ARG.contrast '.mat'])
else
    error('specify whether you want to save data mat file or load it')
end
%% Plot acrossVoxAvg PSC as a function of version
num_trials=numel(data(1).acrossVoxelAvg_PSCs_NORDIC);
num_versions=numel(data);
f1=figure;
subplot(2,1,1)
hold on
acrossTrialMean_noNORDIC=mean(data(1).acrossVoxelAvg_PSCs_noNORDIC);
acrossTrialStdErr_noNORDIC=std(data(1).acrossVoxelAvg_PSCs_noNORDIC)./sqrt(num_trials);
plot([0,numel(data)+1],[acrossTrialMean_noNORDIC,acrossTrialMean_noNORDIC],'--k')
for i=1:num_versions
%noNORDIC:
if i==1
    errorbar(i,acrossTrialMean_noNORDIC,acrossTrialStdErr_noNORDIC,'.b')
end
%NORDIC:
acrossTrialMean=mean(data(i).acrossVoxelAvg_PSCs_NORDIC);
acrossTrialStdErr=std(data(i).acrossVoxelAvg_PSCs_NORDIC)./sqrt(num_trials);
errorbar(i+1,acrossTrialMean,acrossTrialStdErr,'.b')
end
set(gca,'XTick',1:num_versions+1)
set(gca,'XTickLabel',['noNORDIC' ARG.versions])
ylabel('Percent change')
set(gcf,'Color',[1 1 1])
set(gca,'FontSize',15)
title(sprintf('Average percent change \n as a function of factor error'),'fontweight','normal')
if ARG.contrast=='VASO'
ylim([0 1])
elseif ARG.contrast=='BOLD'
ylim([0 1.2])
end
hold off

%Do the same for dif:
subplot(2,1,2)
hold on
plot([0,numel(data)+1],[0 0],'--k')
for i=1:num_versions
%noNORDIC:
if i==1
plot(i,0,'.b')
end
%NORDIC:
acrossTrialMean=-1*mean(data(i).dif_acrossVoxelAvg_deltas); %invert to get noNORDIC-NORDIC instead of NORDIC-noNORDIC
acrossTrialStdErr=std(data(i).dif_acrossVoxelAvg_deltas)./sqrt(num_trials);
errorbar(i+1,acrossTrialMean,acrossTrialStdErr,'.b')
end
set(gca,'XTick',1:num_versions+1)
set(gca,'XTickLabel',['noNORDIC' ARG.versions])
ylabel('Delta')
set(gcf,'Color',[1 1 1])
set(gca,'FontSize',15)
title(sprintf('Average delta for difference timeseries \n as a function of factor error'),'fontweight','normal')
ylim([-1 8])
hold off

sgtitle(sprintf('Evaluation of response magnitude changes \n as a function of NORDIC version'),'fontsize',15,'fontweight','bold')

f1.Position=[500 0 500 1500]; %[left bottom width height]
if saveFigs==1
saveas(f1,[ARG.rootDir 'figures/evalFE/' ARG.contrast '_PSCasFunctionOfVersion'],'epsc')
end




end
