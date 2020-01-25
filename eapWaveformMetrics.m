% This function calculates metrics of the mean EAP
%
% sMetric=eapWaveformMetrics(spikeWave, troughTime, sRate);
%
% INPUT
% spikeWave: a vector with spike waveform
% troughTime: the time that the spike trough/extremum occurs in the waveform
% sRate: the sampling rate of the waveform in kHz
%
% OUTPUT
% sMetric: a structure that contains the spike amplitude (AMP), half-width (HW),
% trough-to-peak width (TPW), repolarization time (REP)
%
% Clayton Mosher, 05/17/19, Rutishauser Lab, clayton.mosher@cshs.org

function sMetric=eapWaveformMetrics(spikeWave, troughTime, sRate);

% --- EXTREMUM AMPLITUDE --- the amplitude of the EAP trough
tempTrough=spikeWave(troughTime-3:troughTime+3); % take 3 samples before and after the spike extremum
usTempTrough=interp1([1:7],tempTrough,[1:0.01:7],'spline'); % spline interpolate theses samples at 100 x the sampling rate to identify EAP extremum
sMetric.extremAmp=abs(min(usTempTrough)); % the extremum amplitude is value of the up-sampled EAP trough
shiftTrough=(find(usTempTrough==min(usTempTrough))-301)/100; % the time of the extremum trough for the upsampled signal

% --- HALF WIDTH --- the duration of time the EAP trough exceeds
% half the extremum amplitude
halfAmplitude=-sMetric.extremAmp/2; % calculate the half  value of the extremum amplitude
firstCrossing=find(spikeWave(1:troughTime-1)>halfAmplitude & spikeWave(2:troughTime)<halfAmplitude,1,'last'); % find the timepoint when the spike reaches half-amplitude
secondCrossing=find(spikeWave(troughTime:end-1)<halfAmplitude & spikeWave(troughTime+1:end)>halfAmplitude,1)+troughTime-1; %find the timepoint when the spike returns to half-amplitude
zeroTime1=interp1(spikeWave([firstCrossing, firstCrossing+1]),[0 1],halfAmplitude); % fine tune the first crossing time by interpolating
zeroTime2=interp1(spikeWave([secondCrossing, secondCrossing+1]),[0 1],halfAmplitude); % fine tune the second crossing time by interpolating
halfStart=zeroTime1+firstCrossing; % the time point when the EAP first reaches the half amplitude value
halfEnd=zeroTime2+secondCrossing; % the time point after the EAP has reached its maximum trough and returns to the half-amplitude value
sMetric.widthHW=(halfEnd-halfStart)/sRate; % the half width time, scaled by the sampling rate
sMetric.timeLines=[halfStart, halfEnd]; % record the half width start and end times
sMetric.horizonLines=[halfAmplitude]; % record the half width start and end times

% --- TROUGH-to-PEAK WIDTH --- the time from the EAP trough to the EAP peak
[peakValue,peakTimes] = findpeaks(spikeWave(troughTime+1:end)); % find all of the local peaks after the spike trough/extremum
derSpike=diff(spikeWave); % sometimes there is not a well definied peak, in this case we calculate the first inflection point. here calculate the first derivative
[peakValue2,peakTimes2] = findpeaks(-derSpike(troughTime+1:end)); % identify troughs in the first derivative, i.e., the ascending inflection points
peakValue2=spikeWave(peakTimes2+troughTime); % calculate the magnitude of the EAP at the inflection points
peakValue=[peakValue, peakValue2]; % concatentate the peak and inflection point values
peakTimes=[peakTimes, peakTimes2]; % concatenat the peak and inflection point times
[n,ix]=sort(peakValue,'descend'); % sort the magnitude of the peak / inflection values
peakTimes=peakTimes(ix); % sort the magnitude of the peak / inflection times
peakValue=peakValue(ix); % sort the magnitude of the peak / inflection values
if ~isempty(peakTimes);
    sMetric.widthTP=(peakTimes(1)-shiftTrough)/sRate; % identify the peak / inflection point with the largest magnitude, this is the peak time and gives the trough-to-peak width, adjust for the trough time detected with upsampled EAP
    sMetric.timeLines=[sMetric.timeLines, peakTimes(1)+troughTime+1]; % record the time of the EAP peak
else
    sMetric.widthTP=nan; % if no peak or infleciton point is found, then trough-to-peak width cannot be calculated, set value to nan
    sMetric.timeLines=[sMetric.timeLines, nan]; % record the time of the EAP peak
end

% --- REPOLARIZATION TIME  --- the time lapse between the EAP peak and the
halfRepCross=nan; % now we'll determine the time when the EAP returns to half its hyperpolarized value, set to NaN to initialize
if (peakTimes(1)+troughTime)<256-3; % if the peak from the trough-to-peak calculation is not too close to the end of the EAP window (within 3 samples)
    temps=spikeWave(troughTime+(peakTimes(1)-3:peakTimes(1)+3)); %  get +/- 3 samples around the EAP peak
    tt=interp1([1:7],temps,[1:0.01:7],'spline'); % interpolate the EAP peak to get a better estimate of the peak time
    shiftPeak=(find(tt==max(tt))-301)/100; % shift the original peak time by this amount, the time when the interpolated EAP is at its peak
    sMetric.widthTP=sMetric.widthTP+shiftPeak/sRate; % update the TP width value with the higher resolution peak value
    
    hyperVal=max(tt)/2; % calculate half the value of the EAP peak, the hyperpolarized value
    sMetric.horizonLines=[sMetric.horizonLines, hyperVal, hyperVal*2]; % record the repolarization amplitude
    if hyperVal>0; % if this value is greater than zero, then the EAP hyperpolarized
        trigTime=peakTimes(1)+troughTime+1; % we will look for the timepoint after the peak
        halfRepCross=find(spikeWave(trigTime:end-1)>hyperVal & spikeWave(trigTime+1:end)<hyperVal,1)+trigTime-1; %find the timepoint when the spike returns to half its hyperpolarized value
        if isnan(halfRepCross); % if the time of half hyperpolarization was not found
            halfRepCross=length(spikeWave); % assign the value to be the end of the waveform
        elseif isempty(halfRepCross); % if the time of half hyperpolarization was not found
            halfRepCross=length(spikeWave); % assign the value to be the end of the waveform
        end
    end
else % if the EAP peak occurs at the end of the waveform window, then the repolarization time can't be calculated
    halfRepCross=length(spikeWave); % set repolarization time to the length of the window
end
if halfRepCross<=254; % if the half repolarization time is not at the end of the window
    zeroTime=interp1(spikeWave([halfRepCross, halfRepCross+1]),[0 1],hyperVal); % fine tune the time with interpolation
else
    zeroTime=0; % otherwise don't fine tune the time
end

repolTime=(halfRepCross+zeroTime-peakTimes(1)-shiftPeak-troughTime)./sRate; % calculate the repolarization time, accounting for shifts in the peak
sMetric.repolTime=repolTime; % record the repolarization duration
sMetric.timeLines=[sMetric.timeLines, halfRepCross]; % record the time repolarization
sMetric.timeLines=(sMetric.timeLines-95)/sRate; % calculate time values in milliseconds
