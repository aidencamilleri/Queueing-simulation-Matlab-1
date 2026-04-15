# Queueing-simulation-Matlab-1 Aiden Camilleri
A queueing simulation in Matlab.

## Abstract
Mickey’s Department Store expects many customers during the holiday season. Customer Relations
have set a goal of fewer than 10% of customers waiting more than 5 minutes. I used M/M/k queue
simulations and queuing theory to provide reccomendations on how many registers are needed to meet
this goal. Using these, I determined that 6 registers was the minimum to meet Customer Relation’s goal
under ideal assumptions. Upon sensitivity analysis, the maximum number of registers (8) was strugging
to keep up, as such, I recommended 8 registers to provide breathing room for Mickey’s.

## Architecture
The overall architecture is event driven.

The main class is `ServiceQueue`.
It maintains a list of events, ordered by the time that they occur.
There is one `Arrival` scheduled at any time that represents the arrival of the next customer.
When a customer reaches the front of the waiting queue, they can be moved to a service station.
Once a customer moves into a service slot, a `Departure` event for that customer is scheduled.
There should be one `Departure` event scheduled for each busy service station.
There is one `RecordToLog` scheduled at any time that represents the next time statistics will be added to the log table.
