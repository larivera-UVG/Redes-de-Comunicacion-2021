function abe_myfun()
    persistent n
    if isempty(n)
        n = 0;
    end
    n = n+1
    n
end