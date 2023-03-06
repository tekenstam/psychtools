clear all;close all;

while 1
    prompt='Enter your participant number (e.g. student ID): ';
    subID=input(prompt,'s');
    if isnan(str2double(subID))
        fprintf('Please enter a valid integer number.\n\n');
    else
        break
    end
end

% Run the actual experiment:
result=runMovieRating(str2double(subID));
