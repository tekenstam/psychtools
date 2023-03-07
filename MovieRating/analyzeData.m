
clear all;

results{1}=load('results/resultfile_112114_20230303125256.mat');
results{2}=load('results/resultfile_115576_20230228220137.mat');
results{3}=load('results/resultfile_122652_20230301115523.mat');
results{4}=load('results/resultfile_134164_20230301131427.mat');
results{5}=load('results/resultfile_142249_20230302125209.mat');
results{6}=load('results/resultfile_20050817_20230304204831.mat');
results{7}=load('results/resultfile_20071026_20230304211511.mat');
results{8}=load('results/resultfile_20120207_20230304193314.mat');

emotionList = ["disgust","fear","happy","sad"];
numEmotions = length(emotionList);
figureNum = 0;

%loop through each emotion
for emotionNum = 1:numEmotions
    emotion = emotionList{emotionNum};
    videoList = dir(strcat('/Users/annikaekenstam/Dropbox/Stimuli/',emotion,'/*.mov'));
    videoList = {videoList(:).name};

    numVid = length(videoList);

    %loop through each video
    for vidNum = 1:numVid
        [~,videoBaseName,~] = fileparts(videoList{vidNum});
        Y=nan(3000,5);
        for subjNum = 1:length(results)
            subjData=results{subjNum}.result.(emotion).(videoBaseName).data(:,3);

            dataLength=length(subjData);
            Y(1:dataLength,subjNum)=subjData;

        end

        meanAcrossSubjects = mean(Y,2);
        standardDeviationAcrossSubjects = std(Y,0,2);

        figureNum = figureNum + 1;
        figure(figureNum);
        g = plot(meanAcrossSubjects,'-k');
        set(g,'linewidth',3)
        hold on
        plot(Y)
        g = plot(meanAcrossSubjects-standardDeviationAcrossSubjects,':k');
        set(g,'linewidth',3)
        g = plot(meanAcrossSubjects+standardDeviationAcrossSubjects,':k');
        set(g,'linewidth',3)
        title(strcat(emotion,' video #',num2str(vidNum)))


        %find correlation between subject and mean of all subject
        %TODO: Solve the NaN problem
        %TODO: Create a function that will cleanup the data. Do the
        %interpolation of the timeseries, etc.
        for corrNum = 1:subjNum
            temp=corrcoef(Y(:,corrNum),meanAcrossSubjects)
        end

        temp=corr(Y, meanAcrossSubjects,'rows','complete')

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