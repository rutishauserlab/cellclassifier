
function  [classLabel,cellType]=classifyEAP(metricMatrix,ekgdata);
% metricMatrix=[amp, hw, tpw, rep, hw MI, tpw MI, rep MI, AMP~HW,
% AMP~TPW, AMP~REP;
% ekgdata=1 if ekg is available, 0 otherwise.

load('eap_svm_classifiers.mat'); %load the classifier

% scale the EAP metrics to the distribution of values in our dataset
for j=1:length(metricMatrix);
    metVal=metricMatrix(j);
    if metVal<scale_NS_BS(1,j);
        metVal=scale_NS_BS(1,j);
    elseif metVal>scale_NS_BS(2,j);
        metVal=scale_NS_BS(2,j);
    end
    metVal=(metVal-scale_NS_BS(1,j))./(scale_NS_BS(2,j)-scale_NS_BS(1,j));
    scaledVal(j)=(metVal-scale_NS_BS(3,j))/scale_NS_BS(4,j);
end

% NS vs. BS classifer
for j=1:1000; % classifier is composed of 1000 classifers trained and tested on different subsets of data, get the result for each of these classifeirs
    [labelTest] = predict(expClass_NS_BS(j).svmModel,scaledVal(2:4));
    allClassExp(j)=double(labelTest);
end
for j=1:2; % get probability of the classifiers classifying as NS or BS
    probExp(j)=length(find(allClassExp==j))/1000;
end
classLabel=[median(allClassExp)  probExp ];
if classLabel(1)==1;
    cellType='NS';
elseif classLabel(1)==2;
    cellType='BS';
end

% BS1 vs. B2 classifer
if ekgdata==1 && classLabel(1)==2; % if ekgdata is available and the cell was classified as BS
    for j=1:1000; % classifier is composed of 1000 classifers trained and tested on different subsets of data, get the result for each of these classifeirs
        [labelTest] = predict(expClass_NS_BS(j).svmModel,scaledVal(2:4));
        allClassExp(j)=double(labelTest);
    end
    for j=1:2; % get probability of the classifiers classifying as BS1 or BS2
        probExp2(j)=length(find(allClassExp==j))/1000;
    end
    classLabel=[classLabel, median(allClassExp),  probExp ];
    if classLabel(4)==1;
        cellType='BS1';
    elseif classLabel(4)==2;
        cellType='BS2';
    end
end

