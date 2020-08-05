imageN = zeros(1,895); %size can vary based on subjects
count = 1;
slope = betahat(2,1); %access betahat structure for slope
intercept = betahat(1,1); %access betahat structure for intercept
    
while (count < 896)
    imageN(1,count) = (r_video_mean(1,count) * slope) + intercept; %linear formula to apply, need to replace video_mean for the color you want
    count = count + 1;
end