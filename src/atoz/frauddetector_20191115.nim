
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Fraud Detector
## version: 2019-11-15
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## This is the Amazon Fraud Detector API Reference. This guide is for developers who need detailed information about Amazon Fraud Detector API actions, data types, and errors. For more information about Amazon Fraud Detector features, see the <a href="https://docs.aws.amazon.com/frauddetector/latest/ug/">Amazon Fraud Detector User Guide</a>.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/frauddetector/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "frauddetector.ap-northeast-1.amazonaws.com", "ap-southeast-1": "frauddetector.ap-southeast-1.amazonaws.com", "us-west-2": "frauddetector.us-west-2.amazonaws.com", "eu-west-2": "frauddetector.eu-west-2.amazonaws.com", "ap-northeast-3": "frauddetector.ap-northeast-3.amazonaws.com", "eu-central-1": "frauddetector.eu-central-1.amazonaws.com", "us-east-2": "frauddetector.us-east-2.amazonaws.com", "us-east-1": "frauddetector.us-east-1.amazonaws.com", "cn-northwest-1": "frauddetector.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "frauddetector.ap-south-1.amazonaws.com", "eu-north-1": "frauddetector.eu-north-1.amazonaws.com", "ap-northeast-2": "frauddetector.ap-northeast-2.amazonaws.com", "us-west-1": "frauddetector.us-west-1.amazonaws.com", "us-gov-east-1": "frauddetector.us-gov-east-1.amazonaws.com", "eu-west-3": "frauddetector.eu-west-3.amazonaws.com", "cn-north-1": "frauddetector.cn-north-1.amazonaws.com.cn", "sa-east-1": "frauddetector.sa-east-1.amazonaws.com", "eu-west-1": "frauddetector.eu-west-1.amazonaws.com", "us-gov-west-1": "frauddetector.us-gov-west-1.amazonaws.com", "ap-southeast-2": "frauddetector.ap-southeast-2.amazonaws.com", "ca-central-1": "frauddetector.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "frauddetector.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "frauddetector.ap-southeast-1.amazonaws.com",
      "us-west-2": "frauddetector.us-west-2.amazonaws.com",
      "eu-west-2": "frauddetector.eu-west-2.amazonaws.com",
      "ap-northeast-3": "frauddetector.ap-northeast-3.amazonaws.com",
      "eu-central-1": "frauddetector.eu-central-1.amazonaws.com",
      "us-east-2": "frauddetector.us-east-2.amazonaws.com",
      "us-east-1": "frauddetector.us-east-1.amazonaws.com",
      "cn-northwest-1": "frauddetector.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "frauddetector.ap-south-1.amazonaws.com",
      "eu-north-1": "frauddetector.eu-north-1.amazonaws.com",
      "ap-northeast-2": "frauddetector.ap-northeast-2.amazonaws.com",
      "us-west-1": "frauddetector.us-west-1.amazonaws.com",
      "us-gov-east-1": "frauddetector.us-gov-east-1.amazonaws.com",
      "eu-west-3": "frauddetector.eu-west-3.amazonaws.com",
      "cn-north-1": "frauddetector.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "frauddetector.sa-east-1.amazonaws.com",
      "eu-west-1": "frauddetector.eu-west-1.amazonaws.com",
      "us-gov-west-1": "frauddetector.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "frauddetector.ap-southeast-2.amazonaws.com",
      "ca-central-1": "frauddetector.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "frauddetector"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchCreateVariable_612996 = ref object of OpenApiRestCall_612658
proc url_BatchCreateVariable_612998(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchCreateVariable_612997(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a batch of variables.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613123 = header.getOrDefault("X-Amz-Target")
  valid_613123 = validateParameter(valid_613123, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.BatchCreateVariable"))
  if valid_613123 != nil:
    section.add "X-Amz-Target", valid_613123
  var valid_613124 = header.getOrDefault("X-Amz-Signature")
  valid_613124 = validateParameter(valid_613124, JString, required = false,
                                 default = nil)
  if valid_613124 != nil:
    section.add "X-Amz-Signature", valid_613124
  var valid_613125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Content-Sha256", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Date")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Date", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Credential")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Credential", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Security-Token")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Security-Token", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Algorithm")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Algorithm", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-SignedHeaders", valid_613130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613154: Call_BatchCreateVariable_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a batch of variables.
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_BatchCreateVariable_612996; body: JsonNode): Recallable =
  ## batchCreateVariable
  ## Creates a batch of variables.
  ##   body: JObject (required)
  var body_613226 = newJObject()
  if body != nil:
    body_613226 = body
  result = call_613225.call(nil, nil, nil, nil, body_613226)

var batchCreateVariable* = Call_BatchCreateVariable_612996(
    name: "batchCreateVariable", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.BatchCreateVariable",
    validator: validate_BatchCreateVariable_612997, base: "/",
    url: url_BatchCreateVariable_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetVariable_613265 = ref object of OpenApiRestCall_612658
proc url_BatchGetVariable_613267(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetVariable_613266(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets a batch of variables.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613268 = header.getOrDefault("X-Amz-Target")
  valid_613268 = validateParameter(valid_613268, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.BatchGetVariable"))
  if valid_613268 != nil:
    section.add "X-Amz-Target", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Signature")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Signature", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Content-Sha256", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Date")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Date", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Credential")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Credential", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Security-Token")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Security-Token", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Algorithm")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Algorithm", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-SignedHeaders", valid_613275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613277: Call_BatchGetVariable_613265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a batch of variables.
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_BatchGetVariable_613265; body: JsonNode): Recallable =
  ## batchGetVariable
  ## Gets a batch of variables.
  ##   body: JObject (required)
  var body_613279 = newJObject()
  if body != nil:
    body_613279 = body
  result = call_613278.call(nil, nil, nil, nil, body_613279)

var batchGetVariable* = Call_BatchGetVariable_613265(name: "batchGetVariable",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.BatchGetVariable",
    validator: validate_BatchGetVariable_613266, base: "/",
    url: url_BatchGetVariable_613267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDetectorVersion_613280 = ref object of OpenApiRestCall_612658
proc url_CreateDetectorVersion_613282(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDetectorVersion_613281(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a detector version. The detector version starts in a <code>DRAFT</code> status.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613283 = header.getOrDefault("X-Amz-Target")
  valid_613283 = validateParameter(valid_613283, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.CreateDetectorVersion"))
  if valid_613283 != nil:
    section.add "X-Amz-Target", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Signature")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Signature", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Content-Sha256", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Date")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Date", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Credential")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Credential", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Security-Token")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Security-Token", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Algorithm")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Algorithm", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-SignedHeaders", valid_613290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613292: Call_CreateDetectorVersion_613280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a detector version. The detector version starts in a <code>DRAFT</code> status.
  ## 
  let valid = call_613292.validator(path, query, header, formData, body)
  let scheme = call_613292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613292.url(scheme.get, call_613292.host, call_613292.base,
                         call_613292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613292, url, valid)

proc call*(call_613293: Call_CreateDetectorVersion_613280; body: JsonNode): Recallable =
  ## createDetectorVersion
  ## Creates a detector version. The detector version starts in a <code>DRAFT</code> status.
  ##   body: JObject (required)
  var body_613294 = newJObject()
  if body != nil:
    body_613294 = body
  result = call_613293.call(nil, nil, nil, nil, body_613294)

var createDetectorVersion* = Call_CreateDetectorVersion_613280(
    name: "createDetectorVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.CreateDetectorVersion",
    validator: validate_CreateDetectorVersion_613281, base: "/",
    url: url_CreateDetectorVersion_613282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModelVersion_613295 = ref object of OpenApiRestCall_612658
proc url_CreateModelVersion_613297(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateModelVersion_613296(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Creates a version of the model using the specified model type. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613298 = header.getOrDefault("X-Amz-Target")
  valid_613298 = validateParameter(valid_613298, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.CreateModelVersion"))
  if valid_613298 != nil:
    section.add "X-Amz-Target", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Signature")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Signature", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Content-Sha256", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Date")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Date", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Credential")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Credential", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Security-Token")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Security-Token", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Algorithm")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Algorithm", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-SignedHeaders", valid_613305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613307: Call_CreateModelVersion_613295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of the model using the specified model type. 
  ## 
  let valid = call_613307.validator(path, query, header, formData, body)
  let scheme = call_613307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613307.url(scheme.get, call_613307.host, call_613307.base,
                         call_613307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613307, url, valid)

