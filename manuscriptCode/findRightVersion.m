function findRightVersion(ARG,saveFigs)
%% Prepare files
%It takes a while to load and prepare files, so if runningMode=saveMode, we
%just load and prepare files so it only has to be done once.
if ARG.runningMode=="saveMode"
    %Load/save files:
    PSCs_NORDIC=spm_read_vols(spm_vol(ARG.pPSCs_NORDIC));
    PSCs_noNORDIC=spm_read_vols(spm_vol(ARG.pPSCs_noNORDIC));
    deltas_dif=spm_read_vols(spm_vol(ARG.pdeltas_dif));
    deltas_NORDIC_resample=spm_read_vols(spm_vol(ARG.pdeltas_NORDIC_resample));
    deltas_noNORDIC_resample=spm_read_vols(spm_vol(ARG.pdeltas_noNORDIC_resample));
    tVals_NORDIC=spm_read_vols(spm_vol(ARG.ptVal_NORDIC));
    tVals_noNORDIC=spm_read_vols(spm_vol(ARG.ptVal_noNORDIC));
    tSNR_NORDIC=spm_read_vols(spm_vol(ARG.ptSNR_NORDIC));
    tSNR_noNORDIC=spm_read_vols(spm_vol(ARG.ptSNR_noNORDIC));
    raw_magn_NORDIC=spm_read_vols(spm_vol(ARG.praw_magn_NORDIC));
    raw_magn_noNORDIC=spm_read_vols(spm_vol(ARG.praw_magn_noNORDIC));
    ROI=spm_read_vols(spm_vol(ARG.pROI));
    depthmap=spm_read_vols(spm_vol(ARG.pdepthmap));


    %reshape to vector format and get rid of potential noiseVolumes:
    s=size(PSCs_noNORDIC);
    s_raw=size(raw_magn_noNORDIC);
    s_resample=size(deltas_NORDIC_resample);

    PSCs_NORDIC=reshape(PSCs_NORDIC,s(1)*s(2)*s(3),s(4));
    PSCs_noNORDIC=reshape(PSCs_noNORDIC,s(1)*s(2)*s(3),s(4));
    deltas_dif=reshape(deltas_dif,s(1)*s(2)*s(3),s(4));
    deltas_NORDIC_resample=reshape(deltas_NORDIC_resample,s_resample(1)*s_resample(2)*s_resample(3),s_resample(4));
    deltas_noNORDIC_resample=reshape(deltas_noNORDIC_resample,s_resample(1)*s_resample(2)*s_resample(3),s_resample(4));
    tVals_NORDIC=reshape(tVals_NORDIC,s(1)*s(2)*s(3),1);
    tVals_noNORDIC=reshape(tVals_noNORDIC,s(1)*s(2)*s(3),1);
    tSNR_NORDIC=reshape(tSNR_NORDIC,s(1)*s(2)*s(3),1);
    tSNR_noNORDIC=reshape(tSNR_noNORDIC,s(1)*s(2)*s(3),1);
    raw_magn_NORDIC=reshape(raw_magn_NORDIC(:,:,:,1:ARG.num_vol),s_raw(1)*s_raw(2)*s_raw(3),s_raw(4)); %make sure potential noise-volumes aren't included
    raw_magn_noNORDIC=reshape(raw_magn_noNORDIC(:,:,:,1:ARG.num_vol),s_raw(1)*s_raw(2)*s_raw(3),s_raw(4));
    ROI=reshape(ROI,s(1)*s(2)*s(3),1);
    depthmap=reshape(depthmap,s_resample(1)*s_resample(2)*s_resample(3),1);

    %Remove voxels outside ROI:
    idx=find(ROI>0);
    PSCs_NORDIC=PSCs_NORDIC(idx,:);
    PSCs_noNORDIC=PSCs_noNORDIC(idx,:);
    deltas_dif=deltas_dif(idx,:);
    tVals_NORDIC=tVals_NORDIC(idx,:);
    tVals_noNORDIC=tVals_noNORDIC(idx,:);
    tSNR_NORDIC=tSNR_NORDIC(idx,:);
    tSNR_noNORDIC=tSNR_noNORDIC(idx,:);
    raw_magn_NORDIC=raw_magn_NORDIC(idx,:);
    raw_magn_noNORDIC=raw_magn_noNORDIC(idx,:);

    %Remove voxels outside depthmap:
    idx_resample=find(depthmap>0);
    deltas_NORDIC_resample=deltas_NORDIC_resample(idx_resample,:);
    deltas_noNORDIC_resample=deltas_noNORDIC_resample(idx_resample,:);
    depthmap=depthmap(idx_resample,1);


    %If 'f' version, also load and prepare raw phase timeseries:
    if sum(ARG.version=='f') == 1
        raw_phase_NORDIC=spm_read_vols(spm_vol(ARG.praw_phase_NORDIC));
        raw_phase_noNORDIC=spm_read_vols(spm_vol(ARG.praw_phase_noNORDIC));

        raw_phase_NORDIC=reshape(raw_phase_NORDIC(:,:,:,1:ARG.num_vol),s_raw(1)*s_raw(2)*s_raw(3),s_raw(4));
        raw_phase_noNORDIC=reshape(raw_phase_noNORDIC(:,:,:,1:ARG.num_vol),s_raw(1)*s_raw(2)*s_raw(3),s_raw(4));

        raw_phase_NORDIC=raw_phase_NORDIC(idx,:);
        raw_phase_noNORDIC=raw_phase_noNORDIC(idx,:);
    end
    %Remove fields that could be set differently in loadMode:
    rmfield(ARG,'runningMode')


    save(['./analysis/' ARG.version '_dataMat1_' ARG.contrast '.mat']) 
    return
