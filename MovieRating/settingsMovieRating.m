%%
%% Settings for change blindness experiment
%% Change these to suit your experiment!
%%

% Add a directory paths to the list to support variations of where the stimuli groups are located.
% This is used to support multiple computers/installations with different locations of stumuli files.
directoryList{1}='/Users/jackgrinband/Dropbox/expts/movie_rating/';
directoryList{2}='/Users/jack/Dropbox/expts/movie_rating/';
directoryList{3}='/Users/annikaekenstam/Dropbox/Stimuli/';
directoryList{4}='/Users/corelabuser/Dropbox/Stimuli/scripts/';
directoryList{5}='/Users/corelabuser/Dropbox/Stimuli/';

%% Configure the groups of movie stimuli that the experiment will iterate through.
%% Each group is a directory in the path containing movie files.
groupList = ["disgust","fear","happy","sad"];
% groupList = ["test"];

%set playback volume of movie audio (0 is mute, 1.0 == 100% audio volume).
soundvolume=0;
%set playback rate of movie:
playbackRate=1;

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

%set default values for input arguments (for testing only!)
if ~exist('subID','var')
    subID=999999;
end
