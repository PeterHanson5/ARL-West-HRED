% Phase 1 analysis of snapshot movies, the output of this is a structure
% called "out" which contains image feature metrics

clear out; %just in case you ran this before, clear the output variable for the new run

%change directory to subject directory
subjID = 'S3132';%'P3062'; %which subject to analyze
cd('E:\subject_S3132_faa9c2a4-4a2f-4e25-a3bc-c38886de25fa');

%optional parameters:
flag_eyepos = 2; %1 uses mean raw position, 2 uses mean fixation location
flag_isplotting = 0;1; %0 is don't plot, 1 is do plot figures for quality checks/demos

%check if v has already been loaded into memory, if not, load it
%v is the video structure
if ~exist('v')
    v=VideoReader([subjID, '-Video.mp4']);
end

%check if ilab structure has been loaded for this subject, I preloaded ilab
%structures onto my local machine, so you might replace lines below to create
%ilab structures on the fly, e.g. using hid_BuildILAB
if ~exist('ilab')
    %load(['Live_idata_',subjID,'.mat']);
    %ilab = Live.ilab;
    ilab = hid_BuildILAB('E:\subject_S3132_faa9c2a4-4a2f-4e25-a3bc-c38886de25fa');
    ilab = find_blinks(ilab);
    ilab = eye_detectmovements(ilab);
    clear Live
    
    %create clean pupil signal with linear interpolation of blinks
    ilab = create_EyeSize_clean(ilab);
        
end

%create vector of fixation locations for alternative method of analysis
FixX = NaN(size(ilab.EyeTime)); %initialize vector full of NaNs
FixY = NaN(size(ilab.EyeTime)); %for x and y positions
for f = 1:size(ilab.Fixations,1) %loop through all fixations
    %get indices of start and end of this fixation
    idx_start = ilab.Fixations(f,4);
    idx_end = ilab.Fixations(f,5);
    FixX(idx_start:idx_end) = ilab.Fixations(f,2); %replace all values with the X fixation location (2nd column)
    FixY(idx_start:idx_end) = ilab.Fixations(f,3); %Y fixation location is 3rd column
end


if flag_isplotting
    %lets plot x,y gaze location by raw data and by mean fixation
    %you may need to zoom in on these plots to see the overlay
    figure;
    subplot(1,2,1); %plot x dimension on left subplot
    plot(ilab.EyeTime,ilab.EyePosX,'r'); hold on;
    plot(ilab.EyeTime,FixX,'b');
    legend('raw','mean fixation');
    title('X position')
    
    subplot(1,2,2); %plot y dimension on right subplot
    plot(ilab.EyeTime,ilab.EyePosY,'r'); hold on;
    plot(ilab.EyeTime,FixY,'b');
    legend('raw','mean fixation');
    title('Y position')
end


%intialize time at first frame of video object
v.CurrentTime=0;

ssidx = -1; %this is the snapshot index, used to track which frame is being indexed
%will always add 10, so starting at -1 will actually start at frame 9, then
%19, 29, etc.

%% MAIN LOOP: we will use a while loop to loop through all frames up to video duration
output_cntr =0; %initialize the counter for output data structure
load HID_gammas_clut

