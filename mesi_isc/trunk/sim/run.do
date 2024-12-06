vlog +define+DEBUG mesi_isc_tb.sv


vsim -voptargs=+acc work.mesi_isc_tb -debugDB
add wave /mesi_isc_tb/*
run -all
