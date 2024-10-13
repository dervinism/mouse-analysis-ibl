% Figures showing distributions of preferred unit firing phase wrt the pupila area

% Load parameters
params

% Load data analysis results
analysisResultsFile = fullfile(processedDataFolder, 'eightprobesAnalysisResults.mat');
if exist(analysisResultsFile, 'file')
  load(analysisResultsFile);
end

% Extract data
animalNames = fieldnames(infraslowAnalyses.spikingPupilCorr);
positiveCellFractions = nan(numel(animalNames), numel(areaLabels));
for iAnimal = 1:numel(animalNames)
  animalName = animalNames{iAnimal};
  brainAreas = fieldnames(infraslowAnalyses.spikingPupilCorr.(animalName));
  for iArea = 1:numel(brainAreas)
    areaName = brainAreas{iArea};
    areaInd = ismember(areaLabels, areaName);
    rSpearman_BrainArea = ...
      infraslowAnalyses.spikingPupilCoh.(animalName).(areaName).rSpearman;
    positiveCellFractions(iAnimal, areaInd) = ...
      sum(rSpearman_BrainArea >= 0)/numel(rSpearman_BrainArea);
  end
end

% Group data
positiveCellFractionsPerArea = {};
for iArea = 1:numel(areaLabels)
  positiveCellFractionsPerArea{iArea} = positiveCellFractions(:,iArea); %#ok<*SAGROW>
  if sum(isnan(positiveCellFractions(:,iArea))) == 1
    ind = isnan(positiveCellFractions(:,iArea));
    positiveCellFractionsPerArea{iArea}(ind) = ...
      datamean(positiveCellFractionsPerArea{iArea});
  elseif sum(isnan(positiveCellFractions(:,iArea))) == 2
    positiveCellFractionsPerArea{iArea} = [ ...
      datamean(positiveCellFractionsPerArea{iArea}) + 1e-3;
      datamean(positiveCellFractionsPerArea{iArea});
      datamean(positiveCellFractionsPerArea{iArea}) - 1e-3];
  end
end

% Get descriptive stats
[positiveCellFractionMean, positiveCellFractionCI95] = datamean(positiveCellFractions);
positiveCellFractionCI95(isnan(positiveCellFractionCI95)) = 0;

% Make violin plots for each animal
fontSize = 18;
fH = figure;
%colourCodes = {[0, 0.5, 0], [0.4660, 0.6740, 0.1880], [0, 0.4470, 0.7410], [0.3010, 0.7450, 0.9330]};
violinplotAugmented(positiveCellFractionsPerArea, areaLabels, ...
  dataMeans=positiveCellFractionMean, ...
  dataCIs=positiveCellFractionMean+positiveCellFractionCI95, ...
  Width=0.2, medianPlot=false, ShowNotches=false, edgeVisibility=false);
hold on
p1 = plot([5 5],[0 10], 'k', 'LineWidth',1);
p2 = plot([5 5],[0 10], 'k--', 'LineWidth',0.5);
hold off
ylabel('Fraction', 'FontSize',fontSize, 'FontWeight','bold');

% Tidy the figure
set(fH, 'Color', 'white');
ax = gca;
set(ax, 'box', 'off');
set(ax, 'TickDir', 'out');
yTicks = get(ax, 'YTick');
if numel(yTicks) > 8
  set(ax, 'YTick', yTicks(1:2:end));
end
ax.FontSize = fontSize - 4;
set(get(ax, 'XAxis'), 'FontWeight', 'bold');
set(get(ax, 'YAxis'), 'FontWeight', 'bold');
xlim([0.5 numel(positiveCellFractionsPerArea)+0.5])
ylim([0 1])

legend([p1 p2], {'Mean', '95% CI'})
legend('boxoff');