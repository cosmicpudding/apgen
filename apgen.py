# APERTIF PARSET GENERATOR (apgen.py)
# Input: source text file
# V.A. Moss 05/04/2018 (vmoss.astro@gmail.com)
__author__ = "V.A. Moss"
__date__ = "$19-jul-2018 17:00:00$"
__version__ = "1.1"

# Imports
import os
import sys
from astropy.io import ascii
from beamcalc import *
from datetime import datetime,timedelta


# scopes: edit this to suit the current available scopes!
scopes = '[RT2, RT3, RT4, RT5, RT6, RT7, RT8, RT9, RTA, RTB, RTC, RTD]'

# renumber scans
renum = False 

# Read in the source file
try:
	fname = sys.argv[1]
except:
	fname = 'input/input.txt'

# Get the observation type:
# Note: currently only "ag" is used
try:
	obstype = sys.argv[2]
except:
	obstype = 'ag'

# Get the software version currently used
try:
	softver = sys.argv[3]
except:
	softver = '3-r5805'

# Specify the weight pattern
try:
	weightpatt = sys.argv[4]
except:

	# Element beams
	weightpatt = 'ebm_20171214T104900.dat'

	# Compound beams
	#weightpatt = 'bfweights_square_39p1_20180502_f4800_1005.dat'

def ra2dec(ra):
    if not ra:
        return None
      
    r = ra.split(':')
    if len(r) == 2:
        r.append(0.0)
    return (float(r[0]) + float(r[1])/60.0 + float(r[2])/3600.0)*15


def dec2dec(dec):
    if not dec:
        return None
    d = dec.split(':')
    if len(d) == 2:
        d.append(0.0)
    if d[0].startswith('-') or float(d[0]) < 0:
        return float(d[0]) - float(d[1])/60.0 - float(d[2])/3600.0
    else:
        return float(d[0]) + float(d[1])/60.0 + float(d[2])/3600.0

def writesource(i,j,scan,date,stime,date2,etime,lo,sub1,src,ra,dec,old_date,old_etime,field,ints):

	# Determine the execute time
	if j == 0:

		# Old method, needs to change!! 
		#exetime = 'utcnow()'
		#exectime = None
 
		# Set the exec time to 10 min before start of scan (9/05/2018 VAM)
		exectime = datetime.strptime(date+stime,'%Y-%m-%d%H:%M:%S')-timedelta(minutes=10)
		exetime = str(exectime.date()) + ' ' + str(exectime.time())

	else:

		sdate_dt = datetime.strptime(str(date)+str(stime),'%Y-%m-%d%H:%M:%S')

		# Make it a 10 second gap between execution of the next parset (2/2/18 VM)
		exectime = datetime.strptime(old_date+old_etime,'%Y-%m-%d%H:%M:%S')+timedelta(seconds=10)
		exetime = str(exectime.date()) + ' ' + str(exectime.time())

		# Correct if too long
		if (sdate_dt-exectime).seconds > 600.:
			# Set the exec time to 10 min before start of scan (9/05/2018 VAM)
			exectime = datetime.strptime(date+stime,'%Y-%m-%d%H:%M:%S')-timedelta(minutes=10)
			exetime = str(exectime.date()) + ' ' + str(exectime.time())


	# Determine what the scan id is
	print(renum)
	if renum != False:
				scan = str(d['scan'][i])[:-2]+ '%.2d' % (j+1)
	if j == 0:

		# Write to file (not plus=)
		out.write("""TASKIDS=(    '%s')
EXEC_TIMES=( '%s')
START_TIMES=('%s %s')
STOP_TIMES=( '%s %s')
LO1FREQS=(   '%s')
SUBBAND1=(    %s)
SOURCENAMES=('%s')
FIELDNAMES=('%s')
SOURCE_RAS=( '%.4f')
SOURCE_DECS=('%.4f')
INTFACTORS=( '%s')

""" % (scan,exetime,date,stime,date2,etime,lo,sub1,src,src,ra,dec,ints))
		out.flush()
	else:
		# Write to file (plus=)
		out.write("""TASKIDS+=(    '%s')
EXEC_TIMES+=( '%s')
START_TIMES+=('%s %s')
STOP_TIMES+=( '%s %s')
LO1FREQS+=(   '%s')
SUBBAND1+=(    %s)
SOURCENAMES+=('%s')
FIELDNAMES+=('%s')
SOURCE_RAS+=( '%.4f')
SOURCE_DECS+=('%.4f')
INTFACTORS+=( '%s')

""" % (scan,exetime,date,stime,date2,etime,lo,sub1,src,src,ra,dec,ints))
		out.flush()

