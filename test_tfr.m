% test time frequency representation analysis
clear all

% load data 
load('./data/data_task.mat')

% tfr with fixed-length window
cfg              = [];
cfg.output       = 'pow';
cfg.channel      = 'all';
cfg.method       = 'mtmconvol';
cfg.taper        = 'hanning';
cfg.foi          = 2:2:30;                         % analysis 2 to 30 Hz in steps of 2 Hz
cfg.t_ftimwin    = ones(length(cfg.foi),1).*0.5;   % length of time window = 0.5 sec
cfg.toi          = -1:0.05:1;                      % the time window "slides" from -0.5 to 1.5 in 0.05 sec steps
TFRhann_visc = ft_freqanalysis(cfg, data_visc);    % visual stimuli
TFRhann_audc = ft_freqanalysis(cfg, data_audc);    % auditory stimuli

% visualise the results on all sensors
cfg = [];
cfg.baseline     = [-0.5 -0.3];
cfg.baselinetype = 'absolute';
cfg.showlabels   = 'yes';
cfg.layout       = 'easycapM10.mat';
figure; ft_multiplotTFR(cfg, TFRhann_visc);

% -------------------------------------
% TFR with morlet wavelets 

% important parameter is the "width". It determines the width of of the
% wavelets in number of cycles. Small width values increase the temporal
% resolution at the expense of frequency resolution and vice versa. 
cfg = [];
cfg.channel    = 'all';
cfg.method     = 'wavelet';
cfg.width      = 7; % width definition is important 
cfg.output     = 'pow';
cfg.foi        = 1:2:30;
cfg.toi        = -1:0.05:1;
TFRwave_visc = ft_freqanalysis(cfg, data_visc);    % visual stimuli
TFRwave_audc = ft_freqanalysis(cfg, data_audc);    % auditory stimuli

% plot results 
cfg = [];
cfg.baseline     = [-0.5 -0.3];
cfg.baselinetype = 'absolute';
cfg.marker       = 'on';
cfg.showlabels   = 'yes';
cfg.layout       = 'easycapM10.mat';
figure; ft_multiplotTFR(cfg, TFRwave_visc);
figure;
subplot(211);ft_singleplotTFR(cfg, TFRwave_visc); title('visual stim');
subplot(212);ft_singleplotTFR(cfg, TFRwave_audc); title('auditory stim');

