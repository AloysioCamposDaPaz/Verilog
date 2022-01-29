onerror {resume}
quietly virtual signal -install /tb_waveform_gen {/tb_waveform_gen/tb_sin_out  } tb_sin_out_11_0
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Clock and Reset}
add wave -noupdate /tb_waveform_gen/tb_clk
add wave -noupdate /tb_waveform_gen/tb_reset
add wave -noupdate -divider Enable
add wave -noupdate /tb_waveform_gen/tb_en
add wave -noupdate -divider {Phase Increment}
add wave -noupdate -radix hexadecimal /tb_waveform_gen/tb_phase_inc
add wave -noupdate -divider {Waveform Outputs}
add wave -noupdate -radix binary /tb_waveform_gen/tb_sin_out
add wave -noupdate /tb_waveform_gen/tb_cos_out
add wave -noupdate /tb_waveform_gen/tb_squ_out
add wave -noupdate /tb_waveform_gen/tb_saw_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {476146 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 235
configure wave -valuecolwidth 210
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
WaveRestoreZoom {480710 ps} {480861 ps}