# Default file to use:
if obstype == 'ag':
	usefile = 'create_parset_ag.txt'
else:
	print('Error! This obstype does not exist...')
	sys.exit()

################################################

# Deal with the software version
if obstype == 'ag' and softver != '3-r5805':
	f = open('create_parset_ag.txt','rU').read()
	f2 = ('SR="%s"' % softver).join(f.split('SR="3-r5805"'))

	out = open('temp_create.txt','w')
	out.write(f2)
	out.flush()
	usefile = 'temp_create.txt'

else:
	f = open('create_parset_ag.txt','rU').read()
	out = open('temp_create.txt','w')
	out.write(f)
	out.flush()
	usefile = 'temp_create.txt'

################################################

# Deal with the weight pattern
if weightpatt != 'ebm_20171214T104900.dat':
	f = open('create_parset_ag.txt','rU').read()
	f2 = ('WEIGHTPATTERN="%s"' % weightpatt).join(f.split('WEIGHTPATTERN="ebm_20171214T104900.dat"'))

	# Write a new file
	out = open('temp_create.txt','w')
	out.write(f2)
	out.flush()
	usefile = 'temp_create.txt'

else:
	f = open('create_parset_ag.txt','rU').read()
	out = open('temp_create.txt','w')
	out.write(f)
	out.flush()
	usefile = 'temp_create.txt'

################################################

# Read file
d = ascii.read(fname,delimiter='\s',guess=False)
print(list(d.keys())) 

# Start the file
out = open('%s_params.txt' % fname.split('.')[0],'w')
out.write('#!/bin/bash\n# Script to create parsets for APERTIF\n# Original form by Boudewijn Hut 25/07/2017\n# Adapted by V.A. Moss 27/10/2017\n# Last updated by V.A. Moss 05/04/2018\n\n# values that change per measurement\n')
out.flush()

# Task ID counter
j = 0

# Initialise
old_date = None
old_etime = None

# Loop through sources
for i in range(0,len(d)):

	# Details source
	src = d['source'][i]
	src_obstype = d['type'][i]
	field = d['intent'][i].upper()

	# Account for RFI sources:
	if 'deg' in d['ra'][i]:
		ra = float(d['ra'][i].split('deg')[0])
		dec = float(d['dec'][i].split('deg')[0])

	# With :
	elif ':' in d['ra'][i]:
		ra = ra2dec(d['ra'][i])
		dec = dec2dec(d['dec'][i])

	# With HMS
	else:
		ra = ra2dec(d['ra'][i].replace('h',':').replace('m',':').replace('s',''))
		dec = dec2dec(d['dec'][i].replace('d',':').replace('m',':').replace('s',''))
	
	# Details obs
	stime = d['time1'][i]
	etime = d['time2'][i]
	date = d['date1'][i]
	ints = d['int'][i]

	# Details system
	lo = d['lo'][i]
	sub1 = d['sub1'][i]
	scan = d['scan'][i]

	# Fix times if they aren't the right length
	if len(stime.split(':')[0]) < 2:
		stime = '0'+stime
	if len(etime.split(':')[0]) < 2:
		etime = '0'+etime

	# do a check for the end time
	stime_dt = datetime.strptime(stime,'%H:%M:%S')
	etime_dt = datetime.strptime(etime,'%H:%M:%S')
	if etime_dt < stime_dt:
		date2 = datetime.strptime(date,'%Y-%m-%d')+timedelta(days=1)
		date2 = datetime.strftime(date2,'%Y-%m-%d')
	else:
		date2 = date

	# total date time
	sdate_dt = datetime.strptime(date+stime,'%Y-%m-%d%H:%M:%S')
	edate_dt = datetime.strptime(date2+etime,'%Y-%m-%d%H:%M:%S')

	# Write sources to file
	writesource(i,j,scan,date,stime,date2,etime,lo,sub1,src,ra,dec,old_date,old_etime,field,ints)		
	j+=1

	# update parameters
	old_etime = etime
	old_date = date2

out.write("""# constant value for all measurements
TELESCOPES="%s"   # "[RT2, RT3, RT4, RT5, RT6, RT7, RT8, RT9, RTA, RTB, RTC, RTD]"
""" % scopes)
out.flush()

# Determine which file to concatenate with
if obstype == 'ag':
	outname = '%s_params.txt' % fname.split('.')[0]
	outname2 = '%s_params_ag.sh' % fname.split('.')[0]
	os.system('cat %s %s > %s' % (outname,usefile,outname2))

else:
	print('You have specified something weird!')

# Make the resultting file executable
os.system('chmod oug+x %s' % outname2)
os.system('rm -rf temp_create.txt input/*params.txt')

