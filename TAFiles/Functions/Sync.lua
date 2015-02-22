function sync(object,type)
  if tMode.sync.amount > 0 then 
    object.type = type
    rednet.send(
      tMode.sync.ids,
      "Sync edit",
      object
    )
  end
end