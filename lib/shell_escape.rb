class String
  # escape special characters used in most unix shells to use it, for example, with system()
  def shell_escape
    "'" + gsub(/'/) { "'\\''" } + "'"
  end
end
