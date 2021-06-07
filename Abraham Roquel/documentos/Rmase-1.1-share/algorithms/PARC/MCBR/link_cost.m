function out = link_cost(idx)

global ID t

global LTOTALS
global RTIMES
global RSTRENGTHS
global RNUMBERS


out = exp(-RSTRENGTHS{ID}(idx))+exp(LTOTALS{ID}(idx)/RNUMBERS{ID}(idx));    