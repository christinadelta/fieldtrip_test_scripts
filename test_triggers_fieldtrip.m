%%% Preporcessing with fieldtrip test script 
%%% test - trigger based trial selection

% Procedure:
% 1. define segments of data: ft_definetrial.m
% 2. read data into matlab and preprocess: ft_preprocessing.m
% 3. split data for different conditions: ft_selectdata.m

% add fieldtrip to the path
ftdir           = '/Users/christinadelta/githubstuff/fieldtrip';                 
addpath(ftdir)

% add data path 
datadir         = '/Users/christinadelta/Desktop/SubjectEEG';
megdir          = fullfile(datadir, 'meg');

%% read abd preprocess data

% to define trials of interest, we'll use the "ft_definetrial.m" function
% Trials are defined:
% 1. start of trial
% 2. end of trial
% 3. trial offset (event offset) --- normally at 0

% reading continuous data into memory
cfg                     = [];
cfg.dataset             = fullfile(megdir, 'Subject01.ds'); % add subject path and file name 
cfg.trialfun            = 'ft_trialfun_general'; % default 
cfg.trialdef.eventtype  = 'backpanel trigger';
cfg.trialdef.eventvalue = [3 5 9];  % trigger codes for the three conditions
cfg.trialdef.prestim    = 1;        % in secs
cfg.trialdef.poststim   = 2;        % in secs

cfg                     = ft_definetrial(cfg);

% cfg.trl contains the trial definitions. We can use the output of
% ft_definetrial for ft_preprocessing
cfg.channel             = {'MEG' 'EOG'};
cfg.continuous          = 'yes';
data_all                = ft_preprocessing(cfg);

% save data for later use 
save preprocData data_all

% plot trial data for channel 130
plot(data_all.time{1}, data_all.trial{1}(130, :))

%% split the conditions 

% split conditions based on the trigger code
cfg         = [];
cfg.trials  = data_all.trialinfo == 3; % FIC condition
dataFIC     = ft_selectdata(cfg, data_all);

cfg.trials  = data_all.trialinfo == 5; % IC condition
dataIC      = ft_selectdata(cfg, data_all);

cfg.trials  = data_all.trialinfo == 9; % FC condition
dataFC      = ft_selectdata(cfg, data_all);

% save the preprocessed data
save preprocData dataFIC dataIC dataFC -append









