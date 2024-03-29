
%clear all variables and close all open diagrams
clear all;   %#ok - We want to clear all variables before running
close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%load results from result files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist('/Users/annikaekenstam/Dropbox/Stimuli/results/', 'dir')
    resultsFolder = '/Users/annikaekenstam/Dropbox/Stimuli/results/';
elseif exist('/Users/corelabuserXXX/Dropbox/Stimuli/results/', 'dir')
    resultsFolder = '/Users/corelabuserXXX/Dropbox/Stimuli/results/';
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
emotionList = results{2}.result.info.groupList;
numEmotions = length(emotionList);

myGroupResults = cell(numEmotions, 1);
mySubjSlopes = zeros(numSubjects, numEmotions);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%process data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%loop through each emotion
subjByEmotionCorrelation = nan(numSubjects, numEmotions);
subjByEmotionCorrelationSEM = nan(numSubjects, numEmotions);
for emotionNum = 1:numEmotions
    emotion = emotionList{emotionNum};
    videoList = results{2}.result.(emotion).info.movieList;

    numVid = length(videoList);

    subjCorrelation = nan(numSubjects, numVid);

    %loop through each video
    tempSlopes = zeros(numSubjects, numVid);
    for vidNum = 1:numVid
        [~,videoBaseName,~] = fileparts(videoList{vidNum});
        duration = results{2}.result.(emotion).(videoBaseName).info.duration;
        fps = results{2}.result.(emotion).(videoBaseName).info.fps;
        numExpectedDatapoints = round(duration * fps);

        videoResults=nan(numExpectedDatapoints, numSubjects);
        meanAcrossSubjects=nan(numExpectedDatapoints, numSubjects);
        for subjNum = 1:numSubjects
            %TODO: cleanup data files so this is not needed
            %HACK: add video 'info' from subject 2 if missing

            % Skip if video doesn't exist in results
            if isfield(results{subjNum}.result.(emotion), videoBaseName)
                if ~isfield(results{subjNum}.result.(emotion).(videoBaseName), 'info')
                    fprintf("Adding info to %s of subject %d\n", videoBaseName, subjNum)
                    results{subjNum}.result.(emotion).(videoBaseName).info = ...
                        results{2}.result.(emotion).(videoBaseName).info;
                end

                %cleanup errors and gaps in data from data collection
                subjData = interpolateData(results{subjNum}.result.(emotion).(videoBaseName));
                if size(subjData>numExpectedDatapoints)
                    subjData(numExpectedDatapoints+1:size(subjData)) = [];
                end

                dataLength = length(subjData);
                videoResults(1:dataLength,subjNum) = subjData;
            else
                fprintf("Skipping %s for %d\n", videoBaseName, subjNum);
                % videoResults(:,subjNum) = [];
            end
        end
        

        indsTemp = 1:numSubjects;
        for subjNum = 1:numSubjects
            inds = indsTemp;
            inds(subjNum) = [];
            meanAcrossSubjects(:,subjNum) = nanmean(videoResults(:,inds), 2);
        end

        standardErrorAcrossSubjects = std(videoResults, 0, 2)/sqrt(numSubjects);

        %for each subject and video, find the slope between mean and
        %subject timeseries
        for subjNum = 1:numSubjects
            if ~isnan(meanAcrossSubjects(1, subjNum)) && ~isnan(videoResults(1,subjNum))
                B = robustfit(meanAcrossSubjects(:, subjNum), videoResults(:,subjNum));
                tempSlopes(subjNum, vidNum) = B(2);
            end
        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %plot mean and +/- standard deviation across subjects
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        figure;hold on;
        plot(videoResults);
        g1 = plot(mean(meanAcrossSubjects, 2), '-k', 'DisplayName', 'Mean across subjects', 'LineWidth', 3);
        g2 = plot(mean(meanAcrossSubjects, 2) - standardErrorAcrossSubjects, ':k', 'DisplayName', 'Standard error of the mean', 'LineWidth', 2);
        plot(mean(meanAcrossSubjects, 2) + standardErrorAcrossSubjects, ':k', 'DisplayName', 'Standard error of the mean', 'LineWidth', 2);
        title(['Subject ratings of ', emotion, ' video #', num2str(vidNum)]);
        xlabel('Time (video frame number)');
        ylabel('Subject rating');
        legend([g1(1), g2]);

