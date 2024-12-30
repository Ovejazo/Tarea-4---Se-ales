% Read and parse JSON file
jsonStr = fileread('examples.json');
jsonData = jsondecode(jsonStr);

% Initialize counter for correctly detected notes
correctCount = 0;
totalCount = length(jsonData);

% MIDI note to frequency conversion constants
A4_MIDI = 69;    % MIDI note number for A4
A4_FREQ = 440;   % A4 frequency in Hz

% Iterate through each entry in the JSON structure
fileNames = fieldnames(jsonData);

for i = 1:length(fileNames)
    currentFile = fileNames{i};
    
    % Construct full filename with .wav extension
    audioFileName = fullfile([currentFile, '.wav']);
    
    try
        % Read audio file
        [y, fs] = audioread(audioFileName);
        
        % Get ground truth MIDI pitch from JSON
        truePitch = jsonData.(currentFile).pitch;
        
        % Take first 3 seconds of audio (where note is sustained)
        samples = min(round(3 * fs), length(y));
        signal = y(1:samples);
        
        % Convert stereo to mono if necessary
        if size(signal, 2) > 1
            signal = mean(signal, 2);
        end
        
        % Apply Hanning window to reduce spectral leakage
        window = hanning(length(signal));
        windowed_signal = signal .* window;
        
        % Compute FFT
        N = length(windowed_signal);
        Y = fft(windowed_signal);
        
        % Get magnitude spectrum (only first half due to symmetry)
        P2 = abs(Y/N);
        P1 = P2(1:floor(N/2)+1);
        P1(2:end-1) = 2*P1(2:end-1);
        
        % Create frequency axis
        f = fs * (0:(N/2))/N;
        
        % Find peaks in spectrum
        [peaks, locs] = findpeaks(P1, 'MinPeakHeight', max(P1)*0.1);
        
        % Get frequency with maximum magnitude in the expected range (20Hz - 5000Hz)
        validFreqs = f(locs);
        validFreqs = validFreqs(validFreqs >= 20 & validFreqs <= 5000);
        if ~isempty(validFreqs)
            fundamental = validFreqs(1); % Take the lowest frequency peak
        else
            fundamental = 0;
        end
        
        % Convert frequency to MIDI note number
        if fundamental > 0
            detectedPitch = round(12 * log2(fundamental/A4_FREQ) + A4_MIDI);
        else
            detectedPitch = 0;
        end
        
        % Compare with ground truth
        if detectedPitch == truePitch
            correctCount = correctCount + 1;
        end
        
        % Print progress and results for each file
        fprintf('File: %s\n', currentFile);
        fprintf('True Pitch: %d, Detected Pitch: %d\n', truePitch, detectedPitch);
        
    catch e
        fprintf('Error processing file %s: %s\n', audioFileName, e.message);
        continue;
    end
end

% Calculate and display final accuracy
accuracy = (correctCount / totalCount) * 100;
fprintf('\nFinal Results:\n');
fprintf('Correctly detected %d out of %d notes (%.2f%%)\n', ...
        correctCount, totalCount, accuracy);