function depthMap = disparity2depth(base_distance,focal_length, disparityMap)
%DIPARITY@DEPTH convert each disparity value to distance/depth based on 
% camera intrinsic parameters and distance between cameras
% input base_distance : the distance between cameras in length units
%       focal_lenght : the cameras focal length in pixels assuming both images
%           were takin with same camera(type) 
%       disparityMap : stereo images calulated disparity map
% output depthMap : a matrix of same dimentions as disparity map with
%           pixels calculated depth distance
    depthMap = base_distance*focal_length./disparityMap; 
end


