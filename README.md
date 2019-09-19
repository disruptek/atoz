# atoz
Amazon Web Services (AWS) APIs in Nim

## Supported APIs

[Sadly, only the 206 most popular AWS APIs are supported at this time.](https://github.com/disruptek/atoz/tree/master/src/atoz) :cry:

## Example

Your import statement names the APIs you want to use and the versions of same,
ie. release dates without any hyphens.

For signing purposes, set your `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and
`AWS_REGION` environmental variables.

```nim
import asyncdispatch
import httpclient
import httpcore

import atoz/sqs_20121105
import atoz/sns_20100331

let myQueues = getListQueues.call()
for response in myQueues.retried(tries=3):
  if response.code.is2xx:
    echo waitfor response.body
    break

let
  myTopics = getListTopics.call()
  response = waitfor myTopics.retry(tries=3)
if response.code.is2xx:
  echo waitfor response.body
```

## Details

This project is based almost entirely upon the following:

- OpenAPI Code Generator https://github.com/disruptek/openapi
- Amazon Web Services Signature Version 4 https://github.com/disruptek/sigv4

Patches welcome!

## License

MIT
