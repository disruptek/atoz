
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchGrantPermissions_592703 = ref object of OpenApiRestCall_592364
proc url_BatchGrantPermissions_592705(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGrantPermissions_592704(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Batch operation to grant permissions to the principal.
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
  var valid_592830 = header.getOrDefault("X-Amz-Target")
  valid_592830 = validateParameter(valid_592830, JString, required = true, default = newJString(
      "AWSLakeFormation.BatchGrantPermissions"))
  if valid_592830 != nil:
    section.add "X-Amz-Target", valid_592830
  var valid_592831 = header.getOrDefault("X-Amz-Signature")
  valid_592831 = validateParameter(valid_592831, JString, required = false,
                                 default = nil)
  if valid_592831 != nil:
    section.add "X-Amz-Signature", valid_592831
  var valid_592832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592832 = validateParameter(valid_592832, JString, required = false,
                                 default = nil)
  if valid_592832 != nil:
    section.add "X-Amz-Content-Sha256", valid_592832
  var valid_592833 = header.getOrDefault("X-Amz-Date")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "X-Amz-Date", valid_592833
  var valid_592834 = header.getOrDefault("X-Amz-Credential")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Credential", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Security-Token")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Security-Token", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Algorithm")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Algorithm", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-SignedHeaders", valid_592837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592861: Call_BatchGrantPermissions_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Batch operation to grant permissions to the principal.
  ## 
  let valid = call_592861.validator(path, query, header, formData, body)
  let scheme = call_592861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592861.url(scheme.get, call_592861.host, call_592861.base,
                         call_592861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592861, url, valid)

proc call*(call_592932: Call_BatchGrantPermissions_592703; body: JsonNode): Recallable =
  ## batchGrantPermissions
  ## Batch operation to grant permissions to the principal.
  ##   body: JObject (required)
  var body_592933 = newJObject()
  if body != nil:
    body_592933 = body
  result = call_592932.call(nil, nil, nil, nil, body_592933)

var batchGrantPermissions* = Call_BatchGrantPermissions_592703(
    name: "batchGrantPermissions", meth: HttpMethod.HttpPost,
    host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.BatchGrantPermissions",
    validator: validate_BatchGrantPermissions_592704, base: "/",
    url: url_BatchGrantPermissions_592705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchRevokePermissions_592972 = ref object of OpenApiRestCall_592364
proc url_BatchRevokePermissions_592974(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchRevokePermissions_592973(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Batch operation to revoke permissions from the principal.
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
  var valid_592975 = header.getOrDefault("X-Amz-Target")
  valid_592975 = validateParameter(valid_592975, JString, required = true, default = newJString(
      "AWSLakeFormation.BatchRevokePermissions"))
  if valid_592975 != nil:
    section.add "X-Amz-Target", valid_592975
  var valid_592976 = header.getOrDefault("X-Amz-Signature")
  valid_592976 = validateParameter(valid_592976, JString, required = false,
                                 default = nil)
  if valid_592976 != nil:
    section.add "X-Amz-Signature", valid_592976
  var valid_592977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Content-Sha256", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Date")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Date", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Credential")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Credential", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Security-Token")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Security-Token", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Algorithm")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Algorithm", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-SignedHeaders", valid_592982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592984: Call_BatchRevokePermissions_592972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Batch operation to revoke permissions from the principal.
  ## 
  let valid = call_592984.validator(path, query, header, formData, body)
  let scheme = call_592984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592984.url(scheme.get, call_592984.host, call_592984.base,
                         call_592984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592984, url, valid)

proc call*(call_592985: Call_BatchRevokePermissions_592972; body: JsonNode): Recallable =
  ## batchRevokePermissions
  ## Batch operation to revoke permissions from the principal.
  ##   body: JObject (required)
  var body_592986 = newJObject()
  if body != nil:
    body_592986 = body
  result = call_592985.call(nil, nil, nil, nil, body_592986)

