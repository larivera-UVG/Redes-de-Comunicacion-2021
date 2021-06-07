function Plot3D(type, bt)

BORDER=6;

[v, x, y]=attribute(type);
if bt==1 
    bv = max(max(v));
elseif bt==0
    bv = min(min(v));
else bt = 0;
end
bak = pcolor([min(x)-BORDER,x,max(x)+BORDER], [min(y)-BORDER,y,max(y)+BORDER], ...
    ones(length(y)+2, length(x)+2)*bv);

h_ax = Prowler('GetDisplayHandle');
colormap(h_ax, hot);
set(bak, 'parent', h_ax);
child=pcolor(x, y, v);
shading interp;
set(child, 'parent', h_ax);
prowler('Redraw');