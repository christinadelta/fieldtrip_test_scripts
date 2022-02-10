function loadeeg(params, subI)

% this function is part of the formal preprocessing and analysis pipeline
% of the Beads EEG data with Fieldtrip

% it loads all block files and runs preprocessing 
% note that I run 3 different types of preprocessing because I split the
% data in three different ways:
% 1. all data -- all data preprocessed together and saved in 1 struct
% called all_data
% 2. condition data -- data are split in conditions 1&2 (easy, difficult),
% preprocessed and saved in different structures
% 3. draws data -- data are split in [all draws - last] and [last],
% preprocessed and saved in different structures

% once all preprocessing is done, I store all 5 structures in 1 struct
% called data (1 for each block). This struct is then loaded from the main
% analysis script and further processed. 

% Unpack params 
task        = params.task;
taskdir     = params.taskdir;
blocks      = params.blocks;
blocktrials = params.blocktrials;
totaltrials = params.totaltrials;
nconds      = params.nconds;
conditions  = params.conditions;
totalconds  = nconds/2;

subname     = params.subname;

% specify subI dir 
subIdir     = fullfile(taskdir, subname{subI});

for blockI = 1:blocks
    
    % load subI block .bdf files 
    subFile = fullfile(subIdir, sprintf('sub_%02d_%s_block_%02d.bdf', subI, task, blockI));
    cfg                     = [];
    cfg.dataset             = subFile;

    cfg.trialdef.eventtype  = 'STATUS';
    cfg.trialdef.eventvalue = [1 2 3 4 102 103];
    cfg.trialdef.prestim    = 0.2;
    cfg.trialdef.poststim   = 0.8; 
    cfg                     = ft_definetrial(cfg);

    % extract trl list
    trls                    = cfg.trl;
    tstart                  = 102; % start of sequence
    tend                    = 103; % end of sequence
    
    blocksequences          = length(find(trls(:,4) == tstart));
    trialstart              = find(trls(:,4) == tstart);
    trialend                = find(trls(:,4) == tend);

    counter                 = 0;
    
    % loop over block-sequences 
    for iTrial = 1:blocksequences

        % add trial number 
        tmp                 = length(trialstart(iTrial)+1: trialend(iTrial)-1);
        for j = 1:tmp

            cnt             = counter + j; 
            trialnum(cnt,1) = iTrial;
            trialnum(cnt,2) = blockI;
        end 

        % update counter 
        counter             = counter + tmp ;

        clear tmp cnt
    end % end of sequence loop
    
    % remove trialstart and trialend from the trl list
    trls(trls(:,4) == tstart, :)    = [];
    trls(trls(:,4) == tend, :)      = [];
    trls(:,5)                       = trialnum(:,1); % add trialnum to the main list
    trls(:,6)                       = trialnum(:,2); % add trialnum to the main list
    
    % now split data to conditions and preprocess cfg and move condition data to
    % new data structures     
    trl_length                      = length(trls);
    
    for i = 1:trl_length
        
        if trls(i,4) == 1 | trls(i,4) == 2
            trls(i,7) = 1;
            
        elseif trls(i,4) == 3 | trls(i,4) == 4
            trls(i,7) = 2;
            
        end
    end
    
    clear trialend trialstart j i counter cnt trialnum 
    
    % preprocess easy cond and diff cond data seperately 
    trl_easy            = find(trls(:,7) == 1);
    trl_diff            = find(trls(:,7) == 2);
    
    easy_trls           = trls((trl_easy),:);
    diff_trls           = trls((trl_diff),:);
    
    % split the data into "allbutlast" and "last" trls 
    tmp_all             = 0;
    tmp_last            = 0;
    c                   = 0; % counter index
    l                   = 1; % last draw index
    
    for icond = 1:totalconds
        for itrial = 1:blocktrials
            
            tmp = find(trls(:,7)== icond & trls(:,5)== itrial);
            
            if ~isempty(tmp)
                tl                  = length(tmp)-1;
                tmp_all(c+1:c+tl)   = tmp(1:end-1); % only pick 
                tmp_last(:,l)       = tmp(end);
                
                % update c and l 
                c                   = c + tl;
                l                   = l + 1;
            end
            
        end % end of trials loop
    end % end of iconds loop
    
    tmp_all = tmp_all'; tmp_last = tmp_last'; %transpose 
    
    first_trls                      = trls((tmp_all),:);
    last_trls                       = trls((tmp_last),:);
        
    %% re-reference/preprocess
    
    % first preprocess all data (all draws, all conditions together) 
    cfg.reref           = 'yes';
    cfg.refchannel      = {'EXG1' 'EXG2'};
    cfg.demean          = 'yes';
    cfg.baselinewindow  = [-0.2 0];
    
    % re-write the trl list to the cfg struct and preprocess all data 
    cfg.trl             = trls;
    alldata             = ft_preprocessing(cfg);
    data.alldata        = alldata; % update data struct
    
    % re-write the trl list to the cfg struct and preprocess easy_cond data 
    cfg.trl             = easy_trls;
    easy_data           = ft_preprocessing(cfg);
    data.easy_data      = easy_data;
    
    % re-write the trl list to the cfg struct and preprocess easy_cond data 
    cfg.trl             = diff_trls;
    diff_data           = ft_preprocessing(cfg);
    data.diff_data      = diff_data;
    
    % re-write the trl list to the cfg struct and preprocess allbutlast data 
    cfg.trl             = first_trls;
    first_data          = ft_preprocessing(cfg);
    data.first_data     = first_data;
    
    % re-write the trl list to the cfg struct and preprocess last data 
    cfg.trl             = last_trls;
    last_data           = ft_preprocessing(cfg);
    data.last_data      = last_data;
    
    % save preprocesssed block data in a .mat file 
    save(['beads_analysis/prepro/beads_preproc_sub_', num2str(subI), '_block_', num2str(blockI)], 'data')
   
end % end of blocks loop


end 