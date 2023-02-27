%%
%% Settings for change blindness experiment
%% Change these to suit your experiment!
%%

%set default values for input arguments (for testing only!)
if ~exist('subID','var')
    subID=999999;
end

%% Configure the groups of movie stimuli that the experiment will iterate through.
%% Each group is a directory in the path containing movie files.
% groupList = ["disgust","fear","happy", "sad"];
groupList = ["fear"];

%% Define the maximum and minimum rating assigned to each movie frame.
maxRating=20;
minRating=1;

%% Rating feedback window behavior
lineWidth=6;
dotSize=10;
feedbackWindowHeight=125;
%https://www.w3schools.com/colors/colors_picker.asp
oldDotColor=[255 0 0 255];             % Red (255,0,0)
newDotColor=[255 0 255 255];           % Fuchsia (255,0,255)


