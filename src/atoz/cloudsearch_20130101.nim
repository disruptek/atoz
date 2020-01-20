
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  Call_PostBuildSuggesters_606198 = ref object of OpenApiRestCall_605589
proc url_PostBuildSuggesters_606200(protocol: Scheme; host: string; base: string;
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

proc validate_PostBuildSuggesters_606199(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606201 = query.getOrDefault("Action")
  valid_606201 = validateParameter(valid_606201, JString, required = true,
                                 default = newJString("BuildSuggesters"))
  if valid_606201 != nil:
    section.add "Action", valid_606201
  var valid_606202 = query.getOrDefault("Version")
  valid_606202 = validateParameter(valid_606202, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606202 != nil:
    section.add "Version", valid_606202
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
  var valid_606203 = header.getOrDefault("X-Amz-Signature")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Signature", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Content-Sha256", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Date")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Date", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Credential")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Credential", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Security-Token")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Security-Token", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Algorithm")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Algorithm", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-SignedHeaders", valid_606209
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606210 = formData.getOrDefault("DomainName")
  valid_606210 = validateParameter(valid_606210, JString, required = true,
                                 default = nil)
  if valid_606210 != nil:
    section.add "DomainName", valid_606210
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606211: Call_PostBuildSuggesters_606198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606211.validator(path, query, header, formData, body)
  let scheme = call_606211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606211.url(scheme.get, call_606211.host, call_606211.base,
                         call_606211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606211, url, valid)

proc call*(call_606212: Call_PostBuildSuggesters_606198; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## postBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606213 = newJObject()
  var formData_606214 = newJObject()
  add(formData_606214, "DomainName", newJString(DomainName))
  add(query_606213, "Action", newJString(Action))
  add(query_606213, "Version", newJString(Version))
  result = call_606212.call(nil, query_606213, nil, formData_606214, nil)

var postBuildSuggesters* = Call_PostBuildSuggesters_606198(
    name: "postBuildSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_PostBuildSuggesters_606199, base: "/",
    url: url_PostBuildSuggesters_606200, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuildSuggesters_605927 = ref object of OpenApiRestCall_605589
proc url_GetBuildSuggesters_605929(protocol: Scheme; host: string; base: string;
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

proc validate_GetBuildSuggesters_605928(path: JsonNode; query: JsonNode;
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
  var valid_606041 = query.getOrDefault("DomainName")
  valid_606041 = validateParameter(valid_606041, JString, required = true,
                                 default = nil)
  if valid_606041 != nil:
    section.add "DomainName", valid_606041
  var valid_606055 = query.getOrDefault("Action")
  valid_606055 = validateParameter(valid_606055, JString, required = true,
                                 default = newJString("BuildSuggesters"))
  if valid_606055 != nil:
    section.add "Action", valid_606055
  var valid_606056 = query.getOrDefault("Version")
  valid_606056 = validateParameter(valid_606056, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606056 != nil:
    section.add "Version", valid_606056
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
  var valid_606057 = header.getOrDefault("X-Amz-Signature")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Signature", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Content-Sha256", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Date")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Date", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Credential")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Credential", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Security-Token")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Security-Token", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-Algorithm")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-Algorithm", valid_606062
  var valid_606063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606063 = validateParameter(valid_606063, JString, required = false,
                                 default = nil)
  if valid_606063 != nil:
    section.add "X-Amz-SignedHeaders", valid_606063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606086: Call_GetBuildSuggesters_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606086.validator(path, query, header, formData, body)
  let scheme = call_606086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606086.url(scheme.get, call_606086.host, call_606086.base,
                         call_606086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606086, url, valid)

proc call*(call_606157: Call_GetBuildSuggesters_605927; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## getBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606158 = newJObject()
  add(query_606158, "DomainName", newJString(DomainName))
  add(query_606158, "Action", newJString(Action))
  add(query_606158, "Version", newJString(Version))
  result = call_606157.call(nil, query_606158, nil, nil, nil)

var getBuildSuggesters* = Call_GetBuildSuggesters_605927(
    name: "getBuildSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_GetBuildSuggesters_605928, base: "/",
    url: url_GetBuildSuggesters_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_606231 = ref object of OpenApiRestCall_605589
proc url_PostCreateDomain_606233(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDomain_606232(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606234 = query.getOrDefault("Action")
  valid_606234 = validateParameter(valid_606234, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_606234 != nil:
    section.add "Action", valid_606234
  var valid_606235 = query.getOrDefault("Version")
  valid_606235 = validateParameter(valid_606235, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606235 != nil:
    section.add "Version", valid_606235
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
  var valid_606236 = header.getOrDefault("X-Amz-Signature")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Signature", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Content-Sha256", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-Date")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Date", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Credential")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Credential", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Security-Token")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Security-Token", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Algorithm")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Algorithm", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-SignedHeaders", valid_606242
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606243 = formData.getOrDefault("DomainName")
  valid_606243 = validateParameter(valid_606243, JString, required = true,
                                 default = nil)
  if valid_606243 != nil:
    section.add "DomainName", valid_606243
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606244: Call_PostCreateDomain_606231; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606244.validator(path, query, header, formData, body)
  let scheme = call_606244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606244.url(scheme.get, call_606244.host, call_606244.base,
                         call_606244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606244, url, valid)

proc call*(call_606245: Call_PostCreateDomain_606231; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606246 = newJObject()
  var formData_606247 = newJObject()
  add(formData_606247, "DomainName", newJString(DomainName))
  add(query_606246, "Action", newJString(Action))
  add(query_606246, "Version", newJString(Version))
  result = call_606245.call(nil, query_606246, nil, formData_606247, nil)

var postCreateDomain* = Call_PostCreateDomain_606231(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_606232,
    base: "/", url: url_PostCreateDomain_606233,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_606215 = ref object of OpenApiRestCall_605589
proc url_GetCreateDomain_606217(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDomain_606216(path: JsonNode; query: JsonNode;
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
  var valid_606218 = query.getOrDefault("DomainName")
  valid_606218 = validateParameter(valid_606218, JString, required = true,
                                 default = nil)
  if valid_606218 != nil:
    section.add "DomainName", valid_606218
  var valid_606219 = query.getOrDefault("Action")
  valid_606219 = validateParameter(valid_606219, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_606219 != nil:
    section.add "Action", valid_606219
  var valid_606220 = query.getOrDefault("Version")
  valid_606220 = validateParameter(valid_606220, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606220 != nil:
    section.add "Version", valid_606220
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
  var valid_606221 = header.getOrDefault("X-Amz-Signature")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Signature", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Content-Sha256", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Date")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Date", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Credential")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Credential", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Security-Token")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Security-Token", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Algorithm")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Algorithm", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-SignedHeaders", valid_606227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606228: Call_GetCreateDomain_606215; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606228.validator(path, query, header, formData, body)
  let scheme = call_606228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606228.url(scheme.get, call_606228.host, call_606228.base,
                         call_606228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606228, url, valid)

proc call*(call_606229: Call_GetCreateDomain_606215; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606230 = newJObject()
  add(query_606230, "DomainName", newJString(DomainName))
  add(query_606230, "Action", newJString(Action))
  add(query_606230, "Version", newJString(Version))
  result = call_606229.call(nil, query_606230, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_606215(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_606216,
    base: "/", url: url_GetCreateDomain_606217, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineAnalysisScheme_606267 = ref object of OpenApiRestCall_605589
proc url_PostDefineAnalysisScheme_606269(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
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

proc validate_PostDefineAnalysisScheme_606268(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606270 = query.getOrDefault("Action")
  valid_606270 = validateParameter(valid_606270, JString, required = true,
                                 default = newJString("DefineAnalysisScheme"))
  if valid_606270 != nil:
    section.add "Action", valid_606270
  var valid_606271 = query.getOrDefault("Version")
  valid_606271 = validateParameter(valid_606271, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606271 != nil:
    section.add "Version", valid_606271
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
  var valid_606272 = header.getOrDefault("X-Amz-Signature")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Signature", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Content-Sha256", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-Date")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-Date", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Credential")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Credential", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Security-Token")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Security-Token", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Algorithm")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Algorithm", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-SignedHeaders", valid_606278
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
  var valid_606279 = formData.getOrDefault("AnalysisScheme.AnalysisSchemeLanguage")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_606279
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606280 = formData.getOrDefault("DomainName")
  valid_606280 = validateParameter(valid_606280, JString, required = true,
                                 default = nil)
  if valid_606280 != nil:
    section.add "DomainName", valid_606280
  var valid_606281 = formData.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_606281
  var valid_606282 = formData.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_606282
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606283: Call_PostDefineAnalysisScheme_606267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_PostDefineAnalysisScheme_606267; DomainName: string;
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
  var query_606285 = newJObject()
  var formData_606286 = newJObject()
  add(formData_606286, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(formData_606286, "DomainName", newJString(DomainName))
  add(formData_606286, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_606285, "Action", newJString(Action))
  add(formData_606286, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  add(query_606285, "Version", newJString(Version))
  result = call_606284.call(nil, query_606285, nil, formData_606286, nil)

var postDefineAnalysisScheme* = Call_PostDefineAnalysisScheme_606267(
    name: "postDefineAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_PostDefineAnalysisScheme_606268, base: "/",
    url: url_PostDefineAnalysisScheme_606269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineAnalysisScheme_606248 = ref object of OpenApiRestCall_605589
proc url_GetDefineAnalysisScheme_606250(protocol: Scheme; host: string; base: string;
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

proc validate_GetDefineAnalysisScheme_606249(path: JsonNode; query: JsonNode;
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
  var valid_606251 = query.getOrDefault("DomainName")
  valid_606251 = validateParameter(valid_606251, JString, required = true,
                                 default = nil)
  if valid_606251 != nil:
    section.add "DomainName", valid_606251
  var valid_606252 = query.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_606252
  var valid_606253 = query.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_606253
  var valid_606254 = query.getOrDefault("Action")
  valid_606254 = validateParameter(valid_606254, JString, required = true,
                                 default = newJString("DefineAnalysisScheme"))
  if valid_606254 != nil:
    section.add "Action", valid_606254
  var valid_606255 = query.getOrDefault("AnalysisScheme.AnalysisSchemeLanguage")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_606255
  var valid_606256 = query.getOrDefault("Version")
  valid_606256 = validateParameter(valid_606256, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606256 != nil:
    section.add "Version", valid_606256
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
  var valid_606257 = header.getOrDefault("X-Amz-Signature")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Signature", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-Content-Sha256", valid_606258
  var valid_606259 = header.getOrDefault("X-Amz-Date")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "X-Amz-Date", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Credential")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Credential", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Security-Token")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Security-Token", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Algorithm")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Algorithm", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-SignedHeaders", valid_606263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606264: Call_GetDefineAnalysisScheme_606248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606264.validator(path, query, header, formData, body)
  let scheme = call_606264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606264.url(scheme.get, call_606264.host, call_606264.base,
                         call_606264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606264, url, valid)

proc call*(call_606265: Call_GetDefineAnalysisScheme_606248; DomainName: string;
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
  var query_606266 = newJObject()
  add(query_606266, "DomainName", newJString(DomainName))
  add(query_606266, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_606266, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  add(query_606266, "Action", newJString(Action))
  add(query_606266, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(query_606266, "Version", newJString(Version))
  result = call_606265.call(nil, query_606266, nil, nil, nil)

var getDefineAnalysisScheme* = Call_GetDefineAnalysisScheme_606248(
    name: "getDefineAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_GetDefineAnalysisScheme_606249, base: "/",
    url: url_GetDefineAnalysisScheme_606250, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineExpression_606305 = ref object of OpenApiRestCall_605589
proc url_PostDefineExpression_606307(protocol: Scheme; host: string; base: string;
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

proc validate_PostDefineExpression_606306(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606308 = query.getOrDefault("Action")
  valid_606308 = validateParameter(valid_606308, JString, required = true,
                                 default = newJString("DefineExpression"))
  if valid_606308 != nil:
    section.add "Action", valid_606308
  var valid_606309 = query.getOrDefault("Version")
  valid_606309 = validateParameter(valid_606309, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606309 != nil:
    section.add "Version", valid_606309
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
  var valid_606310 = header.getOrDefault("X-Amz-Signature")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Signature", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Content-Sha256", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-Date")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Date", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-Credential")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Credential", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-Security-Token")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Security-Token", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-Algorithm")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-Algorithm", valid_606315
  var valid_606316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-SignedHeaders", valid_606316
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
  var valid_606317 = formData.getOrDefault("Expression.ExpressionName")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "Expression.ExpressionName", valid_606317
  var valid_606318 = formData.getOrDefault("Expression.ExpressionValue")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "Expression.ExpressionValue", valid_606318
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606319 = formData.getOrDefault("DomainName")
  valid_606319 = validateParameter(valid_606319, JString, required = true,
                                 default = nil)
  if valid_606319 != nil:
    section.add "DomainName", valid_606319
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606320: Call_PostDefineExpression_606305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606320.validator(path, query, header, formData, body)
  let scheme = call_606320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606320.url(scheme.get, call_606320.host, call_606320.base,
                         call_606320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606320, url, valid)

proc call*(call_606321: Call_PostDefineExpression_606305; DomainName: string;
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
  var query_606322 = newJObject()
  var formData_606323 = newJObject()
  add(formData_606323, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(formData_606323, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(formData_606323, "DomainName", newJString(DomainName))
  add(query_606322, "Action", newJString(Action))
  add(query_606322, "Version", newJString(Version))
  result = call_606321.call(nil, query_606322, nil, formData_606323, nil)

var postDefineExpression* = Call_PostDefineExpression_606305(
    name: "postDefineExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_PostDefineExpression_606306, base: "/",
    url: url_PostDefineExpression_606307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineExpression_606287 = ref object of OpenApiRestCall_605589
proc url_GetDefineExpression_606289(protocol: Scheme; host: string; base: string;
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

proc validate_GetDefineExpression_606288(path: JsonNode; query: JsonNode;
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
  var valid_606290 = query.getOrDefault("DomainName")
  valid_606290 = validateParameter(valid_606290, JString, required = true,
                                 default = nil)
  if valid_606290 != nil:
    section.add "DomainName", valid_606290
  var valid_606291 = query.getOrDefault("Expression.ExpressionValue")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "Expression.ExpressionValue", valid_606291
  var valid_606292 = query.getOrDefault("Action")
  valid_606292 = validateParameter(valid_606292, JString, required = true,
                                 default = newJString("DefineExpression"))
  if valid_606292 != nil:
    section.add "Action", valid_606292
  var valid_606293 = query.getOrDefault("Expression.ExpressionName")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "Expression.ExpressionName", valid_606293
  var valid_606294 = query.getOrDefault("Version")
  valid_606294 = validateParameter(valid_606294, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606294 != nil:
    section.add "Version", valid_606294
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
  var valid_606295 = header.getOrDefault("X-Amz-Signature")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Signature", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-Content-Sha256", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-Date")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-Date", valid_606297
  var valid_606298 = header.getOrDefault("X-Amz-Credential")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Credential", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-Security-Token")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Security-Token", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Algorithm")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Algorithm", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-SignedHeaders", valid_606301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606302: Call_GetDefineExpression_606287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606302.validator(path, query, header, formData, body)
  let scheme = call_606302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606302.url(scheme.get, call_606302.host, call_606302.base,
                         call_606302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606302, url, valid)

proc call*(call_606303: Call_GetDefineExpression_606287; DomainName: string;
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
  var query_606304 = newJObject()
  add(query_606304, "DomainName", newJString(DomainName))
  add(query_606304, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(query_606304, "Action", newJString(Action))
  add(query_606304, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(query_606304, "Version", newJString(Version))
  result = call_606303.call(nil, query_606304, nil, nil, nil)

var getDefineExpression* = Call_GetDefineExpression_606287(
    name: "getDefineExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_GetDefineExpression_606288, base: "/",
    url: url_GetDefineExpression_606289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_606353 = ref object of OpenApiRestCall_605589
proc url_PostDefineIndexField_606355(protocol: Scheme; host: string; base: string;
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

proc validate_PostDefineIndexField_606354(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606356 = query.getOrDefault("Action")
  valid_606356 = validateParameter(valid_606356, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_606356 != nil:
    section.add "Action", valid_606356
  var valid_606357 = query.getOrDefault("Version")
  valid_606357 = validateParameter(valid_606357, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606357 != nil:
    section.add "Version", valid_606357
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
  var valid_606358 = header.getOrDefault("X-Amz-Signature")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-Signature", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-Content-Sha256", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-Date")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Date", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-Credential")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-Credential", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-Security-Token")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Security-Token", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-Algorithm")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Algorithm", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-SignedHeaders", valid_606364
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
  var valid_606365 = formData.getOrDefault("IndexField.IntOptions")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "IndexField.IntOptions", valid_606365
  var valid_606366 = formData.getOrDefault("IndexField.TextArrayOptions")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "IndexField.TextArrayOptions", valid_606366
  var valid_606367 = formData.getOrDefault("IndexField.DoubleOptions")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "IndexField.DoubleOptions", valid_606367
  var valid_606368 = formData.getOrDefault("IndexField.LatLonOptions")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "IndexField.LatLonOptions", valid_606368
  var valid_606369 = formData.getOrDefault("IndexField.LiteralArrayOptions")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_606369
  var valid_606370 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "IndexField.IndexFieldType", valid_606370
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606371 = formData.getOrDefault("DomainName")
  valid_606371 = validateParameter(valid_606371, JString, required = true,
                                 default = nil)
  if valid_606371 != nil:
    section.add "DomainName", valid_606371
  var valid_606372 = formData.getOrDefault("IndexField.TextOptions")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "IndexField.TextOptions", valid_606372
  var valid_606373 = formData.getOrDefault("IndexField.IntArrayOptions")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "IndexField.IntArrayOptions", valid_606373
  var valid_606374 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "IndexField.LiteralOptions", valid_606374
  var valid_606375 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "IndexField.IndexFieldName", valid_606375
  var valid_606376 = formData.getOrDefault("IndexField.DateOptions")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "IndexField.DateOptions", valid_606376
  var valid_606377 = formData.getOrDefault("IndexField.DateArrayOptions")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "IndexField.DateArrayOptions", valid_606377
  var valid_606378 = formData.getOrDefault("IndexField.DoubleArrayOptions")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_606378
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606379: Call_PostDefineIndexField_606353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_606379.validator(path, query, header, formData, body)
  let scheme = call_606379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606379.url(scheme.get, call_606379.host, call_606379.base,
                         call_606379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606379, url, valid)

proc call*(call_606380: Call_PostDefineIndexField_606353; DomainName: string;
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
  var query_606381 = newJObject()
  var formData_606382 = newJObject()
  add(formData_606382, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(formData_606382, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(formData_606382, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(formData_606382, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  add(formData_606382, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(formData_606382, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(formData_606382, "DomainName", newJString(DomainName))
  add(formData_606382, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(formData_606382, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  add(formData_606382, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_606381, "Action", newJString(Action))
  add(formData_606382, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(formData_606382, "IndexField.DateOptions", newJString(IndexFieldDateOptions))
  add(formData_606382, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(query_606381, "Version", newJString(Version))
  add(formData_606382, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  result = call_606380.call(nil, query_606381, nil, formData_606382, nil)

var postDefineIndexField* = Call_PostDefineIndexField_606353(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_606354, base: "/",
    url: url_PostDefineIndexField_606355, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_606324 = ref object of OpenApiRestCall_605589
proc url_GetDefineIndexField_606326(protocol: Scheme; host: string; base: string;
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

proc validate_GetDefineIndexField_606325(path: JsonNode; query: JsonNode;
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
  var valid_606327 = query.getOrDefault("IndexField.TextOptions")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "IndexField.TextOptions", valid_606327
  var valid_606328 = query.getOrDefault("IndexField.LiteralArrayOptions")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_606328
  var valid_606329 = query.getOrDefault("IndexField.DoubleArrayOptions")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_606329
  var valid_606330 = query.getOrDefault("IndexField.IntArrayOptions")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "IndexField.IntArrayOptions", valid_606330
  var valid_606331 = query.getOrDefault("IndexField.IndexFieldType")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "IndexField.IndexFieldType", valid_606331
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_606332 = query.getOrDefault("DomainName")
  valid_606332 = validateParameter(valid_606332, JString, required = true,
                                 default = nil)
  if valid_606332 != nil:
    section.add "DomainName", valid_606332
  var valid_606333 = query.getOrDefault("IndexField.IndexFieldName")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "IndexField.IndexFieldName", valid_606333
  var valid_606334 = query.getOrDefault("IndexField.DoubleOptions")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "IndexField.DoubleOptions", valid_606334
  var valid_606335 = query.getOrDefault("IndexField.TextArrayOptions")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "IndexField.TextArrayOptions", valid_606335
  var valid_606336 = query.getOrDefault("Action")
  valid_606336 = validateParameter(valid_606336, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_606336 != nil:
    section.add "Action", valid_606336
  var valid_606337 = query.getOrDefault("IndexField.DateOptions")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "IndexField.DateOptions", valid_606337
  var valid_606338 = query.getOrDefault("IndexField.LiteralOptions")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "IndexField.LiteralOptions", valid_606338
  var valid_606339 = query.getOrDefault("IndexField.IntOptions")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "IndexField.IntOptions", valid_606339
  var valid_606340 = query.getOrDefault("Version")
  valid_606340 = validateParameter(valid_606340, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606340 != nil:
    section.add "Version", valid_606340
  var valid_606341 = query.getOrDefault("IndexField.DateArrayOptions")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "IndexField.DateArrayOptions", valid_606341
  var valid_606342 = query.getOrDefault("IndexField.LatLonOptions")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "IndexField.LatLonOptions", valid_606342
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
  var valid_606343 = header.getOrDefault("X-Amz-Signature")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Signature", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Content-Sha256", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-Date")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Date", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Credential")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Credential", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-Security-Token")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Security-Token", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-Algorithm")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-Algorithm", valid_606348
  var valid_606349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-SignedHeaders", valid_606349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606350: Call_GetDefineIndexField_606324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_606350.validator(path, query, header, formData, body)
  let scheme = call_606350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606350.url(scheme.get, call_606350.host, call_606350.base,
                         call_606350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606350, url, valid)

proc call*(call_606351: Call_GetDefineIndexField_606324; DomainName: string;
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
  var query_606352 = newJObject()
  add(query_606352, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_606352, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(query_606352, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  add(query_606352, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  add(query_606352, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_606352, "DomainName", newJString(DomainName))
  add(query_606352, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_606352, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(query_606352, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(query_606352, "Action", newJString(Action))
  add(query_606352, "IndexField.DateOptions", newJString(IndexFieldDateOptions))
  add(query_606352, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_606352, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(query_606352, "Version", newJString(Version))
  add(query_606352, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(query_606352, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  result = call_606351.call(nil, query_606352, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_606324(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_606325, base: "/",
    url: url_GetDefineIndexField_606326, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineSuggester_606401 = ref object of OpenApiRestCall_605589
proc url_PostDefineSuggester_606403(protocol: Scheme; host: string; base: string;
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

proc validate_PostDefineSuggester_606402(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606404 = query.getOrDefault("Action")
  valid_606404 = validateParameter(valid_606404, JString, required = true,
                                 default = newJString("DefineSuggester"))
  if valid_606404 != nil:
    section.add "Action", valid_606404
  var valid_606405 = query.getOrDefault("Version")
  valid_606405 = validateParameter(valid_606405, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606405 != nil:
    section.add "Version", valid_606405
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
  var valid_606406 = header.getOrDefault("X-Amz-Signature")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-Signature", valid_606406
  var valid_606407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Content-Sha256", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-Date")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-Date", valid_606408
  var valid_606409 = header.getOrDefault("X-Amz-Credential")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-Credential", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Security-Token")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Security-Token", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Algorithm")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Algorithm", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-SignedHeaders", valid_606412
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
  var valid_606413 = formData.getOrDefault("DomainName")
  valid_606413 = validateParameter(valid_606413, JString, required = true,
                                 default = nil)
  if valid_606413 != nil:
    section.add "DomainName", valid_606413
  var valid_606414 = formData.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_606414
  var valid_606415 = formData.getOrDefault("Suggester.SuggesterName")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "Suggester.SuggesterName", valid_606415
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606416: Call_PostDefineSuggester_606401; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606416.validator(path, query, header, formData, body)
  let scheme = call_606416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606416.url(scheme.get, call_606416.host, call_606416.base,
                         call_606416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606416, url, valid)

proc call*(call_606417: Call_PostDefineSuggester_606401; DomainName: string;
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
  var query_606418 = newJObject()
  var formData_606419 = newJObject()
  add(formData_606419, "DomainName", newJString(DomainName))
  add(formData_606419, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(query_606418, "Action", newJString(Action))
  add(formData_606419, "Suggester.SuggesterName",
      newJString(SuggesterSuggesterName))
  add(query_606418, "Version", newJString(Version))
  result = call_606417.call(nil, query_606418, nil, formData_606419, nil)

var postDefineSuggester* = Call_PostDefineSuggester_606401(
    name: "postDefineSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_PostDefineSuggester_606402, base: "/",
    url: url_PostDefineSuggester_606403, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineSuggester_606383 = ref object of OpenApiRestCall_605589
proc url_GetDefineSuggester_606385(protocol: Scheme; host: string; base: string;
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

proc validate_GetDefineSuggester_606384(path: JsonNode; query: JsonNode;
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
  var valid_606386 = query.getOrDefault("DomainName")
  valid_606386 = validateParameter(valid_606386, JString, required = true,
                                 default = nil)
  if valid_606386 != nil:
    section.add "DomainName", valid_606386
  var valid_606387 = query.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_606387
  var valid_606388 = query.getOrDefault("Action")
  valid_606388 = validateParameter(valid_606388, JString, required = true,
                                 default = newJString("DefineSuggester"))
  if valid_606388 != nil:
    section.add "Action", valid_606388
  var valid_606389 = query.getOrDefault("Suggester.SuggesterName")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "Suggester.SuggesterName", valid_606389
  var valid_606390 = query.getOrDefault("Version")
  valid_606390 = validateParameter(valid_606390, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606390 != nil:
    section.add "Version", valid_606390
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
  var valid_606391 = header.getOrDefault("X-Amz-Signature")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-Signature", valid_606391
  var valid_606392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-Content-Sha256", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-Date")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Date", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-Credential")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-Credential", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Security-Token")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Security-Token", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Algorithm")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Algorithm", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-SignedHeaders", valid_606397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606398: Call_GetDefineSuggester_606383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606398.validator(path, query, header, formData, body)
  let scheme = call_606398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606398.url(scheme.get, call_606398.host, call_606398.base,
                         call_606398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606398, url, valid)

proc call*(call_606399: Call_GetDefineSuggester_606383; DomainName: string;
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
  var query_606400 = newJObject()
  add(query_606400, "DomainName", newJString(DomainName))
  add(query_606400, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(query_606400, "Action", newJString(Action))
  add(query_606400, "Suggester.SuggesterName", newJString(SuggesterSuggesterName))
  add(query_606400, "Version", newJString(Version))
  result = call_606399.call(nil, query_606400, nil, nil, nil)

var getDefineSuggester* = Call_GetDefineSuggester_606383(
    name: "getDefineSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_GetDefineSuggester_606384, base: "/",
    url: url_GetDefineSuggester_606385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAnalysisScheme_606437 = ref object of OpenApiRestCall_605589
proc url_PostDeleteAnalysisScheme_606439(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
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

proc validate_PostDeleteAnalysisScheme_606438(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606440 = query.getOrDefault("Action")
  valid_606440 = validateParameter(valid_606440, JString, required = true,
                                 default = newJString("DeleteAnalysisScheme"))
  if valid_606440 != nil:
    section.add "Action", valid_606440
  var valid_606441 = query.getOrDefault("Version")
  valid_606441 = validateParameter(valid_606441, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606441 != nil:
    section.add "Version", valid_606441
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
  var valid_606442 = header.getOrDefault("X-Amz-Signature")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Signature", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Content-Sha256", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Date")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Date", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Credential")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Credential", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-Security-Token")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-Security-Token", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-Algorithm")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Algorithm", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-SignedHeaders", valid_606448
  result.add "header", section
  ## parameters in `formData` object:
  ##   AnalysisSchemeName: JString (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AnalysisSchemeName` field"
  var valid_606449 = formData.getOrDefault("AnalysisSchemeName")
  valid_606449 = validateParameter(valid_606449, JString, required = true,
                                 default = nil)
  if valid_606449 != nil:
    section.add "AnalysisSchemeName", valid_606449
  var valid_606450 = formData.getOrDefault("DomainName")
  valid_606450 = validateParameter(valid_606450, JString, required = true,
                                 default = nil)
  if valid_606450 != nil:
    section.add "DomainName", valid_606450
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606451: Call_PostDeleteAnalysisScheme_606437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_606451.validator(path, query, header, formData, body)
  let scheme = call_606451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606451.url(scheme.get, call_606451.host, call_606451.base,
                         call_606451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606451, url, valid)

proc call*(call_606452: Call_PostDeleteAnalysisScheme_606437;
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
  var query_606453 = newJObject()
  var formData_606454 = newJObject()
  add(formData_606454, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(formData_606454, "DomainName", newJString(DomainName))
  add(query_606453, "Action", newJString(Action))
  add(query_606453, "Version", newJString(Version))
  result = call_606452.call(nil, query_606453, nil, formData_606454, nil)

var postDeleteAnalysisScheme* = Call_PostDeleteAnalysisScheme_606437(
    name: "postDeleteAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_PostDeleteAnalysisScheme_606438, base: "/",
    url: url_PostDeleteAnalysisScheme_606439, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAnalysisScheme_606420 = ref object of OpenApiRestCall_605589
proc url_GetDeleteAnalysisScheme_606422(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteAnalysisScheme_606421(path: JsonNode; query: JsonNode;
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
  var valid_606423 = query.getOrDefault("DomainName")
  valid_606423 = validateParameter(valid_606423, JString, required = true,
                                 default = nil)
  if valid_606423 != nil:
    section.add "DomainName", valid_606423
  var valid_606424 = query.getOrDefault("Action")
  valid_606424 = validateParameter(valid_606424, JString, required = true,
                                 default = newJString("DeleteAnalysisScheme"))
  if valid_606424 != nil:
    section.add "Action", valid_606424
  var valid_606425 = query.getOrDefault("AnalysisSchemeName")
  valid_606425 = validateParameter(valid_606425, JString, required = true,
                                 default = nil)
  if valid_606425 != nil:
    section.add "AnalysisSchemeName", valid_606425
  var valid_606426 = query.getOrDefault("Version")
  valid_606426 = validateParameter(valid_606426, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606426 != nil:
    section.add "Version", valid_606426
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
  var valid_606427 = header.getOrDefault("X-Amz-Signature")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Signature", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Content-Sha256", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Date")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Date", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Credential")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Credential", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-Security-Token")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-Security-Token", valid_606431
  var valid_606432 = header.getOrDefault("X-Amz-Algorithm")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-Algorithm", valid_606432
  var valid_606433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-SignedHeaders", valid_606433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606434: Call_GetDeleteAnalysisScheme_606420; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_606434.validator(path, query, header, formData, body)
  let scheme = call_606434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606434.url(scheme.get, call_606434.host, call_606434.base,
                         call_606434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606434, url, valid)

proc call*(call_606435: Call_GetDeleteAnalysisScheme_606420; DomainName: string;
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
  var query_606436 = newJObject()
  add(query_606436, "DomainName", newJString(DomainName))
  add(query_606436, "Action", newJString(Action))
  add(query_606436, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(query_606436, "Version", newJString(Version))
  result = call_606435.call(nil, query_606436, nil, nil, nil)

var getDeleteAnalysisScheme* = Call_GetDeleteAnalysisScheme_606420(
    name: "getDeleteAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_GetDeleteAnalysisScheme_606421, base: "/",
    url: url_GetDeleteAnalysisScheme_606422, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_606471 = ref object of OpenApiRestCall_605589
proc url_PostDeleteDomain_606473(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDomain_606472(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606474 = query.getOrDefault("Action")
  valid_606474 = validateParameter(valid_606474, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_606474 != nil:
    section.add "Action", valid_606474
  var valid_606475 = query.getOrDefault("Version")
  valid_606475 = validateParameter(valid_606475, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606475 != nil:
    section.add "Version", valid_606475
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
  var valid_606476 = header.getOrDefault("X-Amz-Signature")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-Signature", valid_606476
  var valid_606477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-Content-Sha256", valid_606477
  var valid_606478 = header.getOrDefault("X-Amz-Date")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "X-Amz-Date", valid_606478
  var valid_606479 = header.getOrDefault("X-Amz-Credential")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "X-Amz-Credential", valid_606479
  var valid_606480 = header.getOrDefault("X-Amz-Security-Token")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-Security-Token", valid_606480
  var valid_606481 = header.getOrDefault("X-Amz-Algorithm")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "X-Amz-Algorithm", valid_606481
  var valid_606482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606482 = validateParameter(valid_606482, JString, required = false,
                                 default = nil)
  if valid_606482 != nil:
    section.add "X-Amz-SignedHeaders", valid_606482
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606483 = formData.getOrDefault("DomainName")
  valid_606483 = validateParameter(valid_606483, JString, required = true,
                                 default = nil)
  if valid_606483 != nil:
    section.add "DomainName", valid_606483
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606484: Call_PostDeleteDomain_606471; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_606484.validator(path, query, header, formData, body)
  let scheme = call_606484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606484.url(scheme.get, call_606484.host, call_606484.base,
                         call_606484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606484, url, valid)

proc call*(call_606485: Call_PostDeleteDomain_606471; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606486 = newJObject()
  var formData_606487 = newJObject()
  add(formData_606487, "DomainName", newJString(DomainName))
  add(query_606486, "Action", newJString(Action))
  add(query_606486, "Version", newJString(Version))
  result = call_606485.call(nil, query_606486, nil, formData_606487, nil)

var postDeleteDomain* = Call_PostDeleteDomain_606471(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_606472,
    base: "/", url: url_PostDeleteDomain_606473,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_606455 = ref object of OpenApiRestCall_605589
proc url_GetDeleteDomain_606457(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDomain_606456(path: JsonNode; query: JsonNode;
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
  var valid_606458 = query.getOrDefault("DomainName")
  valid_606458 = validateParameter(valid_606458, JString, required = true,
                                 default = nil)
  if valid_606458 != nil:
    section.add "DomainName", valid_606458
  var valid_606459 = query.getOrDefault("Action")
  valid_606459 = validateParameter(valid_606459, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_606459 != nil:
    section.add "Action", valid_606459
  var valid_606460 = query.getOrDefault("Version")
  valid_606460 = validateParameter(valid_606460, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606460 != nil:
    section.add "Version", valid_606460
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
  var valid_606461 = header.getOrDefault("X-Amz-Signature")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-Signature", valid_606461
  var valid_606462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-Content-Sha256", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-Date")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Date", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-Credential")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-Credential", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-Security-Token")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-Security-Token", valid_606465
  var valid_606466 = header.getOrDefault("X-Amz-Algorithm")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "X-Amz-Algorithm", valid_606466
  var valid_606467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-SignedHeaders", valid_606467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606468: Call_GetDeleteDomain_606455; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_606468.validator(path, query, header, formData, body)
  let scheme = call_606468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606468.url(scheme.get, call_606468.host, call_606468.base,
                         call_606468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606468, url, valid)

proc call*(call_606469: Call_GetDeleteDomain_606455; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606470 = newJObject()
  add(query_606470, "DomainName", newJString(DomainName))
  add(query_606470, "Action", newJString(Action))
  add(query_606470, "Version", newJString(Version))
  result = call_606469.call(nil, query_606470, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_606455(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_606456,
    base: "/", url: url_GetDeleteDomain_606457, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteExpression_606505 = ref object of OpenApiRestCall_605589
proc url_PostDeleteExpression_606507(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteExpression_606506(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606508 = query.getOrDefault("Action")
  valid_606508 = validateParameter(valid_606508, JString, required = true,
                                 default = newJString("DeleteExpression"))
  if valid_606508 != nil:
    section.add "Action", valid_606508
  var valid_606509 = query.getOrDefault("Version")
  valid_606509 = validateParameter(valid_606509, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606509 != nil:
    section.add "Version", valid_606509
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
  var valid_606510 = header.getOrDefault("X-Amz-Signature")
  valid_606510 = validateParameter(valid_606510, JString, required = false,
                                 default = nil)
  if valid_606510 != nil:
    section.add "X-Amz-Signature", valid_606510
  var valid_606511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606511 = validateParameter(valid_606511, JString, required = false,
                                 default = nil)
  if valid_606511 != nil:
    section.add "X-Amz-Content-Sha256", valid_606511
  var valid_606512 = header.getOrDefault("X-Amz-Date")
  valid_606512 = validateParameter(valid_606512, JString, required = false,
                                 default = nil)
  if valid_606512 != nil:
    section.add "X-Amz-Date", valid_606512
  var valid_606513 = header.getOrDefault("X-Amz-Credential")
  valid_606513 = validateParameter(valid_606513, JString, required = false,
                                 default = nil)
  if valid_606513 != nil:
    section.add "X-Amz-Credential", valid_606513
  var valid_606514 = header.getOrDefault("X-Amz-Security-Token")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-Security-Token", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Algorithm")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Algorithm", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-SignedHeaders", valid_606516
  result.add "header", section
  ## parameters in `formData` object:
  ##   ExpressionName: JString (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ExpressionName` field"
  var valid_606517 = formData.getOrDefault("ExpressionName")
  valid_606517 = validateParameter(valid_606517, JString, required = true,
                                 default = nil)
  if valid_606517 != nil:
    section.add "ExpressionName", valid_606517
  var valid_606518 = formData.getOrDefault("DomainName")
  valid_606518 = validateParameter(valid_606518, JString, required = true,
                                 default = nil)
  if valid_606518 != nil:
    section.add "DomainName", valid_606518
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606519: Call_PostDeleteExpression_606505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606519.validator(path, query, header, formData, body)
  let scheme = call_606519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606519.url(scheme.get, call_606519.host, call_606519.base,
                         call_606519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606519, url, valid)

proc call*(call_606520: Call_PostDeleteExpression_606505; ExpressionName: string;
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
  var query_606521 = newJObject()
  var formData_606522 = newJObject()
  add(formData_606522, "ExpressionName", newJString(ExpressionName))
  add(formData_606522, "DomainName", newJString(DomainName))
  add(query_606521, "Action", newJString(Action))
  add(query_606521, "Version", newJString(Version))
  result = call_606520.call(nil, query_606521, nil, formData_606522, nil)

var postDeleteExpression* = Call_PostDeleteExpression_606505(
    name: "postDeleteExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_PostDeleteExpression_606506, base: "/",
    url: url_PostDeleteExpression_606507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteExpression_606488 = ref object of OpenApiRestCall_605589
proc url_GetDeleteExpression_606490(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteExpression_606489(path: JsonNode; query: JsonNode;
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
  var valid_606491 = query.getOrDefault("ExpressionName")
  valid_606491 = validateParameter(valid_606491, JString, required = true,
                                 default = nil)
  if valid_606491 != nil:
    section.add "ExpressionName", valid_606491
  var valid_606492 = query.getOrDefault("DomainName")
  valid_606492 = validateParameter(valid_606492, JString, required = true,
                                 default = nil)
  if valid_606492 != nil:
    section.add "DomainName", valid_606492
  var valid_606493 = query.getOrDefault("Action")
  valid_606493 = validateParameter(valid_606493, JString, required = true,
                                 default = newJString("DeleteExpression"))
  if valid_606493 != nil:
    section.add "Action", valid_606493
  var valid_606494 = query.getOrDefault("Version")
  valid_606494 = validateParameter(valid_606494, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606494 != nil:
    section.add "Version", valid_606494
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
  var valid_606495 = header.getOrDefault("X-Amz-Signature")
  valid_606495 = validateParameter(valid_606495, JString, required = false,
                                 default = nil)
  if valid_606495 != nil:
    section.add "X-Amz-Signature", valid_606495
  var valid_606496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "X-Amz-Content-Sha256", valid_606496
  var valid_606497 = header.getOrDefault("X-Amz-Date")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "X-Amz-Date", valid_606497
  var valid_606498 = header.getOrDefault("X-Amz-Credential")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "X-Amz-Credential", valid_606498
  var valid_606499 = header.getOrDefault("X-Amz-Security-Token")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "X-Amz-Security-Token", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-Algorithm")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Algorithm", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-SignedHeaders", valid_606501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606502: Call_GetDeleteExpression_606488; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606502.validator(path, query, header, formData, body)
  let scheme = call_606502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606502.url(scheme.get, call_606502.host, call_606502.base,
                         call_606502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606502, url, valid)

proc call*(call_606503: Call_GetDeleteExpression_606488; ExpressionName: string;
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
  var query_606504 = newJObject()
  add(query_606504, "ExpressionName", newJString(ExpressionName))
  add(query_606504, "DomainName", newJString(DomainName))
  add(query_606504, "Action", newJString(Action))
  add(query_606504, "Version", newJString(Version))
  result = call_606503.call(nil, query_606504, nil, nil, nil)

var getDeleteExpression* = Call_GetDeleteExpression_606488(
    name: "getDeleteExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_GetDeleteExpression_606489, base: "/",
    url: url_GetDeleteExpression_606490, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_606540 = ref object of OpenApiRestCall_605589
proc url_PostDeleteIndexField_606542(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteIndexField_606541(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606543 = query.getOrDefault("Action")
  valid_606543 = validateParameter(valid_606543, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_606543 != nil:
    section.add "Action", valid_606543
  var valid_606544 = query.getOrDefault("Version")
  valid_606544 = validateParameter(valid_606544, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606544 != nil:
    section.add "Version", valid_606544
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
  var valid_606545 = header.getOrDefault("X-Amz-Signature")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Signature", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Content-Sha256", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Date")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Date", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Credential")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Credential", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Security-Token")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Security-Token", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Algorithm")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Algorithm", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-SignedHeaders", valid_606551
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldName: JString (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606552 = formData.getOrDefault("DomainName")
  valid_606552 = validateParameter(valid_606552, JString, required = true,
                                 default = nil)
  if valid_606552 != nil:
    section.add "DomainName", valid_606552
  var valid_606553 = formData.getOrDefault("IndexFieldName")
  valid_606553 = validateParameter(valid_606553, JString, required = true,
                                 default = nil)
  if valid_606553 != nil:
    section.add "IndexFieldName", valid_606553
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606554: Call_PostDeleteIndexField_606540; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606554.validator(path, query, header, formData, body)
  let scheme = call_606554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606554.url(scheme.get, call_606554.host, call_606554.base,
                         call_606554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606554, url, valid)

proc call*(call_606555: Call_PostDeleteIndexField_606540; DomainName: string;
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
  var query_606556 = newJObject()
  var formData_606557 = newJObject()
  add(formData_606557, "DomainName", newJString(DomainName))
  add(formData_606557, "IndexFieldName", newJString(IndexFieldName))
  add(query_606556, "Action", newJString(Action))
  add(query_606556, "Version", newJString(Version))
  result = call_606555.call(nil, query_606556, nil, formData_606557, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_606540(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_606541, base: "/",
    url: url_PostDeleteIndexField_606542, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_606523 = ref object of OpenApiRestCall_605589
proc url_GetDeleteIndexField_606525(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteIndexField_606524(path: JsonNode; query: JsonNode;
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
  var valid_606526 = query.getOrDefault("DomainName")
  valid_606526 = validateParameter(valid_606526, JString, required = true,
                                 default = nil)
  if valid_606526 != nil:
    section.add "DomainName", valid_606526
  var valid_606527 = query.getOrDefault("Action")
  valid_606527 = validateParameter(valid_606527, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_606527 != nil:
    section.add "Action", valid_606527
  var valid_606528 = query.getOrDefault("IndexFieldName")
  valid_606528 = validateParameter(valid_606528, JString, required = true,
                                 default = nil)
  if valid_606528 != nil:
    section.add "IndexFieldName", valid_606528
  var valid_606529 = query.getOrDefault("Version")
  valid_606529 = validateParameter(valid_606529, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606529 != nil:
    section.add "Version", valid_606529
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
  var valid_606530 = header.getOrDefault("X-Amz-Signature")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-Signature", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Content-Sha256", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Date")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Date", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Credential")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Credential", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Security-Token")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Security-Token", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Algorithm")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Algorithm", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-SignedHeaders", valid_606536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606537: Call_GetDeleteIndexField_606523; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606537.validator(path, query, header, formData, body)
  let scheme = call_606537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606537.url(scheme.get, call_606537.host, call_606537.base,
                         call_606537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606537, url, valid)

proc call*(call_606538: Call_GetDeleteIndexField_606523; DomainName: string;
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
  var query_606539 = newJObject()
  add(query_606539, "DomainName", newJString(DomainName))
  add(query_606539, "Action", newJString(Action))
  add(query_606539, "IndexFieldName", newJString(IndexFieldName))
  add(query_606539, "Version", newJString(Version))
  result = call_606538.call(nil, query_606539, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_606523(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_606524, base: "/",
    url: url_GetDeleteIndexField_606525, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteSuggester_606575 = ref object of OpenApiRestCall_605589
proc url_PostDeleteSuggester_606577(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteSuggester_606576(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606578 = query.getOrDefault("Action")
  valid_606578 = validateParameter(valid_606578, JString, required = true,
                                 default = newJString("DeleteSuggester"))
  if valid_606578 != nil:
    section.add "Action", valid_606578
  var valid_606579 = query.getOrDefault("Version")
  valid_606579 = validateParameter(valid_606579, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606579 != nil:
    section.add "Version", valid_606579
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
  var valid_606580 = header.getOrDefault("X-Amz-Signature")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-Signature", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-Content-Sha256", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-Date")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Date", valid_606582
  var valid_606583 = header.getOrDefault("X-Amz-Credential")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-Credential", valid_606583
  var valid_606584 = header.getOrDefault("X-Amz-Security-Token")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "X-Amz-Security-Token", valid_606584
  var valid_606585 = header.getOrDefault("X-Amz-Algorithm")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-Algorithm", valid_606585
  var valid_606586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606586 = validateParameter(valid_606586, JString, required = false,
                                 default = nil)
  if valid_606586 != nil:
    section.add "X-Amz-SignedHeaders", valid_606586
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   SuggesterName: JString (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606587 = formData.getOrDefault("DomainName")
  valid_606587 = validateParameter(valid_606587, JString, required = true,
                                 default = nil)
  if valid_606587 != nil:
    section.add "DomainName", valid_606587
  var valid_606588 = formData.getOrDefault("SuggesterName")
  valid_606588 = validateParameter(valid_606588, JString, required = true,
                                 default = nil)
  if valid_606588 != nil:
    section.add "SuggesterName", valid_606588
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606589: Call_PostDeleteSuggester_606575; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606589.validator(path, query, header, formData, body)
  let scheme = call_606589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606589.url(scheme.get, call_606589.host, call_606589.base,
                         call_606589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606589, url, valid)

proc call*(call_606590: Call_PostDeleteSuggester_606575; DomainName: string;
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
  var query_606591 = newJObject()
  var formData_606592 = newJObject()
  add(formData_606592, "DomainName", newJString(DomainName))
  add(formData_606592, "SuggesterName", newJString(SuggesterName))
  add(query_606591, "Action", newJString(Action))
  add(query_606591, "Version", newJString(Version))
  result = call_606590.call(nil, query_606591, nil, formData_606592, nil)

var postDeleteSuggester* = Call_PostDeleteSuggester_606575(
    name: "postDeleteSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_PostDeleteSuggester_606576, base: "/",
    url: url_PostDeleteSuggester_606577, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteSuggester_606558 = ref object of OpenApiRestCall_605589
proc url_GetDeleteSuggester_606560(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteSuggester_606559(path: JsonNode; query: JsonNode;
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
  var valid_606561 = query.getOrDefault("DomainName")
  valid_606561 = validateParameter(valid_606561, JString, required = true,
                                 default = nil)
  if valid_606561 != nil:
    section.add "DomainName", valid_606561
  var valid_606562 = query.getOrDefault("Action")
  valid_606562 = validateParameter(valid_606562, JString, required = true,
                                 default = newJString("DeleteSuggester"))
  if valid_606562 != nil:
    section.add "Action", valid_606562
  var valid_606563 = query.getOrDefault("Version")
  valid_606563 = validateParameter(valid_606563, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606563 != nil:
    section.add "Version", valid_606563
  var valid_606564 = query.getOrDefault("SuggesterName")
  valid_606564 = validateParameter(valid_606564, JString, required = true,
                                 default = nil)
  if valid_606564 != nil:
    section.add "SuggesterName", valid_606564
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
  var valid_606565 = header.getOrDefault("X-Amz-Signature")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Signature", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-Content-Sha256", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-Date")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-Date", valid_606567
  var valid_606568 = header.getOrDefault("X-Amz-Credential")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-Credential", valid_606568
  var valid_606569 = header.getOrDefault("X-Amz-Security-Token")
  valid_606569 = validateParameter(valid_606569, JString, required = false,
                                 default = nil)
  if valid_606569 != nil:
    section.add "X-Amz-Security-Token", valid_606569
  var valid_606570 = header.getOrDefault("X-Amz-Algorithm")
  valid_606570 = validateParameter(valid_606570, JString, required = false,
                                 default = nil)
  if valid_606570 != nil:
    section.add "X-Amz-Algorithm", valid_606570
  var valid_606571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606571 = validateParameter(valid_606571, JString, required = false,
                                 default = nil)
  if valid_606571 != nil:
    section.add "X-Amz-SignedHeaders", valid_606571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606572: Call_GetDeleteSuggester_606558; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606572.validator(path, query, header, formData, body)
  let scheme = call_606572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606572.url(scheme.get, call_606572.host, call_606572.base,
                         call_606572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606572, url, valid)

proc call*(call_606573: Call_GetDeleteSuggester_606558; DomainName: string;
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
  var query_606574 = newJObject()
  add(query_606574, "DomainName", newJString(DomainName))
  add(query_606574, "Action", newJString(Action))
  add(query_606574, "Version", newJString(Version))
  add(query_606574, "SuggesterName", newJString(SuggesterName))
  result = call_606573.call(nil, query_606574, nil, nil, nil)

var getDeleteSuggester* = Call_GetDeleteSuggester_606558(
    name: "getDeleteSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_GetDeleteSuggester_606559, base: "/",
    url: url_GetDeleteSuggester_606560, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAnalysisSchemes_606611 = ref object of OpenApiRestCall_605589
proc url_PostDescribeAnalysisSchemes_606613(protocol: Scheme; host: string;
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

proc validate_PostDescribeAnalysisSchemes_606612(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606614 = query.getOrDefault("Action")
  valid_606614 = validateParameter(valid_606614, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_606614 != nil:
    section.add "Action", valid_606614
  var valid_606615 = query.getOrDefault("Version")
  valid_606615 = validateParameter(valid_606615, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606615 != nil:
    section.add "Version", valid_606615
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
  var valid_606616 = header.getOrDefault("X-Amz-Signature")
  valid_606616 = validateParameter(valid_606616, JString, required = false,
                                 default = nil)
  if valid_606616 != nil:
    section.add "X-Amz-Signature", valid_606616
  var valid_606617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "X-Amz-Content-Sha256", valid_606617
  var valid_606618 = header.getOrDefault("X-Amz-Date")
  valid_606618 = validateParameter(valid_606618, JString, required = false,
                                 default = nil)
  if valid_606618 != nil:
    section.add "X-Amz-Date", valid_606618
  var valid_606619 = header.getOrDefault("X-Amz-Credential")
  valid_606619 = validateParameter(valid_606619, JString, required = false,
                                 default = nil)
  if valid_606619 != nil:
    section.add "X-Amz-Credential", valid_606619
  var valid_606620 = header.getOrDefault("X-Amz-Security-Token")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "X-Amz-Security-Token", valid_606620
  var valid_606621 = header.getOrDefault("X-Amz-Algorithm")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "X-Amz-Algorithm", valid_606621
  var valid_606622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-SignedHeaders", valid_606622
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  section = newJObject()
  var valid_606623 = formData.getOrDefault("Deployed")
  valid_606623 = validateParameter(valid_606623, JBool, required = false, default = nil)
  if valid_606623 != nil:
    section.add "Deployed", valid_606623
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606624 = formData.getOrDefault("DomainName")
  valid_606624 = validateParameter(valid_606624, JString, required = true,
                                 default = nil)
  if valid_606624 != nil:
    section.add "DomainName", valid_606624
  var valid_606625 = formData.getOrDefault("AnalysisSchemeNames")
  valid_606625 = validateParameter(valid_606625, JArray, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "AnalysisSchemeNames", valid_606625
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606626: Call_PostDescribeAnalysisSchemes_606611; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606626.validator(path, query, header, formData, body)
  let scheme = call_606626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606626.url(scheme.get, call_606626.host, call_606626.base,
                         call_606626.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606626, url, valid)

proc call*(call_606627: Call_PostDescribeAnalysisSchemes_606611;
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
  var query_606628 = newJObject()
  var formData_606629 = newJObject()
  add(formData_606629, "Deployed", newJBool(Deployed))
  add(formData_606629, "DomainName", newJString(DomainName))
  if AnalysisSchemeNames != nil:
    formData_606629.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_606628, "Action", newJString(Action))
  add(query_606628, "Version", newJString(Version))
  result = call_606627.call(nil, query_606628, nil, formData_606629, nil)

var postDescribeAnalysisSchemes* = Call_PostDescribeAnalysisSchemes_606611(
    name: "postDescribeAnalysisSchemes", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_PostDescribeAnalysisSchemes_606612, base: "/",
    url: url_PostDescribeAnalysisSchemes_606613,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAnalysisSchemes_606593 = ref object of OpenApiRestCall_605589
proc url_GetDescribeAnalysisSchemes_606595(protocol: Scheme; host: string;
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

proc validate_GetDescribeAnalysisSchemes_606594(path: JsonNode; query: JsonNode;
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
  var valid_606596 = query.getOrDefault("DomainName")
  valid_606596 = validateParameter(valid_606596, JString, required = true,
                                 default = nil)
  if valid_606596 != nil:
    section.add "DomainName", valid_606596
  var valid_606597 = query.getOrDefault("AnalysisSchemeNames")
  valid_606597 = validateParameter(valid_606597, JArray, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "AnalysisSchemeNames", valid_606597
  var valid_606598 = query.getOrDefault("Deployed")
  valid_606598 = validateParameter(valid_606598, JBool, required = false, default = nil)
  if valid_606598 != nil:
    section.add "Deployed", valid_606598
  var valid_606599 = query.getOrDefault("Action")
  valid_606599 = validateParameter(valid_606599, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_606599 != nil:
    section.add "Action", valid_606599
  var valid_606600 = query.getOrDefault("Version")
  valid_606600 = validateParameter(valid_606600, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606600 != nil:
    section.add "Version", valid_606600
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
  var valid_606601 = header.getOrDefault("X-Amz-Signature")
  valid_606601 = validateParameter(valid_606601, JString, required = false,
                                 default = nil)
  if valid_606601 != nil:
    section.add "X-Amz-Signature", valid_606601
  var valid_606602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-Content-Sha256", valid_606602
  var valid_606603 = header.getOrDefault("X-Amz-Date")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "X-Amz-Date", valid_606603
  var valid_606604 = header.getOrDefault("X-Amz-Credential")
  valid_606604 = validateParameter(valid_606604, JString, required = false,
                                 default = nil)
  if valid_606604 != nil:
    section.add "X-Amz-Credential", valid_606604
  var valid_606605 = header.getOrDefault("X-Amz-Security-Token")
  valid_606605 = validateParameter(valid_606605, JString, required = false,
                                 default = nil)
  if valid_606605 != nil:
    section.add "X-Amz-Security-Token", valid_606605
  var valid_606606 = header.getOrDefault("X-Amz-Algorithm")
  valid_606606 = validateParameter(valid_606606, JString, required = false,
                                 default = nil)
  if valid_606606 != nil:
    section.add "X-Amz-Algorithm", valid_606606
  var valid_606607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "X-Amz-SignedHeaders", valid_606607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606608: Call_GetDescribeAnalysisSchemes_606593; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606608.validator(path, query, header, formData, body)
  let scheme = call_606608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606608.url(scheme.get, call_606608.host, call_606608.base,
                         call_606608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606608, url, valid)

proc call*(call_606609: Call_GetDescribeAnalysisSchemes_606593; DomainName: string;
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
  var query_606610 = newJObject()
  add(query_606610, "DomainName", newJString(DomainName))
  if AnalysisSchemeNames != nil:
    query_606610.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_606610, "Deployed", newJBool(Deployed))
  add(query_606610, "Action", newJString(Action))
  add(query_606610, "Version", newJString(Version))
  result = call_606609.call(nil, query_606610, nil, nil, nil)

var getDescribeAnalysisSchemes* = Call_GetDescribeAnalysisSchemes_606593(
    name: "getDescribeAnalysisSchemes", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_GetDescribeAnalysisSchemes_606594, base: "/",
    url: url_GetDescribeAnalysisSchemes_606595,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_606647 = ref object of OpenApiRestCall_605589
proc url_PostDescribeAvailabilityOptions_606649(protocol: Scheme; host: string;
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

proc validate_PostDescribeAvailabilityOptions_606648(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606650 = query.getOrDefault("Action")
  valid_606650 = validateParameter(valid_606650, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_606650 != nil:
    section.add "Action", valid_606650
  var valid_606651 = query.getOrDefault("Version")
  valid_606651 = validateParameter(valid_606651, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606651 != nil:
    section.add "Version", valid_606651
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
  var valid_606652 = header.getOrDefault("X-Amz-Signature")
  valid_606652 = validateParameter(valid_606652, JString, required = false,
                                 default = nil)
  if valid_606652 != nil:
    section.add "X-Amz-Signature", valid_606652
  var valid_606653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606653 = validateParameter(valid_606653, JString, required = false,
                                 default = nil)
  if valid_606653 != nil:
    section.add "X-Amz-Content-Sha256", valid_606653
  var valid_606654 = header.getOrDefault("X-Amz-Date")
  valid_606654 = validateParameter(valid_606654, JString, required = false,
                                 default = nil)
  if valid_606654 != nil:
    section.add "X-Amz-Date", valid_606654
  var valid_606655 = header.getOrDefault("X-Amz-Credential")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Credential", valid_606655
  var valid_606656 = header.getOrDefault("X-Amz-Security-Token")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-Security-Token", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-Algorithm")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-Algorithm", valid_606657
  var valid_606658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606658 = validateParameter(valid_606658, JString, required = false,
                                 default = nil)
  if valid_606658 != nil:
    section.add "X-Amz-SignedHeaders", valid_606658
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_606659 = formData.getOrDefault("Deployed")
  valid_606659 = validateParameter(valid_606659, JBool, required = false, default = nil)
  if valid_606659 != nil:
    section.add "Deployed", valid_606659
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606660 = formData.getOrDefault("DomainName")
  valid_606660 = validateParameter(valid_606660, JString, required = true,
                                 default = nil)
  if valid_606660 != nil:
    section.add "DomainName", valid_606660
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606661: Call_PostDescribeAvailabilityOptions_606647;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606661.validator(path, query, header, formData, body)
  let scheme = call_606661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606661.url(scheme.get, call_606661.host, call_606661.base,
                         call_606661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606661, url, valid)

proc call*(call_606662: Call_PostDescribeAvailabilityOptions_606647;
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
  var query_606663 = newJObject()
  var formData_606664 = newJObject()
  add(formData_606664, "Deployed", newJBool(Deployed))
  add(formData_606664, "DomainName", newJString(DomainName))
  add(query_606663, "Action", newJString(Action))
  add(query_606663, "Version", newJString(Version))
  result = call_606662.call(nil, query_606663, nil, formData_606664, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_606647(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_606648, base: "/",
    url: url_PostDescribeAvailabilityOptions_606649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_606630 = ref object of OpenApiRestCall_605589
proc url_GetDescribeAvailabilityOptions_606632(protocol: Scheme; host: string;
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

proc validate_GetDescribeAvailabilityOptions_606631(path: JsonNode;
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
  var valid_606633 = query.getOrDefault("DomainName")
  valid_606633 = validateParameter(valid_606633, JString, required = true,
                                 default = nil)
  if valid_606633 != nil:
    section.add "DomainName", valid_606633
  var valid_606634 = query.getOrDefault("Deployed")
  valid_606634 = validateParameter(valid_606634, JBool, required = false, default = nil)
  if valid_606634 != nil:
    section.add "Deployed", valid_606634
  var valid_606635 = query.getOrDefault("Action")
  valid_606635 = validateParameter(valid_606635, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_606635 != nil:
    section.add "Action", valid_606635
  var valid_606636 = query.getOrDefault("Version")
  valid_606636 = validateParameter(valid_606636, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606636 != nil:
    section.add "Version", valid_606636
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
  var valid_606637 = header.getOrDefault("X-Amz-Signature")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Signature", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Content-Sha256", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-Date")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Date", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-Credential")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Credential", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-Security-Token")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-Security-Token", valid_606641
  var valid_606642 = header.getOrDefault("X-Amz-Algorithm")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-Algorithm", valid_606642
  var valid_606643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-SignedHeaders", valid_606643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606644: Call_GetDescribeAvailabilityOptions_606630; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606644.validator(path, query, header, formData, body)
  let scheme = call_606644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606644.url(scheme.get, call_606644.host, call_606644.base,
                         call_606644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606644, url, valid)

proc call*(call_606645: Call_GetDescribeAvailabilityOptions_606630;
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
  var query_606646 = newJObject()
  add(query_606646, "DomainName", newJString(DomainName))
  add(query_606646, "Deployed", newJBool(Deployed))
  add(query_606646, "Action", newJString(Action))
  add(query_606646, "Version", newJString(Version))
  result = call_606645.call(nil, query_606646, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_606630(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_606631, base: "/",
    url: url_GetDescribeAvailabilityOptions_606632,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomainEndpointOptions_606682 = ref object of OpenApiRestCall_605589
proc url_PostDescribeDomainEndpointOptions_606684(protocol: Scheme; host: string;
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

proc validate_PostDescribeDomainEndpointOptions_606683(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606685 = query.getOrDefault("Action")
  valid_606685 = validateParameter(valid_606685, JString, required = true, default = newJString(
      "DescribeDomainEndpointOptions"))
  if valid_606685 != nil:
    section.add "Action", valid_606685
  var valid_606686 = query.getOrDefault("Version")
  valid_606686 = validateParameter(valid_606686, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606686 != nil:
    section.add "Version", valid_606686
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
  var valid_606687 = header.getOrDefault("X-Amz-Signature")
  valid_606687 = validateParameter(valid_606687, JString, required = false,
                                 default = nil)
  if valid_606687 != nil:
    section.add "X-Amz-Signature", valid_606687
  var valid_606688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606688 = validateParameter(valid_606688, JString, required = false,
                                 default = nil)
  if valid_606688 != nil:
    section.add "X-Amz-Content-Sha256", valid_606688
  var valid_606689 = header.getOrDefault("X-Amz-Date")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-Date", valid_606689
  var valid_606690 = header.getOrDefault("X-Amz-Credential")
  valid_606690 = validateParameter(valid_606690, JString, required = false,
                                 default = nil)
  if valid_606690 != nil:
    section.add "X-Amz-Credential", valid_606690
  var valid_606691 = header.getOrDefault("X-Amz-Security-Token")
  valid_606691 = validateParameter(valid_606691, JString, required = false,
                                 default = nil)
  if valid_606691 != nil:
    section.add "X-Amz-Security-Token", valid_606691
  var valid_606692 = header.getOrDefault("X-Amz-Algorithm")
  valid_606692 = validateParameter(valid_606692, JString, required = false,
                                 default = nil)
  if valid_606692 != nil:
    section.add "X-Amz-Algorithm", valid_606692
  var valid_606693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606693 = validateParameter(valid_606693, JString, required = false,
                                 default = nil)
  if valid_606693 != nil:
    section.add "X-Amz-SignedHeaders", valid_606693
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to retrieve the latest configuration (which might be in a Processing state) or the current, active configuration. Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_606694 = formData.getOrDefault("Deployed")
  valid_606694 = validateParameter(valid_606694, JBool, required = false, default = nil)
  if valid_606694 != nil:
    section.add "Deployed", valid_606694
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606695 = formData.getOrDefault("DomainName")
  valid_606695 = validateParameter(valid_606695, JString, required = true,
                                 default = nil)
  if valid_606695 != nil:
    section.add "DomainName", valid_606695
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606696: Call_PostDescribeDomainEndpointOptions_606682;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606696.validator(path, query, header, formData, body)
  let scheme = call_606696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606696.url(scheme.get, call_606696.host, call_606696.base,
                         call_606696.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606696, url, valid)

proc call*(call_606697: Call_PostDescribeDomainEndpointOptions_606682;
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
  var query_606698 = newJObject()
  var formData_606699 = newJObject()
  add(formData_606699, "Deployed", newJBool(Deployed))
  add(formData_606699, "DomainName", newJString(DomainName))
  add(query_606698, "Action", newJString(Action))
  add(query_606698, "Version", newJString(Version))
  result = call_606697.call(nil, query_606698, nil, formData_606699, nil)

var postDescribeDomainEndpointOptions* = Call_PostDescribeDomainEndpointOptions_606682(
    name: "postDescribeDomainEndpointOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDomainEndpointOptions",
    validator: validate_PostDescribeDomainEndpointOptions_606683, base: "/",
    url: url_PostDescribeDomainEndpointOptions_606684,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomainEndpointOptions_606665 = ref object of OpenApiRestCall_605589
proc url_GetDescribeDomainEndpointOptions_606667(protocol: Scheme; host: string;
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

proc validate_GetDescribeDomainEndpointOptions_606666(path: JsonNode;
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
  var valid_606668 = query.getOrDefault("DomainName")
  valid_606668 = validateParameter(valid_606668, JString, required = true,
                                 default = nil)
  if valid_606668 != nil:
    section.add "DomainName", valid_606668
  var valid_606669 = query.getOrDefault("Deployed")
  valid_606669 = validateParameter(valid_606669, JBool, required = false, default = nil)
  if valid_606669 != nil:
    section.add "Deployed", valid_606669
  var valid_606670 = query.getOrDefault("Action")
  valid_606670 = validateParameter(valid_606670, JString, required = true, default = newJString(
      "DescribeDomainEndpointOptions"))
  if valid_606670 != nil:
    section.add "Action", valid_606670
  var valid_606671 = query.getOrDefault("Version")
  valid_606671 = validateParameter(valid_606671, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606671 != nil:
    section.add "Version", valid_606671
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
  var valid_606672 = header.getOrDefault("X-Amz-Signature")
  valid_606672 = validateParameter(valid_606672, JString, required = false,
                                 default = nil)
  if valid_606672 != nil:
    section.add "X-Amz-Signature", valid_606672
  var valid_606673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606673 = validateParameter(valid_606673, JString, required = false,
                                 default = nil)
  if valid_606673 != nil:
    section.add "X-Amz-Content-Sha256", valid_606673
  var valid_606674 = header.getOrDefault("X-Amz-Date")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-Date", valid_606674
  var valid_606675 = header.getOrDefault("X-Amz-Credential")
  valid_606675 = validateParameter(valid_606675, JString, required = false,
                                 default = nil)
  if valid_606675 != nil:
    section.add "X-Amz-Credential", valid_606675
  var valid_606676 = header.getOrDefault("X-Amz-Security-Token")
  valid_606676 = validateParameter(valid_606676, JString, required = false,
                                 default = nil)
  if valid_606676 != nil:
    section.add "X-Amz-Security-Token", valid_606676
  var valid_606677 = header.getOrDefault("X-Amz-Algorithm")
  valid_606677 = validateParameter(valid_606677, JString, required = false,
                                 default = nil)
  if valid_606677 != nil:
    section.add "X-Amz-Algorithm", valid_606677
  var valid_606678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606678 = validateParameter(valid_606678, JString, required = false,
                                 default = nil)
  if valid_606678 != nil:
    section.add "X-Amz-SignedHeaders", valid_606678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606679: Call_GetDescribeDomainEndpointOptions_606665;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606679.validator(path, query, header, formData, body)
  let scheme = call_606679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606679.url(scheme.get, call_606679.host, call_606679.base,
                         call_606679.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606679, url, valid)

proc call*(call_606680: Call_GetDescribeDomainEndpointOptions_606665;
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
  var query_606681 = newJObject()
  add(query_606681, "DomainName", newJString(DomainName))
  add(query_606681, "Deployed", newJBool(Deployed))
  add(query_606681, "Action", newJString(Action))
  add(query_606681, "Version", newJString(Version))
  result = call_606680.call(nil, query_606681, nil, nil, nil)

var getDescribeDomainEndpointOptions* = Call_GetDescribeDomainEndpointOptions_606665(
    name: "getDescribeDomainEndpointOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDomainEndpointOptions",
    validator: validate_GetDescribeDomainEndpointOptions_606666, base: "/",
    url: url_GetDescribeDomainEndpointOptions_606667,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_606716 = ref object of OpenApiRestCall_605589
proc url_PostDescribeDomains_606718(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDomains_606717(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606719 = query.getOrDefault("Action")
  valid_606719 = validateParameter(valid_606719, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_606719 != nil:
    section.add "Action", valid_606719
  var valid_606720 = query.getOrDefault("Version")
  valid_606720 = validateParameter(valid_606720, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606720 != nil:
    section.add "Version", valid_606720
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
  var valid_606721 = header.getOrDefault("X-Amz-Signature")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "X-Amz-Signature", valid_606721
  var valid_606722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606722 = validateParameter(valid_606722, JString, required = false,
                                 default = nil)
  if valid_606722 != nil:
    section.add "X-Amz-Content-Sha256", valid_606722
  var valid_606723 = header.getOrDefault("X-Amz-Date")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "X-Amz-Date", valid_606723
  var valid_606724 = header.getOrDefault("X-Amz-Credential")
  valid_606724 = validateParameter(valid_606724, JString, required = false,
                                 default = nil)
  if valid_606724 != nil:
    section.add "X-Amz-Credential", valid_606724
  var valid_606725 = header.getOrDefault("X-Amz-Security-Token")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "X-Amz-Security-Token", valid_606725
  var valid_606726 = header.getOrDefault("X-Amz-Algorithm")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "X-Amz-Algorithm", valid_606726
  var valid_606727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606727 = validateParameter(valid_606727, JString, required = false,
                                 default = nil)
  if valid_606727 != nil:
    section.add "X-Amz-SignedHeaders", valid_606727
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_606728 = formData.getOrDefault("DomainNames")
  valid_606728 = validateParameter(valid_606728, JArray, required = false,
                                 default = nil)
  if valid_606728 != nil:
    section.add "DomainNames", valid_606728
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606729: Call_PostDescribeDomains_606716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606729.validator(path, query, header, formData, body)
  let scheme = call_606729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606729.url(scheme.get, call_606729.host, call_606729.base,
                         call_606729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606729, url, valid)

proc call*(call_606730: Call_PostDescribeDomains_606716;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606731 = newJObject()
  var formData_606732 = newJObject()
  if DomainNames != nil:
    formData_606732.add "DomainNames", DomainNames
  add(query_606731, "Action", newJString(Action))
  add(query_606731, "Version", newJString(Version))
  result = call_606730.call(nil, query_606731, nil, formData_606732, nil)

var postDescribeDomains* = Call_PostDescribeDomains_606716(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_606717, base: "/",
    url: url_PostDescribeDomains_606718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_606700 = ref object of OpenApiRestCall_605589
proc url_GetDescribeDomains_606702(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDomains_606701(path: JsonNode; query: JsonNode;
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
  var valid_606703 = query.getOrDefault("DomainNames")
  valid_606703 = validateParameter(valid_606703, JArray, required = false,
                                 default = nil)
  if valid_606703 != nil:
    section.add "DomainNames", valid_606703
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606704 = query.getOrDefault("Action")
  valid_606704 = validateParameter(valid_606704, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_606704 != nil:
    section.add "Action", valid_606704
  var valid_606705 = query.getOrDefault("Version")
  valid_606705 = validateParameter(valid_606705, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606705 != nil:
    section.add "Version", valid_606705
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
  var valid_606706 = header.getOrDefault("X-Amz-Signature")
  valid_606706 = validateParameter(valid_606706, JString, required = false,
                                 default = nil)
  if valid_606706 != nil:
    section.add "X-Amz-Signature", valid_606706
  var valid_606707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606707 = validateParameter(valid_606707, JString, required = false,
                                 default = nil)
  if valid_606707 != nil:
    section.add "X-Amz-Content-Sha256", valid_606707
  var valid_606708 = header.getOrDefault("X-Amz-Date")
  valid_606708 = validateParameter(valid_606708, JString, required = false,
                                 default = nil)
  if valid_606708 != nil:
    section.add "X-Amz-Date", valid_606708
  var valid_606709 = header.getOrDefault("X-Amz-Credential")
  valid_606709 = validateParameter(valid_606709, JString, required = false,
                                 default = nil)
  if valid_606709 != nil:
    section.add "X-Amz-Credential", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-Security-Token")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-Security-Token", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-Algorithm")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-Algorithm", valid_606711
  var valid_606712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606712 = validateParameter(valid_606712, JString, required = false,
                                 default = nil)
  if valid_606712 != nil:
    section.add "X-Amz-SignedHeaders", valid_606712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606713: Call_GetDescribeDomains_606700; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606713.validator(path, query, header, formData, body)
  let scheme = call_606713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606713.url(scheme.get, call_606713.host, call_606713.base,
                         call_606713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606713, url, valid)

proc call*(call_606714: Call_GetDescribeDomains_606700;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606715 = newJObject()
  if DomainNames != nil:
    query_606715.add "DomainNames", DomainNames
  add(query_606715, "Action", newJString(Action))
  add(query_606715, "Version", newJString(Version))
  result = call_606714.call(nil, query_606715, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_606700(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_606701, base: "/",
    url: url_GetDescribeDomains_606702, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeExpressions_606751 = ref object of OpenApiRestCall_605589
proc url_PostDescribeExpressions_606753(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeExpressions_606752(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606754 = query.getOrDefault("Action")
  valid_606754 = validateParameter(valid_606754, JString, required = true,
                                 default = newJString("DescribeExpressions"))
  if valid_606754 != nil:
    section.add "Action", valid_606754
  var valid_606755 = query.getOrDefault("Version")
  valid_606755 = validateParameter(valid_606755, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606755 != nil:
    section.add "Version", valid_606755
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
  var valid_606756 = header.getOrDefault("X-Amz-Signature")
  valid_606756 = validateParameter(valid_606756, JString, required = false,
                                 default = nil)
  if valid_606756 != nil:
    section.add "X-Amz-Signature", valid_606756
  var valid_606757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606757 = validateParameter(valid_606757, JString, required = false,
                                 default = nil)
  if valid_606757 != nil:
    section.add "X-Amz-Content-Sha256", valid_606757
  var valid_606758 = header.getOrDefault("X-Amz-Date")
  valid_606758 = validateParameter(valid_606758, JString, required = false,
                                 default = nil)
  if valid_606758 != nil:
    section.add "X-Amz-Date", valid_606758
  var valid_606759 = header.getOrDefault("X-Amz-Credential")
  valid_606759 = validateParameter(valid_606759, JString, required = false,
                                 default = nil)
  if valid_606759 != nil:
    section.add "X-Amz-Credential", valid_606759
  var valid_606760 = header.getOrDefault("X-Amz-Security-Token")
  valid_606760 = validateParameter(valid_606760, JString, required = false,
                                 default = nil)
  if valid_606760 != nil:
    section.add "X-Amz-Security-Token", valid_606760
  var valid_606761 = header.getOrDefault("X-Amz-Algorithm")
  valid_606761 = validateParameter(valid_606761, JString, required = false,
                                 default = nil)
  if valid_606761 != nil:
    section.add "X-Amz-Algorithm", valid_606761
  var valid_606762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606762 = validateParameter(valid_606762, JString, required = false,
                                 default = nil)
  if valid_606762 != nil:
    section.add "X-Amz-SignedHeaders", valid_606762
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  section = newJObject()
  var valid_606763 = formData.getOrDefault("Deployed")
  valid_606763 = validateParameter(valid_606763, JBool, required = false, default = nil)
  if valid_606763 != nil:
    section.add "Deployed", valid_606763
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606764 = formData.getOrDefault("DomainName")
  valid_606764 = validateParameter(valid_606764, JString, required = true,
                                 default = nil)
  if valid_606764 != nil:
    section.add "DomainName", valid_606764
  var valid_606765 = formData.getOrDefault("ExpressionNames")
  valid_606765 = validateParameter(valid_606765, JArray, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "ExpressionNames", valid_606765
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606766: Call_PostDescribeExpressions_606751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606766.validator(path, query, header, formData, body)
  let scheme = call_606766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606766.url(scheme.get, call_606766.host, call_606766.base,
                         call_606766.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606766, url, valid)

proc call*(call_606767: Call_PostDescribeExpressions_606751; DomainName: string;
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
  var query_606768 = newJObject()
  var formData_606769 = newJObject()
  add(formData_606769, "Deployed", newJBool(Deployed))
  add(formData_606769, "DomainName", newJString(DomainName))
  add(query_606768, "Action", newJString(Action))
  if ExpressionNames != nil:
    formData_606769.add "ExpressionNames", ExpressionNames
  add(query_606768, "Version", newJString(Version))
  result = call_606767.call(nil, query_606768, nil, formData_606769, nil)

var postDescribeExpressions* = Call_PostDescribeExpressions_606751(
    name: "postDescribeExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_PostDescribeExpressions_606752, base: "/",
    url: url_PostDescribeExpressions_606753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeExpressions_606733 = ref object of OpenApiRestCall_605589
proc url_GetDescribeExpressions_606735(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeExpressions_606734(path: JsonNode; query: JsonNode;
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
  var valid_606736 = query.getOrDefault("ExpressionNames")
  valid_606736 = validateParameter(valid_606736, JArray, required = false,
                                 default = nil)
  if valid_606736 != nil:
    section.add "ExpressionNames", valid_606736
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_606737 = query.getOrDefault("DomainName")
  valid_606737 = validateParameter(valid_606737, JString, required = true,
                                 default = nil)
  if valid_606737 != nil:
    section.add "DomainName", valid_606737
  var valid_606738 = query.getOrDefault("Deployed")
  valid_606738 = validateParameter(valid_606738, JBool, required = false, default = nil)
  if valid_606738 != nil:
    section.add "Deployed", valid_606738
  var valid_606739 = query.getOrDefault("Action")
  valid_606739 = validateParameter(valid_606739, JString, required = true,
                                 default = newJString("DescribeExpressions"))
  if valid_606739 != nil:
    section.add "Action", valid_606739
  var valid_606740 = query.getOrDefault("Version")
  valid_606740 = validateParameter(valid_606740, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606740 != nil:
    section.add "Version", valid_606740
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
  var valid_606741 = header.getOrDefault("X-Amz-Signature")
  valid_606741 = validateParameter(valid_606741, JString, required = false,
                                 default = nil)
  if valid_606741 != nil:
    section.add "X-Amz-Signature", valid_606741
  var valid_606742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606742 = validateParameter(valid_606742, JString, required = false,
                                 default = nil)
  if valid_606742 != nil:
    section.add "X-Amz-Content-Sha256", valid_606742
  var valid_606743 = header.getOrDefault("X-Amz-Date")
  valid_606743 = validateParameter(valid_606743, JString, required = false,
                                 default = nil)
  if valid_606743 != nil:
    section.add "X-Amz-Date", valid_606743
  var valid_606744 = header.getOrDefault("X-Amz-Credential")
  valid_606744 = validateParameter(valid_606744, JString, required = false,
                                 default = nil)
  if valid_606744 != nil:
    section.add "X-Amz-Credential", valid_606744
  var valid_606745 = header.getOrDefault("X-Amz-Security-Token")
  valid_606745 = validateParameter(valid_606745, JString, required = false,
                                 default = nil)
  if valid_606745 != nil:
    section.add "X-Amz-Security-Token", valid_606745
  var valid_606746 = header.getOrDefault("X-Amz-Algorithm")
  valid_606746 = validateParameter(valid_606746, JString, required = false,
                                 default = nil)
  if valid_606746 != nil:
    section.add "X-Amz-Algorithm", valid_606746
  var valid_606747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = nil)
  if valid_606747 != nil:
    section.add "X-Amz-SignedHeaders", valid_606747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606748: Call_GetDescribeExpressions_606733; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606748.validator(path, query, header, formData, body)
  let scheme = call_606748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606748.url(scheme.get, call_606748.host, call_606748.base,
                         call_606748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606748, url, valid)

proc call*(call_606749: Call_GetDescribeExpressions_606733; DomainName: string;
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
  var query_606750 = newJObject()
  if ExpressionNames != nil:
    query_606750.add "ExpressionNames", ExpressionNames
  add(query_606750, "DomainName", newJString(DomainName))
  add(query_606750, "Deployed", newJBool(Deployed))
  add(query_606750, "Action", newJString(Action))
  add(query_606750, "Version", newJString(Version))
  result = call_606749.call(nil, query_606750, nil, nil, nil)

var getDescribeExpressions* = Call_GetDescribeExpressions_606733(
    name: "getDescribeExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_GetDescribeExpressions_606734, base: "/",
    url: url_GetDescribeExpressions_606735, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_606788 = ref object of OpenApiRestCall_605589
proc url_PostDescribeIndexFields_606790(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeIndexFields_606789(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606791 = query.getOrDefault("Action")
  valid_606791 = validateParameter(valid_606791, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_606791 != nil:
    section.add "Action", valid_606791
  var valid_606792 = query.getOrDefault("Version")
  valid_606792 = validateParameter(valid_606792, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606792 != nil:
    section.add "Version", valid_606792
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
  var valid_606793 = header.getOrDefault("X-Amz-Signature")
  valid_606793 = validateParameter(valid_606793, JString, required = false,
                                 default = nil)
  if valid_606793 != nil:
    section.add "X-Amz-Signature", valid_606793
  var valid_606794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606794 = validateParameter(valid_606794, JString, required = false,
                                 default = nil)
  if valid_606794 != nil:
    section.add "X-Amz-Content-Sha256", valid_606794
  var valid_606795 = header.getOrDefault("X-Amz-Date")
  valid_606795 = validateParameter(valid_606795, JString, required = false,
                                 default = nil)
  if valid_606795 != nil:
    section.add "X-Amz-Date", valid_606795
  var valid_606796 = header.getOrDefault("X-Amz-Credential")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-Credential", valid_606796
  var valid_606797 = header.getOrDefault("X-Amz-Security-Token")
  valid_606797 = validateParameter(valid_606797, JString, required = false,
                                 default = nil)
  if valid_606797 != nil:
    section.add "X-Amz-Security-Token", valid_606797
  var valid_606798 = header.getOrDefault("X-Amz-Algorithm")
  valid_606798 = validateParameter(valid_606798, JString, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "X-Amz-Algorithm", valid_606798
  var valid_606799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606799 = validateParameter(valid_606799, JString, required = false,
                                 default = nil)
  if valid_606799 != nil:
    section.add "X-Amz-SignedHeaders", valid_606799
  result.add "header", section
  ## parameters in `formData` object:
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_606800 = formData.getOrDefault("FieldNames")
  valid_606800 = validateParameter(valid_606800, JArray, required = false,
                                 default = nil)
  if valid_606800 != nil:
    section.add "FieldNames", valid_606800
  var valid_606801 = formData.getOrDefault("Deployed")
  valid_606801 = validateParameter(valid_606801, JBool, required = false, default = nil)
  if valid_606801 != nil:
    section.add "Deployed", valid_606801
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606802 = formData.getOrDefault("DomainName")
  valid_606802 = validateParameter(valid_606802, JString, required = true,
                                 default = nil)
  if valid_606802 != nil:
    section.add "DomainName", valid_606802
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606803: Call_PostDescribeIndexFields_606788; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606803.validator(path, query, header, formData, body)
  let scheme = call_606803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606803.url(scheme.get, call_606803.host, call_606803.base,
                         call_606803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606803, url, valid)

proc call*(call_606804: Call_PostDescribeIndexFields_606788; DomainName: string;
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
  var query_606805 = newJObject()
  var formData_606806 = newJObject()
  if FieldNames != nil:
    formData_606806.add "FieldNames", FieldNames
  add(formData_606806, "Deployed", newJBool(Deployed))
  add(formData_606806, "DomainName", newJString(DomainName))
  add(query_606805, "Action", newJString(Action))
  add(query_606805, "Version", newJString(Version))
  result = call_606804.call(nil, query_606805, nil, formData_606806, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_606788(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_606789, base: "/",
    url: url_PostDescribeIndexFields_606790, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_606770 = ref object of OpenApiRestCall_605589
proc url_GetDescribeIndexFields_606772(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeIndexFields_606771(path: JsonNode; query: JsonNode;
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
  var valid_606773 = query.getOrDefault("DomainName")
  valid_606773 = validateParameter(valid_606773, JString, required = true,
                                 default = nil)
  if valid_606773 != nil:
    section.add "DomainName", valid_606773
  var valid_606774 = query.getOrDefault("Deployed")
  valid_606774 = validateParameter(valid_606774, JBool, required = false, default = nil)
  if valid_606774 != nil:
    section.add "Deployed", valid_606774
  var valid_606775 = query.getOrDefault("Action")
  valid_606775 = validateParameter(valid_606775, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_606775 != nil:
    section.add "Action", valid_606775
  var valid_606776 = query.getOrDefault("Version")
  valid_606776 = validateParameter(valid_606776, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606776 != nil:
    section.add "Version", valid_606776
  var valid_606777 = query.getOrDefault("FieldNames")
  valid_606777 = validateParameter(valid_606777, JArray, required = false,
                                 default = nil)
  if valid_606777 != nil:
    section.add "FieldNames", valid_606777
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
  var valid_606778 = header.getOrDefault("X-Amz-Signature")
  valid_606778 = validateParameter(valid_606778, JString, required = false,
                                 default = nil)
  if valid_606778 != nil:
    section.add "X-Amz-Signature", valid_606778
  var valid_606779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606779 = validateParameter(valid_606779, JString, required = false,
                                 default = nil)
  if valid_606779 != nil:
    section.add "X-Amz-Content-Sha256", valid_606779
  var valid_606780 = header.getOrDefault("X-Amz-Date")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "X-Amz-Date", valid_606780
  var valid_606781 = header.getOrDefault("X-Amz-Credential")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-Credential", valid_606781
  var valid_606782 = header.getOrDefault("X-Amz-Security-Token")
  valid_606782 = validateParameter(valid_606782, JString, required = false,
                                 default = nil)
  if valid_606782 != nil:
    section.add "X-Amz-Security-Token", valid_606782
  var valid_606783 = header.getOrDefault("X-Amz-Algorithm")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "X-Amz-Algorithm", valid_606783
  var valid_606784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606784 = validateParameter(valid_606784, JString, required = false,
                                 default = nil)
  if valid_606784 != nil:
    section.add "X-Amz-SignedHeaders", valid_606784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606785: Call_GetDescribeIndexFields_606770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606785.validator(path, query, header, formData, body)
  let scheme = call_606785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606785.url(scheme.get, call_606785.host, call_606785.base,
                         call_606785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606785, url, valid)

proc call*(call_606786: Call_GetDescribeIndexFields_606770; DomainName: string;
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
  var query_606787 = newJObject()
  add(query_606787, "DomainName", newJString(DomainName))
  add(query_606787, "Deployed", newJBool(Deployed))
  add(query_606787, "Action", newJString(Action))
  add(query_606787, "Version", newJString(Version))
  if FieldNames != nil:
    query_606787.add "FieldNames", FieldNames
  result = call_606786.call(nil, query_606787, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_606770(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_606771, base: "/",
    url: url_GetDescribeIndexFields_606772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeScalingParameters_606823 = ref object of OpenApiRestCall_605589
proc url_PostDescribeScalingParameters_606825(protocol: Scheme; host: string;
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

proc validate_PostDescribeScalingParameters_606824(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606826 = query.getOrDefault("Action")
  valid_606826 = validateParameter(valid_606826, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_606826 != nil:
    section.add "Action", valid_606826
  var valid_606827 = query.getOrDefault("Version")
  valid_606827 = validateParameter(valid_606827, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606827 != nil:
    section.add "Version", valid_606827
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
  var valid_606828 = header.getOrDefault("X-Amz-Signature")
  valid_606828 = validateParameter(valid_606828, JString, required = false,
                                 default = nil)
  if valid_606828 != nil:
    section.add "X-Amz-Signature", valid_606828
  var valid_606829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606829 = validateParameter(valid_606829, JString, required = false,
                                 default = nil)
  if valid_606829 != nil:
    section.add "X-Amz-Content-Sha256", valid_606829
  var valid_606830 = header.getOrDefault("X-Amz-Date")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "X-Amz-Date", valid_606830
  var valid_606831 = header.getOrDefault("X-Amz-Credential")
  valid_606831 = validateParameter(valid_606831, JString, required = false,
                                 default = nil)
  if valid_606831 != nil:
    section.add "X-Amz-Credential", valid_606831
  var valid_606832 = header.getOrDefault("X-Amz-Security-Token")
  valid_606832 = validateParameter(valid_606832, JString, required = false,
                                 default = nil)
  if valid_606832 != nil:
    section.add "X-Amz-Security-Token", valid_606832
  var valid_606833 = header.getOrDefault("X-Amz-Algorithm")
  valid_606833 = validateParameter(valid_606833, JString, required = false,
                                 default = nil)
  if valid_606833 != nil:
    section.add "X-Amz-Algorithm", valid_606833
  var valid_606834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606834 = validateParameter(valid_606834, JString, required = false,
                                 default = nil)
  if valid_606834 != nil:
    section.add "X-Amz-SignedHeaders", valid_606834
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606835 = formData.getOrDefault("DomainName")
  valid_606835 = validateParameter(valid_606835, JString, required = true,
                                 default = nil)
  if valid_606835 != nil:
    section.add "DomainName", valid_606835
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606836: Call_PostDescribeScalingParameters_606823; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606836.validator(path, query, header, formData, body)
  let scheme = call_606836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606836.url(scheme.get, call_606836.host, call_606836.base,
                         call_606836.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606836, url, valid)

proc call*(call_606837: Call_PostDescribeScalingParameters_606823;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606838 = newJObject()
  var formData_606839 = newJObject()
  add(formData_606839, "DomainName", newJString(DomainName))
  add(query_606838, "Action", newJString(Action))
  add(query_606838, "Version", newJString(Version))
  result = call_606837.call(nil, query_606838, nil, formData_606839, nil)

var postDescribeScalingParameters* = Call_PostDescribeScalingParameters_606823(
    name: "postDescribeScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_PostDescribeScalingParameters_606824, base: "/",
    url: url_PostDescribeScalingParameters_606825,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeScalingParameters_606807 = ref object of OpenApiRestCall_605589
proc url_GetDescribeScalingParameters_606809(protocol: Scheme; host: string;
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

proc validate_GetDescribeScalingParameters_606808(path: JsonNode; query: JsonNode;
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
  var valid_606810 = query.getOrDefault("DomainName")
  valid_606810 = validateParameter(valid_606810, JString, required = true,
                                 default = nil)
  if valid_606810 != nil:
    section.add "DomainName", valid_606810
  var valid_606811 = query.getOrDefault("Action")
  valid_606811 = validateParameter(valid_606811, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_606811 != nil:
    section.add "Action", valid_606811
  var valid_606812 = query.getOrDefault("Version")
  valid_606812 = validateParameter(valid_606812, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606812 != nil:
    section.add "Version", valid_606812
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
  var valid_606813 = header.getOrDefault("X-Amz-Signature")
  valid_606813 = validateParameter(valid_606813, JString, required = false,
                                 default = nil)
  if valid_606813 != nil:
    section.add "X-Amz-Signature", valid_606813
  var valid_606814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606814 = validateParameter(valid_606814, JString, required = false,
                                 default = nil)
  if valid_606814 != nil:
    section.add "X-Amz-Content-Sha256", valid_606814
  var valid_606815 = header.getOrDefault("X-Amz-Date")
  valid_606815 = validateParameter(valid_606815, JString, required = false,
                                 default = nil)
  if valid_606815 != nil:
    section.add "X-Amz-Date", valid_606815
  var valid_606816 = header.getOrDefault("X-Amz-Credential")
  valid_606816 = validateParameter(valid_606816, JString, required = false,
                                 default = nil)
  if valid_606816 != nil:
    section.add "X-Amz-Credential", valid_606816
  var valid_606817 = header.getOrDefault("X-Amz-Security-Token")
  valid_606817 = validateParameter(valid_606817, JString, required = false,
                                 default = nil)
  if valid_606817 != nil:
    section.add "X-Amz-Security-Token", valid_606817
  var valid_606818 = header.getOrDefault("X-Amz-Algorithm")
  valid_606818 = validateParameter(valid_606818, JString, required = false,
                                 default = nil)
  if valid_606818 != nil:
    section.add "X-Amz-Algorithm", valid_606818
  var valid_606819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606819 = validateParameter(valid_606819, JString, required = false,
                                 default = nil)
  if valid_606819 != nil:
    section.add "X-Amz-SignedHeaders", valid_606819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606820: Call_GetDescribeScalingParameters_606807; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606820.validator(path, query, header, formData, body)
  let scheme = call_606820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606820.url(scheme.get, call_606820.host, call_606820.base,
                         call_606820.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606820, url, valid)

proc call*(call_606821: Call_GetDescribeScalingParameters_606807;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606822 = newJObject()
  add(query_606822, "DomainName", newJString(DomainName))
  add(query_606822, "Action", newJString(Action))
  add(query_606822, "Version", newJString(Version))
  result = call_606821.call(nil, query_606822, nil, nil, nil)

var getDescribeScalingParameters* = Call_GetDescribeScalingParameters_606807(
    name: "getDescribeScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_GetDescribeScalingParameters_606808, base: "/",
    url: url_GetDescribeScalingParameters_606809,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_606857 = ref object of OpenApiRestCall_605589
proc url_PostDescribeServiceAccessPolicies_606859(protocol: Scheme; host: string;
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

proc validate_PostDescribeServiceAccessPolicies_606858(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606860 = query.getOrDefault("Action")
  valid_606860 = validateParameter(valid_606860, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_606860 != nil:
    section.add "Action", valid_606860
  var valid_606861 = query.getOrDefault("Version")
  valid_606861 = validateParameter(valid_606861, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606861 != nil:
    section.add "Version", valid_606861
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
  var valid_606862 = header.getOrDefault("X-Amz-Signature")
  valid_606862 = validateParameter(valid_606862, JString, required = false,
                                 default = nil)
  if valid_606862 != nil:
    section.add "X-Amz-Signature", valid_606862
  var valid_606863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606863 = validateParameter(valid_606863, JString, required = false,
                                 default = nil)
  if valid_606863 != nil:
    section.add "X-Amz-Content-Sha256", valid_606863
  var valid_606864 = header.getOrDefault("X-Amz-Date")
  valid_606864 = validateParameter(valid_606864, JString, required = false,
                                 default = nil)
  if valid_606864 != nil:
    section.add "X-Amz-Date", valid_606864
  var valid_606865 = header.getOrDefault("X-Amz-Credential")
  valid_606865 = validateParameter(valid_606865, JString, required = false,
                                 default = nil)
  if valid_606865 != nil:
    section.add "X-Amz-Credential", valid_606865
  var valid_606866 = header.getOrDefault("X-Amz-Security-Token")
  valid_606866 = validateParameter(valid_606866, JString, required = false,
                                 default = nil)
  if valid_606866 != nil:
    section.add "X-Amz-Security-Token", valid_606866
  var valid_606867 = header.getOrDefault("X-Amz-Algorithm")
  valid_606867 = validateParameter(valid_606867, JString, required = false,
                                 default = nil)
  if valid_606867 != nil:
    section.add "X-Amz-Algorithm", valid_606867
  var valid_606868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606868 = validateParameter(valid_606868, JString, required = false,
                                 default = nil)
  if valid_606868 != nil:
    section.add "X-Amz-SignedHeaders", valid_606868
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_606869 = formData.getOrDefault("Deployed")
  valid_606869 = validateParameter(valid_606869, JBool, required = false, default = nil)
  if valid_606869 != nil:
    section.add "Deployed", valid_606869
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606870 = formData.getOrDefault("DomainName")
  valid_606870 = validateParameter(valid_606870, JString, required = true,
                                 default = nil)
  if valid_606870 != nil:
    section.add "DomainName", valid_606870
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606871: Call_PostDescribeServiceAccessPolicies_606857;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606871.validator(path, query, header, formData, body)
  let scheme = call_606871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606871.url(scheme.get, call_606871.host, call_606871.base,
                         call_606871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606871, url, valid)

proc call*(call_606872: Call_PostDescribeServiceAccessPolicies_606857;
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
  var query_606873 = newJObject()
  var formData_606874 = newJObject()
  add(formData_606874, "Deployed", newJBool(Deployed))
  add(formData_606874, "DomainName", newJString(DomainName))
  add(query_606873, "Action", newJString(Action))
  add(query_606873, "Version", newJString(Version))
  result = call_606872.call(nil, query_606873, nil, formData_606874, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_606857(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_606858, base: "/",
    url: url_PostDescribeServiceAccessPolicies_606859,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_606840 = ref object of OpenApiRestCall_605589
proc url_GetDescribeServiceAccessPolicies_606842(protocol: Scheme; host: string;
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

proc validate_GetDescribeServiceAccessPolicies_606841(path: JsonNode;
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
  var valid_606843 = query.getOrDefault("DomainName")
  valid_606843 = validateParameter(valid_606843, JString, required = true,
                                 default = nil)
  if valid_606843 != nil:
    section.add "DomainName", valid_606843
  var valid_606844 = query.getOrDefault("Deployed")
  valid_606844 = validateParameter(valid_606844, JBool, required = false, default = nil)
  if valid_606844 != nil:
    section.add "Deployed", valid_606844
  var valid_606845 = query.getOrDefault("Action")
  valid_606845 = validateParameter(valid_606845, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_606845 != nil:
    section.add "Action", valid_606845
  var valid_606846 = query.getOrDefault("Version")
  valid_606846 = validateParameter(valid_606846, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606846 != nil:
    section.add "Version", valid_606846
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
  var valid_606847 = header.getOrDefault("X-Amz-Signature")
  valid_606847 = validateParameter(valid_606847, JString, required = false,
                                 default = nil)
  if valid_606847 != nil:
    section.add "X-Amz-Signature", valid_606847
  var valid_606848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606848 = validateParameter(valid_606848, JString, required = false,
                                 default = nil)
  if valid_606848 != nil:
    section.add "X-Amz-Content-Sha256", valid_606848
  var valid_606849 = header.getOrDefault("X-Amz-Date")
  valid_606849 = validateParameter(valid_606849, JString, required = false,
                                 default = nil)
  if valid_606849 != nil:
    section.add "X-Amz-Date", valid_606849
  var valid_606850 = header.getOrDefault("X-Amz-Credential")
  valid_606850 = validateParameter(valid_606850, JString, required = false,
                                 default = nil)
  if valid_606850 != nil:
    section.add "X-Amz-Credential", valid_606850
  var valid_606851 = header.getOrDefault("X-Amz-Security-Token")
  valid_606851 = validateParameter(valid_606851, JString, required = false,
                                 default = nil)
  if valid_606851 != nil:
    section.add "X-Amz-Security-Token", valid_606851
  var valid_606852 = header.getOrDefault("X-Amz-Algorithm")
  valid_606852 = validateParameter(valid_606852, JString, required = false,
                                 default = nil)
  if valid_606852 != nil:
    section.add "X-Amz-Algorithm", valid_606852
  var valid_606853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606853 = validateParameter(valid_606853, JString, required = false,
                                 default = nil)
  if valid_606853 != nil:
    section.add "X-Amz-SignedHeaders", valid_606853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606854: Call_GetDescribeServiceAccessPolicies_606840;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606854.validator(path, query, header, formData, body)
  let scheme = call_606854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606854.url(scheme.get, call_606854.host, call_606854.base,
                         call_606854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606854, url, valid)

proc call*(call_606855: Call_GetDescribeServiceAccessPolicies_606840;
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
  var query_606856 = newJObject()
  add(query_606856, "DomainName", newJString(DomainName))
  add(query_606856, "Deployed", newJBool(Deployed))
  add(query_606856, "Action", newJString(Action))
  add(query_606856, "Version", newJString(Version))
  result = call_606855.call(nil, query_606856, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_606840(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_606841, base: "/",
    url: url_GetDescribeServiceAccessPolicies_606842,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSuggesters_606893 = ref object of OpenApiRestCall_605589
proc url_PostDescribeSuggesters_606895(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeSuggesters_606894(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606896 = query.getOrDefault("Action")
  valid_606896 = validateParameter(valid_606896, JString, required = true,
                                 default = newJString("DescribeSuggesters"))
  if valid_606896 != nil:
    section.add "Action", valid_606896
  var valid_606897 = query.getOrDefault("Version")
  valid_606897 = validateParameter(valid_606897, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606897 != nil:
    section.add "Version", valid_606897
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
  var valid_606898 = header.getOrDefault("X-Amz-Signature")
  valid_606898 = validateParameter(valid_606898, JString, required = false,
                                 default = nil)
  if valid_606898 != nil:
    section.add "X-Amz-Signature", valid_606898
  var valid_606899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606899 = validateParameter(valid_606899, JString, required = false,
                                 default = nil)
  if valid_606899 != nil:
    section.add "X-Amz-Content-Sha256", valid_606899
  var valid_606900 = header.getOrDefault("X-Amz-Date")
  valid_606900 = validateParameter(valid_606900, JString, required = false,
                                 default = nil)
  if valid_606900 != nil:
    section.add "X-Amz-Date", valid_606900
  var valid_606901 = header.getOrDefault("X-Amz-Credential")
  valid_606901 = validateParameter(valid_606901, JString, required = false,
                                 default = nil)
  if valid_606901 != nil:
    section.add "X-Amz-Credential", valid_606901
  var valid_606902 = header.getOrDefault("X-Amz-Security-Token")
  valid_606902 = validateParameter(valid_606902, JString, required = false,
                                 default = nil)
  if valid_606902 != nil:
    section.add "X-Amz-Security-Token", valid_606902
  var valid_606903 = header.getOrDefault("X-Amz-Algorithm")
  valid_606903 = validateParameter(valid_606903, JString, required = false,
                                 default = nil)
  if valid_606903 != nil:
    section.add "X-Amz-Algorithm", valid_606903
  var valid_606904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606904 = validateParameter(valid_606904, JString, required = false,
                                 default = nil)
  if valid_606904 != nil:
    section.add "X-Amz-SignedHeaders", valid_606904
  result.add "header", section
  ## parameters in `formData` object:
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_606905 = formData.getOrDefault("SuggesterNames")
  valid_606905 = validateParameter(valid_606905, JArray, required = false,
                                 default = nil)
  if valid_606905 != nil:
    section.add "SuggesterNames", valid_606905
  var valid_606906 = formData.getOrDefault("Deployed")
  valid_606906 = validateParameter(valid_606906, JBool, required = false, default = nil)
  if valid_606906 != nil:
    section.add "Deployed", valid_606906
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606907 = formData.getOrDefault("DomainName")
  valid_606907 = validateParameter(valid_606907, JString, required = true,
                                 default = nil)
  if valid_606907 != nil:
    section.add "DomainName", valid_606907
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606908: Call_PostDescribeSuggesters_606893; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606908.validator(path, query, header, formData, body)
  let scheme = call_606908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606908.url(scheme.get, call_606908.host, call_606908.base,
                         call_606908.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606908, url, valid)

proc call*(call_606909: Call_PostDescribeSuggesters_606893; DomainName: string;
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
  var query_606910 = newJObject()
  var formData_606911 = newJObject()
  if SuggesterNames != nil:
    formData_606911.add "SuggesterNames", SuggesterNames
  add(formData_606911, "Deployed", newJBool(Deployed))
  add(formData_606911, "DomainName", newJString(DomainName))
  add(query_606910, "Action", newJString(Action))
  add(query_606910, "Version", newJString(Version))
  result = call_606909.call(nil, query_606910, nil, formData_606911, nil)

var postDescribeSuggesters* = Call_PostDescribeSuggesters_606893(
    name: "postDescribeSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_PostDescribeSuggesters_606894, base: "/",
    url: url_PostDescribeSuggesters_606895, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSuggesters_606875 = ref object of OpenApiRestCall_605589
proc url_GetDescribeSuggesters_606877(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeSuggesters_606876(path: JsonNode; query: JsonNode;
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
  var valid_606878 = query.getOrDefault("DomainName")
  valid_606878 = validateParameter(valid_606878, JString, required = true,
                                 default = nil)
  if valid_606878 != nil:
    section.add "DomainName", valid_606878
  var valid_606879 = query.getOrDefault("Deployed")
  valid_606879 = validateParameter(valid_606879, JBool, required = false, default = nil)
  if valid_606879 != nil:
    section.add "Deployed", valid_606879
  var valid_606880 = query.getOrDefault("Action")
  valid_606880 = validateParameter(valid_606880, JString, required = true,
                                 default = newJString("DescribeSuggesters"))
  if valid_606880 != nil:
    section.add "Action", valid_606880
  var valid_606881 = query.getOrDefault("Version")
  valid_606881 = validateParameter(valid_606881, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606881 != nil:
    section.add "Version", valid_606881
  var valid_606882 = query.getOrDefault("SuggesterNames")
  valid_606882 = validateParameter(valid_606882, JArray, required = false,
                                 default = nil)
  if valid_606882 != nil:
    section.add "SuggesterNames", valid_606882
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
  var valid_606883 = header.getOrDefault("X-Amz-Signature")
  valid_606883 = validateParameter(valid_606883, JString, required = false,
                                 default = nil)
  if valid_606883 != nil:
    section.add "X-Amz-Signature", valid_606883
  var valid_606884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606884 = validateParameter(valid_606884, JString, required = false,
                                 default = nil)
  if valid_606884 != nil:
    section.add "X-Amz-Content-Sha256", valid_606884
  var valid_606885 = header.getOrDefault("X-Amz-Date")
  valid_606885 = validateParameter(valid_606885, JString, required = false,
                                 default = nil)
  if valid_606885 != nil:
    section.add "X-Amz-Date", valid_606885
  var valid_606886 = header.getOrDefault("X-Amz-Credential")
  valid_606886 = validateParameter(valid_606886, JString, required = false,
                                 default = nil)
  if valid_606886 != nil:
    section.add "X-Amz-Credential", valid_606886
  var valid_606887 = header.getOrDefault("X-Amz-Security-Token")
  valid_606887 = validateParameter(valid_606887, JString, required = false,
                                 default = nil)
  if valid_606887 != nil:
    section.add "X-Amz-Security-Token", valid_606887
  var valid_606888 = header.getOrDefault("X-Amz-Algorithm")
  valid_606888 = validateParameter(valid_606888, JString, required = false,
                                 default = nil)
  if valid_606888 != nil:
    section.add "X-Amz-Algorithm", valid_606888
  var valid_606889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606889 = validateParameter(valid_606889, JString, required = false,
                                 default = nil)
  if valid_606889 != nil:
    section.add "X-Amz-SignedHeaders", valid_606889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606890: Call_GetDescribeSuggesters_606875; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606890.validator(path, query, header, formData, body)
  let scheme = call_606890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606890.url(scheme.get, call_606890.host, call_606890.base,
                         call_606890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606890, url, valid)

proc call*(call_606891: Call_GetDescribeSuggesters_606875; DomainName: string;
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
  var query_606892 = newJObject()
  add(query_606892, "DomainName", newJString(DomainName))
  add(query_606892, "Deployed", newJBool(Deployed))
  add(query_606892, "Action", newJString(Action))
  add(query_606892, "Version", newJString(Version))
  if SuggesterNames != nil:
    query_606892.add "SuggesterNames", SuggesterNames
  result = call_606891.call(nil, query_606892, nil, nil, nil)

var getDescribeSuggesters* = Call_GetDescribeSuggesters_606875(
    name: "getDescribeSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_GetDescribeSuggesters_606876, base: "/",
    url: url_GetDescribeSuggesters_606877, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_606928 = ref object of OpenApiRestCall_605589
proc url_PostIndexDocuments_606930(protocol: Scheme; host: string; base: string;
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

proc validate_PostIndexDocuments_606929(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606931 = query.getOrDefault("Action")
  valid_606931 = validateParameter(valid_606931, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_606931 != nil:
    section.add "Action", valid_606931
  var valid_606932 = query.getOrDefault("Version")
  valid_606932 = validateParameter(valid_606932, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606932 != nil:
    section.add "Version", valid_606932
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
  var valid_606933 = header.getOrDefault("X-Amz-Signature")
  valid_606933 = validateParameter(valid_606933, JString, required = false,
                                 default = nil)
  if valid_606933 != nil:
    section.add "X-Amz-Signature", valid_606933
  var valid_606934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606934 = validateParameter(valid_606934, JString, required = false,
                                 default = nil)
  if valid_606934 != nil:
    section.add "X-Amz-Content-Sha256", valid_606934
  var valid_606935 = header.getOrDefault("X-Amz-Date")
  valid_606935 = validateParameter(valid_606935, JString, required = false,
                                 default = nil)
  if valid_606935 != nil:
    section.add "X-Amz-Date", valid_606935
  var valid_606936 = header.getOrDefault("X-Amz-Credential")
  valid_606936 = validateParameter(valid_606936, JString, required = false,
                                 default = nil)
  if valid_606936 != nil:
    section.add "X-Amz-Credential", valid_606936
  var valid_606937 = header.getOrDefault("X-Amz-Security-Token")
  valid_606937 = validateParameter(valid_606937, JString, required = false,
                                 default = nil)
  if valid_606937 != nil:
    section.add "X-Amz-Security-Token", valid_606937
  var valid_606938 = header.getOrDefault("X-Amz-Algorithm")
  valid_606938 = validateParameter(valid_606938, JString, required = false,
                                 default = nil)
  if valid_606938 != nil:
    section.add "X-Amz-Algorithm", valid_606938
  var valid_606939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606939 = validateParameter(valid_606939, JString, required = false,
                                 default = nil)
  if valid_606939 != nil:
    section.add "X-Amz-SignedHeaders", valid_606939
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606940 = formData.getOrDefault("DomainName")
  valid_606940 = validateParameter(valid_606940, JString, required = true,
                                 default = nil)
  if valid_606940 != nil:
    section.add "DomainName", valid_606940
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606941: Call_PostIndexDocuments_606928; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_606941.validator(path, query, header, formData, body)
  let scheme = call_606941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606941.url(scheme.get, call_606941.host, call_606941.base,
                         call_606941.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606941, url, valid)

proc call*(call_606942: Call_PostIndexDocuments_606928; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606943 = newJObject()
  var formData_606944 = newJObject()
  add(formData_606944, "DomainName", newJString(DomainName))
  add(query_606943, "Action", newJString(Action))
  add(query_606943, "Version", newJString(Version))
  result = call_606942.call(nil, query_606943, nil, formData_606944, nil)

var postIndexDocuments* = Call_PostIndexDocuments_606928(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_606929, base: "/",
    url: url_PostIndexDocuments_606930, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_606912 = ref object of OpenApiRestCall_605589
proc url_GetIndexDocuments_606914(protocol: Scheme; host: string; base: string;
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

proc validate_GetIndexDocuments_606913(path: JsonNode; query: JsonNode;
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
  var valid_606915 = query.getOrDefault("DomainName")
  valid_606915 = validateParameter(valid_606915, JString, required = true,
                                 default = nil)
  if valid_606915 != nil:
    section.add "DomainName", valid_606915
  var valid_606916 = query.getOrDefault("Action")
  valid_606916 = validateParameter(valid_606916, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_606916 != nil:
    section.add "Action", valid_606916
  var valid_606917 = query.getOrDefault("Version")
  valid_606917 = validateParameter(valid_606917, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606917 != nil:
    section.add "Version", valid_606917
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
  var valid_606918 = header.getOrDefault("X-Amz-Signature")
  valid_606918 = validateParameter(valid_606918, JString, required = false,
                                 default = nil)
  if valid_606918 != nil:
    section.add "X-Amz-Signature", valid_606918
  var valid_606919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606919 = validateParameter(valid_606919, JString, required = false,
                                 default = nil)
  if valid_606919 != nil:
    section.add "X-Amz-Content-Sha256", valid_606919
  var valid_606920 = header.getOrDefault("X-Amz-Date")
  valid_606920 = validateParameter(valid_606920, JString, required = false,
                                 default = nil)
  if valid_606920 != nil:
    section.add "X-Amz-Date", valid_606920
  var valid_606921 = header.getOrDefault("X-Amz-Credential")
  valid_606921 = validateParameter(valid_606921, JString, required = false,
                                 default = nil)
  if valid_606921 != nil:
    section.add "X-Amz-Credential", valid_606921
  var valid_606922 = header.getOrDefault("X-Amz-Security-Token")
  valid_606922 = validateParameter(valid_606922, JString, required = false,
                                 default = nil)
  if valid_606922 != nil:
    section.add "X-Amz-Security-Token", valid_606922
  var valid_606923 = header.getOrDefault("X-Amz-Algorithm")
  valid_606923 = validateParameter(valid_606923, JString, required = false,
                                 default = nil)
  if valid_606923 != nil:
    section.add "X-Amz-Algorithm", valid_606923
  var valid_606924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606924 = validateParameter(valid_606924, JString, required = false,
                                 default = nil)
  if valid_606924 != nil:
    section.add "X-Amz-SignedHeaders", valid_606924
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606925: Call_GetIndexDocuments_606912; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_606925.validator(path, query, header, formData, body)
  let scheme = call_606925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606925.url(scheme.get, call_606925.host, call_606925.base,
                         call_606925.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606925, url, valid)

proc call*(call_606926: Call_GetIndexDocuments_606912; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606927 = newJObject()
  add(query_606927, "DomainName", newJString(DomainName))
  add(query_606927, "Action", newJString(Action))
  add(query_606927, "Version", newJString(Version))
  result = call_606926.call(nil, query_606927, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_606912(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_606913,
    base: "/", url: url_GetIndexDocuments_606914,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomainNames_606960 = ref object of OpenApiRestCall_605589
proc url_PostListDomainNames_606962(protocol: Scheme; host: string; base: string;
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

proc validate_PostListDomainNames_606961(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606963 = query.getOrDefault("Action")
  valid_606963 = validateParameter(valid_606963, JString, required = true,
                                 default = newJString("ListDomainNames"))
  if valid_606963 != nil:
    section.add "Action", valid_606963
  var valid_606964 = query.getOrDefault("Version")
  valid_606964 = validateParameter(valid_606964, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606964 != nil:
    section.add "Version", valid_606964
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
  var valid_606965 = header.getOrDefault("X-Amz-Signature")
  valid_606965 = validateParameter(valid_606965, JString, required = false,
                                 default = nil)
  if valid_606965 != nil:
    section.add "X-Amz-Signature", valid_606965
  var valid_606966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606966 = validateParameter(valid_606966, JString, required = false,
                                 default = nil)
  if valid_606966 != nil:
    section.add "X-Amz-Content-Sha256", valid_606966
  var valid_606967 = header.getOrDefault("X-Amz-Date")
  valid_606967 = validateParameter(valid_606967, JString, required = false,
                                 default = nil)
  if valid_606967 != nil:
    section.add "X-Amz-Date", valid_606967
  var valid_606968 = header.getOrDefault("X-Amz-Credential")
  valid_606968 = validateParameter(valid_606968, JString, required = false,
                                 default = nil)
  if valid_606968 != nil:
    section.add "X-Amz-Credential", valid_606968
  var valid_606969 = header.getOrDefault("X-Amz-Security-Token")
  valid_606969 = validateParameter(valid_606969, JString, required = false,
                                 default = nil)
  if valid_606969 != nil:
    section.add "X-Amz-Security-Token", valid_606969
  var valid_606970 = header.getOrDefault("X-Amz-Algorithm")
  valid_606970 = validateParameter(valid_606970, JString, required = false,
                                 default = nil)
  if valid_606970 != nil:
    section.add "X-Amz-Algorithm", valid_606970
  var valid_606971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606971 = validateParameter(valid_606971, JString, required = false,
                                 default = nil)
  if valid_606971 != nil:
    section.add "X-Amz-SignedHeaders", valid_606971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606972: Call_PostListDomainNames_606960; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_606972.validator(path, query, header, formData, body)
  let scheme = call_606972.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606972.url(scheme.get, call_606972.host, call_606972.base,
                         call_606972.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606972, url, valid)

proc call*(call_606973: Call_PostListDomainNames_606960;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## postListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606974 = newJObject()
  add(query_606974, "Action", newJString(Action))
  add(query_606974, "Version", newJString(Version))
  result = call_606973.call(nil, query_606974, nil, nil, nil)

var postListDomainNames* = Call_PostListDomainNames_606960(
    name: "postListDomainNames", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_PostListDomainNames_606961, base: "/",
    url: url_PostListDomainNames_606962, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomainNames_606945 = ref object of OpenApiRestCall_605589
proc url_GetListDomainNames_606947(protocol: Scheme; host: string; base: string;
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

proc validate_GetListDomainNames_606946(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606948 = query.getOrDefault("Action")
  valid_606948 = validateParameter(valid_606948, JString, required = true,
                                 default = newJString("ListDomainNames"))
  if valid_606948 != nil:
    section.add "Action", valid_606948
  var valid_606949 = query.getOrDefault("Version")
  valid_606949 = validateParameter(valid_606949, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606949 != nil:
    section.add "Version", valid_606949
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
  var valid_606950 = header.getOrDefault("X-Amz-Signature")
  valid_606950 = validateParameter(valid_606950, JString, required = false,
                                 default = nil)
  if valid_606950 != nil:
    section.add "X-Amz-Signature", valid_606950
  var valid_606951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606951 = validateParameter(valid_606951, JString, required = false,
                                 default = nil)
  if valid_606951 != nil:
    section.add "X-Amz-Content-Sha256", valid_606951
  var valid_606952 = header.getOrDefault("X-Amz-Date")
  valid_606952 = validateParameter(valid_606952, JString, required = false,
                                 default = nil)
  if valid_606952 != nil:
    section.add "X-Amz-Date", valid_606952
  var valid_606953 = header.getOrDefault("X-Amz-Credential")
  valid_606953 = validateParameter(valid_606953, JString, required = false,
                                 default = nil)
  if valid_606953 != nil:
    section.add "X-Amz-Credential", valid_606953
  var valid_606954 = header.getOrDefault("X-Amz-Security-Token")
  valid_606954 = validateParameter(valid_606954, JString, required = false,
                                 default = nil)
  if valid_606954 != nil:
    section.add "X-Amz-Security-Token", valid_606954
  var valid_606955 = header.getOrDefault("X-Amz-Algorithm")
  valid_606955 = validateParameter(valid_606955, JString, required = false,
                                 default = nil)
  if valid_606955 != nil:
    section.add "X-Amz-Algorithm", valid_606955
  var valid_606956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606956 = validateParameter(valid_606956, JString, required = false,
                                 default = nil)
  if valid_606956 != nil:
    section.add "X-Amz-SignedHeaders", valid_606956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606957: Call_GetListDomainNames_606945; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_606957.validator(path, query, header, formData, body)
  let scheme = call_606957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606957.url(scheme.get, call_606957.host, call_606957.base,
                         call_606957.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606957, url, valid)

proc call*(call_606958: Call_GetListDomainNames_606945;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## getListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606959 = newJObject()
  add(query_606959, "Action", newJString(Action))
  add(query_606959, "Version", newJString(Version))
  result = call_606958.call(nil, query_606959, nil, nil, nil)

var getListDomainNames* = Call_GetListDomainNames_606945(
    name: "getListDomainNames", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_GetListDomainNames_606946, base: "/",
    url: url_GetListDomainNames_606947, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_606992 = ref object of OpenApiRestCall_605589
proc url_PostUpdateAvailabilityOptions_606994(protocol: Scheme; host: string;
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

proc validate_PostUpdateAvailabilityOptions_606993(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606995 = query.getOrDefault("Action")
  valid_606995 = validateParameter(valid_606995, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_606995 != nil:
    section.add "Action", valid_606995
  var valid_606996 = query.getOrDefault("Version")
  valid_606996 = validateParameter(valid_606996, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606996 != nil:
    section.add "Version", valid_606996
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
  var valid_606997 = header.getOrDefault("X-Amz-Signature")
  valid_606997 = validateParameter(valid_606997, JString, required = false,
                                 default = nil)
  if valid_606997 != nil:
    section.add "X-Amz-Signature", valid_606997
  var valid_606998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606998 = validateParameter(valid_606998, JString, required = false,
                                 default = nil)
  if valid_606998 != nil:
    section.add "X-Amz-Content-Sha256", valid_606998
  var valid_606999 = header.getOrDefault("X-Amz-Date")
  valid_606999 = validateParameter(valid_606999, JString, required = false,
                                 default = nil)
  if valid_606999 != nil:
    section.add "X-Amz-Date", valid_606999
  var valid_607000 = header.getOrDefault("X-Amz-Credential")
  valid_607000 = validateParameter(valid_607000, JString, required = false,
                                 default = nil)
  if valid_607000 != nil:
    section.add "X-Amz-Credential", valid_607000
  var valid_607001 = header.getOrDefault("X-Amz-Security-Token")
  valid_607001 = validateParameter(valid_607001, JString, required = false,
                                 default = nil)
  if valid_607001 != nil:
    section.add "X-Amz-Security-Token", valid_607001
  var valid_607002 = header.getOrDefault("X-Amz-Algorithm")
  valid_607002 = validateParameter(valid_607002, JString, required = false,
                                 default = nil)
  if valid_607002 != nil:
    section.add "X-Amz-Algorithm", valid_607002
  var valid_607003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607003 = validateParameter(valid_607003, JString, required = false,
                                 default = nil)
  if valid_607003 != nil:
    section.add "X-Amz-SignedHeaders", valid_607003
  result.add "header", section
  ## parameters in `formData` object:
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `MultiAZ` field"
  var valid_607004 = formData.getOrDefault("MultiAZ")
  valid_607004 = validateParameter(valid_607004, JBool, required = true, default = nil)
  if valid_607004 != nil:
    section.add "MultiAZ", valid_607004
  var valid_607005 = formData.getOrDefault("DomainName")
  valid_607005 = validateParameter(valid_607005, JString, required = true,
                                 default = nil)
  if valid_607005 != nil:
    section.add "DomainName", valid_607005
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607006: Call_PostUpdateAvailabilityOptions_606992; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_607006.validator(path, query, header, formData, body)
  let scheme = call_607006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607006.url(scheme.get, call_607006.host, call_607006.base,
                         call_607006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607006, url, valid)

proc call*(call_607007: Call_PostUpdateAvailabilityOptions_606992; MultiAZ: bool;
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
  var query_607008 = newJObject()
  var formData_607009 = newJObject()
  add(formData_607009, "MultiAZ", newJBool(MultiAZ))
  add(formData_607009, "DomainName", newJString(DomainName))
  add(query_607008, "Action", newJString(Action))
  add(query_607008, "Version", newJString(Version))
  result = call_607007.call(nil, query_607008, nil, formData_607009, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_606992(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_606993, base: "/",
    url: url_PostUpdateAvailabilityOptions_606994,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_606975 = ref object of OpenApiRestCall_605589
proc url_GetUpdateAvailabilityOptions_606977(protocol: Scheme; host: string;
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

proc validate_GetUpdateAvailabilityOptions_606976(path: JsonNode; query: JsonNode;
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
  var valid_606978 = query.getOrDefault("DomainName")
  valid_606978 = validateParameter(valid_606978, JString, required = true,
                                 default = nil)
  if valid_606978 != nil:
    section.add "DomainName", valid_606978
  var valid_606979 = query.getOrDefault("Action")
  valid_606979 = validateParameter(valid_606979, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_606979 != nil:
    section.add "Action", valid_606979
  var valid_606980 = query.getOrDefault("MultiAZ")
  valid_606980 = validateParameter(valid_606980, JBool, required = true, default = nil)
  if valid_606980 != nil:
    section.add "MultiAZ", valid_606980
  var valid_606981 = query.getOrDefault("Version")
  valid_606981 = validateParameter(valid_606981, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_606981 != nil:
    section.add "Version", valid_606981
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
  var valid_606982 = header.getOrDefault("X-Amz-Signature")
  valid_606982 = validateParameter(valid_606982, JString, required = false,
                                 default = nil)
  if valid_606982 != nil:
    section.add "X-Amz-Signature", valid_606982
  var valid_606983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606983 = validateParameter(valid_606983, JString, required = false,
                                 default = nil)
  if valid_606983 != nil:
    section.add "X-Amz-Content-Sha256", valid_606983
  var valid_606984 = header.getOrDefault("X-Amz-Date")
  valid_606984 = validateParameter(valid_606984, JString, required = false,
                                 default = nil)
  if valid_606984 != nil:
    section.add "X-Amz-Date", valid_606984
  var valid_606985 = header.getOrDefault("X-Amz-Credential")
  valid_606985 = validateParameter(valid_606985, JString, required = false,
                                 default = nil)
  if valid_606985 != nil:
    section.add "X-Amz-Credential", valid_606985
  var valid_606986 = header.getOrDefault("X-Amz-Security-Token")
  valid_606986 = validateParameter(valid_606986, JString, required = false,
                                 default = nil)
  if valid_606986 != nil:
    section.add "X-Amz-Security-Token", valid_606986
  var valid_606987 = header.getOrDefault("X-Amz-Algorithm")
  valid_606987 = validateParameter(valid_606987, JString, required = false,
                                 default = nil)
  if valid_606987 != nil:
    section.add "X-Amz-Algorithm", valid_606987
  var valid_606988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606988 = validateParameter(valid_606988, JString, required = false,
                                 default = nil)
  if valid_606988 != nil:
    section.add "X-Amz-SignedHeaders", valid_606988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606989: Call_GetUpdateAvailabilityOptions_606975; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606989.validator(path, query, header, formData, body)
  let scheme = call_606989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606989.url(scheme.get, call_606989.host, call_606989.base,
                         call_606989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606989, url, valid)

proc call*(call_606990: Call_GetUpdateAvailabilityOptions_606975;
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
  var query_606991 = newJObject()
  add(query_606991, "DomainName", newJString(DomainName))
  add(query_606991, "Action", newJString(Action))
  add(query_606991, "MultiAZ", newJBool(MultiAZ))
  add(query_606991, "Version", newJString(Version))
  result = call_606990.call(nil, query_606991, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_606975(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_606976, base: "/",
    url: url_GetUpdateAvailabilityOptions_606977,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateDomainEndpointOptions_607028 = ref object of OpenApiRestCall_605589
proc url_PostUpdateDomainEndpointOptions_607030(protocol: Scheme; host: string;
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

proc validate_PostUpdateDomainEndpointOptions_607029(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607031 = query.getOrDefault("Action")
  valid_607031 = validateParameter(valid_607031, JString, required = true, default = newJString(
      "UpdateDomainEndpointOptions"))
  if valid_607031 != nil:
    section.add "Action", valid_607031
  var valid_607032 = query.getOrDefault("Version")
  valid_607032 = validateParameter(valid_607032, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_607032 != nil:
    section.add "Version", valid_607032
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
  var valid_607033 = header.getOrDefault("X-Amz-Signature")
  valid_607033 = validateParameter(valid_607033, JString, required = false,
                                 default = nil)
  if valid_607033 != nil:
    section.add "X-Amz-Signature", valid_607033
  var valid_607034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607034 = validateParameter(valid_607034, JString, required = false,
                                 default = nil)
  if valid_607034 != nil:
    section.add "X-Amz-Content-Sha256", valid_607034
  var valid_607035 = header.getOrDefault("X-Amz-Date")
  valid_607035 = validateParameter(valid_607035, JString, required = false,
                                 default = nil)
  if valid_607035 != nil:
    section.add "X-Amz-Date", valid_607035
  var valid_607036 = header.getOrDefault("X-Amz-Credential")
  valid_607036 = validateParameter(valid_607036, JString, required = false,
                                 default = nil)
  if valid_607036 != nil:
    section.add "X-Amz-Credential", valid_607036
  var valid_607037 = header.getOrDefault("X-Amz-Security-Token")
  valid_607037 = validateParameter(valid_607037, JString, required = false,
                                 default = nil)
  if valid_607037 != nil:
    section.add "X-Amz-Security-Token", valid_607037
  var valid_607038 = header.getOrDefault("X-Amz-Algorithm")
  valid_607038 = validateParameter(valid_607038, JString, required = false,
                                 default = nil)
  if valid_607038 != nil:
    section.add "X-Amz-Algorithm", valid_607038
  var valid_607039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607039 = validateParameter(valid_607039, JString, required = false,
                                 default = nil)
  if valid_607039 != nil:
    section.add "X-Amz-SignedHeaders", valid_607039
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
  var valid_607040 = formData.getOrDefault("DomainEndpointOptions.TLSSecurityPolicy")
  valid_607040 = validateParameter(valid_607040, JString, required = false,
                                 default = nil)
  if valid_607040 != nil:
    section.add "DomainEndpointOptions.TLSSecurityPolicy", valid_607040
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_607041 = formData.getOrDefault("DomainName")
  valid_607041 = validateParameter(valid_607041, JString, required = true,
                                 default = nil)
  if valid_607041 != nil:
    section.add "DomainName", valid_607041
  var valid_607042 = formData.getOrDefault("DomainEndpointOptions.EnforceHTTPS")
  valid_607042 = validateParameter(valid_607042, JString, required = false,
                                 default = nil)
  if valid_607042 != nil:
    section.add "DomainEndpointOptions.EnforceHTTPS", valid_607042
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607043: Call_PostUpdateDomainEndpointOptions_607028;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_607043.validator(path, query, header, formData, body)
  let scheme = call_607043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607043.url(scheme.get, call_607043.host, call_607043.base,
                         call_607043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607043, url, valid)

proc call*(call_607044: Call_PostUpdateDomainEndpointOptions_607028;
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
  var query_607045 = newJObject()
  var formData_607046 = newJObject()
  add(formData_607046, "DomainEndpointOptions.TLSSecurityPolicy",
      newJString(DomainEndpointOptionsTLSSecurityPolicy))
  add(formData_607046, "DomainName", newJString(DomainName))
  add(query_607045, "Action", newJString(Action))
  add(formData_607046, "DomainEndpointOptions.EnforceHTTPS",
      newJString(DomainEndpointOptionsEnforceHTTPS))
  add(query_607045, "Version", newJString(Version))
  result = call_607044.call(nil, query_607045, nil, formData_607046, nil)

var postUpdateDomainEndpointOptions* = Call_PostUpdateDomainEndpointOptions_607028(
    name: "postUpdateDomainEndpointOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateDomainEndpointOptions",
    validator: validate_PostUpdateDomainEndpointOptions_607029, base: "/",
    url: url_PostUpdateDomainEndpointOptions_607030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateDomainEndpointOptions_607010 = ref object of OpenApiRestCall_605589
proc url_GetUpdateDomainEndpointOptions_607012(protocol: Scheme; host: string;
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

proc validate_GetUpdateDomainEndpointOptions_607011(path: JsonNode;
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
  var valid_607013 = query.getOrDefault("DomainEndpointOptions.EnforceHTTPS")
  valid_607013 = validateParameter(valid_607013, JString, required = false,
                                 default = nil)
  if valid_607013 != nil:
    section.add "DomainEndpointOptions.EnforceHTTPS", valid_607013
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_607014 = query.getOrDefault("DomainName")
  valid_607014 = validateParameter(valid_607014, JString, required = true,
                                 default = nil)
  if valid_607014 != nil:
    section.add "DomainName", valid_607014
  var valid_607015 = query.getOrDefault("Action")
  valid_607015 = validateParameter(valid_607015, JString, required = true, default = newJString(
      "UpdateDomainEndpointOptions"))
  if valid_607015 != nil:
    section.add "Action", valid_607015
  var valid_607016 = query.getOrDefault("DomainEndpointOptions.TLSSecurityPolicy")
  valid_607016 = validateParameter(valid_607016, JString, required = false,
                                 default = nil)
  if valid_607016 != nil:
    section.add "DomainEndpointOptions.TLSSecurityPolicy", valid_607016
  var valid_607017 = query.getOrDefault("Version")
  valid_607017 = validateParameter(valid_607017, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_607017 != nil:
    section.add "Version", valid_607017
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
  var valid_607018 = header.getOrDefault("X-Amz-Signature")
  valid_607018 = validateParameter(valid_607018, JString, required = false,
                                 default = nil)
  if valid_607018 != nil:
    section.add "X-Amz-Signature", valid_607018
  var valid_607019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607019 = validateParameter(valid_607019, JString, required = false,
                                 default = nil)
  if valid_607019 != nil:
    section.add "X-Amz-Content-Sha256", valid_607019
  var valid_607020 = header.getOrDefault("X-Amz-Date")
  valid_607020 = validateParameter(valid_607020, JString, required = false,
                                 default = nil)
  if valid_607020 != nil:
    section.add "X-Amz-Date", valid_607020
  var valid_607021 = header.getOrDefault("X-Amz-Credential")
  valid_607021 = validateParameter(valid_607021, JString, required = false,
                                 default = nil)
  if valid_607021 != nil:
    section.add "X-Amz-Credential", valid_607021
  var valid_607022 = header.getOrDefault("X-Amz-Security-Token")
  valid_607022 = validateParameter(valid_607022, JString, required = false,
                                 default = nil)
  if valid_607022 != nil:
    section.add "X-Amz-Security-Token", valid_607022
  var valid_607023 = header.getOrDefault("X-Amz-Algorithm")
  valid_607023 = validateParameter(valid_607023, JString, required = false,
                                 default = nil)
  if valid_607023 != nil:
    section.add "X-Amz-Algorithm", valid_607023
  var valid_607024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607024 = validateParameter(valid_607024, JString, required = false,
                                 default = nil)
  if valid_607024 != nil:
    section.add "X-Amz-SignedHeaders", valid_607024
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607025: Call_GetUpdateDomainEndpointOptions_607010; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_607025.validator(path, query, header, formData, body)
  let scheme = call_607025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607025.url(scheme.get, call_607025.host, call_607025.base,
                         call_607025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607025, url, valid)

proc call*(call_607026: Call_GetUpdateDomainEndpointOptions_607010;
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
  var query_607027 = newJObject()
  add(query_607027, "DomainEndpointOptions.EnforceHTTPS",
      newJString(DomainEndpointOptionsEnforceHTTPS))
  add(query_607027, "DomainName", newJString(DomainName))
  add(query_607027, "Action", newJString(Action))
  add(query_607027, "DomainEndpointOptions.TLSSecurityPolicy",
      newJString(DomainEndpointOptionsTLSSecurityPolicy))
  add(query_607027, "Version", newJString(Version))
  result = call_607026.call(nil, query_607027, nil, nil, nil)

var getUpdateDomainEndpointOptions* = Call_GetUpdateDomainEndpointOptions_607010(
    name: "getUpdateDomainEndpointOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateDomainEndpointOptions",
    validator: validate_GetUpdateDomainEndpointOptions_607011, base: "/",
    url: url_GetUpdateDomainEndpointOptions_607012,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateScalingParameters_607066 = ref object of OpenApiRestCall_605589
proc url_PostUpdateScalingParameters_607068(protocol: Scheme; host: string;
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

proc validate_PostUpdateScalingParameters_607067(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607069 = query.getOrDefault("Action")
  valid_607069 = validateParameter(valid_607069, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_607069 != nil:
    section.add "Action", valid_607069
  var valid_607070 = query.getOrDefault("Version")
  valid_607070 = validateParameter(valid_607070, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_607070 != nil:
    section.add "Version", valid_607070
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
  var valid_607071 = header.getOrDefault("X-Amz-Signature")
  valid_607071 = validateParameter(valid_607071, JString, required = false,
                                 default = nil)
  if valid_607071 != nil:
    section.add "X-Amz-Signature", valid_607071
  var valid_607072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607072 = validateParameter(valid_607072, JString, required = false,
                                 default = nil)
  if valid_607072 != nil:
    section.add "X-Amz-Content-Sha256", valid_607072
  var valid_607073 = header.getOrDefault("X-Amz-Date")
  valid_607073 = validateParameter(valid_607073, JString, required = false,
                                 default = nil)
  if valid_607073 != nil:
    section.add "X-Amz-Date", valid_607073
  var valid_607074 = header.getOrDefault("X-Amz-Credential")
  valid_607074 = validateParameter(valid_607074, JString, required = false,
                                 default = nil)
  if valid_607074 != nil:
    section.add "X-Amz-Credential", valid_607074
  var valid_607075 = header.getOrDefault("X-Amz-Security-Token")
  valid_607075 = validateParameter(valid_607075, JString, required = false,
                                 default = nil)
  if valid_607075 != nil:
    section.add "X-Amz-Security-Token", valid_607075
  var valid_607076 = header.getOrDefault("X-Amz-Algorithm")
  valid_607076 = validateParameter(valid_607076, JString, required = false,
                                 default = nil)
  if valid_607076 != nil:
    section.add "X-Amz-Algorithm", valid_607076
  var valid_607077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607077 = validateParameter(valid_607077, JString, required = false,
                                 default = nil)
  if valid_607077 != nil:
    section.add "X-Amz-SignedHeaders", valid_607077
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
  var valid_607078 = formData.getOrDefault("ScalingParameters.DesiredReplicationCount")
  valid_607078 = validateParameter(valid_607078, JString, required = false,
                                 default = nil)
  if valid_607078 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_607078
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_607079 = formData.getOrDefault("DomainName")
  valid_607079 = validateParameter(valid_607079, JString, required = true,
                                 default = nil)
  if valid_607079 != nil:
    section.add "DomainName", valid_607079
  var valid_607080 = formData.getOrDefault("ScalingParameters.DesiredPartitionCount")
  valid_607080 = validateParameter(valid_607080, JString, required = false,
                                 default = nil)
  if valid_607080 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_607080
  var valid_607081 = formData.getOrDefault("ScalingParameters.DesiredInstanceType")
  valid_607081 = validateParameter(valid_607081, JString, required = false,
                                 default = nil)
  if valid_607081 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_607081
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607082: Call_PostUpdateScalingParameters_607066; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_607082.validator(path, query, header, formData, body)
  let scheme = call_607082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607082.url(scheme.get, call_607082.host, call_607082.base,
                         call_607082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607082, url, valid)

proc call*(call_607083: Call_PostUpdateScalingParameters_607066;
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
  var query_607084 = newJObject()
  var formData_607085 = newJObject()
  add(formData_607085, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  add(formData_607085, "DomainName", newJString(DomainName))
  add(query_607084, "Action", newJString(Action))
  add(formData_607085, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(formData_607085, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  add(query_607084, "Version", newJString(Version))
  result = call_607083.call(nil, query_607084, nil, formData_607085, nil)

var postUpdateScalingParameters* = Call_PostUpdateScalingParameters_607066(
    name: "postUpdateScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_PostUpdateScalingParameters_607067, base: "/",
    url: url_PostUpdateScalingParameters_607068,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateScalingParameters_607047 = ref object of OpenApiRestCall_605589
proc url_GetUpdateScalingParameters_607049(protocol: Scheme; host: string;
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

proc validate_GetUpdateScalingParameters_607048(path: JsonNode; query: JsonNode;
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
  var valid_607050 = query.getOrDefault("ScalingParameters.DesiredPartitionCount")
  valid_607050 = validateParameter(valid_607050, JString, required = false,
                                 default = nil)
  if valid_607050 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_607050
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_607051 = query.getOrDefault("DomainName")
  valid_607051 = validateParameter(valid_607051, JString, required = true,
                                 default = nil)
  if valid_607051 != nil:
    section.add "DomainName", valid_607051
  var valid_607052 = query.getOrDefault("ScalingParameters.DesiredInstanceType")
  valid_607052 = validateParameter(valid_607052, JString, required = false,
                                 default = nil)
  if valid_607052 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_607052
  var valid_607053 = query.getOrDefault("Action")
  valid_607053 = validateParameter(valid_607053, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_607053 != nil:
    section.add "Action", valid_607053
  var valid_607054 = query.getOrDefault("Version")
  valid_607054 = validateParameter(valid_607054, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_607054 != nil:
    section.add "Version", valid_607054
  var valid_607055 = query.getOrDefault("ScalingParameters.DesiredReplicationCount")
  valid_607055 = validateParameter(valid_607055, JString, required = false,
                                 default = nil)
  if valid_607055 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_607055
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
  var valid_607056 = header.getOrDefault("X-Amz-Signature")
  valid_607056 = validateParameter(valid_607056, JString, required = false,
                                 default = nil)
  if valid_607056 != nil:
    section.add "X-Amz-Signature", valid_607056
  var valid_607057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607057 = validateParameter(valid_607057, JString, required = false,
                                 default = nil)
  if valid_607057 != nil:
    section.add "X-Amz-Content-Sha256", valid_607057
  var valid_607058 = header.getOrDefault("X-Amz-Date")
  valid_607058 = validateParameter(valid_607058, JString, required = false,
                                 default = nil)
  if valid_607058 != nil:
    section.add "X-Amz-Date", valid_607058
  var valid_607059 = header.getOrDefault("X-Amz-Credential")
  valid_607059 = validateParameter(valid_607059, JString, required = false,
                                 default = nil)
  if valid_607059 != nil:
    section.add "X-Amz-Credential", valid_607059
  var valid_607060 = header.getOrDefault("X-Amz-Security-Token")
  valid_607060 = validateParameter(valid_607060, JString, required = false,
                                 default = nil)
  if valid_607060 != nil:
    section.add "X-Amz-Security-Token", valid_607060
  var valid_607061 = header.getOrDefault("X-Amz-Algorithm")
  valid_607061 = validateParameter(valid_607061, JString, required = false,
                                 default = nil)
  if valid_607061 != nil:
    section.add "X-Amz-Algorithm", valid_607061
  var valid_607062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607062 = validateParameter(valid_607062, JString, required = false,
                                 default = nil)
  if valid_607062 != nil:
    section.add "X-Amz-SignedHeaders", valid_607062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607063: Call_GetUpdateScalingParameters_607047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_607063.validator(path, query, header, formData, body)
  let scheme = call_607063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607063.url(scheme.get, call_607063.host, call_607063.base,
                         call_607063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607063, url, valid)

proc call*(call_607064: Call_GetUpdateScalingParameters_607047; DomainName: string;
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
  var query_607065 = newJObject()
  add(query_607065, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(query_607065, "DomainName", newJString(DomainName))
  add(query_607065, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  add(query_607065, "Action", newJString(Action))
  add(query_607065, "Version", newJString(Version))
  add(query_607065, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  result = call_607064.call(nil, query_607065, nil, nil, nil)

var getUpdateScalingParameters* = Call_GetUpdateScalingParameters_607047(
    name: "getUpdateScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_GetUpdateScalingParameters_607048, base: "/",
    url: url_GetUpdateScalingParameters_607049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_607103 = ref object of OpenApiRestCall_605589
proc url_PostUpdateServiceAccessPolicies_607105(protocol: Scheme; host: string;
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

proc validate_PostUpdateServiceAccessPolicies_607104(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607106 = query.getOrDefault("Action")
  valid_607106 = validateParameter(valid_607106, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_607106 != nil:
    section.add "Action", valid_607106
  var valid_607107 = query.getOrDefault("Version")
  valid_607107 = validateParameter(valid_607107, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_607107 != nil:
    section.add "Version", valid_607107
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
  var valid_607108 = header.getOrDefault("X-Amz-Signature")
  valid_607108 = validateParameter(valid_607108, JString, required = false,
                                 default = nil)
  if valid_607108 != nil:
    section.add "X-Amz-Signature", valid_607108
  var valid_607109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607109 = validateParameter(valid_607109, JString, required = false,
                                 default = nil)
  if valid_607109 != nil:
    section.add "X-Amz-Content-Sha256", valid_607109
  var valid_607110 = header.getOrDefault("X-Amz-Date")
  valid_607110 = validateParameter(valid_607110, JString, required = false,
                                 default = nil)
  if valid_607110 != nil:
    section.add "X-Amz-Date", valid_607110
  var valid_607111 = header.getOrDefault("X-Amz-Credential")
  valid_607111 = validateParameter(valid_607111, JString, required = false,
                                 default = nil)
  if valid_607111 != nil:
    section.add "X-Amz-Credential", valid_607111
  var valid_607112 = header.getOrDefault("X-Amz-Security-Token")
  valid_607112 = validateParameter(valid_607112, JString, required = false,
                                 default = nil)
  if valid_607112 != nil:
    section.add "X-Amz-Security-Token", valid_607112
  var valid_607113 = header.getOrDefault("X-Amz-Algorithm")
  valid_607113 = validateParameter(valid_607113, JString, required = false,
                                 default = nil)
  if valid_607113 != nil:
    section.add "X-Amz-Algorithm", valid_607113
  var valid_607114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607114 = validateParameter(valid_607114, JString, required = false,
                                 default = nil)
  if valid_607114 != nil:
    section.add "X-Amz-SignedHeaders", valid_607114
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
  var valid_607115 = formData.getOrDefault("AccessPolicies")
  valid_607115 = validateParameter(valid_607115, JString, required = true,
                                 default = nil)
  if valid_607115 != nil:
    section.add "AccessPolicies", valid_607115
  var valid_607116 = formData.getOrDefault("DomainName")
  valid_607116 = validateParameter(valid_607116, JString, required = true,
                                 default = nil)
  if valid_607116 != nil:
    section.add "DomainName", valid_607116
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607117: Call_PostUpdateServiceAccessPolicies_607103;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_607117.validator(path, query, header, formData, body)
  let scheme = call_607117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607117.url(scheme.get, call_607117.host, call_607117.base,
                         call_607117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607117, url, valid)

proc call*(call_607118: Call_PostUpdateServiceAccessPolicies_607103;
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
  var query_607119 = newJObject()
  var formData_607120 = newJObject()
  add(formData_607120, "AccessPolicies", newJString(AccessPolicies))
  add(formData_607120, "DomainName", newJString(DomainName))
  add(query_607119, "Action", newJString(Action))
  add(query_607119, "Version", newJString(Version))
  result = call_607118.call(nil, query_607119, nil, formData_607120, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_607103(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_607104, base: "/",
    url: url_PostUpdateServiceAccessPolicies_607105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_607086 = ref object of OpenApiRestCall_605589
proc url_GetUpdateServiceAccessPolicies_607088(protocol: Scheme; host: string;
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

proc validate_GetUpdateServiceAccessPolicies_607087(path: JsonNode;
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
  var valid_607089 = query.getOrDefault("DomainName")
  valid_607089 = validateParameter(valid_607089, JString, required = true,
                                 default = nil)
  if valid_607089 != nil:
    section.add "DomainName", valid_607089
  var valid_607090 = query.getOrDefault("Action")
  valid_607090 = validateParameter(valid_607090, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_607090 != nil:
    section.add "Action", valid_607090
  var valid_607091 = query.getOrDefault("Version")
  valid_607091 = validateParameter(valid_607091, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_607091 != nil:
    section.add "Version", valid_607091
  var valid_607092 = query.getOrDefault("AccessPolicies")
  valid_607092 = validateParameter(valid_607092, JString, required = true,
                                 default = nil)
  if valid_607092 != nil:
    section.add "AccessPolicies", valid_607092
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
  var valid_607093 = header.getOrDefault("X-Amz-Signature")
  valid_607093 = validateParameter(valid_607093, JString, required = false,
                                 default = nil)
  if valid_607093 != nil:
    section.add "X-Amz-Signature", valid_607093
  var valid_607094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607094 = validateParameter(valid_607094, JString, required = false,
                                 default = nil)
  if valid_607094 != nil:
    section.add "X-Amz-Content-Sha256", valid_607094
  var valid_607095 = header.getOrDefault("X-Amz-Date")
  valid_607095 = validateParameter(valid_607095, JString, required = false,
                                 default = nil)
  if valid_607095 != nil:
    section.add "X-Amz-Date", valid_607095
  var valid_607096 = header.getOrDefault("X-Amz-Credential")
  valid_607096 = validateParameter(valid_607096, JString, required = false,
                                 default = nil)
  if valid_607096 != nil:
    section.add "X-Amz-Credential", valid_607096
  var valid_607097 = header.getOrDefault("X-Amz-Security-Token")
  valid_607097 = validateParameter(valid_607097, JString, required = false,
                                 default = nil)
  if valid_607097 != nil:
    section.add "X-Amz-Security-Token", valid_607097
  var valid_607098 = header.getOrDefault("X-Amz-Algorithm")
  valid_607098 = validateParameter(valid_607098, JString, required = false,
                                 default = nil)
  if valid_607098 != nil:
    section.add "X-Amz-Algorithm", valid_607098
  var valid_607099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607099 = validateParameter(valid_607099, JString, required = false,
                                 default = nil)
  if valid_607099 != nil:
    section.add "X-Amz-SignedHeaders", valid_607099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607100: Call_GetUpdateServiceAccessPolicies_607086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_607100.validator(path, query, header, formData, body)
  let scheme = call_607100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607100.url(scheme.get, call_607100.host, call_607100.base,
                         call_607100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607100, url, valid)

proc call*(call_607101: Call_GetUpdateServiceAccessPolicies_607086;
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
  var query_607102 = newJObject()
  add(query_607102, "DomainName", newJString(DomainName))
  add(query_607102, "Action", newJString(Action))
  add(query_607102, "Version", newJString(Version))
  add(query_607102, "AccessPolicies", newJString(AccessPolicies))
  result = call_607101.call(nil, query_607102, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_607086(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_607087, base: "/",
    url: url_GetUpdateServiceAccessPolicies_607088,
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
