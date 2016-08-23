file {'/tmp/example-ip':                                            # resource type file and filename
	ensure  => present,                                               # make sure it exists
	mode    => '0644',                                                # file permissions
	content => hiera('max.password'),  # note the ipaddress_eth0 fact
}
