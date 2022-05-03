module Users
  class MassDeactivator
    USER_LIST_0503 = [
      'aberry@bluestone-prop.com', 'mglass@bluestone-prop.com', 'mgoodwin@bluestone-prop.com', 'wpardue@bluestone-prop.com', 'cridgway@bluestone-prop.com', 'jbailey@bluestone-prop.com', 'ahahn@bluestone-prop.com', 'cmagee@bluestone-prop.com', 'dcross@bluestone-prop.com', 'drodriguez@bluestone-prop.com', 'dbailey@bluestone-prop.com', 'jgoss@bluestone-prop.com', 'apatrick@bluestone-prop.com', 'jransom@bluestone-prop.com', 'avanic@bluestone-prop.com', 'jscheivelhud@bluestone-prop.com', 'gbaker@bluestone-prop.com', 'abell@bluestone-prop.com', 'ccreamer@bluestone-prop.com', 'mfreire@bluestone-prop.com', 'lmyers@bluestone-prop.com', 'mwatson@bluestone-prop.com', 'rwilson@bluestone-prop.com', 'alcarballo@bluestone-prop.com', 'sdavis@bluestone-prop.com', 'aregalado@bluestone-prop.com', 'lizaguirre@bluestone-prop.com', 'ameyer@bluestone-prop.com', 'crosado@bluestone-prop.com', 'snaules@bluestone-prop.com', 'oarizpe@bluestone-prop.com', 'kbacon@bluestone-prop.com', 'nbushey@bluestone-prop.com', 'dlassiter@bluestone-prop.com', 'npatton@bluestone-prop.com', 'brebollar@bluestone-prop.com', 'javiles@bluestone-prop.com', 'cconner@bluestone-prop.com', 'ejimmerson@bluestone-prop.com', 'acastro@bluestone-prop.com', 'nvillalva@bluestone-prop.com', 'tday@bluestone-prop.com', 'sfloyd@bluestone-prop.com', 'jgonzalez@bluestone-prop.com', 'akarns@bluestone-prop.com', 'troush@bluestone-prop.com', 'ksoutherland@bluestone-prop.com', 'jtopping@bluestone-prop.com', 'ovaden@bluestone-prop.com', 'sclontz@bluestone-prop.com', 'slane@bluestone-prop.com', 'amiles@bluestone-prop.com', 'sowens@bluestone-prop.com', 'lhowell@bluestone-prop.com', 'acamden@bluestone-prop.com', 'rdunn@bluestone-prop.com', 'ahodgens@bluestone-prop.com', 'machellem@bluestone-prop.com', 'cmoore@bluestone-prop.com', 'jmoulder@bluestone-prop.com', 'preed@bluestone-prop.com', 'ashokunbi@bluestone-prop.com', 'sstafford@bluestone-prop.com', 'jblankenbaker@bluestone-prop.com', 'kfranzman@bluestone-prop.com', 'mmcclure@bluestone-prop.com', 'kphillips@bluestone-prop.com', 'cadams@bluestone-prop.com', 'ygreen@bluestone-prop.com', 'mjohnson@bluestone-prop.com', 'jmccray@bluestone-prop.com', 'jpeace@bluestone-prop.com', 'tporter@bluestone-prop.com', 'fsnelson@bluestone-prop.com', 'nrobbs@bluestone-prop.com', 'ccooksey@bluestone-prop.com', 'tgraves@bluestone-prop.com', 'bmonroe@bluestone-prop.com', 'rpullen@bluestone-prop.com', 'smarvel@bluestone-prop.com', 'dbowman@bluestone-prop.com', 'rgudiel@bluestone-prop.com', 'joshuah@bluestone-prop.com', 'djenkins@bluestone-prop.com', 'towens@bluestone-prop.com', 'aprate@bluestone-prop.com', 'jcallis@bluestone-prop.com', 'kavery@bluestone-prop.com', 'kdains@bluestone-prop.com', 'jmayfield@bluestone-prop.com', 'kmosley@bluestone-prop.com', 'twilliams@bluestone-prop.com', 'milwilson@bluestone-prop.com', 'twilliams@bluestone-prop.com', 'vbyes@bluestone-prop.com', 'gcombs@bluestone-proop.com', 'shedge@bluestone-prop.com', 'rjackson@bluestone-prop.com', 'klibka@bluestone-prop.com', 'jrobey@bluestone-prop.com', 'callen@bluestone-prop.com', 'jdean@bluestone-prop.com', 'gfangman@bluestone-prop.com', 'jhendley@bluestone-prop.com', 'sjackson@bluestone-prop.com', 'hkoschka@bluestone-prop.com', 'esims@bluestone-prop.com', 'mbartee@bluestone-prop.com', 'jfletcher@bluestone-prop.com', 'jwiessner@bluestone-prop.com', 'kcummings@bluestone-prop.com', 'cjackson@bluestone-prop.com', 'ssierra@bluestone-prop.com', 'avaldez@bluestone-prop.com', 'klukefahr@bluestone-prop.com', 'sreynolds@bluestone-prop.com', 'dshular@bluestone-prop.com', 'jwilliams@bluestone-prop.com', 'fbracero@bluestone-prop.com', 'cdelafuente@bluestone-prop.com', 'alopez@bluestone-prop.com', 'alexm@bluestone-prop.com', 'cpargas@bluestone-prop.com', 'malcolmb@bluestone-prop.com', 'thayden@bluestone-prop.com', 'kholmes@bluestone-prop.com', 'sphillips@bluestone-prop.com', 'rvazquez@bluestone-prop.com', 'mwebb@bluestone-prop.com', 'lyoung@bluestone-prop.com', 'lallen@bluestone-prop.com', 'jharrison@bluestone-prop.com', 'clee@bluestone-prop.com', 'hperry@bluestone-prop.com', 'mtodd@bluestone-prop.com', 'tyoung@bluestone-prop.com', 'shaller@bluestone-prop.com', 'wharrington@bluestone-prop.com', 'rking@bluestone-prop.com', 'rpaul@bluestone-prop.com', 'areiniche@bluestone-prop.com', 'alinton@bluestone-prop.com', 'jstafford@bluestone-prop.com', 'hterrell@bluestone-prop.com', 'mward@bluestone-prop.com', 'tbaird@bluestone-prop.com', 'jbrowning@bluestone-prop.com', 'tcarithers@bluestone-prop.com', 'hdurliat@bluestone-prop.com', 'mmoser@bluestone-prop.com', 'kscott@bluestone-prop.com', 'rcandanoza@bluestone-prop.com', 'tclevenger@bluestone-prop.com', 'chaywood@bluestone-prop.com', 'tcannon@bluestone-prop.com', 'eboucher@bluestone-prop.com', 'jcombs@bluestone-prop.com', 'acook@bluestone-prop.com', 'mflermoen@bluestone-prop.com', 'mweiss@bluestone-prop.com', 'dwirt@bluestone-prop.com', 'fbrewer@bluestone-prop.com', 'aharper@bluestone-prop.com', 'msalisbury@bluestone-prop.com', 'aroe@bluestone-prop.com', 'maguilar@bluestone-prop.com', 'dkowalk@bluestone-prop.com'
    ]

    USER_LIST_0530 = [
'mhash@bluestone-prop.com', 'ahayden@bluestone-prop.com', 'ktrumbull@bluestone-prop.com', 'jwebb@bluestone-prop.com', 'dcaldwell@bluestone-prop.com', 'scockrell@bluestone-prop.com', 'mgutierrez@bluestone-prop.com', 'jkakuk@bluestone-prop.com', 'tmoffatt@bluestone-prop.com', 'cmorris@bluestone-prop.com', 'ecopeland@bluestone-prop.com', 'hgallegos@bluestone-prop.com', 'tgilbert@bluestone-prop.com', 'iguerrero@bluestone-prop.com', 'chartgraves@bluestone-prop.com', 'mmesa@bluestone-prop.com', 'nwallace@bluestone-prop.com', 'azuniga@bluestone-prop.com', 'lblair@bluestone-prop.com', 'aharris@bluestone-prop.com', 'edorwart@bluestone-prop.com', 'ehayden@bluestone-prop.com', 'jhopson@bluestone-prop.com', 'njewell@bluestone-prop.com', 'acarballo@bluestone-prop.com', 'cbaker@bluestone-prop.com', 'hcaldwell@bluestone-prop.com', 'sdickens@bluestone-prop.com'
    ]

		def initialize(debug: false)
			@debug = debug ? true : ENV.fetch('DEBUG', 'false').upcase == 'TRUE'
		end

    def call
			deactivate_for_0503
			deactivate_for_0530
    end

		def debug?
			@debug
		end

		def undo
			users = User.where(deactivated: true, email: USER_LIST_0503 + USER_LIST_0530)
			puts "*** Re-Activating Users"
			User.transaction do
				users.each do |user|
					reactivate_user(user)
					puts user_status(user)
				end
			end
		end

    private

		def deactivate_for_0503
			users = User.active.where(email: USER_LIST_0503)
			puts "*** Deactivating #{users.count} users for 5/3/22"
			if !debug? && Time.current < Time.new(2022,5,3)
				puts "!!!ABORT!!!! TOO EARLY!"
        return false
			end
			User.transaction do
				users.each do |user|
					deactivate_user(user)
					puts user_status(user)
				end
			end
			puts "--- Done."
		end

		def deactivate_for_0530
			users = User.active.where(email: USER_LIST_0530)
			puts "*** Deactivating #{users.count} users for 5/30/22"
			if !debug? && Time.current < Time.new(2022,5,30)
				puts "!!!ABORT!!!! TOO EARLY!"
        return false
			end
			User.transaction do
				users.each do |user|
					deactivate_user(user)
					puts user_status(user)
				end
			end
			puts "--- Done."
		end

    def deactivate_user(user)
			user.deactivated = true
			user.save!
    end

    def reactivate_user(user)
			user.deactivated = false
			user.save!
    end

		def user_status(user)
			" * #{user.email} => #{user.deactivated? ? 'INACTIVE' : 'ACTIVE'}"
		end

  end
end
