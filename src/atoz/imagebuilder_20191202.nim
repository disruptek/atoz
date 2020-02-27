
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, httpcore,
  sigv4

## auto-generated via openapi macro
## title: EC2 Image Builder
## version: 2019-12-02
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## EC2 Image Builder is a fully managed AWS service that makes it easier to automate the creation, management, and deployment of customized, secure, and up-to-date “golden” server images that are pre-installed and pre-configured with software and settings to meet specific IT standards.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/imagebuilder/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_616866 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_616866](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_616866): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "imagebuilder.ap-northeast-1.amazonaws.com", "ap-southeast-1": "imagebuilder.ap-southeast-1.amazonaws.com",
                           "us-west-2": "imagebuilder.us-west-2.amazonaws.com",
                           "eu-west-2": "imagebuilder.eu-west-2.amazonaws.com", "ap-northeast-3": "imagebuilder.ap-northeast-3.amazonaws.com", "eu-central-1": "imagebuilder.eu-central-1.amazonaws.com",
                           "us-east-2": "imagebuilder.us-east-2.amazonaws.com",
                           "us-east-1": "imagebuilder.us-east-1.amazonaws.com", "cn-northwest-1": "imagebuilder.cn-northwest-1.amazonaws.com.cn", "ap-northeast-2": "imagebuilder.ap-northeast-2.amazonaws.com", "ap-south-1": "imagebuilder.ap-south-1.amazonaws.com", "eu-north-1": "imagebuilder.eu-north-1.amazonaws.com",
                           "us-west-1": "imagebuilder.us-west-1.amazonaws.com", "us-gov-east-1": "imagebuilder.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "imagebuilder.eu-west-3.amazonaws.com", "cn-north-1": "imagebuilder.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "imagebuilder.sa-east-1.amazonaws.com",
                           "eu-west-1": "imagebuilder.eu-west-1.amazonaws.com", "us-gov-west-1": "imagebuilder.us-gov-west-1.amazonaws.com", "ap-southeast-2": "imagebuilder.ap-southeast-2.amazonaws.com", "ca-central-1": "imagebuilder.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "imagebuilder.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "imagebuilder.ap-southeast-1.amazonaws.com",
      "us-west-2": "imagebuilder.us-west-2.amazonaws.com",
      "eu-west-2": "imagebuilder.eu-west-2.amazonaws.com",
      "ap-northeast-3": "imagebuilder.ap-northeast-3.amazonaws.com",
      "eu-central-1": "imagebuilder.eu-central-1.amazonaws.com",
      "us-east-2": "imagebuilder.us-east-2.amazonaws.com",
      "us-east-1": "imagebuilder.us-east-1.amazonaws.com",
      "cn-northwest-1": "imagebuilder.cn-northwest-1.amazonaws.com.cn",
      "ap-northeast-2": "imagebuilder.ap-northeast-2.amazonaws.com",
      "ap-south-1": "imagebuilder.ap-south-1.amazonaws.com",
      "eu-north-1": "imagebuilder.eu-north-1.amazonaws.com",
      "us-west-1": "imagebuilder.us-west-1.amazonaws.com",
      "us-gov-east-1": "imagebuilder.us-gov-east-1.amazonaws.com",
      "eu-west-3": "imagebuilder.eu-west-3.amazonaws.com",
      "cn-north-1": "imagebuilder.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "imagebuilder.sa-east-1.amazonaws.com",
      "eu-west-1": "imagebuilder.eu-west-1.amazonaws.com",
      "us-gov-west-1": "imagebuilder.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "imagebuilder.ap-southeast-2.amazonaws.com",
      "ca-central-1": "imagebuilder.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "imagebuilder"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CancelImageCreation_617205 = ref object of OpenApiRestCall_616866
