sNums = 9:10:8949;
newNums = 10:10:8950;
counter = 1;
videoTest = VideoReader('P3071-part1-Test.mp4'); %read from a video

while hasframe(videoTest)
    imgVideo = readFrame(videoTest);
    imgPNG = imread([num2str(newNums(counter)),'.png']); %read specified png
    imageThresh = imgVideo(300:500,300:500,:); %take slice from frame
    imageThresh(imageThresh<0) = 0; %any value less than 0 becomes 0
    imageThresh(imageThresh>255) = 255; %any value greater than 255 becomes 255
    
    
