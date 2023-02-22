function result = runMovieRating(subID)
%Video Stimulus Presentation Program

% Make sure the script is running on Psychtoolbox-3:
AssertOpenGL;

clc;clear all;close all;
Screen('Preference', 'SkipSyncTests', 0);

%set default values for input arguments
if ~exist('subID','var')
    subID=66;
end

%warn if duplicate sub ID
fileName=['MovieRatingSubj' num2str(subID) '.txt'];
if exist(fileName,'file')
    if ~IsOctave
        resp=questdlg({['the file ' fileName 'already exists']; 'do you want to overwrite it?'},...
            'duplicate warning','cancel','ok','ok');
    else
        resp=input(['the file ' fileName ' already exists. do you want to overwrite it? [Type ok for overwrite]'], 's');
    end
    
    if ~strcmp(resp,'ok') %abort experiment if overwriting was not confirmed
        disp('experiment aborted')
        return
    end
end

%when working with the PTB it is a good idea to enclose the whole body of your program
%in a try ... catch ... end construct. This will often prevent you from getting stuck
%in the PTB full screen mode
try
    Screen('CloseAll')
    rand('state',sum(100*clock));			% reset random number generator
    Screen('Screens');


    % Add a computer to the list by indicating where the cyberballrace folder is located.

    directoryList{1}='/Users/jackgrinband/Dropbox/expts/movie_rating/';
    directoryList{2}='/Users/jack/Dropbox/expts/movie_rating/';
    directoryList{3}='/Users/annika/Dropbox/expts/movie_rating/';
    directoryList{4}='/Users/corelabuser/Dropbox/Stimuli/scripts/';
    directoryList{5}='/Users/corelabuser/Dropbox/Stimuli/';

    for i=1:length(directoryList)
        if exist(directoryList{i},'dir')
            myexpt=directoryList{i};
        end
    end

    addpath(myexpt)


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

    moviename=[myexpt 'TM - Angry.mov'];

    fprintf('Loading movie %s ...\n', moviename);

    % Background color will be a grey one:
    background=[128, 128, 128];
    myscreen=max(Screen('Screens'));

    % Setup key mapping:
    space=KbName('SPACE');
    esc=KbName('ESCAPE');
    right=KbName('RightArrow');
    left=KbName('LeftArrow');
    up=KbName('UpArrow');
    down=KbName('DownArrow');
    shift=KbName('RightShift');
    colorPicker=KbName('c');


    %===========================================
    % Video parameters

    indexisFrames=2;
    toTime=100000;
    fromTime=0;
    indexisFrames = 0;
    benchmark = 0;
    async = [];
    preloadSecs = [];
    specialflags = [];
    pixelFormat = [];
    maxThreads = [];
    movieOptions = [];



    win = PsychImaging('OpenWindow', myscreen, [128, 128, 128]);
    [ monitorFlipInterval nrValidSamples stddev ]=Screen('GetFlipInterval', win);

    hz=round(1/monitorFlipInterval);


    [w, h] = Screen('WindowSize', win);
    Screen('Blendfunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    HideCursor(win);

    shader = [];


    Screen('Flip',win);
    iteration = 0;
    abortit = 0;

    % Use blocking wait for new frames by default:
    blocking = 1;

    % Default preload setting:
    preloadsecs = [];
    % Playbackrate defaults to 1:
    rate=1;

    % No mouse color prober/picker by default - Performance impact!
    colorprobe = 0;

    % Choose 16 pixel text size:
    Screen('TextSize', win, 16);

    %===========================================




    fromH=0;
    while (abortit<2)
        
        
        % Show title while movie is loading/prerolling:
        DrawFormattedText(win, ['Loading ...\n' moviename], 'center', 'center', 0, 40);
        Screen('Flip', win);
        
        % Close previously open movie
        % if movie
        %     Screen('CloseMovie', movie);
        % end
        
        % Open movie file and retrieve basic info about movie
        [movie, movieduration, fps, imgw, imgh, ~, ~, hdrStaticMetaData] = Screen('OpenMovie', win, moviename, [], preloadsecs, [], pixelFormat, maxThreads, movieOptions);
        fprintf('Movie: %s  : %f seconds duration, %f fps, w x h = %i x %i...\n', moviename, movieduration, fps, imgw, imgh);
        if imgw > w || imgh > h
            % Video frames too big to fit into window, so define size to be window size:
            dstRect = CenterRect((w / imgw) * [0, 0, imgw, imgh], Screen('Rect', win));
        else
            %dstRect = [w/2, 2/2, imgw, imgh];
            [dstRect,dh,dv] = CenterRect([0 0 imgw imgh],[0 0 w h]);
            offset=dstRect(2)-round(dstRect(2)*.2);
            dstRect=[dstRect(1) dstRect(2)-offset dstRect(3) dstRect(4)-offset];
        end
        
        
        % Start playback of movie. This will start
        % the realtime playback clock and playback of audio tracks, if any.
        % Play 'movie', at a playbackrate = 1, with endless loop=1 and
        % 1.0 == 100% audio volume.
        
        Screen('PlayMovie', movie, rate, 0, 1.0);
        
        t1 = GetSecs;
        dialPos=0;
        dialScale=10;
        
        Hpos=ones(round(hz*movieduration),1); % initialize array
        Vpos=Hpos;
        
        
    %    Vbot=700;
        Vbot=h;
        Vtop=Vbot-140;
        Vstart=Vbot;
        Vpos(1)=Vstart;
        counter=1;

        rating(1)=0;

        dialPos=0;
        oldPos=0;

        % Infinite playback loop: Fetch video frames and display them...
        while 1

            counter=counter+1;
            % Check for abortion:
            abortit=0;
            [keyIsDown, ~, keyCode] = KbCheck(-1);
            if (keyIsDown==1 && keyCode(esc))
                % Set the abort-demo flag.
                abortit=2;
                % clear mex
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
                    break;
                end
                
                % Draw the new texture immediately to screen:
                Screen('DrawTexture', win, tex, [], dstRect, [], [], [], [], shader);
            end
            
            if powerMateExists
                [button, dialPos] = PsychPowerMate('Get', handle);
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

            diffPos = oldPos - dialPos;
            oldPos = dialPos;

            rating(counter) = rating(counter-1) - diffPos;

            %Make rating a value between 0-9
            if rating(counter)>10
                rating(counter)=10;
            elseif rating(counter)<1
                rating(counter)=1;
            end
            
            lineWidth=5;
            Screen('DrawLine', win, [0 0 0 255], 1, Vtop-lineWidth, w, Vtop-lineWidth, lineWidth);
            Screen('DrawLine', win, [0 0 0 255], 1, Vbot, w, Vbot, lineWidth);
            
            Vpos(counter)=Vstart-round(dialScale*rating(counter))
            Hpos(counter,1)=Hpos(counter-1)+1;

            %https://www.w3schools.com/colors/colors_picker.asp
            %draw old data points with Red:
            Screen('DrawDots', win, [(Hpos(1:counter-1))'; (Vpos(1:counter-1))'], 10, [255 0 0 255]);
            %draw new data point with Fuchsia:
            Screen('DrawDots', win, [Hpos(counter) Vpos(counter)], 10, [255 0 255 255]);
            
            %enter results in matrix
            results(counter,:) = [subID, 666, counter, rating(counter)];

            % Update display:
            Screen('Flip', win);
        end

    end

    telapsed = GetSecs - t1;
    fprintf('Elapsed time %f seconds, for %i frames. Average framerate %f fps.\n', telapsed, i, i / telapsed);

    Screen('Flip', win);
    KbReleaseWait;

    % Close movie object:
    Screen('CloseMovie', movie);

    % Close any remaining movie objects
    % Screen('CloseAll');

    clear mex


    %TODO: write results to comma delimited text file (use '\t' for tabs)
    % dlmwrite(fileName, results, 'delimiter', ',', 'precision', 6);
    dlmwrite(fileName, results, 'delimiter', ',');
    %'precision','%.6f'

    %TODO: display thank you and performance feedback
    % DrawFormattedText(expWin, ['Thank you for participating!'], 'center', 'center');
    % Screen('Flip', expWin);
    % KbWait([], 2); %wait for keystroke

    %clean up before exit
    ShowCursor;
    sca; %or sca;
    ListenChar(0);
    %return to olddebuglevel
    % Screen('Preference', 'VisualDebuglevel', olddebuglevel);

catch
    % This section is executed only in case an error happens in the
    % experiment code implemented between try and catch...
    ShowCursor;
    sca; %or sca
    ListenChar(0);
    % Screen('Preference', 'VisualDebuglevel', olddebuglevel);
    %output the error message
    psychrethrow(psychlasterror);
end
