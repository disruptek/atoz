
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

  OpenApiRestCall_597389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_597389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_597389): Option[Scheme] {.used.} =
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
  Call_BatchCreateVariable_597727 = ref object of OpenApiRestCall_597389
proc url_BatchCreateVariable_597729(protocol: Scheme; host: string; base: string;
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

proc validate_BatchCreateVariable_597728(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_597854 = header.getOrDefault("X-Amz-Target")
  valid_597854 = validateParameter(valid_597854, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.BatchCreateVariable"))
  if valid_597854 != nil:
    section.add "X-Amz-Target", valid_597854
  var valid_597855 = header.getOrDefault("X-Amz-Signature")
  valid_597855 = validateParameter(valid_597855, JString, required = false,
                                 default = nil)
  if valid_597855 != nil:
    section.add "X-Amz-Signature", valid_597855
  var valid_597856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597856 = validateParameter(valid_597856, JString, required = false,
                                 default = nil)
  if valid_597856 != nil:
    section.add "X-Amz-Content-Sha256", valid_597856
  var valid_597857 = header.getOrDefault("X-Amz-Date")
  valid_597857 = validateParameter(valid_597857, JString, required = false,
                                 default = nil)
  if valid_597857 != nil:
    section.add "X-Amz-Date", valid_597857
  var valid_597858 = header.getOrDefault("X-Amz-Credential")
  valid_597858 = validateParameter(valid_597858, JString, required = false,
                                 default = nil)
  if valid_597858 != nil:
    section.add "X-Amz-Credential", valid_597858
  var valid_597859 = header.getOrDefault("X-Amz-Security-Token")
  valid_597859 = validateParameter(valid_597859, JString, required = false,
                                 default = nil)
  if valid_597859 != nil:
    section.add "X-Amz-Security-Token", valid_597859
  var valid_597860 = header.getOrDefault("X-Amz-Algorithm")
  valid_597860 = validateParameter(valid_597860, JString, required = false,
                                 default = nil)
  if valid_597860 != nil:
    section.add "X-Amz-Algorithm", valid_597860
  var valid_597861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597861 = validateParameter(valid_597861, JString, required = false,
                                 default = nil)
  if valid_597861 != nil:
    section.add "X-Amz-SignedHeaders", valid_597861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_597885: Call_BatchCreateVariable_597727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a batch of variables.
  ## 
  let valid = call_597885.validator(path, query, header, formData, body)
  let scheme = call_597885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597885.url(scheme.get, call_597885.host, call_597885.base,
                         call_597885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597885, url, valid)

proc call*(call_597956: Call_BatchCreateVariable_597727; body: JsonNode): Recallable =
  ## batchCreateVariable
  ## Creates a batch of variables.
  ##   body: JObject (required)
  var body_597957 = newJObject()
  if body != nil:
    body_597957 = body
  result = call_597956.call(nil, nil, nil, nil, body_597957)

var batchCreateVariable* = Call_BatchCreateVariable_597727(
    name: "batchCreateVariable", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.BatchCreateVariable",
    validator: validate_BatchCreateVariable_597728, base: "/",
    url: url_BatchCreateVariable_597729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetVariable_597996 = ref object of OpenApiRestCall_597389
proc url_BatchGetVariable_597998(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetVariable_597997(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_597999 = header.getOrDefault("X-Amz-Target")
  valid_597999 = validateParameter(valid_597999, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.BatchGetVariable"))
  if valid_597999 != nil:
    section.add "X-Amz-Target", valid_597999
  var valid_598000 = header.getOrDefault("X-Amz-Signature")
  valid_598000 = validateParameter(valid_598000, JString, required = false,
                                 default = nil)
  if valid_598000 != nil:
    section.add "X-Amz-Signature", valid_598000
  var valid_598001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598001 = validateParameter(valid_598001, JString, required = false,
                                 default = nil)
  if valid_598001 != nil:
    section.add "X-Amz-Content-Sha256", valid_598001
  var valid_598002 = header.getOrDefault("X-Amz-Date")
  valid_598002 = validateParameter(valid_598002, JString, required = false,
                                 default = nil)
  if valid_598002 != nil:
    section.add "X-Amz-Date", valid_598002
  var valid_598003 = header.getOrDefault("X-Amz-Credential")
  valid_598003 = validateParameter(valid_598003, JString, required = false,
                                 default = nil)
  if valid_598003 != nil:
    section.add "X-Amz-Credential", valid_598003
  var valid_598004 = header.getOrDefault("X-Amz-Security-Token")
  valid_598004 = validateParameter(valid_598004, JString, required = false,
                                 default = nil)
  if valid_598004 != nil:
    section.add "X-Amz-Security-Token", valid_598004
  var valid_598005 = header.getOrDefault("X-Amz-Algorithm")
  valid_598005 = validateParameter(valid_598005, JString, required = false,
                                 default = nil)
  if valid_598005 != nil:
    section.add "X-Amz-Algorithm", valid_598005
  var valid_598006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598006 = validateParameter(valid_598006, JString, required = false,
                                 default = nil)
  if valid_598006 != nil:
    section.add "X-Amz-SignedHeaders", valid_598006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598008: Call_BatchGetVariable_597996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a batch of variables.
  ## 
  let valid = call_598008.validator(path, query, header, formData, body)
  let scheme = call_598008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598008.url(scheme.get, call_598008.host, call_598008.base,
                         call_598008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598008, url, valid)

proc call*(call_598009: Call_BatchGetVariable_597996; body: JsonNode): Recallable =
  ## batchGetVariable
  ## Gets a batch of variables.
  ##   body: JObject (required)
  var body_598010 = newJObject()
  if body != nil:
    body_598010 = body
  result = call_598009.call(nil, nil, nil, nil, body_598010)

var batchGetVariable* = Call_BatchGetVariable_597996(name: "batchGetVariable",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.BatchGetVariable",
    validator: validate_BatchGetVariable_597997, base: "/",
    url: url_BatchGetVariable_597998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDetectorVersion_598011 = ref object of OpenApiRestCall_597389
proc url_CreateDetectorVersion_598013(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDetectorVersion_598012(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598014 = header.getOrDefault("X-Amz-Target")
  valid_598014 = validateParameter(valid_598014, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.CreateDetectorVersion"))
  if valid_598014 != nil:
    section.add "X-Amz-Target", valid_598014
  var valid_598015 = header.getOrDefault("X-Amz-Signature")
  valid_598015 = validateParameter(valid_598015, JString, required = false,
                                 default = nil)
  if valid_598015 != nil:
    section.add "X-Amz-Signature", valid_598015
  var valid_598016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598016 = validateParameter(valid_598016, JString, required = false,
                                 default = nil)
  if valid_598016 != nil:
    section.add "X-Amz-Content-Sha256", valid_598016
  var valid_598017 = header.getOrDefault("X-Amz-Date")
  valid_598017 = validateParameter(valid_598017, JString, required = false,
                                 default = nil)
  if valid_598017 != nil:
    section.add "X-Amz-Date", valid_598017
  var valid_598018 = header.getOrDefault("X-Amz-Credential")
  valid_598018 = validateParameter(valid_598018, JString, required = false,
                                 default = nil)
  if valid_598018 != nil:
    section.add "X-Amz-Credential", valid_598018
  var valid_598019 = header.getOrDefault("X-Amz-Security-Token")
  valid_598019 = validateParameter(valid_598019, JString, required = false,
                                 default = nil)
  if valid_598019 != nil:
    section.add "X-Amz-Security-Token", valid_598019
  var valid_598020 = header.getOrDefault("X-Amz-Algorithm")
  valid_598020 = validateParameter(valid_598020, JString, required = false,
                                 default = nil)
  if valid_598020 != nil:
    section.add "X-Amz-Algorithm", valid_598020
  var valid_598021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598021 = validateParameter(valid_598021, JString, required = false,
                                 default = nil)
  if valid_598021 != nil:
    section.add "X-Amz-SignedHeaders", valid_598021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598023: Call_CreateDetectorVersion_598011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a detector version. The detector version starts in a <code>DRAFT</code> status.
  ## 
  let valid = call_598023.validator(path, query, header, formData, body)
  let scheme = call_598023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598023.url(scheme.get, call_598023.host, call_598023.base,
                         call_598023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598023, url, valid)

proc call*(call_598024: Call_CreateDetectorVersion_598011; body: JsonNode): Recallable =
  ## createDetectorVersion
  ## Creates a detector version. The detector version starts in a <code>DRAFT</code> status.
  ##   body: JObject (required)
  var body_598025 = newJObject()
  if body != nil:
    body_598025 = body
  result = call_598024.call(nil, nil, nil, nil, body_598025)

var createDetectorVersion* = Call_CreateDetectorVersion_598011(
    name: "createDetectorVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.CreateDetectorVersion",
    validator: validate_CreateDetectorVersion_598012, base: "/",
    url: url_CreateDetectorVersion_598013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModelVersion_598026 = ref object of OpenApiRestCall_597389
proc url_CreateModelVersion_598028(protocol: Scheme; host: string; base: string;
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

proc validate_CreateModelVersion_598027(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598029 = header.getOrDefault("X-Amz-Target")
  valid_598029 = validateParameter(valid_598029, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.CreateModelVersion"))
  if valid_598029 != nil:
    section.add "X-Amz-Target", valid_598029
  var valid_598030 = header.getOrDefault("X-Amz-Signature")
  valid_598030 = validateParameter(valid_598030, JString, required = false,
                                 default = nil)
  if valid_598030 != nil:
    section.add "X-Amz-Signature", valid_598030
  var valid_598031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598031 = validateParameter(valid_598031, JString, required = false,
                                 default = nil)
  if valid_598031 != nil:
    section.add "X-Amz-Content-Sha256", valid_598031
  var valid_598032 = header.getOrDefault("X-Amz-Date")
  valid_598032 = validateParameter(valid_598032, JString, required = false,
                                 default = nil)
  if valid_598032 != nil:
    section.add "X-Amz-Date", valid_598032
  var valid_598033 = header.getOrDefault("X-Amz-Credential")
  valid_598033 = validateParameter(valid_598033, JString, required = false,
                                 default = nil)
  if valid_598033 != nil:
    section.add "X-Amz-Credential", valid_598033
  var valid_598034 = header.getOrDefault("X-Amz-Security-Token")
  valid_598034 = validateParameter(valid_598034, JString, required = false,
                                 default = nil)
  if valid_598034 != nil:
    section.add "X-Amz-Security-Token", valid_598034
  var valid_598035 = header.getOrDefault("X-Amz-Algorithm")
  valid_598035 = validateParameter(valid_598035, JString, required = false,
                                 default = nil)
  if valid_598035 != nil:
    section.add "X-Amz-Algorithm", valid_598035
  var valid_598036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598036 = validateParameter(valid_598036, JString, required = false,
                                 default = nil)
  if valid_598036 != nil:
    section.add "X-Amz-SignedHeaders", valid_598036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598038: Call_CreateModelVersion_598026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of the model using the specified model type. 
  ## 
  let valid = call_598038.validator(path, query, header, formData, body)
  let scheme = call_598038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598038.url(scheme.get, call_598038.host, call_598038.base,
                         call_598038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598038, url, valid)

proc call*(call_598039: Call_CreateModelVersion_598026; body: JsonNode): Recallable =
  ## createModelVersion
  ## Creates a version of the model using the specified model type. 
  ##   body: JObject (required)
  var body_598040 = newJObject()
  if body != nil:
    body_598040 = body
  result = call_598039.call(nil, nil, nil, nil, body_598040)

var createModelVersion* = Call_CreateModelVersion_598026(
    name: "createModelVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.CreateModelVersion",
    validator: validate_CreateModelVersion_598027, base: "/",
    url: url_CreateModelVersion_598028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRule_598041 = ref object of OpenApiRestCall_597389
proc url_CreateRule_598043(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateRule_598042(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598044 = header.getOrDefault("X-Amz-Target")
  valid_598044 = validateParameter(valid_598044, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.CreateRule"))
  if valid_598044 != nil:
    section.add "X-Amz-Target", valid_598044
  var valid_598045 = header.getOrDefault("X-Amz-Signature")
  valid_598045 = validateParameter(valid_598045, JString, required = false,
                                 default = nil)
  if valid_598045 != nil:
    section.add "X-Amz-Signature", valid_598045
  var valid_598046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598046 = validateParameter(valid_598046, JString, required = false,
                                 default = nil)
  if valid_598046 != nil:
    section.add "X-Amz-Content-Sha256", valid_598046
  var valid_598047 = header.getOrDefault("X-Amz-Date")
  valid_598047 = validateParameter(valid_598047, JString, required = false,
                                 default = nil)
  if valid_598047 != nil:
    section.add "X-Amz-Date", valid_598047
  var valid_598048 = header.getOrDefault("X-Amz-Credential")
  valid_598048 = validateParameter(valid_598048, JString, required = false,
                                 default = nil)
  if valid_598048 != nil:
    section.add "X-Amz-Credential", valid_598048
  var valid_598049 = header.getOrDefault("X-Amz-Security-Token")
  valid_598049 = validateParameter(valid_598049, JString, required = false,
                                 default = nil)
  if valid_598049 != nil:
    section.add "X-Amz-Security-Token", valid_598049
  var valid_598050 = header.getOrDefault("X-Amz-Algorithm")
  valid_598050 = validateParameter(valid_598050, JString, required = false,
                                 default = nil)
  if valid_598050 != nil:
    section.add "X-Amz-Algorithm", valid_598050
  var valid_598051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598051 = validateParameter(valid_598051, JString, required = false,
                                 default = nil)
  if valid_598051 != nil:
    section.add "X-Amz-SignedHeaders", valid_598051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598053: Call_CreateRule_598041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a rule for use with the specified detector. 
  ## 
  let valid = call_598053.validator(path, query, header, formData, body)
  let scheme = call_598053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598053.url(scheme.get, call_598053.host, call_598053.base,
                         call_598053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598053, url, valid)

proc call*(call_598054: Call_CreateRule_598041; body: JsonNode): Recallable =
  ## createRule
  ## Creates a rule for use with the specified detector. 
  ##   body: JObject (required)
  var body_598055 = newJObject()
  if body != nil:
    body_598055 = body
  result = call_598054.call(nil, nil, nil, nil, body_598055)

var createRule* = Call_CreateRule_598041(name: "createRule",
                                      meth: HttpMethod.HttpPost,
                                      host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.CreateRule",
                                      validator: validate_CreateRule_598042,
                                      base: "/", url: url_CreateRule_598043,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVariable_598056 = ref object of OpenApiRestCall_597389
proc url_CreateVariable_598058(protocol: Scheme; host: string; base: string;
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

proc validate_CreateVariable_598057(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598059 = header.getOrDefault("X-Amz-Target")
  valid_598059 = validateParameter(valid_598059, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.CreateVariable"))
  if valid_598059 != nil:
    section.add "X-Amz-Target", valid_598059
  var valid_598060 = header.getOrDefault("X-Amz-Signature")
  valid_598060 = validateParameter(valid_598060, JString, required = false,
                                 default = nil)
  if valid_598060 != nil:
    section.add "X-Amz-Signature", valid_598060
  var valid_598061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598061 = validateParameter(valid_598061, JString, required = false,
                                 default = nil)
  if valid_598061 != nil:
    section.add "X-Amz-Content-Sha256", valid_598061
  var valid_598062 = header.getOrDefault("X-Amz-Date")
  valid_598062 = validateParameter(valid_598062, JString, required = false,
                                 default = nil)
  if valid_598062 != nil:
    section.add "X-Amz-Date", valid_598062
  var valid_598063 = header.getOrDefault("X-Amz-Credential")
  valid_598063 = validateParameter(valid_598063, JString, required = false,
                                 default = nil)
  if valid_598063 != nil:
    section.add "X-Amz-Credential", valid_598063
  var valid_598064 = header.getOrDefault("X-Amz-Security-Token")
  valid_598064 = validateParameter(valid_598064, JString, required = false,
                                 default = nil)
  if valid_598064 != nil:
    section.add "X-Amz-Security-Token", valid_598064
  var valid_598065 = header.getOrDefault("X-Amz-Algorithm")
  valid_598065 = validateParameter(valid_598065, JString, required = false,
                                 default = nil)
  if valid_598065 != nil:
    section.add "X-Amz-Algorithm", valid_598065
  var valid_598066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598066 = validateParameter(valid_598066, JString, required = false,
                                 default = nil)
  if valid_598066 != nil:
    section.add "X-Amz-SignedHeaders", valid_598066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598068: Call_CreateVariable_598056; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a variable.
  ## 
  let valid = call_598068.validator(path, query, header, formData, body)
  let scheme = call_598068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598068.url(scheme.get, call_598068.host, call_598068.base,
                         call_598068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598068, url, valid)

proc call*(call_598069: Call_CreateVariable_598056; body: JsonNode): Recallable =
  ## createVariable
  ## Creates a variable.
  ##   body: JObject (required)
  var body_598070 = newJObject()
  if body != nil:
    body_598070 = body
  result = call_598069.call(nil, nil, nil, nil, body_598070)

var createVariable* = Call_CreateVariable_598056(name: "createVariable",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.CreateVariable",
    validator: validate_CreateVariable_598057, base: "/", url: url_CreateVariable_598058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDetectorVersion_598071 = ref object of OpenApiRestCall_597389
proc url_DeleteDetectorVersion_598073(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDetectorVersion_598072(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598074 = header.getOrDefault("X-Amz-Target")
  valid_598074 = validateParameter(valid_598074, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.DeleteDetectorVersion"))
  if valid_598074 != nil:
    section.add "X-Amz-Target", valid_598074
  var valid_598075 = header.getOrDefault("X-Amz-Signature")
  valid_598075 = validateParameter(valid_598075, JString, required = false,
                                 default = nil)
  if valid_598075 != nil:
    section.add "X-Amz-Signature", valid_598075
  var valid_598076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598076 = validateParameter(valid_598076, JString, required = false,
                                 default = nil)
  if valid_598076 != nil:
    section.add "X-Amz-Content-Sha256", valid_598076
  var valid_598077 = header.getOrDefault("X-Amz-Date")
  valid_598077 = validateParameter(valid_598077, JString, required = false,
                                 default = nil)
  if valid_598077 != nil:
    section.add "X-Amz-Date", valid_598077
  var valid_598078 = header.getOrDefault("X-Amz-Credential")
  valid_598078 = validateParameter(valid_598078, JString, required = false,
                                 default = nil)
  if valid_598078 != nil:
    section.add "X-Amz-Credential", valid_598078
  var valid_598079 = header.getOrDefault("X-Amz-Security-Token")
  valid_598079 = validateParameter(valid_598079, JString, required = false,
                                 default = nil)
  if valid_598079 != nil:
    section.add "X-Amz-Security-Token", valid_598079
  var valid_598080 = header.getOrDefault("X-Amz-Algorithm")
  valid_598080 = validateParameter(valid_598080, JString, required = false,
                                 default = nil)
  if valid_598080 != nil:
    section.add "X-Amz-Algorithm", valid_598080
  var valid_598081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598081 = validateParameter(valid_598081, JString, required = false,
                                 default = nil)
  if valid_598081 != nil:
    section.add "X-Amz-SignedHeaders", valid_598081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598083: Call_DeleteDetectorVersion_598071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the detector version.
  ## 
  let valid = call_598083.validator(path, query, header, formData, body)
  let scheme = call_598083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598083.url(scheme.get, call_598083.host, call_598083.base,
                         call_598083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598083, url, valid)

proc call*(call_598084: Call_DeleteDetectorVersion_598071; body: JsonNode): Recallable =
  ## deleteDetectorVersion
  ## Deletes the detector version.
  ##   body: JObject (required)
  var body_598085 = newJObject()
  if body != nil:
    body_598085 = body
  result = call_598084.call(nil, nil, nil, nil, body_598085)

var deleteDetectorVersion* = Call_DeleteDetectorVersion_598071(
    name: "deleteDetectorVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.DeleteDetectorVersion",
    validator: validate_DeleteDetectorVersion_598072, base: "/",
    url: url_DeleteDetectorVersion_598073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEvent_598086 = ref object of OpenApiRestCall_597389
proc url_DeleteEvent_598088(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEvent_598087(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598089 = header.getOrDefault("X-Amz-Target")
  valid_598089 = validateParameter(valid_598089, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.DeleteEvent"))
  if valid_598089 != nil:
    section.add "X-Amz-Target", valid_598089
  var valid_598090 = header.getOrDefault("X-Amz-Signature")
  valid_598090 = validateParameter(valid_598090, JString, required = false,
                                 default = nil)
  if valid_598090 != nil:
    section.add "X-Amz-Signature", valid_598090
  var valid_598091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598091 = validateParameter(valid_598091, JString, required = false,
                                 default = nil)
  if valid_598091 != nil:
    section.add "X-Amz-Content-Sha256", valid_598091
  var valid_598092 = header.getOrDefault("X-Amz-Date")
  valid_598092 = validateParameter(valid_598092, JString, required = false,
                                 default = nil)
  if valid_598092 != nil:
    section.add "X-Amz-Date", valid_598092
  var valid_598093 = header.getOrDefault("X-Amz-Credential")
  valid_598093 = validateParameter(valid_598093, JString, required = false,
                                 default = nil)
  if valid_598093 != nil:
    section.add "X-Amz-Credential", valid_598093
  var valid_598094 = header.getOrDefault("X-Amz-Security-Token")
  valid_598094 = validateParameter(valid_598094, JString, required = false,
                                 default = nil)
  if valid_598094 != nil:
    section.add "X-Amz-Security-Token", valid_598094
  var valid_598095 = header.getOrDefault("X-Amz-Algorithm")
  valid_598095 = validateParameter(valid_598095, JString, required = false,
                                 default = nil)
  if valid_598095 != nil:
    section.add "X-Amz-Algorithm", valid_598095
  var valid_598096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598096 = validateParameter(valid_598096, JString, required = false,
                                 default = nil)
  if valid_598096 != nil:
    section.add "X-Amz-SignedHeaders", valid_598096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598098: Call_DeleteEvent_598086; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified event.
  ## 
  let valid = call_598098.validator(path, query, header, formData, body)
  let scheme = call_598098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598098.url(scheme.get, call_598098.host, call_598098.base,
                         call_598098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598098, url, valid)

proc call*(call_598099: Call_DeleteEvent_598086; body: JsonNode): Recallable =
  ## deleteEvent
  ## Deletes the specified event.
  ##   body: JObject (required)
  var body_598100 = newJObject()
  if body != nil:
    body_598100 = body
  result = call_598099.call(nil, nil, nil, nil, body_598100)

var deleteEvent* = Call_DeleteEvent_598086(name: "deleteEvent",
                                        meth: HttpMethod.HttpPost,
                                        host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.DeleteEvent",
                                        validator: validate_DeleteEvent_598087,
                                        base: "/", url: url_DeleteEvent_598088,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDetector_598101 = ref object of OpenApiRestCall_597389
proc url_DescribeDetector_598103(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDetector_598102(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598104 = header.getOrDefault("X-Amz-Target")
  valid_598104 = validateParameter(valid_598104, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.DescribeDetector"))
  if valid_598104 != nil:
    section.add "X-Amz-Target", valid_598104
  var valid_598105 = header.getOrDefault("X-Amz-Signature")
  valid_598105 = validateParameter(valid_598105, JString, required = false,
                                 default = nil)
  if valid_598105 != nil:
    section.add "X-Amz-Signature", valid_598105
  var valid_598106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598106 = validateParameter(valid_598106, JString, required = false,
                                 default = nil)
  if valid_598106 != nil:
    section.add "X-Amz-Content-Sha256", valid_598106
  var valid_598107 = header.getOrDefault("X-Amz-Date")
  valid_598107 = validateParameter(valid_598107, JString, required = false,
                                 default = nil)
  if valid_598107 != nil:
    section.add "X-Amz-Date", valid_598107
  var valid_598108 = header.getOrDefault("X-Amz-Credential")
  valid_598108 = validateParameter(valid_598108, JString, required = false,
                                 default = nil)
  if valid_598108 != nil:
    section.add "X-Amz-Credential", valid_598108
  var valid_598109 = header.getOrDefault("X-Amz-Security-Token")
  valid_598109 = validateParameter(valid_598109, JString, required = false,
                                 default = nil)
  if valid_598109 != nil:
    section.add "X-Amz-Security-Token", valid_598109
  var valid_598110 = header.getOrDefault("X-Amz-Algorithm")
  valid_598110 = validateParameter(valid_598110, JString, required = false,
                                 default = nil)
  if valid_598110 != nil:
    section.add "X-Amz-Algorithm", valid_598110
  var valid_598111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598111 = validateParameter(valid_598111, JString, required = false,
                                 default = nil)
  if valid_598111 != nil:
    section.add "X-Amz-SignedHeaders", valid_598111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598113: Call_DescribeDetector_598101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all versions for a specified detector.
  ## 
  let valid = call_598113.validator(path, query, header, formData, body)
  let scheme = call_598113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598113.url(scheme.get, call_598113.host, call_598113.base,
                         call_598113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598113, url, valid)

proc call*(call_598114: Call_DescribeDetector_598101; body: JsonNode): Recallable =
  ## describeDetector
  ## Gets all versions for a specified detector.
  ##   body: JObject (required)
  var body_598115 = newJObject()
  if body != nil:
    body_598115 = body
  result = call_598114.call(nil, nil, nil, nil, body_598115)

var describeDetector* = Call_DescribeDetector_598101(name: "describeDetector",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.DescribeDetector",
    validator: validate_DescribeDetector_598102, base: "/",
    url: url_DescribeDetector_598103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModelVersions_598116 = ref object of OpenApiRestCall_597389
proc url_DescribeModelVersions_598118(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeModelVersions_598117(path: JsonNode; query: JsonNode;
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
  var valid_598119 = query.getOrDefault("nextToken")
  valid_598119 = validateParameter(valid_598119, JString, required = false,
                                 default = nil)
  if valid_598119 != nil:
    section.add "nextToken", valid_598119
  var valid_598120 = query.getOrDefault("maxResults")
  valid_598120 = validateParameter(valid_598120, JString, required = false,
                                 default = nil)
  if valid_598120 != nil:
    section.add "maxResults", valid_598120
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598121 = header.getOrDefault("X-Amz-Target")
  valid_598121 = validateParameter(valid_598121, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.DescribeModelVersions"))
  if valid_598121 != nil:
    section.add "X-Amz-Target", valid_598121
  var valid_598122 = header.getOrDefault("X-Amz-Signature")
  valid_598122 = validateParameter(valid_598122, JString, required = false,
                                 default = nil)
  if valid_598122 != nil:
    section.add "X-Amz-Signature", valid_598122
  var valid_598123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598123 = validateParameter(valid_598123, JString, required = false,
                                 default = nil)
  if valid_598123 != nil:
    section.add "X-Amz-Content-Sha256", valid_598123
  var valid_598124 = header.getOrDefault("X-Amz-Date")
  valid_598124 = validateParameter(valid_598124, JString, required = false,
                                 default = nil)
  if valid_598124 != nil:
    section.add "X-Amz-Date", valid_598124
  var valid_598125 = header.getOrDefault("X-Amz-Credential")
  valid_598125 = validateParameter(valid_598125, JString, required = false,
                                 default = nil)
  if valid_598125 != nil:
    section.add "X-Amz-Credential", valid_598125
  var valid_598126 = header.getOrDefault("X-Amz-Security-Token")
  valid_598126 = validateParameter(valid_598126, JString, required = false,
                                 default = nil)
  if valid_598126 != nil:
    section.add "X-Amz-Security-Token", valid_598126
  var valid_598127 = header.getOrDefault("X-Amz-Algorithm")
  valid_598127 = validateParameter(valid_598127, JString, required = false,
                                 default = nil)
  if valid_598127 != nil:
    section.add "X-Amz-Algorithm", valid_598127
  var valid_598128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598128 = validateParameter(valid_598128, JString, required = false,
                                 default = nil)
  if valid_598128 != nil:
    section.add "X-Amz-SignedHeaders", valid_598128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598130: Call_DescribeModelVersions_598116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all of the model versions for the specified model type or for the specified model type and model ID. You can also get details for a single, specified model version. 
  ## 
  let valid = call_598130.validator(path, query, header, formData, body)
  let scheme = call_598130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598130.url(scheme.get, call_598130.host, call_598130.base,
                         call_598130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598130, url, valid)

proc call*(call_598131: Call_DescribeModelVersions_598116; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeModelVersions
  ## Gets all of the model versions for the specified model type or for the specified model type and model ID. You can also get details for a single, specified model version. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598132 = newJObject()
  var body_598133 = newJObject()
  add(query_598132, "nextToken", newJString(nextToken))
  if body != nil:
    body_598133 = body
  add(query_598132, "maxResults", newJString(maxResults))
  result = call_598131.call(nil, query_598132, nil, nil, body_598133)

var describeModelVersions* = Call_DescribeModelVersions_598116(
    name: "describeModelVersions", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.DescribeModelVersions",
    validator: validate_DescribeModelVersions_598117, base: "/",
    url: url_DescribeModelVersions_598118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetectorVersion_598135 = ref object of OpenApiRestCall_597389
proc url_GetDetectorVersion_598137(protocol: Scheme; host: string; base: string;
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

proc validate_GetDetectorVersion_598136(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598138 = header.getOrDefault("X-Amz-Target")
  valid_598138 = validateParameter(valid_598138, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetDetectorVersion"))
  if valid_598138 != nil:
    section.add "X-Amz-Target", valid_598138
  var valid_598139 = header.getOrDefault("X-Amz-Signature")
  valid_598139 = validateParameter(valid_598139, JString, required = false,
                                 default = nil)
  if valid_598139 != nil:
    section.add "X-Amz-Signature", valid_598139
  var valid_598140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598140 = validateParameter(valid_598140, JString, required = false,
                                 default = nil)
  if valid_598140 != nil:
    section.add "X-Amz-Content-Sha256", valid_598140
  var valid_598141 = header.getOrDefault("X-Amz-Date")
  valid_598141 = validateParameter(valid_598141, JString, required = false,
                                 default = nil)
  if valid_598141 != nil:
    section.add "X-Amz-Date", valid_598141
  var valid_598142 = header.getOrDefault("X-Amz-Credential")
  valid_598142 = validateParameter(valid_598142, JString, required = false,
                                 default = nil)
  if valid_598142 != nil:
    section.add "X-Amz-Credential", valid_598142
  var valid_598143 = header.getOrDefault("X-Amz-Security-Token")
  valid_598143 = validateParameter(valid_598143, JString, required = false,
                                 default = nil)
  if valid_598143 != nil:
    section.add "X-Amz-Security-Token", valid_598143
  var valid_598144 = header.getOrDefault("X-Amz-Algorithm")
  valid_598144 = validateParameter(valid_598144, JString, required = false,
                                 default = nil)
  if valid_598144 != nil:
    section.add "X-Amz-Algorithm", valid_598144
  var valid_598145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598145 = validateParameter(valid_598145, JString, required = false,
                                 default = nil)
  if valid_598145 != nil:
    section.add "X-Amz-SignedHeaders", valid_598145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598147: Call_GetDetectorVersion_598135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a particular detector version. 
  ## 
  let valid = call_598147.validator(path, query, header, formData, body)
  let scheme = call_598147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598147.url(scheme.get, call_598147.host, call_598147.base,
                         call_598147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598147, url, valid)

proc call*(call_598148: Call_GetDetectorVersion_598135; body: JsonNode): Recallable =
  ## getDetectorVersion
  ## Gets a particular detector version. 
  ##   body: JObject (required)
  var body_598149 = newJObject()
  if body != nil:
    body_598149 = body
  result = call_598148.call(nil, nil, nil, nil, body_598149)

var getDetectorVersion* = Call_GetDetectorVersion_598135(
    name: "getDetectorVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetDetectorVersion",
    validator: validate_GetDetectorVersion_598136, base: "/",
    url: url_GetDetectorVersion_598137, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetectors_598150 = ref object of OpenApiRestCall_597389
proc url_GetDetectors_598152(protocol: Scheme; host: string; base: string;
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

proc validate_GetDetectors_598151(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598153 = query.getOrDefault("nextToken")
  valid_598153 = validateParameter(valid_598153, JString, required = false,
                                 default = nil)
  if valid_598153 != nil:
    section.add "nextToken", valid_598153
  var valid_598154 = query.getOrDefault("maxResults")
  valid_598154 = validateParameter(valid_598154, JString, required = false,
                                 default = nil)
  if valid_598154 != nil:
    section.add "maxResults", valid_598154
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598155 = header.getOrDefault("X-Amz-Target")
  valid_598155 = validateParameter(valid_598155, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetDetectors"))
  if valid_598155 != nil:
    section.add "X-Amz-Target", valid_598155
  var valid_598156 = header.getOrDefault("X-Amz-Signature")
  valid_598156 = validateParameter(valid_598156, JString, required = false,
                                 default = nil)
  if valid_598156 != nil:
    section.add "X-Amz-Signature", valid_598156
  var valid_598157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598157 = validateParameter(valid_598157, JString, required = false,
                                 default = nil)
  if valid_598157 != nil:
    section.add "X-Amz-Content-Sha256", valid_598157
  var valid_598158 = header.getOrDefault("X-Amz-Date")
  valid_598158 = validateParameter(valid_598158, JString, required = false,
                                 default = nil)
  if valid_598158 != nil:
    section.add "X-Amz-Date", valid_598158
  var valid_598159 = header.getOrDefault("X-Amz-Credential")
  valid_598159 = validateParameter(valid_598159, JString, required = false,
                                 default = nil)
  if valid_598159 != nil:
    section.add "X-Amz-Credential", valid_598159
  var valid_598160 = header.getOrDefault("X-Amz-Security-Token")
  valid_598160 = validateParameter(valid_598160, JString, required = false,
                                 default = nil)
  if valid_598160 != nil:
    section.add "X-Amz-Security-Token", valid_598160
  var valid_598161 = header.getOrDefault("X-Amz-Algorithm")
  valid_598161 = validateParameter(valid_598161, JString, required = false,
                                 default = nil)
  if valid_598161 != nil:
    section.add "X-Amz-Algorithm", valid_598161
  var valid_598162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598162 = validateParameter(valid_598162, JString, required = false,
                                 default = nil)
  if valid_598162 != nil:
    section.add "X-Amz-SignedHeaders", valid_598162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598164: Call_GetDetectors_598150; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all of detectors. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetEventTypesResponse</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ## 
  let valid = call_598164.validator(path, query, header, formData, body)
  let scheme = call_598164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598164.url(scheme.get, call_598164.host, call_598164.base,
                         call_598164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598164, url, valid)

proc call*(call_598165: Call_GetDetectors_598150; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getDetectors
  ## Gets all of detectors. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetEventTypesResponse</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598166 = newJObject()
  var body_598167 = newJObject()
  add(query_598166, "nextToken", newJString(nextToken))
  if body != nil:
    body_598167 = body
  add(query_598166, "maxResults", newJString(maxResults))
  result = call_598165.call(nil, query_598166, nil, nil, body_598167)

var getDetectors* = Call_GetDetectors_598150(name: "getDetectors",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetDetectors",
    validator: validate_GetDetectors_598151, base: "/", url: url_GetDetectors_598152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExternalModels_598168 = ref object of OpenApiRestCall_597389
proc url_GetExternalModels_598170(protocol: Scheme; host: string; base: string;
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

proc validate_GetExternalModels_598169(path: JsonNode; query: JsonNode;
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
  var valid_598171 = query.getOrDefault("nextToken")
  valid_598171 = validateParameter(valid_598171, JString, required = false,
                                 default = nil)
  if valid_598171 != nil:
    section.add "nextToken", valid_598171
  var valid_598172 = query.getOrDefault("maxResults")
  valid_598172 = validateParameter(valid_598172, JString, required = false,
                                 default = nil)
  if valid_598172 != nil:
    section.add "maxResults", valid_598172
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598173 = header.getOrDefault("X-Amz-Target")
  valid_598173 = validateParameter(valid_598173, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetExternalModels"))
  if valid_598173 != nil:
    section.add "X-Amz-Target", valid_598173
  var valid_598174 = header.getOrDefault("X-Amz-Signature")
  valid_598174 = validateParameter(valid_598174, JString, required = false,
                                 default = nil)
  if valid_598174 != nil:
    section.add "X-Amz-Signature", valid_598174
  var valid_598175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598175 = validateParameter(valid_598175, JString, required = false,
                                 default = nil)
  if valid_598175 != nil:
    section.add "X-Amz-Content-Sha256", valid_598175
  var valid_598176 = header.getOrDefault("X-Amz-Date")
  valid_598176 = validateParameter(valid_598176, JString, required = false,
                                 default = nil)
  if valid_598176 != nil:
    section.add "X-Amz-Date", valid_598176
  var valid_598177 = header.getOrDefault("X-Amz-Credential")
  valid_598177 = validateParameter(valid_598177, JString, required = false,
                                 default = nil)
  if valid_598177 != nil:
    section.add "X-Amz-Credential", valid_598177
  var valid_598178 = header.getOrDefault("X-Amz-Security-Token")
  valid_598178 = validateParameter(valid_598178, JString, required = false,
                                 default = nil)
  if valid_598178 != nil:
    section.add "X-Amz-Security-Token", valid_598178
  var valid_598179 = header.getOrDefault("X-Amz-Algorithm")
  valid_598179 = validateParameter(valid_598179, JString, required = false,
                                 default = nil)
  if valid_598179 != nil:
    section.add "X-Amz-Algorithm", valid_598179
  var valid_598180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598180 = validateParameter(valid_598180, JString, required = false,
                                 default = nil)
  if valid_598180 != nil:
    section.add "X-Amz-SignedHeaders", valid_598180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598182: Call_GetExternalModels_598168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the details for one or more Amazon SageMaker models that have been imported into the service. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetExternalModelsResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ## 
  let valid = call_598182.validator(path, query, header, formData, body)
  let scheme = call_598182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598182.url(scheme.get, call_598182.host, call_598182.base,
                         call_598182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598182, url, valid)

proc call*(call_598183: Call_GetExternalModels_598168; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getExternalModels
  ## Gets the details for one or more Amazon SageMaker models that have been imported into the service. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetExternalModelsResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598184 = newJObject()
  var body_598185 = newJObject()
  add(query_598184, "nextToken", newJString(nextToken))
  if body != nil:
    body_598185 = body
  add(query_598184, "maxResults", newJString(maxResults))
  result = call_598183.call(nil, query_598184, nil, nil, body_598185)

var getExternalModels* = Call_GetExternalModels_598168(name: "getExternalModels",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetExternalModels",
    validator: validate_GetExternalModels_598169, base: "/",
    url: url_GetExternalModels_598170, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelVersion_598186 = ref object of OpenApiRestCall_597389
proc url_GetModelVersion_598188(protocol: Scheme; host: string; base: string;
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

proc validate_GetModelVersion_598187(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598189 = header.getOrDefault("X-Amz-Target")
  valid_598189 = validateParameter(valid_598189, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetModelVersion"))
  if valid_598189 != nil:
    section.add "X-Amz-Target", valid_598189
  var valid_598190 = header.getOrDefault("X-Amz-Signature")
  valid_598190 = validateParameter(valid_598190, JString, required = false,
                                 default = nil)
  if valid_598190 != nil:
    section.add "X-Amz-Signature", valid_598190
  var valid_598191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598191 = validateParameter(valid_598191, JString, required = false,
                                 default = nil)
  if valid_598191 != nil:
    section.add "X-Amz-Content-Sha256", valid_598191
  var valid_598192 = header.getOrDefault("X-Amz-Date")
  valid_598192 = validateParameter(valid_598192, JString, required = false,
                                 default = nil)
  if valid_598192 != nil:
    section.add "X-Amz-Date", valid_598192
  var valid_598193 = header.getOrDefault("X-Amz-Credential")
  valid_598193 = validateParameter(valid_598193, JString, required = false,
                                 default = nil)
  if valid_598193 != nil:
    section.add "X-Amz-Credential", valid_598193
  var valid_598194 = header.getOrDefault("X-Amz-Security-Token")
  valid_598194 = validateParameter(valid_598194, JString, required = false,
                                 default = nil)
  if valid_598194 != nil:
    section.add "X-Amz-Security-Token", valid_598194
  var valid_598195 = header.getOrDefault("X-Amz-Algorithm")
  valid_598195 = validateParameter(valid_598195, JString, required = false,
                                 default = nil)
  if valid_598195 != nil:
    section.add "X-Amz-Algorithm", valid_598195
  var valid_598196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598196 = validateParameter(valid_598196, JString, required = false,
                                 default = nil)
  if valid_598196 != nil:
    section.add "X-Amz-SignedHeaders", valid_598196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598198: Call_GetModelVersion_598186; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a model version. 
  ## 
  let valid = call_598198.validator(path, query, header, formData, body)
  let scheme = call_598198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598198.url(scheme.get, call_598198.host, call_598198.base,
                         call_598198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598198, url, valid)

proc call*(call_598199: Call_GetModelVersion_598186; body: JsonNode): Recallable =
  ## getModelVersion
  ## Gets a model version. 
  ##   body: JObject (required)
  var body_598200 = newJObject()
  if body != nil:
    body_598200 = body
  result = call_598199.call(nil, nil, nil, nil, body_598200)

var getModelVersion* = Call_GetModelVersion_598186(name: "getModelVersion",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetModelVersion",
    validator: validate_GetModelVersion_598187, base: "/", url: url_GetModelVersion_598188,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_598201 = ref object of OpenApiRestCall_597389
proc url_GetModels_598203(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModels_598202(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598204 = query.getOrDefault("nextToken")
  valid_598204 = validateParameter(valid_598204, JString, required = false,
                                 default = nil)
  if valid_598204 != nil:
    section.add "nextToken", valid_598204
  var valid_598205 = query.getOrDefault("maxResults")
  valid_598205 = validateParameter(valid_598205, JString, required = false,
                                 default = nil)
  if valid_598205 != nil:
    section.add "maxResults", valid_598205
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598206 = header.getOrDefault("X-Amz-Target")
  valid_598206 = validateParameter(valid_598206, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetModels"))
  if valid_598206 != nil:
    section.add "X-Amz-Target", valid_598206
  var valid_598207 = header.getOrDefault("X-Amz-Signature")
  valid_598207 = validateParameter(valid_598207, JString, required = false,
                                 default = nil)
  if valid_598207 != nil:
    section.add "X-Amz-Signature", valid_598207
  var valid_598208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598208 = validateParameter(valid_598208, JString, required = false,
                                 default = nil)
  if valid_598208 != nil:
    section.add "X-Amz-Content-Sha256", valid_598208
  var valid_598209 = header.getOrDefault("X-Amz-Date")
  valid_598209 = validateParameter(valid_598209, JString, required = false,
                                 default = nil)
  if valid_598209 != nil:
    section.add "X-Amz-Date", valid_598209
  var valid_598210 = header.getOrDefault("X-Amz-Credential")
  valid_598210 = validateParameter(valid_598210, JString, required = false,
                                 default = nil)
  if valid_598210 != nil:
    section.add "X-Amz-Credential", valid_598210
  var valid_598211 = header.getOrDefault("X-Amz-Security-Token")
  valid_598211 = validateParameter(valid_598211, JString, required = false,
                                 default = nil)
  if valid_598211 != nil:
    section.add "X-Amz-Security-Token", valid_598211
  var valid_598212 = header.getOrDefault("X-Amz-Algorithm")
  valid_598212 = validateParameter(valid_598212, JString, required = false,
                                 default = nil)
  if valid_598212 != nil:
    section.add "X-Amz-Algorithm", valid_598212
  var valid_598213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598213 = validateParameter(valid_598213, JString, required = false,
                                 default = nil)
  if valid_598213 != nil:
    section.add "X-Amz-SignedHeaders", valid_598213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598215: Call_GetModels_598201; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all of the models for the AWS account, or the specified model type, or gets a single model for the specified model type, model ID combination. 
  ## 
  let valid = call_598215.validator(path, query, header, formData, body)
  let scheme = call_598215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598215.url(scheme.get, call_598215.host, call_598215.base,
                         call_598215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598215, url, valid)

proc call*(call_598216: Call_GetModels_598201; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getModels
  ## Gets all of the models for the AWS account, or the specified model type, or gets a single model for the specified model type, model ID combination. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598217 = newJObject()
  var body_598218 = newJObject()
  add(query_598217, "nextToken", newJString(nextToken))
  if body != nil:
    body_598218 = body
  add(query_598217, "maxResults", newJString(maxResults))
  result = call_598216.call(nil, query_598217, nil, nil, body_598218)

var getModels* = Call_GetModels_598201(name: "getModels", meth: HttpMethod.HttpPost,
                                    host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetModels",
                                    validator: validate_GetModels_598202,
                                    base: "/", url: url_GetModels_598203,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOutcomes_598219 = ref object of OpenApiRestCall_597389
proc url_GetOutcomes_598221(protocol: Scheme; host: string; base: string;
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

proc validate_GetOutcomes_598220(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598222 = query.getOrDefault("nextToken")
  valid_598222 = validateParameter(valid_598222, JString, required = false,
                                 default = nil)
  if valid_598222 != nil:
    section.add "nextToken", valid_598222
  var valid_598223 = query.getOrDefault("maxResults")
  valid_598223 = validateParameter(valid_598223, JString, required = false,
                                 default = nil)
  if valid_598223 != nil:
    section.add "maxResults", valid_598223
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598224 = header.getOrDefault("X-Amz-Target")
  valid_598224 = validateParameter(valid_598224, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetOutcomes"))
  if valid_598224 != nil:
    section.add "X-Amz-Target", valid_598224
  var valid_598225 = header.getOrDefault("X-Amz-Signature")
  valid_598225 = validateParameter(valid_598225, JString, required = false,
                                 default = nil)
  if valid_598225 != nil:
    section.add "X-Amz-Signature", valid_598225
  var valid_598226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598226 = validateParameter(valid_598226, JString, required = false,
                                 default = nil)
  if valid_598226 != nil:
    section.add "X-Amz-Content-Sha256", valid_598226
  var valid_598227 = header.getOrDefault("X-Amz-Date")
  valid_598227 = validateParameter(valid_598227, JString, required = false,
                                 default = nil)
  if valid_598227 != nil:
    section.add "X-Amz-Date", valid_598227
  var valid_598228 = header.getOrDefault("X-Amz-Credential")
  valid_598228 = validateParameter(valid_598228, JString, required = false,
                                 default = nil)
  if valid_598228 != nil:
    section.add "X-Amz-Credential", valid_598228
  var valid_598229 = header.getOrDefault("X-Amz-Security-Token")
  valid_598229 = validateParameter(valid_598229, JString, required = false,
                                 default = nil)
  if valid_598229 != nil:
    section.add "X-Amz-Security-Token", valid_598229
  var valid_598230 = header.getOrDefault("X-Amz-Algorithm")
  valid_598230 = validateParameter(valid_598230, JString, required = false,
                                 default = nil)
  if valid_598230 != nil:
    section.add "X-Amz-Algorithm", valid_598230
  var valid_598231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598231 = validateParameter(valid_598231, JString, required = false,
                                 default = nil)
  if valid_598231 != nil:
    section.add "X-Amz-SignedHeaders", valid_598231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598233: Call_GetOutcomes_598219; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets one or more outcomes. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 50 and 100. To get the next page results, provide the pagination token from the <code>GetOutcomesResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ## 
  let valid = call_598233.validator(path, query, header, formData, body)
  let scheme = call_598233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598233.url(scheme.get, call_598233.host, call_598233.base,
                         call_598233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598233, url, valid)

proc call*(call_598234: Call_GetOutcomes_598219; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getOutcomes
  ## Gets one or more outcomes. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 50 and 100. To get the next page results, provide the pagination token from the <code>GetOutcomesResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598235 = newJObject()
  var body_598236 = newJObject()
  add(query_598235, "nextToken", newJString(nextToken))
  if body != nil:
    body_598236 = body
  add(query_598235, "maxResults", newJString(maxResults))
  result = call_598234.call(nil, query_598235, nil, nil, body_598236)

var getOutcomes* = Call_GetOutcomes_598219(name: "getOutcomes",
                                        meth: HttpMethod.HttpPost,
                                        host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetOutcomes",
                                        validator: validate_GetOutcomes_598220,
                                        base: "/", url: url_GetOutcomes_598221,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPrediction_598237 = ref object of OpenApiRestCall_597389
proc url_GetPrediction_598239(protocol: Scheme; host: string; base: string;
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

proc validate_GetPrediction_598238(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598240 = header.getOrDefault("X-Amz-Target")
  valid_598240 = validateParameter(valid_598240, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetPrediction"))
  if valid_598240 != nil:
    section.add "X-Amz-Target", valid_598240
  var valid_598241 = header.getOrDefault("X-Amz-Signature")
  valid_598241 = validateParameter(valid_598241, JString, required = false,
                                 default = nil)
  if valid_598241 != nil:
    section.add "X-Amz-Signature", valid_598241
  var valid_598242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598242 = validateParameter(valid_598242, JString, required = false,
                                 default = nil)
  if valid_598242 != nil:
    section.add "X-Amz-Content-Sha256", valid_598242
  var valid_598243 = header.getOrDefault("X-Amz-Date")
  valid_598243 = validateParameter(valid_598243, JString, required = false,
                                 default = nil)
  if valid_598243 != nil:
    section.add "X-Amz-Date", valid_598243
  var valid_598244 = header.getOrDefault("X-Amz-Credential")
  valid_598244 = validateParameter(valid_598244, JString, required = false,
                                 default = nil)
  if valid_598244 != nil:
    section.add "X-Amz-Credential", valid_598244
  var valid_598245 = header.getOrDefault("X-Amz-Security-Token")
  valid_598245 = validateParameter(valid_598245, JString, required = false,
                                 default = nil)
  if valid_598245 != nil:
    section.add "X-Amz-Security-Token", valid_598245
  var valid_598246 = header.getOrDefault("X-Amz-Algorithm")
  valid_598246 = validateParameter(valid_598246, JString, required = false,
                                 default = nil)
  if valid_598246 != nil:
    section.add "X-Amz-Algorithm", valid_598246
  var valid_598247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598247 = validateParameter(valid_598247, JString, required = false,
                                 default = nil)
  if valid_598247 != nil:
    section.add "X-Amz-SignedHeaders", valid_598247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598249: Call_GetPrediction_598237; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Evaluates an event against a detector version. If a version ID is not provided, the detector’s (<code>ACTIVE</code>) version is used. 
  ## 
  let valid = call_598249.validator(path, query, header, formData, body)
  let scheme = call_598249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598249.url(scheme.get, call_598249.host, call_598249.base,
                         call_598249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598249, url, valid)

proc call*(call_598250: Call_GetPrediction_598237; body: JsonNode): Recallable =
  ## getPrediction
  ## Evaluates an event against a detector version. If a version ID is not provided, the detector’s (<code>ACTIVE</code>) version is used. 
  ##   body: JObject (required)
  var body_598251 = newJObject()
  if body != nil:
    body_598251 = body
  result = call_598250.call(nil, nil, nil, nil, body_598251)

var getPrediction* = Call_GetPrediction_598237(name: "getPrediction",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetPrediction",
    validator: validate_GetPrediction_598238, base: "/", url: url_GetPrediction_598239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRules_598252 = ref object of OpenApiRestCall_597389
proc url_GetRules_598254(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRules_598253(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598255 = query.getOrDefault("nextToken")
  valid_598255 = validateParameter(valid_598255, JString, required = false,
                                 default = nil)
  if valid_598255 != nil:
    section.add "nextToken", valid_598255
  var valid_598256 = query.getOrDefault("maxResults")
  valid_598256 = validateParameter(valid_598256, JString, required = false,
                                 default = nil)
  if valid_598256 != nil:
    section.add "maxResults", valid_598256
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598257 = header.getOrDefault("X-Amz-Target")
  valid_598257 = validateParameter(valid_598257, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetRules"))
  if valid_598257 != nil:
    section.add "X-Amz-Target", valid_598257
  var valid_598258 = header.getOrDefault("X-Amz-Signature")
  valid_598258 = validateParameter(valid_598258, JString, required = false,
                                 default = nil)
  if valid_598258 != nil:
    section.add "X-Amz-Signature", valid_598258
  var valid_598259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598259 = validateParameter(valid_598259, JString, required = false,
                                 default = nil)
  if valid_598259 != nil:
    section.add "X-Amz-Content-Sha256", valid_598259
  var valid_598260 = header.getOrDefault("X-Amz-Date")
  valid_598260 = validateParameter(valid_598260, JString, required = false,
                                 default = nil)
  if valid_598260 != nil:
    section.add "X-Amz-Date", valid_598260
  var valid_598261 = header.getOrDefault("X-Amz-Credential")
  valid_598261 = validateParameter(valid_598261, JString, required = false,
                                 default = nil)
  if valid_598261 != nil:
    section.add "X-Amz-Credential", valid_598261
  var valid_598262 = header.getOrDefault("X-Amz-Security-Token")
  valid_598262 = validateParameter(valid_598262, JString, required = false,
                                 default = nil)
  if valid_598262 != nil:
    section.add "X-Amz-Security-Token", valid_598262
  var valid_598263 = header.getOrDefault("X-Amz-Algorithm")
  valid_598263 = validateParameter(valid_598263, JString, required = false,
                                 default = nil)
  if valid_598263 != nil:
    section.add "X-Amz-Algorithm", valid_598263
  var valid_598264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598264 = validateParameter(valid_598264, JString, required = false,
                                 default = nil)
  if valid_598264 != nil:
    section.add "X-Amz-SignedHeaders", valid_598264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598266: Call_GetRules_598252; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all rules available for the specified detector.
  ## 
  let valid = call_598266.validator(path, query, header, formData, body)
  let scheme = call_598266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598266.url(scheme.get, call_598266.host, call_598266.base,
                         call_598266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598266, url, valid)

proc call*(call_598267: Call_GetRules_598252; body: JsonNode; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getRules
  ## Gets all rules available for the specified detector.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598268 = newJObject()
  var body_598269 = newJObject()
  add(query_598268, "nextToken", newJString(nextToken))
  if body != nil:
    body_598269 = body
  add(query_598268, "maxResults", newJString(maxResults))
  result = call_598267.call(nil, query_598268, nil, nil, body_598269)

var getRules* = Call_GetRules_598252(name: "getRules", meth: HttpMethod.HttpPost,
                                  host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetRules",
                                  validator: validate_GetRules_598253, base: "/",
                                  url: url_GetRules_598254,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVariables_598270 = ref object of OpenApiRestCall_597389
proc url_GetVariables_598272(protocol: Scheme; host: string; base: string;
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

proc validate_GetVariables_598271(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598273 = query.getOrDefault("nextToken")
  valid_598273 = validateParameter(valid_598273, JString, required = false,
                                 default = nil)
  if valid_598273 != nil:
    section.add "nextToken", valid_598273
  var valid_598274 = query.getOrDefault("maxResults")
  valid_598274 = validateParameter(valid_598274, JString, required = false,
                                 default = nil)
  if valid_598274 != nil:
    section.add "maxResults", valid_598274
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598275 = header.getOrDefault("X-Amz-Target")
  valid_598275 = validateParameter(valid_598275, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetVariables"))
  if valid_598275 != nil:
    section.add "X-Amz-Target", valid_598275
  var valid_598276 = header.getOrDefault("X-Amz-Signature")
  valid_598276 = validateParameter(valid_598276, JString, required = false,
                                 default = nil)
  if valid_598276 != nil:
    section.add "X-Amz-Signature", valid_598276
  var valid_598277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598277 = validateParameter(valid_598277, JString, required = false,
                                 default = nil)
  if valid_598277 != nil:
    section.add "X-Amz-Content-Sha256", valid_598277
  var valid_598278 = header.getOrDefault("X-Amz-Date")
  valid_598278 = validateParameter(valid_598278, JString, required = false,
                                 default = nil)
  if valid_598278 != nil:
    section.add "X-Amz-Date", valid_598278
  var valid_598279 = header.getOrDefault("X-Amz-Credential")
  valid_598279 = validateParameter(valid_598279, JString, required = false,
                                 default = nil)
  if valid_598279 != nil:
    section.add "X-Amz-Credential", valid_598279
  var valid_598280 = header.getOrDefault("X-Amz-Security-Token")
  valid_598280 = validateParameter(valid_598280, JString, required = false,
                                 default = nil)
  if valid_598280 != nil:
    section.add "X-Amz-Security-Token", valid_598280
  var valid_598281 = header.getOrDefault("X-Amz-Algorithm")
  valid_598281 = validateParameter(valid_598281, JString, required = false,
                                 default = nil)
  if valid_598281 != nil:
    section.add "X-Amz-Algorithm", valid_598281
  var valid_598282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598282 = validateParameter(valid_598282, JString, required = false,
                                 default = nil)
  if valid_598282 != nil:
    section.add "X-Amz-SignedHeaders", valid_598282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598284: Call_GetVariables_598270; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all of the variables or the specific variable. This is a paginated API. Providing null <code>maxSizePerPage</code> results in retrieving maximum of 100 records per page. If you provide <code>maxSizePerPage</code> the value must be between 50 and 100. To get the next page result, a provide a pagination token from <code>GetVariablesResult</code> as part of your request. Null pagination token fetches the records from the beginning. 
  ## 
  let valid = call_598284.validator(path, query, header, formData, body)
  let scheme = call_598284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598284.url(scheme.get, call_598284.host, call_598284.base,
                         call_598284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598284, url, valid)

proc call*(call_598285: Call_GetVariables_598270; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getVariables
  ## Gets all of the variables or the specific variable. This is a paginated API. Providing null <code>maxSizePerPage</code> results in retrieving maximum of 100 records per page. If you provide <code>maxSizePerPage</code> the value must be between 50 and 100. To get the next page result, a provide a pagination token from <code>GetVariablesResult</code> as part of your request. Null pagination token fetches the records from the beginning. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598286 = newJObject()
  var body_598287 = newJObject()
  add(query_598286, "nextToken", newJString(nextToken))
  if body != nil:
    body_598287 = body
  add(query_598286, "maxResults", newJString(maxResults))
  result = call_598285.call(nil, query_598286, nil, nil, body_598287)

var getVariables* = Call_GetVariables_598270(name: "getVariables",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetVariables",
    validator: validate_GetVariables_598271, base: "/", url: url_GetVariables_598272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDetector_598288 = ref object of OpenApiRestCall_597389
proc url_PutDetector_598290(protocol: Scheme; host: string; base: string;
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

proc validate_PutDetector_598289(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598291 = header.getOrDefault("X-Amz-Target")
  valid_598291 = validateParameter(valid_598291, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.PutDetector"))
  if valid_598291 != nil:
    section.add "X-Amz-Target", valid_598291
  var valid_598292 = header.getOrDefault("X-Amz-Signature")
  valid_598292 = validateParameter(valid_598292, JString, required = false,
                                 default = nil)
  if valid_598292 != nil:
    section.add "X-Amz-Signature", valid_598292
  var valid_598293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598293 = validateParameter(valid_598293, JString, required = false,
                                 default = nil)
  if valid_598293 != nil:
    section.add "X-Amz-Content-Sha256", valid_598293
  var valid_598294 = header.getOrDefault("X-Amz-Date")
  valid_598294 = validateParameter(valid_598294, JString, required = false,
                                 default = nil)
  if valid_598294 != nil:
    section.add "X-Amz-Date", valid_598294
  var valid_598295 = header.getOrDefault("X-Amz-Credential")
  valid_598295 = validateParameter(valid_598295, JString, required = false,
                                 default = nil)
  if valid_598295 != nil:
    section.add "X-Amz-Credential", valid_598295
  var valid_598296 = header.getOrDefault("X-Amz-Security-Token")
  valid_598296 = validateParameter(valid_598296, JString, required = false,
                                 default = nil)
  if valid_598296 != nil:
    section.add "X-Amz-Security-Token", valid_598296
  var valid_598297 = header.getOrDefault("X-Amz-Algorithm")
  valid_598297 = validateParameter(valid_598297, JString, required = false,
                                 default = nil)
  if valid_598297 != nil:
    section.add "X-Amz-Algorithm", valid_598297
  var valid_598298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598298 = validateParameter(valid_598298, JString, required = false,
                                 default = nil)
  if valid_598298 != nil:
    section.add "X-Amz-SignedHeaders", valid_598298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598300: Call_PutDetector_598288; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a detector. 
  ## 
  let valid = call_598300.validator(path, query, header, formData, body)
  let scheme = call_598300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598300.url(scheme.get, call_598300.host, call_598300.base,
                         call_598300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598300, url, valid)

proc call*(call_598301: Call_PutDetector_598288; body: JsonNode): Recallable =
  ## putDetector
  ## Creates or updates a detector. 
  ##   body: JObject (required)
  var body_598302 = newJObject()
  if body != nil:
    body_598302 = body
  result = call_598301.call(nil, nil, nil, nil, body_598302)

var putDetector* = Call_PutDetector_598288(name: "putDetector",
                                        meth: HttpMethod.HttpPost,
                                        host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.PutDetector",
                                        validator: validate_PutDetector_598289,
                                        base: "/", url: url_PutDetector_598290,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutExternalModel_598303 = ref object of OpenApiRestCall_597389
proc url_PutExternalModel_598305(protocol: Scheme; host: string; base: string;
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

proc validate_PutExternalModel_598304(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598306 = header.getOrDefault("X-Amz-Target")
  valid_598306 = validateParameter(valid_598306, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.PutExternalModel"))
  if valid_598306 != nil:
    section.add "X-Amz-Target", valid_598306
  var valid_598307 = header.getOrDefault("X-Amz-Signature")
  valid_598307 = validateParameter(valid_598307, JString, required = false,
                                 default = nil)
  if valid_598307 != nil:
    section.add "X-Amz-Signature", valid_598307
  var valid_598308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598308 = validateParameter(valid_598308, JString, required = false,
                                 default = nil)
  if valid_598308 != nil:
    section.add "X-Amz-Content-Sha256", valid_598308
  var valid_598309 = header.getOrDefault("X-Amz-Date")
  valid_598309 = validateParameter(valid_598309, JString, required = false,
                                 default = nil)
  if valid_598309 != nil:
    section.add "X-Amz-Date", valid_598309
  var valid_598310 = header.getOrDefault("X-Amz-Credential")
  valid_598310 = validateParameter(valid_598310, JString, required = false,
                                 default = nil)
  if valid_598310 != nil:
    section.add "X-Amz-Credential", valid_598310
  var valid_598311 = header.getOrDefault("X-Amz-Security-Token")
  valid_598311 = validateParameter(valid_598311, JString, required = false,
                                 default = nil)
  if valid_598311 != nil:
    section.add "X-Amz-Security-Token", valid_598311
  var valid_598312 = header.getOrDefault("X-Amz-Algorithm")
  valid_598312 = validateParameter(valid_598312, JString, required = false,
                                 default = nil)
  if valid_598312 != nil:
    section.add "X-Amz-Algorithm", valid_598312
  var valid_598313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598313 = validateParameter(valid_598313, JString, required = false,
                                 default = nil)
  if valid_598313 != nil:
    section.add "X-Amz-SignedHeaders", valid_598313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598315: Call_PutExternalModel_598303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates an Amazon SageMaker model endpoint. You can also use this action to update the configuration of the model endpoint, including the IAM role and/or the mapped variables. 
  ## 
  let valid = call_598315.validator(path, query, header, formData, body)
  let scheme = call_598315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598315.url(scheme.get, call_598315.host, call_598315.base,
                         call_598315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598315, url, valid)

proc call*(call_598316: Call_PutExternalModel_598303; body: JsonNode): Recallable =
  ## putExternalModel
  ## Creates or updates an Amazon SageMaker model endpoint. You can also use this action to update the configuration of the model endpoint, including the IAM role and/or the mapped variables. 
  ##   body: JObject (required)
  var body_598317 = newJObject()
  if body != nil:
    body_598317 = body
  result = call_598316.call(nil, nil, nil, nil, body_598317)

var putExternalModel* = Call_PutExternalModel_598303(name: "putExternalModel",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.PutExternalModel",
    validator: validate_PutExternalModel_598304, base: "/",
    url: url_PutExternalModel_598305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutModel_598318 = ref object of OpenApiRestCall_597389
proc url_PutModel_598320(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutModel_598319(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598321 = header.getOrDefault("X-Amz-Target")
  valid_598321 = validateParameter(valid_598321, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.PutModel"))
  if valid_598321 != nil:
    section.add "X-Amz-Target", valid_598321
  var valid_598322 = header.getOrDefault("X-Amz-Signature")
  valid_598322 = validateParameter(valid_598322, JString, required = false,
                                 default = nil)
  if valid_598322 != nil:
    section.add "X-Amz-Signature", valid_598322
  var valid_598323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598323 = validateParameter(valid_598323, JString, required = false,
                                 default = nil)
  if valid_598323 != nil:
    section.add "X-Amz-Content-Sha256", valid_598323
  var valid_598324 = header.getOrDefault("X-Amz-Date")
  valid_598324 = validateParameter(valid_598324, JString, required = false,
                                 default = nil)
  if valid_598324 != nil:
    section.add "X-Amz-Date", valid_598324
  var valid_598325 = header.getOrDefault("X-Amz-Credential")
  valid_598325 = validateParameter(valid_598325, JString, required = false,
                                 default = nil)
  if valid_598325 != nil:
    section.add "X-Amz-Credential", valid_598325
  var valid_598326 = header.getOrDefault("X-Amz-Security-Token")
  valid_598326 = validateParameter(valid_598326, JString, required = false,
                                 default = nil)
  if valid_598326 != nil:
    section.add "X-Amz-Security-Token", valid_598326
  var valid_598327 = header.getOrDefault("X-Amz-Algorithm")
  valid_598327 = validateParameter(valid_598327, JString, required = false,
                                 default = nil)
  if valid_598327 != nil:
    section.add "X-Amz-Algorithm", valid_598327
  var valid_598328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598328 = validateParameter(valid_598328, JString, required = false,
                                 default = nil)
  if valid_598328 != nil:
    section.add "X-Amz-SignedHeaders", valid_598328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598330: Call_PutModel_598318; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a model. 
  ## 
  let valid = call_598330.validator(path, query, header, formData, body)
  let scheme = call_598330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598330.url(scheme.get, call_598330.host, call_598330.base,
                         call_598330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598330, url, valid)

proc call*(call_598331: Call_PutModel_598318; body: JsonNode): Recallable =
  ## putModel
  ## Creates or updates a model. 
  ##   body: JObject (required)
  var body_598332 = newJObject()
  if body != nil:
    body_598332 = body
  result = call_598331.call(nil, nil, nil, nil, body_598332)

var putModel* = Call_PutModel_598318(name: "putModel", meth: HttpMethod.HttpPost,
                                  host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.PutModel",
                                  validator: validate_PutModel_598319, base: "/",
                                  url: url_PutModel_598320,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutOutcome_598333 = ref object of OpenApiRestCall_597389
proc url_PutOutcome_598335(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutOutcome_598334(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598336 = header.getOrDefault("X-Amz-Target")
  valid_598336 = validateParameter(valid_598336, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.PutOutcome"))
  if valid_598336 != nil:
    section.add "X-Amz-Target", valid_598336
  var valid_598337 = header.getOrDefault("X-Amz-Signature")
  valid_598337 = validateParameter(valid_598337, JString, required = false,
                                 default = nil)
  if valid_598337 != nil:
    section.add "X-Amz-Signature", valid_598337
  var valid_598338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598338 = validateParameter(valid_598338, JString, required = false,
                                 default = nil)
  if valid_598338 != nil:
    section.add "X-Amz-Content-Sha256", valid_598338
  var valid_598339 = header.getOrDefault("X-Amz-Date")
  valid_598339 = validateParameter(valid_598339, JString, required = false,
                                 default = nil)
  if valid_598339 != nil:
    section.add "X-Amz-Date", valid_598339
  var valid_598340 = header.getOrDefault("X-Amz-Credential")
  valid_598340 = validateParameter(valid_598340, JString, required = false,
                                 default = nil)
  if valid_598340 != nil:
    section.add "X-Amz-Credential", valid_598340
  var valid_598341 = header.getOrDefault("X-Amz-Security-Token")
  valid_598341 = validateParameter(valid_598341, JString, required = false,
                                 default = nil)
  if valid_598341 != nil:
    section.add "X-Amz-Security-Token", valid_598341
  var valid_598342 = header.getOrDefault("X-Amz-Algorithm")
  valid_598342 = validateParameter(valid_598342, JString, required = false,
                                 default = nil)
  if valid_598342 != nil:
    section.add "X-Amz-Algorithm", valid_598342
  var valid_598343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598343 = validateParameter(valid_598343, JString, required = false,
                                 default = nil)
  if valid_598343 != nil:
    section.add "X-Amz-SignedHeaders", valid_598343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598345: Call_PutOutcome_598333; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates an outcome. 
  ## 
  let valid = call_598345.validator(path, query, header, formData, body)
  let scheme = call_598345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598345.url(scheme.get, call_598345.host, call_598345.base,
                         call_598345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598345, url, valid)

proc call*(call_598346: Call_PutOutcome_598333; body: JsonNode): Recallable =
  ## putOutcome
  ## Creates or updates an outcome. 
  ##   body: JObject (required)
  var body_598347 = newJObject()
  if body != nil:
    body_598347 = body
  result = call_598346.call(nil, nil, nil, nil, body_598347)

var putOutcome* = Call_PutOutcome_598333(name: "putOutcome",
                                      meth: HttpMethod.HttpPost,
                                      host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.PutOutcome",
                                      validator: validate_PutOutcome_598334,
                                      base: "/", url: url_PutOutcome_598335,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorVersion_598348 = ref object of OpenApiRestCall_597389
proc url_UpdateDetectorVersion_598350(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDetectorVersion_598349(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598351 = header.getOrDefault("X-Amz-Target")
  valid_598351 = validateParameter(valid_598351, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateDetectorVersion"))
  if valid_598351 != nil:
    section.add "X-Amz-Target", valid_598351
  var valid_598352 = header.getOrDefault("X-Amz-Signature")
  valid_598352 = validateParameter(valid_598352, JString, required = false,
                                 default = nil)
  if valid_598352 != nil:
    section.add "X-Amz-Signature", valid_598352
  var valid_598353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598353 = validateParameter(valid_598353, JString, required = false,
                                 default = nil)
  if valid_598353 != nil:
    section.add "X-Amz-Content-Sha256", valid_598353
  var valid_598354 = header.getOrDefault("X-Amz-Date")
  valid_598354 = validateParameter(valid_598354, JString, required = false,
                                 default = nil)
  if valid_598354 != nil:
    section.add "X-Amz-Date", valid_598354
  var valid_598355 = header.getOrDefault("X-Amz-Credential")
  valid_598355 = validateParameter(valid_598355, JString, required = false,
                                 default = nil)
  if valid_598355 != nil:
    section.add "X-Amz-Credential", valid_598355
  var valid_598356 = header.getOrDefault("X-Amz-Security-Token")
  valid_598356 = validateParameter(valid_598356, JString, required = false,
                                 default = nil)
  if valid_598356 != nil:
    section.add "X-Amz-Security-Token", valid_598356
  var valid_598357 = header.getOrDefault("X-Amz-Algorithm")
  valid_598357 = validateParameter(valid_598357, JString, required = false,
                                 default = nil)
  if valid_598357 != nil:
    section.add "X-Amz-Algorithm", valid_598357
  var valid_598358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598358 = validateParameter(valid_598358, JString, required = false,
                                 default = nil)
  if valid_598358 != nil:
    section.add "X-Amz-SignedHeaders", valid_598358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598360: Call_UpdateDetectorVersion_598348; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates a detector version. The detector version attributes that you can update include models, external model endpoints, rules, and description. You can only update a <code>DRAFT</code> detector version.
  ## 
  let valid = call_598360.validator(path, query, header, formData, body)
  let scheme = call_598360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598360.url(scheme.get, call_598360.host, call_598360.base,
                         call_598360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598360, url, valid)

proc call*(call_598361: Call_UpdateDetectorVersion_598348; body: JsonNode): Recallable =
  ## updateDetectorVersion
  ##  Updates a detector version. The detector version attributes that you can update include models, external model endpoints, rules, and description. You can only update a <code>DRAFT</code> detector version.
  ##   body: JObject (required)
  var body_598362 = newJObject()
  if body != nil:
    body_598362 = body
  result = call_598361.call(nil, nil, nil, nil, body_598362)

var updateDetectorVersion* = Call_UpdateDetectorVersion_598348(
    name: "updateDetectorVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateDetectorVersion",
    validator: validate_UpdateDetectorVersion_598349, base: "/",
    url: url_UpdateDetectorVersion_598350, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorVersionMetadata_598363 = ref object of OpenApiRestCall_597389
proc url_UpdateDetectorVersionMetadata_598365(protocol: Scheme; host: string;
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

proc validate_UpdateDetectorVersionMetadata_598364(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598366 = header.getOrDefault("X-Amz-Target")
  valid_598366 = validateParameter(valid_598366, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateDetectorVersionMetadata"))
  if valid_598366 != nil:
    section.add "X-Amz-Target", valid_598366
  var valid_598367 = header.getOrDefault("X-Amz-Signature")
  valid_598367 = validateParameter(valid_598367, JString, required = false,
                                 default = nil)
  if valid_598367 != nil:
    section.add "X-Amz-Signature", valid_598367
  var valid_598368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598368 = validateParameter(valid_598368, JString, required = false,
                                 default = nil)
  if valid_598368 != nil:
    section.add "X-Amz-Content-Sha256", valid_598368
  var valid_598369 = header.getOrDefault("X-Amz-Date")
  valid_598369 = validateParameter(valid_598369, JString, required = false,
                                 default = nil)
  if valid_598369 != nil:
    section.add "X-Amz-Date", valid_598369
  var valid_598370 = header.getOrDefault("X-Amz-Credential")
  valid_598370 = validateParameter(valid_598370, JString, required = false,
                                 default = nil)
  if valid_598370 != nil:
    section.add "X-Amz-Credential", valid_598370
  var valid_598371 = header.getOrDefault("X-Amz-Security-Token")
  valid_598371 = validateParameter(valid_598371, JString, required = false,
                                 default = nil)
  if valid_598371 != nil:
    section.add "X-Amz-Security-Token", valid_598371
  var valid_598372 = header.getOrDefault("X-Amz-Algorithm")
  valid_598372 = validateParameter(valid_598372, JString, required = false,
                                 default = nil)
  if valid_598372 != nil:
    section.add "X-Amz-Algorithm", valid_598372
  var valid_598373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598373 = validateParameter(valid_598373, JString, required = false,
                                 default = nil)
  if valid_598373 != nil:
    section.add "X-Amz-SignedHeaders", valid_598373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598375: Call_UpdateDetectorVersionMetadata_598363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the detector version's description. You can update the metadata for any detector version (<code>DRAFT, ACTIVE,</code> or <code>INACTIVE</code>). 
  ## 
  let valid = call_598375.validator(path, query, header, formData, body)
  let scheme = call_598375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598375.url(scheme.get, call_598375.host, call_598375.base,
                         call_598375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598375, url, valid)

proc call*(call_598376: Call_UpdateDetectorVersionMetadata_598363; body: JsonNode): Recallable =
  ## updateDetectorVersionMetadata
  ## Updates the detector version's description. You can update the metadata for any detector version (<code>DRAFT, ACTIVE,</code> or <code>INACTIVE</code>). 
  ##   body: JObject (required)
  var body_598377 = newJObject()
  if body != nil:
    body_598377 = body
  result = call_598376.call(nil, nil, nil, nil, body_598377)

var updateDetectorVersionMetadata* = Call_UpdateDetectorVersionMetadata_598363(
    name: "updateDetectorVersionMetadata", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateDetectorVersionMetadata",
    validator: validate_UpdateDetectorVersionMetadata_598364, base: "/",
    url: url_UpdateDetectorVersionMetadata_598365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorVersionStatus_598378 = ref object of OpenApiRestCall_597389
proc url_UpdateDetectorVersionStatus_598380(protocol: Scheme; host: string;
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

proc validate_UpdateDetectorVersionStatus_598379(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598381 = header.getOrDefault("X-Amz-Target")
  valid_598381 = validateParameter(valid_598381, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateDetectorVersionStatus"))
  if valid_598381 != nil:
    section.add "X-Amz-Target", valid_598381
  var valid_598382 = header.getOrDefault("X-Amz-Signature")
  valid_598382 = validateParameter(valid_598382, JString, required = false,
                                 default = nil)
  if valid_598382 != nil:
    section.add "X-Amz-Signature", valid_598382
  var valid_598383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598383 = validateParameter(valid_598383, JString, required = false,
                                 default = nil)
  if valid_598383 != nil:
    section.add "X-Amz-Content-Sha256", valid_598383
  var valid_598384 = header.getOrDefault("X-Amz-Date")
  valid_598384 = validateParameter(valid_598384, JString, required = false,
                                 default = nil)
  if valid_598384 != nil:
    section.add "X-Amz-Date", valid_598384
  var valid_598385 = header.getOrDefault("X-Amz-Credential")
  valid_598385 = validateParameter(valid_598385, JString, required = false,
                                 default = nil)
  if valid_598385 != nil:
    section.add "X-Amz-Credential", valid_598385
  var valid_598386 = header.getOrDefault("X-Amz-Security-Token")
  valid_598386 = validateParameter(valid_598386, JString, required = false,
                                 default = nil)
  if valid_598386 != nil:
    section.add "X-Amz-Security-Token", valid_598386
  var valid_598387 = header.getOrDefault("X-Amz-Algorithm")
  valid_598387 = validateParameter(valid_598387, JString, required = false,
                                 default = nil)
  if valid_598387 != nil:
    section.add "X-Amz-Algorithm", valid_598387
  var valid_598388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598388 = validateParameter(valid_598388, JString, required = false,
                                 default = nil)
  if valid_598388 != nil:
    section.add "X-Amz-SignedHeaders", valid_598388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598390: Call_UpdateDetectorVersionStatus_598378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the detector version’s status. You can perform the following promotions or demotions using <code>UpdateDetectorVersionStatus</code>: <code>DRAFT</code> to <code>ACTIVE</code>, <code>ACTIVE</code> to <code>INACTIVE</code>, and <code>INACTIVE</code> to <code>ACTIVE</code>.
  ## 
  let valid = call_598390.validator(path, query, header, formData, body)
  let scheme = call_598390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598390.url(scheme.get, call_598390.host, call_598390.base,
                         call_598390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598390, url, valid)

proc call*(call_598391: Call_UpdateDetectorVersionStatus_598378; body: JsonNode): Recallable =
  ## updateDetectorVersionStatus
  ## Updates the detector version’s status. You can perform the following promotions or demotions using <code>UpdateDetectorVersionStatus</code>: <code>DRAFT</code> to <code>ACTIVE</code>, <code>ACTIVE</code> to <code>INACTIVE</code>, and <code>INACTIVE</code> to <code>ACTIVE</code>.
  ##   body: JObject (required)
  var body_598392 = newJObject()
  if body != nil:
    body_598392 = body
  result = call_598391.call(nil, nil, nil, nil, body_598392)

var updateDetectorVersionStatus* = Call_UpdateDetectorVersionStatus_598378(
    name: "updateDetectorVersionStatus", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateDetectorVersionStatus",
    validator: validate_UpdateDetectorVersionStatus_598379, base: "/",
    url: url_UpdateDetectorVersionStatus_598380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModelVersion_598393 = ref object of OpenApiRestCall_597389
proc url_UpdateModelVersion_598395(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateModelVersion_598394(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598396 = header.getOrDefault("X-Amz-Target")
  valid_598396 = validateParameter(valid_598396, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateModelVersion"))
  if valid_598396 != nil:
    section.add "X-Amz-Target", valid_598396
  var valid_598397 = header.getOrDefault("X-Amz-Signature")
  valid_598397 = validateParameter(valid_598397, JString, required = false,
                                 default = nil)
  if valid_598397 != nil:
    section.add "X-Amz-Signature", valid_598397
  var valid_598398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598398 = validateParameter(valid_598398, JString, required = false,
                                 default = nil)
  if valid_598398 != nil:
    section.add "X-Amz-Content-Sha256", valid_598398
  var valid_598399 = header.getOrDefault("X-Amz-Date")
  valid_598399 = validateParameter(valid_598399, JString, required = false,
                                 default = nil)
  if valid_598399 != nil:
    section.add "X-Amz-Date", valid_598399
  var valid_598400 = header.getOrDefault("X-Amz-Credential")
  valid_598400 = validateParameter(valid_598400, JString, required = false,
                                 default = nil)
  if valid_598400 != nil:
    section.add "X-Amz-Credential", valid_598400
  var valid_598401 = header.getOrDefault("X-Amz-Security-Token")
  valid_598401 = validateParameter(valid_598401, JString, required = false,
                                 default = nil)
  if valid_598401 != nil:
    section.add "X-Amz-Security-Token", valid_598401
  var valid_598402 = header.getOrDefault("X-Amz-Algorithm")
  valid_598402 = validateParameter(valid_598402, JString, required = false,
                                 default = nil)
  if valid_598402 != nil:
    section.add "X-Amz-Algorithm", valid_598402
  var valid_598403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598403 = validateParameter(valid_598403, JString, required = false,
                                 default = nil)
  if valid_598403 != nil:
    section.add "X-Amz-SignedHeaders", valid_598403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598405: Call_UpdateModelVersion_598393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a model version. You can update the description and status attributes using this action. You can perform the following status updates: </p> <ol> <li> <p>Change the <code>TRAINING_COMPLETE</code> status to <code>ACTIVE</code> </p> </li> <li> <p>Change <code>ACTIVE</code> back to <code>TRAINING_COMPLETE</code> </p> </li> </ol>
  ## 
  let valid = call_598405.validator(path, query, header, formData, body)
  let scheme = call_598405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598405.url(scheme.get, call_598405.host, call_598405.base,
                         call_598405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598405, url, valid)

proc call*(call_598406: Call_UpdateModelVersion_598393; body: JsonNode): Recallable =
  ## updateModelVersion
  ## <p>Updates a model version. You can update the description and status attributes using this action. You can perform the following status updates: </p> <ol> <li> <p>Change the <code>TRAINING_COMPLETE</code> status to <code>ACTIVE</code> </p> </li> <li> <p>Change <code>ACTIVE</code> back to <code>TRAINING_COMPLETE</code> </p> </li> </ol>
  ##   body: JObject (required)
  var body_598407 = newJObject()
  if body != nil:
    body_598407 = body
  result = call_598406.call(nil, nil, nil, nil, body_598407)

var updateModelVersion* = Call_UpdateModelVersion_598393(
    name: "updateModelVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateModelVersion",
    validator: validate_UpdateModelVersion_598394, base: "/",
    url: url_UpdateModelVersion_598395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRuleMetadata_598408 = ref object of OpenApiRestCall_597389
proc url_UpdateRuleMetadata_598410(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRuleMetadata_598409(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598411 = header.getOrDefault("X-Amz-Target")
  valid_598411 = validateParameter(valid_598411, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateRuleMetadata"))
  if valid_598411 != nil:
    section.add "X-Amz-Target", valid_598411
  var valid_598412 = header.getOrDefault("X-Amz-Signature")
  valid_598412 = validateParameter(valid_598412, JString, required = false,
                                 default = nil)
  if valid_598412 != nil:
    section.add "X-Amz-Signature", valid_598412
  var valid_598413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598413 = validateParameter(valid_598413, JString, required = false,
                                 default = nil)
  if valid_598413 != nil:
    section.add "X-Amz-Content-Sha256", valid_598413
  var valid_598414 = header.getOrDefault("X-Amz-Date")
  valid_598414 = validateParameter(valid_598414, JString, required = false,
                                 default = nil)
  if valid_598414 != nil:
    section.add "X-Amz-Date", valid_598414
  var valid_598415 = header.getOrDefault("X-Amz-Credential")
  valid_598415 = validateParameter(valid_598415, JString, required = false,
                                 default = nil)
  if valid_598415 != nil:
    section.add "X-Amz-Credential", valid_598415
  var valid_598416 = header.getOrDefault("X-Amz-Security-Token")
  valid_598416 = validateParameter(valid_598416, JString, required = false,
                                 default = nil)
  if valid_598416 != nil:
    section.add "X-Amz-Security-Token", valid_598416
  var valid_598417 = header.getOrDefault("X-Amz-Algorithm")
  valid_598417 = validateParameter(valid_598417, JString, required = false,
                                 default = nil)
  if valid_598417 != nil:
    section.add "X-Amz-Algorithm", valid_598417
  var valid_598418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598418 = validateParameter(valid_598418, JString, required = false,
                                 default = nil)
  if valid_598418 != nil:
    section.add "X-Amz-SignedHeaders", valid_598418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598420: Call_UpdateRuleMetadata_598408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a rule's metadata. 
  ## 
  let valid = call_598420.validator(path, query, header, formData, body)
  let scheme = call_598420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598420.url(scheme.get, call_598420.host, call_598420.base,
                         call_598420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598420, url, valid)

proc call*(call_598421: Call_UpdateRuleMetadata_598408; body: JsonNode): Recallable =
  ## updateRuleMetadata
  ## Updates a rule's metadata. 
  ##   body: JObject (required)
  var body_598422 = newJObject()
  if body != nil:
    body_598422 = body
  result = call_598421.call(nil, nil, nil, nil, body_598422)

var updateRuleMetadata* = Call_UpdateRuleMetadata_598408(
    name: "updateRuleMetadata", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateRuleMetadata",
    validator: validate_UpdateRuleMetadata_598409, base: "/",
    url: url_UpdateRuleMetadata_598410, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRuleVersion_598423 = ref object of OpenApiRestCall_597389
proc url_UpdateRuleVersion_598425(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRuleVersion_598424(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598426 = header.getOrDefault("X-Amz-Target")
  valid_598426 = validateParameter(valid_598426, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateRuleVersion"))
  if valid_598426 != nil:
    section.add "X-Amz-Target", valid_598426
  var valid_598427 = header.getOrDefault("X-Amz-Signature")
  valid_598427 = validateParameter(valid_598427, JString, required = false,
                                 default = nil)
  if valid_598427 != nil:
    section.add "X-Amz-Signature", valid_598427
  var valid_598428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598428 = validateParameter(valid_598428, JString, required = false,
                                 default = nil)
  if valid_598428 != nil:
    section.add "X-Amz-Content-Sha256", valid_598428
  var valid_598429 = header.getOrDefault("X-Amz-Date")
  valid_598429 = validateParameter(valid_598429, JString, required = false,
                                 default = nil)
  if valid_598429 != nil:
    section.add "X-Amz-Date", valid_598429
  var valid_598430 = header.getOrDefault("X-Amz-Credential")
  valid_598430 = validateParameter(valid_598430, JString, required = false,
                                 default = nil)
  if valid_598430 != nil:
    section.add "X-Amz-Credential", valid_598430
  var valid_598431 = header.getOrDefault("X-Amz-Security-Token")
  valid_598431 = validateParameter(valid_598431, JString, required = false,
                                 default = nil)
  if valid_598431 != nil:
    section.add "X-Amz-Security-Token", valid_598431
  var valid_598432 = header.getOrDefault("X-Amz-Algorithm")
  valid_598432 = validateParameter(valid_598432, JString, required = false,
                                 default = nil)
  if valid_598432 != nil:
    section.add "X-Amz-Algorithm", valid_598432
  var valid_598433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598433 = validateParameter(valid_598433, JString, required = false,
                                 default = nil)
  if valid_598433 != nil:
    section.add "X-Amz-SignedHeaders", valid_598433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598435: Call_UpdateRuleVersion_598423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a rule version resulting in a new rule version. 
  ## 
  let valid = call_598435.validator(path, query, header, formData, body)
  let scheme = call_598435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598435.url(scheme.get, call_598435.host, call_598435.base,
                         call_598435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598435, url, valid)

proc call*(call_598436: Call_UpdateRuleVersion_598423; body: JsonNode): Recallable =
  ## updateRuleVersion
  ## Updates a rule version resulting in a new rule version. 
  ##   body: JObject (required)
  var body_598437 = newJObject()
  if body != nil:
    body_598437 = body
  result = call_598436.call(nil, nil, nil, nil, body_598437)

var updateRuleVersion* = Call_UpdateRuleVersion_598423(name: "updateRuleVersion",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateRuleVersion",
    validator: validate_UpdateRuleVersion_598424, base: "/",
    url: url_UpdateRuleVersion_598425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVariable_598438 = ref object of OpenApiRestCall_597389
proc url_UpdateVariable_598440(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVariable_598439(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598441 = header.getOrDefault("X-Amz-Target")
  valid_598441 = validateParameter(valid_598441, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateVariable"))
  if valid_598441 != nil:
    section.add "X-Amz-Target", valid_598441
  var valid_598442 = header.getOrDefault("X-Amz-Signature")
  valid_598442 = validateParameter(valid_598442, JString, required = false,
                                 default = nil)
  if valid_598442 != nil:
    section.add "X-Amz-Signature", valid_598442
  var valid_598443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598443 = validateParameter(valid_598443, JString, required = false,
                                 default = nil)
  if valid_598443 != nil:
    section.add "X-Amz-Content-Sha256", valid_598443
  var valid_598444 = header.getOrDefault("X-Amz-Date")
  valid_598444 = validateParameter(valid_598444, JString, required = false,
                                 default = nil)
  if valid_598444 != nil:
    section.add "X-Amz-Date", valid_598444
  var valid_598445 = header.getOrDefault("X-Amz-Credential")
  valid_598445 = validateParameter(valid_598445, JString, required = false,
                                 default = nil)
  if valid_598445 != nil:
    section.add "X-Amz-Credential", valid_598445
  var valid_598446 = header.getOrDefault("X-Amz-Security-Token")
  valid_598446 = validateParameter(valid_598446, JString, required = false,
                                 default = nil)
  if valid_598446 != nil:
    section.add "X-Amz-Security-Token", valid_598446
  var valid_598447 = header.getOrDefault("X-Amz-Algorithm")
  valid_598447 = validateParameter(valid_598447, JString, required = false,
                                 default = nil)
  if valid_598447 != nil:
    section.add "X-Amz-Algorithm", valid_598447
  var valid_598448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598448 = validateParameter(valid_598448, JString, required = false,
                                 default = nil)
  if valid_598448 != nil:
    section.add "X-Amz-SignedHeaders", valid_598448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598450: Call_UpdateVariable_598438; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a variable.
  ## 
  let valid = call_598450.validator(path, query, header, formData, body)
  let scheme = call_598450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598450.url(scheme.get, call_598450.host, call_598450.base,
                         call_598450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598450, url, valid)

proc call*(call_598451: Call_UpdateVariable_598438; body: JsonNode): Recallable =
  ## updateVariable
  ## Updates a variable.
  ##   body: JObject (required)
  var body_598452 = newJObject()
  if body != nil:
    body_598452 = body
  result = call_598451.call(nil, nil, nil, nil, body_598452)

var updateVariable* = Call_UpdateVariable_598438(name: "updateVariable",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateVariable",
    validator: validate_UpdateVariable_598439, base: "/", url: url_UpdateVariable_598440,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
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
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
