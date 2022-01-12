
% used in trial definition function for the beads task -- as part of the
% FieldTrip analysis
% this function extracts events and creates conditions for epoching 

% read the header (needed for the samping rate) and the events
hdr_beads           = ft_read_header(cfgbeads.dataset);
event_beads         = ft_read_event(cfgbeads.dataset);

% remove the first 3 rows as they are not trigger related 
event_beads(1:3)    = [];

% for the events of interest, find the sample numbers (these are
% integers)and event triggers 
EVsample_b          = [event_beads.sample]';
EVvalue_b           = [event_beads.value]'; 

% based on the trigger value determine whether it is an easy or difficult
% trial
easy_trigger        = 100;
diff_trigger        = 101;

start_trigger       = 102;
end_trigger         = 103;

% how many times easy and diff cond triggers appeared in that block?
t_easy              = length(find(EVvalue_b == easy_trigger));
t_diff              = length(find(EVvalue_b == diff_trigger));
block_trials        = t_easy + t_diff;

% find index of each easy and difficult trials in the array
easy_cond           = find(EVvalue_b == easy_trigger);
diff_cond           = find(EVvalue_b == diff_trigger);
all_conds           = sort(cat(1,easy_cond, diff_cond));

% find index of each all starts and ends in the array
conds_start = find(EVvalue_b == start_trigger);
conds_end = find(EVvalue_b == end_trigger);

% create the condition cell
conds = [];
cnt = 0;

for i = 1:block_trials
    
    if EVvalue_b((all_conds(i)),1) == easy_trigger
        
        tmp = length(all_conds(i): conds_end(i));
        conds{i} = ones(tmp,1);
        
    elseif EVvalue_b((all_conds(i)),1) == diff_trigger
        
        tmp = length(all_conds(i): conds_end(i));
        conds{i} = ones(tmp,1)*2; 
        
    end 
end

% extract data from strcut
for i = 1:block_trials
    
    tmp = conds{i};
    
    for j = 1:length(tmp)
        
        count = cnt + j; % update count var
        conditions(count,1) = tmp(j);
        
    end
    
    cnt = cnt + length(tmp); % update cnt var
   
end

clear tmp count cnt i j % for memory efficiency 

% concat the trigger values with the condition array and the rest of the
% data needed 
EVvalue_b(:,2)      = conditions;

% select conditions (hmm, not sure if I'll use those; will keep them for now) 
easy                = find(EVvalue_b(:,2) == 1);
difficult           = find(EVvalue_b(:,2) == 2);

% split the events struct into easy and difficult conditions 
easy_struct           = event_beads(easy);
diff_struct           = event_beads(difficult);

% extract data from the 2 structs of interest
easy_data(:,1)      = [easy_struct.sample]'; % begsample
easy_data(:,2)      = [easy_struct.sample]'; % endsample 
easy_data(:,3)      = zeros(size(easy_struct)); % offset 
easy_data(:,4)      = [easy_struct.value]'; % trigger 

diff_data(:,1)      = [diff_struct.sample]';
diff_data(:,2)      = [diff_struct.sample]';
diff_data(:,3)      = zeros(size(diff_struct));
diff_data(:,4)      = [diff_struct.value]';

% all trial starts and trial ends in each condition
easy_tstart         = find(easy_data(:,4) == 102); 
easy_tend           = find(easy_data(:,4) == 103);

diff_tstart         = find(diff_data(:,4) == 102); 
diff_tend           = find(diff_data(:,4) == 103);

% total number of easy and difficult trials (to be used for looping)
totaleasy_trials    = length(easy_struct);
totaldiff_trials    = length(diff_struct);

% now create a structure to save the samples/draws of each trial. These
% draws will be used for epoching
trials              = []; % INIT TRIALS STRUCT
tcond               = 2; % how many conditions?

% first deal with the condition trials
% here I create a structure that stores the triggers within each
% trial/sequence (triggers: draw, responseprompt, feedback screen) in
% seperate arrays. This struct will be used for epoching 
% CONDITION LOOP
for i = 1:tcond
    
    if i == 1 % if this is the easy condition
        % TRIAL LOOP
        for j = 1:t_easy

            trials{i}{j} = easy_data(easy_tstart(j)+1:easy_tend(j)-1, :);
        end
        
    elseif i == 2 % if this is the difficult condition
        
        for j = 1:t_diff

            trials{i}{j} = diff_data(diff_tstart(j)+1:diff_tend(j)-1, :);

        end  
    end
end

% maybe also get only the draw triggers from the data. This will be used to
% epoch only draws for each trial/sequence. IN FACT, THIS IS THE MAIN
% EPOCHING THAT WILL BE DONE 
blue_easy           = find(easy_data(:,4) == 1);
green_easy          = find(easy_data(:,4) == 2);
win_easy            = find(easy_data(:,4) == 14);
lose_easy           = find(easy_data(:,4) == 15);
tmp_easy            = sort(cat(1,blue_easy, green_easy, win_easy, lose_easy, easy_tstart));
easytrials          = easy_data(tmp_easy,:);

blue_diff           = find(diff_data(:,4) == 3);
green_diff          = find(diff_data(:,4) == 4);
win_diff            = find(diff_data(:,4) == 14);
lose_diff           = find(diff_data(:,4) == 15);
tmp_diff            = sort(cat(1,blue_diff, green_diff, win_diff, lose_diff, diff_tstart));
difftrials          = diff_data(tmp_diff,:);

clear blue_easy green_easy win_easy lose_easy tmp_easy blue_diff green_diff win_diff lose_diff tmp_diff 

% now that we have new structures for the easy and difficult trials
% (including only the draws), find the indexes of the t_start and feedback
% triggers again, to use in the loop below 
start_easy          = find(easytrials(:,4) == 102);
win_easy            = find(easytrials(:,4) == 14);
lose_easy           = find(easytrials(:,4) == 15);
feed_easy           = sort(cat(1, lose_easy, win_easy));

start_diff          = find(difftrials(:,4) == 102);
win_diff            = find(difftrials(:,4) == 14);
lose_diff           = find(difftrials(:,4) == 15);
feed_diff           = sort(cat(1, lose_diff, win_diff));

clear win_easy lose_easy win_diff lose_diff

% split in trials/sequences
for i = 1:tcond 
    
    if i == 1
        
        for j = 1:t_easy
        
            draws{i}{j} = easytrials(start_easy(j)+1:feed_easy(j)-1, :);
        
        end
        
    elseif i == 2
        
        for j = 1:t_diff
        
            draws{i}{j} = difftrials(start_diff(j)+1:feed_diff(j)-1, :);
        
        end
    end
end

