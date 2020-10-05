namespace :marketing_expenses do

  desc 'Create Pending Marketing Expenses'
  task create_pending: :environment do
    message = '*** Creating Scheduled Marketing Expenses'
    puts message
    Rails.logger.warn message
    MarketingSource.all.each do |source|
      next unless source.property&.active?
      expense = source.create_pending_expense
      if expense.valid?
        message = "=== Created MarketingExpense -- #{source.property.name}:#{source.name} => #{expense.description}: #{expense.fee_total} (#{expense.start_date})"
        puts message
        Rails.logger.warn message
        Note.create(
          notable_id: expense.property.id,
          notable_type: 'Property',
          content: message,
          created_at: DateTime.now,
          classification: 'system'
        )
      end
    end

  end
end
