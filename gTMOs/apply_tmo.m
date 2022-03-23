%------------------------------------------
function out = apply_tmo(in, x, y, s)
%------------------------------------------
% input parameter "in" is HDR image in RGB format. [x, y] are the LUT that
% define the TMO. The last optional parameter is for gamma correction. If
% it is defined, then HDR luminance is tone-mapped and then a ratio image
% is used to transform RGB images and gamma corretion is also applied. If
% the last parameter is not defined, then RGB values of each channel are
% tone-mapped independently. We recoomend the first option and gamma =
% 1/1.5.

[x,idx]=unique(x); y = y(idx);
[y,idx]=unique(y); x=x(idx);

if size(in,3)==1  % luminance channel only
    out = interp1(x, y, in, 'linear', 'extrap');
%    if s > 1, out = out .^s; end
    return
end

if (nargin<4) % each channel tone-mapped independently
    
    out = interp1(x, y ,in, 'linear', 'extrap');
    
else % relative ratios maintained
    
    in_lum = 1.0*(0.2126.*in(:,:,1)+0.7152.*in(:,:,2)+0.0722.*in(:,:,3));
    out_lum = interp1(x, y, in_lum, 'linear', 'extrap');
    out = (in ./ (in_lum)) .^ s .* (out_lum) ;
    out(out > 255) = 255;
    
end
end

