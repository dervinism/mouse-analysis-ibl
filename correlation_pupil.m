% Correlate neural activity with pupil area

% Load parameters
params
averagedPupilDownsampling = true;

% Load preprocessed data
preprocessedDataFile = fullfile(processedDataFolder, 'eightprobesPreprocessedData.mat');
load(preprocessedDataFile);

% Correlate individual unit activity with the pupil area
animalNames = fieldnames(infraslowData);
for iAnimal = 1:numel(animalNames)
  animalName = animalNames{iAnimal};
  startTime = infraslowData.(animalName).times(1);
  effectiveSR = round(1/mean(diff(infraslowData.(animalName).times)));
  times = infraslowData.(animalName).times - startTime + 0.5/effectiveSR;
  brainAreas = fieldnames(infraslowData.(animalName).spikeCounts);
  rSpearmanPositiveFraction_perArea = zeros(numel(brainAreas), 1);
  rSpearmanNegativeFraction_perArea = zeros(numel(brainAreas), 1);
  for iArea = 1:numel(brainAreas)
    areaName = brainAreas{iArea};

    % Get spiking data
    brainAreaSpikes = infraslowData.(animalName).spikeCounts.(areaName);
    [brainAreaSpikes, downsampledTimes] = resampleSpikeCounts( ...
      brainAreaSpikes, stepsize=1/effectiveSR, ...
      newStepsize=1/downsampledRate); % Downsample spiking data

    % Get pupil data
    pupilArea = infraslowData.(animalName).pupilArea;
    if averagedPupilDownsampling
      % Average pupil area size (most accurate downsampling)
      averagedPupilArea = movmean(pupilArea, ...
        round(effectiveSR/downsampledRate), 'omitnan');
      downsampledPupilArea = interp1(times, averagedPupilArea, ...
        downsampledTimes, 'linear', 'extrap');
    else
      % Downsample pupil area size
      downsampledPupilArea = interp1(times, pupilArea, downsampledTimes, ...
        'linear', 'extrap'); %#ok<*UNRCH>
    end
    %figure; plot(times, pupilArea); hold on
    %plot(downsampledTimes, downsampledPupilArea); hold off

    [spikingPupilCorr.(animalName).(areaName).rPearson, ...
      spikingPupilCorr.(animalName).(areaName).pvalPearson] = ...
      corrMulti(downsampledPupilArea, brainAreaSpikes, 'Pearson');
    [spikingPupilCorr.(animalName).(areaName).rSpearman, ...
      spikingPupilCorr.(animalName).(areaName).pvalSpearman] = ...
      corrMulti(downsampledPupilArea, brainAreaSpikes, 'Spearman');

    % Calculate correlated cell fractions
    spikingPupilCorr.(animalName).(areaName).rPearsonPositiveFraction = ...
      sum(spikingPupilCorr.(animalName).(areaName).rPearson > 0)/ ...
      numel(spikingPupilCorr.(animalName).(areaName).rPearson);
    spikingPupilCorr.(animalName).(areaName).rPearsonNegativeFraction = ...
      sum(spikingPupilCorr.(animalName).(areaName).rPearson < 0)/ ...
      numel(spikingPupilCorr.(animalName).(areaName).rPearson);
    spikingPupilCorr.(animalName).(areaName).rSpearmanPositiveFraction = ...
      sum(spikingPupilCorr.(animalName).(areaName).rSpearman > 0)/ ...
      numel(spikingPupilCorr.(animalName).(areaName).rSpearman);
    spikingPupilCorr.(animalName).(areaName).rSpearmanNegativeFraction = ...
      sum(spikingPupilCorr.(animalName).(areaName).rSpearman < 0)/ ...
      numel(spikingPupilCorr.(animalName).(areaName).rSpearman);

    rSpearmanPositiveFraction_perArea(iArea) = ...
      spikingPupilCorr.(animalName).(areaName).rPearsonPositiveFraction;
    rSpearmanNegativeFraction_perArea(iArea) = ...
      spikingPupilCorr.(animalName).(areaName).rPearsonNegativeFraction;

    spikingPupilCorr.(animalName).(areaName).timeOfCompletion = datetime;
  end

  [~, areaOrder] = sort(rSpearmanPositiveFraction_perArea, 'descend');
  fractionTable = table(brainAreas(areaOrder), ...
    rSpearmanPositiveFraction_perArea(areaOrder), ...
    rSpearmanNegativeFraction_perArea(areaOrder), ...
    'VariableNames', ...
    {'Brain_area', 'Positive_cell_fraction', 'Negative_cell_fraction'}) %#ok<*NOPTS>
end

% Save data analysis results
analysisResultsFile = fullfile(processedDataFolder, 'eightprobesAnalysisResults.mat');
if exist(analysisResultsFile, 'file')
  load(analysisResultsFile);
end
infraslowAnalyses.spikingPupilCorr = spikingPupilCorr;
save(analysisResultsFile, 'infraslowAnalyses', '-v7.3');