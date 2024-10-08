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

% Save data analysis results
analysisResultsFile = fullfile(processedDataFolder, 'eightprobesAnalysisResults.mat');
load(analysisResultsFile);