elseif ARG.runningMode=="loadMode"
    load(['./analysis/' ARG.version '_dataMat1_' ARG.contrast '.mat'])
else
    error('specify whether you want to save dataMat1.mat file or load it')
end


%% Plot NORDIC PSC as a function of noNORDIC PSC (averaged across trials):
%Fit regression line:
b=robustfit(mean(PSCs_noNORDIC,2),mean(PSCs_NORDIC,2));
x=linspace(min(mean(PSCs_noNORDIC,2)),max(mean(PSCs_noNORDIC,2)),2);
y=b(2)*x+b(1);

f2=figure;
hold on
xline(0,'k') %add x-axis
yline(0,'k') %add y-axis
scatter(mean(PSCs_noNORDIC,2),mean(PSCs_NORDIC,2))
plot(x,y,'r-')
refline(1,0)
xlabel('noNORDIC PSC')
ylabel('NORDIC PSC')
ylim([-15 25])
set(gcf,'Color',[1 1 1])
set(gca,'FontSize',15)
sgtitle(sprintf('%s - single-voxel PSC NORDIC vs noNORDIC \n slope = %02f constant = %02f ',ARG.version,b(2),b(1)),'fontsize',15,'fontweight','bold')
hold off

if saveFigs==1
saveas(f2,[ARG.rootDir 'figures/' ARG.version '/' ARG.contrast '_nordicAsFunctionOfNoNORDIC'],'epsc')
end
%% Boxplot PSC single trials (averaged across voxels)
%Load .mat files containing single-trial PSCs computed from across-voxel
%averaged timeseries:
tmp=load([ARG.rootDir '/noNORDIC/analysis/noNORDIC_PSCs_avgTS_' ARG.contrast '.mat']);
if ARG.contrast=='VASO'
acrossVoxelAvg_PSCs_noNORDIC=tmp.PSCs_avgTS_VASO;
elseif ARG.contrast=='BOLD'
acrossVoxelAvg_PSCs_noNORDIC=tmp.PSCs_avgTS_BOLD;
end

tmp=load(['./analysis/' ARG.version '_PSCs_avgTS_' ARG.contrast '.mat']);
if ARG.contrast=='VASO'
acrossVoxelAvg_PSCs_NORDIC=tmp.PSCs_avgTS_VASO;
elseif ARG.contrast=='BOLD'
acrossVoxelAvg_PSCs_NORDIC=tmp.PSCs_avgTS_BOLD;
end