while v.CurrentTime <= v.Duration
    ssidx = ssidx + 10; %increment snapshot index by 10
    if mod(output_cntr,10)==0
        display([subjID, ': ',num2str((v.CurrentTime./v.Duration)*100,2),' % complete']);
    end
    
    %tempimg is a temporary variable to store image on this frame
    %using readFrame will automatically increment the video object to the
    %next frame (v.currentTime is auto incremented by 1/v.FrameRate)
    tempimg = v.readFrame;
    
    %seperate RGB channels and convert to double for later analysis
    %it is here we can also apply the fitted models to make adjustments to
    %each channel (e.g. mp4 compression artifacts), and to apply screen
    %gamma adjustment
    tempimgR = double(tempimg(:,:,1)); %just the red channel for later processing
    tempimgG = double(tempimg(:,:,2)); %just the green channel
    tempimgB = double(tempimg(:,:,3)); %just the blue channel
    
    %apply luminance models
    
    
    %% section for future code to make gamma, compression adjustments
    tempimgR = gammas.clut.R(tempimgR+1);
    tempimgG = gammas.clut.G(tempimgG+1);
    tempimgB = gammas.clut.B(tempimgB+1);
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    
    %get eye position for this frame
    [~,etidx] = min(abs(ilab.TransformTime(ssidx)-ilab.EyeTime)); %this is eyetime index and it is the correct time point to index in ilab.EyeTime
    
    %iX and iY will store x,y fixation position of this frame for analysis and plotting
    if flag_eyepos == 1 %option 1 use raw eye position data, taking the mean of both eyes
        whichEye = 1; %1:2; %this could be eye 1, eye 2 or eye 1:2 to take an average
        iX = nanmean(ilab.EyePosX(etidx,whichEye),2);
        iY = nanmean(ilab.EyePosY(etidx,whichEye),2);
    elseif flag_eyepos == 2 %option 2 uses mean fixation location
        iX = FixX(etidx); %these could be NaN's if snapshot coincides with a saccade
        iY = FixY(etidx);
    end
    
    %round eye position for reference to pixels
    iX = round(iX);
    iY = round(iY);
    
    if flag_isplotting %if you'd like to plot the video frame with x,y overlay
        %redo iX for visualization and overlay purposes
        %raw is plotted with red circle, fixation in blue circle
        iX_raw = nanmean(ilab.EyePosX(etidx,whichEye),2);
        iY_raw = nanmean(ilab.EyePosY(etidx,whichEye),2);
        iX_fix = FixX(etidx); %these could be NaN's if snapshot coincides with a saccade
        iY_fix = FixY(etidx);
        clf; %clear current figure;
        tempimg2 = tempimg; %create a new version of tempimg so we can create a white spot
        %in the image just for visualization and quality check without
        %modifying the original
        tempimg2(round(iY)-4:round(iY)+4,round(iX)-4:round(iX)+4,:) = ones(9,9,3)*255;
        imagesc(tempimg2);
        axis image;
        hold on;
        plot(iX_raw, iY_raw, 'ro','MarkerSize',20)
        plot(iX_fix, iY_fix, 'bo','MarkerSize',20)
        pause(1/20);
    end
    
    %let's write code to extract relevant metrics from the current snapshot image
    %around fixation location (e.g. RGB intensity, etc)
    
    %ok, first let's compute the distance of every image pixel to fixation point
    %let's also only do it if iX and iY are real numbers (not NaNs)
    if ~isnan(iX) && ~isnan(iY)
    output_cntr = output_cntr + 1; %this counter will help keep track of stored data
    [mx,my] = meshgrid(1:v.Width,1:v.Height);
    distMap = sqrt((mx - iX).^2 + (my - iY).^2); %distance map from fixation
    
    out.windowSizes = [50 150 300 500 700 10000]; %you can change these, 10000 is effectively the whole screen
    for w = 1:length(out.windowSizes)
        dist_idx = find(distMap < out.windowSizes(w)); %find pixel indices that are within window size radius
        
        %store computed values in output data structure called "out"
        %compute mean RGB within the window
        out.(['RGBmean_',num2str(out.windowSizes(w))])(output_cntr,1) = nanmean(tempimgR(dist_idx)); %1st column will be Red channel
        out.(['RGBmean_',num2str(out.windowSizes(w))])(output_cntr,2) = nanmean(tempimgG(dist_idx)); %2nd column will be Green channel
        out.(['RGBmean_',num2str(out.windowSizes(w))])(output_cntr,3) = nanmean(tempimgB(dist_idx)); %3rd column will be Blue channel
        
        %also compute median RGB within the window, in case it is better
        out.(['RGBmed_',num2str(out.windowSizes(w))])(output_cntr,1) = nanmedian(tempimgR(dist_idx)); %1st column will be Red channel
        out.(['RGBmed_',num2str(out.windowSizes(w))])(output_cntr,2) = nanmedian(tempimgG(dist_idx)); %2nd column will be Green channel
        out.(['RGBmed_',num2str(out.windowSizes(w))])(output_cntr,3) = nanmedian(tempimgB(dist_idx)); %3rd column will be Blue channel

        %we can add code below to extract other metrics from the window?
        
    end
    %also save time stamps for later analysis
    out.time_index(output_cntr) = etidx;
    out.time_value(output_cntr) = ilab.EyeTime(etidx);
    out.time_ssFrame(output_cntr) = ssidx;
    out.pupilSize(output_cntr,:) = ilab.EyeSize_clean(etidx,:);
    out.fixX(output_cntr,1) = iX;
    out.fixY(output_cntr,1) = iY;
    
    %add code to extract window
    corrWinSize = 700/2;
    
    %initialize RGB slices as nans
