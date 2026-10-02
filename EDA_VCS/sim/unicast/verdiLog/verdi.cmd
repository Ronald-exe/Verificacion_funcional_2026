simSetSimulator "-vcssv" -exec "simv" -args "+ntb_random_seed=1010 -ucli"
debImport "-dbdir" "simv.daidir"
debLoadSimResult \
           /mnt/vol_NFS_rh003/Est_Veri_II2026/CASTRO_VELASQUEZ_ERIC_VeriII26/P1/Verificacion_funcional_2026/EDA_VCS/sim/unicast/waves.fsdb
wvCreateWindow
srcSignalView -on
srcHBSelect "tb_top.dut" -win $_nTrace1
srcHBSelect "tb_top.dut" -win $_nTrace1
srcHBSelect "tb_top.dut" -win $_nTrace1
srcSetScope "tb_top.dut" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut" -win $_nTrace1
srcSignalViewSelect "tb_top.dut.pndng\[0:0\]"
srcSignalViewSelect "tb_top.dut.pndng\[0:0\]"
srcSignalViewExpand "tb_top.dut.pndng\[0:0\]"
srcSignalViewExpand "tb_top.dut.pndng\[0\]\[3:0\]"
srcSignalViewSelect "tb_top.dut.pndng\[0:0\]"
srcSignalViewCollapse "tb_top.dut.pndng\[0:0\]"
srcSignalViewSelect "tb_top.dut.pndng\[0:0\]"
wvCreateWindow
wvSetPosition -win $_nWave3 {("G1" 0)}
wvOpenFile -win $_nWave3 \
           {/mnt/vol_NFS_rh003/Est_Veri_II2026/CASTRO_VELASQUEZ_ERIC_VeriII26/P1/Verificacion_funcional_2026/EDA_VCS/sim/unicast/waves.fsdb}
srcSignalViewAddSelectedToWave -win $_nTrace1 -clipboard
wvDrop -win $_nWave3
srcSignalViewSelect "tb_top.dut.pndng\[0:0\]"
srcSignalViewExpand "tb_top.dut.pndng\[0:0\]"
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\]" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\]" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs" -win $_nTrace1
srcSignalViewSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs.pndng"
srcSignalViewSelect "tb_top.dut.BUS\[0\].ID\[0\].ntrfs.pndng"
wvCreateWindow
wvSetPosition -win $_nWave4 {("G1" 0)}
wvOpenFile -win $_nWave4 \
           {/mnt/vol_NFS_rh003/Est_Veri_II2026/CASTRO_VELASQUEZ_ERIC_VeriII26/P1/Verificacion_funcional_2026/EDA_VCS/sim/unicast/waves.fsdb}
srcSignalViewAddSelectedToWave -win $_nTrace1 -clipboard
wvDrop -win $_nWave4
srcHBSelect "tb_top.dut.BUS\[0\].ID\[1\].ntrfs" -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[1\].ntrfs" -win $_nTrace1
srcSetScope "tb_top.dut.BUS\[0\].ID\[1\].ntrfs" -delim "." -win $_nTrace1
srcHBSelect "tb_top.dut.BUS\[0\].ID\[1\].ntrfs" -win $_nTrace1
srcSignalViewSelect "tb_top.dut.BUS\[0\].ID\[1\].ntrfs.pndng"
srcSignalViewSelect "tb_top.dut.BUS\[0\].ID\[1\].ntrfs.pndng"
srcSignalViewAddSelectedToWave -win $_nTrace1 -clipboard
wvDrop -win $_nWave4
srcSignalViewSelect "tb_top.dut.BUS\[0\].ID\[1\].ntrfs.reset" \
           "tb_top.dut.BUS\[0\].ID\[1\].ntrfs.pndng"
