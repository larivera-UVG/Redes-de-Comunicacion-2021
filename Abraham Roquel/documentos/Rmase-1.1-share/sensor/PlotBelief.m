function PlotBelief(belief, target)

global BELIEF_HANDLES

BORDER = 6;
MK_SIZE = 15;
h_ax = Prowler('GetDisplayHandle');
load black_white
if (~isempty(BELIEF_HANDLES)) 
    try delete(BELIEF_HANDLES), catch disp('not valid handles'), end; 
end
    
bak = pcolor((-BORDER:belief.x_max+BORDER)*belief.dx, ...
    (-BORDER:belief.y_max+BORDER)*belief.dy, zeros(belief.y_max+2*BORDER+1, belief.x_max+2*BORDER+1));
hold on;
if (isempty(h_ax))   
	colormap(map);
	bel = pcolor((0:belief.x_max)*belief.dx, (0:belief.y_max)*belief.dy, belief.display);
    tar = plot(target(1), target(2), 'r+', target(1), target(2), 'ro', 'markersize', MK_SIZE);    
else
    set(bak, 'parent', h_ax);
	colormap(h_ax, map);
	bel = pcolor((0:belief.x_max)*belief.dx, (0:belief.y_max)*belief.dy, belief.display);
	set(bel, 'parent', h_ax);
    tar = plot(target(1), target(2), 'r+', target(1), target(2), 'ro', 'markersize', MK_SIZE, 'parent', h_ax);
end

BELIEF_HANDLES = [bak, bel, tar(1), tar(2)];
prowler('Redraw');