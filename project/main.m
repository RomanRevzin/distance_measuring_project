clear,clc,close all force;
% main file for testing 

%hold algorithm times
allTimes = zeros(1, 8);


I1 = imread('.\images\GoodOneLeft.jpeg');
I2 = imread('.\images\GoodOneRight.jpeg');

tic 
% image rectification
[rect1, rect2] = rectifyImages(I1,I2);
allTimes(1) = toc;

J1 = rgb2gray(rect1);
J2 = rgb2gray(rect2);   
disparityRange = [-64 64];

tic
% disparity map calculation
disparityMap = disparitySGM(J1,J2,'DisparityRange',disparityRange,'UniquenessThreshold',20);
allTimes(2) = toc;

tic
% shifting disparity range to positive values due to uncalibrated
% rectification
disparityMap = disparityMap - min(disparityMap,[],"all");
allTimes(3) = toc;

tic
% removing errors in disparity map due to faulty algorithm mistakes and
% image distortions
disparityMap = medfilt2(disparityMap,[3 3]);
allTimes(4) = toc;
tic
disparityMap = imopen(disparityMap,strel("square",10));
allTimes(5) = toc;

tic
disparityMap = imclose(disparityMap,strel("square",10));
allTimes(6) = toc;

tic
disparityMap(isnan(disparityMap)) = 0;
allTimes(7) = toc;

tic
disparityMap = imfill(disparityMap,'holes');
allTimes(8) = toc;


figure
imshow(disparityMap,[]);
title('Disparity Map')
colormap jet
colorbar 
% camera and image location values
base_distance = 10;
focal_length = 1300;
depth_map = base_distance*focal_length./disparityMap;
figure
max_dist = 400;
depth_map(depth_map>max_dist)=nan;
imshow(depth_map,[0 400]);
title('Depth Map')
colormap jet
colorbar 
figure
show = zeros(size(J2));
bottom_range = 250;
top_range = 330;
range = find(depth_map < top_range & depth_map > bottom_range);
show(range) = rect2(range);
imshow(show,[])

algLabels = {'rectifyImages','disparitySGM','shiftMean','medfilt2',...
             'imopen', 'imclose', 'isnan', 'imfill'};
times = strcat(string(allTimes)',' s');

t = table(algLabels',strcat(string(allTimes)',' s'),'VariableNames',...
    {'Algorithm Name', 'Execution Time'})

writetable(t, 'executionTime3.csv')