wvSelectSignal -win $_nWave4 {( "G1" 1 )} 
wvSelectSignal -win $_nWave4 {( "G1" 1 2 )} 
wvSetPosition -win $_nWave4 {("G1" 0)}
wvCollapseGroup -win $_nWave4 "G1"
wvExpandGroup -win $_nWave4 "G1"
wvCollapseGroup -win $_nWave4 "G1"
wvSelectSignal -win $_nWave4 {( "G1" 2 )} 
wvSetPosition -win $_nWave4 {("G1" 2)}
wvSetPosition -win $_nWave4 {("G2" 0)}
wvMoveSelected -win $_nWave4
wvSetPosition -win $_nWave4 {("G2" 1)}
wvSetPosition -win $_nWave4 {("G2" 1)}
wvCollapseGroup -win $_nWave4 "G1"
wvSelectSignal -win $_nWave4 {( "G2" 1 )} 
wvExpandGroup -win $_nWave4 "G1"
wvSelectSignal -win $_nWave4 {( "G2" 1 )} 
wvCollapseGroup -win $_nWave4 "G1"
wvSelectSignal -win $_nWave4 {( "G2" 1 )} 
srcHBSelect "tb_top.dut.BUS\[0\].ID\[1\].ntrfs" -win $_nTrace1
srcSignalView -off
srcSignalView -on
srcHBSelect "tb_top.bus_if_inst" -win $_nTrace1
srcHBSelect "tb_top.bus_if_inst" -win $_nTrace1
srcSetScope "tb_top.bus_if_inst" -delim "." -win $_nTrace1
srcHBSelect "tb_top.bus_if_inst" -win $_nTrace1
srcSignalViewExpand "tb_top.bus_if_inst.pndng\[0:0\]"
srcSignalViewExpand "tb_top.bus_if_inst.pndng\[0\]\[3:0\]"
srcSignalViewSort -name
srcSignalViewSelect "tb_top.bus_if_inst.drvrs"
srcSignalViewExpand "tb_top.bus_if_inst.pndng\[0:0\]"
srcSignalViewSelect "tb_top.bus_if_inst.pndng\[0\]\[3:0\]"
srcSignalViewSelect "tb_top.bus_if_inst.pndng\[0\]\[3:0\]"
srcSignalViewAddSelectedToWave -win $_nTrace1 -clipboard
wvDrop -win $_nWave4
srcSignalViewSelect "tb_top.bus_if_inst.pndng\[0\]\[3:0\]"
srcSignalViewExpand "tb_top.bus_if_inst.pndng\[0\]\[3:0\]"
srcSignalViewSelect "tb_top.bus_if_inst.pndng\[0\]\[3\]"
srcSignalViewSelect "tb_top.bus_if_inst.pndng\[0\]\[3\]" \
           "tb_top.bus_if_inst.pndng\[0\]\[2\]"
srcSignalViewSelect "tb_top.bus_if_inst.pndng\[0\]\[3\]" \
           "tb_top.bus_if_inst.pndng\[0\]\[2\]" \
           "tb_top.bus_if_inst.pndng\[0\]\[1\]"
srcSignalViewSelect "tb_top.bus_if_inst.pndng\[0\]\[3\]" \
           "tb_top.bus_if_inst.pndng\[0\]\[2\]" \
           "tb_top.bus_if_inst.pndng\[0\]\[1\]" \
           "tb_top.bus_if_inst.pndng\[0\]\[0\]"
srcSignalViewSelect "tb_top.bus_if_inst.pndng\[0\]\[3\]" \
           "tb_top.bus_if_inst.pndng\[0\]\[2\]" \
           "tb_top.bus_if_inst.pndng\[0\]\[1\]" \
           "tb_top.bus_if_inst.pndng\[0\]\[0\]" "tb_top.bus_if_inst.pckg_sz"
srcSignalViewSelect "tb_top.bus_if_inst.pndng\[0\]\[3\]" \
           "tb_top.bus_if_inst.pndng\[0\]\[2\]" \
           "tb_top.bus_if_inst.pndng\[0\]\[1\]" \
           "tb_top.bus_if_inst.pndng\[0\]\[0\]"
srcSignalViewAddSelectedToWave -win $_nTrace1 -clipboard
wvDrop -win $_nWave4
wvUnknownSaveResult -win $_nWave4 -clear
srcHBSelect "tb_top" -win $_nTrace1
srcSetScope "tb_top" -delim "." -win $_nTrace1
srcHBSelect "tb_top" -win $_nTrace1
srcHBSelect "tb_top.bus_if_inst" -win $_nTrace1
srcSetScope "tb_top.bus_if_inst" -delim "." -win $_nTrace1
srcHBSelect "tb_top.bus_if_inst" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcHBSelect "tb_top.dut" -win $_nTrace1
srcHBSelect "tb_top" -win $_nTrace1
srcSetScope "tb_top" -delim "." -win $_nTrace1
srcHBSelect "tb_top" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "pckg_sz" -line 130 -pos 2 -win $_nTrace1
srcAction -pos 129 4 3 -win $_nTrace1 -name "pckg_sz" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "pckg_sz" -line 130 -pos 2 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -win $_nTrace1 -signal "bus_if_inst.pndng" -line 143 -pos 1
srcDeselectAll -win $_nTrace1
srcSelect -win $_nTrace1 -signal "bus_if_inst.pndng" -line 143 -pos 1
srcAction -pos 142 4 8 -win $_nTrace1 -name "bus_if_inst.pndng" -ctrlKey off
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
verdiWindowResize -win $_Verdi_1 "548" "57" "857" "902"
verdiDockWidgetSetCurTab -dock windowDock_nWave_2
wvSelectGroup -win $_nWave2 {G1}
wvSelectGroup -win $_nWave2 {G1}
verdiDockWidgetSetCurTab -dock windowDock_nWave_3
wvSelectGroup -win $_nWave3 {G1}
wvTpfCloseForm -win $_nWave2
wvGetSignalClose -win $_nWave2
wvCloseWindow -win $_nWave2
wvTpfCloseForm -win $_nWave3
wvGetSignalClose -win $_nWave3
wvCloseWindow -win $_nWave3
wvSetCursor -win $_nWave4 8785.026395 -snap {("G3" 0)}
debExit
