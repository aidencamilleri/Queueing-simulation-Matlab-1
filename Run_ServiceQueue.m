%[text] # Run samples of the ServiceQueue simulation Aiden Camilleri
%[text] Collect statistics and plot histograms along the way.
%%
%[text] ## Set up
%[text] We'll measure time in hours
%[text] Arrival rate: 10 per hour
lambda = 10;
%[text] Departure (service) rate: 1 per 5 minutes, so 12 per hour
mu = 12;
%[text] Number of serving stations
s = 1;
%[text] Run 100 samples of the queue.
NumSamples = 100;
%[text] Each sample is run up to a maximum time.
MaxTime = 96;
%[text] Make a log entry every so often
LogInterval = 1/60;
%%
%[text] ## Numbers from theory for M/M/1 queue
%[text] Compute `P(1+n)` = $P\_n$ = probability of finding the system in state $n$ in the long term. Note that this calculation assumes $s=1$.
rho = lambda / mu;
P0 = 1 - rho;
nMax = 10;
P = zeros([1, nMax+1]);
P(1) = P0;
for n = 1:nMax
    P(1+n) = P0 * rho^n;
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
fprintf("Mean time in system: %f\n", meanTimeInSystem); %[output:3951852a]

meanTimeInWaiting = mean(TimeInWaiting);
fprintf("Mean time waiting: %f\n", meanTimeInWaiting); %[output:67342ace]
%[text] Make a figure with one set of axes.
fig = figure(); %[output:2c550a5b]
t = tiledlayout(fig,1,1); %[output:2c550a5b]
ax = nexttile(t); %[output:2c550a5b]
%[text] This time, the data is a list of real numbers, not integers.  The option `BinWidth=...` means to use bins of a particular width, and choose the left-most and right-most edges automatically.  Instead, you could specify the left-most and right-most edges explicitly.  For instance, using `BinEdges=0:0.5:60` means to use bins $(0, 0.5), (0.5, 1.0), \\dots$
h = histogram(ax, TimeInSystem, Normalization="probability", BinWidth=5/60); %[output:2c550a5b]
%[text] Add titles and labels and such.
title(ax, "Time in the system"); %[output:2c550a5b]
xlabel(ax, "Time"); %[output:2c550a5b]
ylabel(ax, "Probability"); %[output:2c550a5b]
%[text] Set ranges on the axes.
ylim(ax, [0, 0.2]); %[output:2c550a5b]
xlim(ax, [0, 2.0]); %[output:2c550a5b]
%[text] Wait for MATLAB to catch up.
pause(2);
%[text] Save the picture as a PDF file.
exportgraphics(fig, "Time in system histogram.pdf"); %[output:2c550a5b]
%[text] $L = \\frac{\\lambda}{\\mu - \\lambda} = \\frac{10}{12 - 10}  = 5$
%[text] $L\_q = \\frac{\\lambda}{\\mu - \\lambda} - \\frac{\\lambda}{\\mu} = \\frac{10}{12 - 10} - \\frac{10}{12} = \\frac{25}{6} \\approx 4.167$
%[text] $W = \\frac{1}{\\mu - \\lambda} = \\frac{1}{12-10} = \\frac{1}{2}$
%[text] $W\_q = \\frac{\\lambda}{\\mu \* (\\mu - \\lambda)} = \\frac{10}{12 \* (12 - 10)} = \\frac{5}{12} \\approx 0.4167$
%[text] 
%[text] $L$ is 3.83% lower than the theoretical value.
%[text] $L\_q$ is 4.5% lower than the theoretical value.
%[text] $W$ is 3.95% lower than the theoretical value.
%[text] $W\_q$ is 4.71% lower than the theoretical value.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":20.5}
%---
%[output:94f11e96]
%   data: {"dataType":"text","outputData":{"text":"Working on sample 1\nWorking on sample 2\nWorking on sample 3\nWorking on sample 4\nWorking on sample 5\nWorking on sample 6\nWorking on sample 7\nWorking on sample 8\nWorking on sample 9\nWorking on sample 10\nWorking on sample 11\nWorking on sample 12\nWorking on sample 13\nWorking on sample 14\nWorking on sample 15\nWorking on sample 16\nWorking on sample 17\nWorking on sample 18\nWorking on sample 19\nWorking on sample 20\nWorking on sample 21\nWorking on sample 22\nWorking on sample 23\nWorking on sample 24\nWorking on sample 25\nWorking on sample 26\nWorking on sample 27\nWorking on sample 28\nWorking on sample 29\nWorking on sample 30\nWorking on sample 31\nWorking on sample 32\nWorking on sample 33\nWorking on sample 34\nWorking on sample 35\nWorking on sample 36\nWorking on sample 37\nWorking on sample 38\nWorking on sample 39\nWorking on sample 40\nWorking on sample 41\nWorking on sample 42\nWorking on sample 43\nWorking on sample 44\nWorking on sample 45\nWorking on sample 46\nWorking on sample 47\nWorking on sample 48\nWorking on sample 49\nWorking on sample 50\nWorking on sample 51\nWorking on sample 52\nWorking on sample 53\nWorking on sample 54\nWorking on sample 55\nWorking on sample 56\nWorking on sample 57\nWorking on sample 58\nWorking on sample 59\nWorking on sample 60\nWorking on sample 61\nWorking on sample 62\nWorking on sample 63\nWorking on sample 64\nWorking on sample 65\nWorking on sample 66\nWorking on sample 67\nWorking on sample 68\nWorking on sample 69\nWorking on sample 70\nWorking on sample 71\nWorking on sample 72\nWorking on sample 73\nWorking on sample 74\nWorking on sample 75\nWorking on sample 76\nWorking on sample 77\nWorking on sample 78\nWorking on sample 79\nWorking on sample 80\nWorking on sample 81\nWorking on sample 82\nWorking on sample 83\nWorking on sample 84\nWorking on sample 85\nWorking on sample 86\nWorking on sample 87\nWorking on sample 88\nWorking on sample 89\nWorking on sample 90\nWorking on sample 91\nWorking on sample 92\nWorking on sample 93\nWorking on sample 94\nWorking on sample 95\nWorking on sample 96\nWorking on sample 97\nWorking on sample 98\nWorking on sample 99\nWorking on sample 100\n","truncated":false}}
%---
%[output:66891288]
%   data: {"dataType":"text","outputData":{"text":"Mean number in system: 4.808672\n","truncated":false}}
%---
%[output:955e9560]
%   data: {"dataType":"text","outputData":{"text":"Mean number waiting: 3.979327\n","truncated":false}}
%---
%[output:3220b3ee]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAPoAAACXCAYAAAA8hka5AAAAAXNSR0IArs4c6QAAIABJREFUeF7tnQm4FcXRhgsiCopg0ATBBDXiLrjFKwkEo0biEpeouBFc0ESUTY2KBtTIIuAWBTQuEVFQEDdcooICxqhBDCaAogioiHuIIkIQVPh9K+n7zx3PnJlzzsycOfdUPw8PcO9MT\/fX9XVXV1dXNWjRosV6sWIIGAL1GoEGRvR6Pb7WOUNAETCimyAYAlWAgBG9CgbZumgIGNFNBgyBKkDAiF4Fg2xdNASM6CYDhkAVIGBEr4JBti4aAkZ0kwFDoAoQMKJXwSBbFw0BI7rJgCFQBQgY0atgkK2LhoAR3WTAEKgCBIzoVTDI1kVDIBNE33DDDeX73\/++jsbixYtrR+W73\/2ubLrppvLuu+\/K559\/HttotWjRQpo3by4ffvih\/Oc\/\/4mt3qgVbbnllrL99tvLnDlzZMWKFVFfq6rn9tlnH1m7dq1iVEpp1KiRIEeM8yeffFJKVRX9biaIvtdee8kNN9ygQP7xj3+UO++8U\/\/N3xDi6quvlvvvvz82oP\/0pz\/Jrrvuqt8cP358bPVGqeg3v\/mNnHbaafrokCFD5M9\/\/nOU10p65tJLL9WJ9Le\/\/W3FTCx\/+9vfZN26ddKxY8eC+o4snXXWWcL7Y8aMkSOOOEIuvvhiefPNN+Wkk04qqK6kH\/a3NcnvZY7oa9askYMOOki++OKLekn0e++9V773ve\/J7NmzZdiwYaqtJF2mTp2qmtFxxx0nS5cuTfpzsdTPZLx69Wrp06dPQfUdc8wxcv7558uCBQvk1FNPzTTR\/W0tqKMFPpw5otP+J598UliFvCs6E0Dfvn1l1qxZMnDgQNliiy3k7rvvln\/\/+99y4okn6qy93377KYGYKTfeeGN57LHHpEGDBnLIIYfUagsTJ04Ut6K\/8sor0qZNG2Hr8Oqrr2r9TDD77ruvfn+zzTZTle+JJ56Qa665Rho3biwPP\/ywvPfee\/LZZ59J+\/bt9Zvegqr4hz\/8QXbbbTetl\/dHjRolDz30kIwYMUJ+8pOfaJuWL1+u\/3\/66afrvM+qS3uph+\/cdddd8uijj2p7OnXqJDfffLNqN7\/85S915Xr22Wdl0KBB8rOf\/UxOP\/107Q9tAyfe8X4T1fXcc8+VN954I7CNXbp0kfPOO09ef\/112WqrrRTnRYsWyYMPPqj4bLTRRrpaXnTRRdruIKxoz4UXXqjt2GmnneTLL7+UE044QdBofvGLX8jmm28uy5Ytk0mTJmkf\/QXMGfMjjzxSNREm\/3\/+85+KOWP72muvyTnnnFNnSwfmYN+0aVMdR9r53HPPqWx89NFHijvfBXsmA8acbdRVV10lW2+9taxfv17mz58v\/fr1022DvwS1\/b777pNmzZrJ4MGD5a9\/\/ascdthhWgeTDVj+\/ve\/l5qaGpWH999\/X6688kqt39\/W\/v376+TUrVs37eOnn34q1113nTBRFyLfueaATBEdAUWQEHJmOwBp27atAgLJEOyFCxfKySefrEIIwMz6BxxwgKr8e+yxh\/aRQaYOV9z\/GUiIybOo7hQAZwAokPHWW29VMjds2FCBZgARkHHjxskdd9whTz31VB0cf\/SjH9X5v5tE+BYk32STTfT3kOTwww+XAw88UOv+17\/+pSREEF3p0aOH\/PrXv1aBo18MNuXYY49V0iLkbDXYcrgtAJNV7969ZcqUKdpnCLrttttqnwYMGKDY8Ic+YJOANAgN\/c\/Vxh122EHry4WjFyvqmDdvXiBWkJhJxRWIdvnll2vbqWfJkiU6trTh0EMPVay9xau6X3vtteJw9raBSW\/s2LG1r+24445y\/fXXq\/2FSWLGjBnyj3\/8Q\/tL4Wdg5PBHrWfrhM0GvPk58geGp5xySp32uO1lrrYPHz5cZY82Q+ybbrpJdt99d52Qv\/Wtb8lRRx2l9gHkAbll7C+44IJvtHXmzJk6KVB4\/tvf\/rb+G5no1atXZPlG3v0lU0Snc5MnT9Y9LDP2BhtsUDDRn3nmGR1YVgTUVSaDkSNHKkERfvZpEABBx9DTs2dPVWkRSgZg+vTpcvzxxyspWLUQwq5duyrw\/O2IjtbBRLRy5cpaTBEivk9xfXCDzkrBiusEi+\/6DU3ud0wWt912m7YbMjCrM\/EFER2Nge9AGvr99ttv68pF\/bTXq7p\/8MEHedtI\/yH6xx9\/rBMTxPnhD38ob731lmpOaESsfkx84BmEFQQEU\/bZTJ5oZ0wyRx99tAo844xAMhGisbD6hRGdNvzqV7\/SlZzJz0363veCVHcIyoTHqg9WkJ4xuP3227WNjA0TBFhT0CC8Ywsxg9resmVLnbRXrVqlmtVf\/vIXxQZthLFBy2KLxgKCYZBxYmyZaLzbjAkTJsg222yj74Pf7373O7VRPf\/88zrpM5lEkW\/sEZknOsR6\/PHHVW0GaNSwXCs6+1z2u\/4V3a14EJzZ87LLLlNBR4CbNGmiMzUqJUR3hj9AnDZtmg4As6p\/lQY0BIW2QZwgIxFChFAjRD\/96U8VawST2ZgVDuLkIzpqPCsK6ptf8Fm9vERnlkcDYEU\/44wzlDgInCtoR0xUL730Uh2iI8z52giRIbojEcJGuxE+6nMaC9smNIcgrFi5IToCDikpqMn33HNPrQbFz9555x0lmf\/0IdeKzpiyhXITM1oB24EoRHfPoqGh\/TCeaApuC+Inhpuo3c\/D2u7IjbyhubBoQGS2KWCIRkVBxlDvUdP9k5KTe39bIC4aD0SPIt9oJBVBdPai7JtcgegUBAfBYGVldh46dGjBRId4TnV1wotlF8s+qzazJ3ss9seoZKhzDDKzNcIH0b1E9gLK5MRgUdhnsxfEso667lbEfERH1WvdurW2D9JjiNpll110BYLMrKxsL2iXqxeiX3HFFaoq0k5WBJ5j8nLf9K7oTAD52sjqGoXoCByqZRBWqMOMl3fVZT\/P5MDv2rVrpxMX+DJhQ7qwFZ1JCA2jGKI7q7uX6Ez4rOCQnpWVwmSJus1k4D3SDWs78oMcucWJbR7jBj6MC1vPDh06qIZGYTyxXXhXdLc4sSgxcaPtMDFjQGVij0J05Nt7RO0wzZzqzqpJcYY4\/g3R586dq2oWBeEBMGbJQld0DB3MsG6PikGGulC1WNUfeeQRHXxmXkiNMDL4qN7ss\/MRnbahnn3nO99RgxgzK3s72jl69Gg1OuUjOiopqjDCgtr94x\/\/uNaYiCbC6oW6y2QHYSgQ\/cYbb6zd+9J+yL733nvXHim5lQJ7AJMjQhjURuqMQnRUdwyfQVhBFD\/REWpWMbQb2nTwwQdrOxyB4yA6RkoIzMRM25hIvMdrXqL\/\/Oc\/V0Iz9uCNwRDckClUcDQ3V8LazsR1yy231D5P3WgpbquD\/Lzwwgu6dURrg7io5d62IpPs55l4kEW0QrRQtCgm7yhER74xtlbEik4jUc2xyEISd47uJT97aAgYlegAxyrnJTpkZB9PQTC6d++uVlEMKqibTt1ipUe9RH2inqAVnXowZkE8Z4TjZxDMrRgQEUt2rj06K51bKd1Auf0677CHYytDYQ\/N8051ZyJxkwq\/d3tQbB0Y8tzJA5MV\/QhqI\/twnnErMSRBBXXaj9tCQHTqCMKK0wU\/0Wk7faAvrkB69r5+A5JXdXerJdsF9rxuRXcai1eowYQTAsjLtgGZoQ+uP16iY5iF0JziQD6HG3g5W4urO0rbsdvwHDYSJmwKmgAalzOs8jO0RuwV\/rbSL7ZVaHGuvPzyy3LmmWfqRJ6P6F75zizRXacwZuWyGHoHkn03Ja7zZ9RtAPeDA1EBHGsx+7tCyw9+8ANVw9FECvV+491WrVrpiun3CMTxhQmKbYG\/oObhUcYkCMG9WNJP+oQx7quvvtJXS2mj99uFYoUxb7vtttOtRS6hLBRr\/\/Oo3m67lQunXM\/vvPPO+mNWXu9K7n82X9ud6o0GyiLlLWytWFTQ8pApV3K1lYkQfJicmNDjKJlQ3TFYsDKgprB6otb4iYyqymoCWKxWrJJYz60YAllAwBnjkE1sMm4yzULbaEPZiY4qhQEIoDC0YMBwzhVekNy+EosmsypqYdB+JCvgWjsMgawgUHai44kFeTHMsHfEaohF0h1POaDYg2LIwoiDtRLDnLNOu2fYx7BP5Qyava0VQ8AQ+C8CZSc6lmYspc6V1Hkgoc7j3uovEJy9JU4XzsDknsGAk+tc1wbbEKh2BMpOdKzREJZ9DQUjBJZnzh9zGSJwJuGcnaMIv9HDiF7t4mz9D0Kg7ETnGAb3Qc6MKRx3XHLJJXUui2CZRHXnmMU5A3BhBacW1Hxb0U3ADYH8CJSd6Jx3YojDHRWjnHM64By7c+fOev6I\/zb7cxxFOH\/EX5hzXKzw7u463bQV3cTdEMiNQNmJTrMgr\/OH5ngCP2NcFnHs5\/wXbyH27Fz9c44oXJ3kOe8xhhHdxNwQyDDRaRqExsjGJYx8BYs7jha5QksZ0U3MDYGMEz2OATKix4Gi1VEfEciE6h4XsEb0uJC0euobAkb0+jai1h9DIAcCRnQTC0OgChAwotfTQXbuwPW0exXRLQzLRBfKQjGiZ2EUEmiD2SsSALXAKrM0BokRnQAB3KslCAB\/wu6ZF4hhzsezBGwc\/SmlDsOiFPTieTdLY5AY0YmWgV86ccW4yE+kDLzZiEOeVMkSsEn1MWq9hkVUpJJ7LktjkBjRHXxEhCFO1v7776+k59YZcdcIQ+SP5V0q5FkCttS+lPq+H4us79mj7GcJy0SIsVLScxHghBuQYXnY0EbJH+APWlnIuGRJHhMnOuGhuIaKC6uLgOkSKriLLIWAl+\/ZLAEbV5+KrcePBf8\/aNAjxVaX+HtPXnp46BVjtEQ8I8lMU2zhXgUGMjTMXIVJhJDUf\/\/73zWZAmQvtmRJHhMjOrfQiDtORFKCLBIni8spqO+s6lxiIehdnCVLwMbZr2LqqnSic2ORqLes4g888ICGv3YrOnHRCeTJ7UVSHRFplSwtXF0m8isBPglgQvw3NAUmBy5IcWHKEZ3ov2wtCbhIfD3uVRBvjyAoBHcknDbXp10kWe5iEM6ZSEfUycUqAkAS3JL3iIzkj6eeJXlMjOioRwQyZID4tz8GHPfN484kmiVgiyFnnO9UOtFZddEEXVholziDwCTEtYdYJElABSfyLn9z0YmwyEQnImIsKZnYsjh7EaHEHdGJPMsVaRYfYiFAXiL0kn2HeiA0udQIiMJEQsgzJg60UK5Vc9+CNjDZcKsSshMpmAnElSzJY2JE5+44ET7Zi3sLwDKIuYLMlyroWQK21L6U+n6lE50MKqyoEI7wyBh0SXHkJToTAeG+kSniEhD6mqCh5KVjZc5HdG5BEmiUP6zMpP9i1YbsqO7klSNtEllqqJ8UTYQEZ4+PFkDGGLRSJhXisBMfgbj93oSRWZLH2ImOOoTxDSAJ8si1U1cAk0ivQdkk4hbuUuur5PcrnejEKYDsZDfhZiNbPmKmO6JDQlZbMqBAaNRqJgOITsx8UiM5orPSkjjCu6KzykNSVmZkku1lLqJTD3t1F8OQ7SjPEa+QYKbu50wQ7O+9SR\/rNdFRhzC8kfGCvbhXlSH7CZ0nrVASJUvAJtG\/QuqsdKKjHiM7EIdwY+yx2Zs7ojuSBRGdDCjEt+ddto4k+\/ASHZWen1M\/W0g0A0d0CEsWViYTbE0uPRarPIFOiLfOM1VNdCeMAETMt7D75YUIb9izRvT\/R6jSiU5KIzKmoC6TRYX9MEdre+65p+6RHclcBlv\/is6zaAQsLmiWLkmm26Nj6GPy4HfIKQkzWKUhO4vUsGHDNLUxWgOTBSq8K2it7Nn9RCeHXFYjHsWqupPnioR+dJaECwCZq6A25YrwGkbksN8b0YOJXonn6KjqWNI56iomIQKWewgZdGYOuQlgwu85N8evg6NfLOrebCqgyoSCZR8tI2pbsiSPsROd\/QyqEMnzOPrIVbCaotb7S5SUTKhqDEYusLMEbNiklPTvDYukEQ6vP0tjECvRw7ue+4koKZkwyLCfYq8F0clpxj7MO2FkCdhisYjrPcMiLiSLrydLYxAr0VHdySjpspAGQUR+c6e6R03JxL4MCyzHGrxL\/nSI701VmyVgixePeN40LOLBsZRasjQGsRO9f\/\/+odhgxHArcdSUTOz72R9hJKFwnIGzgte7LkvAhoKQ8ANJYYF1uoGINPnyS1nB302a6Bm0lW8ikNQYFIN1rESnAaQgJq0vhhBvjnBv4zB+uNS0haZkoh6Xw9ufew1gKZZ7LZkY95D82tWrpadnMG8SkfOaNFHCJ1W87qxJfSOJeust0SE311DxLMK\/mJzQuQoeTeTpphSSkgkrKbeJyKbKOSZqvLdkCdgkBKeQOuPGgmOoEStW1CG5a08SZD\/ggAP0eAvvOOTpmWeeUXfWSipxj0EpfY99RedIDed+VnOuqOYqAOACUURJyUQdJKrH5ZAJgu3BkiVLvlF1loAtZVDieDduLNDS1n7xRWDTNmnSRBrHuKoz1hyt8TcJPPA\/ZyHB\/sMEz\/EXpzR9+\/bVi1P4wjtHLGQP7zgMuJy\/c8+CI90VK1aoJxt1LV26VKZMmaL9QZ4mTZqkSUPiLHGPQSlti53o3sbgNIN\/Mqs7N4rwMLrvvvsUcFeipmSaMGGCTh74MbuCKum9054lYEsZlDjejRuLBp99JsvyEH2LRo1k\/aabxtF0rQOvNDRCbo\/h3MIFKdxb27Vrp5dZuL1GauzWrVvLggUL9CgXv3i83SA9CwHbQy684BHHhIEmyM+5nELWXX6+2267qUGXtN1euYyjI3GPQSltSozozJwYztiPcw0QtbtNmzZKTLyMvOfgUVIy4dHEpOAtuCJ67wtnCdhSBiWOd+PG4vPVq2XV6tWBTduwUSO9IBJXwUjL8SmLBao7GgUXV9j2nX322UpSFg4uTeHqyoKCfGGfOeuss2pTarNAsJ0kA+\/y5cv1d1tuuaWGN8MLjrrIEITdJ+4S9xiU0r7EiM7g4NzCALjiyI8B7oUXXqjT7qgpmfJ1NgjYarQUxy1kuQxxbizYo\/dv1ixW67uf6KzmrPL8HFW7d+\/eMmbMGFXDXUFFx9UVVd4tAKz6HMcyCeBh5+w63HEHI1xtWe1LiVoTJJNxj0Fmib5y5Uq9o+tX09lXvfjii6W0O+e7uYAtl6U49s4VWGESQpYmlhAaX3WMcl5jnCM6d8jR8rgzjqo+cOBA1SggMHfKWWA49oPApOFmJfcSHblkMmDPT5izqG6thQxDEmNQyPe9z8a+ohMFhIKRjauBdJa7uuyv2Vdx\/Mbd3jSATdtSXOwgJPFeUkIGphC+2der+OoNNpD1\/ztLj7sPqNeQlktRuFM7q7uX6JAVmXIOWiwgc+bM0ZWesGUQHaMdQSa4J+4lOum4mSBmz54tffr0ibv5Wl9SY1BMY2MlOl5uzpKZrzHe47ViGh1VVQqzFHfq2LHONdo421LuurIkZMViwaUWbp9xgy2oYHnHQEcMONR2V7iYwuISZEnnPfb4GHcJWJFEydIYxEp0wApyknFAMhlgPHEOM3EC7Ad277ZtZeqsWYGf6FJTI7M9e7w421LuurIkZOXGwv99tE4MxcSG48ppUiVLYxA70b2gcScYYwfnnxRmZ4Bl70UQgbiLH9hu3brJyFGjAj\/ToaZGFhrR4x4Gq+9\/CFQF0VHPOR5xBZKzl8LHnWONsLjaxUhLLqLvMmpUoDdX03HjpF+\/fsV8KvPvZP3+eeYBjKGBUWLVx\/CZSFUktqJzrIExBH90jCqch7KaMwFgUElDdYf4NV37yPC5U7\/hn31R+y4y695R6jhRjcdvkaTDHqo3CCRG9MmTJ2vcLaJxYjHl7BPi8W\/O0ZMIMeVf0fk\/SQvWfLhYPp03VS3Fa1tup5bi5u26CEkDiOhZjosa9UaCrCMVgUBiRCebBvG2ON9EPUZlHz9+vBI\/l8NMHGgFET2o7qEHt5SV3bundlEjjj5aHYZAMQgkRnTOywcMGKBqMS6IBPpjj46f8hFHHFFMW0PfKZTorRZOkpl5rPJxX9QI7YA9YAgkhEBiRPe3l2M3nBhwaEiqFEr0HRdOqtrjt6TGwOrNJgKJEj3K7bU4YSmU6Ee2WFK1x29x4m51ZR+BxIheyO21uGAqhujVevwWF+ZWT2UgkBjRC729FgdchRIdq7sdv8WBvNWRdQQSJXq5b6+547WgQYDodvyWdRG19sWBQOxEz9LttahEDwLSjt\/iEDGrIwsIxEr0rN1eK5XoYcdv9fn2WxaE09oQHwKxEp1mhd1e45mga4dRUjLxPiGlvFcSHRzF7NFR3YOKHb\/FJ2hWU3kRiJ3o3u4QqpfgAM2bN9eom2RxIVKnP+9alJRMrl687IgeQuQRf4mb6FGP38xXvrxCbF8PRyAxoh922GHq\/rps2TJNNk9wSP4Qv4vwve5SS9SUTESSHTJkiEb9JANmWkQPO34jcIH5yocLmj1RXgQSIzq5oonw0qNHj9oekkr57rvvll69etVeaomakolwv8Tm5hIK8eLTIHrY8dvoC7qbr3x55de+HhGBxIhO6mTibZ933nm1TSEq7LRp02TUqFEyceJE\/XmhKZmI78VV1yCiU6dLyVSqMS7s+C3MWGe+8hGl0B5LHIHEiE7qJLKfDh06VMlNOGcCUXD8RtQZztgphaRk4vkwonO\/3Gucy2dsc0QOQjns91GNdbaHT1yO7QMhCCRGdKzvBM8ngqcrpGFiJSfovitRUzK557NE9CjGurnz5tke3mhYdgQSIzppdMiMQWYW9tVkVZk+ffo3IstETcmUVaLnM9bN79NH8v0+6SykZZcua0BmEEiM6ISSItcVMdzDSpSUTK4ODHnEi0\/LGBem+ufzld+p8XK77x42+Pb7VBBIjOguOCRHazNmzBAC\/7uC5Z0jMm9JIiVTXMa4sD18UKgq28OnIsP2kQgIJEb00aNHy5577pmzCTi8cL4ed4nbYSbMGBf2e9vDxz3CVl+xCCRG9GIbVMp7WSS67eFLGVF7Ny4EYic63m+cje+9997yzjvvaKZKf+bUuBrvrydrRA9zuIm6h7fjuaQkpnrqjZ3ot956qyaXh+Tkv+JIjZBSaZQsEj3fffcoe\/hn7XguDdGp99+InejksSZzJWfluK1OmjRJveMgYdIlq0QP6nfYHr6hiOBx0DNHBeQkt+O5pCWq\/tQfK9HJsUZoZ7zdIDyFhA0333yzkj\/pUolEz7eHP1tE1uUBzbnYmmqftGRVfv2JEN2boIFk9bfccosRPYeshO3haxovDw1Hbap95ZMwjR4kQnQSzr\/\/\/vvafu6a4xXHBRdX8IP3n6PH0dlKW9HDLs3Epdrbih+HdFV2HbETPUo6ZDK1VMM5etg5e9jvIXqpqj155sLuy9tEUNkkjtL6WIke5YNJPlOpK3oQJqWq9s1FZESIMY9vh00ESY6Z1Z0OAkb0PDHjwlbctH4f5GIbRbXPZ8zbsFEjGfnFF3mt+ohhg68njCZffikr+LtJE02HbaWyEDCiVwDRg0QqTLXvLyKf5pHHjURkTZ7f55oI7FivsgjuWmtEr2Cih6n2J++3Y97ccpt9HeFneYDcPi0ir9kZfmWyOkerjegVTvR8nndhK\/7YmprAa7TE2J2eR8wtTFZlzQFG9HpA9GKNeaz4QVb9fUTkxTyy3KWmRmYvWlRZ0l7FrTWi13Oih+WWCwqccW7L7WT1h4sDqdGhpkYWGtErZuowolcB0fOt+EETAe8Mnzs10CLfdNw4qampKVrQX3rpJQ37bSUdBIzoRvRAScu1x8fqflH7LjLr3lGaiTZsEsn3+3wibhNBvBNAxRE9X362+ugwUyqZSn2\/c6\/r5NN5U6WZiKxtuZ3gade8XRdJw4egFFG3iaIuehVDdG7G3X777dK2bVtZv369PProozJs2LA6vTGi1x3cJMmYZN30Io76baL4fwQqhuiXXHKJHHjggUKusx122EEGDBggPXv2lDlz5tT2Jozo5G977TVOh\/9b4hCmUldM7\/tZbl+W28ZYJtG+UiaKQt\/1Jh4p9N0oz1cM0Unx9Oabb0rv3r21X0899ZQ88MADdZJB3HDDDbLXXnvV6ffkNwjfkLvs03K9vPghDp72+1wI5MPHsItPdlh8Hhp8ShS+Fv1MxRCde+0Q+\/rrr9fOksSRzKys6lYMAUMgPwIVQ3Qi1ZAU4s4779Qe8Td51o3oJuKGQDgCFUP0yZMna6rlQYMGaa8eeeQRefLJJ2XkyJHhvbQnDIEqR6BiiD5ixAgNIX3IIYdoNlaMcX379pUXX8znqFnlo2vdNwT+h0DFEJ3Q0aRyIksrBVW+f38uYloxBAyBMAQqhuiuI7vvvrvGjMcQZ8UQMASiIVBxRI\/WLXvKEDAEvAhUFdHzuc+aWORGgPz1a9eurfPLhg0bSoMGDeSrr74qO2y52lf2Rn19Iahx48aapciPUbmwqwqiR3GfLZdw4OWHa6+3kNkmrXx1+frdr18\/IfOtNxf9wIEDpUuXLho3btGiRXL66aerQJej5GrftGnTlGSuPPzww4IhN61C+u+xY8dKy5YtFZe5c+fKhRdeqEfB5cSuKogexX02LUHwf4c88lzX5BTBlZdffllWrVpVriapO+mQIUOkdevWGn\/fEb1Tp05y1VVXydChQ2X+\/PkyZswYvXNw9dVXp9rWoPZB8BkzZiixnBayZMkS+eCDD1JrH5NKhw4d5JprrlE7EnhBfPAqJ3ZVQfQo7rOpSYLvQ5wc7LHHHuoPgJFx6dKl5WpK7XfJmXfcccdpu7baaqtaog8fPlyPOA866CB99qabbpKNN95YTj755FTbHNQ+3J9JDsLEudFGG6nfRdoFR65XX3219sIV\/h7vvfeefPLJJ2XFriqInmX3WdJKQyhWIPabCMUJJ5xQNnXYS4w+ffoIGodb0SdMmKA3B0866SR9jEkKNZ7LRuUo\/vZ169ZN70KsW7dObQhoReeee66gIZX1VzuDAAAE60lEQVSjnHjiierrcfHFF8uZZ55ZVuyqguhZdp\/t0aOHCuVtt92m2Wfvuece\/Td\/yl38RJo4caIsX7681u2YlZOJIK202H48\/O1ja8Gkc8UVV+iKTiZfUoNhR0iztGrVSjWLrbfeWu6\/\/35V48uNXVUQPcvus+SSf\/vtt2XFCtIjiF7c+eijjzLhw+8n0qWXXqrax9FHH61tZa\/epk0b6d69e5o8qv2Wv33bbrutkF7K7clpb+fOnVOdiHbeeWdBS6MNaDzYCCjlxq4qiJ5l91kmIayzXbt21Su2o0ePlsGDB8vjjz9eFvLkU90PPvhgFdhTTz1VOKq88cYb5YknnvhGAJC0Gu4n+mWXXSb777+\/kNsPD0qMhVi90\/SgZHvDt4mb4AqTD\/fNy4ldVRA9y+6zHTt2VFUT9R3yYJA7\/vjjdZ9Z7oJqfswxx9Tu0TkDvuOOOzTKDwXNgwnKf86eVrv97WvatKleX27WrJnQVo60zjjjDI1jkFbBHoStxVvIJszkWE7sqoLoDvQsu8+iwpNhNs2joGKFn70n5+iLFweHgy627jjew9ZBjrjXX389jupiraNc2FUV0WMdMavMEKggBIzoFTRY1lRDoFgEjOjFIlfB7+HkQvIFbBevvPKK\/rFSvxEwotfv8f1G7zAKYRHG+OcKTjqnnXZa7RFf3JCcc8456rRCQE8r5UHAiF4e3MvyVbzYLr\/8ciXd+eefL2vWrFGrOt5k+GIn5VgCwZ9\/\/nk9XrJSHgSM6OXBvSxfxe8aa7Tfkw0Ctm\/fXo499ljBqwu\/Ay60cDzFzboHH3xQb4SNGzdOL7u4WPpc1uDcePr06fo3nmj4yLM1mDlzpsb34w\/f43LMXXfdlQmPv7KAX+aPGtHLPABpfv65554TklywmucqXOcl4CZ\/47CzzTbbCEeS3P4jNh\/OMTilTJ06VV\/HtRiC467L+TF+8FwT3X777dX9k2dxHkF158ydW25ZuH6bJuZZ+ZYRPSsjkXA7IO+zzz4r3M\/2p7Jyn2Y15hIIe\/h58+bpjyE3JMULLYzo+HW7K6tMAnyL\/5vqnvDgRqjeiB4BpPryyNNPP60OOdyO8xZcbw899FA10OHmireeK1y7JJgC\/ux+oqMhjB8\/vnZFR013rruo83yPnxnRyy9BRvTyj0FqLeDCDJFPuOjhDXHk\/LPZjxO0gfvmK1eu1HZBXIx37M0hOsY8\/sbNdMqUKZpIw6nuXrXeiJ7asEb6kBE9Ekz146F9991XrrvuOnnrrbeUsB9\/\/LHekiNW\/pVXXikE6GAVxpCGgW7XXXfV57kUgirOCk6esAsuuEDDInFRIwrR2ffzHuq\/lfIgYEQvD+5l+ypHaNyB59KHK4899pjemKNA6qOOOqr2dwsWLNDnuWSDNR5tgELEFC6RoLpjfccYh9HOnZVjlONnqO7ky8NBBxsBk4SV9BEwoqePedm\/yC25XXbZRW9ZcVTmv322+eabS7t27XQV9l+yadGihR7RvfvuuwX1g5BUxFDjmM1K+ggY0dPH3L5oCKSOgBE9dcjtg4ZA+ggY0dPH3L5oCKSOgBE9dcjtg4ZA+ggY0dPH3L5oCKSOgBE9dcjtg4ZA+ggY0dPH3L5oCKSOgBE9dcjtg4ZA+ggY0dPH3L5oCKSOgBE9dcjtg4ZA+ggY0dPH3L5oCKSOwP8BaWU5cPg3BQEAAAAASUVORK5CYII=","height":151,"width":250}}
%---
%[output:3951852a]
%   data: {"dataType":"text","outputData":{"text":"Mean time in system: 0.480263\n","truncated":false}}
%---
%[output:67342ace]
%   data: {"dataType":"text","outputData":{"text":"Mean time waiting: 0.397092\n","truncated":false}}
%---
%[output:2c550a5b]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAPoAAACXCAYAAAA8hka5AAAAAXNSR0IArs4c6QAAGPpJREFUeF7tXQm0jdUX34SQDC8zISSKiAoVT\/TMU8ZHyDwsU4YMmR+WmWTIlHmei2QeSwrVo2UWIvMckQz\/9dv9v9t979377v3u+6Zz795rtcL9vjP8zvl9e5999tknUVhY2BMSEQQEgaBGIJEQPajHVzonCDACQnSZCIJACCAgRA+BQZYuCgJCdJkDgkAIICBED4FBli4KAkJ0mQOCQAggIEQPgUGWLgoCQnSZA4JACCAgRA+BQZYuCgJCdJkDgkAIICBED4FBli4KAkJ0mQOCQAggIEQPgUGWLgoCQnQD58Dzzz9PyZIl81jijRs3KGPGjPTss8\/SL7\/8Qv\/884+BNf9X1BtvvEEPHjyg6OjoBJWfNGlSbu9ff\/1FaLuI2ggI0Q0cvx07dngl+v79+yl37tyULl066tSpE+3du9fAmv8r6vvvv6fHjx\/T22+\/rav8p556iqZMmUKXLl2ivn37UvXq1al379506tQpatiwoa6yzH64aNGi1K5dO0JfZ86caXZ1QVG+EN3AYZw4cSKlSZOGnnnmGcqSJQs9efKETp48yTXs2rWLMmXKRLly5aKoqCg6c+aMgTX\/V9SMGTPo3r171LFjR13lQ4Pv3LmTrYHw8HBHE7127drUvXt3Onr0KDVt2lRXP0P1YSG6CSNfvHhx+vTTT+nvv\/+mMmXKuGoACXPkyMEaHf\/v2rUrHTt2jLJly0bp06enEydO0KpVq\/j3p59+mjVWr169+H1M6A8++IBSpkxJt27d4vI3btwYp\/Xr16\/nemvUqEHdunWjiIgIXiq8+uqr\/O6RI0foo48+ovv378d4d8WKFZQ1a1b+t3PnztG8efNYo1++fJkSJUpEzz33HN28eZMJdvjwYcKHYciQIVSiRAn+Hc916dKFzp49G6dNrVu3pqpVq3IZV69epaVLl9KCBQto+fLllDp1aho8eDB\/CKtUqUKdO3dmAuND5ek9LEnGjRtHqVKl4uUPMOrZs6dXfMqXL68LZxOmgyOKFKKbMAzeiL5u3TqX6Z4vXz7q0KED144JC+JoAq2qrfVBNpB+4MCB\/DPWyzD\/Ia1ataJff\/01Rg\/cTfexY8dSyZIl+Xf3MqdOnUqzZ8+O8d6iRYvY2oAVgg8OSIi6IfhwoH2JEyemK1eusLYfPnw4a34sE7COB\/FQR9myZenRo0eusmFmT5o0iX+DFZM3b16uo3LlylxGkSJFmKz46GHpULhwYcJHZ+vWrR7fa9++Pb8Hywnt2rZtG+3Zs8crPijPX5y3b99uwmxwRpFCdBPGQQ\/Rr1+\/TtWqVaPx48fT66+\/TqdPn6YGDRrQ4sWLKWfOnKxZS5UqxSSEDwAE\/eSTT+jFF1+k3bt3s9Z2F09ER5mNGjViTV6nTh06fvw4NWnSJMZ73kx3jbwFCxZkImpWiuaPGDp0KH8YJk+eTClSpCD8fe3ata6yP\/74Y6pVqxZ\/DFavXs0fNSxt8AyWMiNGjKC7d+\/Se++9x\/3DBw7WyIcffuj1PbTF3XTXPlKe8Pnpp5+Y6P7gjD4EqwjRTRhZPUTXSAfygvCYrDDXYea\/8sortHDhQtZ+adOmjdNST44yT0SHdh4zZgzVq1ePzWto1sjISL+Irj0LE3vDhg2smUFKrOc9CT5Q+GhpkjlzZlqyZEkMJyWWBi1atKDbt2+7yD1gwAAaNGiQy2KI7z0sR9yJ\/s0333jF5+uvv2ai+4PzhAkTTJgNzihSiG7COBhJ9Pnz59O7777L63iYs9CK0IgwXbEehsbypdE18gVCdO1j4k50mOywJrA2HzlyJK\/psZyARsfuAv6uCbB44YUXKCwsjAoVKsS+AiwBli1bRlhajB49mncI7ty5w+b\/nDlz2HKI7z18fNyJjg+ZN3wKFCjgF9GBM5YYwSpCdBNG1kiiw3TH3nvNmjVZm27ZsoUdfCAVtP4XX3xhCNFhMsOawPoZjjJ8RNy312ITHUTNnj07O+EOHjzIa3MQHw7D3377zdUmEBJecjjhoHkrVqxIGTJk4KUJND\/IP23aNNfzFSpUYE0f33u\/\/\/479ejRg01+OCVh+XjDB05HfzQ6cBbT3QQyBHOR\/hAdTil41zWTEqSCk0sz3eEwg\/bDBISGmz59Or388ssu2OCEa9OmDTvDvGl0TVvC\/IdZqml0zQ8Qeww0zzvKxNoZbdLaF5vo0KBok+YY1D4QsbUitDTW0NhV0ASkx7pdCxratGkTa3MQuH79+vxYfO\/hw4fdCXyc\/vjjD+6XN3xQnr84C9EtYiUcQr4ixpInT87PuHt2LWqe7dWALHny5GHywblkhmBtDLl48aJfxcMsB9kPHToUZ8vOvQA4FtF2fGTcNT6e0UxvbJth682f9xDgg7ZCq2PbD2IFPn6B4sCHHGG6Y48V2yswR7F9hG0jfKndBc4oeJzhqQXRDxw4wOYbvLki6iKgedrhzS9XrlxIfsCtGD3biQ6TEFstGHCs2WCmPnz4MI5XGKYkgjPgPb527RqNGjWKie++vrMCMKlDEFARAduJjsglbKvASYOIL+z3tmzZMkZEGYCdO3cuR2QNGzaMcV6zZg2dP3+e16maYH2IAA0RQUAlBLBzgkAgM8V2oiOI4\/333+coK4gWSQVzHprbkyCgBA4WOIvco5mwh6xFgpkJmlFlq9ReldqK8VGpvVa01XaiYxulUqVKvD6DwGGDPU3EPcd2OOGgCPZe4diBhxhmvLtYAZhRJEc5sFywRaaCqNRW1bC1Yt7aTnSEd2L9\/dZbb\/F8R9RVv379XBpeIwECHz7\/\/HP2BuMQg6fTX1YApgIppY1qIWDFvLWd6FqgBkgMp5zmXENMdunSpfnEFU5kYS8WEWE40aQJjmNiXa+JFYCpNYWktSogYMW8tZ3oGAgczACxIdhmadasGSc8gFcd22qIevKU1CH24QwrAFNh4kgb1ULAinnrCKJjWEBoZGCJHbutZ8isAExPe+RZQcAfBKyYt44huj+A+HrGCsB8tUF+FwT0ImDFvBWi6x0VeV4QMBgBIbpOQK0ATGeT5HFBwCcCVsxb0eg+h0EeEATMRUCIrhNfKwDT2SR5XBDwiYAV81Y0us9hkAcEAXMRUJroSHSA88FIEID\/fJ0zNwJKKwAzop1ShiDgjoAV89Y0jY6sH8hFjqQEyFiCjCjIlvLtt9+aNspWAGZa46XgkEXAinlrGtG1UUPKIVzpgwSHID0SRWzevJnzc7mHrxoxylYAZkQ7pQxBIGg0utYRpIfCMVQcO0WeNIh2YYF2kMWoYReiG4WklGMlAlbMW9M0Ok6hNW\/enC8e0K7sweEUmO\/Q6jjE4p40wghgrQDMiHZKGYJA0Gj0WbNmEa4RRmII\/Dl2DjicN0dyfSMFRI9PrMjkYWR\/pKzQQMAKBWWaRkeqYWT7jJ1CF1odaXO0W0aNHEoAFhG1xmuRm\/pXUyoDjZHYSFnORUBJosPTDucbzo4jySOOnWqSJEkSzvSKvHBCdOdOPGmZtQgoSXRkjIHjrVixYrwWR0JHTZDkH5368ssvTUFSNLopsEqhJiOgJNE1TOCMQ863hJwv14uvEF0vYvK8ExBQjui4PG\/jxo2cmhk3eCAVlCdBMI23DK8JAV6InhD05F27EFCS6AMHDmRvOi7Se\/PNNz1ih4vszbhhRYhu11SVehOCgHJET0hnjXhXiG4EilKG1QgoR3SY7rgZEwEy8UndunXFdLd6Nkl9jkVASaIj57ovwR1rYrr7Qkl+DxUElCM6BiYsLIz+\/PNPwrW22Ev3JLgxNfa93kYMqj+mu7d6JGrOiBGQMgJBQDmig9w4hrpkyRLKnz8\/FS5c2GO\/ccjF3\/u39QDnD9G9Rc5J1JwepOVZIxFQjujoPLbUjh07xtocR1Q9CTpmRiIKIbqR00\/KsgoBJYnuDg6CZmrUqMHa\/cKFC3zAZfny5XT79m1TMBSimwKrFGoyAkoTvUyZMnyXOdbjR44cIdyEmiNHDk42Ua1aNXr06JHh8AnRDYdUCrQAAaWJjnV68uTJWaNropEfd6L\/8MMPhkMoRDccUinQAgSUJ\/qdO3eoRYsWLqi0m1M7depEe\/fuNRxCIbrhkEqBFiCgJNGLFy\/O0OAUW+3atfm02rp169g517hxY95+i4iIENPdggkkVaiBgHJET506NW3YsMEnuk7dXvPW8Ogz16htZFWf\/ZIHBIFAEFCO6OiktyAZDQB8DC5dumRbwEx8++iyxx7INJV3EoqAkkR373T27NmpQoUKHCUHQeIJZKDp1asX7dq1Kw4+yBjrz\/461voPHjyI835C1+hC9IROWXk\/EASUJjrM8x49erj6DZLjsAti3OvUqcPbbpogI03Xrl05zRT+vVWrVnGSSWrPdu7cmT35ZcuWFaIHMqvkHcchoDTRZ8yYQcgR17t3b1q5ciUheAbaHB+A8uXLu0x3mPJr166lHTt2EA67TJkyhXPNRUZGxhgQBN0MGTKEsmbNSvfv3xeiO266SoMCRUBpoq9evZp+\/vlnGjRoEO3cuZNwqg0dwp+xj66lmALp8UzFihU5mAaJI1u2bEnYc3cXpI5GZpoiRYpwaK03jY535u04RnN3HI2DO+LZZY0e6HSU98xAAHMdW9AlS5Y0o3hXmaale46KiqLw8HDq27cvwdyGyT5\/\/nwmtXvADP4MLY9nIUWLFqVJkyZxgklP6aY6duzIz4vpbuq8kMItREBpjY798j59+tC9e\/f4RFv\/\/v15jX7lyhWqXr26C8bu3btTpUqVqFy5cvxvefLk4Q8CLnhAcsnYIkS3cAZKVZYgoDTRYyOEbTfcvRYdHR3jJwTWjBgxgrR72LCW79evn0vDO4Xo3kZczrFbwoWgrkR5ovtzek0Li8VdbHDKTZs2jQcVnnkceU2ZMiXhdhdN7NLosvUW1FyztXNKE13P6bVu3boxsSG42aVZs2Z06tQpmj17NqVNm5Zq1qzpGghc54TQWqvX6EJ0W7kQ1JUrTXS9p9dA6Ny5cyfowgczA2aE6EHNNVs7pzzRVTu9Jltvts73kK1cSaKrfHpNiB6yXLO148oRXfXTa4ESPb5ZIl55WzmkROXKER2o+jq9hmfu3r1rygDYtUaXO9lNGc6QKVRJoruPDgJhEN6XJk0aOnv2LN\/igiuTzbi8AfUK0UOGG0HVUaWJjsg2hL9evXqVTp8+zckh8R\/CWrFdZtcFDoGa54G8h9ko+eKDipOmdEZpoi9btoxvbGnevLkLHFylvHDhQsJeuBn3potGN2UeSqEmI6A00XF18tGjR\/mcuSbICrtlyxaaMGECLV682HD4nEp0bx0VR53hU0DJApUm+tixY6lEiRI0dOhQJjcCYpCIAttvyDqDPXajxalEl2Abo0c6uMpTmujwvi9atIgyZMjgGhWkiYImnzx5sikjJUQ3BVYp1GQElCY6MsTcvHmTk0kgWcTx48dp69atpjjhtHEQops8I6V4UxBQmuhIJZUzZ07O4W6VqEh0Wb9bNTucW4\/SRNeSQ2Jrbdu2bZwHThN43pH3zWhRkeiyfjd6FqhXntJEnzhxIr322mseUUcWV+yvGy1CdKMRlfKsQEBpolsBUOw6go3oYtbbMYusr1NJoiP6DQkfixUrRufOnSNkjjHj5lRPwxFsRBez3nrS2VGjkkSfPn06FSxYkEmeMWNGvnkFKaWsECG6FShLHUYjoCTRv\/vuO1qwYAHvlSMX+9KlSzk6Dp0xW4ToZiMs5ZuBgHJExx1rSO2MFM4gPAQXNkydOpXJb7aEEtHjw1JCa82eacaWryzR3S9owFVLyOwqRI87ORJyc4ycgTeWbHaWpizR9+3bRxcuXGDscOMKouJwwEUTxMHLPvq\/R1gDOf4a33vAGL+Lx95O6uqrW0mie7oOOXa3cVOL7KObS3Tx2Osjm51PK0d0O8FC3aG0RvdlusdHdNH2ds\/UmPUL0XWOhxD9X8ASsiQw+1ZPnUMaEo8L0XUOsxA94UQXba9z0hnwuBBdJ4hC9IQTXdb2OiedAY8L0XWCKEQ3l+jxDYfs3eucrG6PC9F1YidEN5fovhyAYvbrnLD\/f1yIrhM3Ibq9RBezX+eEFaIHDpgvrWN0gIo\/wStSpwTwxDejRaPr5LtodOdq9ED29X0Nf7D4BYToHkY6adKkfPTVkwjR1SR6IBYPehpfqK9KjkMhutto4WTcrFmzKG\/evPTkyRNau3YtDRs2LMZ4CtFDj+iBfCQC\/UCYZWEI0d2Q7devH5UrV45at25N+fLloz59+lDbtm0pOjra9ZQQXYiuTYaERAcmxM\/j62Pg7XezIxIThYWFPQm0cVa+hyueTp06RR06dOBqN2\/eTCtXroxxGcSkSZOoaNGiVjZL6hIEEoxA9Jlr1DayaoLLia8AZYiOc+0g9vjx47k\/uMQRN7NCq4sIAoJA\/AgoQ3RkqsGlEHPnzuUe4f+4Z12ILlNcEPCNgDJEX716NV+1HBUVxb1as2YNbdq0iT777DPfvZQnBIEQR0AZoo8YMYJTSFeqVIlvY4UzrlOnTrR3794QH0LpviDgGwFliI7U0bjKCbe0QmDK9+zZ03cP5QlBQBAgZYiujVXhwoU5ZzwccSKCgCDgHwLKEd2\/bslTgoAg4I5AUBE9vvBYu4c9ceLElChRInr06JHdTQm4\/mTJktGDBw8Cft\/MF53cNl\/9Tp48OYd1mzk3goLo\/oTH+gLbzN\/79u1L5cuXpyRJktCJEyeoRYsWceL127VrR40aNXI1AwNfpkwZM5ulq+zOnTsTbsEtW7asrveseBjLuSlTphCu6r548WKcKp2Kbdq0aWn27NmUKVMmng8HDhygHj168Lax0RIURPcnPNZo4Pwt75133qFRo0bR0KFD6dChQzRz5kyO0x89enSMIsaNG0fp0qXjSykhGHhsJ9ot+fPnpyFDhlDWrFk5F7\/TiI54ily5chGsOW9Edyq22EkqUaIEjRkzhn1OmCcgPi48MVqCguj+hMcaDZy\/5Q0fPpy3BSMiIvgVaJ6UKVNSkyZNYhSBSL\/9+\/fTjz\/+yP\/duXPH3ypMfQ7359WrV4+KFClC2bJlcxzRu3XrRmFhYdwub0R3Krb4SB0+fNh1OAuxIefPn6c2bdoYPqZBQXQnh8cuWrSIT9s1bNiQBw9bgjDjcUDHXRD8kypVKl4DQzvhIgwnbR927NiRieQ0jQ4Mcchpzpw5XonudGzRhwYNGnBcSO\/evWn79u1CdE8IODk8dvHixXTz5k1XqG779u15Qsa+ShoRf1u3buVBhgbt0qULRUZG0pkzZwwf9EAKVJnoTsY2S5YshCvKcubMSStWrGAz3gwJCo3u5PDY\/v37s9lbq1YtHj+s1XPkyEGNGzd2jSe8ri+99FKMI7e7d+\/mk3nz5883Y9x1l6kq0Z2MbYECBdgnAwcirDczP+pBQXQnh8dWrFiRQPamTZuySQ7yrl+\/ntdlpUuX5vU6rpresGEDffXVV4S+4Mw9noeJ75S1umpEVwFbLOsQ6Ynx1uTevXt069Yt3R9iXy8EBdGdHB6L\/XOsH5EZB3L58mWqW7cur8XhYcUWS82aNXl9Vr9+fX4G76xbt44GDx7sa\/ws+x1Ljtq1aztyjZ4nTx62fNydcSpgC98S9v\/dBTcPx3bUGjHIQUF0DQgnh8diDYZ99JMnT3odN2j8QoUK8V777du3jRhfKeP\/CIQ6tkFFdJnVgoAg4BkBIbrMDEEgBBAQoofAIMfuIhyAiMJzl8ePH7v+iqg8OIXu3r0bgugEZ5eF6ME5rvH2CnHr2KP3JvD6IruukwJ2QnCYDO2yEN1QONUoDJ7+zJkzc2Ph6ccWYKtWrejhw4f8b4gdv3DhQox9fTV6Jq30hoAQPcTnBrbNcGoO+87aDTjYyz948CAtWbKEsNe7ceNGjtWH5xpbhTjoUqpUKT5lhQNFiNeGVKlShZo1a8axATjAg1N7OAgjYj8CQnT7x8DWFngiOgJ6QHTk5cNeL2L19+zZwwTH2h4xAAg7xscBZn716tU5uGfQoEF0+vRpjvQqXrw4WwXYexexHwEhuv1jYGsL\/CH6vn37CJFxVatWZfIjtz5i+BHxh8M54eHhHKedIkUKqly5MvcHwSs4W43QXxBexF4EhOj24m977f4QfeTIkbRq1SrW4DDrkYACEX44Ioo\/49+1KC9of02QUadr166Eq7JE7EVAiG4v\/rbX7g\/RBwwYwOt0jejQ7EiU4E50HAW9fv06de\/enfuEdToiFZErQLbpbB9m9bLA2g9ZcLXAKKJPmDCB773DeWo44pAtBefEkQ7L2zXXwYWks3sjGt3Z42N66\/whOjzruNRS0+hYh9+4cSOGRseW3bx58yh9+vTcZgTgIF0WTH4R+xEQots\/BkHVAnjmQXbkuzMjyWFQgWVhZ4ToFoItVQkCdiEgRLcLealXELAQASG6hWBLVYKAXQgI0e1CXuoVBCxEQIhuIdhSlSBgFwJCdLuQl3oFAQsREKJbCLZUJQjYhYAQ3S7kpV5BwEIEhOgWgi1VCQJ2ISBEtwt5qVcQsBABIbqFYEtVgoBdCPwPeryN6R7Xk9oAAAAASUVORK5CYII=","height":151,"width":250}}
%---
