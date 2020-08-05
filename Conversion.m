sNums = 9:10:8949; %replace 1000 with the final snapshot number
newNums = 10:10:8950;


for i = 1:length(sNums)
    %load the image
    im = imread([num2str(sNums(1)),'.png']);
    imtemp = im(300:500,300:500,:);
    name = sprintf('%d.png',newNums(i));
    imwrite(imtemp,name);
end