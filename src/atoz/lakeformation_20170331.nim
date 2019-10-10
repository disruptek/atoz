
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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
  Call_BatchGrantPermissions_602803 = ref object of OpenApiRestCall_602466
proc url_BatchGrantPermissions_602805(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGrantPermissions_602804(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602932 = header.getOrDefault("X-Amz-Target")
  valid_602932 = validateParameter(valid_602932, JString, required = true, default = newJString(
      "AWSLakeFormation.BatchGrantPermissions"))
  if valid_602932 != nil:
    section.add "X-Amz-Target", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Content-Sha256", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Algorithm")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Algorithm", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_BatchGrantPermissions_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Batch operation to grant permissions to the principal.
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_BatchGrantPermissions_602803; body: JsonNode): Recallable =
  ## batchGrantPermissions
  ## Batch operation to grant permissions to the principal.
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var batchGrantPermissions* = Call_BatchGrantPermissions_602803(
    name: "batchGrantPermissions", meth: HttpMethod.HttpPost,
    host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.BatchGrantPermissions",
    validator: validate_BatchGrantPermissions_602804, base: "/",
    url: url_BatchGrantPermissions_602805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchRevokePermissions_603072 = ref object of OpenApiRestCall_602466
proc url_BatchRevokePermissions_603074(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchRevokePermissions_603073(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603075 = header.getOrDefault("X-Amz-Date")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Date", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Security-Token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Security-Token", valid_603076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603077 = header.getOrDefault("X-Amz-Target")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "AWSLakeFormation.BatchRevokePermissions"))
  if valid_603077 != nil:
    section.add "X-Amz-Target", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_BatchRevokePermissions_603072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Batch operation to revoke permissions from the principal.
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_BatchRevokePermissions_603072; body: JsonNode): Recallable =
  ## batchRevokePermissions
  ## Batch operation to revoke permissions from the principal.
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var batchRevokePermissions* = Call_BatchRevokePermissions_603072(
    name: "batchRevokePermissions", meth: HttpMethod.HttpPost,
    host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.BatchRevokePermissions",
    validator: validate_BatchRevokePermissions_603073, base: "/",
    url: url_BatchRevokePermissions_603074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterResource_603087 = ref object of OpenApiRestCall_602466
proc url_DeregisterResource_603089(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeregisterResource_603088(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603092 = header.getOrDefault("X-Amz-Target")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "AWSLakeFormation.DeregisterResource"))
  if valid_603092 != nil:
    section.add "X-Amz-Target", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_DeregisterResource_603087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deregisters the resource as managed by the Data Catalog.</p> <p>When you deregister a path, Lake Formation removes the path from the inline policy attached to your service-linked role.</p>
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_DeregisterResource_603087; body: JsonNode): Recallable =
  ## deregisterResource
  ## <p>Deregisters the resource as managed by the Data Catalog.</p> <p>When you deregister a path, Lake Formation removes the path from the inline policy attached to your service-linked role.</p>
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var deregisterResource* = Call_DeregisterResource_603087(
    name: "deregisterResource", meth: HttpMethod.HttpPost,
    host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.DeregisterResource",
    validator: validate_DeregisterResource_603088, base: "/",
    url: url_DeregisterResource_603089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResource_603102 = ref object of OpenApiRestCall_602466
proc url_DescribeResource_603104(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeResource_603103(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603107 = header.getOrDefault("X-Amz-Target")
  valid_603107 = validateParameter(valid_603107, JString, required = true, default = newJString(
      "AWSLakeFormation.DescribeResource"))
  if valid_603107 != nil:
    section.add "X-Amz-Target", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Content-Sha256", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Algorithm")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Algorithm", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_DescribeResource_603102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current data access role for the given resource registered in AWS Lake Formation.
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_DescribeResource_603102; body: JsonNode): Recallable =
  ## describeResource
  ## Retrieves the current data access role for the given resource registered in AWS Lake Formation.
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var describeResource* = Call_DescribeResource_603102(name: "describeResource",
    meth: HttpMethod.HttpPost, host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.DescribeResource",
    validator: validate_DescribeResource_603103, base: "/",
    url: url_DescribeResource_603104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataLakeSettings_603117 = ref object of OpenApiRestCall_602466
proc url_GetDataLakeSettings_603119(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDataLakeSettings_603118(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603122 = header.getOrDefault("X-Amz-Target")
  valid_603122 = validateParameter(valid_603122, JString, required = true, default = newJString(
      "AWSLakeFormation.GetDataLakeSettings"))
  if valid_603122 != nil:
    section.add "X-Amz-Target", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Content-Sha256", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-SignedHeaders", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_GetDataLakeSettings_603117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The AWS Lake Formation principal.
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_GetDataLakeSettings_603117; body: JsonNode): Recallable =
  ## getDataLakeSettings
  ## The AWS Lake Formation principal.
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var getDataLakeSettings* = Call_GetDataLakeSettings_603117(
    name: "getDataLakeSettings", meth: HttpMethod.HttpPost,
    host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.GetDataLakeSettings",
    validator: validate_GetDataLakeSettings_603118, base: "/",
    url: url_GetDataLakeSettings_603119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEffectivePermissionsForPath_603132 = ref object of OpenApiRestCall_602466
proc url_GetEffectivePermissionsForPath_603134(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetEffectivePermissionsForPath_603133(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603135 = query.getOrDefault("NextToken")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "NextToken", valid_603135
  var valid_603136 = query.getOrDefault("MaxResults")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "MaxResults", valid_603136
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
  var valid_603137 = header.getOrDefault("X-Amz-Date")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Date", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Security-Token")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Security-Token", valid_603138
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603139 = header.getOrDefault("X-Amz-Target")
  valid_603139 = validateParameter(valid_603139, JString, required = true, default = newJString(
      "AWSLakeFormation.GetEffectivePermissionsForPath"))
  if valid_603139 != nil:
    section.add "X-Amz-Target", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Content-Sha256", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Algorithm")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Algorithm", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Signature")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Signature", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-SignedHeaders", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-Credential")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Credential", valid_603144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603146: Call_GetEffectivePermissionsForPath_603132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the permissions for a specified table or database resource located at a path in Amazon S3.
  ## 
  let valid = call_603146.validator(path, query, header, formData, body)
  let scheme = call_603146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603146.url(scheme.get, call_603146.host, call_603146.base,
                         call_603146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603146, url, valid)

proc call*(call_603147: Call_GetEffectivePermissionsForPath_603132; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getEffectivePermissionsForPath
  ## Returns the permissions for a specified table or database resource located at a path in Amazon S3.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603148 = newJObject()
  var body_603149 = newJObject()
  add(query_603148, "NextToken", newJString(NextToken))
  if body != nil:
    body_603149 = body
  add(query_603148, "MaxResults", newJString(MaxResults))
  result = call_603147.call(nil, query_603148, nil, nil, body_603149)

var getEffectivePermissionsForPath* = Call_GetEffectivePermissionsForPath_603132(
    name: "getEffectivePermissionsForPath", meth: HttpMethod.HttpPost,
    host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.GetEffectivePermissionsForPath",
    validator: validate_GetEffectivePermissionsForPath_603133, base: "/",
    url: url_GetEffectivePermissionsForPath_603134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GrantPermissions_603151 = ref object of OpenApiRestCall_602466
proc url_GrantPermissions_603153(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GrantPermissions_603152(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603154 = header.getOrDefault("X-Amz-Date")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Date", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Security-Token")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Security-Token", valid_603155
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603156 = header.getOrDefault("X-Amz-Target")
  valid_603156 = validateParameter(valid_603156, JString, required = true, default = newJString(
      "AWSLakeFormation.GrantPermissions"))
  if valid_603156 != nil:
    section.add "X-Amz-Target", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Content-Sha256", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-Algorithm")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-Algorithm", valid_603158
  var valid_603159 = header.getOrDefault("X-Amz-Signature")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-Signature", valid_603159
  var valid_603160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-SignedHeaders", valid_603160
  var valid_603161 = header.getOrDefault("X-Amz-Credential")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-Credential", valid_603161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603163: Call_GrantPermissions_603151; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Grants permissions to the principal to access metadata in the Data Catalog and data organized in underlying data storage such as Amazon S3.</p> <p>For information about permissions, see <a href="https://docs-aws.amazon.com/michigan/latest/dg/security-data-access.html">Security and Access Control to Metadata and Data</a>.</p>
  ## 
  let valid = call_603163.validator(path, query, header, formData, body)
  let scheme = call_603163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603163.url(scheme.get, call_603163.host, call_603163.base,
                         call_603163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603163, url, valid)

proc call*(call_603164: Call_GrantPermissions_603151; body: JsonNode): Recallable =
  ## grantPermissions
  ## <p>Grants permissions to the principal to access metadata in the Data Catalog and data organized in underlying data storage such as Amazon S3.</p> <p>For information about permissions, see <a href="https://docs-aws.amazon.com/michigan/latest/dg/security-data-access.html">Security and Access Control to Metadata and Data</a>.</p>
  ##   body: JObject (required)
  var body_603165 = newJObject()
  if body != nil:
    body_603165 = body
  result = call_603164.call(nil, nil, nil, nil, body_603165)

var grantPermissions* = Call_GrantPermissions_603151(name: "grantPermissions",
    meth: HttpMethod.HttpPost, host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.GrantPermissions",
    validator: validate_GrantPermissions_603152, base: "/",
    url: url_GrantPermissions_603153, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPermissions_603166 = ref object of OpenApiRestCall_602466
proc url_ListPermissions_603168(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPermissions_603167(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_603169 = query.getOrDefault("NextToken")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "NextToken", valid_603169
  var valid_603170 = query.getOrDefault("MaxResults")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "MaxResults", valid_603170
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
  var valid_603171 = header.getOrDefault("X-Amz-Date")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Date", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Security-Token")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Security-Token", valid_603172
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603173 = header.getOrDefault("X-Amz-Target")
  valid_603173 = validateParameter(valid_603173, JString, required = true, default = newJString(
      "AWSLakeFormation.ListPermissions"))
  if valid_603173 != nil:
    section.add "X-Amz-Target", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Content-Sha256", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-Algorithm")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Algorithm", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Signature")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Signature", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-SignedHeaders", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Credential")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Credential", valid_603178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603180: Call_ListPermissions_603166; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the principal permissions on the resource, filtered by the permissions of the caller. For example, if you are granted an ALTER permission, you are able to see only the principal permissions for ALTER.</p> <p>This operation returns only those permissions that have been explicitly granted.</p> <p>For information about permissions, see <a href="https://docs-aws.amazon.com/michigan/latest/dg/security-data-access.html">Security and Access Control to Metadata and Data</a>.</p>
  ## 
  let valid = call_603180.validator(path, query, header, formData, body)
  let scheme = call_603180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603180.url(scheme.get, call_603180.host, call_603180.base,
                         call_603180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603180, url, valid)

proc call*(call_603181: Call_ListPermissions_603166; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listPermissions
  ## <p>Returns a list of the principal permissions on the resource, filtered by the permissions of the caller. For example, if you are granted an ALTER permission, you are able to see only the principal permissions for ALTER.</p> <p>This operation returns only those permissions that have been explicitly granted.</p> <p>For information about permissions, see <a href="https://docs-aws.amazon.com/michigan/latest/dg/security-data-access.html">Security and Access Control to Metadata and Data</a>.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603182 = newJObject()
  var body_603183 = newJObject()
  add(query_603182, "NextToken", newJString(NextToken))
  if body != nil:
    body_603183 = body
  add(query_603182, "MaxResults", newJString(MaxResults))
  result = call_603181.call(nil, query_603182, nil, nil, body_603183)

var listPermissions* = Call_ListPermissions_603166(name: "listPermissions",
    meth: HttpMethod.HttpPost, host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.ListPermissions",
    validator: validate_ListPermissions_603167, base: "/", url: url_ListPermissions_603168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResources_603184 = ref object of OpenApiRestCall_602466
proc url_ListResources_603186(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResources_603185(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603187 = query.getOrDefault("NextToken")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "NextToken", valid_603187
  var valid_603188 = query.getOrDefault("MaxResults")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "MaxResults", valid_603188
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
  var valid_603189 = header.getOrDefault("X-Amz-Date")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Date", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Security-Token")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Security-Token", valid_603190
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603191 = header.getOrDefault("X-Amz-Target")
  valid_603191 = validateParameter(valid_603191, JString, required = true, default = newJString(
      "AWSLakeFormation.ListResources"))
  if valid_603191 != nil:
    section.add "X-Amz-Target", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Content-Sha256", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Algorithm")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Algorithm", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-Signature")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Signature", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-SignedHeaders", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Credential")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Credential", valid_603196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603198: Call_ListResources_603184; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resources registered to be managed by the Data Catalog.
  ## 
  let valid = call_603198.validator(path, query, header, formData, body)
  let scheme = call_603198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603198.url(scheme.get, call_603198.host, call_603198.base,
                         call_603198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603198, url, valid)

proc call*(call_603199: Call_ListResources_603184; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listResources
  ## Lists the resources registered to be managed by the Data Catalog.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603200 = newJObject()
  var body_603201 = newJObject()
  add(query_603200, "NextToken", newJString(NextToken))
  if body != nil:
    body_603201 = body
  add(query_603200, "MaxResults", newJString(MaxResults))
  result = call_603199.call(nil, query_603200, nil, nil, body_603201)

var listResources* = Call_ListResources_603184(name: "listResources",
    meth: HttpMethod.HttpPost, host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.ListResources",
    validator: validate_ListResources_603185, base: "/", url: url_ListResources_603186,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDataLakeSettings_603202 = ref object of OpenApiRestCall_602466
proc url_PutDataLakeSettings_603204(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutDataLakeSettings_603203(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603205 = header.getOrDefault("X-Amz-Date")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Date", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Security-Token")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Security-Token", valid_603206
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603207 = header.getOrDefault("X-Amz-Target")
  valid_603207 = validateParameter(valid_603207, JString, required = true, default = newJString(
      "AWSLakeFormation.PutDataLakeSettings"))
  if valid_603207 != nil:
    section.add "X-Amz-Target", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Content-Sha256", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Algorithm")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Algorithm", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-Signature")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Signature", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-SignedHeaders", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Credential")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Credential", valid_603212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603214: Call_PutDataLakeSettings_603202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The AWS Lake Formation principal.
  ## 
  let valid = call_603214.validator(path, query, header, formData, body)
  let scheme = call_603214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603214.url(scheme.get, call_603214.host, call_603214.base,
                         call_603214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603214, url, valid)

proc call*(call_603215: Call_PutDataLakeSettings_603202; body: JsonNode): Recallable =
  ## putDataLakeSettings
  ## The AWS Lake Formation principal.
  ##   body: JObject (required)
  var body_603216 = newJObject()
  if body != nil:
    body_603216 = body
  result = call_603215.call(nil, nil, nil, nil, body_603216)

var putDataLakeSettings* = Call_PutDataLakeSettings_603202(
    name: "putDataLakeSettings", meth: HttpMethod.HttpPost,
    host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.PutDataLakeSettings",
    validator: validate_PutDataLakeSettings_603203, base: "/",
    url: url_PutDataLakeSettings_603204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterResource_603217 = ref object of OpenApiRestCall_602466
proc url_RegisterResource_603219(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterResource_603218(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603220 = header.getOrDefault("X-Amz-Date")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Date", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Security-Token")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Security-Token", valid_603221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603222 = header.getOrDefault("X-Amz-Target")
  valid_603222 = validateParameter(valid_603222, JString, required = true, default = newJString(
      "AWSLakeFormation.RegisterResource"))
  if valid_603222 != nil:
    section.add "X-Amz-Target", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Content-Sha256", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-Algorithm")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Algorithm", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Signature")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Signature", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-SignedHeaders", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-Credential")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Credential", valid_603227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603229: Call_RegisterResource_603217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the resource as managed by the Data Catalog.</p> <p>To add or update data, Lake Formation needs read/write access to the chosen Amazon S3 path. Choose a role that you know has permission to do this, or choose the AWSServiceRoleForLakeFormationDataAccess service-linked role. When you register the first Amazon S3 path, the service-linked role and a new inline policy are created on your behalf. Lake Formation adds the first path to the inline policy and attaches it to the service-linked role. When you register subsequent paths, Lake Formation adds the path to the existing policy.</p>
  ## 
  let valid = call_603229.validator(path, query, header, formData, body)
  let scheme = call_603229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603229.url(scheme.get, call_603229.host, call_603229.base,
                         call_603229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603229, url, valid)

proc call*(call_603230: Call_RegisterResource_603217; body: JsonNode): Recallable =
  ## registerResource
  ## <p>Registers the resource as managed by the Data Catalog.</p> <p>To add or update data, Lake Formation needs read/write access to the chosen Amazon S3 path. Choose a role that you know has permission to do this, or choose the AWSServiceRoleForLakeFormationDataAccess service-linked role. When you register the first Amazon S3 path, the service-linked role and a new inline policy are created on your behalf. Lake Formation adds the first path to the inline policy and attaches it to the service-linked role. When you register subsequent paths, Lake Formation adds the path to the existing policy.</p>
  ##   body: JObject (required)
  var body_603231 = newJObject()
  if body != nil:
    body_603231 = body
  result = call_603230.call(nil, nil, nil, nil, body_603231)

var registerResource* = Call_RegisterResource_603217(name: "registerResource",
    meth: HttpMethod.HttpPost, host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.RegisterResource",
    validator: validate_RegisterResource_603218, base: "/",
    url: url_RegisterResource_603219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokePermissions_603232 = ref object of OpenApiRestCall_602466
proc url_RevokePermissions_603234(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RevokePermissions_603233(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603235 = header.getOrDefault("X-Amz-Date")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Date", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Security-Token")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Security-Token", valid_603236
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603237 = header.getOrDefault("X-Amz-Target")
  valid_603237 = validateParameter(valid_603237, JString, required = true, default = newJString(
      "AWSLakeFormation.RevokePermissions"))
  if valid_603237 != nil:
    section.add "X-Amz-Target", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Content-Sha256", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-Algorithm")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Algorithm", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Signature")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Signature", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-SignedHeaders", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Credential")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Credential", valid_603242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603244: Call_RevokePermissions_603232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes permissions to the principal to access metadata in the Data Catalog and data organized in underlying data storage such as Amazon S3.
  ## 
  let valid = call_603244.validator(path, query, header, formData, body)
  let scheme = call_603244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603244.url(scheme.get, call_603244.host, call_603244.base,
                         call_603244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603244, url, valid)

proc call*(call_603245: Call_RevokePermissions_603232; body: JsonNode): Recallable =
  ## revokePermissions
  ## Revokes permissions to the principal to access metadata in the Data Catalog and data organized in underlying data storage such as Amazon S3.
  ##   body: JObject (required)
  var body_603246 = newJObject()
  if body != nil:
    body_603246 = body
  result = call_603245.call(nil, nil, nil, nil, body_603246)

var revokePermissions* = Call_RevokePermissions_603232(name: "revokePermissions",
    meth: HttpMethod.HttpPost, host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.RevokePermissions",
    validator: validate_RevokePermissions_603233, base: "/",
    url: url_RevokePermissions_603234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResource_603247 = ref object of OpenApiRestCall_602466
proc url_UpdateResource_603249(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateResource_603248(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603250 = header.getOrDefault("X-Amz-Date")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-Date", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-Security-Token")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Security-Token", valid_603251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603252 = header.getOrDefault("X-Amz-Target")
  valid_603252 = validateParameter(valid_603252, JString, required = true, default = newJString(
      "AWSLakeFormation.UpdateResource"))
  if valid_603252 != nil:
    section.add "X-Amz-Target", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Content-Sha256", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-Algorithm")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Algorithm", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Signature")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Signature", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-SignedHeaders", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Credential")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Credential", valid_603257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603259: Call_UpdateResource_603247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the data access role used for vending access to the given (registered) resource in AWS Lake Formation. 
  ## 
  let valid = call_603259.validator(path, query, header, formData, body)
  let scheme = call_603259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603259.url(scheme.get, call_603259.host, call_603259.base,
                         call_603259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603259, url, valid)

proc call*(call_603260: Call_UpdateResource_603247; body: JsonNode): Recallable =
  ## updateResource
  ## Updates the data access role used for vending access to the given (registered) resource in AWS Lake Formation. 
  ##   body: JObject (required)
  var body_603261 = newJObject()
  if body != nil:
    body_603261 = body
  result = call_603260.call(nil, nil, nil, nil, body_603261)

var updateResource* = Call_UpdateResource_603247(name: "updateResource",
    meth: HttpMethod.HttpPost, host: "lakeformation.amazonaws.com",
    route: "/#X-Amz-Target=AWSLakeFormation.UpdateResource",
    validator: validate_UpdateResource_603248, base: "/", url: url_UpdateResource_603249,
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
