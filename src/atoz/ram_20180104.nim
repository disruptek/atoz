
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Resource Access Manager
## version: 2018-01-04
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Use AWS Resource Access Manager to share AWS resources between AWS accounts. To share a resource, you create a resource share, associate the resource with the resource share, and specify the principals that can access the resources associated with the resource share. The following principals are supported: AWS accounts, organizational units (OU) from AWS Organizations, and organizations from AWS Organizations.</p> <p>For more information, see the <a href="https://docs.aws.amazon.com/ram/latest/userguide/">AWS Resource Access Manager User Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/ram/
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
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
    if required:
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "ram.ap-northeast-1.amazonaws.com", "ap-southeast-1": "ram.ap-southeast-1.amazonaws.com",
                           "us-west-2": "ram.us-west-2.amazonaws.com",
                           "eu-west-2": "ram.eu-west-2.amazonaws.com", "ap-northeast-3": "ram.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "ram.eu-central-1.amazonaws.com",
                           "us-east-2": "ram.us-east-2.amazonaws.com",
                           "us-east-1": "ram.us-east-1.amazonaws.com", "cn-northwest-1": "ram.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "ram.ap-south-1.amazonaws.com",
                           "eu-north-1": "ram.eu-north-1.amazonaws.com", "ap-northeast-2": "ram.ap-northeast-2.amazonaws.com",
                           "us-west-1": "ram.us-west-1.amazonaws.com",
                           "us-gov-east-1": "ram.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "ram.eu-west-3.amazonaws.com",
                           "cn-north-1": "ram.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "ram.sa-east-1.amazonaws.com",
                           "eu-west-1": "ram.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "ram.us-gov-west-1.amazonaws.com", "ap-southeast-2": "ram.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "ram.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "ram.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "ram.ap-southeast-1.amazonaws.com",
      "us-west-2": "ram.us-west-2.amazonaws.com",
      "eu-west-2": "ram.eu-west-2.amazonaws.com",
      "ap-northeast-3": "ram.ap-northeast-3.amazonaws.com",
      "eu-central-1": "ram.eu-central-1.amazonaws.com",
      "us-east-2": "ram.us-east-2.amazonaws.com",
      "us-east-1": "ram.us-east-1.amazonaws.com",
      "cn-northwest-1": "ram.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "ram.ap-south-1.amazonaws.com",
      "eu-north-1": "ram.eu-north-1.amazonaws.com",
      "ap-northeast-2": "ram.ap-northeast-2.amazonaws.com",
      "us-west-1": "ram.us-west-1.amazonaws.com",
      "us-gov-east-1": "ram.us-gov-east-1.amazonaws.com",
      "eu-west-3": "ram.eu-west-3.amazonaws.com",
      "cn-north-1": "ram.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "ram.sa-east-1.amazonaws.com",
      "eu-west-1": "ram.eu-west-1.amazonaws.com",
      "us-gov-west-1": "ram.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "ram.ap-southeast-2.amazonaws.com",
      "ca-central-1": "ram.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "ram"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AcceptResourceShareInvitation_21625779 = ref object of OpenApiRestCall_21625435