%         if strcmp(emotion, 'fear')
%             for subjNum = 1:numSubjects
%                 figure; hold on;
%                 X = meanAcrossSubjects(:, subjNum);
%                 Y = videoResults(:,subjNum);
%                 plot(X, Y, 'o', 'DisplayName', 'Rating', 'LineWidth', 1);
%                 [B, stats] = robustfit(X, Y);
%                 %y = ax + b
%                 plot(X, X * B(2) + B(1), 'r-', 'DisplayName', 'Robust fit regression', 'LineWidth', 2);
    
%                 xlabel('Mean Rating Across Subjects');
%                 ylabel('Subject Rating');
% %                 title(['Subject #', num2str(subjNum), ' ratings of ', emotion, ' video #', num2str(vidNum), ' vs. mean rating']);
%                 title(['Subject #', num2str(subjNum), ' ratings of ', emotion, ' video #', num2str(vidNum), ' vs. mean rating (slope: ', ...
%                     num2str(B(2)), ')']);
%                 ylim([0 20])
%                 xlim([0 20])
%                 legend;
%             end
%         end

        for subjNum = 1:numSubjects
            subjCorrelation(subjNum,vidNum) = corr(videoResults(:,subjNum), meanAcrossSubjects(:,subjNum), 'rows', 'complete');
        end

    end

    %calculate mean of slope for each video, excluding current subject
    indsTemp = 1:numSubjects;
    for subjNum = 1:numSubjects
        inds = indsTemp;
        inds(subjNum) = [];
        mySubjSlopes(subjNum,emotionNum) = mean(mean(tempSlopes(inds,:), 1));
        %JG: Can you check?
        %mySubjSlopesSEM(subjNum,emotionNum) = std(tempSlopes(inds,:), 0, 1)/sqrt(numSubjects);
    end

    myGroupResults{emotionNum} = subjCorrelation;

    indsTemp = 1:numSubjects;
    for subjNum = 1:numSubjects
        inds = indsTemp;
        inds(subjNum) = [];
        subjByEmotionCorrelation(subjNum,emotionNum) = nanmean(subjCorrelation(subjNum,:), 2);
        subjByEmotionCorrelationSEM(subjNum,emotionNum) = std(subjCorrelation(subjNum,:), 0, 2)/sqrt(numSubjects);
    end

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%subject correlation for all emotions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure; hold on;
emoCorrForRegression = nan(numSubjects * factorial(numEmotions - 1), 2);
for emotionNumX = 1:numEmotions-1
    for emotionNumY = emotionNumX+1:numEmotions
        temp=[subjByEmotionCorrelation(:,emotionNumX), ...
            subjByEmotionCorrelation(:,emotionNumY)];
        emoCorrForRegression = [emoCorrForRegression;temp]; %#ok - Collect all correlations

        X = subjByEmotionCorrelation(:,emotionNumX);
        Y = subjByEmotionCorrelation(:,emotionNumY);
        g1 = plot(X, Y, 'o');
        g1.set('DisplayName', 'Subject correlation');
        g1.set('LineWidth', 2);
    end
end

[B, stats] = robustfit(emoCorrForRegression(:,1), emoCorrForRegression(:,2));
%y = ax + b
g2 = plot(emoCorrForRegression(:,1), emoCorrForRegression(:,1) * B(2) + B(1), 'r-', 'DisplayName', 'Fit robust linear regression', 'LineWidth', 2);
xlabel('Correlation to the mean');
ylabel('Correlation to the mean');
title(['Correlation between all emotions (P-value: ', num2str(stats.p(2)), ')']);
legend([g1 g2], 'location', 'best');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%subject correlation between each emotion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

emoCorrForRegression = nan(numSubjects, 2);
for emotionNumX = 1:numEmotions-1
    for emotionNumY = emotionNumX+1:numEmotions
        figure; hold on;
        emoCorrForRegression = [subjByEmotionCorrelation(:,emotionNumX), ...
            subjByEmotionCorrelation(:,emotionNumY)];
        X = subjByEmotionCorrelation(:,emotionNumX);
        Y = subjByEmotionCorrelation(:,emotionNumY);
        errX = subjByEmotionCorrelationSEM(:,emotionNumX);
        errY = subjByEmotionCorrelationSEM(:,emotionNumY);
        g = plot(X, Y, 'bo');
        g.set('LineWidth', 2);
        g.set('DisplayName', 'Subjects');
        
        g = errorbar(X, Y, errX, errY, 'both');
        g.LineStyle = 'none';
        g.DisplayName = 'Standard error of the mean';
        g.Color = '#EDB120';

        xlabel(['Correlation of ', emotionList{emotionNumX},' videos']);
        ylabel(['Correlation of ', emotionList{emotionNumY},' videos']);
        title(['Correlation between ' emotionList{emotionNumX}, ' and ', emotionList{emotionNumY}, ...
            ' videos (P-value: ', num2str(stats.p(2)), ')']);
        [B, stats] = robustfit(emoCorrForRegression(:,1), ...
            emoCorrForRegression(:,2));
        %y = ax + b
        plot(emoCorrForRegression(:,1), emoCorrForRegression(:,1) * B(2) + B(1), 'r-', 'DisplayName', 'Fit robust linear regression', 'LineWidth', 2);
        legend;
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%subject correlation vs RS score for each emotion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rsScores = importdata('results/rs-scores.csv');

