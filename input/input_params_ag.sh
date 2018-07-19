#!/bin/bash
# Script to create parsets for APERTIF
# Original form by Boudewijn Hut 25/07/2017
# Adapted by V.A. Moss 27/10/2017
# Last updated by V.A. Moss 05/04/2018

# values that change per measurement
TASKIDS=(    '180330999')
EXEC_TIMES=( '2018-03-30 13:25:00')
START_TIMES=('2018-03-30 13:35:00')
STOP_TIMES=( '2018-03-30 13:40:00')
LO1FREQS=(   '4800')
SUBBAND1=(    137)
SOURCENAMES=('3C48')
FIELDNAMES=('3C48')
SOURCE_RAS=( '24.4221')
SOURCE_DECS=('33.1598')
INTFACTORS=( '30')

TASKIDS+=(    '180330998')
EXEC_TIMES+=( '2018-03-30 13:40:10')
START_TIMES+=('2018-03-30 13:41:00')
STOP_TIMES+=( '2018-03-30 13:46:00')
LO1FREQS+=(   '4800')
SUBBAND1+=(    137)
SOURCENAMES+=('3C48_11')
FIELDNAMES+=('3C48_11')
SOURCE_RAS+=( '23.5262')
SOURCE_DECS+=('32.4098')
INTFACTORS+=( '30')

TASKIDS+=(    '180330997')
EXEC_TIMES+=( '2018-03-30 13:46:10')
START_TIMES+=('2018-03-30 13:47:00')
STOP_TIMES+=( '2018-03-30 13:52:00')
LO1FREQS+=(   '4800')
SUBBAND1+=(    137)
SOURCENAMES+=('3C48_35')
FIELDNAMES+=('3C48_35')
SOURCE_RAS+=( '26.2139')
SOURCE_DECS+=('33.1598')
INTFACTORS+=( '30')

# constant value for all measurements
TELESCOPES="[RT2, RT3, RT4, RT5, RT6, RT7, RT8, RT9, RTA, RTB, RTC, RTD]"   # "[RT2, RT3, RT4, RT5, RT6, RT7, RT8, RT9, RTA, RTB, RTC, RTD]"

# constant value for all measurements
WEIGHTPATTERN="ebm" # central element beam (PAF element 27X)
WEIGHTPATTERN="ebm_20171214T104900.dat" # 37 element beams, all in X: 27 3 5 7 13 15 17 19 12 14 16 18 20 24 26 28 30 23 25 29 31 35 37 39 41 34 36 38 40 42 46 48 50 52 47 49 51, 134 MHz
#WEIGHTPATTERN="bfweights_square_39p1_20180502_f4800_1005.dat" # first version of compound beam weights
DATAWRITER="wcudata1"
OUTPUTPATH="\/data\/apertif\/" # make sure sed can use the forward slashes (i.e. use '\/' in stead of '/')
SR="3-r5805" # System release. Valid numbers: 3-r5452
CENTRAL_UNIBOARDS='[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]' # selection of central uniboards

# added for reference:
#HOLOGPATTERN="HologGridDec50_20170803T163100"     # smaller grid, 2.5 hours
#HOLOGPATTERN="HologGridDec50_20170810T134500.dat" # extended grid, 5.3 hours


