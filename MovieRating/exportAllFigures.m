function [  ] = exportAllFigures(  )
% exportAllFigures
%   helper function to export all figures with print resolution

function exportAllFigures()  %#ok - This function is manually called

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