proc url_CancelImageCreation_617207(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelImageCreation_617206(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
  ## CancelImageCreation cancels the creation of Image. This operation can only be used on images in a non-terminal state.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617319 = header.getOrDefault("X-Amz-Date")
  valid_617319 = validateParameter(valid_617319, JString, required = false,
                                 default = nil)
  if valid_617319 != nil:
    section.add "X-Amz-Date", valid_617319
  var valid_617320 = header.getOrDefault("X-Amz-Security-Token")
  valid_617320 = validateParameter(valid_617320, JString, required = false,
                                 default = nil)
  if valid_617320 != nil:
    section.add "X-Amz-Security-Token", valid_617320
  var valid_617321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617321 = validateParameter(valid_617321, JString, required = false,
                                 default = nil)
  if valid_617321 != nil:
    section.add "X-Amz-Content-Sha256", valid_617321
  var valid_617322 = header.getOrDefault("X-Amz-Algorithm")
  valid_617322 = validateParameter(valid_617322, JString, required = false,
                                 default = nil)
  if valid_617322 != nil:
    section.add "X-Amz-Algorithm", valid_617322
  var valid_617323 = header.getOrDefault("X-Amz-Signature")
  valid_617323 = validateParameter(valid_617323, JString, required = false,
                                 default = nil)
  if valid_617323 != nil:
    section.add "X-Amz-Signature", valid_617323
  var valid_617324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617324 = validateParameter(valid_617324, JString, required = false,
                                 default = nil)
  if valid_617324 != nil:
    section.add "X-Amz-SignedHeaders", valid_617324
  var valid_617325 = header.getOrDefault("X-Amz-Credential")
  valid_617325 = validateParameter(valid_617325, JString, required = false,
                                 default = nil)
  if valid_617325 != nil:
    section.add "X-Amz-Credential", valid_617325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617350: Call_CancelImageCreation_617205; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## CancelImageCreation cancels the creation of Image. This operation can only be used on images in a non-terminal state.
  ## 
  let valid = call_617350.validator(path, query, header, formData, body, _)
  let scheme = call_617350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617350.url(scheme.get, call_617350.host, call_617350.base,
                         call_617350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617350, url, valid, _)

proc call*(call_617421: Call_CancelImageCreation_617205; body: JsonNode): Recallable =
  ## cancelImageCreation
  ## CancelImageCreation cancels the creation of Image. This operation can only be used on images in a non-terminal state.
  ##   body: JObject (required)
  var body_617422 = newJObject()
  if body != nil:
    body_617422 = body
  result = call_617421.call(nil, nil, nil, nil, body_617422)

var cancelImageCreation* = Call_CancelImageCreation_617205(
    name: "cancelImageCreation", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/CancelImageCreation",
    validator: validate_CancelImageCreation_617206, base: "/",
    url: url_CancelImageCreation_617207, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComponent_617463 = ref object of OpenApiRestCall_616866
proc url_CreateComponent_617465(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateComponent_617464(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
  ## Creates a new component that can be used to build, validate, test, and assess your image.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617466 = header.getOrDefault("X-Amz-Date")
  valid_617466 = validateParameter(valid_617466, JString, required = false,
                                 default = nil)
  if valid_617466 != nil:
    section.add "X-Amz-Date", valid_617466
  var valid_617467 = header.getOrDefault("X-Amz-Security-Token")
  valid_617467 = validateParameter(valid_617467, JString, required = false,
                                 default = nil)
  if valid_617467 != nil:
    section.add "X-Amz-Security-Token", valid_617467
  var valid_617468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617468 = validateParameter(valid_617468, JString, required = false,
                                 default = nil)
  if valid_617468 != nil:
    section.add "X-Amz-Content-Sha256", valid_617468
  var valid_617469 = header.getOrDefault("X-Amz-Algorithm")
  valid_617469 = validateParameter(valid_617469, JString, required = false,
                                 default = nil)
  if valid_617469 != nil:
    section.add "X-Amz-Algorithm", valid_617469
  var valid_617470 = header.getOrDefault("X-Amz-Signature")
  valid_617470 = validateParameter(valid_617470, JString, required = false,
                                 default = nil)
  if valid_617470 != nil:
    section.add "X-Amz-Signature", valid_617470
  var valid_617471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617471 = validateParameter(valid_617471, JString, required = false,
                                 default = nil)
  if valid_617471 != nil:
    section.add "X-Amz-SignedHeaders", valid_617471
  var valid_617472 = header.getOrDefault("X-Amz-Credential")
  valid_617472 = validateParameter(valid_617472, JString, required = false,
                                 default = nil)
  if valid_617472 != nil:
    section.add "X-Amz-Credential", valid_617472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617474: Call_CreateComponent_617463; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new component that can be used to build, validate, test, and assess your image.
  ## 
  let valid = call_617474.validator(path, query, header, formData, body, _)
  let scheme = call_617474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617474.url(scheme.get, call_617474.host, call_617474.base,
                         call_617474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617474, url, valid, _)

proc call*(call_617475: Call_CreateComponent_617463; body: JsonNode): Recallable =
  ## createComponent
  ## Creates a new component that can be used to build, validate, test, and assess your image.
  ##   body: JObject (required)
  var body_617476 = newJObject()
  if body != nil:
    body_617476 = body
  result = call_617475.call(nil, nil, nil, nil, body_617476)

var createComponent* = Call_CreateComponent_617463(name: "createComponent",
    meth: HttpMethod.HttpPut, host: "imagebuilder.amazonaws.com",
    route: "/CreateComponent", validator: validate_CreateComponent_617464,
    base: "/", url: url_CreateComponent_617465, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistributionConfiguration_617477 = ref object of OpenApiRestCall_616866
proc url_CreateDistributionConfiguration_617479(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDistributionConfiguration_617478(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ## Creates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617480 = header.getOrDefault("X-Amz-Date")
  valid_617480 = validateParameter(valid_617480, JString, required = false,
                                 default = nil)
  if valid_617480 != nil:
    section.add "X-Amz-Date", valid_617480
  var valid_617481 = header.getOrDefault("X-Amz-Security-Token")
  valid_617481 = validateParameter(valid_617481, JString, required = false,
                                 default = nil)
  if valid_617481 != nil:
    section.add "X-Amz-Security-Token", valid_617481
  var valid_617482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617482 = validateParameter(valid_617482, JString, required = false,
                                 default = nil)
  if valid_617482 != nil:
    section.add "X-Amz-Content-Sha256", valid_617482
  var valid_617483 = header.getOrDefault("X-Amz-Algorithm")
  valid_617483 = validateParameter(valid_617483, JString, required = false,
                                 default = nil)
  if valid_617483 != nil:
    section.add "X-Amz-Algorithm", valid_617483
  var valid_617484 = header.getOrDefault("X-Amz-Signature")
  valid_617484 = validateParameter(valid_617484, JString, required = false,
                                 default = nil)
  if valid_617484 != nil:
    section.add "X-Amz-Signature", valid_617484
  var valid_617485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617485 = validateParameter(valid_617485, JString, required = false,
                                 default = nil)
  if valid_617485 != nil:
    section.add "X-Amz-SignedHeaders", valid_617485
  var valid_617486 = header.getOrDefault("X-Amz-Credential")
  valid_617486 = validateParameter(valid_617486, JString, required = false,
                                 default = nil)
  if valid_617486 != nil:
    section.add "X-Amz-Credential", valid_617486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617488: Call_CreateDistributionConfiguration_617477;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ## 
  let valid = call_617488.validator(path, query, header, formData, body, _)
  let scheme = call_617488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617488.url(scheme.get, call_617488.host, call_617488.base,
                         call_617488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617488, url, valid, _)

proc call*(call_617489: Call_CreateDistributionConfiguration_617477; body: JsonNode): Recallable =
  ## createDistributionConfiguration
  ## Creates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ##   body: JObject (required)
  var body_617490 = newJObject()
  if body != nil:
    body_617490 = body
  result = call_617489.call(nil, nil, nil, nil, body_617490)

var createDistributionConfiguration* = Call_CreateDistributionConfiguration_617477(
    name: "createDistributionConfiguration", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/CreateDistributionConfiguration",
    validator: validate_CreateDistributionConfiguration_617478, base: "/",
    url: url_CreateDistributionConfiguration_617479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImage_617491 = ref object of OpenApiRestCall_616866
proc url_CreateImage_617493(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateImage_617492(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ##  Creates a new image. This request will create a new image along with all of the configured output resources defined in the distribution configuration. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617494 = header.getOrDefault("X-Amz-Date")
  valid_617494 = validateParameter(valid_617494, JString, required = false,
                                 default = nil)
  if valid_617494 != nil:
    section.add "X-Amz-Date", valid_617494
  var valid_617495 = header.getOrDefault("X-Amz-Security-Token")
  valid_617495 = validateParameter(valid_617495, JString, required = false,
                                 default = nil)
  if valid_617495 != nil:
    section.add "X-Amz-Security-Token", valid_617495
  var valid_617496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617496 = validateParameter(valid_617496, JString, required = false,
                                 default = nil)
  if valid_617496 != nil:
    section.add "X-Amz-Content-Sha256", valid_617496
  var valid_617497 = header.getOrDefault("X-Amz-Algorithm")
  valid_617497 = validateParameter(valid_617497, JString, required = false,
                                 default = nil)
  if valid_617497 != nil:
    section.add "X-Amz-Algorithm", valid_617497
  var valid_617498 = header.getOrDefault("X-Amz-Signature")
  valid_617498 = validateParameter(valid_617498, JString, required = false,
                                 default = nil)
  if valid_617498 != nil:
    section.add "X-Amz-Signature", valid_617498
  var valid_617499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617499 = validateParameter(valid_617499, JString, required = false,
                                 default = nil)
  if valid_617499 != nil:
    section.add "X-Amz-SignedHeaders", valid_617499
  var valid_617500 = header.getOrDefault("X-Amz-Credential")
  valid_617500 = validateParameter(valid_617500, JString, required = false,
                                 default = nil)
  if valid_617500 != nil:
    section.add "X-Amz-Credential", valid_617500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617502: Call_CreateImage_617491; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Creates a new image. This request will create a new image along with all of the configured output resources defined in the distribution configuration. 
  ## 
  let valid = call_617502.validator(path, query, header, formData, body, _)
  let scheme = call_617502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617502.url(scheme.get, call_617502.host, call_617502.base,
                         call_617502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617502, url, valid, _)

proc call*(call_617503: Call_CreateImage_617491; body: JsonNode): Recallable =
  ## createImage
  ##  Creates a new image. This request will create a new image along with all of the configured output resources defined in the distribution configuration. 
  ##   body: JObject (required)
  var body_617504 = newJObject()
  if body != nil:
    body_617504 = body
  result = call_617503.call(nil, nil, nil, nil, body_617504)

var createImage* = Call_CreateImage_617491(name: "createImage",
                                        meth: HttpMethod.HttpPut,
                                        host: "imagebuilder.amazonaws.com",
                                        route: "/CreateImage",
                                        validator: validate_CreateImage_617492,
                                        base: "/", url: url_CreateImage_617493,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImagePipeline_617505 = ref object of OpenApiRestCall_616866
proc url_CreateImagePipeline_617507(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateImagePipeline_617506(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
  ##  Creates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617508 = header.getOrDefault("X-Amz-Date")
  valid_617508 = validateParameter(valid_617508, JString, required = false,
                                 default = nil)
  if valid_617508 != nil:
    section.add "X-Amz-Date", valid_617508
  var valid_617509 = header.getOrDefault("X-Amz-Security-Token")
  valid_617509 = validateParameter(valid_617509, JString, required = false,
                                 default = nil)
  if valid_617509 != nil:
    section.add "X-Amz-Security-Token", valid_617509
  var valid_617510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617510 = validateParameter(valid_617510, JString, required = false,
                                 default = nil)
  if valid_617510 != nil:
    section.add "X-Amz-Content-Sha256", valid_617510
  var valid_617511 = header.getOrDefault("X-Amz-Algorithm")
  valid_617511 = validateParameter(valid_617511, JString, required = false,
                                 default = nil)
  if valid_617511 != nil:
    section.add "X-Amz-Algorithm", valid_617511
  var valid_617512 = header.getOrDefault("X-Amz-Signature")
  valid_617512 = validateParameter(valid_617512, JString, required = false,
                                 default = nil)
  if valid_617512 != nil:
    section.add "X-Amz-Signature", valid_617512
  var valid_617513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617513 = validateParameter(valid_617513, JString, required = false,
                                 default = nil)
  if valid_617513 != nil:
    section.add "X-Amz-SignedHeaders", valid_617513
  var valid_617514 = header.getOrDefault("X-Amz-Credential")
  valid_617514 = validateParameter(valid_617514, JString, required = false,
                                 default = nil)
  if valid_617514 != nil:
    section.add "X-Amz-Credential", valid_617514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617516: Call_CreateImagePipeline_617505; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Creates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ## 
  let valid = call_617516.validator(path, query, header, formData, body, _)
  let scheme = call_617516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617516.url(scheme.get, call_617516.host, call_617516.base,
                         call_617516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617516, url, valid, _)

proc call*(call_617517: Call_CreateImagePipeline_617505; body: JsonNode): Recallable =
  ## createImagePipeline
  ##  Creates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ##   body: JObject (required)
  var body_617518 = newJObject()
  if body != nil:
    body_617518 = body
  result = call_617517.call(nil, nil, nil, nil, body_617518)

var createImagePipeline* = Call_CreateImagePipeline_617505(
    name: "createImagePipeline", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/CreateImagePipeline",
    validator: validate_CreateImagePipeline_617506, base: "/",
    url: url_CreateImagePipeline_617507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImageRecipe_617519 = ref object of OpenApiRestCall_616866
proc url_CreateImageRecipe_617521(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateImageRecipe_617520(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
  ##  Creates a new image recipe. Image recipes define how images are configured, tested, and assessed. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617522 = header.getOrDefault("X-Amz-Date")
  valid_617522 = validateParameter(valid_617522, JString, required = false,
                                 default = nil)
  if valid_617522 != nil:
    section.add "X-Amz-Date", valid_617522
  var valid_617523 = header.getOrDefault("X-Amz-Security-Token")
  valid_617523 = validateParameter(valid_617523, JString, required = false,
                                 default = nil)
  if valid_617523 != nil:
    section.add "X-Amz-Security-Token", valid_617523
  var valid_617524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617524 = validateParameter(valid_617524, JString, required = false,
                                 default = nil)
  if valid_617524 != nil:
    section.add "X-Amz-Content-Sha256", valid_617524
  var valid_617525 = header.getOrDefault("X-Amz-Algorithm")
  valid_617525 = validateParameter(valid_617525, JString, required = false,
                                 default = nil)
  if valid_617525 != nil:
    section.add "X-Amz-Algorithm", valid_617525
  var valid_617526 = header.getOrDefault("X-Amz-Signature")
  valid_617526 = validateParameter(valid_617526, JString, required = false,
                                 default = nil)
  if valid_617526 != nil:
    section.add "X-Amz-Signature", valid_617526
  var valid_617527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617527 = validateParameter(valid_617527, JString, required = false,
                                 default = nil)
  if valid_617527 != nil:
    section.add "X-Amz-SignedHeaders", valid_617527
  var valid_617528 = header.getOrDefault("X-Amz-Credential")
  valid_617528 = validateParameter(valid_617528, JString, required = false,
                                 default = nil)
  if valid_617528 != nil:
    section.add "X-Amz-Credential", valid_617528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617530: Call_CreateImageRecipe_617519; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Creates a new image recipe. Image recipes define how images are configured, tested, and assessed. 
  ## 
  let valid = call_617530.validator(path, query, header, formData, body, _)
  let scheme = call_617530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617530.url(scheme.get, call_617530.host, call_617530.base,
                         call_617530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617530, url, valid, _)

proc call*(call_617531: Call_CreateImageRecipe_617519; body: JsonNode): Recallable =
  ## createImageRecipe
  ##  Creates a new image recipe. Image recipes define how images are configured, tested, and assessed. 
  ##   body: JObject (required)
  var body_617532 = newJObject()
  if body != nil:
    body_617532 = body
  result = call_617531.call(nil, nil, nil, nil, body_617532)

var createImageRecipe* = Call_CreateImageRecipe_617519(name: "createImageRecipe",
    meth: HttpMethod.HttpPut, host: "imagebuilder.amazonaws.com",
    route: "/CreateImageRecipe", validator: validate_CreateImageRecipe_617520,
    base: "/", url: url_CreateImageRecipe_617521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInfrastructureConfiguration_617533 = ref object of OpenApiRestCall_616866
proc url_CreateInfrastructureConfiguration_617535(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInfrastructureConfiguration_617534(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ##  Creates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617536 = header.getOrDefault("X-Amz-Date")
  valid_617536 = validateParameter(valid_617536, JString, required = false,
                                 default = nil)
  if valid_617536 != nil:
    section.add "X-Amz-Date", valid_617536
  var valid_617537 = header.getOrDefault("X-Amz-Security-Token")
  valid_617537 = validateParameter(valid_617537, JString, required = false,
                                 default = nil)
  if valid_617537 != nil:
    section.add "X-Amz-Security-Token", valid_617537
  var valid_617538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617538 = validateParameter(valid_617538, JString, required = false,
                                 default = nil)
  if valid_617538 != nil:
    section.add "X-Amz-Content-Sha256", valid_617538
  var valid_617539 = header.getOrDefault("X-Amz-Algorithm")
  valid_617539 = validateParameter(valid_617539, JString, required = false,
                                 default = nil)
  if valid_617539 != nil:
    section.add "X-Amz-Algorithm", valid_617539
  var valid_617540 = header.getOrDefault("X-Amz-Signature")
  valid_617540 = validateParameter(valid_617540, JString, required = false,
                                 default = nil)
  if valid_617540 != nil:
    section.add "X-Amz-Signature", valid_617540
  var valid_617541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617541 = validateParameter(valid_617541, JString, required = false,
                                 default = nil)
  if valid_617541 != nil:
    section.add "X-Amz-SignedHeaders", valid_617541
  var valid_617542 = header.getOrDefault("X-Amz-Credential")
  valid_617542 = validateParameter(valid_617542, JString, required = false,
                                 default = nil)
  if valid_617542 != nil:
    section.add "X-Amz-Credential", valid_617542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617544: Call_CreateInfrastructureConfiguration_617533;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Creates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ## 
  let valid = call_617544.validator(path, query, header, formData, body, _)
  let scheme = call_617544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617544.url(scheme.get, call_617544.host, call_617544.base,
                         call_617544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617544, url, valid, _)

proc call*(call_617545: Call_CreateInfrastructureConfiguration_617533;
          body: JsonNode): Recallable =
  ## createInfrastructureConfiguration
  ##  Creates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ##   body: JObject (required)
  var body_617546 = newJObject()
  if body != nil:
    body_617546 = body
  result = call_617545.call(nil, nil, nil, nil, body_617546)

var createInfrastructureConfiguration* = Call_CreateInfrastructureConfiguration_617533(
    name: "createInfrastructureConfiguration", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com",
    route: "/CreateInfrastructureConfiguration",
    validator: validate_CreateInfrastructureConfiguration_617534, base: "/",
    url: url_CreateInfrastructureConfiguration_617535,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComponent_617547 = ref object of OpenApiRestCall_616866
proc url_DeleteComponent_617549(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteComponent_617548(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
  ##  Deletes a component build version. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   componentBuildVersionArn: JString (required)
  ##                           :  The Amazon Resource Name (ARN) of the component build version to delete. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `componentBuildVersionArn` field"
  var valid_617550 = query.getOrDefault("componentBuildVersionArn")
  valid_617550 = validateParameter(valid_617550, JString, required = true,
                                 default = nil)
  if valid_617550 != nil:
    section.add "componentBuildVersionArn", valid_617550
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617551 = header.getOrDefault("X-Amz-Date")
  valid_617551 = validateParameter(valid_617551, JString, required = false,
                                 default = nil)
  if valid_617551 != nil:
    section.add "X-Amz-Date", valid_617551
  var valid_617552 = header.getOrDefault("X-Amz-Security-Token")
  valid_617552 = validateParameter(valid_617552, JString, required = false,
                                 default = nil)
  if valid_617552 != nil:
    section.add "X-Amz-Security-Token", valid_617552
  var valid_617553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617553 = validateParameter(valid_617553, JString, required = false,
                                 default = nil)
  if valid_617553 != nil:
    section.add "X-Amz-Content-Sha256", valid_617553
  var valid_617554 = header.getOrDefault("X-Amz-Algorithm")
  valid_617554 = validateParameter(valid_617554, JString, required = false,
                                 default = nil)
  if valid_617554 != nil:
    section.add "X-Amz-Algorithm", valid_617554
  var valid_617555 = header.getOrDefault("X-Amz-Signature")
  valid_617555 = validateParameter(valid_617555, JString, required = false,
                                 default = nil)
  if valid_617555 != nil:
    section.add "X-Amz-Signature", valid_617555
  var valid_617556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617556 = validateParameter(valid_617556, JString, required = false,
                                 default = nil)
  if valid_617556 != nil:
    section.add "X-Amz-SignedHeaders", valid_617556
  var valid_617557 = header.getOrDefault("X-Amz-Credential")
  valid_617557 = validateParameter(valid_617557, JString, required = false,
                                 default = nil)
  if valid_617557 != nil:
    section.add "X-Amz-Credential", valid_617557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617558: Call_DeleteComponent_617547; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Deletes a component build version. 
  ## 
  let valid = call_617558.validator(path, query, header, formData, body, _)
  let scheme = call_617558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617558.url(scheme.get, call_617558.host, call_617558.base,
                         call_617558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617558, url, valid, _)

proc call*(call_617559: Call_DeleteComponent_617547;
          componentBuildVersionArn: string): Recallable =
  ## deleteComponent
  ##  Deletes a component build version. 
  ##   componentBuildVersionArn: string (required)
  ##                           :  The Amazon Resource Name (ARN) of the component build version to delete. 
  var query_617560 = newJObject()
  add(query_617560, "componentBuildVersionArn",
      newJString(componentBuildVersionArn))
  result = call_617559.call(nil, query_617560, nil, nil, nil)

var deleteComponent* = Call_DeleteComponent_617547(name: "deleteComponent",
    meth: HttpMethod.HttpDelete, host: "imagebuilder.amazonaws.com",
    route: "/DeleteComponent#componentBuildVersionArn",
    validator: validate_DeleteComponent_617548, base: "/", url: url_DeleteComponent_617549,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDistributionConfiguration_617562 = ref object of OpenApiRestCall_616866
proc url_DeleteDistributionConfiguration_617564(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDistributionConfiguration_617563(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ##  Deletes a distribution configuration. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   distributionConfigurationArn: JString (required)
  ##                               :  The Amazon Resource Name (ARN) of the distribution configuration to delete. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `distributionConfigurationArn` field"
  var valid_617565 = query.getOrDefault("distributionConfigurationArn")
  valid_617565 = validateParameter(valid_617565, JString, required = true,
                                 default = nil)
  if valid_617565 != nil:
    section.add "distributionConfigurationArn", valid_617565
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617566 = header.getOrDefault("X-Amz-Date")
  valid_617566 = validateParameter(valid_617566, JString, required = false,
                                 default = nil)
  if valid_617566 != nil:
    section.add "X-Amz-Date", valid_617566
  var valid_617567 = header.getOrDefault("X-Amz-Security-Token")
  valid_617567 = validateParameter(valid_617567, JString, required = false,
                                 default = nil)
  if valid_617567 != nil:
    section.add "X-Amz-Security-Token", valid_617567
  var valid_617568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617568 = validateParameter(valid_617568, JString, required = false,
                                 default = nil)
  if valid_617568 != nil:
    section.add "X-Amz-Content-Sha256", valid_617568
  var valid_617569 = header.getOrDefault("X-Amz-Algorithm")
  valid_617569 = validateParameter(valid_617569, JString, required = false,
                                 default = nil)
  if valid_617569 != nil:
    section.add "X-Amz-Algorithm", valid_617569
  var valid_617570 = header.getOrDefault("X-Amz-Signature")
  valid_617570 = validateParameter(valid_617570, JString, required = false,
                                 default = nil)
  if valid_617570 != nil:
    section.add "X-Amz-Signature", valid_617570
  var valid_617571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617571 = validateParameter(valid_617571, JString, required = false,
                                 default = nil)
  if valid_617571 != nil:
    section.add "X-Amz-SignedHeaders", valid_617571
  var valid_617572 = header.getOrDefault("X-Amz-Credential")
  valid_617572 = validateParameter(valid_617572, JString, required = false,
                                 default = nil)
  if valid_617572 != nil:
    section.add "X-Amz-Credential", valid_617572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617573: Call_DeleteDistributionConfiguration_617562;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Deletes a distribution configuration. 
  ## 
  let valid = call_617573.validator(path, query, header, formData, body, _)
  let scheme = call_617573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617573.url(scheme.get, call_617573.host, call_617573.base,
                         call_617573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617573, url, valid, _)

proc call*(call_617574: Call_DeleteDistributionConfiguration_617562;
          distributionConfigurationArn: string): Recallable =
  ## deleteDistributionConfiguration
  ##  Deletes a distribution configuration. 
  ##   distributionConfigurationArn: string (required)
  ##                               :  The Amazon Resource Name (ARN) of the distribution configuration to delete. 
  var query_617575 = newJObject()
  add(query_617575, "distributionConfigurationArn",
      newJString(distributionConfigurationArn))
  result = call_617574.call(nil, query_617575, nil, nil, nil)

var deleteDistributionConfiguration* = Call_DeleteDistributionConfiguration_617562(
    name: "deleteDistributionConfiguration", meth: HttpMethod.HttpDelete,
    host: "imagebuilder.amazonaws.com",
    route: "/DeleteDistributionConfiguration#distributionConfigurationArn",
    validator: validate_DeleteDistributionConfiguration_617563, base: "/",
    url: url_DeleteDistributionConfiguration_617564,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImage_617576 = ref object of OpenApiRestCall_616866
proc url_DeleteImage_617578(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteImage_617577(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ##  Deletes an image. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imageBuildVersionArn: JString (required)
  ##                       :  The Amazon Resource Name (ARN) of the image to delete. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `imageBuildVersionArn` field"
  var valid_617579 = query.getOrDefault("imageBuildVersionArn")
  valid_617579 = validateParameter(valid_617579, JString, required = true,
                                 default = nil)
  if valid_617579 != nil:
    section.add "imageBuildVersionArn", valid_617579
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617580 = header.getOrDefault("X-Amz-Date")
  valid_617580 = validateParameter(valid_617580, JString, required = false,
                                 default = nil)
  if valid_617580 != nil:
    section.add "X-Amz-Date", valid_617580
  var valid_617581 = header.getOrDefault("X-Amz-Security-Token")
  valid_617581 = validateParameter(valid_617581, JString, required = false,
                                 default = nil)
  if valid_617581 != nil:
    section.add "X-Amz-Security-Token", valid_617581
  var valid_617582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617582 = validateParameter(valid_617582, JString, required = false,
                                 default = nil)
  if valid_617582 != nil:
    section.add "X-Amz-Content-Sha256", valid_617582
  var valid_617583 = header.getOrDefault("X-Amz-Algorithm")
  valid_617583 = validateParameter(valid_617583, JString, required = false,
                                 default = nil)
  if valid_617583 != nil:
    section.add "X-Amz-Algorithm", valid_617583
  var valid_617584 = header.getOrDefault("X-Amz-Signature")
  valid_617584 = validateParameter(valid_617584, JString, required = false,
                                 default = nil)
  if valid_617584 != nil:
    section.add "X-Amz-Signature", valid_617584
  var valid_617585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617585 = validateParameter(valid_617585, JString, required = false,
                                 default = nil)
  if valid_617585 != nil:
    section.add "X-Amz-SignedHeaders", valid_617585
  var valid_617586 = header.getOrDefault("X-Amz-Credential")
  valid_617586 = validateParameter(valid_617586, JString, required = false,
                                 default = nil)
  if valid_617586 != nil:
    section.add "X-Amz-Credential", valid_617586
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617587: Call_DeleteImage_617576; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Deletes an image. 
  ## 
  let valid = call_617587.validator(path, query, header, formData, body, _)
  let scheme = call_617587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617587.url(scheme.get, call_617587.host, call_617587.base,
                         call_617587.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617587, url, valid, _)

proc call*(call_617588: Call_DeleteImage_617576; imageBuildVersionArn: string): Recallable =
  ## deleteImage
  ##  Deletes an image. 
  ##   imageBuildVersionArn: string (required)
  ##                       :  The Amazon Resource Name (ARN) of the image to delete. 
  var query_617589 = newJObject()
  add(query_617589, "imageBuildVersionArn", newJString(imageBuildVersionArn))
  result = call_617588.call(nil, query_617589, nil, nil, nil)

var deleteImage* = Call_DeleteImage_617576(name: "deleteImage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "imagebuilder.amazonaws.com", route: "/DeleteImage#imageBuildVersionArn",
                                        validator: validate_DeleteImage_617577,
                                        base: "/", url: url_DeleteImage_617578,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImagePipeline_617590 = ref object of OpenApiRestCall_616866
proc url_DeleteImagePipeline_617592(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteImagePipeline_617591(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
  ##  Deletes an image pipeline. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imagePipelineArn: JString (required)
  ##                   :  The Amazon Resource Name (ARN) of the image pipeline to delete. 
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `imagePipelineArn` field"
  var valid_617593 = query.getOrDefault("imagePipelineArn")
  valid_617593 = validateParameter(valid_617593, JString, required = true,
                                 default = nil)
  if valid_617593 != nil:
    section.add "imagePipelineArn", valid_617593
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617594 = header.getOrDefault("X-Amz-Date")
  valid_617594 = validateParameter(valid_617594, JString, required = false,
                                 default = nil)
  if valid_617594 != nil:
    section.add "X-Amz-Date", valid_617594
  var valid_617595 = header.getOrDefault("X-Amz-Security-Token")
  valid_617595 = validateParameter(valid_617595, JString, required = false,
                                 default = nil)
  if valid_617595 != nil:
    section.add "X-Amz-Security-Token", valid_617595
  var valid_617596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617596 = validateParameter(valid_617596, JString, required = false,
                                 default = nil)
  if valid_617596 != nil:
    section.add "X-Amz-Content-Sha256", valid_617596
  var valid_617597 = header.getOrDefault("X-Amz-Algorithm")
  valid_617597 = validateParameter(valid_617597, JString, required = false,
                                 default = nil)
  if valid_617597 != nil:
    section.add "X-Amz-Algorithm", valid_617597
  var valid_617598 = header.getOrDefault("X-Amz-Signature")
  valid_617598 = validateParameter(valid_617598, JString, required = false,
                                 default = nil)
  if valid_617598 != nil:
    section.add "X-Amz-Signature", valid_617598
  var valid_617599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617599 = validateParameter(valid_617599, JString, required = false,
                                 default = nil)
  if valid_617599 != nil:
    section.add "X-Amz-SignedHeaders", valid_617599
  var valid_617600 = header.getOrDefault("X-Amz-Credential")
  valid_617600 = validateParameter(valid_617600, JString, required = false,
                                 default = nil)
  if valid_617600 != nil:
    section.add "X-Amz-Credential", valid_617600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617601: Call_DeleteImagePipeline_617590; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Deletes an image pipeline. 
  ## 
  let valid = call_617601.validator(path, query, header, formData, body, _)
  let scheme = call_617601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617601.url(scheme.get, call_617601.host, call_617601.base,
                         call_617601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617601, url, valid, _)

proc call*(call_617602: Call_DeleteImagePipeline_617590; imagePipelineArn: string): Recallable =
  ## deleteImagePipeline
  ##  Deletes an image pipeline. 
  ##   imagePipelineArn: string (required)
  ##                   :  The Amazon Resource Name (ARN) of the image pipeline to delete. 
  var query_617603 = newJObject()
  add(query_617603, "imagePipelineArn", newJString(imagePipelineArn))
  result = call_617602.call(nil, query_617603, nil, nil, nil)

var deleteImagePipeline* = Call_DeleteImagePipeline_617590(
    name: "deleteImagePipeline", meth: HttpMethod.HttpDelete,
    host: "imagebuilder.amazonaws.com",
    route: "/DeleteImagePipeline#imagePipelineArn",
    validator: validate_DeleteImagePipeline_617591, base: "/",
    url: url_DeleteImagePipeline_617592, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImageRecipe_617604 = ref object of OpenApiRestCall_616866
proc url_DeleteImageRecipe_617606(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteImageRecipe_617605(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
  ##  Deletes an image recipe. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imageRecipeArn: JString (required)
  ##                 :  The Amazon Resource Name (ARN) of the image recipe to delete. 
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `imageRecipeArn` field"
  var valid_617607 = query.getOrDefault("imageRecipeArn")
  valid_617607 = validateParameter(valid_617607, JString, required = true,
                                 default = nil)
  if valid_617607 != nil:
    section.add "imageRecipeArn", valid_617607
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617608 = header.getOrDefault("X-Amz-Date")
  valid_617608 = validateParameter(valid_617608, JString, required = false,
                                 default = nil)
  if valid_617608 != nil:
    section.add "X-Amz-Date", valid_617608
  var valid_617609 = header.getOrDefault("X-Amz-Security-Token")
  valid_617609 = validateParameter(valid_617609, JString, required = false,
                                 default = nil)
  if valid_617609 != nil:
    section.add "X-Amz-Security-Token", valid_617609
  var valid_617610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617610 = validateParameter(valid_617610, JString, required = false,
                                 default = nil)
  if valid_617610 != nil:
    section.add "X-Amz-Content-Sha256", valid_617610
  var valid_617611 = header.getOrDefault("X-Amz-Algorithm")
  valid_617611 = validateParameter(valid_617611, JString, required = false,
                                 default = nil)
  if valid_617611 != nil:
    section.add "X-Amz-Algorithm", valid_617611
  var valid_617612 = header.getOrDefault("X-Amz-Signature")
  valid_617612 = validateParameter(valid_617612, JString, required = false,
                                 default = nil)
  if valid_617612 != nil:
    section.add "X-Amz-Signature", valid_617612
  var valid_617613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617613 = validateParameter(valid_617613, JString, required = false,
                                 default = nil)
  if valid_617613 != nil:
    section.add "X-Amz-SignedHeaders", valid_617613
  var valid_617614 = header.getOrDefault("X-Amz-Credential")
  valid_617614 = validateParameter(valid_617614, JString, required = false,
                                 default = nil)
  if valid_617614 != nil:
    section.add "X-Amz-Credential", valid_617614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617615: Call_DeleteImageRecipe_617604; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Deletes an image recipe. 
  ## 
  let valid = call_617615.validator(path, query, header, formData, body, _)
  let scheme = call_617615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617615.url(scheme.get, call_617615.host, call_617615.base,
                         call_617615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617615, url, valid, _)

proc call*(call_617616: Call_DeleteImageRecipe_617604; imageRecipeArn: string): Recallable =
  ## deleteImageRecipe
  ##  Deletes an image recipe. 
  ##   imageRecipeArn: string (required)
  ##                 :  The Amazon Resource Name (ARN) of the image recipe to delete. 
  var query_617617 = newJObject()
  add(query_617617, "imageRecipeArn", newJString(imageRecipeArn))
  result = call_617616.call(nil, query_617617, nil, nil, nil)

var deleteImageRecipe* = Call_DeleteImageRecipe_617604(name: "deleteImageRecipe",
    meth: HttpMethod.HttpDelete, host: "imagebuilder.amazonaws.com",
    route: "/DeleteImageRecipe#imageRecipeArn",
    validator: validate_DeleteImageRecipe_617605, base: "/",
    url: url_DeleteImageRecipe_617606, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInfrastructureConfiguration_617618 = ref object of OpenApiRestCall_616866
proc url_DeleteInfrastructureConfiguration_617620(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInfrastructureConfiguration_617619(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ##  Deletes an infrastructure configuration. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   infrastructureConfigurationArn: JString (required)
  ##                                 :  The Amazon Resource Name (ARN) of the infrastructure configuration to delete. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `infrastructureConfigurationArn` field"
  var valid_617621 = query.getOrDefault("infrastructureConfigurationArn")
  valid_617621 = validateParameter(valid_617621, JString, required = true,
                                 default = nil)
  if valid_617621 != nil:
    section.add "infrastructureConfigurationArn", valid_617621
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617622 = header.getOrDefault("X-Amz-Date")
  valid_617622 = validateParameter(valid_617622, JString, required = false,
                                 default = nil)
  if valid_617622 != nil:
    section.add "X-Amz-Date", valid_617622
  var valid_617623 = header.getOrDefault("X-Amz-Security-Token")
  valid_617623 = validateParameter(valid_617623, JString, required = false,
                                 default = nil)
  if valid_617623 != nil:
    section.add "X-Amz-Security-Token", valid_617623
  var valid_617624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617624 = validateParameter(valid_617624, JString, required = false,
                                 default = nil)
  if valid_617624 != nil:
    section.add "X-Amz-Content-Sha256", valid_617624
  var valid_617625 = header.getOrDefault("X-Amz-Algorithm")
  valid_617625 = validateParameter(valid_617625, JString, required = false,
                                 default = nil)
  if valid_617625 != nil:
    section.add "X-Amz-Algorithm", valid_617625
  var valid_617626 = header.getOrDefault("X-Amz-Signature")
  valid_617626 = validateParameter(valid_617626, JString, required = false,
                                 default = nil)
  if valid_617626 != nil:
    section.add "X-Amz-Signature", valid_617626
  var valid_617627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617627 = validateParameter(valid_617627, JString, required = false,
                                 default = nil)
  if valid_617627 != nil:
    section.add "X-Amz-SignedHeaders", valid_617627
  var valid_617628 = header.getOrDefault("X-Amz-Credential")
  valid_617628 = validateParameter(valid_617628, JString, required = false,
                                 default = nil)
  if valid_617628 != nil:
    section.add "X-Amz-Credential", valid_617628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617629: Call_DeleteInfrastructureConfiguration_617618;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Deletes an infrastructure configuration. 
  ## 
  let valid = call_617629.validator(path, query, header, formData, body, _)
  let scheme = call_617629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617629.url(scheme.get, call_617629.host, call_617629.base,
                         call_617629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617629, url, valid, _)

proc call*(call_617630: Call_DeleteInfrastructureConfiguration_617618;
          infrastructureConfigurationArn: string): Recallable =
  ## deleteInfrastructureConfiguration
  ##  Deletes an infrastructure configuration. 
  ##   infrastructureConfigurationArn: string (required)
  ##                                 :  The Amazon Resource Name (ARN) of the infrastructure configuration to delete. 
  var query_617631 = newJObject()
  add(query_617631, "infrastructureConfigurationArn",
      newJString(infrastructureConfigurationArn))
  result = call_617630.call(nil, query_617631, nil, nil, nil)

var deleteInfrastructureConfiguration* = Call_DeleteInfrastructureConfiguration_617618(
    name: "deleteInfrastructureConfiguration", meth: HttpMethod.HttpDelete,
    host: "imagebuilder.amazonaws.com",
    route: "/DeleteInfrastructureConfiguration#infrastructureConfigurationArn",
    validator: validate_DeleteInfrastructureConfiguration_617619, base: "/",
    url: url_DeleteInfrastructureConfiguration_617620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComponent_617632 = ref object of OpenApiRestCall_616866
proc url_GetComponent_617634(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComponent_617633(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ##  Gets a component object. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   componentBuildVersionArn: JString (required)
  ##                           :  The Amazon Resource Name (ARN) of the component that you want to retrieve. Regex requires "/\d+$" suffix.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `componentBuildVersionArn` field"
  var valid_617635 = query.getOrDefault("componentBuildVersionArn")
  valid_617635 = validateParameter(valid_617635, JString, required = true,
                                 default = nil)
  if valid_617635 != nil:
    section.add "componentBuildVersionArn", valid_617635
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617636 = header.getOrDefault("X-Amz-Date")
  valid_617636 = validateParameter(valid_617636, JString, required = false,
                                 default = nil)
  if valid_617636 != nil:
    section.add "X-Amz-Date", valid_617636
  var valid_617637 = header.getOrDefault("X-Amz-Security-Token")
  valid_617637 = validateParameter(valid_617637, JString, required = false,
                                 default = nil)
  if valid_617637 != nil:
    section.add "X-Amz-Security-Token", valid_617637
  var valid_617638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617638 = validateParameter(valid_617638, JString, required = false,
                                 default = nil)
  if valid_617638 != nil:
    section.add "X-Amz-Content-Sha256", valid_617638
  var valid_617639 = header.getOrDefault("X-Amz-Algorithm")
  valid_617639 = validateParameter(valid_617639, JString, required = false,
                                 default = nil)
  if valid_617639 != nil:
    section.add "X-Amz-Algorithm", valid_617639
  var valid_617640 = header.getOrDefault("X-Amz-Signature")
  valid_617640 = validateParameter(valid_617640, JString, required = false,
                                 default = nil)
  if valid_617640 != nil:
    section.add "X-Amz-Signature", valid_617640
  var valid_617641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617641 = validateParameter(valid_617641, JString, required = false,
                                 default = nil)
  if valid_617641 != nil:
    section.add "X-Amz-SignedHeaders", valid_617641
  var valid_617642 = header.getOrDefault("X-Amz-Credential")
  valid_617642 = validateParameter(valid_617642, JString, required = false,
                                 default = nil)
  if valid_617642 != nil:
    section.add "X-Amz-Credential", valid_617642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617643: Call_GetComponent_617632; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets a component object. 
  ## 
  let valid = call_617643.validator(path, query, header, formData, body, _)
  let scheme = call_617643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617643.url(scheme.get, call_617643.host, call_617643.base,
                         call_617643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617643, url, valid, _)

proc call*(call_617644: Call_GetComponent_617632; componentBuildVersionArn: string): Recallable =
  ## getComponent
  ##  Gets a component object. 
  ##   componentBuildVersionArn: string (required)
  ##                           :  The Amazon Resource Name (ARN) of the component that you want to retrieve. Regex requires "/\d+$" suffix.
  var query_617645 = newJObject()
  add(query_617645, "componentBuildVersionArn",
      newJString(componentBuildVersionArn))
  result = call_617644.call(nil, query_617645, nil, nil, nil)

var getComponent* = Call_GetComponent_617632(name: "getComponent",
    meth: HttpMethod.HttpGet, host: "imagebuilder.amazonaws.com",
    route: "/GetComponent#componentBuildVersionArn",
    validator: validate_GetComponent_617633, base: "/", url: url_GetComponent_617634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComponentPolicy_617646 = ref object of OpenApiRestCall_616866
proc url_GetComponentPolicy_617648(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComponentPolicy_617647(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
  ##  Gets a component policy. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   componentArn: JString (required)
  ##               :  The Amazon Resource Name (ARN) of the component whose policy you want to retrieve. 
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `componentArn` field"
  var valid_617649 = query.getOrDefault("componentArn")
  valid_617649 = validateParameter(valid_617649, JString, required = true,
                                 default = nil)
  if valid_617649 != nil:
    section.add "componentArn", valid_617649
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617650 = header.getOrDefault("X-Amz-Date")
  valid_617650 = validateParameter(valid_617650, JString, required = false,
                                 default = nil)
  if valid_617650 != nil:
    section.add "X-Amz-Date", valid_617650
  var valid_617651 = header.getOrDefault("X-Amz-Security-Token")
  valid_617651 = validateParameter(valid_617651, JString, required = false,
                                 default = nil)
  if valid_617651 != nil:
    section.add "X-Amz-Security-Token", valid_617651
  var valid_617652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617652 = validateParameter(valid_617652, JString, required = false,
                                 default = nil)
  if valid_617652 != nil:
    section.add "X-Amz-Content-Sha256", valid_617652
  var valid_617653 = header.getOrDefault("X-Amz-Algorithm")
  valid_617653 = validateParameter(valid_617653, JString, required = false,
                                 default = nil)
  if valid_617653 != nil:
    section.add "X-Amz-Algorithm", valid_617653
  var valid_617654 = header.getOrDefault("X-Amz-Signature")
  valid_617654 = validateParameter(valid_617654, JString, required = false,
                                 default = nil)
  if valid_617654 != nil:
    section.add "X-Amz-Signature", valid_617654
  var valid_617655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617655 = validateParameter(valid_617655, JString, required = false,
                                 default = nil)
  if valid_617655 != nil:
    section.add "X-Amz-SignedHeaders", valid_617655
  var valid_617656 = header.getOrDefault("X-Amz-Credential")
  valid_617656 = validateParameter(valid_617656, JString, required = false,
                                 default = nil)
  if valid_617656 != nil:
    section.add "X-Amz-Credential", valid_617656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617657: Call_GetComponentPolicy_617646; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets a component policy. 
  ## 
  let valid = call_617657.validator(path, query, header, formData, body, _)
  let scheme = call_617657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617657.url(scheme.get, call_617657.host, call_617657.base,
                         call_617657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617657, url, valid, _)

proc call*(call_617658: Call_GetComponentPolicy_617646; componentArn: string): Recallable =
  ## getComponentPolicy
  ##  Gets a component policy. 
  ##   componentArn: string (required)
  ##               :  The Amazon Resource Name (ARN) of the component whose policy you want to retrieve. 
  var query_617659 = newJObject()
  add(query_617659, "componentArn", newJString(componentArn))
  result = call_617658.call(nil, query_617659, nil, nil, nil)

var getComponentPolicy* = Call_GetComponentPolicy_617646(
    name: "getComponentPolicy", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com", route: "/GetComponentPolicy#componentArn",
    validator: validate_GetComponentPolicy_617647, base: "/",
    url: url_GetComponentPolicy_617648, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistributionConfiguration_617660 = ref object of OpenApiRestCall_616866
proc url_GetDistributionConfiguration_617662(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDistributionConfiguration_617661(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ##  Gets a distribution configuration. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   distributionConfigurationArn: JString (required)
  ##                               :  The Amazon Resource Name (ARN) of the distribution configuration that you want to retrieve. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `distributionConfigurationArn` field"
  var valid_617663 = query.getOrDefault("distributionConfigurationArn")
  valid_617663 = validateParameter(valid_617663, JString, required = true,
                                 default = nil)
  if valid_617663 != nil:
    section.add "distributionConfigurationArn", valid_617663
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617664 = header.getOrDefault("X-Amz-Date")
  valid_617664 = validateParameter(valid_617664, JString, required = false,
                                 default = nil)
  if valid_617664 != nil:
    section.add "X-Amz-Date", valid_617664
  var valid_617665 = header.getOrDefault("X-Amz-Security-Token")
  valid_617665 = validateParameter(valid_617665, JString, required = false,
                                 default = nil)
  if valid_617665 != nil:
    section.add "X-Amz-Security-Token", valid_617665
  var valid_617666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617666 = validateParameter(valid_617666, JString, required = false,
                                 default = nil)
  if valid_617666 != nil:
    section.add "X-Amz-Content-Sha256", valid_617666
  var valid_617667 = header.getOrDefault("X-Amz-Algorithm")
  valid_617667 = validateParameter(valid_617667, JString, required = false,
                                 default = nil)
  if valid_617667 != nil:
    section.add "X-Amz-Algorithm", valid_617667
  var valid_617668 = header.getOrDefault("X-Amz-Signature")
  valid_617668 = validateParameter(valid_617668, JString, required = false,
                                 default = nil)
  if valid_617668 != nil:
    section.add "X-Amz-Signature", valid_617668
  var valid_617669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617669 = validateParameter(valid_617669, JString, required = false,
                                 default = nil)
  if valid_617669 != nil:
    section.add "X-Amz-SignedHeaders", valid_617669
  var valid_617670 = header.getOrDefault("X-Amz-Credential")
  valid_617670 = validateParameter(valid_617670, JString, required = false,
                                 default = nil)
  if valid_617670 != nil:
    section.add "X-Amz-Credential", valid_617670
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617671: Call_GetDistributionConfiguration_617660;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets a distribution configuration. 
  ## 
  let valid = call_617671.validator(path, query, header, formData, body, _)
  let scheme = call_617671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617671.url(scheme.get, call_617671.host, call_617671.base,
                         call_617671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617671, url, valid, _)

proc call*(call_617672: Call_GetDistributionConfiguration_617660;
          distributionConfigurationArn: string): Recallable =
  ## getDistributionConfiguration
  ##  Gets a distribution configuration. 
  ##   distributionConfigurationArn: string (required)
  ##                               :  The Amazon Resource Name (ARN) of the distribution configuration that you want to retrieve. 
  var query_617673 = newJObject()
  add(query_617673, "distributionConfigurationArn",
      newJString(distributionConfigurationArn))
  result = call_617672.call(nil, query_617673, nil, nil, nil)

var getDistributionConfiguration* = Call_GetDistributionConfiguration_617660(
    name: "getDistributionConfiguration", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com",
    route: "/GetDistributionConfiguration#distributionConfigurationArn",
    validator: validate_GetDistributionConfiguration_617661, base: "/",
    url: url_GetDistributionConfiguration_617662,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImage_617674 = ref object of OpenApiRestCall_616866
proc url_GetImage_617676(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetImage_617675(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ##  Gets an image. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imageBuildVersionArn: JString (required)
  ##                       :  The Amazon Resource Name (ARN) of the image that you want to retrieve. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `imageBuildVersionArn` field"
  var valid_617677 = query.getOrDefault("imageBuildVersionArn")
  valid_617677 = validateParameter(valid_617677, JString, required = true,
                                 default = nil)
  if valid_617677 != nil:
    section.add "imageBuildVersionArn", valid_617677
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617678 = header.getOrDefault("X-Amz-Date")
  valid_617678 = validateParameter(valid_617678, JString, required = false,
                                 default = nil)
  if valid_617678 != nil:
    section.add "X-Amz-Date", valid_617678
  var valid_617679 = header.getOrDefault("X-Amz-Security-Token")
  valid_617679 = validateParameter(valid_617679, JString, required = false,
                                 default = nil)
  if valid_617679 != nil:
    section.add "X-Amz-Security-Token", valid_617679
  var valid_617680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617680 = validateParameter(valid_617680, JString, required = false,
                                 default = nil)
  if valid_617680 != nil:
    section.add "X-Amz-Content-Sha256", valid_617680
  var valid_617681 = header.getOrDefault("X-Amz-Algorithm")
  valid_617681 = validateParameter(valid_617681, JString, required = false,
                                 default = nil)
  if valid_617681 != nil:
    section.add "X-Amz-Algorithm", valid_617681
  var valid_617682 = header.getOrDefault("X-Amz-Signature")
  valid_617682 = validateParameter(valid_617682, JString, required = false,
                                 default = nil)
  if valid_617682 != nil:
    section.add "X-Amz-Signature", valid_617682
  var valid_617683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617683 = validateParameter(valid_617683, JString, required = false,
                                 default = nil)
  if valid_617683 != nil:
    section.add "X-Amz-SignedHeaders", valid_617683
  var valid_617684 = header.getOrDefault("X-Amz-Credential")
  valid_617684 = validateParameter(valid_617684, JString, required = false,
                                 default = nil)
  if valid_617684 != nil:
    section.add "X-Amz-Credential", valid_617684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617685: Call_GetImage_617674; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets an image. 
  ## 
  let valid = call_617685.validator(path, query, header, formData, body, _)
  let scheme = call_617685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617685.url(scheme.get, call_617685.host, call_617685.base,
                         call_617685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617685, url, valid, _)

proc call*(call_617686: Call_GetImage_617674; imageBuildVersionArn: string): Recallable =
  ## getImage
  ##  Gets an image. 
  ##   imageBuildVersionArn: string (required)
  ##                       :  The Amazon Resource Name (ARN) of the image that you want to retrieve. 
  var query_617687 = newJObject()
  add(query_617687, "imageBuildVersionArn", newJString(imageBuildVersionArn))
  result = call_617686.call(nil, query_617687, nil, nil, nil)

var getImage* = Call_GetImage_617674(name: "getImage", meth: HttpMethod.HttpGet,
                                  host: "imagebuilder.amazonaws.com",
                                  route: "/GetImage#imageBuildVersionArn",
                                  validator: validate_GetImage_617675, base: "/",
                                  url: url_GetImage_617676,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImagePipeline_617688 = ref object of OpenApiRestCall_616866
proc url_GetImagePipeline_617690(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetImagePipeline_617689(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
  ##  Gets an image pipeline. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imagePipelineArn: JString (required)
  ##                   :  The Amazon Resource Name (ARN) of the image pipeline that you want to retrieve. 
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `imagePipelineArn` field"
  var valid_617691 = query.getOrDefault("imagePipelineArn")
  valid_617691 = validateParameter(valid_617691, JString, required = true,
                                 default = nil)
  if valid_617691 != nil:
    section.add "imagePipelineArn", valid_617691
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617692 = header.getOrDefault("X-Amz-Date")
  valid_617692 = validateParameter(valid_617692, JString, required = false,
                                 default = nil)
  if valid_617692 != nil:
    section.add "X-Amz-Date", valid_617692
  var valid_617693 = header.getOrDefault("X-Amz-Security-Token")
  valid_617693 = validateParameter(valid_617693, JString, required = false,
                                 default = nil)
  if valid_617693 != nil:
    section.add "X-Amz-Security-Token", valid_617693
  var valid_617694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617694 = validateParameter(valid_617694, JString, required = false,
                                 default = nil)
  if valid_617694 != nil:
    section.add "X-Amz-Content-Sha256", valid_617694
  var valid_617695 = header.getOrDefault("X-Amz-Algorithm")
  valid_617695 = validateParameter(valid_617695, JString, required = false,
                                 default = nil)
  if valid_617695 != nil:
    section.add "X-Amz-Algorithm", valid_617695
  var valid_617696 = header.getOrDefault("X-Amz-Signature")
  valid_617696 = validateParameter(valid_617696, JString, required = false,
                                 default = nil)
  if valid_617696 != nil:
    section.add "X-Amz-Signature", valid_617696
  var valid_617697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617697 = validateParameter(valid_617697, JString, required = false,
                                 default = nil)
  if valid_617697 != nil:
    section.add "X-Amz-SignedHeaders", valid_617697
  var valid_617698 = header.getOrDefault("X-Amz-Credential")
  valid_617698 = validateParameter(valid_617698, JString, required = false,
                                 default = nil)
  if valid_617698 != nil:
    section.add "X-Amz-Credential", valid_617698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617699: Call_GetImagePipeline_617688; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets an image pipeline. 
  ## 
  let valid = call_617699.validator(path, query, header, formData, body, _)
  let scheme = call_617699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617699.url(scheme.get, call_617699.host, call_617699.base,
                         call_617699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617699, url, valid, _)

proc call*(call_617700: Call_GetImagePipeline_617688; imagePipelineArn: string): Recallable =
  ## getImagePipeline
  ##  Gets an image pipeline. 
  ##   imagePipelineArn: string (required)
  ##                   :  The Amazon Resource Name (ARN) of the image pipeline that you want to retrieve. 
  var query_617701 = newJObject()
  add(query_617701, "imagePipelineArn", newJString(imagePipelineArn))
  result = call_617700.call(nil, query_617701, nil, nil, nil)

var getImagePipeline* = Call_GetImagePipeline_617688(name: "getImagePipeline",
    meth: HttpMethod.HttpGet, host: "imagebuilder.amazonaws.com",
    route: "/GetImagePipeline#imagePipelineArn",
    validator: validate_GetImagePipeline_617689, base: "/",
    url: url_GetImagePipeline_617690, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImagePolicy_617702 = ref object of OpenApiRestCall_616866
proc url_GetImagePolicy_617704(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetImagePolicy_617703(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
  ##  Gets an image policy. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imageArn: JString (required)
  ##           :  The Amazon Resource Name (ARN) of the image whose policy you want to retrieve. 
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `imageArn` field"
  var valid_617705 = query.getOrDefault("imageArn")
  valid_617705 = validateParameter(valid_617705, JString, required = true,
                                 default = nil)
  if valid_617705 != nil:
    section.add "imageArn", valid_617705
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617706 = header.getOrDefault("X-Amz-Date")
  valid_617706 = validateParameter(valid_617706, JString, required = false,
                                 default = nil)
  if valid_617706 != nil:
    section.add "X-Amz-Date", valid_617706
  var valid_617707 = header.getOrDefault("X-Amz-Security-Token")
  valid_617707 = validateParameter(valid_617707, JString, required = false,
                                 default = nil)
  if valid_617707 != nil:
    section.add "X-Amz-Security-Token", valid_617707
  var valid_617708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617708 = validateParameter(valid_617708, JString, required = false,
                                 default = nil)
  if valid_617708 != nil:
    section.add "X-Amz-Content-Sha256", valid_617708
  var valid_617709 = header.getOrDefault("X-Amz-Algorithm")
  valid_617709 = validateParameter(valid_617709, JString, required = false,
                                 default = nil)
  if valid_617709 != nil:
    section.add "X-Amz-Algorithm", valid_617709
  var valid_617710 = header.getOrDefault("X-Amz-Signature")
  valid_617710 = validateParameter(valid_617710, JString, required = false,
                                 default = nil)
  if valid_617710 != nil:
    section.add "X-Amz-Signature", valid_617710
  var valid_617711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617711 = validateParameter(valid_617711, JString, required = false,
                                 default = nil)
  if valid_617711 != nil:
    section.add "X-Amz-SignedHeaders", valid_617711
  var valid_617712 = header.getOrDefault("X-Amz-Credential")
  valid_617712 = validateParameter(valid_617712, JString, required = false,
                                 default = nil)
  if valid_617712 != nil:
    section.add "X-Amz-Credential", valid_617712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617713: Call_GetImagePolicy_617702; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets an image policy. 
  ## 
  let valid = call_617713.validator(path, query, header, formData, body, _)
  let scheme = call_617713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617713.url(scheme.get, call_617713.host, call_617713.base,
                         call_617713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617713, url, valid, _)

proc call*(call_617714: Call_GetImagePolicy_617702; imageArn: string): Recallable =
  ## getImagePolicy
  ##  Gets an image policy. 
  ##   imageArn: string (required)
  ##           :  The Amazon Resource Name (ARN) of the image whose policy you want to retrieve. 
  var query_617715 = newJObject()
  add(query_617715, "imageArn", newJString(imageArn))
  result = call_617714.call(nil, query_617715, nil, nil, nil)

var getImagePolicy* = Call_GetImagePolicy_617702(name: "getImagePolicy",
    meth: HttpMethod.HttpGet, host: "imagebuilder.amazonaws.com",
    route: "/GetImagePolicy#imageArn", validator: validate_GetImagePolicy_617703,
    base: "/", url: url_GetImagePolicy_617704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImageRecipe_617716 = ref object of OpenApiRestCall_616866
proc url_GetImageRecipe_617718(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetImageRecipe_617717(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
  ##  Gets an image recipe. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imageRecipeArn: JString (required)
  ##                 :  The Amazon Resource Name (ARN) of the image recipe that you want to retrieve. 
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `imageRecipeArn` field"
  var valid_617719 = query.getOrDefault("imageRecipeArn")
  valid_617719 = validateParameter(valid_617719, JString, required = true,
                                 default = nil)
  if valid_617719 != nil:
    section.add "imageRecipeArn", valid_617719
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617720 = header.getOrDefault("X-Amz-Date")
  valid_617720 = validateParameter(valid_617720, JString, required = false,
                                 default = nil)
  if valid_617720 != nil:
    section.add "X-Amz-Date", valid_617720
  var valid_617721 = header.getOrDefault("X-Amz-Security-Token")
  valid_617721 = validateParameter(valid_617721, JString, required = false,
                                 default = nil)
  if valid_617721 != nil:
    section.add "X-Amz-Security-Token", valid_617721
  var valid_617722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617722 = validateParameter(valid_617722, JString, required = false,
                                 default = nil)
  if valid_617722 != nil:
    section.add "X-Amz-Content-Sha256", valid_617722
  var valid_617723 = header.getOrDefault("X-Amz-Algorithm")
  valid_617723 = validateParameter(valid_617723, JString, required = false,
                                 default = nil)
  if valid_617723 != nil:
    section.add "X-Amz-Algorithm", valid_617723
  var valid_617724 = header.getOrDefault("X-Amz-Signature")
  valid_617724 = validateParameter(valid_617724, JString, required = false,
                                 default = nil)
  if valid_617724 != nil:
    section.add "X-Amz-Signature", valid_617724
  var valid_617725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617725 = validateParameter(valid_617725, JString, required = false,
                                 default = nil)
  if valid_617725 != nil:
    section.add "X-Amz-SignedHeaders", valid_617725
  var valid_617726 = header.getOrDefault("X-Amz-Credential")
  valid_617726 = validateParameter(valid_617726, JString, required = false,
                                 default = nil)
  if valid_617726 != nil:
    section.add "X-Amz-Credential", valid_617726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617727: Call_GetImageRecipe_617716; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets an image recipe. 
  ## 
  let valid = call_617727.validator(path, query, header, formData, body, _)
  let scheme = call_617727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617727.url(scheme.get, call_617727.host, call_617727.base,
                         call_617727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617727, url, valid, _)

proc call*(call_617728: Call_GetImageRecipe_617716; imageRecipeArn: string): Recallable =
  ## getImageRecipe
  ##  Gets an image recipe. 
  ##   imageRecipeArn: string (required)
  ##                 :  The Amazon Resource Name (ARN) of the image recipe that you want to retrieve. 
  var query_617729 = newJObject()
  add(query_617729, "imageRecipeArn", newJString(imageRecipeArn))
  result = call_617728.call(nil, query_617729, nil, nil, nil)

var getImageRecipe* = Call_GetImageRecipe_617716(name: "getImageRecipe",
    meth: HttpMethod.HttpGet, host: "imagebuilder.amazonaws.com",
    route: "/GetImageRecipe#imageRecipeArn", validator: validate_GetImageRecipe_617717,
    base: "/", url: url_GetImageRecipe_617718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImageRecipePolicy_617730 = ref object of OpenApiRestCall_616866
proc url_GetImageRecipePolicy_617732(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetImageRecipePolicy_617731(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ##  Gets an image recipe policy. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imageRecipeArn: JString (required)
  ##                 :  The Amazon Resource Name (ARN) of the image recipe whose policy you want to retrieve. 
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `imageRecipeArn` field"
  var valid_617733 = query.getOrDefault("imageRecipeArn")
  valid_617733 = validateParameter(valid_617733, JString, required = true,
                                 default = nil)
  if valid_617733 != nil:
    section.add "imageRecipeArn", valid_617733
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617734 = header.getOrDefault("X-Amz-Date")
  valid_617734 = validateParameter(valid_617734, JString, required = false,
                                 default = nil)
  if valid_617734 != nil:
    section.add "X-Amz-Date", valid_617734
  var valid_617735 = header.getOrDefault("X-Amz-Security-Token")
  valid_617735 = validateParameter(valid_617735, JString, required = false,
                                 default = nil)
  if valid_617735 != nil:
    section.add "X-Amz-Security-Token", valid_617735
  var valid_617736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617736 = validateParameter(valid_617736, JString, required = false,
                                 default = nil)
  if valid_617736 != nil:
    section.add "X-Amz-Content-Sha256", valid_617736
  var valid_617737 = header.getOrDefault("X-Amz-Algorithm")
  valid_617737 = validateParameter(valid_617737, JString, required = false,
                                 default = nil)
  if valid_617737 != nil:
    section.add "X-Amz-Algorithm", valid_617737
  var valid_617738 = header.getOrDefault("X-Amz-Signature")
  valid_617738 = validateParameter(valid_617738, JString, required = false,
                                 default = nil)
  if valid_617738 != nil:
    section.add "X-Amz-Signature", valid_617738
  var valid_617739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617739 = validateParameter(valid_617739, JString, required = false,
                                 default = nil)
  if valid_617739 != nil:
    section.add "X-Amz-SignedHeaders", valid_617739
  var valid_617740 = header.getOrDefault("X-Amz-Credential")
  valid_617740 = validateParameter(valid_617740, JString, required = false,
                                 default = nil)
  if valid_617740 != nil:
    section.add "X-Amz-Credential", valid_617740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617741: Call_GetImageRecipePolicy_617730; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets an image recipe policy. 
  ## 
  let valid = call_617741.validator(path, query, header, formData, body, _)
  let scheme = call_617741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617741.url(scheme.get, call_617741.host, call_617741.base,
                         call_617741.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617741, url, valid, _)

proc call*(call_617742: Call_GetImageRecipePolicy_617730; imageRecipeArn: string): Recallable =
  ## getImageRecipePolicy
  ##  Gets an image recipe policy. 
  ##   imageRecipeArn: string (required)
  ##                 :  The Amazon Resource Name (ARN) of the image recipe whose policy you want to retrieve. 
  var query_617743 = newJObject()
  add(query_617743, "imageRecipeArn", newJString(imageRecipeArn))
  result = call_617742.call(nil, query_617743, nil, nil, nil)

var getImageRecipePolicy* = Call_GetImageRecipePolicy_617730(
    name: "getImageRecipePolicy", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com",
    route: "/GetImageRecipePolicy#imageRecipeArn",
    validator: validate_GetImageRecipePolicy_617731, base: "/",
    url: url_GetImageRecipePolicy_617732, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInfrastructureConfiguration_617744 = ref object of OpenApiRestCall_616866
proc url_GetInfrastructureConfiguration_617746(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInfrastructureConfiguration_617745(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ##  Gets an infrastructure configuration. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   infrastructureConfigurationArn: JString (required)
  ##                                 : The Amazon Resource Name (ARN) of the infrastructure configuration that you want to retrieve. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `infrastructureConfigurationArn` field"
  var valid_617747 = query.getOrDefault("infrastructureConfigurationArn")
  valid_617747 = validateParameter(valid_617747, JString, required = true,
                                 default = nil)
  if valid_617747 != nil:
    section.add "infrastructureConfigurationArn", valid_617747
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617748 = header.getOrDefault("X-Amz-Date")
  valid_617748 = validateParameter(valid_617748, JString, required = false,
                                 default = nil)
  if valid_617748 != nil:
    section.add "X-Amz-Date", valid_617748
  var valid_617749 = header.getOrDefault("X-Amz-Security-Token")
  valid_617749 = validateParameter(valid_617749, JString, required = false,
                                 default = nil)
  if valid_617749 != nil:
    section.add "X-Amz-Security-Token", valid_617749
  var valid_617750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617750 = validateParameter(valid_617750, JString, required = false,
                                 default = nil)
  if valid_617750 != nil:
    section.add "X-Amz-Content-Sha256", valid_617750
  var valid_617751 = header.getOrDefault("X-Amz-Algorithm")
  valid_617751 = validateParameter(valid_617751, JString, required = false,
                                 default = nil)
  if valid_617751 != nil:
    section.add "X-Amz-Algorithm", valid_617751
  var valid_617752 = header.getOrDefault("X-Amz-Signature")
  valid_617752 = validateParameter(valid_617752, JString, required = false,
                                 default = nil)
  if valid_617752 != nil:
    section.add "X-Amz-Signature", valid_617752
  var valid_617753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617753 = validateParameter(valid_617753, JString, required = false,
                                 default = nil)
  if valid_617753 != nil:
    section.add "X-Amz-SignedHeaders", valid_617753
  var valid_617754 = header.getOrDefault("X-Amz-Credential")
  valid_617754 = validateParameter(valid_617754, JString, required = false,
                                 default = nil)
  if valid_617754 != nil:
    section.add "X-Amz-Credential", valid_617754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617755: Call_GetInfrastructureConfiguration_617744;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets an infrastructure configuration. 
  ## 
  let valid = call_617755.validator(path, query, header, formData, body, _)
  let scheme = call_617755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617755.url(scheme.get, call_617755.host, call_617755.base,
                         call_617755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617755, url, valid, _)

proc call*(call_617756: Call_GetInfrastructureConfiguration_617744;
          infrastructureConfigurationArn: string): Recallable =
  ## getInfrastructureConfiguration
  ##  Gets an infrastructure configuration. 
  ##   infrastructureConfigurationArn: string (required)
  ##                                 : The Amazon Resource Name (ARN) of the infrastructure configuration that you want to retrieve. 
  var query_617757 = newJObject()
  add(query_617757, "infrastructureConfigurationArn",
      newJString(infrastructureConfigurationArn))
  result = call_617756.call(nil, query_617757, nil, nil, nil)

var getInfrastructureConfiguration* = Call_GetInfrastructureConfiguration_617744(
    name: "getInfrastructureConfiguration", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com",
    route: "/GetInfrastructureConfiguration#infrastructureConfigurationArn",
    validator: validate_GetInfrastructureConfiguration_617745, base: "/",
    url: url_GetInfrastructureConfiguration_617746,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportComponent_617758 = ref object of OpenApiRestCall_616866
proc url_ImportComponent_617760(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportComponent_617759(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
  ## Imports a component and transforms its data into a component document. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617761 = header.getOrDefault("X-Amz-Date")
  valid_617761 = validateParameter(valid_617761, JString, required = false,
                                 default = nil)
  if valid_617761 != nil:
    section.add "X-Amz-Date", valid_617761
  var valid_617762 = header.getOrDefault("X-Amz-Security-Token")
  valid_617762 = validateParameter(valid_617762, JString, required = false,
                                 default = nil)
  if valid_617762 != nil:
    section.add "X-Amz-Security-Token", valid_617762
  var valid_617763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617763 = validateParameter(valid_617763, JString, required = false,
                                 default = nil)
  if valid_617763 != nil:
    section.add "X-Amz-Content-Sha256", valid_617763
  var valid_617764 = header.getOrDefault("X-Amz-Algorithm")
  valid_617764 = validateParameter(valid_617764, JString, required = false,
                                 default = nil)
  if valid_617764 != nil:
    section.add "X-Amz-Algorithm", valid_617764
  var valid_617765 = header.getOrDefault("X-Amz-Signature")
  valid_617765 = validateParameter(valid_617765, JString, required = false,
                                 default = nil)
  if valid_617765 != nil:
    section.add "X-Amz-Signature", valid_617765
  var valid_617766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617766 = validateParameter(valid_617766, JString, required = false,
                                 default = nil)
  if valid_617766 != nil:
    section.add "X-Amz-SignedHeaders", valid_617766
  var valid_617767 = header.getOrDefault("X-Amz-Credential")
  valid_617767 = validateParameter(valid_617767, JString, required = false,
                                 default = nil)
  if valid_617767 != nil:
    section.add "X-Amz-Credential", valid_617767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617769: Call_ImportComponent_617758; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Imports a component and transforms its data into a component document. 
  ## 
  let valid = call_617769.validator(path, query, header, formData, body, _)
  let scheme = call_617769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617769.url(scheme.get, call_617769.host, call_617769.base,
                         call_617769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617769, url, valid, _)

proc call*(call_617770: Call_ImportComponent_617758; body: JsonNode): Recallable =
  ## importComponent
  ## Imports a component and transforms its data into a component document. 
  ##   body: JObject (required)
  var body_617771 = newJObject()
  if body != nil:
    body_617771 = body
  result = call_617770.call(nil, nil, nil, nil, body_617771)

var importComponent* = Call_ImportComponent_617758(name: "importComponent",
    meth: HttpMethod.HttpPut, host: "imagebuilder.amazonaws.com",
    route: "/ImportComponent", validator: validate_ImportComponent_617759,
    base: "/", url: url_ImportComponent_617760, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComponentBuildVersions_617772 = ref object of OpenApiRestCall_616866
proc url_ListComponentBuildVersions_617774(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListComponentBuildVersions_617773(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ##  Returns the list of component build versions for the specified semantic version. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_617775 = query.getOrDefault("maxResults")
  valid_617775 = validateParameter(valid_617775, JString, required = false,
                                 default = nil)
  if valid_617775 != nil:
    section.add "maxResults", valid_617775
  var valid_617776 = query.getOrDefault("nextToken")
  valid_617776 = validateParameter(valid_617776, JString, required = false,
                                 default = nil)
  if valid_617776 != nil:
    section.add "nextToken", valid_617776
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617777 = header.getOrDefault("X-Amz-Date")
  valid_617777 = validateParameter(valid_617777, JString, required = false,
                                 default = nil)
  if valid_617777 != nil:
    section.add "X-Amz-Date", valid_617777
  var valid_617778 = header.getOrDefault("X-Amz-Security-Token")
  valid_617778 = validateParameter(valid_617778, JString, required = false,
                                 default = nil)
  if valid_617778 != nil:
    section.add "X-Amz-Security-Token", valid_617778
  var valid_617779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617779 = validateParameter(valid_617779, JString, required = false,
                                 default = nil)
  if valid_617779 != nil:
    section.add "X-Amz-Content-Sha256", valid_617779
  var valid_617780 = header.getOrDefault("X-Amz-Algorithm")
  valid_617780 = validateParameter(valid_617780, JString, required = false,
                                 default = nil)
  if valid_617780 != nil:
    section.add "X-Amz-Algorithm", valid_617780
  var valid_617781 = header.getOrDefault("X-Amz-Signature")
  valid_617781 = validateParameter(valid_617781, JString, required = false,
                                 default = nil)
  if valid_617781 != nil:
    section.add "X-Amz-Signature", valid_617781
  var valid_617782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617782 = validateParameter(valid_617782, JString, required = false,
                                 default = nil)
  if valid_617782 != nil:
    section.add "X-Amz-SignedHeaders", valid_617782
  var valid_617783 = header.getOrDefault("X-Amz-Credential")
  valid_617783 = validateParameter(valid_617783, JString, required = false,
                                 default = nil)
  if valid_617783 != nil:
    section.add "X-Amz-Credential", valid_617783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617785: Call_ListComponentBuildVersions_617772;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns the list of component build versions for the specified semantic version. 
  ## 
  let valid = call_617785.validator(path, query, header, formData, body, _)
  let scheme = call_617785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617785.url(scheme.get, call_617785.host, call_617785.base,
                         call_617785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617785, url, valid, _)

proc call*(call_617786: Call_ListComponentBuildVersions_617772; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listComponentBuildVersions
  ##  Returns the list of component build versions for the specified semantic version. 
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617787 = newJObject()
  var body_617788 = newJObject()
  add(query_617787, "maxResults", newJString(maxResults))
  add(query_617787, "nextToken", newJString(nextToken))
  if body != nil:
    body_617788 = body
  result = call_617786.call(nil, query_617787, nil, nil, body_617788)

var listComponentBuildVersions* = Call_ListComponentBuildVersions_617772(
    name: "listComponentBuildVersions", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListComponentBuildVersions",
    validator: validate_ListComponentBuildVersions_617773, base: "/",
    url: url_ListComponentBuildVersions_617774,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComponents_617789 = ref object of OpenApiRestCall_616866
proc url_ListComponents_617791(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListComponents_617790(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
  ## Returns the list of component build versions for the specified semantic version. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_617792 = query.getOrDefault("maxResults")
  valid_617792 = validateParameter(valid_617792, JString, required = false,
                                 default = nil)
  if valid_617792 != nil:
    section.add "maxResults", valid_617792
  var valid_617793 = query.getOrDefault("nextToken")
  valid_617793 = validateParameter(valid_617793, JString, required = false,
                                 default = nil)
  if valid_617793 != nil:
    section.add "nextToken", valid_617793
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617794 = header.getOrDefault("X-Amz-Date")
  valid_617794 = validateParameter(valid_617794, JString, required = false,
                                 default = nil)
  if valid_617794 != nil:
    section.add "X-Amz-Date", valid_617794
  var valid_617795 = header.getOrDefault("X-Amz-Security-Token")
  valid_617795 = validateParameter(valid_617795, JString, required = false,
                                 default = nil)
  if valid_617795 != nil:
    section.add "X-Amz-Security-Token", valid_617795
  var valid_617796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617796 = validateParameter(valid_617796, JString, required = false,
                                 default = nil)
  if valid_617796 != nil:
    section.add "X-Amz-Content-Sha256", valid_617796
  var valid_617797 = header.getOrDefault("X-Amz-Algorithm")
  valid_617797 = validateParameter(valid_617797, JString, required = false,
                                 default = nil)
  if valid_617797 != nil:
    section.add "X-Amz-Algorithm", valid_617797
  var valid_617798 = header.getOrDefault("X-Amz-Signature")
  valid_617798 = validateParameter(valid_617798, JString, required = false,
                                 default = nil)
  if valid_617798 != nil:
    section.add "X-Amz-Signature", valid_617798
  var valid_617799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617799 = validateParameter(valid_617799, JString, required = false,
                                 default = nil)
  if valid_617799 != nil:
    section.add "X-Amz-SignedHeaders", valid_617799
  var valid_617800 = header.getOrDefault("X-Amz-Credential")
  valid_617800 = validateParameter(valid_617800, JString, required = false,
                                 default = nil)
  if valid_617800 != nil:
    section.add "X-Amz-Credential", valid_617800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617802: Call_ListComponents_617789; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the list of component build versions for the specified semantic version. 
  ## 
  let valid = call_617802.validator(path, query, header, formData, body, _)
  let scheme = call_617802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617802.url(scheme.get, call_617802.host, call_617802.base,
                         call_617802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617802, url, valid, _)

proc call*(call_617803: Call_ListComponents_617789; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listComponents
  ## Returns the list of component build versions for the specified semantic version. 
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617804 = newJObject()
  var body_617805 = newJObject()
  add(query_617804, "maxResults", newJString(maxResults))
  add(query_617804, "nextToken", newJString(nextToken))
  if body != nil:
    body_617805 = body
  result = call_617803.call(nil, query_617804, nil, nil, body_617805)

var listComponents* = Call_ListComponents_617789(name: "listComponents",
    meth: HttpMethod.HttpPost, host: "imagebuilder.amazonaws.com",
    route: "/ListComponents", validator: validate_ListComponents_617790, base: "/",
    url: url_ListComponents_617791, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributionConfigurations_617806 = ref object of OpenApiRestCall_616866
proc url_ListDistributionConfigurations_617808(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDistributionConfigurations_617807(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ##  Returns a list of distribution configurations. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_617809 = query.getOrDefault("maxResults")
  valid_617809 = validateParameter(valid_617809, JString, required = false,
                                 default = nil)
  if valid_617809 != nil:
    section.add "maxResults", valid_617809
  var valid_617810 = query.getOrDefault("nextToken")
  valid_617810 = validateParameter(valid_617810, JString, required = false,
                                 default = nil)
  if valid_617810 != nil:
    section.add "nextToken", valid_617810
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617811 = header.getOrDefault("X-Amz-Date")
  valid_617811 = validateParameter(valid_617811, JString, required = false,
                                 default = nil)
  if valid_617811 != nil:
    section.add "X-Amz-Date", valid_617811
  var valid_617812 = header.getOrDefault("X-Amz-Security-Token")
  valid_617812 = validateParameter(valid_617812, JString, required = false,
                                 default = nil)
  if valid_617812 != nil:
    section.add "X-Amz-Security-Token", valid_617812
  var valid_617813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617813 = validateParameter(valid_617813, JString, required = false,
                                 default = nil)
  if valid_617813 != nil:
    section.add "X-Amz-Content-Sha256", valid_617813
  var valid_617814 = header.getOrDefault("X-Amz-Algorithm")
  valid_617814 = validateParameter(valid_617814, JString, required = false,
                                 default = nil)
  if valid_617814 != nil:
    section.add "X-Amz-Algorithm", valid_617814
  var valid_617815 = header.getOrDefault("X-Amz-Signature")
  valid_617815 = validateParameter(valid_617815, JString, required = false,
                                 default = nil)
  if valid_617815 != nil:
    section.add "X-Amz-Signature", valid_617815
  var valid_617816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617816 = validateParameter(valid_617816, JString, required = false,
                                 default = nil)
  if valid_617816 != nil:
    section.add "X-Amz-SignedHeaders", valid_617816
  var valid_617817 = header.getOrDefault("X-Amz-Credential")
  valid_617817 = validateParameter(valid_617817, JString, required = false,
                                 default = nil)
  if valid_617817 != nil:
    section.add "X-Amz-Credential", valid_617817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617819: Call_ListDistributionConfigurations_617806;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns a list of distribution configurations. 
  ## 
  let valid = call_617819.validator(path, query, header, formData, body, _)
  let scheme = call_617819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617819.url(scheme.get, call_617819.host, call_617819.base,
                         call_617819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617819, url, valid, _)

proc call*(call_617820: Call_ListDistributionConfigurations_617806; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listDistributionConfigurations
  ##  Returns a list of distribution configurations. 
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617821 = newJObject()
  var body_617822 = newJObject()
  add(query_617821, "maxResults", newJString(maxResults))
  add(query_617821, "nextToken", newJString(nextToken))
  if body != nil:
    body_617822 = body
  result = call_617820.call(nil, query_617821, nil, nil, body_617822)

var listDistributionConfigurations* = Call_ListDistributionConfigurations_617806(
    name: "listDistributionConfigurations", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListDistributionConfigurations",
    validator: validate_ListDistributionConfigurations_617807, base: "/",
    url: url_ListDistributionConfigurations_617808,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImageBuildVersions_617823 = ref object of OpenApiRestCall_616866
proc url_ListImageBuildVersions_617825(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListImageBuildVersions_617824(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ##  Returns a list of distribution configurations. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_617826 = query.getOrDefault("maxResults")
  valid_617826 = validateParameter(valid_617826, JString, required = false,
                                 default = nil)
  if valid_617826 != nil:
    section.add "maxResults", valid_617826
  var valid_617827 = query.getOrDefault("nextToken")
  valid_617827 = validateParameter(valid_617827, JString, required = false,
                                 default = nil)
  if valid_617827 != nil:
    section.add "nextToken", valid_617827
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617828 = header.getOrDefault("X-Amz-Date")
  valid_617828 = validateParameter(valid_617828, JString, required = false,
                                 default = nil)
  if valid_617828 != nil:
    section.add "X-Amz-Date", valid_617828
  var valid_617829 = header.getOrDefault("X-Amz-Security-Token")
  valid_617829 = validateParameter(valid_617829, JString, required = false,
                                 default = nil)
  if valid_617829 != nil:
    section.add "X-Amz-Security-Token", valid_617829
  var valid_617830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617830 = validateParameter(valid_617830, JString, required = false,
                                 default = nil)
  if valid_617830 != nil:
    section.add "X-Amz-Content-Sha256", valid_617830
  var valid_617831 = header.getOrDefault("X-Amz-Algorithm")
  valid_617831 = validateParameter(valid_617831, JString, required = false,
                                 default = nil)
  if valid_617831 != nil:
    section.add "X-Amz-Algorithm", valid_617831
  var valid_617832 = header.getOrDefault("X-Amz-Signature")
  valid_617832 = validateParameter(valid_617832, JString, required = false,
                                 default = nil)
  if valid_617832 != nil:
    section.add "X-Amz-Signature", valid_617832
  var valid_617833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617833 = validateParameter(valid_617833, JString, required = false,
                                 default = nil)
  if valid_617833 != nil:
    section.add "X-Amz-SignedHeaders", valid_617833
  var valid_617834 = header.getOrDefault("X-Amz-Credential")
  valid_617834 = validateParameter(valid_617834, JString, required = false,
                                 default = nil)
  if valid_617834 != nil:
    section.add "X-Amz-Credential", valid_617834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617836: Call_ListImageBuildVersions_617823; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns a list of distribution configurations. 
  ## 
  let valid = call_617836.validator(path, query, header, formData, body, _)
  let scheme = call_617836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617836.url(scheme.get, call_617836.host, call_617836.base,
                         call_617836.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617836, url, valid, _)

proc call*(call_617837: Call_ListImageBuildVersions_617823; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listImageBuildVersions
  ##  Returns a list of distribution configurations. 
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617838 = newJObject()
  var body_617839 = newJObject()
  add(query_617838, "maxResults", newJString(maxResults))
  add(query_617838, "nextToken", newJString(nextToken))
  if body != nil:
    body_617839 = body
  result = call_617837.call(nil, query_617838, nil, nil, body_617839)

var listImageBuildVersions* = Call_ListImageBuildVersions_617823(
    name: "listImageBuildVersions", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListImageBuildVersions",
    validator: validate_ListImageBuildVersions_617824, base: "/",
    url: url_ListImageBuildVersions_617825, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImagePipelineImages_617840 = ref object of OpenApiRestCall_616866
proc url_ListImagePipelineImages_617842(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListImagePipelineImages_617841(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ##  Returns a list of images created by the specified pipeline. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_617843 = query.getOrDefault("maxResults")
  valid_617843 = validateParameter(valid_617843, JString, required = false,
                                 default = nil)
  if valid_617843 != nil:
    section.add "maxResults", valid_617843
  var valid_617844 = query.getOrDefault("nextToken")
  valid_617844 = validateParameter(valid_617844, JString, required = false,
                                 default = nil)
  if valid_617844 != nil:
    section.add "nextToken", valid_617844
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617845 = header.getOrDefault("X-Amz-Date")
  valid_617845 = validateParameter(valid_617845, JString, required = false,
                                 default = nil)
  if valid_617845 != nil:
    section.add "X-Amz-Date", valid_617845
  var valid_617846 = header.getOrDefault("X-Amz-Security-Token")
  valid_617846 = validateParameter(valid_617846, JString, required = false,
                                 default = nil)
  if valid_617846 != nil:
    section.add "X-Amz-Security-Token", valid_617846
  var valid_617847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617847 = validateParameter(valid_617847, JString, required = false,
                                 default = nil)
  if valid_617847 != nil:
    section.add "X-Amz-Content-Sha256", valid_617847
  var valid_617848 = header.getOrDefault("X-Amz-Algorithm")
  valid_617848 = validateParameter(valid_617848, JString, required = false,
                                 default = nil)
  if valid_617848 != nil:
    section.add "X-Amz-Algorithm", valid_617848
  var valid_617849 = header.getOrDefault("X-Amz-Signature")
  valid_617849 = validateParameter(valid_617849, JString, required = false,
                                 default = nil)
  if valid_617849 != nil:
    section.add "X-Amz-Signature", valid_617849
  var valid_617850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617850 = validateParameter(valid_617850, JString, required = false,
                                 default = nil)
  if valid_617850 != nil:
    section.add "X-Amz-SignedHeaders", valid_617850
  var valid_617851 = header.getOrDefault("X-Amz-Credential")
  valid_617851 = validateParameter(valid_617851, JString, required = false,
                                 default = nil)
  if valid_617851 != nil:
    section.add "X-Amz-Credential", valid_617851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617853: Call_ListImagePipelineImages_617840; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns a list of images created by the specified pipeline. 
  ## 
  let valid = call_617853.validator(path, query, header, formData, body, _)
  let scheme = call_617853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617853.url(scheme.get, call_617853.host, call_617853.base,
                         call_617853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617853, url, valid, _)

proc call*(call_617854: Call_ListImagePipelineImages_617840; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listImagePipelineImages
  ##  Returns a list of images created by the specified pipeline. 
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617855 = newJObject()
  var body_617856 = newJObject()
  add(query_617855, "maxResults", newJString(maxResults))
  add(query_617855, "nextToken", newJString(nextToken))
  if body != nil:
    body_617856 = body
  result = call_617854.call(nil, query_617855, nil, nil, body_617856)

var listImagePipelineImages* = Call_ListImagePipelineImages_617840(
    name: "listImagePipelineImages", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListImagePipelineImages",
    validator: validate_ListImagePipelineImages_617841, base: "/",
    url: url_ListImagePipelineImages_617842, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImagePipelines_617857 = ref object of OpenApiRestCall_616866
proc url_ListImagePipelines_617859(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListImagePipelines_617858(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
  ## Returns a list of image pipelines. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_617860 = query.getOrDefault("maxResults")
  valid_617860 = validateParameter(valid_617860, JString, required = false,
                                 default = nil)
  if valid_617860 != nil:
    section.add "maxResults", valid_617860
  var valid_617861 = query.getOrDefault("nextToken")
  valid_617861 = validateParameter(valid_617861, JString, required = false,
                                 default = nil)
  if valid_617861 != nil:
    section.add "nextToken", valid_617861
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617862 = header.getOrDefault("X-Amz-Date")
  valid_617862 = validateParameter(valid_617862, JString, required = false,
                                 default = nil)
  if valid_617862 != nil:
    section.add "X-Amz-Date", valid_617862
  var valid_617863 = header.getOrDefault("X-Amz-Security-Token")
  valid_617863 = validateParameter(valid_617863, JString, required = false,
                                 default = nil)
  if valid_617863 != nil:
    section.add "X-Amz-Security-Token", valid_617863
  var valid_617864 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617864 = validateParameter(valid_617864, JString, required = false,
                                 default = nil)
  if valid_617864 != nil:
    section.add "X-Amz-Content-Sha256", valid_617864
  var valid_617865 = header.getOrDefault("X-Amz-Algorithm")
  valid_617865 = validateParameter(valid_617865, JString, required = false,
                                 default = nil)
  if valid_617865 != nil:
    section.add "X-Amz-Algorithm", valid_617865
  var valid_617866 = header.getOrDefault("X-Amz-Signature")
  valid_617866 = validateParameter(valid_617866, JString, required = false,
                                 default = nil)
  if valid_617866 != nil:
    section.add "X-Amz-Signature", valid_617866
  var valid_617867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617867 = validateParameter(valid_617867, JString, required = false,
                                 default = nil)
  if valid_617867 != nil:
    section.add "X-Amz-SignedHeaders", valid_617867
  var valid_617868 = header.getOrDefault("X-Amz-Credential")
  valid_617868 = validateParameter(valid_617868, JString, required = false,
                                 default = nil)
  if valid_617868 != nil:
    section.add "X-Amz-Credential", valid_617868
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617870: Call_ListImagePipelines_617857; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of image pipelines. 
  ## 
  let valid = call_617870.validator(path, query, header, formData, body, _)
  let scheme = call_617870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617870.url(scheme.get, call_617870.host, call_617870.base,
                         call_617870.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617870, url, valid, _)

proc call*(call_617871: Call_ListImagePipelines_617857; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listImagePipelines
  ## Returns a list of image pipelines. 
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617872 = newJObject()
  var body_617873 = newJObject()
  add(query_617872, "maxResults", newJString(maxResults))
  add(query_617872, "nextToken", newJString(nextToken))
  if body != nil:
    body_617873 = body
  result = call_617871.call(nil, query_617872, nil, nil, body_617873)

var listImagePipelines* = Call_ListImagePipelines_617857(
    name: "listImagePipelines", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListImagePipelines",
    validator: validate_ListImagePipelines_617858, base: "/",
    url: url_ListImagePipelines_617859, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImageRecipes_617874 = ref object of OpenApiRestCall_616866
proc url_ListImageRecipes_617876(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListImageRecipes_617875(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
  ##  Returns a list of image recipes. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_617877 = query.getOrDefault("maxResults")
  valid_617877 = validateParameter(valid_617877, JString, required = false,
                                 default = nil)
  if valid_617877 != nil:
    section.add "maxResults", valid_617877
  var valid_617878 = query.getOrDefault("nextToken")
  valid_617878 = validateParameter(valid_617878, JString, required = false,
                                 default = nil)
  if valid_617878 != nil:
    section.add "nextToken", valid_617878
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617879 = header.getOrDefault("X-Amz-Date")
  valid_617879 = validateParameter(valid_617879, JString, required = false,
                                 default = nil)
  if valid_617879 != nil:
    section.add "X-Amz-Date", valid_617879
  var valid_617880 = header.getOrDefault("X-Amz-Security-Token")
  valid_617880 = validateParameter(valid_617880, JString, required = false,
                                 default = nil)
  if valid_617880 != nil:
    section.add "X-Amz-Security-Token", valid_617880
  var valid_617881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617881 = validateParameter(valid_617881, JString, required = false,
                                 default = nil)
  if valid_617881 != nil:
    section.add "X-Amz-Content-Sha256", valid_617881
  var valid_617882 = header.getOrDefault("X-Amz-Algorithm")
  valid_617882 = validateParameter(valid_617882, JString, required = false,
                                 default = nil)
  if valid_617882 != nil:
    section.add "X-Amz-Algorithm", valid_617882
  var valid_617883 = header.getOrDefault("X-Amz-Signature")
  valid_617883 = validateParameter(valid_617883, JString, required = false,
                                 default = nil)
  if valid_617883 != nil:
    section.add "X-Amz-Signature", valid_617883
  var valid_617884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617884 = validateParameter(valid_617884, JString, required = false,
                                 default = nil)
  if valid_617884 != nil:
    section.add "X-Amz-SignedHeaders", valid_617884
  var valid_617885 = header.getOrDefault("X-Amz-Credential")
  valid_617885 = validateParameter(valid_617885, JString, required = false,
                                 default = nil)
  if valid_617885 != nil:
    section.add "X-Amz-Credential", valid_617885
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617887: Call_ListImageRecipes_617874; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns a list of image recipes. 
  ## 
  let valid = call_617887.validator(path, query, header, formData, body, _)
  let scheme = call_617887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617887.url(scheme.get, call_617887.host, call_617887.base,
                         call_617887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617887, url, valid, _)

proc call*(call_617888: Call_ListImageRecipes_617874; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listImageRecipes
  ##  Returns a list of image recipes. 
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617889 = newJObject()
  var body_617890 = newJObject()
  add(query_617889, "maxResults", newJString(maxResults))
  add(query_617889, "nextToken", newJString(nextToken))
  if body != nil:
    body_617890 = body
  result = call_617888.call(nil, query_617889, nil, nil, body_617890)

var listImageRecipes* = Call_ListImageRecipes_617874(name: "listImageRecipes",
    meth: HttpMethod.HttpPost, host: "imagebuilder.amazonaws.com",
    route: "/ListImageRecipes", validator: validate_ListImageRecipes_617875,
    base: "/", url: url_ListImageRecipes_617876,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImages_617891 = ref object of OpenApiRestCall_616866
proc url_ListImages_617893(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListImages_617892(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ##  Returns the list of image build versions for the specified semantic version. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_617894 = query.getOrDefault("maxResults")
  valid_617894 = validateParameter(valid_617894, JString, required = false,
                                 default = nil)
  if valid_617894 != nil:
    section.add "maxResults", valid_617894
  var valid_617895 = query.getOrDefault("nextToken")
  valid_617895 = validateParameter(valid_617895, JString, required = false,
                                 default = nil)
  if valid_617895 != nil:
    section.add "nextToken", valid_617895
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617896 = header.getOrDefault("X-Amz-Date")
  valid_617896 = validateParameter(valid_617896, JString, required = false,
                                 default = nil)
  if valid_617896 != nil:
    section.add "X-Amz-Date", valid_617896
  var valid_617897 = header.getOrDefault("X-Amz-Security-Token")
  valid_617897 = validateParameter(valid_617897, JString, required = false,
                                 default = nil)
  if valid_617897 != nil:
    section.add "X-Amz-Security-Token", valid_617897
  var valid_617898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617898 = validateParameter(valid_617898, JString, required = false,
                                 default = nil)
  if valid_617898 != nil:
    section.add "X-Amz-Content-Sha256", valid_617898
  var valid_617899 = header.getOrDefault("X-Amz-Algorithm")
  valid_617899 = validateParameter(valid_617899, JString, required = false,
                                 default = nil)
  if valid_617899 != nil:
    section.add "X-Amz-Algorithm", valid_617899
  var valid_617900 = header.getOrDefault("X-Amz-Signature")
  valid_617900 = validateParameter(valid_617900, JString, required = false,
                                 default = nil)
  if valid_617900 != nil:
    section.add "X-Amz-Signature", valid_617900
  var valid_617901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617901 = validateParameter(valid_617901, JString, required = false,
                                 default = nil)
  if valid_617901 != nil:
    section.add "X-Amz-SignedHeaders", valid_617901
  var valid_617902 = header.getOrDefault("X-Amz-Credential")
  valid_617902 = validateParameter(valid_617902, JString, required = false,
                                 default = nil)
  if valid_617902 != nil:
    section.add "X-Amz-Credential", valid_617902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617904: Call_ListImages_617891; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns the list of image build versions for the specified semantic version. 
  ## 
  let valid = call_617904.validator(path, query, header, formData, body, _)
  let scheme = call_617904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617904.url(scheme.get, call_617904.host, call_617904.base,
                         call_617904.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617904, url, valid, _)

proc call*(call_617905: Call_ListImages_617891; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listImages
  ##  Returns the list of image build versions for the specified semantic version. 
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617906 = newJObject()
  var body_617907 = newJObject()
  add(query_617906, "maxResults", newJString(maxResults))
  add(query_617906, "nextToken", newJString(nextToken))
  if body != nil:
    body_617907 = body
  result = call_617905.call(nil, query_617906, nil, nil, body_617907)

var listImages* = Call_ListImages_617891(name: "listImages",
                                      meth: HttpMethod.HttpPost,
                                      host: "imagebuilder.amazonaws.com",
                                      route: "/ListImages",
                                      validator: validate_ListImages_617892,
                                      base: "/", url: url_ListImages_617893,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInfrastructureConfigurations_617908 = ref object of OpenApiRestCall_616866
proc url_ListInfrastructureConfigurations_617910(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInfrastructureConfigurations_617909(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ##  Returns a list of infrastructure configurations. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_617911 = query.getOrDefault("maxResults")
  valid_617911 = validateParameter(valid_617911, JString, required = false,
                                 default = nil)
  if valid_617911 != nil:
    section.add "maxResults", valid_617911
  var valid_617912 = query.getOrDefault("nextToken")
  valid_617912 = validateParameter(valid_617912, JString, required = false,
                                 default = nil)
  if valid_617912 != nil:
    section.add "nextToken", valid_617912
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617913 = header.getOrDefault("X-Amz-Date")
  valid_617913 = validateParameter(valid_617913, JString, required = false,
                                 default = nil)
  if valid_617913 != nil:
    section.add "X-Amz-Date", valid_617913
  var valid_617914 = header.getOrDefault("X-Amz-Security-Token")
  valid_617914 = validateParameter(valid_617914, JString, required = false,
                                 default = nil)
  if valid_617914 != nil:
    section.add "X-Amz-Security-Token", valid_617914
  var valid_617915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617915 = validateParameter(valid_617915, JString, required = false,
                                 default = nil)
  if valid_617915 != nil:
    section.add "X-Amz-Content-Sha256", valid_617915
  var valid_617916 = header.getOrDefault("X-Amz-Algorithm")
  valid_617916 = validateParameter(valid_617916, JString, required = false,
                                 default = nil)
  if valid_617916 != nil:
    section.add "X-Amz-Algorithm", valid_617916
  var valid_617917 = header.getOrDefault("X-Amz-Signature")
  valid_617917 = validateParameter(valid_617917, JString, required = false,
                                 default = nil)
  if valid_617917 != nil:
    section.add "X-Amz-Signature", valid_617917
  var valid_617918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617918 = validateParameter(valid_617918, JString, required = false,
                                 default = nil)
  if valid_617918 != nil:
    section.add "X-Amz-SignedHeaders", valid_617918
  var valid_617919 = header.getOrDefault("X-Amz-Credential")
  valid_617919 = validateParameter(valid_617919, JString, required = false,
                                 default = nil)
  if valid_617919 != nil:
    section.add "X-Amz-Credential", valid_617919
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617921: Call_ListInfrastructureConfigurations_617908;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns a list of infrastructure configurations. 
  ## 
  let valid = call_617921.validator(path, query, header, formData, body, _)
  let scheme = call_617921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617921.url(scheme.get, call_617921.host, call_617921.base,
                         call_617921.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617921, url, valid, _)

proc call*(call_617922: Call_ListInfrastructureConfigurations_617908;
          body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listInfrastructureConfigurations
  ##  Returns a list of infrastructure configurations. 
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617923 = newJObject()
  var body_617924 = newJObject()
  add(query_617923, "maxResults", newJString(maxResults))
  add(query_617923, "nextToken", newJString(nextToken))
  if body != nil:
    body_617924 = body
  result = call_617922.call(nil, query_617923, nil, nil, body_617924)

var listInfrastructureConfigurations* = Call_ListInfrastructureConfigurations_617908(
    name: "listInfrastructureConfigurations", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com",
    route: "/ListInfrastructureConfigurations",
    validator: validate_ListInfrastructureConfigurations_617909, base: "/",
    url: url_ListInfrastructureConfigurations_617910,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_617953 = ref object of OpenApiRestCall_616866
proc url_TagResource_617955(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_617954(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ##  Adds a tag to a resource. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              :  The Amazon Resource Name (ARN) of the resource that you want to tag. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_617956 = path.getOrDefault("resourceArn")
  valid_617956 = validateParameter(valid_617956, JString, required = true,
                                 default = nil)
  if valid_617956 != nil:
    section.add "resourceArn", valid_617956
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617957 = header.getOrDefault("X-Amz-Date")
  valid_617957 = validateParameter(valid_617957, JString, required = false,
                                 default = nil)
  if valid_617957 != nil:
    section.add "X-Amz-Date", valid_617957
  var valid_617958 = header.getOrDefault("X-Amz-Security-Token")
  valid_617958 = validateParameter(valid_617958, JString, required = false,
                                 default = nil)
  if valid_617958 != nil:
    section.add "X-Amz-Security-Token", valid_617958
  var valid_617959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617959 = validateParameter(valid_617959, JString, required = false,
                                 default = nil)
  if valid_617959 != nil:
    section.add "X-Amz-Content-Sha256", valid_617959
  var valid_617960 = header.getOrDefault("X-Amz-Algorithm")
  valid_617960 = validateParameter(valid_617960, JString, required = false,
                                 default = nil)
  if valid_617960 != nil:
    section.add "X-Amz-Algorithm", valid_617960
  var valid_617961 = header.getOrDefault("X-Amz-Signature")
  valid_617961 = validateParameter(valid_617961, JString, required = false,
                                 default = nil)
  if valid_617961 != nil:
    section.add "X-Amz-Signature", valid_617961
  var valid_617962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617962 = validateParameter(valid_617962, JString, required = false,
                                 default = nil)
  if valid_617962 != nil:
    section.add "X-Amz-SignedHeaders", valid_617962
  var valid_617963 = header.getOrDefault("X-Amz-Credential")
  valid_617963 = validateParameter(valid_617963, JString, required = false,
                                 default = nil)
  if valid_617963 != nil:
    section.add "X-Amz-Credential", valid_617963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617965: Call_TagResource_617953; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Adds a tag to a resource. 
  ## 
  let valid = call_617965.validator(path, query, header, formData, body, _)
  let scheme = call_617965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617965.url(scheme.get, call_617965.host, call_617965.base,
                         call_617965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617965, url, valid, _)

proc call*(call_617966: Call_TagResource_617953; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ##  Adds a tag to a resource. 
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              :  The Amazon Resource Name (ARN) of the resource that you want to tag. 
  var path_617967 = newJObject()
  var body_617968 = newJObject()
  if body != nil:
    body_617968 = body
  add(path_617967, "resourceArn", newJString(resourceArn))
  result = call_617966.call(path_617967, nil, nil, nil, body_617968)

var tagResource* = Call_TagResource_617953(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "imagebuilder.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_617954,
                                        base: "/", url: url_TagResource_617955,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_617925 = ref object of OpenApiRestCall_616866
proc url_ListTagsForResource_617927(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_617926(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
  ##  Returns the list of tags for the specified resource. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              :  The Amazon Resource Name (ARN) of the resource whose tags you want to retrieve. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_617942 = path.getOrDefault("resourceArn")
  valid_617942 = validateParameter(valid_617942, JString, required = true,
                                 default = nil)
  if valid_617942 != nil:
    section.add "resourceArn", valid_617942
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617943 = header.getOrDefault("X-Amz-Date")
  valid_617943 = validateParameter(valid_617943, JString, required = false,
                                 default = nil)
  if valid_617943 != nil:
    section.add "X-Amz-Date", valid_617943
  var valid_617944 = header.getOrDefault("X-Amz-Security-Token")
  valid_617944 = validateParameter(valid_617944, JString, required = false,
                                 default = nil)
  if valid_617944 != nil:
    section.add "X-Amz-Security-Token", valid_617944
  var valid_617945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617945 = validateParameter(valid_617945, JString, required = false,
                                 default = nil)
  if valid_617945 != nil:
    section.add "X-Amz-Content-Sha256", valid_617945
  var valid_617946 = header.getOrDefault("X-Amz-Algorithm")
  valid_617946 = validateParameter(valid_617946, JString, required = false,
                                 default = nil)
  if valid_617946 != nil:
    section.add "X-Amz-Algorithm", valid_617946
  var valid_617947 = header.getOrDefault("X-Amz-Signature")
  valid_617947 = validateParameter(valid_617947, JString, required = false,
                                 default = nil)
  if valid_617947 != nil:
    section.add "X-Amz-Signature", valid_617947
  var valid_617948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617948 = validateParameter(valid_617948, JString, required = false,
                                 default = nil)
  if valid_617948 != nil:
    section.add "X-Amz-SignedHeaders", valid_617948
  var valid_617949 = header.getOrDefault("X-Amz-Credential")
  valid_617949 = validateParameter(valid_617949, JString, required = false,
                                 default = nil)
  if valid_617949 != nil:
    section.add "X-Amz-Credential", valid_617949
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617950: Call_ListTagsForResource_617925; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns the list of tags for the specified resource. 
  ## 
  let valid = call_617950.validator(path, query, header, formData, body, _)
  let scheme = call_617950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617950.url(scheme.get, call_617950.host, call_617950.base,
                         call_617950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617950, url, valid, _)

proc call*(call_617951: Call_ListTagsForResource_617925; resourceArn: string): Recallable =
  ## listTagsForResource
  ##  Returns the list of tags for the specified resource. 
  ##   resourceArn: string (required)
  ##              :  The Amazon Resource Name (ARN) of the resource whose tags you want to retrieve. 
  var path_617952 = newJObject()
  add(path_617952, "resourceArn", newJString(resourceArn))
  result = call_617951.call(path_617952, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_617925(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_617926, base: "/",
    url: url_ListTagsForResource_617927, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutComponentPolicy_617969 = ref object of OpenApiRestCall_616866
proc url_PutComponentPolicy_617971(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutComponentPolicy_617970(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
  ##  Applies a policy to a component. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617972 = header.getOrDefault("X-Amz-Date")
  valid_617972 = validateParameter(valid_617972, JString, required = false,
                                 default = nil)
  if valid_617972 != nil:
    section.add "X-Amz-Date", valid_617972
  var valid_617973 = header.getOrDefault("X-Amz-Security-Token")
  valid_617973 = validateParameter(valid_617973, JString, required = false,
                                 default = nil)
  if valid_617973 != nil:
    section.add "X-Amz-Security-Token", valid_617973
  var valid_617974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617974 = validateParameter(valid_617974, JString, required = false,
                                 default = nil)
  if valid_617974 != nil:
    section.add "X-Amz-Content-Sha256", valid_617974
  var valid_617975 = header.getOrDefault("X-Amz-Algorithm")
  valid_617975 = validateParameter(valid_617975, JString, required = false,
                                 default = nil)
  if valid_617975 != nil:
    section.add "X-Amz-Algorithm", valid_617975
  var valid_617976 = header.getOrDefault("X-Amz-Signature")
  valid_617976 = validateParameter(valid_617976, JString, required = false,
                                 default = nil)
  if valid_617976 != nil:
    section.add "X-Amz-Signature", valid_617976
  var valid_617977 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617977 = validateParameter(valid_617977, JString, required = false,
                                 default = nil)
  if valid_617977 != nil:
    section.add "X-Amz-SignedHeaders", valid_617977
  var valid_617978 = header.getOrDefault("X-Amz-Credential")
  valid_617978 = validateParameter(valid_617978, JString, required = false,
                                 default = nil)
  if valid_617978 != nil:
    section.add "X-Amz-Credential", valid_617978
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617980: Call_PutComponentPolicy_617969; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Applies a policy to a component. 
  ## 
  let valid = call_617980.validator(path, query, header, formData, body, _)
  let scheme = call_617980.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617980.url(scheme.get, call_617980.host, call_617980.base,
                         call_617980.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617980, url, valid, _)

proc call*(call_617981: Call_PutComponentPolicy_617969; body: JsonNode): Recallable =
  ## putComponentPolicy
  ##  Applies a policy to a component. 
  ##   body: JObject (required)
  var body_617982 = newJObject()
  if body != nil:
    body_617982 = body
  result = call_617981.call(nil, nil, nil, nil, body_617982)

var putComponentPolicy* = Call_PutComponentPolicy_617969(
    name: "putComponentPolicy", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/PutComponentPolicy",
    validator: validate_PutComponentPolicy_617970, base: "/",
    url: url_PutComponentPolicy_617971, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImagePolicy_617983 = ref object of OpenApiRestCall_616866
proc url_PutImagePolicy_617985(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutImagePolicy_617984(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
  ##  Applies a policy to an image. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617986 = header.getOrDefault("X-Amz-Date")
  valid_617986 = validateParameter(valid_617986, JString, required = false,
                                 default = nil)
  if valid_617986 != nil:
    section.add "X-Amz-Date", valid_617986
  var valid_617987 = header.getOrDefault("X-Amz-Security-Token")
  valid_617987 = validateParameter(valid_617987, JString, required = false,
                                 default = nil)
  if valid_617987 != nil:
    section.add "X-Amz-Security-Token", valid_617987
  var valid_617988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617988 = validateParameter(valid_617988, JString, required = false,
                                 default = nil)
  if valid_617988 != nil:
    section.add "X-Amz-Content-Sha256", valid_617988
  var valid_617989 = header.getOrDefault("X-Amz-Algorithm")
  valid_617989 = validateParameter(valid_617989, JString, required = false,
                                 default = nil)
  if valid_617989 != nil:
    section.add "X-Amz-Algorithm", valid_617989
  var valid_617990 = header.getOrDefault("X-Amz-Signature")
  valid_617990 = validateParameter(valid_617990, JString, required = false,
                                 default = nil)
  if valid_617990 != nil:
    section.add "X-Amz-Signature", valid_617990
  var valid_617991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617991 = validateParameter(valid_617991, JString, required = false,
                                 default = nil)
  if valid_617991 != nil:
    section.add "X-Amz-SignedHeaders", valid_617991
  var valid_617992 = header.getOrDefault("X-Amz-Credential")
  valid_617992 = validateParameter(valid_617992, JString, required = false,
                                 default = nil)
  if valid_617992 != nil:
    section.add "X-Amz-Credential", valid_617992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617994: Call_PutImagePolicy_617983; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Applies a policy to an image. 
  ## 
  let valid = call_617994.validator(path, query, header, formData, body, _)
  let scheme = call_617994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617994.url(scheme.get, call_617994.host, call_617994.base,
                         call_617994.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617994, url, valid, _)

proc call*(call_617995: Call_PutImagePolicy_617983; body: JsonNode): Recallable =
  ## putImagePolicy
  ##  Applies a policy to an image. 
  ##   body: JObject (required)
  var body_617996 = newJObject()
  if body != nil:
    body_617996 = body
  result = call_617995.call(nil, nil, nil, nil, body_617996)

var putImagePolicy* = Call_PutImagePolicy_617983(name: "putImagePolicy",
    meth: HttpMethod.HttpPut, host: "imagebuilder.amazonaws.com",
    route: "/PutImagePolicy", validator: validate_PutImagePolicy_617984, base: "/",
    url: url_PutImagePolicy_617985, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImageRecipePolicy_617997 = ref object of OpenApiRestCall_616866
proc url_PutImageRecipePolicy_617999(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutImageRecipePolicy_617998(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ##  Applies a policy to an image recipe. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618000 = header.getOrDefault("X-Amz-Date")
  valid_618000 = validateParameter(valid_618000, JString, required = false,
                                 default = nil)
  if valid_618000 != nil:
    section.add "X-Amz-Date", valid_618000
  var valid_618001 = header.getOrDefault("X-Amz-Security-Token")
  valid_618001 = validateParameter(valid_618001, JString, required = false,
                                 default = nil)
  if valid_618001 != nil:
    section.add "X-Amz-Security-Token", valid_618001
  var valid_618002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618002 = validateParameter(valid_618002, JString, required = false,
                                 default = nil)
  if valid_618002 != nil:
    section.add "X-Amz-Content-Sha256", valid_618002
  var valid_618003 = header.getOrDefault("X-Amz-Algorithm")
  valid_618003 = validateParameter(valid_618003, JString, required = false,
                                 default = nil)
  if valid_618003 != nil:
    section.add "X-Amz-Algorithm", valid_618003
  var valid_618004 = header.getOrDefault("X-Amz-Signature")
  valid_618004 = validateParameter(valid_618004, JString, required = false,
                                 default = nil)
  if valid_618004 != nil:
    section.add "X-Amz-Signature", valid_618004
  var valid_618005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618005 = validateParameter(valid_618005, JString, required = false,
                                 default = nil)
  if valid_618005 != nil:
    section.add "X-Amz-SignedHeaders", valid_618005
  var valid_618006 = header.getOrDefault("X-Amz-Credential")
  valid_618006 = validateParameter(valid_618006, JString, required = false,
                                 default = nil)
  if valid_618006 != nil:
    section.add "X-Amz-Credential", valid_618006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_618008: Call_PutImageRecipePolicy_617997; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Applies a policy to an image recipe. 
  ## 
  let valid = call_618008.validator(path, query, header, formData, body, _)
  let scheme = call_618008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618008.url(scheme.get, call_618008.host, call_618008.base,
                         call_618008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618008, url, valid, _)

proc call*(call_618009: Call_PutImageRecipePolicy_617997; body: JsonNode): Recallable =
  ## putImageRecipePolicy
  ##  Applies a policy to an image recipe. 
  ##   body: JObject (required)
  var body_618010 = newJObject()
  if body != nil:
    body_618010 = body
  result = call_618009.call(nil, nil, nil, nil, body_618010)

var putImageRecipePolicy* = Call_PutImageRecipePolicy_617997(
    name: "putImageRecipePolicy", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/PutImageRecipePolicy",
    validator: validate_PutImageRecipePolicy_617998, base: "/",
    url: url_PutImageRecipePolicy_617999, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImagePipelineExecution_618011 = ref object of OpenApiRestCall_616866
proc url_StartImagePipelineExecution_618013(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartImagePipelineExecution_618012(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ##  Manually triggers a pipeline to create an image. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618014 = header.getOrDefault("X-Amz-Date")
  valid_618014 = validateParameter(valid_618014, JString, required = false,
                                 default = nil)
  if valid_618014 != nil:
    section.add "X-Amz-Date", valid_618014
  var valid_618015 = header.getOrDefault("X-Amz-Security-Token")
  valid_618015 = validateParameter(valid_618015, JString, required = false,
                                 default = nil)
  if valid_618015 != nil:
    section.add "X-Amz-Security-Token", valid_618015
  var valid_618016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618016 = validateParameter(valid_618016, JString, required = false,
                                 default = nil)
  if valid_618016 != nil:
    section.add "X-Amz-Content-Sha256", valid_618016
  var valid_618017 = header.getOrDefault("X-Amz-Algorithm")
  valid_618017 = validateParameter(valid_618017, JString, required = false,
                                 default = nil)
  if valid_618017 != nil:
    section.add "X-Amz-Algorithm", valid_618017
  var valid_618018 = header.getOrDefault("X-Amz-Signature")
  valid_618018 = validateParameter(valid_618018, JString, required = false,
                                 default = nil)
  if valid_618018 != nil:
    section.add "X-Amz-Signature", valid_618018
  var valid_618019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618019 = validateParameter(valid_618019, JString, required = false,
                                 default = nil)
  if valid_618019 != nil:
    section.add "X-Amz-SignedHeaders", valid_618019
  var valid_618020 = header.getOrDefault("X-Amz-Credential")
  valid_618020 = validateParameter(valid_618020, JString, required = false,
                                 default = nil)
  if valid_618020 != nil:
    section.add "X-Amz-Credential", valid_618020
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_618022: Call_StartImagePipelineExecution_618011;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Manually triggers a pipeline to create an image. 
  ## 
  let valid = call_618022.validator(path, query, header, formData, body, _)
  let scheme = call_618022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618022.url(scheme.get, call_618022.host, call_618022.base,
                         call_618022.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618022, url, valid, _)

proc call*(call_618023: Call_StartImagePipelineExecution_618011; body: JsonNode): Recallable =
  ## startImagePipelineExecution
  ##  Manually triggers a pipeline to create an image. 
  ##   body: JObject (required)
  var body_618024 = newJObject()
  if body != nil:
    body_618024 = body
  result = call_618023.call(nil, nil, nil, nil, body_618024)

var startImagePipelineExecution* = Call_StartImagePipelineExecution_618011(
    name: "startImagePipelineExecution", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/StartImagePipelineExecution",
    validator: validate_StartImagePipelineExecution_618012, base: "/",
    url: url_StartImagePipelineExecution_618013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_618025 = ref object of OpenApiRestCall_616866
proc url_UntagResource_618027(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_618026(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ##  Removes a tag from a resource. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              :  The Amazon Resource Name (ARN) of the resource that you want to untag. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_618028 = path.getOrDefault("resourceArn")
  valid_618028 = validateParameter(valid_618028, JString, required = true,
                                 default = nil)
  if valid_618028 != nil:
    section.add "resourceArn", valid_618028
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          :  The tag keys to remove from the resource. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_618029 = query.getOrDefault("tagKeys")
  valid_618029 = validateParameter(valid_618029, JArray, required = true, default = nil)
  if valid_618029 != nil:
    section.add "tagKeys", valid_618029
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618030 = header.getOrDefault("X-Amz-Date")
  valid_618030 = validateParameter(valid_618030, JString, required = false,
                                 default = nil)
  if valid_618030 != nil:
    section.add "X-Amz-Date", valid_618030
  var valid_618031 = header.getOrDefault("X-Amz-Security-Token")
  valid_618031 = validateParameter(valid_618031, JString, required = false,
                                 default = nil)
  if valid_618031 != nil:
    section.add "X-Amz-Security-Token", valid_618031
  var valid_618032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618032 = validateParameter(valid_618032, JString, required = false,
                                 default = nil)
  if valid_618032 != nil:
    section.add "X-Amz-Content-Sha256", valid_618032
  var valid_618033 = header.getOrDefault("X-Amz-Algorithm")
  valid_618033 = validateParameter(valid_618033, JString, required = false,
                                 default = nil)
  if valid_618033 != nil:
    section.add "X-Amz-Algorithm", valid_618033
  var valid_618034 = header.getOrDefault("X-Amz-Signature")
  valid_618034 = validateParameter(valid_618034, JString, required = false,
                                 default = nil)
  if valid_618034 != nil:
    section.add "X-Amz-Signature", valid_618034
  var valid_618035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618035 = validateParameter(valid_618035, JString, required = false,
                                 default = nil)
  if valid_618035 != nil:
    section.add "X-Amz-SignedHeaders", valid_618035
  var valid_618036 = header.getOrDefault("X-Amz-Credential")
  valid_618036 = validateParameter(valid_618036, JString, required = false,
                                 default = nil)
  if valid_618036 != nil:
    section.add "X-Amz-Credential", valid_618036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618037: Call_UntagResource_618025; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Removes a tag from a resource. 
  ## 
  let valid = call_618037.validator(path, query, header, formData, body, _)
  let scheme = call_618037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618037.url(scheme.get, call_618037.host, call_618037.base,
                         call_618037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618037, url, valid, _)

proc call*(call_618038: Call_UntagResource_618025; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ##  Removes a tag from a resource. 
  ##   tagKeys: JArray (required)
  ##          :  The tag keys to remove from the resource. 
  ##   resourceArn: string (required)
  ##              :  The Amazon Resource Name (ARN) of the resource that you want to untag. 
  var path_618039 = newJObject()
  var query_618040 = newJObject()
  if tagKeys != nil:
    query_618040.add "tagKeys", tagKeys
  add(path_618039, "resourceArn", newJString(resourceArn))
  result = call_618038.call(path_618039, query_618040, nil, nil, nil)

var untagResource* = Call_UntagResource_618025(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "imagebuilder.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_618026,
    base: "/", url: url_UntagResource_618027, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDistributionConfiguration_618041 = ref object of OpenApiRestCall_616866
proc url_UpdateDistributionConfiguration_618043(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDistributionConfiguration_618042(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ##  Updates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618044 = header.getOrDefault("X-Amz-Date")
  valid_618044 = validateParameter(valid_618044, JString, required = false,
                                 default = nil)
  if valid_618044 != nil:
    section.add "X-Amz-Date", valid_618044
  var valid_618045 = header.getOrDefault("X-Amz-Security-Token")
  valid_618045 = validateParameter(valid_618045, JString, required = false,
                                 default = nil)
  if valid_618045 != nil:
    section.add "X-Amz-Security-Token", valid_618045
  var valid_618046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618046 = validateParameter(valid_618046, JString, required = false,
                                 default = nil)
  if valid_618046 != nil:
    section.add "X-Amz-Content-Sha256", valid_618046
  var valid_618047 = header.getOrDefault("X-Amz-Algorithm")
  valid_618047 = validateParameter(valid_618047, JString, required = false,
                                 default = nil)
  if valid_618047 != nil:
    section.add "X-Amz-Algorithm", valid_618047
  var valid_618048 = header.getOrDefault("X-Amz-Signature")
  valid_618048 = validateParameter(valid_618048, JString, required = false,
                                 default = nil)
  if valid_618048 != nil:
    section.add "X-Amz-Signature", valid_618048
  var valid_618049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618049 = validateParameter(valid_618049, JString, required = false,
                                 default = nil)
  if valid_618049 != nil:
    section.add "X-Amz-SignedHeaders", valid_618049
  var valid_618050 = header.getOrDefault("X-Amz-Credential")
  valid_618050 = validateParameter(valid_618050, JString, required = false,
                                 default = nil)
  if valid_618050 != nil:
    section.add "X-Amz-Credential", valid_618050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_618052: Call_UpdateDistributionConfiguration_618041;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Updates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ## 
  let valid = call_618052.validator(path, query, header, formData, body, _)
  let scheme = call_618052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618052.url(scheme.get, call_618052.host, call_618052.base,
                         call_618052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618052, url, valid, _)

proc call*(call_618053: Call_UpdateDistributionConfiguration_618041; body: JsonNode): Recallable =
  ## updateDistributionConfiguration
  ##  Updates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ##   body: JObject (required)
  var body_618054 = newJObject()
  if body != nil:
    body_618054 = body
  result = call_618053.call(nil, nil, nil, nil, body_618054)

var updateDistributionConfiguration* = Call_UpdateDistributionConfiguration_618041(
    name: "updateDistributionConfiguration", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/UpdateDistributionConfiguration",
    validator: validate_UpdateDistributionConfiguration_618042, base: "/",
    url: url_UpdateDistributionConfiguration_618043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateImagePipeline_618055 = ref object of OpenApiRestCall_616866
proc url_UpdateImagePipeline_618057(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateImagePipeline_618056(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
  ##  Updates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618058 = header.getOrDefault("X-Amz-Date")
  valid_618058 = validateParameter(valid_618058, JString, required = false,
                                 default = nil)
  if valid_618058 != nil:
    section.add "X-Amz-Date", valid_618058
  var valid_618059 = header.getOrDefault("X-Amz-Security-Token")
  valid_618059 = validateParameter(valid_618059, JString, required = false,
                                 default = nil)
  if valid_618059 != nil:
    section.add "X-Amz-Security-Token", valid_618059
  var valid_618060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618060 = validateParameter(valid_618060, JString, required = false,
                                 default = nil)
  if valid_618060 != nil:
    section.add "X-Amz-Content-Sha256", valid_618060
  var valid_618061 = header.getOrDefault("X-Amz-Algorithm")
  valid_618061 = validateParameter(valid_618061, JString, required = false,
                                 default = nil)
  if valid_618061 != nil:
    section.add "X-Amz-Algorithm", valid_618061
  var valid_618062 = header.getOrDefault("X-Amz-Signature")
  valid_618062 = validateParameter(valid_618062, JString, required = false,
                                 default = nil)
  if valid_618062 != nil:
    section.add "X-Amz-Signature", valid_618062
  var valid_618063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618063 = validateParameter(valid_618063, JString, required = false,
                                 default = nil)
  if valid_618063 != nil:
    section.add "X-Amz-SignedHeaders", valid_618063
  var valid_618064 = header.getOrDefault("X-Amz-Credential")
  valid_618064 = validateParameter(valid_618064, JString, required = false,
                                 default = nil)
  if valid_618064 != nil:
    section.add "X-Amz-Credential", valid_618064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_618066: Call_UpdateImagePipeline_618055; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Updates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ## 
  let valid = call_618066.validator(path, query, header, formData, body, _)
  let scheme = call_618066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618066.url(scheme.get, call_618066.host, call_618066.base,
                         call_618066.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618066, url, valid, _)

proc call*(call_618067: Call_UpdateImagePipeline_618055; body: JsonNode): Recallable =
  ## updateImagePipeline
  ##  Updates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ##   body: JObject (required)
  var body_618068 = newJObject()
  if body != nil:
    body_618068 = body
  result = call_618067.call(nil, nil, nil, nil, body_618068)

var updateImagePipeline* = Call_UpdateImagePipeline_618055(
    name: "updateImagePipeline", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/UpdateImagePipeline",
    validator: validate_UpdateImagePipeline_618056, base: "/",
    url: url_UpdateImagePipeline_618057, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInfrastructureConfiguration_618069 = ref object of OpenApiRestCall_616866
proc url_UpdateInfrastructureConfiguration_618071(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateInfrastructureConfiguration_618070(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ##  Updates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618072 = header.getOrDefault("X-Amz-Date")
  valid_618072 = validateParameter(valid_618072, JString, required = false,
                                 default = nil)
  if valid_618072 != nil:
    section.add "X-Amz-Date", valid_618072
  var valid_618073 = header.getOrDefault("X-Amz-Security-Token")
  valid_618073 = validateParameter(valid_618073, JString, required = false,
                                 default = nil)
  if valid_618073 != nil:
    section.add "X-Amz-Security-Token", valid_618073
  var valid_618074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618074 = validateParameter(valid_618074, JString, required = false,
                                 default = nil)
  if valid_618074 != nil:
    section.add "X-Amz-Content-Sha256", valid_618074
  var valid_618075 = header.getOrDefault("X-Amz-Algorithm")
  valid_618075 = validateParameter(valid_618075, JString, required = false,
                                 default = nil)
  if valid_618075 != nil:
    section.add "X-Amz-Algorithm", valid_618075
  var valid_618076 = header.getOrDefault("X-Amz-Signature")
  valid_618076 = validateParameter(valid_618076, JString, required = false,
                                 default = nil)
  if valid_618076 != nil:
    section.add "X-Amz-Signature", valid_618076
  var valid_618077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618077 = validateParameter(valid_618077, JString, required = false,
                                 default = nil)
  if valid_618077 != nil:
    section.add "X-Amz-SignedHeaders", valid_618077
  var valid_618078 = header.getOrDefault("X-Amz-Credential")
  valid_618078 = validateParameter(valid_618078, JString, required = false,
                                 default = nil)
  if valid_618078 != nil:
    section.add "X-Amz-Credential", valid_618078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_618080: Call_UpdateInfrastructureConfiguration_618069;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Updates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ## 
  let valid = call_618080.validator(path, query, header, formData, body, _)
  let scheme = call_618080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618080.url(scheme.get, call_618080.host, call_618080.base,
                         call_618080.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618080, url, valid, _)

proc call*(call_618081: Call_UpdateInfrastructureConfiguration_618069;
          body: JsonNode): Recallable =
  ## updateInfrastructureConfiguration
  ##  Updates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ##   body: JObject (required)
  var body_618082 = newJObject()
  if body != nil:
    body_618082 = body
  result = call_618081.call(nil, nil, nil, nil, body_618082)

var updateInfrastructureConfiguration* = Call_UpdateInfrastructureConfiguration_618069(
    name: "updateInfrastructureConfiguration", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com",
    route: "/UpdateInfrastructureConfiguration",
    validator: validate_UpdateInfrastructureConfiguration_618070, base: "/",
    url: url_UpdateInfrastructureConfiguration_618071,
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = $text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
