# atoz
Amazon Web Services (AWS) APIs in Nim

## Supported APIs

[369 AWS APIs are supported.](https://github.com/disruptek/atoz/tree/master/src/atoz)

## Example

Your import statement names the APIs you want to use and the versions of same,
ie. release dates without any hyphens.

For signing purposes, set your `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and
`AWS_REGION` environmental variables.

```nim
import asyncdispatch
import httpclient
import httpcore

import atoz/sqs_20121105 # ie. SQS release version 2012-11-05
import atoz/sns_20100331 # ie. SNS release version 2010-03-31

let
  # the call() gets arguments you might expect; they have sensible
  # defaults depending upon the call, the API, whether they are
  # required, what their types are, whether we can infer a default...
  myQueues = getListQueues.call(QueueNamePrefix="production_")
for response in myQueues.retried(tries=3):
  if response.code.is2xx:
    echo waitfor response.body
    break

let
  # you can usually override the API version, even to use a later
  # version than the one you imported.  but, y'know, why would you?
  myTopics = getListTopics.call(Version="1969-12-31")
  response = waitfor myTopics.retry(tries=3)
if response.code.is2xx:
  echo waitfor response.body
```

## Building

Requires [Elle](https://github.com/disruptek/elle) and a checkout of the
[openapi-directory](https://github.com/APIs-guru/openapi-directory).

```bash
cd generator
elle build.lisp            # yaml→json, then json→nim
elle build.lisp yaml       # yaml→json only
elle build.lisp nim        # json→nim only
elle build.lisp nim sqs    # single service
```

## Details

This project is based upon:

- OpenAPI Code Generator https://github.com/disruptek/openapi
- Amazon Web Services Signature Version 4 https://github.com/disruptek/sigv4

## License

MIT