for emotionNum = 1:numEmotions
    X = subjByEmotionCorrelation(:,emotionNum);
    Y = rsScores.data(:,2);
    errX = subjByEmotionCorrelationSEM(:,emotionNum);

    figure; hold on;
    plot(X, Y, 'o', 'DisplayName', 'Subjects', 'LineWidth', 2);
    [B, stats] = robustfit(X, Y);
    %y = ax + b
    plot(X, X * B(2) + B(1), 'r-', 'DisplayName', 'Fit robust linear regression', 'LineWidth', 2);
    %TODO: Add errorbar
    g = errorbar(X, Y, errX);
    g.LineStyle = 'none';
    g.DisplayName = 'Standard error of the mean';
    g.Color = '#EDB120';
    xlabel(['Correlation of ', emotionList{emotionNum},' videos']);
    ylabel('RS score');
    title(['Correlation of ', emotionList{emotionNum},' videos vs. RS score (P-value: ', ...
        num2str(stats.p(2)), ')']);
    legend;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%subject correlation vs RS Anxiety sub-score for each emotion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for emotionNum = 1:numEmotions
    X = subjByEmotionCorrelation(:,emotionNum);
    Y = rsScores.data(:,3);
    errX = subjByEmotionCorrelationSEM(:,emotionNum);

    figure; hold on;
    plot(X, Y, 'o', 'DisplayName', 'Subjects', 'LineWidth', 2);
    [B, stats] = robustfit(X, Y);
    %y = ax + b
    plot(X, X * B(2) + B(1), 'r-', 'DisplayName', 'Fit robust linear regression', 'LineWidth', 2);
    %TODO: Add errorbar
    g = errorbar(X, Y, errX);
    g.LineStyle = 'none';
    g.DisplayName = 'Standard error of the mean';
    g.Color = '#EDB120';
    xlabel(['Correlation of ', emotionList{emotionNum},' videos']);
    ylabel('RS Anxiety sub-score');
    title(['Correlation of ', emotionList{emotionNum},' videos vs. RS Anxiety sub-score (P-value: ', ...
        num2str(stats.p(2)), ')']);
    legend;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%subject correlation vs RS Expectation sub-score for each emotion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for emotionNum = 1:numEmotions
    X = subjByEmotionCorrelation(:,emotionNum);
    Y = rsScores.data(:,4);
    errX = subjByEmotionCorrelationSEM(:,emotionNum);

    figure; hold on;
    plot(X, Y, 'o', 'DisplayName', 'Subjects', 'LineWidth', 2);
    [B, stats] = robustfit(X, Y);
    %y = ax + b
    plot(X, X * B(2) + B(1), 'r-', 'DisplayName', 'Fit robust linear regression', 'LineWidth', 2);
    %TODO: Add errorbar
    g = errorbar(X, Y, errX);
    g.LineStyle = 'none';
    g.DisplayName = 'Standard error of the mean';
    g.Color = '#EDB120';
    xlabel(['Correlation of ', emotionList{emotionNum},' videos']);
    ylabel('RS Expectation sub-score');
    title(['Correlation of ', emotionList{emotionNum},' videos vs. RS Expectation sub-score (P-value: ', ...
        num2str(stats.p(2)), ')']);
    legend;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%mean scaling factor (slope) of each subject vs RS score
