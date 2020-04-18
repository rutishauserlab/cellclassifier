
function [modIndex,removeNoise,allCorr,allLinMod]=fitCardiacModulation(radBins, phaseMetricMatrix, metricNames, plotOn,plotpos);
for k=1:size(phaseMetricMatrix,1);
    if (length(find(isnan(phaseMetricMatrix(k,:))))/length(phaseMetricMatrix(k,:)))<0.8
        Arlowess = smooth(phaseMetricMatrix(k,:),'rlowess',1)';
        removeNoise(k,:)=Arlowess;
        scaledMetricPre=phaseMetricMatrix(k,:)./nanmean(Arlowess); % scale the metric to the mean value, so we can calculate percent changes
        scaledMetric=Arlowess./nanmean(Arlowess); % scale the metric to the mean value, so we can calculate percent changes
        probMetric=(Arlowess-min(Arlowess)); % subtract minimum and divide by sum to create a "probability distribution" which will be used to detect mean phase for circular-linear fit
        probMetric=probMetric./nansum(probMetric);
        killnan=find(~isnan(scaledMetric));
        meanPhase=circ_mean(radBins(killnan),probMetric(killnan),2); % determine the pahse with the highest value for that metric
        if meanPhase<0; % if the phase is negative
            meanPhase=2*pi+meanPhase; % wrap around and put the phase in 0-2pi terms
        end
        uni=unique(scaledMetric);
        if any(isnan(uni));
            uni(isnan(uni))=[];
            uni(end+1)=nan;
        end
        if length(uni)~=1
            mdl=fitlm(cos(radBins(killnan)-meanPhase),scaledMetric(killnan)); % fit a circular-linear model to the modulated data, radbins is the phase for each bin of data
            modIndex(k,1)=mdl.Coefficients{2,1}; % record the modulation index, the slope of the cosine function
            modIndex(k,2)=mdl.Coefficients{2,4}; % record teh p-value of the modulation index
            modIndex(k,3)=meanPhase; % the phase of modulation
            modIndex(k,4)=mdl.Rsquared.ordinary; % record teh p-value of the modulation index
        else
            modIndex(k,1)=0; % record the modulation index, the slope of the cosine function
            modIndex(k,2)=0; % record teh p-value of the modulation index
            modIndex(k,3)=nan; % the phase of modulation
            modIndex(k,4)=0;
        end
        
        allScale(k,:)=scaledMetric;
        if plotOn==1;
            
            cak=k;
            subplot(plotpos(k));
            plot(radBins, scaledMetricPre,'-k','LineWidth',2);
            hold on;
            plot(radBins, mdl.Coefficients{1,1}+mdl.Coefficients{2,1}*cos(radBins-meanPhase),'-r','LineWidth',2);
            %   plot([meanPhase, meanPhase],[0 2],'--r');
            title({metricNames{k};['MI=',num2str(modIndex(k,1)),', (p=',num2str(modIndex(k,2)),',R2=',num2str(modIndex(k,4)),')']});
            xlabel('cardiac phase (rad)');
            ylabel('% change');
            axis tight;
        end
        
    else
        removeNoise(k,:)=nan(1,size(phaseMetricMatrix,2));
        modIndex(k,1)=nan; % record the modulation index, the slope of the cosine function
        modIndex(k,2)=nan; % record teh p-value of the modulation index
        modIndex(k,3)=nan; % the phase of modulation
        modIndex(k,4)=nan;
    end
end

linCorrVals=[]; % create a variable that will hold information about the correlations
caca=0;
for k=1:size(phaseMetricMatrix,1);
for j=k+1:size(phaseMetricMatrix,1);
    scaledMetric1=removeNoise(k,:)./nanmean(removeNoise(k,:)); % scale the first metric by the mean
    scaledMetric2=removeNoise(j,:)./nanmean(removeNoise(j,:)); % scale the second metric by the mean
    eso=corrcoef(scaledMetric1,scaledMetric2);
    caca=caca+1;
    allCorr(caca)=eso(2,1);
    
    modo=fitlm(scaledMetric1,scaledMetric2);
    allLinMod(caca,1)=modo.Coefficients{2,1};
    allLinMod(caca,2)=modo.Coefficients{2,4};
end
end


