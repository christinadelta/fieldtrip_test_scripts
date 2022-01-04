%%% Preporcessing ERPs with fieldtrip test subject 4

%%% preprocessing and averaging ERPs

%%% Dataset:
% positive/negative, animal/human judgements on nouns
% positive nouns: e.g. puppy, princess 
% negative nouns: e.g. maggot, murderer 

% important functions used here: "ft_definetrial.m"

% outputs of ft_definetrial.m:
% cfg structure: 
% cfg.trl = parts od the datafile that will be preprocessed (rows: epochs
% of interest, columns: start-point, endpoint, offset of the first sample
% within each epoch with respect to time-point 0.

% Procedure:
% 1. define trials 

% we will use the "trialfun_affcog.m" function to read markers from the EEG
% signal and identifies trials that belong to condition 1
% (positive-negative judgements) or 2 (animal-human judgements). 

% 2. pre-process and re-reference 
% 3. extract eog signal

% in the BrainApp acquisition system all channels are measured relative to
% a common reference. 
% For EOGH: compute the potential difference between channels 57 and 25 
% For EOGV: use channel 53 and LEOG 

% NOTE: Given that biosemi records bibolar signal of EOG, the above
% re-referencing step to obtain the EOG channels is not needed 

% 4. channel layout 

%% define trials - read the data 

% add paths 
datadir         = '/Users/christinadelta/githubstuff/fieldtrip_test_scripts';
eegdir          = fullfile(datadir, 'preprocessing_erp');


cfg             = [];
cfg.trialfun    = 'trialfun_affcog';
cfg.headerfile  = fullfile(eegdir, 's04.vhdr');
cfg.datafile    = fullfile(eegdir, 's04.eeg');
cfg             = ft_definetrial(cfg);

%% pre-process and re-reference 

% the signal is unipolar and referenced to the left mastoid 
% the signal should now be re-referenced to the linked mastoids (left and
% right)

% right mastoid: electroded 32 
% To re-reference:
% 1. use the cfg.implicitref option in ft_preprocessing. This will add the
% implicit reference (LM) to the data representation as a channel with all
% zeros 
% 2. use the cfg.refchannel and cfg.reref to subtract the mean of the two
% mastoids from all channels 

% we will call pre-processing using the cfg output that resulted from
% ft_definetrial 

% Baseline correction
cfg.demean          = 'yes';
cfg.baselinewindow  = [-0.2 0];

% filtering 
cfg.lpfilter        = 'yes';
cfg.lpfreq          = 100;

% re-referencing 
cfg.implicitref     = 'LM';
cfg.reref           = 'yes';
cfg.refchannel      = {'LM' 'RM'};

data                = ft_preprocessing(cfg);

% visualise the epoched data
cfg                 = [];
ft_databrowser(cfg, data)

% visualise the continuous data
cfg                 = [];
cfg.dataset         = fullfile(eegdir, 's04.vhdr');
ft_databrowser(cfg)

% we can also plot a single trial
plot(data.time{1}, data.trial{1})

%% extract eog signal 

% eogv channel
cfg                 = [];
cfg.channel         = {'53' 'LEOG'};
cfg.reref           = 'yes';
cfg.implicitref     = []; % this is the default, we mention it here to be explicit
cfg.refchannel      = {'53'};
eogv                = ft_preprocessing(cfg, data);

% only keep one channel, and rename to eogv
cfg                 = [];
cfg.channel         = 'LEOG';
eogv                = ft_selectdata(cfg, eogv);
eogv.label          = {'eogv'};

% EOGH channel
cfg                 = [];
cfg.channel         = {'57' '25'};
cfg.reref           = 'yes';
cfg.implicitref     = []; % this is the default, we mention it here to be explicit
cfg.refchannel      = {'57'};
eogh                = ft_preprocessing(cfg, data);

% only keep one channel, and rename to eogh
cfg                 = [];
cfg.channel         = '25';
eogh                = ft_selectdata(cfg, eogh);
eogh.label          = {'eogh'};

% discard these extra channels that were used as EOG from the data and add 
% the bipolar-referenced EOGv and EOGh channels that we have just create

% only keep all non-EOG channels
cfg         = [];
cfg.channel = setdiff(1:60, [53, 57, 25]); % you can use either strings or numbers as selection
data        = ft_selectdata(cfg, data);

% append the EOGH and EOGV channel to the 60 selected EEG channels
cfg  = [];
data = ft_appenddata(cfg, data, eogv, eogh);

% use ft_databrowser to visual the new data
cfg                 = [];
ft_databrowser(cfg, data)

%% channel layout 