proc call*(call_613308: Call_CreateModelVersion_613295; body: JsonNode): Recallable =
  ## createModelVersion
  ## Creates a version of the model using the specified model type. 
  ##   body: JObject (required)
  var body_613309 = newJObject()
  if body != nil:
    body_613309 = body
  result = call_613308.call(nil, nil, nil, nil, body_613309)

var createModelVersion* = Call_CreateModelVersion_613295(
    name: "createModelVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.CreateModelVersion",
    validator: validate_CreateModelVersion_613296, base: "/",
    url: url_CreateModelVersion_613297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRule_613310 = ref object of OpenApiRestCall_612658
proc url_CreateRule_613312(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRule_613311(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a rule for use with the specified detector. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613313 = header.getOrDefault("X-Amz-Target")
  valid_613313 = validateParameter(valid_613313, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.CreateRule"))
  if valid_613313 != nil:
    section.add "X-Amz-Target", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Signature")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Signature", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Content-Sha256", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Date")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Date", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Credential")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Credential", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Security-Token")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Security-Token", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Algorithm")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Algorithm", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-SignedHeaders", valid_613320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613322: Call_CreateRule_613310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a rule for use with the specified detector. 
  ## 
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_CreateRule_613310; body: JsonNode): Recallable =
  ## createRule
  ## Creates a rule for use with the specified detector. 
  ##   body: JObject (required)
  var body_613324 = newJObject()
  if body != nil:
    body_613324 = body
  result = call_613323.call(nil, nil, nil, nil, body_613324)

var createRule* = Call_CreateRule_613310(name: "createRule",
                                      meth: HttpMethod.HttpPost,
                                      host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.CreateRule",
                                      validator: validate_CreateRule_613311,
                                      base: "/", url: url_CreateRule_613312,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVariable_613325 = ref object of OpenApiRestCall_612658
proc url_CreateVariable_613327(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateVariable_613326(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a variable.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613328 = header.getOrDefault("X-Amz-Target")
  valid_613328 = validateParameter(valid_613328, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.CreateVariable"))
  if valid_613328 != nil:
    section.add "X-Amz-Target", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Signature")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Signature", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Content-Sha256", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Date")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Date", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Credential")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Credential", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Security-Token")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Security-Token", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Algorithm")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Algorithm", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-SignedHeaders", valid_613335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613337: Call_CreateVariable_613325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a variable.
  ## 
  let valid = call_613337.validator(path, query, header, formData, body)
  let scheme = call_613337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613337.url(scheme.get, call_613337.host, call_613337.base,
                         call_613337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613337, url, valid)

proc call*(call_613338: Call_CreateVariable_613325; body: JsonNode): Recallable =
  ## createVariable
  ## Creates a variable.
  ##   body: JObject (required)
  var body_613339 = newJObject()
  if body != nil:
    body_613339 = body
  result = call_613338.call(nil, nil, nil, nil, body_613339)

var createVariable* = Call_CreateVariable_613325(name: "createVariable",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.CreateVariable",
    validator: validate_CreateVariable_613326, base: "/", url: url_CreateVariable_613327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDetectorVersion_613340 = ref object of OpenApiRestCall_612658
proc url_DeleteDetectorVersion_613342(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDetectorVersion_613341(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the detector version.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613343 = header.getOrDefault("X-Amz-Target")
  valid_613343 = validateParameter(valid_613343, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.DeleteDetectorVersion"))
  if valid_613343 != nil:
    section.add "X-Amz-Target", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Signature")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Signature", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Content-Sha256", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Date")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Date", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Credential")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Credential", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Security-Token")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Security-Token", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Algorithm")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Algorithm", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-SignedHeaders", valid_613350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613352: Call_DeleteDetectorVersion_613340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the detector version.
  ## 
  let valid = call_613352.validator(path, query, header, formData, body)
  let scheme = call_613352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613352.url(scheme.get, call_613352.host, call_613352.base,
                         call_613352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613352, url, valid)

proc call*(call_613353: Call_DeleteDetectorVersion_613340; body: JsonNode): Recallable =
  ## deleteDetectorVersion
  ## Deletes the detector version.
  ##   body: JObject (required)
  var body_613354 = newJObject()
  if body != nil:
    body_613354 = body
  result = call_613353.call(nil, nil, nil, nil, body_613354)

var deleteDetectorVersion* = Call_DeleteDetectorVersion_613340(
    name: "deleteDetectorVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.DeleteDetectorVersion",
    validator: validate_DeleteDetectorVersion_613341, base: "/",
    url: url_DeleteDetectorVersion_613342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEvent_613355 = ref object of OpenApiRestCall_612658
proc url_DeleteEvent_613357(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEvent_613356(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified event.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613358 = header.getOrDefault("X-Amz-Target")
  valid_613358 = validateParameter(valid_613358, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.DeleteEvent"))
  if valid_613358 != nil:
    section.add "X-Amz-Target", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Signature")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Signature", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Content-Sha256", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Date")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Date", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Credential")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Credential", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Security-Token")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Security-Token", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Algorithm")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Algorithm", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-SignedHeaders", valid_613365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613367: Call_DeleteEvent_613355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified event.
  ## 
  let valid = call_613367.validator(path, query, header, formData, body)
  let scheme = call_613367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613367.url(scheme.get, call_613367.host, call_613367.base,
                         call_613367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613367, url, valid)

proc call*(call_613368: Call_DeleteEvent_613355; body: JsonNode): Recallable =
  ## deleteEvent
  ## Deletes the specified event.
  ##   body: JObject (required)
  var body_613369 = newJObject()
  if body != nil:
    body_613369 = body
  result = call_613368.call(nil, nil, nil, nil, body_613369)

var deleteEvent* = Call_DeleteEvent_613355(name: "deleteEvent",
                                        meth: HttpMethod.HttpPost,
                                        host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.DeleteEvent",
                                        validator: validate_DeleteEvent_613356,
                                        base: "/", url: url_DeleteEvent_613357,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDetector_613370 = ref object of OpenApiRestCall_612658
proc url_DescribeDetector_613372(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDetector_613371(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets all versions for a specified detector.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613373 = header.getOrDefault("X-Amz-Target")
  valid_613373 = validateParameter(valid_613373, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.DescribeDetector"))
  if valid_613373 != nil:
    section.add "X-Amz-Target", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Signature")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Signature", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Content-Sha256", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Date")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Date", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Credential")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Credential", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Security-Token")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Security-Token", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Algorithm")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Algorithm", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-SignedHeaders", valid_613380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613382: Call_DescribeDetector_613370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all versions for a specified detector.
  ## 
  let valid = call_613382.validator(path, query, header, formData, body)
  let scheme = call_613382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613382.url(scheme.get, call_613382.host, call_613382.base,
                         call_613382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613382, url, valid)

proc call*(call_613383: Call_DescribeDetector_613370; body: JsonNode): Recallable =
  ## describeDetector
  ## Gets all versions for a specified detector.
  ##   body: JObject (required)
  var body_613384 = newJObject()
  if body != nil:
    body_613384 = body
  result = call_613383.call(nil, nil, nil, nil, body_613384)