var batchRevokePermissions* = Call_BatchRevokePermissions_592972(
    name: "batchRevokePermissions", meth: HttpMethod.HttpPost,
    host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.BatchRevokePermissions",
    validator: validate_BatchRevokePermissions_592973, base: "/",
    url: url_BatchRevokePermissions_592974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterResource_592987 = ref object of OpenApiRestCall_592364
proc url_DeregisterResource_592989(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeregisterResource_592988(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Deregisters the resource as managed by the Data Catalog.</p> <p>When you deregister a path, Lake Formation removes the path from the inline policy attached to your service-linked role.</p>
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
  var valid_592990 = header.getOrDefault("X-Amz-Target")
  valid_592990 = validateParameter(valid_592990, JString, required = true, default = newJString(
      "AWSLakeFormation.DeregisterResource"))
  if valid_592990 != nil:
    section.add "X-Amz-Target", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-Signature")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-Signature", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Content-Sha256", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Date")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Date", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Credential")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Credential", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Security-Token")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Security-Token", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Algorithm")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Algorithm", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-SignedHeaders", valid_592997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592999: Call_DeregisterResource_592987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deregisters the resource as managed by the Data Catalog.</p> <p>When you deregister a path, Lake Formation removes the path from the inline policy attached to your service-linked role.</p>
  ## 
  let valid = call_592999.validator(path, query, header, formData, body)
  let scheme = call_592999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592999.url(scheme.get, call_592999.host, call_592999.base,
                         call_592999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592999, url, valid)

proc call*(call_593000: Call_DeregisterResource_592987; body: JsonNode): Recallable =
  ## deregisterResource
  ## <p>Deregisters the resource as managed by the Data Catalog.</p> <p>When you deregister a path, Lake Formation removes the path from the inline policy attached to your service-linked role.</p>
  ##   body: JObject (required)
  var body_593001 = newJObject()
  if body != nil:
    body_593001 = body
  result = call_593000.call(nil, nil, nil, nil, body_593001)

var deregisterResource* = Call_DeregisterResource_592987(
    name: "deregisterResource", meth: HttpMethod.HttpPost,
    host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.DeregisterResource",
    validator: validate_DeregisterResource_592988, base: "/",
    url: url_DeregisterResource_592989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResource_593002 = ref object of OpenApiRestCall_592364
proc url_DescribeResource_593004(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeResource_593003(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves the current data access role for the given resource registered in AWS Lake Formation.
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
  var valid_593005 = header.getOrDefault("X-Amz-Target")
  valid_593005 = validateParameter(valid_593005, JString, required = true, default = newJString(
      "AWSLakeFormation.DescribeResource"))
  if valid_593005 != nil:
    section.add "X-Amz-Target", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Signature")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Signature", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Content-Sha256", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Date")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Date", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Credential")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Credential", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Security-Token")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Security-Token", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Algorithm")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Algorithm", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-SignedHeaders", valid_593012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593014: Call_DescribeResource_593002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current data access role for the given resource registered in AWS Lake Formation.
  ## 
  let valid = call_593014.validator(path, query, header, formData, body)
  let scheme = call_593014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593014.url(scheme.get, call_593014.host, call_593014.base,
                         call_593014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593014, url, valid)

proc call*(call_593015: Call_DescribeResource_593002; body: JsonNode): Recallable =
  ## describeResource
  ## Retrieves the current data access role for the given resource registered in AWS Lake Formation.
  ##   body: JObject (required)
  var body_593016 = newJObject()
  if body != nil:
    body_593016 = body
  result = call_593015.call(nil, nil, nil, nil, body_593016)

var describeResource* = Call_DescribeResource_593002(name: "describeResource",
    meth: HttpMethod.HttpPost, host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.DescribeResource",
    validator: validate_DescribeResource_593003, base: "/",
    url: url_DescribeResource_593004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataLakeSettings_593017 = ref object of OpenApiRestCall_592364
proc url_GetDataLakeSettings_593019(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDataLakeSettings_593018(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## The AWS Lake Formation principal.
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
  var valid_593020 = header.getOrDefault("X-Amz-Target")
  valid_593020 = validateParameter(valid_593020, JString, required = true, default = newJString(
      "AWSLakeFormation.GetDataLakeSettings"))
  if valid_593020 != nil:
    section.add "X-Amz-Target", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Signature")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Signature", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Content-Sha256", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Date")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Date", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Credential")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Credential", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Security-Token")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Security-Token", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Algorithm")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Algorithm", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-SignedHeaders", valid_593027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593029: Call_GetDataLakeSettings_593017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The AWS Lake Formation principal.
  ## 
  let valid = call_593029.validator(path, query, header, formData, body)
  let scheme = call_593029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593029.url(scheme.get, call_593029.host, call_593029.base,
                         call_593029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593029, url, valid)

