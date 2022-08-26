function disparityMap = disparity(rect1,rect2)
%DISPARITY calculates the disparity map from two rectified images 
% input rect1,rect2 : left, right rectfied stereo images.
% accepts rgb or grayscale
% output disparityMap : single nxm matrix with disparity values for each
% pixel

% convert images to grayscale
J1 = rgb2gray(rect1);
J2 = rgb2gray(rect2);

% pick dipsarity range
% because the rectification was done using uncalibraded rectification we
% get negative disparity values
disparityRange = [-64 64];

% compute disparity map with semi-global matching
% uniquenessThreshold obtained from triel and error dictates the uniqueness
% threshold for retaining the disparity 
disparityMap = disparitySGM(J1,J2,'DisparityRange',disparityRange,'UniquenessThreshold',20);

% shift disparity range to positive range
disparityMap = disparityMap - min(disparityMap,[],"all");

% filter salt and pepper noise 
% disparity values that are very localized and therefore unreliable
disparityMap = medfilt2(disparityMap,[3 3]);

% opening and closing to close large areas with same disparity under the
% assumption that disparity values are probably similar in very near
% proximity
disparityMap = imopen(disparityMap,strel("square",10));
disparityMap = imclose(disparityMap,strel("square",10));

% replace NaN values or unreliable disparity values with zeros
disparityMap(isnan(disparityMap)) = 0;

% fill holes in objects on the map
disparityMap = imfill(disparityMap,'holes');
end

