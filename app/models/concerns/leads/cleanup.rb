module Leads
  class Cleanup
    attr_accessor :debug

    def call
      log('*** Running Lead Data Cleanup')
      cleanup_referrals
    end

    private

    def cleanup_referrals
      log('=> Cleaning up Lead Referrals')

      Lead.where(referral: ['Abodo']).update_all(referral: 'Abodo.com')
      Lead.where(referral: ['ApartmentList.com','Apartmentlist.com']).update_all(referral: 'ApartmentList.com')
      Lead.where(referral: ['Apartmentguide.com']).update_all(referral: 'ApartmentGuide.com')
      Lead.where(referral: ['Apartments.com','Apartments.com and Apartmentfinder', 'Apartments.com/ForRent']).update_all(referral: 'Apartments.com')
      Lead.where(referral: ['craigslist', 'Craigslist', 'Craigslist.com']).update_all(referral: 'CraigsList.com')
      Lead.where(referral: ['facebook', 'facebook.com', 'Facebook', 'FaceBook.com']).update_all(referral: 'Facebook.com')
      Lead.where(referral: ['Hotpads', 'HotPads.com']).update_all(referral: 'Hotpads.com')
      Lead.where(referral: ['Google Search']).update_all(referral: 'Google.com')
      Lead.where(referral: ['Rent.com & ApartmentGuide']).update_all(referral: 'Rent.com')
      Lead.where(referral: ['Rentpath.com']).update_all(referral: 'RentPath.com')
      Lead.where(referral: ['Zillow']).update_all(referral: 'Zillow.com')
      Lead.where(referral: ['Zillow']).update_all(referral: 'Zillow.com')
    end

    def log(message)
      puts message if @debug
      Rails.logger.warn message
    end
  end
end
