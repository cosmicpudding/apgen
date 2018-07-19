# APERTIF PARSET GENERATOR
Script to take input from a text file and translate into a parset for the APERTIF system. 

## Input
- Input text file containing source information
- Obs type: currently the only option is the "ag" setting (default)
- Software version: defaults to 2.7, but can be specified if needed

Note: parameters can be specified (in order) on command line, or defaults edited within the script

## To run
``` 
python apgen.py [INPUT FILE] [OBS TYPE] [SOFTWARE VERSION]
```
Examples:
```
python apgen.py
```
```
python apgen.py input/input_20180720.txt ag 2.7 bfweights_square_39p1_20180502_f4800_1005.dat
```
```
python apgen.py input/input_20180720.txt ag 2.6 ebm_20171214T104900.dat
```

## Solutions to known issues
#### 1) Bad interpreter when executing .sh file
If you see an error like this:
```
-bash: ./nov03_params.sh: /bin/bash^M: bad interpreter: No such file or directory
```
then the text file likely does not have the correct line endings for Unix systems. You should be able to solve it by switching the line endings back to Unix, using this command:
```
sed -i 's/\r//' nov03_params.sh 
```

## Help
For questions regarding this code: contact me via the RO Slack, drop me an email, or open a Redmine issue.
