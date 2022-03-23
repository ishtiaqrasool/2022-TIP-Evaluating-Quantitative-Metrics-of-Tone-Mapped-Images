function x = globalTMO_to_matt(L, Ld)

% Pick key-points from the tone curve (ATT like LUT)
[y1, x1] = ikey_points(Ld(:), L(:), 0.0001, 256);

% Convert LUT to MATT-like structure
y0 = min(y1) : (max(y1)-min(y1))/255 : max(y1);
x = interp1(y1, x1, y0, 'linear', 'extrap');

end

%---------------------------------------------------------------------
function [yy, xx, delta] = ikey_points(y, x, delta, max_no_key_points)
%----------------------------------------------------------------------

if size(y, 1) == 1 
    y = y'; 
    x = x';
end
[x, i] = unique(x);
y = y(i);

nPoints = size(y, 1);

if nargin < 3 
    delta = 0.005; %(max(y) - min(y))/nPoints;
end
if nargin < 4
    max_no_key_points = 100;
end

status = zeros(nPoints, 1);
status(:) = 2; status(1) = 1; status(end) = 1;

xx = [min(x), max(x)];
yy = [min(y), max(y)];
y0 = interp1(xx, yy, x);

while(1)

    if numel(xx) >= max_no_key_points, break, end
    
    [m, j] = max(abs(y - y0));
    if m <= delta, break; end
    
    if ismember(x(j), xx), break; end
    if ismember(y(j), yy), break; end
    xx = [xx, x(j)]; xx = sort(xx);
    yy = [yy, y(j)]; yy = sort(yy);
    
    y0 = interp1(xx, yy, x);
    

end
delta = m;
end

