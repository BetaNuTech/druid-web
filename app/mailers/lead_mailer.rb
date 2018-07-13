class LeadMailer < ActionMailer::Base

  def application_link
    @lead = params[:lead]
    @url = 'https://example.com'
    @subject =  "Please complete your application for #{@lead.property.name}"
    mail(to: @lead.email, subject: @subject)
  end
end
