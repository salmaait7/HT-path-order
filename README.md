A small project for detecting circuit modifications from STA timing reports:

We builds a **timing fingerprint** of a reference circuit (without HT) at design time by comparing delays between pairs of paths, then checks whether the same relationships still hold in a test circuit (with HT).

Any broken relationship is counted as a **violation**.
