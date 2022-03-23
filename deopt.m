%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Function: [global_best,score2,initial_best,score1] = deopt(S_struct)
% 
% This is a tailor version of the original code provided by
% Author: Rainer Storn, Ken Price, Arnold Neumaier, Jim Van Zandt
%
% Input Parameters 
% -----------------
% S_struct:     Problem data vector (must remain fixed during the minimization). 
% nParameters:  Number of parameters of the objective function.              
% nPopulation:  Number of population members.
% n_itermax:    Maximum number of iterations (generations).
% weight:       DE-stepsize weight from interval [0, 2].
% CR:           Crossover probability constant from interval [0, 1].
% strategy:     1 --> DE/rand/1
%               2 --> DE/local-to-best/1               
%               3 --> DE/best/1 with jitter                                       
%               4 --> DE/rand/1 with per-vector-dither                                       
%               5 --> DE/rand/1 with per-generation-dither                                       
%               6 --> DE/rand/1 either-or-algorithm%                   
% refresh:      Intermediate output will be produced after "refresh" iterations.
% y:            The LDR vector, kept fixed as 0, 1, 2, ..., 255.
% hdr:          The input HDR image data.
%
% Output Parameters
% ------------------
% global_best:  Best parameter vector in the final population.
% score2:       Score of the global best solution
% initial_best: Best parameter vector in the initial population.
% score1:       Score of the best solution in the initial population
%
% Copyright notice with the original code
% ----------------------------------------
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 1, or (at your option)
% any later version.
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details. A copy of the GNU
% General Public License can be obtained from the
% Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function [global_best, score2, initial_best, score1] = deopt(S_struct)

% the inputs
nPopulation         = S_struct.nPopulation;
weight              = S_struct.weight;
CR                  = S_struct.CR;
nParameters         = S_struct.nParameters;
n_itermax           = S_struct.n_itermax;
strategy            = S_struct.strategy;
refresh             = S_struct.refresh;
y                   = S_struct.y;
hdr                 = S_struct.hdr;

monotonic           = S_struct.monotonic;
log_domain          = S_struct.log_domain;

%% -----Initialize population -------------------------------
% initialize with random curves
pop = zeros(nPopulation,nParameters);
random_x = random_tmc(min(hdr(:)), max(hdr(:)), nParameters, nPopulation); % random TMCs
random_x = sort(random_x, 2);
if log_domain, random_x = log10(1+random_x); end
pop(1:end,:) = random_x;

%add some real TMOs
nTMO = 12;
nTMO = min(12,nTMO);
tmo_x = zeros(nTMO, nParameters);                       % Existing TMOs
tmo_x(1,:) = design_tmo_matt(hdr);                      % ATT TMO
for k=1:nTMO-1                                          % 11 other existing TMOs
    tmo_x(k+1,:) = theyab(S_struct.hdr,k); 
end
if log_domain, tmo_x = log10(1+tmo_x); end

pop(1:nTMO,:) = tmo_x;

scores =  get_scores(pop, S_struct, log_domain);
tmo_scores = scores(1:nTMO);
% [score1, idx] = max(scores);
% initial_best = pop(idx, :);
score1 = scores(1);
initial_best = pop(1, :);
if log_domain, initial_best = 10.^initial_best-1; end

%% DE-Minimization

rot  = (0:1:nPopulation-1);   % rotating index array (size nPopulation)

% arrange the population based on scores in descending order
[scores, idx] = sort(scores, 'descend');
pop = pop(idx, :);

% DE iterations
for n_iter = 1 : n_itermax

    % generate new population through evolutionary operators
    % -------------------------------------------------------
    
    %mutation and crossover
    new_pop = DE_iteration(pop, rot, CR, strategy, weight); 
    
    if monotonic  
        new_pop = sort((new_pop),2); % sort, to keep monotonicity
    else 
        new_pop(1:30, :) = sort(new_pop(1:30,:),2); % let last five stay non-monotonic
    end
    
    scores_new = get_scores(new_pop, S_struct, log_domain);
    
    % Selection
    [pop, scores] = selection(pop, new_pop, scores, scores_new, 'compare_all');
    
    %---- Show Intermedite Outputs-----------------------------------------
    
    if (refresh > 0)
        if ((rem(n_iter,refresh) == 0) || n_iter == 1)
            fprintf('Iteration: %d,  Best: %f \n', n_iter, scores(1));
            show_population(hdr, pop, scores, log_domain); %show best 9 images
        end
    end
    
end

global_best = pop(1,:);
score2 = scores(1);
if log_domain, global_best = 10.^global_best-1; end

end

%%
function ui = DE_iteration(pop_old, rot, CR, strategy, weight)

[nPopulation, nParameters] = size(pop_old);
ind = randperm(4);               % index pointer array

a1  = randperm(nPopulation);                   % shuffle locations of vectors
rt  = rem(rot+ind(1),nPopulation);     % rotate indices by ind(1) positions
a2  = a1(rt+1);                 % rotate vector locations
rt  = rem(rot+ind(2),nPopulation);
a3  = a2(rt+1);
rt  = rem(rot+ind(3),nPopulation);
a4  = a3(rt+1);
rt  = rem(rot+ind(4),nPopulation);
a5  = a4(rt+1);

