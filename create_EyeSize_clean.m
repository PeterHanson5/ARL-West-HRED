function ilab = create_EyeSize_clean(ilab)

ilab.EyeSize_clean = ilab.EyeSize;
    velThresh(1)=nanstd(ilab.EyeSize(2:end,1)-ilab.EyeSize(1:end-1,1))*4.5;
    velThresh(2)=nanstd(ilab.EyeSize(2:end,2)-ilab.EyeSize(1:end-1,2))*4.5;
    
    pupVel1=[0; ilab.EyeSize(2:end,1)-ilab.EyeSize(1:end-1,1)];
    bad = find(abs(pupVel1)>velThresh(1));
    ilab.EyeSize_clean(bad,1) = NaN;
    
    pupVel2=[0; ilab.EyeSize(2:end,2)-ilab.EyeSize(1:end-1,2)];
    bad = find(abs(pupVel2)>velThresh(2));
    ilab.EyeSize_clean(bad,2) = NaN;
    
    ilab.EyeSize_clean(isnan(ilab.EyeSize_clean))=0;
    ilab.EyeSize_clean(:,1)=blinkinterp(ilab.EyeSize_clean(:,1)',1000,.03,.01,50,75,'linear');
    ilab.EyeSize_clean(:,2)=blinkinterp(ilab.EyeSize_clean(:,2)',1000,.03,.01,50,75,'linear');
    pupisnan=sum(isnan(ilab.EyeSize),1);
    [~,whichEye] = min(pupisnan);
    ilab.EyeSize_clean = ilab.EyeSize_clean(:,whichEye);%nanmean(ilab.EyeSize_clean,2);
    if isnan(ilab.EyeSize_clean(1))
        tid=max(find(isnan(ilab.EyeSize_clean(1:1000))));
        ilab.EyeSize_clean(1:tid)=ilab.EyeSize_clean(tid+1);
    end
    if isnan(ilab.EyeSize_clean(end))
        tid=min(find(isnan(ilab.EyeSize_clean)));
        ilab.EyeSize_clean(tid:end)=ilab.EyeSize_clean(tid-1);
    end