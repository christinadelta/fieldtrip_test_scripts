%%% cluster based permution for timelock data 

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
cfg.baselinewindow  = [-0.2 0];
cfg.lpfilter   = 'yes';                              % apply lowpass filter
cfg.lpfreq     = 35;                                 % lowpass at 35 Hz.

data_all = ft_preprocessing(cfg);

% split data into two different structures (sets). Fully incongruent (FIC)
% and fully congruent conditions (FC)
cfg = [];
cfg.trials = data_all.trialinfo == 3;
dataFIC_LP = ft_redefinetrial(cfg, data_all);

cfg = [];
cfg.trials = data_all.trialinfo == 9;
dataFC_LP = ft_redefinetrial(cfg, data_all);

% save data 
save dataFIC_LP dataFIC_LP
save dataFC_LP dataFC_LP

% load data
load dataFIC_LP
load dataFC_LP

% run timelock analysis (this doesn't have the trials field
cfg = [];
cfg.keeptrials = 'yes';
timelockFIC    = ft_timelockanalysis(cfg, dataFIC_LP); 
timelockFC     = ft_timelockanalysis(cfg, dataFC_LP);

%% Between trials design 

% first create the neighbours structure
cfg_neighb          = [];
cfg_neighb.method   = 'distance';
neighbours          = ft_prepare_neighbours(cfg_neighb, dataFC_LP);

cfg.neighbours      = neighbours;  % the neighbours specify for each sensor with
                                 % which other sensors it can form clusters
cfg.channel         = {'MEG'};     % cell-array with selected channel labels
cfg.latency         = [0 1];       % time interval over which the experimental
                                 % conditions must be compared (in seconds)

% permutation tests
cfg.method           = 'montecarlo';    % use the Monte Carlo Method to calculate the significance probability
cfg.statistic        = 'indepsamplesT'; % use the independent samples T-statistic as a measure to
                                        % evaluate the effect at the sample level
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.05;       % alpha level of the sample-specific test statistic that
                                   % will be used for thresholding
cfg.clusterstatistic = 'maxsum';   % test statistic that will be evaluated under the
                                   % permutation distribution.
cfg.minnbchan        = 2;          % minimum number of neighborhood channels that is
                                   % required for a selected sample to be included
                                   % in the clustering algorithm (default=0).
% cfg.neighbours     = neighbours; % see below
cfg.tail             = 0;          % -1, 1 or 0 (default = 0); one-sided or two-sided test
cfg.clustertail      = 0;
cfg.alpha            = 0.025;      % alpha level of the permutation test (if two-sided set to 0.025)
cfg.numrandomization = 100;        % number of draws from the permutation distribution

n_fc                 = size(timelockFC.trial, 1);
n_fic                = size(timelockFIC.trial, 1);

cfg.design           = [ones(1,n_fic), ones(1,n_fc)*2]; % design matrix
cfg.ivar             = 1; % number or list with indices indicating the independent variable(s)

% run stats 
[stat]               = ft_timelockstatistics(cfg, timelockFIC, timelockFC);

cfg    = [];
avgFIC = ft_timelockanalysis(cfg, dataFIC_LP);
avgFC  = ft_timelockanalysis(cfg, dataFC_LP);

% Then take the difference of the averages using ft_math
cfg           = [];
cfg.operation = 'subtract';
cfg.parameter = 'avg';
raweffectFICvsFC = ft_math(cfg, avgFIC, avgFC);

% Make a vector of all p-values associated with the clusters from ft_timelockstatistics.
pos_cluster_pvals = [stat.posclusters(:).prob];

% Then, find which clusters are deemed interesting to visualize, here we use a cutoff criterion based on the
% cluster-associated p-value, and take a 5% two-sided cutoff (i.e. 0.025 for the positive and negative clusters,
% respectively
pos_clust = find(pos_cluster_pvals < 0.025);
pos       = ismember(stat.posclusterslabelmat, pos_clust);


% and now for the negative clusters...
neg_cluster_pvals = [stat.negclusters(:).prob];
neg_clust         = find(neg_cluster_pvals < 0.025);
neg               = ismember(stat.negclusterslabelmat, neg_clust);

ipos = find([stat.posclusters.prob] < 0.025) 

% loop over all sig positive clusters
for i=pos_clust

  cfg=[];
  cfg.highlight = 'on';
  cfg.zparam    = 'stat';
  cfg.layout    = 'CTF151_helmet.mat';
  cfg.style     = 'straight';
  cfg.gridscale = 500;

  % find the significant time range for this cluster
  tmp=[];
  for t = 1:length(stat.time)
    if ~isempty(find(any(stat.posclusterslabelmat(:,t)==pos_clust)))
      tmp = [tmp t];
    end
  end
  cfg.xlim      = [stat.time(tmp(1)) stat.time(tmp(end))];

  % find the channels belonging to this cluster
  cfg.highlightchannel = [];
  
  for c = 1:length(stat.label)
    if ~isempty(find(any(stat.posclusterslabelmat(:, c)==pos_clust)))
      cfg.highlightchannel = [cfg.highlightchannel c];
    end
  end

  figure
  ft_topoplotER(cfg, stat);
  title('positive cluster')
  print(gcf, '-dpng', ['figures/fig5_STAT_pos', num2str(i) ])
end

% loop over negative clusters
for i=neg_clust

  cfg=[];
  cfg.highlight = 'on';
  cfg.zparam    = 'stat';
  cfg.layout    = 'CTF151_helmet.mat';
  cfg.style     = 'straight';
  cfg.gridscale = 500;

  % find the significant time range for this cluster
  tmp=[];
  
  for t = 1:length(stat.time)
    if ~isempty(find(any(stat.negclusterslabelmat(:,t)==neg_clust)))
      tmp = [tmp t];
    end
  end
  cfg.xlim      = [stat.time(tmp(1)) stat.time(tmp(end))];

  % find the channels belonging to this cluster
  cfg.highlightchannel = [];
  for c = 1:length(stat.label)
    if ~isempty(find(any(stat.negclusterslabelmat(:,c)==neg_clust)))
      cfg.highlightchannel = [cfg.highlightchannel c];
    end
  end

  figure
  ft_topoplotER(cfg, stat);
  title('negative cluster')
  print(gcf, '-dpng', ['figures/fig6_STAT_neg', num2str(i)])
end

%% Within-subjects design 

load ERF_orig;

cfg         = [];
cfg.channel = {'MEG'};
cfg.latency = [0 1];

cfg.method           = 'montecarlo';
cfg.statistic        = 'depsamplesT';
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';
cfg.minnbchan        = 2;
cfg.neighbours       = neighbours;  % same as defined for the between-trials experiment
cfg.tail             = 0;
cfg.clustertail      = 0;
cfg.alpha            = 0.025;
cfg.numrandomization = 500;

Nsubj  = 10;
design = zeros(2, Nsubj*2);
design(1,:) = [1:Nsubj 1:Nsubj];
design(2,:) = [ones(1,Nsubj) ones(1,Nsubj)*2];

cfg.design = design;
cfg.uvar   = 1;
cfg.ivar   = 2;

[stat] = ft_timelockstatistics(cfg, allsubjFIC{:}, allsubjFC{:});

save stat_ERF_planar_FICvsFC_GA stat









