function out = mcbr_dest

out = 0;
func = sim_params('get_app', 'DestFunc'); 
if (isempty(func)) return; end
try out = feval(func)*mcbr_cost; end