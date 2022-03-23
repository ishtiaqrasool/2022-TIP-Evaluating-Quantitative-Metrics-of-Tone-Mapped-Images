%% About the code and copyrigt
% This code implements the followin paper:
% I. R. Khan, T. A. Alotaibi, A. Siddiq and F. Bourennani, "Evaluating
% Quantitative Metrics of Tone-Mapped Images," IEEE Transactions on Image
% Processing, vol. 31, pp. 1751-1760, 2022, doi: 10.1109/TIP.2022.3146640.

% Please cite the above paper if you use this code.

% Copyright (C) 2022 Ishtiaq Rasool Khan (irkhan@uj.edu.sa)
% Use of this TMO and the following implementation software is permitted
% for non-commercial research purposes free of charge. For commercial use
% contact irkhan@uj.edu.sa or ishtiaqrasool@gmail.com

% The code can be used to evaluate tone-mapped image quality assessment
% (TM_IQA) metrics (such as TMQI, TMQI2, FSITM, BTMQI, or any similar
% metric that assigns a quality score to the tone-mapped images).

%% Working
% You will provide an HDR image and the metric function. The algorithm will
% tone-map the HDR image and use the metric to score its quality. Then it
% will use differential evolution (DE) to enhance the image such that your
% metric's score will increase. After a few iterations, it will output the
% initial and the enhanced tone-mapped image with their scores. You can
% then visually compare the two to verify if the metric's scores represent
% the true relative quality of both images. In most of the cases you will
% find that the quality of the final image with high score is actually low.
% In many cases you will see visual artifacts. If this happens, it will
% show that the metric failed to assign correct scores.
%
% We evaluated six metrics (TMQI, TMQI2, FSITM, BTMQI, NLPD, and VQGC) and
% all failed in this test. See details in our paper.
%
% DE produces a population of candidate solutions which keeps evolving. We
% consider only the best solutions in the first and the last populations
% and their scores assigned by the metric for final comparison. However,
% 9 top-scoring candiates will be visible for you during execution of code.


%% Instructions to evaluate a new TM_IQA metric
% if you want to test your metric, do the following changes in the code.
%
% 1. change the variable metric_name to 'test_metric' below in this file in
% the inputs section (it is set to 'TMQI' currently).
%
% 2. Make a new function for your code as follows
% function [score] = test_metric(hdrImage, ldrImage)
% where ldrImage is in uint8 format in [0, 255] range. High score should
% refer to better quality. If lower score indicates better quality in your
% metric, then return its value with negative sign.
% Save this function in the following folder ..\Metrics\test_metric 
% Name the file as test_metric.m (A sample code is already there, which is
% in fact TMQI code. Relace it with your file.)
%
% Provide the path to input HDR image to be used in this evaluation in the
% inputs section below.
%
% 3. Optionally you can change the number of maximum iterations also.
% Default is 20 iterations. If the algorithm is unable to increase the
% score, try with a larger number of iterations.
%
% 4. Make sure the 'results' folder exists. It will not be created by the
% code if it does not exist and an error message will appear.

%% Inputs

% change metric_name to 'test_metric' if you want to test your metric.
metric_name = 'TMQI'; 
%metric_name = 'test_metric'; 

% the maximum number of iterations
iter_max = 20;

% Test hdr image used for this evaluation.
hdr_file = '.\test_images\SpheronNice_o9E0.hdr';

%%
format short g
addpath(genpath('.\Metrics\'));
addpath('.\gTMOs\');
results_folder = '.\results\';

% read HDR image.
hdr = 179*double(hdrread(hdr_file));

% Downscale HDR image for better speed
r = max(0.25, 300/min(size(hdr,1),size(hdr,2)));
hdr = imresize(hdr, r);
hdr(hdr<=0) = 0.01;
y = 0:255;

%% Set DE options
S_struct.n_itermax = iter_max;      % terminate after this number of iterations
S_struct.log_domain = 1;            % apply mutation in linear or log domain
S_struct.monotonic = 0;             % if 0, then 5 out of 35 TMCs will be allowed to remain non-monotonic

S_struct.nPopulation = 35;          % number of candidate soultions
S_struct.nParameters = 256;         % number of coefficients in a candidate solution
S_struct.weight =0.65;              % F: Weight used in mutation
S_struct.CR = 0.65;                 % CR: crossover probabililty constant
S_struct.strategy = 2;              % There are 6 mutation strategies in DE
S_struct.refresh = 3;               % show intermediate results after 'refresh' number of iterations
S_struct.metric_name = metric_name; % metric to be used as the cost function
S_struct.hdr = hdr;                 % the  input  image
S_struct.y = y;                     % The L vector (LDR values in the LUT).  It will remain unchanged. 

%%  Call the DE Optimization function
% DE produces a population of candidate solutions which keeps evolving. We
% consider only the best solutions in the first and the last populations
% and their scores assigned by the metric for final comparison.

% Output parameters: x1, x2: the best TMCs in the inital and final population
% score1, score2: their scores
[x2, score2, x1, score1] = deopt(S_struct);

x = [x1; x2];
scores = [score1, score2];

%% Save Images and Scores
% We store the scores as parts of the file name. So when you compare the
% images visually, you can see thier scores in the file names. The best way
% to compare is to open the image file in full screen mode and then use
% right/left arrows to shift between the two, to better perceive the
% changes.
[~,img_name,~] = fileparts(hdr_file);
for k=1:numel(scores)
    ldr2 = apply_tmo(hdr, x(k,:), y, 1);
    ldr_file = sprintf('%s%s(%s)(%d)(%0.2f).png', results_folder, img_name, metric_name, k, scores(k));    
    imwrite(uint8(ldr2), ldr_file);    
end


