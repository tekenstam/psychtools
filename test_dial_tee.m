%Cyberball Stimulus Presentation Program

clc;clear all;close all;
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

moviename=[myexpt 'xhappy1.mov'];

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
    
    % Open movie file and retrieve basic info about movie:
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
    
    Screen('PlayMovie', movie, rate, 1, 1.0);
    
    t1 = GetSecs;
    dialPos=0;
    dialScale=10;
    
    Hpos=ones(round(hz*movieduration),1); % initialize array
    Vpos=Hpos;
    
    
    Vbot=700;
    Vtop=Vbot-140;
    Vstart=Vbot;
    Vpos(1)=Vstart;
    counter=1;
    % Infinite playback loop: Fetch video frames and display them...
    while 1
        counter=counter+1;
        % Check for abortion:
        abortit=0;
        [keyIsDown, ~, keyCode] = KbCheck(-1);
        if (keyIsDown==1 && keyCode(esc))
            % Set the abort-demo flag.
            abortit=2;
            break;
            clear mex
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
        
        Screen('DrawLine', win, [0 0 0 255], 1, Vtop, w, Vtop ,5);
        Screen('DrawLine', win, [0 0 0 255], 1, Vbot, w, Vbot ,5);
        
        Vpos(counter)=Vstart+round(dialScale*dialPos);
        if Vpos(counter)<Vtop
            Vpos(counter)=Vtop;
            dialPos=dialPos+1;
        elseif Vpos(counter)>Vbot
            Vpos(counter)=Vbot;
            dialPos=dialPos-1;
        end
        Hpos(counter,1)=Hpos(counter-1)+1;
        Screen('DrawDots', win, [(Hpos(1:counter-1))'; (Vpos(1:counter-1))'], 10, [255 0 0 255]);
        Screen('DrawDots', win, [Hpos(counter) Vpos(counter)], 10, [255 0 255 255]);
        
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

clear mex
