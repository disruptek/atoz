#!/usr/bin/env nim
mode = ScriptMode.Verbose


import strformat
import os except paramStr

# these are inputs to the openapi calls
let
  source = paramStr(2)
  input = paramStr(3)
  output = paramStr(4)
  api = paramStr(5)
  serial = paramStr(6)
  cache = getTempDir() / "openapi-cache." & api & "-" & serial

putEnv "OPENAPIIN", input
putEnv "OPENAPIOUT", output

echo api, " release ", serial

var
  cmd = "nim c --define:openapiOmitAllDocs --maxLoopIterationsVM:100000000 --define:ssl"

cmd = fmt"""{cmd} -d:OPENAPIIN="{input}" -d:OPENAPIOUT="{output}" --nimcache="{cache}""""
exec fmt"""{cmd} -f "{source}""""
exec fmt"""rm -rf "{cache}""""
