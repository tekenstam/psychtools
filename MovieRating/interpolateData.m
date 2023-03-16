function [ subjData ] = interpolateData( videoStruct )
% interpolateData
%   helper function to fill gaps in rating data using interpolation

%normalize rating data to 'maxRating'
%JG: This should not be needed
% maxValue = max(videoStruct.data(:,3));
% maxRating = 20;
% if maxValue > maxRating
%     videoStruct.data(:,3) = normalize(videoStruct.data(:,3), 'range', [ 1 maxRating]);
% end

%fill gaps in rating data using interpolation
secondsPerFrame=1/videoStruct.info.fps;
numFrames=round(videoStruct.info.duration/secondsPerFrame);
xq = (videoStruct.data(1,1):secondsPerFrame:videoStruct.data(1,1)+(secondsPerFrame*(numFrames-1)));
xq = reshape(xq, [], 1);

subjData = interp1(videoStruct.data(:,1), videoStruct.data(:,3), xq);

end

