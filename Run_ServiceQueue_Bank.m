%[text] # Run samples of the ServiceQueueBank simulation Aiden Camilleri
%[text] Collect statistics and plot histograms along the way.
%%
%[text] ## Set up
%[text] We'll measure time in hours
%[text] Arrival rate: 40 per hour
lambda = 40;
%[text] Departure (service) rate: 1 per 2 minutes, so 30 per hour
mu = 30;
%[text] Number of serving stations
s = 2;
%[text] Run 100 samples of the queue.
NumSamples = 100;
%[text] Each sample is run up to a maximum time.
MaxTime = 8;
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
%[text] ## Numbers from theory for M/M/k queue (k=2)
%[text] Rewrote above section with info from Example 8.8 from textbook.
k = 2;
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

P0 = (1 - (lambda/muN(2)))/(1 + (lambda/ muN(2)));
P = zeros([1, maxN]);
P(1) = P0;
for n = 1:maxN %[output:group:40768ce0]
    P(1+n) = P0 * 2 * (lambda/muN(2))^n;
    fprintf("P%d: %f\n", n-1, P(1+n)); %[output:54d0d06b]
end %[output:group:40768ce0]
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
fprintf("Mean number in system: %f\n", meanNumInSystem); %[output:66891288]
fprintf("Mean number waiting: %f\n", meanNumWaiting); %[output:955e9560]
%[text] 
%[text] Make a figure with one set of axes.
fig = figure(); %[output:3220b3ee]
t = tiledlayout(fig,1,1); %[output:3220b3ee]
ax = nexttile(t); %[output:3220b3ee]
%[text] MATLAB-ism: Once you've created a picture, you can use `hold` to cause further plotting functions to work with the same picture rather than create a new one.
hold(ax, "on"); %[output:3220b3ee]
%[text] Start with a histogram.  The result is an empirical PDF, that is, the area of the bar at horizontal index n is proportional to the fraction of samples for which there were n customers in the system.  The data for this histogram is counts of customers, which must all be whole numbers.  The option `BinMethod="integers"` means to use bins $(-0.5, 0.5), (0.5, 1.5), \\dots$ so that the height of the first bar is proportional to the count of 0s in the data, the height of the second bar is proportional to the count of 1s, etc. MATLAB can choose bins automatically, but since we know the data consists of whole numbers, it makes sense to specify this option so we get consistent results.
h = histogram(ax, NumInSystem, Normalization="probability", BinMethod="integers"); %[output:3220b3ee]
%[text] Plot $(0, P\_0), (1, P\_1), \\dots$.  If all goes well, these dots should land close to the tops of the bars of the histogram.
plot(ax, 0:nMax, P, 'o', MarkerEdgeColor='k', MarkerFaceColor='r'); %[output:3220b3ee]
%[text] Add titles and labels and such.
title(ax, "Number of customers in the system"); %[output:3220b3ee]
xlabel(ax, "Count"); %[output:3220b3ee]
ylabel(ax, "Probability"); %[output:3220b3ee]
legend(ax, "simulation", "theory"); %[output:3220b3ee]
%[text] Set ranges on the axes. MATLAB's plotting functions do this automatically, but when you need to compare two sets of data, it's a good idea to use the same ranges on the two pictures.  To start, you can let MATLAB choose the ranges automatically, and just know that it might choose very different ranges for different sets of data.  Once you're certain the picture content is correct, choose an x range and a y range that gives good results for all sets of data.  The final choice of ranges is a matter of some trial and error.  You generally have to do these commands *after* calling `plot` and `histogram`.
%[text] This sets the vertical axis to go from $0$ to $0.3$.
ylim(ax, [0, 0.3]); %[output:3220b3ee]
%[text] This sets the horizontal axis to go from $-1$ to $21$.  The histogram will use bins $(-0.5, 0.5), (0.5, 1.5), \\dots$ so this leaves some visual breathing room on the left.
xlim(ax, [-1, 21]); %[output:3220b3ee]
%[text] MATLAB-ism: You have to wait a couple of seconds for those settings to take effect or `exportgraphics` will screw up the margins.
pause(2);
%[text] Save the picture as a PDF file.
exportgraphics(fig, "Number in system histogram.pdf"); %[output:3220b3ee]
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
fprintf("Mean time in system: %f\n", meanTimeInSystem); %[output:571d4cb3]

