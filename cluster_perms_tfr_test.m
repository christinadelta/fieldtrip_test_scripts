%%% cluster based permution for TFR data 

% based on the following tutorial:
% https://www.fieldtriptoolbox.org/tutorial/cluster_permutation_timelock/ 

% add fieldtrip to the path
ftdir                   = '/Users/christinadelta/githubstuff/fieldtrip';                 
addpath(ftdir)

% add data path 
datadir                 = '/Users/christinadelta/githubstuff/fieldtrip_test_scripts';
megdir                  = fullfile(datadir, 'meg');

% reading continuous data into memory
cfg                     = [];
cfg.dataset             = fullfile(megdir, 'Subject01.ds'); % add subject path and file name 
cfg.trialfun            = 'ft_trialfun_general'; % default 
cfg.trialdef.eventtype  = 'backpanel trigger';
cfg.trialdef.eventvalue = [3 5 9];  % trigger codes for the three conditions
cfg.trialdef.prestim    = 1;        % in secs
cfg.trialdef.poststim   = 2;        % in secs

cfg                     = ft_definetrial(cfg);

% clean data 
% remove the trials that have artifacts from the trl
cfg.trl([2, 5, 6, 8, 9, 10, 12, 39, 43, 46, 49, 52, 58, 84, 102, 107, 114, 115, 116, 119, 121, 123, 126, 127, 128, 133, 137, 143, 144, 147, 149, 158, 181, 229, 230, 233, 241, 243, 245, 250, 254, 260],:) = [];

% preprocess the data
cfg.channel    = {'MEG', '-MLP31', '-MLO12'};        % read all MEG channels except MLP31 and MLO12
cfg.demean     = 'yes';

data_all = ft_preprocessing(cfg);

% For subsequent analysis we extract the trials of the fully incongruent 
% condition and the fully congruent condition to separate data structures.
cfg         = [];
cfg.trials  = data_all.trialinfo == 3;
dataFIC     = ft_redefinetrial(cfg, data_all);

cfg         = [];
cfg.trials  = data_all.trialinfo == 9;
dataFC      = ft_redefinetrial(cfg, data_all);

% save data 
save dataFIC_LP dataFIC_LP
save dataFC_LP dataFC_LP

% load data
load dataFIC_LP
load dataFC_LP

% Calculation of the planar gradient and time-frequency analysis
cfg = [];

cfg.planarmethod = 'sincos';
% prepare_neighbours determines with what sensors the planar gradient is computed
cfg_neighb.method    = 'distance';
cfg.neighbours       = ft_prepare_neighbours(cfg_neighb, dataFC);

dataFIC_planar = ft_megplanar(cfg, dataFIC);
dataFC_planar  = ft_megplanar(cfg, dataFC);

% run tfr
cfg = [];
cfg.output     = 'pow';
cfg.channel    = 'MEG';
cfg.method     = 'mtmconvol';
cfg.taper      = 'hanning';
cfg.foi        = 20;
cfg.toi        = [-1:0.05:2.0];
cfg.t_ftimwin  = 7./cfg.foi; %7 cycles
cfg.keeptrials = 'yes';

freqFIC_planar = ft_freqanalysis(cfg, dataFIC_planar);
freqFC_planar  = ft_freqanalysis(cfg, dataFC_planar);

% Finally, we calculate the combined planar gradient and copy the gradiometer structure in the new datasets.
cfg                     = [];
freqFIC_planar_cmb      = ft_combineplanar(cfg, freqFIC_planar);
freqFC_planar_cmb       = ft_combineplanar(cfg, freqFC_planar);

freqFIC_planar_cmb.grad = dataFIC.grad;
freqFC_planar_cmb.grad  = dataFC.grad;

% To save:
save freqFIC_planar_cmb freqFIC_planar_cmb;
save freqFC_planar_cmb  freqFC_planar_cmb;

% permutation tests
% between trials 
load freqFIC_planar_cmb
load freqFC_planar_cmb

cfg = [];
cfg.channel          = {'MEG', '-MLP31', '-MLO12'};
cfg.latency          = 'all';
cfg.frequency        = 20;
cfg.method           = 'montecarlo';
cfg.statistic        = 'ft_statfun_indepsamplesT';
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';
cfg.minnbchan        = 2;
cfg.tail             = 0;
cfg.clustertail      = 0;
cfg.alpha            = 0.025;
cfg.numrandomization = 500;

% prepare_neighbours determines what sensors may form clusters
cfg_neighb.method    = 'distance';
cfg.neighbours       = ft_prepare_neighbours(cfg_neighb, dataFC);

design = zeros(1,size(freqFIC_planar_cmb.powspctrm,1) + size(freqFC_planar_cmb.powspctrm,1));
design(1,1:size(freqFIC_planar_cmb.powspctrm,1)) = 1;
design(1,(size(freqFIC_planar_cmb.powspctrm,1)+1):(size(freqFIC_planar_cmb.powspctrm,1)+...
size(freqFC_planar_cmb.powspctrm,1))) = 2;

cfg.design           = design;
cfg.ivar             = 1;

[stat] = ft_freqstatistics(cfg, freqFIC_planar_cmb, freqFC_planar_cmb);

save stat_freq_planar_FICvsFC stat;

% Plotting the results
cfg = [];
freqFIC_planar_cmb = ft_freqdescriptives(cfg, freqFIC_planar_cmb);
freqFC_planar_cmb  = ft_freqdescriptives(cfg, freqFC_planar_cmb);

% Subsequently we add the raw effect (FIC-FC) to the obtained stat structure 
% and plot the largest cluster overlayed on the raw effect.
stat.raweffect = freqFIC_planar_cmb.powspctrm - freqFC_planar_cmb.powspctrm;

cfg = [];
cfg.alpha  = 0.025;
cfg.parameter = 'raweffect';
cfg.zlim   = [-1e-27 1e-27];
cfg.layout = 'CTF151_helmet.mat';
ft_clusterplot(cfg, stat);

%% witin subject disign 
load GA_TFR_orig;

cfg = [];
cfg.channel          = {'MEG'};
cfg.latency          = [0 1.8]; % latency is different should read about it in 
cfg.frequency        = 20;
cfg.method           = 'montecarlo';
cfg.statistic        = 'ft_statfun_depsamplesT';
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';
cfg.minnbchan        = 2;
cfg.tail             = 0;
cfg.clustertail      = 0;
cfg.alpha            = 0.025;
cfg.numrandomization = 500;

% specifies with which sensors other sensors can form clusters
cfg_neighb.method    = 'distance';
cfg.neighbours       = ft_prepare_neighbours(cfg_neighb, GA_TFRFC);

% WITHIN SUBJECTS DESIGN MATRIX
subj = 10;
design = zeros(2,2*subj);

for i = 1:subj
  design(1,i) = i;
end

for i = 1:subj
  design(1,subj+i) = i;
end

design(2,1:subj)        = 1;
design(2,subj+1:2*subj) = 2;

cfg.design   = design;
cfg.uvar     = 1;
cfg.ivar     = 2;

[stat] = ft_freqstatistics(cfg, GA_TFRFIC, GA_TFRFC);

save stat_freq_planar_FICvsFC_GA stat

% plot 
cfg = [];
cfg.alpha  = 0.05; % if alpha = 0.025 doesn't work try 0.05
cfg.parameter = 'stat';
cfg.zlim   = [-4 4];
cfg.layout = 'CTF151_helmet.mat';
ft_clusterplot(cfg, stat);



