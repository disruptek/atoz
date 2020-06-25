
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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

  OpenApiRestCall_21625426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625426): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateHomeRegionControl_21625770 = ref object of OpenApiRestCall_21625426
proc url_CreateHomeRegionControl_21625772(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateHomeRegionControl_21625771(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This API sets up the home region for the calling account only.
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
  var valid_21625873 = header.getOrDefault("X-Amz-Date")
  valid_21625873 = validateParameter(valid_21625873, JString, required = false,
                                   default = nil)
  if valid_21625873 != nil:
    section.add "X-Amz-Date", valid_21625873
  var valid_21625874 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625874 = validateParameter(valid_21625874, JString, required = false,
                                   default = nil)
  if valid_21625874 != nil:
    section.add "X-Amz-Security-Token", valid_21625874
  var valid_21625889 = header.getOrDefault("X-Amz-Target")
  valid_21625889 = validateParameter(valid_21625889, JString, required = true, default = newJString(
      "AWSMigrationHubMultiAccountService.CreateHomeRegionControl"))
  if valid_21625889 != nil:
    section.add "X-Amz-Target", valid_21625889
  var valid_21625890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625890 = validateParameter(valid_21625890, JString, required = false,
                                   default = nil)
  if valid_21625890 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625890
  var valid_21625891 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625891 = validateParameter(valid_21625891, JString, required = false,
                                   default = nil)
  if valid_21625891 != nil:
    section.add "X-Amz-Algorithm", valid_21625891
  var valid_21625892 = header.getOrDefault("X-Amz-Signature")
  valid_21625892 = validateParameter(valid_21625892, JString, required = false,
                                   default = nil)
  if valid_21625892 != nil:
    section.add "X-Amz-Signature", valid_21625892
  var valid_21625893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625893 = validateParameter(valid_21625893, JString, required = false,
                                   default = nil)
  if valid_21625893 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625893
  var valid_21625894 = header.getOrDefault("X-Amz-Credential")
  valid_21625894 = validateParameter(valid_21625894, JString, required = false,
                                   default = nil)
  if valid_21625894 != nil:
    section.add "X-Amz-Credential", valid_21625894
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

proc call*(call_21625920: Call_CreateHomeRegionControl_21625770;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This API sets up the home region for the calling account only.
  ## 
  let valid = call_21625920.validator(path, query, header, formData, body, _)
  let scheme = call_21625920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625920.makeUrl(scheme.get, call_21625920.host, call_21625920.base,
                               call_21625920.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625920, uri, valid, _)

proc call*(call_21625983: Call_CreateHomeRegionControl_21625770; body: JsonNode): Recallable =
  ## createHomeRegionControl
  ## This API sets up the home region for the calling account only.
  ##   body: JObject (required)
  var body_21625984 = newJObject()
  if body != nil:
    body_21625984 = body
  result = call_21625983.call(nil, nil, nil, nil, body_21625984)

var createHomeRegionControl* = Call_CreateHomeRegionControl_21625770(
    name: "createHomeRegionControl", meth: HttpMethod.HttpPost,
    host: "migrationhub-config.amazonaws.com", route: "/#X-Amz-Target=AWSMigrationHubMultiAccountService.CreateHomeRegionControl",
    validator: validate_CreateHomeRegionControl_21625771, base: "/",
    makeUrl: url_CreateHomeRegionControl_21625772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHomeRegionControls_21626020 = ref object of OpenApiRestCall_21625426
proc url_DescribeHomeRegionControls_21626022(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeHomeRegionControls_21626021(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This API permits filtering on the <code>ControlId</code>, <code>HomeRegion</code>, and <code>RegionControlScope</code> fields.
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
  var valid_21626023 = query.getOrDefault("NextToken")
  valid_21626023 = validateParameter(valid_21626023, JString, required = false,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "NextToken", valid_21626023
  var valid_21626024 = query.getOrDefault("MaxResults")
  valid_21626024 = validateParameter(valid_21626024, JString, required = false,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "MaxResults", valid_21626024
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
  var valid_21626025 = header.getOrDefault("X-Amz-Date")
  valid_21626025 = validateParameter(valid_21626025, JString, required = false,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "X-Amz-Date", valid_21626025
  var valid_21626026 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Security-Token", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-Target")
  valid_21626027 = validateParameter(valid_21626027, JString, required = true, default = newJString(
      "AWSMigrationHubMultiAccountService.DescribeHomeRegionControls"))
  if valid_21626027 != nil:
    section.add "X-Amz-Target", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626028
  var valid_21626029 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626029 = validateParameter(valid_21626029, JString, required = false,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "X-Amz-Algorithm", valid_21626029
  var valid_21626030 = header.getOrDefault("X-Amz-Signature")
  valid_21626030 = validateParameter(valid_21626030, JString, required = false,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "X-Amz-Signature", valid_21626030
  var valid_21626031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626031 = validateParameter(valid_21626031, JString, required = false,
                                   default = nil)
  if valid_21626031 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626031
  var valid_21626032 = header.getOrDefault("X-Amz-Credential")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Credential", valid_21626032
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

proc call*(call_21626034: Call_DescribeHomeRegionControls_21626020;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This API permits filtering on the <code>ControlId</code>, <code>HomeRegion</code>, and <code>RegionControlScope</code> fields.
  ## 
  let valid = call_21626034.validator(path, query, header, formData, body, _)
  let scheme = call_21626034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626034.makeUrl(scheme.get, call_21626034.host, call_21626034.base,
                               call_21626034.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626034, uri, valid, _)

proc call*(call_21626035: Call_DescribeHomeRegionControls_21626020; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeHomeRegionControls
  ## This API permits filtering on the <code>ControlId</code>, <code>HomeRegion</code>, and <code>RegionControlScope</code> fields.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626037 = newJObject()
  var body_21626038 = newJObject()
  add(query_21626037, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626038 = body
  add(query_21626037, "MaxResults", newJString(MaxResults))
  result = call_21626035.call(nil, query_21626037, nil, nil, body_21626038)

var describeHomeRegionControls* = Call_DescribeHomeRegionControls_21626020(
    name: "describeHomeRegionControls", meth: HttpMethod.HttpPost,
    host: "migrationhub-config.amazonaws.com", route: "/#X-Amz-Target=AWSMigrationHubMultiAccountService.DescribeHomeRegionControls",
    validator: validate_DescribeHomeRegionControls_21626021, base: "/",
    makeUrl: url_DescribeHomeRegionControls_21626022,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHomeRegion_21626042 = ref object of OpenApiRestCall_21625426
proc url_GetHomeRegion_21626044(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetHomeRegion_21626043(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Returns the calling account’s home region, if configured. This API is used by other AWS services to determine the regional endpoint for calling AWS Application Discovery Service and Migration Hub. You must call <code>GetHomeRegion</code> at least once before you call any other AWS Application Discovery Service and AWS Migration Hub APIs, to obtain the account's Migration Hub home region.
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
  var valid_21626047 = header.getOrDefault("X-Amz-Target")
  valid_21626047 = validateParameter(valid_21626047, JString, required = true, default = newJString(
      "AWSMigrationHubMultiAccountService.GetHomeRegion"))
  if valid_21626047 != nil:
    section.add "X-Amz-Target", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-Algorithm", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Signature")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Signature", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Credential")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Credential", valid_21626052
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

proc call*(call_21626054: Call_GetHomeRegion_21626042; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the calling account’s home region, if configured. This API is used by other AWS services to determine the regional endpoint for calling AWS Application Discovery Service and Migration Hub. You must call <code>GetHomeRegion</code> at least once before you call any other AWS Application Discovery Service and AWS Migration Hub APIs, to obtain the account's Migration Hub home region.
  ## 
  let valid = call_21626054.validator(path, query, header, formData, body, _)
  let scheme = call_21626054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626054.makeUrl(scheme.get, call_21626054.host, call_21626054.base,
                               call_21626054.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626054, uri, valid, _)

proc call*(call_21626055: Call_GetHomeRegion_21626042; body: JsonNode): Recallable =
  ## getHomeRegion
  ## Returns the calling account’s home region, if configured. This API is used by other AWS services to determine the regional endpoint for calling AWS Application Discovery Service and Migration Hub. You must call <code>GetHomeRegion</code> at least once before you call any other AWS Application Discovery Service and AWS Migration Hub APIs, to obtain the account's Migration Hub home region.
  ##   body: JObject (required)
  var body_21626056 = newJObject()
  if body != nil:
    body_21626056 = body
  result = call_21626055.call(nil, nil, nil, nil, body_21626056)

var getHomeRegion* = Call_GetHomeRegion_21626042(name: "getHomeRegion",
    meth: HttpMethod.HttpPost, host: "migrationhub-config.amazonaws.com",
    route: "/#X-Amz-Target=AWSMigrationHubMultiAccountService.GetHomeRegion",
    validator: validate_GetHomeRegion_21626043, base: "/",
    makeUrl: url_GetHomeRegion_21626044, schemes: {Scheme.Https, Scheme.Http})
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