pm1 = pop_old(a1,:);             % shuffled population 1
pm2 = pop_old(a2,:);             % shuffled population 2
pm3 = pop_old(a3,:);             % shuffled population 3
pm4 = pop_old(a4,:);             % shuffled population 4
pm5 = pop_old(a5,:);             % shuffled population 5

bm = repmat(pop_old(1,:), nPopulation, 1);% population filled with the best member

mui = rand(nPopulation,nParameters) < CR;  % all random numbers < CR are 1, 0 otherwise
mpo = mui < 0.5;    % inverse mask to mui

if (strategy == 1)                             % DE/rand/1
    ui = pm3 + weight*(pm1 - pm2);   % differential variation
    ui = pop_old.*mpo + ui.*mui;     % crossover
    origin = pm3;
elseif (strategy == 2)                         % DE/local-to-best/1
    ui = pop_old + weight*(bm-pop_old) + weight*(pm1 - pm2);
    ui = pop_old.*mpo + ui.*mui;
    origin = pop_old;
elseif (strategy == 3)                         % DE/best/1 with jitter
    ui = bm + (pm1 - pm2).*((1-0.9999)*rand(nPopulation,nParameters)+weight);
    ui = pop_old.*mpo + ui.*mui;
    origin = bm;
elseif (strategy == 4)                         % DE/rand/1 with per-vector-dither
    f1 = ((1-weight)*rand(nPopulation,1)+weight);
    for k=1:nParameters
        pm5(:,k)=f1;
    end
    ui = pm3 + (pm1 - pm2).*pm5;    % differential variation
    origin = pm3;
    ui = pop_old.*mpo + ui.*mui;     % crossover
elseif (strategy == 5)                          % DE/rand/1 with per-vector-dither
    f1 = ((1-weight)*rand+weight);
    ui = pm3 + (pm1 - pm2)*f1;         % differential variation
    origin= pm3;
    ui = pop_old.*mpo + ui.*mui;     % crossover
elseif  (strategy == 6)                                            % either-or-algorithm
    if (rand < 0.5)                               % Pmu = 0.5
        ui = pm3 + weight*(pm1 - pm2);% differential variation
        origin = pm3;
    else                                           % use F-K-Rule: K = 0.5(F+1)
        ui = pm3 + 0.5*(weight+1.0)*(pm1 + pm2 - 2*pm3);
    end
    ui = pop_old.*mpo + ui.*mui;     % crossover
elseif  (strategy == 7)
    ui = pop_old + weight*(bm-pop_old) + weight*(pm1 - pm2);
    ui = pop_old.*mpo+ ui.*mui;
    origin =pop_old;
end
end

%% ----------------------------------------------------
function scores = get_scores(pop, S_struct,log_domain)
%------------------------------------------------------
if log_domain, pop = (10.^pop)-1; end
scores = zeros(1,size(pop, 1));
for k=1:numel(scores)
    F = objfun(S_struct.hdr, pop(k,:), S_struct.y, S_struct.metric_name);
    scores(k) = -F.cost;
end
end

%% -------------------------------------------------------------
function show_population(hdr, pop, val, log_domain)
%---------------------------------------------------------------
if log_domain, pop = 10.^pop-1; end
[val, idx] = sort(val,'descend');

r=3; c=3;
figure(108);

for i=1:9 % show best nine results
    ldr = apply_tmo(hdr, pop(idx(i),:), 0:255, 1);
    %    [q,s,n] = TMQI(hdr, uint8(255*ldr));
    subplot(r,c,i); imshow(uint8(ldr));
    title(sprintf('%0.2f', val(i)));
end
%drawnow();
end

function b = set_range(a, minn, maxx)
b = minn+(maxx-minn)*(a-min(a(:)))/(max(a(:))-min(a(:)));
end

function r = random_tmc(minn, maxx, nParameters, nCurves)

r = (random('Normal',randi(100),randi(10),[nCurves,nParameters]));
for i=1:nCurves
    r(i,:) = set_range(r(i,:), minn, maxx);
end
%if rand(1)>0.5, r(2:end-1) = r(2:end-1)*rand(1); end
%figure(101), plot(r, 0:255);
end

%%
% -------------------------------------------------------------------
function [pop, scores] = selection(pop, ui, scores, scores_ui, algo)
% -------------------------------------------------------------------
if strcmp(algo, 'compare_all')
    nPopulation = size(pop, 1);
    pop_temp = [pop; ui];
    scores_temp = [scores, scores_ui];
    [scores_temp, idx] = sort(scores_temp, 'descend');
    pop = pop_temp(idx(1:nPopulation), :);
    scores = scores_temp(1:nPopulation);
    
elseif strcmp(algo, 'one_on_one')
    idx = find(scores_ui > scores);
    pop(idx, :) = ui(idx, :);
    scores(idx) = scores_ui(idx);
    [scores, idx] = sort(scores, 'descend');
    pop = pop(idx, :);
end

end

%%
%-----------------------------------------------
function F = objfun(hdr, x, y, metric_name, ldr)
%-----------------------------------------------

if nargin < 5
    ldr = apply_tmo(hdr, x, y, 1);
end

ldr = (uint8(ldr));

if strcmp(metric_name, 'TMQI')
    [q,s,n] = TMQI(hdr, ldr);
    F.cost = -(q+s+n)/3;
    
elseif strcmp(metric_name, 'test_metric')
    F.cost = -test_metric(hdr, ldr);
end


end

