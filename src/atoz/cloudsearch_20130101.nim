
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudSearch
## version: 2013-01-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon CloudSearch Configuration Service</fullname> <p>You use the Amazon CloudSearch configuration service to create, configure, and manage search domains. Configuration service requests are submitted using the AWS Query protocol. AWS Query requests are HTTP or HTTPS requests submitted via HTTP GET or POST with a query parameter named Action.</p> <p>The endpoint for configuration service requests is region-specific: cloudsearch.<i>region</i>.amazonaws.com. For example, cloudsearch.us-east-1.amazonaws.com. For a current list of supported regions and endpoints, see <a href="http://docs.aws.amazon.com/general/latest/gr/rande.html#cloudsearch_region" target="_blank">Regions and Endpoints</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cloudsearch/
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "cloudsearch.ap-northeast-1.amazonaws.com", "ap-southeast-1": "cloudsearch.ap-southeast-1.amazonaws.com",
                           "us-west-2": "cloudsearch.us-west-2.amazonaws.com",
                           "eu-west-2": "cloudsearch.eu-west-2.amazonaws.com", "ap-northeast-3": "cloudsearch.ap-northeast-3.amazonaws.com", "eu-central-1": "cloudsearch.eu-central-1.amazonaws.com",
                           "us-east-2": "cloudsearch.us-east-2.amazonaws.com",
                           "us-east-1": "cloudsearch.us-east-1.amazonaws.com", "cn-northwest-1": "cloudsearch.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "cloudsearch.ap-south-1.amazonaws.com", "eu-north-1": "cloudsearch.eu-north-1.amazonaws.com", "ap-northeast-2": "cloudsearch.ap-northeast-2.amazonaws.com",
                           "us-west-1": "cloudsearch.us-west-1.amazonaws.com", "us-gov-east-1": "cloudsearch.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "cloudsearch.eu-west-3.amazonaws.com", "cn-north-1": "cloudsearch.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "cloudsearch.sa-east-1.amazonaws.com",
                           "eu-west-1": "cloudsearch.eu-west-1.amazonaws.com", "us-gov-west-1": "cloudsearch.us-gov-west-1.amazonaws.com", "ap-southeast-2": "cloudsearch.ap-southeast-2.amazonaws.com", "ca-central-1": "cloudsearch.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "cloudsearch.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "cloudsearch.ap-southeast-1.amazonaws.com",
      "us-west-2": "cloudsearch.us-west-2.amazonaws.com",
      "eu-west-2": "cloudsearch.eu-west-2.amazonaws.com",
      "ap-northeast-3": "cloudsearch.ap-northeast-3.amazonaws.com",
      "eu-central-1": "cloudsearch.eu-central-1.amazonaws.com",
      "us-east-2": "cloudsearch.us-east-2.amazonaws.com",
      "us-east-1": "cloudsearch.us-east-1.amazonaws.com",
      "cn-northwest-1": "cloudsearch.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "cloudsearch.ap-south-1.amazonaws.com",
      "eu-north-1": "cloudsearch.eu-north-1.amazonaws.com",
      "ap-northeast-2": "cloudsearch.ap-northeast-2.amazonaws.com",
      "us-west-1": "cloudsearch.us-west-1.amazonaws.com",
      "us-gov-east-1": "cloudsearch.us-gov-east-1.amazonaws.com",
      "eu-west-3": "cloudsearch.eu-west-3.amazonaws.com",
      "cn-north-1": "cloudsearch.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "cloudsearch.sa-east-1.amazonaws.com",
      "eu-west-1": "cloudsearch.eu-west-1.amazonaws.com",
      "us-gov-west-1": "cloudsearch.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "cloudsearch.ap-southeast-2.amazonaws.com",
      "ca-central-1": "cloudsearch.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "cloudsearch"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostBuildSuggesters_611267 = ref object of OpenApiRestCall_610658
