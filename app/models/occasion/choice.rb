Occasion::Choice = Data.define(:occasion, :still_to_choose, :everyone) do
  def chosen_count
    everyone.size - still_to_choose.size
  end

  def progress?
    everyone.size > 1
  end
end
