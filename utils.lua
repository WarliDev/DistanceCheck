utils = {}
_G.utils = utils


utils.split = function (str)
  ret = {}
  ret.length = 0
  for s in string.gmatch(str, "%S+") do
    ret[ret.length] = s
    ret.length = ret.length + 1
  end
  return ret
end
