%-----------------------------------
function [x, y] = design_tmo_matt(hdr)
%------------------------------------
% ATT stands for Adaptive TVI Tone-mapping. The function tone-maps a high
% dynamic range image (hdr) to a low dynamic range image (ldr). ATT was
% published in IEEE Transactions on Industrial Electronics, 65(4),
% 3469-3479, 2018. (irkhan@uj.edu.sa)
%
% MATT is a modified version of ATT which maintains the same tone-mapping
% curve but makes the inversion very fast.
% MATT is defined by only x (hdr key values). y (ldr values) are 0:255
%-------------------------------------

[x1, y1] = design_tmo_att(hdr);
y = (0:255.0)/255;
x = interp1(y1, x1, y, 'linear', 'extrap');

end