class ActiveRecord::Base
  class << self
    def active_callbacks
      self.__callbacks.map{|c| [c[0], c[1].to_a.map{|cc| cc.filter.to_s}]}
      .inject({}){|memo, obj| memo[obj[0]]=obj[1] if obj[1].present?; memo}
    end
  end
end
