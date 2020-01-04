
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

  OpenApiRestCall_601380 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601380](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601380): Option[Scheme] {.used.} =
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
  Call_CreateHomeRegionControl_601718 = ref object of OpenApiRestCall_601380
proc url_CreateHomeRegionControl_601720(protocol: Scheme; host: string; base: string;
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

proc validate_CreateHomeRegionControl_601719(path: JsonNode; query: JsonNode;
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
  var valid_601845 = header.getOrDefault("X-Amz-Target")
  valid_601845 = validateParameter(valid_601845, JString, required = true, default = newJString(
      "AWSMigrationHubMultiAccountService.CreateHomeRegionControl"))
  if valid_601845 != nil:
    section.add "X-Amz-Target", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Signature")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Signature", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Content-Sha256", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Date")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Date", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-Credential")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-Credential", valid_601849
  var valid_601850 = header.getOrDefault("X-Amz-Security-Token")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "X-Amz-Security-Token", valid_601850
  var valid_601851 = header.getOrDefault("X-Amz-Algorithm")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "X-Amz-Algorithm", valid_601851
  var valid_601852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601852 = validateParameter(valid_601852, JString, required = false,
                                 default = nil)
  if valid_601852 != nil:
    section.add "X-Amz-SignedHeaders", valid_601852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601876: Call_CreateHomeRegionControl_601718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This API sets up the home region for the calling account only.
  ## 
  let valid = call_601876.validator(path, query, header, formData, body)
  let scheme = call_601876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601876.url(scheme.get, call_601876.host, call_601876.base,
                         call_601876.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601876, url, valid)

proc call*(call_601947: Call_CreateHomeRegionControl_601718; body: JsonNode): Recallable =
  ## createHomeRegionControl
  ## This API sets up the home region for the calling account only.
  ##   body: JObject (required)
  var body_601948 = newJObject()
  if body != nil:
    body_601948 = body
  result = call_601947.call(nil, nil, nil, nil, body_601948)

