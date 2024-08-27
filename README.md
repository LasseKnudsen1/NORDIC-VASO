"NORDIC_VASO_wrapper.m" runs NORDIC on VASO data (NIFTI_NORDIC.m) https://github.com/SteenMoeller/NORDIC_Raw.
%It runs NORDIC on nulled and not-nulled timeseries separately using magnitude-only, 
%and using appended noise-volume(s)

The files in manuscriptCode were used to preprocess, get stats files and figures for NORDIC denoising on VASO data manuscript. 
The files in the mother directory corresponds to the main 3T analysis. Raw files were first deobliqued with "deoblique_testNORDICvaso.sh",
the following steps are then described in "Pipeline_testNORDICvas.m". Figures were generated using "call*.m" files and corresponding functions. 

For analysis of the 7T data (in codeFor7Tpart) we first prepared files with "prepareFiles.sh", then denoising with "runNORDIC*m" files, 
then further preproc with "MOCOBOCO_gFactor.sh", stats files with "call_statsjob_gFactor.m", and figures were generated with call "call_findRightVersion_gFactor.m". 

Questions or comments are most welcome at lasse.knudsen96@gmail.com
