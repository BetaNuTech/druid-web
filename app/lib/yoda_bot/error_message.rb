module YodaBot
  # The text of one #bluesky-errors post, in the voice of Yoda. Built by
  # YodaBot::ErrorNotifier and posted by YodaBotErrorJob.
  class ErrorMessage
    OPENINGS = [
      "Disturbance in the Force, I sense.",
      "Hmm. Wrong, something has gone.",
      "Failed, the code has. Clouded, the Force is.",
      "Do or do not. Did not, this code did.",
      "Fear leads to anger. Anger leads to hate. Hate leads to errors.",
      "Strong with the bugs, this one is.",
      "Much to learn, this code still has.",
      "Difficult to see. Always in motion, the stack trace is."
    ].freeze

    def initialize(error_class:, message:, location: nil, origin: nil, data: nil, host: nil)
      @error_class = error_class
      @message = message
      @location = location
      @origin = origin
      @data = data
      @host = host
    end

    def text(suppressed = 0)
      lines = []
      lines << "*#{OPENINGS.sample}*"

      where = @origin.present? ? " in `#{escape(@origin)}`" : ""
      lines << "`#{escape(@error_class)}`#{where}, there is."
      lines << "```#{code_block(@message)}```" if @message.present?
      lines << "Born at `#{escape(@location)}`, this error was." if @location.present?
      lines << "Carried, this data was: _#{escape(@data)}_" if @data.present?

      if suppressed.to_i > 0
        times = suppressed == 1 ? "time" : "times"
        lines << "Seen #{suppressed} more #{times} since last I spoke, it was. Silent, I stayed."
      end

      lines << "From #{escape(@host)}, this comes." if @host.present?

      lines.join("\n")
    end

    private

    # Slack's control characters; escaping them is what stops an exception
    # message from rendering as <!channel> or a <@user> mention.
    def escape(text)
      text.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
    end

    # A ``` inside the message would close the code block early.
    def code_block(text)
      escape(text).gsub('```', "'''")
    end
  end
end
