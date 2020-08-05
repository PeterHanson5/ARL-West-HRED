%compare native images to mp4 images

imN = 9:10:8949;
isPlotting = 1;
x = zeros(1,895);
count = 1;

%if the variables don't exist in memory yet, load them
if ~exist('v')
    v=VideoReader('P3071-part1.mp4');
end

if ~exist('n')
    for f=1:length(imN)
    n{f}=imread([num2str(imN(f)),'.png']);
    end
end

%intialize time at first frame of video object
v.CurrentTime=0;

%plotting routine for native vs. mp4 images
if isPlotting
    figure('Position',[20 80 1200 480]);
    for f=1:length(imN)
        %plot native
        subplot(1,3,1);
        imagesc(n{f}); axis image off; title('native');
       
        %plot mp4
        subplot(1,3,2);
        tempimg = v.readFrame;
        imagesc(tempimg); axis image off; title('mp4 image');
       
        %convert to luminance
        lum_n = rgb2ycbcr(n{f}); %first slice in 3rd dim is luminance
        lum_v = rgb2ycbcr(tempimg);
        %compute difference image
        lum_diff = (double(lum_v(:,:,1))-double(lum_n(:,:,1)));
       
        %plot the difference image
        subplot(1,3,3);
        imagesc(lum_diff,[-15 15]); axis image off;
       
        %find percentage of pixels with abs diff less than 13
        %(13/256 = .05, corresponds to 5% difference)
        n5 = length(find(abs(lum_diff)<13))./length(lum_diff(:));
       
        %show percentage in the title
        title([num2str(n5*100,3),'% within 5% delta'])
        x(1,count) = n5*100;
        count = count + 1;
       
        pause(1/v.FrameRate);
        clf
    end
end