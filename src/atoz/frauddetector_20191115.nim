
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_BatchCreateVariable_601727 = ref object of OpenApiRestCall_601389
proc url_BatchCreateVariable_601729(protocol: Scheme; host: string; base: string;
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

proc validate_BatchCreateVariable_601728(path: JsonNode; query: JsonNode;
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
  var valid_601854 = header.getOrDefault("X-Amz-Target")
  valid_601854 = validateParameter(valid_601854, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.BatchCreateVariable"))
  if valid_601854 != nil:
    section.add "X-Amz-Target", valid_601854
  var valid_601855 = header.getOrDefault("X-Amz-Signature")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "X-Amz-Signature", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Content-Sha256", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Date")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Date", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Credential")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Credential", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Security-Token")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Security-Token", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Algorithm")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Algorithm", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-SignedHeaders", valid_601861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601885: Call_BatchCreateVariable_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a batch of variables.
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_BatchCreateVariable_601727; body: JsonNode): Recallable =
  ## batchCreateVariable
  ## Creates a batch of variables.
  ##   body: JObject (required)
  var body_601957 = newJObject()
  if body != nil:
    body_601957 = body
  result = call_601956.call(nil, nil, nil, nil, body_601957)

var batchCreateVariable* = Call_BatchCreateVariable_601727(
    name: "batchCreateVariable", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.BatchCreateVariable",
    validator: validate_BatchCreateVariable_601728, base: "/",
    url: url_BatchCreateVariable_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetVariable_601996 = ref object of OpenApiRestCall_601389
proc url_BatchGetVariable_601998(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetVariable_601997(path: JsonNode; query: JsonNode;
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
  var valid_601999 = header.getOrDefault("X-Amz-Target")
  valid_601999 = validateParameter(valid_601999, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.BatchGetVariable"))
  if valid_601999 != nil:
    section.add "X-Amz-Target", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Signature")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Signature", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Content-Sha256", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Date")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Date", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Credential")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Credential", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Security-Token")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Security-Token", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Algorithm")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Algorithm", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-SignedHeaders", valid_602006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602008: Call_BatchGetVariable_601996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a batch of variables.
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_BatchGetVariable_601996; body: JsonNode): Recallable =
  ## batchGetVariable
  ## Gets a batch of variables.
  ##   body: JObject (required)
  var body_602010 = newJObject()
  if body != nil:
    body_602010 = body
  result = call_602009.call(nil, nil, nil, nil, body_602010)

var batchGetVariable* = Call_BatchGetVariable_601996(name: "batchGetVariable",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.BatchGetVariable",
    validator: validate_BatchGetVariable_601997, base: "/",
    url: url_BatchGetVariable_601998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDetectorVersion_602011 = ref object of OpenApiRestCall_601389
proc url_CreateDetectorVersion_602013(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDetectorVersion_602012(path: JsonNode; query: JsonNode;
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
  var valid_602014 = header.getOrDefault("X-Amz-Target")
  valid_602014 = validateParameter(valid_602014, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.CreateDetectorVersion"))
  if valid_602014 != nil:
    section.add "X-Amz-Target", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Signature")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Signature", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Content-Sha256", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Date")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Date", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Credential")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Credential", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Security-Token")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Security-Token", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Algorithm")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Algorithm", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-SignedHeaders", valid_602021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602023: Call_CreateDetectorVersion_602011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a detector version. The detector version starts in a <code>DRAFT</code> status.
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_CreateDetectorVersion_602011; body: JsonNode): Recallable =
  ## createDetectorVersion
  ## Creates a detector version. The detector version starts in a <code>DRAFT</code> status.
  ##   body: JObject (required)
  var body_602025 = newJObject()
  if body != nil:
    body_602025 = body
  result = call_602024.call(nil, nil, nil, nil, body_602025)

var createDetectorVersion* = Call_CreateDetectorVersion_602011(
    name: "createDetectorVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.CreateDetectorVersion",
    validator: validate_CreateDetectorVersion_602012, base: "/",
    url: url_CreateDetectorVersion_602013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModelVersion_602026 = ref object of OpenApiRestCall_601389
proc url_CreateModelVersion_602028(protocol: Scheme; host: string; base: string;
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

proc validate_CreateModelVersion_602027(path: JsonNode; query: JsonNode;
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
  var valid_602029 = header.getOrDefault("X-Amz-Target")
  valid_602029 = validateParameter(valid_602029, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.CreateModelVersion"))
  if valid_602029 != nil:
    section.add "X-Amz-Target", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Signature")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Signature", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Content-Sha256", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Date")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Date", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Credential")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Credential", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Security-Token")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Security-Token", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Algorithm")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Algorithm", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-SignedHeaders", valid_602036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602038: Call_CreateModelVersion_602026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of the model using the specified model type. 
  ## 
  let valid = call_602038.validator(path, query, header, formData, body)
  let scheme = call_602038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602038.url(scheme.get, call_602038.host, call_602038.base,
                         call_602038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602038, url, valid)

proc call*(call_602039: Call_CreateModelVersion_602026; body: JsonNode): Recallable =
  ## createModelVersion
  ## Creates a version of the model using the specified model type. 
  ##   body: JObject (required)
  var body_602040 = newJObject()
  if body != nil:
    body_602040 = body
  result = call_602039.call(nil, nil, nil, nil, body_602040)

var createModelVersion* = Call_CreateModelVersion_602026(
    name: "createModelVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.CreateModelVersion",
    validator: validate_CreateModelVersion_602027, base: "/",
    url: url_CreateModelVersion_602028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRule_602041 = ref object of OpenApiRestCall_601389
proc url_CreateRule_602043(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateRule_602042(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602044 = header.getOrDefault("X-Amz-Target")
  valid_602044 = validateParameter(valid_602044, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.CreateRule"))
  if valid_602044 != nil:
    section.add "X-Amz-Target", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Signature")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Signature", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Content-Sha256", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Date")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Date", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Credential")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Credential", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Security-Token")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Security-Token", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Algorithm")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Algorithm", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-SignedHeaders", valid_602051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602053: Call_CreateRule_602041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a rule for use with the specified detector. 
  ## 
  let valid = call_602053.validator(path, query, header, formData, body)
  let scheme = call_602053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602053.url(scheme.get, call_602053.host, call_602053.base,
                         call_602053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602053, url, valid)

proc call*(call_602054: Call_CreateRule_602041; body: JsonNode): Recallable =
  ## createRule
  ## Creates a rule for use with the specified detector. 
  ##   body: JObject (required)
  var body_602055 = newJObject()
  if body != nil:
    body_602055 = body
  result = call_602054.call(nil, nil, nil, nil, body_602055)

