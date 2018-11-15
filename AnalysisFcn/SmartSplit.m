function [ncols,nrows] = SmartSplit(N)
% Function to generate smart distribution of subplots
%
% Input:
% - N: number of subplots
%
% Output:
% - ncols: number of columns
% - nrows: number of rows
%
% Example of usage:
% [ncols,nrows] = SmartSplit(N)
%
% Last update: 14/11/2018

SmartDist = [1 1;... 
    1 2;...
    1 3;...
    2 2;...
    3 2;...
    3 2;...
    4 2;...
    4 2;...
    3 3;...
    5 2;...
    4 3;...
    4 3;...
    4 max(ceil(N/4),1)];
if N <= 12
    ncols = SmartDist(N,1);
    nrows = SmartDist(N,2);
else
    ncols = SmartDist(13,1);
    nrows = SmartDist(13,2);
end