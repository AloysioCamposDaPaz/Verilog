onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Clk and Reset}
add wave -noupdate /tb_lfsr_5bit/tb_clk
add wave -noupdate /tb_lfsr_5bit/tb_reset
add wave -noupdate -divider {LFSR Sequence}
add wave -noupdate -radix hexadecimal /tb_lfsr_5bit/tb_rand_sequence
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {32159 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 262
configure wave -valuecolwidth 152
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {304 ps}