var createRule* = Call_CreateRule_602041(name: "createRule",
                                      meth: HttpMethod.HttpPost,
                                      host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.CreateRule",
                                      validator: validate_CreateRule_602042,
                                      base: "/", url: url_CreateRule_602043,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVariable_602056 = ref object of OpenApiRestCall_601389
proc url_CreateVariable_602058(protocol: Scheme; host: string; base: string;
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

proc validate_CreateVariable_602057(path: JsonNode; query: JsonNode;
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
  var valid_602059 = header.getOrDefault("X-Amz-Target")
  valid_602059 = validateParameter(valid_602059, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.CreateVariable"))
  if valid_602059 != nil:
    section.add "X-Amz-Target", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Signature")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Signature", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Content-Sha256", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Date")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Date", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Credential")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Credential", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Security-Token")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Security-Token", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Algorithm")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Algorithm", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-SignedHeaders", valid_602066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602068: Call_CreateVariable_602056; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a variable.
  ## 
  let valid = call_602068.validator(path, query, header, formData, body)
  let scheme = call_602068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602068.url(scheme.get, call_602068.host, call_602068.base,
                         call_602068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602068, url, valid)

proc call*(call_602069: Call_CreateVariable_602056; body: JsonNode): Recallable =
  ## createVariable
  ## Creates a variable.
  ##   body: JObject (required)
  var body_602070 = newJObject()
  if body != nil:
    body_602070 = body
  result = call_602069.call(nil, nil, nil, nil, body_602070)

var createVariable* = Call_CreateVariable_602056(name: "createVariable",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.CreateVariable",
    validator: validate_CreateVariable_602057, base: "/", url: url_CreateVariable_602058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDetectorVersion_602071 = ref object of OpenApiRestCall_601389
proc url_DeleteDetectorVersion_602073(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDetectorVersion_602072(path: JsonNode; query: JsonNode;
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
  var valid_602074 = header.getOrDefault("X-Amz-Target")
  valid_602074 = validateParameter(valid_602074, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.DeleteDetectorVersion"))
  if valid_602074 != nil:
    section.add "X-Amz-Target", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Signature")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Signature", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Content-Sha256", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Date")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Date", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Credential")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Credential", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Security-Token")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Security-Token", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Algorithm")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Algorithm", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-SignedHeaders", valid_602081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602083: Call_DeleteDetectorVersion_602071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the detector version.
  ## 
  let valid = call_602083.validator(path, query, header, formData, body)
  let scheme = call_602083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602083.url(scheme.get, call_602083.host, call_602083.base,
                         call_602083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602083, url, valid)

proc call*(call_602084: Call_DeleteDetectorVersion_602071; body: JsonNode): Recallable =
  ## deleteDetectorVersion
  ## Deletes the detector version.
  ##   body: JObject (required)
  var body_602085 = newJObject()
  if body != nil:
    body_602085 = body
  result = call_602084.call(nil, nil, nil, nil, body_602085)

var deleteDetectorVersion* = Call_DeleteDetectorVersion_602071(
    name: "deleteDetectorVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.DeleteDetectorVersion",
    validator: validate_DeleteDetectorVersion_602072, base: "/",
    url: url_DeleteDetectorVersion_602073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEvent_602086 = ref object of OpenApiRestCall_601389
proc url_DeleteEvent_602088(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEvent_602087(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602089 = header.getOrDefault("X-Amz-Target")
  valid_602089 = validateParameter(valid_602089, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.DeleteEvent"))
  if valid_602089 != nil:
    section.add "X-Amz-Target", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Signature")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Signature", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Content-Sha256", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Date")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Date", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Credential")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Credential", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Security-Token")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Security-Token", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Algorithm")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Algorithm", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-SignedHeaders", valid_602096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602098: Call_DeleteEvent_602086; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified event.
  ## 
  let valid = call_602098.validator(path, query, header, formData, body)
  let scheme = call_602098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602098.url(scheme.get, call_602098.host, call_602098.base,
                         call_602098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602098, url, valid)

proc call*(call_602099: Call_DeleteEvent_602086; body: JsonNode): Recallable =
  ## deleteEvent
  ## Deletes the specified event.
  ##   body: JObject (required)
  var body_602100 = newJObject()
  if body != nil:
    body_602100 = body
  result = call_602099.call(nil, nil, nil, nil, body_602100)

var deleteEvent* = Call_DeleteEvent_602086(name: "deleteEvent",
                                        meth: HttpMethod.HttpPost,
                                        host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.DeleteEvent",
                                        validator: validate_DeleteEvent_602087,
                                        base: "/", url: url_DeleteEvent_602088,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDetector_602101 = ref object of OpenApiRestCall_601389
proc url_DescribeDetector_602103(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDetector_602102(path: JsonNode; query: JsonNode;
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
  var valid_602104 = header.getOrDefault("X-Amz-Target")
  valid_602104 = validateParameter(valid_602104, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.DescribeDetector"))
  if valid_602104 != nil:
    section.add "X-Amz-Target", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Signature")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Signature", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Content-Sha256", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Date")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Date", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Credential")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Credential", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Security-Token")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Security-Token", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Algorithm")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Algorithm", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-SignedHeaders", valid_602111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602113: Call_DescribeDetector_602101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all versions for a specified detector.
  ## 
  let valid = call_602113.validator(path, query, header, formData, body)
  let scheme = call_602113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602113.url(scheme.get, call_602113.host, call_602113.base,
                         call_602113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602113, url, valid)

proc call*(call_602114: Call_DescribeDetector_602101; body: JsonNode): Recallable =
  ## describeDetector
  ## Gets all versions for a specified detector.
  ##   body: JObject (required)
  var body_602115 = newJObject()
  if body != nil:
    body_602115 = body
  result = call_602114.call(nil, nil, nil, nil, body_602115)

var describeDetector* = Call_DescribeDetector_602101(name: "describeDetector",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.DescribeDetector",
    validator: validate_DescribeDetector_602102, base: "/",
    url: url_DescribeDetector_602103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModelVersions_602116 = ref object of OpenApiRestCall_601389
proc url_DescribeModelVersions_602118(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeModelVersions_602117(path: JsonNode; query: JsonNode;
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
  var valid_602119 = query.getOrDefault("nextToken")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "nextToken", valid_602119
  var valid_602120 = query.getOrDefault("maxResults")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "maxResults", valid_602120
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
  var valid_602121 = header.getOrDefault("X-Amz-Target")
  valid_602121 = validateParameter(valid_602121, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.DescribeModelVersions"))
  if valid_602121 != nil:
    section.add "X-Amz-Target", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Signature")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Signature", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Content-Sha256", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Date")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Date", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Credential")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Credential", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Security-Token")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Security-Token", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Algorithm")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Algorithm", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-SignedHeaders", valid_602128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602130: Call_DescribeModelVersions_602116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all of the model versions for the specified model type or for the specified model type and model ID. You can also get details for a single, specified model version. 
  ## 
  let valid = call_602130.validator(path, query, header, formData, body)
  let scheme = call_602130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602130.url(scheme.get, call_602130.host, call_602130.base,
                         call_602130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602130, url, valid)

