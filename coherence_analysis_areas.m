% Coherence analysis script comparing unit spiking activity with respect to the population rates of different brain areas

areaLabels = {'FrCtx', ...    % Frontal cortex?
              'FrMoCtx', ...  % Frontal motor cortex (premotor, supplementary motor?)
              'SomMoCtx', ... % Somatomotor cortex: Primary motor and the somatosensory cortices
              'SSCtx', ...    % Somatosensory cortex (or secondory somatosensory cortex?)
              'V1', ...
              'V2', ...
              'RSP', ...      % Retrosplenial cortex
              'CP', ...       % Caudoputamen
              'LS', ...       % Lateral septum
              'LH', ...       % Lateral habenula
              'HPF', ...      % Hippocampal formation
              'TH', ...       % Thalamus
              'SC', ...       % Superior colliculus
              'MB'};          % Midbrain

% Look into these brain areas:
% HPF -> RSP -> (FrCtx -> FrMoCtx) -> (SomMoCtx -> SSCtx) -> (V2 -> V1) -> TH

% Load parameters
params
population = 'Full'; % 'Full', 'Positive', or 'Negative'

% Load preprocessed data
preprocessedDataFile = fullfile(processedDataFolder, 'eightprobesPreprocessedData.mat');
load(preprocessedDataFile);

% Load data analysis results
analysisResultsFile = fullfile(processedDataFolder, 'eightprobesAnalysisResults.mat');
load(analysisResultsFile);

% Carry out coherence analysis of individual units wrt population rates of different brain areas
warning('off', 'all');
animalNames = fieldnames(infraslowData);
for iAnimal = 1:numel(animalNames)
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
      disp(['Comparing units in the brain area ' areaName ...
        ' to the population rate in the area ' refAreaName '.']);
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
        for iUnit = 1:numel(brainAreaSpikeTimes)
          excludeInds = spikeProbeIDs == spikeProbeIDs(iUnit) & ...
            abs(verticalCoords - verticalCoords(iUnit)) < exclRad;
          brainAreaPopulationRate(iUnit) = collapseCell( ...
            refBrainAreaSpikeTimes(~excludeInds(:) & includeReference(:)), sortElements='ascend'); %#ok<*SAGROW>
        end
      else
        brainAreaPopulationRate = collapseCell( ...
          refBrainAreaSpikeTimes(includeReference), sortElements='ascend');
      end
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
        parallelise=true);
      spikingSpikingCoh.(animalName).(areaName).(refAreaName).unitIDs = ...
        infraslowData.(animalName).unitIDs.(areaName)(includeSignal);
      spikingSpikingCoh.(animalName).(areaName).(refAreaName).timeOfCompletion = datetime;
    end
  end
end

% Save data analysis results
containerName = ['spikingSpikingCoh' population];
infraslowAnalyses.(containerName) = spikingSpikingCoh;
save(analysisResultsFile, 'infraslowAnalyses', '-v7.3');
warning('on', 'all');