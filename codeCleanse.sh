#!/bin/sh
#title           :codeCleanse.sh
#description     :Code Cleanse aims to find all unused labels of Repository.
#author		     :Shivam Gupta, shivamgupta@salesforce.com
#date            :20210830
#version         :1.0.0    
#usage		     :./codeCleanse.sh
#notes           :Change stored PATH's as per usage
#bash_version    :3.2.57(1)-release
########################################################################################################

#--------------------------------------------------------------------------------------------------------
# Start Script
#--------------------------------------------------------------------------------------------------------
echo "\n"
echo "\t 🍂🍂 Running - Code Cleanse 🍂🍂";
echo "\t 🍂🍂    Team Everglades     🍂🍂";

#-----------------------------------------------
# Store path for different aspects of code
#-----------------------------------------------
CUSTOM_LABELS_PATH="../labels/CustomLabels.labels"
LWC_COMPONENTS_PATH="../lwcprojects"
PAGES_PATH="../pages"
CLASSES_PATH="../classes"

#-----------------------------------------------
# Define common messages
#-----------------------------------------------
POINTER="👉"
ALL_GOOD="\t All Good. 🌴"
NEEDS_FIX=" , Needs Fix 🩹"
DUPLCATE_VALUE_FOUND="\t Duplicate <value> Found   $POINTER"
UNUSED_LABEL_FOUND="\t Unused Label Found        $POINTER"
UNUSED_LABEL_IMPORT_FOUND="\t Unused Label import Found $POINTER"
OTHER_REPO_LABELS_FOUND="\t Other repo label found    $POINTER"

#-----------------------------------------------
# Identify and output duplicate values, if any
#-----------------------------------------------
echo "\n1 - Check duplicate values within CustomLabels.labels" # pending case insensitive check

#-----------------------------------------------
# Assumption <fullName>...</fullName> tags are in single line
# Assumption <value>...</value> tags are in single line
#-----------------------------------------------
OLD_IFS="$IFS"
IFS=$'\n'
DUPLICATE_LABELS=($( \
    sed -n '/<value>/p' $CUSTOM_LABELS_PATH | \
    sed -e 's/ *<\/*value> *//g'| \
    sort | \
    uniq -d))

