%clear all variables and close all open diagrams
clear all;
close all;

%load results from result files
resultsFolder = 'results/';
resultList = dir([resultsFolder,'*.mat']);
numResults = length(resultList);
subjIDList = zeros(numResults, 1);
for resultNum = 1:numResults;
    results{resultNum}=load([resultsFolder,resultList(resultNum).name]);
    subjIDList(resultNum,1) = results{resultNum}.result.subID;
end
%subjIDList=subjIDList.';

% The syntax for cell arrays is
% emotionList = {'disgust','fear','happy','sad'};
% curly brackets signify cell arrays
% square brackets signify numerical, string, and character arrays
% using ["disgust"...] seems to work but it is not consistent with other
% syntax of cell arrays

%set list of emotions to analyze from info in first result set
%(they should all be the same)
emotionList = results{1}.result.info.groupList;
numEmotions = length(emotionList);
figureNum = 0;

myGroupResults = cell(numEmotions,1);

%loop through each emotion
for emotionNum = 1:numEmotions
    emotion = emotionList{emotionNum};

    videoList = results{1}.result.(emotion).info.movieList;
    numVid = length(videoList);

    %TO DO INITIALIZE SUBJECT ARRAY TO NANANANANANAN

    subjCorrelation = nan(numResults,numVid);

    %loop through each video
    for vidNum = 1:numVid
        [~,videoBaseName,~] = fileparts(videoList{vidNum});
        duration = results{1}.result.(emotion).(videoBaseName).info.duration;
        fps = results{1}.result.(emotion).(videoBaseName).info.fps;
        numExpectedDatapoints = round(duration*fps);

        Y=nan(numExpectedDatapoints,numResults);
        for subjNum = 1:length(results)
            %videoStruct = interpolateData(results{subjNum}.result.(emotion).(videoBaseName));
            subjData = results{subjNum}.result.(emotion).(videoBaseName).data(:,3);

            dataLength = length(subjData);
            Y(1:dataLength,subjNum) = subjData;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%
        % if you want to remove values that exceed the max boundary you can do it here.
        %Change any values > 20 to 20.

        %TODO: Rescale timeseries with any values > 20
        %inds = find(Y > 20); Y(inds) = 20;
        %meanAcrossSubjects = nanmean(Y,2);

        % nanmean calculates mean while ignoring NaNs
        meanAcrossSubjects = nanmean(Y,2);


        % replace with standard error of the mean. %%%%%%%%%%%%%%%%%%%%%
        % se = std(x)/sqrt(n), where n = number of values in x
        % std is the sample variance
        % se is the estimate of the population variance
        standardDeviationAcrossSubjects = std(Y,0,2);

        figureNum = figureNum + 1;
        % You could also just do figure(vidNum) %%%%%%%%%%%%%%%%%%%%%
        figure(figureNum);
        g = plot(meanAcrossSubjects,'-k');
        set(g,'linewidth',3)
        hold on
        plot(Y)

        g = plot(meanAcrossSubjects-standardDeviationAcrossSubjects,':k');
        set(g,'linewidth',2)
        g = plot(meanAcrossSubjects+standardDeviationAcrossSubjects,':k');
        set(g,'linewidth',2)
        % alternative to strcat and fullfile: title([emotion,' video #',num2str(vidNum)]) %%%%%%%%%%%%%
        title(strcat(emotion,' video #',num2str(vidNum)))

        subjCorrelation(:,vidNum) = corr(Y,meanAcrossSubjects,'rows','complete');

        %find correlation between subject and mean of all subject
        %TODO: Solve the NaN problem
        %TODO: Create a function that will cleanup the data. Do the
        %interpolation of the timeseries, etc.
        %for corrNum = 1:subjNum
        %    temp=corrcoef(Y(:,corrNum),meanAcrossSubjects);
        %end

        %temp=corr(Y, meanAcrossSubjects,'rows','complete');

        %Get collenations for all video
        %average of all correlation for each emotion for each subject
        % relationship between different correlations of different emotions

        %regression analysis - techniwue to predict Y given X
        %load the RSQ data from text file
        %Similarity to: correlate the RSQ against correlation of the mean across subjects and the individual rating
        %Sensitivity: correlate the RSQ  against the slope of the regression (scaling factor)

        %robustfit or regress functions - basic linear equation

        %bar plot of correlation of each emotion
    end

    myGroupResults{emotionNum} = subjCorrelation;
    %TODO: This should need to be 'nanmean'
    subjectByEmotionCorr(:,emotionNum) = mean(subjCorrelation,2);

    plot(1:7,mean(myGroupResults{1}))
    xlabel('disgust')
    ylabel('corr to the mean')



    %subject by emotion

    % for upper bounds always use a variable
    % otherwise you will have to change your code every time you add a subject
    % correlationTable = table(subjIDList,subjCorrelation{1:numSubj});

    %videoCorrelation=subjCorrelation.';
    %correlation between subject and mean of all subjects
    %correlationTable = table(num2str(subjIDList),subjCorrelation(:,1:numVid));
    %     correlationTable = table(num2str(subjIDList),{subjCorrelation});

    % you can convert a number into a string using num2str(x)
    % e.g. for i=1:9
    % mystring = ['00' num2str(i)];
    % end
    % for i = 10:99
    % mystring = ['0' num2str(i)];
    % end
    %
    % bonus points if you can combine these two loops into one
    %     correlationTable.Properties.VariableNames = ["subjID","Video 001","Video 002","Video 003","Video 004","Video 005","Video 006","Video 007"];
    %     fprintf("Correlation on subject ratings between %s videos:\n",emotion);
    %     disp(correlationTable);

    %plot correlation between subject and mean of all subjects per emotion
    %(x = mean rating across subjects, y = subject rating)
    %line of best fit, final relationship = slope (a)
    %y = ax + b

    %plot slope vs. RS
    %(x = slope (a), y = RS)
    %line of best fit using robustfit, final relationship = final
    %predicted + slope (as slope increases, RS increases)

    %plot corr vs. RS
    %(x = corr (a), y = RS)
    %line of best fit using robustfit, final relationship = final
    %predicted - slope (as corr increases, RS decreases)

