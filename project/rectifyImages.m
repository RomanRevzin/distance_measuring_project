function [I1Rect,I2Rect,img] = rectifyImages(I1,I2)
%RECTIFYIMAGES performes stereo image rectification using matching detected SURF
%points in both images, calculating the fundumental matrix and applying the
%affine transfromatrion retained from it on both images.
% input I1,I1: left, right stereo images.
% accepts rgb or grayscale
% output I1Rect,I2Rect : rectified images I1,I2 respectfully 
%        img : 3D anaglyph from images with matching points
%  the function requires at least 8 matching points in order to return a
%  result.

% convert images to grayscale
I1gray = rgb2gray(I1);
I2gray = rgb2gray(I2);

% detect points of interest on both pictures using SURF algorithm
% metric threshold is set to 2000 from trial and error.
% represents strongest feature threshold (the larger the threshold less
% points are found)
blobs1 = detectSURFFeatures(I1gray, 'MetricThreshold', 2000);
blobs2 = detectSURFFeatures(I2gray, 'MetricThreshold', 2000);

% extracе valid points with their features from image
[features1, validBlobs1] = extractFeatures(I1gray, blobs1);
[features2, validBlobs2] = extractFeatures(I2gray, blobs2);

% find corresponding pairs of indexes in both feature arrays
% using sum of absolute differences 
% metric threshold represents the percent of the distance from a perfect
% match
indexPairs = matchFeatures(features1, features2, 'Metric', 'SAD', ...
  'MatchThreshold', 5);

% get corresponding pixels of both images
matchedPoints1 = validBlobs1(indexPairs(:,1),:);
matchedPoints2 = validBlobs2(indexPairs(:,2),:);

% get estimadted fundamental matrix for projection onto the same plain
% using random sample consensus method with 10000 itterations 
% distance threshold and confidance used for RANSAC algorithem wich also
% requires at least 8 points
[fMatrix, epipolarInliers, status] = estimateFundamentalMatrix(...
  matchedPoints1, matchedPoints2, 'Method', 'RANSAC', ...
  'NumTrials', 10000, 'DistanceThreshold', 0.1, 'Confidence', 99.99);

% check if there are enough points to perform rectification if epipole is
% in image (using parallel cameras the epiples should be outside of images)
if status ~= 0 || isEpipoleInImage(fMatrix, size(I1)) ...
  || isEpipoleInImage(fMatrix', size(I2))
  error(['Either not enough matching points were found or '...
         'the epipoles are inside the images. You may need to '...
         'inspect and improve the quality of detected features ',...
         'and/or improve the quality of your images.']);
end

% get corresponding points to build visualization
inlierPoints1 = matchedPoints1(epipolarInliers, :);
inlierPoints2 = matchedPoints2(epipolarInliers, :);

% disallow showing created figures
set(0,'DefaultFigureVisible','off')
% returns handler, which has no arrows on the image
% also, opens figure, which is suppresed by previous
showMatchedFeatures(I1, I2, inlierPoints1, inlierPoints2);  
% save axes as image for passing image with arrows
img = frame2im(getframe(gca));
% close invisible figure
close(gcf)
% restore default behaviour
set(0,'DefaultFigureVisible','on')

% get projective transformations of non calibrated stereo images 
% for rectification
[t1, t2] = estimateUncalibratedRectification(fMatrix, ...
  inlierPoints1.Location, inlierPoints2.Location, size(I2));

% perform rectification of stereo images
tform1 = projective2d(t1);
tform2 = projective2d(t2);
[I1Rect, I2Rect] = rectifyStereoImages(I1, I2, tform1, tform2);
end