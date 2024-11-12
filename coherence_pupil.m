% Coherence analysis script comparing unit spiking activity with respect to the pupil area

% Load parameters
params
parallelCores = 8;

% Load preprocessed data
preprocessedDataFile = fullfile(processedDataFolder, 'eightprobesPreprocessedData.mat');
load(preprocessedDataFile);

% Load data analysis results
analysisResultsFile = fullfile(processedDataFolder, 'eightprobesAnalysisResults.mat');
if exist(analysisResultsFile, 'file')
  load(analysisResultsFile);
end

% Set up parallelisation
warning('off', 'all');
if parallelCores > 1
  parallelise = true;
  p = gcp('nocreate');
  if isempty(p)
    parpool(parallelCores);
  end
  parfevalOnAll(@warning,0,'off','all');
else
  parallelise = false;
end

% Carry out coherence analysis of individual units wrt the pupil area
warning('off', 'all');
animalNames = fieldnames(infraslowData);
for iAnimal = 1:numel(animalNames)
  animalName = animalNames{iAnimal};
  pupilArea = infraslowData.(animalName).pupilArea;
  times = infraslowData.(animalName).times;
  effectiveSR = round(1/mean(diff(times)));
  brainAreas = fieldnames(infraslowData.(animalName).spikeCounts);
  for iArea = 1:numel(brainAreas)
    areaName = brainAreas{iArea};
    progressIndicator = [num2str(iAnimal) '.' num2str(iArea) '/' ...
        num2str(numel(animalNames)) '.' num2str(numel(brainAreas))];
    disp([progressIndicator ' Comparing units in ' animalName ' brain area ' ...
      areaName ' to the pupil area.']);
    brainAreaSpikeCounts = infraslowData.(animalName).spikeCounts.(areaName);
    brainAreaSpikeTimes = infraslowData.(animalName).spikeTimes.(areaName);
    [spikingPupilCoh.(animalName).(areaName).fullCoherence, ...
      spikingPupilCoh.(animalName).(areaName).half1Coherence, ...
      spikingPupilCoh.(animalName).(areaName).half2Coherence, ...
      spikingPupilCoh.(animalName).(areaName).fullInterpCoherence, ...
      spikingPupilCoh.(animalName).(areaName).half1InterpCoherence, ...
      spikingPupilCoh.(animalName).(areaName).half2InterpCoherence] = ...
      coherence(brainAreaSpikeTimes, pupilArea(1:size(brainAreaSpikeCounts,2)), ...
      stepsize=1/effectiveSR, startTime=times(1), freqGrid=FOI, ...
      typespk1='pb', typespk2='c', winfactor=winfactor, ...
      freqfactor=freqfactor, tapers=tapers, halfCoherence=true, ...
      parallelise=parallelise);
    spikingPupilCoh.(animalName).(areaName).timeOfCompletion = datetime;
  end

  % Save data analysis results
  infraslowAnalyses.spikingPupilCoh.(animalName) = spikingPupilCoh.(animalName);
  save(analysisResultsFile, 'infraslowAnalyses', '-v7.3');
end

% Switch on warnings
if parallelCores > 1
  parfevalOnAll(@warning,0,'on','all');
end
warning('on', 'all');