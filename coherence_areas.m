% Coherence analysis script comparing unit spiking activity with respect to the population rates of different brain areas

% Load parameters
params
population = 'Full'; % 'Full', 'Positive', or 'Negative'
parallelCores = 1;

% Load preprocessed data
preprocessedDataFile = fullfile(processedDataFolder, 'eightprobesPreprocessedData.mat');
load(preprocessedDataFile);

% Load data analysis results
analysisResultsFile = fullfile(processedDataFolder, 'eightprobesAnalysisResults.mat');
load(analysisResultsFile);

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

% Carry out coherence analysis of individual units wrt population rates of different brain areas
warning('off', 'all');
animalNames = fieldnames(infraslowData);
for iAnimal = 2:numel(animalNames) %1:numel(animalNames)
  animalName = animalNames{iAnimal};
  times = infraslowData.(animalName).times;
  effectiveSR = round(1/mean(diff(times)));
  brainAreas = fieldnames(infraslowData.(animalName).spikeCounts);
  for iArea = 1:numel(brainAreas)
    areaName = brainAreas{iArea};
    brainAreaSpikeTimes = infraslowData.(animalName).spikeTimes.(areaName);
    if strcmpi(population, 'Full')
      includeSignal = logical(infraslowAnalyses.spikingPupilCorr.(animalName).(areaName).rSpearman);
    elseif strcmpi(population, 'Positive') %#ok<*UNRCH>
      includeSignal = infraslowAnalyses.spikingPupilCorr.(animalName).(areaName).rSpearman >= 0;
    elseif strcmpi(population, 'Negative')
      includeSignal = infraslowAnalyses.spikingPupilCorr.(animalName).(areaName).rSpearman < 0;
    else
      error('Unsupported population type.')
    end
    for iRefArea = 1:numel(brainAreas)
      refAreaName = brainAreas{iRefArea};
      progressIndicator = [num2str(iAnimal) '.' num2str(iArea) '.' num2str(iRefArea) '/' ...
        num2str(numel(animalNames)) '.' num2str(numel(brainAreas)) '.' num2str(numel(brainAreas))];
      disp([progressIndicator ' Comparing units in ' animalName ' brain area ' ...
        areaName ' to the population rate in the area ' refAreaName '.']);
      refBrainAreaSpikeTimes = infraslowData.(animalName).spikeTimes.(refAreaName);
      if strcmpi(population, 'Full')
        includeReference = logical(infraslowAnalyses.spikingPupilCorr.(animalName).(refAreaName).rSpearman);
      elseif strcmpi(population, 'Positive') %#ok<*UNRCH>
        includeReference = infraslowAnalyses.spikingPupilCorr.(animalName).(refAreaName).rSpearman >= 0;
      elseif strcmpi(population, 'Negative')
        includeReference = infraslowAnalyses.spikingPupilCorr.(animalName).(refAreaName).rSpearman < 0;
      end
      if strcmpi(areaName, refAreaName)
        spikeProbeIDs = infraslowData.(animalName).spikeProbeIDs.(refAreaName);
        verticalCoords = infraslowData.(animalName).verticalCoords.(refAreaName);
        spikingSpikingCoh.(animalName).(areaName).(refAreaName).fullCoherence = [];
        spikingSpikingCoh.(animalName).(areaName).(refAreaName).half1Coherence = [];
        spikingSpikingCoh.(animalName).(areaName).(refAreaName).half2Coherence = [];
        spikingSpikingCoh.(animalName).(areaName).(refAreaName).fullInterpCoherence = [];
        spikingSpikingCoh.(animalName).(areaName).(refAreaName).half1InterpCoherence = [];
        spikingSpikingCoh.(animalName).(areaName).(refAreaName).half2InterpCoherence = [];
        for iUnit = 1:numel(brainAreaSpikeTimes)
          if includeSignal(iUnit)
            excludeInds = spikeProbeIDs == spikeProbeIDs(iUnit) & ...
              abs(verticalCoords - verticalCoords(iUnit)) < exclRad;
            brainAreaPopulationRate = collapseCell(refBrainAreaSpikeTimes( ...
              ~excludeInds(:) & includeReference(:)), sortElements='ascend'); %#ok<*SAGROW>
            [fullCoherenceTemp, half1CoherenceTemp, half2CoherenceTemp, ...
              fullInterpCoherenceTemp, half1InterpCoherenceTemp, half2InterpCoherenceTemp] = ...
              coherence(brainAreaSpikeTimes(iUnit), brainAreaPopulationRate, ...
              stepsize=1/effectiveSR, startTime=times(1), freqGrid=FOI, ...
              typespk1='pb', typespk2='pb', winfactor=winfactor, ...
              freqfactor=freqfactor, tapers=tapers, halfCoherence=true, ...
              parallelise=false);
            spikingSpikingCoh.(animalName).(areaName).(refAreaName).fullCoherence = ...
              [spikingSpikingCoh.(animalName).(areaName).(refAreaName).fullCoherence; fullCoherenceTemp];
            spikingSpikingCoh.(animalName).(areaName).(refAreaName).half1Coherence = ...
              [spikingSpikingCoh.(animalName).(areaName).(refAreaName).half1Coherence; half1CoherenceTemp];
            spikingSpikingCoh.(animalName).(areaName).(refAreaName).half2Coherence = ...
              [spikingSpikingCoh.(animalName).(areaName).(refAreaName).half2Coherence; half2CoherenceTemp];
            spikingSpikingCoh.(animalName).(areaName).(refAreaName).fullInterpCoherence = ...
              [spikingSpikingCoh.(animalName).(areaName).(refAreaName).fullInterpCoherence; fullInterpCoherenceTemp];
            spikingSpikingCoh.(animalName).(areaName).(refAreaName).half1InterpCoherence = ...
              [spikingSpikingCoh.(animalName).(areaName).(refAreaName).half1InterpCoherence; half1InterpCoherenceTemp];
            spikingSpikingCoh.(animalName).(areaName).(refAreaName).half2InterpCoherence = ...
              [spikingSpikingCoh.(animalName).(areaName).(refAreaName).half2InterpCoherence; half2InterpCoherenceTemp];
          end
        end
      else
        brainAreaPopulationRate = collapseCell( ...
          refBrainAreaSpikeTimes(includeReference), sortElements='ascend');
        [spikingSpikingCoh.(animalName).(areaName).(refAreaName).fullCoherence, ...
          spikingSpikingCoh.(animalName).(areaName).(refAreaName).half1Coherence, ...
          spikingSpikingCoh.(animalName).(areaName).(refAreaName).half2Coherence, ...
          spikingSpikingCoh.(animalName).(areaName).(refAreaName).fullInterpCoherence, ...
          spikingSpikingCoh.(animalName).(areaName).(refAreaName).half1InterpCoherence, ...
          spikingSpikingCoh.(animalName).(areaName).(refAreaName).half2InterpCoherence] = ...
          coherence(brainAreaSpikeTimes(includeSignal), brainAreaPopulationRate, ...
          stepsize=1/effectiveSR, startTime=times(1), freqGrid=FOI, ...
          typespk1='pb', typespk2='pb', winfactor=winfactor, ...
          freqfactor=freqfactor, tapers=tapers, halfCoherence=true, ...
          parallelise=parallelise);
      end
      spikingSpikingCoh.(animalName).(areaName).(refAreaName).unitIDs = ...
        infraslowData.(animalName).unitIDs.(areaName)(includeSignal);
      spikingSpikingCoh.(animalName).(areaName).(refAreaName).timeOfCompletion = datetime;
    end
  end
  
  % Save data analysis results
  containerName = ['spikingSpikingCoh' population];
  infraslowAnalyses.(containerName).(animalName) = spikingSpikingCoh.(animalName);
  save(analysisResultsFile, 'infraslowAnalyses', '-v7.3');
end

% Switch on warnings
if parallelCores > 1
  parfevalOnAll(@warning,0,'on','all');
end
warning('on', 'all');