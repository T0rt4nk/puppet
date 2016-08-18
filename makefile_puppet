module = .puppetlabs/etc/code/environments/production/modules/tortank

run:
	puppet master --no-daemonize

init:
	rm -f $(module)
	puppet module build tortank
	puppet module install tortank/pkg/rulz-tortank-0.1.0.tar.gz
	rm -rf $(module)
	cd $$(dirname $(module)) && ln -s ../../../../../../tortank