proc call*(call_593030: Call_GetDataLakeSettings_593017; body: JsonNode): Recallable =
  ## getDataLakeSettings
  ## The AWS Lake Formation principal.
  ##   body: JObject (required)
  var body_593031 = newJObject()
  if body != nil:
    body_593031 = body
  result = call_593030.call(nil, nil, nil, nil, body_593031)

var getDataLakeSettings* = Call_GetDataLakeSettings_593017(
    name: "getDataLakeSettings", meth: HttpMethod.HttpPost,
    host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.GetDataLakeSettings",
    validator: validate_GetDataLakeSettings_593018, base: "/",
    url: url_GetDataLakeSettings_593019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEffectivePermissionsForPath_593032 = ref object of OpenApiRestCall_592364
proc url_GetEffectivePermissionsForPath_593034(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetEffectivePermissionsForPath_593033(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the permissions for a specified table or database resource located at a path in Amazon S3.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593035 = query.getOrDefault("MaxResults")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "MaxResults", valid_593035
  var valid_593036 = query.getOrDefault("NextToken")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "NextToken", valid_593036
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
  var valid_593037 = header.getOrDefault("X-Amz-Target")
  valid_593037 = validateParameter(valid_593037, JString, required = true, default = newJString(
      "AWSLakeFormation.GetEffectivePermissionsForPath"))
  if valid_593037 != nil:
    section.add "X-Amz-Target", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Signature")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Signature", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Content-Sha256", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Date")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Date", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Credential")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Credential", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-Security-Token")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Security-Token", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-Algorithm")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-Algorithm", valid_593043
  var valid_593044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "X-Amz-SignedHeaders", valid_593044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593046: Call_GetEffectivePermissionsForPath_593032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the permissions for a specified table or database resource located at a path in Amazon S3.
  ## 
  let valid = call_593046.validator(path, query, header, formData, body)
  let scheme = call_593046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593046.url(scheme.get, call_593046.host, call_593046.base,
                         call_593046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593046, url, valid)