proc url_AcceptResourceShareInvitation_21625781(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcceptResourceShareInvitation_21625780(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Accepts an invitation to a resource share from another AWS account.
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
  var valid_21625882 = header.getOrDefault("X-Amz-Date")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Date", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Security-Token", valid_21625883
  var valid_21625884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625884
  var valid_21625885 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "X-Amz-Algorithm", valid_21625885
  var valid_21625886 = header.getOrDefault("X-Amz-Signature")
  valid_21625886 = validateParameter(valid_21625886, JString, required = false,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "X-Amz-Signature", valid_21625886
  var valid_21625887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625887 = validateParameter(valid_21625887, JString, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625887
  var valid_21625888 = header.getOrDefault("X-Amz-Credential")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-Credential", valid_21625888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21625914: Call_AcceptResourceShareInvitation_21625779;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Accepts an invitation to a resource share from another AWS account.
  ## 
  let valid = call_21625914.validator(path, query, header, formData, body, _)
  let scheme = call_21625914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625914.makeUrl(scheme.get, call_21625914.host, call_21625914.base,
                               call_21625914.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625914, uri, valid, _)

proc call*(call_21625977: Call_AcceptResourceShareInvitation_21625779;
          body: JsonNode): Recallable =
  ## acceptResourceShareInvitation
  ## Accepts an invitation to a resource share from another AWS account.
  ##   body: JObject (required)
  var body_21625978 = newJObject()
  if body != nil:
    body_21625978 = body
  result = call_21625977.call(nil, nil, nil, nil, body_21625978)

var acceptResourceShareInvitation* = Call_AcceptResourceShareInvitation_21625779(
    name: "acceptResourceShareInvitation", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/acceptresourceshareinvitation",
    validator: validate_AcceptResourceShareInvitation_21625780, base: "/",
    makeUrl: url_AcceptResourceShareInvitation_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateResourceShare_21626014 = ref object of OpenApiRestCall_21625435
proc url_AssociateResourceShare_21626016(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateResourceShare_21626015(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Associates the specified resource share with the specified principals and resources.
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
  var valid_21626017 = header.getOrDefault("X-Amz-Date")
  valid_21626017 = validateParameter(valid_21626017, JString, required = false,
                                   default = nil)
  if valid_21626017 != nil:
    section.add "X-Amz-Date", valid_21626017
  var valid_21626018 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626018 = validateParameter(valid_21626018, JString, required = false,
                                   default = nil)
  if valid_21626018 != nil:
    section.add "X-Amz-Security-Token", valid_21626018
  var valid_21626019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626019 = validateParameter(valid_21626019, JString, required = false,
                                   default = nil)
  if valid_21626019 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626019
  var valid_21626020 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626020 = validateParameter(valid_21626020, JString, required = false,
                                   default = nil)
  if valid_21626020 != nil:
    section.add "X-Amz-Algorithm", valid_21626020
  var valid_21626021 = header.getOrDefault("X-Amz-Signature")
  valid_21626021 = validateParameter(valid_21626021, JString, required = false,
                                   default = nil)
  if valid_21626021 != nil:
    section.add "X-Amz-Signature", valid_21626021
  var valid_21626022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626022 = validateParameter(valid_21626022, JString, required = false,
                                   default = nil)
  if valid_21626022 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626022
  var valid_21626023 = header.getOrDefault("X-Amz-Credential")
  valid_21626023 = validateParameter(valid_21626023, JString, required = false,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "X-Amz-Credential", valid_21626023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626025: Call_AssociateResourceShare_21626014;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates the specified resource share with the specified principals and resources.
  ## 
  let valid = call_21626025.validator(path, query, header, formData, body, _)
  let scheme = call_21626025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626025.makeUrl(scheme.get, call_21626025.host, call_21626025.base,
                               call_21626025.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626025, uri, valid, _)

proc call*(call_21626026: Call_AssociateResourceShare_21626014; body: JsonNode): Recallable =
  ## associateResourceShare
  ## Associates the specified resource share with the specified principals and resources.
  ##   body: JObject (required)
  var body_21626027 = newJObject()
  if body != nil:
    body_21626027 = body
  result = call_21626026.call(nil, nil, nil, nil, body_21626027)

var associateResourceShare* = Call_AssociateResourceShare_21626014(
    name: "associateResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/associateresourceshare",
    validator: validate_AssociateResourceShare_21626015, base: "/",
    makeUrl: url_AssociateResourceShare_21626016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateResourceSharePermission_21626028 = ref object of OpenApiRestCall_21625435
proc url_AssociateResourceSharePermission_21626030(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateResourceSharePermission_21626029(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Associates a permission with a resource share.
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
  var valid_21626031 = header.getOrDefault("X-Amz-Date")
  valid_21626031 = validateParameter(valid_21626031, JString, required = false,
                                   default = nil)
  if valid_21626031 != nil:
    section.add "X-Amz-Date", valid_21626031
  var valid_21626032 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Security-Token", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626034 = validateParameter(valid_21626034, JString, required = false,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "X-Amz-Algorithm", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Signature")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Signature", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Credential")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Credential", valid_21626037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626039: Call_AssociateResourceSharePermission_21626028;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a permission with a resource share.
  ## 
  let valid = call_21626039.validator(path, query, header, formData, body, _)
  let scheme = call_21626039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626039.makeUrl(scheme.get, call_21626039.host, call_21626039.base,
                               call_21626039.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626039, uri, valid, _)

proc call*(call_21626040: Call_AssociateResourceSharePermission_21626028;
          body: JsonNode): Recallable =
  ## associateResourceSharePermission
  ## Associates a permission with a resource share.
  ##   body: JObject (required)
  var body_21626041 = newJObject()
  if body != nil:
    body_21626041 = body
  result = call_21626040.call(nil, nil, nil, nil, body_21626041)

var associateResourceSharePermission* = Call_AssociateResourceSharePermission_21626028(
    name: "associateResourceSharePermission", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/associateresourcesharepermission",
    validator: validate_AssociateResourceSharePermission_21626029, base: "/",
    makeUrl: url_AssociateResourceSharePermission_21626030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceShare_21626042 = ref object of OpenApiRestCall_21625435
proc url_CreateResourceShare_21626044(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateResourceShare_21626043(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a resource share.
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
  var valid_21626045 = header.getOrDefault("X-Amz-Date")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Date", valid_21626045
  var valid_21626046 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "X-Amz-Security-Token", valid_21626046
  var valid_21626047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Algorithm", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Signature")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-Signature", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Credential")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Credential", valid_21626051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626053: Call_CreateResourceShare_21626042; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a resource share.
  ## 
  let valid = call_21626053.validator(path, query, header, formData, body, _)
  let scheme = call_21626053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626053.makeUrl(scheme.get, call_21626053.host, call_21626053.base,
                               call_21626053.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626053, uri, valid, _)

proc call*(call_21626054: Call_CreateResourceShare_21626042; body: JsonNode): Recallable =
  ## createResourceShare
  ## Creates a resource share.
  ##   body: JObject (required)
  var body_21626055 = newJObject()
  if body != nil:
    body_21626055 = body
  result = call_21626054.call(nil, nil, nil, nil, body_21626055)

var createResourceShare* = Call_CreateResourceShare_21626042(
    name: "createResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/createresourceshare",
    validator: validate_CreateResourceShare_21626043, base: "/",
    makeUrl: url_CreateResourceShare_21626044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceShare_21626056 = ref object of OpenApiRestCall_21625435
proc url_DeleteResourceShare_21626058(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteResourceShare_21626057(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified resource share.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceShareArn: JString (required)
  ##                   : The Amazon Resource Name (ARN) of the resource share.
  ##   clientToken: JString
  ##              : A unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `resourceShareArn` field"
  var valid_21626059 = query.getOrDefault("resourceShareArn")
  valid_21626059 = validateParameter(valid_21626059, JString, required = true,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "resourceShareArn", valid_21626059
  var valid_21626060 = query.getOrDefault("clientToken")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "clientToken", valid_21626060
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
  var valid_21626061 = header.getOrDefault("X-Amz-Date")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-Date", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Security-Token", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Algorithm", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Signature")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Signature", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Credential")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Credential", valid_21626067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626068: Call_DeleteResourceShare_21626056; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified resource share.
  ## 
  let valid = call_21626068.validator(path, query, header, formData, body, _)
  let scheme = call_21626068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626068.makeUrl(scheme.get, call_21626068.host, call_21626068.base,
                               call_21626068.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626068, uri, valid, _)

proc call*(call_21626069: Call_DeleteResourceShare_21626056;
          resourceShareArn: string; clientToken: string = ""): Recallable =
  ## deleteResourceShare
  ## Deletes the specified resource share.
  ##   resourceShareArn: string (required)
  ##                   : The Amazon Resource Name (ARN) of the resource share.
  ##   clientToken: string
  ##              : A unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  var query_21626071 = newJObject()
  add(query_21626071, "resourceShareArn", newJString(resourceShareArn))
  add(query_21626071, "clientToken", newJString(clientToken))
  result = call_21626069.call(nil, query_21626071, nil, nil, nil)

var deleteResourceShare* = Call_DeleteResourceShare_21626056(
    name: "deleteResourceShare", meth: HttpMethod.HttpDelete,
    host: "ram.amazonaws.com", route: "/deleteresourceshare#resourceShareArn",
    validator: validate_DeleteResourceShare_21626057, base: "/",
    makeUrl: url_DeleteResourceShare_21626058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateResourceShare_21626075 = ref object of OpenApiRestCall_21625435
proc url_DisassociateResourceShare_21626077(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateResourceShare_21626076(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Disassociates the specified principals or resources from the specified resource share.
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
  var valid_21626078 = header.getOrDefault("X-Amz-Date")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Date", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Security-Token", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Algorithm", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Signature")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Signature", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Credential")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Credential", valid_21626084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626086: Call_DisassociateResourceShare_21626075;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates the specified principals or resources from the specified resource share.
  ## 
  let valid = call_21626086.validator(path, query, header, formData, body, _)
  let scheme = call_21626086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626086.makeUrl(scheme.get, call_21626086.host, call_21626086.base,
                               call_21626086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626086, uri, valid, _)

proc call*(call_21626087: Call_DisassociateResourceShare_21626075; body: JsonNode): Recallable =
  ## disassociateResourceShare
  ## Disassociates the specified principals or resources from the specified resource share.
  ##   body: JObject (required)
  var body_21626088 = newJObject()
  if body != nil:
    body_21626088 = body
  result = call_21626087.call(nil, nil, nil, nil, body_21626088)

var disassociateResourceShare* = Call_DisassociateResourceShare_21626075(
    name: "disassociateResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/disassociateresourceshare",
    validator: validate_DisassociateResourceShare_21626076, base: "/",
    makeUrl: url_DisassociateResourceShare_21626077,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateResourceSharePermission_21626089 = ref object of OpenApiRestCall_21625435
proc url_DisassociateResourceSharePermission_21626091(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateResourceSharePermission_21626090(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Disassociates an AWS RAM permission from a resource share.
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
  var valid_21626092 = header.getOrDefault("X-Amz-Date")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Date", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Security-Token", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Algorithm", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Signature")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Signature", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-Credential")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Credential", valid_21626098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626100: Call_DisassociateResourceSharePermission_21626089;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates an AWS RAM permission from a resource share.
  ## 
  let valid = call_21626100.validator(path, query, header, formData, body, _)
  let scheme = call_21626100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626100.makeUrl(scheme.get, call_21626100.host, call_21626100.base,
                               call_21626100.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626100, uri, valid, _)

proc call*(call_21626101: Call_DisassociateResourceSharePermission_21626089;
          body: JsonNode): Recallable =
  ## disassociateResourceSharePermission
  ## Disassociates an AWS RAM permission from a resource share.
  ##   body: JObject (required)
  var body_21626102 = newJObject()
  if body != nil:
    body_21626102 = body
  result = call_21626101.call(nil, nil, nil, nil, body_21626102)

var disassociateResourceSharePermission* = Call_DisassociateResourceSharePermission_21626089(
    name: "disassociateResourceSharePermission", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/disassociateresourcesharepermission",
    validator: validate_DisassociateResourceSharePermission_21626090, base: "/",
    makeUrl: url_DisassociateResourceSharePermission_21626091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableSharingWithAwsOrganization_21626103 = ref object of OpenApiRestCall_21625435
proc url_EnableSharingWithAwsOrganization_21626105(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableSharingWithAwsOrganization_21626104(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Enables resource sharing within your AWS Organization.</p> <p>The caller must be the master account for the AWS Organization.</p>
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
  var valid_21626106 = header.getOrDefault("X-Amz-Date")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-Date", valid_21626106
  var valid_21626107 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Security-Token", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626109 = validateParameter(valid_21626109, JString, required = false,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "X-Amz-Algorithm", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Signature")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Signature", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Credential")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Credential", valid_21626112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626113: Call_EnableSharingWithAwsOrganization_21626103;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Enables resource sharing within your AWS Organization.</p> <p>The caller must be the master account for the AWS Organization.</p>
  ## 
  let valid = call_21626113.validator(path, query, header, formData, body, _)
  let scheme = call_21626113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626113.makeUrl(scheme.get, call_21626113.host, call_21626113.base,
                               call_21626113.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626113, uri, valid, _)

proc call*(call_21626114: Call_EnableSharingWithAwsOrganization_21626103): Recallable =
  ## enableSharingWithAwsOrganization
  ## <p>Enables resource sharing within your AWS Organization.</p> <p>The caller must be the master account for the AWS Organization.</p>
  result = call_21626114.call(nil, nil, nil, nil, nil)

var enableSharingWithAwsOrganization* = Call_EnableSharingWithAwsOrganization_21626103(
    name: "enableSharingWithAwsOrganization", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/enablesharingwithawsorganization",
    validator: validate_EnableSharingWithAwsOrganization_21626104, base: "/",
    makeUrl: url_EnableSharingWithAwsOrganization_21626105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPermission_21626115 = ref object of OpenApiRestCall_21625435
proc url_GetPermission_21626117(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPermission_21626116(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Gets the contents of an AWS RAM permission in JSON format.
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
  var valid_21626118 = header.getOrDefault("X-Amz-Date")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Date", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-Security-Token", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Algorithm", valid_21626121
  var valid_21626122 = header.getOrDefault("X-Amz-Signature")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Signature", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Credential")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Credential", valid_21626124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626126: Call_GetPermission_21626115; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the contents of an AWS RAM permission in JSON format.
  ## 
  let valid = call_21626126.validator(path, query, header, formData, body, _)
  let scheme = call_21626126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626126.makeUrl(scheme.get, call_21626126.host, call_21626126.base,
                               call_21626126.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626126, uri, valid, _)

proc call*(call_21626127: Call_GetPermission_21626115; body: JsonNode): Recallable =
  ## getPermission
  ## Gets the contents of an AWS RAM permission in JSON format.
  ##   body: JObject (required)
  var body_21626128 = newJObject()
  if body != nil:
    body_21626128 = body
  result = call_21626127.call(nil, nil, nil, nil, body_21626128)

var getPermission* = Call_GetPermission_21626115(name: "getPermission",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/getpermission",
    validator: validate_GetPermission_21626116, base: "/",
    makeUrl: url_GetPermission_21626117, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicies_21626129 = ref object of OpenApiRestCall_21625435
proc url_GetResourcePolicies_21626131(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResourcePolicies_21626130(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the policies for the specified resources that you own and have shared.
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
  var valid_21626132 = query.getOrDefault("maxResults")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "maxResults", valid_21626132
  var valid_21626133 = query.getOrDefault("nextToken")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "nextToken", valid_21626133
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
  var valid_21626134 = header.getOrDefault("X-Amz-Date")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-Date", valid_21626134
  var valid_21626135 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Security-Token", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Algorithm", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Signature")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Signature", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Credential")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Credential", valid_21626140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626142: Call_GetResourcePolicies_21626129; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the policies for the specified resources that you own and have shared.
  ## 
  let valid = call_21626142.validator(path, query, header, formData, body, _)
  let scheme = call_21626142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626142.makeUrl(scheme.get, call_21626142.host, call_21626142.base,
                               call_21626142.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626142, uri, valid, _)

proc call*(call_21626143: Call_GetResourcePolicies_21626129; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getResourcePolicies
  ## Gets the policies for the specified resources that you own and have shared.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626144 = newJObject()
  var body_21626145 = newJObject()
  add(query_21626144, "maxResults", newJString(maxResults))
  add(query_21626144, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626145 = body
  result = call_21626143.call(nil, query_21626144, nil, nil, body_21626145)

var getResourcePolicies* = Call_GetResourcePolicies_21626129(
    name: "getResourcePolicies", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourcepolicies",
    validator: validate_GetResourcePolicies_21626130, base: "/",
    makeUrl: url_GetResourcePolicies_21626131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceShareAssociations_21626146 = ref object of OpenApiRestCall_21625435
proc url_GetResourceShareAssociations_21626148(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResourceShareAssociations_21626147(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Gets the resources or principals for the resource shares that you own.
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
  var valid_21626149 = query.getOrDefault("maxResults")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "maxResults", valid_21626149
  var valid_21626150 = query.getOrDefault("nextToken")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "nextToken", valid_21626150
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
  var valid_21626151 = header.getOrDefault("X-Amz-Date")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Date", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Security-Token", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Algorithm", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Signature")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Signature", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Credential")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Credential", valid_21626157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626159: Call_GetResourceShareAssociations_21626146;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the resources or principals for the resource shares that you own.
  ## 
  let valid = call_21626159.validator(path, query, header, formData, body, _)
  let scheme = call_21626159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626159.makeUrl(scheme.get, call_21626159.host, call_21626159.base,
                               call_21626159.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626159, uri, valid, _)

proc call*(call_21626160: Call_GetResourceShareAssociations_21626146;
          body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getResourceShareAssociations
  ## Gets the resources or principals for the resource shares that you own.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626161 = newJObject()
  var body_21626162 = newJObject()
  add(query_21626161, "maxResults", newJString(maxResults))
  add(query_21626161, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626162 = body
  result = call_21626160.call(nil, query_21626161, nil, nil, body_21626162)

var getResourceShareAssociations* = Call_GetResourceShareAssociations_21626146(
    name: "getResourceShareAssociations", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourceshareassociations",
    validator: validate_GetResourceShareAssociations_21626147, base: "/",
    makeUrl: url_GetResourceShareAssociations_21626148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceShareInvitations_21626163 = ref object of OpenApiRestCall_21625435
proc url_GetResourceShareInvitations_21626165(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResourceShareInvitations_21626164(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the invitations for resource sharing that you've received.
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
  var valid_21626166 = query.getOrDefault("maxResults")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "maxResults", valid_21626166
  var valid_21626167 = query.getOrDefault("nextToken")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "nextToken", valid_21626167
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
  var valid_21626168 = header.getOrDefault("X-Amz-Date")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Date", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Security-Token", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Algorithm", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Signature")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Signature", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Credential")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Credential", valid_21626174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626176: Call_GetResourceShareInvitations_21626163;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the invitations for resource sharing that you've received.
  ## 
  let valid = call_21626176.validator(path, query, header, formData, body, _)
  let scheme = call_21626176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626176.makeUrl(scheme.get, call_21626176.host, call_21626176.base,
                               call_21626176.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626176, uri, valid, _)

proc call*(call_21626177: Call_GetResourceShareInvitations_21626163;
          body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getResourceShareInvitations
  ## Gets the invitations for resource sharing that you've received.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626178 = newJObject()
  var body_21626179 = newJObject()
  add(query_21626178, "maxResults", newJString(maxResults))
  add(query_21626178, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626179 = body
  result = call_21626177.call(nil, query_21626178, nil, nil, body_21626179)

var getResourceShareInvitations* = Call_GetResourceShareInvitations_21626163(
    name: "getResourceShareInvitations", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourceshareinvitations",
    validator: validate_GetResourceShareInvitations_21626164, base: "/",
    makeUrl: url_GetResourceShareInvitations_21626165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceShares_21626180 = ref object of OpenApiRestCall_21625435
proc url_GetResourceShares_21626182(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResourceShares_21626181(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the resource shares that you own or the resource shares that are shared with you.
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
  var valid_21626183 = query.getOrDefault("maxResults")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "maxResults", valid_21626183
  var valid_21626184 = query.getOrDefault("nextToken")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "nextToken", valid_21626184
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
  var valid_21626185 = header.getOrDefault("X-Amz-Date")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Date", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Security-Token", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-Algorithm", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Signature")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Signature", valid_21626189
  var valid_21626190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626190
  var valid_21626191 = header.getOrDefault("X-Amz-Credential")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-Credential", valid_21626191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626193: Call_GetResourceShares_21626180; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the resource shares that you own or the resource shares that are shared with you.
  ## 
  let valid = call_21626193.validator(path, query, header, formData, body, _)
  let scheme = call_21626193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626193.makeUrl(scheme.get, call_21626193.host, call_21626193.base,
                               call_21626193.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626193, uri, valid, _)

proc call*(call_21626194: Call_GetResourceShares_21626180; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getResourceShares
  ## Gets the resource shares that you own or the resource shares that are shared with you.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626195 = newJObject()
  var body_21626196 = newJObject()
  add(query_21626195, "maxResults", newJString(maxResults))
  add(query_21626195, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626196 = body
  result = call_21626194.call(nil, query_21626195, nil, nil, body_21626196)

var getResourceShares* = Call_GetResourceShares_21626180(name: "getResourceShares",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com",
    route: "/getresourceshares", validator: validate_GetResourceShares_21626181,
    base: "/", makeUrl: url_GetResourceShares_21626182,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPendingInvitationResources_21626197 = ref object of OpenApiRestCall_21625435
proc url_ListPendingInvitationResources_21626199(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPendingInvitationResources_21626198(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists the resources in a resource share that is shared with you but that the invitation is still pending for.
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
  var valid_21626200 = query.getOrDefault("maxResults")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "maxResults", valid_21626200
  var valid_21626201 = query.getOrDefault("nextToken")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "nextToken", valid_21626201
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
  var valid_21626202 = header.getOrDefault("X-Amz-Date")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Date", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-Security-Token", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626204
  var valid_21626205 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626205 = validateParameter(valid_21626205, JString, required = false,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "X-Amz-Algorithm", valid_21626205
  var valid_21626206 = header.getOrDefault("X-Amz-Signature")
  valid_21626206 = validateParameter(valid_21626206, JString, required = false,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "X-Amz-Signature", valid_21626206
  var valid_21626207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626207
  var valid_21626208 = header.getOrDefault("X-Amz-Credential")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "X-Amz-Credential", valid_21626208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626210: Call_ListPendingInvitationResources_21626197;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the resources in a resource share that is shared with you but that the invitation is still pending for.
  ## 
  let valid = call_21626210.validator(path, query, header, formData, body, _)
  let scheme = call_21626210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626210.makeUrl(scheme.get, call_21626210.host, call_21626210.base,
                               call_21626210.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626210, uri, valid, _)

proc call*(call_21626211: Call_ListPendingInvitationResources_21626197;
          body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listPendingInvitationResources
  ## Lists the resources in a resource share that is shared with you but that the invitation is still pending for.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626212 = newJObject()
  var body_21626213 = newJObject()
  add(query_21626212, "maxResults", newJString(maxResults))
  add(query_21626212, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626213 = body
  result = call_21626211.call(nil, query_21626212, nil, nil, body_21626213)

var listPendingInvitationResources* = Call_ListPendingInvitationResources_21626197(
    name: "listPendingInvitationResources", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/listpendinginvitationresources",
    validator: validate_ListPendingInvitationResources_21626198, base: "/",
    makeUrl: url_ListPendingInvitationResources_21626199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPermissions_21626214 = ref object of OpenApiRestCall_21625435
proc url_ListPermissions_21626216(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPermissions_21626215(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the AWS RAM permissions.
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
  var valid_21626217 = header.getOrDefault("X-Amz-Date")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Date", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-Security-Token", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626219
  var valid_21626220 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626220 = validateParameter(valid_21626220, JString, required = false,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "X-Amz-Algorithm", valid_21626220
  var valid_21626221 = header.getOrDefault("X-Amz-Signature")
  valid_21626221 = validateParameter(valid_21626221, JString, required = false,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "X-Amz-Signature", valid_21626221
  var valid_21626222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626222 = validateParameter(valid_21626222, JString, required = false,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626222
  var valid_21626223 = header.getOrDefault("X-Amz-Credential")
  valid_21626223 = validateParameter(valid_21626223, JString, required = false,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "X-Amz-Credential", valid_21626223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626225: Call_ListPermissions_21626214; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the AWS RAM permissions.
  ## 
  let valid = call_21626225.validator(path, query, header, formData, body, _)
  let scheme = call_21626225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626225.makeUrl(scheme.get, call_21626225.host, call_21626225.base,
                               call_21626225.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626225, uri, valid, _)

proc call*(call_21626226: Call_ListPermissions_21626214; body: JsonNode): Recallable =
  ## listPermissions
  ## Lists the AWS RAM permissions.
  ##   body: JObject (required)
  var body_21626227 = newJObject()
  if body != nil:
    body_21626227 = body
  result = call_21626226.call(nil, nil, nil, nil, body_21626227)

var listPermissions* = Call_ListPermissions_21626214(name: "listPermissions",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/listpermissions",
    validator: validate_ListPermissions_21626215, base: "/",
    makeUrl: url_ListPermissions_21626216, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPrincipals_21626228 = ref object of OpenApiRestCall_21625435
proc url_ListPrincipals_21626230(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPrincipals_21626229(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the principals that you have shared resources with or that have shared resources with you.
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
  var valid_21626231 = query.getOrDefault("maxResults")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "maxResults", valid_21626231
  var valid_21626232 = query.getOrDefault("nextToken")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "nextToken", valid_21626232
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
  var valid_21626233 = header.getOrDefault("X-Amz-Date")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Date", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Security-Token", valid_21626234
  var valid_21626235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626235
  var valid_21626236 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626236 = validateParameter(valid_21626236, JString, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "X-Amz-Algorithm", valid_21626236
  var valid_21626237 = header.getOrDefault("X-Amz-Signature")
  valid_21626237 = validateParameter(valid_21626237, JString, required = false,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "X-Amz-Signature", valid_21626237
  var valid_21626238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626238 = validateParameter(valid_21626238, JString, required = false,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626238
  var valid_21626239 = header.getOrDefault("X-Amz-Credential")
  valid_21626239 = validateParameter(valid_21626239, JString, required = false,
                                   default = nil)
  if valid_21626239 != nil:
    section.add "X-Amz-Credential", valid_21626239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626241: Call_ListPrincipals_21626228; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the principals that you have shared resources with or that have shared resources with you.
  ## 
  let valid = call_21626241.validator(path, query, header, formData, body, _)
  let scheme = call_21626241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626241.makeUrl(scheme.get, call_21626241.host, call_21626241.base,
                               call_21626241.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626241, uri, valid, _)

proc call*(call_21626242: Call_ListPrincipals_21626228; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listPrincipals
  ## Lists the principals that you have shared resources with or that have shared resources with you.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626243 = newJObject()
  var body_21626244 = newJObject()
  add(query_21626243, "maxResults", newJString(maxResults))
  add(query_21626243, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626244 = body
  result = call_21626242.call(nil, query_21626243, nil, nil, body_21626244)

var listPrincipals* = Call_ListPrincipals_21626228(name: "listPrincipals",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/listprincipals",
    validator: validate_ListPrincipals_21626229, base: "/",
    makeUrl: url_ListPrincipals_21626230, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceSharePermissions_21626245 = ref object of OpenApiRestCall_21625435
proc url_ListResourceSharePermissions_21626247(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourceSharePermissions_21626246(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists the AWS RAM permissions that are associated with a resource share.
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
  var valid_21626248 = header.getOrDefault("X-Amz-Date")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-Date", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Security-Token", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "X-Amz-Algorithm", valid_21626251
  var valid_21626252 = header.getOrDefault("X-Amz-Signature")
  valid_21626252 = validateParameter(valid_21626252, JString, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "X-Amz-Signature", valid_21626252
  var valid_21626253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626253 = validateParameter(valid_21626253, JString, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626253
  var valid_21626254 = header.getOrDefault("X-Amz-Credential")
  valid_21626254 = validateParameter(valid_21626254, JString, required = false,
                                   default = nil)
  if valid_21626254 != nil:
    section.add "X-Amz-Credential", valid_21626254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626256: Call_ListResourceSharePermissions_21626245;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the AWS RAM permissions that are associated with a resource share.
  ## 
  let valid = call_21626256.validator(path, query, header, formData, body, _)
  let scheme = call_21626256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626256.makeUrl(scheme.get, call_21626256.host, call_21626256.base,
                               call_21626256.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626256, uri, valid, _)

proc call*(call_21626257: Call_ListResourceSharePermissions_21626245;
          body: JsonNode): Recallable =
  ## listResourceSharePermissions
  ## Lists the AWS RAM permissions that are associated with a resource share.
  ##   body: JObject (required)
  var body_21626258 = newJObject()
  if body != nil:
    body_21626258 = body
  result = call_21626257.call(nil, nil, nil, nil, body_21626258)

var listResourceSharePermissions* = Call_ListResourceSharePermissions_21626245(
    name: "listResourceSharePermissions", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/listresourcesharepermissions",
    validator: validate_ListResourceSharePermissions_21626246, base: "/",
    makeUrl: url_ListResourceSharePermissions_21626247,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResources_21626259 = ref object of OpenApiRestCall_21625435
proc url_ListResources_21626261(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResources_21626260(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Lists the resources that you added to a resource shares or the resources that are shared with you.
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
  var valid_21626262 = query.getOrDefault("maxResults")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "maxResults", valid_21626262
  var valid_21626263 = query.getOrDefault("nextToken")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "nextToken", valid_21626263
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
  var valid_21626264 = header.getOrDefault("X-Amz-Date")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Date", valid_21626264
  var valid_21626265 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-Security-Token", valid_21626265
  var valid_21626266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626266
  var valid_21626267 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626267 = validateParameter(valid_21626267, JString, required = false,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "X-Amz-Algorithm", valid_21626267
  var valid_21626268 = header.getOrDefault("X-Amz-Signature")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "X-Amz-Signature", valid_21626268
  var valid_21626269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626269
  var valid_21626270 = header.getOrDefault("X-Amz-Credential")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-Credential", valid_21626270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626272: Call_ListResources_21626259; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the resources that you added to a resource shares or the resources that are shared with you.
  ## 
  let valid = call_21626272.validator(path, query, header, formData, body, _)
  let scheme = call_21626272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626272.makeUrl(scheme.get, call_21626272.host, call_21626272.base,
                               call_21626272.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626272, uri, valid, _)

proc call*(call_21626273: Call_ListResources_21626259; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listResources
  ## Lists the resources that you added to a resource shares or the resources that are shared with you.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626274 = newJObject()
  var body_21626275 = newJObject()
  add(query_21626274, "maxResults", newJString(maxResults))
  add(query_21626274, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626275 = body
  result = call_21626273.call(nil, query_21626274, nil, nil, body_21626275)

var listResources* = Call_ListResources_21626259(name: "listResources",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/listresources",
    validator: validate_ListResources_21626260, base: "/",
    makeUrl: url_ListResources_21626261, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PromoteResourceShareCreatedFromPolicy_21626276 = ref object of OpenApiRestCall_21625435
proc url_PromoteResourceShareCreatedFromPolicy_21626278(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PromoteResourceShareCreatedFromPolicy_21626277(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Resource shares that were created by attaching a policy to a resource are visible only to the resource share owner, and the resource share cannot be modified in AWS RAM.</p> <p>Use this API action to promote the resource share. When you promote the resource share, it becomes:</p> <ul> <li> <p>Visible to all principals that it is shared with.</p> </li> <li> <p>Modifiable in AWS RAM.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceShareArn: JString (required)
  ##                   : The ARN of the resource share to promote.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `resourceShareArn` field"
  var valid_21626279 = query.getOrDefault("resourceShareArn")
  valid_21626279 = validateParameter(valid_21626279, JString, required = true,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "resourceShareArn", valid_21626279
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
  var valid_21626280 = header.getOrDefault("X-Amz-Date")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-Date", valid_21626280
  var valid_21626281 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-Security-Token", valid_21626281
  var valid_21626282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626282
  var valid_21626283 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-Algorithm", valid_21626283
  var valid_21626284 = header.getOrDefault("X-Amz-Signature")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-Signature", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626285
  var valid_21626286 = header.getOrDefault("X-Amz-Credential")
  valid_21626286 = validateParameter(valid_21626286, JString, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "X-Amz-Credential", valid_21626286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626287: Call_PromoteResourceShareCreatedFromPolicy_21626276;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Resource shares that were created by attaching a policy to a resource are visible only to the resource share owner, and the resource share cannot be modified in AWS RAM.</p> <p>Use this API action to promote the resource share. When you promote the resource share, it becomes:</p> <ul> <li> <p>Visible to all principals that it is shared with.</p> </li> <li> <p>Modifiable in AWS RAM.</p> </li> </ul>
  ## 
  let valid = call_21626287.validator(path, query, header, formData, body, _)
  let scheme = call_21626287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626287.makeUrl(scheme.get, call_21626287.host, call_21626287.base,
                               call_21626287.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626287, uri, valid, _)

proc call*(call_21626288: Call_PromoteResourceShareCreatedFromPolicy_21626276;
          resourceShareArn: string): Recallable =
  ## promoteResourceShareCreatedFromPolicy
  ## <p>Resource shares that were created by attaching a policy to a resource are visible only to the resource share owner, and the resource share cannot be modified in AWS RAM.</p> <p>Use this API action to promote the resource share. When you promote the resource share, it becomes:</p> <ul> <li> <p>Visible to all principals that it is shared with.</p> </li> <li> <p>Modifiable in AWS RAM.</p> </li> </ul>
  ##   resourceShareArn: string (required)
  ##                   : The ARN of the resource share to promote.
  var query_21626289 = newJObject()
  add(query_21626289, "resourceShareArn", newJString(resourceShareArn))
  result = call_21626288.call(nil, query_21626289, nil, nil, nil)

var promoteResourceShareCreatedFromPolicy* = Call_PromoteResourceShareCreatedFromPolicy_21626276(
    name: "promoteResourceShareCreatedFromPolicy", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com",
    route: "/promoteresourcesharecreatedfrompolicy#resourceShareArn",
    validator: validate_PromoteResourceShareCreatedFromPolicy_21626277, base: "/",
    makeUrl: url_PromoteResourceShareCreatedFromPolicy_21626278,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectResourceShareInvitation_21626290 = ref object of OpenApiRestCall_21625435
proc url_RejectResourceShareInvitation_21626292(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RejectResourceShareInvitation_21626291(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Rejects an invitation to a resource share from another AWS account.
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
  var valid_21626293 = header.getOrDefault("X-Amz-Date")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-Date", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Security-Token", valid_21626294
  var valid_21626295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626295
  var valid_21626296 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "X-Amz-Algorithm", valid_21626296
  var valid_21626297 = header.getOrDefault("X-Amz-Signature")
  valid_21626297 = validateParameter(valid_21626297, JString, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "X-Amz-Signature", valid_21626297
  var valid_21626298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626298
  var valid_21626299 = header.getOrDefault("X-Amz-Credential")
  valid_21626299 = validateParameter(valid_21626299, JString, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "X-Amz-Credential", valid_21626299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626301: Call_RejectResourceShareInvitation_21626290;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Rejects an invitation to a resource share from another AWS account.
  ## 
  let valid = call_21626301.validator(path, query, header, formData, body, _)
  let scheme = call_21626301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626301.makeUrl(scheme.get, call_21626301.host, call_21626301.base,
                               call_21626301.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626301, uri, valid, _)

proc call*(call_21626302: Call_RejectResourceShareInvitation_21626290;
          body: JsonNode): Recallable =
  ## rejectResourceShareInvitation
  ## Rejects an invitation to a resource share from another AWS account.
  ##   body: JObject (required)
  var body_21626303 = newJObject()
  if body != nil:
    body_21626303 = body
  result = call_21626302.call(nil, nil, nil, nil, body_21626303)

var rejectResourceShareInvitation* = Call_RejectResourceShareInvitation_21626290(
    name: "rejectResourceShareInvitation", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/rejectresourceshareinvitation",
    validator: validate_RejectResourceShareInvitation_21626291, base: "/",
    makeUrl: url_RejectResourceShareInvitation_21626292,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626304 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626306(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_21626305(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds the specified tags to the specified resource share that you own.
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
  var valid_21626307 = header.getOrDefault("X-Amz-Date")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Date", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-Security-Token", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626309
  var valid_21626310 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-Algorithm", valid_21626310
  var valid_21626311 = header.getOrDefault("X-Amz-Signature")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "X-Amz-Signature", valid_21626311
  var valid_21626312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626312 = validateParameter(valid_21626312, JString, required = false,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626312
  var valid_21626313 = header.getOrDefault("X-Amz-Credential")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-Credential", valid_21626313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626315: Call_TagResource_21626304; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds the specified tags to the specified resource share that you own.
  ## 
  let valid = call_21626315.validator(path, query, header, formData, body, _)
  let scheme = call_21626315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626315.makeUrl(scheme.get, call_21626315.host, call_21626315.base,
                               call_21626315.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626315, uri, valid, _)

proc call*(call_21626316: Call_TagResource_21626304; body: JsonNode): Recallable =
  ## tagResource
  ## Adds the specified tags to the specified resource share that you own.
  ##   body: JObject (required)
  var body_21626317 = newJObject()
  if body != nil:
    body_21626317 = body
  result = call_21626316.call(nil, nil, nil, nil, body_21626317)

var tagResource* = Call_TagResource_21626304(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/tagresource",
    validator: validate_TagResource_21626305, base: "/", makeUrl: url_TagResource_21626306,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626318 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626320(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_21626319(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Removes the specified tags from the specified resource share that you own.
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
  var valid_21626321 = header.getOrDefault("X-Amz-Date")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-Date", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Security-Token", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Algorithm", valid_21626324
  var valid_21626325 = header.getOrDefault("X-Amz-Signature")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "X-Amz-Signature", valid_21626325
  var valid_21626326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626326
  var valid_21626327 = header.getOrDefault("X-Amz-Credential")
  valid_21626327 = validateParameter(valid_21626327, JString, required = false,
                                   default = nil)
  if valid_21626327 != nil:
    section.add "X-Amz-Credential", valid_21626327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626329: Call_UntagResource_21626318; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the specified tags from the specified resource share that you own.
  ## 
  let valid = call_21626329.validator(path, query, header, formData, body, _)
  let scheme = call_21626329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626329.makeUrl(scheme.get, call_21626329.host, call_21626329.base,
                               call_21626329.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626329, uri, valid, _)

proc call*(call_21626330: Call_UntagResource_21626318; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from the specified resource share that you own.
  ##   body: JObject (required)
  var body_21626331 = newJObject()
  if body != nil:
    body_21626331 = body
  result = call_21626330.call(nil, nil, nil, nil, body_21626331)

var untagResource* = Call_UntagResource_21626318(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/untagresource",
    validator: validate_UntagResource_21626319, base: "/",
    makeUrl: url_UntagResource_21626320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceShare_21626332 = ref object of OpenApiRestCall_21625435
proc url_UpdateResourceShare_21626334(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateResourceShare_21626333(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the specified resource share that you own.
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
  var valid_21626335 = header.getOrDefault("X-Amz-Date")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Date", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Security-Token", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Algorithm", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Signature")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Signature", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626340
  var valid_21626341 = header.getOrDefault("X-Amz-Credential")
  valid_21626341 = validateParameter(valid_21626341, JString, required = false,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "X-Amz-Credential", valid_21626341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626343: Call_UpdateResourceShare_21626332; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the specified resource share that you own.
  ## 
  let valid = call_21626343.validator(path, query, header, formData, body, _)
  let scheme = call_21626343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626343.makeUrl(scheme.get, call_21626343.host, call_21626343.base,
                               call_21626343.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626343, uri, valid, _)

proc call*(call_21626344: Call_UpdateResourceShare_21626332; body: JsonNode): Recallable =
  ## updateResourceShare
  ## Updates the specified resource share that you own.
  ##   body: JObject (required)
  var body_21626345 = newJObject()
  if body != nil:
    body_21626345 = body
  result = call_21626344.call(nil, nil, nil, nil, body_21626345)

var updateResourceShare* = Call_UpdateResourceShare_21626332(
    name: "updateResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/updateresourceshare",
    validator: validate_UpdateResourceShare_21626333, base: "/",
    makeUrl: url_UpdateResourceShare_21626334,
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
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}