function y = persis_poiner(u)
    persistent n
        
    if isempty(n)
        n = u;
    else
    	n = n + 1;
    end
    
    y = n;
end