# check input
printf "\n"
N_MEASUREMENTS=${#TASKIDS[@]} # number of measurements

unique_TASKIDS=($(echo "${TASKIDS[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
if [ ${#unique_TASKIDS[@]} -ne $N_MEASUREMENTS ]; then printf "ERROR - The specified TASKIDS are not unique.\n"; exit 0; fi

if [ ${#EXEC_TIMES[@]}  -ne $N_MEASUREMENTS ]; then printf "ERROR - The number of %s does not match the number of measurements.\n" "EXEC_TIMES" ; exit 0; fi
if [ ${#START_TIMES[@]} -ne $N_MEASUREMENTS ]; then printf "ERROR - The number of %s does not match the number of measurements.\n" "START_TIMES"; exit 0; fi
if [ ${#STOP_TIMES[@]}  -ne $N_MEASUREMENTS ]; then printf "ERROR - The number of %s does not match the number of measurements.\n" "STOP_TIMES" ; exit 0; fi
if [ ${#LO1FREQS[@]}    -ne $N_MEASUREMENTS ]; then printf "ERROR - The number of %s does not match the number of measurements.\n" "LO1FREQS"   ; exit 0; fi
if [ ${#SUBBAND1[@]}    -ne $N_MEASUREMENTS ]; then printf "ERROR - The number of %s does not match the number of measurements.\n" "SUBBAND1"   ; exit 0; fi
if [ ${#FIELDNAMES[@]}  -ne $N_MEASUREMENTS ]; then printf "ERROR - The number of %s does not match the number of measurements.\n" "FIELDNAMES" ; exit 0; fi
if [ ${#SOURCENAMES[@]} -ne $N_MEASUREMENTS ]; then printf "ERROR - The number of %s does not match the number of measurements.\n" "SOURCENAMES"; exit 0; fi
if [ ${#SOURCE_RAS[@]}  -ne $N_MEASUREMENTS ]; then printf "ERROR - The number of %s does not match the number of measurements.\n" "SOURCE_RAS" ; exit 0; fi
if [ ${#SOURCE_DECS[@]} -ne $N_MEASUREMENTS ]; then printf "ERROR - The number of %s does not match the number of measurements.\n" "SOURCE_DECS"; exit 0; fi
if [ ${#INTFACTORS[@]}  -ne $N_MEASUREMENTS ]; then printf "ERROR - The number of %s does not match the number of measurements.\n" "INTFACTORS" ; exit 0; fi

# system values
if [ "$SR" == "3-r5805" ]; then
    CONTROLLERS="['DirectionControl', 'CorrelatorControl']"
    # no longer use multicast: be specific and use e.g. "SignalControl@lcu-rt2"
    TELS="${TELESCOPES//,/ }"
    for TEL in $TELS
    do
        # convert telescopes string to lcu string
        TMP_STR=$(echo "$TEL" | tr '[:upper:]' '[:lower:]')
        TMP_STR=${TMP_STR#"["}
        TMP_STR=${TMP_STR#"]"}
	TMP_STR=${TMP_STR%"["}
	TMP_STR=${TMP_STR%"]"}
        LCU="lcu-$TMP_STR"
        # add SignalControl@<host> and DelayCompControl@<host>
        CONTROLLERS="${CONTROLLERS::-1}, 'SignalControl@$LCU', 'DelayCompControl@$LCU']"
    done
    CMD_DW=". /opt/gcc-6.3.0/gcc.rc ; cd /softw/datawriter/installed/ ; . apertifinit.sh ; "
    CMD_MAC=". /opt/apertif/apertifinit.sh;"
    CMD_SENDFILE="send_file -t 0"
    CONTROLLER_DW="['DatawriterControl']"
fi

DIR_PARSET=${PWD}
BEAMS="[0..36]"
#N_SUBBANDS=171
#SUBBAND_BF=(0 1 2 3 3 3 4 5 6 7 7 7 8 9 10 11 11 11 12 13 14 15 15 15 16 17 18 19 19 19 20 21 22 23 23 23 24 25 26 27 27 27 28 29 30 31 31 31 32 33 34 35 35 35 36 37 38 39 39 39 40 41 42 43 43 43 44 45 46 47 47 47 48 49 50 51 51 51 52 53 54 55 55 55 56 57 58 59 59 59 60 61 62 63 63 63 64 65 66 67 67 67 68 69 70 71 71 71 72 73 74 75 75 75 76 77 78 79 79 79 80 81 82 83 83 83 84 85 86 87 87 87 88 89 90 91 91 91 92 93 94 95 95 95 96 97 98 99 99 99 100 101 102 103 103 103 104 105 106 107 107 107 108 109 110 111 111 111 112 113 114 115 115 115 116 117 118 119 119 119 120 121 122 123 123 123 124 125 126 127 127 127 128 129 130 131 131 131 132 133 134 135 135 135 136 137 138 139 139 139 140 141 142 143 143 143 144 145 146 147 147 147 148 149 150 151 151 151 152 153 154 155 155 155 156 157 158 159 159 159 160 161 162 163 163 163 164 165 166 167 167 167 168 169 170 171) # 171 171 172 173 174 175 175 175 176 177 178 179 179 179 180 181 182 183 183 183 184 185 186 187 187 187 188 189 190 191 191 191 192 193 194 195 195 195 196 197 198 199 199 199 200 201 202 203 203 203 204 205 206 207 207 207 208 209 210 211 211 211 212 213 214 215 215 215 216 217 218 219 219 219 220 221 222 223 223 223 224 225 226 227 227 227 228 229 230 231 231 231 232 233 234 235 235 235 236 237 238 239 239 239 240 241 242 243 243 243 244 245 246 247 247 247 248 249 250 251 251 251 252 253 254 255 255 255)
N_SUBBANDS=255
SUBBAND_BF=(0 1 2 3 3 3 4 5 6 7 7 7 8 9 10 11 11 11 12 13 14 15 15 15 16 17 18 19 19 19 20 21 22 23 23 23 24 25 26 27 27 27 28 29 30 31 31 31 32 33 34 35 35 35 36 37 38 39 39 39 40 41 42 43 43 43 44 45 46 47 47 47 48 49 50 51 51 51 52 53 54 55 55 55 56 57 58 59 59 59 60 61 62 63 63 63 64 65 66 67 67 67 68 69 70 71 71 71 72 73 74 75 75 75 76 77 78 79 79 79 80 81 82 83 83 83 84 85 86 87 87 87 88 89 90 91 91 91 92 93 94 95 95 95 96 97 98 99 99 99 100 101 102 103 103 103 104 105 106 107 107 107 108 109 110 111 111 111 112 113 114 115 115 115 116 117 118 119 119 119 120 121 122 123 123 123 124 125 126 127 127 127 128 129 130 131 131 131 132 133 134 135 135 135 136 137 138 139 139 139 140 141 142 143 143 143 144 145 146 147 147 147 148 149 150 151 151 151 152 153 154 155 155 155 156 157 158 159 159 159 160 161 162 163 163 163 164 165 166 167 167 167 168 169 170 171 171 171 172 173 174 175 175 175 176 177 178 179 179 179 180 181 182 183 183 183 184 185 186 187 187 187 188 189 190 191 191 191 192 193 194 195 195 195 196 197 198 199 199 199 200 201 202 203 203 203 204 205 206 207 207 207 208 209 210 211 211 211 212 213 214 215 215 215 216 217 218 219 219 219 220 221 222 223 223 223 224 225 226 227 227 227 228 229 230 231 231 231 232 233 234 235 235 235 236 237 238 239 239 239 240 241 242 243 243 243 244 245 246 247 247 247 248 249 250 251 251 251 252 253 254 255 255 255)

CMD_MAC="$CMD_MAC cd $DIR_PARSET ; $CMD_SENDFILE "

PREV_STOP_TIME='1970-01-01 00:00:00'
PREV_LO1FREQ="4650"
PREV_SB1="-1"
EXIT_STATUS=0
printf "\nThere are %s measurements specified:\n" "$N_MEASUREMENTS"
printf "%-11s %-20s  %-10s  %-4s  %-10s  %-9s %-11s\n" "SOURCE" "UTC(PREP:START-STOP)" "DATE" "LO1" "SUBBANDS" "TASKID" "FIELD/COMMENT"
for ((i=0;i<${#TASKIDS[@]};++i)); do
    NOTE=""
    TASKID="${TASKIDS[i]}"
    EXEC_TIME="${EXEC_TIMES[i]}"
    START_TIME="${START_TIMES[i]}"
    STOP_TIME="${STOP_TIMES[i]}"
    LO1FREQ="${LO1FREQS[i]}"
    SOURCENAME="${SOURCENAMES[i]}"
    FIELDNAME="${FIELDNAMES[i]}"
    SOURCE_RA="${SOURCE_RAS[i]}"
    SOURCE_DEC="${SOURCE_DECS[i]}"
    INTFACTOR="${INTFACTORS[i]}"
    
    # convert 'first subband' to list of subband numbers
    # for Datawriter
    SB1="${SUBBAND1[i]}"
    SB2=$((${SUBBAND1[i]}+$N_SUBBANDS))
    SUBBAND="[$SB1..$SB2]"
    # for SignalControl and DelayCompControl
    SUBBAND_BF_STR="["
    for ((j=0;j<${#SUBBAND_BF[@]};++j)); do
        SUBBAND_BF_STR="${SUBBAND_BF_STR}$((${SUBBAND_BF[$j]} + $SB1)),"
    done
    SUBBAND_BF_STR="${SUBBAND_BF_STR::-1}]"
    
    # generate general parset
    PARSET=$TASKID.parset
    cp parset_multi_element_beams.template $PARSET
    sed -i "s/@TASKID@/$TASKID/g" $PARSET
    sed -i "s/@EXEC_TIME@/$EXEC_TIME/g" $PARSET
    sed -i "s/@START_TIME@/$START_TIME/g" $PARSET
    sed -i "s/@STOP_TIME@/$STOP_TIME/g" $PARSET
    sed -i "s/@TELESCOPES@/$TELESCOPES/g" $PARSET
    sed -i "s/@LO1FREQ@/$LO1FREQ/g" $PARSET
    sed -i "s/@SOURCENAME@/$SOURCENAME/g" $PARSET
    sed -i "s/@FIELDNAME@/$FIELDNAME/g" $PARSET
    sed -i "s/@TEL_POINTING_RA@/$SOURCE_RA/g" $PARSET
    sed -i "s/@TEL_POINTING_DEC@/$SOURCE_DEC/g" $PARSET
    sed -i "s/@BEAMS@/$BEAMS/g" $PARSET
    sed -i "s/@WEIGHTPATTERN@/$WEIGHTPATTERN/g" $PARSET
    sed -i "s/@DATAWRITER@/$DATAWRITER/g" $PARSET
    sed -i "s/@INTFACTOR@/$INTFACTOR/g" $PARSET
    sed -i "s/@OUTPUTPATH@/$OUTPUTPATH/g" $PARSET
    sed -i "s/@CENTRAL_UNIBOARDS@/$CENTRAL_UNIBOARDS/g" $PARSET
    
    for BM_CNT in `seq 0 36`; do
      BM_STR=$(printf "%03d" "$BM_CNT")
      # calculate phase center per compound beam
      PHC_RA=$(python calc_phase_centers.py "$SOURCE_RA" "$SOURCE_DEC" $WEIGHTPATTERN $BM_CNT ra)
      PHC_DEC=$(python calc_phase_centers.py $SOURCE_RA $SOURCE_DEC $WEIGHTPATTERN $BM_CNT dec)
      sed -i "s/@PHASE_CENTER_RA_BM$BM_STR@/$PHC_RA/g" $PARSET
      sed -i "s/@PHASE_CENTER_DEC_BM$BM_STR@/$PHC_DEC/g" $PARSET
    done
    
    # generate parset for datawriter
    PARSET_DW=$TASKID\_dw.parset
    cp $PARSET $PARSET_DW
    sed -i "s/@SUBBAND@/$SUBBAND/g" $PARSET_DW
    sed -i "s/@CONTROLLERS@/$CONTROLLER_DW/g" $PARSET_DW
    # make sure parset for rest of the system
    sed -i "s/@SUBBAND@/$SUBBAND_BF_STR/g" $PARSET
    sed -i "s/@CONTROLLERS@/$CONTROLLERS/g" $PARSET
    
    CMD_MAC="$CMD_MAC $PARSET $PARSET_DW"
    START_TIME_STR=$START_TIME
    START_TIME_STR=${START_TIME_STR//-/}
    START_TIME_STR=${START_TIME_STR//:/}
    CMD_DW="${CMD_DW} ./sleepuntil.sh $START_TIME_STR ; datawriter -t 3 $DIR_PARSET/$PARSET_DW 2>&1|tee /opt/apertif/var/log/datawriter_${PARSET/parset/log} ;" # TODO
    
    # check PREV_STOP, EXEC, START, STOP times to be increasing
    ERRORSTR=""
    T0=`date --date="$PREV_STOP_TIME" +%s`
    if [ "$EXEC_TIME" != "utcnow()" ]; then
        T1=`date --date="$EXEC_TIME" +%s`
    else
        T1=$((T0 + 1)) # nasty way of making EXEC_TIME be a kind-of-valid number
    fi
    T2=`date --date="$START_TIME" +%s`
    T3=`date --date="$STOP_TIME" +%s`
    if [ $T1 -le $T0 ]; then ERRORSTR+="ERROR - The specified START_TIME does not follows previous STOP_TIME." ; EXIT_STATUS=1; fi
    if [ $T2 -le $T1 ]; then ERRORSTR+="ERROR - The specified START_TIME does not follows EXEC_TIME." ; EXIT_STATUS=1; fi
    if [ $T3 -le $T2 ]; then ERRORSTR+="ERROR - The specified STOP_TIME does not follows START_TIME." ; EXIT_STATUS=1; fi
    
    if [ "$ERRORSTR" != "" ]; then ERRORTAG="(!)" ; else ERRORTAG="";  fi
    printf "%-11s %5s: %5s - %5s  %-10s  %-4s  %-10s  %-9s %-3s %-11s %s\n%s" "$SOURCENAME" "$(echo $EXEC_TIME | cut -c12-16)" "$(echo $START_TIME | cut -c12-16)" "$(echo $STOP_TIME | cut -c12-16)" "$(echo $START_TIME | cut -c1-10)" "$LO1FREQ" "$SUBBAND" "$TASKID" "$FIELDNAME" "$ERRORTAG" "$NOTE" "$ERRORSTR"
    if [ "$ERRORSTR" != "" ]; then printf "\n" ; fi
    
    PREV_STOP_TIME=$STOP_TIME
    PREV_LO1FREQ=$LO1FREQ
    PREV_SB1=$SB1
done

printf "\n"
printf "Telescopes:     %s\n" "$TELESCOPES"
printf "Weight pattern: %s\n" "$WEIGHTPATTERN"
printf "Datawriter:     %s\n" "$DATAWRITER"
printf "System release: %s\n" "SR$SR"

printf "\n\n"

printf "You could use the following to control the mac software on any machine as any user:\n"
printf "%s\n\n" "$CMD_MAC"

printf "You could use the following to control the datawriter (as user apertif):\n"
printf "%s\n\n" "$CMD_DW"

exit $EXIT_STATUS
