%[text] # Run samples of the ServiceQueueBaseline simulation Aiden Camilleri
%[text] Collect statistics and plot histograms along the way.
%%
%[text] ## Set up
%[text] We'll measure time in hours
%[text] Arrival rate: 40 per hour
lambda = 48;
%[text] Departure (service) rate: 1 per 8 minutes, so 60/8 per hour
mu = 60/8;
%[text] Number of serving stations
s = 9;
%[text] Run 100 samples of the queue.
NumSamples = 100;
%[text] Each sample is run up to a maximum time.
MaxTime = 4;
%[text] Make a log entry every so often
LogInterval = 1/60;
%%
%[text] ## Numbers from theory for M/M/1 queue
%[text] Compute `P(1+n)` = $P\_n$ = probability of finding the system in state $n$ in the long term. Note that this calculation assumes $s=1$.
%[text] rho = lambda / mu;
%[text] P0 = 1 - rho;
%[text] nMax = 10;
%[text] P = zeros(\[1, nMax+1\]);
%[text] P(1) = P0;
%[text] for n = 1:nMax
%[text]     P(1+n) = P0 \* rho^n;
%[text] end
%%
%[text] ## Numbers from theory for M/M/k queue (k=s)
%[text] Rewrote above section with info from Example 8.8 from textbook.
k = s;
maxN = 10;
nMax = maxN;
muN = 1:maxN;
for n = 1:maxN
    if n <= k
        muN(n) = n * mu;
    elseif muN >= k
        muN(n) = k * mu;
    end
end

P0S1 = 0;
for n = 0:k-1
    P0S1 = P0S1 + ((lambda/mu)^n)/factorial(n);
end
P0Part2 = (1/factorial(k)) * (lambda/mu)^k * 1/(1-(lambda/(k*mu)));

P0 = 1/(P0S1+P0Part2);
P = zeros([1, maxN]);
P(1) = P0;

for n = 1:maxN
    if n <= k
        P(n+1) = P(1)*((lambda/mu)^n)/factorial(n);
    elseif n > k
        P(n+1) = P(1)*((lambda/(k*mu))^n)*(k^k/factorial(k));
    end
end
%%
%[text] ## Run simulation samples
%[text] This is the most time consuming calculation in the script, so let's put it in its own section.  That way, we can run it once, and more easily run the faster calculations multiple times as we add features to this script.
%[text] Reset the random number generator.  This causes MATLAB to use the same sequence of pseudo-random numbers each time you run the script, which means the results come out exactly the same.  This is a good idea for testing purposes.  Under other circumstances, you probably want the random numbers to be truly unpredictable and you wouldn't do this.
rng("default");
%[text] We'll store our queue simulation objects in this list.
QSamples = cell([NumSamples, 1]);
%[text] The statistics come out weird if the log interval is too short, because the log entries are not independent enough.  So the log interval should be long enough for several arrival and departure events happen.
for SampleNum = 1:NumSamples %[output:group:2eee3106]
    fprintf("Working on sample %d\n", SampleNum); %[output:94f11e96]
    q = ServiceQueue( ...
        ArrivalRate=lambda, ...
        DepartureRate=mu, ...
        NumServers=s, ...
        LogInterval=LogInterval);
    q.schedule_event(Arrival(random(q.InterArrivalDist), Customer(1)));
    run_until(q, MaxTime);
    QSamples{SampleNum} = q;
end %[output:group:2eee3106]
%%
%[text] ## Collect measurements of how many customers are in the system
%[text] Count how many customers are in the system at each log entry for each sample run.  There are two ways to do this.  You only have to do one of them.
%[text] ### Option one: Use a for loop.
NumInSystemSamples = cell([NumSamples, 1]);
for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};
    % Pull out samples of the number of customers in the queue system. Each
    % sample run of the queue results in a column of samples of customer
    % counts, because tables like q.Log allow easy extraction of whole
    % columns like this.
    NumInSystemSamples{SampleNum} = q.Log.NumWaiting + q.Log.NumInService;
end
%[text] ### Option two: Map a function over the cell array of ServiceQueue objects.
%[text] The `@(q) ...` expression is shorthand for a function that takes a `ServiceQueue` as input, names it `q`, and computes the sum of two columns from its log.  The `cellfun` function applies that function to each item in `QSamples`. The option `UniformOutput=false` tells `cellfun` to produce a cell array rather than a numerical array.
NumInSystemSamples = cellfun( ...
    @(q) q.Log.NumWaiting + q.Log.NumInService, ...
    QSamples, ...
    UniformOutput=false);

NumWaitingSamples = cellfun( ...
    @(q) q.Log.NumWaiting, ...
    QSamples, ...
    UniformOutput=false);
%[text] ## Join numbers from all sample runs.
%[text] `vertcat` is short for "vertical concatenate", meaning it joins a bunch of arrays vertically, which in this case results in one tall column.
NumInSystem = vertcat(NumInSystemSamples{:});

