json.array!(@aardvarks) do |aardvark|
  json.extract! aardvark, 
  json.url aardvark_url(aardvark, format: :json)
end
