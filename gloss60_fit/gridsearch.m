
function [gminparams, gmineval] = gridsearch(f,lb,ub,nper,shrink,tol,miniter,constrain,jitter)

% minimize function f using iterative grid search
%
% lb and ub are the initial lower and upper bounds (vectors giving bounds
% for each parameter).
%
% nper is the number of samples per dimension on each iteration.
%
% On each iteration, the function is evaluated at each grid point. For the
% next iteration, the grid is centered on the previous best value, and the
% range of each parameter is shrunk by a factor of shrink. Iterations
% repeat until the function value changes by less than tol for at least
% miniter iterations in a row. If 'constrain' is nonzero, then the initial
% parameter range is absolute, so new ranges are shifted to lie within the
% initial range. If 'jitter' is nonzero, on each iteration the grid center
% randomly jittered +/- 1/2 grid width to avoid repeating values. Note: the
% best value is kept, so that if the next iteration results in a poorer
% fit, the previously better value isn't forgotten. The next iteration's
% grid starts centered on the best value from all previous iterations.

if min(size(lb))>1 | min(size(ub))>1 | length(lb)~=length(ub)
    error('fminmsl: lb/ub must be vectors of equal length');
end
if fix(nper)~=nper | nper < 4
    error('fminmsl: nper must be an integer greater than 3');
end
if shrink <= 0 | shrink >= 1
    error('fminmsl: shrink must lie between 0 and 1');
end
if fix(miniter)~=miniter | miniter<1
    error('fminmsl: miniter must be a positive integer');
end

ncurriter = 0;
firstiter = 1;
initlb = lb;    % save for later use as a constraint
initub = ub;
ndim = length(lb);
neval = nper^ndim;
svgrid = zeros(1,neval);
while (1)
    incr = (ub-lb)/(nper-1);
    currind = zeros(size(lb));
    minparams = lb;
    mineval = f(minparams);
    svgrid(1) = mineval;
    ind = zeros(size(lb));
    for evalnum = 2:neval
        for dim = 1:ndim
            newval = ind(dim) + 1;
            if newval > nper
                ind(dim) = 0;
            else
                ind(dim) = newval;
                break;
            end
        end
        cparam = lb + ind.*incr;
        fval = f(cparam);
        svgrid(evalnum) = fval;
        if fval < mineval
            mineval = fval;
            minparams = cparam;
        end
    end
    if firstiter
        firstiter = 0;
        gminparams = minparams;
        gmineval = mineval;
    else
        chg = gmineval - mineval;
        if chg > 0  % if any improvement
            gminparams = minparams;
            gmineval = mineval;
        end
        if chg > tol    % if enough improvement
            ncurriter = 0;
        else
            ncurriter = ncurriter + 1;
            if ncurriter >= miniter
                break;
            end
        end
    end
    newhalfrange = shrink*(ub-lb)/2;
    lb = gminparams - newhalfrange;
    ub = gminparams + newhalfrange;
    if jitter
        jit = 2*(rand(size(ub))-.5) .* newhalfrange/nper;
        lb = lb + jit;
        ub = ub + jit;
    end
    if constrain
        low = find(lb < initlb);
        high = find(ub > initub);
        lb(low) = initlb(low);
        ub(low) = lb(low) + 2*newhalfrange(low);
        ub(high) = initub(high);
        lb(high) = ub(high) - 2*newhalfrange(high);
    end
end