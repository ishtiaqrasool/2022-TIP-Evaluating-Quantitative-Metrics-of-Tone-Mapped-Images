function [x,ldr2,ldr1]=theyab(imhdr,n)
addpath('.\gTMOs\');
if n==1
    [ldr1,L,Ld]=LogarithmicTMO(imhdr,100,0);
elseif n==2
    [ldr1,L,Ld]=DragoTMO(imhdr);
elseif n==3
    [ldr1,L,Ld]=ExponentialTMO(imhdr);
elseif n==4
    [ldr1,L,Ld]=LogarithmicTMO(imhdr);
elseif n==5
    [ldr1,L,Ld]=ReinhardTMO(imhdr);
elseif n==6
    [ldr1,L,Ld]=NormalizeTMO(imhdr);
elseif n==7
    [ldr1,L,Ld]=TumblinTMO(imhdr);
elseif n==8
    [ldr1,L,Ld]=VanHaterenTMO(imhdr);
elseif n==9
    [ldr1,L,Ld]=KimKautzConsistentTMO(imhdr);
elseif n==10
    [ldr1,L,Ld]=WardHistAdjTMO(imhdr);
elseif n==11    
    [ldr1,L,Ld]=WardGlobalTMO(imhdr);
end

x=globalTMO_to_matt(L,Ld);
