%% Esempio pratico di utilizzo di array di 2 microfoni per stimare la DoA (Direction on Arrival) di un suono

clc;
clear all;
close all;

% --- Parametri di Setup ---
DISTANCE = 0.145;      % Distanza tra i microfoni Pixel 8 Pro (14.5 cm)
DISTANCE = 0.07;       % Distanza tra i microfoni PC (7 cm)
SOUND_SPEED = 343;     % Velocità del suono in metri/secondo
WINDOW_SIZE_SEC = 0.05; % Dimensione della finestra per l'analisi (0.5 secondi)

% --- PARAMETRO DI CORREZIONE FISSO ---
% L'utente ha notato un offset di +10 gradi quando è frontale (0°).
% Applichiamo un offset negativo per compensare.

% ANGLE_OFFSET_DEG = -10; % quando uso l'audio del PC devo togliere lo
% shift
ANGLE_OFFSET_DEG = 0;
disp(['ATTENZIONE: Verrà applicata una correzione angolare fissa di ', num2str(ANGLE_OFFSET_DEG), ' gradi a tutte le stime.']);

% --- Caricamento e Analisi Iniziale ---
%[audio, Fs] = audioread("PC Stereo.wav");           % File stereo PC
[audio, Fs] = audioread("JBLGO solo 45 gradi.wav");           % File stereo PC


if size(audio, 2) > 2
    audio = audio(:, 1:2);
end

numSamples = size(audio, 1);
t = (0:numSamples-1) / Fs;

% --- Calcolo dei Parametri per la Stima ---
windowSamples = round(WINDOW_SIZE_SEC * Fs); % Dimensione della finestra in campioni
numFrames = floor(numSamples / windowSamples); % Numero di finestre intere
timeFrames = (0:numFrames-1) * WINDOW_SIZE_SEC + WINDOW_SIZE_SEC/2; % Centro di ogni finestra temporale

% Array per salvare le stime dell'angolo corrette
theta_estimates = zeros(1, numFrames);

disp(['Analisi iniziata: ', num2str(numFrames), ' finestre da ', num2str(WINDOW_SIZE_SEC), ' secondi.']);

% --- Elaborazione Frame-by-Frame (Calcolo e Correzione DOA) ---
for i = 1:numFrames
    startIndex = (i - 1) * windowSamples + 1;
    endIndex = startIndex + windowSamples - 1;

    if endIndex > numSamples
        endIndex = numSamples;
    end

    segment1 = audio(startIndex:endIndex, 1);
    segment2 = audio(startIndex:endIndex, 2);

    % Calcola la correlazione incrociata
    [R, lags] = xcorr(segment1, segment2);

    % Trova il ritardo in campioni
    [~, I] = max(abs(R));
    delay_samples = lags(I);

    % Converti il ritardo in secondi (ITD)
    tau_hat = delay_samples / Fs;

    % --- Calcolo dell'Angolo (DOA) ---
    sin_theta = (tau_hat * SOUND_SPEED) / DISTANCE;
    sin_theta = max(-1, min(1, sin_theta));

    theta_rad = asin(sin_theta);
    theta_deg_raw = rad2deg(theta_rad);

    % APPLICAZIONE DELLA CORREZIONE FISSA
    theta_deg_corrected = theta_deg_raw + ANGLE_OFFSET_DEG;

    % Salva la stima dell'angolo corretta
    theta_estimates(i) = theta_deg_corrected;
end

disp('Calcolo DOA e correzione completati. Inizio visualizzazione dinamica...');

% --- Setup per la Rappresentazione Grafica Dinamica ---

% 1. Figura per il Grafico Polare (DOA Corrente)
h_fig_polar = figure('Name', 'Direzione di Arrivo Corrente (DOA)', 'Position', [100 100 500 500]);
h_ax_polar = polaraxes; 
hold on;
title(h_ax_polar, 'Stima Direzione di Arrivo (DOA Corrente) Calibrata', 'FontSize', 14);

% Configurazione assi polari
rlim(h_ax_polar, [0 1]);
pax = h_ax_polar;
pax.ThetaDir = 'clockwise';
pax.ThetaZeroLocation = 'top';
pax.ThetaTick = [-90 -45 0 45 90 135 180 225 270];
pax.ThetaTickLabel = {'90° (Destra)', '45°', '0° (Fronte)', '-45°', '-90° (Sinistra)', '', '', '', ''};
text(0.5, 0.0, '0°: Fronte | -90°: Sinistra | +90°: Destra', 'Units', 'normalized', 'FontSize', 10, 'HorizontalAlignment', 'center', 'Parent', h_ax_polar);

% Disegna il punto iniziale per inizializzazione
h_polar_point = polarplot(h_ax_polar, deg2rad(theta_estimates(1)), 1, 'o', 'MarkerSize', 15, 'MarkerFaceColor', 'r');


% 2. Figura per il Grafico Tempo-Angolo (DOA Storico)
h_fig_time = figure('Name', 'Angolo di Arrivo nel Tempo', 'Position', [650 100 600 500]);
h_ax_time = axes('Parent', h_fig_time);
h_plot_time = plot(h_ax_time, timeFrames, theta_estimates, 'b-', 'LineWidth', 1);
hold on;
h_marker = plot(h_ax_time, timeFrames(1), theta_estimates(1), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
xlabel(h_ax_time, 'Tempo [s]');
ylabel(h_ax_time, 'Angolo Stimato [Gradi]');
title(h_ax_time, 'Angolo di Arrivo Stimato nel Tempo (Corretto)', 'FontSize', 14);
grid on;
ylim([-100 100]); % Limiti per gli angoli da -90 a +90
xlim([timeFrames(1) timeFrames(end)]);

% Evidenziazione del tempo riprodotto
h_time_highlight = plot(h_ax_time, timeFrames(1), theta_estimates(1), 'r-', 'LineWidth', 3);
uistack(h_marker, 'top'); 


% --- Riproduzione Audio e Loop di Animazione ---
player = audioplayer(audio, Fs);
play(player);

% Loop per l'animazione dinamica
for i = 1:numFrames
    % Tempo di inizio e fine dell'intervallo corrente
    startTime = (i - 1) * WINDOW_SIZE_SEC;
    endTime = i * WINDOW_SIZE_SEC;
    
    % *** AGGIORNAMENTO GRAFICO POLARE ***
    set(h_polar_point, 'ThetaData', deg2rad(theta_estimates(i)), 'RData', 1);
    title(h_ax_polar, ['Stima DOA: ', num2str(theta_estimates(i), '%.1f'), '° (Tempo: ', num2str(timeFrames(i), '%.1f'), ' s)'], 'FontSize', 14);


    % *** AGGIORNAMENTO GRAFICO TEMPO-ANGOLO ***
    set(h_marker, 'XData', timeFrames(i), 'YData', theta_estimates(i));
    
    % Aggiorna la linea di evidenziazione
    set(h_time_highlight, 'XData', timeFrames(1:i), 'YData', theta_estimates(1:i));


    % *** SINCRONIZZAZIONE CON L'AUDIO ***
    elapsedTime = player.CurrentSample / Fs;
    timeToWait = endTime - elapsedTime;
    
    if timeToWait > 0
        pause(timeToWait);
    end
end

% Blocca l'esecuzione finché l'audio non è finito
while isplaying(player)
    pause(0.1);
end

disp('Analisi e riproduzione completate.');