num_trials=numel(acrossVoxelAvg_PSCs_NORDIC);
f3=figure;
hold on
boxchart([acrossVoxelAvg_PSCs_noNORDIC',acrossVoxelAvg_PSCs_NORDIC'])
scatter(1,acrossVoxelAvg_PSCs_noNORDIC,30,'MarkerFaceColor','k')
scatter(2,acrossVoxelAvg_PSCs_NORDIC,30,'MarkerFaceColor','k')
for trial=1:num_trials
plot([1,2],[acrossVoxelAvg_PSCs_noNORDIC(trial),acrossVoxelAvg_PSCs_NORDIC(trial)])
end
sgtitle(sprintf('%s - PSC single trials (averaged across voxels)',ARG.version),'fontsize',18,'fontweight','bold')
ylabel('PSC')
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gca,'FontSize',15)
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
hold off

if saveFigs==1
saveas(f3,[ARG.rootDir 'figures/' ARG.version '/' ARG.contrast '_boxplotSingleTrials'],'epsc')
end


%% Get layer profiles
stepsize=0.1;
lower_depth=0.05;
upper_depth=0.75;
depths=depthmap;
if lower_depth-stepsize/2<0 || upper_depth+stepsize/2>1
    error('make sure desired upper and lower depths match stepsize') 
end

temp_lower=lower_depth-stepsize/2;
temp_upper=temp_lower+stepsize;
for layer=1:numel(lower_depth:stepsize:upper_depth)
    
    %NORDIC
    deltaProfiles_NORDIC(layer,:)=mean(deltas_NORDIC_resample(depths>=temp_lower & depths<temp_upper,:),1);

    %noNORDIC
    deltaProfiles_noNORDIC(layer,:)=mean(deltas_noNORDIC_resample(depths>=temp_lower & depths<temp_upper,:),1);

    temp_lower=temp_lower+stepsize;
    temp_upper=temp_upper+stepsize;
end
sampled_depths=lower_depth:stepsize:upper_depth;


%Calculate mean and stdErr across trials:
deltaProfiles_NORDIC_mean=mean(deltaProfiles_NORDIC,2);
deltaProfiles_noNORDIC_mean=mean(deltaProfiles_noNORDIC,2);

deltaProfiles_NORDIC_stdErr=std(deltaProfiles_NORDIC,[],2)./sqrt(num_trials);
deltaProfiles_noNORDIC_stdErr=std(deltaProfiles_noNORDIC,[],2)./sqrt(num_trials);

%Plot:
f6=figure;
hold on
errorbar(sampled_depths,deltaProfiles_NORDIC_mean,deltaProfiles_NORDIC_stdErr,'r')
errorbar(sampled_depths,deltaProfiles_noNORDIC_mean,deltaProfiles_noNORDIC_stdErr,'b')

xlabel('Depth from wm to csf')
ylabel('delta')
set(gcf,'Color',[1 1 1])
set(gca,'FontSize',15)
sgtitle(sprintf('%s - Laminar profiles',ARG.version),'fontsize',20,'fontweight','bold')
legend('NORDIC','noNORDIC','location','northwest')
if ARG.contrast=='VASO'
ylim([-0.002 0.015])
elseif ARG.contrast=='BOLD'
ylim([0 80])
end
hold off

if saveFigs==1
saveas(f6,[ARG.rootDir 'figures/' ARG.version '/' ARG.contrast '_layerProfiles'],'epsc')
end

%% Get subsampled layer profiles:
f7=figure;
skipFactors=[1 2 3 6]; %Degree of subsampling, 1=no subsampling

counter1=1;
for skip=skipFactors
    for startIdx=1:num_trials/(num_trials/skip)
        idx_trials=startIdx:skip:num_trials;
        subplot(2,2,counter1)
        hold on
        plot(sampled_depths,mean(deltaProfiles_NORDIC(:,idx_trials),2),'r','linewidth',1)
        plot(sampled_depths,mean(deltaProfiles_noNORDIC(:,idx_trials),2),'b','linewidth',1)
        ylabel('Delta')
        set(gca,'FontSize',15)
        title(sprintf('trials included = %d',num_trials/skip),'FontSize',16)
        set(gca,'XColor',[0 0 0])
        set(gca,'YColor',[0 0 0])
        set(gca,'fontname','arial')
        set(gcf,'Color',[1 1 1])
        %ylim([0 0.03])
        %legend('NORDIC','noNORDIC')
        hold off
    end
    counter1=counter1+1;
end

end
