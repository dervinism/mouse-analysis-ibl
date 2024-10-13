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
areaPhase = cell(size(areaLabels));
for iAnimal = 1:numel(animalNames)
  animalName = animalNames{iAnimal};
  brainAreas = fieldnames(infraslowAnalyses.spikingPupilCorr.(animalName));
  for iArea = 1:numel(brainAreas)
    areaName = brainAreas{iArea};
    phase = infraslowAnalyses.spikingPupilCoh.(animalName).(areaName).fullInterpCoherence.phase;
    areaFrequencies = infraslowAnalyses.spikingPupilCoh.(animalName).(areaName).fullInterpCoherence.frequency(1,:);
    fInds = ismember(areaFrequencies, FOI);
    
    % Agregate data
    areaInd = ismember(areaLabels, areaName);
    if isempty(areaPhase{areaInd})
      areaPhase{areaInd} = phase(:,fInds);
    else
      areaPhase{areaInd} = [areaPhase{iArea}; phase(:,fInds)];
    end
  end
end

% Bin phase values to histograms
binCounts = cell(size(areaPhase));
binLocs = cell(size(areaPhase));
totalCounts = cell(size(areaPhase));
phaseMeans = cell(size(areaPhase));
phaseSDs = cell(size(areaPhase));
significantFractions = cell(size(areaPhase));
for iArea = 1:numel(areaPhase)
  [binCounts{iArea}, binLocs{iArea}, totalCounts{iArea}, ...
    significantFractions{iArea}, phaseMeans{iArea}, phaseSDs{iArea}] = ...
    phaseHistrogram(areaPhase{iArea}, centre=0, nBins=10);
end

% Plot phase histograms
if ~exist(figFolder, 'dir')
  mkdir(figFolder);
end
for iArea = 1:numel(areaPhase)
  for iFreq = 1:numel(FOI)
    nValues = round(totalCounts{iArea}(iFreq)/significantFractions{iArea}(iFreq));
    if isnan(nValues)
      nValues = 0;
    end
    text2display = {[num2str(totalCounts{iArea}(iFreq)) '/' num2str(nValues)]};
    figTitle = ['Phase histogram: ' areaLabels{iArea} ' ' num2str(FOI(iFreq)) 'Hz'];
    fH = phaseHistogramPlot(binCounts{iArea}(:,iFreq), ...
      dataMean=phaseMeans{iArea}(iFreq), figText=text2display, ...
      figTitle=figTitle, figPath=figFolder);
  end
end