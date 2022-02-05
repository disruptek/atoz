# atoz generator

This is a messy collection of adhoc scripts that I use to rebuild the the AWS
APIs from the OpenAPI source distribution.

Yes, it should have been a `Makefile` but it evolved from something else
and I just never bothered to clean it up.

You will have to generalize/customize this stuff to your environment; PRs
welcome!

- `atoz.nim` is the openapi generator itself
- `yaml-into-json` takes the openapi spec and converts it to renamed
  json outputs, without modifying mtimes on unchanged outputs
- `json-into-nim` turns novel json inputs into nim source using the generator
