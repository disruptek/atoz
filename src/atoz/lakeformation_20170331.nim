
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Lake Formation
## version: 2017-03-31
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Lake Formation</fullname> <p>Defines the public endpoint for the AWS Lake Formation service.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/lakeformation/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "lakeformation.ap-northeast-1.amazonaws.com", "ap-southeast-1": "lakeformation.ap-southeast-1.amazonaws.com", "us-west-2": "lakeformation.us-west-2.amazonaws.com", "eu-west-2": "lakeformation.eu-west-2.amazonaws.com", "ap-northeast-3": "lakeformation.ap-northeast-3.amazonaws.com", "eu-central-1": "lakeformation.eu-central-1.amazonaws.com", "us-east-2": "lakeformation.us-east-2.amazonaws.com", "us-east-1": "lakeformation.us-east-1.amazonaws.com", "cn-northwest-1": "lakeformation.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "lakeformation.ap-south-1.amazonaws.com", "eu-north-1": "lakeformation.eu-north-1.amazonaws.com", "ap-northeast-2": "lakeformation.ap-northeast-2.amazonaws.com", "us-west-1": "lakeformation.us-west-1.amazonaws.com", "us-gov-east-1": "lakeformation.us-gov-east-1.amazonaws.com", "eu-west-3": "lakeformation.eu-west-3.amazonaws.com", "cn-north-1": "lakeformation.cn-north-1.amazonaws.com.cn", "sa-east-1": "lakeformation.sa-east-1.amazonaws.com", "eu-west-1": "lakeformation.eu-west-1.amazonaws.com", "us-gov-west-1": "lakeformation.us-gov-west-1.amazonaws.com", "ap-southeast-2": "lakeformation.ap-southeast-2.amazonaws.com", "ca-central-1": "lakeformation.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "lakeformation.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "lakeformation.ap-southeast-1.amazonaws.com",
      "us-west-2": "lakeformation.us-west-2.amazonaws.com",
      "eu-west-2": "lakeformation.eu-west-2.amazonaws.com",
      "ap-northeast-3": "lakeformation.ap-northeast-3.amazonaws.com",
      "eu-central-1": "lakeformation.eu-central-1.amazonaws.com",
      "us-east-2": "lakeformation.us-east-2.amazonaws.com",
      "us-east-1": "lakeformation.us-east-1.amazonaws.com",
      "cn-northwest-1": "lakeformation.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "lakeformation.ap-south-1.amazonaws.com",
      "eu-north-1": "lakeformation.eu-north-1.amazonaws.com",
      "ap-northeast-2": "lakeformation.ap-northeast-2.amazonaws.com",
      "us-west-1": "lakeformation.us-west-1.amazonaws.com",
      "us-gov-east-1": "lakeformation.us-gov-east-1.amazonaws.com",
      "eu-west-3": "lakeformation.eu-west-3.amazonaws.com",
      "cn-north-1": "lakeformation.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "lakeformation.sa-east-1.amazonaws.com",
      "eu-west-1": "lakeformation.eu-west-1.amazonaws.com",
      "us-gov-west-1": "lakeformation.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "lakeformation.ap-southeast-2.amazonaws.com",
      "ca-central-1": "lakeformation.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "lakeformation"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_BatchGrantPermissions_21625779 = ref object of OpenApiRestCall_21625435
proc url_BatchGrantPermissions_21625781(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGrantPermissions_21625780(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Batch operation to grant permissions to the principal.
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
  ##   X-Amz-Target: JString (required)
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
  var valid_21625898 = header.getOrDefault("X-Amz-Target")
  valid_21625898 = validateParameter(valid_21625898, JString, required = true, default = newJString(
      "AWSLakeFormation.BatchGrantPermissions"))
  if valid_21625898 != nil:
    section.add "X-Amz-Target", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Algorithm", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Signature")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Signature", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Credential")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Credential", valid_21625903
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

