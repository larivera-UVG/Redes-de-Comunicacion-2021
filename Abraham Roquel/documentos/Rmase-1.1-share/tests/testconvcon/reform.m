function out = reform(in)
in = in';
for i=1:7
    out(i,:) = in(10*(i-1)+1:10*i);
end