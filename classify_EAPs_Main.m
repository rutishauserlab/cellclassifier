% Example code for classification of NS, WS1, and WS2 cell types in human
% hippocampus as described in:
%
% Mosher CP, Wei Y, Kaminski J, Nandi A, Mamelak A, Anastassiou CA, & Rutishauser U.
% "Cellular classes in the human brain revealed by heartbeat-related modulation of the
% extracellular action potential waveform"
% Cell Reports(2020)
%
% This code imports the broadband signal, single unit spike times, and
% heartbeat times and calculates standard and motion features of the EAP
% (half-width HW, trough-to-peak width TPW, and repolarization time REP).
% The cell is first classified as NS or WS and, if heartbeat data is
% provided, WS cells are futher subdivied into WS1 and WS2 cell types
%%

clear; % clear workspace
clc; % clear screen

% Load the spike data and heartbeat times.  The .mat file contains the variables:
%
% broadbandSignal: (n x 1) vector of n samples of broadband microwire
% signal at 32 kHz, units microvolts
%
% beatTimes: (n x 1) vector of heartbeat times, rounded to nearest
% millisecond
%
% spikeTimes: {n x 1} cell array where each entry is the spike times for a
% single unit, units are in samples (32 kHz)
%
%
load('exampleData.mat');
ekgdata=1; % if ekgdata=1 then ekg data is available and will classify all cell types (NS, BS1, BS2).  If ekgdata=0 only classify NS vs. BS

%% high pass filter the broadband signal
filteredSignal=hp_filter_data(broadbandSignal); % highpass filter the broadband signal


%% extract the EAPs and calculate the mean EAP
unitID=2;; % the index of the single unit in "spikeTimes" to classify
EAPS=cutDataVec(filteredSignal,spikeTimes{unitID},24, 59); % extract the EAPs around each spike time
upEAPs=upsampleSpikes(EAPS); % upsample the EAPs to 256 samples at 100 kHz
[upEAPs,newTimestamps, shifted] = realigneSpikes(upEAPs, spikeTimes{unitID}, 2, 0, 1); % realgin the extremum of the upsampled EAPs
meanEAP=mean(upEAPs);


%% calculate the mean EAP metrics and classify the cell as NS/BS
figure; % open a figure window

troughTime=95; % the time of the EAP trough is 95, defined by spike extraction method
sRate=100; % the EAP has been upsampled to 100 kHz
sMetric=eapWaveformMetrics(meanEAP, troughTime, sRate); % calculate the EAP metrics
metricMatrix=[sMetric.extremAmp, sMetric.widthHW, sMetric.widthTP, sMetric.repolTime];
[classStat,cellType]=classifyEAP(metricMatrix,0);



%% plot the results for the mean waveform and NS/BS classification
waveTimes=([1:256]-troughTime)/100; % the times before and after each EAP trough, for plotting
subplot(2,3,[1 4]); % create a subplot to plot the waveform
plot(waveTimes, meanEAP,'-k','LineWidth',3); axis tight; hold on; % plot the mean EAP
xlabel('time from EAP extremum'); % label the x-axis, EAP time
ylabel('EAP (\muV)'); % label the y-axis EAP microvolt
waveRange=[min(meanEAP), max(meanEAP)];  % the uper and lower limits of the mean EAP, for plotting
timeRange=[waveTimes(1) waveTimes(end)]; % the upper and lower limits of the time, for plotting
plot( timeRange, [0 0],':k','LineWidth',2,'Color',[0.6 0.6 0.6]); % plot the zero line
plot([0 0],[ waveRange(1),0],':b','LineWidth',2); % plot a line at the EAP trough
plot([0 sMetric.timeLines(3)], [0 0],':r','LineWidth',2); % plot the TP-width line
plot([sMetric.timeLines(1) sMetric.timeLines(2)], sMetric.horizonLines(1)*[1 1],':r','LineWidth',2); % plot the HW line
plot( [sMetric.timeLines(3) sMetric.timeLines(3)], [0 waveRange(2)],':b','LineWidth',2); % plot the peak line
plot([sMetric.timeLines(3) sMetric.timeLines(4)], sMetric.horizonLines(2)*[1 1],':r','LineWidth',2); % plot the REP line

if ekgdata==0; % if ekg data is not available, just finish plotting
    title({cellType;['AMP=',num2str(sMetric.extremAmp),' uV',',   HW=',num2str(sMetric.widthHW),' ms'];...
        ['TP=',num2str(sMetric.widthTP),' ms,','   REP=',num2str(sMetric.repolTime),' ms']}); % title with EAP parameters
elseif ekgdata==1; % if ekg data is available
    %% extract the waveform of spikes during cardiac cycle
    spikems=round(newTimestamps/32); spikems(find(spikems<51 | spikems>max(beatTimes)-2001))=[]; % convert spike times to milliseconds
    IBI=diff(beatTimes); % calculated interbeat interval of the heartbeat
    [f,x]=ecdf(IBI); % distribution of IBIs
    lowIBI=x(find(f>0.025,1)); lowlim=lowIBI-mod(lowIBI,10)+10; % determine the minimum interbeat interval
    phaseBinsLap=[-20:10:lowlim]; % bins to use for cardiac motion
    radBins=2*pi*phaseBinsLap/(20+max(phaseBinsLap)+1); % calculate time bins as circular phases
    
    for j=1:length(phaseBinsLap); % for each 100 ms bin (10 ms overlap), calculate mean EAP and waveform metrics
        cardbin=zeros(1,max(beatTimes)+1000); % matrix filled with zeros duration of recording
        idx=round(reshape(beatTimes+phaseBinsLap(j)+[-50:50],length(beatTimes)*101,1)); % identify all time points in recording that are at a particular cardiac phase
        cardbin(idx)=1; % label these time points in experiment with 1
        esos=find(cardbin(spikems)==1); % find all spikes that occur at these time points
        binnedWave(j,:)=nanmean(upEAPs(esos,:)); % calculate the average EAP in that bin
        phaseMetricStructRaw=spikeWaveMetrics(binnedWave(j,:),troughTime,sRate,0); % calculate the spike metrics for the average waveform in each spike bin
        waveMetricMatrixRaw(:,j)=cell2mat(struct2cell(phaseMetricStructRaw)); % convert the structure to a matrix, each row of the matrix is a metric, each column a phase bin
        
    end
    plotidx=[2 3 5 6]; % subplot idxs for position to plot each feature modulation
    for k=1:4;
        plotpos(k)=subplot(2,3,plotidx(k)); % get subplot posiitons
    end
    metricNames=fieldnames(phaseMetricStructRaw); % extract the fields of the structure, the metric names, to be used when plotting data later
    [modIndex, removeNoise,allCorr,allLinMod]=fitCardiacModulation(radBins, waveMetricMatrixRaw, metricNames, 1,plotpos); % calculate motion correlation
    metricMatrix=[metricMatrix, modIndex(2:4,1)',allLinMod(1:3,1)']; % combine the standard and movement features
    [classStat,cellType]=classifyEAP(metricMatrix,1); %classify as BS1 or BS2
    subplot(2,3,[1 4]);
        title({cellType;['AMP=',num2str(sMetric.extremAmp),' uV',',   HW=',num2str(sMetric.widthHW),' ms'];...
        ['TP=',num2str(sMetric.widthTP),' ms,','   REP=',num2str(sMetric.repolTime),' ms']}); % title with EAP parameters

end

