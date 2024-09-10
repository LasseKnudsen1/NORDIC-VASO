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

    %Load and prepare run-wise MOCO files:
    for run=1:numel(ARG.runs)
    tmp_moco_NORDIC{run}=spm_read_vols(spm_vol(ARG.pMoco_NORDIC{run}));
    tmp_moco_noNORDIC{run}=spm_read_vols(spm_vol(ARG.pMoco_noNORDIC{run}));

    %reshape to vector format and get rid of potential noiseVolumes:
    s=size(tmp_moco_noNORDIC{run});
    tmp_moco_NORDIC{run}=reshape(tmp_moco_NORDIC{run}(:,:,:,1:ARG.num_vol),s(1)*s(2)*s(3),ARG.num_vol); %make sure potential noise-volumes aren't included
    tmp_moco_noNORDIC{run}=reshape(tmp_moco_noNORDIC{run}(:,:,:,1:ARG.num_vol),s(1)*s(2)*s(3),ARG.num_vol);

    %Remove voxels outside ROI:
    tmp_moco_NORDIC{run}=tmp_moco_NORDIC{run}(idx,:);
    tmp_moco_noNORDIC{run}=tmp_moco_noNORDIC{run}(idx,:);
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


%% PSC analysis from moco files 
%Prepare files:
for run=1:numel(ARG.runs)
    %Change to double format instead of cell:
    TS_NORDIC(run,:,:)=tmp_moco_NORDIC{run};
    TS_noNORDIC(run,:,:)=tmp_moco_noNORDIC{run};
    %Get rid of first non-steady state volume (set equal to second volume)
    TS_NORDIC(run,:,1)=TS_NORDIC(run,:,2);
    TS_noNORDIC(run,:,1)=TS_noNORDIC(run,:,2);
    %Get difference timeseries:
    difTS_moco(run,:,:)=TS_NORDIC(run,:,:)-TS_noNORDIC(run,:,:);
end

%Get voxel-averaged timeseries:
for run=1:numel(ARG.runs)
voxAvg_TS_NORDIC(run,:)=squeeze(mean(TS_NORDIC(run,:,:),2));
voxAvg_TS_noNORDIC(run,:)=squeeze(mean(TS_noNORDIC(run,:,:),2));
end

%Get mean across all rest and all task volumes in each run:
num_blocks=ARG.num_blocks;
discardFirstVols=ARG.discardFirstVols;
for run=1:numel(ARG.runs)
lower=discardFirstVols+1;
upper=ARG.num_TRperBlock;
tmpRest_NORDIC=[];
tmpRest_noNORDIC=[];
tmpOn_NORDIC=[];
tmpOn_noNORDIC=[];
for block=1:num_blocks
    if mod(block,2)==1 %odd blocks
        tmpRest_NORDIC=[tmpRest_NORDIC voxAvg_TS_NORDIC(run,lower:upper)];
        tmpRest_noNORDIC=[tmpRest_noNORDIC voxAvg_TS_noNORDIC(run,lower:upper)];
    elseif mod(block,2)==0 %Even blocks
        tmpOn_NORDIC=[tmpOn_NORDIC voxAvg_TS_NORDIC(run,lower:upper)];
        tmpOn_noNORDIC=[tmpOn_noNORDIC voxAvg_TS_noNORDIC(run,lower:upper)];
    end
    lower=lower+ARG.num_TRperBlock;
    upper=upper+ARG.num_TRperBlock;
end
restTRs_NORDIC(run,:)=tmpRest_NORDIC;
restTRs_noNORDIC(run,:)=tmpRest_noNORDIC;
onTRs_NORDIC(run,:)=tmpOn_NORDIC;
onTRs_noNORDIC(run,:)=tmpOn_noNORDIC;
end

%Get percent change for each run:
if ARG.contrast=="VASO"
    PSC_NORDIC=-100*((mean(onTRs_NORDIC,2)-mean(restTRs_NORDIC,2))./mean(restTRs_NORDIC,2));
    PSC_noNORDIC=-100*((mean(onTRs_noNORDIC,2)-mean(restTRs_noNORDIC,2))./mean(restTRs_noNORDIC,2));
else
    PSC_NORDIC=100*((mean(onTRs_NORDIC,2)-mean(restTRs_NORDIC,2))./mean(restTRs_NORDIC,2));
    PSC_noNORDIC=100*((mean(onTRs_noNORDIC,2)-mean(restTRs_noNORDIC,2))./mean(restTRs_noNORDIC,2));
end
PSC_dif=PSC_noNORDIC-PSC_NORDIC;

%Set color and edge for bargraph plot:
if sum(ARG.version=='c') == 1
    currentColor=[0.4 0.4 0.4];
else
    currentColor=[0.6 0.6 0.6];
end
if sum(ARG.version=='f') == 1
    currentLinestyle='-';
else
    currentLinestyle='--';
end


