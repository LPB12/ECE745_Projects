make     cli GEN_TRANS_TYPE=i2cmb_test
make run_cli GEN_TRANS_TYPE=test_i2cmb_reg_addrs 
make run_cli GEN_TRANS_TYPE=test_i2cmb_reg_defaults 
make run_cli GEN_TRANS_TYPE=test_i2cmb_reg_faultaddrs 
make run_cli GEN_TRANS_TYPE=test_i2cmb_reg_transactions 
make run_cli GEN_TRANS_TYPE=test_i2cmb_reg_writeouts 
make run_cli GEN_TRANS_TYPE=test_i2cmbFSM_before 
make run_cli GEN_TRANS_TYPE=test_i2cmbFSM_starts 
make run_cli GEN_TRANS_TYPE=test_i2cmbFSM_stops 
make run_cli GEN_TRANS_TYPE=test_i2cmbFSM_writefirst 
make run_cli GEN_TRANS_TYPE=test_i2cmbFSM_bus_ranges 
make run_cli GEN_TRANS_TYPE=test_i2cmb_random TEST_SEED=47609
make merge_coverage
