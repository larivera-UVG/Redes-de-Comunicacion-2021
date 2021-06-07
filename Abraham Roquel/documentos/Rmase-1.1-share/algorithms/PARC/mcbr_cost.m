function out=mcbr_cost(varargin)

out = 1;
func = sim_params('get_app', 'CostFunc'); 
if (isempty(func)) return; end
n = length(varargin);
switch n
    case 0
        try out = feval(func); end
    case 1
        try out = feval(func, varargin{1}); end
    case 2
        try out = feval(func, varargin{1}, varargin{2}); end
    case 3
        try out = feval(func, varargin{1}, varargin{2}, varargin{3}); end
end