proc call*(call_21625929: Call_BatchGrantPermissions_21625779;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Batch operation to grant permissions to the principal.
  ## 
  let valid = call_21625929.validator(path, query, header, formData, body, _)
  let scheme = call_21625929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625929.makeUrl(scheme.get, call_21625929.host, call_21625929.base,
                               call_21625929.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625929, uri, valid, _)

proc call*(call_21625992: Call_BatchGrantPermissions_21625779; body: JsonNode): Recallable =
  ## batchGrantPermissions
  ## Batch operation to grant permissions to the principal.
  ##   body: JObject (required)
  var body_21625993 = newJObject()
  if body != nil:
    body_21625993 = body
  result = call_21625992.call(nil, nil, nil, nil, body_21625993)

var batchGrantPermissions* = Call_BatchGrantPermissions_21625779(
    name: "batchGrantPermissions", meth: HttpMethod.HttpPost,
    host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.BatchGrantPermissions",
    validator: validate_BatchGrantPermissions_21625780, base: "/",
    makeUrl: url_BatchGrantPermissions_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchRevokePermissions_21626029 = ref object of OpenApiRestCall_21625435
proc url_BatchRevokePermissions_21626031(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchRevokePermissions_21626030(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Batch operation to revoke permissions from the principal.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626032 = header.getOrDefault("X-Amz-Date")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Date", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Security-Token", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Target")
  valid_21626034 = validateParameter(valid_21626034, JString, required = true, default = newJString(
      "AWSLakeFormation.BatchRevokePermissions"))
  if valid_21626034 != nil:
    section.add "X-Amz-Target", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Algorithm", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Signature")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Signature", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Credential")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Credential", valid_21626039
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

proc call*(call_21626041: Call_BatchRevokePermissions_21626029;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Batch operation to revoke permissions from the principal.
  ## 
  let valid = call_21626041.validator(path, query, header, formData, body, _)
  let scheme = call_21626041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626041.makeUrl(scheme.get, call_21626041.host, call_21626041.base,
                               call_21626041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626041, uri, valid, _)

proc call*(call_21626042: Call_BatchRevokePermissions_21626029; body: JsonNode): Recallable =
  ## batchRevokePermissions
  ## Batch operation to revoke permissions from the principal.
  ##   body: JObject (required)
  var body_21626043 = newJObject()
  if body != nil:
    body_21626043 = body
  result = call_21626042.call(nil, nil, nil, nil, body_21626043)

var batchRevokePermissions* = Call_BatchRevokePermissions_21626029(
    name: "batchRevokePermissions", meth: HttpMethod.HttpPost,
    host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.BatchRevokePermissions",
    validator: validate_BatchRevokePermissions_21626030, base: "/",
    makeUrl: url_BatchRevokePermissions_21626031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterResource_21626044 = ref object of OpenApiRestCall_21625435
proc url_DeregisterResource_21626046(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterResource_21626045(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deregisters the resource as managed by the Data Catalog.</p> <p>When you deregister a path, Lake Formation removes the path from the inline policy attached to your service-linked role.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626047 = header.getOrDefault("X-Amz-Date")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Date", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Security-Token", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Target")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true, default = newJString(
      "AWSLakeFormation.DeregisterResource"))
  if valid_21626049 != nil:
    section.add "X-Amz-Target", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Algorithm", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Signature")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Signature", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Credential")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Credential", valid_21626054
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

proc call*(call_21626056: Call_DeregisterResource_21626044; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deregisters the resource as managed by the Data Catalog.</p> <p>When you deregister a path, Lake Formation removes the path from the inline policy attached to your service-linked role.</p>
  ## 
  let valid = call_21626056.validator(path, query, header, formData, body, _)
  let scheme = call_21626056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626056.makeUrl(scheme.get, call_21626056.host, call_21626056.base,
                               call_21626056.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626056, uri, valid, _)

proc call*(call_21626057: Call_DeregisterResource_21626044; body: JsonNode): Recallable =
  ## deregisterResource
  ## <p>Deregisters the resource as managed by the Data Catalog.</p> <p>When you deregister a path, Lake Formation removes the path from the inline policy attached to your service-linked role.</p>
  ##   body: JObject (required)
  var body_21626058 = newJObject()
  if body != nil:
    body_21626058 = body
  result = call_21626057.call(nil, nil, nil, nil, body_21626058)

var deregisterResource* = Call_DeregisterResource_21626044(
    name: "deregisterResource", meth: HttpMethod.HttpPost,
    host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.DeregisterResource",
    validator: validate_DeregisterResource_21626045, base: "/",
    makeUrl: url_DeregisterResource_21626046, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResource_21626059 = ref object of OpenApiRestCall_21625435
proc url_DescribeResource_21626061(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeResource_21626060(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the current data access role for the given resource registered in AWS Lake Formation.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626062 = header.getOrDefault("X-Amz-Date")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Date", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Security-Token", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Target")
  valid_21626064 = validateParameter(valid_21626064, JString, required = true, default = newJString(
      "AWSLakeFormation.DescribeResource"))
  if valid_21626064 != nil:
    section.add "X-Amz-Target", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Algorithm", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Signature")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Signature", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Credential")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Credential", valid_21626069
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

proc call*(call_21626071: Call_DescribeResource_21626059; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the current data access role for the given resource registered in AWS Lake Formation.
  ## 
  let valid = call_21626071.validator(path, query, header, formData, body, _)
  let scheme = call_21626071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626071.makeUrl(scheme.get, call_21626071.host, call_21626071.base,
                               call_21626071.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626071, uri, valid, _)

proc call*(call_21626072: Call_DescribeResource_21626059; body: JsonNode): Recallable =
  ## describeResource
  ## Retrieves the current data access role for the given resource registered in AWS Lake Formation.
  ##   body: JObject (required)
  var body_21626073 = newJObject()
  if body != nil:
    body_21626073 = body
  result = call_21626072.call(nil, nil, nil, nil, body_21626073)

var describeResource* = Call_DescribeResource_21626059(name: "describeResource",
    meth: HttpMethod.HttpPost, host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.DescribeResource",
    validator: validate_DescribeResource_21626060, base: "/",
    makeUrl: url_DescribeResource_21626061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataLakeSettings_21626074 = ref object of OpenApiRestCall_21625435
proc url_GetDataLakeSettings_21626076(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDataLakeSettings_21626075(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## The AWS Lake Formation principal.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626077 = header.getOrDefault("X-Amz-Date")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Date", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Security-Token", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Target")
  valid_21626079 = validateParameter(valid_21626079, JString, required = true, default = newJString(
      "AWSLakeFormation.GetDataLakeSettings"))
  if valid_21626079 != nil:
    section.add "X-Amz-Target", valid_21626079
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

proc call*(call_21626086: Call_GetDataLakeSettings_21626074; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## The AWS Lake Formation principal.
  ## 
  let valid = call_21626086.validator(path, query, header, formData, body, _)
  let scheme = call_21626086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626086.makeUrl(scheme.get, call_21626086.host, call_21626086.base,
                               call_21626086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626086, uri, valid, _)

proc call*(call_21626087: Call_GetDataLakeSettings_21626074; body: JsonNode): Recallable =
  ## getDataLakeSettings
  ## The AWS Lake Formation principal.
  ##   body: JObject (required)
  var body_21626088 = newJObject()
  if body != nil:
    body_21626088 = body
  result = call_21626087.call(nil, nil, nil, nil, body_21626088)

var getDataLakeSettings* = Call_GetDataLakeSettings_21626074(
    name: "getDataLakeSettings", meth: HttpMethod.HttpPost,
    host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.GetDataLakeSettings",
    validator: validate_GetDataLakeSettings_21626075, base: "/",
    makeUrl: url_GetDataLakeSettings_21626076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEffectivePermissionsForPath_21626089 = ref object of OpenApiRestCall_21625435
proc url_GetEffectivePermissionsForPath_21626091(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetEffectivePermissionsForPath_21626090(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns the permissions for a specified table or database resource located at a path in Amazon S3.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626092 = query.getOrDefault("NextToken")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "NextToken", valid_21626092
  var valid_21626093 = query.getOrDefault("MaxResults")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "MaxResults", valid_21626093
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626094 = header.getOrDefault("X-Amz-Date")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "X-Amz-Date", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Security-Token", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Target")
  valid_21626096 = validateParameter(valid_21626096, JString, required = true, default = newJString(
      "AWSLakeFormation.GetEffectivePermissionsForPath"))
  if valid_21626096 != nil:
    section.add "X-Amz-Target", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Algorithm", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Signature")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Signature", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Credential")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Credential", valid_21626101
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

proc call*(call_21626103: Call_GetEffectivePermissionsForPath_21626089;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the permissions for a specified table or database resource located at a path in Amazon S3.
  ## 
  let valid = call_21626103.validator(path, query, header, formData, body, _)
  let scheme = call_21626103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626103.makeUrl(scheme.get, call_21626103.host, call_21626103.base,
                               call_21626103.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626103, uri, valid, _)

proc call*(call_21626104: Call_GetEffectivePermissionsForPath_21626089;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getEffectivePermissionsForPath
  ## Returns the permissions for a specified table or database resource located at a path in Amazon S3.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626106 = newJObject()
  var body_21626107 = newJObject()
  add(query_21626106, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626107 = body
  add(query_21626106, "MaxResults", newJString(MaxResults))
  result = call_21626104.call(nil, query_21626106, nil, nil, body_21626107)

var getEffectivePermissionsForPath* = Call_GetEffectivePermissionsForPath_21626089(
    name: "getEffectivePermissionsForPath", meth: HttpMethod.HttpPost,
    host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.GetEffectivePermissionsForPath",
    validator: validate_GetEffectivePermissionsForPath_21626090, base: "/",
    makeUrl: url_GetEffectivePermissionsForPath_21626091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GrantPermissions_21626111 = ref object of OpenApiRestCall_21625435
proc url_GrantPermissions_21626113(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GrantPermissions_21626112(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Grants permissions to the principal to access metadata in the Data Catalog and data organized in underlying data storage such as Amazon S3.</p> <p>For information about permissions, see <a href="https://docs-aws.amazon.com/michigan/latest/dg/security-data-access.html">Security and Access Control to Metadata and Data</a>.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626114 = header.getOrDefault("X-Amz-Date")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Date", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-Security-Token", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Target")
  valid_21626116 = validateParameter(valid_21626116, JString, required = true, default = newJString(
      "AWSLakeFormation.GrantPermissions"))
  if valid_21626116 != nil:
    section.add "X-Amz-Target", valid_21626116
  var valid_21626117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Algorithm", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-Signature")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-Signature", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-Credential")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Credential", valid_21626121
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

proc call*(call_21626123: Call_GrantPermissions_21626111; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Grants permissions to the principal to access metadata in the Data Catalog and data organized in underlying data storage such as Amazon S3.</p> <p>For information about permissions, see <a href="https://docs-aws.amazon.com/michigan/latest/dg/security-data-access.html">Security and Access Control to Metadata and Data</a>.</p>
  ## 
  let valid = call_21626123.validator(path, query, header, formData, body, _)
  let scheme = call_21626123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626123.makeUrl(scheme.get, call_21626123.host, call_21626123.base,
                               call_21626123.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626123, uri, valid, _)

proc call*(call_21626124: Call_GrantPermissions_21626111; body: JsonNode): Recallable =
  ## grantPermissions
  ## <p>Grants permissions to the principal to access metadata in the Data Catalog and data organized in underlying data storage such as Amazon S3.</p> <p>For information about permissions, see <a href="https://docs-aws.amazon.com/michigan/latest/dg/security-data-access.html">Security and Access Control to Metadata and Data</a>.</p>
  ##   body: JObject (required)
  var body_21626125 = newJObject()
  if body != nil:
    body_21626125 = body
  result = call_21626124.call(nil, nil, nil, nil, body_21626125)

var grantPermissions* = Call_GrantPermissions_21626111(name: "grantPermissions",
    meth: HttpMethod.HttpPost, host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.GrantPermissions",
    validator: validate_GrantPermissions_21626112, base: "/",
    makeUrl: url_GrantPermissions_21626113, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPermissions_21626126 = ref object of OpenApiRestCall_21625435
proc url_ListPermissions_21626128(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPermissions_21626127(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a list of the principal permissions on the resource, filtered by the permissions of the caller. For example, if you are granted an ALTER permission, you are able to see only the principal permissions for ALTER.</p> <p>This operation returns only those permissions that have been explicitly granted.</p> <p>For information about permissions, see <a href="https://docs-aws.amazon.com/michigan/latest/dg/security-data-access.html">Security and Access Control to Metadata and Data</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626129 = query.getOrDefault("NextToken")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "NextToken", valid_21626129
  var valid_21626130 = query.getOrDefault("MaxResults")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "MaxResults", valid_21626130
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626131 = header.getOrDefault("X-Amz-Date")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "X-Amz-Date", valid_21626131
  var valid_21626132 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "X-Amz-Security-Token", valid_21626132
  var valid_21626133 = header.getOrDefault("X-Amz-Target")
  valid_21626133 = validateParameter(valid_21626133, JString, required = true, default = newJString(
      "AWSLakeFormation.ListPermissions"))
  if valid_21626133 != nil:
    section.add "X-Amz-Target", valid_21626133
  var valid_21626134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626134
  var valid_21626135 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Algorithm", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Signature")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Signature", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Credential")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Credential", valid_21626138
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

proc call*(call_21626140: Call_ListPermissions_21626126; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of the principal permissions on the resource, filtered by the permissions of the caller. For example, if you are granted an ALTER permission, you are able to see only the principal permissions for ALTER.</p> <p>This operation returns only those permissions that have been explicitly granted.</p> <p>For information about permissions, see <a href="https://docs-aws.amazon.com/michigan/latest/dg/security-data-access.html">Security and Access Control to Metadata and Data</a>.</p>
  ## 
  let valid = call_21626140.validator(path, query, header, formData, body, _)
  let scheme = call_21626140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626140.makeUrl(scheme.get, call_21626140.host, call_21626140.base,
                               call_21626140.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626140, uri, valid, _)

proc call*(call_21626141: Call_ListPermissions_21626126; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listPermissions
  ## <p>Returns a list of the principal permissions on the resource, filtered by the permissions of the caller. For example, if you are granted an ALTER permission, you are able to see only the principal permissions for ALTER.</p> <p>This operation returns only those permissions that have been explicitly granted.</p> <p>For information about permissions, see <a href="https://docs-aws.amazon.com/michigan/latest/dg/security-data-access.html">Security and Access Control to Metadata and Data</a>.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626142 = newJObject()
  var body_21626143 = newJObject()
  add(query_21626142, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626143 = body
  add(query_21626142, "MaxResults", newJString(MaxResults))
  result = call_21626141.call(nil, query_21626142, nil, nil, body_21626143)

var listPermissions* = Call_ListPermissions_21626126(name: "listPermissions",
    meth: HttpMethod.HttpPost, host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.ListPermissions",
    validator: validate_ListPermissions_21626127, base: "/",
    makeUrl: url_ListPermissions_21626128, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResources_21626144 = ref object of OpenApiRestCall_21625435
proc url_ListResources_21626146(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResources_21626145(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Lists the resources registered to be managed by the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626147 = query.getOrDefault("NextToken")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "NextToken", valid_21626147
  var valid_21626148 = query.getOrDefault("MaxResults")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "MaxResults", valid_21626148
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626149 = header.getOrDefault("X-Amz-Date")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "X-Amz-Date", valid_21626149
  var valid_21626150 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-Security-Token", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-Target")
  valid_21626151 = validateParameter(valid_21626151, JString, required = true, default = newJString(
      "AWSLakeFormation.ListResources"))
  if valid_21626151 != nil:
    section.add "X-Amz-Target", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Algorithm", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Signature")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Signature", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Credential")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Credential", valid_21626156
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

proc call*(call_21626158: Call_ListResources_21626144; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the resources registered to be managed by the Data Catalog.
  ## 
  let valid = call_21626158.validator(path, query, header, formData, body, _)
  let scheme = call_21626158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626158.makeUrl(scheme.get, call_21626158.host, call_21626158.base,
                               call_21626158.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626158, uri, valid, _)

proc call*(call_21626159: Call_ListResources_21626144; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listResources
  ## Lists the resources registered to be managed by the Data Catalog.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626160 = newJObject()
  var body_21626161 = newJObject()
  add(query_21626160, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626161 = body
  add(query_21626160, "MaxResults", newJString(MaxResults))
  result = call_21626159.call(nil, query_21626160, nil, nil, body_21626161)

var listResources* = Call_ListResources_21626144(name: "listResources",
    meth: HttpMethod.HttpPost, host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.ListResources",
    validator: validate_ListResources_21626145, base: "/",
    makeUrl: url_ListResources_21626146, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDataLakeSettings_21626162 = ref object of OpenApiRestCall_21625435
proc url_PutDataLakeSettings_21626164(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutDataLakeSettings_21626163(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## The AWS Lake Formation principal.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626165 = header.getOrDefault("X-Amz-Date")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-Date", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Security-Token", valid_21626166
  var valid_21626167 = header.getOrDefault("X-Amz-Target")
  valid_21626167 = validateParameter(valid_21626167, JString, required = true, default = newJString(
      "AWSLakeFormation.PutDataLakeSettings"))
  if valid_21626167 != nil:
    section.add "X-Amz-Target", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Algorithm", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Signature")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Signature", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Credential")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Credential", valid_21626172
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

proc call*(call_21626174: Call_PutDataLakeSettings_21626162; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## The AWS Lake Formation principal.
  ## 
  let valid = call_21626174.validator(path, query, header, formData, body, _)
  let scheme = call_21626174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626174.makeUrl(scheme.get, call_21626174.host, call_21626174.base,
                               call_21626174.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626174, uri, valid, _)

proc call*(call_21626175: Call_PutDataLakeSettings_21626162; body: JsonNode): Recallable =
  ## putDataLakeSettings
  ## The AWS Lake Formation principal.
  ##   body: JObject (required)
  var body_21626176 = newJObject()
  if body != nil:
    body_21626176 = body
  result = call_21626175.call(nil, nil, nil, nil, body_21626176)

var putDataLakeSettings* = Call_PutDataLakeSettings_21626162(
    name: "putDataLakeSettings", meth: HttpMethod.HttpPost,
    host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.PutDataLakeSettings",
    validator: validate_PutDataLakeSettings_21626163, base: "/",
    makeUrl: url_PutDataLakeSettings_21626164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterResource_21626177 = ref object of OpenApiRestCall_21625435
proc url_RegisterResource_21626179(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterResource_21626178(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Registers the resource as managed by the Data Catalog.</p> <p>To add or update data, Lake Formation needs read/write access to the chosen Amazon S3 path. Choose a role that you know has permission to do this, or choose the AWSServiceRoleForLakeFormationDataAccess service-linked role. When you register the first Amazon S3 path, the service-linked role and a new inline policy are created on your behalf. Lake Formation adds the first path to the inline policy and attaches it to the service-linked role. When you register subsequent paths, Lake Formation adds the path to the existing policy.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626180 = header.getOrDefault("X-Amz-Date")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-Date", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Security-Token", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-Target")
  valid_21626182 = validateParameter(valid_21626182, JString, required = true, default = newJString(
      "AWSLakeFormation.RegisterResource"))
  if valid_21626182 != nil:
    section.add "X-Amz-Target", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Algorithm", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Signature")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Signature", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Credential")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Credential", valid_21626187
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

proc call*(call_21626189: Call_RegisterResource_21626177; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Registers the resource as managed by the Data Catalog.</p> <p>To add or update data, Lake Formation needs read/write access to the chosen Amazon S3 path. Choose a role that you know has permission to do this, or choose the AWSServiceRoleForLakeFormationDataAccess service-linked role. When you register the first Amazon S3 path, the service-linked role and a new inline policy are created on your behalf. Lake Formation adds the first path to the inline policy and attaches it to the service-linked role. When you register subsequent paths, Lake Formation adds the path to the existing policy.</p>
  ## 
  let valid = call_21626189.validator(path, query, header, formData, body, _)
  let scheme = call_21626189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626189.makeUrl(scheme.get, call_21626189.host, call_21626189.base,
                               call_21626189.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626189, uri, valid, _)

proc call*(call_21626190: Call_RegisterResource_21626177; body: JsonNode): Recallable =
  ## registerResource
  ## <p>Registers the resource as managed by the Data Catalog.</p> <p>To add or update data, Lake Formation needs read/write access to the chosen Amazon S3 path. Choose a role that you know has permission to do this, or choose the AWSServiceRoleForLakeFormationDataAccess service-linked role. When you register the first Amazon S3 path, the service-linked role and a new inline policy are created on your behalf. Lake Formation adds the first path to the inline policy and attaches it to the service-linked role. When you register subsequent paths, Lake Formation adds the path to the existing policy.</p>
  ##   body: JObject (required)
  var body_21626191 = newJObject()
  if body != nil:
    body_21626191 = body
  result = call_21626190.call(nil, nil, nil, nil, body_21626191)

var registerResource* = Call_RegisterResource_21626177(name: "registerResource",
    meth: HttpMethod.HttpPost, host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.RegisterResource",
    validator: validate_RegisterResource_21626178, base: "/",
    makeUrl: url_RegisterResource_21626179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokePermissions_21626192 = ref object of OpenApiRestCall_21625435
proc url_RevokePermissions_21626194(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RevokePermissions_21626193(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Revokes permissions to the principal to access metadata in the Data Catalog and data organized in underlying data storage such as Amazon S3.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626195 = header.getOrDefault("X-Amz-Date")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-Date", valid_21626195
  var valid_21626196 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-Security-Token", valid_21626196
  var valid_21626197 = header.getOrDefault("X-Amz-Target")
  valid_21626197 = validateParameter(valid_21626197, JString, required = true, default = newJString(
      "AWSLakeFormation.RevokePermissions"))
  if valid_21626197 != nil:
    section.add "X-Amz-Target", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Algorithm", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Signature")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Signature", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Credential")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Credential", valid_21626202
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

proc call*(call_21626204: Call_RevokePermissions_21626192; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Revokes permissions to the principal to access metadata in the Data Catalog and data organized in underlying data storage such as Amazon S3.
  ## 
  let valid = call_21626204.validator(path, query, header, formData, body, _)
  let scheme = call_21626204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626204.makeUrl(scheme.get, call_21626204.host, call_21626204.base,
                               call_21626204.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626204, uri, valid, _)

proc call*(call_21626205: Call_RevokePermissions_21626192; body: JsonNode): Recallable =
  ## revokePermissions
  ## Revokes permissions to the principal to access metadata in the Data Catalog and data organized in underlying data storage such as Amazon S3.
  ##   body: JObject (required)
  var body_21626206 = newJObject()
  if body != nil:
    body_21626206 = body
  result = call_21626205.call(nil, nil, nil, nil, body_21626206)

var revokePermissions* = Call_RevokePermissions_21626192(name: "revokePermissions",
    meth: HttpMethod.HttpPost, host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.RevokePermissions",
    validator: validate_RevokePermissions_21626193, base: "/",
    makeUrl: url_RevokePermissions_21626194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResource_21626207 = ref object of OpenApiRestCall_21625435
proc url_UpdateResource_21626209(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateResource_21626208(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the data access role used for vending access to the given (registered) resource in AWS Lake Formation. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626210 = header.getOrDefault("X-Amz-Date")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "X-Amz-Date", valid_21626210
  var valid_21626211 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "X-Amz-Security-Token", valid_21626211
  var valid_21626212 = header.getOrDefault("X-Amz-Target")
  valid_21626212 = validateParameter(valid_21626212, JString, required = true, default = newJString(
      "AWSLakeFormation.UpdateResource"))
  if valid_21626212 != nil:
    section.add "X-Amz-Target", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Algorithm", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Signature")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Signature", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Credential")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Credential", valid_21626217
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

proc call*(call_21626219: Call_UpdateResource_21626207; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the data access role used for vending access to the given (registered) resource in AWS Lake Formation. 
  ## 
  let valid = call_21626219.validator(path, query, header, formData, body, _)
  let scheme = call_21626219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626219.makeUrl(scheme.get, call_21626219.host, call_21626219.base,
                               call_21626219.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626219, uri, valid, _)

proc call*(call_21626220: Call_UpdateResource_21626207; body: JsonNode): Recallable =
  ## updateResource
  ## Updates the data access role used for vending access to the given (registered) resource in AWS Lake Formation. 
  ##   body: JObject (required)
  var body_21626221 = newJObject()
  if body != nil:
    body_21626221 = body
  result = call_21626220.call(nil, nil, nil, nil, body_21626221)

var updateResource* = Call_UpdateResource_21626207(name: "updateResource",
    meth: HttpMethod.HttpPost, host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.UpdateResource",
    validator: validate_UpdateResource_21626208, base: "/",
    makeUrl: url_UpdateResource_21626209, schemes: {Scheme.Https, Scheme.Http})
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