# run_GSI

This script is designed to run GSI. In order to do this, you need to create 2 folders.

    [1] $ mkdir run/
    [2] $ mkdir plots/

In order to run the shell scripts in this folder, you may have to run

    $ chmod +x run_gsi.sh 
    $ chmod +x find_available_files.sh 

If you want a list of availabe WRF input files, you can run find_available_files.sh. 

    $ ./find_available_files.sh

This will create a text file called "available_wrf_files.txt". Right now, I don't cross-check 
there is available data for every wrf file b/c I assume there is (for now, a safe assumption.)
Anyways, now you can go to the main script: run_gsi.sh

There is a section at the top entitled USER INPUT. This should be the only section you need to modify. 
Change the date to be a 10-digit number (for me, it's easiest to grab a date from the "available
_wrf_file") text; or you can look manually in whatever folder you've processed files. 

    #################### USER INPUT #######################
    date=2018110909

    DEBUG=1 # (0,1): Debug options 1 for True (print extra info), 0 for False (less output)
    CLEAN=0 # (0,1): 1 for clean folder/delete interim files, 0 for keep extra file s
    LINK_BINARY=1 #(0,1) 1=Link binary files (should only have to do once); 0=Don't link 
    #######################################################

When you first set up this repository, you will want to set 
     DEBUG=1    >> will help print out info
     CLEAN=0    >> will keep interim files / easier for users to examine what's happened in the folder
and MOST IMPORTANTLY! 
    LINK_BINARY=1 >> this creates a symlink (soft link) between 