proc call*(call_602131: Call_DescribeModelVersions_602116; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeModelVersions
  ## Gets all of the model versions for the specified model type or for the specified model type and model ID. You can also get details for a single, specified model version. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602132 = newJObject()
  var body_602133 = newJObject()
  add(query_602132, "nextToken", newJString(nextToken))
  if body != nil:
    body_602133 = body
  add(query_602132, "maxResults", newJString(maxResults))
  result = call_602131.call(nil, query_602132, nil, nil, body_602133)

var describeModelVersions* = Call_DescribeModelVersions_602116(
    name: "describeModelVersions", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.DescribeModelVersions",
    validator: validate_DescribeModelVersions_602117, base: "/",
    url: url_DescribeModelVersions_602118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetectorVersion_602135 = ref object of OpenApiRestCall_601389
proc url_GetDetectorVersion_602137(protocol: Scheme; host: string; base: string;
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

proc validate_GetDetectorVersion_602136(path: JsonNode; query: JsonNode;
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
  var valid_602138 = header.getOrDefault("X-Amz-Target")
  valid_602138 = validateParameter(valid_602138, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetDetectorVersion"))
  if valid_602138 != nil:
    section.add "X-Amz-Target", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Signature")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Signature", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Content-Sha256", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Date")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Date", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Credential")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Credential", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Security-Token")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Security-Token", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Algorithm")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Algorithm", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-SignedHeaders", valid_602145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602147: Call_GetDetectorVersion_602135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a particular detector version. 
  ## 
  let valid = call_602147.validator(path, query, header, formData, body)
  let scheme = call_602147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602147.url(scheme.get, call_602147.host, call_602147.base,
                         call_602147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602147, url, valid)

proc call*(call_602148: Call_GetDetectorVersion_602135; body: JsonNode): Recallable =
  ## getDetectorVersion
  ## Gets a particular detector version. 
  ##   body: JObject (required)
  var body_602149 = newJObject()
  if body != nil:
    body_602149 = body
  result = call_602148.call(nil, nil, nil, nil, body_602149)

var getDetectorVersion* = Call_GetDetectorVersion_602135(
    name: "getDetectorVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetDetectorVersion",
    validator: validate_GetDetectorVersion_602136, base: "/",
    url: url_GetDetectorVersion_602137, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetectors_602150 = ref object of OpenApiRestCall_601389
proc url_GetDetectors_602152(protocol: Scheme; host: string; base: string;
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

proc validate_GetDetectors_602151(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602153 = query.getOrDefault("nextToken")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "nextToken", valid_602153
  var valid_602154 = query.getOrDefault("maxResults")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "maxResults", valid_602154
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
  var valid_602155 = header.getOrDefault("X-Amz-Target")
  valid_602155 = validateParameter(valid_602155, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetDetectors"))
  if valid_602155 != nil:
    section.add "X-Amz-Target", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Signature")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Signature", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Content-Sha256", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Date")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Date", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Credential")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Credential", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Security-Token")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Security-Token", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-Algorithm")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Algorithm", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-SignedHeaders", valid_602162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602164: Call_GetDetectors_602150; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all of detectors. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetEventTypesResponse</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ## 
  let valid = call_602164.validator(path, query, header, formData, body)
  let scheme = call_602164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602164.url(scheme.get, call_602164.host, call_602164.base,
                         call_602164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602164, url, valid)

proc call*(call_602165: Call_GetDetectors_602150; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getDetectors
  ## Gets all of detectors. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetEventTypesResponse</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602166 = newJObject()
  var body_602167 = newJObject()
  add(query_602166, "nextToken", newJString(nextToken))
  if body != nil:
    body_602167 = body
  add(query_602166, "maxResults", newJString(maxResults))
  result = call_602165.call(nil, query_602166, nil, nil, body_602167)

var getDetectors* = Call_GetDetectors_602150(name: "getDetectors",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetDetectors",
    validator: validate_GetDetectors_602151, base: "/", url: url_GetDetectors_602152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExternalModels_602168 = ref object of OpenApiRestCall_601389
proc url_GetExternalModels_602170(protocol: Scheme; host: string; base: string;
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

proc validate_GetExternalModels_602169(path: JsonNode; query: JsonNode;
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
  var valid_602171 = query.getOrDefault("nextToken")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "nextToken", valid_602171
  var valid_602172 = query.getOrDefault("maxResults")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "maxResults", valid_602172
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
  var valid_602173 = header.getOrDefault("X-Amz-Target")
  valid_602173 = validateParameter(valid_602173, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetExternalModels"))
  if valid_602173 != nil:
    section.add "X-Amz-Target", valid_602173
  var valid_602174 = header.getOrDefault("X-Amz-Signature")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Signature", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Content-Sha256", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-Date")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Date", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Credential")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Credential", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Security-Token")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Security-Token", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Algorithm")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Algorithm", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-SignedHeaders", valid_602180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602182: Call_GetExternalModels_602168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the details for one or more Amazon SageMaker models that have been imported into the service. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetExternalModelsResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ## 
  let valid = call_602182.validator(path, query, header, formData, body)
  let scheme = call_602182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602182.url(scheme.get, call_602182.host, call_602182.base,
                         call_602182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602182, url, valid)

proc call*(call_602183: Call_GetExternalModels_602168; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getExternalModels
  ## Gets the details for one or more Amazon SageMaker models that have been imported into the service. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetExternalModelsResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602184 = newJObject()
  var body_602185 = newJObject()
  add(query_602184, "nextToken", newJString(nextToken))
  if body != nil:
    body_602185 = body
  add(query_602184, "maxResults", newJString(maxResults))
  result = call_602183.call(nil, query_602184, nil, nil, body_602185)

var getExternalModels* = Call_GetExternalModels_602168(name: "getExternalModels",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetExternalModels",
    validator: validate_GetExternalModels_602169, base: "/",
    url: url_GetExternalModels_602170, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelVersion_602186 = ref object of OpenApiRestCall_601389
proc url_GetModelVersion_602188(protocol: Scheme; host: string; base: string;
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

proc validate_GetModelVersion_602187(path: JsonNode; query: JsonNode;
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
  var valid_602189 = header.getOrDefault("X-Amz-Target")
  valid_602189 = validateParameter(valid_602189, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetModelVersion"))
  if valid_602189 != nil:
    section.add "X-Amz-Target", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-Signature")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Signature", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Content-Sha256", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Date")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Date", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Credential")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Credential", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Security-Token")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Security-Token", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Algorithm")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Algorithm", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-SignedHeaders", valid_602196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602198: Call_GetModelVersion_602186; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a model version. 
  ## 
  let valid = call_602198.validator(path, query, header, formData, body)
  let scheme = call_602198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602198.url(scheme.get, call_602198.host, call_602198.base,
                         call_602198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602198, url, valid)

proc call*(call_602199: Call_GetModelVersion_602186; body: JsonNode): Recallable =
  ## getModelVersion
  ## Gets a model version. 
  ##   body: JObject (required)
  var body_602200 = newJObject()
  if body != nil:
    body_602200 = body
  result = call_602199.call(nil, nil, nil, nil, body_602200)

var getModelVersion* = Call_GetModelVersion_602186(name: "getModelVersion",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetModelVersion",
    validator: validate_GetModelVersion_602187, base: "/", url: url_GetModelVersion_602188,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_602201 = ref object of OpenApiRestCall_601389
proc url_GetModels_602203(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModels_602202(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602204 = query.getOrDefault("nextToken")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "nextToken", valid_602204
  var valid_602205 = query.getOrDefault("maxResults")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "maxResults", valid_602205
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
  var valid_602206 = header.getOrDefault("X-Amz-Target")
  valid_602206 = validateParameter(valid_602206, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetModels"))
  if valid_602206 != nil:
    section.add "X-Amz-Target", valid_602206
  var valid_602207 = header.getOrDefault("X-Amz-Signature")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "X-Amz-Signature", valid_602207
  var valid_602208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "X-Amz-Content-Sha256", valid_602208
  var valid_602209 = header.getOrDefault("X-Amz-Date")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-Date", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Credential")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Credential", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-Security-Token")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Security-Token", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Algorithm")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Algorithm", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-SignedHeaders", valid_602213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602215: Call_GetModels_602201; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all of the models for the AWS account, or the specified model type, or gets a single model for the specified model type, model ID combination. 
  ## 
  let valid = call_602215.validator(path, query, header, formData, body)
  let scheme = call_602215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602215.url(scheme.get, call_602215.host, call_602215.base,
                         call_602215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602215, url, valid)

proc call*(call_602216: Call_GetModels_602201; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getModels
  ## Gets all of the models for the AWS account, or the specified model type, or gets a single model for the specified model type, model ID combination. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602217 = newJObject()
  var body_602218 = newJObject()
  add(query_602217, "nextToken", newJString(nextToken))
  if body != nil:
    body_602218 = body
  add(query_602217, "maxResults", newJString(maxResults))
  result = call_602216.call(nil, query_602217, nil, nil, body_602218)

var getModels* = Call_GetModels_602201(name: "getModels", meth: HttpMethod.HttpPost,
                                    host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetModels",
                                    validator: validate_GetModels_602202,
                                    base: "/", url: url_GetModels_602203,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOutcomes_602219 = ref object of OpenApiRestCall_601389
proc url_GetOutcomes_602221(protocol: Scheme; host: string; base: string;
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

proc validate_GetOutcomes_602220(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602222 = query.getOrDefault("nextToken")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "nextToken", valid_602222
  var valid_602223 = query.getOrDefault("maxResults")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "maxResults", valid_602223
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
  var valid_602224 = header.getOrDefault("X-Amz-Target")
  valid_602224 = validateParameter(valid_602224, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetOutcomes"))
  if valid_602224 != nil:
    section.add "X-Amz-Target", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-Signature")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Signature", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Content-Sha256", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Date")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Date", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Credential")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Credential", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Security-Token")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Security-Token", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Algorithm")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Algorithm", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-SignedHeaders", valid_602231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602233: Call_GetOutcomes_602219; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets one or more outcomes. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 50 and 100. To get the next page results, provide the pagination token from the <code>GetOutcomesResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ## 
  let valid = call_602233.validator(path, query, header, formData, body)
  let scheme = call_602233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602233.url(scheme.get, call_602233.host, call_602233.base,
                         call_602233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602233, url, valid)

proc call*(call_602234: Call_GetOutcomes_602219; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getOutcomes
  ## Gets one or more outcomes. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 50 and 100. To get the next page results, provide the pagination token from the <code>GetOutcomesResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602235 = newJObject()
  var body_602236 = newJObject()
  add(query_602235, "nextToken", newJString(nextToken))
  if body != nil:
    body_602236 = body
  add(query_602235, "maxResults", newJString(maxResults))
  result = call_602234.call(nil, query_602235, nil, nil, body_602236)

var getOutcomes* = Call_GetOutcomes_602219(name: "getOutcomes",
                                        meth: HttpMethod.HttpPost,
                                        host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetOutcomes",
                                        validator: validate_GetOutcomes_602220,
                                        base: "/", url: url_GetOutcomes_602221,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPrediction_602237 = ref object of OpenApiRestCall_601389
proc url_GetPrediction_602239(protocol: Scheme; host: string; base: string;
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

proc validate_GetPrediction_602238(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602240 = header.getOrDefault("X-Amz-Target")
  valid_602240 = validateParameter(valid_602240, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetPrediction"))
  if valid_602240 != nil:
    section.add "X-Amz-Target", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Signature")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Signature", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Content-Sha256", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Date")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Date", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Credential")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Credential", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Security-Token")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Security-Token", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-Algorithm")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Algorithm", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-SignedHeaders", valid_602247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602249: Call_GetPrediction_602237; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Evaluates an event against a detector version. If a version ID is not provided, the detector’s (<code>ACTIVE</code>) version is used. 
  ## 
  let valid = call_602249.validator(path, query, header, formData, body)
  let scheme = call_602249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602249.url(scheme.get, call_602249.host, call_602249.base,
                         call_602249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602249, url, valid)

proc call*(call_602250: Call_GetPrediction_602237; body: JsonNode): Recallable =
  ## getPrediction
  ## Evaluates an event against a detector version. If a version ID is not provided, the detector’s (<code>ACTIVE</code>) version is used. 
  ##   body: JObject (required)
  var body_602251 = newJObject()
  if body != nil:
    body_602251 = body
  result = call_602250.call(nil, nil, nil, nil, body_602251)

var getPrediction* = Call_GetPrediction_602237(name: "getPrediction",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetPrediction",
    validator: validate_GetPrediction_602238, base: "/", url: url_GetPrediction_602239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRules_602252 = ref object of OpenApiRestCall_601389
proc url_GetRules_602254(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRules_602253(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602255 = query.getOrDefault("nextToken")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "nextToken", valid_602255
  var valid_602256 = query.getOrDefault("maxResults")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "maxResults", valid_602256
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
  var valid_602257 = header.getOrDefault("X-Amz-Target")
  valid_602257 = validateParameter(valid_602257, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetRules"))
  if valid_602257 != nil:
    section.add "X-Amz-Target", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Signature")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Signature", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Content-Sha256", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Date")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Date", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-Credential")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-Credential", valid_602261
  var valid_602262 = header.getOrDefault("X-Amz-Security-Token")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "X-Amz-Security-Token", valid_602262
  var valid_602263 = header.getOrDefault("X-Amz-Algorithm")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-Algorithm", valid_602263
  var valid_602264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602264 = validateParameter(valid_602264, JString, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "X-Amz-SignedHeaders", valid_602264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602266: Call_GetRules_602252; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all rules available for the specified detector.
  ## 
  let valid = call_602266.validator(path, query, header, formData, body)
  let scheme = call_602266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602266.url(scheme.get, call_602266.host, call_602266.base,
                         call_602266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602266, url, valid)

proc call*(call_602267: Call_GetRules_602252; body: JsonNode; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getRules
  ## Gets all rules available for the specified detector.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602268 = newJObject()
  var body_602269 = newJObject()
  add(query_602268, "nextToken", newJString(nextToken))
  if body != nil:
    body_602269 = body
  add(query_602268, "maxResults", newJString(maxResults))
  result = call_602267.call(nil, query_602268, nil, nil, body_602269)

var getRules* = Call_GetRules_602252(name: "getRules", meth: HttpMethod.HttpPost,
                                  host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetRules",
                                  validator: validate_GetRules_602253, base: "/",
                                  url: url_GetRules_602254,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVariables_602270 = ref object of OpenApiRestCall_601389
proc url_GetVariables_602272(protocol: Scheme; host: string; base: string;
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

proc validate_GetVariables_602271(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602273 = query.getOrDefault("nextToken")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "nextToken", valid_602273
  var valid_602274 = query.getOrDefault("maxResults")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "maxResults", valid_602274
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
  var valid_602275 = header.getOrDefault("X-Amz-Target")
  valid_602275 = validateParameter(valid_602275, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetVariables"))
  if valid_602275 != nil:
    section.add "X-Amz-Target", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-Signature")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Signature", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-Content-Sha256", valid_602277
  var valid_602278 = header.getOrDefault("X-Amz-Date")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-Date", valid_602278
  var valid_602279 = header.getOrDefault("X-Amz-Credential")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-Credential", valid_602279
  var valid_602280 = header.getOrDefault("X-Amz-Security-Token")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Security-Token", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-Algorithm")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-Algorithm", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-SignedHeaders", valid_602282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602284: Call_GetVariables_602270; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all of the variables or the specific variable. This is a paginated API. Providing null <code>maxSizePerPage</code> results in retrieving maximum of 100 records per page. If you provide <code>maxSizePerPage</code> the value must be between 50 and 100. To get the next page result, a provide a pagination token from <code>GetVariablesResult</code> as part of your request. Null pagination token fetches the records from the beginning. 
  ## 
  let valid = call_602284.validator(path, query, header, formData, body)
  let scheme = call_602284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602284.url(scheme.get, call_602284.host, call_602284.base,
                         call_602284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602284, url, valid)

proc call*(call_602285: Call_GetVariables_602270; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getVariables
  ## Gets all of the variables or the specific variable. This is a paginated API. Providing null <code>maxSizePerPage</code> results in retrieving maximum of 100 records per page. If you provide <code>maxSizePerPage</code> the value must be between 50 and 100. To get the next page result, a provide a pagination token from <code>GetVariablesResult</code> as part of your request. Null pagination token fetches the records from the beginning. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602286 = newJObject()
  var body_602287 = newJObject()
  add(query_602286, "nextToken", newJString(nextToken))
  if body != nil:
    body_602287 = body
  add(query_602286, "maxResults", newJString(maxResults))
  result = call_602285.call(nil, query_602286, nil, nil, body_602287)

var getVariables* = Call_GetVariables_602270(name: "getVariables",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetVariables",
    validator: validate_GetVariables_602271, base: "/", url: url_GetVariables_602272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDetector_602288 = ref object of OpenApiRestCall_601389
proc url_PutDetector_602290(protocol: Scheme; host: string; base: string;
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

proc validate_PutDetector_602289(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602291 = header.getOrDefault("X-Amz-Target")
  valid_602291 = validateParameter(valid_602291, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.PutDetector"))
  if valid_602291 != nil:
    section.add "X-Amz-Target", valid_602291
  var valid_602292 = header.getOrDefault("X-Amz-Signature")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "X-Amz-Signature", valid_602292
  var valid_602293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602293 = validateParameter(valid_602293, JString, required = false,
                                 default = nil)
  if valid_602293 != nil:
    section.add "X-Amz-Content-Sha256", valid_602293
  var valid_602294 = header.getOrDefault("X-Amz-Date")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "X-Amz-Date", valid_602294
  var valid_602295 = header.getOrDefault("X-Amz-Credential")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "X-Amz-Credential", valid_602295
  var valid_602296 = header.getOrDefault("X-Amz-Security-Token")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-Security-Token", valid_602296
  var valid_602297 = header.getOrDefault("X-Amz-Algorithm")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-Algorithm", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-SignedHeaders", valid_602298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602300: Call_PutDetector_602288; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a detector. 
  ## 
  let valid = call_602300.validator(path, query, header, formData, body)
  let scheme = call_602300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602300.url(scheme.get, call_602300.host, call_602300.base,
                         call_602300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602300, url, valid)

proc call*(call_602301: Call_PutDetector_602288; body: JsonNode): Recallable =
  ## putDetector
  ## Creates or updates a detector. 
  ##   body: JObject (required)
  var body_602302 = newJObject()
  if body != nil:
    body_602302 = body
  result = call_602301.call(nil, nil, nil, nil, body_602302)

var putDetector* = Call_PutDetector_602288(name: "putDetector",
                                        meth: HttpMethod.HttpPost,
                                        host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.PutDetector",
                                        validator: validate_PutDetector_602289,
                                        base: "/", url: url_PutDetector_602290,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutExternalModel_602303 = ref object of OpenApiRestCall_601389
proc url_PutExternalModel_602305(protocol: Scheme; host: string; base: string;
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

proc validate_PutExternalModel_602304(path: JsonNode; query: JsonNode;
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
  var valid_602306 = header.getOrDefault("X-Amz-Target")
  valid_602306 = validateParameter(valid_602306, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.PutExternalModel"))
  if valid_602306 != nil:
    section.add "X-Amz-Target", valid_602306
  var valid_602307 = header.getOrDefault("X-Amz-Signature")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "X-Amz-Signature", valid_602307
  var valid_602308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "X-Amz-Content-Sha256", valid_602308
  var valid_602309 = header.getOrDefault("X-Amz-Date")
  valid_602309 = validateParameter(valid_602309, JString, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "X-Amz-Date", valid_602309
  var valid_602310 = header.getOrDefault("X-Amz-Credential")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-Credential", valid_602310
  var valid_602311 = header.getOrDefault("X-Amz-Security-Token")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-Security-Token", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-Algorithm")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Algorithm", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-SignedHeaders", valid_602313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602315: Call_PutExternalModel_602303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates an Amazon SageMaker model endpoint. You can also use this action to update the configuration of the model endpoint, including the IAM role and/or the mapped variables. 
  ## 
  let valid = call_602315.validator(path, query, header, formData, body)
  let scheme = call_602315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602315.url(scheme.get, call_602315.host, call_602315.base,
                         call_602315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602315, url, valid)

proc call*(call_602316: Call_PutExternalModel_602303; body: JsonNode): Recallable =
  ## putExternalModel
  ## Creates or updates an Amazon SageMaker model endpoint. You can also use this action to update the configuration of the model endpoint, including the IAM role and/or the mapped variables. 
  ##   body: JObject (required)
  var body_602317 = newJObject()
  if body != nil:
    body_602317 = body
  result = call_602316.call(nil, nil, nil, nil, body_602317)

var putExternalModel* = Call_PutExternalModel_602303(name: "putExternalModel",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.PutExternalModel",
    validator: validate_PutExternalModel_602304, base: "/",
    url: url_PutExternalModel_602305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutModel_602318 = ref object of OpenApiRestCall_601389
proc url_PutModel_602320(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutModel_602319(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602321 = header.getOrDefault("X-Amz-Target")
  valid_602321 = validateParameter(valid_602321, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.PutModel"))
  if valid_602321 != nil:
    section.add "X-Amz-Target", valid_602321
  var valid_602322 = header.getOrDefault("X-Amz-Signature")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-Signature", valid_602322
  var valid_602323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-Content-Sha256", valid_602323
  var valid_602324 = header.getOrDefault("X-Amz-Date")
  valid_602324 = validateParameter(valid_602324, JString, required = false,
                                 default = nil)
  if valid_602324 != nil:
    section.add "X-Amz-Date", valid_602324
  var valid_602325 = header.getOrDefault("X-Amz-Credential")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "X-Amz-Credential", valid_602325
  var valid_602326 = header.getOrDefault("X-Amz-Security-Token")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "X-Amz-Security-Token", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-Algorithm")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-Algorithm", valid_602327
  var valid_602328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-SignedHeaders", valid_602328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602330: Call_PutModel_602318; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a model. 
  ## 
  let valid = call_602330.validator(path, query, header, formData, body)
  let scheme = call_602330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602330.url(scheme.get, call_602330.host, call_602330.base,
                         call_602330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602330, url, valid)

proc call*(call_602331: Call_PutModel_602318; body: JsonNode): Recallable =
  ## putModel
  ## Creates or updates a model. 
  ##   body: JObject (required)
  var body_602332 = newJObject()
  if body != nil:
    body_602332 = body
  result = call_602331.call(nil, nil, nil, nil, body_602332)

var putModel* = Call_PutModel_602318(name: "putModel", meth: HttpMethod.HttpPost,
                                  host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.PutModel",
                                  validator: validate_PutModel_602319, base: "/",
                                  url: url_PutModel_602320,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutOutcome_602333 = ref object of OpenApiRestCall_601389
proc url_PutOutcome_602335(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutOutcome_602334(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602336 = header.getOrDefault("X-Amz-Target")
  valid_602336 = validateParameter(valid_602336, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.PutOutcome"))
  if valid_602336 != nil:
    section.add "X-Amz-Target", valid_602336
  var valid_602337 = header.getOrDefault("X-Amz-Signature")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-Signature", valid_602337
  var valid_602338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "X-Amz-Content-Sha256", valid_602338
  var valid_602339 = header.getOrDefault("X-Amz-Date")
  valid_602339 = validateParameter(valid_602339, JString, required = false,
                                 default = nil)
  if valid_602339 != nil:
    section.add "X-Amz-Date", valid_602339
  var valid_602340 = header.getOrDefault("X-Amz-Credential")
  valid_602340 = validateParameter(valid_602340, JString, required = false,
                                 default = nil)
  if valid_602340 != nil:
    section.add "X-Amz-Credential", valid_602340
  var valid_602341 = header.getOrDefault("X-Amz-Security-Token")
  valid_602341 = validateParameter(valid_602341, JString, required = false,
                                 default = nil)
  if valid_602341 != nil:
    section.add "X-Amz-Security-Token", valid_602341
  var valid_602342 = header.getOrDefault("X-Amz-Algorithm")
  valid_602342 = validateParameter(valid_602342, JString, required = false,
                                 default = nil)
  if valid_602342 != nil:
    section.add "X-Amz-Algorithm", valid_602342
  var valid_602343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602343 = validateParameter(valid_602343, JString, required = false,
                                 default = nil)
  if valid_602343 != nil:
    section.add "X-Amz-SignedHeaders", valid_602343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602345: Call_PutOutcome_602333; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates an outcome. 
  ## 
  let valid = call_602345.validator(path, query, header, formData, body)
  let scheme = call_602345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602345.url(scheme.get, call_602345.host, call_602345.base,
                         call_602345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602345, url, valid)

proc call*(call_602346: Call_PutOutcome_602333; body: JsonNode): Recallable =
  ## putOutcome
  ## Creates or updates an outcome. 
  ##   body: JObject (required)
  var body_602347 = newJObject()
  if body != nil:
    body_602347 = body
  result = call_602346.call(nil, nil, nil, nil, body_602347)

var putOutcome* = Call_PutOutcome_602333(name: "putOutcome",
                                      meth: HttpMethod.HttpPost,
                                      host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.PutOutcome",
                                      validator: validate_PutOutcome_602334,
                                      base: "/", url: url_PutOutcome_602335,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorVersion_602348 = ref object of OpenApiRestCall_601389
proc url_UpdateDetectorVersion_602350(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDetectorVersion_602349(path: JsonNode; query: JsonNode;
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
  var valid_602351 = header.getOrDefault("X-Amz-Target")
  valid_602351 = validateParameter(valid_602351, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateDetectorVersion"))
  if valid_602351 != nil:
    section.add "X-Amz-Target", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-Signature")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Signature", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-Content-Sha256", valid_602353
  var valid_602354 = header.getOrDefault("X-Amz-Date")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "X-Amz-Date", valid_602354
  var valid_602355 = header.getOrDefault("X-Amz-Credential")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "X-Amz-Credential", valid_602355
  var valid_602356 = header.getOrDefault("X-Amz-Security-Token")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-Security-Token", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-Algorithm")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Algorithm", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-SignedHeaders", valid_602358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602360: Call_UpdateDetectorVersion_602348; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates a detector version. The detector version attributes that you can update include models, external model endpoints, rules, and description. You can only update a <code>DRAFT</code> detector version.
  ## 
  let valid = call_602360.validator(path, query, header, formData, body)
  let scheme = call_602360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602360.url(scheme.get, call_602360.host, call_602360.base,
                         call_602360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602360, url, valid)

proc call*(call_602361: Call_UpdateDetectorVersion_602348; body: JsonNode): Recallable =
  ## updateDetectorVersion
  ##  Updates a detector version. The detector version attributes that you can update include models, external model endpoints, rules, and description. You can only update a <code>DRAFT</code> detector version.
  ##   body: JObject (required)
  var body_602362 = newJObject()
  if body != nil:
    body_602362 = body
  result = call_602361.call(nil, nil, nil, nil, body_602362)

var updateDetectorVersion* = Call_UpdateDetectorVersion_602348(
    name: "updateDetectorVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateDetectorVersion",
    validator: validate_UpdateDetectorVersion_602349, base: "/",
    url: url_UpdateDetectorVersion_602350, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorVersionMetadata_602363 = ref object of OpenApiRestCall_601389
proc url_UpdateDetectorVersionMetadata_602365(protocol: Scheme; host: string;
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

proc validate_UpdateDetectorVersionMetadata_602364(path: JsonNode; query: JsonNode;
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
  var valid_602366 = header.getOrDefault("X-Amz-Target")
  valid_602366 = validateParameter(valid_602366, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateDetectorVersionMetadata"))
  if valid_602366 != nil:
    section.add "X-Amz-Target", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Signature")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Signature", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Content-Sha256", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-Date")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Date", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-Credential")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-Credential", valid_602370
  var valid_602371 = header.getOrDefault("X-Amz-Security-Token")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-Security-Token", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-Algorithm")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-Algorithm", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-SignedHeaders", valid_602373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602375: Call_UpdateDetectorVersionMetadata_602363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the detector version's description. You can update the metadata for any detector version (<code>DRAFT, ACTIVE,</code> or <code>INACTIVE</code>). 
  ## 
  let valid = call_602375.validator(path, query, header, formData, body)
  let scheme = call_602375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602375.url(scheme.get, call_602375.host, call_602375.base,
                         call_602375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602375, url, valid)

proc call*(call_602376: Call_UpdateDetectorVersionMetadata_602363; body: JsonNode): Recallable =
  ## updateDetectorVersionMetadata
  ## Updates the detector version's description. You can update the metadata for any detector version (<code>DRAFT, ACTIVE,</code> or <code>INACTIVE</code>). 
  ##   body: JObject (required)
  var body_602377 = newJObject()
  if body != nil:
    body_602377 = body
  result = call_602376.call(nil, nil, nil, nil, body_602377)

var updateDetectorVersionMetadata* = Call_UpdateDetectorVersionMetadata_602363(
    name: "updateDetectorVersionMetadata", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateDetectorVersionMetadata",
    validator: validate_UpdateDetectorVersionMetadata_602364, base: "/",
    url: url_UpdateDetectorVersionMetadata_602365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorVersionStatus_602378 = ref object of OpenApiRestCall_601389
proc url_UpdateDetectorVersionStatus_602380(protocol: Scheme; host: string;
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

proc validate_UpdateDetectorVersionStatus_602379(path: JsonNode; query: JsonNode;
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
  var valid_602381 = header.getOrDefault("X-Amz-Target")
  valid_602381 = validateParameter(valid_602381, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateDetectorVersionStatus"))
  if valid_602381 != nil:
    section.add "X-Amz-Target", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-Signature")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Signature", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Content-Sha256", valid_602383
  var valid_602384 = header.getOrDefault("X-Amz-Date")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-Date", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-Credential")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-Credential", valid_602385
  var valid_602386 = header.getOrDefault("X-Amz-Security-Token")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "X-Amz-Security-Token", valid_602386
  var valid_602387 = header.getOrDefault("X-Amz-Algorithm")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-Algorithm", valid_602387
  var valid_602388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602388 = validateParameter(valid_602388, JString, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "X-Amz-SignedHeaders", valid_602388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602390: Call_UpdateDetectorVersionStatus_602378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the detector version’s status. You can perform the following promotions or demotions using <code>UpdateDetectorVersionStatus</code>: <code>DRAFT</code> to <code>ACTIVE</code>, <code>ACTIVE</code> to <code>INACTIVE</code>, and <code>INACTIVE</code> to <code>ACTIVE</code>.
  ## 
  let valid = call_602390.validator(path, query, header, formData, body)
  let scheme = call_602390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602390.url(scheme.get, call_602390.host, call_602390.base,
                         call_602390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602390, url, valid)

proc call*(call_602391: Call_UpdateDetectorVersionStatus_602378; body: JsonNode): Recallable =
  ## updateDetectorVersionStatus
  ## Updates the detector version’s status. You can perform the following promotions or demotions using <code>UpdateDetectorVersionStatus</code>: <code>DRAFT</code> to <code>ACTIVE</code>, <code>ACTIVE</code> to <code>INACTIVE</code>, and <code>INACTIVE</code> to <code>ACTIVE</code>.
  ##   body: JObject (required)
  var body_602392 = newJObject()
  if body != nil:
    body_602392 = body
  result = call_602391.call(nil, nil, nil, nil, body_602392)

var updateDetectorVersionStatus* = Call_UpdateDetectorVersionStatus_602378(
    name: "updateDetectorVersionStatus", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateDetectorVersionStatus",
    validator: validate_UpdateDetectorVersionStatus_602379, base: "/",
    url: url_UpdateDetectorVersionStatus_602380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModelVersion_602393 = ref object of OpenApiRestCall_601389
proc url_UpdateModelVersion_602395(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateModelVersion_602394(path: JsonNode; query: JsonNode;
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
  var valid_602396 = header.getOrDefault("X-Amz-Target")
  valid_602396 = validateParameter(valid_602396, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateModelVersion"))
  if valid_602396 != nil:
    section.add "X-Amz-Target", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-Signature")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-Signature", valid_602397
  var valid_602398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Content-Sha256", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Date")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Date", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-Credential")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-Credential", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-Security-Token")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Security-Token", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-Algorithm")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Algorithm", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-SignedHeaders", valid_602403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602405: Call_UpdateModelVersion_602393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a model version. You can update the description and status attributes using this action. You can perform the following status updates: </p> <ol> <li> <p>Change the <code>TRAINING_COMPLETE</code> status to <code>ACTIVE</code> </p> </li> <li> <p>Change <code>ACTIVE</code> back to <code>TRAINING_COMPLETE</code> </p> </li> </ol>
  ## 
  let valid = call_602405.validator(path, query, header, formData, body)
  let scheme = call_602405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602405.url(scheme.get, call_602405.host, call_602405.base,
                         call_602405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602405, url, valid)

proc call*(call_602406: Call_UpdateModelVersion_602393; body: JsonNode): Recallable =
  ## updateModelVersion
  ## <p>Updates a model version. You can update the description and status attributes using this action. You can perform the following status updates: </p> <ol> <li> <p>Change the <code>TRAINING_COMPLETE</code> status to <code>ACTIVE</code> </p> </li> <li> <p>Change <code>ACTIVE</code> back to <code>TRAINING_COMPLETE</code> </p> </li> </ol>
  ##   body: JObject (required)
  var body_602407 = newJObject()
  if body != nil:
    body_602407 = body
  result = call_602406.call(nil, nil, nil, nil, body_602407)

var updateModelVersion* = Call_UpdateModelVersion_602393(
    name: "updateModelVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateModelVersion",
    validator: validate_UpdateModelVersion_602394, base: "/",
    url: url_UpdateModelVersion_602395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRuleMetadata_602408 = ref object of OpenApiRestCall_601389
proc url_UpdateRuleMetadata_602410(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRuleMetadata_602409(path: JsonNode; query: JsonNode;
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
  var valid_602411 = header.getOrDefault("X-Amz-Target")
  valid_602411 = validateParameter(valid_602411, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateRuleMetadata"))
  if valid_602411 != nil:
    section.add "X-Amz-Target", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-Signature")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-Signature", valid_602412
  var valid_602413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Content-Sha256", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-Date")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Date", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-Credential")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Credential", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-Security-Token")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Security-Token", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-Algorithm")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Algorithm", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-SignedHeaders", valid_602418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602420: Call_UpdateRuleMetadata_602408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a rule's metadata. 
  ## 
  let valid = call_602420.validator(path, query, header, formData, body)
  let scheme = call_602420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602420.url(scheme.get, call_602420.host, call_602420.base,
                         call_602420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602420, url, valid)

proc call*(call_602421: Call_UpdateRuleMetadata_602408; body: JsonNode): Recallable =
  ## updateRuleMetadata
  ## Updates a rule's metadata. 
  ##   body: JObject (required)
  var body_602422 = newJObject()
  if body != nil:
    body_602422 = body
  result = call_602421.call(nil, nil, nil, nil, body_602422)

var updateRuleMetadata* = Call_UpdateRuleMetadata_602408(
    name: "updateRuleMetadata", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateRuleMetadata",
    validator: validate_UpdateRuleMetadata_602409, base: "/",
    url: url_UpdateRuleMetadata_602410, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRuleVersion_602423 = ref object of OpenApiRestCall_601389
proc url_UpdateRuleVersion_602425(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRuleVersion_602424(path: JsonNode; query: JsonNode;
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
  var valid_602426 = header.getOrDefault("X-Amz-Target")
  valid_602426 = validateParameter(valid_602426, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateRuleVersion"))
  if valid_602426 != nil:
    section.add "X-Amz-Target", valid_602426
  var valid_602427 = header.getOrDefault("X-Amz-Signature")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "X-Amz-Signature", valid_602427
  var valid_602428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-Content-Sha256", valid_602428
  var valid_602429 = header.getOrDefault("X-Amz-Date")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "X-Amz-Date", valid_602429
  var valid_602430 = header.getOrDefault("X-Amz-Credential")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "X-Amz-Credential", valid_602430
  var valid_602431 = header.getOrDefault("X-Amz-Security-Token")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "X-Amz-Security-Token", valid_602431
  var valid_602432 = header.getOrDefault("X-Amz-Algorithm")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "X-Amz-Algorithm", valid_602432
  var valid_602433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-SignedHeaders", valid_602433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602435: Call_UpdateRuleVersion_602423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a rule version resulting in a new rule version. 
  ## 
  let valid = call_602435.validator(path, query, header, formData, body)
  let scheme = call_602435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602435.url(scheme.get, call_602435.host, call_602435.base,
                         call_602435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602435, url, valid)

proc call*(call_602436: Call_UpdateRuleVersion_602423; body: JsonNode): Recallable =
  ## updateRuleVersion
  ## Updates a rule version resulting in a new rule version. 
  ##   body: JObject (required)
  var body_602437 = newJObject()
  if body != nil:
    body_602437 = body
  result = call_602436.call(nil, nil, nil, nil, body_602437)

var updateRuleVersion* = Call_UpdateRuleVersion_602423(name: "updateRuleVersion",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateRuleVersion",
    validator: validate_UpdateRuleVersion_602424, base: "/",
    url: url_UpdateRuleVersion_602425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVariable_602438 = ref object of OpenApiRestCall_601389
proc url_UpdateVariable_602440(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVariable_602439(path: JsonNode; query: JsonNode;
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
  var valid_602441 = header.getOrDefault("X-Amz-Target")
  valid_602441 = validateParameter(valid_602441, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateVariable"))
  if valid_602441 != nil:
    section.add "X-Amz-Target", valid_602441
  var valid_602442 = header.getOrDefault("X-Amz-Signature")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-Signature", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-Content-Sha256", valid_602443
  var valid_602444 = header.getOrDefault("X-Amz-Date")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-Date", valid_602444
  var valid_602445 = header.getOrDefault("X-Amz-Credential")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-Credential", valid_602445
  var valid_602446 = header.getOrDefault("X-Amz-Security-Token")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "X-Amz-Security-Token", valid_602446
  var valid_602447 = header.getOrDefault("X-Amz-Algorithm")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-Algorithm", valid_602447
  var valid_602448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-SignedHeaders", valid_602448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602450: Call_UpdateVariable_602438; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a variable.
  ## 
  let valid = call_602450.validator(path, query, header, formData, body)
  let scheme = call_602450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602450.url(scheme.get, call_602450.host, call_602450.base,
                         call_602450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602450, url, valid)

proc call*(call_602451: Call_UpdateVariable_602438; body: JsonNode): Recallable =
  ## updateVariable
  ## Updates a variable.
  ##   body: JObject (required)
  var body_602452 = newJObject()
  if body != nil:
    body_602452 = body
  result = call_602451.call(nil, nil, nil, nil, body_602452)

var updateVariable* = Call_UpdateVariable_602438(name: "updateVariable",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateVariable",
    validator: validate_UpdateVariable_602439, base: "/", url: url_UpdateVariable_602440,
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