proc url_PostBuildSuggesters_611269(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostBuildSuggesters_611268(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611270 = query.getOrDefault("Action")
  valid_611270 = validateParameter(valid_611270, JString, required = true,
                                 default = newJString("BuildSuggesters"))
  if valid_611270 != nil:
    section.add "Action", valid_611270
  var valid_611271 = query.getOrDefault("Version")
  valid_611271 = validateParameter(valid_611271, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611271 != nil:
    section.add "Version", valid_611271
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611272 = header.getOrDefault("X-Amz-Signature")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Signature", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Content-Sha256", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Date")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Date", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Credential")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Credential", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-Security-Token")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Security-Token", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-Algorithm")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Algorithm", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-SignedHeaders", valid_611278
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611279 = formData.getOrDefault("DomainName")
  valid_611279 = validateParameter(valid_611279, JString, required = true,
                                 default = nil)
  if valid_611279 != nil:
    section.add "DomainName", valid_611279
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611280: Call_PostBuildSuggesters_611267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611280.validator(path, query, header, formData, body)
  let scheme = call_611280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611280.url(scheme.get, call_611280.host, call_611280.base,
                         call_611280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611280, url, valid)

proc call*(call_611281: Call_PostBuildSuggesters_611267; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## postBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611282 = newJObject()
  var formData_611283 = newJObject()
  add(formData_611283, "DomainName", newJString(DomainName))
  add(query_611282, "Action", newJString(Action))
  add(query_611282, "Version", newJString(Version))
  result = call_611281.call(nil, query_611282, nil, formData_611283, nil)

var postBuildSuggesters* = Call_PostBuildSuggesters_611267(
    name: "postBuildSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_PostBuildSuggesters_611268, base: "/",
    url: url_PostBuildSuggesters_611269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuildSuggesters_610996 = ref object of OpenApiRestCall_610658
proc url_GetBuildSuggesters_610998(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBuildSuggesters_610997(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611110 = query.getOrDefault("DomainName")
  valid_611110 = validateParameter(valid_611110, JString, required = true,
                                 default = nil)
  if valid_611110 != nil:
    section.add "DomainName", valid_611110
  var valid_611124 = query.getOrDefault("Action")
  valid_611124 = validateParameter(valid_611124, JString, required = true,
                                 default = newJString("BuildSuggesters"))
  if valid_611124 != nil:
    section.add "Action", valid_611124
  var valid_611125 = query.getOrDefault("Version")
  valid_611125 = validateParameter(valid_611125, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611125 != nil:
    section.add "Version", valid_611125
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611126 = header.getOrDefault("X-Amz-Signature")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Signature", valid_611126
  var valid_611127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Content-Sha256", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Date")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Date", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Credential")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Credential", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-Security-Token")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-Security-Token", valid_611130
  var valid_611131 = header.getOrDefault("X-Amz-Algorithm")
  valid_611131 = validateParameter(valid_611131, JString, required = false,
                                 default = nil)
  if valid_611131 != nil:
    section.add "X-Amz-Algorithm", valid_611131
  var valid_611132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611132 = validateParameter(valid_611132, JString, required = false,
                                 default = nil)
  if valid_611132 != nil:
    section.add "X-Amz-SignedHeaders", valid_611132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611155: Call_GetBuildSuggesters_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611155.validator(path, query, header, formData, body)
  let scheme = call_611155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611155.url(scheme.get, call_611155.host, call_611155.base,
                         call_611155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611155, url, valid)

proc call*(call_611226: Call_GetBuildSuggesters_610996; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## getBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611227 = newJObject()
  add(query_611227, "DomainName", newJString(DomainName))
  add(query_611227, "Action", newJString(Action))
  add(query_611227, "Version", newJString(Version))
  result = call_611226.call(nil, query_611227, nil, nil, nil)

var getBuildSuggesters* = Call_GetBuildSuggesters_610996(
    name: "getBuildSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_GetBuildSuggesters_610997, base: "/",
    url: url_GetBuildSuggesters_610998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_611300 = ref object of OpenApiRestCall_610658
proc url_PostCreateDomain_611302(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDomain_611301(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611303 = query.getOrDefault("Action")
  valid_611303 = validateParameter(valid_611303, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_611303 != nil:
    section.add "Action", valid_611303
  var valid_611304 = query.getOrDefault("Version")
  valid_611304 = validateParameter(valid_611304, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611304 != nil:
    section.add "Version", valid_611304
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611305 = header.getOrDefault("X-Amz-Signature")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-Signature", valid_611305
  var valid_611306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "X-Amz-Content-Sha256", valid_611306
  var valid_611307 = header.getOrDefault("X-Amz-Date")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "X-Amz-Date", valid_611307
  var valid_611308 = header.getOrDefault("X-Amz-Credential")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-Credential", valid_611308
  var valid_611309 = header.getOrDefault("X-Amz-Security-Token")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "X-Amz-Security-Token", valid_611309
  var valid_611310 = header.getOrDefault("X-Amz-Algorithm")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-Algorithm", valid_611310
  var valid_611311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "X-Amz-SignedHeaders", valid_611311
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611312 = formData.getOrDefault("DomainName")
  valid_611312 = validateParameter(valid_611312, JString, required = true,
                                 default = nil)
  if valid_611312 != nil:
    section.add "DomainName", valid_611312
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611313: Call_PostCreateDomain_611300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611313.validator(path, query, header, formData, body)
  let scheme = call_611313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611313.url(scheme.get, call_611313.host, call_611313.base,
                         call_611313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611313, url, valid)

proc call*(call_611314: Call_PostCreateDomain_611300; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611315 = newJObject()
  var formData_611316 = newJObject()
  add(formData_611316, "DomainName", newJString(DomainName))
  add(query_611315, "Action", newJString(Action))
  add(query_611315, "Version", newJString(Version))
  result = call_611314.call(nil, query_611315, nil, formData_611316, nil)

var postCreateDomain* = Call_PostCreateDomain_611300(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_611301,
    base: "/", url: url_PostCreateDomain_611302,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_611284 = ref object of OpenApiRestCall_610658
proc url_GetCreateDomain_611286(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDomain_611285(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611287 = query.getOrDefault("DomainName")
  valid_611287 = validateParameter(valid_611287, JString, required = true,
                                 default = nil)
  if valid_611287 != nil:
    section.add "DomainName", valid_611287
  var valid_611288 = query.getOrDefault("Action")
  valid_611288 = validateParameter(valid_611288, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_611288 != nil:
    section.add "Action", valid_611288
  var valid_611289 = query.getOrDefault("Version")
  valid_611289 = validateParameter(valid_611289, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611289 != nil:
    section.add "Version", valid_611289
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611290 = header.getOrDefault("X-Amz-Signature")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-Signature", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-Content-Sha256", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-Date")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-Date", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-Credential")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Credential", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-Security-Token")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-Security-Token", valid_611294
  var valid_611295 = header.getOrDefault("X-Amz-Algorithm")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-Algorithm", valid_611295
  var valid_611296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "X-Amz-SignedHeaders", valid_611296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611297: Call_GetCreateDomain_611284; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611297.validator(path, query, header, formData, body)
  let scheme = call_611297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611297.url(scheme.get, call_611297.host, call_611297.base,
                         call_611297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611297, url, valid)

proc call*(call_611298: Call_GetCreateDomain_611284; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611299 = newJObject()
  add(query_611299, "DomainName", newJString(DomainName))
  add(query_611299, "Action", newJString(Action))
  add(query_611299, "Version", newJString(Version))
  result = call_611298.call(nil, query_611299, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_611284(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_611285,
    base: "/", url: url_GetCreateDomain_611286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineAnalysisScheme_611336 = ref object of OpenApiRestCall_610658
proc url_PostDefineAnalysisScheme_611338(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineAnalysisScheme_611337(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611339 = query.getOrDefault("Action")
  valid_611339 = validateParameter(valid_611339, JString, required = true,
                                 default = newJString("DefineAnalysisScheme"))
  if valid_611339 != nil:
    section.add "Action", valid_611339
  var valid_611340 = query.getOrDefault("Version")
  valid_611340 = validateParameter(valid_611340, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611340 != nil:
    section.add "Version", valid_611340
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611341 = header.getOrDefault("X-Amz-Signature")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-Signature", valid_611341
  var valid_611342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-Content-Sha256", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-Date")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-Date", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Credential")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Credential", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Security-Token")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Security-Token", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-Algorithm")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Algorithm", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-SignedHeaders", valid_611347
  result.add "header", section
  ## parameters in `formData` object:
  ##   AnalysisScheme.AnalysisSchemeLanguage: JString
  ##                                        : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisScheme.AnalysisSchemeName: JString
  ##                                    : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   AnalysisScheme.AnalysisOptions: JString
  ##                                 : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  section = newJObject()
  var valid_611348 = formData.getOrDefault("AnalysisScheme.AnalysisSchemeLanguage")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_611348
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611349 = formData.getOrDefault("DomainName")
  valid_611349 = validateParameter(valid_611349, JString, required = true,
                                 default = nil)
  if valid_611349 != nil:
    section.add "DomainName", valid_611349
  var valid_611350 = formData.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_611350
  var valid_611351 = formData.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_611351
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611352: Call_PostDefineAnalysisScheme_611336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611352.validator(path, query, header, formData, body)
  let scheme = call_611352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611352.url(scheme.get, call_611352.host, call_611352.base,
                         call_611352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611352, url, valid)

proc call*(call_611353: Call_PostDefineAnalysisScheme_611336; DomainName: string;
          AnalysisSchemeAnalysisSchemeLanguage: string = "";
          AnalysisSchemeAnalysisSchemeName: string = "";
          Action: string = "DefineAnalysisScheme";
          AnalysisSchemeAnalysisOptions: string = ""; Version: string = "2013-01-01"): Recallable =
  ## postDefineAnalysisScheme
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   AnalysisSchemeAnalysisSchemeLanguage: string
  ##                                       : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeAnalysisSchemeName: string
  ##                                   : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   Action: string (required)
  ##   AnalysisSchemeAnalysisOptions: string
  ##                                : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   Version: string (required)
  var query_611354 = newJObject()
  var formData_611355 = newJObject()
  add(formData_611355, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(formData_611355, "DomainName", newJString(DomainName))
  add(formData_611355, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_611354, "Action", newJString(Action))
  add(formData_611355, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  add(query_611354, "Version", newJString(Version))
  result = call_611353.call(nil, query_611354, nil, formData_611355, nil)

var postDefineAnalysisScheme* = Call_PostDefineAnalysisScheme_611336(
    name: "postDefineAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_PostDefineAnalysisScheme_611337, base: "/",
    url: url_PostDefineAnalysisScheme_611338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineAnalysisScheme_611317 = ref object of OpenApiRestCall_610658
proc url_GetDefineAnalysisScheme_611319(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineAnalysisScheme_611318(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisScheme.AnalysisSchemeName: JString
  ##                                    : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   AnalysisScheme.AnalysisOptions: JString
  ##                                 : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   Action: JString (required)
  ##   AnalysisScheme.AnalysisSchemeLanguage: JString
  ##                                        : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611320 = query.getOrDefault("DomainName")
  valid_611320 = validateParameter(valid_611320, JString, required = true,
                                 default = nil)
  if valid_611320 != nil:
    section.add "DomainName", valid_611320
  var valid_611321 = query.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_611321
  var valid_611322 = query.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_611322
  var valid_611323 = query.getOrDefault("Action")
  valid_611323 = validateParameter(valid_611323, JString, required = true,
                                 default = newJString("DefineAnalysisScheme"))
  if valid_611323 != nil:
    section.add "Action", valid_611323
  var valid_611324 = query.getOrDefault("AnalysisScheme.AnalysisSchemeLanguage")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_611324
  var valid_611325 = query.getOrDefault("Version")
  valid_611325 = validateParameter(valid_611325, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611325 != nil:
    section.add "Version", valid_611325
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611326 = header.getOrDefault("X-Amz-Signature")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "X-Amz-Signature", valid_611326
  var valid_611327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "X-Amz-Content-Sha256", valid_611327
  var valid_611328 = header.getOrDefault("X-Amz-Date")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "X-Amz-Date", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Credential")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Credential", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Security-Token")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Security-Token", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Algorithm")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Algorithm", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-SignedHeaders", valid_611332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611333: Call_GetDefineAnalysisScheme_611317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611333.validator(path, query, header, formData, body)
  let scheme = call_611333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611333.url(scheme.get, call_611333.host, call_611333.base,
                         call_611333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611333, url, valid)

proc call*(call_611334: Call_GetDefineAnalysisScheme_611317; DomainName: string;
          AnalysisSchemeAnalysisSchemeName: string = "";
          AnalysisSchemeAnalysisOptions: string = "";
          Action: string = "DefineAnalysisScheme";
          AnalysisSchemeAnalysisSchemeLanguage: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## getDefineAnalysisScheme
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeAnalysisSchemeName: string
  ##                                   : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   AnalysisSchemeAnalysisOptions: string
  ##                                : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   Action: string (required)
  ##   AnalysisSchemeAnalysisSchemeLanguage: string
  ##                                       : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   Version: string (required)
  var query_611335 = newJObject()
  add(query_611335, "DomainName", newJString(DomainName))
  add(query_611335, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_611335, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  add(query_611335, "Action", newJString(Action))
  add(query_611335, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(query_611335, "Version", newJString(Version))
  result = call_611334.call(nil, query_611335, nil, nil, nil)

var getDefineAnalysisScheme* = Call_GetDefineAnalysisScheme_611317(
    name: "getDefineAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_GetDefineAnalysisScheme_611318, base: "/",
    url: url_GetDefineAnalysisScheme_611319, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineExpression_611374 = ref object of OpenApiRestCall_610658
proc url_PostDefineExpression_611376(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineExpression_611375(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611377 = query.getOrDefault("Action")
  valid_611377 = validateParameter(valid_611377, JString, required = true,
                                 default = newJString("DefineExpression"))
  if valid_611377 != nil:
    section.add "Action", valid_611377
  var valid_611378 = query.getOrDefault("Version")
  valid_611378 = validateParameter(valid_611378, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611378 != nil:
    section.add "Version", valid_611378
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611379 = header.getOrDefault("X-Amz-Signature")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Signature", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-Content-Sha256", valid_611380
  var valid_611381 = header.getOrDefault("X-Amz-Date")
  valid_611381 = validateParameter(valid_611381, JString, required = false,
                                 default = nil)
  if valid_611381 != nil:
    section.add "X-Amz-Date", valid_611381
  var valid_611382 = header.getOrDefault("X-Amz-Credential")
  valid_611382 = validateParameter(valid_611382, JString, required = false,
                                 default = nil)
  if valid_611382 != nil:
    section.add "X-Amz-Credential", valid_611382
  var valid_611383 = header.getOrDefault("X-Amz-Security-Token")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-Security-Token", valid_611383
  var valid_611384 = header.getOrDefault("X-Amz-Algorithm")
  valid_611384 = validateParameter(valid_611384, JString, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "X-Amz-Algorithm", valid_611384
  var valid_611385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "X-Amz-SignedHeaders", valid_611385
  result.add "header", section
  ## parameters in `formData` object:
  ##   Expression.ExpressionName: JString
  ##                            : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   Expression.ExpressionValue: JString
  ##                             : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_611386 = formData.getOrDefault("Expression.ExpressionName")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "Expression.ExpressionName", valid_611386
  var valid_611387 = formData.getOrDefault("Expression.ExpressionValue")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "Expression.ExpressionValue", valid_611387
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611388 = formData.getOrDefault("DomainName")
  valid_611388 = validateParameter(valid_611388, JString, required = true,
                                 default = nil)
  if valid_611388 != nil:
    section.add "DomainName", valid_611388
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611389: Call_PostDefineExpression_611374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611389.validator(path, query, header, formData, body)
  let scheme = call_611389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611389.url(scheme.get, call_611389.host, call_611389.base,
                         call_611389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611389, url, valid)

proc call*(call_611390: Call_PostDefineExpression_611374; DomainName: string;
          ExpressionExpressionName: string = "";
          ExpressionExpressionValue: string = "";
          Action: string = "DefineExpression"; Version: string = "2013-01-01"): Recallable =
  ## postDefineExpression
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   ExpressionExpressionName: string
  ##                           : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   ExpressionExpressionValue: string
  ##                            : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611391 = newJObject()
  var formData_611392 = newJObject()
  add(formData_611392, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(formData_611392, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(formData_611392, "DomainName", newJString(DomainName))
  add(query_611391, "Action", newJString(Action))
  add(query_611391, "Version", newJString(Version))
  result = call_611390.call(nil, query_611391, nil, formData_611392, nil)

var postDefineExpression* = Call_PostDefineExpression_611374(
    name: "postDefineExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_PostDefineExpression_611375, base: "/",
    url: url_PostDefineExpression_611376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineExpression_611356 = ref object of OpenApiRestCall_610658
proc url_GetDefineExpression_611358(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineExpression_611357(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Expression.ExpressionValue: JString
  ##                             : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   Action: JString (required)
  ##   Expression.ExpressionName: JString
  ##                            : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611359 = query.getOrDefault("DomainName")
  valid_611359 = validateParameter(valid_611359, JString, required = true,
                                 default = nil)
  if valid_611359 != nil:
    section.add "DomainName", valid_611359
  var valid_611360 = query.getOrDefault("Expression.ExpressionValue")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "Expression.ExpressionValue", valid_611360
  var valid_611361 = query.getOrDefault("Action")
  valid_611361 = validateParameter(valid_611361, JString, required = true,
                                 default = newJString("DefineExpression"))
  if valid_611361 != nil:
    section.add "Action", valid_611361
  var valid_611362 = query.getOrDefault("Expression.ExpressionName")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "Expression.ExpressionName", valid_611362
  var valid_611363 = query.getOrDefault("Version")
  valid_611363 = validateParameter(valid_611363, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611363 != nil:
    section.add "Version", valid_611363
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611364 = header.getOrDefault("X-Amz-Signature")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-Signature", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-Content-Sha256", valid_611365
  var valid_611366 = header.getOrDefault("X-Amz-Date")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "X-Amz-Date", valid_611366
  var valid_611367 = header.getOrDefault("X-Amz-Credential")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "X-Amz-Credential", valid_611367
  var valid_611368 = header.getOrDefault("X-Amz-Security-Token")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-Security-Token", valid_611368
  var valid_611369 = header.getOrDefault("X-Amz-Algorithm")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Algorithm", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-SignedHeaders", valid_611370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611371: Call_GetDefineExpression_611356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611371.validator(path, query, header, formData, body)
  let scheme = call_611371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611371.url(scheme.get, call_611371.host, call_611371.base,
                         call_611371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611371, url, valid)

proc call*(call_611372: Call_GetDefineExpression_611356; DomainName: string;
          ExpressionExpressionValue: string = "";
          Action: string = "DefineExpression";
          ExpressionExpressionName: string = ""; Version: string = "2013-01-01"): Recallable =
  ## getDefineExpression
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ExpressionExpressionValue: string
  ##                            : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   Action: string (required)
  ##   ExpressionExpressionName: string
  ##                           : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   Version: string (required)
  var query_611373 = newJObject()
  add(query_611373, "DomainName", newJString(DomainName))
  add(query_611373, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(query_611373, "Action", newJString(Action))
  add(query_611373, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(query_611373, "Version", newJString(Version))
  result = call_611372.call(nil, query_611373, nil, nil, nil)

var getDefineExpression* = Call_GetDefineExpression_611356(
    name: "getDefineExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_GetDefineExpression_611357, base: "/",
    url: url_GetDefineExpression_611358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_611422 = ref object of OpenApiRestCall_610658
proc url_PostDefineIndexField_611424(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineIndexField_611423(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611425 = query.getOrDefault("Action")
  valid_611425 = validateParameter(valid_611425, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_611425 != nil:
    section.add "Action", valid_611425
  var valid_611426 = query.getOrDefault("Version")
  valid_611426 = validateParameter(valid_611426, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611426 != nil:
    section.add "Version", valid_611426
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611427 = header.getOrDefault("X-Amz-Signature")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-Signature", valid_611427
  var valid_611428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "X-Amz-Content-Sha256", valid_611428
  var valid_611429 = header.getOrDefault("X-Amz-Date")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "X-Amz-Date", valid_611429
  var valid_611430 = header.getOrDefault("X-Amz-Credential")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "X-Amz-Credential", valid_611430
  var valid_611431 = header.getOrDefault("X-Amz-Security-Token")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-Security-Token", valid_611431
  var valid_611432 = header.getOrDefault("X-Amz-Algorithm")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-Algorithm", valid_611432
  var valid_611433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "X-Amz-SignedHeaders", valid_611433
  result.add "header", section
  ## parameters in `formData` object:
  ##   IndexField.IntOptions: JString
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.TextArrayOptions: JString
  ##                              : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DoubleOptions: JString
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LatLonOptions: JString
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LiteralArrayOptions: JString
  ##                                 : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IndexFieldType: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexField.TextOptions: JString
  ##                         : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IntArrayOptions: JString
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LiteralOptions: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IndexFieldName: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## <p>A string that represents the name of an index field. CloudSearch supports regular index fields as well as dynamic fields. A dynamic field's name defines a pattern that begins or ends with a wildcard. Any document fields that don't map to a regular index field but do match a dynamic field's pattern are configured with the dynamic field's indexing options. </p> <p>Regular field names begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Dynamic field names must begin or end with a wildcard (*). The wildcard can also be the only character in a dynamic field name. Multiple wildcards, and wildcards embedded within a string are not supported. </p> <p>The name <code>score</code> is reserved and cannot be used as a field name. To reference a document's ID, you can use the name <code>_id</code>. </p>
  ##   IndexField.DateOptions: JString
  ##                         : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DateArrayOptions: JString
  ##                              : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DoubleArrayOptions: JString
  ##                                : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  section = newJObject()
  var valid_611434 = formData.getOrDefault("IndexField.IntOptions")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "IndexField.IntOptions", valid_611434
  var valid_611435 = formData.getOrDefault("IndexField.TextArrayOptions")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "IndexField.TextArrayOptions", valid_611435
  var valid_611436 = formData.getOrDefault("IndexField.DoubleOptions")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "IndexField.DoubleOptions", valid_611436
  var valid_611437 = formData.getOrDefault("IndexField.LatLonOptions")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "IndexField.LatLonOptions", valid_611437
  var valid_611438 = formData.getOrDefault("IndexField.LiteralArrayOptions")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_611438
  var valid_611439 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "IndexField.IndexFieldType", valid_611439
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611440 = formData.getOrDefault("DomainName")
  valid_611440 = validateParameter(valid_611440, JString, required = true,
                                 default = nil)
  if valid_611440 != nil:
    section.add "DomainName", valid_611440
  var valid_611441 = formData.getOrDefault("IndexField.TextOptions")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "IndexField.TextOptions", valid_611441
  var valid_611442 = formData.getOrDefault("IndexField.IntArrayOptions")
  valid_611442 = validateParameter(valid_611442, JString, required = false,
                                 default = nil)
  if valid_611442 != nil:
    section.add "IndexField.IntArrayOptions", valid_611442
  var valid_611443 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_611443 = validateParameter(valid_611443, JString, required = false,
                                 default = nil)
  if valid_611443 != nil:
    section.add "IndexField.LiteralOptions", valid_611443
  var valid_611444 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_611444 = validateParameter(valid_611444, JString, required = false,
                                 default = nil)
  if valid_611444 != nil:
    section.add "IndexField.IndexFieldName", valid_611444
  var valid_611445 = formData.getOrDefault("IndexField.DateOptions")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "IndexField.DateOptions", valid_611445
  var valid_611446 = formData.getOrDefault("IndexField.DateArrayOptions")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "IndexField.DateArrayOptions", valid_611446
  var valid_611447 = formData.getOrDefault("IndexField.DoubleArrayOptions")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_611447
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611448: Call_PostDefineIndexField_611422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_611448.validator(path, query, header, formData, body)
  let scheme = call_611448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611448.url(scheme.get, call_611448.host, call_611448.base,
                         call_611448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611448, url, valid)

proc call*(call_611449: Call_PostDefineIndexField_611422; DomainName: string;
          IndexFieldIntOptions: string = "";
          IndexFieldTextArrayOptions: string = "";
          IndexFieldDoubleOptions: string = "";
          IndexFieldLatLonOptions: string = "";
          IndexFieldLiteralArrayOptions: string = "";
          IndexFieldIndexFieldType: string = ""; IndexFieldTextOptions: string = "";
          IndexFieldIntArrayOptions: string = "";
          IndexFieldLiteralOptions: string = "";
          Action: string = "DefineIndexField";
          IndexFieldIndexFieldName: string = ""; IndexFieldDateOptions: string = "";
          IndexFieldDateArrayOptions: string = ""; Version: string = "2013-01-01";
          IndexFieldDoubleArrayOptions: string = ""): Recallable =
  ## postDefineIndexField
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   IndexFieldIntOptions: string
  ##                       : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldTextArrayOptions: string
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDoubleOptions: string
  ##                          : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLatLonOptions: string
  ##                          : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLiteralArrayOptions: string
  ##                                : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIndexFieldType: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldTextOptions: string
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIntArrayOptions: string
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLiteralOptions: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Action: string (required)
  ##   IndexFieldIndexFieldName: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## <p>A string that represents the name of an index field. CloudSearch supports regular index fields as well as dynamic fields. A dynamic field's name defines a pattern that begins or ends with a wildcard. Any document fields that don't map to a regular index field but do match a dynamic field's pattern are configured with the dynamic field's indexing options. </p> <p>Regular field names begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Dynamic field names must begin or end with a wildcard (*). The wildcard can also be the only character in a dynamic field name. Multiple wildcards, and wildcards embedded within a string are not supported. </p> <p>The name <code>score</code> is reserved and cannot be used as a field name. To reference a document's ID, you can use the name <code>_id</code>. </p>
  ##   IndexFieldDateOptions: string
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDateArrayOptions: string
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Version: string (required)
  ##   IndexFieldDoubleArrayOptions: string
  ##                               : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  var query_611450 = newJObject()
  var formData_611451 = newJObject()
  add(formData_611451, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(formData_611451, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(formData_611451, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(formData_611451, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  add(formData_611451, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(formData_611451, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(formData_611451, "DomainName", newJString(DomainName))
  add(formData_611451, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(formData_611451, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  add(formData_611451, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_611450, "Action", newJString(Action))
  add(formData_611451, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(formData_611451, "IndexField.DateOptions", newJString(IndexFieldDateOptions))
  add(formData_611451, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(query_611450, "Version", newJString(Version))
  add(formData_611451, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  result = call_611449.call(nil, query_611450, nil, formData_611451, nil)

var postDefineIndexField* = Call_PostDefineIndexField_611422(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_611423, base: "/",
    url: url_PostDefineIndexField_611424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_611393 = ref object of OpenApiRestCall_610658
proc url_GetDefineIndexField_611395(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineIndexField_611394(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IndexField.TextOptions: JString
  ##                         : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LiteralArrayOptions: JString
  ##                                 : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DoubleArrayOptions: JString
  ##                                : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IntArrayOptions: JString
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IndexFieldType: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexField.IndexFieldName: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## <p>A string that represents the name of an index field. CloudSearch supports regular index fields as well as dynamic fields. A dynamic field's name defines a pattern that begins or ends with a wildcard. Any document fields that don't map to a regular index field but do match a dynamic field's pattern are configured with the dynamic field's indexing options. </p> <p>Regular field names begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Dynamic field names must begin or end with a wildcard (*). The wildcard can also be the only character in a dynamic field name. Multiple wildcards, and wildcards embedded within a string are not supported. </p> <p>The name <code>score</code> is reserved and cannot be used as a field name. To reference a document's ID, you can use the name <code>_id</code>. </p>
  ##   IndexField.DoubleOptions: JString
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.TextArrayOptions: JString
  ##                              : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Action: JString (required)
  ##   IndexField.DateOptions: JString
  ##                         : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LiteralOptions: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IntOptions: JString
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Version: JString (required)
  ##   IndexField.DateArrayOptions: JString
  ##                              : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LatLonOptions: JString
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  section = newJObject()
  var valid_611396 = query.getOrDefault("IndexField.TextOptions")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "IndexField.TextOptions", valid_611396
  var valid_611397 = query.getOrDefault("IndexField.LiteralArrayOptions")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_611397
  var valid_611398 = query.getOrDefault("IndexField.DoubleArrayOptions")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_611398
  var valid_611399 = query.getOrDefault("IndexField.IntArrayOptions")
  valid_611399 = validateParameter(valid_611399, JString, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "IndexField.IntArrayOptions", valid_611399
  var valid_611400 = query.getOrDefault("IndexField.IndexFieldType")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "IndexField.IndexFieldType", valid_611400
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611401 = query.getOrDefault("DomainName")
  valid_611401 = validateParameter(valid_611401, JString, required = true,
                                 default = nil)
  if valid_611401 != nil:
    section.add "DomainName", valid_611401
  var valid_611402 = query.getOrDefault("IndexField.IndexFieldName")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "IndexField.IndexFieldName", valid_611402
  var valid_611403 = query.getOrDefault("IndexField.DoubleOptions")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "IndexField.DoubleOptions", valid_611403
  var valid_611404 = query.getOrDefault("IndexField.TextArrayOptions")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "IndexField.TextArrayOptions", valid_611404
  var valid_611405 = query.getOrDefault("Action")
  valid_611405 = validateParameter(valid_611405, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_611405 != nil:
    section.add "Action", valid_611405
  var valid_611406 = query.getOrDefault("IndexField.DateOptions")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "IndexField.DateOptions", valid_611406
  var valid_611407 = query.getOrDefault("IndexField.LiteralOptions")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "IndexField.LiteralOptions", valid_611407
  var valid_611408 = query.getOrDefault("IndexField.IntOptions")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "IndexField.IntOptions", valid_611408
  var valid_611409 = query.getOrDefault("Version")
  valid_611409 = validateParameter(valid_611409, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611409 != nil:
    section.add "Version", valid_611409
  var valid_611410 = query.getOrDefault("IndexField.DateArrayOptions")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "IndexField.DateArrayOptions", valid_611410
  var valid_611411 = query.getOrDefault("IndexField.LatLonOptions")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "IndexField.LatLonOptions", valid_611411
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611412 = header.getOrDefault("X-Amz-Signature")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Signature", valid_611412
  var valid_611413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-Content-Sha256", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-Date")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-Date", valid_611414
  var valid_611415 = header.getOrDefault("X-Amz-Credential")
  valid_611415 = validateParameter(valid_611415, JString, required = false,
                                 default = nil)
  if valid_611415 != nil:
    section.add "X-Amz-Credential", valid_611415
  var valid_611416 = header.getOrDefault("X-Amz-Security-Token")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-Security-Token", valid_611416
  var valid_611417 = header.getOrDefault("X-Amz-Algorithm")
  valid_611417 = validateParameter(valid_611417, JString, required = false,
                                 default = nil)
  if valid_611417 != nil:
    section.add "X-Amz-Algorithm", valid_611417
  var valid_611418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611418 = validateParameter(valid_611418, JString, required = false,
                                 default = nil)
  if valid_611418 != nil:
    section.add "X-Amz-SignedHeaders", valid_611418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611419: Call_GetDefineIndexField_611393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_611419.validator(path, query, header, formData, body)
  let scheme = call_611419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611419.url(scheme.get, call_611419.host, call_611419.base,
                         call_611419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611419, url, valid)

proc call*(call_611420: Call_GetDefineIndexField_611393; DomainName: string;
          IndexFieldTextOptions: string = "";
          IndexFieldLiteralArrayOptions: string = "";
          IndexFieldDoubleArrayOptions: string = "";
          IndexFieldIntArrayOptions: string = "";
          IndexFieldIndexFieldType: string = "";
          IndexFieldIndexFieldName: string = "";
          IndexFieldDoubleOptions: string = "";
          IndexFieldTextArrayOptions: string = "";
          Action: string = "DefineIndexField"; IndexFieldDateOptions: string = "";
          IndexFieldLiteralOptions: string = ""; IndexFieldIntOptions: string = "";
          Version: string = "2013-01-01"; IndexFieldDateArrayOptions: string = "";
          IndexFieldLatLonOptions: string = ""): Recallable =
  ## getDefineIndexField
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   IndexFieldTextOptions: string
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLiteralArrayOptions: string
  ##                                : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDoubleArrayOptions: string
  ##                               : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIntArrayOptions: string
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIndexFieldType: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldIndexFieldName: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## <p>A string that represents the name of an index field. CloudSearch supports regular index fields as well as dynamic fields. A dynamic field's name defines a pattern that begins or ends with a wildcard. Any document fields that don't map to a regular index field but do match a dynamic field's pattern are configured with the dynamic field's indexing options. </p> <p>Regular field names begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Dynamic field names must begin or end with a wildcard (*). The wildcard can also be the only character in a dynamic field name. Multiple wildcards, and wildcards embedded within a string are not supported. </p> <p>The name <code>score</code> is reserved and cannot be used as a field name. To reference a document's ID, you can use the name <code>_id</code>. </p>
  ##   IndexFieldDoubleOptions: string
  ##                          : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldTextArrayOptions: string
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Action: string (required)
  ##   IndexFieldDateOptions: string
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLiteralOptions: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIntOptions: string
  ##                       : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Version: string (required)
  ##   IndexFieldDateArrayOptions: string
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLatLonOptions: string
  ##                          : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  var query_611421 = newJObject()
  add(query_611421, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_611421, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(query_611421, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  add(query_611421, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  add(query_611421, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_611421, "DomainName", newJString(DomainName))
  add(query_611421, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_611421, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(query_611421, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(query_611421, "Action", newJString(Action))
  add(query_611421, "IndexField.DateOptions", newJString(IndexFieldDateOptions))
  add(query_611421, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_611421, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(query_611421, "Version", newJString(Version))
  add(query_611421, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(query_611421, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  result = call_611420.call(nil, query_611421, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_611393(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_611394, base: "/",
    url: url_GetDefineIndexField_611395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineSuggester_611470 = ref object of OpenApiRestCall_610658
proc url_PostDefineSuggester_611472(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineSuggester_611471(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611473 = query.getOrDefault("Action")
  valid_611473 = validateParameter(valid_611473, JString, required = true,
                                 default = newJString("DefineSuggester"))
  if valid_611473 != nil:
    section.add "Action", valid_611473
  var valid_611474 = query.getOrDefault("Version")
  valid_611474 = validateParameter(valid_611474, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611474 != nil:
    section.add "Version", valid_611474
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611475 = header.getOrDefault("X-Amz-Signature")
  valid_611475 = validateParameter(valid_611475, JString, required = false,
                                 default = nil)
  if valid_611475 != nil:
    section.add "X-Amz-Signature", valid_611475
  var valid_611476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611476 = validateParameter(valid_611476, JString, required = false,
                                 default = nil)
  if valid_611476 != nil:
    section.add "X-Amz-Content-Sha256", valid_611476
  var valid_611477 = header.getOrDefault("X-Amz-Date")
  valid_611477 = validateParameter(valid_611477, JString, required = false,
                                 default = nil)
  if valid_611477 != nil:
    section.add "X-Amz-Date", valid_611477
  var valid_611478 = header.getOrDefault("X-Amz-Credential")
  valid_611478 = validateParameter(valid_611478, JString, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "X-Amz-Credential", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-Security-Token")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Security-Token", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-Algorithm")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Algorithm", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-SignedHeaders", valid_611481
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Suggester.DocumentSuggesterOptions: JString
  ##                                     : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   Suggester.SuggesterName: JString
  ##                          : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611482 = formData.getOrDefault("DomainName")
  valid_611482 = validateParameter(valid_611482, JString, required = true,
                                 default = nil)
  if valid_611482 != nil:
    section.add "DomainName", valid_611482
  var valid_611483 = formData.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_611483
  var valid_611484 = formData.getOrDefault("Suggester.SuggesterName")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "Suggester.SuggesterName", valid_611484
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611485: Call_PostDefineSuggester_611470; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611485.validator(path, query, header, formData, body)
  let scheme = call_611485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611485.url(scheme.get, call_611485.host, call_611485.base,
                         call_611485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611485, url, valid)

proc call*(call_611486: Call_PostDefineSuggester_611470; DomainName: string;
          SuggesterDocumentSuggesterOptions: string = "";
          Action: string = "DefineSuggester"; SuggesterSuggesterName: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## postDefineSuggester
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   SuggesterDocumentSuggesterOptions: string
  ##                                    : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   Action: string (required)
  ##   SuggesterSuggesterName: string
  ##                         : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   Version: string (required)
  var query_611487 = newJObject()
  var formData_611488 = newJObject()
  add(formData_611488, "DomainName", newJString(DomainName))
  add(formData_611488, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(query_611487, "Action", newJString(Action))
  add(formData_611488, "Suggester.SuggesterName",
      newJString(SuggesterSuggesterName))
  add(query_611487, "Version", newJString(Version))
  result = call_611486.call(nil, query_611487, nil, formData_611488, nil)

var postDefineSuggester* = Call_PostDefineSuggester_611470(
    name: "postDefineSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_PostDefineSuggester_611471, base: "/",
    url: url_PostDefineSuggester_611472, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineSuggester_611452 = ref object of OpenApiRestCall_610658
proc url_GetDefineSuggester_611454(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineSuggester_611453(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Suggester.DocumentSuggesterOptions: JString
  ##                                     : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   Action: JString (required)
  ##   Suggester.SuggesterName: JString
  ##                          : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611455 = query.getOrDefault("DomainName")
  valid_611455 = validateParameter(valid_611455, JString, required = true,
                                 default = nil)
  if valid_611455 != nil:
    section.add "DomainName", valid_611455
  var valid_611456 = query.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_611456
  var valid_611457 = query.getOrDefault("Action")
  valid_611457 = validateParameter(valid_611457, JString, required = true,
                                 default = newJString("DefineSuggester"))
  if valid_611457 != nil:
    section.add "Action", valid_611457
  var valid_611458 = query.getOrDefault("Suggester.SuggesterName")
  valid_611458 = validateParameter(valid_611458, JString, required = false,
                                 default = nil)
  if valid_611458 != nil:
    section.add "Suggester.SuggesterName", valid_611458
  var valid_611459 = query.getOrDefault("Version")
  valid_611459 = validateParameter(valid_611459, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611459 != nil:
    section.add "Version", valid_611459
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611460 = header.getOrDefault("X-Amz-Signature")
  valid_611460 = validateParameter(valid_611460, JString, required = false,
                                 default = nil)
  if valid_611460 != nil:
    section.add "X-Amz-Signature", valid_611460
  var valid_611461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611461 = validateParameter(valid_611461, JString, required = false,
                                 default = nil)
  if valid_611461 != nil:
    section.add "X-Amz-Content-Sha256", valid_611461
  var valid_611462 = header.getOrDefault("X-Amz-Date")
  valid_611462 = validateParameter(valid_611462, JString, required = false,
                                 default = nil)
  if valid_611462 != nil:
    section.add "X-Amz-Date", valid_611462
  var valid_611463 = header.getOrDefault("X-Amz-Credential")
  valid_611463 = validateParameter(valid_611463, JString, required = false,
                                 default = nil)
  if valid_611463 != nil:
    section.add "X-Amz-Credential", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-Security-Token")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Security-Token", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-Algorithm")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-Algorithm", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-SignedHeaders", valid_611466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611467: Call_GetDefineSuggester_611452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611467.validator(path, query, header, formData, body)
  let scheme = call_611467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611467.url(scheme.get, call_611467.host, call_611467.base,
                         call_611467.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611467, url, valid)

proc call*(call_611468: Call_GetDefineSuggester_611452; DomainName: string;
          SuggesterDocumentSuggesterOptions: string = "";
          Action: string = "DefineSuggester"; SuggesterSuggesterName: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## getDefineSuggester
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   SuggesterDocumentSuggesterOptions: string
  ##                                    : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   Action: string (required)
  ##   SuggesterSuggesterName: string
  ##                         : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   Version: string (required)
  var query_611469 = newJObject()
  add(query_611469, "DomainName", newJString(DomainName))
  add(query_611469, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(query_611469, "Action", newJString(Action))
  add(query_611469, "Suggester.SuggesterName", newJString(SuggesterSuggesterName))
  add(query_611469, "Version", newJString(Version))
  result = call_611468.call(nil, query_611469, nil, nil, nil)

var getDefineSuggester* = Call_GetDefineSuggester_611452(
    name: "getDefineSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_GetDefineSuggester_611453, base: "/",
    url: url_GetDefineSuggester_611454, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAnalysisScheme_611506 = ref object of OpenApiRestCall_610658
proc url_PostDeleteAnalysisScheme_611508(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteAnalysisScheme_611507(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611509 = query.getOrDefault("Action")
  valid_611509 = validateParameter(valid_611509, JString, required = true,
                                 default = newJString("DeleteAnalysisScheme"))
  if valid_611509 != nil:
    section.add "Action", valid_611509
  var valid_611510 = query.getOrDefault("Version")
  valid_611510 = validateParameter(valid_611510, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611510 != nil:
    section.add "Version", valid_611510
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611511 = header.getOrDefault("X-Amz-Signature")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "X-Amz-Signature", valid_611511
  var valid_611512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Content-Sha256", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-Date")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Date", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-Credential")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Credential", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-Security-Token")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-Security-Token", valid_611515
  var valid_611516 = header.getOrDefault("X-Amz-Algorithm")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "X-Amz-Algorithm", valid_611516
  var valid_611517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "X-Amz-SignedHeaders", valid_611517
  result.add "header", section
  ## parameters in `formData` object:
  ##   AnalysisSchemeName: JString (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AnalysisSchemeName` field"
  var valid_611518 = formData.getOrDefault("AnalysisSchemeName")
  valid_611518 = validateParameter(valid_611518, JString, required = true,
                                 default = nil)
  if valid_611518 != nil:
    section.add "AnalysisSchemeName", valid_611518
  var valid_611519 = formData.getOrDefault("DomainName")
  valid_611519 = validateParameter(valid_611519, JString, required = true,
                                 default = nil)
  if valid_611519 != nil:
    section.add "DomainName", valid_611519
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611520: Call_PostDeleteAnalysisScheme_611506; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_611520.validator(path, query, header, formData, body)
  let scheme = call_611520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611520.url(scheme.get, call_611520.host, call_611520.base,
                         call_611520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611520, url, valid)

proc call*(call_611521: Call_PostDeleteAnalysisScheme_611506;
          AnalysisSchemeName: string; DomainName: string;
          Action: string = "DeleteAnalysisScheme"; Version: string = "2013-01-01"): Recallable =
  ## postDeleteAnalysisScheme
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   AnalysisSchemeName: string (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611522 = newJObject()
  var formData_611523 = newJObject()
  add(formData_611523, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(formData_611523, "DomainName", newJString(DomainName))
  add(query_611522, "Action", newJString(Action))
  add(query_611522, "Version", newJString(Version))
  result = call_611521.call(nil, query_611522, nil, formData_611523, nil)

var postDeleteAnalysisScheme* = Call_PostDeleteAnalysisScheme_611506(
    name: "postDeleteAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_PostDeleteAnalysisScheme_611507, base: "/",
    url: url_PostDeleteAnalysisScheme_611508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAnalysisScheme_611489 = ref object of OpenApiRestCall_610658
proc url_GetDeleteAnalysisScheme_611491(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteAnalysisScheme_611490(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   AnalysisSchemeName: JString (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611492 = query.getOrDefault("DomainName")
  valid_611492 = validateParameter(valid_611492, JString, required = true,
                                 default = nil)
  if valid_611492 != nil:
    section.add "DomainName", valid_611492
  var valid_611493 = query.getOrDefault("Action")
  valid_611493 = validateParameter(valid_611493, JString, required = true,
                                 default = newJString("DeleteAnalysisScheme"))
  if valid_611493 != nil:
    section.add "Action", valid_611493
  var valid_611494 = query.getOrDefault("AnalysisSchemeName")
  valid_611494 = validateParameter(valid_611494, JString, required = true,
                                 default = nil)
  if valid_611494 != nil:
    section.add "AnalysisSchemeName", valid_611494
  var valid_611495 = query.getOrDefault("Version")
  valid_611495 = validateParameter(valid_611495, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611495 != nil:
    section.add "Version", valid_611495
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611496 = header.getOrDefault("X-Amz-Signature")
  valid_611496 = validateParameter(valid_611496, JString, required = false,
                                 default = nil)
  if valid_611496 != nil:
    section.add "X-Amz-Signature", valid_611496
  var valid_611497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "X-Amz-Content-Sha256", valid_611497
  var valid_611498 = header.getOrDefault("X-Amz-Date")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Date", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Credential")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Credential", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-Security-Token")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-Security-Token", valid_611500
  var valid_611501 = header.getOrDefault("X-Amz-Algorithm")
  valid_611501 = validateParameter(valid_611501, JString, required = false,
                                 default = nil)
  if valid_611501 != nil:
    section.add "X-Amz-Algorithm", valid_611501
  var valid_611502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611502 = validateParameter(valid_611502, JString, required = false,
                                 default = nil)
  if valid_611502 != nil:
    section.add "X-Amz-SignedHeaders", valid_611502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611503: Call_GetDeleteAnalysisScheme_611489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_611503.validator(path, query, header, formData, body)
  let scheme = call_611503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611503.url(scheme.get, call_611503.host, call_611503.base,
                         call_611503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611503, url, valid)

proc call*(call_611504: Call_GetDeleteAnalysisScheme_611489; DomainName: string;
          AnalysisSchemeName: string; Action: string = "DeleteAnalysisScheme";
          Version: string = "2013-01-01"): Recallable =
  ## getDeleteAnalysisScheme
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   AnalysisSchemeName: string (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   Version: string (required)
  var query_611505 = newJObject()
  add(query_611505, "DomainName", newJString(DomainName))
  add(query_611505, "Action", newJString(Action))
  add(query_611505, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(query_611505, "Version", newJString(Version))
  result = call_611504.call(nil, query_611505, nil, nil, nil)

var getDeleteAnalysisScheme* = Call_GetDeleteAnalysisScheme_611489(
    name: "getDeleteAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_GetDeleteAnalysisScheme_611490, base: "/",
    url: url_GetDeleteAnalysisScheme_611491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_611540 = ref object of OpenApiRestCall_610658
proc url_PostDeleteDomain_611542(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDomain_611541(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611543 = query.getOrDefault("Action")
  valid_611543 = validateParameter(valid_611543, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_611543 != nil:
    section.add "Action", valid_611543
  var valid_611544 = query.getOrDefault("Version")
  valid_611544 = validateParameter(valid_611544, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611544 != nil:
    section.add "Version", valid_611544
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611545 = header.getOrDefault("X-Amz-Signature")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-Signature", valid_611545
  var valid_611546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611546 = validateParameter(valid_611546, JString, required = false,
                                 default = nil)
  if valid_611546 != nil:
    section.add "X-Amz-Content-Sha256", valid_611546
  var valid_611547 = header.getOrDefault("X-Amz-Date")
  valid_611547 = validateParameter(valid_611547, JString, required = false,
                                 default = nil)
  if valid_611547 != nil:
    section.add "X-Amz-Date", valid_611547
  var valid_611548 = header.getOrDefault("X-Amz-Credential")
  valid_611548 = validateParameter(valid_611548, JString, required = false,
                                 default = nil)
  if valid_611548 != nil:
    section.add "X-Amz-Credential", valid_611548
  var valid_611549 = header.getOrDefault("X-Amz-Security-Token")
  valid_611549 = validateParameter(valid_611549, JString, required = false,
                                 default = nil)
  if valid_611549 != nil:
    section.add "X-Amz-Security-Token", valid_611549
  var valid_611550 = header.getOrDefault("X-Amz-Algorithm")
  valid_611550 = validateParameter(valid_611550, JString, required = false,
                                 default = nil)
  if valid_611550 != nil:
    section.add "X-Amz-Algorithm", valid_611550
  var valid_611551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611551 = validateParameter(valid_611551, JString, required = false,
                                 default = nil)
  if valid_611551 != nil:
    section.add "X-Amz-SignedHeaders", valid_611551
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611552 = formData.getOrDefault("DomainName")
  valid_611552 = validateParameter(valid_611552, JString, required = true,
                                 default = nil)
  if valid_611552 != nil:
    section.add "DomainName", valid_611552
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611553: Call_PostDeleteDomain_611540; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_611553.validator(path, query, header, formData, body)
  let scheme = call_611553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611553.url(scheme.get, call_611553.host, call_611553.base,
                         call_611553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611553, url, valid)

proc call*(call_611554: Call_PostDeleteDomain_611540; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611555 = newJObject()
  var formData_611556 = newJObject()
  add(formData_611556, "DomainName", newJString(DomainName))
  add(query_611555, "Action", newJString(Action))
  add(query_611555, "Version", newJString(Version))
  result = call_611554.call(nil, query_611555, nil, formData_611556, nil)

var postDeleteDomain* = Call_PostDeleteDomain_611540(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_611541,
    base: "/", url: url_PostDeleteDomain_611542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_611524 = ref object of OpenApiRestCall_610658
proc url_GetDeleteDomain_611526(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDomain_611525(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611527 = query.getOrDefault("DomainName")
  valid_611527 = validateParameter(valid_611527, JString, required = true,
                                 default = nil)
  if valid_611527 != nil:
    section.add "DomainName", valid_611527
  var valid_611528 = query.getOrDefault("Action")
  valid_611528 = validateParameter(valid_611528, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_611528 != nil:
    section.add "Action", valid_611528
  var valid_611529 = query.getOrDefault("Version")
  valid_611529 = validateParameter(valid_611529, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611529 != nil:
    section.add "Version", valid_611529
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611530 = header.getOrDefault("X-Amz-Signature")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-Signature", valid_611530
  var valid_611531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611531 = validateParameter(valid_611531, JString, required = false,
                                 default = nil)
  if valid_611531 != nil:
    section.add "X-Amz-Content-Sha256", valid_611531
  var valid_611532 = header.getOrDefault("X-Amz-Date")
  valid_611532 = validateParameter(valid_611532, JString, required = false,
                                 default = nil)
  if valid_611532 != nil:
    section.add "X-Amz-Date", valid_611532
  var valid_611533 = header.getOrDefault("X-Amz-Credential")
  valid_611533 = validateParameter(valid_611533, JString, required = false,
                                 default = nil)
  if valid_611533 != nil:
    section.add "X-Amz-Credential", valid_611533
  var valid_611534 = header.getOrDefault("X-Amz-Security-Token")
  valid_611534 = validateParameter(valid_611534, JString, required = false,
                                 default = nil)
  if valid_611534 != nil:
    section.add "X-Amz-Security-Token", valid_611534
  var valid_611535 = header.getOrDefault("X-Amz-Algorithm")
  valid_611535 = validateParameter(valid_611535, JString, required = false,
                                 default = nil)
  if valid_611535 != nil:
    section.add "X-Amz-Algorithm", valid_611535
  var valid_611536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611536 = validateParameter(valid_611536, JString, required = false,
                                 default = nil)
  if valid_611536 != nil:
    section.add "X-Amz-SignedHeaders", valid_611536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611537: Call_GetDeleteDomain_611524; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_611537.validator(path, query, header, formData, body)
  let scheme = call_611537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611537.url(scheme.get, call_611537.host, call_611537.base,
                         call_611537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611537, url, valid)

proc call*(call_611538: Call_GetDeleteDomain_611524; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611539 = newJObject()
  add(query_611539, "DomainName", newJString(DomainName))
  add(query_611539, "Action", newJString(Action))
  add(query_611539, "Version", newJString(Version))
  result = call_611538.call(nil, query_611539, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_611524(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_611525,
    base: "/", url: url_GetDeleteDomain_611526, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteExpression_611574 = ref object of OpenApiRestCall_610658
proc url_PostDeleteExpression_611576(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteExpression_611575(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611577 = query.getOrDefault("Action")
  valid_611577 = validateParameter(valid_611577, JString, required = true,
                                 default = newJString("DeleteExpression"))
  if valid_611577 != nil:
    section.add "Action", valid_611577
  var valid_611578 = query.getOrDefault("Version")
  valid_611578 = validateParameter(valid_611578, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611578 != nil:
    section.add "Version", valid_611578
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611579 = header.getOrDefault("X-Amz-Signature")
  valid_611579 = validateParameter(valid_611579, JString, required = false,
                                 default = nil)
  if valid_611579 != nil:
    section.add "X-Amz-Signature", valid_611579
  var valid_611580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611580 = validateParameter(valid_611580, JString, required = false,
                                 default = nil)
  if valid_611580 != nil:
    section.add "X-Amz-Content-Sha256", valid_611580
  var valid_611581 = header.getOrDefault("X-Amz-Date")
  valid_611581 = validateParameter(valid_611581, JString, required = false,
                                 default = nil)
  if valid_611581 != nil:
    section.add "X-Amz-Date", valid_611581
  var valid_611582 = header.getOrDefault("X-Amz-Credential")
  valid_611582 = validateParameter(valid_611582, JString, required = false,
                                 default = nil)
  if valid_611582 != nil:
    section.add "X-Amz-Credential", valid_611582
  var valid_611583 = header.getOrDefault("X-Amz-Security-Token")
  valid_611583 = validateParameter(valid_611583, JString, required = false,
                                 default = nil)
  if valid_611583 != nil:
    section.add "X-Amz-Security-Token", valid_611583
  var valid_611584 = header.getOrDefault("X-Amz-Algorithm")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-Algorithm", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-SignedHeaders", valid_611585
  result.add "header", section
  ## parameters in `formData` object:
  ##   ExpressionName: JString (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ExpressionName` field"
  var valid_611586 = formData.getOrDefault("ExpressionName")
  valid_611586 = validateParameter(valid_611586, JString, required = true,
                                 default = nil)
  if valid_611586 != nil:
    section.add "ExpressionName", valid_611586
  var valid_611587 = formData.getOrDefault("DomainName")
  valid_611587 = validateParameter(valid_611587, JString, required = true,
                                 default = nil)
  if valid_611587 != nil:
    section.add "DomainName", valid_611587
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611588: Call_PostDeleteExpression_611574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611588.validator(path, query, header, formData, body)
  let scheme = call_611588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611588.url(scheme.get, call_611588.host, call_611588.base,
                         call_611588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611588, url, valid)

proc call*(call_611589: Call_PostDeleteExpression_611574; ExpressionName: string;
          DomainName: string; Action: string = "DeleteExpression";
          Version: string = "2013-01-01"): Recallable =
  ## postDeleteExpression
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   ExpressionName: string (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611590 = newJObject()
  var formData_611591 = newJObject()
  add(formData_611591, "ExpressionName", newJString(ExpressionName))
  add(formData_611591, "DomainName", newJString(DomainName))
  add(query_611590, "Action", newJString(Action))
  add(query_611590, "Version", newJString(Version))
  result = call_611589.call(nil, query_611590, nil, formData_611591, nil)

var postDeleteExpression* = Call_PostDeleteExpression_611574(
    name: "postDeleteExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_PostDeleteExpression_611575, base: "/",
    url: url_PostDeleteExpression_611576, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteExpression_611557 = ref object of OpenApiRestCall_610658
proc url_GetDeleteExpression_611559(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteExpression_611558(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ExpressionName: JString (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ExpressionName` field"
  var valid_611560 = query.getOrDefault("ExpressionName")
  valid_611560 = validateParameter(valid_611560, JString, required = true,
                                 default = nil)
  if valid_611560 != nil:
    section.add "ExpressionName", valid_611560
  var valid_611561 = query.getOrDefault("DomainName")
  valid_611561 = validateParameter(valid_611561, JString, required = true,
                                 default = nil)
  if valid_611561 != nil:
    section.add "DomainName", valid_611561
  var valid_611562 = query.getOrDefault("Action")
  valid_611562 = validateParameter(valid_611562, JString, required = true,
                                 default = newJString("DeleteExpression"))
  if valid_611562 != nil:
    section.add "Action", valid_611562
  var valid_611563 = query.getOrDefault("Version")
  valid_611563 = validateParameter(valid_611563, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611563 != nil:
    section.add "Version", valid_611563
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611564 = header.getOrDefault("X-Amz-Signature")
  valid_611564 = validateParameter(valid_611564, JString, required = false,
                                 default = nil)
  if valid_611564 != nil:
    section.add "X-Amz-Signature", valid_611564
  var valid_611565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611565 = validateParameter(valid_611565, JString, required = false,
                                 default = nil)
  if valid_611565 != nil:
    section.add "X-Amz-Content-Sha256", valid_611565
  var valid_611566 = header.getOrDefault("X-Amz-Date")
  valid_611566 = validateParameter(valid_611566, JString, required = false,
                                 default = nil)
  if valid_611566 != nil:
    section.add "X-Amz-Date", valid_611566
  var valid_611567 = header.getOrDefault("X-Amz-Credential")
  valid_611567 = validateParameter(valid_611567, JString, required = false,
                                 default = nil)
  if valid_611567 != nil:
    section.add "X-Amz-Credential", valid_611567
  var valid_611568 = header.getOrDefault("X-Amz-Security-Token")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "X-Amz-Security-Token", valid_611568
  var valid_611569 = header.getOrDefault("X-Amz-Algorithm")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Algorithm", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-SignedHeaders", valid_611570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611571: Call_GetDeleteExpression_611557; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611571.validator(path, query, header, formData, body)
  let scheme = call_611571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611571.url(scheme.get, call_611571.host, call_611571.base,
                         call_611571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611571, url, valid)

proc call*(call_611572: Call_GetDeleteExpression_611557; ExpressionName: string;
          DomainName: string; Action: string = "DeleteExpression";
          Version: string = "2013-01-01"): Recallable =
  ## getDeleteExpression
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   ExpressionName: string (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611573 = newJObject()
  add(query_611573, "ExpressionName", newJString(ExpressionName))
  add(query_611573, "DomainName", newJString(DomainName))
  add(query_611573, "Action", newJString(Action))
  add(query_611573, "Version", newJString(Version))
  result = call_611572.call(nil, query_611573, nil, nil, nil)

var getDeleteExpression* = Call_GetDeleteExpression_611557(
    name: "getDeleteExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_GetDeleteExpression_611558, base: "/",
    url: url_GetDeleteExpression_611559, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_611609 = ref object of OpenApiRestCall_610658
proc url_PostDeleteIndexField_611611(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteIndexField_611610(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611612 = query.getOrDefault("Action")
  valid_611612 = validateParameter(valid_611612, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_611612 != nil:
    section.add "Action", valid_611612
  var valid_611613 = query.getOrDefault("Version")
  valid_611613 = validateParameter(valid_611613, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611613 != nil:
    section.add "Version", valid_611613
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611614 = header.getOrDefault("X-Amz-Signature")
  valid_611614 = validateParameter(valid_611614, JString, required = false,
                                 default = nil)
  if valid_611614 != nil:
    section.add "X-Amz-Signature", valid_611614
  var valid_611615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611615 = validateParameter(valid_611615, JString, required = false,
                                 default = nil)
  if valid_611615 != nil:
    section.add "X-Amz-Content-Sha256", valid_611615
  var valid_611616 = header.getOrDefault("X-Amz-Date")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Date", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-Credential")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-Credential", valid_611617
  var valid_611618 = header.getOrDefault("X-Amz-Security-Token")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "X-Amz-Security-Token", valid_611618
  var valid_611619 = header.getOrDefault("X-Amz-Algorithm")
  valid_611619 = validateParameter(valid_611619, JString, required = false,
                                 default = nil)
  if valid_611619 != nil:
    section.add "X-Amz-Algorithm", valid_611619
  var valid_611620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "X-Amz-SignedHeaders", valid_611620
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldName: JString (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611621 = formData.getOrDefault("DomainName")
  valid_611621 = validateParameter(valid_611621, JString, required = true,
                                 default = nil)
  if valid_611621 != nil:
    section.add "DomainName", valid_611621
  var valid_611622 = formData.getOrDefault("IndexFieldName")
  valid_611622 = validateParameter(valid_611622, JString, required = true,
                                 default = nil)
  if valid_611622 != nil:
    section.add "IndexFieldName", valid_611622
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611623: Call_PostDeleteIndexField_611609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611623.validator(path, query, header, formData, body)
  let scheme = call_611623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611623.url(scheme.get, call_611623.host, call_611623.base,
                         call_611623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611623, url, valid)

proc call*(call_611624: Call_PostDeleteIndexField_611609; DomainName: string;
          IndexFieldName: string; Action: string = "DeleteIndexField";
          Version: string = "2013-01-01"): Recallable =
  ## postDeleteIndexField
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldName: string (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611625 = newJObject()
  var formData_611626 = newJObject()
  add(formData_611626, "DomainName", newJString(DomainName))
  add(formData_611626, "IndexFieldName", newJString(IndexFieldName))
  add(query_611625, "Action", newJString(Action))
  add(query_611625, "Version", newJString(Version))
  result = call_611624.call(nil, query_611625, nil, formData_611626, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_611609(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_611610, base: "/",
    url: url_PostDeleteIndexField_611611, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_611592 = ref object of OpenApiRestCall_610658
proc url_GetDeleteIndexField_611594(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteIndexField_611593(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   IndexFieldName: JString (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611595 = query.getOrDefault("DomainName")
  valid_611595 = validateParameter(valid_611595, JString, required = true,
                                 default = nil)
  if valid_611595 != nil:
    section.add "DomainName", valid_611595
  var valid_611596 = query.getOrDefault("Action")
  valid_611596 = validateParameter(valid_611596, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_611596 != nil:
    section.add "Action", valid_611596
  var valid_611597 = query.getOrDefault("IndexFieldName")
  valid_611597 = validateParameter(valid_611597, JString, required = true,
                                 default = nil)
  if valid_611597 != nil:
    section.add "IndexFieldName", valid_611597
  var valid_611598 = query.getOrDefault("Version")
  valid_611598 = validateParameter(valid_611598, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611598 != nil:
    section.add "Version", valid_611598
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611599 = header.getOrDefault("X-Amz-Signature")
  valid_611599 = validateParameter(valid_611599, JString, required = false,
                                 default = nil)
  if valid_611599 != nil:
    section.add "X-Amz-Signature", valid_611599
  var valid_611600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Content-Sha256", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-Date")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Date", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-Credential")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-Credential", valid_611602
  var valid_611603 = header.getOrDefault("X-Amz-Security-Token")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Security-Token", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-Algorithm")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-Algorithm", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-SignedHeaders", valid_611605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611606: Call_GetDeleteIndexField_611592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611606.validator(path, query, header, formData, body)
  let scheme = call_611606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611606.url(scheme.get, call_611606.host, call_611606.base,
                         call_611606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611606, url, valid)

proc call*(call_611607: Call_GetDeleteIndexField_611592; DomainName: string;
          IndexFieldName: string; Action: string = "DeleteIndexField";
          Version: string = "2013-01-01"): Recallable =
  ## getDeleteIndexField
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   IndexFieldName: string (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  ##   Version: string (required)
  var query_611608 = newJObject()
  add(query_611608, "DomainName", newJString(DomainName))
  add(query_611608, "Action", newJString(Action))
  add(query_611608, "IndexFieldName", newJString(IndexFieldName))
  add(query_611608, "Version", newJString(Version))
  result = call_611607.call(nil, query_611608, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_611592(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_611593, base: "/",
    url: url_GetDeleteIndexField_611594, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteSuggester_611644 = ref object of OpenApiRestCall_610658
proc url_PostDeleteSuggester_611646(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteSuggester_611645(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611647 = query.getOrDefault("Action")
  valid_611647 = validateParameter(valid_611647, JString, required = true,
                                 default = newJString("DeleteSuggester"))
  if valid_611647 != nil:
    section.add "Action", valid_611647
  var valid_611648 = query.getOrDefault("Version")
  valid_611648 = validateParameter(valid_611648, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611648 != nil:
    section.add "Version", valid_611648
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611649 = header.getOrDefault("X-Amz-Signature")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "X-Amz-Signature", valid_611649
  var valid_611650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611650 = validateParameter(valid_611650, JString, required = false,
                                 default = nil)
  if valid_611650 != nil:
    section.add "X-Amz-Content-Sha256", valid_611650
  var valid_611651 = header.getOrDefault("X-Amz-Date")
  valid_611651 = validateParameter(valid_611651, JString, required = false,
                                 default = nil)
  if valid_611651 != nil:
    section.add "X-Amz-Date", valid_611651
  var valid_611652 = header.getOrDefault("X-Amz-Credential")
  valid_611652 = validateParameter(valid_611652, JString, required = false,
                                 default = nil)
  if valid_611652 != nil:
    section.add "X-Amz-Credential", valid_611652
  var valid_611653 = header.getOrDefault("X-Amz-Security-Token")
  valid_611653 = validateParameter(valid_611653, JString, required = false,
                                 default = nil)
  if valid_611653 != nil:
    section.add "X-Amz-Security-Token", valid_611653
  var valid_611654 = header.getOrDefault("X-Amz-Algorithm")
  valid_611654 = validateParameter(valid_611654, JString, required = false,
                                 default = nil)
  if valid_611654 != nil:
    section.add "X-Amz-Algorithm", valid_611654
  var valid_611655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611655 = validateParameter(valid_611655, JString, required = false,
                                 default = nil)
  if valid_611655 != nil:
    section.add "X-Amz-SignedHeaders", valid_611655
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   SuggesterName: JString (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611656 = formData.getOrDefault("DomainName")
  valid_611656 = validateParameter(valid_611656, JString, required = true,
                                 default = nil)
  if valid_611656 != nil:
    section.add "DomainName", valid_611656
  var valid_611657 = formData.getOrDefault("SuggesterName")
  valid_611657 = validateParameter(valid_611657, JString, required = true,
                                 default = nil)
  if valid_611657 != nil:
    section.add "SuggesterName", valid_611657
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611658: Call_PostDeleteSuggester_611644; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611658.validator(path, query, header, formData, body)
  let scheme = call_611658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611658.url(scheme.get, call_611658.host, call_611658.base,
                         call_611658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611658, url, valid)

proc call*(call_611659: Call_PostDeleteSuggester_611644; DomainName: string;
          SuggesterName: string; Action: string = "DeleteSuggester";
          Version: string = "2013-01-01"): Recallable =
  ## postDeleteSuggester
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   SuggesterName: string (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611660 = newJObject()
  var formData_611661 = newJObject()
  add(formData_611661, "DomainName", newJString(DomainName))
  add(formData_611661, "SuggesterName", newJString(SuggesterName))
  add(query_611660, "Action", newJString(Action))
  add(query_611660, "Version", newJString(Version))
  result = call_611659.call(nil, query_611660, nil, formData_611661, nil)

var postDeleteSuggester* = Call_PostDeleteSuggester_611644(
    name: "postDeleteSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_PostDeleteSuggester_611645, base: "/",
    url: url_PostDeleteSuggester_611646, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteSuggester_611627 = ref object of OpenApiRestCall_610658
proc url_GetDeleteSuggester_611629(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteSuggester_611628(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SuggesterName: JString (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611630 = query.getOrDefault("DomainName")
  valid_611630 = validateParameter(valid_611630, JString, required = true,
                                 default = nil)
  if valid_611630 != nil:
    section.add "DomainName", valid_611630
  var valid_611631 = query.getOrDefault("Action")
  valid_611631 = validateParameter(valid_611631, JString, required = true,
                                 default = newJString("DeleteSuggester"))
  if valid_611631 != nil:
    section.add "Action", valid_611631
  var valid_611632 = query.getOrDefault("Version")
  valid_611632 = validateParameter(valid_611632, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611632 != nil:
    section.add "Version", valid_611632
  var valid_611633 = query.getOrDefault("SuggesterName")
  valid_611633 = validateParameter(valid_611633, JString, required = true,
                                 default = nil)
  if valid_611633 != nil:
    section.add "SuggesterName", valid_611633
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611634 = header.getOrDefault("X-Amz-Signature")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Signature", valid_611634
  var valid_611635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-Content-Sha256", valid_611635
  var valid_611636 = header.getOrDefault("X-Amz-Date")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-Date", valid_611636
  var valid_611637 = header.getOrDefault("X-Amz-Credential")
  valid_611637 = validateParameter(valid_611637, JString, required = false,
                                 default = nil)
  if valid_611637 != nil:
    section.add "X-Amz-Credential", valid_611637
  var valid_611638 = header.getOrDefault("X-Amz-Security-Token")
  valid_611638 = validateParameter(valid_611638, JString, required = false,
                                 default = nil)
  if valid_611638 != nil:
    section.add "X-Amz-Security-Token", valid_611638
  var valid_611639 = header.getOrDefault("X-Amz-Algorithm")
  valid_611639 = validateParameter(valid_611639, JString, required = false,
                                 default = nil)
  if valid_611639 != nil:
    section.add "X-Amz-Algorithm", valid_611639
  var valid_611640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611640 = validateParameter(valid_611640, JString, required = false,
                                 default = nil)
  if valid_611640 != nil:
    section.add "X-Amz-SignedHeaders", valid_611640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611641: Call_GetDeleteSuggester_611627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611641.validator(path, query, header, formData, body)
  let scheme = call_611641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611641.url(scheme.get, call_611641.host, call_611641.base,
                         call_611641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611641, url, valid)

proc call*(call_611642: Call_GetDeleteSuggester_611627; DomainName: string;
          SuggesterName: string; Action: string = "DeleteSuggester";
          Version: string = "2013-01-01"): Recallable =
  ## getDeleteSuggester
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SuggesterName: string (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  var query_611643 = newJObject()
  add(query_611643, "DomainName", newJString(DomainName))
  add(query_611643, "Action", newJString(Action))
  add(query_611643, "Version", newJString(Version))
  add(query_611643, "SuggesterName", newJString(SuggesterName))
  result = call_611642.call(nil, query_611643, nil, nil, nil)

var getDeleteSuggester* = Call_GetDeleteSuggester_611627(
    name: "getDeleteSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_GetDeleteSuggester_611628, base: "/",
    url: url_GetDeleteSuggester_611629, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAnalysisSchemes_611680 = ref object of OpenApiRestCall_610658
proc url_PostDescribeAnalysisSchemes_611682(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAnalysisSchemes_611681(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611683 = query.getOrDefault("Action")
  valid_611683 = validateParameter(valid_611683, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_611683 != nil:
    section.add "Action", valid_611683
  var valid_611684 = query.getOrDefault("Version")
  valid_611684 = validateParameter(valid_611684, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611684 != nil:
    section.add "Version", valid_611684
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611685 = header.getOrDefault("X-Amz-Signature")
  valid_611685 = validateParameter(valid_611685, JString, required = false,
                                 default = nil)
  if valid_611685 != nil:
    section.add "X-Amz-Signature", valid_611685
  var valid_611686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611686 = validateParameter(valid_611686, JString, required = false,
                                 default = nil)
  if valid_611686 != nil:
    section.add "X-Amz-Content-Sha256", valid_611686
  var valid_611687 = header.getOrDefault("X-Amz-Date")
  valid_611687 = validateParameter(valid_611687, JString, required = false,
                                 default = nil)
  if valid_611687 != nil:
    section.add "X-Amz-Date", valid_611687
  var valid_611688 = header.getOrDefault("X-Amz-Credential")
  valid_611688 = validateParameter(valid_611688, JString, required = false,
                                 default = nil)
  if valid_611688 != nil:
    section.add "X-Amz-Credential", valid_611688
  var valid_611689 = header.getOrDefault("X-Amz-Security-Token")
  valid_611689 = validateParameter(valid_611689, JString, required = false,
                                 default = nil)
  if valid_611689 != nil:
    section.add "X-Amz-Security-Token", valid_611689
  var valid_611690 = header.getOrDefault("X-Amz-Algorithm")
  valid_611690 = validateParameter(valid_611690, JString, required = false,
                                 default = nil)
  if valid_611690 != nil:
    section.add "X-Amz-Algorithm", valid_611690
  var valid_611691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611691 = validateParameter(valid_611691, JString, required = false,
                                 default = nil)
  if valid_611691 != nil:
    section.add "X-Amz-SignedHeaders", valid_611691
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  section = newJObject()
  var valid_611692 = formData.getOrDefault("Deployed")
  valid_611692 = validateParameter(valid_611692, JBool, required = false, default = nil)
  if valid_611692 != nil:
    section.add "Deployed", valid_611692
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611693 = formData.getOrDefault("DomainName")
  valid_611693 = validateParameter(valid_611693, JString, required = true,
                                 default = nil)
  if valid_611693 != nil:
    section.add "DomainName", valid_611693
  var valid_611694 = formData.getOrDefault("AnalysisSchemeNames")
  valid_611694 = validateParameter(valid_611694, JArray, required = false,
                                 default = nil)
  if valid_611694 != nil:
    section.add "AnalysisSchemeNames", valid_611694
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611695: Call_PostDescribeAnalysisSchemes_611680; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611695.validator(path, query, header, formData, body)
  let scheme = call_611695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611695.url(scheme.get, call_611695.host, call_611695.base,
                         call_611695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611695, url, valid)

proc call*(call_611696: Call_PostDescribeAnalysisSchemes_611680;
          DomainName: string; Deployed: bool = false;
          AnalysisSchemeNames: JsonNode = nil;
          Action: string = "DescribeAnalysisSchemes"; Version: string = "2013-01-01"): Recallable =
  ## postDescribeAnalysisSchemes
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611697 = newJObject()
  var formData_611698 = newJObject()
  add(formData_611698, "Deployed", newJBool(Deployed))
  add(formData_611698, "DomainName", newJString(DomainName))
  if AnalysisSchemeNames != nil:
    formData_611698.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_611697, "Action", newJString(Action))
  add(query_611697, "Version", newJString(Version))
  result = call_611696.call(nil, query_611697, nil, formData_611698, nil)

var postDescribeAnalysisSchemes* = Call_PostDescribeAnalysisSchemes_611680(
    name: "postDescribeAnalysisSchemes", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_PostDescribeAnalysisSchemes_611681, base: "/",
    url: url_PostDescribeAnalysisSchemes_611682,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAnalysisSchemes_611662 = ref object of OpenApiRestCall_610658
proc url_GetDescribeAnalysisSchemes_611664(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAnalysisSchemes_611663(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611665 = query.getOrDefault("DomainName")
  valid_611665 = validateParameter(valid_611665, JString, required = true,
                                 default = nil)
  if valid_611665 != nil:
    section.add "DomainName", valid_611665
  var valid_611666 = query.getOrDefault("AnalysisSchemeNames")
  valid_611666 = validateParameter(valid_611666, JArray, required = false,
                                 default = nil)
  if valid_611666 != nil:
    section.add "AnalysisSchemeNames", valid_611666
  var valid_611667 = query.getOrDefault("Deployed")
  valid_611667 = validateParameter(valid_611667, JBool, required = false, default = nil)
  if valid_611667 != nil:
    section.add "Deployed", valid_611667
  var valid_611668 = query.getOrDefault("Action")
  valid_611668 = validateParameter(valid_611668, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_611668 != nil:
    section.add "Action", valid_611668
  var valid_611669 = query.getOrDefault("Version")
  valid_611669 = validateParameter(valid_611669, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611669 != nil:
    section.add "Version", valid_611669
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611670 = header.getOrDefault("X-Amz-Signature")
  valid_611670 = validateParameter(valid_611670, JString, required = false,
                                 default = nil)
  if valid_611670 != nil:
    section.add "X-Amz-Signature", valid_611670
  var valid_611671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611671 = validateParameter(valid_611671, JString, required = false,
                                 default = nil)
  if valid_611671 != nil:
    section.add "X-Amz-Content-Sha256", valid_611671
  var valid_611672 = header.getOrDefault("X-Amz-Date")
  valid_611672 = validateParameter(valid_611672, JString, required = false,
                                 default = nil)
  if valid_611672 != nil:
    section.add "X-Amz-Date", valid_611672
  var valid_611673 = header.getOrDefault("X-Amz-Credential")
  valid_611673 = validateParameter(valid_611673, JString, required = false,
                                 default = nil)
  if valid_611673 != nil:
    section.add "X-Amz-Credential", valid_611673
  var valid_611674 = header.getOrDefault("X-Amz-Security-Token")
  valid_611674 = validateParameter(valid_611674, JString, required = false,
                                 default = nil)
  if valid_611674 != nil:
    section.add "X-Amz-Security-Token", valid_611674
  var valid_611675 = header.getOrDefault("X-Amz-Algorithm")
  valid_611675 = validateParameter(valid_611675, JString, required = false,
                                 default = nil)
  if valid_611675 != nil:
    section.add "X-Amz-Algorithm", valid_611675
  var valid_611676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611676 = validateParameter(valid_611676, JString, required = false,
                                 default = nil)
  if valid_611676 != nil:
    section.add "X-Amz-SignedHeaders", valid_611676
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611677: Call_GetDescribeAnalysisSchemes_611662; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611677.validator(path, query, header, formData, body)
  let scheme = call_611677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611677.url(scheme.get, call_611677.host, call_611677.base,
                         call_611677.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611677, url, valid)

proc call*(call_611678: Call_GetDescribeAnalysisSchemes_611662; DomainName: string;
          AnalysisSchemeNames: JsonNode = nil; Deployed: bool = false;
          Action: string = "DescribeAnalysisSchemes"; Version: string = "2013-01-01"): Recallable =
  ## getDescribeAnalysisSchemes
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611679 = newJObject()
  add(query_611679, "DomainName", newJString(DomainName))
  if AnalysisSchemeNames != nil:
    query_611679.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_611679, "Deployed", newJBool(Deployed))
  add(query_611679, "Action", newJString(Action))
  add(query_611679, "Version", newJString(Version))
  result = call_611678.call(nil, query_611679, nil, nil, nil)

var getDescribeAnalysisSchemes* = Call_GetDescribeAnalysisSchemes_611662(
    name: "getDescribeAnalysisSchemes", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_GetDescribeAnalysisSchemes_611663, base: "/",
    url: url_GetDescribeAnalysisSchemes_611664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_611716 = ref object of OpenApiRestCall_610658
proc url_PostDescribeAvailabilityOptions_611718(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAvailabilityOptions_611717(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611719 = query.getOrDefault("Action")
  valid_611719 = validateParameter(valid_611719, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_611719 != nil:
    section.add "Action", valid_611719
  var valid_611720 = query.getOrDefault("Version")
  valid_611720 = validateParameter(valid_611720, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611720 != nil:
    section.add "Version", valid_611720
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611721 = header.getOrDefault("X-Amz-Signature")
  valid_611721 = validateParameter(valid_611721, JString, required = false,
                                 default = nil)
  if valid_611721 != nil:
    section.add "X-Amz-Signature", valid_611721
  var valid_611722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611722 = validateParameter(valid_611722, JString, required = false,
                                 default = nil)
  if valid_611722 != nil:
    section.add "X-Amz-Content-Sha256", valid_611722
  var valid_611723 = header.getOrDefault("X-Amz-Date")
  valid_611723 = validateParameter(valid_611723, JString, required = false,
                                 default = nil)
  if valid_611723 != nil:
    section.add "X-Amz-Date", valid_611723
  var valid_611724 = header.getOrDefault("X-Amz-Credential")
  valid_611724 = validateParameter(valid_611724, JString, required = false,
                                 default = nil)
  if valid_611724 != nil:
    section.add "X-Amz-Credential", valid_611724
  var valid_611725 = header.getOrDefault("X-Amz-Security-Token")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "X-Amz-Security-Token", valid_611725
  var valid_611726 = header.getOrDefault("X-Amz-Algorithm")
  valid_611726 = validateParameter(valid_611726, JString, required = false,
                                 default = nil)
  if valid_611726 != nil:
    section.add "X-Amz-Algorithm", valid_611726
  var valid_611727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611727 = validateParameter(valid_611727, JString, required = false,
                                 default = nil)
  if valid_611727 != nil:
    section.add "X-Amz-SignedHeaders", valid_611727
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_611728 = formData.getOrDefault("Deployed")
  valid_611728 = validateParameter(valid_611728, JBool, required = false, default = nil)
  if valid_611728 != nil:
    section.add "Deployed", valid_611728
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611729 = formData.getOrDefault("DomainName")
  valid_611729 = validateParameter(valid_611729, JString, required = true,
                                 default = nil)
  if valid_611729 != nil:
    section.add "DomainName", valid_611729
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611730: Call_PostDescribeAvailabilityOptions_611716;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611730.validator(path, query, header, formData, body)
  let scheme = call_611730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611730.url(scheme.get, call_611730.host, call_611730.base,
                         call_611730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611730, url, valid)

proc call*(call_611731: Call_PostDescribeAvailabilityOptions_611716;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeAvailabilityOptions";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611732 = newJObject()
  var formData_611733 = newJObject()
  add(formData_611733, "Deployed", newJBool(Deployed))
  add(formData_611733, "DomainName", newJString(DomainName))
  add(query_611732, "Action", newJString(Action))
  add(query_611732, "Version", newJString(Version))
  result = call_611731.call(nil, query_611732, nil, formData_611733, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_611716(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_611717, base: "/",
    url: url_PostDescribeAvailabilityOptions_611718,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_611699 = ref object of OpenApiRestCall_610658
proc url_GetDescribeAvailabilityOptions_611701(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAvailabilityOptions_611700(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611702 = query.getOrDefault("DomainName")
  valid_611702 = validateParameter(valid_611702, JString, required = true,
                                 default = nil)
  if valid_611702 != nil:
    section.add "DomainName", valid_611702
  var valid_611703 = query.getOrDefault("Deployed")
  valid_611703 = validateParameter(valid_611703, JBool, required = false, default = nil)
  if valid_611703 != nil:
    section.add "Deployed", valid_611703
  var valid_611704 = query.getOrDefault("Action")
  valid_611704 = validateParameter(valid_611704, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_611704 != nil:
    section.add "Action", valid_611704
  var valid_611705 = query.getOrDefault("Version")
  valid_611705 = validateParameter(valid_611705, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611705 != nil:
    section.add "Version", valid_611705
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611706 = header.getOrDefault("X-Amz-Signature")
  valid_611706 = validateParameter(valid_611706, JString, required = false,
                                 default = nil)
  if valid_611706 != nil:
    section.add "X-Amz-Signature", valid_611706
  var valid_611707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611707 = validateParameter(valid_611707, JString, required = false,
                                 default = nil)
  if valid_611707 != nil:
    section.add "X-Amz-Content-Sha256", valid_611707
  var valid_611708 = header.getOrDefault("X-Amz-Date")
  valid_611708 = validateParameter(valid_611708, JString, required = false,
                                 default = nil)
  if valid_611708 != nil:
    section.add "X-Amz-Date", valid_611708
  var valid_611709 = header.getOrDefault("X-Amz-Credential")
  valid_611709 = validateParameter(valid_611709, JString, required = false,
                                 default = nil)
  if valid_611709 != nil:
    section.add "X-Amz-Credential", valid_611709
  var valid_611710 = header.getOrDefault("X-Amz-Security-Token")
  valid_611710 = validateParameter(valid_611710, JString, required = false,
                                 default = nil)
  if valid_611710 != nil:
    section.add "X-Amz-Security-Token", valid_611710
  var valid_611711 = header.getOrDefault("X-Amz-Algorithm")
  valid_611711 = validateParameter(valid_611711, JString, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "X-Amz-Algorithm", valid_611711
  var valid_611712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611712 = validateParameter(valid_611712, JString, required = false,
                                 default = nil)
  if valid_611712 != nil:
    section.add "X-Amz-SignedHeaders", valid_611712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611713: Call_GetDescribeAvailabilityOptions_611699; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611713.validator(path, query, header, formData, body)
  let scheme = call_611713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611713.url(scheme.get, call_611713.host, call_611713.base,
                         call_611713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611713, url, valid)

proc call*(call_611714: Call_GetDescribeAvailabilityOptions_611699;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeAvailabilityOptions";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611715 = newJObject()
  add(query_611715, "DomainName", newJString(DomainName))
  add(query_611715, "Deployed", newJBool(Deployed))
  add(query_611715, "Action", newJString(Action))
  add(query_611715, "Version", newJString(Version))
  result = call_611714.call(nil, query_611715, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_611699(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_611700, base: "/",
    url: url_GetDescribeAvailabilityOptions_611701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomainEndpointOptions_611751 = ref object of OpenApiRestCall_610658
proc url_PostDescribeDomainEndpointOptions_611753(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDomainEndpointOptions_611752(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611754 = query.getOrDefault("Action")
  valid_611754 = validateParameter(valid_611754, JString, required = true, default = newJString(
      "DescribeDomainEndpointOptions"))
  if valid_611754 != nil:
    section.add "Action", valid_611754
  var valid_611755 = query.getOrDefault("Version")
  valid_611755 = validateParameter(valid_611755, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611755 != nil:
    section.add "Version", valid_611755
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611756 = header.getOrDefault("X-Amz-Signature")
  valid_611756 = validateParameter(valid_611756, JString, required = false,
                                 default = nil)
  if valid_611756 != nil:
    section.add "X-Amz-Signature", valid_611756
  var valid_611757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611757 = validateParameter(valid_611757, JString, required = false,
                                 default = nil)
  if valid_611757 != nil:
    section.add "X-Amz-Content-Sha256", valid_611757
  var valid_611758 = header.getOrDefault("X-Amz-Date")
  valid_611758 = validateParameter(valid_611758, JString, required = false,
                                 default = nil)
  if valid_611758 != nil:
    section.add "X-Amz-Date", valid_611758
  var valid_611759 = header.getOrDefault("X-Amz-Credential")
  valid_611759 = validateParameter(valid_611759, JString, required = false,
                                 default = nil)
  if valid_611759 != nil:
    section.add "X-Amz-Credential", valid_611759
  var valid_611760 = header.getOrDefault("X-Amz-Security-Token")
  valid_611760 = validateParameter(valid_611760, JString, required = false,
                                 default = nil)
  if valid_611760 != nil:
    section.add "X-Amz-Security-Token", valid_611760
  var valid_611761 = header.getOrDefault("X-Amz-Algorithm")
  valid_611761 = validateParameter(valid_611761, JString, required = false,
                                 default = nil)
  if valid_611761 != nil:
    section.add "X-Amz-Algorithm", valid_611761
  var valid_611762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611762 = validateParameter(valid_611762, JString, required = false,
                                 default = nil)
  if valid_611762 != nil:
    section.add "X-Amz-SignedHeaders", valid_611762
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to retrieve the latest configuration (which might be in a Processing state) or the current, active configuration. Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_611763 = formData.getOrDefault("Deployed")
  valid_611763 = validateParameter(valid_611763, JBool, required = false, default = nil)
  if valid_611763 != nil:
    section.add "Deployed", valid_611763
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611764 = formData.getOrDefault("DomainName")
  valid_611764 = validateParameter(valid_611764, JString, required = true,
                                 default = nil)
  if valid_611764 != nil:
    section.add "DomainName", valid_611764
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611765: Call_PostDescribeDomainEndpointOptions_611751;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611765.validator(path, query, header, formData, body)
  let scheme = call_611765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611765.url(scheme.get, call_611765.host, call_611765.base,
                         call_611765.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611765, url, valid)

proc call*(call_611766: Call_PostDescribeDomainEndpointOptions_611751;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeDomainEndpointOptions";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeDomainEndpointOptions
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to retrieve the latest configuration (which might be in a Processing state) or the current, active configuration. Defaults to <code>false</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611767 = newJObject()
  var formData_611768 = newJObject()
  add(formData_611768, "Deployed", newJBool(Deployed))
  add(formData_611768, "DomainName", newJString(DomainName))
  add(query_611767, "Action", newJString(Action))
  add(query_611767, "Version", newJString(Version))
  result = call_611766.call(nil, query_611767, nil, formData_611768, nil)

var postDescribeDomainEndpointOptions* = Call_PostDescribeDomainEndpointOptions_611751(
    name: "postDescribeDomainEndpointOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDomainEndpointOptions",
    validator: validate_PostDescribeDomainEndpointOptions_611752, base: "/",
    url: url_PostDescribeDomainEndpointOptions_611753,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomainEndpointOptions_611734 = ref object of OpenApiRestCall_610658
proc url_GetDescribeDomainEndpointOptions_611736(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDomainEndpointOptions_611735(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to retrieve the latest configuration (which might be in a Processing state) or the current, active configuration. Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611737 = query.getOrDefault("DomainName")
  valid_611737 = validateParameter(valid_611737, JString, required = true,
                                 default = nil)
  if valid_611737 != nil:
    section.add "DomainName", valid_611737
  var valid_611738 = query.getOrDefault("Deployed")
  valid_611738 = validateParameter(valid_611738, JBool, required = false, default = nil)
  if valid_611738 != nil:
    section.add "Deployed", valid_611738
  var valid_611739 = query.getOrDefault("Action")
  valid_611739 = validateParameter(valid_611739, JString, required = true, default = newJString(
      "DescribeDomainEndpointOptions"))
  if valid_611739 != nil:
    section.add "Action", valid_611739
  var valid_611740 = query.getOrDefault("Version")
  valid_611740 = validateParameter(valid_611740, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611740 != nil:
    section.add "Version", valid_611740
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611741 = header.getOrDefault("X-Amz-Signature")
  valid_611741 = validateParameter(valid_611741, JString, required = false,
                                 default = nil)
  if valid_611741 != nil:
    section.add "X-Amz-Signature", valid_611741
  var valid_611742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611742 = validateParameter(valid_611742, JString, required = false,
                                 default = nil)
  if valid_611742 != nil:
    section.add "X-Amz-Content-Sha256", valid_611742
  var valid_611743 = header.getOrDefault("X-Amz-Date")
  valid_611743 = validateParameter(valid_611743, JString, required = false,
                                 default = nil)
  if valid_611743 != nil:
    section.add "X-Amz-Date", valid_611743
  var valid_611744 = header.getOrDefault("X-Amz-Credential")
  valid_611744 = validateParameter(valid_611744, JString, required = false,
                                 default = nil)
  if valid_611744 != nil:
    section.add "X-Amz-Credential", valid_611744
  var valid_611745 = header.getOrDefault("X-Amz-Security-Token")
  valid_611745 = validateParameter(valid_611745, JString, required = false,
                                 default = nil)
  if valid_611745 != nil:
    section.add "X-Amz-Security-Token", valid_611745
  var valid_611746 = header.getOrDefault("X-Amz-Algorithm")
  valid_611746 = validateParameter(valid_611746, JString, required = false,
                                 default = nil)
  if valid_611746 != nil:
    section.add "X-Amz-Algorithm", valid_611746
  var valid_611747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611747 = validateParameter(valid_611747, JString, required = false,
                                 default = nil)
  if valid_611747 != nil:
    section.add "X-Amz-SignedHeaders", valid_611747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611748: Call_GetDescribeDomainEndpointOptions_611734;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611748.validator(path, query, header, formData, body)
  let scheme = call_611748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611748.url(scheme.get, call_611748.host, call_611748.base,
                         call_611748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611748, url, valid)

proc call*(call_611749: Call_GetDescribeDomainEndpointOptions_611734;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeDomainEndpointOptions";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeDomainEndpointOptions
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to retrieve the latest configuration (which might be in a Processing state) or the current, active configuration. Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611750 = newJObject()
  add(query_611750, "DomainName", newJString(DomainName))
  add(query_611750, "Deployed", newJBool(Deployed))
  add(query_611750, "Action", newJString(Action))
  add(query_611750, "Version", newJString(Version))
  result = call_611749.call(nil, query_611750, nil, nil, nil)

var getDescribeDomainEndpointOptions* = Call_GetDescribeDomainEndpointOptions_611734(
    name: "getDescribeDomainEndpointOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDomainEndpointOptions",
    validator: validate_GetDescribeDomainEndpointOptions_611735, base: "/",
    url: url_GetDescribeDomainEndpointOptions_611736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_611785 = ref object of OpenApiRestCall_610658
proc url_PostDescribeDomains_611787(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDomains_611786(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611788 = query.getOrDefault("Action")
  valid_611788 = validateParameter(valid_611788, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_611788 != nil:
    section.add "Action", valid_611788
  var valid_611789 = query.getOrDefault("Version")
  valid_611789 = validateParameter(valid_611789, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611789 != nil:
    section.add "Version", valid_611789
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611790 = header.getOrDefault("X-Amz-Signature")
  valid_611790 = validateParameter(valid_611790, JString, required = false,
                                 default = nil)
  if valid_611790 != nil:
    section.add "X-Amz-Signature", valid_611790
  var valid_611791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611791 = validateParameter(valid_611791, JString, required = false,
                                 default = nil)
  if valid_611791 != nil:
    section.add "X-Amz-Content-Sha256", valid_611791
  var valid_611792 = header.getOrDefault("X-Amz-Date")
  valid_611792 = validateParameter(valid_611792, JString, required = false,
                                 default = nil)
  if valid_611792 != nil:
    section.add "X-Amz-Date", valid_611792
  var valid_611793 = header.getOrDefault("X-Amz-Credential")
  valid_611793 = validateParameter(valid_611793, JString, required = false,
                                 default = nil)
  if valid_611793 != nil:
    section.add "X-Amz-Credential", valid_611793
  var valid_611794 = header.getOrDefault("X-Amz-Security-Token")
  valid_611794 = validateParameter(valid_611794, JString, required = false,
                                 default = nil)
  if valid_611794 != nil:
    section.add "X-Amz-Security-Token", valid_611794
  var valid_611795 = header.getOrDefault("X-Amz-Algorithm")
  valid_611795 = validateParameter(valid_611795, JString, required = false,
                                 default = nil)
  if valid_611795 != nil:
    section.add "X-Amz-Algorithm", valid_611795
  var valid_611796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611796 = validateParameter(valid_611796, JString, required = false,
                                 default = nil)
  if valid_611796 != nil:
    section.add "X-Amz-SignedHeaders", valid_611796
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_611797 = formData.getOrDefault("DomainNames")
  valid_611797 = validateParameter(valid_611797, JArray, required = false,
                                 default = nil)
  if valid_611797 != nil:
    section.add "DomainNames", valid_611797
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611798: Call_PostDescribeDomains_611785; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611798.validator(path, query, header, formData, body)
  let scheme = call_611798.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611798.url(scheme.get, call_611798.host, call_611798.base,
                         call_611798.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611798, url, valid)

proc call*(call_611799: Call_PostDescribeDomains_611785;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611800 = newJObject()
  var formData_611801 = newJObject()
  if DomainNames != nil:
    formData_611801.add "DomainNames", DomainNames
  add(query_611800, "Action", newJString(Action))
  add(query_611800, "Version", newJString(Version))
  result = call_611799.call(nil, query_611800, nil, formData_611801, nil)

var postDescribeDomains* = Call_PostDescribeDomains_611785(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_611786, base: "/",
    url: url_PostDescribeDomains_611787, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_611769 = ref object of OpenApiRestCall_610658
proc url_GetDescribeDomains_611771(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDomains_611770(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611772 = query.getOrDefault("DomainNames")
  valid_611772 = validateParameter(valid_611772, JArray, required = false,
                                 default = nil)
  if valid_611772 != nil:
    section.add "DomainNames", valid_611772
  var valid_611773 = query.getOrDefault("Action")
  valid_611773 = validateParameter(valid_611773, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_611773 != nil:
    section.add "Action", valid_611773
  var valid_611774 = query.getOrDefault("Version")
  valid_611774 = validateParameter(valid_611774, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611774 != nil:
    section.add "Version", valid_611774
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611775 = header.getOrDefault("X-Amz-Signature")
  valid_611775 = validateParameter(valid_611775, JString, required = false,
                                 default = nil)
  if valid_611775 != nil:
    section.add "X-Amz-Signature", valid_611775
  var valid_611776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611776 = validateParameter(valid_611776, JString, required = false,
                                 default = nil)
  if valid_611776 != nil:
    section.add "X-Amz-Content-Sha256", valid_611776
  var valid_611777 = header.getOrDefault("X-Amz-Date")
  valid_611777 = validateParameter(valid_611777, JString, required = false,
                                 default = nil)
  if valid_611777 != nil:
    section.add "X-Amz-Date", valid_611777
  var valid_611778 = header.getOrDefault("X-Amz-Credential")
  valid_611778 = validateParameter(valid_611778, JString, required = false,
                                 default = nil)
  if valid_611778 != nil:
    section.add "X-Amz-Credential", valid_611778
  var valid_611779 = header.getOrDefault("X-Amz-Security-Token")
  valid_611779 = validateParameter(valid_611779, JString, required = false,
                                 default = nil)
  if valid_611779 != nil:
    section.add "X-Amz-Security-Token", valid_611779
  var valid_611780 = header.getOrDefault("X-Amz-Algorithm")
  valid_611780 = validateParameter(valid_611780, JString, required = false,
                                 default = nil)
  if valid_611780 != nil:
    section.add "X-Amz-Algorithm", valid_611780
  var valid_611781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611781 = validateParameter(valid_611781, JString, required = false,
                                 default = nil)
  if valid_611781 != nil:
    section.add "X-Amz-SignedHeaders", valid_611781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611782: Call_GetDescribeDomains_611769; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611782.validator(path, query, header, formData, body)
  let scheme = call_611782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611782.url(scheme.get, call_611782.host, call_611782.base,
                         call_611782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611782, url, valid)

proc call*(call_611783: Call_GetDescribeDomains_611769;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611784 = newJObject()
  if DomainNames != nil:
    query_611784.add "DomainNames", DomainNames
  add(query_611784, "Action", newJString(Action))
  add(query_611784, "Version", newJString(Version))
  result = call_611783.call(nil, query_611784, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_611769(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_611770, base: "/",
    url: url_GetDescribeDomains_611771, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeExpressions_611820 = ref object of OpenApiRestCall_610658
proc url_PostDescribeExpressions_611822(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeExpressions_611821(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611823 = query.getOrDefault("Action")
  valid_611823 = validateParameter(valid_611823, JString, required = true,
                                 default = newJString("DescribeExpressions"))
  if valid_611823 != nil:
    section.add "Action", valid_611823
  var valid_611824 = query.getOrDefault("Version")
  valid_611824 = validateParameter(valid_611824, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611824 != nil:
    section.add "Version", valid_611824
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611825 = header.getOrDefault("X-Amz-Signature")
  valid_611825 = validateParameter(valid_611825, JString, required = false,
                                 default = nil)
  if valid_611825 != nil:
    section.add "X-Amz-Signature", valid_611825
  var valid_611826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611826 = validateParameter(valid_611826, JString, required = false,
                                 default = nil)
  if valid_611826 != nil:
    section.add "X-Amz-Content-Sha256", valid_611826
  var valid_611827 = header.getOrDefault("X-Amz-Date")
  valid_611827 = validateParameter(valid_611827, JString, required = false,
                                 default = nil)
  if valid_611827 != nil:
    section.add "X-Amz-Date", valid_611827
  var valid_611828 = header.getOrDefault("X-Amz-Credential")
  valid_611828 = validateParameter(valid_611828, JString, required = false,
                                 default = nil)
  if valid_611828 != nil:
    section.add "X-Amz-Credential", valid_611828
  var valid_611829 = header.getOrDefault("X-Amz-Security-Token")
  valid_611829 = validateParameter(valid_611829, JString, required = false,
                                 default = nil)
  if valid_611829 != nil:
    section.add "X-Amz-Security-Token", valid_611829
  var valid_611830 = header.getOrDefault("X-Amz-Algorithm")
  valid_611830 = validateParameter(valid_611830, JString, required = false,
                                 default = nil)
  if valid_611830 != nil:
    section.add "X-Amz-Algorithm", valid_611830
  var valid_611831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611831 = validateParameter(valid_611831, JString, required = false,
                                 default = nil)
  if valid_611831 != nil:
    section.add "X-Amz-SignedHeaders", valid_611831
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  section = newJObject()
  var valid_611832 = formData.getOrDefault("Deployed")
  valid_611832 = validateParameter(valid_611832, JBool, required = false, default = nil)
  if valid_611832 != nil:
    section.add "Deployed", valid_611832
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611833 = formData.getOrDefault("DomainName")
  valid_611833 = validateParameter(valid_611833, JString, required = true,
                                 default = nil)
  if valid_611833 != nil:
    section.add "DomainName", valid_611833
  var valid_611834 = formData.getOrDefault("ExpressionNames")
  valid_611834 = validateParameter(valid_611834, JArray, required = false,
                                 default = nil)
  if valid_611834 != nil:
    section.add "ExpressionNames", valid_611834
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611835: Call_PostDescribeExpressions_611820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611835.validator(path, query, header, formData, body)
  let scheme = call_611835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611835.url(scheme.get, call_611835.host, call_611835.base,
                         call_611835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611835, url, valid)

proc call*(call_611836: Call_PostDescribeExpressions_611820; DomainName: string;
          Deployed: bool = false; Action: string = "DescribeExpressions";
          ExpressionNames: JsonNode = nil; Version: string = "2013-01-01"): Recallable =
  ## postDescribeExpressions
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  ##   Version: string (required)
  var query_611837 = newJObject()
  var formData_611838 = newJObject()
  add(formData_611838, "Deployed", newJBool(Deployed))
  add(formData_611838, "DomainName", newJString(DomainName))
  add(query_611837, "Action", newJString(Action))
  if ExpressionNames != nil:
    formData_611838.add "ExpressionNames", ExpressionNames
  add(query_611837, "Version", newJString(Version))
  result = call_611836.call(nil, query_611837, nil, formData_611838, nil)

var postDescribeExpressions* = Call_PostDescribeExpressions_611820(
    name: "postDescribeExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_PostDescribeExpressions_611821, base: "/",
    url: url_PostDescribeExpressions_611822, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeExpressions_611802 = ref object of OpenApiRestCall_610658
proc url_GetDescribeExpressions_611804(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeExpressions_611803(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611805 = query.getOrDefault("ExpressionNames")
  valid_611805 = validateParameter(valid_611805, JArray, required = false,
                                 default = nil)
  if valid_611805 != nil:
    section.add "ExpressionNames", valid_611805
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611806 = query.getOrDefault("DomainName")
  valid_611806 = validateParameter(valid_611806, JString, required = true,
                                 default = nil)
  if valid_611806 != nil:
    section.add "DomainName", valid_611806
  var valid_611807 = query.getOrDefault("Deployed")
  valid_611807 = validateParameter(valid_611807, JBool, required = false, default = nil)
  if valid_611807 != nil:
    section.add "Deployed", valid_611807
  var valid_611808 = query.getOrDefault("Action")
  valid_611808 = validateParameter(valid_611808, JString, required = true,
                                 default = newJString("DescribeExpressions"))
  if valid_611808 != nil:
    section.add "Action", valid_611808
  var valid_611809 = query.getOrDefault("Version")
  valid_611809 = validateParameter(valid_611809, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611809 != nil:
    section.add "Version", valid_611809
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611810 = header.getOrDefault("X-Amz-Signature")
  valid_611810 = validateParameter(valid_611810, JString, required = false,
                                 default = nil)
  if valid_611810 != nil:
    section.add "X-Amz-Signature", valid_611810
  var valid_611811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611811 = validateParameter(valid_611811, JString, required = false,
                                 default = nil)
  if valid_611811 != nil:
    section.add "X-Amz-Content-Sha256", valid_611811
  var valid_611812 = header.getOrDefault("X-Amz-Date")
  valid_611812 = validateParameter(valid_611812, JString, required = false,
                                 default = nil)
  if valid_611812 != nil:
    section.add "X-Amz-Date", valid_611812
  var valid_611813 = header.getOrDefault("X-Amz-Credential")
  valid_611813 = validateParameter(valid_611813, JString, required = false,
                                 default = nil)
  if valid_611813 != nil:
    section.add "X-Amz-Credential", valid_611813
  var valid_611814 = header.getOrDefault("X-Amz-Security-Token")
  valid_611814 = validateParameter(valid_611814, JString, required = false,
                                 default = nil)
  if valid_611814 != nil:
    section.add "X-Amz-Security-Token", valid_611814
  var valid_611815 = header.getOrDefault("X-Amz-Algorithm")
  valid_611815 = validateParameter(valid_611815, JString, required = false,
                                 default = nil)
  if valid_611815 != nil:
    section.add "X-Amz-Algorithm", valid_611815
  var valid_611816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611816 = validateParameter(valid_611816, JString, required = false,
                                 default = nil)
  if valid_611816 != nil:
    section.add "X-Amz-SignedHeaders", valid_611816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611817: Call_GetDescribeExpressions_611802; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611817.validator(path, query, header, formData, body)
  let scheme = call_611817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611817.url(scheme.get, call_611817.host, call_611817.base,
                         call_611817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611817, url, valid)

proc call*(call_611818: Call_GetDescribeExpressions_611802; DomainName: string;
          ExpressionNames: JsonNode = nil; Deployed: bool = false;
          Action: string = "DescribeExpressions"; Version: string = "2013-01-01"): Recallable =
  ## getDescribeExpressions
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611819 = newJObject()
  if ExpressionNames != nil:
    query_611819.add "ExpressionNames", ExpressionNames
  add(query_611819, "DomainName", newJString(DomainName))
  add(query_611819, "Deployed", newJBool(Deployed))
  add(query_611819, "Action", newJString(Action))
  add(query_611819, "Version", newJString(Version))
  result = call_611818.call(nil, query_611819, nil, nil, nil)

var getDescribeExpressions* = Call_GetDescribeExpressions_611802(
    name: "getDescribeExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_GetDescribeExpressions_611803, base: "/",
    url: url_GetDescribeExpressions_611804, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_611857 = ref object of OpenApiRestCall_610658
proc url_PostDescribeIndexFields_611859(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeIndexFields_611858(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611860 = query.getOrDefault("Action")
  valid_611860 = validateParameter(valid_611860, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_611860 != nil:
    section.add "Action", valid_611860
  var valid_611861 = query.getOrDefault("Version")
  valid_611861 = validateParameter(valid_611861, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611861 != nil:
    section.add "Version", valid_611861
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611862 = header.getOrDefault("X-Amz-Signature")
  valid_611862 = validateParameter(valid_611862, JString, required = false,
                                 default = nil)
  if valid_611862 != nil:
    section.add "X-Amz-Signature", valid_611862
  var valid_611863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611863 = validateParameter(valid_611863, JString, required = false,
                                 default = nil)
  if valid_611863 != nil:
    section.add "X-Amz-Content-Sha256", valid_611863
  var valid_611864 = header.getOrDefault("X-Amz-Date")
  valid_611864 = validateParameter(valid_611864, JString, required = false,
                                 default = nil)
  if valid_611864 != nil:
    section.add "X-Amz-Date", valid_611864
  var valid_611865 = header.getOrDefault("X-Amz-Credential")
  valid_611865 = validateParameter(valid_611865, JString, required = false,
                                 default = nil)
  if valid_611865 != nil:
    section.add "X-Amz-Credential", valid_611865
  var valid_611866 = header.getOrDefault("X-Amz-Security-Token")
  valid_611866 = validateParameter(valid_611866, JString, required = false,
                                 default = nil)
  if valid_611866 != nil:
    section.add "X-Amz-Security-Token", valid_611866
  var valid_611867 = header.getOrDefault("X-Amz-Algorithm")
  valid_611867 = validateParameter(valid_611867, JString, required = false,
                                 default = nil)
  if valid_611867 != nil:
    section.add "X-Amz-Algorithm", valid_611867
  var valid_611868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611868 = validateParameter(valid_611868, JString, required = false,
                                 default = nil)
  if valid_611868 != nil:
    section.add "X-Amz-SignedHeaders", valid_611868
  result.add "header", section
  ## parameters in `formData` object:
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_611869 = formData.getOrDefault("FieldNames")
  valid_611869 = validateParameter(valid_611869, JArray, required = false,
                                 default = nil)
  if valid_611869 != nil:
    section.add "FieldNames", valid_611869
  var valid_611870 = formData.getOrDefault("Deployed")
  valid_611870 = validateParameter(valid_611870, JBool, required = false, default = nil)
  if valid_611870 != nil:
    section.add "Deployed", valid_611870
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611871 = formData.getOrDefault("DomainName")
  valid_611871 = validateParameter(valid_611871, JString, required = true,
                                 default = nil)
  if valid_611871 != nil:
    section.add "DomainName", valid_611871
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611872: Call_PostDescribeIndexFields_611857; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611872.validator(path, query, header, formData, body)
  let scheme = call_611872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611872.url(scheme.get, call_611872.host, call_611872.base,
                         call_611872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611872, url, valid)

proc call*(call_611873: Call_PostDescribeIndexFields_611857; DomainName: string;
          FieldNames: JsonNode = nil; Deployed: bool = false;
          Action: string = "DescribeIndexFields"; Version: string = "2013-01-01"): Recallable =
  ## postDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611874 = newJObject()
  var formData_611875 = newJObject()
  if FieldNames != nil:
    formData_611875.add "FieldNames", FieldNames
  add(formData_611875, "Deployed", newJBool(Deployed))
  add(formData_611875, "DomainName", newJString(DomainName))
  add(query_611874, "Action", newJString(Action))
  add(query_611874, "Version", newJString(Version))
  result = call_611873.call(nil, query_611874, nil, formData_611875, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_611857(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_611858, base: "/",
    url: url_PostDescribeIndexFields_611859, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_611839 = ref object of OpenApiRestCall_610658
proc url_GetDescribeIndexFields_611841(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeIndexFields_611840(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611842 = query.getOrDefault("DomainName")
  valid_611842 = validateParameter(valid_611842, JString, required = true,
                                 default = nil)
  if valid_611842 != nil:
    section.add "DomainName", valid_611842
  var valid_611843 = query.getOrDefault("Deployed")
  valid_611843 = validateParameter(valid_611843, JBool, required = false, default = nil)
  if valid_611843 != nil:
    section.add "Deployed", valid_611843
  var valid_611844 = query.getOrDefault("Action")
  valid_611844 = validateParameter(valid_611844, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_611844 != nil:
    section.add "Action", valid_611844
  var valid_611845 = query.getOrDefault("Version")
  valid_611845 = validateParameter(valid_611845, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611845 != nil:
    section.add "Version", valid_611845
  var valid_611846 = query.getOrDefault("FieldNames")
  valid_611846 = validateParameter(valid_611846, JArray, required = false,
                                 default = nil)
  if valid_611846 != nil:
    section.add "FieldNames", valid_611846
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611847 = header.getOrDefault("X-Amz-Signature")
  valid_611847 = validateParameter(valid_611847, JString, required = false,
                                 default = nil)
  if valid_611847 != nil:
    section.add "X-Amz-Signature", valid_611847
  var valid_611848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611848 = validateParameter(valid_611848, JString, required = false,
                                 default = nil)
  if valid_611848 != nil:
    section.add "X-Amz-Content-Sha256", valid_611848
  var valid_611849 = header.getOrDefault("X-Amz-Date")
  valid_611849 = validateParameter(valid_611849, JString, required = false,
                                 default = nil)
  if valid_611849 != nil:
    section.add "X-Amz-Date", valid_611849
  var valid_611850 = header.getOrDefault("X-Amz-Credential")
  valid_611850 = validateParameter(valid_611850, JString, required = false,
                                 default = nil)
  if valid_611850 != nil:
    section.add "X-Amz-Credential", valid_611850
  var valid_611851 = header.getOrDefault("X-Amz-Security-Token")
  valid_611851 = validateParameter(valid_611851, JString, required = false,
                                 default = nil)
  if valid_611851 != nil:
    section.add "X-Amz-Security-Token", valid_611851
  var valid_611852 = header.getOrDefault("X-Amz-Algorithm")
  valid_611852 = validateParameter(valid_611852, JString, required = false,
                                 default = nil)
  if valid_611852 != nil:
    section.add "X-Amz-Algorithm", valid_611852
  var valid_611853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611853 = validateParameter(valid_611853, JString, required = false,
                                 default = nil)
  if valid_611853 != nil:
    section.add "X-Amz-SignedHeaders", valid_611853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611854: Call_GetDescribeIndexFields_611839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611854.validator(path, query, header, formData, body)
  let scheme = call_611854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611854.url(scheme.get, call_611854.host, call_611854.base,
                         call_611854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611854, url, valid)

proc call*(call_611855: Call_GetDescribeIndexFields_611839; DomainName: string;
          Deployed: bool = false; Action: string = "DescribeIndexFields";
          Version: string = "2013-01-01"; FieldNames: JsonNode = nil): Recallable =
  ## getDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  var query_611856 = newJObject()
  add(query_611856, "DomainName", newJString(DomainName))
  add(query_611856, "Deployed", newJBool(Deployed))
  add(query_611856, "Action", newJString(Action))
  add(query_611856, "Version", newJString(Version))
  if FieldNames != nil:
    query_611856.add "FieldNames", FieldNames
  result = call_611855.call(nil, query_611856, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_611839(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_611840, base: "/",
    url: url_GetDescribeIndexFields_611841, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeScalingParameters_611892 = ref object of OpenApiRestCall_610658
proc url_PostDescribeScalingParameters_611894(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeScalingParameters_611893(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611895 = query.getOrDefault("Action")
  valid_611895 = validateParameter(valid_611895, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_611895 != nil:
    section.add "Action", valid_611895
  var valid_611896 = query.getOrDefault("Version")
  valid_611896 = validateParameter(valid_611896, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611896 != nil:
    section.add "Version", valid_611896
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611897 = header.getOrDefault("X-Amz-Signature")
  valid_611897 = validateParameter(valid_611897, JString, required = false,
                                 default = nil)
  if valid_611897 != nil:
    section.add "X-Amz-Signature", valid_611897
  var valid_611898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611898 = validateParameter(valid_611898, JString, required = false,
                                 default = nil)
  if valid_611898 != nil:
    section.add "X-Amz-Content-Sha256", valid_611898
  var valid_611899 = header.getOrDefault("X-Amz-Date")
  valid_611899 = validateParameter(valid_611899, JString, required = false,
                                 default = nil)
  if valid_611899 != nil:
    section.add "X-Amz-Date", valid_611899
  var valid_611900 = header.getOrDefault("X-Amz-Credential")
  valid_611900 = validateParameter(valid_611900, JString, required = false,
                                 default = nil)
  if valid_611900 != nil:
    section.add "X-Amz-Credential", valid_611900
  var valid_611901 = header.getOrDefault("X-Amz-Security-Token")
  valid_611901 = validateParameter(valid_611901, JString, required = false,
                                 default = nil)
  if valid_611901 != nil:
    section.add "X-Amz-Security-Token", valid_611901
  var valid_611902 = header.getOrDefault("X-Amz-Algorithm")
  valid_611902 = validateParameter(valid_611902, JString, required = false,
                                 default = nil)
  if valid_611902 != nil:
    section.add "X-Amz-Algorithm", valid_611902
  var valid_611903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611903 = validateParameter(valid_611903, JString, required = false,
                                 default = nil)
  if valid_611903 != nil:
    section.add "X-Amz-SignedHeaders", valid_611903
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611904 = formData.getOrDefault("DomainName")
  valid_611904 = validateParameter(valid_611904, JString, required = true,
                                 default = nil)
  if valid_611904 != nil:
    section.add "DomainName", valid_611904
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611905: Call_PostDescribeScalingParameters_611892; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611905.validator(path, query, header, formData, body)
  let scheme = call_611905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611905.url(scheme.get, call_611905.host, call_611905.base,
                         call_611905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611905, url, valid)

proc call*(call_611906: Call_PostDescribeScalingParameters_611892;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611907 = newJObject()
  var formData_611908 = newJObject()
  add(formData_611908, "DomainName", newJString(DomainName))
  add(query_611907, "Action", newJString(Action))
  add(query_611907, "Version", newJString(Version))
  result = call_611906.call(nil, query_611907, nil, formData_611908, nil)

var postDescribeScalingParameters* = Call_PostDescribeScalingParameters_611892(
    name: "postDescribeScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_PostDescribeScalingParameters_611893, base: "/",
    url: url_PostDescribeScalingParameters_611894,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeScalingParameters_611876 = ref object of OpenApiRestCall_610658
proc url_GetDescribeScalingParameters_611878(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeScalingParameters_611877(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611879 = query.getOrDefault("DomainName")
  valid_611879 = validateParameter(valid_611879, JString, required = true,
                                 default = nil)
  if valid_611879 != nil:
    section.add "DomainName", valid_611879
  var valid_611880 = query.getOrDefault("Action")
  valid_611880 = validateParameter(valid_611880, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_611880 != nil:
    section.add "Action", valid_611880
  var valid_611881 = query.getOrDefault("Version")
  valid_611881 = validateParameter(valid_611881, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611881 != nil:
    section.add "Version", valid_611881
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611882 = header.getOrDefault("X-Amz-Signature")
  valid_611882 = validateParameter(valid_611882, JString, required = false,
                                 default = nil)
  if valid_611882 != nil:
    section.add "X-Amz-Signature", valid_611882
  var valid_611883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611883 = validateParameter(valid_611883, JString, required = false,
                                 default = nil)
  if valid_611883 != nil:
    section.add "X-Amz-Content-Sha256", valid_611883
  var valid_611884 = header.getOrDefault("X-Amz-Date")
  valid_611884 = validateParameter(valid_611884, JString, required = false,
                                 default = nil)
  if valid_611884 != nil:
    section.add "X-Amz-Date", valid_611884
  var valid_611885 = header.getOrDefault("X-Amz-Credential")
  valid_611885 = validateParameter(valid_611885, JString, required = false,
                                 default = nil)
  if valid_611885 != nil:
    section.add "X-Amz-Credential", valid_611885
  var valid_611886 = header.getOrDefault("X-Amz-Security-Token")
  valid_611886 = validateParameter(valid_611886, JString, required = false,
                                 default = nil)
  if valid_611886 != nil:
    section.add "X-Amz-Security-Token", valid_611886
  var valid_611887 = header.getOrDefault("X-Amz-Algorithm")
  valid_611887 = validateParameter(valid_611887, JString, required = false,
                                 default = nil)
  if valid_611887 != nil:
    section.add "X-Amz-Algorithm", valid_611887
  var valid_611888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611888 = validateParameter(valid_611888, JString, required = false,
                                 default = nil)
  if valid_611888 != nil:
    section.add "X-Amz-SignedHeaders", valid_611888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611889: Call_GetDescribeScalingParameters_611876; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611889.validator(path, query, header, formData, body)
  let scheme = call_611889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611889.url(scheme.get, call_611889.host, call_611889.base,
                         call_611889.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611889, url, valid)

proc call*(call_611890: Call_GetDescribeScalingParameters_611876;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611891 = newJObject()
  add(query_611891, "DomainName", newJString(DomainName))
  add(query_611891, "Action", newJString(Action))
  add(query_611891, "Version", newJString(Version))
  result = call_611890.call(nil, query_611891, nil, nil, nil)

var getDescribeScalingParameters* = Call_GetDescribeScalingParameters_611876(
    name: "getDescribeScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_GetDescribeScalingParameters_611877, base: "/",
    url: url_GetDescribeScalingParameters_611878,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_611926 = ref object of OpenApiRestCall_610658
proc url_PostDescribeServiceAccessPolicies_611928(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeServiceAccessPolicies_611927(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611929 = query.getOrDefault("Action")
  valid_611929 = validateParameter(valid_611929, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_611929 != nil:
    section.add "Action", valid_611929
  var valid_611930 = query.getOrDefault("Version")
  valid_611930 = validateParameter(valid_611930, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611930 != nil:
    section.add "Version", valid_611930
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611931 = header.getOrDefault("X-Amz-Signature")
  valid_611931 = validateParameter(valid_611931, JString, required = false,
                                 default = nil)
  if valid_611931 != nil:
    section.add "X-Amz-Signature", valid_611931
  var valid_611932 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611932 = validateParameter(valid_611932, JString, required = false,
                                 default = nil)
  if valid_611932 != nil:
    section.add "X-Amz-Content-Sha256", valid_611932
  var valid_611933 = header.getOrDefault("X-Amz-Date")
  valid_611933 = validateParameter(valid_611933, JString, required = false,
                                 default = nil)
  if valid_611933 != nil:
    section.add "X-Amz-Date", valid_611933
  var valid_611934 = header.getOrDefault("X-Amz-Credential")
  valid_611934 = validateParameter(valid_611934, JString, required = false,
                                 default = nil)
  if valid_611934 != nil:
    section.add "X-Amz-Credential", valid_611934
  var valid_611935 = header.getOrDefault("X-Amz-Security-Token")
  valid_611935 = validateParameter(valid_611935, JString, required = false,
                                 default = nil)
  if valid_611935 != nil:
    section.add "X-Amz-Security-Token", valid_611935
  var valid_611936 = header.getOrDefault("X-Amz-Algorithm")
  valid_611936 = validateParameter(valid_611936, JString, required = false,
                                 default = nil)
  if valid_611936 != nil:
    section.add "X-Amz-Algorithm", valid_611936
  var valid_611937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611937 = validateParameter(valid_611937, JString, required = false,
                                 default = nil)
  if valid_611937 != nil:
    section.add "X-Amz-SignedHeaders", valid_611937
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_611938 = formData.getOrDefault("Deployed")
  valid_611938 = validateParameter(valid_611938, JBool, required = false, default = nil)
  if valid_611938 != nil:
    section.add "Deployed", valid_611938
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611939 = formData.getOrDefault("DomainName")
  valid_611939 = validateParameter(valid_611939, JString, required = true,
                                 default = nil)
  if valid_611939 != nil:
    section.add "DomainName", valid_611939
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611940: Call_PostDescribeServiceAccessPolicies_611926;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611940.validator(path, query, header, formData, body)
  let scheme = call_611940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611940.url(scheme.get, call_611940.host, call_611940.base,
                         call_611940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611940, url, valid)

proc call*(call_611941: Call_PostDescribeServiceAccessPolicies_611926;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeServiceAccessPolicies
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611942 = newJObject()
  var formData_611943 = newJObject()
  add(formData_611943, "Deployed", newJBool(Deployed))
  add(formData_611943, "DomainName", newJString(DomainName))
  add(query_611942, "Action", newJString(Action))
  add(query_611942, "Version", newJString(Version))
  result = call_611941.call(nil, query_611942, nil, formData_611943, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_611926(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_611927, base: "/",
    url: url_PostDescribeServiceAccessPolicies_611928,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_611909 = ref object of OpenApiRestCall_610658
proc url_GetDescribeServiceAccessPolicies_611911(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeServiceAccessPolicies_611910(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611912 = query.getOrDefault("DomainName")
  valid_611912 = validateParameter(valid_611912, JString, required = true,
                                 default = nil)
  if valid_611912 != nil:
    section.add "DomainName", valid_611912
  var valid_611913 = query.getOrDefault("Deployed")
  valid_611913 = validateParameter(valid_611913, JBool, required = false, default = nil)
  if valid_611913 != nil:
    section.add "Deployed", valid_611913
  var valid_611914 = query.getOrDefault("Action")
  valid_611914 = validateParameter(valid_611914, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_611914 != nil:
    section.add "Action", valid_611914
  var valid_611915 = query.getOrDefault("Version")
  valid_611915 = validateParameter(valid_611915, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611915 != nil:
    section.add "Version", valid_611915
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611916 = header.getOrDefault("X-Amz-Signature")
  valid_611916 = validateParameter(valid_611916, JString, required = false,
                                 default = nil)
  if valid_611916 != nil:
    section.add "X-Amz-Signature", valid_611916
  var valid_611917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611917 = validateParameter(valid_611917, JString, required = false,
                                 default = nil)
  if valid_611917 != nil:
    section.add "X-Amz-Content-Sha256", valid_611917
  var valid_611918 = header.getOrDefault("X-Amz-Date")
  valid_611918 = validateParameter(valid_611918, JString, required = false,
                                 default = nil)
  if valid_611918 != nil:
    section.add "X-Amz-Date", valid_611918
  var valid_611919 = header.getOrDefault("X-Amz-Credential")
  valid_611919 = validateParameter(valid_611919, JString, required = false,
                                 default = nil)
  if valid_611919 != nil:
    section.add "X-Amz-Credential", valid_611919
  var valid_611920 = header.getOrDefault("X-Amz-Security-Token")
  valid_611920 = validateParameter(valid_611920, JString, required = false,
                                 default = nil)
  if valid_611920 != nil:
    section.add "X-Amz-Security-Token", valid_611920
  var valid_611921 = header.getOrDefault("X-Amz-Algorithm")
  valid_611921 = validateParameter(valid_611921, JString, required = false,
                                 default = nil)
  if valid_611921 != nil:
    section.add "X-Amz-Algorithm", valid_611921
  var valid_611922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611922 = validateParameter(valid_611922, JString, required = false,
                                 default = nil)
  if valid_611922 != nil:
    section.add "X-Amz-SignedHeaders", valid_611922
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611923: Call_GetDescribeServiceAccessPolicies_611909;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611923.validator(path, query, header, formData, body)
  let scheme = call_611923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611923.url(scheme.get, call_611923.host, call_611923.base,
                         call_611923.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611923, url, valid)

proc call*(call_611924: Call_GetDescribeServiceAccessPolicies_611909;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeServiceAccessPolicies
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611925 = newJObject()
  add(query_611925, "DomainName", newJString(DomainName))
  add(query_611925, "Deployed", newJBool(Deployed))
  add(query_611925, "Action", newJString(Action))
  add(query_611925, "Version", newJString(Version))
  result = call_611924.call(nil, query_611925, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_611909(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_611910, base: "/",
    url: url_GetDescribeServiceAccessPolicies_611911,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSuggesters_611962 = ref object of OpenApiRestCall_610658
proc url_PostDescribeSuggesters_611964(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeSuggesters_611963(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611965 = query.getOrDefault("Action")
  valid_611965 = validateParameter(valid_611965, JString, required = true,
                                 default = newJString("DescribeSuggesters"))
  if valid_611965 != nil:
    section.add "Action", valid_611965
  var valid_611966 = query.getOrDefault("Version")
  valid_611966 = validateParameter(valid_611966, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611966 != nil:
    section.add "Version", valid_611966
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611967 = header.getOrDefault("X-Amz-Signature")
  valid_611967 = validateParameter(valid_611967, JString, required = false,
                                 default = nil)
  if valid_611967 != nil:
    section.add "X-Amz-Signature", valid_611967
  var valid_611968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611968 = validateParameter(valid_611968, JString, required = false,
                                 default = nil)
  if valid_611968 != nil:
    section.add "X-Amz-Content-Sha256", valid_611968
  var valid_611969 = header.getOrDefault("X-Amz-Date")
  valid_611969 = validateParameter(valid_611969, JString, required = false,
                                 default = nil)
  if valid_611969 != nil:
    section.add "X-Amz-Date", valid_611969
  var valid_611970 = header.getOrDefault("X-Amz-Credential")
  valid_611970 = validateParameter(valid_611970, JString, required = false,
                                 default = nil)
  if valid_611970 != nil:
    section.add "X-Amz-Credential", valid_611970
  var valid_611971 = header.getOrDefault("X-Amz-Security-Token")
  valid_611971 = validateParameter(valid_611971, JString, required = false,
                                 default = nil)
  if valid_611971 != nil:
    section.add "X-Amz-Security-Token", valid_611971
  var valid_611972 = header.getOrDefault("X-Amz-Algorithm")
  valid_611972 = validateParameter(valid_611972, JString, required = false,
                                 default = nil)
  if valid_611972 != nil:
    section.add "X-Amz-Algorithm", valid_611972
  var valid_611973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611973 = validateParameter(valid_611973, JString, required = false,
                                 default = nil)
  if valid_611973 != nil:
    section.add "X-Amz-SignedHeaders", valid_611973
  result.add "header", section
  ## parameters in `formData` object:
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_611974 = formData.getOrDefault("SuggesterNames")
  valid_611974 = validateParameter(valid_611974, JArray, required = false,
                                 default = nil)
  if valid_611974 != nil:
    section.add "SuggesterNames", valid_611974
  var valid_611975 = formData.getOrDefault("Deployed")
  valid_611975 = validateParameter(valid_611975, JBool, required = false, default = nil)
  if valid_611975 != nil:
    section.add "Deployed", valid_611975
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611976 = formData.getOrDefault("DomainName")
  valid_611976 = validateParameter(valid_611976, JString, required = true,
                                 default = nil)
  if valid_611976 != nil:
    section.add "DomainName", valid_611976
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611977: Call_PostDescribeSuggesters_611962; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611977.validator(path, query, header, formData, body)
  let scheme = call_611977.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611977.url(scheme.get, call_611977.host, call_611977.base,
                         call_611977.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611977, url, valid)

proc call*(call_611978: Call_PostDescribeSuggesters_611962; DomainName: string;
          SuggesterNames: JsonNode = nil; Deployed: bool = false;
          Action: string = "DescribeSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## postDescribeSuggesters
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611979 = newJObject()
  var formData_611980 = newJObject()
  if SuggesterNames != nil:
    formData_611980.add "SuggesterNames", SuggesterNames
  add(formData_611980, "Deployed", newJBool(Deployed))
  add(formData_611980, "DomainName", newJString(DomainName))
  add(query_611979, "Action", newJString(Action))
  add(query_611979, "Version", newJString(Version))
  result = call_611978.call(nil, query_611979, nil, formData_611980, nil)

var postDescribeSuggesters* = Call_PostDescribeSuggesters_611962(
    name: "postDescribeSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_PostDescribeSuggesters_611963, base: "/",
    url: url_PostDescribeSuggesters_611964, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSuggesters_611944 = ref object of OpenApiRestCall_610658
proc url_GetDescribeSuggesters_611946(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeSuggesters_611945(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611947 = query.getOrDefault("DomainName")
  valid_611947 = validateParameter(valid_611947, JString, required = true,
                                 default = nil)
  if valid_611947 != nil:
    section.add "DomainName", valid_611947
  var valid_611948 = query.getOrDefault("Deployed")
  valid_611948 = validateParameter(valid_611948, JBool, required = false, default = nil)
  if valid_611948 != nil:
    section.add "Deployed", valid_611948
  var valid_611949 = query.getOrDefault("Action")
  valid_611949 = validateParameter(valid_611949, JString, required = true,
                                 default = newJString("DescribeSuggesters"))
  if valid_611949 != nil:
    section.add "Action", valid_611949
  var valid_611950 = query.getOrDefault("Version")
  valid_611950 = validateParameter(valid_611950, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611950 != nil:
    section.add "Version", valid_611950
  var valid_611951 = query.getOrDefault("SuggesterNames")
  valid_611951 = validateParameter(valid_611951, JArray, required = false,
                                 default = nil)
  if valid_611951 != nil:
    section.add "SuggesterNames", valid_611951
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611952 = header.getOrDefault("X-Amz-Signature")
  valid_611952 = validateParameter(valid_611952, JString, required = false,
                                 default = nil)
  if valid_611952 != nil:
    section.add "X-Amz-Signature", valid_611952
  var valid_611953 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611953 = validateParameter(valid_611953, JString, required = false,
                                 default = nil)
  if valid_611953 != nil:
    section.add "X-Amz-Content-Sha256", valid_611953
  var valid_611954 = header.getOrDefault("X-Amz-Date")
  valid_611954 = validateParameter(valid_611954, JString, required = false,
                                 default = nil)
  if valid_611954 != nil:
    section.add "X-Amz-Date", valid_611954
  var valid_611955 = header.getOrDefault("X-Amz-Credential")
  valid_611955 = validateParameter(valid_611955, JString, required = false,
                                 default = nil)
  if valid_611955 != nil:
    section.add "X-Amz-Credential", valid_611955
  var valid_611956 = header.getOrDefault("X-Amz-Security-Token")
  valid_611956 = validateParameter(valid_611956, JString, required = false,
                                 default = nil)
  if valid_611956 != nil:
    section.add "X-Amz-Security-Token", valid_611956
  var valid_611957 = header.getOrDefault("X-Amz-Algorithm")
  valid_611957 = validateParameter(valid_611957, JString, required = false,
                                 default = nil)
  if valid_611957 != nil:
    section.add "X-Amz-Algorithm", valid_611957
  var valid_611958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611958 = validateParameter(valid_611958, JString, required = false,
                                 default = nil)
  if valid_611958 != nil:
    section.add "X-Amz-SignedHeaders", valid_611958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611959: Call_GetDescribeSuggesters_611944; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611959.validator(path, query, header, formData, body)
  let scheme = call_611959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611959.url(scheme.get, call_611959.host, call_611959.base,
                         call_611959.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611959, url, valid)

proc call*(call_611960: Call_GetDescribeSuggesters_611944; DomainName: string;
          Deployed: bool = false; Action: string = "DescribeSuggesters";
          Version: string = "2013-01-01"; SuggesterNames: JsonNode = nil): Recallable =
  ## getDescribeSuggesters
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  var query_611961 = newJObject()
  add(query_611961, "DomainName", newJString(DomainName))
  add(query_611961, "Deployed", newJBool(Deployed))
  add(query_611961, "Action", newJString(Action))
  add(query_611961, "Version", newJString(Version))
  if SuggesterNames != nil:
    query_611961.add "SuggesterNames", SuggesterNames
  result = call_611960.call(nil, query_611961, nil, nil, nil)

var getDescribeSuggesters* = Call_GetDescribeSuggesters_611944(
    name: "getDescribeSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_GetDescribeSuggesters_611945, base: "/",
    url: url_GetDescribeSuggesters_611946, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_611997 = ref object of OpenApiRestCall_610658
proc url_PostIndexDocuments_611999(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostIndexDocuments_611998(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612000 = query.getOrDefault("Action")
  valid_612000 = validateParameter(valid_612000, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_612000 != nil:
    section.add "Action", valid_612000
  var valid_612001 = query.getOrDefault("Version")
  valid_612001 = validateParameter(valid_612001, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_612001 != nil:
    section.add "Version", valid_612001
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612002 = header.getOrDefault("X-Amz-Signature")
  valid_612002 = validateParameter(valid_612002, JString, required = false,
                                 default = nil)
  if valid_612002 != nil:
    section.add "X-Amz-Signature", valid_612002
  var valid_612003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612003 = validateParameter(valid_612003, JString, required = false,
                                 default = nil)
  if valid_612003 != nil:
    section.add "X-Amz-Content-Sha256", valid_612003
  var valid_612004 = header.getOrDefault("X-Amz-Date")
  valid_612004 = validateParameter(valid_612004, JString, required = false,
                                 default = nil)
  if valid_612004 != nil:
    section.add "X-Amz-Date", valid_612004
  var valid_612005 = header.getOrDefault("X-Amz-Credential")
  valid_612005 = validateParameter(valid_612005, JString, required = false,
                                 default = nil)
  if valid_612005 != nil:
    section.add "X-Amz-Credential", valid_612005
  var valid_612006 = header.getOrDefault("X-Amz-Security-Token")
  valid_612006 = validateParameter(valid_612006, JString, required = false,
                                 default = nil)
  if valid_612006 != nil:
    section.add "X-Amz-Security-Token", valid_612006
  var valid_612007 = header.getOrDefault("X-Amz-Algorithm")
  valid_612007 = validateParameter(valid_612007, JString, required = false,
                                 default = nil)
  if valid_612007 != nil:
    section.add "X-Amz-Algorithm", valid_612007
  var valid_612008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612008 = validateParameter(valid_612008, JString, required = false,
                                 default = nil)
  if valid_612008 != nil:
    section.add "X-Amz-SignedHeaders", valid_612008
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_612009 = formData.getOrDefault("DomainName")
  valid_612009 = validateParameter(valid_612009, JString, required = true,
                                 default = nil)
  if valid_612009 != nil:
    section.add "DomainName", valid_612009
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612010: Call_PostIndexDocuments_611997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_612010.validator(path, query, header, formData, body)
  let scheme = call_612010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612010.url(scheme.get, call_612010.host, call_612010.base,
                         call_612010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612010, url, valid)

proc call*(call_612011: Call_PostIndexDocuments_611997; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612012 = newJObject()
  var formData_612013 = newJObject()
  add(formData_612013, "DomainName", newJString(DomainName))
  add(query_612012, "Action", newJString(Action))
  add(query_612012, "Version", newJString(Version))
  result = call_612011.call(nil, query_612012, nil, formData_612013, nil)

var postIndexDocuments* = Call_PostIndexDocuments_611997(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_611998, base: "/",
    url: url_PostIndexDocuments_611999, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_611981 = ref object of OpenApiRestCall_610658
proc url_GetIndexDocuments_611983(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetIndexDocuments_611982(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611984 = query.getOrDefault("DomainName")
  valid_611984 = validateParameter(valid_611984, JString, required = true,
                                 default = nil)
  if valid_611984 != nil:
    section.add "DomainName", valid_611984
  var valid_611985 = query.getOrDefault("Action")
  valid_611985 = validateParameter(valid_611985, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_611985 != nil:
    section.add "Action", valid_611985
  var valid_611986 = query.getOrDefault("Version")
  valid_611986 = validateParameter(valid_611986, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_611986 != nil:
    section.add "Version", valid_611986
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611987 = header.getOrDefault("X-Amz-Signature")
  valid_611987 = validateParameter(valid_611987, JString, required = false,
                                 default = nil)
  if valid_611987 != nil:
    section.add "X-Amz-Signature", valid_611987
  var valid_611988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611988 = validateParameter(valid_611988, JString, required = false,
                                 default = nil)
  if valid_611988 != nil:
    section.add "X-Amz-Content-Sha256", valid_611988
  var valid_611989 = header.getOrDefault("X-Amz-Date")
  valid_611989 = validateParameter(valid_611989, JString, required = false,
                                 default = nil)
  if valid_611989 != nil:
    section.add "X-Amz-Date", valid_611989
  var valid_611990 = header.getOrDefault("X-Amz-Credential")
  valid_611990 = validateParameter(valid_611990, JString, required = false,
                                 default = nil)
  if valid_611990 != nil:
    section.add "X-Amz-Credential", valid_611990
  var valid_611991 = header.getOrDefault("X-Amz-Security-Token")
  valid_611991 = validateParameter(valid_611991, JString, required = false,
                                 default = nil)
  if valid_611991 != nil:
    section.add "X-Amz-Security-Token", valid_611991
  var valid_611992 = header.getOrDefault("X-Amz-Algorithm")
  valid_611992 = validateParameter(valid_611992, JString, required = false,
                                 default = nil)
  if valid_611992 != nil:
    section.add "X-Amz-Algorithm", valid_611992
  var valid_611993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611993 = validateParameter(valid_611993, JString, required = false,
                                 default = nil)
  if valid_611993 != nil:
    section.add "X-Amz-SignedHeaders", valid_611993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611994: Call_GetIndexDocuments_611981; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_611994.validator(path, query, header, formData, body)
  let scheme = call_611994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611994.url(scheme.get, call_611994.host, call_611994.base,
                         call_611994.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611994, url, valid)

proc call*(call_611995: Call_GetIndexDocuments_611981; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611996 = newJObject()
  add(query_611996, "DomainName", newJString(DomainName))
  add(query_611996, "Action", newJString(Action))
  add(query_611996, "Version", newJString(Version))
  result = call_611995.call(nil, query_611996, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_611981(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_611982,
    base: "/", url: url_GetIndexDocuments_611983,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomainNames_612029 = ref object of OpenApiRestCall_610658
proc url_PostListDomainNames_612031(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListDomainNames_612030(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists all search domains owned by an account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612032 = query.getOrDefault("Action")
  valid_612032 = validateParameter(valid_612032, JString, required = true,
                                 default = newJString("ListDomainNames"))
  if valid_612032 != nil:
    section.add "Action", valid_612032
  var valid_612033 = query.getOrDefault("Version")
  valid_612033 = validateParameter(valid_612033, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_612033 != nil:
    section.add "Version", valid_612033
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612034 = header.getOrDefault("X-Amz-Signature")
  valid_612034 = validateParameter(valid_612034, JString, required = false,
                                 default = nil)
  if valid_612034 != nil:
    section.add "X-Amz-Signature", valid_612034
  var valid_612035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612035 = validateParameter(valid_612035, JString, required = false,
                                 default = nil)
  if valid_612035 != nil:
    section.add "X-Amz-Content-Sha256", valid_612035
  var valid_612036 = header.getOrDefault("X-Amz-Date")
  valid_612036 = validateParameter(valid_612036, JString, required = false,
                                 default = nil)
  if valid_612036 != nil:
    section.add "X-Amz-Date", valid_612036
  var valid_612037 = header.getOrDefault("X-Amz-Credential")
  valid_612037 = validateParameter(valid_612037, JString, required = false,
                                 default = nil)
  if valid_612037 != nil:
    section.add "X-Amz-Credential", valid_612037
  var valid_612038 = header.getOrDefault("X-Amz-Security-Token")
  valid_612038 = validateParameter(valid_612038, JString, required = false,
                                 default = nil)
  if valid_612038 != nil:
    section.add "X-Amz-Security-Token", valid_612038
  var valid_612039 = header.getOrDefault("X-Amz-Algorithm")
  valid_612039 = validateParameter(valid_612039, JString, required = false,
                                 default = nil)
  if valid_612039 != nil:
    section.add "X-Amz-Algorithm", valid_612039
  var valid_612040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612040 = validateParameter(valid_612040, JString, required = false,
                                 default = nil)
  if valid_612040 != nil:
    section.add "X-Amz-SignedHeaders", valid_612040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612041: Call_PostListDomainNames_612029; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_612041.validator(path, query, header, formData, body)
  let scheme = call_612041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612041.url(scheme.get, call_612041.host, call_612041.base,
                         call_612041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612041, url, valid)

proc call*(call_612042: Call_PostListDomainNames_612029;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## postListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612043 = newJObject()
  add(query_612043, "Action", newJString(Action))
  add(query_612043, "Version", newJString(Version))
  result = call_612042.call(nil, query_612043, nil, nil, nil)

var postListDomainNames* = Call_PostListDomainNames_612029(
    name: "postListDomainNames", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_PostListDomainNames_612030, base: "/",
    url: url_PostListDomainNames_612031, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomainNames_612014 = ref object of OpenApiRestCall_610658
proc url_GetListDomainNames_612016(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListDomainNames_612015(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Lists all search domains owned by an account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612017 = query.getOrDefault("Action")
  valid_612017 = validateParameter(valid_612017, JString, required = true,
                                 default = newJString("ListDomainNames"))
  if valid_612017 != nil:
    section.add "Action", valid_612017
  var valid_612018 = query.getOrDefault("Version")
  valid_612018 = validateParameter(valid_612018, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_612018 != nil:
    section.add "Version", valid_612018
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612019 = header.getOrDefault("X-Amz-Signature")
  valid_612019 = validateParameter(valid_612019, JString, required = false,
                                 default = nil)
  if valid_612019 != nil:
    section.add "X-Amz-Signature", valid_612019
  var valid_612020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612020 = validateParameter(valid_612020, JString, required = false,
                                 default = nil)
  if valid_612020 != nil:
    section.add "X-Amz-Content-Sha256", valid_612020
  var valid_612021 = header.getOrDefault("X-Amz-Date")
  valid_612021 = validateParameter(valid_612021, JString, required = false,
                                 default = nil)
  if valid_612021 != nil:
    section.add "X-Amz-Date", valid_612021
  var valid_612022 = header.getOrDefault("X-Amz-Credential")
  valid_612022 = validateParameter(valid_612022, JString, required = false,
                                 default = nil)
  if valid_612022 != nil:
    section.add "X-Amz-Credential", valid_612022
  var valid_612023 = header.getOrDefault("X-Amz-Security-Token")
  valid_612023 = validateParameter(valid_612023, JString, required = false,
                                 default = nil)
  if valid_612023 != nil:
    section.add "X-Amz-Security-Token", valid_612023
  var valid_612024 = header.getOrDefault("X-Amz-Algorithm")
  valid_612024 = validateParameter(valid_612024, JString, required = false,
                                 default = nil)
  if valid_612024 != nil:
    section.add "X-Amz-Algorithm", valid_612024
  var valid_612025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612025 = validateParameter(valid_612025, JString, required = false,
                                 default = nil)
  if valid_612025 != nil:
    section.add "X-Amz-SignedHeaders", valid_612025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612026: Call_GetListDomainNames_612014; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_612026.validator(path, query, header, formData, body)
  let scheme = call_612026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612026.url(scheme.get, call_612026.host, call_612026.base,
                         call_612026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612026, url, valid)

proc call*(call_612027: Call_GetListDomainNames_612014;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## getListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612028 = newJObject()
  add(query_612028, "Action", newJString(Action))
  add(query_612028, "Version", newJString(Version))
  result = call_612027.call(nil, query_612028, nil, nil, nil)

var getListDomainNames* = Call_GetListDomainNames_612014(
    name: "getListDomainNames", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_GetListDomainNames_612015, base: "/",
    url: url_GetListDomainNames_612016, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_612061 = ref object of OpenApiRestCall_610658
proc url_PostUpdateAvailabilityOptions_612063(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateAvailabilityOptions_612062(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612064 = query.getOrDefault("Action")
  valid_612064 = validateParameter(valid_612064, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_612064 != nil:
    section.add "Action", valid_612064
  var valid_612065 = query.getOrDefault("Version")
  valid_612065 = validateParameter(valid_612065, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_612065 != nil:
    section.add "Version", valid_612065
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612066 = header.getOrDefault("X-Amz-Signature")
  valid_612066 = validateParameter(valid_612066, JString, required = false,
                                 default = nil)
  if valid_612066 != nil:
    section.add "X-Amz-Signature", valid_612066
  var valid_612067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612067 = validateParameter(valid_612067, JString, required = false,
                                 default = nil)
  if valid_612067 != nil:
    section.add "X-Amz-Content-Sha256", valid_612067
  var valid_612068 = header.getOrDefault("X-Amz-Date")
  valid_612068 = validateParameter(valid_612068, JString, required = false,
                                 default = nil)
  if valid_612068 != nil:
    section.add "X-Amz-Date", valid_612068
  var valid_612069 = header.getOrDefault("X-Amz-Credential")
  valid_612069 = validateParameter(valid_612069, JString, required = false,
                                 default = nil)
  if valid_612069 != nil:
    section.add "X-Amz-Credential", valid_612069
  var valid_612070 = header.getOrDefault("X-Amz-Security-Token")
  valid_612070 = validateParameter(valid_612070, JString, required = false,
                                 default = nil)
  if valid_612070 != nil:
    section.add "X-Amz-Security-Token", valid_612070
  var valid_612071 = header.getOrDefault("X-Amz-Algorithm")
  valid_612071 = validateParameter(valid_612071, JString, required = false,
                                 default = nil)
  if valid_612071 != nil:
    section.add "X-Amz-Algorithm", valid_612071
  var valid_612072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612072 = validateParameter(valid_612072, JString, required = false,
                                 default = nil)
  if valid_612072 != nil:
    section.add "X-Amz-SignedHeaders", valid_612072
  result.add "header", section
  ## parameters in `formData` object:
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `MultiAZ` field"
  var valid_612073 = formData.getOrDefault("MultiAZ")
  valid_612073 = validateParameter(valid_612073, JBool, required = true, default = nil)
  if valid_612073 != nil:
    section.add "MultiAZ", valid_612073
  var valid_612074 = formData.getOrDefault("DomainName")
  valid_612074 = validateParameter(valid_612074, JString, required = true,
                                 default = nil)
  if valid_612074 != nil:
    section.add "DomainName", valid_612074
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612075: Call_PostUpdateAvailabilityOptions_612061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_612075.validator(path, query, header, formData, body)
  let scheme = call_612075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612075.url(scheme.get, call_612075.host, call_612075.base,
                         call_612075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612075, url, valid)

proc call*(call_612076: Call_PostUpdateAvailabilityOptions_612061; MultiAZ: bool;
          DomainName: string; Action: string = "UpdateAvailabilityOptions";
          Version: string = "2013-01-01"): Recallable =
  ## postUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612077 = newJObject()
  var formData_612078 = newJObject()
  add(formData_612078, "MultiAZ", newJBool(MultiAZ))
  add(formData_612078, "DomainName", newJString(DomainName))
  add(query_612077, "Action", newJString(Action))
  add(query_612077, "Version", newJString(Version))
  result = call_612076.call(nil, query_612077, nil, formData_612078, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_612061(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_612062, base: "/",
    url: url_PostUpdateAvailabilityOptions_612063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_612044 = ref object of OpenApiRestCall_610658
proc url_GetUpdateAvailabilityOptions_612046(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateAvailabilityOptions_612045(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_612047 = query.getOrDefault("DomainName")
  valid_612047 = validateParameter(valid_612047, JString, required = true,
                                 default = nil)
  if valid_612047 != nil:
    section.add "DomainName", valid_612047
  var valid_612048 = query.getOrDefault("Action")
  valid_612048 = validateParameter(valid_612048, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_612048 != nil:
    section.add "Action", valid_612048
  var valid_612049 = query.getOrDefault("MultiAZ")
  valid_612049 = validateParameter(valid_612049, JBool, required = true, default = nil)
  if valid_612049 != nil:
    section.add "MultiAZ", valid_612049
  var valid_612050 = query.getOrDefault("Version")
  valid_612050 = validateParameter(valid_612050, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_612050 != nil:
    section.add "Version", valid_612050
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612051 = header.getOrDefault("X-Amz-Signature")
  valid_612051 = validateParameter(valid_612051, JString, required = false,
                                 default = nil)
  if valid_612051 != nil:
    section.add "X-Amz-Signature", valid_612051
  var valid_612052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612052 = validateParameter(valid_612052, JString, required = false,
                                 default = nil)
  if valid_612052 != nil:
    section.add "X-Amz-Content-Sha256", valid_612052
  var valid_612053 = header.getOrDefault("X-Amz-Date")
  valid_612053 = validateParameter(valid_612053, JString, required = false,
                                 default = nil)
  if valid_612053 != nil:
    section.add "X-Amz-Date", valid_612053
  var valid_612054 = header.getOrDefault("X-Amz-Credential")
  valid_612054 = validateParameter(valid_612054, JString, required = false,
                                 default = nil)
  if valid_612054 != nil:
    section.add "X-Amz-Credential", valid_612054
  var valid_612055 = header.getOrDefault("X-Amz-Security-Token")
  valid_612055 = validateParameter(valid_612055, JString, required = false,
                                 default = nil)
  if valid_612055 != nil:
    section.add "X-Amz-Security-Token", valid_612055
  var valid_612056 = header.getOrDefault("X-Amz-Algorithm")
  valid_612056 = validateParameter(valid_612056, JString, required = false,
                                 default = nil)
  if valid_612056 != nil:
    section.add "X-Amz-Algorithm", valid_612056
  var valid_612057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612057 = validateParameter(valid_612057, JString, required = false,
                                 default = nil)
  if valid_612057 != nil:
    section.add "X-Amz-SignedHeaders", valid_612057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612058: Call_GetUpdateAvailabilityOptions_612044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_612058.validator(path, query, header, formData, body)
  let scheme = call_612058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612058.url(scheme.get, call_612058.host, call_612058.base,
                         call_612058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612058, url, valid)

proc call*(call_612059: Call_GetUpdateAvailabilityOptions_612044;
          DomainName: string; MultiAZ: bool;
          Action: string = "UpdateAvailabilityOptions";
          Version: string = "2013-01-01"): Recallable =
  ## getUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Version: string (required)
  var query_612060 = newJObject()
  add(query_612060, "DomainName", newJString(DomainName))
  add(query_612060, "Action", newJString(Action))
  add(query_612060, "MultiAZ", newJBool(MultiAZ))
  add(query_612060, "Version", newJString(Version))
  result = call_612059.call(nil, query_612060, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_612044(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_612045, base: "/",
    url: url_GetUpdateAvailabilityOptions_612046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateDomainEndpointOptions_612097 = ref object of OpenApiRestCall_610658
proc url_PostUpdateDomainEndpointOptions_612099(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateDomainEndpointOptions_612098(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612100 = query.getOrDefault("Action")
  valid_612100 = validateParameter(valid_612100, JString, required = true, default = newJString(
      "UpdateDomainEndpointOptions"))
  if valid_612100 != nil:
    section.add "Action", valid_612100
  var valid_612101 = query.getOrDefault("Version")
  valid_612101 = validateParameter(valid_612101, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_612101 != nil:
    section.add "Version", valid_612101
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612102 = header.getOrDefault("X-Amz-Signature")
  valid_612102 = validateParameter(valid_612102, JString, required = false,
                                 default = nil)
  if valid_612102 != nil:
    section.add "X-Amz-Signature", valid_612102
  var valid_612103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612103 = validateParameter(valid_612103, JString, required = false,
                                 default = nil)
  if valid_612103 != nil:
    section.add "X-Amz-Content-Sha256", valid_612103
  var valid_612104 = header.getOrDefault("X-Amz-Date")
  valid_612104 = validateParameter(valid_612104, JString, required = false,
                                 default = nil)
  if valid_612104 != nil:
    section.add "X-Amz-Date", valid_612104
  var valid_612105 = header.getOrDefault("X-Amz-Credential")
  valid_612105 = validateParameter(valid_612105, JString, required = false,
                                 default = nil)
  if valid_612105 != nil:
    section.add "X-Amz-Credential", valid_612105
  var valid_612106 = header.getOrDefault("X-Amz-Security-Token")
  valid_612106 = validateParameter(valid_612106, JString, required = false,
                                 default = nil)
  if valid_612106 != nil:
    section.add "X-Amz-Security-Token", valid_612106
  var valid_612107 = header.getOrDefault("X-Amz-Algorithm")
  valid_612107 = validateParameter(valid_612107, JString, required = false,
                                 default = nil)
  if valid_612107 != nil:
    section.add "X-Amz-Algorithm", valid_612107
  var valid_612108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612108 = validateParameter(valid_612108, JString, required = false,
                                 default = nil)
  if valid_612108 != nil:
    section.add "X-Amz-SignedHeaders", valid_612108
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainEndpointOptions.TLSSecurityPolicy: JString
  ##                                          : The domain's endpoint options.
  ## The minimum required TLS version
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   DomainEndpointOptions.EnforceHTTPS: JString
  ##                                     : The domain's endpoint options.
  ## Whether the domain is HTTPS only enabled.
  section = newJObject()
  var valid_612109 = formData.getOrDefault("DomainEndpointOptions.TLSSecurityPolicy")
  valid_612109 = validateParameter(valid_612109, JString, required = false,
                                 default = nil)
  if valid_612109 != nil:
    section.add "DomainEndpointOptions.TLSSecurityPolicy", valid_612109
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_612110 = formData.getOrDefault("DomainName")
  valid_612110 = validateParameter(valid_612110, JString, required = true,
                                 default = nil)
  if valid_612110 != nil:
    section.add "DomainName", valid_612110
  var valid_612111 = formData.getOrDefault("DomainEndpointOptions.EnforceHTTPS")
  valid_612111 = validateParameter(valid_612111, JString, required = false,
                                 default = nil)
  if valid_612111 != nil:
    section.add "DomainEndpointOptions.EnforceHTTPS", valid_612111
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612112: Call_PostUpdateDomainEndpointOptions_612097;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_612112.validator(path, query, header, formData, body)
  let scheme = call_612112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612112.url(scheme.get, call_612112.host, call_612112.base,
                         call_612112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612112, url, valid)

proc call*(call_612113: Call_PostUpdateDomainEndpointOptions_612097;
          DomainName: string; DomainEndpointOptionsTLSSecurityPolicy: string = "";
          Action: string = "UpdateDomainEndpointOptions";
          DomainEndpointOptionsEnforceHTTPS: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## postUpdateDomainEndpointOptions
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainEndpointOptionsTLSSecurityPolicy: string
  ##                                         : The domain's endpoint options.
  ## The minimum required TLS version
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   DomainEndpointOptionsEnforceHTTPS: string
  ##                                    : The domain's endpoint options.
  ## Whether the domain is HTTPS only enabled.
  ##   Version: string (required)
  var query_612114 = newJObject()
  var formData_612115 = newJObject()
  add(formData_612115, "DomainEndpointOptions.TLSSecurityPolicy",
      newJString(DomainEndpointOptionsTLSSecurityPolicy))
  add(formData_612115, "DomainName", newJString(DomainName))
  add(query_612114, "Action", newJString(Action))
  add(formData_612115, "DomainEndpointOptions.EnforceHTTPS",
      newJString(DomainEndpointOptionsEnforceHTTPS))
  add(query_612114, "Version", newJString(Version))
  result = call_612113.call(nil, query_612114, nil, formData_612115, nil)

var postUpdateDomainEndpointOptions* = Call_PostUpdateDomainEndpointOptions_612097(
    name: "postUpdateDomainEndpointOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateDomainEndpointOptions",
    validator: validate_PostUpdateDomainEndpointOptions_612098, base: "/",
    url: url_PostUpdateDomainEndpointOptions_612099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateDomainEndpointOptions_612079 = ref object of OpenApiRestCall_610658
proc url_GetUpdateDomainEndpointOptions_612081(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateDomainEndpointOptions_612080(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainEndpointOptions.EnforceHTTPS: JString
  ##                                     : The domain's endpoint options.
  ## Whether the domain is HTTPS only enabled.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   DomainEndpointOptions.TLSSecurityPolicy: JString
  ##                                          : The domain's endpoint options.
  ## The minimum required TLS version
  ##   Version: JString (required)
  section = newJObject()
  var valid_612082 = query.getOrDefault("DomainEndpointOptions.EnforceHTTPS")
  valid_612082 = validateParameter(valid_612082, JString, required = false,
                                 default = nil)
  if valid_612082 != nil:
    section.add "DomainEndpointOptions.EnforceHTTPS", valid_612082
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_612083 = query.getOrDefault("DomainName")
  valid_612083 = validateParameter(valid_612083, JString, required = true,
                                 default = nil)
  if valid_612083 != nil:
    section.add "DomainName", valid_612083
  var valid_612084 = query.getOrDefault("Action")
  valid_612084 = validateParameter(valid_612084, JString, required = true, default = newJString(
      "UpdateDomainEndpointOptions"))
  if valid_612084 != nil:
    section.add "Action", valid_612084
  var valid_612085 = query.getOrDefault("DomainEndpointOptions.TLSSecurityPolicy")
  valid_612085 = validateParameter(valid_612085, JString, required = false,
                                 default = nil)
  if valid_612085 != nil:
    section.add "DomainEndpointOptions.TLSSecurityPolicy", valid_612085
  var valid_612086 = query.getOrDefault("Version")
  valid_612086 = validateParameter(valid_612086, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_612086 != nil:
    section.add "Version", valid_612086
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612087 = header.getOrDefault("X-Amz-Signature")
  valid_612087 = validateParameter(valid_612087, JString, required = false,
                                 default = nil)
  if valid_612087 != nil:
    section.add "X-Amz-Signature", valid_612087
  var valid_612088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612088 = validateParameter(valid_612088, JString, required = false,
                                 default = nil)
  if valid_612088 != nil:
    section.add "X-Amz-Content-Sha256", valid_612088
  var valid_612089 = header.getOrDefault("X-Amz-Date")
  valid_612089 = validateParameter(valid_612089, JString, required = false,
                                 default = nil)
  if valid_612089 != nil:
    section.add "X-Amz-Date", valid_612089
  var valid_612090 = header.getOrDefault("X-Amz-Credential")
  valid_612090 = validateParameter(valid_612090, JString, required = false,
                                 default = nil)
  if valid_612090 != nil:
    section.add "X-Amz-Credential", valid_612090
  var valid_612091 = header.getOrDefault("X-Amz-Security-Token")
  valid_612091 = validateParameter(valid_612091, JString, required = false,
                                 default = nil)
  if valid_612091 != nil:
    section.add "X-Amz-Security-Token", valid_612091
  var valid_612092 = header.getOrDefault("X-Amz-Algorithm")
  valid_612092 = validateParameter(valid_612092, JString, required = false,
                                 default = nil)
  if valid_612092 != nil:
    section.add "X-Amz-Algorithm", valid_612092
  var valid_612093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612093 = validateParameter(valid_612093, JString, required = false,
                                 default = nil)
  if valid_612093 != nil:
    section.add "X-Amz-SignedHeaders", valid_612093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612094: Call_GetUpdateDomainEndpointOptions_612079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_612094.validator(path, query, header, formData, body)
  let scheme = call_612094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612094.url(scheme.get, call_612094.host, call_612094.base,
                         call_612094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612094, url, valid)

proc call*(call_612095: Call_GetUpdateDomainEndpointOptions_612079;
          DomainName: string; DomainEndpointOptionsEnforceHTTPS: string = "";
          Action: string = "UpdateDomainEndpointOptions";
          DomainEndpointOptionsTLSSecurityPolicy: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## getUpdateDomainEndpointOptions
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainEndpointOptionsEnforceHTTPS: string
  ##                                    : The domain's endpoint options.
  ## Whether the domain is HTTPS only enabled.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   DomainEndpointOptionsTLSSecurityPolicy: string
  ##                                         : The domain's endpoint options.
  ## The minimum required TLS version
  ##   Version: string (required)
  var query_612096 = newJObject()
  add(query_612096, "DomainEndpointOptions.EnforceHTTPS",
      newJString(DomainEndpointOptionsEnforceHTTPS))
  add(query_612096, "DomainName", newJString(DomainName))
  add(query_612096, "Action", newJString(Action))
  add(query_612096, "DomainEndpointOptions.TLSSecurityPolicy",
      newJString(DomainEndpointOptionsTLSSecurityPolicy))
  add(query_612096, "Version", newJString(Version))
  result = call_612095.call(nil, query_612096, nil, nil, nil)

var getUpdateDomainEndpointOptions* = Call_GetUpdateDomainEndpointOptions_612079(
    name: "getUpdateDomainEndpointOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateDomainEndpointOptions",
    validator: validate_GetUpdateDomainEndpointOptions_612080, base: "/",
    url: url_GetUpdateDomainEndpointOptions_612081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateScalingParameters_612135 = ref object of OpenApiRestCall_610658
proc url_PostUpdateScalingParameters_612137(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateScalingParameters_612136(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612138 = query.getOrDefault("Action")
  valid_612138 = validateParameter(valid_612138, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_612138 != nil:
    section.add "Action", valid_612138
  var valid_612139 = query.getOrDefault("Version")
  valid_612139 = validateParameter(valid_612139, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_612139 != nil:
    section.add "Version", valid_612139
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612140 = header.getOrDefault("X-Amz-Signature")
  valid_612140 = validateParameter(valid_612140, JString, required = false,
                                 default = nil)
  if valid_612140 != nil:
    section.add "X-Amz-Signature", valid_612140
  var valid_612141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612141 = validateParameter(valid_612141, JString, required = false,
                                 default = nil)
  if valid_612141 != nil:
    section.add "X-Amz-Content-Sha256", valid_612141
  var valid_612142 = header.getOrDefault("X-Amz-Date")
  valid_612142 = validateParameter(valid_612142, JString, required = false,
                                 default = nil)
  if valid_612142 != nil:
    section.add "X-Amz-Date", valid_612142
  var valid_612143 = header.getOrDefault("X-Amz-Credential")
  valid_612143 = validateParameter(valid_612143, JString, required = false,
                                 default = nil)
  if valid_612143 != nil:
    section.add "X-Amz-Credential", valid_612143
  var valid_612144 = header.getOrDefault("X-Amz-Security-Token")
  valid_612144 = validateParameter(valid_612144, JString, required = false,
                                 default = nil)
  if valid_612144 != nil:
    section.add "X-Amz-Security-Token", valid_612144
  var valid_612145 = header.getOrDefault("X-Amz-Algorithm")
  valid_612145 = validateParameter(valid_612145, JString, required = false,
                                 default = nil)
  if valid_612145 != nil:
    section.add "X-Amz-Algorithm", valid_612145
  var valid_612146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612146 = validateParameter(valid_612146, JString, required = false,
                                 default = nil)
  if valid_612146 != nil:
    section.add "X-Amz-SignedHeaders", valid_612146
  result.add "header", section
  ## parameters in `formData` object:
  ##   ScalingParameters.DesiredReplicationCount: JString
  ##                                            : The desired instance type and desired number of replicas of each index partition.
  ## The number of replicas you want to preconfigure for each index partition.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ScalingParameters.DesiredPartitionCount: JString
  ##                                          : The desired instance type and desired number of replicas of each index partition.
  ## The number of partitions you want to preconfigure for your domain. Only valid when you select <code>m2.2xlarge</code> as the desired instance type.
  ##   ScalingParameters.DesiredInstanceType: JString
  ##                                        : The desired instance type and desired number of replicas of each index partition.
  ## The instance type that you want to preconfigure for your domain. For example, <code>search.m1.small</code>.
  section = newJObject()
  var valid_612147 = formData.getOrDefault("ScalingParameters.DesiredReplicationCount")
  valid_612147 = validateParameter(valid_612147, JString, required = false,
                                 default = nil)
  if valid_612147 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_612147
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_612148 = formData.getOrDefault("DomainName")
  valid_612148 = validateParameter(valid_612148, JString, required = true,
                                 default = nil)
  if valid_612148 != nil:
    section.add "DomainName", valid_612148
  var valid_612149 = formData.getOrDefault("ScalingParameters.DesiredPartitionCount")
  valid_612149 = validateParameter(valid_612149, JString, required = false,
                                 default = nil)
  if valid_612149 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_612149
  var valid_612150 = formData.getOrDefault("ScalingParameters.DesiredInstanceType")
  valid_612150 = validateParameter(valid_612150, JString, required = false,
                                 default = nil)
  if valid_612150 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_612150
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612151: Call_PostUpdateScalingParameters_612135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_612151.validator(path, query, header, formData, body)
  let scheme = call_612151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612151.url(scheme.get, call_612151.host, call_612151.base,
                         call_612151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612151, url, valid)

proc call*(call_612152: Call_PostUpdateScalingParameters_612135;
          DomainName: string;
          ScalingParametersDesiredReplicationCount: string = "";
          Action: string = "UpdateScalingParameters";
          ScalingParametersDesiredPartitionCount: string = "";
          ScalingParametersDesiredInstanceType: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## postUpdateScalingParameters
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   ScalingParametersDesiredReplicationCount: string
  ##                                           : The desired instance type and desired number of replicas of each index partition.
  ## The number of replicas you want to preconfigure for each index partition.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   ScalingParametersDesiredPartitionCount: string
  ##                                         : The desired instance type and desired number of replicas of each index partition.
  ## The number of partitions you want to preconfigure for your domain. Only valid when you select <code>m2.2xlarge</code> as the desired instance type.
  ##   ScalingParametersDesiredInstanceType: string
  ##                                       : The desired instance type and desired number of replicas of each index partition.
  ## The instance type that you want to preconfigure for your domain. For example, <code>search.m1.small</code>.
  ##   Version: string (required)
  var query_612153 = newJObject()
  var formData_612154 = newJObject()
  add(formData_612154, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  add(formData_612154, "DomainName", newJString(DomainName))
  add(query_612153, "Action", newJString(Action))
  add(formData_612154, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(formData_612154, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  add(query_612153, "Version", newJString(Version))
  result = call_612152.call(nil, query_612153, nil, formData_612154, nil)

var postUpdateScalingParameters* = Call_PostUpdateScalingParameters_612135(
    name: "postUpdateScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_PostUpdateScalingParameters_612136, base: "/",
    url: url_PostUpdateScalingParameters_612137,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateScalingParameters_612116 = ref object of OpenApiRestCall_610658
proc url_GetUpdateScalingParameters_612118(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateScalingParameters_612117(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ScalingParameters.DesiredPartitionCount: JString
  ##                                          : The desired instance type and desired number of replicas of each index partition.
  ## The number of partitions you want to preconfigure for your domain. Only valid when you select <code>m2.2xlarge</code> as the desired instance type.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ScalingParameters.DesiredInstanceType: JString
  ##                                        : The desired instance type and desired number of replicas of each index partition.
  ## The instance type that you want to preconfigure for your domain. For example, <code>search.m1.small</code>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   ScalingParameters.DesiredReplicationCount: JString
  ##                                            : The desired instance type and desired number of replicas of each index partition.
  ## The number of replicas you want to preconfigure for each index partition.
  section = newJObject()
  var valid_612119 = query.getOrDefault("ScalingParameters.DesiredPartitionCount")
  valid_612119 = validateParameter(valid_612119, JString, required = false,
                                 default = nil)
  if valid_612119 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_612119
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_612120 = query.getOrDefault("DomainName")
  valid_612120 = validateParameter(valid_612120, JString, required = true,
                                 default = nil)
  if valid_612120 != nil:
    section.add "DomainName", valid_612120
  var valid_612121 = query.getOrDefault("ScalingParameters.DesiredInstanceType")
  valid_612121 = validateParameter(valid_612121, JString, required = false,
                                 default = nil)
  if valid_612121 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_612121
  var valid_612122 = query.getOrDefault("Action")
  valid_612122 = validateParameter(valid_612122, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_612122 != nil:
    section.add "Action", valid_612122
  var valid_612123 = query.getOrDefault("Version")
  valid_612123 = validateParameter(valid_612123, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_612123 != nil:
    section.add "Version", valid_612123
  var valid_612124 = query.getOrDefault("ScalingParameters.DesiredReplicationCount")
  valid_612124 = validateParameter(valid_612124, JString, required = false,
                                 default = nil)
  if valid_612124 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_612124
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612125 = header.getOrDefault("X-Amz-Signature")
  valid_612125 = validateParameter(valid_612125, JString, required = false,
                                 default = nil)
  if valid_612125 != nil:
    section.add "X-Amz-Signature", valid_612125
  var valid_612126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612126 = validateParameter(valid_612126, JString, required = false,
                                 default = nil)
  if valid_612126 != nil:
    section.add "X-Amz-Content-Sha256", valid_612126
  var valid_612127 = header.getOrDefault("X-Amz-Date")
  valid_612127 = validateParameter(valid_612127, JString, required = false,
                                 default = nil)
  if valid_612127 != nil:
    section.add "X-Amz-Date", valid_612127
  var valid_612128 = header.getOrDefault("X-Amz-Credential")
  valid_612128 = validateParameter(valid_612128, JString, required = false,
                                 default = nil)
  if valid_612128 != nil:
    section.add "X-Amz-Credential", valid_612128
  var valid_612129 = header.getOrDefault("X-Amz-Security-Token")
  valid_612129 = validateParameter(valid_612129, JString, required = false,
                                 default = nil)
  if valid_612129 != nil:
    section.add "X-Amz-Security-Token", valid_612129
  var valid_612130 = header.getOrDefault("X-Amz-Algorithm")
  valid_612130 = validateParameter(valid_612130, JString, required = false,
                                 default = nil)
  if valid_612130 != nil:
    section.add "X-Amz-Algorithm", valid_612130
  var valid_612131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612131 = validateParameter(valid_612131, JString, required = false,
                                 default = nil)
  if valid_612131 != nil:
    section.add "X-Amz-SignedHeaders", valid_612131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612132: Call_GetUpdateScalingParameters_612116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_612132.validator(path, query, header, formData, body)
  let scheme = call_612132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612132.url(scheme.get, call_612132.host, call_612132.base,
                         call_612132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612132, url, valid)

proc call*(call_612133: Call_GetUpdateScalingParameters_612116; DomainName: string;
          ScalingParametersDesiredPartitionCount: string = "";
          ScalingParametersDesiredInstanceType: string = "";
          Action: string = "UpdateScalingParameters";
          Version: string = "2013-01-01";
          ScalingParametersDesiredReplicationCount: string = ""): Recallable =
  ## getUpdateScalingParameters
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   ScalingParametersDesiredPartitionCount: string
  ##                                         : The desired instance type and desired number of replicas of each index partition.
  ## The number of partitions you want to preconfigure for your domain. Only valid when you select <code>m2.2xlarge</code> as the desired instance type.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ScalingParametersDesiredInstanceType: string
  ##                                       : The desired instance type and desired number of replicas of each index partition.
  ## The instance type that you want to preconfigure for your domain. For example, <code>search.m1.small</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ScalingParametersDesiredReplicationCount: string
  ##                                           : The desired instance type and desired number of replicas of each index partition.
  ## The number of replicas you want to preconfigure for each index partition.
  var query_612134 = newJObject()
  add(query_612134, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(query_612134, "DomainName", newJString(DomainName))
  add(query_612134, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  add(query_612134, "Action", newJString(Action))
  add(query_612134, "Version", newJString(Version))
  add(query_612134, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  result = call_612133.call(nil, query_612134, nil, nil, nil)

var getUpdateScalingParameters* = Call_GetUpdateScalingParameters_612116(
    name: "getUpdateScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_GetUpdateScalingParameters_612117, base: "/",
    url: url_GetUpdateScalingParameters_612118,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_612172 = ref object of OpenApiRestCall_610658
proc url_PostUpdateServiceAccessPolicies_612174(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateServiceAccessPolicies_612173(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612175 = query.getOrDefault("Action")
  valid_612175 = validateParameter(valid_612175, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_612175 != nil:
    section.add "Action", valid_612175
  var valid_612176 = query.getOrDefault("Version")
  valid_612176 = validateParameter(valid_612176, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_612176 != nil:
    section.add "Version", valid_612176
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612177 = header.getOrDefault("X-Amz-Signature")
  valid_612177 = validateParameter(valid_612177, JString, required = false,
                                 default = nil)
  if valid_612177 != nil:
    section.add "X-Amz-Signature", valid_612177
  var valid_612178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612178 = validateParameter(valid_612178, JString, required = false,
                                 default = nil)
  if valid_612178 != nil:
    section.add "X-Amz-Content-Sha256", valid_612178
  var valid_612179 = header.getOrDefault("X-Amz-Date")
  valid_612179 = validateParameter(valid_612179, JString, required = false,
                                 default = nil)
  if valid_612179 != nil:
    section.add "X-Amz-Date", valid_612179
  var valid_612180 = header.getOrDefault("X-Amz-Credential")
  valid_612180 = validateParameter(valid_612180, JString, required = false,
                                 default = nil)
  if valid_612180 != nil:
    section.add "X-Amz-Credential", valid_612180
  var valid_612181 = header.getOrDefault("X-Amz-Security-Token")
  valid_612181 = validateParameter(valid_612181, JString, required = false,
                                 default = nil)
  if valid_612181 != nil:
    section.add "X-Amz-Security-Token", valid_612181
  var valid_612182 = header.getOrDefault("X-Amz-Algorithm")
  valid_612182 = validateParameter(valid_612182, JString, required = false,
                                 default = nil)
  if valid_612182 != nil:
    section.add "X-Amz-Algorithm", valid_612182
  var valid_612183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612183 = validateParameter(valid_612183, JString, required = false,
                                 default = nil)
  if valid_612183 != nil:
    section.add "X-Amz-SignedHeaders", valid_612183
  result.add "header", section
  ## parameters in `formData` object:
  ##   AccessPolicies: JString (required)
  ##                 : Access rules for a domain's document or search service endpoints. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. The maximum size of a policy document is 100 KB.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AccessPolicies` field"
  var valid_612184 = formData.getOrDefault("AccessPolicies")
  valid_612184 = validateParameter(valid_612184, JString, required = true,
                                 default = nil)
  if valid_612184 != nil:
    section.add "AccessPolicies", valid_612184
  var valid_612185 = formData.getOrDefault("DomainName")
  valid_612185 = validateParameter(valid_612185, JString, required = true,
                                 default = nil)
  if valid_612185 != nil:
    section.add "DomainName", valid_612185
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612186: Call_PostUpdateServiceAccessPolicies_612172;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_612186.validator(path, query, header, formData, body)
  let scheme = call_612186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612186.url(scheme.get, call_612186.host, call_612186.base,
                         call_612186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612186, url, valid)

proc call*(call_612187: Call_PostUpdateServiceAccessPolicies_612172;
          AccessPolicies: string; DomainName: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2013-01-01"): Recallable =
  ## postUpdateServiceAccessPolicies
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ##   AccessPolicies: string (required)
  ##                 : Access rules for a domain's document or search service endpoints. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. The maximum size of a policy document is 100 KB.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612188 = newJObject()
  var formData_612189 = newJObject()
  add(formData_612189, "AccessPolicies", newJString(AccessPolicies))
  add(formData_612189, "DomainName", newJString(DomainName))
  add(query_612188, "Action", newJString(Action))
  add(query_612188, "Version", newJString(Version))
  result = call_612187.call(nil, query_612188, nil, formData_612189, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_612172(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_612173, base: "/",
    url: url_PostUpdateServiceAccessPolicies_612174,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_612155 = ref object of OpenApiRestCall_610658
proc url_GetUpdateServiceAccessPolicies_612157(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateServiceAccessPolicies_612156(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   AccessPolicies: JString (required)
  ##                 : Access rules for a domain's document or search service endpoints. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. The maximum size of a policy document is 100 KB.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_612158 = query.getOrDefault("DomainName")
  valid_612158 = validateParameter(valid_612158, JString, required = true,
                                 default = nil)
  if valid_612158 != nil:
    section.add "DomainName", valid_612158
  var valid_612159 = query.getOrDefault("Action")
  valid_612159 = validateParameter(valid_612159, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_612159 != nil:
    section.add "Action", valid_612159
  var valid_612160 = query.getOrDefault("Version")
  valid_612160 = validateParameter(valid_612160, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_612160 != nil:
    section.add "Version", valid_612160
  var valid_612161 = query.getOrDefault("AccessPolicies")
  valid_612161 = validateParameter(valid_612161, JString, required = true,
                                 default = nil)
  if valid_612161 != nil:
    section.add "AccessPolicies", valid_612161
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612162 = header.getOrDefault("X-Amz-Signature")
  valid_612162 = validateParameter(valid_612162, JString, required = false,
                                 default = nil)
  if valid_612162 != nil:
    section.add "X-Amz-Signature", valid_612162
  var valid_612163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612163 = validateParameter(valid_612163, JString, required = false,
                                 default = nil)
  if valid_612163 != nil:
    section.add "X-Amz-Content-Sha256", valid_612163
  var valid_612164 = header.getOrDefault("X-Amz-Date")
  valid_612164 = validateParameter(valid_612164, JString, required = false,
                                 default = nil)
  if valid_612164 != nil:
    section.add "X-Amz-Date", valid_612164
  var valid_612165 = header.getOrDefault("X-Amz-Credential")
  valid_612165 = validateParameter(valid_612165, JString, required = false,
                                 default = nil)
  if valid_612165 != nil:
    section.add "X-Amz-Credential", valid_612165
  var valid_612166 = header.getOrDefault("X-Amz-Security-Token")
  valid_612166 = validateParameter(valid_612166, JString, required = false,
                                 default = nil)
  if valid_612166 != nil:
    section.add "X-Amz-Security-Token", valid_612166
  var valid_612167 = header.getOrDefault("X-Amz-Algorithm")
  valid_612167 = validateParameter(valid_612167, JString, required = false,
                                 default = nil)
  if valid_612167 != nil:
    section.add "X-Amz-Algorithm", valid_612167
  var valid_612168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612168 = validateParameter(valid_612168, JString, required = false,
                                 default = nil)
  if valid_612168 != nil:
    section.add "X-Amz-SignedHeaders", valid_612168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612169: Call_GetUpdateServiceAccessPolicies_612155; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_612169.validator(path, query, header, formData, body)
  let scheme = call_612169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612169.url(scheme.get, call_612169.host, call_612169.base,
                         call_612169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612169, url, valid)

proc call*(call_612170: Call_GetUpdateServiceAccessPolicies_612155;
          DomainName: string; AccessPolicies: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2013-01-01"): Recallable =
  ## getUpdateServiceAccessPolicies
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AccessPolicies: string (required)
  ##                 : Access rules for a domain's document or search service endpoints. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. The maximum size of a policy document is 100 KB.
  var query_612171 = newJObject()
  add(query_612171, "DomainName", newJString(DomainName))
  add(query_612171, "Action", newJString(Action))
  add(query_612171, "Version", newJString(Version))
  add(query_612171, "AccessPolicies", newJString(AccessPolicies))
  result = call_612170.call(nil, query_612171, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_612155(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_612156, base: "/",
    url: url_GetUpdateServiceAccessPolicies_612157,
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