end

figure
% emoCorrForRegression = zeros(factorial(numEmotions-1)*numResults,2);
emoCorrForRegression = [];
for emotionNumX = 1:numEmotions-1
    for emotionNumY = emotionNumX+1:numEmotions
        temp = [subjectByEmotionCorr(:,emotionNumX),subjectByEmotionCorr(:,emotionNumY)];
        emoCorrForRegression = [emoCorrForRegression;temp];
        plot(subjectByEmotionCorr(:,emotionNumX),subjectByEmotionCorr(:,emotionNumY),'ro')
        xlabel('correlation');
        ylabel('correlation');
        title('All emotions')
        hold on;
    end
end
[B, stats] = robustfit(emoCorrForRegression(:,1),emoCorrForRegression(:,2));
%stats.p is P-value. Anything less than .05 is not by chance (e.g.
%statistically significant)
%y=ax+b
plot(emoCorrForRegression(:,1), emoCorrForRegression(:,1)*B(2)+B(1));
disp(['P-value for all datapoints: ', num2str(stats.p(2))]);


% emoCorrForRegression = zeros(factorial(numEmotions-1)*numResults,2);
for emotionNumX = 1:numEmotions-1
    emoCorrForRegression = [];
    for emotionNumY = emotionNumX+1:numEmotions
        figure

%         temp = [subjectByEmotionCorr(:,emotionNumX),subjectByEmotionCorr(:,emotionNumY)];
%         emoCorrForRegression = [emoCorrForRegression;temp];
        emoCorrForRegression = [subjectByEmotionCorr(:,emotionNumX),subjectByEmotionCorr(:,emotionNumY)];
        plot(subjectByEmotionCorr(:,emotionNumX),subjectByEmotionCorr(:,emotionNumY),'ro')
        xlabel([emotionList{emotionNumX}, ' correlation']);
        ylabel([emotionList{emotionNumY}, ' correlation']);
        title([emotionList{emotionNumX}, ' vs. ', emotionList{emotionNumY} ' correlation (P-value: ', num2str(stats.p(2)), ')'])
        hold on;

    [B, stats] = robustfit(emoCorrForRegression(:,1),emoCorrForRegression(:,2));
    %stats.p is P-value. Anything less than .05 is not by chance (e.g.
    %statistically significant)
    %y=ax+b
    plot(emoCorrForRegression(:,1), emoCorrForRegression(:,1)*B(2)+B(1));
    disp(['P-value for all datapoints: ', num2str(stats.p(2))]);
    end
end





function videoStruct = interpolateData(videoStruct)

secondsPerFrame=1/videoStruct.info.fps
numFrames=round(videoStruct.info.duration/secondsPerFrame)
xq = (videoStruct.data(1,1):secondsPerFrame:videoStruct.data(1,1)+(secondsPerFrame*numFrames))
reshape(xq,[],1)

fprintf(videoStruct)

end


% y1 = smoothdata(rand(1069,1),'gaussian', 100);
% y2 = smoothdata(rand(873,1),'gaussian',100);
% y3 = smoothdata(rand(500,1),'gaussian',100);
% y4 = smoothdata(rand(1000,1),'gaussian',100);
% Y=nan(4,1000);
% Y(1,:) = interp1(y1,linspace(1,numel(y1),1000));
% Y(2,:) = interp1(y2,linspace(1,numel(y2),1000));
% Y(3,:) = interp1(y3,linspace(1,numel(y3),1000));
% Y(4,:) = interp1(y4,linspace(1,numel(y4),1000));
% h=plot(linspace(0,100,1000),Y,'Color',[.7 .7 .7]);
% hold on
% hh=plot(linspace(0,100,1000),mean(Y),'k-','linewidth',2);
% legend([h(1) hh],'Individual','Average')