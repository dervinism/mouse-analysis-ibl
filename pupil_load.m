% Parameters
eyeDataFolder = 'C:\Users\44079\Work\Leicester\infraslow-dynamics\03_data\004_ibl_eightprobes_raw_derived\8378360\EightProbeDLC-MD-2024-10-02\videos';
eyeVideoFolder = 'C:\Users\44079\Work\Leicester\infraslow-dynamics\03_data\004_ibl_eightprobes_raw_derived\8378360\EightProbeVideos';
processedDataFolder = 'C:\Users\44079\Work\Leicester\infraslow-dynamics\04_data_analysis\004_ibl_eightprobes';
mstr = {'Krebs','Waksman','Robbins'}; % mouse names
tstart = [3811 3633 3323]; % start of spontaneous activity in each mouse

% Load preprocessed data
preprocessedDataFile = fullfile(processedDataFolder, 'eightprobesPreprocessedData.mat');
load(preprocessedDataFile);

% Extract DLC pupila area and assign it to correct animal
% Load eye data
eyeDataFiles = dir([eyeDataFolder filesep '*.csv']);
for iFile = 1:numel(eyeDataFiles)
  T = readtable([eyeDataFiles(iFile).folder filesep eyeDataFiles(iFile).name]);
  leftIrisCoords = table2array(T(:,2:3));
  rightIrisCoords = table2array(T(:,8:9));
  eyeRad1 = vecnorm(leftIrisCoords' - rightIrisCoords')';
  topIrisCoords = table2array(T(:,5:6));
  bottomIrisCoords = table2array(T(:,11:12));
  eyeRad2 = vecnorm(topIrisCoords' - bottomIrisCoords')';
  pupilArea = pi*eyeRad1.*eyeRad2;
  %figure; plot(pupilArea)

  % Identify animal ID
  for iAnimal = 1:numel(mstr)
    if contains(eyeDataFiles(iFile).name, mstr{iAnimal})
      mouseID = iAnimal;
    end
  end
  mouseName = mstr{mouseID};

  % Filter pupil data
  timestampData = readNPY(fullfile(eyeVideoFolder, sprintf('%s_eye.timestamps.npy',mouseName)));
  sr = 1/mean(diff(timestampData(:,2)));
  d = designfilt('lowpassiir', ...
    'PassbandFrequency',1.5, 'StopbandFrequency',2, ...
    'PassbandRipple',0.5, 'StopbandAttenuation',1, ...
    'DesignMethod','butter', 'SampleRate',sr);
  pupilAreaFilt = filtfilt(d,pupilArea);
  %figure; plot(pupilArea); hold on; plot(pupilAreaFilt); hold off

  % Trim data
  processedAnimalData = infraslowData.(mouseName);
  nFramesDLC = numel(pupilAreaFilt);
  vr = VideoReader(fullfile(eyeVideoFolder, sprintf('%s_eye.mp4',mouseName)));
  nFramesMatlab = get(vr, 'NumFrames');
  assert(nFramesDLC == nFramesMatlab, 'DLC video frame count does not match the count infered directly from the video file.')
  allTimestamps = interp1(timestampData(:,1), timestampData(:,2), 1:nFramesDLC, 'linear', 'extrap');
  trimmedPupilArea = interp1(allTimestamps', pupilAreaFilt, processedAnimalData.times');
  %figure; plot(processedAnimalData.times, trimmedPupilArea)

  % Store data
  infraslowData.(mouseName).pupilArea = trimmedPupilArea';
end

% Save preprocessed data
save(preprocessedDataFile, 'infraslowData', '-v7.3');