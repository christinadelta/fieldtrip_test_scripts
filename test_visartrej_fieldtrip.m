%%% Preporcessing with fieldtrip test script 
%%% test - visual artifact rejection

% for this test script the preprocessed mat file will be used

% Two functions for artefact rejection:
% 1. ft_rejectvisual.m -- works only on segmented data (not continuous)
% 2. ft_databrowser.m -- works on continuous and segmented data. Can also be called to visualise ICA components  

% Procedure:
% 1. read data into matlab with ft_definetrial.m, ft_preprocessing.m 
% 2. visual inspectionof the trials and artifact rejection using
% ft_rejectvisual.m 
% 3. manual artifact rejection using ft_databrowser.m 

%% artifact rejection with ft_rejectvisual.m 

load preprocData data_all % only load the data_all struct

% we'll use the configuration method (cfg.method) to browse through data
% either by channel or by trial or display all data at once. 
% cfg.latency determines the entire time window of the inspected signal 

% browse through the data trial by trial:
cfg = [];
cfg.method = 'trial';
cfg.ylim = [-1e-12 1e-12];
% dummy = ft_rejectvisual(cfg, dataFIC);
dummy = ft_rejectvisual(cfg, data_all);

% browse through the data by channel:
cfg = [];
cfg.method = 'channel';
cfg.ylim = [-1e-12 1e-12];
cfg.megscale = 1;
cfg.eogscale = 5e-8;
dummy = ft_rejectvisual(cfg, data_all);

% display summary 
cfg = [];
cfg.method = 'summary';
cfg.ylim = [-1e-12 1e-12];
dummy = ft_rejectvisual(cfg, data_all);


%% artifact rejection with ft_databrowser.m 

% this function uses butterfly plots of single trials 
cfg = [];
cfg.channel = 'MEG'; % select only meg channels
data = ft_preprocessing(cfg, data_all);

% open browser and page through trials 
cfg = [];
cfg.channel = 'MEG';
data_artf = ft_databrowser(cfg, data);






