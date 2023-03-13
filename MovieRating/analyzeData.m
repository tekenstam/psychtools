%clear all variables and close all open diagrams
clear all;   %#ok - We want to clear all variables before running
close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%load results from result files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist('/Users/annikaekenstam/Dropbox/Stimuli/results/', 'dir')
    resultsFolder = '/Users/annikaekenstam/Dropbox/Stimuli/results/';
elseif exist('/Users/corelabuser/Dropbox/Stimuli/results/', 'dir')
    resultsFolder = '/Users/corelabuser/Dropbox/Stimuli/results/';
else
    resultsFolder = 'results/';
end

resultList = dir([resultsFolder, '*.mat']);
numSubjects = length(resultList);
results = cell(numSubjects);
subjIDList = zeros(numSubjects, 1);

for resultNum = 1:numSubjects
    results{resultNum} = load([resultsFolder, resultList(resultNum).name]);
    subjIDList(resultNum,1) = results{resultNum}.result.subID;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%initialize variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
emotionList = results{1}.result.info.groupList;
numEmotions = length(emotionList);

myGroupResults = cell(numEmotions, 1);
mySubjSlopes = zeros(numSubjects, numEmotions);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%process data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%loop through each emotion
subjByEmotionCorrelation = nan(numSubjects, numEmotions);
for emotionNum = 1:numEmotions
    emotion = emotionList{emotionNum};
    videoList = results{1}.result.(emotion).info.movieList;

    numVid = length(videoList);

    subjCorrelation = nan(numSubjects, numVid);

    %loop through each video
    tempSlopes = zeros(numSubjects, numVid);
    for vidNum = 1:numVid
        [~,videoBaseName,~] = fileparts(videoList{vidNum});
        duration = results{1}.result.(emotion).(videoBaseName).info.duration;
        fps = results{1}.result.(emotion).(videoBaseName).info.fps;
        numExpectedDatapoints = round(duration * fps);

        videoResults=nan(numExpectedDatapoints, numSubjects);
        for subjNum = 1:numSubjects
            subjData = results{subjNum}.result.(emotion).(videoBaseName).data(:,3);

            dataLength = length(subjData);
            videoResults(1:dataLength,subjNum) = subjData;
        end

        meanAcrossSubjects = mean(videoResults, 2);

        standardDeviationAcrossSubjects = std(videoResults, 0, 2);

        %for each subject and video, find the slope between mean and
        %subject timeseries
        for subjNum = 1:numSubjects
            B = robustfit(meanAcrossSubjects, videoResults(:,subjNum));
            tempSlopes(subjNum, vidNum) = B(2);
        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %plot mean and +/- standard deviation across subjects
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        figure;
        g = plot(meanAcrossSubjects, '-k');
        set(g, 'linewidth', 3)
        hold on
        plot(videoResults)
        g = plot(meanAcrossSubjects-standardDeviationAcrossSubjects, ':k');
        set(g, 'linewidth', 2)
        g = plot(meanAcrossSubjects+standardDeviationAcrossSubjects, ':k');
        set(g, 'linewidth', 2)
        title([emotion, ' video #', num2str(vidNum)]);

        subjCorrelation(:,vidNum) = corr(videoResults, meanAcrossSubjects, 'rows', 'complete');

    end

    %calculate mean of slope for each video
    mySubjSlopes(:,emotionNum) = mean(tempSlopes, 2);

    myGroupResults{emotionNum} = subjCorrelation;
    subjByEmotionCorrelation(:,emotionNum) = mean(subjCorrelation, 2);

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%subject correlation for all emotions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure;
emoCorrForRegression = nan(numSubjects * factorial(numEmotions - 1), 2);
for emotionNumX = 1:numEmotions-1
    for emotionNumY = emotionNumX+1:numEmotions
        temp=[subjByEmotionCorrelation(:,emotionNumX), ...
            subjByEmotionCorrelation(:,emotionNumY)];
        emoCorrForRegression = [emoCorrForRegression;temp]; %#ok - Collect all correlations
        plot(subjByEmotionCorrelation(:,emotionNumX), ...
            subjByEmotionCorrelation(:,emotionNumY), 'ro');
        hold on;
    end
