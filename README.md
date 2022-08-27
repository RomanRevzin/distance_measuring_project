# Objective

In this project we will demonstrate an application of “Stereo Image Matching”. 

Computer stereo vision is the extraction of 3D information from digital images, such as those obtained by a CCD camera. By comparing information about a scene from two vantage points, 3D information can be extracted by examining the relative positions of objects in the two panels. This is similar to the biological process of stereopsis.

We will strive to automate the process of obtaining a depth map with minimum error from two images captured by a single camera from parallel view points and measured distance.

# Overview
Pre-processing :
<ul>
	<li>Camera calibration -  extracting the cameras intrinsic parameters.</li>
	<li>The images may be taken from two preset cameras or a single camera from a measured distance.</li>
	<li>Image rectification – the projection of the images to a common plane.</li>
</ul>
Processing : 
<ul>
	<li>Disparity Map extraction – find matching pixels in both rectified images and calculate the disparity. </li>
	<li>Disparity Map post-processing – the initial disparity map may contain errors due to wrongly matched pixels or image distortion from lighting or the sort.
	<li>We will try and remove these by filtering and applying Morphological binary operations.</li>
	<li>Disparity to Depth conversion – using the measured values of camera distances(or image distance) and focal length of camera we can calculate the depth from disparity using geometric properties depth=(focal length*base distance)/disparity.</li>
</ul>

# Assumptions
In order to achieve optimal results, the following factors should be minimized :
	<ul>
	<li>Monochromatic uniform objects and few objects(not a lot of changes in the images).</li>
	<li>Image lens distortion </li>
	<li>Uneven lighting </li>
	<li>Images non-overlapping area</li>
	<li>Images of different sizes</li>
	<li>Distance of objects in relation to base distance and focal length</li>
	</ul>