if [ ${#DUPLICATE_LABELS[@]} -ne 0 ]; then
    for label in "${DUPLICATE_LABELS[@]}"
    do
       echo $DUPLCATE_VALUE_FOUND $label
    done
    echo "\t COUNT =" ${#DUPLICATE_LABELS[@]} $NEEDS_FIX
else
    echo $ALL_GOOD
fi
echo "\n\t📝 Note:- Before fixing duplicate labels, check if they are already part of managed package."
IFS="$OLD_IFS"


#-----------------------------------------------
# Identify and output all unused labels in repository
#-----------------------------------------------

echo "\n2 - Check all unused labels in complete Repository (pages, classes and lwc)"

#-----------------------------------------------
# Assumption *.js-meta.xml prefix is component directory name 
#-----------------------------------------------
USED_LABELS_ALL=()
LWC_COMPONENT_PATH_ARRAY=()
LWC_COMPONENT_LABELS_ARRAY=()
LWC_COMPONENTS=($( \
    find $LWC_COMPONENTS_PATH -name '*.js-meta.xml' | \
    awk -F '/' '{print $NF}' | \
    sed 's/.js-meta.xml//'))
for index in "${!LWC_COMPONENTS[@]}"
do
    LWC_COMPONENT_PATH=$(find $LWC_COMPONENTS_PATH -iname ${LWC_COMPONENTS[$index]})
    LWC_COMPONENT_LABELS=($(grep -hR "@salesforce/label/c." $LWC_COMPONENT_PATH | awk '{print $2}'))
    USED_LABELS_ALL+=(${LWC_COMPONENT_LABELS[*]})

    LWC_COMPONENT_PATH_ARRAY[$index]=$LWC_COMPONENT_PATH
    LWC_COMPONENT_LABELS_ARRAY[$index]=${LWC_COMPONENT_LABELS[*]}
done

USED_LABELS_ALL+=($( \
    grep -R "\$Label\." $PAGES_PATH | \
    sed 's/$Label./\
/g' | \
    awk -F "[^a-zA-Z]*" '{ if(length($1) > 0) print $1}'))

USED_LABELS_ALL+=($( \
    grep -R '[^a-zA-Z]Label\.' $CLASSES_PATH | \
    sed 's/Label\./\
/g' | \
    awk -F "[^a-zA-Z]*" '{ if(length($1) > 0) print $1}'))

#-----------------------------------------------
# Pattern labels are labels which are used by dynamically generating
# e.g $Label["upcReportSection"+ UPPER(key)]
# Hence replacing all labels having prefix upcReportSection with space in array(could be a flaw)
# Finally rmoving all empty spaces in array created by above mentioned step
#-----------------------------------------------
COULD_BE_PATTERN_LABEL=($( \
    grep -R "\$Label\[" $PAGES_PATH | \
    sed 's/$Label\["/\
/g' | \
    awk -F "[^a-zA-Z]*" '{ if(length($1) > 0) print $1}'))

COULD_BE_PATTERN_LABEL+=($( \
    grep -R '[^a-zA-Z]Label\[' $CLASSES_PATH | \
    sed 's/Label\["/\
/g' | \
    awk -F "[^a-zA-Z]*" '{ if(length($1) > 0) print $1}'))

ALL_REGISTERED_LABELS=($( \
    sed -n '/<fullName>/p' $CUSTOM_LABELS_PATH | \
    sed -e 's/ *<\/*fullName> *//g'))

ALL_NON_PATTERN_REGISTERED_LABELS=(${ALL_REGISTERED_LABELS[*]})
for label in "${COULD_BE_PATTERN_LABEL[@]}"
do  
    ALL_NON_PATTERN_REGISTERED_LABELS=("${ALL_NON_PATTERN_REGISTERED_LABELS[@]/$label*/}")    
done
ALL_NON_PATTERN_REGISTERED_LABELS=($(echo "${ALL_NON_PATTERN_REGISTERED_LABELS[*]}" | awk {print}))

UNUSED_LABELS=()
for label in "${ALL_NON_PATTERN_REGISTERED_LABELS[@]}"
do  
    COUNT=($(echo ${USED_LABELS_ALL[*]} | grep -cw $label))
    if [ $COUNT -eq 0 ]; then
        UNUSED_LABELS+=($label)
        echo "$UNUSED_LABEL_FOUND $label"
    fi
done

if [ ${#UNUSED_LABELS[@]} -ne 0 ]; then
    echo "\t COUNT =" ${#UNUSED_LABELS[@]} $NEEDS_FIX
else
    echo $ALL_GOOD
fi
echo "\n\t📝 Note:- Before fixing unused labels, check if other repositories are dependent on it."

#-----------------------------------------------
# Identify and output all labels used from other repositories
#-----------------------------------------------

echo "\n3 - Check all labels imported from other repositories"
OTHER_REPO_LABELS=()
for label in "${USED_LABELS_ALL[@]}"
do  
    COUNT=($(echo ${ALL_NON_PATTERN_REGISTERED_LABELS[*]} | grep -cw $label))
    if [ $COUNT -eq 0 ]; then
        OTHER_REPO_LABELS+=($label)
        echo "$OTHER_REPO_LABELS_FOUND $label"
    fi
done
if [ ${#OTHER_REPO_LABELS[@]} -ne 0 ]; then
    echo "\t COUNT =" ${#OTHER_REPO_LABELS[@]} $NEEDS_FIX
else
    echo $ALL_GOOD
fi

#-----------------------------------------------
# Identify and output all unused imported labels in LWC components
#-----------------------------------------------

echo "\n4 - Check all unused imported Labels in LWC Components"

UNUSED_LABEL_IMPORT=()
for index in "${!LWC_COMPONENTS[@]}"
do
    LWC_COMPONENT_PATH=${LWC_COMPONENT_PATH_ARRAY[$index]}
    LWC_COMPONENT_LABELS=(${LWC_COMPONENT_LABELS_ARRAY[$index]})

    if [ ${#LWC_COMPONENT_LABELS[@]} -ne 0 ]; then
        for label in "${LWC_COMPONENT_LABELS[@]}"
        do  
            LABEL_COUNT_IN_JS=0
            for js_file in $(ls "$LWC_COMPONENT_PATH"/*.js | grep -v "Labels.js")
            do 
                LABEL_COUNT_IN_JS+=$(grep -chR $label $js_file)
            done

            LABEL_COUNT_IN_HTML=0
            if [ -f "$LWC_COMPONENT_PATH/${LWC_COMPONENTS[$index]}.html" ]; then
                LABEL_COUNT_IN_HTML=$(grep -chR $label "$LWC_COMPONENT_PATH/${LWC_COMPONENTS[$index]}.html")
            fi

            if [ $LABEL_COUNT_IN_JS -eq 0 ] && [ $LABEL_COUNT_IN_HTML -eq 0 ]; then
                UNUSED_LABEL_IMPORT+=($label)
                echo "$UNUSED_LABEL_IMPORT_FOUND $label in ${LWC_COMPONENTS[$index]}"
            fi
        done
    fi
done
if [ ${#UNUSED_LABEL_IMPORT[@]} -ne 0 ]; then
    echo "\t COUNT =" ${#UNUSED_LABEL_IMPORT[@]} $NEEDS_FIX
else
    echo $ALL_GOOD
fi

#--------------------------------------------------------------------------------------------------------
# End Script
#--------------------------------------------------------------------------------------------------------