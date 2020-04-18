
function cutVector=cutDataVec(dataVec,trigger,preStim,postStim);

cutVector=zeros(length(trigger),preStim+postStim+1);

roundIdx=[-preStim:1:postStim];
roundIdx=repmat(roundIdx,length(trigger),1);
roundTimes=repmat(trigger,1,preStim+1+postStim)+roundIdx;

rowSub=repmat([1:length(trigger)]',1,preStim+1+postStim);
allRows=reshape(rowSub',[1 length(trigger)*(1+preStim+postStim)]);
allCols=repmat([1:(preStim+1+postStim)],1,length(trigger));

resizeTimes=reshape(roundTimes',1,size(roundTimes,1)*size(roundTimes,2));
cutVector(sub2ind(size(cutVector),allRows,allCols))=dataVec(resizeTimes)';


