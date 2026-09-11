%% Practical example of using a 2-microphone array to estimate the DoA (Direction of Arrival) of a sound
% Brambilla Matteo 2025

clc;
clear all;
close all;

% --- Setup Parameters ---
% DISTANCE = 0.145;      % Distance between Pixel 8 Pro microphones (14.5 cm)
DISTANCE = 0.07;     % Distance between PC microphones (7 cm)
SOUND_SPEED = 343;     % Speed of sound in meters/second
WINDOW_SIZE_SEC = 0.05; % Analysis window size (0.05 seconds)

% --- SMOOTHING PARAMETER ---
% Change this value to adjust the smoothness. 
% 1 = no smoothing. Higher values (e.g., 5, 10, 20) = smoother, but slower to react.
MOVING_AVERAGE_WINDOW = 10; 

% --- FIXED CORRECTION PARAMETER ---
ANGLE_OFFSET_DEG = 0;
disp(['WARNING: A fixed angular correction of ', num2str(ANGLE_OFFSET_DEG), ' degrees will be applied to all estimates.']);

% --- Audio Loading and Initial Analysis ---
[audio, Fs] = audioread("PC Stereo.wav");  % Target audio file
%[audio, Fs] = audioread("JBLGO solo 45 gradi.wav");  % Target audio file

if size(audio, 2) > 2
    audio = audio(:, 1:2);
end
numSamples = size(audio, 1);
t = (0:numSamples-1) / Fs;

% --- Calculation of Estimation Parameters ---
windowSamples = round(WINDOW_SIZE_SEC * Fs); % Window size in samples
numFrames = floor(numSamples / windowSamples); % Number of full frames
timeFrames = (0:numFrames-1) * WINDOW_SIZE_SEC + WINDOW_SIZE_SEC/2; % Center of each time frame

% Array to save the raw corrected angle estimates
theta_estimates = zeros(1, numFrames);
disp(['Analysis started: ', num2str(numFrames), ' frames of ', num2str(WINDOW_SIZE_SEC), ' seconds.']);

% --- Frame-by-Frame Processing (DoA Calculation and Correction) ---
for i = 1:numFrames
    startIndex = (i - 1) * windowSamples + 1;
    endIndex = startIndex + windowSamples - 1;
    
    if endIndex > numSamples
        endIndex = numSamples;
    end
    
    segment1 = audio(startIndex:endIndex, 1);
    segment2 = audio(startIndex:endIndex, 2);
    
    % Calculate cross-correlation
    [R, lags] = xcorr(segment1, segment2);
    
    % Find the delay in samples
    [~, I] = max(abs(R));
    delay_samples = lags(I);
    
    % Convert the delay into seconds (ITD)
    tau_hat = delay_samples / Fs;
    
    % --- Angle Calculation (DoA) ---
    sin_theta = (tau_hat * SOUND_SPEED) / DISTANCE;
    sin_theta = max(-1, min(1, sin_theta));
    theta_rad = asin(sin_theta);
    theta_deg_raw = rad2deg(theta_rad);
    
    % APPLY FIXED CORRECTION
    theta_deg_corrected = theta_deg_raw + ANGLE_OFFSET_DEG;
    
    % Save the raw angle estimate
    theta_estimates(i) = theta_deg_corrected;
end

% --- Apply Moving Average Filter ---
% This smooths out the fast, jittery changes in the angle
theta_estimates_smoothed = movmean(theta_estimates, MOVING_AVERAGE_WINDOW);

disp('DoA calculation, correction, and smoothing completed. Starting dynamic visualization...');

% --- Setup for Dynamic Graphical Representation ---

% 1. Figure for Polar Plot (Current Smoothed DoA)
h_fig_polar = figure('Name', 'Current Direction of Arrival (DoA)', 'Position', [100 100 500 500]);
h_ax_polar = polaraxes; 
hold on;
title(h_ax_polar, 'Smoothed Direction of Arrival Estimate', 'FontSize', 14);

% Polar axes configuration
rlim(h_ax_polar, [0 1]);
pax = h_ax_polar;
pax.ThetaDir = 'clockwise';
pax.ThetaZeroLocation = 'top';
pax.ThetaTick = [-90 -45 0 45 90 135 180 225 270];
pax.ThetaTickLabel = {'90° (Right)', '45°', '0° (Front)', '-45°', '-90° (Left)', '', '', '', ''};
text(0.5, 0.0, '0°: Front | -90°: Left | +90°: Right', 'Units', 'normalized', 'FontSize', 10, 'HorizontalAlignment', 'center', 'Parent', h_ax_polar);

% Draw the initial point for initialization (using smoothed data)
h_polar_point = polarplot(h_ax_polar, deg2rad(theta_estimates_smoothed(1)), 1, 'o', 'MarkerSize', 15, 'MarkerFaceColor', 'r');

% 2. Figure for Time-Angle Plot (Historical DoA)
h_fig_time = figure('Name', 'Angle of Arrival over Time', 'Position', [650 100 600 500]);
h_ax_time = axes('Parent', h_fig_time);

% Plot the RAW data in the background (light color, dashed or thin)
plot(h_ax_time, timeFrames, theta_estimates, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5, 'DisplayName', 'Raw Data');
hold on;

% Plot the SMOOTHED data in the foreground (bold color)
h_plot_time = plot(h_ax_time, timeFrames, theta_estimates_smoothed, 'b-', 'LineWidth', 2, 'DisplayName', 'Smoothed Data');

% Animation marker for the smoothed data
h_marker = plot(h_ax_time, timeFrames(1), theta_estimates_smoothed(1), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');

xlabel(h_ax_time, 'Time [s]');
ylabel(h_ax_time, 'Estimated Angle [Degrees]');
title(h_ax_time, 'Angle of Arrival over Time (Raw vs Smoothed)', 'FontSize', 14);
legend('Location', 'northeast');
grid on;
ylim([-100 100]); % Limits for angles from -90 to +90
xlim([timeFrames(1) timeFrames(end)]);

% Highlight the playback time on the smoothed line
h_time_highlight = plot(h_ax_time, timeFrames(1), theta_estimates_smoothed(1), 'r-', 'LineWidth', 3);
uistack(h_marker, 'top'); 

% --- Audio Playback and Animation Loop ---
player = audioplayer(audio, Fs);
play(player);

% Loop for dynamic animation
for i = 1:numFrames
    % Start and end time of the current interval
    startTime = (i - 1) * WINDOW_SIZE_SEC;
    endTime = i * WINDOW_SIZE_SEC;
    
    % *** POLAR PLOT UPDATE (Using Smoothed Data) ***
    set(h_polar_point, 'ThetaData', deg2rad(theta_estimates_smoothed(i)), 'RData', 1);
    title(h_ax_polar, ['Smoothed DoA: ', num2str(theta_estimates_smoothed(i), '%.1f'), '° (Time: ', num2str(timeFrames(i), '%.1f'), ' s)'], 'FontSize', 14);
    
    % *** TIME-ANGLE PLOT UPDATE (Using Smoothed Data) ***
    set(h_marker, 'XData', timeFrames(i), 'YData', theta_estimates_smoothed(i));
    
    % Update the highlight line
    set(h_time_highlight, 'XData', timeFrames(1:i), 'YData', theta_estimates_smoothed(1:i));
    
    % *** SYNCHRONIZATION WITH AUDIO ***
    elapsedTime = player.CurrentSample / Fs;
    timeToWait = endTime - elapsedTime;
    
    if timeToWait > 0
        pause(timeToWait);
    end
end

% Block execution until audio finishes playing
while isplaying(player)
    pause(0.1);
end
disp('Analysis and playback completed.');