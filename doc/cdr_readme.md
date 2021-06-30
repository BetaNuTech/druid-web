# Notes for Ubuntu 20.x+

Current/secure version of linux have TLSv1 disabled for security reasons. The MySQL CDR database requires TLSv1 for authentication.

If an error similar to the following occurs when accessing the CDR database, continue reading.

```
ActiveRecord::ConnectionNotEstablished: SSL connection error: error:1425F102:SSL routines:ssl_choose_client_version:unsupported protocol
from /home/codeprimate/.rvm/gems/ruby-2.7.3/gems/activerecord-6.1.3.2/lib/active_record/connection_adapters/mysql2_adapter.rb:45:in `rescue in new_client'
Caused by Mysql2::Error::ConnectionError: SSL connection error: error:1425F102:SSL routines:ssl_choose_client_version:unsupported protocol
from /home/codeprimate/.rvm/gems/ruby-2.7.3/gems/mysql2-0.5.3/lib/mysql2/client.rb:90:in `connect'
```

### Resolution

!!! WARNING: the following configuration modification removes security mitigations that prevent your system from using encryption algorithms known as insecure. !!!

* Create a backup of `/etc/ssl/openssl.cnf`
* Edit `/etc/ssl/openssl.cnf`
* Add to the top of the file:

	```
	openssl_conf = default_conf
	```

* Add to the end of the file

```
[ default_conf ]
ssl_conf = ssl_sect

[ssl_sect]
system_default = system_default_sect

[system_default_sect]
MinProtocol = TLSv1
MaxProtocol = None
CipherString = DEFAULT:@SECLEVEL=1
```

This should resolve the connection issue.

