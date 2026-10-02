simSetSimulator "-vcssv" -exec "simv" -args "+ntb_random_seed=1010 -ucli"
debImport "-dbdir" "simv.daidir"
debLoadSimResult \
           /mnt/vol_NFS_rh003/Est_Veri_II2026/CASTRO_VELASQUEZ_ERIC_VeriII26/P1/Verificacion_funcional_2026/EDA_VCS/sim/bcast_param/waves.fsdb
wvCreateWindow
srcDeselectAll -win $_nTrace1
srcHBSelect "tb_top.dut" -win $_nTrace1
srcHBSelect "tb_top.dut" -win $_nTrace1
srcSetScope "tb_top.dut" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "reset" -line 772 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "clk" -line 771 -pos 1 -win $_nTrace1
srcGotoLine 771 -setActive -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "reset" -line 772 -pos 1 -win $_nTrace1
srcAction -pos 771 3 1 -win $_nTrace1 -name "reset" -ctrlKey off
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\]" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "clk" -line 771 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "reset" -line 772 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcHBSelect "tb_top" -win $_nTrace1
srcHBSelect "tb_top" -win $_nTrace1
srcHBSelect "tb_top" -win $_nTrace1
srcSetScope "tb_top" -delim "." -win $_nTrace1
srcHBSelect "tb_top" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcHBSelect "tb_top.dut" -win $_nTrace1
srcHBSelect "tb_top.dut" -win $_nTrace1
srcSetScope "tb_top.dut" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pndng\[b\]\[i\]" -line 861 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "pndng\[b\]\[i\]" -line 861 -pos 1 -partailSelPos 9 -win \
          $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pndng\[b\]\[i\]" -line 861 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pndng\[b\]\[i\]" -line 861 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvUnknownSaveResult -win $_nWave2 -clear
srcDeselectAll -win $_nTrace1
srcSelect -signal "pndng\[b\]\[i\]" -line 861 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "bs_bsy\[b\]" -line 868 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcHBSelect "tb_top.dut" -win $_nTrace1
srcHBSelect "tb_top.dut" -win $_nTrace1
srcSetScope "tb_top.dut" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pndng" -line 841 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvUnknownSaveResult -win $_nWave2 -clear
srcDeselectAll -win $_nTrace1
srcSelect -signal "pndng" -line 841 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pndng" -line 841 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "pndng" -line 841 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvUnknownSaveResult -win $_nWave2 -clear
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\]" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pndng" -line 773 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
verdiWindowResize -win $_Verdi_1 "175" "140" "900" "737"
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\]" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pndng\[b\]\[i\]" -line 861 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\]" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\]" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\]" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\].ID\[0\]" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\]" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[1\].ntrfs" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\].ID\[1\].ntrfs" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[1\].ntrfs" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pndng" -line 773 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcHBSelect "tb_top.dut.BUS\[0\].ID\[2\].ntrfs" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\].ID\[2\].ntrfs" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[2\].ntrfs" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pndng" -line 773 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pndng" -line 773 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcHBSelect "tb_top.dut.BUS\[0\].ID\[3\].ntrfs" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\].ID\[3\].ntrfs" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[3\].ntrfs" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[3\].ntrfs" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pndng" -line 773 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\]" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "trn_chng" -line 849 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
tfgBehaviorAnalysis -bas {{tb_top.dut}} -clockSkew 0 -loopUnroll 0 \
           -bboxEmptyModule 0 -bboxIgnoreProtected 0 -cellModel 0 \
           -confined_flattern 32768