%for all emotions
%X = mean slope, Y= RS score
%mySubjSlopes is the scaling factor to get the values for each subject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure; hold on;
X = mean(mySubjSlopes, 2);
Y = rsScores.data(:,2);
% errX = mean(mySubjSlopesSEM, 2);
plot(X, Y, 'o', 'DisplayName', 'Subjects', 'LineWidth', 2);
[B, stats] = robustfit(mean(mySubjSlopes, 2), rsScores.data(:,2));
%y = ax + b
plot(X, X * B(2) + B(1), 'r-', 'DisplayName', 'Fit robust linear regression', 'LineWidth', 2);
% g = errorbar(X, Y, errX);
% g.LineStyle = 'none';
% g.DisplayName = 'Standard error of the mean';
% g.Color = '#EDB120';
xlabel('Regression slope of mean (all emotions)');
ylabel('RS score');
title(['Regression slope of mean (all emotions) vs. RS score (P-value: ', ...
    num2str(stats.p(2)), ')']);
legend;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%mean scaling factor (slope) of each subject vs RS Anxiety sub-score
%for all emotions
%X = mean slope, Y= RS score
%mySubjSlopes is the scaling factor to get the values for each subject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure; hold on;
X = mean(mySubjSlopes, 2);
Y = rsScores.data(:,3);
% errX = mean(mySubjSlopesSEM, 2);
plot(X, Y, 'o', 'DisplayName', 'Subjects', 'LineWidth', 2);
[B, stats] = robustfit(mean(mySubjSlopes, 2), rsScores.data(:,3));
%y = ax + b
plot(X, X * B(2) + B(1), 'r-', 'DisplayName', 'Fit robust linear regression', 'LineWidth', 2);
% g = errorbar(X, Y, errX);
% g.LineStyle = 'none';
% g.DisplayName = 'Standard error of the mean';
% g.Color = '#EDB120';
xlabel('Regression slope of mean (all emotions)');
ylabel('RS Anxiety sub-score');
title(['Regression slope of mean (all emotions) vs. RS Anxiety sub-score (P-value: ', ...
    num2str(stats.p(2)), ')']);
legend;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%mean scaling factor (slope) of each subject vs RS Expectation sub-score
%for all emotions
%X = mean slope, Y= RS score
%mySubjSlopes is the scaling factor to get the values for each subject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure; hold on;
X = mean(mySubjSlopes, 2);
Y = rsScores.data(:,4);
% errX = mean(mySubjSlopesSEM, 2);
plot(X, Y, 'o', 'DisplayName', 'Subjects', 'LineWidth', 2);
[B, stats] = robustfit(mean(mySubjSlopes, 2), rsScores.data(:,3));
%y = ax + b
plot(X, X * B(2) + B(1), 'r-', 'DisplayName', 'Fit robust linear regression', 'LineWidth', 2);
% g = errorbar(X, Y, errX);
% g.LineStyle = 'none';
% g.DisplayName = 'Standard error of the mean';
% g.Color = '#EDB120';
xlabel('Regression slope of mean (all emotions)');
ylabel('RS Expectation sub-score');
title(['Regression slope of mean (all emotions) vs. RS Expectation sub-score (P-value: ', ...
    num2str(stats.p(2)), ')']);
legend;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%mean scaling factor (slope) of each subject vs RS score
%for each emotion
%X = mean slope, Y= RS score
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for emotionNum = 1:numEmotions
    figure; hold on;
    X = mySubjSlopes(:,emotionNum);
    Y = rsScores.data(:,2);
%     errX = mySubjSlopesSEM(:,emotionNum);
    plot(X, Y, 'o', 'DisplayName', 'Subjects', 'LineWidth', 2);
    [B, stats] = robustfit(X, Y);
    %y = ax + b
    plot(X, X * B(2) + B(1), 'r-', 'DisplayName', 'Fit robust linear regression', 'LineWidth', 2);
%     g = errorbar(X, Y, errX);
%     g.LineStyle = 'none';
%     g.DisplayName = 'Standard error of the mean';
%     g.Color = '#EDB120';
    xlabel(['Regression slope of ', emotionList{emotionNum}, ' mean']);
    ylabel('RS score');
    title(['Regression slope of ', emotionList{emotionNum}, ...
        ' mean vs. RS score (P-value: ', num2str(stats.p(2)), ')']);
    legend;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%mean scaling factor (slope) of each subject vs RS Anxiety sub-score
%for each emotion
%X = mean slope, Y= RS Anxiety sub-score
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for emotionNum = 1:numEmotions
    figure; hold on;
    X = mySubjSlopes(:,emotionNum);
    Y = rsScores.data(:,3);
%     errX = mySubjSlopesSEM(:,emotionNum);
    plot(X, Y, 'o', 'DisplayName', 'Subjects', 'LineWidth', 2);
    [B, stats] = robustfit(X, Y);
    %y = ax + b
    plot(X, X * B(2) + B(1), 'r-', 'DisplayName', 'Fit robust linear regression', 'LineWidth', 2);
