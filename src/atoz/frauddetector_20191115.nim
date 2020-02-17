
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
  Call_BatchCreateVariable_610996 = ref object of OpenApiRestCall_610658
proc url_BatchCreateVariable_610998(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchCreateVariable_610997(path: JsonNode; query: JsonNode;
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
  var valid_611123 = header.getOrDefault("X-Amz-Target")
  valid_611123 = validateParameter(valid_611123, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.BatchCreateVariable"))
  if valid_611123 != nil:
    section.add "X-Amz-Target", valid_611123
  var valid_611124 = header.getOrDefault("X-Amz-Signature")
  valid_611124 = validateParameter(valid_611124, JString, required = false,
                                 default = nil)
  if valid_611124 != nil:
    section.add "X-Amz-Signature", valid_611124
  var valid_611125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "X-Amz-Content-Sha256", valid_611125
  var valid_611126 = header.getOrDefault("X-Amz-Date")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Date", valid_611126
  var valid_611127 = header.getOrDefault("X-Amz-Credential")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Credential", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Security-Token")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Security-Token", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Algorithm")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Algorithm", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-SignedHeaders", valid_611130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611154: Call_BatchCreateVariable_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a batch of variables.
  ## 
  let valid = call_611154.validator(path, query, header, formData, body)
  let scheme = call_611154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611154.url(scheme.get, call_611154.host, call_611154.base,
                         call_611154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611154, url, valid)

proc call*(call_611225: Call_BatchCreateVariable_610996; body: JsonNode): Recallable =
  ## batchCreateVariable
  ## Creates a batch of variables.
  ##   body: JObject (required)
  var body_611226 = newJObject()
  if body != nil:
    body_611226 = body
  result = call_611225.call(nil, nil, nil, nil, body_611226)

var batchCreateVariable* = Call_BatchCreateVariable_610996(
    name: "batchCreateVariable", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.BatchCreateVariable",
    validator: validate_BatchCreateVariable_610997, base: "/",
    url: url_BatchCreateVariable_610998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetVariable_611265 = ref object of OpenApiRestCall_610658
proc url_BatchGetVariable_611267(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetVariable_611266(path: JsonNode; query: JsonNode;
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
  var valid_611268 = header.getOrDefault("X-Amz-Target")
  valid_611268 = validateParameter(valid_611268, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.BatchGetVariable"))
  if valid_611268 != nil:
    section.add "X-Amz-Target", valid_611268
  var valid_611269 = header.getOrDefault("X-Amz-Signature")
  valid_611269 = validateParameter(valid_611269, JString, required = false,
                                 default = nil)
  if valid_611269 != nil:
    section.add "X-Amz-Signature", valid_611269
  var valid_611270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Content-Sha256", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Date")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Date", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Credential")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Credential", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Security-Token")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Security-Token", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Algorithm")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Algorithm", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-SignedHeaders", valid_611275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611277: Call_BatchGetVariable_611265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a batch of variables.
  ## 
  let valid = call_611277.validator(path, query, header, formData, body)
  let scheme = call_611277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611277.url(scheme.get, call_611277.host, call_611277.base,
                         call_611277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611277, url, valid)

proc call*(call_611278: Call_BatchGetVariable_611265; body: JsonNode): Recallable =
  ## batchGetVariable
  ## Gets a batch of variables.
  ##   body: JObject (required)
  var body_611279 = newJObject()
  if body != nil:
    body_611279 = body
  result = call_611278.call(nil, nil, nil, nil, body_611279)

var batchGetVariable* = Call_BatchGetVariable_611265(name: "batchGetVariable",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.BatchGetVariable",
    validator: validate_BatchGetVariable_611266, base: "/",
    url: url_BatchGetVariable_611267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDetectorVersion_611280 = ref object of OpenApiRestCall_610658
proc url_CreateDetectorVersion_611282(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDetectorVersion_611281(path: JsonNode; query: JsonNode;
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
  var valid_611283 = header.getOrDefault("X-Amz-Target")
  valid_611283 = validateParameter(valid_611283, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.CreateDetectorVersion"))
  if valid_611283 != nil:
    section.add "X-Amz-Target", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-Signature")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-Signature", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Content-Sha256", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Date")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Date", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Credential")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Credential", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Security-Token")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Security-Token", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Algorithm")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Algorithm", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-SignedHeaders", valid_611290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611292: Call_CreateDetectorVersion_611280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a detector version. The detector version starts in a <code>DRAFT</code> status.
  ## 
  let valid = call_611292.validator(path, query, header, formData, body)
  let scheme = call_611292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611292.url(scheme.get, call_611292.host, call_611292.base,
                         call_611292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611292, url, valid)

proc call*(call_611293: Call_CreateDetectorVersion_611280; body: JsonNode): Recallable =
  ## createDetectorVersion
  ## Creates a detector version. The detector version starts in a <code>DRAFT</code> status.
  ##   body: JObject (required)
  var body_611294 = newJObject()
  if body != nil:
    body_611294 = body
  result = call_611293.call(nil, nil, nil, nil, body_611294)

var createDetectorVersion* = Call_CreateDetectorVersion_611280(
    name: "createDetectorVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.CreateDetectorVersion",
    validator: validate_CreateDetectorVersion_611281, base: "/",
    url: url_CreateDetectorVersion_611282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModelVersion_611295 = ref object of OpenApiRestCall_610658
proc url_CreateModelVersion_611297(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateModelVersion_611296(path: JsonNode; query: JsonNode;
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
  var valid_611298 = header.getOrDefault("X-Amz-Target")
  valid_611298 = validateParameter(valid_611298, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.CreateModelVersion"))
  if valid_611298 != nil:
    section.add "X-Amz-Target", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Signature")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Signature", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Content-Sha256", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Date")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Date", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Credential")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Credential", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Security-Token")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Security-Token", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Algorithm")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Algorithm", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-SignedHeaders", valid_611305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611307: Call_CreateModelVersion_611295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of the model using the specified model type. 
  ## 
  let valid = call_611307.validator(path, query, header, formData, body)
  let scheme = call_611307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611307.url(scheme.get, call_611307.host, call_611307.base,
                         call_611307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611307, url, valid)

proc call*(call_611308: Call_CreateModelVersion_611295; body: JsonNode): Recallable =
  ## createModelVersion
  ## Creates a version of the model using the specified model type. 
  ##   body: JObject (required)
  var body_611309 = newJObject()
  if body != nil:
    body_611309 = body
  result = call_611308.call(nil, nil, nil, nil, body_611309)

var createModelVersion* = Call_CreateModelVersion_611295(
    name: "createModelVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.CreateModelVersion",
    validator: validate_CreateModelVersion_611296, base: "/",
    url: url_CreateModelVersion_611297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRule_611310 = ref object of OpenApiRestCall_610658
proc url_CreateRule_611312(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRule_611311(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611313 = header.getOrDefault("X-Amz-Target")
  valid_611313 = validateParameter(valid_611313, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.CreateRule"))
  if valid_611313 != nil:
    section.add "X-Amz-Target", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Signature")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Signature", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Content-Sha256", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Date")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Date", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Credential")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Credential", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Security-Token")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Security-Token", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Algorithm")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Algorithm", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-SignedHeaders", valid_611320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611322: Call_CreateRule_611310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a rule for use with the specified detector. 
  ## 
  let valid = call_611322.validator(path, query, header, formData, body)
  let scheme = call_611322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611322.url(scheme.get, call_611322.host, call_611322.base,
                         call_611322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611322, url, valid)

proc call*(call_611323: Call_CreateRule_611310; body: JsonNode): Recallable =
  ## createRule
  ## Creates a rule for use with the specified detector. 
  ##   body: JObject (required)
  var body_611324 = newJObject()
  if body != nil:
    body_611324 = body
  result = call_611323.call(nil, nil, nil, nil, body_611324)

var createRule* = Call_CreateRule_611310(name: "createRule",
                                      meth: HttpMethod.HttpPost,
                                      host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.CreateRule",
                                      validator: validate_CreateRule_611311,
                                      base: "/", url: url_CreateRule_611312,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVariable_611325 = ref object of OpenApiRestCall_610658
proc url_CreateVariable_611327(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateVariable_611326(path: JsonNode; query: JsonNode;
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
  var valid_611328 = header.getOrDefault("X-Amz-Target")
  valid_611328 = validateParameter(valid_611328, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.CreateVariable"))
  if valid_611328 != nil:
    section.add "X-Amz-Target", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Signature")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Signature", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Content-Sha256", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Date")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Date", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Credential")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Credential", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Security-Token")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Security-Token", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Algorithm")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Algorithm", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-SignedHeaders", valid_611335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611337: Call_CreateVariable_611325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a variable.
  ## 
  let valid = call_611337.validator(path, query, header, formData, body)
  let scheme = call_611337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611337.url(scheme.get, call_611337.host, call_611337.base,
                         call_611337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611337, url, valid)

proc call*(call_611338: Call_CreateVariable_611325; body: JsonNode): Recallable =
  ## createVariable
  ## Creates a variable.
  ##   body: JObject (required)
  var body_611339 = newJObject()
  if body != nil:
    body_611339 = body
  result = call_611338.call(nil, nil, nil, nil, body_611339)

var createVariable* = Call_CreateVariable_611325(name: "createVariable",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.CreateVariable",
    validator: validate_CreateVariable_611326, base: "/", url: url_CreateVariable_611327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDetectorVersion_611340 = ref object of OpenApiRestCall_610658
proc url_DeleteDetectorVersion_611342(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDetectorVersion_611341(path: JsonNode; query: JsonNode;
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
  var valid_611343 = header.getOrDefault("X-Amz-Target")
  valid_611343 = validateParameter(valid_611343, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.DeleteDetectorVersion"))
  if valid_611343 != nil:
    section.add "X-Amz-Target", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Signature")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Signature", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Content-Sha256", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-Date")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Date", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Credential")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Credential", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Security-Token")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Security-Token", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Algorithm")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Algorithm", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-SignedHeaders", valid_611350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611352: Call_DeleteDetectorVersion_611340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the detector version.
  ## 
  let valid = call_611352.validator(path, query, header, formData, body)
  let scheme = call_611352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611352.url(scheme.get, call_611352.host, call_611352.base,
                         call_611352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611352, url, valid)

proc call*(call_611353: Call_DeleteDetectorVersion_611340; body: JsonNode): Recallable =
  ## deleteDetectorVersion
  ## Deletes the detector version.
  ##   body: JObject (required)
  var body_611354 = newJObject()
  if body != nil:
    body_611354 = body
  result = call_611353.call(nil, nil, nil, nil, body_611354)

var deleteDetectorVersion* = Call_DeleteDetectorVersion_611340(
    name: "deleteDetectorVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.DeleteDetectorVersion",
    validator: validate_DeleteDetectorVersion_611341, base: "/",
    url: url_DeleteDetectorVersion_611342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEvent_611355 = ref object of OpenApiRestCall_610658
proc url_DeleteEvent_611357(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEvent_611356(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611358 = header.getOrDefault("X-Amz-Target")
  valid_611358 = validateParameter(valid_611358, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.DeleteEvent"))
  if valid_611358 != nil:
    section.add "X-Amz-Target", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Signature")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Signature", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Content-Sha256", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-Date")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-Date", valid_611361
  var valid_611362 = header.getOrDefault("X-Amz-Credential")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-Credential", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-Security-Token")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-Security-Token", valid_611363
  var valid_611364 = header.getOrDefault("X-Amz-Algorithm")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-Algorithm", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-SignedHeaders", valid_611365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611367: Call_DeleteEvent_611355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified event.
  ## 
  let valid = call_611367.validator(path, query, header, formData, body)
  let scheme = call_611367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611367.url(scheme.get, call_611367.host, call_611367.base,
                         call_611367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611367, url, valid)

proc call*(call_611368: Call_DeleteEvent_611355; body: JsonNode): Recallable =
  ## deleteEvent
  ## Deletes the specified event.
  ##   body: JObject (required)
  var body_611369 = newJObject()
  if body != nil:
    body_611369 = body
  result = call_611368.call(nil, nil, nil, nil, body_611369)

var deleteEvent* = Call_DeleteEvent_611355(name: "deleteEvent",
                                        meth: HttpMethod.HttpPost,
                                        host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.DeleteEvent",
                                        validator: validate_DeleteEvent_611356,
                                        base: "/", url: url_DeleteEvent_611357,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDetector_611370 = ref object of OpenApiRestCall_610658
proc url_DescribeDetector_611372(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDetector_611371(path: JsonNode; query: JsonNode;
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
  var valid_611373 = header.getOrDefault("X-Amz-Target")
  valid_611373 = validateParameter(valid_611373, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.DescribeDetector"))
  if valid_611373 != nil:
    section.add "X-Amz-Target", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Signature")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Signature", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Content-Sha256", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Date")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Date", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Credential")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Credential", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-Security-Token")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Security-Token", valid_611378
  var valid_611379 = header.getOrDefault("X-Amz-Algorithm")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Algorithm", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-SignedHeaders", valid_611380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611382: Call_DescribeDetector_611370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all versions for a specified detector.
  ## 
  let valid = call_611382.validator(path, query, header, formData, body)
  let scheme = call_611382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611382.url(scheme.get, call_611382.host, call_611382.base,
                         call_611382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611382, url, valid)

proc call*(call_611383: Call_DescribeDetector_611370; body: JsonNode): Recallable =
  ## describeDetector
  ## Gets all versions for a specified detector.
  ##   body: JObject (required)
  var body_611384 = newJObject()
  if body != nil:
    body_611384 = body
  result = call_611383.call(nil, nil, nil, nil, body_611384)

var describeDetector* = Call_DescribeDetector_611370(name: "describeDetector",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.DescribeDetector",
    validator: validate_DescribeDetector_611371, base: "/",
    url: url_DescribeDetector_611372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModelVersions_611385 = ref object of OpenApiRestCall_610658
proc url_DescribeModelVersions_611387(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeModelVersions_611386(path: JsonNode; query: JsonNode;
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
  var valid_611388 = query.getOrDefault("nextToken")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "nextToken", valid_611388
  var valid_611389 = query.getOrDefault("maxResults")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "maxResults", valid_611389
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
  var valid_611390 = header.getOrDefault("X-Amz-Target")
  valid_611390 = validateParameter(valid_611390, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.DescribeModelVersions"))
  if valid_611390 != nil:
    section.add "X-Amz-Target", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Signature")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Signature", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Content-Sha256", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Date")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Date", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-Credential")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Credential", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-Security-Token")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-Security-Token", valid_611395
  var valid_611396 = header.getOrDefault("X-Amz-Algorithm")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-Algorithm", valid_611396
  var valid_611397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "X-Amz-SignedHeaders", valid_611397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611399: Call_DescribeModelVersions_611385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all of the model versions for the specified model type or for the specified model type and model ID. You can also get details for a single, specified model version. 
  ## 
  let valid = call_611399.validator(path, query, header, formData, body)
  let scheme = call_611399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611399.url(scheme.get, call_611399.host, call_611399.base,
                         call_611399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611399, url, valid)

proc call*(call_611400: Call_DescribeModelVersions_611385; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeModelVersions
  ## Gets all of the model versions for the specified model type or for the specified model type and model ID. You can also get details for a single, specified model version. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611401 = newJObject()
  var body_611402 = newJObject()
  add(query_611401, "nextToken", newJString(nextToken))
  if body != nil:
    body_611402 = body
  add(query_611401, "maxResults", newJString(maxResults))
  result = call_611400.call(nil, query_611401, nil, nil, body_611402)

var describeModelVersions* = Call_DescribeModelVersions_611385(
    name: "describeModelVersions", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.DescribeModelVersions",
    validator: validate_DescribeModelVersions_611386, base: "/",
    url: url_DescribeModelVersions_611387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetectorVersion_611404 = ref object of OpenApiRestCall_610658
proc url_GetDetectorVersion_611406(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDetectorVersion_611405(path: JsonNode; query: JsonNode;
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
  var valid_611407 = header.getOrDefault("X-Amz-Target")
  valid_611407 = validateParameter(valid_611407, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetDetectorVersion"))
  if valid_611407 != nil:
    section.add "X-Amz-Target", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Signature")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Signature", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Content-Sha256", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-Date")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-Date", valid_611410
  var valid_611411 = header.getOrDefault("X-Amz-Credential")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-Credential", valid_611411
  var valid_611412 = header.getOrDefault("X-Amz-Security-Token")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Security-Token", valid_611412
  var valid_611413 = header.getOrDefault("X-Amz-Algorithm")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-Algorithm", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-SignedHeaders", valid_611414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611416: Call_GetDetectorVersion_611404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a particular detector version. 
  ## 
  let valid = call_611416.validator(path, query, header, formData, body)
  let scheme = call_611416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611416.url(scheme.get, call_611416.host, call_611416.base,
                         call_611416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611416, url, valid)

proc call*(call_611417: Call_GetDetectorVersion_611404; body: JsonNode): Recallable =
  ## getDetectorVersion
  ## Gets a particular detector version. 
  ##   body: JObject (required)
  var body_611418 = newJObject()
  if body != nil:
    body_611418 = body
  result = call_611417.call(nil, nil, nil, nil, body_611418)

var getDetectorVersion* = Call_GetDetectorVersion_611404(
    name: "getDetectorVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetDetectorVersion",
    validator: validate_GetDetectorVersion_611405, base: "/",
    url: url_GetDetectorVersion_611406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetectors_611419 = ref object of OpenApiRestCall_610658
proc url_GetDetectors_611421(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDetectors_611420(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611422 = query.getOrDefault("nextToken")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "nextToken", valid_611422
  var valid_611423 = query.getOrDefault("maxResults")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "maxResults", valid_611423
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
  var valid_611424 = header.getOrDefault("X-Amz-Target")
  valid_611424 = validateParameter(valid_611424, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetDetectors"))
  if valid_611424 != nil:
    section.add "X-Amz-Target", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-Signature")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-Signature", valid_611425
  var valid_611426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "X-Amz-Content-Sha256", valid_611426
  var valid_611427 = header.getOrDefault("X-Amz-Date")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-Date", valid_611427
  var valid_611428 = header.getOrDefault("X-Amz-Credential")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "X-Amz-Credential", valid_611428
  var valid_611429 = header.getOrDefault("X-Amz-Security-Token")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "X-Amz-Security-Token", valid_611429
  var valid_611430 = header.getOrDefault("X-Amz-Algorithm")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "X-Amz-Algorithm", valid_611430
  var valid_611431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-SignedHeaders", valid_611431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611433: Call_GetDetectors_611419; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all of detectors. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetEventTypesResponse</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ## 
  let valid = call_611433.validator(path, query, header, formData, body)
  let scheme = call_611433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611433.url(scheme.get, call_611433.host, call_611433.base,
                         call_611433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611433, url, valid)

proc call*(call_611434: Call_GetDetectors_611419; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getDetectors
  ## Gets all of detectors. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetEventTypesResponse</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611435 = newJObject()
  var body_611436 = newJObject()
  add(query_611435, "nextToken", newJString(nextToken))
  if body != nil:
    body_611436 = body
  add(query_611435, "maxResults", newJString(maxResults))
  result = call_611434.call(nil, query_611435, nil, nil, body_611436)

var getDetectors* = Call_GetDetectors_611419(name: "getDetectors",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetDetectors",
    validator: validate_GetDetectors_611420, base: "/", url: url_GetDetectors_611421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExternalModels_611437 = ref object of OpenApiRestCall_610658
proc url_GetExternalModels_611439(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetExternalModels_611438(path: JsonNode; query: JsonNode;
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
  var valid_611440 = query.getOrDefault("nextToken")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "nextToken", valid_611440
  var valid_611441 = query.getOrDefault("maxResults")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "maxResults", valid_611441
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
  var valid_611442 = header.getOrDefault("X-Amz-Target")
  valid_611442 = validateParameter(valid_611442, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetExternalModels"))
  if valid_611442 != nil:
    section.add "X-Amz-Target", valid_611442
  var valid_611443 = header.getOrDefault("X-Amz-Signature")
  valid_611443 = validateParameter(valid_611443, JString, required = false,
                                 default = nil)
  if valid_611443 != nil:
    section.add "X-Amz-Signature", valid_611443
  var valid_611444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611444 = validateParameter(valid_611444, JString, required = false,
                                 default = nil)
  if valid_611444 != nil:
    section.add "X-Amz-Content-Sha256", valid_611444
  var valid_611445 = header.getOrDefault("X-Amz-Date")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "X-Amz-Date", valid_611445
  var valid_611446 = header.getOrDefault("X-Amz-Credential")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "X-Amz-Credential", valid_611446
  var valid_611447 = header.getOrDefault("X-Amz-Security-Token")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "X-Amz-Security-Token", valid_611447
  var valid_611448 = header.getOrDefault("X-Amz-Algorithm")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "X-Amz-Algorithm", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-SignedHeaders", valid_611449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611451: Call_GetExternalModels_611437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the details for one or more Amazon SageMaker models that have been imported into the service. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetExternalModelsResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ## 
  let valid = call_611451.validator(path, query, header, formData, body)
  let scheme = call_611451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611451.url(scheme.get, call_611451.host, call_611451.base,
                         call_611451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611451, url, valid)

proc call*(call_611452: Call_GetExternalModels_611437; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getExternalModels
  ## Gets the details for one or more Amazon SageMaker models that have been imported into the service. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetExternalModelsResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611453 = newJObject()
  var body_611454 = newJObject()
  add(query_611453, "nextToken", newJString(nextToken))
  if body != nil:
    body_611454 = body
  add(query_611453, "maxResults", newJString(maxResults))
  result = call_611452.call(nil, query_611453, nil, nil, body_611454)

var getExternalModels* = Call_GetExternalModels_611437(name: "getExternalModels",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetExternalModels",
    validator: validate_GetExternalModels_611438, base: "/",
    url: url_GetExternalModels_611439, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelVersion_611455 = ref object of OpenApiRestCall_610658
proc url_GetModelVersion_611457(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModelVersion_611456(path: JsonNode; query: JsonNode;
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
  var valid_611458 = header.getOrDefault("X-Amz-Target")
  valid_611458 = validateParameter(valid_611458, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetModelVersion"))
  if valid_611458 != nil:
    section.add "X-Amz-Target", valid_611458
  var valid_611459 = header.getOrDefault("X-Amz-Signature")
  valid_611459 = validateParameter(valid_611459, JString, required = false,
                                 default = nil)
  if valid_611459 != nil:
    section.add "X-Amz-Signature", valid_611459
  var valid_611460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611460 = validateParameter(valid_611460, JString, required = false,
                                 default = nil)
  if valid_611460 != nil:
    section.add "X-Amz-Content-Sha256", valid_611460
  var valid_611461 = header.getOrDefault("X-Amz-Date")
  valid_611461 = validateParameter(valid_611461, JString, required = false,
                                 default = nil)
  if valid_611461 != nil:
    section.add "X-Amz-Date", valid_611461
  var valid_611462 = header.getOrDefault("X-Amz-Credential")
  valid_611462 = validateParameter(valid_611462, JString, required = false,
                                 default = nil)
  if valid_611462 != nil:
    section.add "X-Amz-Credential", valid_611462
  var valid_611463 = header.getOrDefault("X-Amz-Security-Token")
  valid_611463 = validateParameter(valid_611463, JString, required = false,
                                 default = nil)
  if valid_611463 != nil:
    section.add "X-Amz-Security-Token", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-Algorithm")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Algorithm", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-SignedHeaders", valid_611465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611467: Call_GetModelVersion_611455; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a model version. 
  ## 
  let valid = call_611467.validator(path, query, header, formData, body)
  let scheme = call_611467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611467.url(scheme.get, call_611467.host, call_611467.base,
                         call_611467.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611467, url, valid)

proc call*(call_611468: Call_GetModelVersion_611455; body: JsonNode): Recallable =
  ## getModelVersion
  ## Gets a model version. 
  ##   body: JObject (required)
  var body_611469 = newJObject()
  if body != nil:
    body_611469 = body
  result = call_611468.call(nil, nil, nil, nil, body_611469)

var getModelVersion* = Call_GetModelVersion_611455(name: "getModelVersion",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetModelVersion",
    validator: validate_GetModelVersion_611456, base: "/", url: url_GetModelVersion_611457,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_611470 = ref object of OpenApiRestCall_610658
proc url_GetModels_611472(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModels_611471(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611473 = query.getOrDefault("nextToken")
  valid_611473 = validateParameter(valid_611473, JString, required = false,
                                 default = nil)
  if valid_611473 != nil:
    section.add "nextToken", valid_611473
  var valid_611474 = query.getOrDefault("maxResults")
  valid_611474 = validateParameter(valid_611474, JString, required = false,
                                 default = nil)
  if valid_611474 != nil:
    section.add "maxResults", valid_611474
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
  var valid_611475 = header.getOrDefault("X-Amz-Target")
  valid_611475 = validateParameter(valid_611475, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetModels"))
  if valid_611475 != nil:
    section.add "X-Amz-Target", valid_611475
  var valid_611476 = header.getOrDefault("X-Amz-Signature")
  valid_611476 = validateParameter(valid_611476, JString, required = false,
                                 default = nil)
  if valid_611476 != nil:
    section.add "X-Amz-Signature", valid_611476
  var valid_611477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611477 = validateParameter(valid_611477, JString, required = false,
                                 default = nil)
  if valid_611477 != nil:
    section.add "X-Amz-Content-Sha256", valid_611477
  var valid_611478 = header.getOrDefault("X-Amz-Date")
  valid_611478 = validateParameter(valid_611478, JString, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "X-Amz-Date", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-Credential")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Credential", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-Security-Token")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Security-Token", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-Algorithm")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Algorithm", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-SignedHeaders", valid_611482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611484: Call_GetModels_611470; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all of the models for the AWS account, or the specified model type, or gets a single model for the specified model type, model ID combination. 
  ## 
  let valid = call_611484.validator(path, query, header, formData, body)
  let scheme = call_611484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611484.url(scheme.get, call_611484.host, call_611484.base,
                         call_611484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611484, url, valid)

proc call*(call_611485: Call_GetModels_611470; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getModels
  ## Gets all of the models for the AWS account, or the specified model type, or gets a single model for the specified model type, model ID combination. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611486 = newJObject()
  var body_611487 = newJObject()
  add(query_611486, "nextToken", newJString(nextToken))
  if body != nil:
    body_611487 = body
  add(query_611486, "maxResults", newJString(maxResults))
  result = call_611485.call(nil, query_611486, nil, nil, body_611487)

var getModels* = Call_GetModels_611470(name: "getModels", meth: HttpMethod.HttpPost,
                                    host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetModels",
                                    validator: validate_GetModels_611471,
                                    base: "/", url: url_GetModels_611472,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOutcomes_611488 = ref object of OpenApiRestCall_610658
proc url_GetOutcomes_611490(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOutcomes_611489(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611491 = query.getOrDefault("nextToken")
  valid_611491 = validateParameter(valid_611491, JString, required = false,
                                 default = nil)
  if valid_611491 != nil:
    section.add "nextToken", valid_611491
  var valid_611492 = query.getOrDefault("maxResults")
  valid_611492 = validateParameter(valid_611492, JString, required = false,
                                 default = nil)
  if valid_611492 != nil:
    section.add "maxResults", valid_611492
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
  var valid_611493 = header.getOrDefault("X-Amz-Target")
  valid_611493 = validateParameter(valid_611493, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetOutcomes"))
  if valid_611493 != nil:
    section.add "X-Amz-Target", valid_611493
  var valid_611494 = header.getOrDefault("X-Amz-Signature")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "X-Amz-Signature", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-Content-Sha256", valid_611495
  var valid_611496 = header.getOrDefault("X-Amz-Date")
  valid_611496 = validateParameter(valid_611496, JString, required = false,
                                 default = nil)
  if valid_611496 != nil:
    section.add "X-Amz-Date", valid_611496
  var valid_611497 = header.getOrDefault("X-Amz-Credential")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "X-Amz-Credential", valid_611497
  var valid_611498 = header.getOrDefault("X-Amz-Security-Token")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Security-Token", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Algorithm")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Algorithm", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-SignedHeaders", valid_611500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611502: Call_GetOutcomes_611488; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets one or more outcomes. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 50 and 100. To get the next page results, provide the pagination token from the <code>GetOutcomesResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ## 
  let valid = call_611502.validator(path, query, header, formData, body)
  let scheme = call_611502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611502.url(scheme.get, call_611502.host, call_611502.base,
                         call_611502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611502, url, valid)

proc call*(call_611503: Call_GetOutcomes_611488; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getOutcomes
  ## Gets one or more outcomes. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 50 and 100. To get the next page results, provide the pagination token from the <code>GetOutcomesResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611504 = newJObject()
  var body_611505 = newJObject()
  add(query_611504, "nextToken", newJString(nextToken))
  if body != nil:
    body_611505 = body
  add(query_611504, "maxResults", newJString(maxResults))
  result = call_611503.call(nil, query_611504, nil, nil, body_611505)

var getOutcomes* = Call_GetOutcomes_611488(name: "getOutcomes",
                                        meth: HttpMethod.HttpPost,
                                        host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetOutcomes",
                                        validator: validate_GetOutcomes_611489,
                                        base: "/", url: url_GetOutcomes_611490,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPrediction_611506 = ref object of OpenApiRestCall_610658
proc url_GetPrediction_611508(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPrediction_611507(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611509 = header.getOrDefault("X-Amz-Target")
  valid_611509 = validateParameter(valid_611509, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetPrediction"))
  if valid_611509 != nil:
    section.add "X-Amz-Target", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-Signature")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-Signature", valid_611510
  var valid_611511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "X-Amz-Content-Sha256", valid_611511
  var valid_611512 = header.getOrDefault("X-Amz-Date")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Date", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-Credential")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Credential", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-Security-Token")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Security-Token", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-Algorithm")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-Algorithm", valid_611515
  var valid_611516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "X-Amz-SignedHeaders", valid_611516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611518: Call_GetPrediction_611506; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Evaluates an event against a detector version. If a version ID is not provided, the detector’s (<code>ACTIVE</code>) version is used. 
  ## 
  let valid = call_611518.validator(path, query, header, formData, body)
  let scheme = call_611518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611518.url(scheme.get, call_611518.host, call_611518.base,
                         call_611518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611518, url, valid)

proc call*(call_611519: Call_GetPrediction_611506; body: JsonNode): Recallable =
  ## getPrediction
  ## Evaluates an event against a detector version. If a version ID is not provided, the detector’s (<code>ACTIVE</code>) version is used. 
  ##   body: JObject (required)
  var body_611520 = newJObject()
  if body != nil:
    body_611520 = body
  result = call_611519.call(nil, nil, nil, nil, body_611520)

var getPrediction* = Call_GetPrediction_611506(name: "getPrediction",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetPrediction",
    validator: validate_GetPrediction_611507, base: "/", url: url_GetPrediction_611508,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRules_611521 = ref object of OpenApiRestCall_610658
proc url_GetRules_611523(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRules_611522(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611524 = query.getOrDefault("nextToken")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "nextToken", valid_611524
  var valid_611525 = query.getOrDefault("maxResults")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "maxResults", valid_611525
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
  var valid_611526 = header.getOrDefault("X-Amz-Target")
  valid_611526 = validateParameter(valid_611526, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetRules"))
  if valid_611526 != nil:
    section.add "X-Amz-Target", valid_611526
  var valid_611527 = header.getOrDefault("X-Amz-Signature")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "X-Amz-Signature", valid_611527
  var valid_611528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "X-Amz-Content-Sha256", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-Date")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-Date", valid_611529
  var valid_611530 = header.getOrDefault("X-Amz-Credential")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-Credential", valid_611530
  var valid_611531 = header.getOrDefault("X-Amz-Security-Token")
  valid_611531 = validateParameter(valid_611531, JString, required = false,
                                 default = nil)
  if valid_611531 != nil:
    section.add "X-Amz-Security-Token", valid_611531
  var valid_611532 = header.getOrDefault("X-Amz-Algorithm")
  valid_611532 = validateParameter(valid_611532, JString, required = false,
                                 default = nil)
  if valid_611532 != nil:
    section.add "X-Amz-Algorithm", valid_611532
  var valid_611533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611533 = validateParameter(valid_611533, JString, required = false,
                                 default = nil)
  if valid_611533 != nil:
    section.add "X-Amz-SignedHeaders", valid_611533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611535: Call_GetRules_611521; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all rules available for the specified detector.
  ## 
  let valid = call_611535.validator(path, query, header, formData, body)
  let scheme = call_611535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611535.url(scheme.get, call_611535.host, call_611535.base,
                         call_611535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611535, url, valid)

proc call*(call_611536: Call_GetRules_611521; body: JsonNode; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getRules
  ## Gets all rules available for the specified detector.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611537 = newJObject()
  var body_611538 = newJObject()
  add(query_611537, "nextToken", newJString(nextToken))
  if body != nil:
    body_611538 = body
  add(query_611537, "maxResults", newJString(maxResults))
  result = call_611536.call(nil, query_611537, nil, nil, body_611538)

var getRules* = Call_GetRules_611521(name: "getRules", meth: HttpMethod.HttpPost,
                                  host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetRules",
                                  validator: validate_GetRules_611522, base: "/",
                                  url: url_GetRules_611523,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVariables_611539 = ref object of OpenApiRestCall_610658
proc url_GetVariables_611541(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetVariables_611540(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611542 = query.getOrDefault("nextToken")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "nextToken", valid_611542
  var valid_611543 = query.getOrDefault("maxResults")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "maxResults", valid_611543
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
  var valid_611544 = header.getOrDefault("X-Amz-Target")
  valid_611544 = validateParameter(valid_611544, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetVariables"))
  if valid_611544 != nil:
    section.add "X-Amz-Target", valid_611544
  var valid_611545 = header.getOrDefault("X-Amz-Signature")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-Signature", valid_611545
  var valid_611546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611546 = validateParameter(valid_611546, JString, required = false,
                                 default = nil)
  if valid_611546 != nil:
    section.add "X-Amz-Content-Sha256", valid_611546
  var valid_611547 = header.getOrDefault("X-Amz-Date")
  valid_611547 = validateParameter(valid_611547, JString, required = false,
                                 default = nil)
  if valid_611547 != nil:
    section.add "X-Amz-Date", valid_611547
  var valid_611548 = header.getOrDefault("X-Amz-Credential")
  valid_611548 = validateParameter(valid_611548, JString, required = false,
                                 default = nil)
  if valid_611548 != nil:
    section.add "X-Amz-Credential", valid_611548
  var valid_611549 = header.getOrDefault("X-Amz-Security-Token")
  valid_611549 = validateParameter(valid_611549, JString, required = false,
                                 default = nil)
  if valid_611549 != nil:
    section.add "X-Amz-Security-Token", valid_611549
  var valid_611550 = header.getOrDefault("X-Amz-Algorithm")
  valid_611550 = validateParameter(valid_611550, JString, required = false,
                                 default = nil)
  if valid_611550 != nil:
    section.add "X-Amz-Algorithm", valid_611550
  var valid_611551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611551 = validateParameter(valid_611551, JString, required = false,
                                 default = nil)
  if valid_611551 != nil:
    section.add "X-Amz-SignedHeaders", valid_611551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611553: Call_GetVariables_611539; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all of the variables or the specific variable. This is a paginated API. Providing null <code>maxSizePerPage</code> results in retrieving maximum of 100 records per page. If you provide <code>maxSizePerPage</code> the value must be between 50 and 100. To get the next page result, a provide a pagination token from <code>GetVariablesResult</code> as part of your request. Null pagination token fetches the records from the beginning. 
  ## 
  let valid = call_611553.validator(path, query, header, formData, body)
  let scheme = call_611553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611553.url(scheme.get, call_611553.host, call_611553.base,
                         call_611553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611553, url, valid)

proc call*(call_611554: Call_GetVariables_611539; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getVariables
  ## Gets all of the variables or the specific variable. This is a paginated API. Providing null <code>maxSizePerPage</code> results in retrieving maximum of 100 records per page. If you provide <code>maxSizePerPage</code> the value must be between 50 and 100. To get the next page result, a provide a pagination token from <code>GetVariablesResult</code> as part of your request. Null pagination token fetches the records from the beginning. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611555 = newJObject()
  var body_611556 = newJObject()
  add(query_611555, "nextToken", newJString(nextToken))
  if body != nil:
    body_611556 = body
  add(query_611555, "maxResults", newJString(maxResults))
  result = call_611554.call(nil, query_611555, nil, nil, body_611556)

var getVariables* = Call_GetVariables_611539(name: "getVariables",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetVariables",
    validator: validate_GetVariables_611540, base: "/", url: url_GetVariables_611541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDetector_611557 = ref object of OpenApiRestCall_610658
proc url_PutDetector_611559(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutDetector_611558(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611560 = header.getOrDefault("X-Amz-Target")
  valid_611560 = validateParameter(valid_611560, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.PutDetector"))
  if valid_611560 != nil:
    section.add "X-Amz-Target", valid_611560
  var valid_611561 = header.getOrDefault("X-Amz-Signature")
  valid_611561 = validateParameter(valid_611561, JString, required = false,
                                 default = nil)
  if valid_611561 != nil:
    section.add "X-Amz-Signature", valid_611561
  var valid_611562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611562 = validateParameter(valid_611562, JString, required = false,
                                 default = nil)
  if valid_611562 != nil:
    section.add "X-Amz-Content-Sha256", valid_611562
  var valid_611563 = header.getOrDefault("X-Amz-Date")
  valid_611563 = validateParameter(valid_611563, JString, required = false,
                                 default = nil)
  if valid_611563 != nil:
    section.add "X-Amz-Date", valid_611563
  var valid_611564 = header.getOrDefault("X-Amz-Credential")
  valid_611564 = validateParameter(valid_611564, JString, required = false,
                                 default = nil)
  if valid_611564 != nil:
    section.add "X-Amz-Credential", valid_611564
  var valid_611565 = header.getOrDefault("X-Amz-Security-Token")
  valid_611565 = validateParameter(valid_611565, JString, required = false,
                                 default = nil)
  if valid_611565 != nil:
    section.add "X-Amz-Security-Token", valid_611565
  var valid_611566 = header.getOrDefault("X-Amz-Algorithm")
  valid_611566 = validateParameter(valid_611566, JString, required = false,
                                 default = nil)
  if valid_611566 != nil:
    section.add "X-Amz-Algorithm", valid_611566
  var valid_611567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611567 = validateParameter(valid_611567, JString, required = false,
                                 default = nil)
  if valid_611567 != nil:
    section.add "X-Amz-SignedHeaders", valid_611567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611569: Call_PutDetector_611557; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a detector. 
  ## 
  let valid = call_611569.validator(path, query, header, formData, body)
  let scheme = call_611569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611569.url(scheme.get, call_611569.host, call_611569.base,
                         call_611569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611569, url, valid)

proc call*(call_611570: Call_PutDetector_611557; body: JsonNode): Recallable =
  ## putDetector
  ## Creates or updates a detector. 
  ##   body: JObject (required)
  var body_611571 = newJObject()
  if body != nil:
    body_611571 = body
  result = call_611570.call(nil, nil, nil, nil, body_611571)

var putDetector* = Call_PutDetector_611557(name: "putDetector",
                                        meth: HttpMethod.HttpPost,
                                        host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.PutDetector",
                                        validator: validate_PutDetector_611558,
                                        base: "/", url: url_PutDetector_611559,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutExternalModel_611572 = ref object of OpenApiRestCall_610658
proc url_PutExternalModel_611574(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutExternalModel_611573(path: JsonNode; query: JsonNode;
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
  var valid_611575 = header.getOrDefault("X-Amz-Target")
  valid_611575 = validateParameter(valid_611575, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.PutExternalModel"))
  if valid_611575 != nil:
    section.add "X-Amz-Target", valid_611575
  var valid_611576 = header.getOrDefault("X-Amz-Signature")
  valid_611576 = validateParameter(valid_611576, JString, required = false,
                                 default = nil)
  if valid_611576 != nil:
    section.add "X-Amz-Signature", valid_611576
  var valid_611577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611577 = validateParameter(valid_611577, JString, required = false,
                                 default = nil)
  if valid_611577 != nil:
    section.add "X-Amz-Content-Sha256", valid_611577
  var valid_611578 = header.getOrDefault("X-Amz-Date")
  valid_611578 = validateParameter(valid_611578, JString, required = false,
                                 default = nil)
  if valid_611578 != nil:
    section.add "X-Amz-Date", valid_611578
  var valid_611579 = header.getOrDefault("X-Amz-Credential")
  valid_611579 = validateParameter(valid_611579, JString, required = false,
                                 default = nil)
  if valid_611579 != nil:
    section.add "X-Amz-Credential", valid_611579
  var valid_611580 = header.getOrDefault("X-Amz-Security-Token")
  valid_611580 = validateParameter(valid_611580, JString, required = false,
                                 default = nil)
  if valid_611580 != nil:
    section.add "X-Amz-Security-Token", valid_611580
  var valid_611581 = header.getOrDefault("X-Amz-Algorithm")
  valid_611581 = validateParameter(valid_611581, JString, required = false,
                                 default = nil)
  if valid_611581 != nil:
    section.add "X-Amz-Algorithm", valid_611581
  var valid_611582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611582 = validateParameter(valid_611582, JString, required = false,
                                 default = nil)
  if valid_611582 != nil:
    section.add "X-Amz-SignedHeaders", valid_611582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611584: Call_PutExternalModel_611572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates an Amazon SageMaker model endpoint. You can also use this action to update the configuration of the model endpoint, including the IAM role and/or the mapped variables. 
  ## 
  let valid = call_611584.validator(path, query, header, formData, body)
  let scheme = call_611584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611584.url(scheme.get, call_611584.host, call_611584.base,
                         call_611584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611584, url, valid)

proc call*(call_611585: Call_PutExternalModel_611572; body: JsonNode): Recallable =
  ## putExternalModel
  ## Creates or updates an Amazon SageMaker model endpoint. You can also use this action to update the configuration of the model endpoint, including the IAM role and/or the mapped variables. 
  ##   body: JObject (required)
  var body_611586 = newJObject()
  if body != nil:
    body_611586 = body
  result = call_611585.call(nil, nil, nil, nil, body_611586)

var putExternalModel* = Call_PutExternalModel_611572(name: "putExternalModel",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.PutExternalModel",
    validator: validate_PutExternalModel_611573, base: "/",
    url: url_PutExternalModel_611574, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutModel_611587 = ref object of OpenApiRestCall_610658
proc url_PutModel_611589(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutModel_611588(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611590 = header.getOrDefault("X-Amz-Target")
  valid_611590 = validateParameter(valid_611590, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.PutModel"))
  if valid_611590 != nil:
    section.add "X-Amz-Target", valid_611590
  var valid_611591 = header.getOrDefault("X-Amz-Signature")
  valid_611591 = validateParameter(valid_611591, JString, required = false,
                                 default = nil)
  if valid_611591 != nil:
    section.add "X-Amz-Signature", valid_611591
  var valid_611592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611592 = validateParameter(valid_611592, JString, required = false,
                                 default = nil)
  if valid_611592 != nil:
    section.add "X-Amz-Content-Sha256", valid_611592
  var valid_611593 = header.getOrDefault("X-Amz-Date")
  valid_611593 = validateParameter(valid_611593, JString, required = false,
                                 default = nil)
  if valid_611593 != nil:
    section.add "X-Amz-Date", valid_611593
  var valid_611594 = header.getOrDefault("X-Amz-Credential")
  valid_611594 = validateParameter(valid_611594, JString, required = false,
                                 default = nil)
  if valid_611594 != nil:
    section.add "X-Amz-Credential", valid_611594
  var valid_611595 = header.getOrDefault("X-Amz-Security-Token")
  valid_611595 = validateParameter(valid_611595, JString, required = false,
                                 default = nil)
  if valid_611595 != nil:
    section.add "X-Amz-Security-Token", valid_611595
  var valid_611596 = header.getOrDefault("X-Amz-Algorithm")
  valid_611596 = validateParameter(valid_611596, JString, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "X-Amz-Algorithm", valid_611596
  var valid_611597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611597 = validateParameter(valid_611597, JString, required = false,
                                 default = nil)
  if valid_611597 != nil:
    section.add "X-Amz-SignedHeaders", valid_611597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611599: Call_PutModel_611587; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a model. 
  ## 
  let valid = call_611599.validator(path, query, header, formData, body)
  let scheme = call_611599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611599.url(scheme.get, call_611599.host, call_611599.base,
                         call_611599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611599, url, valid)

proc call*(call_611600: Call_PutModel_611587; body: JsonNode): Recallable =
  ## putModel
  ## Creates or updates a model. 
  ##   body: JObject (required)
  var body_611601 = newJObject()
  if body != nil:
    body_611601 = body
  result = call_611600.call(nil, nil, nil, nil, body_611601)

var putModel* = Call_PutModel_611587(name: "putModel", meth: HttpMethod.HttpPost,
                                  host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.PutModel",
                                  validator: validate_PutModel_611588, base: "/",
                                  url: url_PutModel_611589,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutOutcome_611602 = ref object of OpenApiRestCall_610658
proc url_PutOutcome_611604(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutOutcome_611603(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611605 = header.getOrDefault("X-Amz-Target")
  valid_611605 = validateParameter(valid_611605, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.PutOutcome"))
  if valid_611605 != nil:
    section.add "X-Amz-Target", valid_611605
  var valid_611606 = header.getOrDefault("X-Amz-Signature")
  valid_611606 = validateParameter(valid_611606, JString, required = false,
                                 default = nil)
  if valid_611606 != nil:
    section.add "X-Amz-Signature", valid_611606
  var valid_611607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611607 = validateParameter(valid_611607, JString, required = false,
                                 default = nil)
  if valid_611607 != nil:
    section.add "X-Amz-Content-Sha256", valid_611607
  var valid_611608 = header.getOrDefault("X-Amz-Date")
  valid_611608 = validateParameter(valid_611608, JString, required = false,
                                 default = nil)
  if valid_611608 != nil:
    section.add "X-Amz-Date", valid_611608
  var valid_611609 = header.getOrDefault("X-Amz-Credential")
  valid_611609 = validateParameter(valid_611609, JString, required = false,
                                 default = nil)
  if valid_611609 != nil:
    section.add "X-Amz-Credential", valid_611609
  var valid_611610 = header.getOrDefault("X-Amz-Security-Token")
  valid_611610 = validateParameter(valid_611610, JString, required = false,
                                 default = nil)
  if valid_611610 != nil:
    section.add "X-Amz-Security-Token", valid_611610
  var valid_611611 = header.getOrDefault("X-Amz-Algorithm")
  valid_611611 = validateParameter(valid_611611, JString, required = false,
                                 default = nil)
  if valid_611611 != nil:
    section.add "X-Amz-Algorithm", valid_611611
  var valid_611612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611612 = validateParameter(valid_611612, JString, required = false,
                                 default = nil)
  if valid_611612 != nil:
    section.add "X-Amz-SignedHeaders", valid_611612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611614: Call_PutOutcome_611602; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates an outcome. 
  ## 
  let valid = call_611614.validator(path, query, header, formData, body)
  let scheme = call_611614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611614.url(scheme.get, call_611614.host, call_611614.base,
                         call_611614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611614, url, valid)

proc call*(call_611615: Call_PutOutcome_611602; body: JsonNode): Recallable =
  ## putOutcome
  ## Creates or updates an outcome. 
  ##   body: JObject (required)
  var body_611616 = newJObject()
  if body != nil:
    body_611616 = body
  result = call_611615.call(nil, nil, nil, nil, body_611616)

var putOutcome* = Call_PutOutcome_611602(name: "putOutcome",
                                      meth: HttpMethod.HttpPost,
                                      host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.PutOutcome",
                                      validator: validate_PutOutcome_611603,
                                      base: "/", url: url_PutOutcome_611604,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorVersion_611617 = ref object of OpenApiRestCall_610658
proc url_UpdateDetectorVersion_611619(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDetectorVersion_611618(path: JsonNode; query: JsonNode;
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
  var valid_611620 = header.getOrDefault("X-Amz-Target")
  valid_611620 = validateParameter(valid_611620, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateDetectorVersion"))
  if valid_611620 != nil:
    section.add "X-Amz-Target", valid_611620
  var valid_611621 = header.getOrDefault("X-Amz-Signature")
  valid_611621 = validateParameter(valid_611621, JString, required = false,
                                 default = nil)
  if valid_611621 != nil:
    section.add "X-Amz-Signature", valid_611621
  var valid_611622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611622 = validateParameter(valid_611622, JString, required = false,
                                 default = nil)
  if valid_611622 != nil:
    section.add "X-Amz-Content-Sha256", valid_611622
  var valid_611623 = header.getOrDefault("X-Amz-Date")
  valid_611623 = validateParameter(valid_611623, JString, required = false,
                                 default = nil)
  if valid_611623 != nil:
    section.add "X-Amz-Date", valid_611623
  var valid_611624 = header.getOrDefault("X-Amz-Credential")
  valid_611624 = validateParameter(valid_611624, JString, required = false,
                                 default = nil)
  if valid_611624 != nil:
    section.add "X-Amz-Credential", valid_611624
  var valid_611625 = header.getOrDefault("X-Amz-Security-Token")
  valid_611625 = validateParameter(valid_611625, JString, required = false,
                                 default = nil)
  if valid_611625 != nil:
    section.add "X-Amz-Security-Token", valid_611625
  var valid_611626 = header.getOrDefault("X-Amz-Algorithm")
  valid_611626 = validateParameter(valid_611626, JString, required = false,
                                 default = nil)
  if valid_611626 != nil:
    section.add "X-Amz-Algorithm", valid_611626
  var valid_611627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611627 = validateParameter(valid_611627, JString, required = false,
                                 default = nil)
  if valid_611627 != nil:
    section.add "X-Amz-SignedHeaders", valid_611627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611629: Call_UpdateDetectorVersion_611617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates a detector version. The detector version attributes that you can update include models, external model endpoints, rules, and description. You can only update a <code>DRAFT</code> detector version.
  ## 
  let valid = call_611629.validator(path, query, header, formData, body)
  let scheme = call_611629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611629.url(scheme.get, call_611629.host, call_611629.base,
                         call_611629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611629, url, valid)

proc call*(call_611630: Call_UpdateDetectorVersion_611617; body: JsonNode): Recallable =
  ## updateDetectorVersion
  ##  Updates a detector version. The detector version attributes that you can update include models, external model endpoints, rules, and description. You can only update a <code>DRAFT</code> detector version.
  ##   body: JObject (required)
  var body_611631 = newJObject()
  if body != nil:
    body_611631 = body
  result = call_611630.call(nil, nil, nil, nil, body_611631)

var updateDetectorVersion* = Call_UpdateDetectorVersion_611617(
    name: "updateDetectorVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateDetectorVersion",
    validator: validate_UpdateDetectorVersion_611618, base: "/",
    url: url_UpdateDetectorVersion_611619, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorVersionMetadata_611632 = ref object of OpenApiRestCall_610658
proc url_UpdateDetectorVersionMetadata_611634(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDetectorVersionMetadata_611633(path: JsonNode; query: JsonNode;
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
  var valid_611635 = header.getOrDefault("X-Amz-Target")
  valid_611635 = validateParameter(valid_611635, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateDetectorVersionMetadata"))
  if valid_611635 != nil:
    section.add "X-Amz-Target", valid_611635
  var valid_611636 = header.getOrDefault("X-Amz-Signature")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-Signature", valid_611636
  var valid_611637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611637 = validateParameter(valid_611637, JString, required = false,
                                 default = nil)
  if valid_611637 != nil:
    section.add "X-Amz-Content-Sha256", valid_611637
  var valid_611638 = header.getOrDefault("X-Amz-Date")
  valid_611638 = validateParameter(valid_611638, JString, required = false,
                                 default = nil)
  if valid_611638 != nil:
    section.add "X-Amz-Date", valid_611638
  var valid_611639 = header.getOrDefault("X-Amz-Credential")
  valid_611639 = validateParameter(valid_611639, JString, required = false,
                                 default = nil)
  if valid_611639 != nil:
    section.add "X-Amz-Credential", valid_611639
  var valid_611640 = header.getOrDefault("X-Amz-Security-Token")
  valid_611640 = validateParameter(valid_611640, JString, required = false,
                                 default = nil)
  if valid_611640 != nil:
    section.add "X-Amz-Security-Token", valid_611640
  var valid_611641 = header.getOrDefault("X-Amz-Algorithm")
  valid_611641 = validateParameter(valid_611641, JString, required = false,
                                 default = nil)
  if valid_611641 != nil:
    section.add "X-Amz-Algorithm", valid_611641
  var valid_611642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611642 = validateParameter(valid_611642, JString, required = false,
                                 default = nil)
  if valid_611642 != nil:
    section.add "X-Amz-SignedHeaders", valid_611642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611644: Call_UpdateDetectorVersionMetadata_611632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the detector version's description. You can update the metadata for any detector version (<code>DRAFT, ACTIVE,</code> or <code>INACTIVE</code>). 
  ## 
  let valid = call_611644.validator(path, query, header, formData, body)
  let scheme = call_611644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611644.url(scheme.get, call_611644.host, call_611644.base,
                         call_611644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611644, url, valid)

proc call*(call_611645: Call_UpdateDetectorVersionMetadata_611632; body: JsonNode): Recallable =
  ## updateDetectorVersionMetadata
  ## Updates the detector version's description. You can update the metadata for any detector version (<code>DRAFT, ACTIVE,</code> or <code>INACTIVE</code>). 
  ##   body: JObject (required)
  var body_611646 = newJObject()
  if body != nil:
    body_611646 = body
  result = call_611645.call(nil, nil, nil, nil, body_611646)

var updateDetectorVersionMetadata* = Call_UpdateDetectorVersionMetadata_611632(
    name: "updateDetectorVersionMetadata", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateDetectorVersionMetadata",
    validator: validate_UpdateDetectorVersionMetadata_611633, base: "/",
    url: url_UpdateDetectorVersionMetadata_611634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorVersionStatus_611647 = ref object of OpenApiRestCall_610658
proc url_UpdateDetectorVersionStatus_611649(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDetectorVersionStatus_611648(path: JsonNode; query: JsonNode;
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
  var valid_611650 = header.getOrDefault("X-Amz-Target")
  valid_611650 = validateParameter(valid_611650, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateDetectorVersionStatus"))
  if valid_611650 != nil:
    section.add "X-Amz-Target", valid_611650
  var valid_611651 = header.getOrDefault("X-Amz-Signature")
  valid_611651 = validateParameter(valid_611651, JString, required = false,
                                 default = nil)
  if valid_611651 != nil:
    section.add "X-Amz-Signature", valid_611651
  var valid_611652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611652 = validateParameter(valid_611652, JString, required = false,
                                 default = nil)
  if valid_611652 != nil:
    section.add "X-Amz-Content-Sha256", valid_611652
  var valid_611653 = header.getOrDefault("X-Amz-Date")
  valid_611653 = validateParameter(valid_611653, JString, required = false,
                                 default = nil)
  if valid_611653 != nil:
    section.add "X-Amz-Date", valid_611653
  var valid_611654 = header.getOrDefault("X-Amz-Credential")
  valid_611654 = validateParameter(valid_611654, JString, required = false,
                                 default = nil)
  if valid_611654 != nil:
    section.add "X-Amz-Credential", valid_611654
  var valid_611655 = header.getOrDefault("X-Amz-Security-Token")
  valid_611655 = validateParameter(valid_611655, JString, required = false,
                                 default = nil)
  if valid_611655 != nil:
    section.add "X-Amz-Security-Token", valid_611655
  var valid_611656 = header.getOrDefault("X-Amz-Algorithm")
  valid_611656 = validateParameter(valid_611656, JString, required = false,
                                 default = nil)
  if valid_611656 != nil:
    section.add "X-Amz-Algorithm", valid_611656
  var valid_611657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611657 = validateParameter(valid_611657, JString, required = false,
                                 default = nil)
  if valid_611657 != nil:
    section.add "X-Amz-SignedHeaders", valid_611657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611659: Call_UpdateDetectorVersionStatus_611647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the detector version’s status. You can perform the following promotions or demotions using <code>UpdateDetectorVersionStatus</code>: <code>DRAFT</code> to <code>ACTIVE</code>, <code>ACTIVE</code> to <code>INACTIVE</code>, and <code>INACTIVE</code> to <code>ACTIVE</code>.
  ## 
  let valid = call_611659.validator(path, query, header, formData, body)
  let scheme = call_611659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611659.url(scheme.get, call_611659.host, call_611659.base,
                         call_611659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611659, url, valid)

proc call*(call_611660: Call_UpdateDetectorVersionStatus_611647; body: JsonNode): Recallable =
  ## updateDetectorVersionStatus
  ## Updates the detector version’s status. You can perform the following promotions or demotions using <code>UpdateDetectorVersionStatus</code>: <code>DRAFT</code> to <code>ACTIVE</code>, <code>ACTIVE</code> to <code>INACTIVE</code>, and <code>INACTIVE</code> to <code>ACTIVE</code>.
  ##   body: JObject (required)
  var body_611661 = newJObject()
  if body != nil:
    body_611661 = body
  result = call_611660.call(nil, nil, nil, nil, body_611661)

var updateDetectorVersionStatus* = Call_UpdateDetectorVersionStatus_611647(
    name: "updateDetectorVersionStatus", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateDetectorVersionStatus",
    validator: validate_UpdateDetectorVersionStatus_611648, base: "/",
    url: url_UpdateDetectorVersionStatus_611649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModelVersion_611662 = ref object of OpenApiRestCall_610658
proc url_UpdateModelVersion_611664(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateModelVersion_611663(path: JsonNode; query: JsonNode;
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
  var valid_611665 = header.getOrDefault("X-Amz-Target")
  valid_611665 = validateParameter(valid_611665, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateModelVersion"))
  if valid_611665 != nil:
    section.add "X-Amz-Target", valid_611665
  var valid_611666 = header.getOrDefault("X-Amz-Signature")
  valid_611666 = validateParameter(valid_611666, JString, required = false,
                                 default = nil)
  if valid_611666 != nil:
    section.add "X-Amz-Signature", valid_611666
  var valid_611667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611667 = validateParameter(valid_611667, JString, required = false,
                                 default = nil)
  if valid_611667 != nil:
    section.add "X-Amz-Content-Sha256", valid_611667
  var valid_611668 = header.getOrDefault("X-Amz-Date")
  valid_611668 = validateParameter(valid_611668, JString, required = false,
                                 default = nil)
  if valid_611668 != nil:
    section.add "X-Amz-Date", valid_611668
  var valid_611669 = header.getOrDefault("X-Amz-Credential")
  valid_611669 = validateParameter(valid_611669, JString, required = false,
                                 default = nil)
  if valid_611669 != nil:
    section.add "X-Amz-Credential", valid_611669
  var valid_611670 = header.getOrDefault("X-Amz-Security-Token")
  valid_611670 = validateParameter(valid_611670, JString, required = false,
                                 default = nil)
  if valid_611670 != nil:
    section.add "X-Amz-Security-Token", valid_611670
  var valid_611671 = header.getOrDefault("X-Amz-Algorithm")
  valid_611671 = validateParameter(valid_611671, JString, required = false,
                                 default = nil)
  if valid_611671 != nil:
    section.add "X-Amz-Algorithm", valid_611671
  var valid_611672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611672 = validateParameter(valid_611672, JString, required = false,
                                 default = nil)
  if valid_611672 != nil:
    section.add "X-Amz-SignedHeaders", valid_611672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611674: Call_UpdateModelVersion_611662; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a model version. You can update the description and status attributes using this action. You can perform the following status updates: </p> <ol> <li> <p>Change the <code>TRAINING_COMPLETE</code> status to <code>ACTIVE</code> </p> </li> <li> <p>Change <code>ACTIVE</code> back to <code>TRAINING_COMPLETE</code> </p> </li> </ol>
  ## 
  let valid = call_611674.validator(path, query, header, formData, body)
  let scheme = call_611674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611674.url(scheme.get, call_611674.host, call_611674.base,
                         call_611674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611674, url, valid)

proc call*(call_611675: Call_UpdateModelVersion_611662; body: JsonNode): Recallable =
  ## updateModelVersion
  ## <p>Updates a model version. You can update the description and status attributes using this action. You can perform the following status updates: </p> <ol> <li> <p>Change the <code>TRAINING_COMPLETE</code> status to <code>ACTIVE</code> </p> </li> <li> <p>Change <code>ACTIVE</code> back to <code>TRAINING_COMPLETE</code> </p> </li> </ol>
  ##   body: JObject (required)
  var body_611676 = newJObject()
  if body != nil:
    body_611676 = body
  result = call_611675.call(nil, nil, nil, nil, body_611676)

var updateModelVersion* = Call_UpdateModelVersion_611662(
    name: "updateModelVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateModelVersion",
    validator: validate_UpdateModelVersion_611663, base: "/",
    url: url_UpdateModelVersion_611664, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRuleMetadata_611677 = ref object of OpenApiRestCall_610658
proc url_UpdateRuleMetadata_611679(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRuleMetadata_611678(path: JsonNode; query: JsonNode;
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
  var valid_611680 = header.getOrDefault("X-Amz-Target")
  valid_611680 = validateParameter(valid_611680, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateRuleMetadata"))
  if valid_611680 != nil:
    section.add "X-Amz-Target", valid_611680
  var valid_611681 = header.getOrDefault("X-Amz-Signature")
  valid_611681 = validateParameter(valid_611681, JString, required = false,
                                 default = nil)
  if valid_611681 != nil:
    section.add "X-Amz-Signature", valid_611681
  var valid_611682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611682 = validateParameter(valid_611682, JString, required = false,
                                 default = nil)
  if valid_611682 != nil:
    section.add "X-Amz-Content-Sha256", valid_611682
  var valid_611683 = header.getOrDefault("X-Amz-Date")
  valid_611683 = validateParameter(valid_611683, JString, required = false,
                                 default = nil)
  if valid_611683 != nil:
    section.add "X-Amz-Date", valid_611683
  var valid_611684 = header.getOrDefault("X-Amz-Credential")
  valid_611684 = validateParameter(valid_611684, JString, required = false,
                                 default = nil)
  if valid_611684 != nil:
    section.add "X-Amz-Credential", valid_611684
  var valid_611685 = header.getOrDefault("X-Amz-Security-Token")
  valid_611685 = validateParameter(valid_611685, JString, required = false,
                                 default = nil)
  if valid_611685 != nil:
    section.add "X-Amz-Security-Token", valid_611685
  var valid_611686 = header.getOrDefault("X-Amz-Algorithm")
  valid_611686 = validateParameter(valid_611686, JString, required = false,
                                 default = nil)
  if valid_611686 != nil:
    section.add "X-Amz-Algorithm", valid_611686
  var valid_611687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611687 = validateParameter(valid_611687, JString, required = false,
                                 default = nil)
  if valid_611687 != nil:
    section.add "X-Amz-SignedHeaders", valid_611687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611689: Call_UpdateRuleMetadata_611677; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a rule's metadata. 
  ## 
  let valid = call_611689.validator(path, query, header, formData, body)
  let scheme = call_611689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611689.url(scheme.get, call_611689.host, call_611689.base,
                         call_611689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611689, url, valid)

proc call*(call_611690: Call_UpdateRuleMetadata_611677; body: JsonNode): Recallable =
  ## updateRuleMetadata
  ## Updates a rule's metadata. 
  ##   body: JObject (required)
  var body_611691 = newJObject()
  if body != nil:
    body_611691 = body
  result = call_611690.call(nil, nil, nil, nil, body_611691)

var updateRuleMetadata* = Call_UpdateRuleMetadata_611677(
    name: "updateRuleMetadata", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateRuleMetadata",
    validator: validate_UpdateRuleMetadata_611678, base: "/",
    url: url_UpdateRuleMetadata_611679, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRuleVersion_611692 = ref object of OpenApiRestCall_610658
proc url_UpdateRuleVersion_611694(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRuleVersion_611693(path: JsonNode; query: JsonNode;
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
  var valid_611695 = header.getOrDefault("X-Amz-Target")
  valid_611695 = validateParameter(valid_611695, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateRuleVersion"))
  if valid_611695 != nil:
    section.add "X-Amz-Target", valid_611695
  var valid_611696 = header.getOrDefault("X-Amz-Signature")
  valid_611696 = validateParameter(valid_611696, JString, required = false,
                                 default = nil)
  if valid_611696 != nil:
    section.add "X-Amz-Signature", valid_611696
  var valid_611697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611697 = validateParameter(valid_611697, JString, required = false,
                                 default = nil)
  if valid_611697 != nil:
    section.add "X-Amz-Content-Sha256", valid_611697
  var valid_611698 = header.getOrDefault("X-Amz-Date")
  valid_611698 = validateParameter(valid_611698, JString, required = false,
                                 default = nil)
  if valid_611698 != nil:
    section.add "X-Amz-Date", valid_611698
  var valid_611699 = header.getOrDefault("X-Amz-Credential")
  valid_611699 = validateParameter(valid_611699, JString, required = false,
                                 default = nil)
  if valid_611699 != nil:
    section.add "X-Amz-Credential", valid_611699
  var valid_611700 = header.getOrDefault("X-Amz-Security-Token")
  valid_611700 = validateParameter(valid_611700, JString, required = false,
                                 default = nil)
  if valid_611700 != nil:
    section.add "X-Amz-Security-Token", valid_611700
  var valid_611701 = header.getOrDefault("X-Amz-Algorithm")
  valid_611701 = validateParameter(valid_611701, JString, required = false,
                                 default = nil)
  if valid_611701 != nil:
    section.add "X-Amz-Algorithm", valid_611701
  var valid_611702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611702 = validateParameter(valid_611702, JString, required = false,
                                 default = nil)
  if valid_611702 != nil:
    section.add "X-Amz-SignedHeaders", valid_611702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611704: Call_UpdateRuleVersion_611692; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a rule version resulting in a new rule version. 
  ## 
  let valid = call_611704.validator(path, query, header, formData, body)
  let scheme = call_611704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611704.url(scheme.get, call_611704.host, call_611704.base,
                         call_611704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611704, url, valid)

proc call*(call_611705: Call_UpdateRuleVersion_611692; body: JsonNode): Recallable =
  ## updateRuleVersion
  ## Updates a rule version resulting in a new rule version. 
  ##   body: JObject (required)
  var body_611706 = newJObject()
  if body != nil:
    body_611706 = body
  result = call_611705.call(nil, nil, nil, nil, body_611706)

var updateRuleVersion* = Call_UpdateRuleVersion_611692(name: "updateRuleVersion",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateRuleVersion",
    validator: validate_UpdateRuleVersion_611693, base: "/",
    url: url_UpdateRuleVersion_611694, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVariable_611707 = ref object of OpenApiRestCall_610658
proc url_UpdateVariable_611709(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateVariable_611708(path: JsonNode; query: JsonNode;
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
  var valid_611710 = header.getOrDefault("X-Amz-Target")
  valid_611710 = validateParameter(valid_611710, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateVariable"))
  if valid_611710 != nil:
    section.add "X-Amz-Target", valid_611710
  var valid_611711 = header.getOrDefault("X-Amz-Signature")
  valid_611711 = validateParameter(valid_611711, JString, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "X-Amz-Signature", valid_611711
  var valid_611712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611712 = validateParameter(valid_611712, JString, required = false,
                                 default = nil)
  if valid_611712 != nil:
    section.add "X-Amz-Content-Sha256", valid_611712
  var valid_611713 = header.getOrDefault("X-Amz-Date")
  valid_611713 = validateParameter(valid_611713, JString, required = false,
                                 default = nil)
  if valid_611713 != nil:
    section.add "X-Amz-Date", valid_611713
  var valid_611714 = header.getOrDefault("X-Amz-Credential")
  valid_611714 = validateParameter(valid_611714, JString, required = false,
                                 default = nil)
  if valid_611714 != nil:
    section.add "X-Amz-Credential", valid_611714
  var valid_611715 = header.getOrDefault("X-Amz-Security-Token")
  valid_611715 = validateParameter(valid_611715, JString, required = false,
                                 default = nil)
  if valid_611715 != nil:
    section.add "X-Amz-Security-Token", valid_611715
  var valid_611716 = header.getOrDefault("X-Amz-Algorithm")
  valid_611716 = validateParameter(valid_611716, JString, required = false,
                                 default = nil)
  if valid_611716 != nil:
    section.add "X-Amz-Algorithm", valid_611716
  var valid_611717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611717 = validateParameter(valid_611717, JString, required = false,
                                 default = nil)
  if valid_611717 != nil:
    section.add "X-Amz-SignedHeaders", valid_611717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611719: Call_UpdateVariable_611707; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a variable.
  ## 
  let valid = call_611719.validator(path, query, header, formData, body)
  let scheme = call_611719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611719.url(scheme.get, call_611719.host, call_611719.base,
                         call_611719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611719, url, valid)

proc call*(call_611720: Call_UpdateVariable_611707; body: JsonNode): Recallable =
  ## updateVariable
  ## Updates a variable.
  ##   body: JObject (required)
  var body_611721 = newJObject()
  if body != nil:
    body_611721 = body
  result = call_611720.call(nil, nil, nil, nil, body_611721)

var updateVariable* = Call_UpdateVariable_611707(name: "updateVariable",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateVariable",
    validator: validate_UpdateVariable_611708, base: "/", url: url_UpdateVariable_611709,
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