nsMsgSwitchTab -tab general
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "trn_chng" -line 780 -pos 1 -win $_nTrace1
wvCreateWindow
wvSetPosition -win $_nWave3 {("G1" 0)}
wvOpenFile -win $_nWave3 \
           {/mnt/vol_NFS_rh003/Est_Veri_II2026/CASTRO_VELASQUEZ_ERIC_VeriII26/P1/Verificacion_funcional_2026/EDA_VCS/sim/bcast_param/waves.fsdb}
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave3
verdiWindowBeWindow -win $_nWave3
wvResizeWindow -win $_nWave3 2 27 896 265
wvResizeWindow -win $_nWave3 -1 26 1920 1016
wvResizeWindow -win $_nWave3 285 686 896 265
verdiDockWidgetSetCurTab -dock windowDock_nWave_2
wvTpfCloseForm -win $_nWave3
wvGetSignalClose -win $_nWave3
wvCloseWindow -win $_nWave3
srcDeselectAll -win $_nTrace1
srcSelect -signal "trn_chng" -line 780 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\]" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\]" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "bs_bsy" -line 848 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "bs_bsy" -line 848 -pos 1 -win $_nTrace1
srcAction -pos 847 3 2 -win $_nTrace1 -name "bs_bsy" -ctrlKey off
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\]" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcHBDrag -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcHBSelect "tb_top.dut" -win $_nTrace1
srcHBSelect "tb_top.dut" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\]" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
verdiWindowResize -win $_Verdi_1 "554" "48" "777" "737"
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\]" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\]" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "push" -line 864 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvUnknownSaveResult -win $_nWave2 -clear
srcDeselectAll -win $_nTrace1
srcSelect -signal "push" -line 864 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "push" -line 864 -pos 1 -win $_nTrace1
srcAction -pos 863 2 2 -win $_nTrace1 -name "push" -ctrlKey off
srcHBSelect "tb_top" -win $_nTrace1
srcSetScope "tb_top" -delim "." -win $_nTrace1
srcHBSelect "tb_top" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -win $_nTrace1 -signal "bus_if_inst.pndng" -line 143 -pos 1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -win $_nTrace1 -signal "bus_if_inst.pop" -line 145 -pos 1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvUnknownSaveResult -win $_nWave2 -clear
srcDeselectAll -win $_nTrace1
srcSelect -win $_nTrace1 -signal "bus_if_inst.pop" -line 145 -pos 1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcHBSelect "tb_top.dut" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcHBSelect "tb_top" -win $_nTrace1
srcSetScope "tb_top" -delim "." -win $_nTrace1
srcHBSelect "tb_top" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -win $_nTrace1 -signal "bus_if_inst.pop" -line 145 -pos 1
srcAction -pos 144 4 10 -win $_nTrace1 -name "bus_if_inst.pop" -ctrlKey off
srcHBSelect "tb_top" -win $_nTrace1
srcHBSelect "tb_top" -win $_nTrace1
srcHBSelect "tb_top.dut" -win $_nTrace1
srcHBDrag -win $_nTrace1
srcHBSelect "tb_top.bus_if_inst" -win $_nTrace1
srcSetScope "tb_top.bus_if_inst" -delim "." -win $_nTrace1
srcHBSelect "tb_top.bus_if_inst" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pop" -line 44 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvUnknownSaveResult -win $_nWave2 -clear
srcHBSelect "tb_top.dut" -win $_nTrace1
srcHBSelect "tb_top.dut" -win $_nTrace1
srcHBSelect "tb_top.dut" -win $_nTrace1
srcSetScope "tb_top.dut" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pop" -line 843 -pos 1 -win $_nTrace1
srcAction -pos 842 3 1 -win $_nTrace1 -name "pop" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "pop" -line 266 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\]" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pop" -line 843 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pop" -line 843 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pop" -line 843 -pos 1 -win $_nTrace1
srcAction -pos 842 3 0 -win $_nTrace1 -name "pop" -ctrlKey off
srcHBSelect "tb_top.dut.BUS\[0\].ID\[1\].ntrfs" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[1\].ntrfs" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\].ID\[1\].ntrfs" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[1\].ntrfs" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pop" -line 777 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcHBSelect "tb_top.dut.BUS\[0\].ID\[2\]" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[2\]" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\].ID\[2\]" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[2\]" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pop\[b\]\[i\]" -line 865 -pos 1 -win $_nTrace1
srcAction -pos 864 4 1 -win $_nTrace1 -name "pop\[b\]\[i\]" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "pop" -line 266 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pop" -line 266 -pos 1 -win $_nTrace1
srcAction -pos 265 1 0 -win $_nTrace1 -name "pop" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "pop" -line 266 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcHBSelect "tb_top.dut.BUS\[0\].ID\[3\].ntrfs" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\].ID\[3\].ntrfs" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[3\].ntrfs" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pop" -line 777 -pos 1 -win $_nTrace1
srcAction -pos 776 3 1 -win $_nTrace1 -name "pop" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "pop" -line 266 -pos 1 -win $_nTrace1
srcAction -pos 265 1 2 -win $_nTrace1 -name "pop" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "pop" -line 266 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pop" -line 266 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\]" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcSelect -signal "bs_bsy" -line 848 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "bs_bsy" -line 848 -pos 1 -win $_nTrace1
srcAction -pos 847 3 4 -win $_nTrace1 -name "bs_bsy" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "b" -line 17 -pos 1 -win $_nTrace1
srcAction -pos 16 3 0 -win $_nTrace1 -name "b" -ctrlKey off
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs.cntrl.bs_bsy_tri_buf" -win \
           $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\].ID\[0\].ntrfs.cntrl.bs_bsy_tri_buf" -delim "." \
           -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs.cntrl.bs_bsy_tri_buf" -win \
           $_nTrace1
