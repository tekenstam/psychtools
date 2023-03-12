%clear all variables and close all open diagrams
clear all;
close all;

%load results from result files
if exist('/Users/annikaekenstam/Dropbox/Stimuli/results/','dir')
    resultsFolder = '/Users/annikaekenstam/Dropbox/Stimuli/results/';
elseif exist('/Users/corelabuser/Dropbox/Stimuli/results/','dir')
    resultsFolder = '/Users/corelabuser/Dropbox/Stimuli/results/';
else
    resultsFolder = 'results/';
end

resultList = dir([resultsFolder,'*.mat']);
numSubjects = length(resultList);
subjIDList = zeros(numSubjects,1);

for resultNum = 1:numSubjects;
    results{resultNum}=load([resultsFolder,resultList(resultNum).name]);
    subjIDList(resultNum,1) = results{resultNum}.result.subID;
end

%set list of emotions to analyze from
%info in first result set (they should all be the same)
emotionList = results{1}.result.info.groupList;
numEmotions = length(emotionList);
figureNum = 0;

myGroupResults = cell(numEmotions,1);
mySubjSlopes = zeros(numSubjects, numEmotions);

%loop through each emotion
for emotionNum = 1:numEmotions
    emotion = emotionList{emotionNum};
    videoList = results{1}.result.(emotion).info.movieList;

    numVid = length(videoList);

    subjCorrelation = nan(numSubjects,numVid);

    %loop through each video
    tempSlopes = zeros(numSubjects, numVid);
    for vidNum = 1:numVid
        [~,videoBaseName,~] = fileparts(videoList{vidNum});
        duration = results{1}.result.(emotion).(videoBaseName).info.duration;
        fps = results{1}.result.(emotion).(videoBaseName).info.fps;
        numExpectedDatapoints = round(duration*fps);

        Y=nan(numExpectedDatapoints,numSubjects);
        for subjNum = 1:numSubjects
            subjData = results{subjNum}.result.(emotion).(videoBaseName).data(:,3);

            dataLength = length(subjData);
            Y(1:dataLength,subjNum) = subjData;
        end

        %to do check for nan
        meanAcrossSubjects = nanmean(Y,2);

        standardDeviationAcrossSubjects = std(Y,0,2);

        %for every subject and video, find the slope between mean and
        %subject timeseries
        for subjNum = 1:numSubjects
            B = robustfit(meanAcrossSubjects,Y(:,subjNum));
            tempSlopes(subjNum, vidNum) = B(2);
        end

        figureNum = figureNum + 1;
        figure(figureNum);
        g = plot(meanAcrossSubjects,'-k');
        set(g,'linewidth',3)
        hold on
        plot(Y)
        g = plot(meanAcrossSubjects-standardDeviationAcrossSubjects,':k');
        set(g,'linewidth',2)
        g = plot(meanAcrossSubjects+standardDeviationAcrossSubjects,':k');
        set(g,'linewidth',2)
        title(strcat(emotion,' video #',num2str(vidNum)))

        subjCorrelation(:,vidNum) = corr(Y,meanAcrossSubjects,'rows','complete');

    end

    %calc mean of slope for each video
    mySubjSlopes(:,emotionNum) = mean(tempSlopes,2);

    myGroupResults{emotionNum} = subjCorrelation;
    subjByEmotionCorrelation(:,emotionNum) = mean(subjCorrelation,2);


    %correlation between subject and mean of all subjects
    %     correlationTable = table(subjIDList,subjCorrelation(1:7);
    %     correlationTable.Properties.VariableNames = ["subjID","001","002","003","004","005","006","007"];
    %     fprintf("%s\n",emotion);
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

%figure for all emotions
figure;
emoCorrForRegression = [];

for emotionNumX = 1:numEmotions-1;
    for emotionNumY = emotionNumX+1:numEmotions
        temp=[subjByEmotionCorrelation(:,emotionNumX),subjByEmotionCorrelation(:,emotionNumY)];
        emoCorrForRegression = [emoCorrForRegression;temp];
        plot(subjByEmotionCorrelation(:,emotionNumX),subjByEmotionCorrelation(:,emotionNumY),'ro');
        hold on;
    end
end

[B, stats] = robustfit(emoCorrForRegression(:,1),emoCorrForRegression(:,2));
%y = ax + b
plot(emoCorrForRegression(:,1),emoCorrForRegression(:,1)*B(2)+B(1));
xlabel('correlation');
ylabel('correlation');
title(['all emotions (P-value: ',num2str(stats.p(2)),')']);
disp(['P-value for All Data Points: ',num2str(stats.p(2))]);

%figures for each emotion
emoCorrForRegression = [];

for emotionNumX = 1:numEmotions-1;
    for emotionNumY = emotionNumX+1:numEmotions
        figure;
        emoCorrForRegression = [subjByEmotionCorrelation(:,emotionNumX),subjByEmotionCorrelation(:,emotionNumY)];
        plot(subjByEmotionCorrelation(:,emotionNumX),subjByEmotionCorrelation(:,emotionNumY),'ro');
        xlabel([emotionList{emotionNumX},' correlation']);
        ylabel([emotionList{emotionNumY},' correlation']);
        title([emotionList{emotionNumX},' vs. ', emotionList{emotionNumY}, ' correlation (P-value: ',num2str(stats.p(2)),')']);
        disp(['P-value for ',emotionList{emotionNumX},' vs. ', emotionList{emotionNumY},': ',num2str(stats.p(2))]);
        hold on;
        [B, stats] = robustfit(emoCorrForRegression(:,1),emoCorrForRegression(:,2));
        %y = ax + b
        plot(emoCorrForRegression(:,1),emoCorrForRegression(:,1)*B(2)+B(1));
        disp(['regression slope: ',num2str(B(2))]);
        disp(['regression int: ',num2str(B(1))]);
    end
end

rsScores = importdata('results/rs-scores.csv')

for emotionNum = 1:numEmotions
    %rsCorrForRegression = subjByEmotionCorrelation(:,emotionNum),rsScores.data(:,2);
    figure;
    plot(subjByEmotionCorrelation(:,emotionNum), ...
        rsScores.data(:,2),'o');
    hold on;
    [B, stats] = robustfit(subjByEmotionCorrelation(:,emotionNum),rsScores.data(:,2));
    plot(subjByEmotionCorrelation(:,emotionNum),subjByEmotionCorrelation(:,emotionNum)*B(2)+B(1),'ro-');
    xlabel([emotionList{emotionNum},' correlation']);
    ylabel('RS Score');
    title([emotionList{emotionNum},' vs. RS Score (P-value: ',num2str(stats.p(2)),')']);
end

%scaling factor of each subject plotted against RS
%mySubjSlopes is the scaling factor to get the values for each subject
%same analysis as the correlation of each subject
%correltate mySubjSlopes with rsScores
% mean across subject for a particular emotion
% Regression (robustfit):
%X - Independent variable
%Y - Dependent variable

%atanh, then convert back using atan