var describeDetector* = Call_DescribeDetector_613370(name: "describeDetector",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.DescribeDetector",
    validator: validate_DescribeDetector_613371, base: "/",
    url: url_DescribeDetector_613372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModelVersions_613385 = ref object of OpenApiRestCall_612658
proc url_DescribeModelVersions_613387(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeModelVersions_613386(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets all of the model versions for the specified model type or for the specified model type and model ID. You can also get details for a single, specified model version. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613388 = query.getOrDefault("nextToken")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "nextToken", valid_613388
  var valid_613389 = query.getOrDefault("maxResults")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "maxResults", valid_613389
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613390 = header.getOrDefault("X-Amz-Target")
  valid_613390 = validateParameter(valid_613390, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.DescribeModelVersions"))
  if valid_613390 != nil:
    section.add "X-Amz-Target", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Signature")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Signature", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Content-Sha256", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Date")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Date", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Credential")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Credential", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-Security-Token")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-Security-Token", valid_613395
  var valid_613396 = header.getOrDefault("X-Amz-Algorithm")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-Algorithm", valid_613396
  var valid_613397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "X-Amz-SignedHeaders", valid_613397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613399: Call_DescribeModelVersions_613385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all of the model versions for the specified model type or for the specified model type and model ID. You can also get details for a single, specified model version. 
  ## 
  let valid = call_613399.validator(path, query, header, formData, body)
  let scheme = call_613399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613399.url(scheme.get, call_613399.host, call_613399.base,
                         call_613399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613399, url, valid)

proc call*(call_613400: Call_DescribeModelVersions_613385; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeModelVersions
  ## Gets all of the model versions for the specified model type or for the specified model type and model ID. You can also get details for a single, specified model version. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613401 = newJObject()
  var body_613402 = newJObject()
  add(query_613401, "nextToken", newJString(nextToken))
  if body != nil:
    body_613402 = body
  add(query_613401, "maxResults", newJString(maxResults))
  result = call_613400.call(nil, query_613401, nil, nil, body_613402)

var describeModelVersions* = Call_DescribeModelVersions_613385(
    name: "describeModelVersions", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.DescribeModelVersions",
    validator: validate_DescribeModelVersions_613386, base: "/",
    url: url_DescribeModelVersions_613387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetectorVersion_613404 = ref object of OpenApiRestCall_612658
proc url_GetDetectorVersion_613406(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDetectorVersion_613405(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets a particular detector version. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613407 = header.getOrDefault("X-Amz-Target")
  valid_613407 = validateParameter(valid_613407, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetDetectorVersion"))
  if valid_613407 != nil:
    section.add "X-Amz-Target", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Signature")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Signature", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Content-Sha256", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-Date")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-Date", valid_613410
  var valid_613411 = header.getOrDefault("X-Amz-Credential")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "X-Amz-Credential", valid_613411
  var valid_613412 = header.getOrDefault("X-Amz-Security-Token")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-Security-Token", valid_613412
  var valid_613413 = header.getOrDefault("X-Amz-Algorithm")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-Algorithm", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-SignedHeaders", valid_613414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613416: Call_GetDetectorVersion_613404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a particular detector version. 
  ## 
  let valid = call_613416.validator(path, query, header, formData, body)
  let scheme = call_613416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613416.url(scheme.get, call_613416.host, call_613416.base,
                         call_613416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613416, url, valid)

proc call*(call_613417: Call_GetDetectorVersion_613404; body: JsonNode): Recallable =
  ## getDetectorVersion
  ## Gets a particular detector version. 
  ##   body: JObject (required)
  var body_613418 = newJObject()
  if body != nil:
    body_613418 = body
  result = call_613417.call(nil, nil, nil, nil, body_613418)

var getDetectorVersion* = Call_GetDetectorVersion_613404(
    name: "getDetectorVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetDetectorVersion",
    validator: validate_GetDetectorVersion_613405, base: "/",
    url: url_GetDetectorVersion_613406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetectors_613419 = ref object of OpenApiRestCall_612658
proc url_GetDetectors_613421(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDetectors_613420(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets all of detectors. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetEventTypesResponse</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613422 = query.getOrDefault("nextToken")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "nextToken", valid_613422
  var valid_613423 = query.getOrDefault("maxResults")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "maxResults", valid_613423
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613424 = header.getOrDefault("X-Amz-Target")
  valid_613424 = validateParameter(valid_613424, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetDetectors"))
  if valid_613424 != nil:
    section.add "X-Amz-Target", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-Signature")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-Signature", valid_613425
  var valid_613426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "X-Amz-Content-Sha256", valid_613426
  var valid_613427 = header.getOrDefault("X-Amz-Date")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "X-Amz-Date", valid_613427
  var valid_613428 = header.getOrDefault("X-Amz-Credential")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "X-Amz-Credential", valid_613428
  var valid_613429 = header.getOrDefault("X-Amz-Security-Token")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-Security-Token", valid_613429
  var valid_613430 = header.getOrDefault("X-Amz-Algorithm")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-Algorithm", valid_613430
  var valid_613431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-SignedHeaders", valid_613431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613433: Call_GetDetectors_613419; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all of detectors. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetEventTypesResponse</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ## 
  let valid = call_613433.validator(path, query, header, formData, body)
  let scheme = call_613433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613433.url(scheme.get, call_613433.host, call_613433.base,
                         call_613433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613433, url, valid)

proc call*(call_613434: Call_GetDetectors_613419; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getDetectors
  ## Gets all of detectors. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetEventTypesResponse</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613435 = newJObject()
  var body_613436 = newJObject()
  add(query_613435, "nextToken", newJString(nextToken))
  if body != nil:
    body_613436 = body
  add(query_613435, "maxResults", newJString(maxResults))
  result = call_613434.call(nil, query_613435, nil, nil, body_613436)

var getDetectors* = Call_GetDetectors_613419(name: "getDetectors",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetDetectors",
    validator: validate_GetDetectors_613420, base: "/", url: url_GetDetectors_613421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExternalModels_613437 = ref object of OpenApiRestCall_612658
proc url_GetExternalModels_613439(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetExternalModels_613438(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Gets the details for one or more Amazon SageMaker models that have been imported into the service. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetExternalModelsResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613440 = query.getOrDefault("nextToken")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "nextToken", valid_613440
  var valid_613441 = query.getOrDefault("maxResults")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "maxResults", valid_613441
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613442 = header.getOrDefault("X-Amz-Target")
  valid_613442 = validateParameter(valid_613442, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetExternalModels"))
  if valid_613442 != nil:
    section.add "X-Amz-Target", valid_613442
  var valid_613443 = header.getOrDefault("X-Amz-Signature")
  valid_613443 = validateParameter(valid_613443, JString, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "X-Amz-Signature", valid_613443
  var valid_613444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "X-Amz-Content-Sha256", valid_613444
  var valid_613445 = header.getOrDefault("X-Amz-Date")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Date", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-Credential")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Credential", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Security-Token")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Security-Token", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Algorithm")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Algorithm", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-SignedHeaders", valid_613449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613451: Call_GetExternalModels_613437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the details for one or more Amazon SageMaker models that have been imported into the service. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetExternalModelsResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ## 
  let valid = call_613451.validator(path, query, header, formData, body)
  let scheme = call_613451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613451.url(scheme.get, call_613451.host, call_613451.base,
                         call_613451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613451, url, valid)

proc call*(call_613452: Call_GetExternalModels_613437; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getExternalModels
  ## Gets the details for one or more Amazon SageMaker models that have been imported into the service. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetExternalModelsResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613453 = newJObject()
  var body_613454 = newJObject()
  add(query_613453, "nextToken", newJString(nextToken))
  if body != nil:
    body_613454 = body
  add(query_613453, "maxResults", newJString(maxResults))
  result = call_613452.call(nil, query_613453, nil, nil, body_613454)

var getExternalModels* = Call_GetExternalModels_613437(name: "getExternalModels",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetExternalModels",
    validator: validate_GetExternalModels_613438, base: "/",
    url: url_GetExternalModels_613439, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelVersion_613455 = ref object of OpenApiRestCall_612658
proc url_GetModelVersion_613457(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModelVersion_613456(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets a model version. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613458 = header.getOrDefault("X-Amz-Target")
  valid_613458 = validateParameter(valid_613458, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetModelVersion"))
  if valid_613458 != nil:
    section.add "X-Amz-Target", valid_613458
  var valid_613459 = header.getOrDefault("X-Amz-Signature")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "X-Amz-Signature", valid_613459
  var valid_613460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "X-Amz-Content-Sha256", valid_613460
  var valid_613461 = header.getOrDefault("X-Amz-Date")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Date", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-Credential")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Credential", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-Security-Token")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Security-Token", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Algorithm")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Algorithm", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-SignedHeaders", valid_613465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613467: Call_GetModelVersion_613455; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a model version. 
  ## 
  let valid = call_613467.validator(path, query, header, formData, body)
  let scheme = call_613467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613467.url(scheme.get, call_613467.host, call_613467.base,
                         call_613467.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613467, url, valid)

proc call*(call_613468: Call_GetModelVersion_613455; body: JsonNode): Recallable =
  ## getModelVersion
  ## Gets a model version. 
  ##   body: JObject (required)
  var body_613469 = newJObject()
  if body != nil:
    body_613469 = body
  result = call_613468.call(nil, nil, nil, nil, body_613469)

var getModelVersion* = Call_GetModelVersion_613455(name: "getModelVersion",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetModelVersion",
    validator: validate_GetModelVersion_613456, base: "/", url: url_GetModelVersion_613457,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_613470 = ref object of OpenApiRestCall_612658
proc url_GetModels_613472(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModels_613471(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets all of the models for the AWS account, or the specified model type, or gets a single model for the specified model type, model ID combination. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613473 = query.getOrDefault("nextToken")
  valid_613473 = validateParameter(valid_613473, JString, required = false,
                                 default = nil)
  if valid_613473 != nil:
    section.add "nextToken", valid_613473
  var valid_613474 = query.getOrDefault("maxResults")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "maxResults", valid_613474
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613475 = header.getOrDefault("X-Amz-Target")
  valid_613475 = validateParameter(valid_613475, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetModels"))
  if valid_613475 != nil:
    section.add "X-Amz-Target", valid_613475
  var valid_613476 = header.getOrDefault("X-Amz-Signature")
  valid_613476 = validateParameter(valid_613476, JString, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "X-Amz-Signature", valid_613476
  var valid_613477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "X-Amz-Content-Sha256", valid_613477
  var valid_613478 = header.getOrDefault("X-Amz-Date")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-Date", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Credential")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Credential", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Security-Token")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Security-Token", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Algorithm")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Algorithm", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-SignedHeaders", valid_613482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613484: Call_GetModels_613470; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all of the models for the AWS account, or the specified model type, or gets a single model for the specified model type, model ID combination. 
  ## 
  let valid = call_613484.validator(path, query, header, formData, body)
  let scheme = call_613484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613484.url(scheme.get, call_613484.host, call_613484.base,
                         call_613484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613484, url, valid)

proc call*(call_613485: Call_GetModels_613470; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getModels
  ## Gets all of the models for the AWS account, or the specified model type, or gets a single model for the specified model type, model ID combination. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613486 = newJObject()
  var body_613487 = newJObject()
  add(query_613486, "nextToken", newJString(nextToken))
  if body != nil:
    body_613487 = body
  add(query_613486, "maxResults", newJString(maxResults))
  result = call_613485.call(nil, query_613486, nil, nil, body_613487)

var getModels* = Call_GetModels_613470(name: "getModels", meth: HttpMethod.HttpPost,
                                    host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetModels",
                                    validator: validate_GetModels_613471,
                                    base: "/", url: url_GetModels_613472,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOutcomes_613488 = ref object of OpenApiRestCall_612658
proc url_GetOutcomes_613490(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOutcomes_613489(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets one or more outcomes. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 50 and 100. To get the next page results, provide the pagination token from the <code>GetOutcomesResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613491 = query.getOrDefault("nextToken")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "nextToken", valid_613491
  var valid_613492 = query.getOrDefault("maxResults")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "maxResults", valid_613492
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613493 = header.getOrDefault("X-Amz-Target")
  valid_613493 = validateParameter(valid_613493, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetOutcomes"))
  if valid_613493 != nil:
    section.add "X-Amz-Target", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-Signature")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Signature", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Content-Sha256", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Date")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Date", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Credential")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Credential", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Security-Token")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Security-Token", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Algorithm")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Algorithm", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-SignedHeaders", valid_613500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613502: Call_GetOutcomes_613488; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets one or more outcomes. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 50 and 100. To get the next page results, provide the pagination token from the <code>GetOutcomesResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ## 
  let valid = call_613502.validator(path, query, header, formData, body)
  let scheme = call_613502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613502.url(scheme.get, call_613502.host, call_613502.base,
                         call_613502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613502, url, valid)

proc call*(call_613503: Call_GetOutcomes_613488; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getOutcomes
  ## Gets one or more outcomes. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 50 and 100. To get the next page results, provide the pagination token from the <code>GetOutcomesResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613504 = newJObject()
  var body_613505 = newJObject()
  add(query_613504, "nextToken", newJString(nextToken))
  if body != nil:
    body_613505 = body
  add(query_613504, "maxResults", newJString(maxResults))
  result = call_613503.call(nil, query_613504, nil, nil, body_613505)

var getOutcomes* = Call_GetOutcomes_613488(name: "getOutcomes",
                                        meth: HttpMethod.HttpPost,
                                        host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetOutcomes",
                                        validator: validate_GetOutcomes_613489,
                                        base: "/", url: url_GetOutcomes_613490,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPrediction_613506 = ref object of OpenApiRestCall_612658
proc url_GetPrediction_613508(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPrediction_613507(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Evaluates an event against a detector version. If a version ID is not provided, the detector’s (<code>ACTIVE</code>) version is used. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613509 = header.getOrDefault("X-Amz-Target")
  valid_613509 = validateParameter(valid_613509, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetPrediction"))
  if valid_613509 != nil:
    section.add "X-Amz-Target", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Signature")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Signature", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Content-Sha256", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Date")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Date", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Credential")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Credential", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-Security-Token")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Security-Token", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-Algorithm")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-Algorithm", valid_613515
  var valid_613516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-SignedHeaders", valid_613516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613518: Call_GetPrediction_613506; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Evaluates an event against a detector version. If a version ID is not provided, the detector’s (<code>ACTIVE</code>) version is used. 
  ## 
  let valid = call_613518.validator(path, query, header, formData, body)
  let scheme = call_613518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613518.url(scheme.get, call_613518.host, call_613518.base,
                         call_613518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613518, url, valid)

proc call*(call_613519: Call_GetPrediction_613506; body: JsonNode): Recallable =
  ## getPrediction
  ## Evaluates an event against a detector version. If a version ID is not provided, the detector’s (<code>ACTIVE</code>) version is used. 
  ##   body: JObject (required)
  var body_613520 = newJObject()
  if body != nil:
    body_613520 = body
  result = call_613519.call(nil, nil, nil, nil, body_613520)

var getPrediction* = Call_GetPrediction_613506(name: "getPrediction",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetPrediction",
    validator: validate_GetPrediction_613507, base: "/", url: url_GetPrediction_613508,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRules_613521 = ref object of OpenApiRestCall_612658
proc url_GetRules_613523(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRules_613522(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets all rules available for the specified detector.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613524 = query.getOrDefault("nextToken")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "nextToken", valid_613524
  var valid_613525 = query.getOrDefault("maxResults")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "maxResults", valid_613525
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613526 = header.getOrDefault("X-Amz-Target")
  valid_613526 = validateParameter(valid_613526, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetRules"))
  if valid_613526 != nil:
    section.add "X-Amz-Target", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Signature")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Signature", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Content-Sha256", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Date")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Date", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-Credential")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-Credential", valid_613530
  var valid_613531 = header.getOrDefault("X-Amz-Security-Token")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-Security-Token", valid_613531
  var valid_613532 = header.getOrDefault("X-Amz-Algorithm")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-Algorithm", valid_613532
  var valid_613533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613533 = validateParameter(valid_613533, JString, required = false,
                                 default = nil)
  if valid_613533 != nil:
    section.add "X-Amz-SignedHeaders", valid_613533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613535: Call_GetRules_613521; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all rules available for the specified detector.
  ## 
  let valid = call_613535.validator(path, query, header, formData, body)
  let scheme = call_613535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613535.url(scheme.get, call_613535.host, call_613535.base,
                         call_613535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613535, url, valid)

proc call*(call_613536: Call_GetRules_613521; body: JsonNode; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getRules
  ## Gets all rules available for the specified detector.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613537 = newJObject()
  var body_613538 = newJObject()
  add(query_613537, "nextToken", newJString(nextToken))
  if body != nil:
    body_613538 = body
  add(query_613537, "maxResults", newJString(maxResults))
  result = call_613536.call(nil, query_613537, nil, nil, body_613538)

var getRules* = Call_GetRules_613521(name: "getRules", meth: HttpMethod.HttpPost,
                                  host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetRules",
                                  validator: validate_GetRules_613522, base: "/",
                                  url: url_GetRules_613523,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVariables_613539 = ref object of OpenApiRestCall_612658
proc url_GetVariables_613541(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetVariables_613540(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets all of the variables or the specific variable. This is a paginated API. Providing null <code>maxSizePerPage</code> results in retrieving maximum of 100 records per page. If you provide <code>maxSizePerPage</code> the value must be between 50 and 100. To get the next page result, a provide a pagination token from <code>GetVariablesResult</code> as part of your request. Null pagination token fetches the records from the beginning. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613542 = query.getOrDefault("nextToken")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "nextToken", valid_613542
  var valid_613543 = query.getOrDefault("maxResults")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "maxResults", valid_613543
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613544 = header.getOrDefault("X-Amz-Target")
  valid_613544 = validateParameter(valid_613544, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetVariables"))
  if valid_613544 != nil:
    section.add "X-Amz-Target", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-Signature")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-Signature", valid_613545
  var valid_613546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-Content-Sha256", valid_613546
  var valid_613547 = header.getOrDefault("X-Amz-Date")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "X-Amz-Date", valid_613547
  var valid_613548 = header.getOrDefault("X-Amz-Credential")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "X-Amz-Credential", valid_613548
  var valid_613549 = header.getOrDefault("X-Amz-Security-Token")
  valid_613549 = validateParameter(valid_613549, JString, required = false,
                                 default = nil)
  if valid_613549 != nil:
    section.add "X-Amz-Security-Token", valid_613549
  var valid_613550 = header.getOrDefault("X-Amz-Algorithm")
  valid_613550 = validateParameter(valid_613550, JString, required = false,
                                 default = nil)
  if valid_613550 != nil:
    section.add "X-Amz-Algorithm", valid_613550
  var valid_613551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613551 = validateParameter(valid_613551, JString, required = false,
                                 default = nil)
  if valid_613551 != nil:
    section.add "X-Amz-SignedHeaders", valid_613551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613553: Call_GetVariables_613539; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all of the variables or the specific variable. This is a paginated API. Providing null <code>maxSizePerPage</code> results in retrieving maximum of 100 records per page. If you provide <code>maxSizePerPage</code> the value must be between 50 and 100. To get the next page result, a provide a pagination token from <code>GetVariablesResult</code> as part of your request. Null pagination token fetches the records from the beginning. 
  ## 
  let valid = call_613553.validator(path, query, header, formData, body)
  let scheme = call_613553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613553.url(scheme.get, call_613553.host, call_613553.base,
                         call_613553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613553, url, valid)

proc call*(call_613554: Call_GetVariables_613539; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getVariables
  ## Gets all of the variables or the specific variable. This is a paginated API. Providing null <code>maxSizePerPage</code> results in retrieving maximum of 100 records per page. If you provide <code>maxSizePerPage</code> the value must be between 50 and 100. To get the next page result, a provide a pagination token from <code>GetVariablesResult</code> as part of your request. Null pagination token fetches the records from the beginning. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613555 = newJObject()
  var body_613556 = newJObject()
  add(query_613555, "nextToken", newJString(nextToken))
  if body != nil:
    body_613556 = body
  add(query_613555, "maxResults", newJString(maxResults))
  result = call_613554.call(nil, query_613555, nil, nil, body_613556)

var getVariables* = Call_GetVariables_613539(name: "getVariables",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetVariables",
    validator: validate_GetVariables_613540, base: "/", url: url_GetVariables_613541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDetector_613557 = ref object of OpenApiRestCall_612658
proc url_PutDetector_613559(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutDetector_613558(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates or updates a detector. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613560 = header.getOrDefault("X-Amz-Target")
  valid_613560 = validateParameter(valid_613560, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.PutDetector"))
  if valid_613560 != nil:
    section.add "X-Amz-Target", valid_613560
  var valid_613561 = header.getOrDefault("X-Amz-Signature")
  valid_613561 = validateParameter(valid_613561, JString, required = false,
                                 default = nil)
  if valid_613561 != nil:
    section.add "X-Amz-Signature", valid_613561
  var valid_613562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613562 = validateParameter(valid_613562, JString, required = false,
                                 default = nil)
  if valid_613562 != nil:
    section.add "X-Amz-Content-Sha256", valid_613562
  var valid_613563 = header.getOrDefault("X-Amz-Date")
  valid_613563 = validateParameter(valid_613563, JString, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "X-Amz-Date", valid_613563
  var valid_613564 = header.getOrDefault("X-Amz-Credential")
  valid_613564 = validateParameter(valid_613564, JString, required = false,
                                 default = nil)
  if valid_613564 != nil:
    section.add "X-Amz-Credential", valid_613564
  var valid_613565 = header.getOrDefault("X-Amz-Security-Token")
  valid_613565 = validateParameter(valid_613565, JString, required = false,
                                 default = nil)
  if valid_613565 != nil:
    section.add "X-Amz-Security-Token", valid_613565
  var valid_613566 = header.getOrDefault("X-Amz-Algorithm")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "X-Amz-Algorithm", valid_613566
  var valid_613567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "X-Amz-SignedHeaders", valid_613567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613569: Call_PutDetector_613557; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a detector. 
  ## 
  let valid = call_613569.validator(path, query, header, formData, body)
  let scheme = call_613569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613569.url(scheme.get, call_613569.host, call_613569.base,
                         call_613569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613569, url, valid)

proc call*(call_613570: Call_PutDetector_613557; body: JsonNode): Recallable =
  ## putDetector
  ## Creates or updates a detector. 
  ##   body: JObject (required)
  var body_613571 = newJObject()
  if body != nil:
    body_613571 = body
  result = call_613570.call(nil, nil, nil, nil, body_613571)

var putDetector* = Call_PutDetector_613557(name: "putDetector",
                                        meth: HttpMethod.HttpPost,
                                        host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.PutDetector",
                                        validator: validate_PutDetector_613558,
                                        base: "/", url: url_PutDetector_613559,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutExternalModel_613572 = ref object of OpenApiRestCall_612658
proc url_PutExternalModel_613574(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutExternalModel_613573(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates or updates an Amazon SageMaker model endpoint. You can also use this action to update the configuration of the model endpoint, including the IAM role and/or the mapped variables. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613575 = header.getOrDefault("X-Amz-Target")
  valid_613575 = validateParameter(valid_613575, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.PutExternalModel"))
  if valid_613575 != nil:
    section.add "X-Amz-Target", valid_613575
  var valid_613576 = header.getOrDefault("X-Amz-Signature")
  valid_613576 = validateParameter(valid_613576, JString, required = false,
                                 default = nil)
  if valid_613576 != nil:
    section.add "X-Amz-Signature", valid_613576
  var valid_613577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613577 = validateParameter(valid_613577, JString, required = false,
                                 default = nil)
  if valid_613577 != nil:
    section.add "X-Amz-Content-Sha256", valid_613577
  var valid_613578 = header.getOrDefault("X-Amz-Date")
  valid_613578 = validateParameter(valid_613578, JString, required = false,
                                 default = nil)
  if valid_613578 != nil:
    section.add "X-Amz-Date", valid_613578
  var valid_613579 = header.getOrDefault("X-Amz-Credential")
  valid_613579 = validateParameter(valid_613579, JString, required = false,
                                 default = nil)
  if valid_613579 != nil:
    section.add "X-Amz-Credential", valid_613579
  var valid_613580 = header.getOrDefault("X-Amz-Security-Token")
  valid_613580 = validateParameter(valid_613580, JString, required = false,
                                 default = nil)
  if valid_613580 != nil:
    section.add "X-Amz-Security-Token", valid_613580
  var valid_613581 = header.getOrDefault("X-Amz-Algorithm")
  valid_613581 = validateParameter(valid_613581, JString, required = false,
                                 default = nil)
  if valid_613581 != nil:
    section.add "X-Amz-Algorithm", valid_613581
  var valid_613582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613582 = validateParameter(valid_613582, JString, required = false,
                                 default = nil)
  if valid_613582 != nil:
    section.add "X-Amz-SignedHeaders", valid_613582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613584: Call_PutExternalModel_613572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates an Amazon SageMaker model endpoint. You can also use this action to update the configuration of the model endpoint, including the IAM role and/or the mapped variables. 
  ## 
  let valid = call_613584.validator(path, query, header, formData, body)
  let scheme = call_613584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613584.url(scheme.get, call_613584.host, call_613584.base,
                         call_613584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613584, url, valid)

proc call*(call_613585: Call_PutExternalModel_613572; body: JsonNode): Recallable =
  ## putExternalModel
  ## Creates or updates an Amazon SageMaker model endpoint. You can also use this action to update the configuration of the model endpoint, including the IAM role and/or the mapped variables. 
  ##   body: JObject (required)
  var body_613586 = newJObject()
  if body != nil:
    body_613586 = body
  result = call_613585.call(nil, nil, nil, nil, body_613586)

var putExternalModel* = Call_PutExternalModel_613572(name: "putExternalModel",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.PutExternalModel",
    validator: validate_PutExternalModel_613573, base: "/",
    url: url_PutExternalModel_613574, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutModel_613587 = ref object of OpenApiRestCall_612658
proc url_PutModel_613589(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutModel_613588(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates or updates a model. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613590 = header.getOrDefault("X-Amz-Target")
  valid_613590 = validateParameter(valid_613590, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.PutModel"))
  if valid_613590 != nil:
    section.add "X-Amz-Target", valid_613590
  var valid_613591 = header.getOrDefault("X-Amz-Signature")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-Signature", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-Content-Sha256", valid_613592
  var valid_613593 = header.getOrDefault("X-Amz-Date")
  valid_613593 = validateParameter(valid_613593, JString, required = false,
                                 default = nil)
  if valid_613593 != nil:
    section.add "X-Amz-Date", valid_613593
  var valid_613594 = header.getOrDefault("X-Amz-Credential")
  valid_613594 = validateParameter(valid_613594, JString, required = false,
                                 default = nil)
  if valid_613594 != nil:
    section.add "X-Amz-Credential", valid_613594
  var valid_613595 = header.getOrDefault("X-Amz-Security-Token")
  valid_613595 = validateParameter(valid_613595, JString, required = false,
                                 default = nil)
  if valid_613595 != nil:
    section.add "X-Amz-Security-Token", valid_613595
  var valid_613596 = header.getOrDefault("X-Amz-Algorithm")
  valid_613596 = validateParameter(valid_613596, JString, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "X-Amz-Algorithm", valid_613596
  var valid_613597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613597 = validateParameter(valid_613597, JString, required = false,
                                 default = nil)
  if valid_613597 != nil:
    section.add "X-Amz-SignedHeaders", valid_613597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613599: Call_PutModel_613587; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a model. 
  ## 
  let valid = call_613599.validator(path, query, header, formData, body)
  let scheme = call_613599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613599.url(scheme.get, call_613599.host, call_613599.base,
                         call_613599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613599, url, valid)

proc call*(call_613600: Call_PutModel_613587; body: JsonNode): Recallable =
  ## putModel
  ## Creates or updates a model. 
  ##   body: JObject (required)
  var body_613601 = newJObject()
  if body != nil:
    body_613601 = body
  result = call_613600.call(nil, nil, nil, nil, body_613601)

var putModel* = Call_PutModel_613587(name: "putModel", meth: HttpMethod.HttpPost,
                                  host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.PutModel",
                                  validator: validate_PutModel_613588, base: "/",
                                  url: url_PutModel_613589,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutOutcome_613602 = ref object of OpenApiRestCall_612658
proc url_PutOutcome_613604(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutOutcome_613603(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates or updates an outcome. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613605 = header.getOrDefault("X-Amz-Target")
  valid_613605 = validateParameter(valid_613605, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.PutOutcome"))
  if valid_613605 != nil:
    section.add "X-Amz-Target", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-Signature")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Signature", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-Content-Sha256", valid_613607
  var valid_613608 = header.getOrDefault("X-Amz-Date")
  valid_613608 = validateParameter(valid_613608, JString, required = false,
                                 default = nil)
  if valid_613608 != nil:
    section.add "X-Amz-Date", valid_613608
  var valid_613609 = header.getOrDefault("X-Amz-Credential")
  valid_613609 = validateParameter(valid_613609, JString, required = false,
                                 default = nil)
  if valid_613609 != nil:
    section.add "X-Amz-Credential", valid_613609
  var valid_613610 = header.getOrDefault("X-Amz-Security-Token")
  valid_613610 = validateParameter(valid_613610, JString, required = false,
                                 default = nil)
  if valid_613610 != nil:
    section.add "X-Amz-Security-Token", valid_613610
  var valid_613611 = header.getOrDefault("X-Amz-Algorithm")
  valid_613611 = validateParameter(valid_613611, JString, required = false,
                                 default = nil)
  if valid_613611 != nil:
    section.add "X-Amz-Algorithm", valid_613611
  var valid_613612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613612 = validateParameter(valid_613612, JString, required = false,
                                 default = nil)
  if valid_613612 != nil:
    section.add "X-Amz-SignedHeaders", valid_613612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613614: Call_PutOutcome_613602; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates an outcome. 
  ## 
  let valid = call_613614.validator(path, query, header, formData, body)
  let scheme = call_613614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613614.url(scheme.get, call_613614.host, call_613614.base,
                         call_613614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613614, url, valid)

proc call*(call_613615: Call_PutOutcome_613602; body: JsonNode): Recallable =
  ## putOutcome
  ## Creates or updates an outcome. 
  ##   body: JObject (required)
  var body_613616 = newJObject()
  if body != nil:
    body_613616 = body
  result = call_613615.call(nil, nil, nil, nil, body_613616)

var putOutcome* = Call_PutOutcome_613602(name: "putOutcome",
                                      meth: HttpMethod.HttpPost,
                                      host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.PutOutcome",
                                      validator: validate_PutOutcome_613603,
                                      base: "/", url: url_PutOutcome_613604,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorVersion_613617 = ref object of OpenApiRestCall_612658
proc url_UpdateDetectorVersion_613619(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDetectorVersion_613618(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Updates a detector version. The detector version attributes that you can update include models, external model endpoints, rules, and description. You can only update a <code>DRAFT</code> detector version.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613620 = header.getOrDefault("X-Amz-Target")
  valid_613620 = validateParameter(valid_613620, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateDetectorVersion"))
  if valid_613620 != nil:
    section.add "X-Amz-Target", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-Signature")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-Signature", valid_613621
  var valid_613622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-Content-Sha256", valid_613622
  var valid_613623 = header.getOrDefault("X-Amz-Date")
  valid_613623 = validateParameter(valid_613623, JString, required = false,
                                 default = nil)
  if valid_613623 != nil:
    section.add "X-Amz-Date", valid_613623
  var valid_613624 = header.getOrDefault("X-Amz-Credential")
  valid_613624 = validateParameter(valid_613624, JString, required = false,
                                 default = nil)
  if valid_613624 != nil:
    section.add "X-Amz-Credential", valid_613624
  var valid_613625 = header.getOrDefault("X-Amz-Security-Token")
  valid_613625 = validateParameter(valid_613625, JString, required = false,
                                 default = nil)
  if valid_613625 != nil:
    section.add "X-Amz-Security-Token", valid_613625
  var valid_613626 = header.getOrDefault("X-Amz-Algorithm")
  valid_613626 = validateParameter(valid_613626, JString, required = false,
                                 default = nil)
  if valid_613626 != nil:
    section.add "X-Amz-Algorithm", valid_613626
  var valid_613627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "X-Amz-SignedHeaders", valid_613627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613629: Call_UpdateDetectorVersion_613617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates a detector version. The detector version attributes that you can update include models, external model endpoints, rules, and description. You can only update a <code>DRAFT</code> detector version.
  ## 
  let valid = call_613629.validator(path, query, header, formData, body)
  let scheme = call_613629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613629.url(scheme.get, call_613629.host, call_613629.base,
                         call_613629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613629, url, valid)

proc call*(call_613630: Call_UpdateDetectorVersion_613617; body: JsonNode): Recallable =
  ## updateDetectorVersion
  ##  Updates a detector version. The detector version attributes that you can update include models, external model endpoints, rules, and description. You can only update a <code>DRAFT</code> detector version.
  ##   body: JObject (required)
  var body_613631 = newJObject()
  if body != nil:
    body_613631 = body
  result = call_613630.call(nil, nil, nil, nil, body_613631)

var updateDetectorVersion* = Call_UpdateDetectorVersion_613617(
    name: "updateDetectorVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateDetectorVersion",
    validator: validate_UpdateDetectorVersion_613618, base: "/",
    url: url_UpdateDetectorVersion_613619, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorVersionMetadata_613632 = ref object of OpenApiRestCall_612658
proc url_UpdateDetectorVersionMetadata_613634(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDetectorVersionMetadata_613633(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the detector version's description. You can update the metadata for any detector version (<code>DRAFT, ACTIVE,</code> or <code>INACTIVE</code>). 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613635 = header.getOrDefault("X-Amz-Target")
  valid_613635 = validateParameter(valid_613635, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateDetectorVersionMetadata"))
  if valid_613635 != nil:
    section.add "X-Amz-Target", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-Signature")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Signature", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-Content-Sha256", valid_613637
  var valid_613638 = header.getOrDefault("X-Amz-Date")
  valid_613638 = validateParameter(valid_613638, JString, required = false,
                                 default = nil)
  if valid_613638 != nil:
    section.add "X-Amz-Date", valid_613638
  var valid_613639 = header.getOrDefault("X-Amz-Credential")
  valid_613639 = validateParameter(valid_613639, JString, required = false,
                                 default = nil)
  if valid_613639 != nil:
    section.add "X-Amz-Credential", valid_613639
  var valid_613640 = header.getOrDefault("X-Amz-Security-Token")
  valid_613640 = validateParameter(valid_613640, JString, required = false,
                                 default = nil)
  if valid_613640 != nil:
    section.add "X-Amz-Security-Token", valid_613640
  var valid_613641 = header.getOrDefault("X-Amz-Algorithm")
  valid_613641 = validateParameter(valid_613641, JString, required = false,
                                 default = nil)
  if valid_613641 != nil:
    section.add "X-Amz-Algorithm", valid_613641
  var valid_613642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613642 = validateParameter(valid_613642, JString, required = false,
                                 default = nil)
  if valid_613642 != nil:
    section.add "X-Amz-SignedHeaders", valid_613642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613644: Call_UpdateDetectorVersionMetadata_613632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the detector version's description. You can update the metadata for any detector version (<code>DRAFT, ACTIVE,</code> or <code>INACTIVE</code>). 
  ## 
  let valid = call_613644.validator(path, query, header, formData, body)
  let scheme = call_613644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613644.url(scheme.get, call_613644.host, call_613644.base,
                         call_613644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613644, url, valid)

proc call*(call_613645: Call_UpdateDetectorVersionMetadata_613632; body: JsonNode): Recallable =
  ## updateDetectorVersionMetadata
  ## Updates the detector version's description. You can update the metadata for any detector version (<code>DRAFT, ACTIVE,</code> or <code>INACTIVE</code>). 
  ##   body: JObject (required)
  var body_613646 = newJObject()
  if body != nil:
    body_613646 = body
  result = call_613645.call(nil, nil, nil, nil, body_613646)

var updateDetectorVersionMetadata* = Call_UpdateDetectorVersionMetadata_613632(
    name: "updateDetectorVersionMetadata", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateDetectorVersionMetadata",
    validator: validate_UpdateDetectorVersionMetadata_613633, base: "/",
    url: url_UpdateDetectorVersionMetadata_613634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorVersionStatus_613647 = ref object of OpenApiRestCall_612658
proc url_UpdateDetectorVersionStatus_613649(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDetectorVersionStatus_613648(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the detector version’s status. You can perform the following promotions or demotions using <code>UpdateDetectorVersionStatus</code>: <code>DRAFT</code> to <code>ACTIVE</code>, <code>ACTIVE</code> to <code>INACTIVE</code>, and <code>INACTIVE</code> to <code>ACTIVE</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613650 = header.getOrDefault("X-Amz-Target")
  valid_613650 = validateParameter(valid_613650, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateDetectorVersionStatus"))
  if valid_613650 != nil:
    section.add "X-Amz-Target", valid_613650
  var valid_613651 = header.getOrDefault("X-Amz-Signature")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Signature", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-Content-Sha256", valid_613652
  var valid_613653 = header.getOrDefault("X-Amz-Date")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "X-Amz-Date", valid_613653
  var valid_613654 = header.getOrDefault("X-Amz-Credential")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-Credential", valid_613654
  var valid_613655 = header.getOrDefault("X-Amz-Security-Token")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "X-Amz-Security-Token", valid_613655
  var valid_613656 = header.getOrDefault("X-Amz-Algorithm")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-Algorithm", valid_613656
  var valid_613657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613657 = validateParameter(valid_613657, JString, required = false,
                                 default = nil)
  if valid_613657 != nil:
    section.add "X-Amz-SignedHeaders", valid_613657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613659: Call_UpdateDetectorVersionStatus_613647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the detector version’s status. You can perform the following promotions or demotions using <code>UpdateDetectorVersionStatus</code>: <code>DRAFT</code> to <code>ACTIVE</code>, <code>ACTIVE</code> to <code>INACTIVE</code>, and <code>INACTIVE</code> to <code>ACTIVE</code>.
  ## 
  let valid = call_613659.validator(path, query, header, formData, body)
  let scheme = call_613659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613659.url(scheme.get, call_613659.host, call_613659.base,
                         call_613659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613659, url, valid)

proc call*(call_613660: Call_UpdateDetectorVersionStatus_613647; body: JsonNode): Recallable =
  ## updateDetectorVersionStatus
  ## Updates the detector version’s status. You can perform the following promotions or demotions using <code>UpdateDetectorVersionStatus</code>: <code>DRAFT</code> to <code>ACTIVE</code>, <code>ACTIVE</code> to <code>INACTIVE</code>, and <code>INACTIVE</code> to <code>ACTIVE</code>.
  ##   body: JObject (required)
  var body_613661 = newJObject()
  if body != nil:
    body_613661 = body
  result = call_613660.call(nil, nil, nil, nil, body_613661)

var updateDetectorVersionStatus* = Call_UpdateDetectorVersionStatus_613647(
    name: "updateDetectorVersionStatus", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateDetectorVersionStatus",
    validator: validate_UpdateDetectorVersionStatus_613648, base: "/",
    url: url_UpdateDetectorVersionStatus_613649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModelVersion_613662 = ref object of OpenApiRestCall_612658
proc url_UpdateModelVersion_613664(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateModelVersion_613663(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Updates a model version. You can update the description and status attributes using this action. You can perform the following status updates: </p> <ol> <li> <p>Change the <code>TRAINING_COMPLETE</code> status to <code>ACTIVE</code> </p> </li> <li> <p>Change <code>ACTIVE</code> back to <code>TRAINING_COMPLETE</code> </p> </li> </ol>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613665 = header.getOrDefault("X-Amz-Target")
  valid_613665 = validateParameter(valid_613665, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateModelVersion"))
  if valid_613665 != nil:
    section.add "X-Amz-Target", valid_613665
  var valid_613666 = header.getOrDefault("X-Amz-Signature")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-Signature", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Content-Sha256", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Date")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Date", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-Credential")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-Credential", valid_613669
  var valid_613670 = header.getOrDefault("X-Amz-Security-Token")
  valid_613670 = validateParameter(valid_613670, JString, required = false,
                                 default = nil)
  if valid_613670 != nil:
    section.add "X-Amz-Security-Token", valid_613670
  var valid_613671 = header.getOrDefault("X-Amz-Algorithm")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "X-Amz-Algorithm", valid_613671
  var valid_613672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "X-Amz-SignedHeaders", valid_613672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613674: Call_UpdateModelVersion_613662; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a model version. You can update the description and status attributes using this action. You can perform the following status updates: </p> <ol> <li> <p>Change the <code>TRAINING_COMPLETE</code> status to <code>ACTIVE</code> </p> </li> <li> <p>Change <code>ACTIVE</code> back to <code>TRAINING_COMPLETE</code> </p> </li> </ol>
  ## 
  let valid = call_613674.validator(path, query, header, formData, body)
  let scheme = call_613674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613674.url(scheme.get, call_613674.host, call_613674.base,
                         call_613674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613674, url, valid)

proc call*(call_613675: Call_UpdateModelVersion_613662; body: JsonNode): Recallable =
  ## updateModelVersion
  ## <p>Updates a model version. You can update the description and status attributes using this action. You can perform the following status updates: </p> <ol> <li> <p>Change the <code>TRAINING_COMPLETE</code> status to <code>ACTIVE</code> </p> </li> <li> <p>Change <code>ACTIVE</code> back to <code>TRAINING_COMPLETE</code> </p> </li> </ol>
  ##   body: JObject (required)
  var body_613676 = newJObject()
  if body != nil:
    body_613676 = body
  result = call_613675.call(nil, nil, nil, nil, body_613676)

var updateModelVersion* = Call_UpdateModelVersion_613662(
    name: "updateModelVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateModelVersion",
    validator: validate_UpdateModelVersion_613663, base: "/",
    url: url_UpdateModelVersion_613664, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRuleMetadata_613677 = ref object of OpenApiRestCall_612658
proc url_UpdateRuleMetadata_613679(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRuleMetadata_613678(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Updates a rule's metadata. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613680 = header.getOrDefault("X-Amz-Target")
  valid_613680 = validateParameter(valid_613680, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateRuleMetadata"))
  if valid_613680 != nil:
    section.add "X-Amz-Target", valid_613680
  var valid_613681 = header.getOrDefault("X-Amz-Signature")
  valid_613681 = validateParameter(valid_613681, JString, required = false,
                                 default = nil)
  if valid_613681 != nil:
    section.add "X-Amz-Signature", valid_613681
  var valid_613682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613682 = validateParameter(valid_613682, JString, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "X-Amz-Content-Sha256", valid_613682
  var valid_613683 = header.getOrDefault("X-Amz-Date")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "X-Amz-Date", valid_613683
  var valid_613684 = header.getOrDefault("X-Amz-Credential")
  valid_613684 = validateParameter(valid_613684, JString, required = false,
                                 default = nil)
  if valid_613684 != nil:
    section.add "X-Amz-Credential", valid_613684
  var valid_613685 = header.getOrDefault("X-Amz-Security-Token")
  valid_613685 = validateParameter(valid_613685, JString, required = false,
                                 default = nil)
  if valid_613685 != nil:
    section.add "X-Amz-Security-Token", valid_613685
  var valid_613686 = header.getOrDefault("X-Amz-Algorithm")
  valid_613686 = validateParameter(valid_613686, JString, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "X-Amz-Algorithm", valid_613686
  var valid_613687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613687 = validateParameter(valid_613687, JString, required = false,
                                 default = nil)
  if valid_613687 != nil:
    section.add "X-Amz-SignedHeaders", valid_613687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613689: Call_UpdateRuleMetadata_613677; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a rule's metadata. 
  ## 
  let valid = call_613689.validator(path, query, header, formData, body)
  let scheme = call_613689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613689.url(scheme.get, call_613689.host, call_613689.base,
                         call_613689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613689, url, valid)

proc call*(call_613690: Call_UpdateRuleMetadata_613677; body: JsonNode): Recallable =
  ## updateRuleMetadata
  ## Updates a rule's metadata. 
  ##   body: JObject (required)
  var body_613691 = newJObject()
  if body != nil:
    body_613691 = body
  result = call_613690.call(nil, nil, nil, nil, body_613691)

var updateRuleMetadata* = Call_UpdateRuleMetadata_613677(
    name: "updateRuleMetadata", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateRuleMetadata",
    validator: validate_UpdateRuleMetadata_613678, base: "/",
    url: url_UpdateRuleMetadata_613679, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRuleVersion_613692 = ref object of OpenApiRestCall_612658
proc url_UpdateRuleVersion_613694(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRuleVersion_613693(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates a rule version resulting in a new rule version. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613695 = header.getOrDefault("X-Amz-Target")
  valid_613695 = validateParameter(valid_613695, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateRuleVersion"))
  if valid_613695 != nil:
    section.add "X-Amz-Target", valid_613695
  var valid_613696 = header.getOrDefault("X-Amz-Signature")
  valid_613696 = validateParameter(valid_613696, JString, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "X-Amz-Signature", valid_613696
  var valid_613697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-Content-Sha256", valid_613697
  var valid_613698 = header.getOrDefault("X-Amz-Date")
  valid_613698 = validateParameter(valid_613698, JString, required = false,
                                 default = nil)
  if valid_613698 != nil:
    section.add "X-Amz-Date", valid_613698
  var valid_613699 = header.getOrDefault("X-Amz-Credential")
  valid_613699 = validateParameter(valid_613699, JString, required = false,
                                 default = nil)
  if valid_613699 != nil:
    section.add "X-Amz-Credential", valid_613699
  var valid_613700 = header.getOrDefault("X-Amz-Security-Token")
  valid_613700 = validateParameter(valid_613700, JString, required = false,
                                 default = nil)
  if valid_613700 != nil:
    section.add "X-Amz-Security-Token", valid_613700
  var valid_613701 = header.getOrDefault("X-Amz-Algorithm")
  valid_613701 = validateParameter(valid_613701, JString, required = false,
                                 default = nil)
  if valid_613701 != nil:
    section.add "X-Amz-Algorithm", valid_613701
  var valid_613702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613702 = validateParameter(valid_613702, JString, required = false,
                                 default = nil)
  if valid_613702 != nil:
    section.add "X-Amz-SignedHeaders", valid_613702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613704: Call_UpdateRuleVersion_613692; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a rule version resulting in a new rule version. 
  ## 
  let valid = call_613704.validator(path, query, header, formData, body)
  let scheme = call_613704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613704.url(scheme.get, call_613704.host, call_613704.base,
                         call_613704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613704, url, valid)

proc call*(call_613705: Call_UpdateRuleVersion_613692; body: JsonNode): Recallable =
  ## updateRuleVersion
  ## Updates a rule version resulting in a new rule version. 
  ##   body: JObject (required)
  var body_613706 = newJObject()
  if body != nil:
    body_613706 = body
  result = call_613705.call(nil, nil, nil, nil, body_613706)

var updateRuleVersion* = Call_UpdateRuleVersion_613692(name: "updateRuleVersion",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateRuleVersion",
    validator: validate_UpdateRuleVersion_613693, base: "/",
    url: url_UpdateRuleVersion_613694, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVariable_613707 = ref object of OpenApiRestCall_612658
proc url_UpdateVariable_613709(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateVariable_613708(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates a variable.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613710 = header.getOrDefault("X-Amz-Target")
  valid_613710 = validateParameter(valid_613710, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateVariable"))
  if valid_613710 != nil:
    section.add "X-Amz-Target", valid_613710
  var valid_613711 = header.getOrDefault("X-Amz-Signature")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Signature", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-Content-Sha256", valid_613712
  var valid_613713 = header.getOrDefault("X-Amz-Date")
  valid_613713 = validateParameter(valid_613713, JString, required = false,
                                 default = nil)
  if valid_613713 != nil:
    section.add "X-Amz-Date", valid_613713
  var valid_613714 = header.getOrDefault("X-Amz-Credential")
  valid_613714 = validateParameter(valid_613714, JString, required = false,
                                 default = nil)
  if valid_613714 != nil:
    section.add "X-Amz-Credential", valid_613714
  var valid_613715 = header.getOrDefault("X-Amz-Security-Token")
  valid_613715 = validateParameter(valid_613715, JString, required = false,
                                 default = nil)
  if valid_613715 != nil:
    section.add "X-Amz-Security-Token", valid_613715
  var valid_613716 = header.getOrDefault("X-Amz-Algorithm")
  valid_613716 = validateParameter(valid_613716, JString, required = false,
                                 default = nil)
  if valid_613716 != nil:
    section.add "X-Amz-Algorithm", valid_613716
  var valid_613717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613717 = validateParameter(valid_613717, JString, required = false,
                                 default = nil)
  if valid_613717 != nil:
    section.add "X-Amz-SignedHeaders", valid_613717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613719: Call_UpdateVariable_613707; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a variable.
  ## 
  let valid = call_613719.validator(path, query, header, formData, body)
  let scheme = call_613719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613719.url(scheme.get, call_613719.host, call_613719.base,
                         call_613719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613719, url, valid)

proc call*(call_613720: Call_UpdateVariable_613707; body: JsonNode): Recallable =
  ## updateVariable
  ## Updates a variable.
  ##   body: JObject (required)
  var body_613721 = newJObject()
  if body != nil:
    body_613721 = body
  result = call_613720.call(nil, nil, nil, nil, body_613721)

var updateVariable* = Call_UpdateVariable_613707(name: "updateVariable",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateVariable",
    validator: validate_UpdateVariable_613708, base: "/", url: url_UpdateVariable_613709,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