end

[B, stats] = robustfit(emoCorrForRegression(:,1), emoCorrForRegression(:,2));
%y = ax + b
plot(emoCorrForRegression(:,1), emoCorrForRegression(:,1) * B(2) + B(1));
xlabel('Correlation');
ylabel('Correlation');
title(['All emotions (P-value: ', num2str(stats.p(2)), ')']);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%subject correlation between each emotion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

emoCorrForRegression = nan(numSubjects, 2);
for emotionNumX = 1:numEmotions-1
    for emotionNumY = emotionNumX+1:numEmotions
        figure;
        emoCorrForRegression = [subjByEmotionCorrelation(:,emotionNumX), ...
            subjByEmotionCorrelation(:,emotionNumY)];
        plot(subjByEmotionCorrelation(:,emotionNumX), ...
            subjByEmotionCorrelation(:,emotionNumY), 'ro');
        xlabel([emotionList{emotionNumX}, ' correlation']);
        ylabel([emotionList{emotionNumY}, ' correlation']);
        title([emotionList{emotionNumX}, ' vs. ', emotionList{emotionNumY}, ...
            ' correlation (P-value: ', num2str(stats.p(2)), ')']);
        hold on;
        [B, stats] = robustfit(emoCorrForRegression(:,1), ...
            emoCorrForRegression(:,2));
        %y = ax + b
        plot(emoCorrForRegression(:,1), emoCorrForRegression(:,1) * B(2) + B(1));
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%subject correlation vs RS score for each emotion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rsScores = importdata('results/rs-scores.csv');

for emotionNum = 1:numEmotions
    figure;
    plot(subjByEmotionCorrelation(:,emotionNum), rsScores.data(:,2), 'o');
    hold on;
    [B, stats] = robustfit(subjByEmotionCorrelation(:,emotionNum), ...
        rsScores.data(:,2));
    %y = ax + b
    plot(subjByEmotionCorrelation(:,emotionNum), ...
        subjByEmotionCorrelation(:,emotionNum) * B(2) + B(1), 'r-');
    xlabel([emotionList{emotionNum},' correlation']);
    ylabel('RS score');
    title([emotionList{emotionNum},' vs. RS score (P-value: ', ...
        num2str(stats.p(2)), ')']);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%mean scaling factor (slope) of each subject vs RS score
%for all emotions
%X = mean slope, Y= RS score
%mySubjSlopes is the scaling factor to get the values for each subject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure;
plot(mean(mySubjSlopes, 2), rsScores.data(:,2), 'o');
hold on;
[B, stats] = robustfit(mean(mySubjSlopes, 2), rsScores.data(:,2));
%y = ax + b
plot(mean(mySubjSlopes, 2), mean(mySubjSlopes, 2) * B(2) + B(1), 'r-');
xlabel('Mean slope of correlation for all emotions');
ylabel('RS score');
title(['Mean slope of all emotions vs. RS score (P-value: ', ...
    num2str(stats.p(2)), ')']);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%mean scaling factor (slope) of each subject vs RS score
%for each emotion
%X = mean slope, Y= RS score
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for emotionNum = 1:numEmotions
    figure;
    plot(mySubjSlopes(:,emotionNum), rsScores.data(:,2), 'o');
    hold on;
    [B, stats] = robustfit(mySubjSlopes(:,emotionNum), rsScores.data(:,2));
    %y = ax + b
    plot(mySubjSlopes(:,emotionNum), mySubjSlopes(:,emotionNum) * B(2) + B(1), 'r-');
    xlabel(['Slope of ', emotionList{emotionNum}, ' correlation']);
    ylabel('RS score');
    title(['Slope of ', emotionList{emotionNum}, ...
        ' correlation vs. RS score (P-value: ', num2str(stats.p(2)), ')']);

end


%mean correlation across subject for a particular emotion
% Regression (robustfit):
%X - Independent variable
%Y - Dependent variable

%atanh, then convert back using atan

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


