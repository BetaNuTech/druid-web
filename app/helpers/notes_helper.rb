module NotesHelper
  def note_content(note)
    if note.classification == 'comment'
      return note.content
    else
      return ( note.content || '' )[0..200]
    end
  end

  def note_glyph(note)
    glyph_name = case note.classification
                 when 'comment'
                   :pushpin
                 when 'system'
                   :info_sign
                 when 'external'
                   :cloud
                 when 'error'
                   :warning_sign
                 else
                  :pencil
                 end

    glyph(glyph_name)
  end
end
