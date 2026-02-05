# Weight Calculation Analysis for Manual Design

## Pattern Analysis with Staggered Periods

With staggered spike periods [5, 7, 11, 13]:

- Pixel 0 (period=5): spikes at cycles 4, 9, 14, 19, 24, 29, ...
- Pixel 1 (period=7): spikes at cycles 6, 13, 20, 27, 34, ...
- Pixel 2 (period=11): spikes at cycles 10, 21, 32, 43, 54, ...
- Pixel 3 (period=13): spikes at cycles 12, 25, 38, 51, 64, ...

## Hidden Layer Feature Detectors (Input → Hidden)

Current design makes hidden neurons as corner/edge detectors.

### For L-shape [1,0,1,1]:

Active inputs: I0(P=5), I2(P=11), I3(P=13)

- H0: W=[15,0,0,0] → Fires when I0 spikes (period 5)
- H2: W=[0,0,15,0] → Fires when I2 spikes (period 11)
- H3: W=[0,0,0,15] → Fires when I3 spikes (period 13)
- H5: W=[0,0,10,10] → Fires when I2+I3 spike (mixed)
- H6: W=[10,0,10,0] → Fires when I0+I2 spike (mixed)
- H7: W=[0,10,0,10] → Never fires (I1,I3 but I1=inactive)

### For T-shape [1,1,0,1]:

Active inputs: I0(P=5), I1(P=7), I3(P=13)

- H0: W=[15,0,0,0] → Fires when I0 spikes (period 5)
- H1: W=[0,15,0,0] → Fires when I1 spikes (period 7)
- H3: W=[0,0,0,15] → Fires when I3 spikes (period 13)
- H4: W=[10,10,0,0] → Fires when I0+I1 spike (mixed)
- H7: W=[0,10,0,10] → Fires when I1+I3 spike (mixed)

### For Cross [0,1,1,1]:

Active inputs: I1(P=7), I2(P=11), I3(P=13)

- H1: W=[0,15,0,0] → Fires when I1 spikes (period 7)
- H2: W=[0,0,15,0] → Fires when I2 spikes (period 11)
- H3: W=[0,0,0,15] → Fires when I3 spikes (period 13)
- H5: W=[0,0,10,10] → Fires when I2+I3 spike (mixed)
- H7: W=[0,10,0,10] → Fires when I1+I3 spike (mixed)

## Output Layer Analysis

Current O2 (Cross) weights: [0, 12, 12, 10, 0, 12, 0, 12]
For Cross pattern:

- From H1: 12 (fires at I1 spikes)
- From H2: 12 (fires at I2 spikes)
- From H3: 10 (fires at I3 spikes)
- From H5: 12 (fires at I2+I3)
- From H7: 12 (fires at I1+I3)
  Total current per cycle: ~12 (from whichever fires)

Current O1 (T-shape) weights: [10, 12, 0, 10, 12, 0, 0, 12]
For Cross pattern (erroneously):

- From H1: 12 (fires at I1 spikes)
- From H3: 10 (fires at I3 spikes)
- From H7: 12 (fires at I1+I3)
  Total: Similar to O2!

## PROBLEM: H1, H3, H7 are shared between T and Cross!

T-shape [1,1,0,1]: Activates H0, H1, H3, H4, H7
Cross [0,1,1,1]: Activates H1, H2, H3, H5, H7

Shared: H1, H3, H7 (3 out of 5!)
Unique to T: H0, H4
Unique to Cross: H2, H5

## Solution: Increase weight discrimination

Make O2 much stronger for H2 and H5 (unique to Cross)
Make O1 much stronger for H0 and H4 (unique to T)
Reduce weights for shared features (H1, H3, H7)

## Revised Weight Strategy

O0 (L-shape): Strong on H0, H2, H3, H6 (unique combo)
O1 (T-shape): Strong on H0, H4 | Medium on H1, H7 | Zero on H2, H5
O2 (Cross): Strong on H2, H5 | Medium on H1, H7 | Zero on H0, H4

The key insight:

- Use ZERO weights for mutually exclusive features
- Use HIGH weights (15) for unique identifiers
- Use MEDIUM weights (8-10) for shared features
