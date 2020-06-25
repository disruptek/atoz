
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_PostBuildSuggesters_21626034 = ref object of OpenApiRestCall_21625435
proc url_PostBuildSuggesters_21626036(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostBuildSuggesters_21626035(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626037 = query.getOrDefault("Action")
  valid_21626037 = validateParameter(valid_21626037, JString, required = true,
                                   default = newJString("BuildSuggesters"))
  if valid_21626037 != nil:
    section.add "Action", valid_21626037
  var valid_21626038 = query.getOrDefault("Version")
  valid_21626038 = validateParameter(valid_21626038, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626038 != nil:
    section.add "Version", valid_21626038
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
  var valid_21626039 = header.getOrDefault("X-Amz-Date")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Date", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Security-Token", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Algorithm", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-Signature")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Signature", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-Credential")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Credential", valid_21626045
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626046 = formData.getOrDefault("DomainName")
  valid_21626046 = validateParameter(valid_21626046, JString, required = true,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "DomainName", valid_21626046
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626047: Call_PostBuildSuggesters_21626034; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626047.validator(path, query, header, formData, body, _)
  let scheme = call_21626047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626047.makeUrl(scheme.get, call_21626047.host, call_21626047.base,
                               call_21626047.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626047, uri, valid, _)

proc call*(call_21626048: Call_PostBuildSuggesters_21626034; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## postBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626049 = newJObject()
  var formData_21626050 = newJObject()
  add(formData_21626050, "DomainName", newJString(DomainName))
  add(query_21626049, "Action", newJString(Action))
  add(query_21626049, "Version", newJString(Version))
  result = call_21626048.call(nil, query_21626049, nil, formData_21626050, nil)

var postBuildSuggesters* = Call_PostBuildSuggesters_21626034(
    name: "postBuildSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_PostBuildSuggesters_21626035, base: "/",
    makeUrl: url_PostBuildSuggesters_21626036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuildSuggesters_21625779 = ref object of OpenApiRestCall_21625435
proc url_GetBuildSuggesters_21625781(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBuildSuggesters_21625780(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_21625896 = query.getOrDefault("Action")
  valid_21625896 = validateParameter(valid_21625896, JString, required = true,
                                   default = newJString("BuildSuggesters"))
  if valid_21625896 != nil:
    section.add "Action", valid_21625896
  var valid_21625897 = query.getOrDefault("DomainName")
  valid_21625897 = validateParameter(valid_21625897, JString, required = true,
                                   default = nil)
  if valid_21625897 != nil:
    section.add "DomainName", valid_21625897
  var valid_21625898 = query.getOrDefault("Version")
  valid_21625898 = validateParameter(valid_21625898, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21625898 != nil:
    section.add "Version", valid_21625898
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
  var valid_21625899 = header.getOrDefault("X-Amz-Date")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Date", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Security-Token", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Algorithm", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Signature")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Signature", valid_21625903
  var valid_21625904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625904 = validateParameter(valid_21625904, JString, required = false,
                                   default = nil)
  if valid_21625904 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625904
  var valid_21625905 = header.getOrDefault("X-Amz-Credential")
  valid_21625905 = validateParameter(valid_21625905, JString, required = false,
                                   default = nil)
  if valid_21625905 != nil:
    section.add "X-Amz-Credential", valid_21625905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625930: Call_GetBuildSuggesters_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21625930.validator(path, query, header, formData, body, _)
  let scheme = call_21625930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625930.makeUrl(scheme.get, call_21625930.host, call_21625930.base,
                               call_21625930.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625930, uri, valid, _)

proc call*(call_21625993: Call_GetBuildSuggesters_21625779; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## getBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_21625995 = newJObject()
  add(query_21625995, "Action", newJString(Action))
  add(query_21625995, "DomainName", newJString(DomainName))
  add(query_21625995, "Version", newJString(Version))
  result = call_21625993.call(nil, query_21625995, nil, nil, nil)

var getBuildSuggesters* = Call_GetBuildSuggesters_21625779(
    name: "getBuildSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_GetBuildSuggesters_21625780, base: "/",
    makeUrl: url_GetBuildSuggesters_21625781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_21626067 = ref object of OpenApiRestCall_21625435
proc url_PostCreateDomain_21626069(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDomain_21626068(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626070 = query.getOrDefault("Action")
  valid_21626070 = validateParameter(valid_21626070, JString, required = true,
                                   default = newJString("CreateDomain"))
  if valid_21626070 != nil:
    section.add "Action", valid_21626070
  var valid_21626071 = query.getOrDefault("Version")
  valid_21626071 = validateParameter(valid_21626071, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626071 != nil:
    section.add "Version", valid_21626071
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
  var valid_21626072 = header.getOrDefault("X-Amz-Date")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Date", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Security-Token", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Algorithm", valid_21626075
  var valid_21626076 = header.getOrDefault("X-Amz-Signature")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-Signature", valid_21626076
  var valid_21626077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Credential")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Credential", valid_21626078
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626079 = formData.getOrDefault("DomainName")
  valid_21626079 = validateParameter(valid_21626079, JString, required = true,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "DomainName", valid_21626079
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626080: Call_PostCreateDomain_21626067; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626080.validator(path, query, header, formData, body, _)
  let scheme = call_21626080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626080.makeUrl(scheme.get, call_21626080.host, call_21626080.base,
                               call_21626080.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626080, uri, valid, _)

proc call*(call_21626081: Call_PostCreateDomain_21626067; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626082 = newJObject()
  var formData_21626083 = newJObject()
  add(formData_21626083, "DomainName", newJString(DomainName))
  add(query_21626082, "Action", newJString(Action))
  add(query_21626082, "Version", newJString(Version))
  result = call_21626081.call(nil, query_21626082, nil, formData_21626083, nil)

var postCreateDomain* = Call_PostCreateDomain_21626067(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_21626068,
    base: "/", makeUrl: url_PostCreateDomain_21626069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_21626051 = ref object of OpenApiRestCall_21625435
proc url_GetCreateDomain_21626053(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDomain_21626052(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626054 = query.getOrDefault("Action")
  valid_21626054 = validateParameter(valid_21626054, JString, required = true,
                                   default = newJString("CreateDomain"))
  if valid_21626054 != nil:
    section.add "Action", valid_21626054
  var valid_21626055 = query.getOrDefault("DomainName")
  valid_21626055 = validateParameter(valid_21626055, JString, required = true,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "DomainName", valid_21626055
  var valid_21626056 = query.getOrDefault("Version")
  valid_21626056 = validateParameter(valid_21626056, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626056 != nil:
    section.add "Version", valid_21626056
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
  var valid_21626057 = header.getOrDefault("X-Amz-Date")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Date", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Security-Token", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Algorithm", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-Signature")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-Signature", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Credential")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Credential", valid_21626063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626064: Call_GetCreateDomain_21626051; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626064.validator(path, query, header, formData, body, _)
  let scheme = call_21626064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626064.makeUrl(scheme.get, call_21626064.host, call_21626064.base,
                               call_21626064.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626064, uri, valid, _)

proc call*(call_21626065: Call_GetCreateDomain_21626051; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_21626066 = newJObject()
  add(query_21626066, "Action", newJString(Action))
  add(query_21626066, "DomainName", newJString(DomainName))
  add(query_21626066, "Version", newJString(Version))
  result = call_21626065.call(nil, query_21626066, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_21626051(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_21626052,
    base: "/", makeUrl: url_GetCreateDomain_21626053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineAnalysisScheme_21626104 = ref object of OpenApiRestCall_21625435
proc url_PostDefineAnalysisScheme_21626106(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineAnalysisScheme_21626105(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626107 = query.getOrDefault("Action")
  valid_21626107 = validateParameter(valid_21626107, JString, required = true,
                                   default = newJString("DefineAnalysisScheme"))
  if valid_21626107 != nil:
    section.add "Action", valid_21626107
  var valid_21626108 = query.getOrDefault("Version")
  valid_21626108 = validateParameter(valid_21626108, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626108 != nil:
    section.add "Version", valid_21626108
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
  var valid_21626109 = header.getOrDefault("X-Amz-Date")
  valid_21626109 = validateParameter(valid_21626109, JString, required = false,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "X-Amz-Date", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Security-Token", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Algorithm", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-Signature")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-Signature", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-Credential")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-Credential", valid_21626115
  result.add "header", section
  ## parameters in `formData` object:
  ##   AnalysisScheme.AnalysisOptions: JString
  ##                                 : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisScheme.AnalysisSchemeLanguage: JString
  ##                                        : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   AnalysisScheme.AnalysisSchemeName: JString
  ##                                    : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  section = newJObject()
  var valid_21626116 = formData.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_21626116
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626117 = formData.getOrDefault("DomainName")
  valid_21626117 = validateParameter(valid_21626117, JString, required = true,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "DomainName", valid_21626117
  var valid_21626118 = formData.getOrDefault(
      "AnalysisScheme.AnalysisSchemeLanguage")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_21626118
  var valid_21626119 = formData.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_21626119
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626120: Call_PostDefineAnalysisScheme_21626104;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626120.validator(path, query, header, formData, body, _)
  let scheme = call_21626120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626120.makeUrl(scheme.get, call_21626120.host, call_21626120.base,
                               call_21626120.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626120, uri, valid, _)

proc call*(call_21626121: Call_PostDefineAnalysisScheme_21626104;
          DomainName: string; AnalysisSchemeAnalysisOptions: string = "";
          AnalysisSchemeAnalysisSchemeLanguage: string = "";
          Action: string = "DefineAnalysisScheme";
          AnalysisSchemeAnalysisSchemeName: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## postDefineAnalysisScheme
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   AnalysisSchemeAnalysisOptions: string
  ##                                : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeAnalysisSchemeLanguage: string
  ##                                       : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   Action: string (required)
  ##   AnalysisSchemeAnalysisSchemeName: string
  ##                                   : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   Version: string (required)
  var query_21626122 = newJObject()
  var formData_21626123 = newJObject()
  add(formData_21626123, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  add(formData_21626123, "DomainName", newJString(DomainName))
  add(formData_21626123, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(query_21626122, "Action", newJString(Action))
  add(formData_21626123, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_21626122, "Version", newJString(Version))
  result = call_21626121.call(nil, query_21626122, nil, formData_21626123, nil)

var postDefineAnalysisScheme* = Call_PostDefineAnalysisScheme_21626104(
    name: "postDefineAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_PostDefineAnalysisScheme_21626105, base: "/",
    makeUrl: url_PostDefineAnalysisScheme_21626106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineAnalysisScheme_21626084 = ref object of OpenApiRestCall_21625435
proc url_GetDefineAnalysisScheme_21626086(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineAnalysisScheme_21626085(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   AnalysisScheme.AnalysisSchemeLanguage: JString
  ##                                        : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   AnalysisScheme.AnalysisSchemeName: JString
  ##                                    : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  ##   AnalysisScheme.AnalysisOptions: JString
  ##                                 : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  section = newJObject()
  var valid_21626087 = query.getOrDefault("Action")
  valid_21626087 = validateParameter(valid_21626087, JString, required = true,
                                   default = newJString("DefineAnalysisScheme"))
  if valid_21626087 != nil:
    section.add "Action", valid_21626087
  var valid_21626088 = query.getOrDefault("AnalysisScheme.AnalysisSchemeLanguage")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_21626088
  var valid_21626089 = query.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_21626089
  var valid_21626090 = query.getOrDefault("DomainName")
  valid_21626090 = validateParameter(valid_21626090, JString, required = true,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "DomainName", valid_21626090
  var valid_21626091 = query.getOrDefault("Version")
  valid_21626091 = validateParameter(valid_21626091, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626091 != nil:
    section.add "Version", valid_21626091
  var valid_21626092 = query.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_21626092
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
  var valid_21626093 = header.getOrDefault("X-Amz-Date")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Date", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "X-Amz-Security-Token", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Algorithm", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Signature")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Signature", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Credential")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Credential", valid_21626099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626100: Call_GetDefineAnalysisScheme_21626084;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626100.validator(path, query, header, formData, body, _)
  let scheme = call_21626100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626100.makeUrl(scheme.get, call_21626100.host, call_21626100.base,
                               call_21626100.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626100, uri, valid, _)

proc call*(call_21626101: Call_GetDefineAnalysisScheme_21626084;
          DomainName: string; Action: string = "DefineAnalysisScheme";
          AnalysisSchemeAnalysisSchemeLanguage: string = "";
          AnalysisSchemeAnalysisSchemeName: string = "";
          Version: string = "2013-01-01"; AnalysisSchemeAnalysisOptions: string = ""): Recallable =
  ## getDefineAnalysisScheme
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   AnalysisSchemeAnalysisSchemeLanguage: string
  ##                                       : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   AnalysisSchemeAnalysisSchemeName: string
  ##                                   : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  ##   AnalysisSchemeAnalysisOptions: string
  ##                                : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  var query_21626102 = newJObject()
  add(query_21626102, "Action", newJString(Action))
  add(query_21626102, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(query_21626102, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_21626102, "DomainName", newJString(DomainName))
  add(query_21626102, "Version", newJString(Version))
  add(query_21626102, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  result = call_21626101.call(nil, query_21626102, nil, nil, nil)

var getDefineAnalysisScheme* = Call_GetDefineAnalysisScheme_21626084(
    name: "getDefineAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_GetDefineAnalysisScheme_21626085, base: "/",
    makeUrl: url_GetDefineAnalysisScheme_21626086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineExpression_21626142 = ref object of OpenApiRestCall_21625435
proc url_PostDefineExpression_21626144(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineExpression_21626143(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626145 = query.getOrDefault("Action")
  valid_21626145 = validateParameter(valid_21626145, JString, required = true,
                                   default = newJString("DefineExpression"))
  if valid_21626145 != nil:
    section.add "Action", valid_21626145
  var valid_21626146 = query.getOrDefault("Version")
  valid_21626146 = validateParameter(valid_21626146, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626146 != nil:
    section.add "Version", valid_21626146
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
  var valid_21626147 = header.getOrDefault("X-Amz-Date")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-Date", valid_21626147
  var valid_21626148 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-Security-Token", valid_21626148
  var valid_21626149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626149
  var valid_21626150 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-Algorithm", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-Signature")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Signature", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Credential")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Credential", valid_21626153
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Expression.ExpressionName: JString
  ##                            : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   Expression.ExpressionValue: JString
  ##                             : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626154 = formData.getOrDefault("DomainName")
  valid_21626154 = validateParameter(valid_21626154, JString, required = true,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "DomainName", valid_21626154
  var valid_21626155 = formData.getOrDefault("Expression.ExpressionName")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "Expression.ExpressionName", valid_21626155
  var valid_21626156 = formData.getOrDefault("Expression.ExpressionValue")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "Expression.ExpressionValue", valid_21626156
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626157: Call_PostDefineExpression_21626142; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626157.validator(path, query, header, formData, body, _)
  let scheme = call_21626157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626157.makeUrl(scheme.get, call_21626157.host, call_21626157.base,
                               call_21626157.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626157, uri, valid, _)

proc call*(call_21626158: Call_PostDefineExpression_21626142; DomainName: string;
          ExpressionExpressionName: string = "";
          ExpressionExpressionValue: string = "";
          Action: string = "DefineExpression"; Version: string = "2013-01-01"): Recallable =
  ## postDefineExpression
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ExpressionExpressionName: string
  ##                           : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   ExpressionExpressionValue: string
  ##                            : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626159 = newJObject()
  var formData_21626160 = newJObject()
  add(formData_21626160, "DomainName", newJString(DomainName))
  add(formData_21626160, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(formData_21626160, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(query_21626159, "Action", newJString(Action))
  add(query_21626159, "Version", newJString(Version))
  result = call_21626158.call(nil, query_21626159, nil, formData_21626160, nil)

var postDefineExpression* = Call_PostDefineExpression_21626142(
    name: "postDefineExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_PostDefineExpression_21626143, base: "/",
    makeUrl: url_PostDefineExpression_21626144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineExpression_21626124 = ref object of OpenApiRestCall_21625435
proc url_GetDefineExpression_21626126(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineExpression_21626125(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Expression.ExpressionValue: JString
  ##                             : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   Expression.ExpressionName: JString
  ##                            : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626127 = query.getOrDefault("Action")
  valid_21626127 = validateParameter(valid_21626127, JString, required = true,
                                   default = newJString("DefineExpression"))
  if valid_21626127 != nil:
    section.add "Action", valid_21626127
  var valid_21626128 = query.getOrDefault("Expression.ExpressionValue")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "Expression.ExpressionValue", valid_21626128
  var valid_21626129 = query.getOrDefault("Expression.ExpressionName")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "Expression.ExpressionName", valid_21626129
  var valid_21626130 = query.getOrDefault("DomainName")
  valid_21626130 = validateParameter(valid_21626130, JString, required = true,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "DomainName", valid_21626130
  var valid_21626131 = query.getOrDefault("Version")
  valid_21626131 = validateParameter(valid_21626131, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626131 != nil:
    section.add "Version", valid_21626131
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
  var valid_21626132 = header.getOrDefault("X-Amz-Date")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "X-Amz-Date", valid_21626132
  var valid_21626133 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-Security-Token", valid_21626133
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
  if body != nil:
    result.add "body", body

proc call*(call_21626139: Call_GetDefineExpression_21626124; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626139.validator(path, query, header, formData, body, _)
  let scheme = call_21626139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626139.makeUrl(scheme.get, call_21626139.host, call_21626139.base,
                               call_21626139.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626139, uri, valid, _)

proc call*(call_21626140: Call_GetDefineExpression_21626124; DomainName: string;
          Action: string = "DefineExpression";
          ExpressionExpressionValue: string = "";
          ExpressionExpressionName: string = ""; Version: string = "2013-01-01"): Recallable =
  ## getDefineExpression
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   ExpressionExpressionValue: string
  ##                            : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   ExpressionExpressionName: string
  ##                           : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_21626141 = newJObject()
  add(query_21626141, "Action", newJString(Action))
  add(query_21626141, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(query_21626141, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(query_21626141, "DomainName", newJString(DomainName))
  add(query_21626141, "Version", newJString(Version))
  result = call_21626140.call(nil, query_21626141, nil, nil, nil)

var getDefineExpression* = Call_GetDefineExpression_21626124(
    name: "getDefineExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_GetDefineExpression_21626125, base: "/",
    makeUrl: url_GetDefineExpression_21626126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_21626190 = ref object of OpenApiRestCall_21625435
proc url_PostDefineIndexField_21626192(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineIndexField_21626191(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626193 = query.getOrDefault("Action")
  valid_21626193 = validateParameter(valid_21626193, JString, required = true,
                                   default = newJString("DefineIndexField"))
  if valid_21626193 != nil:
    section.add "Action", valid_21626193
  var valid_21626194 = query.getOrDefault("Version")
  valid_21626194 = validateParameter(valid_21626194, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626194 != nil:
    section.add "Version", valid_21626194
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
  var valid_21626197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Algorithm", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Signature")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Signature", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Credential")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Credential", valid_21626201
  result.add "header", section
  ## parameters in `formData` object:
  ##   IndexField.TextArrayOptions: JString
  ##                              : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DateArrayOptions: JString
  ##                              : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.TextOptions: JString
  ##                         : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DoubleOptions: JString
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexField.LiteralOptions: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LiteralArrayOptions: JString
  ##                                 : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DateOptions: JString
  ##                         : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IntOptions: JString
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LatLonOptions: JString
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IndexFieldType: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DoubleArrayOptions: JString
  ##                                : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IndexFieldName: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## <p>A string that represents the name of an index field. CloudSearch supports regular index fields as well as dynamic fields. A dynamic field's name defines a pattern that begins or ends with a wildcard. Any document fields that don't map to a regular index field but do match a dynamic field's pattern are configured with the dynamic field's indexing options. </p> <p>Regular field names begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Dynamic field names must begin or end with a wildcard (*). The wildcard can also be the only character in a dynamic field name. Multiple wildcards, and wildcards embedded within a string are not supported. </p> <p>The name <code>score</code> is reserved and cannot be used as a field name. To reference a document's ID, you can use the name <code>_id</code>. </p>
  ##   IndexField.IntArrayOptions: JString
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  section = newJObject()
  var valid_21626202 = formData.getOrDefault("IndexField.TextArrayOptions")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "IndexField.TextArrayOptions", valid_21626202
  var valid_21626203 = formData.getOrDefault("IndexField.DateArrayOptions")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "IndexField.DateArrayOptions", valid_21626203
  var valid_21626204 = formData.getOrDefault("IndexField.TextOptions")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "IndexField.TextOptions", valid_21626204
  var valid_21626205 = formData.getOrDefault("IndexField.DoubleOptions")
  valid_21626205 = validateParameter(valid_21626205, JString, required = false,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "IndexField.DoubleOptions", valid_21626205
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626206 = formData.getOrDefault("DomainName")
  valid_21626206 = validateParameter(valid_21626206, JString, required = true,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "DomainName", valid_21626206
  var valid_21626207 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "IndexField.LiteralOptions", valid_21626207
  var valid_21626208 = formData.getOrDefault("IndexField.LiteralArrayOptions")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_21626208
  var valid_21626209 = formData.getOrDefault("IndexField.DateOptions")
  valid_21626209 = validateParameter(valid_21626209, JString, required = false,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "IndexField.DateOptions", valid_21626209
  var valid_21626210 = formData.getOrDefault("IndexField.IntOptions")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "IndexField.IntOptions", valid_21626210
  var valid_21626211 = formData.getOrDefault("IndexField.LatLonOptions")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "IndexField.LatLonOptions", valid_21626211
  var valid_21626212 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "IndexField.IndexFieldType", valid_21626212
  var valid_21626213 = formData.getOrDefault("IndexField.DoubleArrayOptions")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_21626213
  var valid_21626214 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "IndexField.IndexFieldName", valid_21626214
  var valid_21626215 = formData.getOrDefault("IndexField.IntArrayOptions")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "IndexField.IntArrayOptions", valid_21626215
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626216: Call_PostDefineIndexField_21626190; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_21626216.validator(path, query, header, formData, body, _)
  let scheme = call_21626216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626216.makeUrl(scheme.get, call_21626216.host, call_21626216.base,
                               call_21626216.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626216, uri, valid, _)

proc call*(call_21626217: Call_PostDefineIndexField_21626190; DomainName: string;
          IndexFieldTextArrayOptions: string = "";
          IndexFieldDateArrayOptions: string = "";
          IndexFieldTextOptions: string = ""; IndexFieldDoubleOptions: string = "";
          IndexFieldLiteralOptions: string = "";
          IndexFieldLiteralArrayOptions: string = "";
          IndexFieldDateOptions: string = ""; IndexFieldIntOptions: string = "";
          IndexFieldLatLonOptions: string = "";
          IndexFieldIndexFieldType: string = "";
          Action: string = "DefineIndexField";
          IndexFieldDoubleArrayOptions: string = "";
          IndexFieldIndexFieldName: string = ""; Version: string = "2013-01-01";
          IndexFieldIntArrayOptions: string = ""): Recallable =
  ## postDefineIndexField
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   IndexFieldTextArrayOptions: string
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDateArrayOptions: string
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldTextOptions: string
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDoubleOptions: string
  ##                          : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldLiteralOptions: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLiteralArrayOptions: string
  ##                                : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDateOptions: string
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIntOptions: string
  ##                       : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLatLonOptions: string
  ##                          : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIndexFieldType: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Action: string (required)
  ##   IndexFieldDoubleArrayOptions: string
  ##                               : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIndexFieldName: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## <p>A string that represents the name of an index field. CloudSearch supports regular index fields as well as dynamic fields. A dynamic field's name defines a pattern that begins or ends with a wildcard. Any document fields that don't map to a regular index field but do match a dynamic field's pattern are configured with the dynamic field's indexing options. </p> <p>Regular field names begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Dynamic field names must begin or end with a wildcard (*). The wildcard can also be the only character in a dynamic field name. Multiple wildcards, and wildcards embedded within a string are not supported. </p> <p>The name <code>score</code> is reserved and cannot be used as a field name. To reference a document's ID, you can use the name <code>_id</code>. </p>
  ##   Version: string (required)
  ##   IndexFieldIntArrayOptions: string
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  var query_21626218 = newJObject()
  var formData_21626219 = newJObject()
  add(formData_21626219, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(formData_21626219, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(formData_21626219, "IndexField.TextOptions",
      newJString(IndexFieldTextOptions))
  add(formData_21626219, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(formData_21626219, "DomainName", newJString(DomainName))
  add(formData_21626219, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(formData_21626219, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(formData_21626219, "IndexField.DateOptions",
      newJString(IndexFieldDateOptions))
  add(formData_21626219, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(formData_21626219, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  add(formData_21626219, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_21626218, "Action", newJString(Action))
  add(formData_21626219, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  add(formData_21626219, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_21626218, "Version", newJString(Version))
  add(formData_21626219, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  result = call_21626217.call(nil, query_21626218, nil, formData_21626219, nil)

var postDefineIndexField* = Call_PostDefineIndexField_21626190(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_21626191, base: "/",
    makeUrl: url_PostDefineIndexField_21626192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_21626161 = ref object of OpenApiRestCall_21625435
proc url_GetDefineIndexField_21626163(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineIndexField_21626162(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   IndexField.DateOptions: JString
  ##                         : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LiteralOptions: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LiteralArrayOptions: JString
  ##                                 : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IndexFieldType: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IntOptions: JString
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DateArrayOptions: JString
  ##                              : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DoubleOptions: JString
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IndexFieldName: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## <p>A string that represents the name of an index field. CloudSearch supports regular index fields as well as dynamic fields. A dynamic field's name defines a pattern that begins or ends with a wildcard. Any document fields that don't map to a regular index field but do match a dynamic field's pattern are configured with the dynamic field's indexing options. </p> <p>Regular field names begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Dynamic field names must begin or end with a wildcard (*). The wildcard can also be the only character in a dynamic field name. Multiple wildcards, and wildcards embedded within a string are not supported. </p> <p>The name <code>score</code> is reserved and cannot be used as a field name. To reference a document's ID, you can use the name <code>_id</code>. </p>
  ##   IndexField.LatLonOptions: JString
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IntArrayOptions: JString
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexField.TextArrayOptions: JString
  ##                              : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DoubleArrayOptions: JString
  ##                                : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626164 = query.getOrDefault("IndexField.TextOptions")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "IndexField.TextOptions", valid_21626164
  var valid_21626165 = query.getOrDefault("IndexField.DateOptions")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "IndexField.DateOptions", valid_21626165
  var valid_21626166 = query.getOrDefault("IndexField.LiteralOptions")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "IndexField.LiteralOptions", valid_21626166
  var valid_21626167 = query.getOrDefault("IndexField.LiteralArrayOptions")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_21626167
  var valid_21626168 = query.getOrDefault("IndexField.IndexFieldType")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "IndexField.IndexFieldType", valid_21626168
  var valid_21626169 = query.getOrDefault("IndexField.IntOptions")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "IndexField.IntOptions", valid_21626169
  var valid_21626170 = query.getOrDefault("IndexField.DateArrayOptions")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "IndexField.DateArrayOptions", valid_21626170
  var valid_21626171 = query.getOrDefault("IndexField.DoubleOptions")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "IndexField.DoubleOptions", valid_21626171
  var valid_21626172 = query.getOrDefault("IndexField.IndexFieldName")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "IndexField.IndexFieldName", valid_21626172
  var valid_21626173 = query.getOrDefault("IndexField.LatLonOptions")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "IndexField.LatLonOptions", valid_21626173
  var valid_21626174 = query.getOrDefault("IndexField.IntArrayOptions")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "IndexField.IntArrayOptions", valid_21626174
  var valid_21626175 = query.getOrDefault("Action")
  valid_21626175 = validateParameter(valid_21626175, JString, required = true,
                                   default = newJString("DefineIndexField"))
  if valid_21626175 != nil:
    section.add "Action", valid_21626175
  var valid_21626176 = query.getOrDefault("DomainName")
  valid_21626176 = validateParameter(valid_21626176, JString, required = true,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "DomainName", valid_21626176
  var valid_21626177 = query.getOrDefault("IndexField.TextArrayOptions")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "IndexField.TextArrayOptions", valid_21626177
  var valid_21626178 = query.getOrDefault("IndexField.DoubleArrayOptions")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_21626178
  var valid_21626179 = query.getOrDefault("Version")
  valid_21626179 = validateParameter(valid_21626179, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626179 != nil:
    section.add "Version", valid_21626179
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
  var valid_21626182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Algorithm", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Signature")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Signature", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Credential")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Credential", valid_21626186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626187: Call_GetDefineIndexField_21626161; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_21626187.validator(path, query, header, formData, body, _)
  let scheme = call_21626187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626187.makeUrl(scheme.get, call_21626187.host, call_21626187.base,
                               call_21626187.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626187, uri, valid, _)

proc call*(call_21626188: Call_GetDefineIndexField_21626161; DomainName: string;
          IndexFieldTextOptions: string = ""; IndexFieldDateOptions: string = "";
          IndexFieldLiteralOptions: string = "";
          IndexFieldLiteralArrayOptions: string = "";
          IndexFieldIndexFieldType: string = ""; IndexFieldIntOptions: string = "";
          IndexFieldDateArrayOptions: string = "";
          IndexFieldDoubleOptions: string = "";
          IndexFieldIndexFieldName: string = "";
          IndexFieldLatLonOptions: string = "";
          IndexFieldIntArrayOptions: string = "";
          Action: string = "DefineIndexField";
          IndexFieldTextArrayOptions: string = "";
          IndexFieldDoubleArrayOptions: string = ""; Version: string = "2013-01-01"): Recallable =
  ## getDefineIndexField
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   IndexFieldTextOptions: string
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDateOptions: string
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLiteralOptions: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLiteralArrayOptions: string
  ##                                : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIndexFieldType: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIntOptions: string
  ##                       : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDateArrayOptions: string
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDoubleOptions: string
  ##                          : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIndexFieldName: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## <p>A string that represents the name of an index field. CloudSearch supports regular index fields as well as dynamic fields. A dynamic field's name defines a pattern that begins or ends with a wildcard. Any document fields that don't map to a regular index field but do match a dynamic field's pattern are configured with the dynamic field's indexing options. </p> <p>Regular field names begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Dynamic field names must begin or end with a wildcard (*). The wildcard can also be the only character in a dynamic field name. Multiple wildcards, and wildcards embedded within a string are not supported. </p> <p>The name <code>score</code> is reserved and cannot be used as a field name. To reference a document's ID, you can use the name <code>_id</code>. </p>
  ##   IndexFieldLatLonOptions: string
  ##                          : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIntArrayOptions: string
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldTextArrayOptions: string
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDoubleArrayOptions: string
  ##                               : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Version: string (required)
  var query_21626189 = newJObject()
  add(query_21626189, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_21626189, "IndexField.DateOptions", newJString(IndexFieldDateOptions))
  add(query_21626189, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_21626189, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(query_21626189, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_21626189, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(query_21626189, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(query_21626189, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(query_21626189, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_21626189, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  add(query_21626189, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  add(query_21626189, "Action", newJString(Action))
  add(query_21626189, "DomainName", newJString(DomainName))
  add(query_21626189, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(query_21626189, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  add(query_21626189, "Version", newJString(Version))
  result = call_21626188.call(nil, query_21626189, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_21626161(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_21626162, base: "/",
    makeUrl: url_GetDefineIndexField_21626163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineSuggester_21626238 = ref object of OpenApiRestCall_21625435
proc url_PostDefineSuggester_21626240(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineSuggester_21626239(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626241 = query.getOrDefault("Action")
  valid_21626241 = validateParameter(valid_21626241, JString, required = true,
                                   default = newJString("DefineSuggester"))
  if valid_21626241 != nil:
    section.add "Action", valid_21626241
  var valid_21626242 = query.getOrDefault("Version")
  valid_21626242 = validateParameter(valid_21626242, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626242 != nil:
    section.add "Version", valid_21626242
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
  var valid_21626243 = header.getOrDefault("X-Amz-Date")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Date", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626244 = validateParameter(valid_21626244, JString, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "X-Amz-Security-Token", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Algorithm", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Signature")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Signature", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Credential")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Credential", valid_21626249
  result.add "header", section
  ## parameters in `formData` object:
  ##   Suggester.DocumentSuggesterOptions: JString
  ##                                     : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Suggester.SuggesterName: JString
  ##                          : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  section = newJObject()
  var valid_21626250 = formData.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_21626250
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626251 = formData.getOrDefault("DomainName")
  valid_21626251 = validateParameter(valid_21626251, JString, required = true,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "DomainName", valid_21626251
  var valid_21626252 = formData.getOrDefault("Suggester.SuggesterName")
  valid_21626252 = validateParameter(valid_21626252, JString, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "Suggester.SuggesterName", valid_21626252
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626253: Call_PostDefineSuggester_21626238; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626253.validator(path, query, header, formData, body, _)
  let scheme = call_21626253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626253.makeUrl(scheme.get, call_21626253.host, call_21626253.base,
                               call_21626253.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626253, uri, valid, _)

proc call*(call_21626254: Call_PostDefineSuggester_21626238; DomainName: string;
          SuggesterDocumentSuggesterOptions: string = "";
          Action: string = "DefineSuggester"; Version: string = "2013-01-01";
          SuggesterSuggesterName: string = ""): Recallable =
  ## postDefineSuggester
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   SuggesterDocumentSuggesterOptions: string
  ##                                    : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SuggesterSuggesterName: string
  ##                         : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  var query_21626255 = newJObject()
  var formData_21626256 = newJObject()
  add(formData_21626256, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(formData_21626256, "DomainName", newJString(DomainName))
  add(query_21626255, "Action", newJString(Action))
  add(query_21626255, "Version", newJString(Version))
  add(formData_21626256, "Suggester.SuggesterName",
      newJString(SuggesterSuggesterName))
  result = call_21626254.call(nil, query_21626255, nil, formData_21626256, nil)

var postDefineSuggester* = Call_PostDefineSuggester_21626238(
    name: "postDefineSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_PostDefineSuggester_21626239, base: "/",
    makeUrl: url_PostDefineSuggester_21626240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineSuggester_21626220 = ref object of OpenApiRestCall_21625435
proc url_GetDefineSuggester_21626222(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineSuggester_21626221(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Suggester.SuggesterName: JString
  ##                          : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   Action: JString (required)
  ##   Suggester.DocumentSuggesterOptions: JString
  ##                                     : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626223 = query.getOrDefault("Suggester.SuggesterName")
  valid_21626223 = validateParameter(valid_21626223, JString, required = false,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "Suggester.SuggesterName", valid_21626223
  var valid_21626224 = query.getOrDefault("Action")
  valid_21626224 = validateParameter(valid_21626224, JString, required = true,
                                   default = newJString("DefineSuggester"))
  if valid_21626224 != nil:
    section.add "Action", valid_21626224
  var valid_21626225 = query.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_21626225 = validateParameter(valid_21626225, JString, required = false,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_21626225
  var valid_21626226 = query.getOrDefault("DomainName")
  valid_21626226 = validateParameter(valid_21626226, JString, required = true,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "DomainName", valid_21626226
  var valid_21626227 = query.getOrDefault("Version")
  valid_21626227 = validateParameter(valid_21626227, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626227 != nil:
    section.add "Version", valid_21626227
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
  var valid_21626228 = header.getOrDefault("X-Amz-Date")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Date", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Security-Token", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Algorithm", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Signature")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Signature", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Credential")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Credential", valid_21626234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626235: Call_GetDefineSuggester_21626220; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626235.validator(path, query, header, formData, body, _)
  let scheme = call_21626235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626235.makeUrl(scheme.get, call_21626235.host, call_21626235.base,
                               call_21626235.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626235, uri, valid, _)

proc call*(call_21626236: Call_GetDefineSuggester_21626220; DomainName: string;
          SuggesterSuggesterName: string = ""; Action: string = "DefineSuggester";
          SuggesterDocumentSuggesterOptions: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## getDefineSuggester
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   SuggesterSuggesterName: string
  ##                         : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   Action: string (required)
  ##   SuggesterDocumentSuggesterOptions: string
  ##                                    : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_21626237 = newJObject()
  add(query_21626237, "Suggester.SuggesterName",
      newJString(SuggesterSuggesterName))
  add(query_21626237, "Action", newJString(Action))
  add(query_21626237, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(query_21626237, "DomainName", newJString(DomainName))
  add(query_21626237, "Version", newJString(Version))
  result = call_21626236.call(nil, query_21626237, nil, nil, nil)

var getDefineSuggester* = Call_GetDefineSuggester_21626220(
    name: "getDefineSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_GetDefineSuggester_21626221, base: "/",
    makeUrl: url_GetDefineSuggester_21626222, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAnalysisScheme_21626274 = ref object of OpenApiRestCall_21625435
proc url_PostDeleteAnalysisScheme_21626276(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteAnalysisScheme_21626275(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626277 = query.getOrDefault("Action")
  valid_21626277 = validateParameter(valid_21626277, JString, required = true,
                                   default = newJString("DeleteAnalysisScheme"))
  if valid_21626277 != nil:
    section.add "Action", valid_21626277
  var valid_21626278 = query.getOrDefault("Version")
  valid_21626278 = validateParameter(valid_21626278, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626278 != nil:
    section.add "Version", valid_21626278
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
  var valid_21626279 = header.getOrDefault("X-Amz-Date")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Date", valid_21626279
  var valid_21626280 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-Security-Token", valid_21626280
  var valid_21626281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626281
  var valid_21626282 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-Algorithm", valid_21626282
  var valid_21626283 = header.getOrDefault("X-Amz-Signature")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-Signature", valid_21626283
  var valid_21626284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-Credential")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-Credential", valid_21626285
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeName: JString (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626286 = formData.getOrDefault("DomainName")
  valid_21626286 = validateParameter(valid_21626286, JString, required = true,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "DomainName", valid_21626286
  var valid_21626287 = formData.getOrDefault("AnalysisSchemeName")
  valid_21626287 = validateParameter(valid_21626287, JString, required = true,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "AnalysisSchemeName", valid_21626287
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626288: Call_PostDeleteAnalysisScheme_21626274;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_21626288.validator(path, query, header, formData, body, _)
  let scheme = call_21626288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626288.makeUrl(scheme.get, call_21626288.host, call_21626288.base,
                               call_21626288.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626288, uri, valid, _)

proc call*(call_21626289: Call_PostDeleteAnalysisScheme_21626274;
          DomainName: string; AnalysisSchemeName: string;
          Action: string = "DeleteAnalysisScheme"; Version: string = "2013-01-01"): Recallable =
  ## postDeleteAnalysisScheme
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeName: string (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626290 = newJObject()
  var formData_21626291 = newJObject()
  add(formData_21626291, "DomainName", newJString(DomainName))
  add(formData_21626291, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(query_21626290, "Action", newJString(Action))
  add(query_21626290, "Version", newJString(Version))
  result = call_21626289.call(nil, query_21626290, nil, formData_21626291, nil)

var postDeleteAnalysisScheme* = Call_PostDeleteAnalysisScheme_21626274(
    name: "postDeleteAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_PostDeleteAnalysisScheme_21626275, base: "/",
    makeUrl: url_PostDeleteAnalysisScheme_21626276,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAnalysisScheme_21626257 = ref object of OpenApiRestCall_21625435
proc url_GetDeleteAnalysisScheme_21626259(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteAnalysisScheme_21626258(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeName: JString (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626260 = query.getOrDefault("Action")
  valid_21626260 = validateParameter(valid_21626260, JString, required = true,
                                   default = newJString("DeleteAnalysisScheme"))
  if valid_21626260 != nil:
    section.add "Action", valid_21626260
  var valid_21626261 = query.getOrDefault("DomainName")
  valid_21626261 = validateParameter(valid_21626261, JString, required = true,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "DomainName", valid_21626261
  var valid_21626262 = query.getOrDefault("AnalysisSchemeName")
  valid_21626262 = validateParameter(valid_21626262, JString, required = true,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "AnalysisSchemeName", valid_21626262
  var valid_21626263 = query.getOrDefault("Version")
  valid_21626263 = validateParameter(valid_21626263, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626263 != nil:
    section.add "Version", valid_21626263
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
  if body != nil:
    result.add "body", body

proc call*(call_21626271: Call_GetDeleteAnalysisScheme_21626257;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_21626271.validator(path, query, header, formData, body, _)
  let scheme = call_21626271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626271.makeUrl(scheme.get, call_21626271.host, call_21626271.base,
                               call_21626271.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626271, uri, valid, _)

proc call*(call_21626272: Call_GetDeleteAnalysisScheme_21626257;
          DomainName: string; AnalysisSchemeName: string;
          Action: string = "DeleteAnalysisScheme"; Version: string = "2013-01-01"): Recallable =
  ## getDeleteAnalysisScheme
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeName: string (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   Version: string (required)
  var query_21626273 = newJObject()
  add(query_21626273, "Action", newJString(Action))
  add(query_21626273, "DomainName", newJString(DomainName))
  add(query_21626273, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(query_21626273, "Version", newJString(Version))
  result = call_21626272.call(nil, query_21626273, nil, nil, nil)

var getDeleteAnalysisScheme* = Call_GetDeleteAnalysisScheme_21626257(
    name: "getDeleteAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_GetDeleteAnalysisScheme_21626258, base: "/",
    makeUrl: url_GetDeleteAnalysisScheme_21626259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_21626308 = ref object of OpenApiRestCall_21625435
proc url_PostDeleteDomain_21626310(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDomain_21626309(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626311 = query.getOrDefault("Action")
  valid_21626311 = validateParameter(valid_21626311, JString, required = true,
                                   default = newJString("DeleteDomain"))
  if valid_21626311 != nil:
    section.add "Action", valid_21626311
  var valid_21626312 = query.getOrDefault("Version")
  valid_21626312 = validateParameter(valid_21626312, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626312 != nil:
    section.add "Version", valid_21626312
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
  var valid_21626313 = header.getOrDefault("X-Amz-Date")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-Date", valid_21626313
  var valid_21626314 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626314 = validateParameter(valid_21626314, JString, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "X-Amz-Security-Token", valid_21626314
  var valid_21626315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626315 = validateParameter(valid_21626315, JString, required = false,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626315
  var valid_21626316 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626316 = validateParameter(valid_21626316, JString, required = false,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "X-Amz-Algorithm", valid_21626316
  var valid_21626317 = header.getOrDefault("X-Amz-Signature")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Signature", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Credential")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Credential", valid_21626319
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626320 = formData.getOrDefault("DomainName")
  valid_21626320 = validateParameter(valid_21626320, JString, required = true,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "DomainName", valid_21626320
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626321: Call_PostDeleteDomain_21626308; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_21626321.validator(path, query, header, formData, body, _)
  let scheme = call_21626321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626321.makeUrl(scheme.get, call_21626321.host, call_21626321.base,
                               call_21626321.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626321, uri, valid, _)

proc call*(call_21626322: Call_PostDeleteDomain_21626308; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626323 = newJObject()
  var formData_21626324 = newJObject()
  add(formData_21626324, "DomainName", newJString(DomainName))
  add(query_21626323, "Action", newJString(Action))
  add(query_21626323, "Version", newJString(Version))
  result = call_21626322.call(nil, query_21626323, nil, formData_21626324, nil)

var postDeleteDomain* = Call_PostDeleteDomain_21626308(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_21626309,
    base: "/", makeUrl: url_PostDeleteDomain_21626310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_21626292 = ref object of OpenApiRestCall_21625435
proc url_GetDeleteDomain_21626294(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDomain_21626293(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626295 = query.getOrDefault("Action")
  valid_21626295 = validateParameter(valid_21626295, JString, required = true,
                                   default = newJString("DeleteDomain"))
  if valid_21626295 != nil:
    section.add "Action", valid_21626295
  var valid_21626296 = query.getOrDefault("DomainName")
  valid_21626296 = validateParameter(valid_21626296, JString, required = true,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "DomainName", valid_21626296
  var valid_21626297 = query.getOrDefault("Version")
  valid_21626297 = validateParameter(valid_21626297, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626297 != nil:
    section.add "Version", valid_21626297
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
  var valid_21626298 = header.getOrDefault("X-Amz-Date")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "X-Amz-Date", valid_21626298
  var valid_21626299 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626299 = validateParameter(valid_21626299, JString, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "X-Amz-Security-Token", valid_21626299
  var valid_21626300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626300 = validateParameter(valid_21626300, JString, required = false,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626300
  var valid_21626301 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626301 = validateParameter(valid_21626301, JString, required = false,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "X-Amz-Algorithm", valid_21626301
  var valid_21626302 = header.getOrDefault("X-Amz-Signature")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Signature", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Credential")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Credential", valid_21626304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626305: Call_GetDeleteDomain_21626292; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_21626305.validator(path, query, header, formData, body, _)
  let scheme = call_21626305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626305.makeUrl(scheme.get, call_21626305.host, call_21626305.base,
                               call_21626305.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626305, uri, valid, _)

proc call*(call_21626306: Call_GetDeleteDomain_21626292; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_21626307 = newJObject()
  add(query_21626307, "Action", newJString(Action))
  add(query_21626307, "DomainName", newJString(DomainName))
  add(query_21626307, "Version", newJString(Version))
  result = call_21626306.call(nil, query_21626307, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_21626292(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_21626293,
    base: "/", makeUrl: url_GetDeleteDomain_21626294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteExpression_21626342 = ref object of OpenApiRestCall_21625435
proc url_PostDeleteExpression_21626344(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteExpression_21626343(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626345 = query.getOrDefault("Action")
  valid_21626345 = validateParameter(valid_21626345, JString, required = true,
                                   default = newJString("DeleteExpression"))
  if valid_21626345 != nil:
    section.add "Action", valid_21626345
  var valid_21626346 = query.getOrDefault("Version")
  valid_21626346 = validateParameter(valid_21626346, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626346 != nil:
    section.add "Version", valid_21626346
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
  var valid_21626347 = header.getOrDefault("X-Amz-Date")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Date", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Security-Token", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Algorithm", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Signature")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Signature", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-Credential")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-Credential", valid_21626353
  result.add "header", section
  ## parameters in `formData` object:
  ##   ExpressionName: JString (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ExpressionName` field"
  var valid_21626354 = formData.getOrDefault("ExpressionName")
  valid_21626354 = validateParameter(valid_21626354, JString, required = true,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "ExpressionName", valid_21626354
  var valid_21626355 = formData.getOrDefault("DomainName")
  valid_21626355 = validateParameter(valid_21626355, JString, required = true,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "DomainName", valid_21626355
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626356: Call_PostDeleteExpression_21626342; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626356.validator(path, query, header, formData, body, _)
  let scheme = call_21626356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626356.makeUrl(scheme.get, call_21626356.host, call_21626356.base,
                               call_21626356.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626356, uri, valid, _)

proc call*(call_21626357: Call_PostDeleteExpression_21626342;
          ExpressionName: string; DomainName: string;
          Action: string = "DeleteExpression"; Version: string = "2013-01-01"): Recallable =
  ## postDeleteExpression
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   ExpressionName: string (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626358 = newJObject()
  var formData_21626359 = newJObject()
  add(formData_21626359, "ExpressionName", newJString(ExpressionName))
  add(formData_21626359, "DomainName", newJString(DomainName))
  add(query_21626358, "Action", newJString(Action))
  add(query_21626358, "Version", newJString(Version))
  result = call_21626357.call(nil, query_21626358, nil, formData_21626359, nil)

var postDeleteExpression* = Call_PostDeleteExpression_21626342(
    name: "postDeleteExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_PostDeleteExpression_21626343, base: "/",
    makeUrl: url_PostDeleteExpression_21626344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteExpression_21626325 = ref object of OpenApiRestCall_21625435
proc url_GetDeleteExpression_21626327(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteExpression_21626326(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ExpressionName: JString (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626328 = query.getOrDefault("Action")
  valid_21626328 = validateParameter(valid_21626328, JString, required = true,
                                   default = newJString("DeleteExpression"))
  if valid_21626328 != nil:
    section.add "Action", valid_21626328
  var valid_21626329 = query.getOrDefault("ExpressionName")
  valid_21626329 = validateParameter(valid_21626329, JString, required = true,
                                   default = nil)
  if valid_21626329 != nil:
    section.add "ExpressionName", valid_21626329
  var valid_21626330 = query.getOrDefault("DomainName")
  valid_21626330 = validateParameter(valid_21626330, JString, required = true,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "DomainName", valid_21626330
  var valid_21626331 = query.getOrDefault("Version")
  valid_21626331 = validateParameter(valid_21626331, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626331 != nil:
    section.add "Version", valid_21626331
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
  var valid_21626332 = header.getOrDefault("X-Amz-Date")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Date", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Security-Token", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Algorithm", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Signature")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Signature", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-Credential")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Credential", valid_21626338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626339: Call_GetDeleteExpression_21626325; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626339.validator(path, query, header, formData, body, _)
  let scheme = call_21626339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626339.makeUrl(scheme.get, call_21626339.host, call_21626339.base,
                               call_21626339.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626339, uri, valid, _)

proc call*(call_21626340: Call_GetDeleteExpression_21626325;
          ExpressionName: string; DomainName: string;
          Action: string = "DeleteExpression"; Version: string = "2013-01-01"): Recallable =
  ## getDeleteExpression
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   ExpressionName: string (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_21626341 = newJObject()
  add(query_21626341, "Action", newJString(Action))
  add(query_21626341, "ExpressionName", newJString(ExpressionName))
  add(query_21626341, "DomainName", newJString(DomainName))
  add(query_21626341, "Version", newJString(Version))
  result = call_21626340.call(nil, query_21626341, nil, nil, nil)

var getDeleteExpression* = Call_GetDeleteExpression_21626325(
    name: "getDeleteExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_GetDeleteExpression_21626326, base: "/",
    makeUrl: url_GetDeleteExpression_21626327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_21626377 = ref object of OpenApiRestCall_21625435
proc url_PostDeleteIndexField_21626379(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteIndexField_21626378(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626380 = query.getOrDefault("Action")
  valid_21626380 = validateParameter(valid_21626380, JString, required = true,
                                   default = newJString("DeleteIndexField"))
  if valid_21626380 != nil:
    section.add "Action", valid_21626380
  var valid_21626381 = query.getOrDefault("Version")
  valid_21626381 = validateParameter(valid_21626381, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626381 != nil:
    section.add "Version", valid_21626381
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
  var valid_21626382 = header.getOrDefault("X-Amz-Date")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Date", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-Security-Token", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626384
  var valid_21626385 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-Algorithm", valid_21626385
  var valid_21626386 = header.getOrDefault("X-Amz-Signature")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "X-Amz-Signature", valid_21626386
  var valid_21626387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626387 = validateParameter(valid_21626387, JString, required = false,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626387
  var valid_21626388 = header.getOrDefault("X-Amz-Credential")
  valid_21626388 = validateParameter(valid_21626388, JString, required = false,
                                   default = nil)
  if valid_21626388 != nil:
    section.add "X-Amz-Credential", valid_21626388
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldName: JString (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626389 = formData.getOrDefault("DomainName")
  valid_21626389 = validateParameter(valid_21626389, JString, required = true,
                                   default = nil)
  if valid_21626389 != nil:
    section.add "DomainName", valid_21626389
  var valid_21626390 = formData.getOrDefault("IndexFieldName")
  valid_21626390 = validateParameter(valid_21626390, JString, required = true,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "IndexFieldName", valid_21626390
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626391: Call_PostDeleteIndexField_21626377; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626391.validator(path, query, header, formData, body, _)
  let scheme = call_21626391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626391.makeUrl(scheme.get, call_21626391.host, call_21626391.base,
                               call_21626391.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626391, uri, valid, _)

proc call*(call_21626392: Call_PostDeleteIndexField_21626377; DomainName: string;
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
  var query_21626393 = newJObject()
  var formData_21626394 = newJObject()
  add(formData_21626394, "DomainName", newJString(DomainName))
  add(formData_21626394, "IndexFieldName", newJString(IndexFieldName))
  add(query_21626393, "Action", newJString(Action))
  add(query_21626393, "Version", newJString(Version))
  result = call_21626392.call(nil, query_21626393, nil, formData_21626394, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_21626377(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_21626378, base: "/",
    makeUrl: url_PostDeleteIndexField_21626379,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_21626360 = ref object of OpenApiRestCall_21625435
proc url_GetDeleteIndexField_21626362(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteIndexField_21626361(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IndexFieldName: JString (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `IndexFieldName` field"
  var valid_21626363 = query.getOrDefault("IndexFieldName")
  valid_21626363 = validateParameter(valid_21626363, JString, required = true,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "IndexFieldName", valid_21626363
  var valid_21626364 = query.getOrDefault("Action")
  valid_21626364 = validateParameter(valid_21626364, JString, required = true,
                                   default = newJString("DeleteIndexField"))
  if valid_21626364 != nil:
    section.add "Action", valid_21626364
  var valid_21626365 = query.getOrDefault("DomainName")
  valid_21626365 = validateParameter(valid_21626365, JString, required = true,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "DomainName", valid_21626365
  var valid_21626366 = query.getOrDefault("Version")
  valid_21626366 = validateParameter(valid_21626366, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626366 != nil:
    section.add "Version", valid_21626366
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
  var valid_21626367 = header.getOrDefault("X-Amz-Date")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Date", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Security-Token", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626369
  var valid_21626370 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-Algorithm", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-Signature")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-Signature", valid_21626371
  var valid_21626372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626372 = validateParameter(valid_21626372, JString, required = false,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626372
  var valid_21626373 = header.getOrDefault("X-Amz-Credential")
  valid_21626373 = validateParameter(valid_21626373, JString, required = false,
                                   default = nil)
  if valid_21626373 != nil:
    section.add "X-Amz-Credential", valid_21626373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626374: Call_GetDeleteIndexField_21626360; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626374.validator(path, query, header, formData, body, _)
  let scheme = call_21626374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626374.makeUrl(scheme.get, call_21626374.host, call_21626374.base,
                               call_21626374.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626374, uri, valid, _)

proc call*(call_21626375: Call_GetDeleteIndexField_21626360;
          IndexFieldName: string; DomainName: string;
          Action: string = "DeleteIndexField"; Version: string = "2013-01-01"): Recallable =
  ## getDeleteIndexField
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   IndexFieldName: string (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_21626376 = newJObject()
  add(query_21626376, "IndexFieldName", newJString(IndexFieldName))
  add(query_21626376, "Action", newJString(Action))
  add(query_21626376, "DomainName", newJString(DomainName))
  add(query_21626376, "Version", newJString(Version))
  result = call_21626375.call(nil, query_21626376, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_21626360(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_21626361, base: "/",
    makeUrl: url_GetDeleteIndexField_21626362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteSuggester_21626412 = ref object of OpenApiRestCall_21625435
proc url_PostDeleteSuggester_21626414(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteSuggester_21626413(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626415 = query.getOrDefault("Action")
  valid_21626415 = validateParameter(valid_21626415, JString, required = true,
                                   default = newJString("DeleteSuggester"))
  if valid_21626415 != nil:
    section.add "Action", valid_21626415
  var valid_21626416 = query.getOrDefault("Version")
  valid_21626416 = validateParameter(valid_21626416, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626416 != nil:
    section.add "Version", valid_21626416
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
  var valid_21626417 = header.getOrDefault("X-Amz-Date")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "X-Amz-Date", valid_21626417
  var valid_21626418 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626418 = validateParameter(valid_21626418, JString, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "X-Amz-Security-Token", valid_21626418
  var valid_21626419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626419 = validateParameter(valid_21626419, JString, required = false,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626419
  var valid_21626420 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626420 = validateParameter(valid_21626420, JString, required = false,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "X-Amz-Algorithm", valid_21626420
  var valid_21626421 = header.getOrDefault("X-Amz-Signature")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "X-Amz-Signature", valid_21626421
  var valid_21626422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-Credential")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-Credential", valid_21626423
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   SuggesterName: JString (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626424 = formData.getOrDefault("DomainName")
  valid_21626424 = validateParameter(valid_21626424, JString, required = true,
                                   default = nil)
  if valid_21626424 != nil:
    section.add "DomainName", valid_21626424
  var valid_21626425 = formData.getOrDefault("SuggesterName")
  valid_21626425 = validateParameter(valid_21626425, JString, required = true,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "SuggesterName", valid_21626425
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626426: Call_PostDeleteSuggester_21626412; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626426.validator(path, query, header, formData, body, _)
  let scheme = call_21626426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626426.makeUrl(scheme.get, call_21626426.host, call_21626426.base,
                               call_21626426.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626426, uri, valid, _)

proc call*(call_21626427: Call_PostDeleteSuggester_21626412; DomainName: string;
          SuggesterName: string; Action: string = "DeleteSuggester";
          Version: string = "2013-01-01"): Recallable =
  ## postDeleteSuggester
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   SuggesterName: string (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   Version: string (required)
  var query_21626428 = newJObject()
  var formData_21626429 = newJObject()
  add(formData_21626429, "DomainName", newJString(DomainName))
  add(query_21626428, "Action", newJString(Action))
  add(formData_21626429, "SuggesterName", newJString(SuggesterName))
  add(query_21626428, "Version", newJString(Version))
  result = call_21626427.call(nil, query_21626428, nil, formData_21626429, nil)

var postDeleteSuggester* = Call_PostDeleteSuggester_21626412(
    name: "postDeleteSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_PostDeleteSuggester_21626413, base: "/",
    makeUrl: url_PostDeleteSuggester_21626414,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteSuggester_21626395 = ref object of OpenApiRestCall_21625435
proc url_GetDeleteSuggester_21626397(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteSuggester_21626396(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   SuggesterName: JString (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626398 = query.getOrDefault("Action")
  valid_21626398 = validateParameter(valid_21626398, JString, required = true,
                                   default = newJString("DeleteSuggester"))
  if valid_21626398 != nil:
    section.add "Action", valid_21626398
  var valid_21626399 = query.getOrDefault("SuggesterName")
  valid_21626399 = validateParameter(valid_21626399, JString, required = true,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "SuggesterName", valid_21626399
  var valid_21626400 = query.getOrDefault("DomainName")
  valid_21626400 = validateParameter(valid_21626400, JString, required = true,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "DomainName", valid_21626400
  var valid_21626401 = query.getOrDefault("Version")
  valid_21626401 = validateParameter(valid_21626401, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626401 != nil:
    section.add "Version", valid_21626401
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
  var valid_21626402 = header.getOrDefault("X-Amz-Date")
  valid_21626402 = validateParameter(valid_21626402, JString, required = false,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "X-Amz-Date", valid_21626402
  var valid_21626403 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626403 = validateParameter(valid_21626403, JString, required = false,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "X-Amz-Security-Token", valid_21626403
  var valid_21626404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626404 = validateParameter(valid_21626404, JString, required = false,
                                   default = nil)
  if valid_21626404 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626404
  var valid_21626405 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626405 = validateParameter(valid_21626405, JString, required = false,
                                   default = nil)
  if valid_21626405 != nil:
    section.add "X-Amz-Algorithm", valid_21626405
  var valid_21626406 = header.getOrDefault("X-Amz-Signature")
  valid_21626406 = validateParameter(valid_21626406, JString, required = false,
                                   default = nil)
  if valid_21626406 != nil:
    section.add "X-Amz-Signature", valid_21626406
  var valid_21626407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626407
  var valid_21626408 = header.getOrDefault("X-Amz-Credential")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "X-Amz-Credential", valid_21626408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626409: Call_GetDeleteSuggester_21626395; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626409.validator(path, query, header, formData, body, _)
  let scheme = call_21626409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626409.makeUrl(scheme.get, call_21626409.host, call_21626409.base,
                               call_21626409.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626409, uri, valid, _)

proc call*(call_21626410: Call_GetDeleteSuggester_21626395; SuggesterName: string;
          DomainName: string; Action: string = "DeleteSuggester";
          Version: string = "2013-01-01"): Recallable =
  ## getDeleteSuggester
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   SuggesterName: string (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_21626411 = newJObject()
  add(query_21626411, "Action", newJString(Action))
  add(query_21626411, "SuggesterName", newJString(SuggesterName))
  add(query_21626411, "DomainName", newJString(DomainName))
  add(query_21626411, "Version", newJString(Version))
  result = call_21626410.call(nil, query_21626411, nil, nil, nil)

var getDeleteSuggester* = Call_GetDeleteSuggester_21626395(
    name: "getDeleteSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_GetDeleteSuggester_21626396, base: "/",
    makeUrl: url_GetDeleteSuggester_21626397, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAnalysisSchemes_21626448 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeAnalysisSchemes_21626450(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAnalysisSchemes_21626449(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626451 = query.getOrDefault("Action")
  valid_21626451 = validateParameter(valid_21626451, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_21626451 != nil:
    section.add "Action", valid_21626451
  var valid_21626452 = query.getOrDefault("Version")
  valid_21626452 = validateParameter(valid_21626452, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626452 != nil:
    section.add "Version", valid_21626452
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
  var valid_21626453 = header.getOrDefault("X-Amz-Date")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-Date", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626454 = validateParameter(valid_21626454, JString, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "X-Amz-Security-Token", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-Algorithm", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Signature")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Signature", valid_21626457
  var valid_21626458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626458 = validateParameter(valid_21626458, JString, required = false,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626458
  var valid_21626459 = header.getOrDefault("X-Amz-Credential")
  valid_21626459 = validateParameter(valid_21626459, JString, required = false,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "X-Amz-Credential", valid_21626459
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626460 = formData.getOrDefault("DomainName")
  valid_21626460 = validateParameter(valid_21626460, JString, required = true,
                                   default = nil)
  if valid_21626460 != nil:
    section.add "DomainName", valid_21626460
  var valid_21626461 = formData.getOrDefault("Deployed")
  valid_21626461 = validateParameter(valid_21626461, JBool, required = false,
                                   default = nil)
  if valid_21626461 != nil:
    section.add "Deployed", valid_21626461
  var valid_21626462 = formData.getOrDefault("AnalysisSchemeNames")
  valid_21626462 = validateParameter(valid_21626462, JArray, required = false,
                                   default = nil)
  if valid_21626462 != nil:
    section.add "AnalysisSchemeNames", valid_21626462
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626463: Call_PostDescribeAnalysisSchemes_21626448;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626463.validator(path, query, header, formData, body, _)
  let scheme = call_21626463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626463.makeUrl(scheme.get, call_21626463.host, call_21626463.base,
                               call_21626463.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626463, uri, valid, _)

proc call*(call_21626464: Call_PostDescribeAnalysisSchemes_21626448;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeAnalysisSchemes";
          AnalysisSchemeNames: JsonNode = nil; Version: string = "2013-01-01"): Recallable =
  ## postDescribeAnalysisSchemes
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  ##   Version: string (required)
  var query_21626465 = newJObject()
  var formData_21626466 = newJObject()
  add(formData_21626466, "DomainName", newJString(DomainName))
  add(formData_21626466, "Deployed", newJBool(Deployed))
  add(query_21626465, "Action", newJString(Action))
  if AnalysisSchemeNames != nil:
    formData_21626466.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_21626465, "Version", newJString(Version))
  result = call_21626464.call(nil, query_21626465, nil, formData_21626466, nil)

var postDescribeAnalysisSchemes* = Call_PostDescribeAnalysisSchemes_21626448(
    name: "postDescribeAnalysisSchemes", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_PostDescribeAnalysisSchemes_21626449, base: "/",
    makeUrl: url_PostDescribeAnalysisSchemes_21626450,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAnalysisSchemes_21626430 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeAnalysisSchemes_21626432(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAnalysisSchemes_21626431(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626433 = query.getOrDefault("Deployed")
  valid_21626433 = validateParameter(valid_21626433, JBool, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "Deployed", valid_21626433
  var valid_21626434 = query.getOrDefault("AnalysisSchemeNames")
  valid_21626434 = validateParameter(valid_21626434, JArray, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "AnalysisSchemeNames", valid_21626434
  var valid_21626435 = query.getOrDefault("Action")
  valid_21626435 = validateParameter(valid_21626435, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_21626435 != nil:
    section.add "Action", valid_21626435
  var valid_21626436 = query.getOrDefault("DomainName")
  valid_21626436 = validateParameter(valid_21626436, JString, required = true,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "DomainName", valid_21626436
  var valid_21626437 = query.getOrDefault("Version")
  valid_21626437 = validateParameter(valid_21626437, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626437 != nil:
    section.add "Version", valid_21626437
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
  var valid_21626438 = header.getOrDefault("X-Amz-Date")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Date", valid_21626438
  var valid_21626439 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626439 = validateParameter(valid_21626439, JString, required = false,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "X-Amz-Security-Token", valid_21626439
  var valid_21626440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626440
  var valid_21626441 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626441 = validateParameter(valid_21626441, JString, required = false,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "X-Amz-Algorithm", valid_21626441
  var valid_21626442 = header.getOrDefault("X-Amz-Signature")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-Signature", valid_21626442
  var valid_21626443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626443 = validateParameter(valid_21626443, JString, required = false,
                                   default = nil)
  if valid_21626443 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626443
  var valid_21626444 = header.getOrDefault("X-Amz-Credential")
  valid_21626444 = validateParameter(valid_21626444, JString, required = false,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "X-Amz-Credential", valid_21626444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626445: Call_GetDescribeAnalysisSchemes_21626430;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626445.validator(path, query, header, formData, body, _)
  let scheme = call_21626445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626445.makeUrl(scheme.get, call_21626445.host, call_21626445.base,
                               call_21626445.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626445, uri, valid, _)

proc call*(call_21626446: Call_GetDescribeAnalysisSchemes_21626430;
          DomainName: string; Deployed: bool = false;
          AnalysisSchemeNames: JsonNode = nil;
          Action: string = "DescribeAnalysisSchemes"; Version: string = "2013-01-01"): Recallable =
  ## getDescribeAnalysisSchemes
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_21626447 = newJObject()
  add(query_21626447, "Deployed", newJBool(Deployed))
  if AnalysisSchemeNames != nil:
    query_21626447.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_21626447, "Action", newJString(Action))
  add(query_21626447, "DomainName", newJString(DomainName))
  add(query_21626447, "Version", newJString(Version))
  result = call_21626446.call(nil, query_21626447, nil, nil, nil)

var getDescribeAnalysisSchemes* = Call_GetDescribeAnalysisSchemes_21626430(
    name: "getDescribeAnalysisSchemes", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_GetDescribeAnalysisSchemes_21626431, base: "/",
    makeUrl: url_GetDescribeAnalysisSchemes_21626432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_21626484 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeAvailabilityOptions_21626486(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAvailabilityOptions_21626485(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626487 = query.getOrDefault("Action")
  valid_21626487 = validateParameter(valid_21626487, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_21626487 != nil:
    section.add "Action", valid_21626487
  var valid_21626488 = query.getOrDefault("Version")
  valid_21626488 = validateParameter(valid_21626488, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626488 != nil:
    section.add "Version", valid_21626488
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
  var valid_21626489 = header.getOrDefault("X-Amz-Date")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-Date", valid_21626489
  var valid_21626490 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626490 = validateParameter(valid_21626490, JString, required = false,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "X-Amz-Security-Token", valid_21626490
  var valid_21626491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626491 = validateParameter(valid_21626491, JString, required = false,
                                   default = nil)
  if valid_21626491 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626491
  var valid_21626492 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626492 = validateParameter(valid_21626492, JString, required = false,
                                   default = nil)
  if valid_21626492 != nil:
    section.add "X-Amz-Algorithm", valid_21626492
  var valid_21626493 = header.getOrDefault("X-Amz-Signature")
  valid_21626493 = validateParameter(valid_21626493, JString, required = false,
                                   default = nil)
  if valid_21626493 != nil:
    section.add "X-Amz-Signature", valid_21626493
  var valid_21626494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626494 = validateParameter(valid_21626494, JString, required = false,
                                   default = nil)
  if valid_21626494 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626494
  var valid_21626495 = header.getOrDefault("X-Amz-Credential")
  valid_21626495 = validateParameter(valid_21626495, JString, required = false,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "X-Amz-Credential", valid_21626495
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626496 = formData.getOrDefault("DomainName")
  valid_21626496 = validateParameter(valid_21626496, JString, required = true,
                                   default = nil)
  if valid_21626496 != nil:
    section.add "DomainName", valid_21626496
  var valid_21626497 = formData.getOrDefault("Deployed")
  valid_21626497 = validateParameter(valid_21626497, JBool, required = false,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "Deployed", valid_21626497
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626498: Call_PostDescribeAvailabilityOptions_21626484;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626498.validator(path, query, header, formData, body, _)
  let scheme = call_21626498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626498.makeUrl(scheme.get, call_21626498.host, call_21626498.base,
                               call_21626498.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626498, uri, valid, _)

proc call*(call_21626499: Call_PostDescribeAvailabilityOptions_21626484;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeAvailabilityOptions";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626500 = newJObject()
  var formData_21626501 = newJObject()
  add(formData_21626501, "DomainName", newJString(DomainName))
  add(formData_21626501, "Deployed", newJBool(Deployed))
  add(query_21626500, "Action", newJString(Action))
  add(query_21626500, "Version", newJString(Version))
  result = call_21626499.call(nil, query_21626500, nil, formData_21626501, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_21626484(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_21626485, base: "/",
    makeUrl: url_PostDescribeAvailabilityOptions_21626486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_21626467 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeAvailabilityOptions_21626469(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAvailabilityOptions_21626468(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626470 = query.getOrDefault("Deployed")
  valid_21626470 = validateParameter(valid_21626470, JBool, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "Deployed", valid_21626470
  var valid_21626471 = query.getOrDefault("Action")
  valid_21626471 = validateParameter(valid_21626471, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_21626471 != nil:
    section.add "Action", valid_21626471
  var valid_21626472 = query.getOrDefault("DomainName")
  valid_21626472 = validateParameter(valid_21626472, JString, required = true,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "DomainName", valid_21626472
  var valid_21626473 = query.getOrDefault("Version")
  valid_21626473 = validateParameter(valid_21626473, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626473 != nil:
    section.add "Version", valid_21626473
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
  var valid_21626474 = header.getOrDefault("X-Amz-Date")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Date", valid_21626474
  var valid_21626475 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626475 = validateParameter(valid_21626475, JString, required = false,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "X-Amz-Security-Token", valid_21626475
  var valid_21626476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626476 = validateParameter(valid_21626476, JString, required = false,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626476
  var valid_21626477 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626477 = validateParameter(valid_21626477, JString, required = false,
                                   default = nil)
  if valid_21626477 != nil:
    section.add "X-Amz-Algorithm", valid_21626477
  var valid_21626478 = header.getOrDefault("X-Amz-Signature")
  valid_21626478 = validateParameter(valid_21626478, JString, required = false,
                                   default = nil)
  if valid_21626478 != nil:
    section.add "X-Amz-Signature", valid_21626478
  var valid_21626479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626479 = validateParameter(valid_21626479, JString, required = false,
                                   default = nil)
  if valid_21626479 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626479
  var valid_21626480 = header.getOrDefault("X-Amz-Credential")
  valid_21626480 = validateParameter(valid_21626480, JString, required = false,
                                   default = nil)
  if valid_21626480 != nil:
    section.add "X-Amz-Credential", valid_21626480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626481: Call_GetDescribeAvailabilityOptions_21626467;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626481.validator(path, query, header, formData, body, _)
  let scheme = call_21626481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626481.makeUrl(scheme.get, call_21626481.host, call_21626481.base,
                               call_21626481.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626481, uri, valid, _)

proc call*(call_21626482: Call_GetDescribeAvailabilityOptions_21626467;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeAvailabilityOptions";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_21626483 = newJObject()
  add(query_21626483, "Deployed", newJBool(Deployed))
  add(query_21626483, "Action", newJString(Action))
  add(query_21626483, "DomainName", newJString(DomainName))
  add(query_21626483, "Version", newJString(Version))
  result = call_21626482.call(nil, query_21626483, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_21626467(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_21626468, base: "/",
    makeUrl: url_GetDescribeAvailabilityOptions_21626469,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomainEndpointOptions_21626519 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeDomainEndpointOptions_21626521(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDomainEndpointOptions_21626520(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626522 = query.getOrDefault("Action")
  valid_21626522 = validateParameter(valid_21626522, JString, required = true, default = newJString(
      "DescribeDomainEndpointOptions"))
  if valid_21626522 != nil:
    section.add "Action", valid_21626522
  var valid_21626523 = query.getOrDefault("Version")
  valid_21626523 = validateParameter(valid_21626523, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626523 != nil:
    section.add "Version", valid_21626523
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
  var valid_21626524 = header.getOrDefault("X-Amz-Date")
  valid_21626524 = validateParameter(valid_21626524, JString, required = false,
                                   default = nil)
  if valid_21626524 != nil:
    section.add "X-Amz-Date", valid_21626524
  var valid_21626525 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626525 = validateParameter(valid_21626525, JString, required = false,
                                   default = nil)
  if valid_21626525 != nil:
    section.add "X-Amz-Security-Token", valid_21626525
  var valid_21626526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626526 = validateParameter(valid_21626526, JString, required = false,
                                   default = nil)
  if valid_21626526 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626526
  var valid_21626527 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "X-Amz-Algorithm", valid_21626527
  var valid_21626528 = header.getOrDefault("X-Amz-Signature")
  valid_21626528 = validateParameter(valid_21626528, JString, required = false,
                                   default = nil)
  if valid_21626528 != nil:
    section.add "X-Amz-Signature", valid_21626528
  var valid_21626529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626529 = validateParameter(valid_21626529, JString, required = false,
                                   default = nil)
  if valid_21626529 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626529
  var valid_21626530 = header.getOrDefault("X-Amz-Credential")
  valid_21626530 = validateParameter(valid_21626530, JString, required = false,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "X-Amz-Credential", valid_21626530
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to retrieve the latest configuration (which might be in a Processing state) or the current, active configuration. Defaults to <code>false</code>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626531 = formData.getOrDefault("DomainName")
  valid_21626531 = validateParameter(valid_21626531, JString, required = true,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "DomainName", valid_21626531
  var valid_21626532 = formData.getOrDefault("Deployed")
  valid_21626532 = validateParameter(valid_21626532, JBool, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "Deployed", valid_21626532
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626533: Call_PostDescribeDomainEndpointOptions_21626519;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626533.validator(path, query, header, formData, body, _)
  let scheme = call_21626533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626533.makeUrl(scheme.get, call_21626533.host, call_21626533.base,
                               call_21626533.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626533, uri, valid, _)

proc call*(call_21626534: Call_PostDescribeDomainEndpointOptions_21626519;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeDomainEndpointOptions";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeDomainEndpointOptions
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to retrieve the latest configuration (which might be in a Processing state) or the current, active configuration. Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626535 = newJObject()
  var formData_21626536 = newJObject()
  add(formData_21626536, "DomainName", newJString(DomainName))
  add(formData_21626536, "Deployed", newJBool(Deployed))
  add(query_21626535, "Action", newJString(Action))
  add(query_21626535, "Version", newJString(Version))
  result = call_21626534.call(nil, query_21626535, nil, formData_21626536, nil)

var postDescribeDomainEndpointOptions* = Call_PostDescribeDomainEndpointOptions_21626519(
    name: "postDescribeDomainEndpointOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDomainEndpointOptions",
    validator: validate_PostDescribeDomainEndpointOptions_21626520, base: "/",
    makeUrl: url_PostDescribeDomainEndpointOptions_21626521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomainEndpointOptions_21626502 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeDomainEndpointOptions_21626504(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDomainEndpointOptions_21626503(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Deployed: JBool
  ##           : Whether to retrieve the latest configuration (which might be in a Processing state) or the current, active configuration. Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626505 = query.getOrDefault("Deployed")
  valid_21626505 = validateParameter(valid_21626505, JBool, required = false,
                                   default = nil)
  if valid_21626505 != nil:
    section.add "Deployed", valid_21626505
  var valid_21626506 = query.getOrDefault("Action")
  valid_21626506 = validateParameter(valid_21626506, JString, required = true, default = newJString(
      "DescribeDomainEndpointOptions"))
  if valid_21626506 != nil:
    section.add "Action", valid_21626506
  var valid_21626507 = query.getOrDefault("DomainName")
  valid_21626507 = validateParameter(valid_21626507, JString, required = true,
                                   default = nil)
  if valid_21626507 != nil:
    section.add "DomainName", valid_21626507
  var valid_21626508 = query.getOrDefault("Version")
  valid_21626508 = validateParameter(valid_21626508, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626508 != nil:
    section.add "Version", valid_21626508
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
  var valid_21626509 = header.getOrDefault("X-Amz-Date")
  valid_21626509 = validateParameter(valid_21626509, JString, required = false,
                                   default = nil)
  if valid_21626509 != nil:
    section.add "X-Amz-Date", valid_21626509
  var valid_21626510 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626510 = validateParameter(valid_21626510, JString, required = false,
                                   default = nil)
  if valid_21626510 != nil:
    section.add "X-Amz-Security-Token", valid_21626510
  var valid_21626511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626511 = validateParameter(valid_21626511, JString, required = false,
                                   default = nil)
  if valid_21626511 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626511
  var valid_21626512 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Algorithm", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-Signature")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-Signature", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626514 = validateParameter(valid_21626514, JString, required = false,
                                   default = nil)
  if valid_21626514 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626514
  var valid_21626515 = header.getOrDefault("X-Amz-Credential")
  valid_21626515 = validateParameter(valid_21626515, JString, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "X-Amz-Credential", valid_21626515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626516: Call_GetDescribeDomainEndpointOptions_21626502;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626516.validator(path, query, header, formData, body, _)
  let scheme = call_21626516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626516.makeUrl(scheme.get, call_21626516.host, call_21626516.base,
                               call_21626516.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626516, uri, valid, _)

proc call*(call_21626517: Call_GetDescribeDomainEndpointOptions_21626502;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeDomainEndpointOptions";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeDomainEndpointOptions
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to retrieve the latest configuration (which might be in a Processing state) or the current, active configuration. Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_21626518 = newJObject()
  add(query_21626518, "Deployed", newJBool(Deployed))
  add(query_21626518, "Action", newJString(Action))
  add(query_21626518, "DomainName", newJString(DomainName))
  add(query_21626518, "Version", newJString(Version))
  result = call_21626517.call(nil, query_21626518, nil, nil, nil)

var getDescribeDomainEndpointOptions* = Call_GetDescribeDomainEndpointOptions_21626502(
    name: "getDescribeDomainEndpointOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDomainEndpointOptions",
    validator: validate_GetDescribeDomainEndpointOptions_21626503, base: "/",
    makeUrl: url_GetDescribeDomainEndpointOptions_21626504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_21626553 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeDomains_21626555(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDomains_21626554(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626556 = query.getOrDefault("Action")
  valid_21626556 = validateParameter(valid_21626556, JString, required = true,
                                   default = newJString("DescribeDomains"))
  if valid_21626556 != nil:
    section.add "Action", valid_21626556
  var valid_21626557 = query.getOrDefault("Version")
  valid_21626557 = validateParameter(valid_21626557, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626557 != nil:
    section.add "Version", valid_21626557
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
  var valid_21626558 = header.getOrDefault("X-Amz-Date")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "X-Amz-Date", valid_21626558
  var valid_21626559 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626559 = validateParameter(valid_21626559, JString, required = false,
                                   default = nil)
  if valid_21626559 != nil:
    section.add "X-Amz-Security-Token", valid_21626559
  var valid_21626560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626560
  var valid_21626561 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "X-Amz-Algorithm", valid_21626561
  var valid_21626562 = header.getOrDefault("X-Amz-Signature")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "X-Amz-Signature", valid_21626562
  var valid_21626563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626563
  var valid_21626564 = header.getOrDefault("X-Amz-Credential")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "X-Amz-Credential", valid_21626564
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_21626565 = formData.getOrDefault("DomainNames")
  valid_21626565 = validateParameter(valid_21626565, JArray, required = false,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "DomainNames", valid_21626565
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626566: Call_PostDescribeDomains_21626553; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626566.validator(path, query, header, formData, body, _)
  let scheme = call_21626566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626566.makeUrl(scheme.get, call_21626566.host, call_21626566.base,
                               call_21626566.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626566, uri, valid, _)

proc call*(call_21626567: Call_PostDescribeDomains_21626553;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626568 = newJObject()
  var formData_21626569 = newJObject()
  if DomainNames != nil:
    formData_21626569.add "DomainNames", DomainNames
  add(query_21626568, "Action", newJString(Action))
  add(query_21626568, "Version", newJString(Version))
  result = call_21626567.call(nil, query_21626568, nil, formData_21626569, nil)

var postDescribeDomains* = Call_PostDescribeDomains_21626553(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_21626554, base: "/",
    makeUrl: url_PostDescribeDomains_21626555,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_21626537 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeDomains_21626539(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDomains_21626538(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626540 = query.getOrDefault("DomainNames")
  valid_21626540 = validateParameter(valid_21626540, JArray, required = false,
                                   default = nil)
  if valid_21626540 != nil:
    section.add "DomainNames", valid_21626540
  var valid_21626541 = query.getOrDefault("Action")
  valid_21626541 = validateParameter(valid_21626541, JString, required = true,
                                   default = newJString("DescribeDomains"))
  if valid_21626541 != nil:
    section.add "Action", valid_21626541
  var valid_21626542 = query.getOrDefault("Version")
  valid_21626542 = validateParameter(valid_21626542, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626542 != nil:
    section.add "Version", valid_21626542
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
  var valid_21626543 = header.getOrDefault("X-Amz-Date")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "X-Amz-Date", valid_21626543
  var valid_21626544 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626544 = validateParameter(valid_21626544, JString, required = false,
                                   default = nil)
  if valid_21626544 != nil:
    section.add "X-Amz-Security-Token", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-Algorithm", valid_21626546
  var valid_21626547 = header.getOrDefault("X-Amz-Signature")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-Signature", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626548
  var valid_21626549 = header.getOrDefault("X-Amz-Credential")
  valid_21626549 = validateParameter(valid_21626549, JString, required = false,
                                   default = nil)
  if valid_21626549 != nil:
    section.add "X-Amz-Credential", valid_21626549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626550: Call_GetDescribeDomains_21626537; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626550.validator(path, query, header, formData, body, _)
  let scheme = call_21626550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626550.makeUrl(scheme.get, call_21626550.host, call_21626550.base,
                               call_21626550.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626550, uri, valid, _)

proc call*(call_21626551: Call_GetDescribeDomains_21626537;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626552 = newJObject()
  if DomainNames != nil:
    query_21626552.add "DomainNames", DomainNames
  add(query_21626552, "Action", newJString(Action))
  add(query_21626552, "Version", newJString(Version))
  result = call_21626551.call(nil, query_21626552, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_21626537(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_21626538, base: "/",
    makeUrl: url_GetDescribeDomains_21626539, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeExpressions_21626588 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeExpressions_21626590(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeExpressions_21626589(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626591 = query.getOrDefault("Action")
  valid_21626591 = validateParameter(valid_21626591, JString, required = true,
                                   default = newJString("DescribeExpressions"))
  if valid_21626591 != nil:
    section.add "Action", valid_21626591
  var valid_21626592 = query.getOrDefault("Version")
  valid_21626592 = validateParameter(valid_21626592, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626592 != nil:
    section.add "Version", valid_21626592
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
  var valid_21626593 = header.getOrDefault("X-Amz-Date")
  valid_21626593 = validateParameter(valid_21626593, JString, required = false,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "X-Amz-Date", valid_21626593
  var valid_21626594 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626594 = validateParameter(valid_21626594, JString, required = false,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "X-Amz-Security-Token", valid_21626594
  var valid_21626595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626595 = validateParameter(valid_21626595, JString, required = false,
                                   default = nil)
  if valid_21626595 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626595
  var valid_21626596 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626596 = validateParameter(valid_21626596, JString, required = false,
                                   default = nil)
  if valid_21626596 != nil:
    section.add "X-Amz-Algorithm", valid_21626596
  var valid_21626597 = header.getOrDefault("X-Amz-Signature")
  valid_21626597 = validateParameter(valid_21626597, JString, required = false,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "X-Amz-Signature", valid_21626597
  var valid_21626598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626598 = validateParameter(valid_21626598, JString, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626598
  var valid_21626599 = header.getOrDefault("X-Amz-Credential")
  valid_21626599 = validateParameter(valid_21626599, JString, required = false,
                                   default = nil)
  if valid_21626599 != nil:
    section.add "X-Amz-Credential", valid_21626599
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626600 = formData.getOrDefault("DomainName")
  valid_21626600 = validateParameter(valid_21626600, JString, required = true,
                                   default = nil)
  if valid_21626600 != nil:
    section.add "DomainName", valid_21626600
  var valid_21626601 = formData.getOrDefault("Deployed")
  valid_21626601 = validateParameter(valid_21626601, JBool, required = false,
                                   default = nil)
  if valid_21626601 != nil:
    section.add "Deployed", valid_21626601
  var valid_21626602 = formData.getOrDefault("ExpressionNames")
  valid_21626602 = validateParameter(valid_21626602, JArray, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "ExpressionNames", valid_21626602
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626603: Call_PostDescribeExpressions_21626588;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626603.validator(path, query, header, formData, body, _)
  let scheme = call_21626603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626603.makeUrl(scheme.get, call_21626603.host, call_21626603.base,
                               call_21626603.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626603, uri, valid, _)

proc call*(call_21626604: Call_PostDescribeExpressions_21626588;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeExpressions"; ExpressionNames: JsonNode = nil;
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeExpressions
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  ##   Version: string (required)
  var query_21626605 = newJObject()
  var formData_21626606 = newJObject()
  add(formData_21626606, "DomainName", newJString(DomainName))
  add(formData_21626606, "Deployed", newJBool(Deployed))
  add(query_21626605, "Action", newJString(Action))
  if ExpressionNames != nil:
    formData_21626606.add "ExpressionNames", ExpressionNames
  add(query_21626605, "Version", newJString(Version))
  result = call_21626604.call(nil, query_21626605, nil, formData_21626606, nil)

var postDescribeExpressions* = Call_PostDescribeExpressions_21626588(
    name: "postDescribeExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_PostDescribeExpressions_21626589, base: "/",
    makeUrl: url_PostDescribeExpressions_21626590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeExpressions_21626570 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeExpressions_21626572(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeExpressions_21626571(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626573 = query.getOrDefault("Deployed")
  valid_21626573 = validateParameter(valid_21626573, JBool, required = false,
                                   default = nil)
  if valid_21626573 != nil:
    section.add "Deployed", valid_21626573
  var valid_21626574 = query.getOrDefault("ExpressionNames")
  valid_21626574 = validateParameter(valid_21626574, JArray, required = false,
                                   default = nil)
  if valid_21626574 != nil:
    section.add "ExpressionNames", valid_21626574
  var valid_21626575 = query.getOrDefault("Action")
  valid_21626575 = validateParameter(valid_21626575, JString, required = true,
                                   default = newJString("DescribeExpressions"))
  if valid_21626575 != nil:
    section.add "Action", valid_21626575
  var valid_21626576 = query.getOrDefault("DomainName")
  valid_21626576 = validateParameter(valid_21626576, JString, required = true,
                                   default = nil)
  if valid_21626576 != nil:
    section.add "DomainName", valid_21626576
  var valid_21626577 = query.getOrDefault("Version")
  valid_21626577 = validateParameter(valid_21626577, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626577 != nil:
    section.add "Version", valid_21626577
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
  var valid_21626578 = header.getOrDefault("X-Amz-Date")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "X-Amz-Date", valid_21626578
  var valid_21626579 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-Security-Token", valid_21626579
  var valid_21626580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626580 = validateParameter(valid_21626580, JString, required = false,
                                   default = nil)
  if valid_21626580 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626580
  var valid_21626581 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626581 = validateParameter(valid_21626581, JString, required = false,
                                   default = nil)
  if valid_21626581 != nil:
    section.add "X-Amz-Algorithm", valid_21626581
  var valid_21626582 = header.getOrDefault("X-Amz-Signature")
  valid_21626582 = validateParameter(valid_21626582, JString, required = false,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "X-Amz-Signature", valid_21626582
  var valid_21626583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626583 = validateParameter(valid_21626583, JString, required = false,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626583
  var valid_21626584 = header.getOrDefault("X-Amz-Credential")
  valid_21626584 = validateParameter(valid_21626584, JString, required = false,
                                   default = nil)
  if valid_21626584 != nil:
    section.add "X-Amz-Credential", valid_21626584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626585: Call_GetDescribeExpressions_21626570;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626585.validator(path, query, header, formData, body, _)
  let scheme = call_21626585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626585.makeUrl(scheme.get, call_21626585.host, call_21626585.base,
                               call_21626585.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626585, uri, valid, _)

proc call*(call_21626586: Call_GetDescribeExpressions_21626570; DomainName: string;
          Deployed: bool = false; ExpressionNames: JsonNode = nil;
          Action: string = "DescribeExpressions"; Version: string = "2013-01-01"): Recallable =
  ## getDescribeExpressions
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_21626587 = newJObject()
  add(query_21626587, "Deployed", newJBool(Deployed))
  if ExpressionNames != nil:
    query_21626587.add "ExpressionNames", ExpressionNames
  add(query_21626587, "Action", newJString(Action))
  add(query_21626587, "DomainName", newJString(DomainName))
  add(query_21626587, "Version", newJString(Version))
  result = call_21626586.call(nil, query_21626587, nil, nil, nil)

var getDescribeExpressions* = Call_GetDescribeExpressions_21626570(
    name: "getDescribeExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_GetDescribeExpressions_21626571, base: "/",
    makeUrl: url_GetDescribeExpressions_21626572,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_21626625 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeIndexFields_21626627(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeIndexFields_21626626(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626628 = query.getOrDefault("Action")
  valid_21626628 = validateParameter(valid_21626628, JString, required = true,
                                   default = newJString("DescribeIndexFields"))
  if valid_21626628 != nil:
    section.add "Action", valid_21626628
  var valid_21626629 = query.getOrDefault("Version")
  valid_21626629 = validateParameter(valid_21626629, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626629 != nil:
    section.add "Version", valid_21626629
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
  var valid_21626630 = header.getOrDefault("X-Amz-Date")
  valid_21626630 = validateParameter(valid_21626630, JString, required = false,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "X-Amz-Date", valid_21626630
  var valid_21626631 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "X-Amz-Security-Token", valid_21626631
  var valid_21626632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-Algorithm", valid_21626633
  var valid_21626634 = header.getOrDefault("X-Amz-Signature")
  valid_21626634 = validateParameter(valid_21626634, JString, required = false,
                                   default = nil)
  if valid_21626634 != nil:
    section.add "X-Amz-Signature", valid_21626634
  var valid_21626635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626635 = validateParameter(valid_21626635, JString, required = false,
                                   default = nil)
  if valid_21626635 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626635
  var valid_21626636 = header.getOrDefault("X-Amz-Credential")
  valid_21626636 = validateParameter(valid_21626636, JString, required = false,
                                   default = nil)
  if valid_21626636 != nil:
    section.add "X-Amz-Credential", valid_21626636
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626637 = formData.getOrDefault("DomainName")
  valid_21626637 = validateParameter(valid_21626637, JString, required = true,
                                   default = nil)
  if valid_21626637 != nil:
    section.add "DomainName", valid_21626637
  var valid_21626638 = formData.getOrDefault("Deployed")
  valid_21626638 = validateParameter(valid_21626638, JBool, required = false,
                                   default = nil)
  if valid_21626638 != nil:
    section.add "Deployed", valid_21626638
  var valid_21626639 = formData.getOrDefault("FieldNames")
  valid_21626639 = validateParameter(valid_21626639, JArray, required = false,
                                   default = nil)
  if valid_21626639 != nil:
    section.add "FieldNames", valid_21626639
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626640: Call_PostDescribeIndexFields_21626625;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626640.validator(path, query, header, formData, body, _)
  let scheme = call_21626640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626640.makeUrl(scheme.get, call_21626640.host, call_21626640.base,
                               call_21626640.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626640, uri, valid, _)

proc call*(call_21626641: Call_PostDescribeIndexFields_21626625;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeIndexFields"; FieldNames: JsonNode = nil;
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  ##   Version: string (required)
  var query_21626642 = newJObject()
  var formData_21626643 = newJObject()
  add(formData_21626643, "DomainName", newJString(DomainName))
  add(formData_21626643, "Deployed", newJBool(Deployed))
  add(query_21626642, "Action", newJString(Action))
  if FieldNames != nil:
    formData_21626643.add "FieldNames", FieldNames
  add(query_21626642, "Version", newJString(Version))
  result = call_21626641.call(nil, query_21626642, nil, formData_21626643, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_21626625(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_21626626, base: "/",
    makeUrl: url_PostDescribeIndexFields_21626627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_21626607 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeIndexFields_21626609(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeIndexFields_21626608(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626610 = query.getOrDefault("Deployed")
  valid_21626610 = validateParameter(valid_21626610, JBool, required = false,
                                   default = nil)
  if valid_21626610 != nil:
    section.add "Deployed", valid_21626610
  var valid_21626611 = query.getOrDefault("FieldNames")
  valid_21626611 = validateParameter(valid_21626611, JArray, required = false,
                                   default = nil)
  if valid_21626611 != nil:
    section.add "FieldNames", valid_21626611
  var valid_21626612 = query.getOrDefault("Action")
  valid_21626612 = validateParameter(valid_21626612, JString, required = true,
                                   default = newJString("DescribeIndexFields"))
  if valid_21626612 != nil:
    section.add "Action", valid_21626612
  var valid_21626613 = query.getOrDefault("DomainName")
  valid_21626613 = validateParameter(valid_21626613, JString, required = true,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "DomainName", valid_21626613
  var valid_21626614 = query.getOrDefault("Version")
  valid_21626614 = validateParameter(valid_21626614, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626614 != nil:
    section.add "Version", valid_21626614
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
  var valid_21626615 = header.getOrDefault("X-Amz-Date")
  valid_21626615 = validateParameter(valid_21626615, JString, required = false,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "X-Amz-Date", valid_21626615
  var valid_21626616 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626616 = validateParameter(valid_21626616, JString, required = false,
                                   default = nil)
  if valid_21626616 != nil:
    section.add "X-Amz-Security-Token", valid_21626616
  var valid_21626617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-Algorithm", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-Signature")
  valid_21626619 = validateParameter(valid_21626619, JString, required = false,
                                   default = nil)
  if valid_21626619 != nil:
    section.add "X-Amz-Signature", valid_21626619
  var valid_21626620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626620 = validateParameter(valid_21626620, JString, required = false,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626620
  var valid_21626621 = header.getOrDefault("X-Amz-Credential")
  valid_21626621 = validateParameter(valid_21626621, JString, required = false,
                                   default = nil)
  if valid_21626621 != nil:
    section.add "X-Amz-Credential", valid_21626621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626622: Call_GetDescribeIndexFields_21626607;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626622.validator(path, query, header, formData, body, _)
  let scheme = call_21626622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626622.makeUrl(scheme.get, call_21626622.host, call_21626622.base,
                               call_21626622.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626622, uri, valid, _)

proc call*(call_21626623: Call_GetDescribeIndexFields_21626607; DomainName: string;
          Deployed: bool = false; FieldNames: JsonNode = nil;
          Action: string = "DescribeIndexFields"; Version: string = "2013-01-01"): Recallable =
  ## getDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_21626624 = newJObject()
  add(query_21626624, "Deployed", newJBool(Deployed))
  if FieldNames != nil:
    query_21626624.add "FieldNames", FieldNames
  add(query_21626624, "Action", newJString(Action))
  add(query_21626624, "DomainName", newJString(DomainName))
  add(query_21626624, "Version", newJString(Version))
  result = call_21626623.call(nil, query_21626624, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_21626607(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_21626608, base: "/",
    makeUrl: url_GetDescribeIndexFields_21626609,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeScalingParameters_21626660 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeScalingParameters_21626662(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeScalingParameters_21626661(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626663 = query.getOrDefault("Action")
  valid_21626663 = validateParameter(valid_21626663, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_21626663 != nil:
    section.add "Action", valid_21626663
  var valid_21626664 = query.getOrDefault("Version")
  valid_21626664 = validateParameter(valid_21626664, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626664 != nil:
    section.add "Version", valid_21626664
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
  var valid_21626665 = header.getOrDefault("X-Amz-Date")
  valid_21626665 = validateParameter(valid_21626665, JString, required = false,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "X-Amz-Date", valid_21626665
  var valid_21626666 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626666 = validateParameter(valid_21626666, JString, required = false,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "X-Amz-Security-Token", valid_21626666
  var valid_21626667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626667 = validateParameter(valid_21626667, JString, required = false,
                                   default = nil)
  if valid_21626667 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626667
  var valid_21626668 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626668 = validateParameter(valid_21626668, JString, required = false,
                                   default = nil)
  if valid_21626668 != nil:
    section.add "X-Amz-Algorithm", valid_21626668
  var valid_21626669 = header.getOrDefault("X-Amz-Signature")
  valid_21626669 = validateParameter(valid_21626669, JString, required = false,
                                   default = nil)
  if valid_21626669 != nil:
    section.add "X-Amz-Signature", valid_21626669
  var valid_21626670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626670 = validateParameter(valid_21626670, JString, required = false,
                                   default = nil)
  if valid_21626670 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626670
  var valid_21626671 = header.getOrDefault("X-Amz-Credential")
  valid_21626671 = validateParameter(valid_21626671, JString, required = false,
                                   default = nil)
  if valid_21626671 != nil:
    section.add "X-Amz-Credential", valid_21626671
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626672 = formData.getOrDefault("DomainName")
  valid_21626672 = validateParameter(valid_21626672, JString, required = true,
                                   default = nil)
  if valid_21626672 != nil:
    section.add "DomainName", valid_21626672
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626673: Call_PostDescribeScalingParameters_21626660;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626673.validator(path, query, header, formData, body, _)
  let scheme = call_21626673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626673.makeUrl(scheme.get, call_21626673.host, call_21626673.base,
                               call_21626673.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626673, uri, valid, _)

proc call*(call_21626674: Call_PostDescribeScalingParameters_21626660;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626675 = newJObject()
  var formData_21626676 = newJObject()
  add(formData_21626676, "DomainName", newJString(DomainName))
  add(query_21626675, "Action", newJString(Action))
  add(query_21626675, "Version", newJString(Version))
  result = call_21626674.call(nil, query_21626675, nil, formData_21626676, nil)

var postDescribeScalingParameters* = Call_PostDescribeScalingParameters_21626660(
    name: "postDescribeScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_PostDescribeScalingParameters_21626661, base: "/",
    makeUrl: url_PostDescribeScalingParameters_21626662,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeScalingParameters_21626644 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeScalingParameters_21626646(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeScalingParameters_21626645(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626647 = query.getOrDefault("Action")
  valid_21626647 = validateParameter(valid_21626647, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_21626647 != nil:
    section.add "Action", valid_21626647
  var valid_21626648 = query.getOrDefault("DomainName")
  valid_21626648 = validateParameter(valid_21626648, JString, required = true,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "DomainName", valid_21626648
  var valid_21626649 = query.getOrDefault("Version")
  valid_21626649 = validateParameter(valid_21626649, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626649 != nil:
    section.add "Version", valid_21626649
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
  var valid_21626650 = header.getOrDefault("X-Amz-Date")
  valid_21626650 = validateParameter(valid_21626650, JString, required = false,
                                   default = nil)
  if valid_21626650 != nil:
    section.add "X-Amz-Date", valid_21626650
  var valid_21626651 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626651 = validateParameter(valid_21626651, JString, required = false,
                                   default = nil)
  if valid_21626651 != nil:
    section.add "X-Amz-Security-Token", valid_21626651
  var valid_21626652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626652 = validateParameter(valid_21626652, JString, required = false,
                                   default = nil)
  if valid_21626652 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626652
  var valid_21626653 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626653 = validateParameter(valid_21626653, JString, required = false,
                                   default = nil)
  if valid_21626653 != nil:
    section.add "X-Amz-Algorithm", valid_21626653
  var valid_21626654 = header.getOrDefault("X-Amz-Signature")
  valid_21626654 = validateParameter(valid_21626654, JString, required = false,
                                   default = nil)
  if valid_21626654 != nil:
    section.add "X-Amz-Signature", valid_21626654
  var valid_21626655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626655 = validateParameter(valid_21626655, JString, required = false,
                                   default = nil)
  if valid_21626655 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626655
  var valid_21626656 = header.getOrDefault("X-Amz-Credential")
  valid_21626656 = validateParameter(valid_21626656, JString, required = false,
                                   default = nil)
  if valid_21626656 != nil:
    section.add "X-Amz-Credential", valid_21626656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626657: Call_GetDescribeScalingParameters_21626644;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626657.validator(path, query, header, formData, body, _)
  let scheme = call_21626657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626657.makeUrl(scheme.get, call_21626657.host, call_21626657.base,
                               call_21626657.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626657, uri, valid, _)

proc call*(call_21626658: Call_GetDescribeScalingParameters_21626644;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_21626659 = newJObject()
  add(query_21626659, "Action", newJString(Action))
  add(query_21626659, "DomainName", newJString(DomainName))
  add(query_21626659, "Version", newJString(Version))
  result = call_21626658.call(nil, query_21626659, nil, nil, nil)

var getDescribeScalingParameters* = Call_GetDescribeScalingParameters_21626644(
    name: "getDescribeScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_GetDescribeScalingParameters_21626645, base: "/",
    makeUrl: url_GetDescribeScalingParameters_21626646,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_21626694 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeServiceAccessPolicies_21626696(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeServiceAccessPolicies_21626695(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626697 = query.getOrDefault("Action")
  valid_21626697 = validateParameter(valid_21626697, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_21626697 != nil:
    section.add "Action", valid_21626697
  var valid_21626698 = query.getOrDefault("Version")
  valid_21626698 = validateParameter(valid_21626698, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626698 != nil:
    section.add "Version", valid_21626698
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
  var valid_21626699 = header.getOrDefault("X-Amz-Date")
  valid_21626699 = validateParameter(valid_21626699, JString, required = false,
                                   default = nil)
  if valid_21626699 != nil:
    section.add "X-Amz-Date", valid_21626699
  var valid_21626700 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626700 = validateParameter(valid_21626700, JString, required = false,
                                   default = nil)
  if valid_21626700 != nil:
    section.add "X-Amz-Security-Token", valid_21626700
  var valid_21626701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626701 = validateParameter(valid_21626701, JString, required = false,
                                   default = nil)
  if valid_21626701 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626701
  var valid_21626702 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626702 = validateParameter(valid_21626702, JString, required = false,
                                   default = nil)
  if valid_21626702 != nil:
    section.add "X-Amz-Algorithm", valid_21626702
  var valid_21626703 = header.getOrDefault("X-Amz-Signature")
  valid_21626703 = validateParameter(valid_21626703, JString, required = false,
                                   default = nil)
  if valid_21626703 != nil:
    section.add "X-Amz-Signature", valid_21626703
  var valid_21626704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626704 = validateParameter(valid_21626704, JString, required = false,
                                   default = nil)
  if valid_21626704 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626704
  var valid_21626705 = header.getOrDefault("X-Amz-Credential")
  valid_21626705 = validateParameter(valid_21626705, JString, required = false,
                                   default = nil)
  if valid_21626705 != nil:
    section.add "X-Amz-Credential", valid_21626705
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626706 = formData.getOrDefault("DomainName")
  valid_21626706 = validateParameter(valid_21626706, JString, required = true,
                                   default = nil)
  if valid_21626706 != nil:
    section.add "DomainName", valid_21626706
  var valid_21626707 = formData.getOrDefault("Deployed")
  valid_21626707 = validateParameter(valid_21626707, JBool, required = false,
                                   default = nil)
  if valid_21626707 != nil:
    section.add "Deployed", valid_21626707
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626708: Call_PostDescribeServiceAccessPolicies_21626694;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626708.validator(path, query, header, formData, body, _)
  let scheme = call_21626708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626708.makeUrl(scheme.get, call_21626708.host, call_21626708.base,
                               call_21626708.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626708, uri, valid, _)

proc call*(call_21626709: Call_PostDescribeServiceAccessPolicies_21626694;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeServiceAccessPolicies
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626710 = newJObject()
  var formData_21626711 = newJObject()
  add(formData_21626711, "DomainName", newJString(DomainName))
  add(formData_21626711, "Deployed", newJBool(Deployed))
  add(query_21626710, "Action", newJString(Action))
  add(query_21626710, "Version", newJString(Version))
  result = call_21626709.call(nil, query_21626710, nil, formData_21626711, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_21626694(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_21626695, base: "/",
    makeUrl: url_PostDescribeServiceAccessPolicies_21626696,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_21626677 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeServiceAccessPolicies_21626679(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeServiceAccessPolicies_21626678(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626680 = query.getOrDefault("Deployed")
  valid_21626680 = validateParameter(valid_21626680, JBool, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "Deployed", valid_21626680
  var valid_21626681 = query.getOrDefault("Action")
  valid_21626681 = validateParameter(valid_21626681, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_21626681 != nil:
    section.add "Action", valid_21626681
  var valid_21626682 = query.getOrDefault("DomainName")
  valid_21626682 = validateParameter(valid_21626682, JString, required = true,
                                   default = nil)
  if valid_21626682 != nil:
    section.add "DomainName", valid_21626682
  var valid_21626683 = query.getOrDefault("Version")
  valid_21626683 = validateParameter(valid_21626683, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626683 != nil:
    section.add "Version", valid_21626683
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
  var valid_21626684 = header.getOrDefault("X-Amz-Date")
  valid_21626684 = validateParameter(valid_21626684, JString, required = false,
                                   default = nil)
  if valid_21626684 != nil:
    section.add "X-Amz-Date", valid_21626684
  var valid_21626685 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626685 = validateParameter(valid_21626685, JString, required = false,
                                   default = nil)
  if valid_21626685 != nil:
    section.add "X-Amz-Security-Token", valid_21626685
  var valid_21626686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626686 = validateParameter(valid_21626686, JString, required = false,
                                   default = nil)
  if valid_21626686 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626686
  var valid_21626687 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626687 = validateParameter(valid_21626687, JString, required = false,
                                   default = nil)
  if valid_21626687 != nil:
    section.add "X-Amz-Algorithm", valid_21626687
  var valid_21626688 = header.getOrDefault("X-Amz-Signature")
  valid_21626688 = validateParameter(valid_21626688, JString, required = false,
                                   default = nil)
  if valid_21626688 != nil:
    section.add "X-Amz-Signature", valid_21626688
  var valid_21626689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626689 = validateParameter(valid_21626689, JString, required = false,
                                   default = nil)
  if valid_21626689 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626689
  var valid_21626690 = header.getOrDefault("X-Amz-Credential")
  valid_21626690 = validateParameter(valid_21626690, JString, required = false,
                                   default = nil)
  if valid_21626690 != nil:
    section.add "X-Amz-Credential", valid_21626690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626691: Call_GetDescribeServiceAccessPolicies_21626677;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626691.validator(path, query, header, formData, body, _)
  let scheme = call_21626691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626691.makeUrl(scheme.get, call_21626691.host, call_21626691.base,
                               call_21626691.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626691, uri, valid, _)

proc call*(call_21626692: Call_GetDescribeServiceAccessPolicies_21626677;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeServiceAccessPolicies
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_21626693 = newJObject()
  add(query_21626693, "Deployed", newJBool(Deployed))
  add(query_21626693, "Action", newJString(Action))
  add(query_21626693, "DomainName", newJString(DomainName))
  add(query_21626693, "Version", newJString(Version))
  result = call_21626692.call(nil, query_21626693, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_21626677(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_21626678, base: "/",
    makeUrl: url_GetDescribeServiceAccessPolicies_21626679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSuggesters_21626730 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeSuggesters_21626732(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeSuggesters_21626731(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626733 = query.getOrDefault("Action")
  valid_21626733 = validateParameter(valid_21626733, JString, required = true,
                                   default = newJString("DescribeSuggesters"))
  if valid_21626733 != nil:
    section.add "Action", valid_21626733
  var valid_21626734 = query.getOrDefault("Version")
  valid_21626734 = validateParameter(valid_21626734, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626734 != nil:
    section.add "Version", valid_21626734
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
  var valid_21626735 = header.getOrDefault("X-Amz-Date")
  valid_21626735 = validateParameter(valid_21626735, JString, required = false,
                                   default = nil)
  if valid_21626735 != nil:
    section.add "X-Amz-Date", valid_21626735
  var valid_21626736 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626736 = validateParameter(valid_21626736, JString, required = false,
                                   default = nil)
  if valid_21626736 != nil:
    section.add "X-Amz-Security-Token", valid_21626736
  var valid_21626737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626737 = validateParameter(valid_21626737, JString, required = false,
                                   default = nil)
  if valid_21626737 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626737
  var valid_21626738 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626738 = validateParameter(valid_21626738, JString, required = false,
                                   default = nil)
  if valid_21626738 != nil:
    section.add "X-Amz-Algorithm", valid_21626738
  var valid_21626739 = header.getOrDefault("X-Amz-Signature")
  valid_21626739 = validateParameter(valid_21626739, JString, required = false,
                                   default = nil)
  if valid_21626739 != nil:
    section.add "X-Amz-Signature", valid_21626739
  var valid_21626740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626740 = validateParameter(valid_21626740, JString, required = false,
                                   default = nil)
  if valid_21626740 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626740
  var valid_21626741 = header.getOrDefault("X-Amz-Credential")
  valid_21626741 = validateParameter(valid_21626741, JString, required = false,
                                   default = nil)
  if valid_21626741 != nil:
    section.add "X-Amz-Credential", valid_21626741
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626742 = formData.getOrDefault("DomainName")
  valid_21626742 = validateParameter(valid_21626742, JString, required = true,
                                   default = nil)
  if valid_21626742 != nil:
    section.add "DomainName", valid_21626742
  var valid_21626743 = formData.getOrDefault("Deployed")
  valid_21626743 = validateParameter(valid_21626743, JBool, required = false,
                                   default = nil)
  if valid_21626743 != nil:
    section.add "Deployed", valid_21626743
  var valid_21626744 = formData.getOrDefault("SuggesterNames")
  valid_21626744 = validateParameter(valid_21626744, JArray, required = false,
                                   default = nil)
  if valid_21626744 != nil:
    section.add "SuggesterNames", valid_21626744
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626745: Call_PostDescribeSuggesters_21626730;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626745.validator(path, query, header, formData, body, _)
  let scheme = call_21626745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626745.makeUrl(scheme.get, call_21626745.host, call_21626745.base,
                               call_21626745.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626745, uri, valid, _)

proc call*(call_21626746: Call_PostDescribeSuggesters_21626730; DomainName: string;
          Deployed: bool = false; Action: string = "DescribeSuggesters";
          SuggesterNames: JsonNode = nil; Version: string = "2013-01-01"): Recallable =
  ## postDescribeSuggesters
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  ##   Version: string (required)
  var query_21626747 = newJObject()
  var formData_21626748 = newJObject()
  add(formData_21626748, "DomainName", newJString(DomainName))
  add(formData_21626748, "Deployed", newJBool(Deployed))
  add(query_21626747, "Action", newJString(Action))
  if SuggesterNames != nil:
    formData_21626748.add "SuggesterNames", SuggesterNames
  add(query_21626747, "Version", newJString(Version))
  result = call_21626746.call(nil, query_21626747, nil, formData_21626748, nil)

var postDescribeSuggesters* = Call_PostDescribeSuggesters_21626730(
    name: "postDescribeSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_PostDescribeSuggesters_21626731, base: "/",
    makeUrl: url_PostDescribeSuggesters_21626732,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSuggesters_21626712 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeSuggesters_21626714(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeSuggesters_21626713(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  section = newJObject()
  var valid_21626715 = query.getOrDefault("Deployed")
  valid_21626715 = validateParameter(valid_21626715, JBool, required = false,
                                   default = nil)
  if valid_21626715 != nil:
    section.add "Deployed", valid_21626715
  var valid_21626716 = query.getOrDefault("Action")
  valid_21626716 = validateParameter(valid_21626716, JString, required = true,
                                   default = newJString("DescribeSuggesters"))
  if valid_21626716 != nil:
    section.add "Action", valid_21626716
  var valid_21626717 = query.getOrDefault("DomainName")
  valid_21626717 = validateParameter(valid_21626717, JString, required = true,
                                   default = nil)
  if valid_21626717 != nil:
    section.add "DomainName", valid_21626717
  var valid_21626718 = query.getOrDefault("Version")
  valid_21626718 = validateParameter(valid_21626718, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626718 != nil:
    section.add "Version", valid_21626718
  var valid_21626719 = query.getOrDefault("SuggesterNames")
  valid_21626719 = validateParameter(valid_21626719, JArray, required = false,
                                   default = nil)
  if valid_21626719 != nil:
    section.add "SuggesterNames", valid_21626719
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
  var valid_21626720 = header.getOrDefault("X-Amz-Date")
  valid_21626720 = validateParameter(valid_21626720, JString, required = false,
                                   default = nil)
  if valid_21626720 != nil:
    section.add "X-Amz-Date", valid_21626720
  var valid_21626721 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626721 = validateParameter(valid_21626721, JString, required = false,
                                   default = nil)
  if valid_21626721 != nil:
    section.add "X-Amz-Security-Token", valid_21626721
  var valid_21626722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626722 = validateParameter(valid_21626722, JString, required = false,
                                   default = nil)
  if valid_21626722 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626722
  var valid_21626723 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626723 = validateParameter(valid_21626723, JString, required = false,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "X-Amz-Algorithm", valid_21626723
  var valid_21626724 = header.getOrDefault("X-Amz-Signature")
  valid_21626724 = validateParameter(valid_21626724, JString, required = false,
                                   default = nil)
  if valid_21626724 != nil:
    section.add "X-Amz-Signature", valid_21626724
  var valid_21626725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626725 = validateParameter(valid_21626725, JString, required = false,
                                   default = nil)
  if valid_21626725 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626725
  var valid_21626726 = header.getOrDefault("X-Amz-Credential")
  valid_21626726 = validateParameter(valid_21626726, JString, required = false,
                                   default = nil)
  if valid_21626726 != nil:
    section.add "X-Amz-Credential", valid_21626726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626727: Call_GetDescribeSuggesters_21626712;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626727.validator(path, query, header, formData, body, _)
  let scheme = call_21626727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626727.makeUrl(scheme.get, call_21626727.host, call_21626727.base,
                               call_21626727.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626727, uri, valid, _)

proc call*(call_21626728: Call_GetDescribeSuggesters_21626712; DomainName: string;
          Deployed: bool = false; Action: string = "DescribeSuggesters";
          Version: string = "2013-01-01"; SuggesterNames: JsonNode = nil): Recallable =
  ## getDescribeSuggesters
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  var query_21626729 = newJObject()
  add(query_21626729, "Deployed", newJBool(Deployed))
  add(query_21626729, "Action", newJString(Action))
  add(query_21626729, "DomainName", newJString(DomainName))
  add(query_21626729, "Version", newJString(Version))
  if SuggesterNames != nil:
    query_21626729.add "SuggesterNames", SuggesterNames
  result = call_21626728.call(nil, query_21626729, nil, nil, nil)

var getDescribeSuggesters* = Call_GetDescribeSuggesters_21626712(
    name: "getDescribeSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_GetDescribeSuggesters_21626713, base: "/",
    makeUrl: url_GetDescribeSuggesters_21626714,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_21626765 = ref object of OpenApiRestCall_21625435
proc url_PostIndexDocuments_21626767(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostIndexDocuments_21626766(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626768 = query.getOrDefault("Action")
  valid_21626768 = validateParameter(valid_21626768, JString, required = true,
                                   default = newJString("IndexDocuments"))
  if valid_21626768 != nil:
    section.add "Action", valid_21626768
  var valid_21626769 = query.getOrDefault("Version")
  valid_21626769 = validateParameter(valid_21626769, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626769 != nil:
    section.add "Version", valid_21626769
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
  var valid_21626770 = header.getOrDefault("X-Amz-Date")
  valid_21626770 = validateParameter(valid_21626770, JString, required = false,
                                   default = nil)
  if valid_21626770 != nil:
    section.add "X-Amz-Date", valid_21626770
  var valid_21626771 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626771 = validateParameter(valid_21626771, JString, required = false,
                                   default = nil)
  if valid_21626771 != nil:
    section.add "X-Amz-Security-Token", valid_21626771
  var valid_21626772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626772 = validateParameter(valid_21626772, JString, required = false,
                                   default = nil)
  if valid_21626772 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626772
  var valid_21626773 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626773 = validateParameter(valid_21626773, JString, required = false,
                                   default = nil)
  if valid_21626773 != nil:
    section.add "X-Amz-Algorithm", valid_21626773
  var valid_21626774 = header.getOrDefault("X-Amz-Signature")
  valid_21626774 = validateParameter(valid_21626774, JString, required = false,
                                   default = nil)
  if valid_21626774 != nil:
    section.add "X-Amz-Signature", valid_21626774
  var valid_21626775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626775 = validateParameter(valid_21626775, JString, required = false,
                                   default = nil)
  if valid_21626775 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626775
  var valid_21626776 = header.getOrDefault("X-Amz-Credential")
  valid_21626776 = validateParameter(valid_21626776, JString, required = false,
                                   default = nil)
  if valid_21626776 != nil:
    section.add "X-Amz-Credential", valid_21626776
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626777 = formData.getOrDefault("DomainName")
  valid_21626777 = validateParameter(valid_21626777, JString, required = true,
                                   default = nil)
  if valid_21626777 != nil:
    section.add "DomainName", valid_21626777
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626778: Call_PostIndexDocuments_21626765; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_21626778.validator(path, query, header, formData, body, _)
  let scheme = call_21626778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626778.makeUrl(scheme.get, call_21626778.host, call_21626778.base,
                               call_21626778.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626778, uri, valid, _)

proc call*(call_21626779: Call_PostIndexDocuments_21626765; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626780 = newJObject()
  var formData_21626781 = newJObject()
  add(formData_21626781, "DomainName", newJString(DomainName))
  add(query_21626780, "Action", newJString(Action))
  add(query_21626780, "Version", newJString(Version))
  result = call_21626779.call(nil, query_21626780, nil, formData_21626781, nil)

var postIndexDocuments* = Call_PostIndexDocuments_21626765(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_21626766, base: "/",
    makeUrl: url_PostIndexDocuments_21626767, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_21626749 = ref object of OpenApiRestCall_21625435
proc url_GetIndexDocuments_21626751(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetIndexDocuments_21626750(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626752 = query.getOrDefault("Action")
  valid_21626752 = validateParameter(valid_21626752, JString, required = true,
                                   default = newJString("IndexDocuments"))
  if valid_21626752 != nil:
    section.add "Action", valid_21626752
  var valid_21626753 = query.getOrDefault("DomainName")
  valid_21626753 = validateParameter(valid_21626753, JString, required = true,
                                   default = nil)
  if valid_21626753 != nil:
    section.add "DomainName", valid_21626753
  var valid_21626754 = query.getOrDefault("Version")
  valid_21626754 = validateParameter(valid_21626754, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626754 != nil:
    section.add "Version", valid_21626754
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
  var valid_21626755 = header.getOrDefault("X-Amz-Date")
  valid_21626755 = validateParameter(valid_21626755, JString, required = false,
                                   default = nil)
  if valid_21626755 != nil:
    section.add "X-Amz-Date", valid_21626755
  var valid_21626756 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626756 = validateParameter(valid_21626756, JString, required = false,
                                   default = nil)
  if valid_21626756 != nil:
    section.add "X-Amz-Security-Token", valid_21626756
  var valid_21626757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626757 = validateParameter(valid_21626757, JString, required = false,
                                   default = nil)
  if valid_21626757 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626757
  var valid_21626758 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626758 = validateParameter(valid_21626758, JString, required = false,
                                   default = nil)
  if valid_21626758 != nil:
    section.add "X-Amz-Algorithm", valid_21626758
  var valid_21626759 = header.getOrDefault("X-Amz-Signature")
  valid_21626759 = validateParameter(valid_21626759, JString, required = false,
                                   default = nil)
  if valid_21626759 != nil:
    section.add "X-Amz-Signature", valid_21626759
  var valid_21626760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626760 = validateParameter(valid_21626760, JString, required = false,
                                   default = nil)
  if valid_21626760 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626760
  var valid_21626761 = header.getOrDefault("X-Amz-Credential")
  valid_21626761 = validateParameter(valid_21626761, JString, required = false,
                                   default = nil)
  if valid_21626761 != nil:
    section.add "X-Amz-Credential", valid_21626761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626762: Call_GetIndexDocuments_21626749; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_21626762.validator(path, query, header, formData, body, _)
  let scheme = call_21626762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626762.makeUrl(scheme.get, call_21626762.host, call_21626762.base,
                               call_21626762.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626762, uri, valid, _)

proc call*(call_21626763: Call_GetIndexDocuments_21626749; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_21626764 = newJObject()
  add(query_21626764, "Action", newJString(Action))
  add(query_21626764, "DomainName", newJString(DomainName))
  add(query_21626764, "Version", newJString(Version))
  result = call_21626763.call(nil, query_21626764, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_21626749(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_21626750,
    base: "/", makeUrl: url_GetIndexDocuments_21626751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomainNames_21626797 = ref object of OpenApiRestCall_21625435
proc url_PostListDomainNames_21626799(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListDomainNames_21626798(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626800 = query.getOrDefault("Action")
  valid_21626800 = validateParameter(valid_21626800, JString, required = true,
                                   default = newJString("ListDomainNames"))
  if valid_21626800 != nil:
    section.add "Action", valid_21626800
  var valid_21626801 = query.getOrDefault("Version")
  valid_21626801 = validateParameter(valid_21626801, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626801 != nil:
    section.add "Version", valid_21626801
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
  var valid_21626802 = header.getOrDefault("X-Amz-Date")
  valid_21626802 = validateParameter(valid_21626802, JString, required = false,
                                   default = nil)
  if valid_21626802 != nil:
    section.add "X-Amz-Date", valid_21626802
  var valid_21626803 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626803 = validateParameter(valid_21626803, JString, required = false,
                                   default = nil)
  if valid_21626803 != nil:
    section.add "X-Amz-Security-Token", valid_21626803
  var valid_21626804 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626804 = validateParameter(valid_21626804, JString, required = false,
                                   default = nil)
  if valid_21626804 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626804
  var valid_21626805 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626805 = validateParameter(valid_21626805, JString, required = false,
                                   default = nil)
  if valid_21626805 != nil:
    section.add "X-Amz-Algorithm", valid_21626805
  var valid_21626806 = header.getOrDefault("X-Amz-Signature")
  valid_21626806 = validateParameter(valid_21626806, JString, required = false,
                                   default = nil)
  if valid_21626806 != nil:
    section.add "X-Amz-Signature", valid_21626806
  var valid_21626807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626807 = validateParameter(valid_21626807, JString, required = false,
                                   default = nil)
  if valid_21626807 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626807
  var valid_21626808 = header.getOrDefault("X-Amz-Credential")
  valid_21626808 = validateParameter(valid_21626808, JString, required = false,
                                   default = nil)
  if valid_21626808 != nil:
    section.add "X-Amz-Credential", valid_21626808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626809: Call_PostListDomainNames_21626797; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_21626809.validator(path, query, header, formData, body, _)
  let scheme = call_21626809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626809.makeUrl(scheme.get, call_21626809.host, call_21626809.base,
                               call_21626809.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626809, uri, valid, _)

proc call*(call_21626810: Call_PostListDomainNames_21626797;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## postListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626811 = newJObject()
  add(query_21626811, "Action", newJString(Action))
  add(query_21626811, "Version", newJString(Version))
  result = call_21626810.call(nil, query_21626811, nil, nil, nil)

var postListDomainNames* = Call_PostListDomainNames_21626797(
    name: "postListDomainNames", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_PostListDomainNames_21626798, base: "/",
    makeUrl: url_PostListDomainNames_21626799,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomainNames_21626782 = ref object of OpenApiRestCall_21625435
proc url_GetListDomainNames_21626784(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListDomainNames_21626783(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626785 = query.getOrDefault("Action")
  valid_21626785 = validateParameter(valid_21626785, JString, required = true,
                                   default = newJString("ListDomainNames"))
  if valid_21626785 != nil:
    section.add "Action", valid_21626785
  var valid_21626786 = query.getOrDefault("Version")
  valid_21626786 = validateParameter(valid_21626786, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626786 != nil:
    section.add "Version", valid_21626786
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
  var valid_21626787 = header.getOrDefault("X-Amz-Date")
  valid_21626787 = validateParameter(valid_21626787, JString, required = false,
                                   default = nil)
  if valid_21626787 != nil:
    section.add "X-Amz-Date", valid_21626787
  var valid_21626788 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626788 = validateParameter(valid_21626788, JString, required = false,
                                   default = nil)
  if valid_21626788 != nil:
    section.add "X-Amz-Security-Token", valid_21626788
  var valid_21626789 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626789 = validateParameter(valid_21626789, JString, required = false,
                                   default = nil)
  if valid_21626789 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626789
  var valid_21626790 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626790 = validateParameter(valid_21626790, JString, required = false,
                                   default = nil)
  if valid_21626790 != nil:
    section.add "X-Amz-Algorithm", valid_21626790
  var valid_21626791 = header.getOrDefault("X-Amz-Signature")
  valid_21626791 = validateParameter(valid_21626791, JString, required = false,
                                   default = nil)
  if valid_21626791 != nil:
    section.add "X-Amz-Signature", valid_21626791
  var valid_21626792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626792 = validateParameter(valid_21626792, JString, required = false,
                                   default = nil)
  if valid_21626792 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626792
  var valid_21626793 = header.getOrDefault("X-Amz-Credential")
  valid_21626793 = validateParameter(valid_21626793, JString, required = false,
                                   default = nil)
  if valid_21626793 != nil:
    section.add "X-Amz-Credential", valid_21626793
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626794: Call_GetListDomainNames_21626782; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_21626794.validator(path, query, header, formData, body, _)
  let scheme = call_21626794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626794.makeUrl(scheme.get, call_21626794.host, call_21626794.base,
                               call_21626794.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626794, uri, valid, _)

proc call*(call_21626795: Call_GetListDomainNames_21626782;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## getListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626796 = newJObject()
  add(query_21626796, "Action", newJString(Action))
  add(query_21626796, "Version", newJString(Version))
  result = call_21626795.call(nil, query_21626796, nil, nil, nil)

var getListDomainNames* = Call_GetListDomainNames_21626782(
    name: "getListDomainNames", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_GetListDomainNames_21626783, base: "/",
    makeUrl: url_GetListDomainNames_21626784, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_21626829 = ref object of OpenApiRestCall_21625435
proc url_PostUpdateAvailabilityOptions_21626831(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateAvailabilityOptions_21626830(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626832 = query.getOrDefault("Action")
  valid_21626832 = validateParameter(valid_21626832, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_21626832 != nil:
    section.add "Action", valid_21626832
  var valid_21626833 = query.getOrDefault("Version")
  valid_21626833 = validateParameter(valid_21626833, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626833 != nil:
    section.add "Version", valid_21626833
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
  var valid_21626834 = header.getOrDefault("X-Amz-Date")
  valid_21626834 = validateParameter(valid_21626834, JString, required = false,
                                   default = nil)
  if valid_21626834 != nil:
    section.add "X-Amz-Date", valid_21626834
  var valid_21626835 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626835 = validateParameter(valid_21626835, JString, required = false,
                                   default = nil)
  if valid_21626835 != nil:
    section.add "X-Amz-Security-Token", valid_21626835
  var valid_21626836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626836 = validateParameter(valid_21626836, JString, required = false,
                                   default = nil)
  if valid_21626836 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626836
  var valid_21626837 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626837 = validateParameter(valid_21626837, JString, required = false,
                                   default = nil)
  if valid_21626837 != nil:
    section.add "X-Amz-Algorithm", valid_21626837
  var valid_21626838 = header.getOrDefault("X-Amz-Signature")
  valid_21626838 = validateParameter(valid_21626838, JString, required = false,
                                   default = nil)
  if valid_21626838 != nil:
    section.add "X-Amz-Signature", valid_21626838
  var valid_21626839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626839 = validateParameter(valid_21626839, JString, required = false,
                                   default = nil)
  if valid_21626839 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626839
  var valid_21626840 = header.getOrDefault("X-Amz-Credential")
  valid_21626840 = validateParameter(valid_21626840, JString, required = false,
                                   default = nil)
  if valid_21626840 != nil:
    section.add "X-Amz-Credential", valid_21626840
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626841 = formData.getOrDefault("DomainName")
  valid_21626841 = validateParameter(valid_21626841, JString, required = true,
                                   default = nil)
  if valid_21626841 != nil:
    section.add "DomainName", valid_21626841
  var valid_21626842 = formData.getOrDefault("MultiAZ")
  valid_21626842 = validateParameter(valid_21626842, JBool, required = true,
                                   default = nil)
  if valid_21626842 != nil:
    section.add "MultiAZ", valid_21626842
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626843: Call_PostUpdateAvailabilityOptions_21626829;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626843.validator(path, query, header, formData, body, _)
  let scheme = call_21626843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626843.makeUrl(scheme.get, call_21626843.host, call_21626843.base,
                               call_21626843.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626843, uri, valid, _)

proc call*(call_21626844: Call_PostUpdateAvailabilityOptions_21626829;
          DomainName: string; MultiAZ: bool;
          Action: string = "UpdateAvailabilityOptions";
          Version: string = "2013-01-01"): Recallable =
  ## postUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626845 = newJObject()
  var formData_21626846 = newJObject()
  add(formData_21626846, "DomainName", newJString(DomainName))
  add(formData_21626846, "MultiAZ", newJBool(MultiAZ))
  add(query_21626845, "Action", newJString(Action))
  add(query_21626845, "Version", newJString(Version))
  result = call_21626844.call(nil, query_21626845, nil, formData_21626846, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_21626829(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_21626830, base: "/",
    makeUrl: url_PostUpdateAvailabilityOptions_21626831,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_21626812 = ref object of OpenApiRestCall_21625435
proc url_GetUpdateAvailabilityOptions_21626814(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateAvailabilityOptions_21626813(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `MultiAZ` field"
  var valid_21626815 = query.getOrDefault("MultiAZ")
  valid_21626815 = validateParameter(valid_21626815, JBool, required = true,
                                   default = nil)
  if valid_21626815 != nil:
    section.add "MultiAZ", valid_21626815
  var valid_21626816 = query.getOrDefault("Action")
  valid_21626816 = validateParameter(valid_21626816, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_21626816 != nil:
    section.add "Action", valid_21626816
  var valid_21626817 = query.getOrDefault("DomainName")
  valid_21626817 = validateParameter(valid_21626817, JString, required = true,
                                   default = nil)
  if valid_21626817 != nil:
    section.add "DomainName", valid_21626817
  var valid_21626818 = query.getOrDefault("Version")
  valid_21626818 = validateParameter(valid_21626818, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626818 != nil:
    section.add "Version", valid_21626818
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
  var valid_21626819 = header.getOrDefault("X-Amz-Date")
  valid_21626819 = validateParameter(valid_21626819, JString, required = false,
                                   default = nil)
  if valid_21626819 != nil:
    section.add "X-Amz-Date", valid_21626819
  var valid_21626820 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626820 = validateParameter(valid_21626820, JString, required = false,
                                   default = nil)
  if valid_21626820 != nil:
    section.add "X-Amz-Security-Token", valid_21626820
  var valid_21626821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626821 = validateParameter(valid_21626821, JString, required = false,
                                   default = nil)
  if valid_21626821 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626821
  var valid_21626822 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626822 = validateParameter(valid_21626822, JString, required = false,
                                   default = nil)
  if valid_21626822 != nil:
    section.add "X-Amz-Algorithm", valid_21626822
  var valid_21626823 = header.getOrDefault("X-Amz-Signature")
  valid_21626823 = validateParameter(valid_21626823, JString, required = false,
                                   default = nil)
  if valid_21626823 != nil:
    section.add "X-Amz-Signature", valid_21626823
  var valid_21626824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626824 = validateParameter(valid_21626824, JString, required = false,
                                   default = nil)
  if valid_21626824 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626824
  var valid_21626825 = header.getOrDefault("X-Amz-Credential")
  valid_21626825 = validateParameter(valid_21626825, JString, required = false,
                                   default = nil)
  if valid_21626825 != nil:
    section.add "X-Amz-Credential", valid_21626825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626826: Call_GetUpdateAvailabilityOptions_21626812;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626826.validator(path, query, header, formData, body, _)
  let scheme = call_21626826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626826.makeUrl(scheme.get, call_21626826.host, call_21626826.base,
                               call_21626826.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626826, uri, valid, _)

proc call*(call_21626827: Call_GetUpdateAvailabilityOptions_21626812;
          MultiAZ: bool; DomainName: string;
          Action: string = "UpdateAvailabilityOptions";
          Version: string = "2013-01-01"): Recallable =
  ## getUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_21626828 = newJObject()
  add(query_21626828, "MultiAZ", newJBool(MultiAZ))
  add(query_21626828, "Action", newJString(Action))
  add(query_21626828, "DomainName", newJString(DomainName))
  add(query_21626828, "Version", newJString(Version))
  result = call_21626827.call(nil, query_21626828, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_21626812(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_21626813, base: "/",
    makeUrl: url_GetUpdateAvailabilityOptions_21626814,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateDomainEndpointOptions_21626865 = ref object of OpenApiRestCall_21625435
proc url_PostUpdateDomainEndpointOptions_21626867(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateDomainEndpointOptions_21626866(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626868 = query.getOrDefault("Action")
  valid_21626868 = validateParameter(valid_21626868, JString, required = true, default = newJString(
      "UpdateDomainEndpointOptions"))
  if valid_21626868 != nil:
    section.add "Action", valid_21626868
  var valid_21626869 = query.getOrDefault("Version")
  valid_21626869 = validateParameter(valid_21626869, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626869 != nil:
    section.add "Version", valid_21626869
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
  var valid_21626870 = header.getOrDefault("X-Amz-Date")
  valid_21626870 = validateParameter(valid_21626870, JString, required = false,
                                   default = nil)
  if valid_21626870 != nil:
    section.add "X-Amz-Date", valid_21626870
  var valid_21626871 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626871 = validateParameter(valid_21626871, JString, required = false,
                                   default = nil)
  if valid_21626871 != nil:
    section.add "X-Amz-Security-Token", valid_21626871
  var valid_21626872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626872 = validateParameter(valid_21626872, JString, required = false,
                                   default = nil)
  if valid_21626872 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626872
  var valid_21626873 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626873 = validateParameter(valid_21626873, JString, required = false,
                                   default = nil)
  if valid_21626873 != nil:
    section.add "X-Amz-Algorithm", valid_21626873
  var valid_21626874 = header.getOrDefault("X-Amz-Signature")
  valid_21626874 = validateParameter(valid_21626874, JString, required = false,
                                   default = nil)
  if valid_21626874 != nil:
    section.add "X-Amz-Signature", valid_21626874
  var valid_21626875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626875 = validateParameter(valid_21626875, JString, required = false,
                                   default = nil)
  if valid_21626875 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626875
  var valid_21626876 = header.getOrDefault("X-Amz-Credential")
  valid_21626876 = validateParameter(valid_21626876, JString, required = false,
                                   default = nil)
  if valid_21626876 != nil:
    section.add "X-Amz-Credential", valid_21626876
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   DomainEndpointOptions.EnforceHTTPS: JString
  ##                                     : The domain's endpoint options.
  ## Whether the domain is HTTPS only enabled.
  ##   DomainEndpointOptions.TLSSecurityPolicy: JString
  ##                                          : The domain's endpoint options.
  ## The minimum required TLS version
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626877 = formData.getOrDefault("DomainName")
  valid_21626877 = validateParameter(valid_21626877, JString, required = true,
                                   default = nil)
  if valid_21626877 != nil:
    section.add "DomainName", valid_21626877
  var valid_21626878 = formData.getOrDefault("DomainEndpointOptions.EnforceHTTPS")
  valid_21626878 = validateParameter(valid_21626878, JString, required = false,
                                   default = nil)
  if valid_21626878 != nil:
    section.add "DomainEndpointOptions.EnforceHTTPS", valid_21626878
  var valid_21626879 = formData.getOrDefault(
      "DomainEndpointOptions.TLSSecurityPolicy")
  valid_21626879 = validateParameter(valid_21626879, JString, required = false,
                                   default = nil)
  if valid_21626879 != nil:
    section.add "DomainEndpointOptions.TLSSecurityPolicy", valid_21626879
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626880: Call_PostUpdateDomainEndpointOptions_21626865;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626880.validator(path, query, header, formData, body, _)
  let scheme = call_21626880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626880.makeUrl(scheme.get, call_21626880.host, call_21626880.base,
                               call_21626880.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626880, uri, valid, _)

proc call*(call_21626881: Call_PostUpdateDomainEndpointOptions_21626865;
          DomainName: string; DomainEndpointOptionsEnforceHTTPS: string = "";
          Action: string = "UpdateDomainEndpointOptions";
          DomainEndpointOptionsTLSSecurityPolicy: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## postUpdateDomainEndpointOptions
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   DomainEndpointOptionsEnforceHTTPS: string
  ##                                    : The domain's endpoint options.
  ## Whether the domain is HTTPS only enabled.
  ##   Action: string (required)
  ##   DomainEndpointOptionsTLSSecurityPolicy: string
  ##                                         : The domain's endpoint options.
  ## The minimum required TLS version
  ##   Version: string (required)
  var query_21626882 = newJObject()
  var formData_21626883 = newJObject()
  add(formData_21626883, "DomainName", newJString(DomainName))
  add(formData_21626883, "DomainEndpointOptions.EnforceHTTPS",
      newJString(DomainEndpointOptionsEnforceHTTPS))
  add(query_21626882, "Action", newJString(Action))
  add(formData_21626883, "DomainEndpointOptions.TLSSecurityPolicy",
      newJString(DomainEndpointOptionsTLSSecurityPolicy))
  add(query_21626882, "Version", newJString(Version))
  result = call_21626881.call(nil, query_21626882, nil, formData_21626883, nil)

var postUpdateDomainEndpointOptions* = Call_PostUpdateDomainEndpointOptions_21626865(
    name: "postUpdateDomainEndpointOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateDomainEndpointOptions",
    validator: validate_PostUpdateDomainEndpointOptions_21626866, base: "/",
    makeUrl: url_PostUpdateDomainEndpointOptions_21626867,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateDomainEndpointOptions_21626847 = ref object of OpenApiRestCall_21625435
proc url_GetUpdateDomainEndpointOptions_21626849(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateDomainEndpointOptions_21626848(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   Action: JString (required)
  ##   DomainEndpointOptions.TLSSecurityPolicy: JString
  ##                                          : The domain's endpoint options.
  ## The minimum required TLS version
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626850 = query.getOrDefault("DomainEndpointOptions.EnforceHTTPS")
  valid_21626850 = validateParameter(valid_21626850, JString, required = false,
                                   default = nil)
  if valid_21626850 != nil:
    section.add "DomainEndpointOptions.EnforceHTTPS", valid_21626850
  var valid_21626851 = query.getOrDefault("Action")
  valid_21626851 = validateParameter(valid_21626851, JString, required = true, default = newJString(
      "UpdateDomainEndpointOptions"))
  if valid_21626851 != nil:
    section.add "Action", valid_21626851
  var valid_21626852 = query.getOrDefault("DomainEndpointOptions.TLSSecurityPolicy")
  valid_21626852 = validateParameter(valid_21626852, JString, required = false,
                                   default = nil)
  if valid_21626852 != nil:
    section.add "DomainEndpointOptions.TLSSecurityPolicy", valid_21626852
  var valid_21626853 = query.getOrDefault("DomainName")
  valid_21626853 = validateParameter(valid_21626853, JString, required = true,
                                   default = nil)
  if valid_21626853 != nil:
    section.add "DomainName", valid_21626853
  var valid_21626854 = query.getOrDefault("Version")
  valid_21626854 = validateParameter(valid_21626854, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626854 != nil:
    section.add "Version", valid_21626854
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
  var valid_21626855 = header.getOrDefault("X-Amz-Date")
  valid_21626855 = validateParameter(valid_21626855, JString, required = false,
                                   default = nil)
  if valid_21626855 != nil:
    section.add "X-Amz-Date", valid_21626855
  var valid_21626856 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626856 = validateParameter(valid_21626856, JString, required = false,
                                   default = nil)
  if valid_21626856 != nil:
    section.add "X-Amz-Security-Token", valid_21626856
  var valid_21626857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626857 = validateParameter(valid_21626857, JString, required = false,
                                   default = nil)
  if valid_21626857 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626857
  var valid_21626858 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626858 = validateParameter(valid_21626858, JString, required = false,
                                   default = nil)
  if valid_21626858 != nil:
    section.add "X-Amz-Algorithm", valid_21626858
  var valid_21626859 = header.getOrDefault("X-Amz-Signature")
  valid_21626859 = validateParameter(valid_21626859, JString, required = false,
                                   default = nil)
  if valid_21626859 != nil:
    section.add "X-Amz-Signature", valid_21626859
  var valid_21626860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626860 = validateParameter(valid_21626860, JString, required = false,
                                   default = nil)
  if valid_21626860 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626860
  var valid_21626861 = header.getOrDefault("X-Amz-Credential")
  valid_21626861 = validateParameter(valid_21626861, JString, required = false,
                                   default = nil)
  if valid_21626861 != nil:
    section.add "X-Amz-Credential", valid_21626861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626862: Call_GetUpdateDomainEndpointOptions_21626847;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626862.validator(path, query, header, formData, body, _)
  let scheme = call_21626862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626862.makeUrl(scheme.get, call_21626862.host, call_21626862.base,
                               call_21626862.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626862, uri, valid, _)

proc call*(call_21626863: Call_GetUpdateDomainEndpointOptions_21626847;
          DomainName: string; DomainEndpointOptionsEnforceHTTPS: string = "";
          Action: string = "UpdateDomainEndpointOptions";
          DomainEndpointOptionsTLSSecurityPolicy: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## getUpdateDomainEndpointOptions
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainEndpointOptionsEnforceHTTPS: string
  ##                                    : The domain's endpoint options.
  ## Whether the domain is HTTPS only enabled.
  ##   Action: string (required)
  ##   DomainEndpointOptionsTLSSecurityPolicy: string
  ##                                         : The domain's endpoint options.
  ## The minimum required TLS version
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_21626864 = newJObject()
  add(query_21626864, "DomainEndpointOptions.EnforceHTTPS",
      newJString(DomainEndpointOptionsEnforceHTTPS))
  add(query_21626864, "Action", newJString(Action))
  add(query_21626864, "DomainEndpointOptions.TLSSecurityPolicy",
      newJString(DomainEndpointOptionsTLSSecurityPolicy))
  add(query_21626864, "DomainName", newJString(DomainName))
  add(query_21626864, "Version", newJString(Version))
  result = call_21626863.call(nil, query_21626864, nil, nil, nil)

var getUpdateDomainEndpointOptions* = Call_GetUpdateDomainEndpointOptions_21626847(
    name: "getUpdateDomainEndpointOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateDomainEndpointOptions",
    validator: validate_GetUpdateDomainEndpointOptions_21626848, base: "/",
    makeUrl: url_GetUpdateDomainEndpointOptions_21626849,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateScalingParameters_21626903 = ref object of OpenApiRestCall_21625435
proc url_PostUpdateScalingParameters_21626905(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateScalingParameters_21626904(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626906 = query.getOrDefault("Action")
  valid_21626906 = validateParameter(valid_21626906, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_21626906 != nil:
    section.add "Action", valid_21626906
  var valid_21626907 = query.getOrDefault("Version")
  valid_21626907 = validateParameter(valid_21626907, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626907 != nil:
    section.add "Version", valid_21626907
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
  var valid_21626908 = header.getOrDefault("X-Amz-Date")
  valid_21626908 = validateParameter(valid_21626908, JString, required = false,
                                   default = nil)
  if valid_21626908 != nil:
    section.add "X-Amz-Date", valid_21626908
  var valid_21626909 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626909 = validateParameter(valid_21626909, JString, required = false,
                                   default = nil)
  if valid_21626909 != nil:
    section.add "X-Amz-Security-Token", valid_21626909
  var valid_21626910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626910 = validateParameter(valid_21626910, JString, required = false,
                                   default = nil)
  if valid_21626910 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626910
  var valid_21626911 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626911 = validateParameter(valid_21626911, JString, required = false,
                                   default = nil)
  if valid_21626911 != nil:
    section.add "X-Amz-Algorithm", valid_21626911
  var valid_21626912 = header.getOrDefault("X-Amz-Signature")
  valid_21626912 = validateParameter(valid_21626912, JString, required = false,
                                   default = nil)
  if valid_21626912 != nil:
    section.add "X-Amz-Signature", valid_21626912
  var valid_21626913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626913 = validateParameter(valid_21626913, JString, required = false,
                                   default = nil)
  if valid_21626913 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626913
  var valid_21626914 = header.getOrDefault("X-Amz-Credential")
  valid_21626914 = validateParameter(valid_21626914, JString, required = false,
                                   default = nil)
  if valid_21626914 != nil:
    section.add "X-Amz-Credential", valid_21626914
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ScalingParameters.DesiredPartitionCount: JString
  ##                                          : The desired instance type and desired number of replicas of each index partition.
  ## The number of partitions you want to preconfigure for your domain. Only valid when you select <code>m2.2xlarge</code> as the desired instance type.
  ##   ScalingParameters.DesiredReplicationCount: JString
  ##                                            : The desired instance type and desired number of replicas of each index partition.
  ## The number of replicas you want to preconfigure for each index partition.
  ##   ScalingParameters.DesiredInstanceType: JString
  ##                                        : The desired instance type and desired number of replicas of each index partition.
  ## The instance type that you want to preconfigure for your domain. For example, <code>search.m1.small</code>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626915 = formData.getOrDefault("DomainName")
  valid_21626915 = validateParameter(valid_21626915, JString, required = true,
                                   default = nil)
  if valid_21626915 != nil:
    section.add "DomainName", valid_21626915
  var valid_21626916 = formData.getOrDefault(
      "ScalingParameters.DesiredPartitionCount")
  valid_21626916 = validateParameter(valid_21626916, JString, required = false,
                                   default = nil)
  if valid_21626916 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_21626916
  var valid_21626917 = formData.getOrDefault(
      "ScalingParameters.DesiredReplicationCount")
  valid_21626917 = validateParameter(valid_21626917, JString, required = false,
                                   default = nil)
  if valid_21626917 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_21626917
  var valid_21626918 = formData.getOrDefault(
      "ScalingParameters.DesiredInstanceType")
  valid_21626918 = validateParameter(valid_21626918, JString, required = false,
                                   default = nil)
  if valid_21626918 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_21626918
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626919: Call_PostUpdateScalingParameters_21626903;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_21626919.validator(path, query, header, formData, body, _)
  let scheme = call_21626919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626919.makeUrl(scheme.get, call_21626919.host, call_21626919.base,
                               call_21626919.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626919, uri, valid, _)

proc call*(call_21626920: Call_PostUpdateScalingParameters_21626903;
          DomainName: string; ScalingParametersDesiredPartitionCount: string = "";
          Action: string = "UpdateScalingParameters";
          ScalingParametersDesiredReplicationCount: string = "";
          ScalingParametersDesiredInstanceType: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## postUpdateScalingParameters
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ScalingParametersDesiredPartitionCount: string
  ##                                         : The desired instance type and desired number of replicas of each index partition.
  ## The number of partitions you want to preconfigure for your domain. Only valid when you select <code>m2.2xlarge</code> as the desired instance type.
  ##   Action: string (required)
  ##   ScalingParametersDesiredReplicationCount: string
  ##                                           : The desired instance type and desired number of replicas of each index partition.
  ## The number of replicas you want to preconfigure for each index partition.
  ##   ScalingParametersDesiredInstanceType: string
  ##                                       : The desired instance type and desired number of replicas of each index partition.
  ## The instance type that you want to preconfigure for your domain. For example, <code>search.m1.small</code>.
  ##   Version: string (required)
  var query_21626921 = newJObject()
  var formData_21626922 = newJObject()
  add(formData_21626922, "DomainName", newJString(DomainName))
  add(formData_21626922, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(query_21626921, "Action", newJString(Action))
  add(formData_21626922, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  add(formData_21626922, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  add(query_21626921, "Version", newJString(Version))
  result = call_21626920.call(nil, query_21626921, nil, formData_21626922, nil)

var postUpdateScalingParameters* = Call_PostUpdateScalingParameters_21626903(
    name: "postUpdateScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_PostUpdateScalingParameters_21626904, base: "/",
    makeUrl: url_PostUpdateScalingParameters_21626905,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateScalingParameters_21626884 = ref object of OpenApiRestCall_21625435
proc url_GetUpdateScalingParameters_21626886(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateScalingParameters_21626885(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ScalingParameters.DesiredReplicationCount: JString
  ##                                            : The desired instance type and desired number of replicas of each index partition.
  ## The number of replicas you want to preconfigure for each index partition.
  ##   ScalingParameters.DesiredPartitionCount: JString
  ##                                          : The desired instance type and desired number of replicas of each index partition.
  ## The number of partitions you want to preconfigure for your domain. Only valid when you select <code>m2.2xlarge</code> as the desired instance type.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  ##   ScalingParameters.DesiredInstanceType: JString
  ##                                        : The desired instance type and desired number of replicas of each index partition.
  ## The instance type that you want to preconfigure for your domain. For example, <code>search.m1.small</code>.
  section = newJObject()
  var valid_21626887 = query.getOrDefault("ScalingParameters.DesiredReplicationCount")
  valid_21626887 = validateParameter(valid_21626887, JString, required = false,
                                   default = nil)
  if valid_21626887 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_21626887
  var valid_21626888 = query.getOrDefault("ScalingParameters.DesiredPartitionCount")
  valid_21626888 = validateParameter(valid_21626888, JString, required = false,
                                   default = nil)
  if valid_21626888 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_21626888
  var valid_21626889 = query.getOrDefault("Action")
  valid_21626889 = validateParameter(valid_21626889, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_21626889 != nil:
    section.add "Action", valid_21626889
  var valid_21626890 = query.getOrDefault("DomainName")
  valid_21626890 = validateParameter(valid_21626890, JString, required = true,
                                   default = nil)
  if valid_21626890 != nil:
    section.add "DomainName", valid_21626890
  var valid_21626891 = query.getOrDefault("Version")
  valid_21626891 = validateParameter(valid_21626891, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626891 != nil:
    section.add "Version", valid_21626891
  var valid_21626892 = query.getOrDefault("ScalingParameters.DesiredInstanceType")
  valid_21626892 = validateParameter(valid_21626892, JString, required = false,
                                   default = nil)
  if valid_21626892 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_21626892
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
  var valid_21626893 = header.getOrDefault("X-Amz-Date")
  valid_21626893 = validateParameter(valid_21626893, JString, required = false,
                                   default = nil)
  if valid_21626893 != nil:
    section.add "X-Amz-Date", valid_21626893
  var valid_21626894 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626894 = validateParameter(valid_21626894, JString, required = false,
                                   default = nil)
  if valid_21626894 != nil:
    section.add "X-Amz-Security-Token", valid_21626894
  var valid_21626895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626895 = validateParameter(valid_21626895, JString, required = false,
                                   default = nil)
  if valid_21626895 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626895
  var valid_21626896 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626896 = validateParameter(valid_21626896, JString, required = false,
                                   default = nil)
  if valid_21626896 != nil:
    section.add "X-Amz-Algorithm", valid_21626896
  var valid_21626897 = header.getOrDefault("X-Amz-Signature")
  valid_21626897 = validateParameter(valid_21626897, JString, required = false,
                                   default = nil)
  if valid_21626897 != nil:
    section.add "X-Amz-Signature", valid_21626897
  var valid_21626898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626898 = validateParameter(valid_21626898, JString, required = false,
                                   default = nil)
  if valid_21626898 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626898
  var valid_21626899 = header.getOrDefault("X-Amz-Credential")
  valid_21626899 = validateParameter(valid_21626899, JString, required = false,
                                   default = nil)
  if valid_21626899 != nil:
    section.add "X-Amz-Credential", valid_21626899
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626900: Call_GetUpdateScalingParameters_21626884;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_21626900.validator(path, query, header, formData, body, _)
  let scheme = call_21626900.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626900.makeUrl(scheme.get, call_21626900.host, call_21626900.base,
                               call_21626900.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626900, uri, valid, _)

proc call*(call_21626901: Call_GetUpdateScalingParameters_21626884;
          DomainName: string;
          ScalingParametersDesiredReplicationCount: string = "";
          ScalingParametersDesiredPartitionCount: string = "";
          Action: string = "UpdateScalingParameters";
          Version: string = "2013-01-01";
          ScalingParametersDesiredInstanceType: string = ""): Recallable =
  ## getUpdateScalingParameters
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   ScalingParametersDesiredReplicationCount: string
  ##                                           : The desired instance type and desired number of replicas of each index partition.
  ## The number of replicas you want to preconfigure for each index partition.
  ##   ScalingParametersDesiredPartitionCount: string
  ##                                         : The desired instance type and desired number of replicas of each index partition.
  ## The number of partitions you want to preconfigure for your domain. Only valid when you select <code>m2.2xlarge</code> as the desired instance type.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  ##   ScalingParametersDesiredInstanceType: string
  ##                                       : The desired instance type and desired number of replicas of each index partition.
  ## The instance type that you want to preconfigure for your domain. For example, <code>search.m1.small</code>.
  var query_21626902 = newJObject()
  add(query_21626902, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  add(query_21626902, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(query_21626902, "Action", newJString(Action))
  add(query_21626902, "DomainName", newJString(DomainName))
  add(query_21626902, "Version", newJString(Version))
  add(query_21626902, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  result = call_21626901.call(nil, query_21626902, nil, nil, nil)

var getUpdateScalingParameters* = Call_GetUpdateScalingParameters_21626884(
    name: "getUpdateScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_GetUpdateScalingParameters_21626885, base: "/",
    makeUrl: url_GetUpdateScalingParameters_21626886,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_21626940 = ref object of OpenApiRestCall_21625435
proc url_PostUpdateServiceAccessPolicies_21626942(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateServiceAccessPolicies_21626941(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626943 = query.getOrDefault("Action")
  valid_21626943 = validateParameter(valid_21626943, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_21626943 != nil:
    section.add "Action", valid_21626943
  var valid_21626944 = query.getOrDefault("Version")
  valid_21626944 = validateParameter(valid_21626944, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626944 != nil:
    section.add "Version", valid_21626944
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
  var valid_21626945 = header.getOrDefault("X-Amz-Date")
  valid_21626945 = validateParameter(valid_21626945, JString, required = false,
                                   default = nil)
  if valid_21626945 != nil:
    section.add "X-Amz-Date", valid_21626945
  var valid_21626946 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626946 = validateParameter(valid_21626946, JString, required = false,
                                   default = nil)
  if valid_21626946 != nil:
    section.add "X-Amz-Security-Token", valid_21626946
  var valid_21626947 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626947 = validateParameter(valid_21626947, JString, required = false,
                                   default = nil)
  if valid_21626947 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626947
  var valid_21626948 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626948 = validateParameter(valid_21626948, JString, required = false,
                                   default = nil)
  if valid_21626948 != nil:
    section.add "X-Amz-Algorithm", valid_21626948
  var valid_21626949 = header.getOrDefault("X-Amz-Signature")
  valid_21626949 = validateParameter(valid_21626949, JString, required = false,
                                   default = nil)
  if valid_21626949 != nil:
    section.add "X-Amz-Signature", valid_21626949
  var valid_21626950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626950 = validateParameter(valid_21626950, JString, required = false,
                                   default = nil)
  if valid_21626950 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626950
  var valid_21626951 = header.getOrDefault("X-Amz-Credential")
  valid_21626951 = validateParameter(valid_21626951, JString, required = false,
                                   default = nil)
  if valid_21626951 != nil:
    section.add "X-Amz-Credential", valid_21626951
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AccessPolicies: JString (required)
  ##                 : Access rules for a domain's document or search service endpoints. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. The maximum size of a policy document is 100 KB.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626952 = formData.getOrDefault("DomainName")
  valid_21626952 = validateParameter(valid_21626952, JString, required = true,
                                   default = nil)
  if valid_21626952 != nil:
    section.add "DomainName", valid_21626952
  var valid_21626953 = formData.getOrDefault("AccessPolicies")
  valid_21626953 = validateParameter(valid_21626953, JString, required = true,
                                   default = nil)
  if valid_21626953 != nil:
    section.add "AccessPolicies", valid_21626953
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626954: Call_PostUpdateServiceAccessPolicies_21626940;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_21626954.validator(path, query, header, formData, body, _)
  let scheme = call_21626954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626954.makeUrl(scheme.get, call_21626954.host, call_21626954.base,
                               call_21626954.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626954, uri, valid, _)

proc call*(call_21626955: Call_PostUpdateServiceAccessPolicies_21626940;
          DomainName: string; AccessPolicies: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2013-01-01"): Recallable =
  ## postUpdateServiceAccessPolicies
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AccessPolicies: string (required)
  ##                 : Access rules for a domain's document or search service endpoints. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. The maximum size of a policy document is 100 KB.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626956 = newJObject()
  var formData_21626957 = newJObject()
  add(formData_21626957, "DomainName", newJString(DomainName))
  add(formData_21626957, "AccessPolicies", newJString(AccessPolicies))
  add(query_21626956, "Action", newJString(Action))
  add(query_21626956, "Version", newJString(Version))
  result = call_21626955.call(nil, query_21626956, nil, formData_21626957, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_21626940(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_21626941, base: "/",
    makeUrl: url_PostUpdateServiceAccessPolicies_21626942,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_21626923 = ref object of OpenApiRestCall_21625435
proc url_GetUpdateServiceAccessPolicies_21626925(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateServiceAccessPolicies_21626924(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   AccessPolicies: JString (required)
  ##                 : Access rules for a domain's document or search service endpoints. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. The maximum size of a policy document is 100 KB.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626926 = query.getOrDefault("Action")
  valid_21626926 = validateParameter(valid_21626926, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_21626926 != nil:
    section.add "Action", valid_21626926
  var valid_21626927 = query.getOrDefault("AccessPolicies")
  valid_21626927 = validateParameter(valid_21626927, JString, required = true,
                                   default = nil)
  if valid_21626927 != nil:
    section.add "AccessPolicies", valid_21626927
  var valid_21626928 = query.getOrDefault("DomainName")
  valid_21626928 = validateParameter(valid_21626928, JString, required = true,
                                   default = nil)
  if valid_21626928 != nil:
    section.add "DomainName", valid_21626928
  var valid_21626929 = query.getOrDefault("Version")
  valid_21626929 = validateParameter(valid_21626929, JString, required = true,
                                   default = newJString("2013-01-01"))
  if valid_21626929 != nil:
    section.add "Version", valid_21626929
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
  var valid_21626930 = header.getOrDefault("X-Amz-Date")
  valid_21626930 = validateParameter(valid_21626930, JString, required = false,
                                   default = nil)
  if valid_21626930 != nil:
    section.add "X-Amz-Date", valid_21626930
  var valid_21626931 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626931 = validateParameter(valid_21626931, JString, required = false,
                                   default = nil)
  if valid_21626931 != nil:
    section.add "X-Amz-Security-Token", valid_21626931
  var valid_21626932 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626932 = validateParameter(valid_21626932, JString, required = false,
                                   default = nil)
  if valid_21626932 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626932
  var valid_21626933 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626933 = validateParameter(valid_21626933, JString, required = false,
                                   default = nil)
  if valid_21626933 != nil:
    section.add "X-Amz-Algorithm", valid_21626933
  var valid_21626934 = header.getOrDefault("X-Amz-Signature")
  valid_21626934 = validateParameter(valid_21626934, JString, required = false,
                                   default = nil)
  if valid_21626934 != nil:
    section.add "X-Amz-Signature", valid_21626934
  var valid_21626935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626935 = validateParameter(valid_21626935, JString, required = false,
                                   default = nil)
  if valid_21626935 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626935
  var valid_21626936 = header.getOrDefault("X-Amz-Credential")
  valid_21626936 = validateParameter(valid_21626936, JString, required = false,
                                   default = nil)
  if valid_21626936 != nil:
    section.add "X-Amz-Credential", valid_21626936
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626937: Call_GetUpdateServiceAccessPolicies_21626923;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_21626937.validator(path, query, header, formData, body, _)
  let scheme = call_21626937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626937.makeUrl(scheme.get, call_21626937.host, call_21626937.base,
                               call_21626937.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626937, uri, valid, _)

proc call*(call_21626938: Call_GetUpdateServiceAccessPolicies_21626923;
          AccessPolicies: string; DomainName: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2013-01-01"): Recallable =
  ## getUpdateServiceAccessPolicies
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ##   Action: string (required)
  ##   AccessPolicies: string (required)
  ##                 : Access rules for a domain's document or search service endpoints. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. The maximum size of a policy document is 100 KB.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_21626939 = newJObject()
  add(query_21626939, "Action", newJString(Action))
  add(query_21626939, "AccessPolicies", newJString(AccessPolicies))
  add(query_21626939, "DomainName", newJString(DomainName))
  add(query_21626939, "Version", newJString(Version))
  result = call_21626938.call(nil, query_21626939, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_21626923(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_21626924, base: "/",
    makeUrl: url_GetUpdateServiceAccessPolicies_21626925,
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