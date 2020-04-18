% This function calculates 10 spike-waveform metrics
%
% sMetric=spikeWaveMetrics(spikeWave, troughTime, sRate, plotOn);
%
% spikeWave: a vector with spike waveform
% troughTime: the time that the spike trough occurs in the waveform
% sRate: the sampling rate of the waveform in kHz
% plotOn: set to 1 if you want to plot the waveform, 0 otherwise
% sMetric: a structure that contains the various spike metrics
%
% Clayton Mosher, 06/14/18, Rutishauser Lab, clayton.mosher@cshs.org


function sMetric=spikeWaveMetrics(spikeWave, troughTime, sRate, plotOn);

if length(unique(spikeWave))>10;
    
    % --- EXTREMUM AMPLITUDE ---
    
    temps=spikeWave(troughTime-3:troughTime+3);
    tt2=interp1([1:7],temps,[1:0.01:7],'spline');
    apo2=find(tt2==min(tt2))-301;
    shiftTrough=apo2/100;
    
    sMetric.extremAmp=abs(min(tt2)); % the extremum amplitude is the magnitude of spike at the time of the EAP trough
    
    
    % --- HALF WIDTH ---
    halfAmplitude=-sMetric.extremAmp/2; % calculate the half  value of the extremum amplitude
    firstCrossing=find(spikeWave(1:troughTime-1)>halfAmplitude & spikeWave(2:troughTime)<halfAmplitude,1,'last'); % find the timepoint when the spike reaches half-amplitude
    secondCrossing=find(spikeWave(troughTime:end-1)<halfAmplitude & spikeWave(troughTime+1:end)>halfAmplitude,1)+troughTime-1; %find the timepoint when teh spike returns to half-amplitude
    zeroTime1=interp1(spikeWave([firstCrossing, firstCrossing+1]),[0 1],halfAmplitude);
    zeroTime2=interp1(spikeWave([secondCrossing, secondCrossing+1]),[0 1],halfAmplitude);
    halfStart=zeroTime1+firstCrossing;
    halfEnd=zeroTime2+secondCrossing;
    
    sMetric.widthHW=(halfEnd-halfStart)/sRate; % take the time duration and divide by sampling rate to get half-width in ms
    
    % --- TROUGH-to-PEAK WIDTH ---
    derSpike=diff(spikeWave);
    [peakValue,peakTimes] = findpeaks(-derSpike(troughTime+1:end)); % find all of the local peaks after the spike trough/extremum
    peakValue=spikeWave(peakTimes+troughTime);
    [peakValue2,peakTimes2] = findpeaks(spikeWave(troughTime+1:end)); % find all of the local peaks after the spike trough/extremum
    peakValue=[peakValue, peakValue2];
    peakTimes=[peakTimes, peakTimes2];
    
    [n,ix]=sort(peakValue,'descend');
    peakTimes=peakTimes(ix);
    peakValue=peakValue(ix);
    
    eos=1; killo=find(peakValue~=max(peakValue));
    if ~isempty(eos);
        killo=find(peakValue~=max(peakValue));
    else
        killo=find(peakValue<0);
    end
    peakTimes(killo)=[];
    peakValue(killo)=[];
    
    if ~isempty(peakTimes);
        sMetric.widthTP=(peakTimes(1)-shiftTrough)/sRate; % identify the peak with the largest magnitude, this is the peak time and gives the trough-to-peak width
    else
        sMetric.widthTP=nan; % if no peak is found, then trough-to-peak width cannot be calculated, set value to nan
    end
    
    % --- REPOLARIZATION AMPLITUDE ---
    if ~isnan(sMetric.widthTP); %if peak can be detected in trough-to-peak
        repolAmp=spikeWave(troughTime+round(sMetric.widthTP*sRate)); % then calculate the repolarization amplitude as the amplitude at the time of the peak
    else
        repolAmp=0; % else set the repolarization amplitude to zero.
    end
    
    
    % --- AREA ABOVE TROUGH/EXTREMUM ---
    zeroCrossing3=nan;
    if (peakTimes(1)+troughTime)<256-3;
        temps=spikeWave(troughTime+(peakTimes(1)-3:peakTimes(1)+3));
        tt=interp1([1:7],temps,[1:0.01:7],'spline');
        apo=find(tt==max(tt))-301;
        shiftPeak=apo/100;
        
        minuses=max(tt)/2;
        if minuses>0;
            trigTime=peakTimes(1)+troughTime+1;
            zeroCrossing3=find(spikeWave(trigTime:end-1)>minuses & spikeWave(trigTime+1:end)<minuses,1)+trigTime-1; %find the timepoint when the spike returns to zero
            if isnan(zeroCrossing3);;
                zeroCrossing3=length(spikeWave);
            end
            if length(zeroCrossing3)==0;;
                zeroCrossing3=length(spikeWave);
            end
        end
    else
        zeroCrossing3=length(spikeWave);
        shiftPeak=0;
    end
    if zeroCrossing3<=254;
        zeroTime3=interp1(spikeWave([zeroCrossing3, zeroCrossing3+1]),[0 1],minuses);
    else
        zeroTime3=0;
    end
    
    
    
    
    repolTime=(zeroCrossing3+zeroTime3-peakTimes(1)-shiftPeak-troughTime)./sRate;
    sMetric.repolTime=repolTime;
    sMetric.widthTP=sMetric.widthTP+shiftPeak/sRate;
    if plotOn==1;
        plot(spikeWave);
        vline(troughTime);
        vline(troughTime+sMetric.widthTP*sRate);
        vline(troughTime+sMetric.widthTP*sRate+sMetric.repolTime*sRate);
        hline(-sMetric.extremAmp/2);
        hline(minuses);
    end
else
    sMetric.extremAmp=nan;
    sMetric.widthHW=nan;
    sMetric.widthTP=nan;
    sMetric.repolTime=nan;
end