var createHomeRegionControl* = Call_CreateHomeRegionControl_601718(
    name: "createHomeRegionControl", meth: HttpMethod.HttpPost,
    host: "migrationhub-config.amazonaws.com", route: "/#X-Amz-Target=AWSMigrationHubMultiAccountService.CreateHomeRegionControl",
    validator: validate_CreateHomeRegionControl_601719, base: "/",
    url: url_CreateHomeRegionControl_601720, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHomeRegionControls_601987 = ref object of OpenApiRestCall_601380
proc url_DescribeHomeRegionControls_601989(protocol: Scheme; host: string;
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

proc validate_DescribeHomeRegionControls_601988(path: JsonNode; query: JsonNode;
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
  var valid_601990 = query.getOrDefault("MaxResults")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "MaxResults", valid_601990
  var valid_601991 = query.getOrDefault("NextToken")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "NextToken", valid_601991
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
  var valid_601992 = header.getOrDefault("X-Amz-Target")
  valid_601992 = validateParameter(valid_601992, JString, required = true, default = newJString(
      "AWSMigrationHubMultiAccountService.DescribeHomeRegionControls"))
  if valid_601992 != nil:
    section.add "X-Amz-Target", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-Signature")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-Signature", valid_601993
  var valid_601994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Content-Sha256", valid_601994
  var valid_601995 = header.getOrDefault("X-Amz-Date")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "X-Amz-Date", valid_601995
  var valid_601996 = header.getOrDefault("X-Amz-Credential")
  valid_601996 = validateParameter(valid_601996, JString, required = false,
                                 default = nil)
  if valid_601996 != nil:
    section.add "X-Amz-Credential", valid_601996
  var valid_601997 = header.getOrDefault("X-Amz-Security-Token")
  valid_601997 = validateParameter(valid_601997, JString, required = false,
                                 default = nil)
  if valid_601997 != nil:
    section.add "X-Amz-Security-Token", valid_601997
  var valid_601998 = header.getOrDefault("X-Amz-Algorithm")
  valid_601998 = validateParameter(valid_601998, JString, required = false,
                                 default = nil)
  if valid_601998 != nil:
    section.add "X-Amz-Algorithm", valid_601998
  var valid_601999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601999 = validateParameter(valid_601999, JString, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "X-Amz-SignedHeaders", valid_601999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602001: Call_DescribeHomeRegionControls_601987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This API permits filtering on the <code>ControlId</code>, <code>HomeRegion</code>, and <code>RegionControlScope</code> fields.
  ## 
  let valid = call_602001.validator(path, query, header, formData, body)
  let scheme = call_602001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602001.url(scheme.get, call_602001.host, call_602001.base,
                         call_602001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602001, url, valid)

proc call*(call_602002: Call_DescribeHomeRegionControls_601987; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeHomeRegionControls
  ## This API permits filtering on the <code>ControlId</code>, <code>HomeRegion</code>, and <code>RegionControlScope</code> fields.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602003 = newJObject()
  var body_602004 = newJObject()
  add(query_602003, "MaxResults", newJString(MaxResults))
  add(query_602003, "NextToken", newJString(NextToken))
  if body != nil:
    body_602004 = body
  result = call_602002.call(nil, query_602003, nil, nil, body_602004)

var describeHomeRegionControls* = Call_DescribeHomeRegionControls_601987(
    name: "describeHomeRegionControls", meth: HttpMethod.HttpPost,
    host: "migrationhub-config.amazonaws.com", route: "/#X-Amz-Target=AWSMigrationHubMultiAccountService.DescribeHomeRegionControls",
    validator: validate_DescribeHomeRegionControls_601988, base: "/",
    url: url_DescribeHomeRegionControls_601989,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHomeRegion_602006 = ref object of OpenApiRestCall_601380
proc url_GetHomeRegion_602008(protocol: Scheme; host: string; base: string;
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

proc validate_GetHomeRegion_602007(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602009 = header.getOrDefault("X-Amz-Target")
  valid_602009 = validateParameter(valid_602009, JString, required = true, default = newJString(
      "AWSMigrationHubMultiAccountService.GetHomeRegion"))
  if valid_602009 != nil:
    section.add "X-Amz-Target", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Signature")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Signature", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Content-Sha256", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-Date")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-Date", valid_602012
  var valid_602013 = header.getOrDefault("X-Amz-Credential")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-Credential", valid_602013
  var valid_602014 = header.getOrDefault("X-Amz-Security-Token")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "X-Amz-Security-Token", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Algorithm")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Algorithm", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-SignedHeaders", valid_602016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602018: Call_GetHomeRegion_602006; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the calling account’s home region, if configured. This API is used by other AWS services to determine the regional endpoint for calling AWS Application Discovery Service and Migration Hub. You must call <code>GetHomeRegion</code> at least once before you call any other AWS Application Discovery Service and AWS Migration Hub APIs, to obtain the account's Migration Hub home region.
  ## 
  let valid = call_602018.validator(path, query, header, formData, body)
  let scheme = call_602018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602018.url(scheme.get, call_602018.host, call_602018.base,
                         call_602018.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602018, url, valid)

proc call*(call_602019: Call_GetHomeRegion_602006; body: JsonNode): Recallable =
  ## getHomeRegion
  ## Returns the calling account’s home region, if configured. This API is used by other AWS services to determine the regional endpoint for calling AWS Application Discovery Service and Migration Hub. You must call <code>GetHomeRegion</code> at least once before you call any other AWS Application Discovery Service and AWS Migration Hub APIs, to obtain the account's Migration Hub home region.
  ##   body: JObject (required)
  var body_602020 = newJObject()
  if body != nil:
    body_602020 = body
  result = call_602019.call(nil, nil, nil, nil, body_602020)

var getHomeRegion* = Call_GetHomeRegion_602006(name: "getHomeRegion",
    meth: HttpMethod.HttpPost, host: "migrationhub-config.amazonaws.com",
    route: "/#X-Amz-Target=AWSMigrationHubMultiAccountService.GetHomeRegion",
    validator: validate_GetHomeRegion_602007, base: "/", url: url_GetHomeRegion_602008,
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