meanTimeInWaiting = mean(TimeInWaiting);
fprintf("Mean time waiting: %f\n", meanTimeInWaiting); %[output:353480f9]
%[text] Make a figure with one set of axes.
fig = figure(); %[output:0d48faa4]
t = tiledlayout(fig,1,1); %[output:0d48faa4]
ax = nexttile(t); %[output:0d48faa4]
%[text] This time, the data is a list of real numbers, not integers.  The option `BinWidth=...` means to use bins of a particular width, and choose the left-most and right-most edges automatically.  Instead, you could specify the left-most and right-most edges explicitly.  For instance, using `BinEdges=0:0.5:60` means to use bins $(0, 0.5), (0.5, 1.0), \\dots$
h = histogram(ax, TimeInSystem, Normalization="probability", BinWidth=5/60); %[output:0d48faa4]
%[text] Add titles and labels and such.
title(ax, "Time in the system"); %[output:0d48faa4]
xlabel(ax, "Time"); %[output:0d48faa4]
ylabel(ax, "Probability"); %[output:0d48faa4]
%[text] Set ranges on the axes.
ylim(ax, [0, 0.2]); %[output:0d48faa4]
xlim(ax, [0, 2.0]); %[output:0d48faa4]
%[text] Wait for MATLAB to catch up.
pause(2);
%[text] Save the picture as a PDF file.
exportgraphics(fig, "Time in system histogram.pdf"); %[output:0d48faa4]
%[text] `P0: 0.266667`
%[text] `P1: 0.177778`
%[text] `P2: 0.118519`
%[text] `P3: 0.079012`
%[text] `P4: 0.052675`
%[text] `P5: 0.035117`
%[text] $L = \\frac{\\lambda / \\mu}{(1-\\lambda/\\mu\_2)(1+\\lambda/\\mu\_2)} = \\frac{\\frac{40}{30}}{(1-\\frac{40}{30\*2})(1+\\frac{40}{30\*2})} = 2.4$
%[text] $L\_q = \\frac{2 \* (\\lambda/\\mu\_2)^3}{1-(\\lambda/\\mu\_2)^2} = \\frac{2 \* (\\frac{40}{2\*30})^3}{1-(\\frac{40}{2\*30})^2} = 1.0667$
%[text] $W = \\frac{1}{(\\mu - \\lambda/2)(1+ \\lambda / \\mu\_2)} = \\frac{1}{(30 - \\frac{40}{2})(1+\\frac{40}{30\*2})} = 0.06$
%[text] $W\_q = \\frac{L\_q}{\\lambda} = W - \\frac{1}{\\mu\_2} \\approx 0.026667$
%[text] 
%[text] $L$ is 0.468% higher than the theoretical value.
%[text] $L\_q$ is 0.211% higher than the theoretical value.
%[text] $W$ is 0.895% higher than the theoretical value.
%[text] $W\_q$ is 2.2% higher than the theoretical value.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":18.3}
%---
%[output:54d0d06b]
%   data: {"dataType":"text","outputData":{"text":"P0: 0.266667\nP1: 0.177778\nP2: 0.118519\nP3: 0.079012\nP4: 0.052675\nP5: 0.035117\nP6: 0.023411\nP7: 0.015607\nP8: 0.010405\nP9: 0.006937\n","truncated":false}}
%---
%[output:94f11e96]
%   data: {"dataType":"text","outputData":{"text":"Working on sample 1\nWorking on sample 2\nWorking on sample 3\nWorking on sample 4\nWorking on sample 5\nWorking on sample 6\nWorking on sample 7\nWorking on sample 8\nWorking on sample 9\nWorking on sample 10\nWorking on sample 11\nWorking on sample 12\nWorking on sample 13\nWorking on sample 14\nWorking on sample 15\nWorking on sample 16\nWorking on sample 17\nWorking on sample 18\nWorking on sample 19\nWorking on sample 20\nWorking on sample 21\nWorking on sample 22\nWorking on sample 23\nWorking on sample 24\nWorking on sample 25\nWorking on sample 26\nWorking on sample 27\nWorking on sample 28\nWorking on sample 29\nWorking on sample 30\nWorking on sample 31\nWorking on sample 32\nWorking on sample 33\nWorking on sample 34\nWorking on sample 35\nWorking on sample 36\nWorking on sample 37\nWorking on sample 38\nWorking on sample 39\nWorking on sample 40\nWorking on sample 41\nWorking on sample 42\nWorking on sample 43\nWorking on sample 44\nWorking on sample 45\nWorking on sample 46\nWorking on sample 47\nWorking on sample 48\nWorking on sample 49\nWorking on sample 50\nWorking on sample 51\nWorking on sample 52\nWorking on sample 53\nWorking on sample 54\nWorking on sample 55\nWorking on sample 56\nWorking on sample 57\nWorking on sample 58\nWorking on sample 59\nWorking on sample 60\nWorking on sample 61\nWorking on sample 62\nWorking on sample 63\nWorking on sample 64\nWorking on sample 65\nWorking on sample 66\nWorking on sample 67\nWorking on sample 68\nWorking on sample 69\nWorking on sample 70\nWorking on sample 71\nWorking on sample 72\nWorking on sample 73\nWorking on sample 74\nWorking on sample 75\nWorking on sample 76\nWorking on sample 77\nWorking on sample 78\nWorking on sample 79\nWorking on sample 80\nWorking on sample 81\nWorking on sample 82\nWorking on sample 83\nWorking on sample 84\nWorking on sample 85\nWorking on sample 86\nWorking on sample 87\nWorking on sample 88\nWorking on sample 89\nWorking on sample 90\nWorking on sample 91\nWorking on sample 92\nWorking on sample 93\nWorking on sample 94\nWorking on sample 95\nWorking on sample 96\nWorking on sample 97\nWorking on sample 98\nWorking on sample 99\nWorking on sample 100\n","truncated":false}}
%---
%[output:66891288]
%   data: {"dataType":"text","outputData":{"text":"Mean number in system: 2.411223\n","truncated":false}}
%---
%[output:955e9560]
%   data: {"dataType":"text","outputData":{"text":"Mean number waiting: 1.089162\n","truncated":false}}
%---
%[output:3220b3ee]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAANsAAACECAYAAAAZW15iAAAAAXNSR0IArs4c6QAAIABJREFUeF7tnQmcVMXxx2uRayOgHLLeAip4QmIETVAwqKBRFA8iJoBBxSO4UVHijQRFQQEJiy7xgrCiBDRA8EgWVDTEiIgJbKIoEDWGKMgtuHLo\/v221vzfvH3XnDuz2\/35+MGdedOvu7p+XdXVdRS8++67VSIi5557rqxbt05OO+00ueuuu\/hIfvSjH0mnTp1kwoQJ5m9aVVWVFBQUxP52\/g\/f\/fjHP5bvfve7cu+998a++uqrr6RevXrmb\/6\/V69esv\/++8vvfve72Ge7d++Whg0bmr9vuukm2bZtmzz44INx7\/nHP\/4hV199ddxnxx13XNxzO3fujPWzfPlyM\/b77rtPWrVqZX63adMm+eMf\/yiTJ0\/27YcxMked5y9\/+Utp3Lix6SeIVqeeeqrcfvvthkYffvihmSNz4u\/u3bvLU089JQcccIDpo7KyUl566SV5\/vnnA8d\/5ZVXyq233iq9e\/f2pLn7Q+bHGlx66aUyePBg8zU0adCggZnPrl275IwzzpAjjjjCk77PPvts4Bz4vbO1bdtWnnzySfPR5ZdfLqzj1KlTY4841wO6du3atdo8nn766Wp0mTVrVlw\/O3bskEaNGpnfMoZTTjlFDjvssEAeevXVV+Pe1aJFC2F+0GHNmjWy5557yt57722eue222wyNRowYYf7+1a9+JX\/5y1\/kN7\/5jXTp0kW2b99usHH\/\/ffLSSedJIzn448\/lkMOOcT09+mnn8of\/vAHGThwoBQWFpo+1q9fL4MGDZLRo0fL0UcfLQWJgO2RRx6RmTNnyuzZs6VJkyZmEX\/2s5\/J97\/\/fbn55pvNC6677jrzMgUbjM3\/n3feeWYCtMcff1yOPfZY6dy5sxl0z5495csvv5Q\/\/\/nPhgArVqyQkpKSGDMwqTFjxpjPt2zZEkfAadOmyeGHH27GctFFF5kNY+LEiWZMNBiPRf7Tn\/5k\/h4yZIi89dZb1RYcBunQoYPph98Akrlz55oFeOGFF+Tll18OBRubw1FHHWX6gMBsDrpxsYj\/\/e9\/5ZVXXjF9T5kyRR5++GGJMn42GMAGaFk8mG369OlmDvQ5YMAAueeee+QHP\/iBmSsMXV5eLk2bNpX3339ffvrTn8qBBx4oMLDSf+nSpZ70HT9+fOgcooJN1764uNiMgXbhhRcaRnc3N11YCwUtoGEDvvbaa6Vfv36xdf31r38dyEPQytkuu+wysyHQ4OU5c+aYflu2bCkAHpqxzqyPvnP+\/PmG1+GBkSNHxtYPnoSv4df+\/fvL559\/LmzKrBWAgwfYYPktfdASAhuA+eSTT6SsrMzsKh988IFcfPHFsu+++xoA0hg8UkzBxi6qAGECMC\/\/8nt2fhqAozFJdonPPvvMgFcl2y233CILFy6stkB8oMR499135ec\/\/7l5hp2HHYh2xx13yJIlS0LBhoRp3ry5vP3228KiuNvJJ58cCrZzzjlHrr\/++rif\/uc\/\/5GxY8eaMdDcTBVl\/OysgE0X0NnP73\/\/eyO9lZEA5A9\/+EN57bXXDC0Bn0ojlQxvvvmmAbsXfX\/yk5+EziEq2GDsf\/3rX+LUPmDM1atXJwQ2mBj6nXDCCTEt6\/zzz5dJkyYF8hCbuLOh3cybNy\/us82bNxtaIERobPLHH3+8kWRsYkgrGiBHW9HvtRPoy+bN5som4gabc8wxsCmQnBLIrUaqqqm78cqVKw2KnWAbNmyY1K9fPwY2\/Q2D++tf\/2qAiPqEZNtnn30MIyCNnO1\/\/\/uf2dWUGXRsXmhbsGCB2V2cIHFO8M4775TFixeHgk2Z3ktV5b1OsPnR6osvvjCqG98DXGdTOrjBFmX8LD5gQ\/Xs0aOH6ZbNB\/CgwsEAfmBjx0W1dDbo\/\/rrr\/vSN2wOUcGmUoyjiKrtyYBN+0ETQmuh9e3bVx566KFAHgKk7ob6ec011xiQOo9DDzzwgAGck3eQZmeeeaahH9oODUmFIGBDU3WRz1XNdIOtW7duRiujxcCGJELsq47Kl8mADVVxjz32iIENVQzUs8sg9mm\/\/e1vzaQ427EzcNaBUTlntGvXzqiLgEfB5gSsm3icg9q0aWOkI88hRceNG2eIQYNJAXSYGomKhaoF0Rgrc4Ch2RxQMVgI3f38aMWCsYGwSPTXp0+f2BmTv1HRFGxoBzBLlPFfccUVCYNNNw82rgsuuMDMh7MfAGV8ANeLvqWlpaFzyCTYlC5ONdIPbJyzgnjoiSeeiGOXoUOHGr5AI0Nbgr\/pA41KtTR+wGbkBBLrD09xvnv00UdNn6jtCAlUWzQpGmorfSKA4EeAzW+gtwHbihUrqhThMBpSQlsyYLvxxhuNqug0kDgPyTA+zOw0vGAM4RkOsDQW\/J\/\/\/GcksDklDioUTPSd73zH9PPee+\/JJZdcInvttVco2JzqE+NhAdRgw67G7qaqme5kblpxFsVgwDhQH5kT50naVVddJcuWLZMXX3zRjI9xshGhgqjhxW\/8aiBJRLKhYaBq0Ti8M1alC+cnJK8X2JCUYXPIBNjcdGFz1DObH9gwNqnxzouH0MCczXnmw3jBkcgYLgoKRNVxnkc4cN7SxobN8zTdLFnbf\/\/739K6dWvDt6wdWgd8pEY8eAAbAXQ++OCDpWDYsGFVqCAKOM4+7Co0wIa6p6I7ihrpBhsHyf3228\/0B9CGDx8eO38hyXi3Wip1Mohpp54fJNn4DX0458Bn7FRMGp3cCTZl+rhV+PYPxD1iXxtSl00DC5bXe9y04qCNZqAWR+0HRsJKSePfs846y\/y\/quFh42cX5jzoBTaVBG41kv6RpBhNnPNB5ZwxY4YvfRl72Bz8wMbODtMpSFTdjqJGuukyatSoav04eQI1EuNQEA+51xg+g5e\/973vxfEcZy2MaxjpaFhqOcfR1q5dazQUbVgkb7jhhpgVk8\/hEwQEkhQe4JynGzVqMzYIAFfQokWLKlSMI4880uzeqHSgFTWEndivMXGeBeHPPPOMmbhf42AK4DgsMzBnQwrSF+oNuzw7VDKNyR1zzDFGBcLSpjtRon0h9jkjQSDG4zZ1K62YL0D2aswXdWXjxo1GHeZfZ2vWrJlZFOitfaRr\/O7xsNHAXFu3bpWKiopq8wlas6A5JErXKM970SXK7xLlIZ5HCrExsGFi+HA2rnlQJRFAHHmcVxn6HIBs3769Mf\/D15yNtQFqNi3+hU8UxAZsPISRgzMJxg0ABPOjnz722GPV5gtaEY80mJHBAzisbrZZCuQzBTjXcWxA7UYwcO5yb7jJzi8GNtQR9ErEMwc\/0AxyEZtO1PIi9GkGgLWHXQE9H8mF2umWXMkOzP7OUqAmKICA4RxHw+nC7fyQyphiYOPgh\/oFsmlYsDh\/cXjXOzQ+RzRyGYh+qtY5gIkhIJ27QCqTsr+1FMhFChiw6S23ejUwUD0k6j2O1+AxSZ944onmvKc37rk4STsmS4FcoIABG4YF3FewmOjdBIdEXFf0fshrsFjvuC\/jfIdFB2+SMP2Wd2AQ0caZUO8ucoEgdgyWApmigAGbeoDoBTQvU1863J3wctCGGqlGFP1MTdN33323PPfcc4Fj\/dvf\/hZnjs7UxGy\/lgK5RoHYmY0LW0zDeJnT9JIXD33Mxto4PCKJ1IuCz\/X+I0jl1N9bsOUaC9jxZIsCMbCpFQZfQi5bUSsJl8CRmMZlKH6DqH1IOr7jM+4Z8HDgXkEdT4MGb8GWraW178k1CsTAxoUingXqQItvFwYQXJ5oSL533nnHeGpwNiNsQr1OuBzExw\/whTULtjAK1a7v3Wf0XJwdzgt6b4xzAZZ5QsVwYPdr2Dm46oLnCTP7xS9+4Rmr5\/x9DGz6IVZIfOi8Yr6cP8SCiRsODU+TqJ4fFmy5yG6ZG5Oudyqgc4LBa6Tc8RK\/qG51ic7GyZNRwYYgAmT4UEZ9fzWwJTrQRJ+3YEuUYvn9vK43\/54+Mj6WLOrM5g\/vHTOq4e+JjQBDHccaJNDpp59uJBP+o\/je4khN4Cxuh8TOEb+HswYN5w2OQhjz0OZwzGBs6giNX65TsgEq7BdEAXBkwocT6zs+lgATBxCiN\/T9eFMRIUA0Aq59HMl4h4n+V3etqBNP9blkwIYDLokYCnfvFkw1TByLqG25T4F0gg0HbuwDGOfwbiIagEh4vO5VjcMhGEYHiICDeDQYHXdCrqmwvCONsFGgnREUyhjxbwREHJMUbBgM8RHmCowUCQAbcAEeIu8J6iVsDH9cfT9gx86Bb+Xf\/\/53E4KDfyxB1TkPNoA2vrJSrnLwFdlDhhYWxsUc5T7b1c0RphNsMDn2AqISAA9nJiQXjhVOsJEFAGlHI2AZpidgVGMq+R1R3mFgw4mYiBMkF7lGADYqI3071UjnmQ0JiTQjuoTG1RnPE6aT02DD4jlm69Y4oCnLWsDlB3gVbJNnPCudDmlZbdAwPW3F4sVGa7mmuNhIDGdb9uEGuarf2SasBScLQKKJpwh3QW10gg1Jg9SjEQCM4Q8fR42ahvmJg3OCDe9\/1D6nZCOmEpWwY8eOsWRJGA6DwIYhEfdF8svQ2BzYJJB2OQ02wlx2urI5ORdhz8JCafxtJqP8YL26N8qgY0OiWgsSiQhpAEb4D\/67pHfgTOYEGxZ1TQwE2AgMRb10g43wI85yjJGQLMKdnGAjNIngY67DUCWRUsQHBoGNpEFYMXmWRpIgQrYAXU6DreCzz2R9ANh6fp0IZ+mqVXWPg\/Noxn5gS0Zr4dyk3ksYJLgLJlYQ0HANhTWSyBXAhsc+oCRUhk1bU27gWI\/DPZZ0JBnR1CaKuqDA3B2TwuDss8+ORWFjBCHyhUBYzl+k7yCOU4NWcb7HgKJgJ8qbXCk49KNOkmqEzYBzZiDYOFASZIdBYtGiRSbVFw0rjobc67oThqNRAEG8kIiBBF14YsDd3YldushKC7achp7feiejtWhKPGfuUmIvUfcwimChxKhBYC4JfWB28tMAIowkSBnAQAMAGrHN7zQlCH3zH2cvJJjm3OQz+gDsABJpSRoMfIEBvYKNHDo49GukNrjA2YNNoaBt27ZV7lyMDAbLC6Hi6KiYMxmQ5s5zJnLVlXamWUsn2I4qKfE9szUpKzO7jW25SwE\/sIVpLa0aNJCqpk3jJoaXEsl3MP9zxiKKmjMfOTQx8+PbC98ihVAzkToARDNmsXkDDDVgINlwpifPJhZKrJDqH6zR2lwVoBZyxkMl5X1IN1wYwQWCZ8OGDXHj5HPSiYAdHEE0xrOgtLS0igxD7saLCQwlUxAoxe+RgyeSDv9JRCeTSbQlItl4tkvfYhm9vLyaNfLmjj3ljVkl1qk50QXI8vN+6\/1FZaVsr6z0HU3Dr++ruCtzNgUb+UFJ1kMQsybd1Xyk8DLfa6Il5+9JgoQa6WXAULCh\/jFmGjyvyau4lKdfQJ5sK1i8eHEVdxHOdtBBBxmV0Bk4yj0BiU9IiYDIZDIkeEFck3ouLLRG+08UbFyE7li7WrZUlEszUmkXHSrkcdjr2J7ivOxMlgD2d5mlgN96exlHdCRYmm9q1qzaXaoX2DSBkxNsCAL4EwMKDWGB9CLjNoHPbgMG6qKCzemmhZEFSyJnRVROd9LXRClXsHz58qowCcWlIeDT1Nya61Bfhj7LJSE6bFhLBmx+fVqwhVG75r9PxU0rW6PHCsl9mtsnEgDzGcYTPUKlMqaCioqKKmeOPHdnmCzZPTgYcsBkd+BCEaMJt+dYgtgNsABhoUFHDWoqovWZoODRMBcfC7ZUlj43fovxAimH1lJZv77RWpwJUt2j1OSzpCnEnO+WbJqqHiMFfr40zkyaws\/PgEHws5cDsmb\/1tR5qVCtYNGiRVX4lLkbohdphTjmQEmmY\/Rkr6Y381wecrsfBjZnLsOwZ4P86SzYUln6\/P0tLld+vOicFV4fHIlw3XI6yvsZMLwoAga4TNdL8lSoVjB9+vQqTKruhvRiUirN9HusLyTQxGqjEdxayMIv9Z2zb6tGprJc9rfZogC8j+aG94g7W0GyYygYPHhwFcDiIg8DCBeBAIozGs6Z7jQH6K58h\/qIsYT0CXhCo0Zy9xa241iwJbtU9nf5ToHYpTbeylgluaPAj0vTI7gniAMmQAP1mjsenRj1Md2X2vbMlu\/sZcfvpEBK7loaaMoNPpbKKM1KtihUss\/URgqkBLZkCGLBlgzV7G9qAwUs2GrDKto55AUFLNjyYpnsIGsDBSzYasMq2jnkBQUs2PJimewgawMFLNhqwyraOeQFBeLARk4GLqajVB7Fx4x7Odxh8Pon7kcrLAbNPMgL3J1Ba8mSJYHpz6y7Vl7wmB3ktxRIqvIoReMJusPbn9AaUoCRNswdve1FZS+w+eWieLu4WOZuPMR3sSzYLB\/nEwWSqjxKiE1RUZFx7yJiVb1PBg8ebELUE5FsJFRp\/8ADvtHYBIkSu+bVLNjyidXsWBOuPArJ3FVKtYoNqiQ59hIB2+GHHSavv\/GG70+ad+wpzSzYLKfWAgqkVHmU+ZPHgZg0MtSSsXbTpk2hYHM+cM2AAVIeALaiokOl8WlXW8lWC5itrk8hpcqjSDRypuPxT8ou0nWFNfeZLSyDVmHRodLagi2MrPb7PKBAwpVHdU4kT8EgQkg5ec+Dyus46eAFtqAMWiNOu1oaFR1qJVseMJMdYjAFEq48SndqECEObuzYsQnR2A22oAxa1hqZEGntwzlOgaQqj2IgIfmk5jPXOZL48qOPPgo9sznTImjMmlcGLVLVRUmLYKvc5DiX2eEZCiRceZS8fLNnz\/YkXxRJ5yXZ\/ACFaT8MbGTCtVVuLDfnAwWSrjya7OTSCbZRZxTJtgEDbJWbZBfD\/i6rFKhx38ig1Adhkm2\/lTMD7+hO6to1NLVeVqltX1anKZDXYOuwcmbgHZ2tclOneTvnJp\/XYDu3xYe2yk3OsZQdkB8F8h5stsqNZe58oUBeg40zna1yky+sZscZCjZi28injiuWVqpJZzHEVAwkakCxVW4sI+cDBXyLIergKfxNSVQSt2rRxHQWQ0wH2PwIbUNw8oEF684YfYsh3njjjULBDYoQ0Jxgoz5buoohWrDVHWar6zP1LIYIUahMg0SjCFzbtm3jwDZu3Li0FUO0YKvrLFh35h9aDBEpNmDAgDiwpbMYogVb3WG2uj7T0GKIXmBLZzFEFiAV38gw38moteDqOiPY+WeeAr7FEPXVXmBzDyuVYohWsmV+ke0bcoMCvsUQ\/cCW7mKIFmy5wQh2FJmngGcxRDXx83ovyUYKhHQVQ7Rgy\/wi2zfkBgU8iyE6q4cq2Hr16mXS1tEo65uuYogWbLnBCHYUmadAqAdJ0BDSUQzRgi3zi2zfkBsUSAlsyUwhncGjYfFu1oMkmRWyv8kUBeoE2GyOkkyxj+03EQrUerDZHCWJsIN9NpMUqNVgszlKMsk6tu9EKVCrwRaWo2TPwkJpXFiYKM3s85YCSVGgVoPN5ihJiifsjzJEgaSLIep4CMV57rnnImexyqY10uYoyRDX2G6TokBSxRD1Tf3795chQ4bIpEmTZPr06ZEGkG2w2RwlkZbFPpQFCiRVDLFHjx5y5513SsOGDc0QcxVsNkdJFjjIviIyBZIqhtihQwcTxd2yZUvp3r17ToONEByboyQyP9gHM0iBlIohUsQe9TGXJZuNd8sg99iuE6JASsUQkwWbe4SZDB61YEuIH+zDGaRA0sUQGVOyYPMqGeU1xyi+j2FgCvveRnJnkLts13EUSKoYovZgwWa5yVIgOgWSKoZYm8CG72SBiBTu3i1E6xUWFkr9+vWjU9A+aSkQkQIJF0O87LLLYl2T4u7JJ5+UiRMnChm3orRs3rOFqaFcervv4SaLyNDCQgM62ywF0kmBvC6GGAamoO+5DhixoNQWUkwnN9m+AilQq30jg8C2bkGpVH4NOL9mnZQtctJNgToLti8WlMraALDZQorpZjXbX50F29aKctm0vNyXA07s0kVWrlplOcRSIG0UqLNg21JRLqOXl\/ue2ZqUlcm1116bNkLbjiwF6izYWHo\/a+TNHXvKG7NKxF54W4CkkwJ1GmwYULoNmSBIuWYisrPoUKkSkb2O7Sk2M1c62cz2BQUCwXbggQeaOmzbtm0zAaJr1qwxVMu1yqN+S5nK1YCCzWbmskBJFwV8K49S\/JCYtZ07d8Y8KsiOvGzZMsmnyqNhvpFBTtA2M1e62Mz2YyRbaWlp1W233RZHjT322ENefPFF2bhxo1x44YUmSPT555+X7du3S+\/evU3+\/3ypPJos2GxmLguQdFPAs\/LokUceKY8\/\/riMHj1a5s6da96JS1bnzp3l1FNPlbvuuitvKo8mCzabmSvdrGb786w8itS6\/vrrjfT66KOPDJUwg\/fr108uueQSU1SjTZs2MepVVVXJo48+agAa1vCNdLeajGfze3dYZq5WDRpIVdOmYdO131sKxCjgWXn0hhtuMOrjmWeeKZs3bzYPKwAvvfRSufvuu42jLqCjdNR1110nzZs3F7575513AsmbS47IQQaUqJm5rAHFoikqBTwrjwKawYMHm8xZb731lumLv\/mcclFffvllXP+5XHk0WTXS6w5OJ01kAJfeV1xxhYyvrIy7GLdRA1FZr+4951l59IQTTpAJEyZIaWmpTJs2zVClpKREOMudf\/75MmrUKHOWW7BggfkOAN5\/\/\/1GlXzsscdqhWQLy8w1adgA2TZggI0aqHuYSXrGvpVHX3rpJeEshuXxoIMOMirjm2++ac5u+VR5NFnJpiqmX2Yua0BJmufq7A99K4926tTJSLMGDRoY4nz66adywQUXyK5du\/Kq8miqYPPjjKgGFHumq7PYqjbxQA8S7tuOP\/54Wbdunbz\/\/vvVfpwPlUczBbYoBpTlFRX2TGex9v\/WyBYtWuAOmLWWL9bIMFevMAPK28XF1VIuOA0sNvVC1lguZ15U5x2RU7nj69K3uFqYDtZIogaOaLxZXn\/jDd+FJhKcXc4mG8oZLGR8IBZsI+d5EjlMsoUZUMLOdHuKyDgRe22QcRbPnRdYsKUINr+lDDrTLRSRFS6geamY1riSO0BJx0gs2DIINr9yVUd8Cza\/BVQVM+zC3IIxHRDIXh8WbBkCW9Cl+E0isiVgjff6OlnsmBDJx8\/DwJg9NrJvikKBpMHWpEkT403SunVrmT9\/volzi9LCrJFcJ6xYgZIlJlo6WdN9qr93v9s5rkT69roUH9i9g0wsKfElVz0R+SqAmA0bNJCJu3blvPfK5ZdfbryKcrHVxNiSAtu+++4rM2fONEGlBJc2atQokqsWRA8DW58+58qcOd+E9eQS2JzjSnVsYdcGYZKvkYjsCODgXMl56V7rXAJdTYwtKbCVlZXJwQcfLH379jUX3lOnTpX27dubCO7PP\/88kKYWbN9sIkHXBmGSb28R+SYWw7vlSs7LmmDoqICuibElBbZXXnlFli5dKkOHDjVzw42LQvb33XefzJ4924ItRCqHXRuESb6pXboE3uGR83JaWVlUvkvoOaJAiAaJ0mqCoaOMy0vDivq7VJ5LGGyc1TijTZkyRR5++GHzbs4z\/E2RDfwpg9qDDz4oxx13XOyRNdsLZMlarnart85FVb7f8XQmv6\/pvieVlMjpU0qq3cPNH1QsBzSRQO+ULaVlUtDmxIzQtE+7oNNkKqyYe79NdyrDhMF2zDHHyCOPPCKA5oknnjAUaty4sbz88ssya9YsGT9+fO5RLU9HtHv3bsG8T5q9yvr1jceJVtfhc2uNzK+FTRhsGEdQFYlnI0cJjZR3AO2OO+6IxbjlFxnyc7RBYMzPGdXuUScMNsjx2muvSUVFhVx55ZWGOpoyoVevXrJ1KyUFbbMUsBRwUyApsHF3cvTRR5u8kitXrjRqJbssuSZtsxSwFPCmQFJgIyPyjBkzTJIf2o4dO0w+jvfee8\/S2VLAUsCHAkmBTfvS4FFNCmSpbClgKeBPgZTAZglrKWApEJ0CFmzRaWWftBRIiQIWbCmRz\/7YUiA6BSzYotPKPmkpkBIFLNhSIp\/9saVAdArkDNj8Ci9Gn0pmnuzQoUO1cr+rVq2SRYsWZeaFEXrF6ZvilO66CvicctfJ+CjxRRHLbDevsXXr1k3atWsXNxQcI7JxVcR7qVlBomHiJIlYcabPzybNcgJsQYUXs80s7veRar1Hjx5xH3\/wwQdy8cUX18jQ+vfvb7zuJ02aJNOnT4+NAde57t27m\/hC6ult2bJFLrroIvNvtprf2ObNmyetWrWKG8bTTz8t48aR8ihz7eSTT5YxY8aYzN4kFybu8uOPPzZBz7Rs06zGwRZWeDFzSxGtZ611MHDgwGg\/yNBTAB6PHYBEc4KN7NWTJ0+WF154QUaOHGm8e\/DyIYW8u9BlJoYXNDbet3DhQhNs\/NBDD2Xi9b59PvXUU1JUVCR9+vQxboTDhw83Uo4iMfBdtmlW42ALK7wYFoya6dVDHaPGASFE9erVk9WrV2f6lZ79o86ec8450rJlSyPBnGAjrpBAXqdvanl5uVGXYK5Mt6CxsTkQ\/wjo165dKxs2bJBPPvkk00My\/bvjLlEZiVZBlSRSJds0q3GwhRVezIZeH7Tyr776aqzeAc8R2nLLLbfI4sWLs8Iw7pdwBkF9dIKNGMKOHTsaEGojtnD\/\/feXU045JWvj9BqbhmShyhUUfBO3COgoP0YZ6Ww1JBkVlsgocNZZZxkNINs0q3GwhRVeDCuumMnFoqgIZbFwtuZ8QSktmATGcTJ2JscQBWyoS\/vss49JS6HNC4CZHqcX2DiP33rrrcK5jf\/OO+88I6HZRKlim42GRKOAJ768VGC69957pSZoVuNgS7TwYjYWJ+gdeqgeNGhQLAtYNsfkxdCcz1DHu3btGhsKai8qJ4ydreY1Nq93Azqc2bOxYQ0bNswYRKigO2LEiJhGUhM0q3GwBRVedO7U2WIY53sYGxa2e+65x1ixaBgp2K3ZobN19nCOyYuhb78NdtesAAAARUlEQVT9dqMa9e7dW9avX28eRyKjFRQXF2eNdF5jg36okki3r776JqXCnDlzDNjcVt50D1QNIs8884yMHTs2rvuaoNn\/AaYZ0oGJCTBqAAAAAElFTkSuQmCC","height":132,"width":219}}
%---
%[output:571d4cb3]
%   data: {"dataType":"text","outputData":{"text":"Mean time in system: 0.060537\n","truncated":false}}
%---
%[output:353480f9]
%   data: {"dataType":"text","outputData":{"text":"Mean time waiting: 0.027253\n","truncated":false}}
%---
%[output:0d48faa4]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAANsAAACECAYAAAAZW15iAAAAAXNSR0IArs4c6QAAFeNJREFUeF7tXQuUTfX3397PIq+kyFghmZUo6aGIjMiIzBTKuzEeeYswRl7RqPFqGpHXjKEakxUZizHDCKWMmCEay5JQooRIk8f9rc\/+\/793nbnunXvuzDnn3uvuvZY17j3f+z3f7+fsz3fv7+PsXaxKlSo2ug1k8uTJ1LFjR+7Jk08+ae\/RkCFDqFevXnTt2jV69tlnqUWLFjRv3jz7dZvNRsWKFXOKAK6hzho1atDKlSu5zM2bN+n69etUunRp\/jx+\/HjasWPHLb\/fvn07lSlThtauXUsffPABZWZm2n\/z33\/\/2f+PH44cOZL27NmTr47333+fHn\/8cSpVqhS3\/eeff6bevXvnqwff47qSQYMG0dWrVz1ua2pqKt111130999\/879atWpxlenp6TRr1ixKS0tjjDZt2kTTpk2jrl270rhx47hMp06d6IknnqCoqCgCXidOnODfAx98Hjx4MNeB+iF\/\/fUXffTRR4xpREQEfwc80A\/cA3164YUXGJPQ0FBdmok61bPX9QMvFSoWyGRbsmQJff7557Ru3TqqWLEiP\/TXXnuNHn30UXr77bf5keCh47vmzZtTXl4ehYSE0I0bN2jz5s1UoUIFOnLkCPXr10832U6fPk1hYWH04IMP0vLly\/l3+Lt48eJb6lixYgU1bNiQfvrpJ+rbty9fV6T9448\/qFu3blSvXj17PXFxcUxQT9p6zz330BdffMF1f\/PNN7Rw4UJq164d15OTk0Pz58+nNWvWUN26dZkoUOr4+Hh65JFH6LfffqOXX36Zli5dSg899BDjN3v2bNq\/fz9Nnz6d63znnXeoRIkS9Omnn\/LnV155hU6ePElbtmyhO+64g44fP049e\/ak++67j5KTk7nMsmXLqHr16kw2EBb4goRJSUl8\/dSpUzyAvvvuuzywYgB8+umnvUQh\/bcNaLJhhD5z5gwlJibSAw88wNajR48eVLNmTSYgBJZrxIgR9tEehINg5MZIDEsAAjqKK8umLB3K79q1i4oXL06rVq0iEMVRCiLb+vXr2WJAdu\/ezW355JNPmAzKMult69atW3ngUALSwNqBaP\/++y8TZNSoUXz5xRdfZGtdrlw5+yChva7q+OWXXwjW+fvvv6f777\/\/FrKpNoMoIBIEngBk7969TGSQDW1p1aoVf68Gms8++4y9kwEDBtAbb7zBhHzqqaf0a72XSgY02V566SU6e\/YsJSQkUP369eno0aPsqmnJ9tZbb7HLhJEWSoHyWvn1119p+PDhusmmtWJFIZuzemARoKCetjUoKIjdQGCgdUuh9MOGDePvMHhgYIAr2aFDB1ZwDDKXL1\/mvsMlxOCl3EUFCDAGMR0tmyLbP\/\/8wxZTKxkZGVS5cmXuC9ziNm3a8GU1gK1evZotsJDNS6NGYeZsesgGosHNgduEUbht27Y82vfv359dOLiRsEx6LVthyKYGAe3o7opszZo186itzz\/\/PGGuh4GkT58+1KhRIwKW9957bz6rAqvZuHFjezeVF4Av4FaC4CAiXMEuXbrwXA2CzykpKXayAUu4jpgHwnXHYAV3GK7mxIkT2bqhHlgzIZuXyOTutmaRbezYsbwgohZVMJLDtalSpQo3CYoGy2gG2T7++GN6+OGHmeQ\/\/PADvfnmm3ZXyhXZsrOzPWprcHAwYe4KuXLlCh07doznk3CTtYSCFZs6daq9m3AxlbWCpYF1hLWD+wh8YCUhIDLmqRs2bODP58+fp7lz51LTpk15vgc5d+4cu7Hly5fnzyAk3Hkhmzut99J1jIpq9crZaqTy\/bF4sGDBAm6lHssGssHdgyWD2wJXSgnmEGohxRXZ1PxCuUCwEFhQgLhzI9u3b0\/R0dF8T8y\/WrdubXelnNUDNxLE8bStcINhXdQKK9oG9w7WKTc319411QeQ\/7nnnmNSQWAFQT781QpWM+GeQkBMzN0gao4aGxubb+UY9cI9RNkJEyZQ586dnbqRmGNjRdOv3UiYdYw2WJaFmT9w4IBL6sCFgu9eu3ZtdqUAAFbpbmfB3AVuGlydffv22ecrZvYZ98RKHeYuWMzRK4VpKwapqlWrspt3+PBhtqhawaIM3MVDhw7xwoSjVKtWjRcqYL1+\/PFH\/qsV6BUs2O+\/\/85khlSqVImt3KVLl3j1Uy2W6O2nP5WzL5BgUQDL4CVLluQRCwqlHT21nXrmmWfovffeY7cB4KCsWgb2p85LW\/UhgHkdVmRBJoizfUF9NQV2KTvZYJnq1KlD4eHhvOKGZecGDRoQgFajkIIK+y533303T4QxIsHVgZXDitTBgwcDG9HbsPfY44uMjOSewWLBfRPxHAE72TD\/yMrKotGjR3Mt8OExX4mJibHvOanqHcvCtcI+kfKlPW+G\/EIQuP0RYLJhroY5mnaFS51wUHsarqDAki0m\/LCC2PB03DO5\/SGUHgoC+hBgsqnlX1gntWdUtmxZ2rZtG++TYNXImcCizZgxgzcytScaCro1jgSJCAK+jgAWwIYOHWpoM5ls6sTEl19+yWfbIOqsGvavcJzHUXCyAiuXFy5c4PNvjgdpXbUSZGs37f\/2XBwlLTo031KwoT31sDK0U7uF4OHPLS3uL231l3bi4ZnRVvucDcdnsPSqJsLqvBv2erAIohW1IIKTATj\/5okI2TxBS19ZMxRD3509K+Uv7TSdbOo4zpQpU\/iMIDZHcXICrztAsNmI09yYn2GBBCuUjifVcZYOJ7oLEiGbZwqqp7S\/KLG\/tNN0st155528c68OkuLEwsCBA+0nCGD5sNE5adKkW1YnlULosXT+QjZs2mIA8gfxl7b6SztNJ5tSKqxC4owaJohmiDuyubqnGRNWM\/ondd4eCJhhhS1\/xcYd2fxh8eT2UCfphbvpjtELZEI20TlBwAkCYtk0sUVEQwQBMxEQsgnZzNQvqVuDgJBNyCaEsAgBIZuQzSJVk9sI2YRswgKLEBCyCdksUjW5jZBNyCYssAgBIZuQzSJVk9sI2YRswgKLEBCyCdksUjW5jZBNyCYssAgBIZuQzSJVk9t4hWwIrIkQ0siYogJo4t03FTpaPRa8TIq4k+5ETv27Q0iu+wICppAtKCjIdvHiRZf9W7RoETVp0oTf2FblEEtS5d9SP9Sm9ikILCGbL6iStMEdAqaQLT4+3oa3rx0FMSMRa12lENKSDdk8EaMEsec9FSGbp4hJeW8gYArZ9uzZY0M0Y0dB1hJYNMRhR4YSLdmQthZZSpAREon3EOtfb4x2IZs3VEfu6SkCppAtOzvbVpCFUjmptWRTaV9VBxDzH\/E6kEXFnQjZ3CEk130BAVPIlpOTY1NpVJ110hnZENgH2SSRrwtZSJBoAYGCkKoIQYHczdm01xMzcykh8yf+CnEjJSyCL6haYLUBgYic5S8wPCzCzp07bZibuRJnZHPmcoJ4iM6FPF3uyFYQoYRsgaXovtpbUyxbUlKSDXmT9ZINy\/4zZ84kRE9WkZJbtmxJc+bMcZliSlu3uJG+ql7SLkc9NdyyRURE2OAWdurUiVNAjRkzxr7Ej5s7s2yI6w\/38fXXX+cw5cguCTcSe2\/uEvYJ2USp\/QEBUywbYv2j8yqkeNeuXfMRRpFNG4Yclgxuo8qBjAyVcB9lU9sf1EjaqAcBU8mmpwGOZVRAVyRAVPmV3dUjls0dQnLdFxDwObIVBhQhW2FQk99YjYCQTQ4iW61zAXs\/IZuQLWCV3+qOC9mEbFbrXMDeT8gmZAtY5be640I2IZvVOhew9xOyCdkCVvmt7riQTchmtc4F7P2EbEK2gFV+qzsuZBOyWa1zAXs\/IZuQLWCV3+qOC9mEbFbrXMDeT8gmZAtY5be640I2IZvVOhew9zOdbBUrVuQXQBGYNS0tjQ4cOOAWbIS827hxo9vYI6oiOfXvFlIp4AMImEq2mjVr8sufJUuW5HfTypQp4zbMAd7UHjp0KH344YeUlJSkCyIhmy6YpJCXETCVbImJiVSnTh0KDw+ns2fP0ooVK6hBgwaE6McILa6VNm3a0JQpU6h06dL8tZDNy5ohtzccAVPJlpmZSVlZWTR69GhueLdu3QguYkxMDK1bty5fZxo2bMjRkqtWrUoIgydkM\/xZS4VeRsA0smGuhjna8uXLafHixdxNhDzA59WrV9PChQuddr1evXrsPgrZvKwZcnvDETCNbMHBwbRkyRKKi4ujVatWccPLli1L27Zto+TkZIqNjTWUbNrKJEir4XoiFXqIgGVBWhFdC4sjcBURC3L27NncVISoA9EmT55sjw\/p2AexbB4+VSnuNwiYZtmAwO7duyknJ4ciIyMZEGSpGTVqFGlD2AnZ\/EZXpKFFRMBUsiExRuPGjXmV8ejRo+xWXr9+nbPXQDBv279\/Py1dutTeDbFsRXyi8nOfRcBUsiGsOGL1I7IxJC8vjwYOHEi5ubn8GZYPSTO0CQiQSgoLKAsWLCBkttEjss+mByUp420ETCWb6pwKvLpv3z5T+itkMwVWqdRgBCwhm8FtvqU6IZvZCEv9RiAgZJODyEbokdShAwEhm5BNh5pIESMQELIJ2YzQI6lDBwJCNiGbDjWRIkYgIGQTshmhR1KHDgSEbEI2HWoiRYxAQMgmZDNCj6QOHQgI2YRsOtREihiBgJBNyGaEHkkdOhAQsgnZdKiJFDECASGbkM0IPZI6dCAgZBOy6VATKWIEAkI2IZsReiR16EBAyCZk06EmUsQIBCwnG+KQIDzC5cuXOerx6dOnuR940RSRk7WC2JII8upO5BUbdwjJdV9AwBSyBQUF2S5evHhL\/xAOASESEB0ZUZIhQ4YM4ZDkCNw6ffr0fL9BOcSQdCdCNncIyXVfQMAUssXHx9smTZqUr38lSpSg9PR0On\/+PIWFhXHk49TUVLpy5QqFhoYy6WDxWrdu7TEuQjaPIZMfeAEBU8i2Z88eW4cOHfJ1p1GjRrRs2TIOa4fwdhDEGWnevDm1bduWrVr9+vWpX79+VKtWLTpy5Ahdu3ZNFyRCNl0wSSEvI2AK2bKzs22OFkqFscPfkydPcrdHjBhB3bt3pz59+tDUqVOpbt26djhsNhsn4QBB3Qk6oRUJ0uoOMbluNgKWBWnNycmxOc61xowZw+4jLN6FCxe4r4qA\/fv3pxkzZlC5cuWYdJUqVaKRI0dyVC5cQwSugkQsm9mqI\/UbgYAplm3nzp02JMnQCkgTERHB6aBUlC18xvctW7akGzdu5CsfEhLCxEMovPnz5wvZjHjaUodXETCFbElJSbZhw4bl61iLFi1o3rx5FB8fTwkJCXwNQVoxl8OS\/8yZM3kut3XrVr4GAs6ZM8dtPjeULYplc4U+BgQMDCKCgFEImEK2iIgIW0pKCnXq1Im6dOlCcCGxFZCRkUGYi2HlsXbt2my59u7dy3O39evXs\/uIZIjYi4uKimI3EkQ8c+aMaZat3bQNTutOiw6lJ2XD2yg9k3r+3ygYrVPFkFgD6EZHR\/McrWvXrkyYJk2asDUrVaoUg3\/u3DnO2YZVR1gykK98+fJ87ebNm+w+mr2pLWQTHliFgCmWTZHNWSew3\/bYY49xJtLjx4\/fUkRFTz548CBvfuuRoriRQjY9CEsZIxCwnGxGNNqxDiGbGahKnUYjIGSTOZvROiX1uUBAyCZkE3JYhICQTchmkarJbYRsQjZhgUUICNmEbBapmtxGyCZkExZYhICQTchmkarJbYRsQjZhgUUICNmEbBapmtxGyCZkExZYhICQTchmkarJbYRsQjZhgUUICNmEbBapmtzGp8hWsWJFflm0Ro0alJaWxvEk9YhZp\/5d3buwb3EjCAyCGPmD+Etb\/aWdeOY+Q7aaNWvyi6II3or32MqUKaMrJILqREHvpZlxrTBv3JoBtlnE9Ze2+ks7fYpsiYmJVKdOHQoPD+cXS1esWEENGjTgSMkIQ16QmGXZCiJpYaxeoCuGGQNDoGNqD4vgCbiZmZmUlZVFo0eP5p8hXMLYsWMpJiaG1q1b53NkK8wb3oGuGJ7og96ygY6px2TDXA1ztOXLl9PixYsZZ4RHwOfVq1dz3JKCJC4ujpo1a6b3+Ug5QcArCBR2rl9QYz0mW3BwMC1ZsoRAmlWrVnHdZcuWpW3btlFycjLFxsZ6BRy5qSDg6wh4TDYsjsBVRNxI5AKAIJwdiDZ58mR7LElf77i0TxCwGgGPyYYG7t69m3JycigyMpLbq0KTt2\/fni5dumR1H+R+goBfIFAosmH\/qXHjxpy\/7ejRo+xWXr9+nZDTTUQQEAScI1AosiHzKOL6IwoyJC8vjwYOHEi5ubmCsyAgCLhAoFBkU3WpIK0q+YagLAgIAq4RKBLZBFhBQBDQj4CQTT9WUlIQKBICQrYiwSc\/FgT0IyBk04+VlBQEioSAkK1I8MmPBQH9CFhGNpwyweb35cuXaePGjXT69Gn9rTSpJFJitWvXjtNifffdd3z6BbnmnAnarvLRqetr167l\/nhT8D7hoEGDaNasWZw7z1cEeF25coWftSvxRUyRdbdNmzacM37nzp20ZcsWwyC1hGzY7MYGON59wztwEGQ01fvCqWG9dahow4YNVK1aNbp69SqDm52dbT8Voy1avHhx2rVr1y3NwN4iTtJ4UxYtWsSJK4ExMsb6ggQFBVFSUhI\/38GDBzttki9iOnLkSHr11Vd53xhJQNHGTZs20bRp0wyB1XSywXqkp6fT+fPnKSwsjEqXLk2pqak86oWGhhrSicJUMnz4cOrRowdNmDCBtm\/fzkrRu3dvp+c769Wrx8rTs2dPp0khC3P\/ov4GrzR17tzZnhnWF8hWoUIFPjOLv5D9+\/e7JJsvYopXx06cOMF6AD3FWyzVq1dnS3fjxo2iPjIynWxIer9s2TI+tIwHAVmwYAE1b96c2rZt6\/Zl0yL30EUFa9asocqVK3NqYwgUBG7kt99+S6NGjcr3K+QbnzhxIr8cW79+fTp27JjX3ceQkBC2aE2bNiVYEl8gG6wBrAME+dnhKbiybL6GKfLGI\/qA9p3M8ePHcz+QOx7PvKhiOtnUIWX8PXnyJLd3xIgR1L17d+rTp4\/XjniBWKdOnaK+ffvaMdSObFpgx4wZw1ZZK5jjoR\/eFrjjvXr18gmyabGAt3D48GGXZPNlTNGPKlWqMPkw9enYsaMhj9l0silQYUEuXLjAjVYE7N+\/Pz8Qb8iOHTvo0KFD+ZQBk+E\/\/\/yT3UutwGdv1aoVW2TkFocL2rBhQ1q5ciVhzuRN8Vey+TKmeP5YdML6Atq5efNmQx6x6WQDoSIiImjo0KGkzlDiM75v2bKlIb5wYZDIyMhgYiGOihJYtq+\/\/pqioqIKrBIuJ95Wh2sBq+JN8VeyOWLmC5hinoY3WjBVwNss48aNozNnzhj2eE0nG5ZS582bR\/Hx8ZSQkMANR+gEzOUwB\/KWYNkeby1g3gipWrUqffXVVzR37lx2H7QSHR1N586d4z5A8FCUmzRgwABvdYHv669k80VMU1JSCC9HG2nNtMrxPytycLqWwaIvAAAAAElFTkSuQmCC","height":132,"width":219}}
%---
