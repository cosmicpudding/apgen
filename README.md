# APERTIF PARSET GENERATOR
Interim script to take output from Google schedule and translate into a parset for the APERTIF system. 

## Input
- Input text file containing source information (specified in command line)

## To run
``` 
python apgen.py input.txt
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
Drop me an email for questions regarding this code, or open an issue.