NumWaiting = vertcat(NumWaitingSamples{:});
%[text] 
%[text] MATLAB-ism: When you pull multiple items from a cell array, the result is a "comma-separated list" rather than some kind of array.  Thus, the above means
%[text] `NumInSystem = vertcat(NumInSystemSamples{1}, NumInSystemSamples{2}, ...)`
%[text] which concatenates all the columns of numbers in NumInSystemSamples into one long column.
%[text] This is roughly equivalent to "splatting" in Python, which looks like `f(*args)`.
%%
%[text] ## Pictures and stats for number of customers in system
%[text] Print out mean number of customers in the system.
meanNumInSystem = mean(NumInSystem);
meanNumWaiting = mean(NumWaiting);
fprintf("Mean number in system: %f\n", meanNumInSystem); %[output:084d9b32]
fprintf("Mean number waiting: %f\n", meanNumWaiting); %[output:07b06633]
%[text] 
%[text] Make a figure with one set of axes.
fig = figure(); %[output:1609bd1c]
t = tiledlayout(fig,1,1); %[output:1609bd1c]
ax = nexttile(t); %[output:1609bd1c]
%[text] MATLAB-ism: Once you've created a picture, you can use `hold` to cause further plotting functions to work with the same picture rather than create a new one.
hold(ax, "on"); %[output:1609bd1c]
%[text] Start with a histogram.  The result is an empirical PDF, that is, the area of the bar at horizontal index n is proportional to the fraction of samples for which there were n customers in the system.  The data for this histogram is counts of customers, which must all be whole numbers.  The option `BinMethod="integers"` means to use bins $(-0.5, 0.5), (0.5, 1.5), \\dots$ so that the height of the first bar is proportional to the count of 0s in the data, the height of the second bar is proportional to the count of 1s, etc. MATLAB can choose bins automatically, but since we know the data consists of whole numbers, it makes sense to specify this option so we get consistent results.
h = histogram(ax, NumInSystem, Normalization="probability", BinMethod="integers"); %[output:1609bd1c]
%[text] Plot $(0, P\_0), (1, P\_1), \\dots$.  If all goes well, these dots should land close to the tops of the bars of the histogram.
plot(ax, 0:nMax, P, 'o', MarkerEdgeColor='k', MarkerFaceColor='r'); %[output:1609bd1c]
%[text] Add titles and labels and such.
title(ax, "Number of customers in the system"); %[output:1609bd1c]
xlabel(ax, "Count"); %[output:1609bd1c]
ylabel(ax, "Probability"); %[output:1609bd1c]
legend(ax, "simulation", "theory"); %[output:1609bd1c]
%[text] Set ranges on the axes. MATLAB's plotting functions do this automatically, but when you need to compare two sets of data, it's a good idea to use the same ranges on the two pictures.  To start, you can let MATLAB choose the ranges automatically, and just know that it might choose very different ranges for different sets of data.  Once you're certain the picture content is correct, choose an x range and a y range that gives good results for all sets of data.  The final choice of ranges is a matter of some trial and error.  You generally have to do these commands *after* calling `plot` and `histogram`.
%[text] This sets the vertical axis to go from $0$ to $0.3$.
ylim(ax, [0, 0.3]); %[output:1609bd1c]
%[text] This sets the horizontal axis to go from $-1$ to $21$.  The histogram will use bins $(-0.5, 0.5), (0.5, 1.5), \\dots$ so this leaves some visual breathing room on the left.
xlim(ax, [-1, 21]); %[output:1609bd1c]
%[text] MATLAB-ism: You have to wait a couple of seconds for those settings to take effect or `exportgraphics` will screw up the margins.
pause(2);
%[text] Save the picture as a PDF file.
exportgraphics(fig, "Number in system histogram.pdf"); %[output:1609bd1c]
%%
%[text] ## Collect measurements of how long customers spend in the system
%[text] This is a rather different calculation because instead of looking at log entries for each sample `ServiceQueue`, we'll look at the list of served  customers in each sample `ServiceQueue`.
%[text] ### Option one: Use a for loop.
TimeInSystemSamples = cell([NumSamples, 1]);
for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};
    % The next command has many parts.
    %
    % q.Served is a row vector of all customers served in this particular
    % sample.
    % The ' on q.Served' transposes it to a column.
    %
    % The @(c) ... expression below says given a customer c, compute its
    % departure time minus its arrival time, which is how long c spent in
    % the system.
    %
    % cellfun(@(c) ..., q.Served') means to compute the time each customer
    % in q.Served spent in the system, and build a column vector of the
    % results.
    %
    % The column vector is stored in TimeInSystemSamples{SampleNum}.
    TimeInSystemSamples{SampleNum} = ...
        cellfun(@(c) c.DepartureTime - c.ArrivalTime, q.Served');
end

%[text] ### Option two: Use `cellfun` twice.
%[text] The outer call to `cellfun` means do something to each `ServiceQueue` object in `QSamples`.  The "something" it does is to look at each customer in the `ServiceQueue` object's list `q.Served` and compute the time it spent in the system.
TimeInSystemSamples = cellfun( ...
    @(q) cellfun(@(c) c.DepartureTime - c.ArrivalTime, q.Served'), ...
    QSamples, ...
    UniformOutput=false);

TimeInWaitingSamples = cellfun( ...
    @(q) cellfun(@(c) c.BeginServiceTime - c.ArrivalTime, q.Served'), ...
    QSamples, ...
    UniformOutput=false);
%[text] ### Join them all into one big column.
TimeInSystem = vertcat(TimeInSystemSamples{:});
TimeInWaiting = vertcat(TimeInWaitingSamples{:});
%%
%[text] ## Pictures and stats for time customers spend in the system
%[text] Print out mean time spent in the system.
meanTimeInSystem = mean(TimeInSystem);
fprintf("Mean time in system: %f\n", meanTimeInSystem); %[output:9f6cc477]

meanTimeInWaiting = mean(TimeInWaiting);
fprintf("Mean time waiting: %f\n", meanTimeInWaiting); %[output:6ebd9048]
fprintf("Pct wait > 5 mins: %f\n", sum(TimeInWaiting > 5/60)/length(TimeInWaiting)*100); %[output:54121984]
%[text] Make a figure with one set of axes.
fig = figure(); %[output:85b46fc8]
t = tiledlayout(fig,1,1); %[output:85b46fc8]
ax = nexttile(t); %[output:85b46fc8]
%[text] This time, the data is a list of real numbers, not integers.  The option `BinWidth=...` means to use bins of a particular width, and choose the left-most and right-most edges automatically.  Instead, you could specify the left-most and right-most edges explicitly.  For instance, using `BinEdges=0:0.5:60` means to use bins $(0, 0.5), (0.5, 1.0), \\dots$
h = histogram(ax, TimeInSystem, Normalization="probability", BinWidth=5/60); %[output:85b46fc8]
%[text] Add titles and labels and such.
title(ax, "Time in the system"); %[output:85b46fc8]
xlabel(ax, "Time"); %[output:85b46fc8]
ylabel(ax, "Probability"); %[output:85b46fc8]
%[text] Set ranges on the axes.
ylim(ax, [0, 0.2]); %[output:85b46fc8]
xlim(ax, [0, 2.0]); %[output:85b46fc8]
%[text] Wait for MATLAB to catch up.
pause(2);
%[text] Save the picture as a PDF file.
exportgraphics(fig, "Time in system histogram.pdf"); %[output:85b46fc8]
%[text] `Min registers to meet Ricky's constraint with Jackie's estimates is 9 registers. There is not room for 9 registers.`

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":21.6}
%---
%[output:94f11e96]
%   data: {"dataType":"text","outputData":{"text":"Working on sample 1\nWorking on sample 2\nWorking on sample 3\nWorking on sample 4\nWorking on sample 5\nWorking on sample 6\nWorking on sample 7\nWorking on sample 8\nWorking on sample 9\nWorking on sample 10\nWorking on sample 11\nWorking on sample 12\nWorking on sample 13\nWorking on sample 14\nWorking on sample 15\nWorking on sample 16\nWorking on sample 17\nWorking on sample 18\nWorking on sample 19\nWorking on sample 20\nWorking on sample 21\nWorking on sample 22\nWorking on sample 23\nWorking on sample 24\nWorking on sample 25\nWorking on sample 26\nWorking on sample 27\nWorking on sample 28\nWorking on sample 29\nWorking on sample 30\nWorking on sample 31\nWorking on sample 32\nWorking on sample 33\nWorking on sample 34\nWorking on sample 35\nWorking on sample 36\nWorking on sample 37\nWorking on sample 38\nWorking on sample 39\nWorking on sample 40\nWorking on sample 41\nWorking on sample 42\nWorking on sample 43\nWorking on sample 44\nWorking on sample 45\nWorking on sample 46\nWorking on sample 47\nWorking on sample 48\nWorking on sample 49\nWorking on sample 50\nWorking on sample 51\nWorking on sample 52\nWorking on sample 53\nWorking on sample 54\nWorking on sample 55\nWorking on sample 56\nWorking on sample 57\nWorking on sample 58\nWorking on sample 59\nWorking on sample 60\nWorking on sample 61\nWorking on sample 62\nWorking on sample 63\nWorking on sample 64\nWorking on sample 65\nWorking on sample 66\nWorking on sample 67\nWorking on sample 68\nWorking on sample 69\nWorking on sample 70\nWorking on sample 71\nWorking on sample 72\nWorking on sample 73\nWorking on sample 74\nWorking on sample 75\nWorking on sample 76\nWorking on sample 77\nWorking on sample 78\nWorking on sample 79\nWorking on sample 80\nWorking on sample 81\nWorking on sample 82\nWorking on sample 83\nWorking on sample 84\nWorking on sample 85\nWorking on sample 86\nWorking on sample 87\nWorking on sample 88\nWorking on sample 89\nWorking on sample 90\nWorking on sample 91\nWorking on sample 92\nWorking on sample 93\nWorking on sample 94\nWorking on sample 95\nWorking on sample 96\nWorking on sample 97\nWorking on sample 98\nWorking on sample 99\nWorking on sample 100\n","truncated":false}}
%---
%[output:084d9b32]
%   data: {"dataType":"text","outputData":{"text":"Mean number in system: 6.629704\n","truncated":false}}
%---
%[output:07b06633]
%   data: {"dataType":"text","outputData":{"text":"Mean number waiting: 0.517566\n","truncated":false}}
%---
%[output:1609bd1c]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAARkAAACpCAYAAAAfrUnWAAAAAXNSR0IArs4c6QAAIABJREFUeF7tnQu8zVX6\/x+G6qhUCsW4hSZFlAlNMhORTEkXImkiUpPjLtO4VCJJGaWJCpFrdKFGuYQumHSZopuTCiE0SKJDN7\/\/e\/1\/6\/y+tn0756zv3t\/vPs96vbxwznevvb6ftdZnPc+znkuxMmXKHBJtioAioAj4hEAxJRmfkNVuFQFFwCCgJKMLQRFQBHxFQEnGV3i1c0VAEVCS0TWgCCgCviKgJOMrvNq5IqAIKMnoGlAEFAFfEVCS8RVe7VwRUASUZHQNKAKKgK8IKMn4Cq92rggoAkoyugYUAUXAVwSUZHyFVztXBBQBJRldA4qAIuArAkoyvsKrnSsCikCoSeaoo46SSpUqmVn84osv8mazXLlycvzxx8vWrVvlwIEDzma5TJkycsIJJ8iOHTvkhx9+cNZvsh2deuqpUrNmTVmzZo3s3bs32Y8VqefOP\/98+fHHHw1GhWklS5YU1hHz\/O233xamqyL\/2VCTzHnnnSf\/\/Oc\/zSSOHz9enn76afNv\/mYzPvjgg\/Lcc885m+SJEyfK2Wefbb5z+vTpzvpNpqNbbrlFOnfubB4dPny4LFiwIJmPFeqZoUOHGhLv169faEjt3\/\/+t\/z6669y4YUX5uvdWUu33Xab8PnJkydL69at5c4775QNGzbI9ddfn6++\/H44cqx+f19h+88Ykjl48KA0b95cfvrpp4wkmblz58pvf\/tbee+992TkyJFGSvO7LV682EiE7dq1k82bN\/v9dU765yDIzc2V7OzsfPV3zTXXSP\/+\/SUnJ0duuummQJNM5Fjz9aJpeDhjSAbslixZIpy+XkkG8unZs6e8\/fbbMnjwYDnllFNk5syZsmvXLunQoYM5rf74xz+azcsJUapUKXn55ZelWLFictlll+VJSbNnzxYryXz88cdSuXJlQV379NNPTf+QW8OGDc33n3jiiUbMXrhwoTz00ENyzDHHyIsvvihff\/21fP\/993LOOeeY7\/Q2xPN\/\/OMfUrt2bdMvnx83bpzMnz9fRo0aJRdddJEZ0549e8z\/X3vttcM+j7TBeOmH75kxY4b861\/\/MuNp3LixPP7440aqu+qqq8yJvWLFChk2bJhccsklcvPNN5v3YWzgxGe834m60KdPH\/nyyy9jjrFFixbSt29f+eyzz6RixYoG588\/\/1xeeOEFg8\/RRx9tpIS\/\/e1vZtyxsGI8d9xxhxnHmWeeKT\/\/\/LO0b99ekOQuv\/xyOfnkk2Xnzp0yZ84c846RDcyZ8yuvvNJIYBw8H3zwgcGcuV23bp307t37MDUazMH+uOOOM\/PIOFeuXGnWxjfffGNw53vBHiJizlFdR48eLVWqVJFDhw7JJ598Ir169TKqWmSLNfZnn31WSpcuLffee6+8+eab8uc\/\/9n0AdGB5d133y0NGjQw62Hbtm3ywAMPmP4jxzpw4EBDjB07djTv+N1338nYsWOFQyI\/69sv\/skIkmFzsIjZYLA8k1GjRg0zGWxwNtX69evlxhtvNBuAyeW0a9q0qVGz6tWrZ\/BlgdGHbfb\/LCJIgWdRl2hMNpNPgwiefPJJQyTFixc3k8ziYXFOmzZNpk6dKq+++uphc3jBBRcc9n9LYHwXBHPsscea37NBr7jiCmnWrJnp+7\/\/\/a8hADaBbV26dJFu3bqZxc57sdBo1157rSEMNhjqHWqeVbsgyh49esiiRYvMO0MO1apVM+80aNAggw1\/eAdsUGxYFizvH22MZ5xxhukvGo5erOjjww8\/jIkVBAKh2cYmv+eee8zY6WfTpk1mbhlDq1atDNbe5lWXxowZIxZn7xgg3ClTpuR97He\/+508\/PDDxt4GQS1fvlzef\/998740fgZGFn9UKdRVbHTgzc9Zf2D4l7\/85bDxWJU+2tjvv\/9+s\/YYM6QyYcIEqVu3rjkMfvOb30ibNm2MPYj1wLpl7gcMGHDEWN966y1DSDSeP+mkk8y\/WRO333570uub9e5HywiSAdh58+YZmwUnVYkSJfJNMm+88YZZVJyEqAgQ0SOPPGLIgY2HXs7mY5NhVLz11luNGsGGYPKXLVsm1113ndmQnNZsgLZt25pJ529LMkhbkOC+ffvy5pMFzPfT7DvYBccJiaRhFzXfG2nUtL+DqCZNmmTGzUbkNIN0Y5EMkhLfw4blvb\/66itzYtM\/4\/WqS9u3b487Rt4fktm9e7chRTbt73\/\/e9m4caORGJEEOfUhXfCMhRWbH0yxq0DcSKUQ3NVXX202G\/PMZoCEkdQ49RORDGO44YYbjAQD8doDx\/u5WOoS5ADZIu2AFYTDHDz11FNmjMwN5ATWNCQn79xCCrHGXr58eXNg7N+\/30iUr7\/+usEGKYy5QbpELebwwgjNPDG3kJxXtZs1a5ZUrVrVfB78\/v73vxub5KpVq8yBA5Els76xP\/nRMoZk2NSvvPKKUVWYZETfaJIMdg3sG5GSjD3pIRdOjbvuustsMjZPVlaWOaEQ4yEZa2RmApcuXWomn9MkUjphwlikjI1NG8sgyQJmQ7GA\/\/SnP5l5ZlNwCnGys2njkQyqEycpInPkpuPU9pIMpxuSD5JM165dzaZlsduGVAhJ\/uc\/\/zmMZNhI8cYIiUAydgOz0Bk3C5\/+rKSGqorEFAsrJBZIhs0FIdBQTZ555pk8yZGfbdmyxWzwyFu2aJIMc4raag8FpCFUsGRIxj6LZIrUx3wiIVm1L3JT2kPC\/jzR2C2xsN6Q2DiwIBFUQzBEkqSxxlCpUI0iCdGu+8ixQBpIepBMMusbScyPllEkg+0BPdk2SIbGomVRIlFwKo0YMSLfJMOmt+qC3TjcYHCDhbTCqYFOjT0EMRgRmgXGKcXCh2S8JOKdTIiRhULDroLuzw0SKpKVBOKRDOJ1hQoVzPggHIyeZ511ljl5IRIkClQ6xmX7hWTuu+8+I54zTk5CnoM47Xd6JRnIJ94YkSqSIRkWO+J8LKxQQZgvr7SB\/QZi4nd16tQxpAm+HBZs+ESSDASIZFUQkrG3S16S4bBBcoFwkChoEDUqDkTkdZtINHbWD+vIHoyo1swb+DAvqPuNGjUykimN+cRW5ZVk7MHIgcihgZTHoYCxnkMlGZJhfXvdQFySTUaRDMBYoy\/\/hmTWrl1rRFsaC5fJ4nTIrySDUY2TxdokMP7RF+It0sxLL71kFh4nDoTCRmDhoe5gV4lHMowNkbhs2bLG+MqJgi7POB999FFj4IxHMqgBqB8sVFSdP\/zhD3mGayQwTm1UDIiWzUqDZB577LE8Wwfjh2jq16+fd21rT0jsPxAzGyDWGOkzGZJBXcLIHgsrNmkkybChOL2R6hhTy5YtzTgsebggGQzikAeHAmODxLxX2F6SufTSSw2ZMPfgjXEa3FhTqD1IrLYlGjuk+cQTT+Q9T99IZ1a9ZP2sXr3aqOtIq5AGqpB3rKxJ7DeQHmsRaRjpG+mRgyMZkmF9Y9j3o2UcyaAOcfPABrV+Ml7iwWbC5k+WZJg0TncvyUAE2G1oLMpOnToZ6z\/GO0R8K+Ii4SDSI7LSTyxJhn4wnLLprcGXn7G57UkJCXBjE80mwwlvJQS7SKx9hs+gs6M+0rCZ8LxVlyAxS2j83tocsG1hNLY3bBAl7xFrjNhdeMZKIGxQxH4r9Vm1DZKhj1hYcYsWSTKMnXfgXWyDcLB1RBorveqSlRJQ0bBxWEnGSmreDQUm3IRBHKhqrBnewb6Pl2S4BIBMuK1k41vcwMva1mzfyYwdOx3PYRPjsKAhASFpWiM+P0Naxj4VOVbeC1UW6dW2jz76SLp3724OkXgk413fRYJkMIAmsnADekG8bZkY2N2VfwkqDn1GTgwkwWRzK4I+n992+umnG9UHCSy\/Xr189rTTTjOSQqSnM051kCOqWGRDtMZTFgKGXLxzwHvyThh+f\/nlF\/PRwozR+935xQrDcfXq1Y0658eGQN2xKm40nCJx4\/latWqZHyNxeCWYyGfjjd2qO0jeHJDehjrLgYZ0y5qyLdpYIWHwgRg5TILSAiHJYOTiZIMEOP0RCSPJADGf0xDAOW055bnt0aYIhBkBa\/hlTWODs0Qe5neKHHvaSQYxFKMhYGOcw+hlHbC8g7X2ACzwnAqI1H7qkZk0yfouikA6EUg7yeApCnFgzEPnx8qNBd1e5VpwsB1g\/MTwh3UdY669TbHPoH9iX8BXBJuENkVAEUg\/AmknGW5GsOxbN3vrIYkKhet\/ZINcsAlgl7FGSfsMRr9o\/hfph1lHoAgUXQTSTjLcnkAW6KM0DFfclOAnEM14hcMZ\/jBc20UaypRkiu5C1jcPLgJpJxmuLHGtxreDxtXgkCFDDgsgxJKOusSVpHUYIogRxzdUK5VkgrvAdGSKQNpJBr8EjL646mMAto5J+Js0adLE+AkQV4M9Bmcy\/ASI48Dfgtsmm0OGqVRJRhe0IhA8BNJOMkACcdg4Fa7yiP\/AnZtgL\/w08GbERkMYvHVWI40Az3mv\/JRkgrfAdESKQCBIhmmATDDoEpgXr3GzhDNWtLSaSjK6oBWB4CEQGJJxAY2SjAsUtQ9FwC0CSjJu8dTeFAFFIAIBJRldEoqAIuArAkoyvsKrnSsCioCSjK4BJwjYkA4nnWknBUKASxOyKQatKckEbUZCOh41uqd\/4oI6B0oy6V8bGTGCoC7wjAA3yZcI6hwoySQ5gfpYfASCusCL0rwFdQ6UZIrSKvTxXSMXeNBtNMnYL0iBSTrXwpQ6JhkbmQMS1dMmqx11wSITo+dnypRk8oNWAZ8NKsgFfJ1QfSwSe\/7ffNhLgX2HJUOvSJgWhNy5eJhTabOgjbg8jLHk3I3WIDDKvbz77rumQBtEU9AW1PWvkkxBZ1Q\/dxgCYScZIv2p6oD08vzzz5vSMlaSod4RyeKJ+qdsLJUEqDpJuhEqG5BEnmRr5PlFQoKYCO4l2NeSDNUtSFNCUm\/yKBOXR15lEraRQJxSNaQ8sZUSiOWjVAoZIemToGCSjJNAnc+RQTKyTpKSTAo2ZVBBTsGrp\/0rwk4ySBskT7MlV2wxPpKoUa+KTU3hNdQeKkvwN0G6lBwhiyMVEShvi5qIBAShUNTPkgyVFUhrQkYBcidBHFSgoJoo\/UAm1MQmeRskRlpaSIsUKKRCIV6PMUB0ZCOAaKiEAXnZFtT1r5JM2rdnZgwg7CRDRUgkCTY7pUeoPEC5WC\/JQEKU0oEoyGNEWRkS2lNfHIkkHsmQPYAk+PxBIqGUMtIKRIO6RH1wStBSdZP+KXdLuR1sOkg\/VMAkHQqERn0l8ilRj4s\/SjIp3ENBZfIUQpC2rwo7yZDXCKKhWiMZAchXRC0kSzIQAFIGFR0hE1QZiAiSoRYWZWYtySBhUIzOK8kg3UAQSCRU5aA2VzSSoR9sMzbHNSWFeY581iTatz+HnLDnoHYpyaRw2SvJpBDsiK8KO8mgkqB6sGlJCYtNBVuMJRm7wWORDBUdqVvFZ7lNooCgl2RQo\/g5\/ZOADYnIkgxk8f777xtJhsyQttQw0g1J2aijxDNKMhGLjop9XMtRlY8\/iYq2udgeSjIuUCxYH2EnGcrDUgESFYWqkNg\/uL4+99xzjU3EbnAKEFIlMlKS4VkkIcoUU9IHlcZLMhiVIS5+R+5qivAhnUA0lLgdOXKkDBgwwEhLEBVqk23Yd7DRRJIMtcDDkBnSN5uMNX5RXB2xkis8RNAVK1YUbBUn8SklmSRA8umRTPCTQT3ixojr5IIUWeOGCjKI5RMDsZBsjd9zAFMCiMOXmyNvdUimCDLjBgvpKtmxBHX9+0Yydi1XrFjRFAu\/+OKLBcKhlAmWe+ohA7LLFlSQXb5jUPtS7NM\/M0GdA99JBkbGKk+O3ho1apiZgL35ua1Q4Gp6ggqyq\/cLcj+KffpnJ6hz4BvJYMDCMl61alVjSUcc5GoOlQlphuu47t27O52ZoILs9CUD2plin\/6JCeoc+EYyWNIrVapkLOX8e+vWrYfNAsXbsLK7bEEF2eU7BrUvv7DnFqaYiGT9\/LPs5e+sLONjou1IBPyag8Ji7RvJUIjtyy+\/NLYXb0OawbvSFmkr7At4Px9UkF2+Y1D78gN7CGZMbq7c6nnpCSLSNyvLkI1fzRsi4Nd3+NGvH3PgYpzOSYbrNgy9eDhyXUcdJds4gVgcTKKSjIvpC04frhc4a2fU3r2HEYx9Wz+IpmnTpuYKGa9fPHC5psa3JUzN9Ry4enfnJEN8BkZe7v6xvXhjK\/AhAIj58+dHHT\/G4ET+NDhD8Uy0a72gguxqsoLcj2vsv\/\/+e\/nxp59ivvKxWVlyjENpBhsh19f8TTFB4om4ksaeiEs\/NkXWZ8+ePY2dkRtSu445UPH6xVMY\/xpMA7hw7N2713jo0tfmzZtl0aJF5n0GDhwoc+bMMQUMXTbXc+BqbM5Jxg4Mwy9OR4mKtfE8pESMBlIOPgTdunU7wobDBOItiSclJLN27VrByxIisy2oILuarCD34xr7Yt9\/LzvjkMwpJUvKoeOPdwYJ3rZ169Y1UdA4zmFPJGSgTp06JjCSKOyJEydKhQoVJCcnx0RjE+eEvRHC2bRpk\/EHI3gSJzzIqkqVKubnBDpecMEF5ue1a9c20dktW7Y0JOSyuZ4DV2NzSjLFixeXxYsXGy\/EatWqGQ\/HaA2W37Vrl\/kVzkvUwCZaFY9GTgJEZSba2\/C6JK6EU4XPjh492pCOrZ3Ns0EF2dVkBbkf19gfyM2V\/bm5MV\/5qJIlTbChq9aiRQtzaHE4oi4hSREEifvFX\/\/6V0MQXGJgYyR8gODJypUry6RJk+S2224zahZt1qxZxuG0cePGsmfPHvO7U0891Xi9491LX1RK7dChg6uhB\/6QdU4yBHdxa1S2bFnD9tEaofNWAmFyiWCF2XHOw17D5NpAMPt5iAvVC\/drGgFihL17r8FdL3TnqyCDO3SNfTSjr4UPm8zA0qWd3jJFkgxSDNINP0e96dGjh0yePNmoPrahFhE+gPpkk00h7XAIQkB4DnMo0shRA0aELyDlFCbbXqxl5HoOXC1XpyRTkEH17t3bnBbEbNAISMPghgplpZ3IfjkF0I2J\/eB0sQ2QaZwuTLa21CHgxwJP5e0SZELsEQZgr+HXkgw5YJC2yfmCejR48GAjSUEe5IRBsuFiA\/IYMmSIkWC8JENkNkSEjQfv92RDBfIzg37MQX6+P9azTkkGdWnJkiUGyHitbdu2eQRCMBiiJpNIq169ukyfPl3wo8Gm423EfpADFV2XybSnhJdk0H21pR4BvxY4qjNkU\/r\/SS+5JUrIof\/1lXH9hqg0EAY2RKRwe7vkJRmIAtuMXd8cdGvWrDESDt7skAwGYhJUkefFSzKlSpUy5PTee+9Jdna26+Gb\/vyag8IO1jnJIFomatherLrEbRT2FhtigE7MSWAlG9tXrVq1jJi5fft2I75iUItsQQU5ER6Z8PtMwJ4ASW5AicSO1bhhwhhMwC+qkm0EOXLLFOvGiM8hdZPgimRXfrSgzoFTkgG4MmXKGKMZ13+AHq1xg4QlnkayIMRQCAQDsDXkYiTDcMwJgAMfBjX6Y5Js44TzBlkGFWQ\/FlTQ+lTsY88IuYKxJZLLFz8yv1pQ58ApyUAsWNbRaUmmzJVgtIYNBonEtn79+hnLOw3nvc6dO5sTgdsjrq7xW4CIICRvI5mPN7t7UEH2a1EFqV\/FPv2zEdQ5cEoywIz0QRZ1pA7SPERrgBHpdAeZcLWXjF9NrOkMKsjpX37+jyDodZb8RyD935BMLal0jNI5yXhfAvsKVnekGspGoJM+++yzzp2Q7HcqyaRjCel3KgLxEfCNZPBzQQ\/F\/kKdGW6G8B3AhkJqwaJ0haeLUBEoygj4RjLYZYgzQpKxzRIPvjGrV692jrtKMs4h1Q4VgUIj4CvJ7Nu3zxSgss3eJOFf8M477xR68JEdKMk4h1Q7VAQKjYBzkuG6job\/C7Vn2PgUosIQjCMTV9wUrlJ1qdBzpx0oAqFAwCnJEOxow9njvX3kFbYrpFSScYWk9qMIuEPAKckwrFgOeHbIEBFRrNYZz92rBNet2uU7al+KQNgQcE4yXgAoeEXUKU56NFy28XgkEI3qfK6bSjKuEdX+FIHCI+AbyaASkZ\/DNgiGwDJilvDujVUAqzCvVJRJRhNuF2bl6Gf9RMA3kiHVAlGppGMguhXHPKQYyIfIVlWX3E1rKlMiuBu19lRUEPCNZObNm2eKiJOQirB5IqeRNPg3fjKFCR+INTlFUZJJdcLtorIx9D3dIeAbyQwbNsykayC5T69evYyaRJ4YSEed8fI3gfFUoVQn3M7fyPVpRUDEN5LBH2bQoEEm4RCR2UOHDjU2GZIyt27d2hfsM0mSsQGHjz76qJw1btwRtYc+yc42OXh63Hhj0gm31W7jy7LTThMg4BvJRH4vV9tkDyOTmF8tk0iGd2ly+1i5+9XxMWsPQTS0R8aNiwlpowYNZP3nnxuyT0ehNL\/mWvsNDwK+koxGYRd8IUAydZu0ktwdX8TspGd2tjz9eo7cv3ZxTCI6bto0U7EzlYXSCv7W+slMRMA3ktEo7MItF0jmoiatZEcckmnRoIHk1Gwn3324+AiiIaP\/385pIW\/PHWdq\/aSyUFrh3lw\/nWkI+EYyGoVduKUCyTRsmy3frl0cVxXaVrOd+f3BHV8YsiHh9o\/lq5uE2yfUaSFLhl4hPTp1ksVvvx2zH8iqS58+RuLRpgi4RsBXktEo7IJPFyTToG12QlVo0MIdcb8EkklEVlnlq8uaN142VQ61KQKuEXBOMhqF7WaKIJnmw15KqArxTLwGySQiq7svuU3e+GdvJRk3U6e9RCDglGQ0Ctvd+rIkk0gVSoZkEpGVVatUknE3f9rT\/yHglGToNlEUNs\/Eq2tTmMnJtCvsZAkkkSRj+4llt+HzSDxKMoVZffrZWAg4JxnvF1EZksx4J5xwgmzevNlUl5w\/f35eYTfX0xI2konnHOeVZGLhBDG4ICIvyajDnutVqf35RjKUmSWkYOfOnbJx40aTSJw\/1LemjlJRDpDEm3fVqlUxPXkp7k5zQSDJEJElmXr16qnDnnKCcwR8I5m5c+eaSpJdunTJG3S1atVk5syZ5qo0WoAkpTwj6zFFe2NyBXtLhNpnwiLJUKZ3X6dOMR3orH9LKklmRMvyccfUNytLsrKynC9A7TDzEfCNZBYsWCA5OTnSt2\/fPBSpXrB06VIZN26czJ49O+\/nl19+uXmORUyemW7dusnWrVujok+wJRUQmjZtesTvw0IyNWvUkLfi+K2cdE4LWT13XEolmdPWz4k7pmOzsuQYJZnMZwQf3tA3khkzZow0atRIRowYYYiFCpEkseKKm2x5+NDQuJGiBjZlaDnhJ0yYIKQvaN++\/WGvS4G44cOHS4UKFeTAgQOhJpn6NWrEdY4rX766vPnGyyklmd+tnxN3TKeULCmHjj\/ehyWoXWY6Ar6RDLdMs2bNkrJly+ZhiCqEBPPYY4\/l\/YwEVqR\/aNmypSn8dsMNN0jXrl2FsARvq1SpkrRr106wG1D+NsySTMeOHeMGNVrnuFSqS1eW2RR3TEeVLCnHK8lkOh\/48n6+kQySyJ49ewxxQAzr16+XZcuWHWHwJbcM2fLIPUM777zzBMMoKhRG4siWnZ1tno9FMjw\/adIkITNfUBskE5m+wY6VmCPrHJdqkok3JgItyXSooQdBXVXBHZdvJMMmr1KliqmxFK\/1799fuOpu1qyZeax69eomuRW3U7t37843yYTB1yNWyIANarTOcakkmViewZFjCgO+wd1uRXNkvpGMTSTO9fXy5cuNncU2bpiwq9AoAjdq1CiTgIlGeoghQ4bkSTb5lWTCsAmsD0wi57hUkwzfl2hMYcC3aG7l4L61byRDRrdzzz036ptzO4T\/DM2Wrh0\/frwxAD\/xxBPm51Q0aNKkiZQqVUoWLlyY108idSkMmyCVjnb58ZNJhtTCgG9wt1vRHJlvJJMfOPv162dIhXbw4EHp3LmzbNiwQaZMmWJupXDesw2bAOVvw2z4DTvJqFdwfla3PuucZPDqxZhbv3592bJliyChrF69OiHSkMnpp59eqCoGYfGTCTPJqFdwwqWsD0Qg4JxknnzySZOJDYIpV66c8eDFzpKKpiRzJMou1SX1Ck7FKs6873BOMitXrpQZM2YYXxh8W+bMmWO8eSEAv1uQSCYowY8uSUa9gv1ewZnZv1OSoeY15U+4loZsaBRze\/zxxw3x+N2CQDJBC350STLqFez3Cs7M\/n0hGW\/xNsIFuDEqKiQTtOBHlySjXsGZSQJ+v5UvJPPuu+\/Ktm3bzNjx3MXbl2BJ24hrsn4yLl8wCJJM0IIfXZNMPK\/ggaVLG69gbYqAFwHnJPPmm28mRJgKktZPJuHD+XggCCQTtOBHlyRDX\/EqWpIHhxQeNvRAr7rzsXgz+FGnJJNunIJAMkELfnRNMsl6BWvFynTvhuB8v5KM47kIWvCjHyQTDzK+7\/zzz9eKlY7XVZi7U5JxPHtBC35MB8loxUrHiyrk3SnJOJ7AoAU\/poNk\/lC7tuz86aeYyGoCLMeLLuDdKck4nqCghQykg2TOrVdP9ufmxkRWE2A5XnQB705JxvEEKclEv4GyMJOf5rM+fWTq1KmOkdfugoqAkozjmVGS+f+1oL77cPERdbxtAqy3547TQnKO112Qu1OSKcDshCkuKR3qUqKKlVqtsgCLLsQfUZJJcvKISSL\/cCJnNLpLJvlTkJ5hzMmQkctnNPlVkgsvAx5TkklyElGDmtw+Vu5+dXxgirK52vRKMkkuAn2sQAgoySQJGyRTt0kryd3xRcxPpLooW5hJJhHs3vCERM\/q74ONgJJMkvMDyVzUpJXsiEMyqS7KFmaSSUZdVJUqycUZ8MeUZJKcIEimYdts+Xbt4pifSHVRNiWZJCdPH0srAkoyScIfK1zAfjwdRdkynWSSmRpVq5JBKb3PKMlE4B\/retr6v8Tz\/0h1UbYo57xcAAAJ1ElEQVRMJ5lEKpU1WKtalV4SSfTtSjIipixuMtfTifw\/0nFLk2gjJkNEYR93okWu0k4ihPz9vZKMiElynuh6+pPsbJm\/u0rC2UhmUwftmbCTTDJEq9JOwqXr2wNFimTiqUKJrqd7Ksmk3GEvEXnkhxyVZHzjkIQdh45kSpYsaWo5RWvxMuPFy9T2wQcfJLyebtGggeTUbJcQ0KBJKcmMJz+bNdHGT+b7XD2Tn3EnmjhVqRIhVPDfh4ZkKLfy1FNPSY0aNeTQoUOmbvbIkSMPe\/NoJIO95eeff5Z9nTrF9NRFFZr2ek7c6+lGDRrItjSTzJlnninr1q3Le+d0bNaCkExYxp1oG63ZtEtubX95osfS\/vuuXbvKxIkT0z4OO4DQkMyQIUOkWbNmcsstt8gZZ5whgwYNkltvvVXWrFmTB2Y0kknGUxdV6OnXc46IGrYdcz193LRpMmjhjoQT52rjR+unTZsrZd68+aEjmUwad8IFkOQDfkpOQch17YUhNCSzYMEC2bBhg5ARn\/bqq6\/K888\/bypV2mZvibwvuHV\/MenRqZN8\/HHsetxnn91Q\/vLgdFk95xFp\/tS4wyQeCGZJ52zpkZ0t7+wolnAJnV\/+UMLngvYMLxW0MSUznjCPu83pvyZcS34+MOzhSfLK7NRIO6EhGYrEQSoUT6PNnTtXdu3aZaSZRO1Abm7SmdpQrbDflBaR3BIl5JCIZGVlJfoK\/b0ioAjEQCA0JEO5W\/TMp59+2rwKf\/\/www9JkUw0o69XFdKiZLo\/FAH\/EAgNycybN88UDhs2bJhB46WXXpIlS5bII488khQ6WgcoKZj0IUXAOQKhIZlRo0ZJ\/fr15bLLLpNLL73UGH579uwp77zzTtKgqCqUNFT6oCLgDIHQkEy5cuVk5syZcuyxx5qXR30aOHCgMyC0I0VAEfAHgdCQjH39unXrypYtW4zRV5sioAgEH4HQkUzwIdURKgKKgBeBIkcy8cISdGm4Q+Coo46SH3\/88bAOixcvLsWKFZNffvnF3Rc57inauB1\/hfPujjnmGBNqE4lrUPAuMiSTTFiC89l30CHezYRTeFvfvn1l9erYzoUOvrZQXfTq1UuuvPJKadq0aV4\/gwcPlhYtWkiJEiXk888\/l5tvvjlmDFqhvrwQH4427qVLlwqb2LYXX3xRuIQIQjvxxBNlypQpUr58eYPl2rVr5Y477jCuHUHCu8iQTDJhCUFYOJFjuOqqq+T22283t2m2ffTRR7J\/\/\/7ADZcYpeHDh0uFChXkwIEDeSTTuHFjGT16tIwYMUI++eQTmTx5sok9e\/DBBwPxDrHGDbksX77cbFwrlW3atEm2b98eiHFDdo0aNZKHHnrI2CjBGNIB4yDhXWRIJpmwhECsnIhBcINWr1494w+EwXvz5s1BHKYZU6VKlaRdu3ZmvBUrVswjmfvvv9+4HzRv3tw8N2HCBClVqpTceOONgXiXWOMmkdmYMWMMyR999NHGTytIDYfUTz\/9NC9QGN+xr7\/+Wr799ttA4V1kSKYwYQnpXFjjx483m5aTFHsBi6h9+\/aBUzW8GGVnZwsSmFWXZs2aZSLnr7\/+evMYxInqRMBrkFrkuDt27Ghi5X799VdjS0J67NOnjyBJBq116NDB+I3deeed0r1790DhXWRIpjBhCelcUF26dDELfNKkSUZSeOaZZ8y\/+RPUFrlZZ8+eLXv27MkLAUEygIQuueSSQL1C5LhR8yDC++67z0gyc+bMkW3bthl7UlDaaaedZqStKlWqyHPPPWdUp6DhXWRIprBhCelaVLVr15avvvpK9u7da4ZAkOg333yTVMxWusYcuVmHDh1qpLGrr77aDAnbTOXKlaVTp07pGmLU740cd7Vq1UywrLXB8B5NmjQJDDnWqlVLkHQZH9Ih9iJa0PAuMiTjIiwhHTsCcuTmoG3btnnJzu+991555ZVX0jGcpL4zcrO2bNnSLPybbrpJcCEgPcfChQuPSDqWVOc+PhQ57rvuuksuvvhiad26tfE0x2DNDU5QPM1RQxkXOZZsgxRJNRokvIsMyYQ1LOHCCy804joqExsU4+91111n7ARBbahD11xzTZ5NBn+NqVOnmqyGNCQxSDPSjybd7xM57uOOO86kFCldurTwDlwNk3WOvEZBaNgZsdN52\/r16w2ZBwnvIkMydiLCGpaA2rRz587AXJ8WZJNhN8BP5osvYtcTL0i\/fn8GWxg5hT777DO\/v8pp\/0HBu8iRjNNZ1M4UAUUgIQJKMgkh0gcUAUWgMAgoyRQGvSL2WRzoGjRoINi3Pv74Y\/NHmyKQCAElmUQI6e8NAhgTucXAAG0bjoGdO3fOu153DVXv3r2N4xtJ47WFFwElmfDOXcpGjnfuPffcYzZ8\/\/795eDBg+b2CG9Y4mT8ck6DXFatWmWuY7WFFwElmfDOXcpGTkwMtyuRHrps\/nPOOUeuvfZawfMUXySCI7nqJXL8hRdeMBHM06ZNM4GTtkYWQXz4eCxbtsz8jSctMU+oY2+99ZbJ48wfvo9AyxkzZgTawzllExHSL1KSCenEpXLYK1euFAqGIcVEa6TRIKk7f+MkWLVqVcFVgMh3cjDjeIdj2+LFi83HCfGAXAiNwNeDuCZSKtSsWdO4x\/MsTmaoS\/jUEK0d5NQWqZyLMH6XkkwYZy2FY4Y4VqxYIeRRiSwLbIeBFELgIDabDz\/80PwYYoEg8KJNRDLE3Ni0DxAQ38X\/VV1K4UT7+FVKMj6Cmyldv\/baa8YJkOhvbyMVQqtWrYwxmNABvJNtIw0BSZWIT4okGSSj6dOn50kyqEY2TAIViu\/jZ0oymbGClGQyYx59fQuCMsm+RnCgN8WjjZ3B\/kJiJ\/LF7Nu3z4wF0sBQjC0GksFwzN+46C9atMgU57PqkleVUpLxdSrT0rmSTFpgD9eXNmzYUMaOHSsbN240ZLF7924TBU4NrAceeEBICIb0gdEWY\/DZZ59tnieQEPUHyWXdunUyYMAAkxaSAL5kSAY7D59D5dIWXgSUZMI7dykdOdfU5LYhUNC2l19+WYgIp0Eobdq0yftdTk6OeZ5ATm6dkIJoZG0j8BB1iVsmDL8YiK0vDAZgfoa6RN1znP+wCUFQ2sKJgJJMOOctLaMmCvyss84ykb9cR0dGUZ988slSp04dI31E5sEtU6aMuQbfunVrvsZOGk\/y13KVrS2cCCjJhHPedNSKQGgQUJIJzVTpQBWBcCKgJBPOedNRKwKhQUBJJjRTpQNVBMKJgJJMOOdNR60IhAYBJZnQTJUOVBEIJwJKMuGcNx21IhAaBJRkQjNVOlBFIJwIKMmEc9501IpAaBBQkgnNVOlAFYFwIqAkE85501ErAqFB4H8AgMvlS0FHhs8AAAAASUVORK5CYII=","height":169,"width":281}}
%---
%[output:9f6cc477]
%   data: {"dataType":"text","outputData":{"text":"Mean time in system: 0.138181\n","truncated":false}}
%---
%[output:6ebd9048]
%   data: {"dataType":"text","outputData":{"text":"Mean time waiting: 0.010506\n","truncated":false}}
%---
%[output:54121984]
%   data: {"dataType":"text","outputData":{"text":"Pct wait > 5 mins: 3.638135\n","truncated":false}}
%---
%[output:85b46fc8]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAARkAAACpCAYAAAAfrUnWAAAAAXNSR0IArs4c6QAAHW1JREFUeF7tXQe0FEWwLYyAKPAUFBAeQTGhoKiAoAQlR0FyEEQMRwmSFCUHAUmSc85REMlBFDNmPeQMkpMIgoryz63\/Z\/\/uY\/ftvmF33\/TMrXM4wO50T8+tnrtV1dVdaRISEi4LhQgQASIQIwTSkGRihCy7JQJEQBEgyXAiEAEiEFMESDIxhZedEwEiQJLhHCACRCCmCJBkYgovOycCRIAkwzlABIhATBEgycQUXnZOBIgASYZzgAgQgZgiQJKJKbzsnAgQAZIM5wARIAIxRYAkE1N42TkRIAIkGc4BIkAEYooASSam8LJzIkAESDIOmAM5c+aUG264IehITp8+LVmzZpWbb75ZfvzxR\/nnn39iMuLHHntM\/v77b\/npp5+uqv\/rr79ex\/vnn38Kxk4hAiQZB8yBTz75JCTJfPfdd5I3b17JnDmztGrVSjZt2hSTEX\/55Zfy33\/\/SfHixVPU\/7XXXitjxoyRo0ePSufOnaVatWrSqVMn2bNnjzRo0CBFfcX64kceeUReffVVwbNOmjQp1rdj\/\/+HAEnGAVNhxIgRkjFjRrnpppskW7ZscvnyZdm1a5eObOPGjXL77bdL7ty5pWfPnrJv376YjHjChAly4cIFadmyZYr6h+Xy6aefqhVUsmRJR5NMrVq1pH379rJt2zZp2rRpip6TF9tHgCRjH7uotyxSpIi8\/\/778tdff0mpUqV8\/YMAcuXKpZYM\/m7btq1s375dcuTIIbfddpvs3LlTPvjgA\/3+xhtv1F\/qt956S9vjZWrYsKGkT59efv\/9d+1\/9erVV4x95cqVet\/q1atLu3btpGzZsuqePfTQQ9p269at0qZNG7l48WJA24ULF0r27Nn1s4MHD8r06dPVkjl27JikSZNGbr31Vjlz5oy+3Fu2bBGQUu\/evaVo0aL6Pa5744035MCBA1eM6aWXXpIqVapoHydOnJB58+bJzJkzZcGCBXLLLbdIr169lIQrV64srVu3VvIASQZrBzdwyJAhkiFDBnU5gdGbb74ZEp9y5cqlCOeoTwYXdUiScZAyQ5HM8uXLfe5S\/vz55fXXX9dR42XBS2sJrAkrtoMXHYTTvXt3\/RrxEbhckBYtWsivv\/4a8OT+7tLgwYOlWLFi+r1\/n2PHjpUpU6YEtJs9e7ZaWbC+QHYgANwbAtLC+K655ho5fvy4Wjn9+vVTiweuGeI2eOlxjzJlysi\/\/\/7r6xuuzciRI\/U7WG933XWX3qNSpUraR6FChZQoQLhw1woWLCggvPXr1wdt99prr2k7WIwY18cffyxfffVVSHzQX6Q4b9iwwUGzyHlDIck4SCcpIZlTp05J1apVZejQofLoo4\/K3r17pX79+jJnzhxJTExUi+LJJ59UAkDMB+Tw9ttvy9133y1ffPGFWiv+Eoxk0GejRo3Ugnnuuedkx44d0qRJk4B2odwlizgKFCigJGBZZ1b8qU+fPkpKo0aNknTp0gn+\/9FHH\/n67tChg9SsWVOJaPHixUqocCdxDdzH\/v37y\/nz5+WZZ57R5wO5wgp7\/vnnQ7bDWPzdJYsgg+Hz\/fffK8lEgjOegRIaAZKMg2ZHSkjGeuFBHCAbvChwkeBaPfDAAzJr1iz91c+UKdMVTxgsKBuMZGCVDBo0SOrUqaMuDSyKevXqRUQy1rVwa1atWqUWCQgB8ZtgAnIEYVpyxx13yNy5cwMC4nDHmjdvLmfPnvURS7du3aRHjx4+Sym5dnAB\/UlmxYoVIfFZtmyZkkwkOA8fPtxBs8h5QyHJOEgn0SSZGTNmSOnSpTVuAxcC1gAsAbgLiH\/glzqcJWO9+HZIxiIyf5KBmwQrCrGY9957T2M4cOFgyWAVDf+3BFjkyZNHEhIS5MEHH9TYENyu+fPnC9y5gQMH6krYuXPn1OWaOnWqWkzJtQPx+ZMMSDQUPvfdd19EJAOc4dZRaMkYMQeiSTJwl5BbU6NGDbUi1q1bp8FkvNCwdiZOnBgVkoGbAisK8RIEZUFg\/kvYSUkGJHHnnXdqwPeXX37RWAxIB8Hp3bt3+8YEMsBqEAK+sDgqVKggWbJkUXcQFg+IZ9y4cb7ry5cvrxZOcu32798vHTt2VDcLAXBYfKHwQYA7EksGONNdSv71oiXjIPqJhGQQAMUqkmXG44VGQNVylxCcxa8+Jj9+2cePHy\/333+\/7ykR8H355Zc18BrKkrGsBLhccAUsS8aK+ySFzFphQp+IlWBM1viSkgwsB4zJCkJb5JTUGoB1gpgJVs8sAeEgTmMlJK5Zs0atGJBH3bp19bLk2oF0sQoHYvztt9\/0uULhg\/4ixZkkYxDJIIgYLqM1bdq0eo3\/SoSDeMKRQ8GLmi9fPn3xEciMhSAWAjly5EhE3cMVAtFs3rz5imVx\/w4QxMbYQXD+lg6usdwdLE1jeTuSdkgexFhhzWBpHRIPfCICxaUXOcKSQS4EliJhymOpFUus+KXxFwQwsUKClQWQzM8\/\/6ymL1YfKN5DwFpRwqrV008\/zR8dB0+BVCcZmNNYlsSkga8NE\/\/SpUtXrGLADEcCF1Y7Tp48KQMGDFDS8ffLHYwzh0YEPItAqpMMMiuxBInAHjJSkZfx4osvBmS8QjvTpk3TjNG+ffuqspYuXSqHDh3S+IIl8OuRxEUhAkQgeQSwuogExXhIqpMMEr2effZZzQKFWJmecKFgsQQTJJ0hKIcAo3+2JXI9yvZcmixua7pWTfYafG9lu8ZDAaHugWdxwjiigYFbnsUtzwGdxvNZUp1ksORYsWJF9ashCPIh9wD7UZIGKbF5EDkSCAZiRQOuk7+4iWRgzWGp2Q3ilmdxy3N4jmSQ+o54yxNPPKHvE7JCu3Tp4rNsrJcMyVGjR4\/W1QtsbAu2G9lNJOMGcuEzOBcBT1kyVjIXCAQBYCuQi70yTz31lO4Axg5h5EwgYxU7bC3B0QSI41hCknHupObInIWAp0gG0GOzHkgFgiXJZs2a6aFHWD3C0jWyMoMd7JR0wx5JxlkTmaNxLgKeIxmoAmSCE+CS7qlJiZpIMilBi9d6GQFPkkw0FE6SiQaK7MMLCJBkbGqZJGMTODbzHAIkGZsqJ8nYBI7NPIcAScamykkyNoFjM88hQJKxqXKSjE3g2MxzCJBkbKqcJGMTODbzHAIkGZsqJ8nYBI7NPIcAScamykkyNoFjM88hQJKxqXKSjE3g2MxzCJBkbKqcJGMTODbzHAIkGZsqJ8nYBI7NPIcAScamykkyNoFjM88hQJKxqXKSjE3g2MxzCJBkbKqcJGMTODbzHAIkGZsqJ8nYBI7NPIeAMSSD6oIojIWqfPgTrjAbNIl6xihLGq44G65DIa5I+rRmCEnGc+8KH9gmAsaQDMp8Nm3aVCsBokQpSqCiPOpnn30W9NE7d+4sKIFy3XXXyc6dO6V58+YhSQQlUnG8Jq6B5M+fXyZPnhzQLwrCff31177PSDI2ZxybeQ4BY0jG0gzqGzdo0EBKly6thIOqjmvXrtVC5NYZvCVKlNCCbH369NHSpJMmTdIzfVF32V9QZB3EYpUwtUgGZVNQJ+add97xXQ5SQ7lRWjKee0f4wFeJgHEkgxrWIAHUSkJBeAjcHHxuVSHo16+fFC5cWMqWLavfo1IkDglv0qRJAFyoXvD4449L+fLl5cCBAz5LBhUKChUqJMOGDZODBw\/qd0kFwEGmf7Jdpn2yLagaTKm7dJVziM2JQFAEUNbF+uGOV12vq6q7hPIlL7zwguTOnVvjLMeOHdPKAnCZYM2gAoFV4RHVBi5fvqwWDwSkAdfJqreUFBFUjARRWYCgL5DM33\/\/LahwgOqR9erVC3C36C7xzSICkSFgjCWDGEnOnDm1iiP+\/dtvvwU8IQq0LVu2TD+bM2eOnDlzRl555RX9P1wfWD8gqmCSlGRAZiCyiRMn6j3nzp2r\/8YfukuRTSxeRQT83xUjLBnEU3bv3q2xF3+BNQMS2bVrl+\/jrl27qiVSs2ZN\/QyxmVy5cknjxo0jIpkCBQrI\/v375ezZs3r9okWL1HKySAuf0ZLhS0QEIkPA8ZYMVpTg9qDY2qVLl7RWkiVYOUqXLp00atQogGQqVKggIBq0RawGxAQy6tu3r2CVatu2bfLTTz\/5+klqySxevFhdo9q1a2u97BEjRkivXr1kxYoVtGQim1e8iggEvCuOtmQQnEWQF4FcxF62bNniGzziLmDJJUuWBKgUeS9Tp071BYZhhYAwEGNB4bZ169ZJz549A0gG3yFQBSlevLi8++676jKBpBD8rVu3ri6dR9tdCjcXURsKlhqFCJiKgOMtGQtYxFNOnTqVooJsiYmJmifj70qlRFFwm06cOKE1sZNKtNylsj2XJjskrFDF61cgJdjwWiIQKQKOJhlYJKtXrxa4M3ny5NF61cEELtDJkycjfeaoXEeSiQqM7MQDCDieZLp3766rRlmyZNGclmCCvBi4UvEUkkw80ea9TEbA0STjZGBJMk7WDsfmJAQcTTJwl9asWaMB2OQEQV26S06aVhwLEfh\/BBxPMsjWDSdDhw6luxQOJH5PBFIJAUeTDDBJSEiQP\/74Q49iQK5MMDl9+nTA8nI8sKS7FA+UeQ83IOBokgGx4CgHpPXfe++9UrBgwaCYY8tAsGXmWCqIJBNLdNm3mxBwNMkAaCxbb9++Xa0YHPMQTPAQKTlwKhoKJMlEA0X24QUEHE8y\/kpAQl716tXVqjl8+LBullywYIFvj1E8FUaSiSfavJfJCBhDMqVKldK9R4i\/bN26VbJly6abHnFQVdWqVcMesRltJZFkoo0o+3MrAsaQDOIyadOmVUvGEot42rRpE3A0ZjyURZKJB8q8hxsQMIpkzp075ztYCuDjQClseGzVqpVs2rQprvogycQVbt7MYAQcTzJFihRReLEbG2fyYsDLly\/XQDDOh8ESN47ZDFeRINo6IslEG1H251YEHE0yt9xyi6xatSos9lzCDgsRLyACqYaAo0kGqIRKwLMQAxEdPXqUyXipNoV4YyKQPAKOJxn\/4d95551aWQBJehAcWoXT79566y3ZuHFjinSNw6giya1B3AcHWiUVukspgpsXexgBY0gGLlHHjh19qgLBYOMkjnh47rnndGk7EsEpeyjUhmM70aZFixZXHEpu9dO6dWtdzSpTpgxJJhJweQ0RCIKAMSQzYcIEPeWuU6dOerA3EvNgxYB8UO7E\/2jMUJqGa4Uib1iRwqZK1GPCucEod+IvSPbr3bu3ZM+eXS5evEiS4atDBK4CAWNIBod7\/\/DDD9KjRw\/59NNPtZYSBo9\/I08GZ+GGE5AR2uOgcSTx4QBynOuLfBt\/QRkUnLaHigfYyhDKkkGbqy3uxuM3w2mN35uKgHHF3XDwd8mSJQU1ruHGwE2aMWOGkkakyXi4DpYP+oGgEsHIkSP1oPJg59G0bNlSr6e7ZOo057idgIAxlgzyYVCb+sKFC7ozGyVPEJM5fvy4VKtWLSIs27dvLxUrVvRVksyXL58SFQrD4ZDypEKSiQhWXkQEkkXAGJJJ+hRY2kYtbP\/6SeF0jYS+\/v37+2pmI67TpUsXn2VDkgmHIL8nAilHwCiSudpd2NY2BNS6RgB43LhxihhWp3CkRPr06bUInCW0ZFI+odiCCCRFwBiSidYu7Hbt2impQFCNslmzZrJnzx6ZMmWKZMqUSWrUqOHDCEXVsJWBMRm+OETAPgLGkEw0d2GDTPLmzRvRilQoaJmMZ3\/SsaW3EDCKZLgL21uTk0\/rDgQcTzLchc0yte541bz7FI4mGe7CFmEtbO++nG55ckeTDEAOtwsb15w\/fz7u+mBMJu6Q84aGIuB4kvHHFYl0zZs3l4wZM8qBAwe0uuSSJUviXtgNY4onySQ3t7CdAqtgFCLgVASMIRlk5WJLwYkTJ2Tv3r16kDj+YDsAlp0j2SAZTSXEk2SS299EdyqaWmVfsUDAGJKZP3++VpJ84YUXfDjkyZNHZs2apb\/kkWyQjCaAJJloosm+3IyAMSSzbNky2bZtm54FYwmqF6xbt06GDx8uc+bMiaueSDJxhZs3MxgBY0hm8ODBUrRoUenTp48SCxLqcIgVlrhxWh5yaOIpJJl4os17mYyAMSSDVabZs2dLlixZfHjj+ExYMKNGjYq7DkgycYecNzQUAWNIBqfXnTlzRg+bwmFSO3bskPXr18c94GvpmSRj6IznsOOOgDEkg+M3ExMTtcaSE4Qk4wQtcAwmIGAMyVgHiWP5+uOPP9azeS3BChPO4o2nkGTiiTbvZTICxpDMiBEj5OGHHw6KNSoKIH8mnkKSiSfavJfJCBhDMk4DmSTjNI1wPE5FwPEkg6xeHABeuHBhOXjwoOBUu6+\/\/joiPK+55ho9BzhcnexIC73535QkE5EKeBER0C04xYoViwsSaRISEi6n9E7jx4+XAgUKKMFkzZpVqz7iGM5wgi0IKIGCWk07d+7UPU9JK0ai9MnYsWMlc+bMWiUSOTirV6+W\/Pnzy+TJkwNugSRAf3IjyYTTAL8nAv+LgONJ5vPPP5eZM2dqLgxIYd68eZr1i4GHkhIlSsiAAQOUNDZv3iyTJk3SM30HDhwY0GThwoVa6vaVV17RMisolYKzfhFkxlYFVEew5Ndffw3Y7U2S4StEBCJDwNEkg5rXKH+CUiYgGwiKucH6APGEkn79+ql7ZS13o1IkDglv0qSJr4nVNypJIqEPJVewdaFhw4ZSu3ZtzcUZNmyYWlDY8Z1ULJKLR3E3bpCMbDLzKmchYERxN4sI\/Iu3ocQsqgwkRzLIDIaF0qBBA0Ud1SbhOj399NM+LaAULVwiHCS+detW\/RxEBgKD\/wiSgQuFCgeHDh3SUrb+7hYtGWdNaI7GuQgYYcl8++23cvjwYUUR1R6R7YvNkpZgX5N\/ngwsE2QHww2CwPWBC+QfyylYsKDWwvYv7LZhwwZB0h+IBQHjiRMnqouGQ8zxb\/yxhCTj3EnNkTkLAceTzMaNG8MihgqS\/nkyqC4JS6RmzZraFrGZXLlySePGjX19YeUJrliHDh3UggGxgGRg2WC1af\/+\/XL27Fm9ftGiRXLs2DEfaeEzkkxYtfACIqAIOJpk7OqoQoUKWsa2adOmShgIGqNoW9++faVOnTpqBaHy5PLly5VMUMStW7duUrp0aSlevLgsXrxYXSPEZlAvG4mAvXr1khUrVtCSsasUtvMsAq4kGVgpU6dO1TK2EFghIAzEWBDTwVERPXv21JUkBInhGiGGM2jQIMGKE4jm3Xff1c9BUgj+1q1bN2AzJi0Zz74zfPAUIuBKkrEwwIZK5Mns2rUrJCxwkxCf+fHHH6\/Io0F+DtywI0eOXNGeJJPCmcbLPYuAq0kmllp1EsmEe04eNh4OIX4fSwRIMjbRdRLJJJdHg8fjYeM2lcxmUUGAJGMTRpKMTeDYzHMIkGRsqpwkYxM4NvMcAiQZmyonydgEjs08hwBJxqbKSTI2gWMzzyFAkrGpcpKMTeDYzHMIkGRsqpwkYxM4NvMcAiQZmyo3jWSSe0zm0dicBGwWEQIkmYhguvIi00iGZ9LYVDSbXTUCJBmbEJJkbALHZp5DgCRjU+UkGZvAsZnnECDJ2FS520iGMRubE4HNwiJAkgkLUfAL3EYyjNnYnAhsFhYBkkxYiEgy3GBpc5KwmSJAkklmIiRX9M1rlky494XL4OEQ8u73JJkgukeVBFQywMl6ODEPNZtwdKe\/eI1kTDlOAmU4cBi86eKW56AlE2ImdunSRcunvPTSS1pNEkXeUPkA5wJbQpIJBA8ulROCx\/H81YwlkbnlOUgyIWYJirzt2bNHXn\/9db1i7dq1WrEAB5JbMnLkSD1knEIEiEDyCMTTlbZVCzs1FIjDxkEqqC4JmT9\/vpw8eTKgJEpqjIv3JAJEIHkEjCEZlMKFXz9t2jR9Ivz9559\/kmQ4w4mAwxEwhmRQdwkmHsqmQJYuXSpr1qzR2tgUIkAEnIuAMSTTv39\/KVy4sFSsWFHKly+vgd9WrVrJpk2bnIsuR0YEiIAYQzJZs2aVWbNmyU033aRqg\/v05ptvUoVEgAg4HAFjSMbCEUXfUD0SQV8KESACzkfAOJJxPqQcIREgAv4IuIpkktty4GS1o044anz\/+++\/Th6m7bGh7DBqnpsmpo47HM5p06bV8s\/xmm+uIJlIthyEAz61vu\/cubOUK1dO64Pv3LlTmjdvfkX971dffVUaNWrkGyImSKlSpVJryCm6b+vWraV69epSpkyZFLVL7Yvhlo8ZM0aeffbZoHXXTdRJpkyZZMqUKXL77bfrHPv555+lY8eOmgoSS3EFyUSy5SCWINrtu0SJEjJgwADp06ePbN68WSZNmqR7sgYOHBjQ5ZAhQyRz5swyevRo\/RwTBMv5TpZ7771XevfuLdmzZ5eLFy8aRTLIwcqdO7fAMg5FMibqBCu0RYsWlUGDBmlME3MPpDNu3LiYTiVXkEwkWw5iiqLNzvv166fL8mXLltUe8MuZPn16adKkSUCPyG7+7rvv5JtvvtE\/586ds3nH+DXLmTOn1KlTRwoVKiQ5cuQwimTatWsnCQkJOuZQJGOiTkCeW7Zs8W0sRq7ZoUOH5OWXX47pxHAFyZi65WD27Nm6o7xBgwaqZCzJw3XCRlB\/QdJhhgwZNK6BX9eNGzcas3zfsmVLfVFNc5ewCXfq1KkhScZknWBu1a9fX\/PMOnXqJBs2bCDJhEPA1C0Hc+bMkTNnzvi2Rrz22ms6qZ955pmAR0aW8\/r163UywDp44403pF69erJv375w0KT6924lGVN1ki1bNhk8eLAkJibKwoUL1XWKtbjCkjF1y0HXrl3VnahZs6bqGbGZXLlySePGjX16x0rAPffcE3CkxRdffKG7z2fMmBHr+XHV\/buRZEzVyX333adxvSNHjqglHK8fKVeQjKlbDipUqCAgmqZNm6obBOJYuXKl+sxPPfWUxmc+++wzWbVqlXz44YeC58R5OrgebpUJsRk3kYzpOoF7jox5zCFLLly4IL\/\/\/vtV\/5gk14ErSMbULQfIj4Hfj9P+IMeOHZPatWtr7AVRfyw51qhRQ33nunXr6jVos3z5cunVq1dMJ0a0OocLWKtWLeNiMvny5VNL0T\/wa7pOELtE7o+\/7Nix44qFhmjp3urHFSRjPYypWw7gHyNPZteuXSH1C0vnwQcf1Fyas2fPRnsesD8bCFAnkYHmKpKJ7JF5FREgAvFEgCQTT7R5LyLgQQRIMh5Uut1HRiAamcf+8t9\/\/\/n+i0xkBBLPnz9v9xZs50IESDIuVGqsHgn7kJCfE0qwSoHqETznJ1YaMLNfkoyZekuVUWO164477tB7Y7ULS\/AtWrSQS5cu6WfY73P48OGAnJ5UGShv6igESDKOUoc5g8HSNHaGI3cEbhIEeTy\/\/PKLzJ07V5CTsXr1at2XhVUYLNVj0+STTz6pu36xqRX7aCCVK1eWZs2aaV4QNopiZzo2VVLcgQBJxh16jPtTBCMZJBKCZHD+MnIysC\/rq6++UnJBLAf5P9gCAmKCa1WtWjVNKuzRo4fs3btXM1GLFCmi1hByayjuQIAk4w49xv0pIiGZb7\/9VpDxW6VKFSUe1MzCfi1kOWMTaMmSJXX\/TLp06aRSpUr6DEh+wxkn2GoBsqGYjwBJxnwdpsoTREIy7733nnzwwQdqucCVwuFVyGrGUQr4Nz63slBh9ViCUwLbtm0rKAtLMR8Bkoz5OkyVJ4iEZLp166ZxGYtkYNHgsCR\/ksGRCadOnZL27dvrcyAug8xtnBHEpfBUUW3Ub0qSiTqk3ugwWiQzfPhwrV+Oc00Q9MVpbTjLBceLWgFlbyDq3qckybhXtzF9skhIBitIa9eu9VkyiLucPn06wJLBsvj06dPltttu0\/EiuQ\/Hj8LNorgDAZKMO\/Ro\/FNgBQpEg7OLY32wtfFgGfYAJBnDFMbhEgHTECDJmKYxjpcIGIYAScYwhXG4RMA0BEgypmmM4yUChiFAkjFMYRwuETANAZKMaRrjeImAYQiQZAxTGIdLBExDgCRjmsY4XiJgGAIkGcMUxuESAdMQIMmYpjGOlwgYhgBJxjCFcbhEwDQE\/geRpnHTOQYzRgAAAABJRU5ErkJggg==","height":169,"width":281}}
%---
