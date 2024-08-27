function findRightVersion_gFactor(ARG,saveFigs)
%% Prepare files
%It takes a while to load and prepare files, so if runningMode=saveMode, we
%just load and prepare files so it only has to be done once.
if ARG.runningMode=="saveMode"
    %Load/save files:
    PSCs_NORDIC=spm_read_vols(spm_vol(ARG.pPSCs_NORDIC));
    PSCs_noNORDIC=spm_read_vols(spm_vol(ARG.pPSCs_noNORDIC));
    deltas_NORDIC_resample=spm_read_vols(spm_vol(ARG.pdeltas_NORDIC_resample));
    deltas_noNORDIC_resample=spm_read_vols(spm_vol(ARG.pdeltas_noNORDIC_resample));
    ROI=spm_read_vols(spm_vol(ARG.pROI));
    depthmap=spm_read_vols(spm_vol(ARG.pdepthmap));


    %reshape to vector format and get rid of potential noiseVolumes:
    s=size(PSCs_noNORDIC);
    s_resample=size(deltas_NORDIC_resample);

    PSCs_NORDIC=reshape(PSCs_NORDIC,s(1)*s(2)*s(3),s(4));
    PSCs_noNORDIC=reshape(PSCs_noNORDIC,s(1)*s(2)*s(3),s(4));
    deltas_NORDIC_resample=reshape(deltas_NORDIC_resample,s_resample(1)*s_resample(2)*s_resample(3),s_resample(4));
    deltas_noNORDIC_resample=reshape(deltas_noNORDIC_resample,s_resample(1)*s_resample(2)*s_resample(3),s_resample(4));
    ROI=reshape(ROI,s(1)*s(2)*s(3),1);
    depthmap=reshape(depthmap,s_resample(1)*s_resample(2)*s_resample(3),1);

    %Remove voxels outside ROI:
    idx=find(ROI>0);
    PSCs_NORDIC=PSCs_NORDIC(idx,:);
    PSCs_noNORDIC=PSCs_noNORDIC(idx,:);

    %Remove voxels outside depthmap:
    idx_resample=find(depthmap>0);
    deltas_NORDIC_resample=deltas_NORDIC_resample(idx_resample,:);
    deltas_noNORDIC_resample=deltas_noNORDIC_resample(idx_resample,:);
    depthmap=depthmap(idx_resample,1);


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
xlim([-35 20])
ylim([-35 20])
set(gcf,'Color',[1 1 1])
set(gca,'FontSize',25)
sgtitle(sprintf('%s - single-voxel PSC NORDIC vs noNORDIC \n slope = %02f constant = %02f ',ARG.version,b(2),b(1)),'fontsize',15,'fontweight','bold')
hold off

if saveFigs==1
saveas(f2,[ARG.rootDir 'figures/' ARG.version '/' ARG.contrast '_nordicAsFunctionOfNoNORDIC'],'svg')
end


%% Boxplot PSC single trials (averaged across voxels)
%Load .mat files containing single-trial PSCs computed from across-voxel
%averaged timeseries:
tmp=load([ARG.rootDir '/w_noNORDIC/analysis/w_noNORDIC_PSCs_avgTS_' ARG.contrast '.mat']);
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
sgtitle(sprintf('%s - PSC single trials (averaged across voxels)',ARG.version),'fontsize',15,'fontweight','bold')
ylabel('PSC')
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gca,'FontSize',25)
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
hold off

if saveFigs==1
saveas(f3,[ARG.rootDir 'figures/' ARG.version '/' ARG.contrast '_boxplotSingleTrials'],'svg')
end


%% Get layer profiles
stepsize=0.1;
lower_depth=0.05;
upper_depth=0.95;
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
set(gca,'FontSize',25)
sgtitle(sprintf('%s - Laminar profiles',ARG.version),'fontsize',20,'fontweight','bold')
%legend('NORDIC','noNORDIC','location','northwest')
if ARG.contrast=='VASO'
ylim([0 0.02])
elseif ARG.contrast=='BOLD'
ylim([0 65])
end
hold off

if saveFigs==1
saveas(f6,[ARG.rootDir 'figures/' ARG.version '/' ARG.contrast '_layerProfiles'],'svg')
end




end