%     out.IMGsliceR(:,:,output_cntr) = NaN(corrWinSize*2+1,corrWinSize*2+1);
%     out.IMGsliceG(:,:,output_cntr) = NaN(corrWinSize*2+1,corrWinSize*2+1);
%     out.IMGsliceB(:,:,output_cntr) = NaN(corrWinSize*2+1,corrWinSize*2+1);
    
    %make adustments if window goes off screen
    xstartoff = 1;
    xendoff = corrWinSize*2+1;
    ystartoff = 1;
    yendoff = corrWinSize*2+1;
    xstart = iX-corrWinSize;
    xend = iX+corrWinSize;
    ystart = iY-corrWinSize;
    yend = iY+corrWinSize;
    
    if xstart < 1
        xendoff = corrWinSize*2+1+xstart-1;
        xstart = 1;
    elseif xend > v.Width
        xstartoff = xend-v.Width+1;
        xend = v.Width;
    end
    
    if ystart < 1
        yendoff = corrWinSize*2+1+ystart-1;
        ystart = 1;
    elseif yend > v.Height
        ystartoff = yend-v.Height+1;
        yend = v.Height;
    end
    
    %save R,G,B slices in output structure
    %resize Red channel by factor of 10
    tempslice = NaN(corrWinSize*2+1,corrWinSize*2+1);
    tempslice(ystartoff:yendoff,xstartoff:xendoff) = tempimgR(ystart:yend,xstart:xend);
    tempslice = imresize(tempslice(1:corrWinSize*2,1:corrWinSize*2),[corrWinSize*2/10, corrWinSize*2/10]);
    out.IMGsliceR(:,:,output_cntr) = uint8(tempslice);
    %resize Green channel
    tempslice = NaN(corrWinSize*2+1,corrWinSize*2+1);
    tempslice(ystartoff:yendoff,xstartoff:xendoff) = tempimgG(ystart:yend,xstart:xend);
    tempslice = imresize(tempslice(1:corrWinSize*2,1:corrWinSize*2),[corrWinSize*2/10, corrWinSize*2/10]);
    out.IMGsliceG(:,:,output_cntr) = uint8(tempslice);
    %resize blue channel
    tempslice = NaN(corrWinSize*2+1,corrWinSize*2+1);
    tempslice(ystartoff:yendoff,xstartoff:xendoff) = tempimgB(ystart:yend,xstart:xend);
    tempslice = imresize(tempslice(1:corrWinSize*2,1:corrWinSize*2),[corrWinSize*2/10, corrWinSize*2/10]);
    out.IMGsliceB(:,:,output_cntr) = uint8(tempslice);
    
    
    
    end
    
end

close all;

%at the end here we can choose to plot a few things for quality check, etc
if flag_isplotting
    figure;
    subplot(2,1,1); %must plot in different plots bc values are on different scales right now
    plot(out.time_value,out.pupilSize,'k');
    
    subplot(2,1,2);
    %for checking, let's plot R, G, B means for the largest window size
    plot(out.time_value,out.(['RGBmean_',num2str(out.windowSizes(end))])(:,1),'r'); hold on;
    plot(out.time_value,out.(['RGBmean_',num2str(out.windowSizes(end))])(:,2),'g');
    plot(out.time_value,out.(['RGBmean_',num2str(out.windowSizes(end))])(:,3),'b');
    
end

%save the data in local subject directory
save([subjID,'_LUM_out.mat'],'out','-v7.3');