
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Migration Hub Config
## version: 2019-06-30
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>The AWS Migration Hub home region APIs are available specifically for working with your Migration Hub home region. You can use these APIs to determine a home region, as well as to create and work with controls that describe the home region.</p> <p>You can use these APIs within your home region only. If you call these APIs from outside your home region, your calls are rejected, except for the ability to register your agents and connectors. </p> <p> You must call <code>GetHomeRegion</code> at least once before you call any other AWS Application Discovery Service and AWS Migration Hub APIs, to obtain the account's Migration Hub home region.</p> <p>The <code>StartDataCollection</code> API call in AWS Application Discovery Service allows your agents and connectors to begin collecting data that flows directly into the home region, and it will prevent you from enabling data collection information to be sent outside the home region. </p> <p>For specific API usage, see the sections that follow in this AWS Migration Hub Home Region API reference. </p> <note> <p>The Migration Hub Home Region APIs do not support AWS Organizations.</p> </note>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/migrationhub-config/
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

  OpenApiRestCall_605580 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605580](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605580): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "migrationhub-config.ap-northeast-1.amazonaws.com", "ap-southeast-1": "migrationhub-config.ap-southeast-1.amazonaws.com", "us-west-2": "migrationhub-config.us-west-2.amazonaws.com", "eu-west-2": "migrationhub-config.eu-west-2.amazonaws.com", "ap-northeast-3": "migrationhub-config.ap-northeast-3.amazonaws.com", "eu-central-1": "migrationhub-config.eu-central-1.amazonaws.com", "us-east-2": "migrationhub-config.us-east-2.amazonaws.com", "us-east-1": "migrationhub-config.us-east-1.amazonaws.com", "cn-northwest-1": "migrationhub-config.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "migrationhub-config.ap-south-1.amazonaws.com", "eu-north-1": "migrationhub-config.eu-north-1.amazonaws.com", "ap-northeast-2": "migrationhub-config.ap-northeast-2.amazonaws.com", "us-west-1": "migrationhub-config.us-west-1.amazonaws.com", "us-gov-east-1": "migrationhub-config.us-gov-east-1.amazonaws.com", "eu-west-3": "migrationhub-config.eu-west-3.amazonaws.com", "cn-north-1": "migrationhub-config.cn-north-1.amazonaws.com.cn", "sa-east-1": "migrationhub-config.sa-east-1.amazonaws.com", "eu-west-1": "migrationhub-config.eu-west-1.amazonaws.com", "us-gov-west-1": "migrationhub-config.us-gov-west-1.amazonaws.com", "ap-southeast-2": "migrationhub-config.ap-southeast-2.amazonaws.com", "ca-central-1": "migrationhub-config.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "migrationhub-config.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "migrationhub-config.ap-southeast-1.amazonaws.com",
      "us-west-2": "migrationhub-config.us-west-2.amazonaws.com",
      "eu-west-2": "migrationhub-config.eu-west-2.amazonaws.com",
      "ap-northeast-3": "migrationhub-config.ap-northeast-3.amazonaws.com",
      "eu-central-1": "migrationhub-config.eu-central-1.amazonaws.com",
      "us-east-2": "migrationhub-config.us-east-2.amazonaws.com",
      "us-east-1": "migrationhub-config.us-east-1.amazonaws.com",
      "cn-northwest-1": "migrationhub-config.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "migrationhub-config.ap-south-1.amazonaws.com",
      "eu-north-1": "migrationhub-config.eu-north-1.amazonaws.com",
      "ap-northeast-2": "migrationhub-config.ap-northeast-2.amazonaws.com",
      "us-west-1": "migrationhub-config.us-west-1.amazonaws.com",
      "us-gov-east-1": "migrationhub-config.us-gov-east-1.amazonaws.com",
      "eu-west-3": "migrationhub-config.eu-west-3.amazonaws.com",
      "cn-north-1": "migrationhub-config.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "migrationhub-config.sa-east-1.amazonaws.com",
      "eu-west-1": "migrationhub-config.eu-west-1.amazonaws.com",
      "us-gov-west-1": "migrationhub-config.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "migrationhub-config.ap-southeast-2.amazonaws.com",
      "ca-central-1": "migrationhub-config.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "migrationhub-config"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateHomeRegionControl_605918 = ref object of OpenApiRestCall_605580
