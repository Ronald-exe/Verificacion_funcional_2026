#!/bin/csh -f

cd /mnt/vol_NFS_rh003/Est_Veri_II2026/CASTRO_VELASQUEZ_ERIC_VeriII26/P1/Verificacion_funcional_2026/EDA_VCS/sim/broadcast

#This ENV is used to avoid overriding current script in next vcselab run 
setenv SNPS_VCSELAB_SCRIPT_NO_OVERRIDE  1

/mnt/vol_NFS_rh003/tools/vcs/R-2020.12-SP2/linux64/bin/vcselab $* \
    -o \
    simv \
    -nobanner \

cd -

