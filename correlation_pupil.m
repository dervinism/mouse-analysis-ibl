% Correlate neural activity with pupil area

% Load parameters
params

% Load preprocessed data
preprocessedDataFile = fullfile(processedDataFolder, 'eightprobesPreprocessedData.mat');
load(preprocessedDataFile);

% Correlate individual unit activity with the pupil area
animalNames = fieldnames(infraslowData);
for iAnimal = 1:numel(animalNames)
  animalName = animalNames{iAnimal};
  pupilArea = infraslowData.(animalName).pupilArea;
  times = infraslowData.(animalName).times;
  effectiveSR = round(1/mean(diff(times)));
  brainAreas = fieldnames(infraslowData.(animalName).spikeCounts);
  for iArea = 1:numel(brainAreas)
    areaName = brainAreas{iArea};
    brainAreaSpikes = infraslowData.(animalName).spikeCounts.(areaName);
    [brainAreaSpikes, downsampledTimes] = resampleSpikeCounts( ...
      brainAreaSpikes, stepsize=1/effectiveSR, ...
      newStepsize=1/downsampledRate); % Downsample spiking data
    downsampledPupilArea = interp1(times, pupilArea, downsampledTimes, ...
      'linear', 'extrap'); % Downsample pupil area
    [spikingPupilCorr.(animalName).(areaName).rPearson, ...
      spikingPupilCorr.(animalName).(areaName).pvalPearson] = ...
      corrMulti(downsampledPupilArea, brainAreaSpikes, 'Pearson');
    [spikingPupilCorr.(animalName).(areaName).rSpearman, ...
      spikingPupilCorr.(animalName).(areaName).pvalSpearman] = ...
      corrMulti(downsampledPupilArea, brainAreaSpikes, 'Spearman');
    spikingPupilCorr.(animalName).(areaName).timeOfCompletion = datetime;
  end
  
end

% Save data analysis results
analysisResultsFile = fullfile(processedDataFolder, 'eightprobesAnalysisResults.mat');
if exist(analysisResultsFile, 'file')
  load(analysisResultsFile);
end
infraslowAnalyses.spikingPupilCorr = spikingPupilCorr;
save(analysisResultsFile, 'infraslowAnalyses', '-v7.3');