srcDeselectAll -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs.cntrl.bs_bsy_tri_buf" -win \
           $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs.cntrl.bs_bsy_tri_buf" -win \
           $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\].ID\[0\].ntrfs.cntrl.bs_bsy_tri_buf" -delim "." \
           -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs.cntrl.bs_bsy_tri_buf" -win \
           $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "b" -line 17 -pos 1 -win $_nTrace1
srcSelect -toggle -signal "b" -line 17 -pos 1 -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "b" -line 17 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 11)}
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs.cntrl.bs_bsy_tri_buf" -win \
           $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs.cntrl" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "bs_bsy" -line 779 -pos 1 -win $_nTrace1
srcSelect -toggle -signal "bs_bsy" -line 779 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "bs_bsy" -line 779 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
wvSelectSignal -win $_nWave2 {( "G1" 7 8 9 10 11 12 )} 
wvSelectGroup -win $_nWave2 {G2}
wvSelectSignal -win $_nWave2 {( "G1" 7 )} 
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 12)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 12)}
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 5
wvScrollDown -win $_nWave2 2
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 5
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs.cntrl.arb_cntr" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\].ID\[0\].ntrfs.cntrl.arb_cntr" -delim "." -win \
           $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs.cntrl.arb_cntr" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -word -line 511 -pos 2 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "count" -line 513 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvSelectSignal -win $_nWave2 {( "G1" 9 )} 
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\]" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "D_pop" -line 844 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "D_pop" -line 844 -pos 1 -win $_nTrace1
srcAction -pos 843 11 3 -win $_nTrace1 -name "D_pop" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "D_pop" -line 844 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "D_pop" -line 844 -pos 1 -win $_nTrace1
srcAction -pos 843 11 2 -win $_nTrace1 -name "D_pop" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "D_pop" -line 844 -pos 1 -win $_nTrace1
srcAction -pos 843 11 3 -win $_nTrace1 -name "D_pop" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "D_pop" -line 844 -pos 1 -win $_nTrace1
srcAction -pos 843 11 3 -win $_nTrace1 -name "D_pop" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "D_pop" -line 844 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "D_pop" -line 844 -pos 1 -win $_nTrace1
srcAction -pos 843 11 3 -win $_nTrace1 -name "D_pop" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "D_pop" -line 844 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "D_pop" -line 844 -pos 1 -win $_nTrace1
srcAction -pos 843 11 3 -win $_nTrace1 -name "D_pop" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "D_pop" -line 844 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "D_pop" -line 844 -pos 1 -win $_nTrace1
srcAction -pos 843 11 3 -win $_nTrace1 -name "D_pop" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "D_pop" -line 844 -pos 1 -win $_nTrace1
srcHBSelect "tb_top.dut" -win $_nTrace1
srcSetScope "tb_top.dut" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs.cntrl" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "push" -line 776 -pos 1 -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\]" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\].ID\[0\]" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\]" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pndng\[b\]\[i\]" -line 861 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pop" -line 843 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvUnknownSaveResult -win $_nWave2 -clear
srcHBSelect "tb_top" -win $_nTrace1
srcSetScope "tb_top" -delim "." -win $_nTrace1
srcHBSelect "tb_top" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -word -line 34 -pos 3 -win $_nTrace1
srcAction -pos 34 3 6 -win $_nTrace1 -name "\"monitor.sv\"" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcAction -pos 64 4 5 -win $_nTrace1 -name "vif.pop\[0\]\[i\]" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcAction -pos 64 4 5 -win $_nTrace1 -name "vif.pop\[0\]\[i\]" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcAction -pos 64 4 6 -win $_nTrace1 -name "vif.pop\[0\]\[i\]" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcAction -pos 32 0 4 -win $_nTrace1 -name "class" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcAction -pos 32 0 4 -win $_nTrace1 -name "class" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSelectSignal -win $_nWave2 {( "G1" 3 9 )} 
wvSelectSignal -win $_nWave2 {( "G1" 3 4 9 )} 
wvSelectSignal -win $_nWave2 {( "G1" 3 4 5 9 )} 
wvSelectSignal -win $_nWave2 {( "G1" 3 4 5 6 9 )} 
wvSetPosition -win $_nWave2 {("G1" 13)}
wvSetPosition -win $_nWave2 {("G1" 13)}
wvSetPosition -win $_nWave2 {("G3" 0)}
wvAddGroup -win $_nWave2 {G3}
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvSelectSignal -win $_nWave2 {( "G1" 3 )} 
wvSelectSignal -win $_nWave2 {( "G1" 4 )} 
wvScrollUp -win $_nWave2 2
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 8
wvSelectSignal -win $_nWave2 {( "G1" 13 )} 
wvSelectGroup -win $_nWave2 {G3}
wvSelectGroup -win $_nWave2 {G2}
wvSelectGroup -win $_nWave2 {G3}
wvSelectSignal -win $_nWave2 {( "G1" 13 )} 
wvSelectGroup -win $_nWave2 {G3}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 13)}
wvScrollUp -win $_nWave2 3
wvSelectSignal -win $_nWave2 {( "G1" 7 )} 
wvSelectSignal -win $_nWave2 {( "G1" 7 8 )} 
wvSelectSignal -win $_nWave2 {( "G1" 7 8 9 )} 
wvSelectSignal -win $_nWave2 {( "G1" 7 8 9 10 )} 
wvSetPosition -win $_nWave2 {("G1" 13)}
wvSetPosition -win $_nWave2 {("G1" 13)}
wvSetPosition -win $_nWave2 {("G3" 0)}
wvAddGroup -win $_nWave2 {G3}
wvScrollDown -win $_nWave2 0
wvSelectGroup -win $_nWave2 {G3}
wvSelectGroup -win $_nWave2 {G2}
wvScrollUp -win $_nWave2 9
wvCollapseGroup -win $_nWave2 "G1"
wvSelectGroup -win $_nWave2 {G2}
wvSelectGroup -win $_nWave2 {G3}
wvSelectGroup -win $_nWave2 {G3}
wvSelectGroup -win $_nWave2 {G2}
wvSelectGroup -win $_nWave2 {G3}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 13)}
wvSelectGroup -win $_nWave2 {G2}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 13)}
wvSetPosition -win $_nWave2 {("G1" 13)}
wvSelectGroup -win $_nWave2 {G2}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 13)}
wvSetPosition -win $_nWave2 {("G1" 13)}
wvSelectGroup -win $_nWave2 {G2}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 13)}
wvSetPosition -win $_nWave2 {("G1" 13)}
wvSelectGroup -win $_nWave2 {G2}
wvSelectGroup -win $_nWave2 {G1}
wvSelectGroup -win $_nWave2 {G1}
wvSelectGroup -win $_nWave2 {G1}
wvSelectGroup -win $_nWave2 {G1}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvCollapseGroup -win $_nWave2 "G1"
wvSelectGroup -win $_nWave2 {G1}
wvSelectGroup -win $_nWave2 {G2}
wvSelectGroup -win $_nWave2 {G2}
wvSelectGroup -win $_nWave2 {G1}
wvSelectGroup -win $_nWave2 {G1}
wvSetCursor -win $_nWave2 47.109564 -snap {("G1" 3)}
wvSetCursor -win $_nWave2 84.797216 -snap {("G1" 4)}
wvZoom -win $_nWave2 86.143203 123.830854
wvZoom -win $_nWave2 107.881132 112.704637
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
debExit