proc call*(call_593047: Call_GetEffectivePermissionsForPath_593032; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getEffectivePermissionsForPath
  ## Returns the permissions for a specified table or database resource located at a path in Amazon S3.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593048 = newJObject()
  var body_593049 = newJObject()
  add(query_593048, "MaxResults", newJString(MaxResults))
  add(query_593048, "NextToken", newJString(NextToken))
  if body != nil:
    body_593049 = body
  result = call_593047.call(nil, query_593048, nil, nil, body_593049)

var getEffectivePermissionsForPath* = Call_GetEffectivePermissionsForPath_593032(
    name: "getEffectivePermissionsForPath", meth: HttpMethod.HttpPost,
    host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.GetEffectivePermissionsForPath",
    validator: validate_GetEffectivePermissionsForPath_593033, base: "/",
    url: url_GetEffectivePermissionsForPath_593034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GrantPermissions_593051 = ref object of OpenApiRestCall_592364
proc url_GrantPermissions_593053(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GrantPermissions_593052(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Grants permissions to the principal to access metadata in the Data Catalog and data organized in underlying data storage such as Amazon S3.</p> <p>For information about permissions, see <a href="https://docs-aws.amazon.com/michigan/latest/dg/security-data-access.html">Security and Access Control to Metadata and Data</a>.</p>
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
  var valid_593054 = header.getOrDefault("X-Amz-Target")
  valid_593054 = validateParameter(valid_593054, JString, required = true, default = newJString(
      "AWSLakeFormation.GrantPermissions"))
  if valid_593054 != nil:
    section.add "X-Amz-Target", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Signature")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Signature", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Content-Sha256", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-Date")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-Date", valid_593057
  var valid_593058 = header.getOrDefault("X-Amz-Credential")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "X-Amz-Credential", valid_593058
  var valid_593059 = header.getOrDefault("X-Amz-Security-Token")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "X-Amz-Security-Token", valid_593059
  var valid_593060 = header.getOrDefault("X-Amz-Algorithm")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-Algorithm", valid_593060
  var valid_593061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-SignedHeaders", valid_593061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593063: Call_GrantPermissions_593051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Grants permissions to the principal to access metadata in the Data Catalog and data organized in underlying data storage such as Amazon S3.</p> <p>For information about permissions, see <a href="https://docs-aws.amazon.com/michigan/latest/dg/security-data-access.html">Security and Access Control to Metadata and Data</a>.</p>
  ## 
  let valid = call_593063.validator(path, query, header, formData, body)
  let scheme = call_593063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593063.url(scheme.get, call_593063.host, call_593063.base,
                         call_593063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593063, url, valid)

proc call*(call_593064: Call_GrantPermissions_593051; body: JsonNode): Recallable =
  ## grantPermissions
  ## <p>Grants permissions to the principal to access metadata in the Data Catalog and data organized in underlying data storage such as Amazon S3.</p> <p>For information about permissions, see <a href="https://docs-aws.amazon.com/michigan/latest/dg/security-data-access.html">Security and Access Control to Metadata and Data</a>.</p>
  ##   body: JObject (required)
  var body_593065 = newJObject()
  if body != nil:
    body_593065 = body
  result = call_593064.call(nil, nil, nil, nil, body_593065)

var grantPermissions* = Call_GrantPermissions_593051(name: "grantPermissions",
    meth: HttpMethod.HttpPost, host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.GrantPermissions",
    validator: validate_GrantPermissions_593052, base: "/",
    url: url_GrantPermissions_593053, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPermissions_593066 = ref object of OpenApiRestCall_592364
proc url_ListPermissions_593068(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPermissions_593067(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Returns a list of the principal permissions on the resource, filtered by the permissions of the caller. For example, if you are granted an ALTER permission, you are able to see only the principal permissions for ALTER.</p> <p>This operation returns only those permissions that have been explicitly granted.</p> <p>For information about permissions, see <a href="https://docs-aws.amazon.com/michigan/latest/dg/security-data-access.html">Security and Access Control to Metadata and Data</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593069 = query.getOrDefault("MaxResults")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "MaxResults", valid_593069
  var valid_593070 = query.getOrDefault("NextToken")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "NextToken", valid_593070
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
  var valid_593071 = header.getOrDefault("X-Amz-Target")
  valid_593071 = validateParameter(valid_593071, JString, required = true, default = newJString(
      "AWSLakeFormation.ListPermissions"))
  if valid_593071 != nil:
    section.add "X-Amz-Target", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-Signature")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-Signature", valid_593072
  var valid_593073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-Content-Sha256", valid_593073
  var valid_593074 = header.getOrDefault("X-Amz-Date")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-Date", valid_593074
  var valid_593075 = header.getOrDefault("X-Amz-Credential")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Credential", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Security-Token")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Security-Token", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-Algorithm")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Algorithm", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-SignedHeaders", valid_593078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593080: Call_ListPermissions_593066; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the principal permissions on the resource, filtered by the permissions of the caller. For example, if you are granted an ALTER permission, you are able to see only the principal permissions for ALTER.</p> <p>This operation returns only those permissions that have been explicitly granted.</p> <p>For information about permissions, see <a href="https://docs-aws.amazon.com/michigan/latest/dg/security-data-access.html">Security and Access Control to Metadata and Data</a>.</p>
  ## 
  let valid = call_593080.validator(path, query, header, formData, body)
  let scheme = call_593080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593080.url(scheme.get, call_593080.host, call_593080.base,
                         call_593080.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593080, url, valid)

proc call*(call_593081: Call_ListPermissions_593066; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPermissions
  ## <p>Returns a list of the principal permissions on the resource, filtered by the permissions of the caller. For example, if you are granted an ALTER permission, you are able to see only the principal permissions for ALTER.</p> <p>This operation returns only those permissions that have been explicitly granted.</p> <p>For information about permissions, see <a href="https://docs-aws.amazon.com/michigan/latest/dg/security-data-access.html">Security and Access Control to Metadata and Data</a>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593082 = newJObject()
  var body_593083 = newJObject()
  add(query_593082, "MaxResults", newJString(MaxResults))
  add(query_593082, "NextToken", newJString(NextToken))
  if body != nil:
    body_593083 = body
  result = call_593081.call(nil, query_593082, nil, nil, body_593083)

var listPermissions* = Call_ListPermissions_593066(name: "listPermissions",
    meth: HttpMethod.HttpPost, host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.ListPermissions",
    validator: validate_ListPermissions_593067, base: "/", url: url_ListPermissions_593068,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResources_593084 = ref object of OpenApiRestCall_592364
proc url_ListResources_593086(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResources_593085(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the resources registered to be managed by the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593087 = query.getOrDefault("MaxResults")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "MaxResults", valid_593087
  var valid_593088 = query.getOrDefault("NextToken")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "NextToken", valid_593088
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
  var valid_593089 = header.getOrDefault("X-Amz-Target")
  valid_593089 = validateParameter(valid_593089, JString, required = true, default = newJString(
      "AWSLakeFormation.ListResources"))
  if valid_593089 != nil:
    section.add "X-Amz-Target", valid_593089
  var valid_593090 = header.getOrDefault("X-Amz-Signature")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-Signature", valid_593090
  var valid_593091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593091 = validateParameter(valid_593091, JString, required = false,
                                 default = nil)
  if valid_593091 != nil:
    section.add "X-Amz-Content-Sha256", valid_593091
  var valid_593092 = header.getOrDefault("X-Amz-Date")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-Date", valid_593092
  var valid_593093 = header.getOrDefault("X-Amz-Credential")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "X-Amz-Credential", valid_593093
  var valid_593094 = header.getOrDefault("X-Amz-Security-Token")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "X-Amz-Security-Token", valid_593094
  var valid_593095 = header.getOrDefault("X-Amz-Algorithm")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-Algorithm", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-SignedHeaders", valid_593096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593098: Call_ListResources_593084; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resources registered to be managed by the Data Catalog.
  ## 
  let valid = call_593098.validator(path, query, header, formData, body)
  let scheme = call_593098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593098.url(scheme.get, call_593098.host, call_593098.base,
                         call_593098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593098, url, valid)

proc call*(call_593099: Call_ListResources_593084; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listResources
  ## Lists the resources registered to be managed by the Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593100 = newJObject()
  var body_593101 = newJObject()
  add(query_593100, "MaxResults", newJString(MaxResults))
  add(query_593100, "NextToken", newJString(NextToken))
  if body != nil:
    body_593101 = body
  result = call_593099.call(nil, query_593100, nil, nil, body_593101)

var listResources* = Call_ListResources_593084(name: "listResources",
    meth: HttpMethod.HttpPost, host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.ListResources",
    validator: validate_ListResources_593085, base: "/", url: url_ListResources_593086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDataLakeSettings_593102 = ref object of OpenApiRestCall_592364
proc url_PutDataLakeSettings_593104(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutDataLakeSettings_593103(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## The AWS Lake Formation principal.
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
  var valid_593105 = header.getOrDefault("X-Amz-Target")
  valid_593105 = validateParameter(valid_593105, JString, required = true, default = newJString(
      "AWSLakeFormation.PutDataLakeSettings"))
  if valid_593105 != nil:
    section.add "X-Amz-Target", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-Signature")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-Signature", valid_593106
  var valid_593107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-Content-Sha256", valid_593107
  var valid_593108 = header.getOrDefault("X-Amz-Date")
  valid_593108 = validateParameter(valid_593108, JString, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "X-Amz-Date", valid_593108
  var valid_593109 = header.getOrDefault("X-Amz-Credential")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "X-Amz-Credential", valid_593109
  var valid_593110 = header.getOrDefault("X-Amz-Security-Token")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "X-Amz-Security-Token", valid_593110
  var valid_593111 = header.getOrDefault("X-Amz-Algorithm")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-Algorithm", valid_593111
  var valid_593112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-SignedHeaders", valid_593112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593114: Call_PutDataLakeSettings_593102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The AWS Lake Formation principal.
  ## 
  let valid = call_593114.validator(path, query, header, formData, body)
  let scheme = call_593114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593114.url(scheme.get, call_593114.host, call_593114.base,
                         call_593114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593114, url, valid)

proc call*(call_593115: Call_PutDataLakeSettings_593102; body: JsonNode): Recallable =
  ## putDataLakeSettings
  ## The AWS Lake Formation principal.
  ##   body: JObject (required)
  var body_593116 = newJObject()
  if body != nil:
    body_593116 = body
  result = call_593115.call(nil, nil, nil, nil, body_593116)

var putDataLakeSettings* = Call_PutDataLakeSettings_593102(
    name: "putDataLakeSettings", meth: HttpMethod.HttpPost,
    host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.PutDataLakeSettings",
    validator: validate_PutDataLakeSettings_593103, base: "/",
    url: url_PutDataLakeSettings_593104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterResource_593117 = ref object of OpenApiRestCall_592364
proc url_RegisterResource_593119(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterResource_593118(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Registers the resource as managed by the Data Catalog.</p> <p>To add or update data, Lake Formation needs read/write access to the chosen Amazon S3 path. Choose a role that you know has permission to do this, or choose the AWSServiceRoleForLakeFormationDataAccess service-linked role. When you register the first Amazon S3 path, the service-linked role and a new inline policy are created on your behalf. Lake Formation adds the first path to the inline policy and attaches it to the service-linked role. When you register subsequent paths, Lake Formation adds the path to the existing policy.</p>
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
  var valid_593120 = header.getOrDefault("X-Amz-Target")
  valid_593120 = validateParameter(valid_593120, JString, required = true, default = newJString(
      "AWSLakeFormation.RegisterResource"))
  if valid_593120 != nil:
    section.add "X-Amz-Target", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-Signature")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-Signature", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Content-Sha256", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-Date")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-Date", valid_593123
  var valid_593124 = header.getOrDefault("X-Amz-Credential")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "X-Amz-Credential", valid_593124
  var valid_593125 = header.getOrDefault("X-Amz-Security-Token")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-Security-Token", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-Algorithm")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Algorithm", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-SignedHeaders", valid_593127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593129: Call_RegisterResource_593117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the resource as managed by the Data Catalog.</p> <p>To add or update data, Lake Formation needs read/write access to the chosen Amazon S3 path. Choose a role that you know has permission to do this, or choose the AWSServiceRoleForLakeFormationDataAccess service-linked role. When you register the first Amazon S3 path, the service-linked role and a new inline policy are created on your behalf. Lake Formation adds the first path to the inline policy and attaches it to the service-linked role. When you register subsequent paths, Lake Formation adds the path to the existing policy.</p>
  ## 
  let valid = call_593129.validator(path, query, header, formData, body)
  let scheme = call_593129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593129.url(scheme.get, call_593129.host, call_593129.base,
                         call_593129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593129, url, valid)

proc call*(call_593130: Call_RegisterResource_593117; body: JsonNode): Recallable =
  ## registerResource
  ## <p>Registers the resource as managed by the Data Catalog.</p> <p>To add or update data, Lake Formation needs read/write access to the chosen Amazon S3 path. Choose a role that you know has permission to do this, or choose the AWSServiceRoleForLakeFormationDataAccess service-linked role. When you register the first Amazon S3 path, the service-linked role and a new inline policy are created on your behalf. Lake Formation adds the first path to the inline policy and attaches it to the service-linked role. When you register subsequent paths, Lake Formation adds the path to the existing policy.</p>
  ##   body: JObject (required)
  var body_593131 = newJObject()
  if body != nil:
    body_593131 = body
  result = call_593130.call(nil, nil, nil, nil, body_593131)

var registerResource* = Call_RegisterResource_593117(name: "registerResource",
    meth: HttpMethod.HttpPost, host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.RegisterResource",
    validator: validate_RegisterResource_593118, base: "/",
    url: url_RegisterResource_593119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokePermissions_593132 = ref object of OpenApiRestCall_592364
proc url_RevokePermissions_593134(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RevokePermissions_593133(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Revokes permissions to the principal to access metadata in the Data Catalog and data organized in underlying data storage such as Amazon S3.
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
  var valid_593135 = header.getOrDefault("X-Amz-Target")
  valid_593135 = validateParameter(valid_593135, JString, required = true, default = newJString(
      "AWSLakeFormation.RevokePermissions"))
  if valid_593135 != nil:
    section.add "X-Amz-Target", valid_593135
  var valid_593136 = header.getOrDefault("X-Amz-Signature")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "X-Amz-Signature", valid_593136
  var valid_593137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Content-Sha256", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-Date")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Date", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-Credential")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Credential", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-Security-Token")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Security-Token", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-Algorithm")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-Algorithm", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-SignedHeaders", valid_593142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593144: Call_RevokePermissions_593132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes permissions to the principal to access metadata in the Data Catalog and data organized in underlying data storage such as Amazon S3.
  ## 
  let valid = call_593144.validator(path, query, header, formData, body)
  let scheme = call_593144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593144.url(scheme.get, call_593144.host, call_593144.base,
                         call_593144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593144, url, valid)

proc call*(call_593145: Call_RevokePermissions_593132; body: JsonNode): Recallable =
  ## revokePermissions
  ## Revokes permissions to the principal to access metadata in the Data Catalog and data organized in underlying data storage such as Amazon S3.
  ##   body: JObject (required)
  var body_593146 = newJObject()
  if body != nil:
    body_593146 = body
  result = call_593145.call(nil, nil, nil, nil, body_593146)

var revokePermissions* = Call_RevokePermissions_593132(name: "revokePermissions",
    meth: HttpMethod.HttpPost, host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.RevokePermissions",
    validator: validate_RevokePermissions_593133, base: "/",
    url: url_RevokePermissions_593134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResource_593147 = ref object of OpenApiRestCall_592364
proc url_UpdateResource_593149(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateResource_593148(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates the data access role used for vending access to the given (registered) resource in AWS Lake Formation. 
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
  var valid_593150 = header.getOrDefault("X-Amz-Target")
  valid_593150 = validateParameter(valid_593150, JString, required = true, default = newJString(
      "AWSLakeFormation.UpdateResource"))
  if valid_593150 != nil:
    section.add "X-Amz-Target", valid_593150
  var valid_593151 = header.getOrDefault("X-Amz-Signature")
  valid_593151 = validateParameter(valid_593151, JString, required = false,
                                 default = nil)
  if valid_593151 != nil:
    section.add "X-Amz-Signature", valid_593151
  var valid_593152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "X-Amz-Content-Sha256", valid_593152
  var valid_593153 = header.getOrDefault("X-Amz-Date")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "X-Amz-Date", valid_593153
  var valid_593154 = header.getOrDefault("X-Amz-Credential")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "X-Amz-Credential", valid_593154
  var valid_593155 = header.getOrDefault("X-Amz-Security-Token")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "X-Amz-Security-Token", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-Algorithm")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Algorithm", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-SignedHeaders", valid_593157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593159: Call_UpdateResource_593147; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the data access role used for vending access to the given (registered) resource in AWS Lake Formation. 
  ## 
  let valid = call_593159.validator(path, query, header, formData, body)
  let scheme = call_593159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593159.url(scheme.get, call_593159.host, call_593159.base,
                         call_593159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593159, url, valid)

proc call*(call_593160: Call_UpdateResource_593147; body: JsonNode): Recallable =
  ## updateResource
  ## Updates the data access role used for vending access to the given (registered) resource in AWS Lake Formation. 
  ##   body: JObject (required)
  var body_593161 = newJObject()
  if body != nil:
    body_593161 = body
  result = call_593160.call(nil, nil, nil, nil, body_593161)

var updateResource* = Call_UpdateResource_593147(name: "updateResource",
    meth: HttpMethod.HttpPost, host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.UpdateResource",
    validator: validate_UpdateResource_593148, base: "/", url: url_UpdateResource_593149,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
