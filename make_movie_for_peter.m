%open video object
v = VideoWriter('P3071-part1-Test','MPEG-4');
v.FrameRate = 12; %set frame rate
open(v); %open the file so you can write to it

sNums = 10:10:8950; %replace 1000 with the final snapshot number

for i = 1:length(sNums)
    %load the image
    im = imread([num2str(sNums(i)),'.png']);
    %write it to video object file
    writeVideo(v,im);
end

close(v); %close it and it'll save