dotSize=200;
barWidth=0.9;
f7=figure;
subtightplot(2,1,1, [0.08, 0.1], 0.05, 0.3) %[gap_Ver, gap_Hor], margin_T/B, margin_L/R
hold on
plot([0.6 1.4],[mean(PSC_noNORDIC) mean(PSC_noNORDIC)],'r','linewidth',3)
bar(2,mean(PSC_NORDIC),barWidth,'facecolor',currentColor,'linestyle',currentLinestyle,'linewidth',2)
for run=1:numel(ARG.runs)
plot([1,2],[PSC_noNORDIC(run),PSC_NORDIC(run)],'k')
end
scatter(1,PSC_noNORDIC,dotSize,'r')
scatter(2,PSC_NORDIC,dotSize,'k')
xlim([0,3])
%ylim([0 1])
set(gca,'XTick',0)
set(gca,'XTickLabel',"")
set(gcf,'Color',[1 1 1])
set(gca,'FontSize',30)
sgtitle(sprintf('%s',ARG.version),'fontsize',10,'fontweight','bold')
hold off

subtightplot(2,1,2, [0.08, 0.1], 0.05, 0.3) %[gap_V, gap_H], margin_T/B, margin_L/R
hold on
scatter(1.5,PSC_dif,dotSize-50,'filled')
plot([1.1,1.9],[mean(PSC_dif) mean(PSC_dif)],'k',linewidth=3)
xlim([0 3])
if ARG.contrast=="VASO"
ylim([-0.1 0.02])
end
set(gcf,'Color',[1 1 1])
set(gca,'FontSize',30)
set(gca,'XTick',0)
set(gca,'XTickLabel',"")
hold off

f7.Position=[500 0 400 1500]; %[left bottom width height]
if saveFigs==1
saveas(f7,[ARG.rootDir 'figures/' ARG.version '/' ARG.contrast '_PSCdifferences'],'svg')
end



%% Plot run-voxel averaged timeseries:
% %Average timeseries across runs and voxels:
% voxRunAvg_TS_NORDIC=squeeze(mean(TS_NORDIC,[1,2]));
% voxRunAvg_TS_noNORDIC=squeeze(mean(TS_noNORDIC,[1,2]));
% voxRunAvg_difTS_moco=squeeze(mean(difTS_moco,[1,2]));
% 
% %Make paradigm for illustration:
% paradigm=repmat([-0.0005*ones(1,ARG.num_TRperBlock),...
%                   0.0005*ones(1,ARG.num_TRperBlock)],1,ARG.num_blocks/2);

% f8=figure;
% subtightplot(3,1,1, [0.03, 0.1], 0.05, 0.15) %[gap_Ver, gap_Hor], margin_T/B, margin_L/R
% hold on
% plot(voxRunAvg_TS_NORDIC,'r')
% plot(voxRunAvg_TS_noNORDIC,'b')
% if ARG.contrast=="VASO"
% %ylim([0.862 0.884]);
% %set(gca,'YTick',[0.862 0.884])
% %set(gca,'YTickLabel',["0.862" "0.884"])
% %set(gca,'XTick',[0 144])
% %set(gca,'XTickLabel',["" ""])
% end
% set(gcf,'Color',[1 1 1])
% set(gca,'FontSize',5)
% 
% % %Percentage offset change from noNORDIC to NORDIC:
% %baselineOffset=((mean(voxRunAvg_TS_NORDIC)-mean(voxRunAvg_TS_noNORDIC))/mean(voxRunAvg_TS_noNORDIC))*100
% 
% subtightplot(3,1,2, [0.03, 0.1], 0.05, 0.15) %[gap_Ver, gap_Hor], margin_T/B, margin_L/R
% hold on
% plot(voxRunAvg_TS_NORDIC-mean(voxRunAvg_TS_NORDIC),'r')
% plot(voxRunAvg_TS_noNORDIC-mean(voxRunAvg_TS_noNORDIC),'b')
% if ARG.contrast=="VASO"
% %ylim([-0.01 0.01]);
% %set(gca,'YTick',[-0.01 0 0.01])
% %set(gca,'YTickLabel',["-0.01" "0" "0.01"])
% %set(gca,'XTick',[0 144])
% %set(gca,'XTickLabel',["" ""])
% end
% set(gcf,'Color',[1 1 1])
% set(gca,'FontSize',5)
% 
% subtightplot(3,1,3, [0.03, 0.1], 0.05, 0.15) %[gap_Ver, gap_Hor], margin_T/B, margin_L/R
% hold on
% plot(paradigm,'Color',[0.2 1 0.2],'linewidth',3)
% plot(voxRunAvg_difTS_moco-mean(voxRunAvg_difTS_moco),'k')
% if ARG.contrast=="VASO"
% %ylim([-0.0028 0.002]);
% %set(gca,'YTick',[-0.0028 0 0.002])
% %set(gca,'YTickLabel',["-0.0028" "0" "0.002"])
% %set(gca,'XTick',[0 144])
% %set(gca,'XTickLabel',["" ""])
% end
% set(gcf,'Color',[1 1 1])
% set(gca,'FontSize',5)
% sgtitle(sprintf('%s',ARG.version),'fontsize',10,'fontweight','bold')
% 
% f8.Position=[400 0 600 350]; %[left bottom width height]
% if saveFigs==1
% saveas(f8,[ARG.rootDir 'figures/' ARG.version '/' ARG.contrast '_mocoTimeseries'],'svg')
% end

end
