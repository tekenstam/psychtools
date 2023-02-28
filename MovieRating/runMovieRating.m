function result = runMovieRating(subID)
%Video Stimulus Presentation Program

%% Uncomment this if needed (for testing only!)
% clear all;close all;

% Make sure the script is running on Psychtoolbox-3 (PTB):
AssertOpenGL;

%%
%% Load settings for experiment
%%
settingsMovieRating;

%when working with the PTB it is a good idea to enclose the whole body of your program
%in a try ... catch ... end construct. This will often prevent you from getting stuck
%in the PTB full screen mode
try
    rng('shuffle');			% reset random number generator
    Screen('Screens');

    %add each directory that exists to the path
    for i=1:length(directoryList)
        if exist(directoryList{i},'dir')
            myexpt=directoryList{i};
        end
    end
    addpath(myexpt)

    %% Discover PowerMate dial and keyboard
    devices=PsychHID('Devices');
    for i=1:length(devices)
        findpowermate(i,1)=strcmp(devices(i).product,'Griffin PowerMate');
    end
    for i=1:length(devices)
        findkeyboard(i,1)=strcmp(devices(i).usageName,'Keyboard');
    end
    keyboardIndex=find(findkeyboard==1);
    powermateIndex=find(findpowermate==1);

    deviceId = PsychPowerMate('List');
    if ~isempty(deviceId)
        powerMateExists=1;
        handle = PsychPowerMate('Open',deviceId);
    else
        powerMateExists=0;
    end

    % Background color will be a grey one:
    background=[128, 128, 128];
    myscreen=max(Screen('Screens'));

    % Setup key mapping:
    space=KbName('SPACE');
    esc=KbName('ESCAPE');
    up=KbName('UpArrow');
    down=KbName('DownArrow');

    %===========================================
    % Video parameters

    % Default preload setting:
    preloadSecs = [];
    pixelFormat = [];
    maxThreads = [];
    movieOptions = [];

    win = PsychImaging('OpenWindow', myscreen, [128, 128, 128]);
    [monitorFlipInterval, ~, ~] = Screen('GetFlipInterval', win);
    [winWidth, winHeight] = Screen('WindowSize', win);

    % Calculate feedback window parameters based on screen size
    displayBottomBuffer=(lineWidth*2)+(dotSize/2)+1;
    displayTopBuffer=(lineWidth)+(dotSize/2)+1;
    displayScaleFactor=(feedbackWindowHeight-displayBottomBuffer-displayTopBuffer)/(maxRating-minRating);
    Vstart=winHeight-displayBottomBuffer;
    Vtop=winHeight-feedbackWindowHeight;
    maxDots=round(winWidth/2);                   %number of dots that fit on half the screen


    hz=round(1/monitorFlipInterval);

    Screen('Blendfunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    HideCursor(win);

    shader = [];

    Screen('Flip',win);

    % Use blocking wait for new frames by default:
    blocking = 1;

    % Playbackrate defaults to 1:
    rate=1;

    % Choose 16 pixel text size:
    Screen('TextSize', win, 32);

    %===========================================


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Set up stimuli lists and results file
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    numGroups = length(groupList);     %#ok groupList is defined in settings file
    % Randomize the group list
    randomizedGroups = randperm(numGroups);

    experimentStart=datetime('now','Format','yyyyMMddHHmmss');
    resultsFolder = strcat('results','/',num2str(subID),'/',string(experimentStart));
    if ~exist(resultsFolder, 'dir')
        % Folder does not exist so create it.
        mkdir(resultsFolder);
    end

    for group = randomizedGroups
        %% Display thank you and performance feedback
        DrawFormattedText(win, sprintf('Use the dial to rate the amount of "%s" emotion displayed in the movie.\n\nPress any key to continue...', groupList{group}), 'center', 'center');
        Screen('Flip', win);
        KbWait([], 2); %wait for keystroke

        % Get the image files for the experiment
        movieFolder=[myexpt groupList{group}];

        movieList = dir(fullfile(movieFolder,'*.mov'));
        movieList = {movieList(:).name};
        numTrials = length(movieList);

        % Randomize the trial list
        randomizedTrials = randperm(numTrials);

        for trial = randomizedTrials
            
            [~,trialBaseName,~] = fileparts(movieList{trial});
            resultsFilename=strcat(resultsFolder, '/', 'resultfile_', num2str(subID), '_', '_', groupList{group}, '_', trialBaseName, '.csv');

            moviePath = [movieFolder '/' movieList{trial}];
            fprintf('Loading movie %s ...\n', moviePath);

            % Show title while movie is loading/prerolling:
            DrawFormattedText(win, 'Loading next movie...\n', 'center', 'center', 0);
            Screen('Flip', win);
                    
            % Open movie file and retrieve basic info about movie
            [movie, movieduration, fps, imgw, imgh, ~, ~, ~] = Screen('OpenMovie', win, moviePath, [], preloadSecs, [], pixelFormat, maxThreads, movieOptions);
            fprintf('Movie: %s  : %f seconds duration, %f fps, w x h = %i x %i...\n', moviePath, movieduration, fps, imgw, imgh);
            if imgw > winWidth || imgh > winHeight
                % Video frames too big to fit into window, so define size to be window size:
                dstRect = CenterRect((winWidth / imgw) * [0, 0, imgw, imgh], Screen('Rect', win));
            else
                [dstRect, ~, ~] = CenterRect([0 0 imgw imgh],[0 0 winWidth winHeight]);
                offset=dstRect(2)-round(dstRect(2)*.2);
                dstRect=[dstRect(1) dstRect(2)-offset dstRect(3) dstRect(4)-offset];
            end
            
            % Start playback of movie. This will start
            % the realtime playback clock and playback of audio tracks, if any.
            % Play 'movie', at a playbackrate = 1, with endless loop=1 and
            % 1.0 == 100% audio volume.
            
            Screen('PlayMovie', movie, rate, 0, soundvolume);
            
            t1 = GetSecs;
            
            result=zeros(round(hz*movieduration),5); % initialize 5-column array;
            
            dialPos=0;
            oldPos=0;

            % Infinite playback loop: Fetch video frames and display them...
            counter=0;                           %number of frames displayed and datapoints collected
            while 1

                counter=counter+1;
                % Check for abortion:
                abortit=0;
                [keyIsDown, ~, keyCode] = KbCheck(-1);
                if (keyIsDown==1 && keyCode(esc))
                    % Set the abort-demo flag.
                    abortit=2;
                    break;
                end
                
                if ((abs(rate)>0) && (imgw>0) && (imgh>0))
                    % Return next frame in movie, in sync with current playback
                    % time and sound.
                    % tex is either the positive texture handle or zero if no
                    % new frame is ready yet in non-blocking mode (blocking == 0).
                    % It is -1 if something went wrong and playback needs to be stopped:
                    tex = Screen('GetMovieImage', win, movie, blocking);
                    
                    % Valid texture returned?
                    if tex < 0
                        % No, and there won't be any in the future, due to some
                        % error. Abort playback loop:
                        abortit=2;
                        break;
                    end
                    
                    % Draw the new texture immediately to screen:
                    Screen('DrawTexture', win, tex, [], dstRect, [], [], [], [], shader);
                end
                
                if powerMateExists
                    [~, dialPos] = PsychPowerMate('Get', handle);
                else
                    [keyIsDown, ~, keyCode] = KbCheck(keyboardIndex);
                    %[keyIsDown, ~, keyCode] = KbCheck(-1);
                    
                    if keyIsDown
                        if keyCode(up)
                            dialPos=dialPos-1;
                        elseif keyCode(down)
                            dialPos=dialPos+1;
                        end
                    end
                end

                %% Use currrent dial position relative to old dial position to adjust rating
                diffPos = oldPos - dialPos;
                oldPos = dialPos;
                if counter==1
                    newRating=1;
                else
                    % Adding diffPos makes turning knob to left increase the rating
                    % and to the right decreases the rating. Substracting diffPos
                    % reverses this. This is kinda like the 'Natural scrolling'
                    % mouse setting on Max OS.
                    newRating = result(counter-1, 5) + diffPos;
                end

                %make newRating a value between min and max rating:
                if newRating>maxRating           %maxRating is defined in setting file
                    newRating=maxRating;
                elseif newRating<minRating       %maxRating is defined in setting file
                    newRating=minRating;
                end

                Screen('DrawLine', win, [0 0 0 255], 0, Vtop, winWidth, Vtop, lineWidth);
                Screen('DrawLine', win, [0 0 0 255], 0, winHeight-lineWidth, winWidth, winHeight-lineWidth, lineWidth);
                
                if counter>1
                    % Generate monotonically incrementing xCords for each 'old' rating.
                    % Value series ends at the center of the screen. This is how the
                    % rating feedback graph starts in the center and shifts to the left.
                    temp = (maxDots-counter+1:1:maxDots-1);
                    xCords = reshape(temp,[length(temp),1]);

                    % Create yCords scaled based on the rating.
                    % First, extract the 5th column from the results matrix (temp1)
                    % Next, scale results by dotSize (temp2)
                    % Finally, generate yCords for dot placement based on desired screen placement (yCords)
                    temp1 = result(1:length(xCords),5);
                    temp2 = (temp1(:,:,1)-1)*displayScaleFactor;
                    yCords = Vstart-temp2(:,:,1);

                    %draw old data points:
                    Screen('DrawDots', win, [(xCords)'; (yCords)'], dotSize, oldDotColor);

                end
                %draw new data point:
                ratingCord=Vstart-((newRating-1)*displayScaleFactor);
                Screen('DrawDots', win, [maxDots ratingCord], dotSize, newDotColor);

                % Update display and close the movie frame texture:
                [~, StimulusOnsetTime, ~, ~, ~] = Screen('Flip', win);
                Screen('Close', tex)

                %enter result in matrix
                result(counter,:) = [subID, trial, StimulusOnsetTime, counter, newRating];
                
            end

            % Close the movie object
            Screen('CloseMovie', movie);


            %%
            %% Append result matrix to comma delimited text file after each movie
            %%

            %truncate unused rows in the result matrix: 
            result(counter:end,:) = [];

            %TODO: add cells for group name and trial name

            %write header row for results file
            writecell({'subID','trial','time','counter','rating'},resultsFilename)
            writematrix(result,resultsFilename,'WriteMode','append');

        end
    end

    %% Display thank you and performance feedback
    DrawFormattedText(win, 'Thank you for participating!\n\nPress any key to exit.', 'center', 'center');
    Screen('Flip', win);
    KbWait([], 2); %wait for keystroke

    Screen('Flip', win);
    KbReleaseWait;

    % Close any remaining movie objects
    Screen('CloseAll');

    telapsed = GetSecs - t1;
    fprintf('Elapsed time %f seconds, for %i frames. Average framerate %f fps.\n', telapsed, i, i / telapsed);

    %clean up before exit
    ShowCursor;
    sca; %or sca;
    ListenChar(0);
    %return to olddebuglevel
    % Screen('Preference', 'VisualDebuglevel', olddebuglevel);

catch ME
    % This section is executed only in case an error happens in the
    % experiment code implemented between try and catch...
    Screen('CloseAll');
    ShowCursor;
    sca; %or sca
    ListenChar(0);
    % Screen('Preference', 'VisualDebuglevel', olddebuglevel);

    rethrow(ME);
end
