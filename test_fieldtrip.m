%%% Preporcessing with fieldtrip test subject

% add fieldtrip to the path
ftdir          = '/Users/christinadelta/githubstuff/fieldtrip';                             % change to your ptb directory
addpath(ftdir)

% add data path 
datadir = '/Users/christinadelta/githubstuff/fieldtrip_test_scripts';
eegdir = fullfile(datadir, 'eeg');

% reading continuous data into memory
cfg         = [];
cfg.dataset = fullfile(eegdir, 'subj2.vhdr'); % add subject path and file name 
data_eeg    = ft_preprocessing(cfg); % read the data

% plot data from one of the channels 
chansel     = 1;
plot(data_eeg.time{1}, data_eeg.trial{1}(chansel, :))
xlabel('time (s)')
ylabel('channel amplitude (uV)')
legend(data_eeg.label(chansel))

%% Preprocessing 

% preprocessing, filtering and re-referencing 
cfg.reref       = 'yes';
cfg.channel     = 'all';
cfg.implicitref = 'M1';
cfg.refchannel  = {'M1', '53'}; % average of the two mastoids 
data_eeg        = ft_preprocessing(cfg); % read the data

% rename the channel 53 (right mastoid) to M2
chanindx = find(strcmp(data_eeg.label, '53'));
data_eeg.label{chanindx} = 'M2';

% remove channels that we do not need
cfg.channel = [1:61 65]; % keep channels 1-61 and the newly created M1
data_eeg = ft_preprocessing(cfg, data_eeg);

% plot the data to check it 
plot(data_eeg.time{1}(1,1:20), data_eeg.trial{1}(1:2, 1:20)) % plot the first 20 tps 
legend(data_eeg.label(1:2))

% plot the data to check it 
plot(data_eeg.time{1}, data_eeg.trial{1}(1:3, :)) % plot all the tps and 3 channels 
legend(data_eeg.label(1:3))

%% Read data for the horizontal EOG

cfg                 = [];
cfg.dataset         = fullfile(eegdir, 'subj2.vhdr');
cfg.eogh_channel    = {'51', '60'};
cfg.reref           = 'yes';
cfg.refchannel      = '51';
data_eogh           = ft_preprocessing(cfg);

% The resulting channel 51 in this representation of the data is referenced 
% to itself, which means that it contains zero values. This can be checked
% like this:
figure 
plot(data_eogh.time{1}, data_eogh.trial{1}(1,:))
hold on 
plot(data_eogh.time{1}, data_eogh.trial{1}(2,:), 'g')
legend({'51', '60'})

% For convenience we rename channel 60 into EOGH and use the ft_preprocessing 
% function once more to select the horizontal EOG channel and discard the dummy channel.
data_eogh.label{2}  = 'EOGH';

cfg                 = [];
cfg.channel         = 'EOGH';
data_eogh           = ft_preprocessing(cfg, data_eogh); 
    
% The processing of the vertical EOG is done similarly, using the difference 
% between channel 50 and 64 as the bipolar EOG
cfg                 = [];
cfg.dataset         = fullfile(eegdir, 'subj2.vhdr');
cfg.eogh_channel    = {'50', '64'};
cfg.reref           = 'yes';
cfg.refchannel      = '50';
data_eogv           = ft_preprocessing(cfg);

data_eogv.label{2} = 'EOGV';

cfg                 = [];
cfg.channel         = 'EOGV';
data_eogv           = ft_preprocessing(cfg, data_eogv); % jsut the channel of interest will be selected

% Now that we have the EEG data rereferenced to linked mastoids and the horizontal and 
% vertical bipolar EOG, we can combine the three raw data structures into a single representation using:
cfg                 = [];
data_all            = ft_appenddata(cfg, data_eeg, data_eogh, data_eogv); % append data 

% data_eeg contains the referenced to the mastoids data
% data_eogh contains the horizontal eog data
% data_eogv contains the vertical eog data

%% segmenting continuous data into trials 

% epoching based on events/trigger codes 
% first take a look at the trigger codes 
cfg                     = [];
cfg.dataset             = fullfile(eegdir, 'subj2.vhdr');
cfg.trialdef.eventtype  = '?';
dummy                   = ft_definetrial(cfg);

% choose triggers that correspond to specific event types/images presented 
% trigger codes: [s111, s121, s131, s141] correspond to pictures of animals
% trigger codes: [s151, s161, s171, s181] correspond to pictures of tools 
cfg                     = [];
cfg.dataset             = fullfile(eegdir, 'subj2.vhdr');
cfg.trialdef.eventtype  = 'Stimulus';

% extract animal pic event types
cfg.trialdef.eventvalue = {'S111', 'S121', 'S131', 'S141'};
cfg_vis_animal          = ft_definetrial(cfg);

% extract tool pic event types
cfg.trialdef.eventvalue = {'S151', 'S161', 'S171', 'S181'};
cfg_vis_tool            = ft_definetrial(cfg);

% now we'll just extract the above event/trials from the continuous signal
% (is this only at 1 tp)?
data_vis_animal         = ft_redefinetrial(cfg_vis_animal, data_all);
data_vis_tool           = ft_redefinetrial(cfg_vis_tool, data_all);

%% segmenting continuous data into 1 sec pieces 

cfg                         = [];
cfg.dataset                 = fullfile(eegdir, 'subj2.vhdr');
cfg.trialfun                = 'ft_trialfun_general';
cfg.trialdef.triallength    = 1; % duration in seconds
cfg.trialdef.ntrials        = inf;
cfg                         = ft_definetrial(cfg);

% segment data into 1 sec pieces 
data_segmented              = ft_preprocessing(cfg);