%     g = errorbar(X, Y, errX);
%     g.LineStyle = 'none';
%     g.DisplayName = 'Standard error of the mean';
%     g.Color = '#EDB120';
    xlabel(['Regression slope of ', emotionList{emotionNum}, ' mean']);
    ylabel('RS Anxiety sub-score');
    title(['Regression slope of ', emotionList{emotionNum}, ...
        ' mean vs. RS Anxiety sub-score (P-value: ', num2str(stats.p(2)), ')']);
    legend;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%mean scaling factor (slope) of each subject vs RS Expectation sub-score
%for each emotion
%X = mean slope, Y= RS Anxiety sub-score
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for emotionNum = 1:numEmotions
    figure; hold on;
    X = mySubjSlopes(:,emotionNum);
    Y = rsScores.data(:,4);
%     errX = mySubjSlopesSEM(:,emotionNum);
    plot(X, Y, 'o', 'DisplayName', 'Subjects', 'LineWidth', 2);
    [B, stats] = robustfit(X, Y);
    %y = ax + b
    plot(X, X * B(2) + B(1), 'r-', 'DisplayName', 'Fit robust linear regression', 'LineWidth', 2);
%     g = errorbar(X, Y, errX);
%     g.LineStyle = 'none';
%     g.DisplayName = 'Standard error of the mean';
%     g.Color = '#EDB120';
    xlabel(['Regression slope of ', emotionList{emotionNum}, ' mean']);
    ylabel('RS Expectation sub-score');
    title(['Regression slope of ', emotionList{emotionNum}, ...
        ' mean vs. RS Expectation sub-score (P-value: ', num2str(stats.p(2)), ')']);
    legend;
end


%plot correlation to the mean vs regression slope
for emotionNum = 1:numEmotions
    figure; hold on;
    X = subjByEmotionCorrelation(:,emotionNum);
    Y = mySubjSlopes(:,emotionNum);
%     errX = mySubjSlopesSEM(:,emotionNum);
    plot(X, Y, 'o', 'DisplayName', 'Subjects', 'LineWidth', 2);
    [B, stats] = robustfit(X, Y);
    %y = ax + b
    plot(X, X * B(2) + B(1), 'r-', 'DisplayName', 'Fit robust linear regression', 'LineWidth', 2);
%     g = errorbar(X, Y, errX);
%     g.LineStyle = 'none';
%     g.DisplayName = 'Standard error of the mean';
%     g.Color = '#EDB120';
    xlabel(['Correlation of ', emotionList{emotionNum},' videos']);
    ylabel(['Regression slope of ', emotionList{emotionNum}, ' mean']);
    title(['Correlation vs regression slope for ', emotionList{emotionNum}, ...
        ' (P-value: ', num2str(stats.p(2)), ')']);
    legend;
end

figure; hold on;
X = mean(subjByEmotionCorrelation, 2);
Y = mean(mySubjSlopes, 2);
% errX = mean(mySubjSlopesSEM, 2);
plot(X, Y, 'o', 'DisplayName', 'Subjects', 'LineWidth', 2);
[B, stats] = robustfit(X, Y);
%y = ax + b
plot(X, X * B(2) + B(1), 'r-', 'DisplayName', 'Fit robust linear regression', 'LineWidth', 2);
% g = errorbar(X, Y, errX);
% g.LineStyle = 'none';
% g.DisplayName = 'Standard error of the mean';
% g.Color = '#EDB120';
xlabel('Correlation to the mean');
ylabel('Regression slope of mean (all emotions)');
title(['Correlation vs. regression slope (all emotions) (P-value: ', ...
    num2str(stats.p(2)), ')']);
legend;



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


function [  ] = exportAllFigures(  ) %#ok - This function is manually called
% exportAllFigures
%   helper function to export all figures with print resolution

figList = findall(groot,'Type','figure');
numFigures = numel(figList);
for figNum = 1:numFigures
    fig_h = figList(figNum);
    fig_h.Position = [fig_h.Position(1), fig_h.Position(2), ...
        fig_h.Position(3)*2, fig_h.Position(4)*2];
    ax = get(fig_h, 'CurrentAxes');
    ax.FontSize = 18; 
    ax.LineWidth = 2;

    h1 = findall(figList(figNum),'Type','text');
    figTitle = h1(1).String;

    exportgraphics(fig_h, ['figures/', figTitle, '.png'], 'Resolution', 300);
end

end
