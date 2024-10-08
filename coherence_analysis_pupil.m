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

% Load preprocessed data
preprocessedDataFile = fullfile(processedDataFolder, 'eightprobesPreprocessedData.mat');
load(preprocessedDataFile);

% Carry out coherence analysis of individual units wrt the pupil area
animalNames = fieldnames(infraslowData);
for iAnimal = 1:numel(animalNames)
  animalName = animalNames{iAnimal};
  pupilArea = infraslowData.(animalName).pupilArea;
  times = infraslowData.(animalName).times;
  effectiveSR = round(1/mean(diff(times)));
  brainAreas = fieldnames(infraslowData.(animalName).spikeCounts);
  for iArea = 1:numel(brainAreas)
    areaName = brainAreas{iArea};
    brainAreaSpikeCounts = infraslowData.(animalName).spikeCounts.(areaName);
    brainAreaSpikeTimes = infraslowData.(animalName).spikeTimes.(areaName);
    [fullCoherence, half1Coherence, half2Coherence, ...
      fullInterpCoherence, half1InterpCoherence, half2InterpCoherence] = ...
      coherence(brainAreaSpikeTimes, pupilArea(1:size(brainAreaSpikeCounts,2)), ...
      stepsize=1/effectiveSR, startTime=times(1), freqGrid=FOI, ...
      typespk1='pb', typespk2='c', winfactor=winfactor, ...
      freqfactor=freqfactor, tapers=tapers, halfCoherence=true, ...
      parallelise=true);

  end
end