proc url_CreateHomeRegionControl_605920(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateHomeRegionControl_605919(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This API sets up the home region for the calling account only.
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
  var valid_606045 = header.getOrDefault("X-Amz-Target")
  valid_606045 = validateParameter(valid_606045, JString, required = true, default = newJString(
      "AWSMigrationHubMultiAccountService.CreateHomeRegionControl"))
  if valid_606045 != nil:
    section.add "X-Amz-Target", valid_606045
  var valid_606046 = header.getOrDefault("X-Amz-Signature")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "X-Amz-Signature", valid_606046
  var valid_606047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-Content-Sha256", valid_606047
  var valid_606048 = header.getOrDefault("X-Amz-Date")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amz-Date", valid_606048
  var valid_606049 = header.getOrDefault("X-Amz-Credential")
  valid_606049 = validateParameter(valid_606049, JString, required = false,
                                 default = nil)
  if valid_606049 != nil:
    section.add "X-Amz-Credential", valid_606049
  var valid_606050 = header.getOrDefault("X-Amz-Security-Token")
  valid_606050 = validateParameter(valid_606050, JString, required = false,
                                 default = nil)
  if valid_606050 != nil:
    section.add "X-Amz-Security-Token", valid_606050
  var valid_606051 = header.getOrDefault("X-Amz-Algorithm")
  valid_606051 = validateParameter(valid_606051, JString, required = false,
                                 default = nil)
  if valid_606051 != nil:
    section.add "X-Amz-Algorithm", valid_606051
  var valid_606052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606052 = validateParameter(valid_606052, JString, required = false,
                                 default = nil)
  if valid_606052 != nil:
    section.add "X-Amz-SignedHeaders", valid_606052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606076: Call_CreateHomeRegionControl_605918; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This API sets up the home region for the calling account only.
  ## 
  let valid = call_606076.validator(path, query, header, formData, body)
  let scheme = call_606076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606076.url(scheme.get, call_606076.host, call_606076.base,
                         call_606076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606076, url, valid)

proc call*(call_606147: Call_CreateHomeRegionControl_605918; body: JsonNode): Recallable =
  ## createHomeRegionControl
  ## This API sets up the home region for the calling account only.
  ##   body: JObject (required)
  var body_606148 = newJObject()
  if body != nil:
    body_606148 = body
  result = call_606147.call(nil, nil, nil, nil, body_606148)

var createHomeRegionControl* = Call_CreateHomeRegionControl_605918(
    name: "createHomeRegionControl", meth: HttpMethod.HttpPost,
    host: "migrationhub-config.amazonaws.com", route: "/#X-Amz-Target=AWSMigrationHubMultiAccountService.CreateHomeRegionControl",
    validator: validate_CreateHomeRegionControl_605919, base: "/",
    url: url_CreateHomeRegionControl_605920, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHomeRegionControls_606187 = ref object of OpenApiRestCall_605580
proc url_DescribeHomeRegionControls_606189(protocol: Scheme; host: string;
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

proc validate_DescribeHomeRegionControls_606188(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This API permits filtering on the <code>ControlId</code>, <code>HomeRegion</code>, and <code>RegionControlScope</code> fields.
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
  var valid_606190 = query.getOrDefault("MaxResults")
  valid_606190 = validateParameter(valid_606190, JString, required = false,
                                 default = nil)
  if valid_606190 != nil:
    section.add "MaxResults", valid_606190
  var valid_606191 = query.getOrDefault("NextToken")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "NextToken", valid_606191
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
  var valid_606192 = header.getOrDefault("X-Amz-Target")
  valid_606192 = validateParameter(valid_606192, JString, required = true, default = newJString(
      "AWSMigrationHubMultiAccountService.DescribeHomeRegionControls"))
  if valid_606192 != nil:
    section.add "X-Amz-Target", valid_606192
  var valid_606193 = header.getOrDefault("X-Amz-Signature")
  valid_606193 = validateParameter(valid_606193, JString, required = false,
                                 default = nil)
  if valid_606193 != nil:
    section.add "X-Amz-Signature", valid_606193
  var valid_606194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606194 = validateParameter(valid_606194, JString, required = false,
                                 default = nil)
  if valid_606194 != nil:
    section.add "X-Amz-Content-Sha256", valid_606194
  var valid_606195 = header.getOrDefault("X-Amz-Date")
  valid_606195 = validateParameter(valid_606195, JString, required = false,
                                 default = nil)
  if valid_606195 != nil:
    section.add "X-Amz-Date", valid_606195
  var valid_606196 = header.getOrDefault("X-Amz-Credential")
  valid_606196 = validateParameter(valid_606196, JString, required = false,
                                 default = nil)
  if valid_606196 != nil:
    section.add "X-Amz-Credential", valid_606196
  var valid_606197 = header.getOrDefault("X-Amz-Security-Token")
  valid_606197 = validateParameter(valid_606197, JString, required = false,
                                 default = nil)
  if valid_606197 != nil:
    section.add "X-Amz-Security-Token", valid_606197
  var valid_606198 = header.getOrDefault("X-Amz-Algorithm")
  valid_606198 = validateParameter(valid_606198, JString, required = false,
                                 default = nil)
  if valid_606198 != nil:
    section.add "X-Amz-Algorithm", valid_606198
  var valid_606199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606199 = validateParameter(valid_606199, JString, required = false,
                                 default = nil)
  if valid_606199 != nil:
    section.add "X-Amz-SignedHeaders", valid_606199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606201: Call_DescribeHomeRegionControls_606187; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This API permits filtering on the <code>ControlId</code>, <code>HomeRegion</code>, and <code>RegionControlScope</code> fields.
  ## 
  let valid = call_606201.validator(path, query, header, formData, body)
  let scheme = call_606201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606201.url(scheme.get, call_606201.host, call_606201.base,
                         call_606201.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606201, url, valid)

proc call*(call_606202: Call_DescribeHomeRegionControls_606187; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeHomeRegionControls
  ## This API permits filtering on the <code>ControlId</code>, <code>HomeRegion</code>, and <code>RegionControlScope</code> fields.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606203 = newJObject()
  var body_606204 = newJObject()
  add(query_606203, "MaxResults", newJString(MaxResults))
  add(query_606203, "NextToken", newJString(NextToken))
  if body != nil:
    body_606204 = body
  result = call_606202.call(nil, query_606203, nil, nil, body_606204)

var describeHomeRegionControls* = Call_DescribeHomeRegionControls_606187(
    name: "describeHomeRegionControls", meth: HttpMethod.HttpPost,
    host: "migrationhub-config.amazonaws.com", route: "/#X-Amz-Target=AWSMigrationHubMultiAccountService.DescribeHomeRegionControls",
    validator: validate_DescribeHomeRegionControls_606188, base: "/",
    url: url_DescribeHomeRegionControls_606189,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHomeRegion_606206 = ref object of OpenApiRestCall_605580
proc url_GetHomeRegion_606208(protocol: Scheme; host: string; base: string;
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

proc validate_GetHomeRegion_606207(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the calling account’s home region, if configured. This API is used by other AWS services to determine the regional endpoint for calling AWS Application Discovery Service and Migration Hub. You must call <code>GetHomeRegion</code> at least once before you call any other AWS Application Discovery Service and AWS Migration Hub APIs, to obtain the account's Migration Hub home region.
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
  var valid_606209 = header.getOrDefault("X-Amz-Target")
  valid_606209 = validateParameter(valid_606209, JString, required = true, default = newJString(
      "AWSMigrationHubMultiAccountService.GetHomeRegion"))
  if valid_606209 != nil:
    section.add "X-Amz-Target", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-Signature")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-Signature", valid_606210
  var valid_606211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "X-Amz-Content-Sha256", valid_606211
  var valid_606212 = header.getOrDefault("X-Amz-Date")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "X-Amz-Date", valid_606212
  var valid_606213 = header.getOrDefault("X-Amz-Credential")
  valid_606213 = validateParameter(valid_606213, JString, required = false,
                                 default = nil)
  if valid_606213 != nil:
    section.add "X-Amz-Credential", valid_606213
  var valid_606214 = header.getOrDefault("X-Amz-Security-Token")
  valid_606214 = validateParameter(valid_606214, JString, required = false,
                                 default = nil)
  if valid_606214 != nil:
    section.add "X-Amz-Security-Token", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Algorithm")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Algorithm", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-SignedHeaders", valid_606216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606218: Call_GetHomeRegion_606206; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the calling account’s home region, if configured. This API is used by other AWS services to determine the regional endpoint for calling AWS Application Discovery Service and Migration Hub. You must call <code>GetHomeRegion</code> at least once before you call any other AWS Application Discovery Service and AWS Migration Hub APIs, to obtain the account's Migration Hub home region.
  ## 
  let valid = call_606218.validator(path, query, header, formData, body)
  let scheme = call_606218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606218.url(scheme.get, call_606218.host, call_606218.base,
                         call_606218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606218, url, valid)

proc call*(call_606219: Call_GetHomeRegion_606206; body: JsonNode): Recallable =
  ## getHomeRegion
  ## Returns the calling account’s home region, if configured. This API is used by other AWS services to determine the regional endpoint for calling AWS Application Discovery Service and Migration Hub. You must call <code>GetHomeRegion</code> at least once before you call any other AWS Application Discovery Service and AWS Migration Hub APIs, to obtain the account's Migration Hub home region.
  ##   body: JObject (required)
  var body_606220 = newJObject()
  if body != nil:
    body_606220 = body
  result = call_606219.call(nil, nil, nil, nil, body_606220)

var getHomeRegion* = Call_GetHomeRegion_606206(name: "getHomeRegion",
    meth: HttpMethod.HttpPost, host: "migrationhub-config.amazonaws.com",
    route: "/#X-Amz-Target=AWSMigrationHubMultiAccountService.GetHomeRegion",
    validator: validate_GetHomeRegion_606207, base: "/", url: url_GetHomeRegion_606208,
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
