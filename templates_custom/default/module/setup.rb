def init
  sections T('docstring'), :children, 
  :method_summary, [:item_summary]
end

private

def if_tag(tag, &block)
  if tag
    yield tag
  end
end

def if_tags(tags, &block)
  if tags
    tags.each &block
  end
end
