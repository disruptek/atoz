
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  Call_PostBuildSuggesters_613267 = ref object of OpenApiRestCall_612658
proc url_PostBuildSuggesters_613269(protocol: Scheme; host: string; base: string;
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

proc validate_PostBuildSuggesters_613268(path: JsonNode; query: JsonNode;
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
  var valid_613270 = query.getOrDefault("Action")
  valid_613270 = validateParameter(valid_613270, JString, required = true,
                                 default = newJString("BuildSuggesters"))
  if valid_613270 != nil:
    section.add "Action", valid_613270
  var valid_613271 = query.getOrDefault("Version")
  valid_613271 = validateParameter(valid_613271, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613271 != nil:
    section.add "Version", valid_613271
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
  var valid_613272 = header.getOrDefault("X-Amz-Signature")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Signature", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Content-Sha256", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Date")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Date", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Credential")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Credential", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Security-Token")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Security-Token", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Algorithm")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Algorithm", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-SignedHeaders", valid_613278
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613279 = formData.getOrDefault("DomainName")
  valid_613279 = validateParameter(valid_613279, JString, required = true,
                                 default = nil)
  if valid_613279 != nil:
    section.add "DomainName", valid_613279
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613280: Call_PostBuildSuggesters_613267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613280.validator(path, query, header, formData, body)
  let scheme = call_613280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613280.url(scheme.get, call_613280.host, call_613280.base,
                         call_613280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613280, url, valid)

proc call*(call_613281: Call_PostBuildSuggesters_613267; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## postBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613282 = newJObject()
  var formData_613283 = newJObject()
  add(formData_613283, "DomainName", newJString(DomainName))
  add(query_613282, "Action", newJString(Action))
  add(query_613282, "Version", newJString(Version))
  result = call_613281.call(nil, query_613282, nil, formData_613283, nil)

var postBuildSuggesters* = Call_PostBuildSuggesters_613267(
    name: "postBuildSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_PostBuildSuggesters_613268, base: "/",
    url: url_PostBuildSuggesters_613269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuildSuggesters_612996 = ref object of OpenApiRestCall_612658
proc url_GetBuildSuggesters_612998(protocol: Scheme; host: string; base: string;
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

proc validate_GetBuildSuggesters_612997(path: JsonNode; query: JsonNode;
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
  var valid_613110 = query.getOrDefault("DomainName")
  valid_613110 = validateParameter(valid_613110, JString, required = true,
                                 default = nil)
  if valid_613110 != nil:
    section.add "DomainName", valid_613110
  var valid_613124 = query.getOrDefault("Action")
  valid_613124 = validateParameter(valid_613124, JString, required = true,
                                 default = newJString("BuildSuggesters"))
  if valid_613124 != nil:
    section.add "Action", valid_613124
  var valid_613125 = query.getOrDefault("Version")
  valid_613125 = validateParameter(valid_613125, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613125 != nil:
    section.add "Version", valid_613125
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
  var valid_613126 = header.getOrDefault("X-Amz-Signature")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Signature", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Content-Sha256", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Date")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Date", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Credential")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Credential", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Security-Token")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Security-Token", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-Algorithm")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-Algorithm", valid_613131
  var valid_613132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613132 = validateParameter(valid_613132, JString, required = false,
                                 default = nil)
  if valid_613132 != nil:
    section.add "X-Amz-SignedHeaders", valid_613132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613155: Call_GetBuildSuggesters_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613155.validator(path, query, header, formData, body)
  let scheme = call_613155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613155.url(scheme.get, call_613155.host, call_613155.base,
                         call_613155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613155, url, valid)

proc call*(call_613226: Call_GetBuildSuggesters_612996; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## getBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613227 = newJObject()
  add(query_613227, "DomainName", newJString(DomainName))
  add(query_613227, "Action", newJString(Action))
  add(query_613227, "Version", newJString(Version))
  result = call_613226.call(nil, query_613227, nil, nil, nil)

var getBuildSuggesters* = Call_GetBuildSuggesters_612996(
    name: "getBuildSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_GetBuildSuggesters_612997, base: "/",
    url: url_GetBuildSuggesters_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_613300 = ref object of OpenApiRestCall_612658
proc url_PostCreateDomain_613302(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDomain_613301(path: JsonNode; query: JsonNode;
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
  var valid_613303 = query.getOrDefault("Action")
  valid_613303 = validateParameter(valid_613303, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_613303 != nil:
    section.add "Action", valid_613303
  var valid_613304 = query.getOrDefault("Version")
  valid_613304 = validateParameter(valid_613304, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613304 != nil:
    section.add "Version", valid_613304
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
  var valid_613305 = header.getOrDefault("X-Amz-Signature")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-Signature", valid_613305
  var valid_613306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-Content-Sha256", valid_613306
  var valid_613307 = header.getOrDefault("X-Amz-Date")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Date", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-Credential")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Credential", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Security-Token")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Security-Token", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Algorithm")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Algorithm", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-SignedHeaders", valid_613311
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613312 = formData.getOrDefault("DomainName")
  valid_613312 = validateParameter(valid_613312, JString, required = true,
                                 default = nil)
  if valid_613312 != nil:
    section.add "DomainName", valid_613312
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613313: Call_PostCreateDomain_613300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613313.validator(path, query, header, formData, body)
  let scheme = call_613313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613313.url(scheme.get, call_613313.host, call_613313.base,
                         call_613313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613313, url, valid)

proc call*(call_613314: Call_PostCreateDomain_613300; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613315 = newJObject()
  var formData_613316 = newJObject()
  add(formData_613316, "DomainName", newJString(DomainName))
  add(query_613315, "Action", newJString(Action))
  add(query_613315, "Version", newJString(Version))
  result = call_613314.call(nil, query_613315, nil, formData_613316, nil)

var postCreateDomain* = Call_PostCreateDomain_613300(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_613301,
    base: "/", url: url_PostCreateDomain_613302,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_613284 = ref object of OpenApiRestCall_612658
proc url_GetCreateDomain_613286(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDomain_613285(path: JsonNode; query: JsonNode;
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
  var valid_613287 = query.getOrDefault("DomainName")
  valid_613287 = validateParameter(valid_613287, JString, required = true,
                                 default = nil)
  if valid_613287 != nil:
    section.add "DomainName", valid_613287
  var valid_613288 = query.getOrDefault("Action")
  valid_613288 = validateParameter(valid_613288, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_613288 != nil:
    section.add "Action", valid_613288
  var valid_613289 = query.getOrDefault("Version")
  valid_613289 = validateParameter(valid_613289, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613289 != nil:
    section.add "Version", valid_613289
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
  var valid_613290 = header.getOrDefault("X-Amz-Signature")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Signature", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Content-Sha256", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-Date")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Date", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Credential")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Credential", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Security-Token")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Security-Token", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-Algorithm")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Algorithm", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-SignedHeaders", valid_613296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613297: Call_GetCreateDomain_613284; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613297.validator(path, query, header, formData, body)
  let scheme = call_613297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613297.url(scheme.get, call_613297.host, call_613297.base,
                         call_613297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613297, url, valid)

proc call*(call_613298: Call_GetCreateDomain_613284; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613299 = newJObject()
  add(query_613299, "DomainName", newJString(DomainName))
  add(query_613299, "Action", newJString(Action))
  add(query_613299, "Version", newJString(Version))
  result = call_613298.call(nil, query_613299, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_613284(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_613285,
    base: "/", url: url_GetCreateDomain_613286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineAnalysisScheme_613336 = ref object of OpenApiRestCall_612658
proc url_PostDefineAnalysisScheme_613338(protocol: Scheme; host: string;
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

proc validate_PostDefineAnalysisScheme_613337(path: JsonNode; query: JsonNode;
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
  var valid_613339 = query.getOrDefault("Action")
  valid_613339 = validateParameter(valid_613339, JString, required = true,
                                 default = newJString("DefineAnalysisScheme"))
  if valid_613339 != nil:
    section.add "Action", valid_613339
  var valid_613340 = query.getOrDefault("Version")
  valid_613340 = validateParameter(valid_613340, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613340 != nil:
    section.add "Version", valid_613340
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
  var valid_613341 = header.getOrDefault("X-Amz-Signature")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-Signature", valid_613341
  var valid_613342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-Content-Sha256", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-Date")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Date", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Credential")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Credential", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Security-Token")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Security-Token", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Algorithm")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Algorithm", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-SignedHeaders", valid_613347
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
  var valid_613348 = formData.getOrDefault("AnalysisScheme.AnalysisSchemeLanguage")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_613348
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613349 = formData.getOrDefault("DomainName")
  valid_613349 = validateParameter(valid_613349, JString, required = true,
                                 default = nil)
  if valid_613349 != nil:
    section.add "DomainName", valid_613349
  var valid_613350 = formData.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_613350
  var valid_613351 = formData.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_613351
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613352: Call_PostDefineAnalysisScheme_613336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613352.validator(path, query, header, formData, body)
  let scheme = call_613352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613352.url(scheme.get, call_613352.host, call_613352.base,
                         call_613352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613352, url, valid)

proc call*(call_613353: Call_PostDefineAnalysisScheme_613336; DomainName: string;
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
  var query_613354 = newJObject()
  var formData_613355 = newJObject()
  add(formData_613355, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(formData_613355, "DomainName", newJString(DomainName))
  add(formData_613355, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_613354, "Action", newJString(Action))
  add(formData_613355, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  add(query_613354, "Version", newJString(Version))
  result = call_613353.call(nil, query_613354, nil, formData_613355, nil)

var postDefineAnalysisScheme* = Call_PostDefineAnalysisScheme_613336(
    name: "postDefineAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_PostDefineAnalysisScheme_613337, base: "/",
    url: url_PostDefineAnalysisScheme_613338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineAnalysisScheme_613317 = ref object of OpenApiRestCall_612658
proc url_GetDefineAnalysisScheme_613319(protocol: Scheme; host: string; base: string;
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

proc validate_GetDefineAnalysisScheme_613318(path: JsonNode; query: JsonNode;
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
  var valid_613320 = query.getOrDefault("DomainName")
  valid_613320 = validateParameter(valid_613320, JString, required = true,
                                 default = nil)
  if valid_613320 != nil:
    section.add "DomainName", valid_613320
  var valid_613321 = query.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_613321
  var valid_613322 = query.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_613322
  var valid_613323 = query.getOrDefault("Action")
  valid_613323 = validateParameter(valid_613323, JString, required = true,
                                 default = newJString("DefineAnalysisScheme"))
  if valid_613323 != nil:
    section.add "Action", valid_613323
  var valid_613324 = query.getOrDefault("AnalysisScheme.AnalysisSchemeLanguage")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_613324
  var valid_613325 = query.getOrDefault("Version")
  valid_613325 = validateParameter(valid_613325, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613325 != nil:
    section.add "Version", valid_613325
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
  var valid_613326 = header.getOrDefault("X-Amz-Signature")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-Signature", valid_613326
  var valid_613327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-Content-Sha256", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-Date")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-Date", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Credential")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Credential", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Security-Token")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Security-Token", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Algorithm")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Algorithm", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-SignedHeaders", valid_613332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613333: Call_GetDefineAnalysisScheme_613317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613333.validator(path, query, header, formData, body)
  let scheme = call_613333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613333.url(scheme.get, call_613333.host, call_613333.base,
                         call_613333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613333, url, valid)

proc call*(call_613334: Call_GetDefineAnalysisScheme_613317; DomainName: string;
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
  var query_613335 = newJObject()
  add(query_613335, "DomainName", newJString(DomainName))
  add(query_613335, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_613335, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  add(query_613335, "Action", newJString(Action))
  add(query_613335, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(query_613335, "Version", newJString(Version))
  result = call_613334.call(nil, query_613335, nil, nil, nil)

var getDefineAnalysisScheme* = Call_GetDefineAnalysisScheme_613317(
    name: "getDefineAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_GetDefineAnalysisScheme_613318, base: "/",
    url: url_GetDefineAnalysisScheme_613319, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineExpression_613374 = ref object of OpenApiRestCall_612658
proc url_PostDefineExpression_613376(protocol: Scheme; host: string; base: string;
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

proc validate_PostDefineExpression_613375(path: JsonNode; query: JsonNode;
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
  var valid_613377 = query.getOrDefault("Action")
  valid_613377 = validateParameter(valid_613377, JString, required = true,
                                 default = newJString("DefineExpression"))
  if valid_613377 != nil:
    section.add "Action", valid_613377
  var valid_613378 = query.getOrDefault("Version")
  valid_613378 = validateParameter(valid_613378, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613378 != nil:
    section.add "Version", valid_613378
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
  var valid_613379 = header.getOrDefault("X-Amz-Signature")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Signature", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-Content-Sha256", valid_613380
  var valid_613381 = header.getOrDefault("X-Amz-Date")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-Date", valid_613381
  var valid_613382 = header.getOrDefault("X-Amz-Credential")
  valid_613382 = validateParameter(valid_613382, JString, required = false,
                                 default = nil)
  if valid_613382 != nil:
    section.add "X-Amz-Credential", valid_613382
  var valid_613383 = header.getOrDefault("X-Amz-Security-Token")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-Security-Token", valid_613383
  var valid_613384 = header.getOrDefault("X-Amz-Algorithm")
  valid_613384 = validateParameter(valid_613384, JString, required = false,
                                 default = nil)
  if valid_613384 != nil:
    section.add "X-Amz-Algorithm", valid_613384
  var valid_613385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "X-Amz-SignedHeaders", valid_613385
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
  var valid_613386 = formData.getOrDefault("Expression.ExpressionName")
  valid_613386 = validateParameter(valid_613386, JString, required = false,
                                 default = nil)
  if valid_613386 != nil:
    section.add "Expression.ExpressionName", valid_613386
  var valid_613387 = formData.getOrDefault("Expression.ExpressionValue")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "Expression.ExpressionValue", valid_613387
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613388 = formData.getOrDefault("DomainName")
  valid_613388 = validateParameter(valid_613388, JString, required = true,
                                 default = nil)
  if valid_613388 != nil:
    section.add "DomainName", valid_613388
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613389: Call_PostDefineExpression_613374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613389.validator(path, query, header, formData, body)
  let scheme = call_613389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613389.url(scheme.get, call_613389.host, call_613389.base,
                         call_613389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613389, url, valid)

proc call*(call_613390: Call_PostDefineExpression_613374; DomainName: string;
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
  var query_613391 = newJObject()
  var formData_613392 = newJObject()
  add(formData_613392, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(formData_613392, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(formData_613392, "DomainName", newJString(DomainName))
  add(query_613391, "Action", newJString(Action))
  add(query_613391, "Version", newJString(Version))
  result = call_613390.call(nil, query_613391, nil, formData_613392, nil)

var postDefineExpression* = Call_PostDefineExpression_613374(
    name: "postDefineExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_PostDefineExpression_613375, base: "/",
    url: url_PostDefineExpression_613376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineExpression_613356 = ref object of OpenApiRestCall_612658
proc url_GetDefineExpression_613358(protocol: Scheme; host: string; base: string;
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

proc validate_GetDefineExpression_613357(path: JsonNode; query: JsonNode;
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
  var valid_613359 = query.getOrDefault("DomainName")
  valid_613359 = validateParameter(valid_613359, JString, required = true,
                                 default = nil)
  if valid_613359 != nil:
    section.add "DomainName", valid_613359
  var valid_613360 = query.getOrDefault("Expression.ExpressionValue")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "Expression.ExpressionValue", valid_613360
  var valid_613361 = query.getOrDefault("Action")
  valid_613361 = validateParameter(valid_613361, JString, required = true,
                                 default = newJString("DefineExpression"))
  if valid_613361 != nil:
    section.add "Action", valid_613361
  var valid_613362 = query.getOrDefault("Expression.ExpressionName")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "Expression.ExpressionName", valid_613362
  var valid_613363 = query.getOrDefault("Version")
  valid_613363 = validateParameter(valid_613363, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613363 != nil:
    section.add "Version", valid_613363
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
  var valid_613364 = header.getOrDefault("X-Amz-Signature")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Signature", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-Content-Sha256", valid_613365
  var valid_613366 = header.getOrDefault("X-Amz-Date")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "X-Amz-Date", valid_613366
  var valid_613367 = header.getOrDefault("X-Amz-Credential")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "X-Amz-Credential", valid_613367
  var valid_613368 = header.getOrDefault("X-Amz-Security-Token")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-Security-Token", valid_613368
  var valid_613369 = header.getOrDefault("X-Amz-Algorithm")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "X-Amz-Algorithm", valid_613369
  var valid_613370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-SignedHeaders", valid_613370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613371: Call_GetDefineExpression_613356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613371.validator(path, query, header, formData, body)
  let scheme = call_613371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613371.url(scheme.get, call_613371.host, call_613371.base,
                         call_613371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613371, url, valid)

proc call*(call_613372: Call_GetDefineExpression_613356; DomainName: string;
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
  var query_613373 = newJObject()
  add(query_613373, "DomainName", newJString(DomainName))
  add(query_613373, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(query_613373, "Action", newJString(Action))
  add(query_613373, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(query_613373, "Version", newJString(Version))
  result = call_613372.call(nil, query_613373, nil, nil, nil)

var getDefineExpression* = Call_GetDefineExpression_613356(
    name: "getDefineExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_GetDefineExpression_613357, base: "/",
    url: url_GetDefineExpression_613358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_613422 = ref object of OpenApiRestCall_612658
proc url_PostDefineIndexField_613424(protocol: Scheme; host: string; base: string;
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

proc validate_PostDefineIndexField_613423(path: JsonNode; query: JsonNode;
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
  var valid_613425 = query.getOrDefault("Action")
  valid_613425 = validateParameter(valid_613425, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_613425 != nil:
    section.add "Action", valid_613425
  var valid_613426 = query.getOrDefault("Version")
  valid_613426 = validateParameter(valid_613426, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613426 != nil:
    section.add "Version", valid_613426
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
  var valid_613427 = header.getOrDefault("X-Amz-Signature")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "X-Amz-Signature", valid_613427
  var valid_613428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "X-Amz-Content-Sha256", valid_613428
  var valid_613429 = header.getOrDefault("X-Amz-Date")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-Date", valid_613429
  var valid_613430 = header.getOrDefault("X-Amz-Credential")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-Credential", valid_613430
  var valid_613431 = header.getOrDefault("X-Amz-Security-Token")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Security-Token", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Algorithm")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Algorithm", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-SignedHeaders", valid_613433
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
  var valid_613434 = formData.getOrDefault("IndexField.IntOptions")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "IndexField.IntOptions", valid_613434
  var valid_613435 = formData.getOrDefault("IndexField.TextArrayOptions")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "IndexField.TextArrayOptions", valid_613435
  var valid_613436 = formData.getOrDefault("IndexField.DoubleOptions")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "IndexField.DoubleOptions", valid_613436
  var valid_613437 = formData.getOrDefault("IndexField.LatLonOptions")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "IndexField.LatLonOptions", valid_613437
  var valid_613438 = formData.getOrDefault("IndexField.LiteralArrayOptions")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_613438
  var valid_613439 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "IndexField.IndexFieldType", valid_613439
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613440 = formData.getOrDefault("DomainName")
  valid_613440 = validateParameter(valid_613440, JString, required = true,
                                 default = nil)
  if valid_613440 != nil:
    section.add "DomainName", valid_613440
  var valid_613441 = formData.getOrDefault("IndexField.TextOptions")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "IndexField.TextOptions", valid_613441
  var valid_613442 = formData.getOrDefault("IndexField.IntArrayOptions")
  valid_613442 = validateParameter(valid_613442, JString, required = false,
                                 default = nil)
  if valid_613442 != nil:
    section.add "IndexField.IntArrayOptions", valid_613442
  var valid_613443 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_613443 = validateParameter(valid_613443, JString, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "IndexField.LiteralOptions", valid_613443
  var valid_613444 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "IndexField.IndexFieldName", valid_613444
  var valid_613445 = formData.getOrDefault("IndexField.DateOptions")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "IndexField.DateOptions", valid_613445
  var valid_613446 = formData.getOrDefault("IndexField.DateArrayOptions")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "IndexField.DateArrayOptions", valid_613446
  var valid_613447 = formData.getOrDefault("IndexField.DoubleArrayOptions")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_613447
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613448: Call_PostDefineIndexField_613422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_613448.validator(path, query, header, formData, body)
  let scheme = call_613448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613448.url(scheme.get, call_613448.host, call_613448.base,
                         call_613448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613448, url, valid)

proc call*(call_613449: Call_PostDefineIndexField_613422; DomainName: string;
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
  var query_613450 = newJObject()
  var formData_613451 = newJObject()
  add(formData_613451, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(formData_613451, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(formData_613451, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(formData_613451, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  add(formData_613451, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(formData_613451, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(formData_613451, "DomainName", newJString(DomainName))
  add(formData_613451, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(formData_613451, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  add(formData_613451, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_613450, "Action", newJString(Action))
  add(formData_613451, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(formData_613451, "IndexField.DateOptions", newJString(IndexFieldDateOptions))
  add(formData_613451, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(query_613450, "Version", newJString(Version))
  add(formData_613451, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  result = call_613449.call(nil, query_613450, nil, formData_613451, nil)

var postDefineIndexField* = Call_PostDefineIndexField_613422(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_613423, base: "/",
    url: url_PostDefineIndexField_613424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_613393 = ref object of OpenApiRestCall_612658
proc url_GetDefineIndexField_613395(protocol: Scheme; host: string; base: string;
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

proc validate_GetDefineIndexField_613394(path: JsonNode; query: JsonNode;
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
  var valid_613396 = query.getOrDefault("IndexField.TextOptions")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "IndexField.TextOptions", valid_613396
  var valid_613397 = query.getOrDefault("IndexField.LiteralArrayOptions")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_613397
  var valid_613398 = query.getOrDefault("IndexField.DoubleArrayOptions")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_613398
  var valid_613399 = query.getOrDefault("IndexField.IntArrayOptions")
  valid_613399 = validateParameter(valid_613399, JString, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "IndexField.IntArrayOptions", valid_613399
  var valid_613400 = query.getOrDefault("IndexField.IndexFieldType")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "IndexField.IndexFieldType", valid_613400
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_613401 = query.getOrDefault("DomainName")
  valid_613401 = validateParameter(valid_613401, JString, required = true,
                                 default = nil)
  if valid_613401 != nil:
    section.add "DomainName", valid_613401
  var valid_613402 = query.getOrDefault("IndexField.IndexFieldName")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "IndexField.IndexFieldName", valid_613402
  var valid_613403 = query.getOrDefault("IndexField.DoubleOptions")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "IndexField.DoubleOptions", valid_613403
  var valid_613404 = query.getOrDefault("IndexField.TextArrayOptions")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "IndexField.TextArrayOptions", valid_613404
  var valid_613405 = query.getOrDefault("Action")
  valid_613405 = validateParameter(valid_613405, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_613405 != nil:
    section.add "Action", valid_613405
  var valid_613406 = query.getOrDefault("IndexField.DateOptions")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "IndexField.DateOptions", valid_613406
  var valid_613407 = query.getOrDefault("IndexField.LiteralOptions")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "IndexField.LiteralOptions", valid_613407
  var valid_613408 = query.getOrDefault("IndexField.IntOptions")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "IndexField.IntOptions", valid_613408
  var valid_613409 = query.getOrDefault("Version")
  valid_613409 = validateParameter(valid_613409, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613409 != nil:
    section.add "Version", valid_613409
  var valid_613410 = query.getOrDefault("IndexField.DateArrayOptions")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "IndexField.DateArrayOptions", valid_613410
  var valid_613411 = query.getOrDefault("IndexField.LatLonOptions")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "IndexField.LatLonOptions", valid_613411
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
  var valid_613412 = header.getOrDefault("X-Amz-Signature")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-Signature", valid_613412
  var valid_613413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-Content-Sha256", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-Date")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-Date", valid_613414
  var valid_613415 = header.getOrDefault("X-Amz-Credential")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Credential", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-Security-Token")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-Security-Token", valid_613416
  var valid_613417 = header.getOrDefault("X-Amz-Algorithm")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "X-Amz-Algorithm", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-SignedHeaders", valid_613418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613419: Call_GetDefineIndexField_613393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_613419.validator(path, query, header, formData, body)
  let scheme = call_613419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613419.url(scheme.get, call_613419.host, call_613419.base,
                         call_613419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613419, url, valid)

proc call*(call_613420: Call_GetDefineIndexField_613393; DomainName: string;
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
  var query_613421 = newJObject()
  add(query_613421, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_613421, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(query_613421, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  add(query_613421, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  add(query_613421, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_613421, "DomainName", newJString(DomainName))
  add(query_613421, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_613421, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(query_613421, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(query_613421, "Action", newJString(Action))
  add(query_613421, "IndexField.DateOptions", newJString(IndexFieldDateOptions))
  add(query_613421, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_613421, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(query_613421, "Version", newJString(Version))
  add(query_613421, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(query_613421, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  result = call_613420.call(nil, query_613421, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_613393(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_613394, base: "/",
    url: url_GetDefineIndexField_613395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineSuggester_613470 = ref object of OpenApiRestCall_612658
proc url_PostDefineSuggester_613472(protocol: Scheme; host: string; base: string;
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

proc validate_PostDefineSuggester_613471(path: JsonNode; query: JsonNode;
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
  var valid_613473 = query.getOrDefault("Action")
  valid_613473 = validateParameter(valid_613473, JString, required = true,
                                 default = newJString("DefineSuggester"))
  if valid_613473 != nil:
    section.add "Action", valid_613473
  var valid_613474 = query.getOrDefault("Version")
  valid_613474 = validateParameter(valid_613474, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613474 != nil:
    section.add "Version", valid_613474
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
  var valid_613475 = header.getOrDefault("X-Amz-Signature")
  valid_613475 = validateParameter(valid_613475, JString, required = false,
                                 default = nil)
  if valid_613475 != nil:
    section.add "X-Amz-Signature", valid_613475
  var valid_613476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613476 = validateParameter(valid_613476, JString, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "X-Amz-Content-Sha256", valid_613476
  var valid_613477 = header.getOrDefault("X-Amz-Date")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "X-Amz-Date", valid_613477
  var valid_613478 = header.getOrDefault("X-Amz-Credential")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-Credential", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Security-Token")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Security-Token", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Algorithm")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Algorithm", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-SignedHeaders", valid_613481
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
  var valid_613482 = formData.getOrDefault("DomainName")
  valid_613482 = validateParameter(valid_613482, JString, required = true,
                                 default = nil)
  if valid_613482 != nil:
    section.add "DomainName", valid_613482
  var valid_613483 = formData.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_613483
  var valid_613484 = formData.getOrDefault("Suggester.SuggesterName")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "Suggester.SuggesterName", valid_613484
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613485: Call_PostDefineSuggester_613470; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613485.validator(path, query, header, formData, body)
  let scheme = call_613485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613485.url(scheme.get, call_613485.host, call_613485.base,
                         call_613485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613485, url, valid)

proc call*(call_613486: Call_PostDefineSuggester_613470; DomainName: string;
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
  var query_613487 = newJObject()
  var formData_613488 = newJObject()
  add(formData_613488, "DomainName", newJString(DomainName))
  add(formData_613488, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(query_613487, "Action", newJString(Action))
  add(formData_613488, "Suggester.SuggesterName",
      newJString(SuggesterSuggesterName))
  add(query_613487, "Version", newJString(Version))
  result = call_613486.call(nil, query_613487, nil, formData_613488, nil)

var postDefineSuggester* = Call_PostDefineSuggester_613470(
    name: "postDefineSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_PostDefineSuggester_613471, base: "/",
    url: url_PostDefineSuggester_613472, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineSuggester_613452 = ref object of OpenApiRestCall_612658
proc url_GetDefineSuggester_613454(protocol: Scheme; host: string; base: string;
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

proc validate_GetDefineSuggester_613453(path: JsonNode; query: JsonNode;
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
  var valid_613455 = query.getOrDefault("DomainName")
  valid_613455 = validateParameter(valid_613455, JString, required = true,
                                 default = nil)
  if valid_613455 != nil:
    section.add "DomainName", valid_613455
  var valid_613456 = query.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_613456 = validateParameter(valid_613456, JString, required = false,
                                 default = nil)
  if valid_613456 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_613456
  var valid_613457 = query.getOrDefault("Action")
  valid_613457 = validateParameter(valid_613457, JString, required = true,
                                 default = newJString("DefineSuggester"))
  if valid_613457 != nil:
    section.add "Action", valid_613457
  var valid_613458 = query.getOrDefault("Suggester.SuggesterName")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "Suggester.SuggesterName", valid_613458
  var valid_613459 = query.getOrDefault("Version")
  valid_613459 = validateParameter(valid_613459, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613459 != nil:
    section.add "Version", valid_613459
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
  var valid_613460 = header.getOrDefault("X-Amz-Signature")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "X-Amz-Signature", valid_613460
  var valid_613461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Content-Sha256", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-Date")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Date", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-Credential")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Credential", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Security-Token")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Security-Token", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Algorithm")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Algorithm", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-SignedHeaders", valid_613466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613467: Call_GetDefineSuggester_613452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613467.validator(path, query, header, formData, body)
  let scheme = call_613467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613467.url(scheme.get, call_613467.host, call_613467.base,
                         call_613467.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613467, url, valid)

proc call*(call_613468: Call_GetDefineSuggester_613452; DomainName: string;
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
  var query_613469 = newJObject()
  add(query_613469, "DomainName", newJString(DomainName))
  add(query_613469, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(query_613469, "Action", newJString(Action))
  add(query_613469, "Suggester.SuggesterName", newJString(SuggesterSuggesterName))
  add(query_613469, "Version", newJString(Version))
  result = call_613468.call(nil, query_613469, nil, nil, nil)

var getDefineSuggester* = Call_GetDefineSuggester_613452(
    name: "getDefineSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_GetDefineSuggester_613453, base: "/",
    url: url_GetDefineSuggester_613454, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAnalysisScheme_613506 = ref object of OpenApiRestCall_612658
proc url_PostDeleteAnalysisScheme_613508(protocol: Scheme; host: string;
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

proc validate_PostDeleteAnalysisScheme_613507(path: JsonNode; query: JsonNode;
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
  var valid_613509 = query.getOrDefault("Action")
  valid_613509 = validateParameter(valid_613509, JString, required = true,
                                 default = newJString("DeleteAnalysisScheme"))
  if valid_613509 != nil:
    section.add "Action", valid_613509
  var valid_613510 = query.getOrDefault("Version")
  valid_613510 = validateParameter(valid_613510, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613510 != nil:
    section.add "Version", valid_613510
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
  var valid_613511 = header.getOrDefault("X-Amz-Signature")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Signature", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Content-Sha256", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Date")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Date", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-Credential")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Credential", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-Security-Token")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-Security-Token", valid_613515
  var valid_613516 = header.getOrDefault("X-Amz-Algorithm")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-Algorithm", valid_613516
  var valid_613517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-SignedHeaders", valid_613517
  result.add "header", section
  ## parameters in `formData` object:
  ##   AnalysisSchemeName: JString (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AnalysisSchemeName` field"
  var valid_613518 = formData.getOrDefault("AnalysisSchemeName")
  valid_613518 = validateParameter(valid_613518, JString, required = true,
                                 default = nil)
  if valid_613518 != nil:
    section.add "AnalysisSchemeName", valid_613518
  var valid_613519 = formData.getOrDefault("DomainName")
  valid_613519 = validateParameter(valid_613519, JString, required = true,
                                 default = nil)
  if valid_613519 != nil:
    section.add "DomainName", valid_613519
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613520: Call_PostDeleteAnalysisScheme_613506; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_613520.validator(path, query, header, formData, body)
  let scheme = call_613520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613520.url(scheme.get, call_613520.host, call_613520.base,
                         call_613520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613520, url, valid)

proc call*(call_613521: Call_PostDeleteAnalysisScheme_613506;
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
  var query_613522 = newJObject()
  var formData_613523 = newJObject()
  add(formData_613523, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(formData_613523, "DomainName", newJString(DomainName))
  add(query_613522, "Action", newJString(Action))
  add(query_613522, "Version", newJString(Version))
  result = call_613521.call(nil, query_613522, nil, formData_613523, nil)

var postDeleteAnalysisScheme* = Call_PostDeleteAnalysisScheme_613506(
    name: "postDeleteAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_PostDeleteAnalysisScheme_613507, base: "/",
    url: url_PostDeleteAnalysisScheme_613508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAnalysisScheme_613489 = ref object of OpenApiRestCall_612658
proc url_GetDeleteAnalysisScheme_613491(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteAnalysisScheme_613490(path: JsonNode; query: JsonNode;
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
  var valid_613492 = query.getOrDefault("DomainName")
  valid_613492 = validateParameter(valid_613492, JString, required = true,
                                 default = nil)
  if valid_613492 != nil:
    section.add "DomainName", valid_613492
  var valid_613493 = query.getOrDefault("Action")
  valid_613493 = validateParameter(valid_613493, JString, required = true,
                                 default = newJString("DeleteAnalysisScheme"))
  if valid_613493 != nil:
    section.add "Action", valid_613493
  var valid_613494 = query.getOrDefault("AnalysisSchemeName")
  valid_613494 = validateParameter(valid_613494, JString, required = true,
                                 default = nil)
  if valid_613494 != nil:
    section.add "AnalysisSchemeName", valid_613494
  var valid_613495 = query.getOrDefault("Version")
  valid_613495 = validateParameter(valid_613495, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613495 != nil:
    section.add "Version", valid_613495
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
  var valid_613496 = header.getOrDefault("X-Amz-Signature")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Signature", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Content-Sha256", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Date")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Date", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Credential")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Credential", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-Security-Token")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-Security-Token", valid_613500
  var valid_613501 = header.getOrDefault("X-Amz-Algorithm")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-Algorithm", valid_613501
  var valid_613502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-SignedHeaders", valid_613502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613503: Call_GetDeleteAnalysisScheme_613489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_613503.validator(path, query, header, formData, body)
  let scheme = call_613503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613503.url(scheme.get, call_613503.host, call_613503.base,
                         call_613503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613503, url, valid)

proc call*(call_613504: Call_GetDeleteAnalysisScheme_613489; DomainName: string;
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
  var query_613505 = newJObject()
  add(query_613505, "DomainName", newJString(DomainName))
  add(query_613505, "Action", newJString(Action))
  add(query_613505, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(query_613505, "Version", newJString(Version))
  result = call_613504.call(nil, query_613505, nil, nil, nil)

var getDeleteAnalysisScheme* = Call_GetDeleteAnalysisScheme_613489(
    name: "getDeleteAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_GetDeleteAnalysisScheme_613490, base: "/",
    url: url_GetDeleteAnalysisScheme_613491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_613540 = ref object of OpenApiRestCall_612658
proc url_PostDeleteDomain_613542(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDomain_613541(path: JsonNode; query: JsonNode;
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
  var valid_613543 = query.getOrDefault("Action")
  valid_613543 = validateParameter(valid_613543, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_613543 != nil:
    section.add "Action", valid_613543
  var valid_613544 = query.getOrDefault("Version")
  valid_613544 = validateParameter(valid_613544, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613544 != nil:
    section.add "Version", valid_613544
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
  var valid_613545 = header.getOrDefault("X-Amz-Signature")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-Signature", valid_613545
  var valid_613546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-Content-Sha256", valid_613546
  var valid_613547 = header.getOrDefault("X-Amz-Date")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "X-Amz-Date", valid_613547
  var valid_613548 = header.getOrDefault("X-Amz-Credential")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "X-Amz-Credential", valid_613548
  var valid_613549 = header.getOrDefault("X-Amz-Security-Token")
  valid_613549 = validateParameter(valid_613549, JString, required = false,
                                 default = nil)
  if valid_613549 != nil:
    section.add "X-Amz-Security-Token", valid_613549
  var valid_613550 = header.getOrDefault("X-Amz-Algorithm")
  valid_613550 = validateParameter(valid_613550, JString, required = false,
                                 default = nil)
  if valid_613550 != nil:
    section.add "X-Amz-Algorithm", valid_613550
  var valid_613551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613551 = validateParameter(valid_613551, JString, required = false,
                                 default = nil)
  if valid_613551 != nil:
    section.add "X-Amz-SignedHeaders", valid_613551
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613552 = formData.getOrDefault("DomainName")
  valid_613552 = validateParameter(valid_613552, JString, required = true,
                                 default = nil)
  if valid_613552 != nil:
    section.add "DomainName", valid_613552
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613553: Call_PostDeleteDomain_613540; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_613553.validator(path, query, header, formData, body)
  let scheme = call_613553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613553.url(scheme.get, call_613553.host, call_613553.base,
                         call_613553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613553, url, valid)

proc call*(call_613554: Call_PostDeleteDomain_613540; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613555 = newJObject()
  var formData_613556 = newJObject()
  add(formData_613556, "DomainName", newJString(DomainName))
  add(query_613555, "Action", newJString(Action))
  add(query_613555, "Version", newJString(Version))
  result = call_613554.call(nil, query_613555, nil, formData_613556, nil)

var postDeleteDomain* = Call_PostDeleteDomain_613540(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_613541,
    base: "/", url: url_PostDeleteDomain_613542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_613524 = ref object of OpenApiRestCall_612658
proc url_GetDeleteDomain_613526(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDomain_613525(path: JsonNode; query: JsonNode;
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
  var valid_613527 = query.getOrDefault("DomainName")
  valid_613527 = validateParameter(valid_613527, JString, required = true,
                                 default = nil)
  if valid_613527 != nil:
    section.add "DomainName", valid_613527
  var valid_613528 = query.getOrDefault("Action")
  valid_613528 = validateParameter(valid_613528, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_613528 != nil:
    section.add "Action", valid_613528
  var valid_613529 = query.getOrDefault("Version")
  valid_613529 = validateParameter(valid_613529, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613529 != nil:
    section.add "Version", valid_613529
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
  var valid_613530 = header.getOrDefault("X-Amz-Signature")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-Signature", valid_613530
  var valid_613531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-Content-Sha256", valid_613531
  var valid_613532 = header.getOrDefault("X-Amz-Date")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-Date", valid_613532
  var valid_613533 = header.getOrDefault("X-Amz-Credential")
  valid_613533 = validateParameter(valid_613533, JString, required = false,
                                 default = nil)
  if valid_613533 != nil:
    section.add "X-Amz-Credential", valid_613533
  var valid_613534 = header.getOrDefault("X-Amz-Security-Token")
  valid_613534 = validateParameter(valid_613534, JString, required = false,
                                 default = nil)
  if valid_613534 != nil:
    section.add "X-Amz-Security-Token", valid_613534
  var valid_613535 = header.getOrDefault("X-Amz-Algorithm")
  valid_613535 = validateParameter(valid_613535, JString, required = false,
                                 default = nil)
  if valid_613535 != nil:
    section.add "X-Amz-Algorithm", valid_613535
  var valid_613536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "X-Amz-SignedHeaders", valid_613536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613537: Call_GetDeleteDomain_613524; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_613537.validator(path, query, header, formData, body)
  let scheme = call_613537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613537.url(scheme.get, call_613537.host, call_613537.base,
                         call_613537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613537, url, valid)

proc call*(call_613538: Call_GetDeleteDomain_613524; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613539 = newJObject()
  add(query_613539, "DomainName", newJString(DomainName))
  add(query_613539, "Action", newJString(Action))
  add(query_613539, "Version", newJString(Version))
  result = call_613538.call(nil, query_613539, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_613524(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_613525,
    base: "/", url: url_GetDeleteDomain_613526, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteExpression_613574 = ref object of OpenApiRestCall_612658
proc url_PostDeleteExpression_613576(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteExpression_613575(path: JsonNode; query: JsonNode;
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
  var valid_613577 = query.getOrDefault("Action")
  valid_613577 = validateParameter(valid_613577, JString, required = true,
                                 default = newJString("DeleteExpression"))
  if valid_613577 != nil:
    section.add "Action", valid_613577
  var valid_613578 = query.getOrDefault("Version")
  valid_613578 = validateParameter(valid_613578, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613578 != nil:
    section.add "Version", valid_613578
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
  var valid_613579 = header.getOrDefault("X-Amz-Signature")
  valid_613579 = validateParameter(valid_613579, JString, required = false,
                                 default = nil)
  if valid_613579 != nil:
    section.add "X-Amz-Signature", valid_613579
  var valid_613580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613580 = validateParameter(valid_613580, JString, required = false,
                                 default = nil)
  if valid_613580 != nil:
    section.add "X-Amz-Content-Sha256", valid_613580
  var valid_613581 = header.getOrDefault("X-Amz-Date")
  valid_613581 = validateParameter(valid_613581, JString, required = false,
                                 default = nil)
  if valid_613581 != nil:
    section.add "X-Amz-Date", valid_613581
  var valid_613582 = header.getOrDefault("X-Amz-Credential")
  valid_613582 = validateParameter(valid_613582, JString, required = false,
                                 default = nil)
  if valid_613582 != nil:
    section.add "X-Amz-Credential", valid_613582
  var valid_613583 = header.getOrDefault("X-Amz-Security-Token")
  valid_613583 = validateParameter(valid_613583, JString, required = false,
                                 default = nil)
  if valid_613583 != nil:
    section.add "X-Amz-Security-Token", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Algorithm")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Algorithm", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-SignedHeaders", valid_613585
  result.add "header", section
  ## parameters in `formData` object:
  ##   ExpressionName: JString (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ExpressionName` field"
  var valid_613586 = formData.getOrDefault("ExpressionName")
  valid_613586 = validateParameter(valid_613586, JString, required = true,
                                 default = nil)
  if valid_613586 != nil:
    section.add "ExpressionName", valid_613586
  var valid_613587 = formData.getOrDefault("DomainName")
  valid_613587 = validateParameter(valid_613587, JString, required = true,
                                 default = nil)
  if valid_613587 != nil:
    section.add "DomainName", valid_613587
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613588: Call_PostDeleteExpression_613574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613588.validator(path, query, header, formData, body)
  let scheme = call_613588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613588.url(scheme.get, call_613588.host, call_613588.base,
                         call_613588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613588, url, valid)

proc call*(call_613589: Call_PostDeleteExpression_613574; ExpressionName: string;
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
  var query_613590 = newJObject()
  var formData_613591 = newJObject()
  add(formData_613591, "ExpressionName", newJString(ExpressionName))
  add(formData_613591, "DomainName", newJString(DomainName))
  add(query_613590, "Action", newJString(Action))
  add(query_613590, "Version", newJString(Version))
  result = call_613589.call(nil, query_613590, nil, formData_613591, nil)

var postDeleteExpression* = Call_PostDeleteExpression_613574(
    name: "postDeleteExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_PostDeleteExpression_613575, base: "/",
    url: url_PostDeleteExpression_613576, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteExpression_613557 = ref object of OpenApiRestCall_612658
proc url_GetDeleteExpression_613559(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteExpression_613558(path: JsonNode; query: JsonNode;
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
  var valid_613560 = query.getOrDefault("ExpressionName")
  valid_613560 = validateParameter(valid_613560, JString, required = true,
                                 default = nil)
  if valid_613560 != nil:
    section.add "ExpressionName", valid_613560
  var valid_613561 = query.getOrDefault("DomainName")
  valid_613561 = validateParameter(valid_613561, JString, required = true,
                                 default = nil)
  if valid_613561 != nil:
    section.add "DomainName", valid_613561
  var valid_613562 = query.getOrDefault("Action")
  valid_613562 = validateParameter(valid_613562, JString, required = true,
                                 default = newJString("DeleteExpression"))
  if valid_613562 != nil:
    section.add "Action", valid_613562
  var valid_613563 = query.getOrDefault("Version")
  valid_613563 = validateParameter(valid_613563, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613563 != nil:
    section.add "Version", valid_613563
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
  var valid_613564 = header.getOrDefault("X-Amz-Signature")
  valid_613564 = validateParameter(valid_613564, JString, required = false,
                                 default = nil)
  if valid_613564 != nil:
    section.add "X-Amz-Signature", valid_613564
  var valid_613565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613565 = validateParameter(valid_613565, JString, required = false,
                                 default = nil)
  if valid_613565 != nil:
    section.add "X-Amz-Content-Sha256", valid_613565
  var valid_613566 = header.getOrDefault("X-Amz-Date")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "X-Amz-Date", valid_613566
  var valid_613567 = header.getOrDefault("X-Amz-Credential")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "X-Amz-Credential", valid_613567
  var valid_613568 = header.getOrDefault("X-Amz-Security-Token")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "X-Amz-Security-Token", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-Algorithm")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Algorithm", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-SignedHeaders", valid_613570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613571: Call_GetDeleteExpression_613557; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613571.validator(path, query, header, formData, body)
  let scheme = call_613571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613571.url(scheme.get, call_613571.host, call_613571.base,
                         call_613571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613571, url, valid)

proc call*(call_613572: Call_GetDeleteExpression_613557; ExpressionName: string;
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
  var query_613573 = newJObject()
  add(query_613573, "ExpressionName", newJString(ExpressionName))
  add(query_613573, "DomainName", newJString(DomainName))
  add(query_613573, "Action", newJString(Action))
  add(query_613573, "Version", newJString(Version))
  result = call_613572.call(nil, query_613573, nil, nil, nil)

var getDeleteExpression* = Call_GetDeleteExpression_613557(
    name: "getDeleteExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_GetDeleteExpression_613558, base: "/",
    url: url_GetDeleteExpression_613559, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_613609 = ref object of OpenApiRestCall_612658
proc url_PostDeleteIndexField_613611(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteIndexField_613610(path: JsonNode; query: JsonNode;
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
  var valid_613612 = query.getOrDefault("Action")
  valid_613612 = validateParameter(valid_613612, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_613612 != nil:
    section.add "Action", valid_613612
  var valid_613613 = query.getOrDefault("Version")
  valid_613613 = validateParameter(valid_613613, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613613 != nil:
    section.add "Version", valid_613613
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
  var valid_613614 = header.getOrDefault("X-Amz-Signature")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "X-Amz-Signature", valid_613614
  var valid_613615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "X-Amz-Content-Sha256", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-Date")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Date", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Credential")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Credential", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Security-Token")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Security-Token", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Algorithm")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Algorithm", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-SignedHeaders", valid_613620
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldName: JString (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613621 = formData.getOrDefault("DomainName")
  valid_613621 = validateParameter(valid_613621, JString, required = true,
                                 default = nil)
  if valid_613621 != nil:
    section.add "DomainName", valid_613621
  var valid_613622 = formData.getOrDefault("IndexFieldName")
  valid_613622 = validateParameter(valid_613622, JString, required = true,
                                 default = nil)
  if valid_613622 != nil:
    section.add "IndexFieldName", valid_613622
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613623: Call_PostDeleteIndexField_613609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613623.validator(path, query, header, formData, body)
  let scheme = call_613623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613623.url(scheme.get, call_613623.host, call_613623.base,
                         call_613623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613623, url, valid)

proc call*(call_613624: Call_PostDeleteIndexField_613609; DomainName: string;
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
  var query_613625 = newJObject()
  var formData_613626 = newJObject()
  add(formData_613626, "DomainName", newJString(DomainName))
  add(formData_613626, "IndexFieldName", newJString(IndexFieldName))
  add(query_613625, "Action", newJString(Action))
  add(query_613625, "Version", newJString(Version))
  result = call_613624.call(nil, query_613625, nil, formData_613626, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_613609(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_613610, base: "/",
    url: url_PostDeleteIndexField_613611, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_613592 = ref object of OpenApiRestCall_612658
proc url_GetDeleteIndexField_613594(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteIndexField_613593(path: JsonNode; query: JsonNode;
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
  var valid_613595 = query.getOrDefault("DomainName")
  valid_613595 = validateParameter(valid_613595, JString, required = true,
                                 default = nil)
  if valid_613595 != nil:
    section.add "DomainName", valid_613595
  var valid_613596 = query.getOrDefault("Action")
  valid_613596 = validateParameter(valid_613596, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_613596 != nil:
    section.add "Action", valid_613596
  var valid_613597 = query.getOrDefault("IndexFieldName")
  valid_613597 = validateParameter(valid_613597, JString, required = true,
                                 default = nil)
  if valid_613597 != nil:
    section.add "IndexFieldName", valid_613597
  var valid_613598 = query.getOrDefault("Version")
  valid_613598 = validateParameter(valid_613598, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613598 != nil:
    section.add "Version", valid_613598
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
  var valid_613599 = header.getOrDefault("X-Amz-Signature")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "X-Amz-Signature", valid_613599
  var valid_613600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Content-Sha256", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Date")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Date", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Credential")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Credential", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-Security-Token")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Security-Token", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-Algorithm")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Algorithm", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-SignedHeaders", valid_613605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613606: Call_GetDeleteIndexField_613592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613606.validator(path, query, header, formData, body)
  let scheme = call_613606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613606.url(scheme.get, call_613606.host, call_613606.base,
                         call_613606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613606, url, valid)

proc call*(call_613607: Call_GetDeleteIndexField_613592; DomainName: string;
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
  var query_613608 = newJObject()
  add(query_613608, "DomainName", newJString(DomainName))
  add(query_613608, "Action", newJString(Action))
  add(query_613608, "IndexFieldName", newJString(IndexFieldName))
  add(query_613608, "Version", newJString(Version))
  result = call_613607.call(nil, query_613608, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_613592(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_613593, base: "/",
    url: url_GetDeleteIndexField_613594, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteSuggester_613644 = ref object of OpenApiRestCall_612658
proc url_PostDeleteSuggester_613646(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteSuggester_613645(path: JsonNode; query: JsonNode;
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
  var valid_613647 = query.getOrDefault("Action")
  valid_613647 = validateParameter(valid_613647, JString, required = true,
                                 default = newJString("DeleteSuggester"))
  if valid_613647 != nil:
    section.add "Action", valid_613647
  var valid_613648 = query.getOrDefault("Version")
  valid_613648 = validateParameter(valid_613648, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613648 != nil:
    section.add "Version", valid_613648
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
  var valid_613649 = header.getOrDefault("X-Amz-Signature")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "X-Amz-Signature", valid_613649
  var valid_613650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-Content-Sha256", valid_613650
  var valid_613651 = header.getOrDefault("X-Amz-Date")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Date", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-Credential")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-Credential", valid_613652
  var valid_613653 = header.getOrDefault("X-Amz-Security-Token")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "X-Amz-Security-Token", valid_613653
  var valid_613654 = header.getOrDefault("X-Amz-Algorithm")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-Algorithm", valid_613654
  var valid_613655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "X-Amz-SignedHeaders", valid_613655
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   SuggesterName: JString (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613656 = formData.getOrDefault("DomainName")
  valid_613656 = validateParameter(valid_613656, JString, required = true,
                                 default = nil)
  if valid_613656 != nil:
    section.add "DomainName", valid_613656
  var valid_613657 = formData.getOrDefault("SuggesterName")
  valid_613657 = validateParameter(valid_613657, JString, required = true,
                                 default = nil)
  if valid_613657 != nil:
    section.add "SuggesterName", valid_613657
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613658: Call_PostDeleteSuggester_613644; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613658.validator(path, query, header, formData, body)
  let scheme = call_613658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613658.url(scheme.get, call_613658.host, call_613658.base,
                         call_613658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613658, url, valid)

proc call*(call_613659: Call_PostDeleteSuggester_613644; DomainName: string;
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
  var query_613660 = newJObject()
  var formData_613661 = newJObject()
  add(formData_613661, "DomainName", newJString(DomainName))
  add(formData_613661, "SuggesterName", newJString(SuggesterName))
  add(query_613660, "Action", newJString(Action))
  add(query_613660, "Version", newJString(Version))
  result = call_613659.call(nil, query_613660, nil, formData_613661, nil)

var postDeleteSuggester* = Call_PostDeleteSuggester_613644(
    name: "postDeleteSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_PostDeleteSuggester_613645, base: "/",
    url: url_PostDeleteSuggester_613646, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteSuggester_613627 = ref object of OpenApiRestCall_612658
proc url_GetDeleteSuggester_613629(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteSuggester_613628(path: JsonNode; query: JsonNode;
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
  var valid_613630 = query.getOrDefault("DomainName")
  valid_613630 = validateParameter(valid_613630, JString, required = true,
                                 default = nil)
  if valid_613630 != nil:
    section.add "DomainName", valid_613630
  var valid_613631 = query.getOrDefault("Action")
  valid_613631 = validateParameter(valid_613631, JString, required = true,
                                 default = newJString("DeleteSuggester"))
  if valid_613631 != nil:
    section.add "Action", valid_613631
  var valid_613632 = query.getOrDefault("Version")
  valid_613632 = validateParameter(valid_613632, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613632 != nil:
    section.add "Version", valid_613632
  var valid_613633 = query.getOrDefault("SuggesterName")
  valid_613633 = validateParameter(valid_613633, JString, required = true,
                                 default = nil)
  if valid_613633 != nil:
    section.add "SuggesterName", valid_613633
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
  var valid_613634 = header.getOrDefault("X-Amz-Signature")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Signature", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-Content-Sha256", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-Date")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Date", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-Credential")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-Credential", valid_613637
  var valid_613638 = header.getOrDefault("X-Amz-Security-Token")
  valid_613638 = validateParameter(valid_613638, JString, required = false,
                                 default = nil)
  if valid_613638 != nil:
    section.add "X-Amz-Security-Token", valid_613638
  var valid_613639 = header.getOrDefault("X-Amz-Algorithm")
  valid_613639 = validateParameter(valid_613639, JString, required = false,
                                 default = nil)
  if valid_613639 != nil:
    section.add "X-Amz-Algorithm", valid_613639
  var valid_613640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613640 = validateParameter(valid_613640, JString, required = false,
                                 default = nil)
  if valid_613640 != nil:
    section.add "X-Amz-SignedHeaders", valid_613640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613641: Call_GetDeleteSuggester_613627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613641.validator(path, query, header, formData, body)
  let scheme = call_613641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613641.url(scheme.get, call_613641.host, call_613641.base,
                         call_613641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613641, url, valid)

proc call*(call_613642: Call_GetDeleteSuggester_613627; DomainName: string;
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
  var query_613643 = newJObject()
  add(query_613643, "DomainName", newJString(DomainName))
  add(query_613643, "Action", newJString(Action))
  add(query_613643, "Version", newJString(Version))
  add(query_613643, "SuggesterName", newJString(SuggesterName))
  result = call_613642.call(nil, query_613643, nil, nil, nil)

var getDeleteSuggester* = Call_GetDeleteSuggester_613627(
    name: "getDeleteSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_GetDeleteSuggester_613628, base: "/",
    url: url_GetDeleteSuggester_613629, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAnalysisSchemes_613680 = ref object of OpenApiRestCall_612658
proc url_PostDescribeAnalysisSchemes_613682(protocol: Scheme; host: string;
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

proc validate_PostDescribeAnalysisSchemes_613681(path: JsonNode; query: JsonNode;
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
  var valid_613683 = query.getOrDefault("Action")
  valid_613683 = validateParameter(valid_613683, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_613683 != nil:
    section.add "Action", valid_613683
  var valid_613684 = query.getOrDefault("Version")
  valid_613684 = validateParameter(valid_613684, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613684 != nil:
    section.add "Version", valid_613684
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
  var valid_613685 = header.getOrDefault("X-Amz-Signature")
  valid_613685 = validateParameter(valid_613685, JString, required = false,
                                 default = nil)
  if valid_613685 != nil:
    section.add "X-Amz-Signature", valid_613685
  var valid_613686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613686 = validateParameter(valid_613686, JString, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "X-Amz-Content-Sha256", valid_613686
  var valid_613687 = header.getOrDefault("X-Amz-Date")
  valid_613687 = validateParameter(valid_613687, JString, required = false,
                                 default = nil)
  if valid_613687 != nil:
    section.add "X-Amz-Date", valid_613687
  var valid_613688 = header.getOrDefault("X-Amz-Credential")
  valid_613688 = validateParameter(valid_613688, JString, required = false,
                                 default = nil)
  if valid_613688 != nil:
    section.add "X-Amz-Credential", valid_613688
  var valid_613689 = header.getOrDefault("X-Amz-Security-Token")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "X-Amz-Security-Token", valid_613689
  var valid_613690 = header.getOrDefault("X-Amz-Algorithm")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "X-Amz-Algorithm", valid_613690
  var valid_613691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-SignedHeaders", valid_613691
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  section = newJObject()
  var valid_613692 = formData.getOrDefault("Deployed")
  valid_613692 = validateParameter(valid_613692, JBool, required = false, default = nil)
  if valid_613692 != nil:
    section.add "Deployed", valid_613692
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613693 = formData.getOrDefault("DomainName")
  valid_613693 = validateParameter(valid_613693, JString, required = true,
                                 default = nil)
  if valid_613693 != nil:
    section.add "DomainName", valid_613693
  var valid_613694 = formData.getOrDefault("AnalysisSchemeNames")
  valid_613694 = validateParameter(valid_613694, JArray, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "AnalysisSchemeNames", valid_613694
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613695: Call_PostDescribeAnalysisSchemes_613680; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613695.validator(path, query, header, formData, body)
  let scheme = call_613695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613695.url(scheme.get, call_613695.host, call_613695.base,
                         call_613695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613695, url, valid)

proc call*(call_613696: Call_PostDescribeAnalysisSchemes_613680;
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
  var query_613697 = newJObject()
  var formData_613698 = newJObject()
  add(formData_613698, "Deployed", newJBool(Deployed))
  add(formData_613698, "DomainName", newJString(DomainName))
  if AnalysisSchemeNames != nil:
    formData_613698.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_613697, "Action", newJString(Action))
  add(query_613697, "Version", newJString(Version))
  result = call_613696.call(nil, query_613697, nil, formData_613698, nil)

var postDescribeAnalysisSchemes* = Call_PostDescribeAnalysisSchemes_613680(
    name: "postDescribeAnalysisSchemes", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_PostDescribeAnalysisSchemes_613681, base: "/",
    url: url_PostDescribeAnalysisSchemes_613682,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAnalysisSchemes_613662 = ref object of OpenApiRestCall_612658
proc url_GetDescribeAnalysisSchemes_613664(protocol: Scheme; host: string;
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

proc validate_GetDescribeAnalysisSchemes_613663(path: JsonNode; query: JsonNode;
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
  var valid_613665 = query.getOrDefault("DomainName")
  valid_613665 = validateParameter(valid_613665, JString, required = true,
                                 default = nil)
  if valid_613665 != nil:
    section.add "DomainName", valid_613665
  var valid_613666 = query.getOrDefault("AnalysisSchemeNames")
  valid_613666 = validateParameter(valid_613666, JArray, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "AnalysisSchemeNames", valid_613666
  var valid_613667 = query.getOrDefault("Deployed")
  valid_613667 = validateParameter(valid_613667, JBool, required = false, default = nil)
  if valid_613667 != nil:
    section.add "Deployed", valid_613667
  var valid_613668 = query.getOrDefault("Action")
  valid_613668 = validateParameter(valid_613668, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_613668 != nil:
    section.add "Action", valid_613668
  var valid_613669 = query.getOrDefault("Version")
  valid_613669 = validateParameter(valid_613669, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613669 != nil:
    section.add "Version", valid_613669
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
  var valid_613670 = header.getOrDefault("X-Amz-Signature")
  valid_613670 = validateParameter(valid_613670, JString, required = false,
                                 default = nil)
  if valid_613670 != nil:
    section.add "X-Amz-Signature", valid_613670
  var valid_613671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "X-Amz-Content-Sha256", valid_613671
  var valid_613672 = header.getOrDefault("X-Amz-Date")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "X-Amz-Date", valid_613672
  var valid_613673 = header.getOrDefault("X-Amz-Credential")
  valid_613673 = validateParameter(valid_613673, JString, required = false,
                                 default = nil)
  if valid_613673 != nil:
    section.add "X-Amz-Credential", valid_613673
  var valid_613674 = header.getOrDefault("X-Amz-Security-Token")
  valid_613674 = validateParameter(valid_613674, JString, required = false,
                                 default = nil)
  if valid_613674 != nil:
    section.add "X-Amz-Security-Token", valid_613674
  var valid_613675 = header.getOrDefault("X-Amz-Algorithm")
  valid_613675 = validateParameter(valid_613675, JString, required = false,
                                 default = nil)
  if valid_613675 != nil:
    section.add "X-Amz-Algorithm", valid_613675
  var valid_613676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613676 = validateParameter(valid_613676, JString, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "X-Amz-SignedHeaders", valid_613676
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613677: Call_GetDescribeAnalysisSchemes_613662; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613677.validator(path, query, header, formData, body)
  let scheme = call_613677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613677.url(scheme.get, call_613677.host, call_613677.base,
                         call_613677.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613677, url, valid)

proc call*(call_613678: Call_GetDescribeAnalysisSchemes_613662; DomainName: string;
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
  var query_613679 = newJObject()
  add(query_613679, "DomainName", newJString(DomainName))
  if AnalysisSchemeNames != nil:
    query_613679.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_613679, "Deployed", newJBool(Deployed))
  add(query_613679, "Action", newJString(Action))
  add(query_613679, "Version", newJString(Version))
  result = call_613678.call(nil, query_613679, nil, nil, nil)

var getDescribeAnalysisSchemes* = Call_GetDescribeAnalysisSchemes_613662(
    name: "getDescribeAnalysisSchemes", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_GetDescribeAnalysisSchemes_613663, base: "/",
    url: url_GetDescribeAnalysisSchemes_613664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_613716 = ref object of OpenApiRestCall_612658
proc url_PostDescribeAvailabilityOptions_613718(protocol: Scheme; host: string;
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

proc validate_PostDescribeAvailabilityOptions_613717(path: JsonNode;
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
  var valid_613719 = query.getOrDefault("Action")
  valid_613719 = validateParameter(valid_613719, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_613719 != nil:
    section.add "Action", valid_613719
  var valid_613720 = query.getOrDefault("Version")
  valid_613720 = validateParameter(valid_613720, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613720 != nil:
    section.add "Version", valid_613720
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
  var valid_613721 = header.getOrDefault("X-Amz-Signature")
  valid_613721 = validateParameter(valid_613721, JString, required = false,
                                 default = nil)
  if valid_613721 != nil:
    section.add "X-Amz-Signature", valid_613721
  var valid_613722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613722 = validateParameter(valid_613722, JString, required = false,
                                 default = nil)
  if valid_613722 != nil:
    section.add "X-Amz-Content-Sha256", valid_613722
  var valid_613723 = header.getOrDefault("X-Amz-Date")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-Date", valid_613723
  var valid_613724 = header.getOrDefault("X-Amz-Credential")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Credential", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-Security-Token")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-Security-Token", valid_613725
  var valid_613726 = header.getOrDefault("X-Amz-Algorithm")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "X-Amz-Algorithm", valid_613726
  var valid_613727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613727 = validateParameter(valid_613727, JString, required = false,
                                 default = nil)
  if valid_613727 != nil:
    section.add "X-Amz-SignedHeaders", valid_613727
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_613728 = formData.getOrDefault("Deployed")
  valid_613728 = validateParameter(valid_613728, JBool, required = false, default = nil)
  if valid_613728 != nil:
    section.add "Deployed", valid_613728
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613729 = formData.getOrDefault("DomainName")
  valid_613729 = validateParameter(valid_613729, JString, required = true,
                                 default = nil)
  if valid_613729 != nil:
    section.add "DomainName", valid_613729
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613730: Call_PostDescribeAvailabilityOptions_613716;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613730.validator(path, query, header, formData, body)
  let scheme = call_613730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613730.url(scheme.get, call_613730.host, call_613730.base,
                         call_613730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613730, url, valid)

proc call*(call_613731: Call_PostDescribeAvailabilityOptions_613716;
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
  var query_613732 = newJObject()
  var formData_613733 = newJObject()
  add(formData_613733, "Deployed", newJBool(Deployed))
  add(formData_613733, "DomainName", newJString(DomainName))
  add(query_613732, "Action", newJString(Action))
  add(query_613732, "Version", newJString(Version))
  result = call_613731.call(nil, query_613732, nil, formData_613733, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_613716(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_613717, base: "/",
    url: url_PostDescribeAvailabilityOptions_613718,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_613699 = ref object of OpenApiRestCall_612658
proc url_GetDescribeAvailabilityOptions_613701(protocol: Scheme; host: string;
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

proc validate_GetDescribeAvailabilityOptions_613700(path: JsonNode;
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
  var valid_613702 = query.getOrDefault("DomainName")
  valid_613702 = validateParameter(valid_613702, JString, required = true,
                                 default = nil)
  if valid_613702 != nil:
    section.add "DomainName", valid_613702
  var valid_613703 = query.getOrDefault("Deployed")
  valid_613703 = validateParameter(valid_613703, JBool, required = false, default = nil)
  if valid_613703 != nil:
    section.add "Deployed", valid_613703
  var valid_613704 = query.getOrDefault("Action")
  valid_613704 = validateParameter(valid_613704, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_613704 != nil:
    section.add "Action", valid_613704
  var valid_613705 = query.getOrDefault("Version")
  valid_613705 = validateParameter(valid_613705, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613705 != nil:
    section.add "Version", valid_613705
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
  var valid_613706 = header.getOrDefault("X-Amz-Signature")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Signature", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Content-Sha256", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-Date")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Date", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-Credential")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Credential", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-Security-Token")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-Security-Token", valid_613710
  var valid_613711 = header.getOrDefault("X-Amz-Algorithm")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Algorithm", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-SignedHeaders", valid_613712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613713: Call_GetDescribeAvailabilityOptions_613699; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613713.validator(path, query, header, formData, body)
  let scheme = call_613713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613713.url(scheme.get, call_613713.host, call_613713.base,
                         call_613713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613713, url, valid)

proc call*(call_613714: Call_GetDescribeAvailabilityOptions_613699;
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
  var query_613715 = newJObject()
  add(query_613715, "DomainName", newJString(DomainName))
  add(query_613715, "Deployed", newJBool(Deployed))
  add(query_613715, "Action", newJString(Action))
  add(query_613715, "Version", newJString(Version))
  result = call_613714.call(nil, query_613715, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_613699(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_613700, base: "/",
    url: url_GetDescribeAvailabilityOptions_613701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomainEndpointOptions_613751 = ref object of OpenApiRestCall_612658
proc url_PostDescribeDomainEndpointOptions_613753(protocol: Scheme; host: string;
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

proc validate_PostDescribeDomainEndpointOptions_613752(path: JsonNode;
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
  var valid_613754 = query.getOrDefault("Action")
  valid_613754 = validateParameter(valid_613754, JString, required = true, default = newJString(
      "DescribeDomainEndpointOptions"))
  if valid_613754 != nil:
    section.add "Action", valid_613754
  var valid_613755 = query.getOrDefault("Version")
  valid_613755 = validateParameter(valid_613755, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613755 != nil:
    section.add "Version", valid_613755
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
  var valid_613756 = header.getOrDefault("X-Amz-Signature")
  valid_613756 = validateParameter(valid_613756, JString, required = false,
                                 default = nil)
  if valid_613756 != nil:
    section.add "X-Amz-Signature", valid_613756
  var valid_613757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613757 = validateParameter(valid_613757, JString, required = false,
                                 default = nil)
  if valid_613757 != nil:
    section.add "X-Amz-Content-Sha256", valid_613757
  var valid_613758 = header.getOrDefault("X-Amz-Date")
  valid_613758 = validateParameter(valid_613758, JString, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "X-Amz-Date", valid_613758
  var valid_613759 = header.getOrDefault("X-Amz-Credential")
  valid_613759 = validateParameter(valid_613759, JString, required = false,
                                 default = nil)
  if valid_613759 != nil:
    section.add "X-Amz-Credential", valid_613759
  var valid_613760 = header.getOrDefault("X-Amz-Security-Token")
  valid_613760 = validateParameter(valid_613760, JString, required = false,
                                 default = nil)
  if valid_613760 != nil:
    section.add "X-Amz-Security-Token", valid_613760
  var valid_613761 = header.getOrDefault("X-Amz-Algorithm")
  valid_613761 = validateParameter(valid_613761, JString, required = false,
                                 default = nil)
  if valid_613761 != nil:
    section.add "X-Amz-Algorithm", valid_613761
  var valid_613762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613762 = validateParameter(valid_613762, JString, required = false,
                                 default = nil)
  if valid_613762 != nil:
    section.add "X-Amz-SignedHeaders", valid_613762
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to retrieve the latest configuration (which might be in a Processing state) or the current, active configuration. Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_613763 = formData.getOrDefault("Deployed")
  valid_613763 = validateParameter(valid_613763, JBool, required = false, default = nil)
  if valid_613763 != nil:
    section.add "Deployed", valid_613763
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613764 = formData.getOrDefault("DomainName")
  valid_613764 = validateParameter(valid_613764, JString, required = true,
                                 default = nil)
  if valid_613764 != nil:
    section.add "DomainName", valid_613764
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613765: Call_PostDescribeDomainEndpointOptions_613751;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613765.validator(path, query, header, formData, body)
  let scheme = call_613765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613765.url(scheme.get, call_613765.host, call_613765.base,
                         call_613765.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613765, url, valid)

proc call*(call_613766: Call_PostDescribeDomainEndpointOptions_613751;
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
  var query_613767 = newJObject()
  var formData_613768 = newJObject()
  add(formData_613768, "Deployed", newJBool(Deployed))
  add(formData_613768, "DomainName", newJString(DomainName))
  add(query_613767, "Action", newJString(Action))
  add(query_613767, "Version", newJString(Version))
  result = call_613766.call(nil, query_613767, nil, formData_613768, nil)

var postDescribeDomainEndpointOptions* = Call_PostDescribeDomainEndpointOptions_613751(
    name: "postDescribeDomainEndpointOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDomainEndpointOptions",
    validator: validate_PostDescribeDomainEndpointOptions_613752, base: "/",
    url: url_PostDescribeDomainEndpointOptions_613753,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomainEndpointOptions_613734 = ref object of OpenApiRestCall_612658
proc url_GetDescribeDomainEndpointOptions_613736(protocol: Scheme; host: string;
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

proc validate_GetDescribeDomainEndpointOptions_613735(path: JsonNode;
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
  var valid_613737 = query.getOrDefault("DomainName")
  valid_613737 = validateParameter(valid_613737, JString, required = true,
                                 default = nil)
  if valid_613737 != nil:
    section.add "DomainName", valid_613737
  var valid_613738 = query.getOrDefault("Deployed")
  valid_613738 = validateParameter(valid_613738, JBool, required = false, default = nil)
  if valid_613738 != nil:
    section.add "Deployed", valid_613738
  var valid_613739 = query.getOrDefault("Action")
  valid_613739 = validateParameter(valid_613739, JString, required = true, default = newJString(
      "DescribeDomainEndpointOptions"))
  if valid_613739 != nil:
    section.add "Action", valid_613739
  var valid_613740 = query.getOrDefault("Version")
  valid_613740 = validateParameter(valid_613740, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613740 != nil:
    section.add "Version", valid_613740
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
  var valid_613741 = header.getOrDefault("X-Amz-Signature")
  valid_613741 = validateParameter(valid_613741, JString, required = false,
                                 default = nil)
  if valid_613741 != nil:
    section.add "X-Amz-Signature", valid_613741
  var valid_613742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "X-Amz-Content-Sha256", valid_613742
  var valid_613743 = header.getOrDefault("X-Amz-Date")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-Date", valid_613743
  var valid_613744 = header.getOrDefault("X-Amz-Credential")
  valid_613744 = validateParameter(valid_613744, JString, required = false,
                                 default = nil)
  if valid_613744 != nil:
    section.add "X-Amz-Credential", valid_613744
  var valid_613745 = header.getOrDefault("X-Amz-Security-Token")
  valid_613745 = validateParameter(valid_613745, JString, required = false,
                                 default = nil)
  if valid_613745 != nil:
    section.add "X-Amz-Security-Token", valid_613745
  var valid_613746 = header.getOrDefault("X-Amz-Algorithm")
  valid_613746 = validateParameter(valid_613746, JString, required = false,
                                 default = nil)
  if valid_613746 != nil:
    section.add "X-Amz-Algorithm", valid_613746
  var valid_613747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613747 = validateParameter(valid_613747, JString, required = false,
                                 default = nil)
  if valid_613747 != nil:
    section.add "X-Amz-SignedHeaders", valid_613747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613748: Call_GetDescribeDomainEndpointOptions_613734;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613748.validator(path, query, header, formData, body)
  let scheme = call_613748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613748.url(scheme.get, call_613748.host, call_613748.base,
                         call_613748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613748, url, valid)

proc call*(call_613749: Call_GetDescribeDomainEndpointOptions_613734;
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
  var query_613750 = newJObject()
  add(query_613750, "DomainName", newJString(DomainName))
  add(query_613750, "Deployed", newJBool(Deployed))
  add(query_613750, "Action", newJString(Action))
  add(query_613750, "Version", newJString(Version))
  result = call_613749.call(nil, query_613750, nil, nil, nil)

var getDescribeDomainEndpointOptions* = Call_GetDescribeDomainEndpointOptions_613734(
    name: "getDescribeDomainEndpointOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDomainEndpointOptions",
    validator: validate_GetDescribeDomainEndpointOptions_613735, base: "/",
    url: url_GetDescribeDomainEndpointOptions_613736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_613785 = ref object of OpenApiRestCall_612658
proc url_PostDescribeDomains_613787(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDomains_613786(path: JsonNode; query: JsonNode;
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
  var valid_613788 = query.getOrDefault("Action")
  valid_613788 = validateParameter(valid_613788, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_613788 != nil:
    section.add "Action", valid_613788
  var valid_613789 = query.getOrDefault("Version")
  valid_613789 = validateParameter(valid_613789, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613789 != nil:
    section.add "Version", valid_613789
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
  var valid_613790 = header.getOrDefault("X-Amz-Signature")
  valid_613790 = validateParameter(valid_613790, JString, required = false,
                                 default = nil)
  if valid_613790 != nil:
    section.add "X-Amz-Signature", valid_613790
  var valid_613791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613791 = validateParameter(valid_613791, JString, required = false,
                                 default = nil)
  if valid_613791 != nil:
    section.add "X-Amz-Content-Sha256", valid_613791
  var valid_613792 = header.getOrDefault("X-Amz-Date")
  valid_613792 = validateParameter(valid_613792, JString, required = false,
                                 default = nil)
  if valid_613792 != nil:
    section.add "X-Amz-Date", valid_613792
  var valid_613793 = header.getOrDefault("X-Amz-Credential")
  valid_613793 = validateParameter(valid_613793, JString, required = false,
                                 default = nil)
  if valid_613793 != nil:
    section.add "X-Amz-Credential", valid_613793
  var valid_613794 = header.getOrDefault("X-Amz-Security-Token")
  valid_613794 = validateParameter(valid_613794, JString, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "X-Amz-Security-Token", valid_613794
  var valid_613795 = header.getOrDefault("X-Amz-Algorithm")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "X-Amz-Algorithm", valid_613795
  var valid_613796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613796 = validateParameter(valid_613796, JString, required = false,
                                 default = nil)
  if valid_613796 != nil:
    section.add "X-Amz-SignedHeaders", valid_613796
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_613797 = formData.getOrDefault("DomainNames")
  valid_613797 = validateParameter(valid_613797, JArray, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "DomainNames", valid_613797
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613798: Call_PostDescribeDomains_613785; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613798.validator(path, query, header, formData, body)
  let scheme = call_613798.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613798.url(scheme.get, call_613798.host, call_613798.base,
                         call_613798.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613798, url, valid)

proc call*(call_613799: Call_PostDescribeDomains_613785;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613800 = newJObject()
  var formData_613801 = newJObject()
  if DomainNames != nil:
    formData_613801.add "DomainNames", DomainNames
  add(query_613800, "Action", newJString(Action))
  add(query_613800, "Version", newJString(Version))
  result = call_613799.call(nil, query_613800, nil, formData_613801, nil)

var postDescribeDomains* = Call_PostDescribeDomains_613785(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_613786, base: "/",
    url: url_PostDescribeDomains_613787, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_613769 = ref object of OpenApiRestCall_612658
proc url_GetDescribeDomains_613771(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDomains_613770(path: JsonNode; query: JsonNode;
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
  var valid_613772 = query.getOrDefault("DomainNames")
  valid_613772 = validateParameter(valid_613772, JArray, required = false,
                                 default = nil)
  if valid_613772 != nil:
    section.add "DomainNames", valid_613772
  var valid_613773 = query.getOrDefault("Action")
  valid_613773 = validateParameter(valid_613773, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_613773 != nil:
    section.add "Action", valid_613773
  var valid_613774 = query.getOrDefault("Version")
  valid_613774 = validateParameter(valid_613774, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613774 != nil:
    section.add "Version", valid_613774
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
  var valid_613775 = header.getOrDefault("X-Amz-Signature")
  valid_613775 = validateParameter(valid_613775, JString, required = false,
                                 default = nil)
  if valid_613775 != nil:
    section.add "X-Amz-Signature", valid_613775
  var valid_613776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613776 = validateParameter(valid_613776, JString, required = false,
                                 default = nil)
  if valid_613776 != nil:
    section.add "X-Amz-Content-Sha256", valid_613776
  var valid_613777 = header.getOrDefault("X-Amz-Date")
  valid_613777 = validateParameter(valid_613777, JString, required = false,
                                 default = nil)
  if valid_613777 != nil:
    section.add "X-Amz-Date", valid_613777
  var valid_613778 = header.getOrDefault("X-Amz-Credential")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-Credential", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-Security-Token")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-Security-Token", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-Algorithm")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-Algorithm", valid_613780
  var valid_613781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613781 = validateParameter(valid_613781, JString, required = false,
                                 default = nil)
  if valid_613781 != nil:
    section.add "X-Amz-SignedHeaders", valid_613781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613782: Call_GetDescribeDomains_613769; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613782.validator(path, query, header, formData, body)
  let scheme = call_613782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613782.url(scheme.get, call_613782.host, call_613782.base,
                         call_613782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613782, url, valid)

proc call*(call_613783: Call_GetDescribeDomains_613769;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613784 = newJObject()
  if DomainNames != nil:
    query_613784.add "DomainNames", DomainNames
  add(query_613784, "Action", newJString(Action))
  add(query_613784, "Version", newJString(Version))
  result = call_613783.call(nil, query_613784, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_613769(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_613770, base: "/",
    url: url_GetDescribeDomains_613771, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeExpressions_613820 = ref object of OpenApiRestCall_612658
proc url_PostDescribeExpressions_613822(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeExpressions_613821(path: JsonNode; query: JsonNode;
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
  var valid_613823 = query.getOrDefault("Action")
  valid_613823 = validateParameter(valid_613823, JString, required = true,
                                 default = newJString("DescribeExpressions"))
  if valid_613823 != nil:
    section.add "Action", valid_613823
  var valid_613824 = query.getOrDefault("Version")
  valid_613824 = validateParameter(valid_613824, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613824 != nil:
    section.add "Version", valid_613824
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
  var valid_613825 = header.getOrDefault("X-Amz-Signature")
  valid_613825 = validateParameter(valid_613825, JString, required = false,
                                 default = nil)
  if valid_613825 != nil:
    section.add "X-Amz-Signature", valid_613825
  var valid_613826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613826 = validateParameter(valid_613826, JString, required = false,
                                 default = nil)
  if valid_613826 != nil:
    section.add "X-Amz-Content-Sha256", valid_613826
  var valid_613827 = header.getOrDefault("X-Amz-Date")
  valid_613827 = validateParameter(valid_613827, JString, required = false,
                                 default = nil)
  if valid_613827 != nil:
    section.add "X-Amz-Date", valid_613827
  var valid_613828 = header.getOrDefault("X-Amz-Credential")
  valid_613828 = validateParameter(valid_613828, JString, required = false,
                                 default = nil)
  if valid_613828 != nil:
    section.add "X-Amz-Credential", valid_613828
  var valid_613829 = header.getOrDefault("X-Amz-Security-Token")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-Security-Token", valid_613829
  var valid_613830 = header.getOrDefault("X-Amz-Algorithm")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "X-Amz-Algorithm", valid_613830
  var valid_613831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613831 = validateParameter(valid_613831, JString, required = false,
                                 default = nil)
  if valid_613831 != nil:
    section.add "X-Amz-SignedHeaders", valid_613831
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  section = newJObject()
  var valid_613832 = formData.getOrDefault("Deployed")
  valid_613832 = validateParameter(valid_613832, JBool, required = false, default = nil)
  if valid_613832 != nil:
    section.add "Deployed", valid_613832
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613833 = formData.getOrDefault("DomainName")
  valid_613833 = validateParameter(valid_613833, JString, required = true,
                                 default = nil)
  if valid_613833 != nil:
    section.add "DomainName", valid_613833
  var valid_613834 = formData.getOrDefault("ExpressionNames")
  valid_613834 = validateParameter(valid_613834, JArray, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "ExpressionNames", valid_613834
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613835: Call_PostDescribeExpressions_613820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613835.validator(path, query, header, formData, body)
  let scheme = call_613835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613835.url(scheme.get, call_613835.host, call_613835.base,
                         call_613835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613835, url, valid)

proc call*(call_613836: Call_PostDescribeExpressions_613820; DomainName: string;
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
  var query_613837 = newJObject()
  var formData_613838 = newJObject()
  add(formData_613838, "Deployed", newJBool(Deployed))
  add(formData_613838, "DomainName", newJString(DomainName))
  add(query_613837, "Action", newJString(Action))
  if ExpressionNames != nil:
    formData_613838.add "ExpressionNames", ExpressionNames
  add(query_613837, "Version", newJString(Version))
  result = call_613836.call(nil, query_613837, nil, formData_613838, nil)

var postDescribeExpressions* = Call_PostDescribeExpressions_613820(
    name: "postDescribeExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_PostDescribeExpressions_613821, base: "/",
    url: url_PostDescribeExpressions_613822, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeExpressions_613802 = ref object of OpenApiRestCall_612658
proc url_GetDescribeExpressions_613804(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeExpressions_613803(path: JsonNode; query: JsonNode;
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
  var valid_613805 = query.getOrDefault("ExpressionNames")
  valid_613805 = validateParameter(valid_613805, JArray, required = false,
                                 default = nil)
  if valid_613805 != nil:
    section.add "ExpressionNames", valid_613805
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_613806 = query.getOrDefault("DomainName")
  valid_613806 = validateParameter(valid_613806, JString, required = true,
                                 default = nil)
  if valid_613806 != nil:
    section.add "DomainName", valid_613806
  var valid_613807 = query.getOrDefault("Deployed")
  valid_613807 = validateParameter(valid_613807, JBool, required = false, default = nil)
  if valid_613807 != nil:
    section.add "Deployed", valid_613807
  var valid_613808 = query.getOrDefault("Action")
  valid_613808 = validateParameter(valid_613808, JString, required = true,
                                 default = newJString("DescribeExpressions"))
  if valid_613808 != nil:
    section.add "Action", valid_613808
  var valid_613809 = query.getOrDefault("Version")
  valid_613809 = validateParameter(valid_613809, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613809 != nil:
    section.add "Version", valid_613809
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
  var valid_613810 = header.getOrDefault("X-Amz-Signature")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "X-Amz-Signature", valid_613810
  var valid_613811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613811 = validateParameter(valid_613811, JString, required = false,
                                 default = nil)
  if valid_613811 != nil:
    section.add "X-Amz-Content-Sha256", valid_613811
  var valid_613812 = header.getOrDefault("X-Amz-Date")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "X-Amz-Date", valid_613812
  var valid_613813 = header.getOrDefault("X-Amz-Credential")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Credential", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Security-Token")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Security-Token", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-Algorithm")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-Algorithm", valid_613815
  var valid_613816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-SignedHeaders", valid_613816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613817: Call_GetDescribeExpressions_613802; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613817.validator(path, query, header, formData, body)
  let scheme = call_613817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613817.url(scheme.get, call_613817.host, call_613817.base,
                         call_613817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613817, url, valid)

proc call*(call_613818: Call_GetDescribeExpressions_613802; DomainName: string;
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
  var query_613819 = newJObject()
  if ExpressionNames != nil:
    query_613819.add "ExpressionNames", ExpressionNames
  add(query_613819, "DomainName", newJString(DomainName))
  add(query_613819, "Deployed", newJBool(Deployed))
  add(query_613819, "Action", newJString(Action))
  add(query_613819, "Version", newJString(Version))
  result = call_613818.call(nil, query_613819, nil, nil, nil)

var getDescribeExpressions* = Call_GetDescribeExpressions_613802(
    name: "getDescribeExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_GetDescribeExpressions_613803, base: "/",
    url: url_GetDescribeExpressions_613804, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_613857 = ref object of OpenApiRestCall_612658
proc url_PostDescribeIndexFields_613859(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeIndexFields_613858(path: JsonNode; query: JsonNode;
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
  var valid_613860 = query.getOrDefault("Action")
  valid_613860 = validateParameter(valid_613860, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_613860 != nil:
    section.add "Action", valid_613860
  var valid_613861 = query.getOrDefault("Version")
  valid_613861 = validateParameter(valid_613861, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613861 != nil:
    section.add "Version", valid_613861
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
  var valid_613862 = header.getOrDefault("X-Amz-Signature")
  valid_613862 = validateParameter(valid_613862, JString, required = false,
                                 default = nil)
  if valid_613862 != nil:
    section.add "X-Amz-Signature", valid_613862
  var valid_613863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613863 = validateParameter(valid_613863, JString, required = false,
                                 default = nil)
  if valid_613863 != nil:
    section.add "X-Amz-Content-Sha256", valid_613863
  var valid_613864 = header.getOrDefault("X-Amz-Date")
  valid_613864 = validateParameter(valid_613864, JString, required = false,
                                 default = nil)
  if valid_613864 != nil:
    section.add "X-Amz-Date", valid_613864
  var valid_613865 = header.getOrDefault("X-Amz-Credential")
  valid_613865 = validateParameter(valid_613865, JString, required = false,
                                 default = nil)
  if valid_613865 != nil:
    section.add "X-Amz-Credential", valid_613865
  var valid_613866 = header.getOrDefault("X-Amz-Security-Token")
  valid_613866 = validateParameter(valid_613866, JString, required = false,
                                 default = nil)
  if valid_613866 != nil:
    section.add "X-Amz-Security-Token", valid_613866
  var valid_613867 = header.getOrDefault("X-Amz-Algorithm")
  valid_613867 = validateParameter(valid_613867, JString, required = false,
                                 default = nil)
  if valid_613867 != nil:
    section.add "X-Amz-Algorithm", valid_613867
  var valid_613868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613868 = validateParameter(valid_613868, JString, required = false,
                                 default = nil)
  if valid_613868 != nil:
    section.add "X-Amz-SignedHeaders", valid_613868
  result.add "header", section
  ## parameters in `formData` object:
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_613869 = formData.getOrDefault("FieldNames")
  valid_613869 = validateParameter(valid_613869, JArray, required = false,
                                 default = nil)
  if valid_613869 != nil:
    section.add "FieldNames", valid_613869
  var valid_613870 = formData.getOrDefault("Deployed")
  valid_613870 = validateParameter(valid_613870, JBool, required = false, default = nil)
  if valid_613870 != nil:
    section.add "Deployed", valid_613870
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613871 = formData.getOrDefault("DomainName")
  valid_613871 = validateParameter(valid_613871, JString, required = true,
                                 default = nil)
  if valid_613871 != nil:
    section.add "DomainName", valid_613871
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613872: Call_PostDescribeIndexFields_613857; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613872.validator(path, query, header, formData, body)
  let scheme = call_613872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613872.url(scheme.get, call_613872.host, call_613872.base,
                         call_613872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613872, url, valid)

proc call*(call_613873: Call_PostDescribeIndexFields_613857; DomainName: string;
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
  var query_613874 = newJObject()
  var formData_613875 = newJObject()
  if FieldNames != nil:
    formData_613875.add "FieldNames", FieldNames
  add(formData_613875, "Deployed", newJBool(Deployed))
  add(formData_613875, "DomainName", newJString(DomainName))
  add(query_613874, "Action", newJString(Action))
  add(query_613874, "Version", newJString(Version))
  result = call_613873.call(nil, query_613874, nil, formData_613875, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_613857(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_613858, base: "/",
    url: url_PostDescribeIndexFields_613859, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_613839 = ref object of OpenApiRestCall_612658
proc url_GetDescribeIndexFields_613841(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeIndexFields_613840(path: JsonNode; query: JsonNode;
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
  var valid_613842 = query.getOrDefault("DomainName")
  valid_613842 = validateParameter(valid_613842, JString, required = true,
                                 default = nil)
  if valid_613842 != nil:
    section.add "DomainName", valid_613842
  var valid_613843 = query.getOrDefault("Deployed")
  valid_613843 = validateParameter(valid_613843, JBool, required = false, default = nil)
  if valid_613843 != nil:
    section.add "Deployed", valid_613843
  var valid_613844 = query.getOrDefault("Action")
  valid_613844 = validateParameter(valid_613844, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_613844 != nil:
    section.add "Action", valid_613844
  var valid_613845 = query.getOrDefault("Version")
  valid_613845 = validateParameter(valid_613845, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613845 != nil:
    section.add "Version", valid_613845
  var valid_613846 = query.getOrDefault("FieldNames")
  valid_613846 = validateParameter(valid_613846, JArray, required = false,
                                 default = nil)
  if valid_613846 != nil:
    section.add "FieldNames", valid_613846
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
  var valid_613847 = header.getOrDefault("X-Amz-Signature")
  valid_613847 = validateParameter(valid_613847, JString, required = false,
                                 default = nil)
  if valid_613847 != nil:
    section.add "X-Amz-Signature", valid_613847
  var valid_613848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "X-Amz-Content-Sha256", valid_613848
  var valid_613849 = header.getOrDefault("X-Amz-Date")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "X-Amz-Date", valid_613849
  var valid_613850 = header.getOrDefault("X-Amz-Credential")
  valid_613850 = validateParameter(valid_613850, JString, required = false,
                                 default = nil)
  if valid_613850 != nil:
    section.add "X-Amz-Credential", valid_613850
  var valid_613851 = header.getOrDefault("X-Amz-Security-Token")
  valid_613851 = validateParameter(valid_613851, JString, required = false,
                                 default = nil)
  if valid_613851 != nil:
    section.add "X-Amz-Security-Token", valid_613851
  var valid_613852 = header.getOrDefault("X-Amz-Algorithm")
  valid_613852 = validateParameter(valid_613852, JString, required = false,
                                 default = nil)
  if valid_613852 != nil:
    section.add "X-Amz-Algorithm", valid_613852
  var valid_613853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613853 = validateParameter(valid_613853, JString, required = false,
                                 default = nil)
  if valid_613853 != nil:
    section.add "X-Amz-SignedHeaders", valid_613853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613854: Call_GetDescribeIndexFields_613839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613854.validator(path, query, header, formData, body)
  let scheme = call_613854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613854.url(scheme.get, call_613854.host, call_613854.base,
                         call_613854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613854, url, valid)

proc call*(call_613855: Call_GetDescribeIndexFields_613839; DomainName: string;
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
  var query_613856 = newJObject()
  add(query_613856, "DomainName", newJString(DomainName))
  add(query_613856, "Deployed", newJBool(Deployed))
  add(query_613856, "Action", newJString(Action))
  add(query_613856, "Version", newJString(Version))
  if FieldNames != nil:
    query_613856.add "FieldNames", FieldNames
  result = call_613855.call(nil, query_613856, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_613839(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_613840, base: "/",
    url: url_GetDescribeIndexFields_613841, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeScalingParameters_613892 = ref object of OpenApiRestCall_612658
proc url_PostDescribeScalingParameters_613894(protocol: Scheme; host: string;
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

proc validate_PostDescribeScalingParameters_613893(path: JsonNode; query: JsonNode;
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
  var valid_613895 = query.getOrDefault("Action")
  valid_613895 = validateParameter(valid_613895, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_613895 != nil:
    section.add "Action", valid_613895
  var valid_613896 = query.getOrDefault("Version")
  valid_613896 = validateParameter(valid_613896, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613896 != nil:
    section.add "Version", valid_613896
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
  var valid_613897 = header.getOrDefault("X-Amz-Signature")
  valid_613897 = validateParameter(valid_613897, JString, required = false,
                                 default = nil)
  if valid_613897 != nil:
    section.add "X-Amz-Signature", valid_613897
  var valid_613898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613898 = validateParameter(valid_613898, JString, required = false,
                                 default = nil)
  if valid_613898 != nil:
    section.add "X-Amz-Content-Sha256", valid_613898
  var valid_613899 = header.getOrDefault("X-Amz-Date")
  valid_613899 = validateParameter(valid_613899, JString, required = false,
                                 default = nil)
  if valid_613899 != nil:
    section.add "X-Amz-Date", valid_613899
  var valid_613900 = header.getOrDefault("X-Amz-Credential")
  valid_613900 = validateParameter(valid_613900, JString, required = false,
                                 default = nil)
  if valid_613900 != nil:
    section.add "X-Amz-Credential", valid_613900
  var valid_613901 = header.getOrDefault("X-Amz-Security-Token")
  valid_613901 = validateParameter(valid_613901, JString, required = false,
                                 default = nil)
  if valid_613901 != nil:
    section.add "X-Amz-Security-Token", valid_613901
  var valid_613902 = header.getOrDefault("X-Amz-Algorithm")
  valid_613902 = validateParameter(valid_613902, JString, required = false,
                                 default = nil)
  if valid_613902 != nil:
    section.add "X-Amz-Algorithm", valid_613902
  var valid_613903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613903 = validateParameter(valid_613903, JString, required = false,
                                 default = nil)
  if valid_613903 != nil:
    section.add "X-Amz-SignedHeaders", valid_613903
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613904 = formData.getOrDefault("DomainName")
  valid_613904 = validateParameter(valid_613904, JString, required = true,
                                 default = nil)
  if valid_613904 != nil:
    section.add "DomainName", valid_613904
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613905: Call_PostDescribeScalingParameters_613892; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613905.validator(path, query, header, formData, body)
  let scheme = call_613905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613905.url(scheme.get, call_613905.host, call_613905.base,
                         call_613905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613905, url, valid)

proc call*(call_613906: Call_PostDescribeScalingParameters_613892;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613907 = newJObject()
  var formData_613908 = newJObject()
  add(formData_613908, "DomainName", newJString(DomainName))
  add(query_613907, "Action", newJString(Action))
  add(query_613907, "Version", newJString(Version))
  result = call_613906.call(nil, query_613907, nil, formData_613908, nil)

var postDescribeScalingParameters* = Call_PostDescribeScalingParameters_613892(
    name: "postDescribeScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_PostDescribeScalingParameters_613893, base: "/",
    url: url_PostDescribeScalingParameters_613894,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeScalingParameters_613876 = ref object of OpenApiRestCall_612658
proc url_GetDescribeScalingParameters_613878(protocol: Scheme; host: string;
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

proc validate_GetDescribeScalingParameters_613877(path: JsonNode; query: JsonNode;
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
  var valid_613879 = query.getOrDefault("DomainName")
  valid_613879 = validateParameter(valid_613879, JString, required = true,
                                 default = nil)
  if valid_613879 != nil:
    section.add "DomainName", valid_613879
  var valid_613880 = query.getOrDefault("Action")
  valid_613880 = validateParameter(valid_613880, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_613880 != nil:
    section.add "Action", valid_613880
  var valid_613881 = query.getOrDefault("Version")
  valid_613881 = validateParameter(valid_613881, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613881 != nil:
    section.add "Version", valid_613881
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
  var valid_613882 = header.getOrDefault("X-Amz-Signature")
  valid_613882 = validateParameter(valid_613882, JString, required = false,
                                 default = nil)
  if valid_613882 != nil:
    section.add "X-Amz-Signature", valid_613882
  var valid_613883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613883 = validateParameter(valid_613883, JString, required = false,
                                 default = nil)
  if valid_613883 != nil:
    section.add "X-Amz-Content-Sha256", valid_613883
  var valid_613884 = header.getOrDefault("X-Amz-Date")
  valid_613884 = validateParameter(valid_613884, JString, required = false,
                                 default = nil)
  if valid_613884 != nil:
    section.add "X-Amz-Date", valid_613884
  var valid_613885 = header.getOrDefault("X-Amz-Credential")
  valid_613885 = validateParameter(valid_613885, JString, required = false,
                                 default = nil)
  if valid_613885 != nil:
    section.add "X-Amz-Credential", valid_613885
  var valid_613886 = header.getOrDefault("X-Amz-Security-Token")
  valid_613886 = validateParameter(valid_613886, JString, required = false,
                                 default = nil)
  if valid_613886 != nil:
    section.add "X-Amz-Security-Token", valid_613886
  var valid_613887 = header.getOrDefault("X-Amz-Algorithm")
  valid_613887 = validateParameter(valid_613887, JString, required = false,
                                 default = nil)
  if valid_613887 != nil:
    section.add "X-Amz-Algorithm", valid_613887
  var valid_613888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613888 = validateParameter(valid_613888, JString, required = false,
                                 default = nil)
  if valid_613888 != nil:
    section.add "X-Amz-SignedHeaders", valid_613888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613889: Call_GetDescribeScalingParameters_613876; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613889.validator(path, query, header, formData, body)
  let scheme = call_613889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613889.url(scheme.get, call_613889.host, call_613889.base,
                         call_613889.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613889, url, valid)

proc call*(call_613890: Call_GetDescribeScalingParameters_613876;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613891 = newJObject()
  add(query_613891, "DomainName", newJString(DomainName))
  add(query_613891, "Action", newJString(Action))
  add(query_613891, "Version", newJString(Version))
  result = call_613890.call(nil, query_613891, nil, nil, nil)

var getDescribeScalingParameters* = Call_GetDescribeScalingParameters_613876(
    name: "getDescribeScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_GetDescribeScalingParameters_613877, base: "/",
    url: url_GetDescribeScalingParameters_613878,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_613926 = ref object of OpenApiRestCall_612658
proc url_PostDescribeServiceAccessPolicies_613928(protocol: Scheme; host: string;
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

proc validate_PostDescribeServiceAccessPolicies_613927(path: JsonNode;
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
  var valid_613929 = query.getOrDefault("Action")
  valid_613929 = validateParameter(valid_613929, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_613929 != nil:
    section.add "Action", valid_613929
  var valid_613930 = query.getOrDefault("Version")
  valid_613930 = validateParameter(valid_613930, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613930 != nil:
    section.add "Version", valid_613930
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
  var valid_613931 = header.getOrDefault("X-Amz-Signature")
  valid_613931 = validateParameter(valid_613931, JString, required = false,
                                 default = nil)
  if valid_613931 != nil:
    section.add "X-Amz-Signature", valid_613931
  var valid_613932 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613932 = validateParameter(valid_613932, JString, required = false,
                                 default = nil)
  if valid_613932 != nil:
    section.add "X-Amz-Content-Sha256", valid_613932
  var valid_613933 = header.getOrDefault("X-Amz-Date")
  valid_613933 = validateParameter(valid_613933, JString, required = false,
                                 default = nil)
  if valid_613933 != nil:
    section.add "X-Amz-Date", valid_613933
  var valid_613934 = header.getOrDefault("X-Amz-Credential")
  valid_613934 = validateParameter(valid_613934, JString, required = false,
                                 default = nil)
  if valid_613934 != nil:
    section.add "X-Amz-Credential", valid_613934
  var valid_613935 = header.getOrDefault("X-Amz-Security-Token")
  valid_613935 = validateParameter(valid_613935, JString, required = false,
                                 default = nil)
  if valid_613935 != nil:
    section.add "X-Amz-Security-Token", valid_613935
  var valid_613936 = header.getOrDefault("X-Amz-Algorithm")
  valid_613936 = validateParameter(valid_613936, JString, required = false,
                                 default = nil)
  if valid_613936 != nil:
    section.add "X-Amz-Algorithm", valid_613936
  var valid_613937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613937 = validateParameter(valid_613937, JString, required = false,
                                 default = nil)
  if valid_613937 != nil:
    section.add "X-Amz-SignedHeaders", valid_613937
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_613938 = formData.getOrDefault("Deployed")
  valid_613938 = validateParameter(valid_613938, JBool, required = false, default = nil)
  if valid_613938 != nil:
    section.add "Deployed", valid_613938
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613939 = formData.getOrDefault("DomainName")
  valid_613939 = validateParameter(valid_613939, JString, required = true,
                                 default = nil)
  if valid_613939 != nil:
    section.add "DomainName", valid_613939
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613940: Call_PostDescribeServiceAccessPolicies_613926;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613940.validator(path, query, header, formData, body)
  let scheme = call_613940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613940.url(scheme.get, call_613940.host, call_613940.base,
                         call_613940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613940, url, valid)

proc call*(call_613941: Call_PostDescribeServiceAccessPolicies_613926;
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
  var query_613942 = newJObject()
  var formData_613943 = newJObject()
  add(formData_613943, "Deployed", newJBool(Deployed))
  add(formData_613943, "DomainName", newJString(DomainName))
  add(query_613942, "Action", newJString(Action))
  add(query_613942, "Version", newJString(Version))
  result = call_613941.call(nil, query_613942, nil, formData_613943, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_613926(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_613927, base: "/",
    url: url_PostDescribeServiceAccessPolicies_613928,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_613909 = ref object of OpenApiRestCall_612658
proc url_GetDescribeServiceAccessPolicies_613911(protocol: Scheme; host: string;
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

proc validate_GetDescribeServiceAccessPolicies_613910(path: JsonNode;
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
  var valid_613912 = query.getOrDefault("DomainName")
  valid_613912 = validateParameter(valid_613912, JString, required = true,
                                 default = nil)
  if valid_613912 != nil:
    section.add "DomainName", valid_613912
  var valid_613913 = query.getOrDefault("Deployed")
  valid_613913 = validateParameter(valid_613913, JBool, required = false, default = nil)
  if valid_613913 != nil:
    section.add "Deployed", valid_613913
  var valid_613914 = query.getOrDefault("Action")
  valid_613914 = validateParameter(valid_613914, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_613914 != nil:
    section.add "Action", valid_613914
  var valid_613915 = query.getOrDefault("Version")
  valid_613915 = validateParameter(valid_613915, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613915 != nil:
    section.add "Version", valid_613915
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
  var valid_613916 = header.getOrDefault("X-Amz-Signature")
  valid_613916 = validateParameter(valid_613916, JString, required = false,
                                 default = nil)
  if valid_613916 != nil:
    section.add "X-Amz-Signature", valid_613916
  var valid_613917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613917 = validateParameter(valid_613917, JString, required = false,
                                 default = nil)
  if valid_613917 != nil:
    section.add "X-Amz-Content-Sha256", valid_613917
  var valid_613918 = header.getOrDefault("X-Amz-Date")
  valid_613918 = validateParameter(valid_613918, JString, required = false,
                                 default = nil)
  if valid_613918 != nil:
    section.add "X-Amz-Date", valid_613918
  var valid_613919 = header.getOrDefault("X-Amz-Credential")
  valid_613919 = validateParameter(valid_613919, JString, required = false,
                                 default = nil)
  if valid_613919 != nil:
    section.add "X-Amz-Credential", valid_613919
  var valid_613920 = header.getOrDefault("X-Amz-Security-Token")
  valid_613920 = validateParameter(valid_613920, JString, required = false,
                                 default = nil)
  if valid_613920 != nil:
    section.add "X-Amz-Security-Token", valid_613920
  var valid_613921 = header.getOrDefault("X-Amz-Algorithm")
  valid_613921 = validateParameter(valid_613921, JString, required = false,
                                 default = nil)
  if valid_613921 != nil:
    section.add "X-Amz-Algorithm", valid_613921
  var valid_613922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613922 = validateParameter(valid_613922, JString, required = false,
                                 default = nil)
  if valid_613922 != nil:
    section.add "X-Amz-SignedHeaders", valid_613922
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613923: Call_GetDescribeServiceAccessPolicies_613909;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613923.validator(path, query, header, formData, body)
  let scheme = call_613923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613923.url(scheme.get, call_613923.host, call_613923.base,
                         call_613923.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613923, url, valid)

proc call*(call_613924: Call_GetDescribeServiceAccessPolicies_613909;
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
  var query_613925 = newJObject()
  add(query_613925, "DomainName", newJString(DomainName))
  add(query_613925, "Deployed", newJBool(Deployed))
  add(query_613925, "Action", newJString(Action))
  add(query_613925, "Version", newJString(Version))
  result = call_613924.call(nil, query_613925, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_613909(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_613910, base: "/",
    url: url_GetDescribeServiceAccessPolicies_613911,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSuggesters_613962 = ref object of OpenApiRestCall_612658
proc url_PostDescribeSuggesters_613964(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeSuggesters_613963(path: JsonNode; query: JsonNode;
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
  var valid_613965 = query.getOrDefault("Action")
  valid_613965 = validateParameter(valid_613965, JString, required = true,
                                 default = newJString("DescribeSuggesters"))
  if valid_613965 != nil:
    section.add "Action", valid_613965
  var valid_613966 = query.getOrDefault("Version")
  valid_613966 = validateParameter(valid_613966, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613966 != nil:
    section.add "Version", valid_613966
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
  var valid_613967 = header.getOrDefault("X-Amz-Signature")
  valid_613967 = validateParameter(valid_613967, JString, required = false,
                                 default = nil)
  if valid_613967 != nil:
    section.add "X-Amz-Signature", valid_613967
  var valid_613968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613968 = validateParameter(valid_613968, JString, required = false,
                                 default = nil)
  if valid_613968 != nil:
    section.add "X-Amz-Content-Sha256", valid_613968
  var valid_613969 = header.getOrDefault("X-Amz-Date")
  valid_613969 = validateParameter(valid_613969, JString, required = false,
                                 default = nil)
  if valid_613969 != nil:
    section.add "X-Amz-Date", valid_613969
  var valid_613970 = header.getOrDefault("X-Amz-Credential")
  valid_613970 = validateParameter(valid_613970, JString, required = false,
                                 default = nil)
  if valid_613970 != nil:
    section.add "X-Amz-Credential", valid_613970
  var valid_613971 = header.getOrDefault("X-Amz-Security-Token")
  valid_613971 = validateParameter(valid_613971, JString, required = false,
                                 default = nil)
  if valid_613971 != nil:
    section.add "X-Amz-Security-Token", valid_613971
  var valid_613972 = header.getOrDefault("X-Amz-Algorithm")
  valid_613972 = validateParameter(valid_613972, JString, required = false,
                                 default = nil)
  if valid_613972 != nil:
    section.add "X-Amz-Algorithm", valid_613972
  var valid_613973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613973 = validateParameter(valid_613973, JString, required = false,
                                 default = nil)
  if valid_613973 != nil:
    section.add "X-Amz-SignedHeaders", valid_613973
  result.add "header", section
  ## parameters in `formData` object:
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_613974 = formData.getOrDefault("SuggesterNames")
  valid_613974 = validateParameter(valid_613974, JArray, required = false,
                                 default = nil)
  if valid_613974 != nil:
    section.add "SuggesterNames", valid_613974
  var valid_613975 = formData.getOrDefault("Deployed")
  valid_613975 = validateParameter(valid_613975, JBool, required = false, default = nil)
  if valid_613975 != nil:
    section.add "Deployed", valid_613975
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613976 = formData.getOrDefault("DomainName")
  valid_613976 = validateParameter(valid_613976, JString, required = true,
                                 default = nil)
  if valid_613976 != nil:
    section.add "DomainName", valid_613976
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613977: Call_PostDescribeSuggesters_613962; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613977.validator(path, query, header, formData, body)
  let scheme = call_613977.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613977.url(scheme.get, call_613977.host, call_613977.base,
                         call_613977.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613977, url, valid)

proc call*(call_613978: Call_PostDescribeSuggesters_613962; DomainName: string;
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
  var query_613979 = newJObject()
  var formData_613980 = newJObject()
  if SuggesterNames != nil:
    formData_613980.add "SuggesterNames", SuggesterNames
  add(formData_613980, "Deployed", newJBool(Deployed))
  add(formData_613980, "DomainName", newJString(DomainName))
  add(query_613979, "Action", newJString(Action))
  add(query_613979, "Version", newJString(Version))
  result = call_613978.call(nil, query_613979, nil, formData_613980, nil)

var postDescribeSuggesters* = Call_PostDescribeSuggesters_613962(
    name: "postDescribeSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_PostDescribeSuggesters_613963, base: "/",
    url: url_PostDescribeSuggesters_613964, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSuggesters_613944 = ref object of OpenApiRestCall_612658
proc url_GetDescribeSuggesters_613946(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeSuggesters_613945(path: JsonNode; query: JsonNode;
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
  var valid_613947 = query.getOrDefault("DomainName")
  valid_613947 = validateParameter(valid_613947, JString, required = true,
                                 default = nil)
  if valid_613947 != nil:
    section.add "DomainName", valid_613947
  var valid_613948 = query.getOrDefault("Deployed")
  valid_613948 = validateParameter(valid_613948, JBool, required = false, default = nil)
  if valid_613948 != nil:
    section.add "Deployed", valid_613948
  var valid_613949 = query.getOrDefault("Action")
  valid_613949 = validateParameter(valid_613949, JString, required = true,
                                 default = newJString("DescribeSuggesters"))
  if valid_613949 != nil:
    section.add "Action", valid_613949
  var valid_613950 = query.getOrDefault("Version")
  valid_613950 = validateParameter(valid_613950, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613950 != nil:
    section.add "Version", valid_613950
  var valid_613951 = query.getOrDefault("SuggesterNames")
  valid_613951 = validateParameter(valid_613951, JArray, required = false,
                                 default = nil)
  if valid_613951 != nil:
    section.add "SuggesterNames", valid_613951
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
  var valid_613952 = header.getOrDefault("X-Amz-Signature")
  valid_613952 = validateParameter(valid_613952, JString, required = false,
                                 default = nil)
  if valid_613952 != nil:
    section.add "X-Amz-Signature", valid_613952
  var valid_613953 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613953 = validateParameter(valid_613953, JString, required = false,
                                 default = nil)
  if valid_613953 != nil:
    section.add "X-Amz-Content-Sha256", valid_613953
  var valid_613954 = header.getOrDefault("X-Amz-Date")
  valid_613954 = validateParameter(valid_613954, JString, required = false,
                                 default = nil)
  if valid_613954 != nil:
    section.add "X-Amz-Date", valid_613954
  var valid_613955 = header.getOrDefault("X-Amz-Credential")
  valid_613955 = validateParameter(valid_613955, JString, required = false,
                                 default = nil)
  if valid_613955 != nil:
    section.add "X-Amz-Credential", valid_613955
  var valid_613956 = header.getOrDefault("X-Amz-Security-Token")
  valid_613956 = validateParameter(valid_613956, JString, required = false,
                                 default = nil)
  if valid_613956 != nil:
    section.add "X-Amz-Security-Token", valid_613956
  var valid_613957 = header.getOrDefault("X-Amz-Algorithm")
  valid_613957 = validateParameter(valid_613957, JString, required = false,
                                 default = nil)
  if valid_613957 != nil:
    section.add "X-Amz-Algorithm", valid_613957
  var valid_613958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613958 = validateParameter(valid_613958, JString, required = false,
                                 default = nil)
  if valid_613958 != nil:
    section.add "X-Amz-SignedHeaders", valid_613958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613959: Call_GetDescribeSuggesters_613944; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613959.validator(path, query, header, formData, body)
  let scheme = call_613959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613959.url(scheme.get, call_613959.host, call_613959.base,
                         call_613959.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613959, url, valid)

proc call*(call_613960: Call_GetDescribeSuggesters_613944; DomainName: string;
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
  var query_613961 = newJObject()
  add(query_613961, "DomainName", newJString(DomainName))
  add(query_613961, "Deployed", newJBool(Deployed))
  add(query_613961, "Action", newJString(Action))
  add(query_613961, "Version", newJString(Version))
  if SuggesterNames != nil:
    query_613961.add "SuggesterNames", SuggesterNames
  result = call_613960.call(nil, query_613961, nil, nil, nil)

var getDescribeSuggesters* = Call_GetDescribeSuggesters_613944(
    name: "getDescribeSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_GetDescribeSuggesters_613945, base: "/",
    url: url_GetDescribeSuggesters_613946, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_613997 = ref object of OpenApiRestCall_612658
proc url_PostIndexDocuments_613999(protocol: Scheme; host: string; base: string;
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

proc validate_PostIndexDocuments_613998(path: JsonNode; query: JsonNode;
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
  var valid_614000 = query.getOrDefault("Action")
  valid_614000 = validateParameter(valid_614000, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_614000 != nil:
    section.add "Action", valid_614000
  var valid_614001 = query.getOrDefault("Version")
  valid_614001 = validateParameter(valid_614001, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_614001 != nil:
    section.add "Version", valid_614001
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
  var valid_614002 = header.getOrDefault("X-Amz-Signature")
  valid_614002 = validateParameter(valid_614002, JString, required = false,
                                 default = nil)
  if valid_614002 != nil:
    section.add "X-Amz-Signature", valid_614002
  var valid_614003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614003 = validateParameter(valid_614003, JString, required = false,
                                 default = nil)
  if valid_614003 != nil:
    section.add "X-Amz-Content-Sha256", valid_614003
  var valid_614004 = header.getOrDefault("X-Amz-Date")
  valid_614004 = validateParameter(valid_614004, JString, required = false,
                                 default = nil)
  if valid_614004 != nil:
    section.add "X-Amz-Date", valid_614004
  var valid_614005 = header.getOrDefault("X-Amz-Credential")
  valid_614005 = validateParameter(valid_614005, JString, required = false,
                                 default = nil)
  if valid_614005 != nil:
    section.add "X-Amz-Credential", valid_614005
  var valid_614006 = header.getOrDefault("X-Amz-Security-Token")
  valid_614006 = validateParameter(valid_614006, JString, required = false,
                                 default = nil)
  if valid_614006 != nil:
    section.add "X-Amz-Security-Token", valid_614006
  var valid_614007 = header.getOrDefault("X-Amz-Algorithm")
  valid_614007 = validateParameter(valid_614007, JString, required = false,
                                 default = nil)
  if valid_614007 != nil:
    section.add "X-Amz-Algorithm", valid_614007
  var valid_614008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614008 = validateParameter(valid_614008, JString, required = false,
                                 default = nil)
  if valid_614008 != nil:
    section.add "X-Amz-SignedHeaders", valid_614008
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_614009 = formData.getOrDefault("DomainName")
  valid_614009 = validateParameter(valid_614009, JString, required = true,
                                 default = nil)
  if valid_614009 != nil:
    section.add "DomainName", valid_614009
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614010: Call_PostIndexDocuments_613997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_614010.validator(path, query, header, formData, body)
  let scheme = call_614010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614010.url(scheme.get, call_614010.host, call_614010.base,
                         call_614010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614010, url, valid)

proc call*(call_614011: Call_PostIndexDocuments_613997; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614012 = newJObject()
  var formData_614013 = newJObject()
  add(formData_614013, "DomainName", newJString(DomainName))
  add(query_614012, "Action", newJString(Action))
  add(query_614012, "Version", newJString(Version))
  result = call_614011.call(nil, query_614012, nil, formData_614013, nil)

var postIndexDocuments* = Call_PostIndexDocuments_613997(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_613998, base: "/",
    url: url_PostIndexDocuments_613999, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_613981 = ref object of OpenApiRestCall_612658
proc url_GetIndexDocuments_613983(protocol: Scheme; host: string; base: string;
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

proc validate_GetIndexDocuments_613982(path: JsonNode; query: JsonNode;
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
  var valid_613984 = query.getOrDefault("DomainName")
  valid_613984 = validateParameter(valid_613984, JString, required = true,
                                 default = nil)
  if valid_613984 != nil:
    section.add "DomainName", valid_613984
  var valid_613985 = query.getOrDefault("Action")
  valid_613985 = validateParameter(valid_613985, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_613985 != nil:
    section.add "Action", valid_613985
  var valid_613986 = query.getOrDefault("Version")
  valid_613986 = validateParameter(valid_613986, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_613986 != nil:
    section.add "Version", valid_613986
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
  var valid_613987 = header.getOrDefault("X-Amz-Signature")
  valid_613987 = validateParameter(valid_613987, JString, required = false,
                                 default = nil)
  if valid_613987 != nil:
    section.add "X-Amz-Signature", valid_613987
  var valid_613988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613988 = validateParameter(valid_613988, JString, required = false,
                                 default = nil)
  if valid_613988 != nil:
    section.add "X-Amz-Content-Sha256", valid_613988
  var valid_613989 = header.getOrDefault("X-Amz-Date")
  valid_613989 = validateParameter(valid_613989, JString, required = false,
                                 default = nil)
  if valid_613989 != nil:
    section.add "X-Amz-Date", valid_613989
  var valid_613990 = header.getOrDefault("X-Amz-Credential")
  valid_613990 = validateParameter(valid_613990, JString, required = false,
                                 default = nil)
  if valid_613990 != nil:
    section.add "X-Amz-Credential", valid_613990
  var valid_613991 = header.getOrDefault("X-Amz-Security-Token")
  valid_613991 = validateParameter(valid_613991, JString, required = false,
                                 default = nil)
  if valid_613991 != nil:
    section.add "X-Amz-Security-Token", valid_613991
  var valid_613992 = header.getOrDefault("X-Amz-Algorithm")
  valid_613992 = validateParameter(valid_613992, JString, required = false,
                                 default = nil)
  if valid_613992 != nil:
    section.add "X-Amz-Algorithm", valid_613992
  var valid_613993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613993 = validateParameter(valid_613993, JString, required = false,
                                 default = nil)
  if valid_613993 != nil:
    section.add "X-Amz-SignedHeaders", valid_613993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613994: Call_GetIndexDocuments_613981; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_613994.validator(path, query, header, formData, body)
  let scheme = call_613994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613994.url(scheme.get, call_613994.host, call_613994.base,
                         call_613994.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613994, url, valid)

proc call*(call_613995: Call_GetIndexDocuments_613981; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613996 = newJObject()
  add(query_613996, "DomainName", newJString(DomainName))
  add(query_613996, "Action", newJString(Action))
  add(query_613996, "Version", newJString(Version))
  result = call_613995.call(nil, query_613996, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_613981(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_613982,
    base: "/", url: url_GetIndexDocuments_613983,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomainNames_614029 = ref object of OpenApiRestCall_612658
proc url_PostListDomainNames_614031(protocol: Scheme; host: string; base: string;
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

proc validate_PostListDomainNames_614030(path: JsonNode; query: JsonNode;
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
  var valid_614032 = query.getOrDefault("Action")
  valid_614032 = validateParameter(valid_614032, JString, required = true,
                                 default = newJString("ListDomainNames"))
  if valid_614032 != nil:
    section.add "Action", valid_614032
  var valid_614033 = query.getOrDefault("Version")
  valid_614033 = validateParameter(valid_614033, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_614033 != nil:
    section.add "Version", valid_614033
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
  var valid_614034 = header.getOrDefault("X-Amz-Signature")
  valid_614034 = validateParameter(valid_614034, JString, required = false,
                                 default = nil)
  if valid_614034 != nil:
    section.add "X-Amz-Signature", valid_614034
  var valid_614035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614035 = validateParameter(valid_614035, JString, required = false,
                                 default = nil)
  if valid_614035 != nil:
    section.add "X-Amz-Content-Sha256", valid_614035
  var valid_614036 = header.getOrDefault("X-Amz-Date")
  valid_614036 = validateParameter(valid_614036, JString, required = false,
                                 default = nil)
  if valid_614036 != nil:
    section.add "X-Amz-Date", valid_614036
  var valid_614037 = header.getOrDefault("X-Amz-Credential")
  valid_614037 = validateParameter(valid_614037, JString, required = false,
                                 default = nil)
  if valid_614037 != nil:
    section.add "X-Amz-Credential", valid_614037
  var valid_614038 = header.getOrDefault("X-Amz-Security-Token")
  valid_614038 = validateParameter(valid_614038, JString, required = false,
                                 default = nil)
  if valid_614038 != nil:
    section.add "X-Amz-Security-Token", valid_614038
  var valid_614039 = header.getOrDefault("X-Amz-Algorithm")
  valid_614039 = validateParameter(valid_614039, JString, required = false,
                                 default = nil)
  if valid_614039 != nil:
    section.add "X-Amz-Algorithm", valid_614039
  var valid_614040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614040 = validateParameter(valid_614040, JString, required = false,
                                 default = nil)
  if valid_614040 != nil:
    section.add "X-Amz-SignedHeaders", valid_614040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614041: Call_PostListDomainNames_614029; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_614041.validator(path, query, header, formData, body)
  let scheme = call_614041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614041.url(scheme.get, call_614041.host, call_614041.base,
                         call_614041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614041, url, valid)

proc call*(call_614042: Call_PostListDomainNames_614029;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## postListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614043 = newJObject()
  add(query_614043, "Action", newJString(Action))
  add(query_614043, "Version", newJString(Version))
  result = call_614042.call(nil, query_614043, nil, nil, nil)

var postListDomainNames* = Call_PostListDomainNames_614029(
    name: "postListDomainNames", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_PostListDomainNames_614030, base: "/",
    url: url_PostListDomainNames_614031, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomainNames_614014 = ref object of OpenApiRestCall_612658
proc url_GetListDomainNames_614016(protocol: Scheme; host: string; base: string;
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

proc validate_GetListDomainNames_614015(path: JsonNode; query: JsonNode;
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
  var valid_614017 = query.getOrDefault("Action")
  valid_614017 = validateParameter(valid_614017, JString, required = true,
                                 default = newJString("ListDomainNames"))
  if valid_614017 != nil:
    section.add "Action", valid_614017
  var valid_614018 = query.getOrDefault("Version")
  valid_614018 = validateParameter(valid_614018, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_614018 != nil:
    section.add "Version", valid_614018
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
  var valid_614019 = header.getOrDefault("X-Amz-Signature")
  valid_614019 = validateParameter(valid_614019, JString, required = false,
                                 default = nil)
  if valid_614019 != nil:
    section.add "X-Amz-Signature", valid_614019
  var valid_614020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614020 = validateParameter(valid_614020, JString, required = false,
                                 default = nil)
  if valid_614020 != nil:
    section.add "X-Amz-Content-Sha256", valid_614020
  var valid_614021 = header.getOrDefault("X-Amz-Date")
  valid_614021 = validateParameter(valid_614021, JString, required = false,
                                 default = nil)
  if valid_614021 != nil:
    section.add "X-Amz-Date", valid_614021
  var valid_614022 = header.getOrDefault("X-Amz-Credential")
  valid_614022 = validateParameter(valid_614022, JString, required = false,
                                 default = nil)
  if valid_614022 != nil:
    section.add "X-Amz-Credential", valid_614022
  var valid_614023 = header.getOrDefault("X-Amz-Security-Token")
  valid_614023 = validateParameter(valid_614023, JString, required = false,
                                 default = nil)
  if valid_614023 != nil:
    section.add "X-Amz-Security-Token", valid_614023
  var valid_614024 = header.getOrDefault("X-Amz-Algorithm")
  valid_614024 = validateParameter(valid_614024, JString, required = false,
                                 default = nil)
  if valid_614024 != nil:
    section.add "X-Amz-Algorithm", valid_614024
  var valid_614025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614025 = validateParameter(valid_614025, JString, required = false,
                                 default = nil)
  if valid_614025 != nil:
    section.add "X-Amz-SignedHeaders", valid_614025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614026: Call_GetListDomainNames_614014; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_614026.validator(path, query, header, formData, body)
  let scheme = call_614026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614026.url(scheme.get, call_614026.host, call_614026.base,
                         call_614026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614026, url, valid)

proc call*(call_614027: Call_GetListDomainNames_614014;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## getListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614028 = newJObject()
  add(query_614028, "Action", newJString(Action))
  add(query_614028, "Version", newJString(Version))
  result = call_614027.call(nil, query_614028, nil, nil, nil)

var getListDomainNames* = Call_GetListDomainNames_614014(
    name: "getListDomainNames", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_GetListDomainNames_614015, base: "/",
    url: url_GetListDomainNames_614016, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_614061 = ref object of OpenApiRestCall_612658
proc url_PostUpdateAvailabilityOptions_614063(protocol: Scheme; host: string;
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

proc validate_PostUpdateAvailabilityOptions_614062(path: JsonNode; query: JsonNode;
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
  var valid_614064 = query.getOrDefault("Action")
  valid_614064 = validateParameter(valid_614064, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_614064 != nil:
    section.add "Action", valid_614064
  var valid_614065 = query.getOrDefault("Version")
  valid_614065 = validateParameter(valid_614065, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_614065 != nil:
    section.add "Version", valid_614065
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
  var valid_614066 = header.getOrDefault("X-Amz-Signature")
  valid_614066 = validateParameter(valid_614066, JString, required = false,
                                 default = nil)
  if valid_614066 != nil:
    section.add "X-Amz-Signature", valid_614066
  var valid_614067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614067 = validateParameter(valid_614067, JString, required = false,
                                 default = nil)
  if valid_614067 != nil:
    section.add "X-Amz-Content-Sha256", valid_614067
  var valid_614068 = header.getOrDefault("X-Amz-Date")
  valid_614068 = validateParameter(valid_614068, JString, required = false,
                                 default = nil)
  if valid_614068 != nil:
    section.add "X-Amz-Date", valid_614068
  var valid_614069 = header.getOrDefault("X-Amz-Credential")
  valid_614069 = validateParameter(valid_614069, JString, required = false,
                                 default = nil)
  if valid_614069 != nil:
    section.add "X-Amz-Credential", valid_614069
  var valid_614070 = header.getOrDefault("X-Amz-Security-Token")
  valid_614070 = validateParameter(valid_614070, JString, required = false,
                                 default = nil)
  if valid_614070 != nil:
    section.add "X-Amz-Security-Token", valid_614070
  var valid_614071 = header.getOrDefault("X-Amz-Algorithm")
  valid_614071 = validateParameter(valid_614071, JString, required = false,
                                 default = nil)
  if valid_614071 != nil:
    section.add "X-Amz-Algorithm", valid_614071
  var valid_614072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614072 = validateParameter(valid_614072, JString, required = false,
                                 default = nil)
  if valid_614072 != nil:
    section.add "X-Amz-SignedHeaders", valid_614072
  result.add "header", section
  ## parameters in `formData` object:
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `MultiAZ` field"
  var valid_614073 = formData.getOrDefault("MultiAZ")
  valid_614073 = validateParameter(valid_614073, JBool, required = true, default = nil)
  if valid_614073 != nil:
    section.add "MultiAZ", valid_614073
  var valid_614074 = formData.getOrDefault("DomainName")
  valid_614074 = validateParameter(valid_614074, JString, required = true,
                                 default = nil)
  if valid_614074 != nil:
    section.add "DomainName", valid_614074
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614075: Call_PostUpdateAvailabilityOptions_614061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_614075.validator(path, query, header, formData, body)
  let scheme = call_614075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614075.url(scheme.get, call_614075.host, call_614075.base,
                         call_614075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614075, url, valid)

proc call*(call_614076: Call_PostUpdateAvailabilityOptions_614061; MultiAZ: bool;
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
  var query_614077 = newJObject()
  var formData_614078 = newJObject()
  add(formData_614078, "MultiAZ", newJBool(MultiAZ))
  add(formData_614078, "DomainName", newJString(DomainName))
  add(query_614077, "Action", newJString(Action))
  add(query_614077, "Version", newJString(Version))
  result = call_614076.call(nil, query_614077, nil, formData_614078, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_614061(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_614062, base: "/",
    url: url_PostUpdateAvailabilityOptions_614063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_614044 = ref object of OpenApiRestCall_612658
proc url_GetUpdateAvailabilityOptions_614046(protocol: Scheme; host: string;
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

proc validate_GetUpdateAvailabilityOptions_614045(path: JsonNode; query: JsonNode;
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
  var valid_614047 = query.getOrDefault("DomainName")
  valid_614047 = validateParameter(valid_614047, JString, required = true,
                                 default = nil)
  if valid_614047 != nil:
    section.add "DomainName", valid_614047
  var valid_614048 = query.getOrDefault("Action")
  valid_614048 = validateParameter(valid_614048, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_614048 != nil:
    section.add "Action", valid_614048
  var valid_614049 = query.getOrDefault("MultiAZ")
  valid_614049 = validateParameter(valid_614049, JBool, required = true, default = nil)
  if valid_614049 != nil:
    section.add "MultiAZ", valid_614049
  var valid_614050 = query.getOrDefault("Version")
  valid_614050 = validateParameter(valid_614050, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_614050 != nil:
    section.add "Version", valid_614050
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
  var valid_614051 = header.getOrDefault("X-Amz-Signature")
  valid_614051 = validateParameter(valid_614051, JString, required = false,
                                 default = nil)
  if valid_614051 != nil:
    section.add "X-Amz-Signature", valid_614051
  var valid_614052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614052 = validateParameter(valid_614052, JString, required = false,
                                 default = nil)
  if valid_614052 != nil:
    section.add "X-Amz-Content-Sha256", valid_614052
  var valid_614053 = header.getOrDefault("X-Amz-Date")
  valid_614053 = validateParameter(valid_614053, JString, required = false,
                                 default = nil)
  if valid_614053 != nil:
    section.add "X-Amz-Date", valid_614053
  var valid_614054 = header.getOrDefault("X-Amz-Credential")
  valid_614054 = validateParameter(valid_614054, JString, required = false,
                                 default = nil)
  if valid_614054 != nil:
    section.add "X-Amz-Credential", valid_614054
  var valid_614055 = header.getOrDefault("X-Amz-Security-Token")
  valid_614055 = validateParameter(valid_614055, JString, required = false,
                                 default = nil)
  if valid_614055 != nil:
    section.add "X-Amz-Security-Token", valid_614055
  var valid_614056 = header.getOrDefault("X-Amz-Algorithm")
  valid_614056 = validateParameter(valid_614056, JString, required = false,
                                 default = nil)
  if valid_614056 != nil:
    section.add "X-Amz-Algorithm", valid_614056
  var valid_614057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614057 = validateParameter(valid_614057, JString, required = false,
                                 default = nil)
  if valid_614057 != nil:
    section.add "X-Amz-SignedHeaders", valid_614057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614058: Call_GetUpdateAvailabilityOptions_614044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_614058.validator(path, query, header, formData, body)
  let scheme = call_614058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614058.url(scheme.get, call_614058.host, call_614058.base,
                         call_614058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614058, url, valid)

proc call*(call_614059: Call_GetUpdateAvailabilityOptions_614044;
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
  var query_614060 = newJObject()
  add(query_614060, "DomainName", newJString(DomainName))
  add(query_614060, "Action", newJString(Action))
  add(query_614060, "MultiAZ", newJBool(MultiAZ))
  add(query_614060, "Version", newJString(Version))
  result = call_614059.call(nil, query_614060, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_614044(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_614045, base: "/",
    url: url_GetUpdateAvailabilityOptions_614046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateDomainEndpointOptions_614097 = ref object of OpenApiRestCall_612658
proc url_PostUpdateDomainEndpointOptions_614099(protocol: Scheme; host: string;
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

proc validate_PostUpdateDomainEndpointOptions_614098(path: JsonNode;
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
  var valid_614100 = query.getOrDefault("Action")
  valid_614100 = validateParameter(valid_614100, JString, required = true, default = newJString(
      "UpdateDomainEndpointOptions"))
  if valid_614100 != nil:
    section.add "Action", valid_614100
  var valid_614101 = query.getOrDefault("Version")
  valid_614101 = validateParameter(valid_614101, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_614101 != nil:
    section.add "Version", valid_614101
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
  var valid_614102 = header.getOrDefault("X-Amz-Signature")
  valid_614102 = validateParameter(valid_614102, JString, required = false,
                                 default = nil)
  if valid_614102 != nil:
    section.add "X-Amz-Signature", valid_614102
  var valid_614103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614103 = validateParameter(valid_614103, JString, required = false,
                                 default = nil)
  if valid_614103 != nil:
    section.add "X-Amz-Content-Sha256", valid_614103
  var valid_614104 = header.getOrDefault("X-Amz-Date")
  valid_614104 = validateParameter(valid_614104, JString, required = false,
                                 default = nil)
  if valid_614104 != nil:
    section.add "X-Amz-Date", valid_614104
  var valid_614105 = header.getOrDefault("X-Amz-Credential")
  valid_614105 = validateParameter(valid_614105, JString, required = false,
                                 default = nil)
  if valid_614105 != nil:
    section.add "X-Amz-Credential", valid_614105
  var valid_614106 = header.getOrDefault("X-Amz-Security-Token")
  valid_614106 = validateParameter(valid_614106, JString, required = false,
                                 default = nil)
  if valid_614106 != nil:
    section.add "X-Amz-Security-Token", valid_614106
  var valid_614107 = header.getOrDefault("X-Amz-Algorithm")
  valid_614107 = validateParameter(valid_614107, JString, required = false,
                                 default = nil)
  if valid_614107 != nil:
    section.add "X-Amz-Algorithm", valid_614107
  var valid_614108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614108 = validateParameter(valid_614108, JString, required = false,
                                 default = nil)
  if valid_614108 != nil:
    section.add "X-Amz-SignedHeaders", valid_614108
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
  var valid_614109 = formData.getOrDefault("DomainEndpointOptions.TLSSecurityPolicy")
  valid_614109 = validateParameter(valid_614109, JString, required = false,
                                 default = nil)
  if valid_614109 != nil:
    section.add "DomainEndpointOptions.TLSSecurityPolicy", valid_614109
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_614110 = formData.getOrDefault("DomainName")
  valid_614110 = validateParameter(valid_614110, JString, required = true,
                                 default = nil)
  if valid_614110 != nil:
    section.add "DomainName", valid_614110
  var valid_614111 = formData.getOrDefault("DomainEndpointOptions.EnforceHTTPS")
  valid_614111 = validateParameter(valid_614111, JString, required = false,
                                 default = nil)
  if valid_614111 != nil:
    section.add "DomainEndpointOptions.EnforceHTTPS", valid_614111
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614112: Call_PostUpdateDomainEndpointOptions_614097;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_614112.validator(path, query, header, formData, body)
  let scheme = call_614112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614112.url(scheme.get, call_614112.host, call_614112.base,
                         call_614112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614112, url, valid)

proc call*(call_614113: Call_PostUpdateDomainEndpointOptions_614097;
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
  var query_614114 = newJObject()
  var formData_614115 = newJObject()
  add(formData_614115, "DomainEndpointOptions.TLSSecurityPolicy",
      newJString(DomainEndpointOptionsTLSSecurityPolicy))
  add(formData_614115, "DomainName", newJString(DomainName))
  add(query_614114, "Action", newJString(Action))
  add(formData_614115, "DomainEndpointOptions.EnforceHTTPS",
      newJString(DomainEndpointOptionsEnforceHTTPS))
  add(query_614114, "Version", newJString(Version))
  result = call_614113.call(nil, query_614114, nil, formData_614115, nil)

var postUpdateDomainEndpointOptions* = Call_PostUpdateDomainEndpointOptions_614097(
    name: "postUpdateDomainEndpointOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateDomainEndpointOptions",
    validator: validate_PostUpdateDomainEndpointOptions_614098, base: "/",
    url: url_PostUpdateDomainEndpointOptions_614099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateDomainEndpointOptions_614079 = ref object of OpenApiRestCall_612658
proc url_GetUpdateDomainEndpointOptions_614081(protocol: Scheme; host: string;
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

proc validate_GetUpdateDomainEndpointOptions_614080(path: JsonNode;
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
  var valid_614082 = query.getOrDefault("DomainEndpointOptions.EnforceHTTPS")
  valid_614082 = validateParameter(valid_614082, JString, required = false,
                                 default = nil)
  if valid_614082 != nil:
    section.add "DomainEndpointOptions.EnforceHTTPS", valid_614082
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_614083 = query.getOrDefault("DomainName")
  valid_614083 = validateParameter(valid_614083, JString, required = true,
                                 default = nil)
  if valid_614083 != nil:
    section.add "DomainName", valid_614083
  var valid_614084 = query.getOrDefault("Action")
  valid_614084 = validateParameter(valid_614084, JString, required = true, default = newJString(
      "UpdateDomainEndpointOptions"))
  if valid_614084 != nil:
    section.add "Action", valid_614084
  var valid_614085 = query.getOrDefault("DomainEndpointOptions.TLSSecurityPolicy")
  valid_614085 = validateParameter(valid_614085, JString, required = false,
                                 default = nil)
  if valid_614085 != nil:
    section.add "DomainEndpointOptions.TLSSecurityPolicy", valid_614085
  var valid_614086 = query.getOrDefault("Version")
  valid_614086 = validateParameter(valid_614086, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_614086 != nil:
    section.add "Version", valid_614086
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
  var valid_614087 = header.getOrDefault("X-Amz-Signature")
  valid_614087 = validateParameter(valid_614087, JString, required = false,
                                 default = nil)
  if valid_614087 != nil:
    section.add "X-Amz-Signature", valid_614087
  var valid_614088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614088 = validateParameter(valid_614088, JString, required = false,
                                 default = nil)
  if valid_614088 != nil:
    section.add "X-Amz-Content-Sha256", valid_614088
  var valid_614089 = header.getOrDefault("X-Amz-Date")
  valid_614089 = validateParameter(valid_614089, JString, required = false,
                                 default = nil)
  if valid_614089 != nil:
    section.add "X-Amz-Date", valid_614089
  var valid_614090 = header.getOrDefault("X-Amz-Credential")
  valid_614090 = validateParameter(valid_614090, JString, required = false,
                                 default = nil)
  if valid_614090 != nil:
    section.add "X-Amz-Credential", valid_614090
  var valid_614091 = header.getOrDefault("X-Amz-Security-Token")
  valid_614091 = validateParameter(valid_614091, JString, required = false,
                                 default = nil)
  if valid_614091 != nil:
    section.add "X-Amz-Security-Token", valid_614091
  var valid_614092 = header.getOrDefault("X-Amz-Algorithm")
  valid_614092 = validateParameter(valid_614092, JString, required = false,
                                 default = nil)
  if valid_614092 != nil:
    section.add "X-Amz-Algorithm", valid_614092
  var valid_614093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614093 = validateParameter(valid_614093, JString, required = false,
                                 default = nil)
  if valid_614093 != nil:
    section.add "X-Amz-SignedHeaders", valid_614093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614094: Call_GetUpdateDomainEndpointOptions_614079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_614094.validator(path, query, header, formData, body)
  let scheme = call_614094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614094.url(scheme.get, call_614094.host, call_614094.base,
                         call_614094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614094, url, valid)

proc call*(call_614095: Call_GetUpdateDomainEndpointOptions_614079;
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
  var query_614096 = newJObject()
  add(query_614096, "DomainEndpointOptions.EnforceHTTPS",
      newJString(DomainEndpointOptionsEnforceHTTPS))
  add(query_614096, "DomainName", newJString(DomainName))
  add(query_614096, "Action", newJString(Action))
  add(query_614096, "DomainEndpointOptions.TLSSecurityPolicy",
      newJString(DomainEndpointOptionsTLSSecurityPolicy))
  add(query_614096, "Version", newJString(Version))
  result = call_614095.call(nil, query_614096, nil, nil, nil)

var getUpdateDomainEndpointOptions* = Call_GetUpdateDomainEndpointOptions_614079(
    name: "getUpdateDomainEndpointOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateDomainEndpointOptions",
    validator: validate_GetUpdateDomainEndpointOptions_614080, base: "/",
    url: url_GetUpdateDomainEndpointOptions_614081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateScalingParameters_614135 = ref object of OpenApiRestCall_612658
proc url_PostUpdateScalingParameters_614137(protocol: Scheme; host: string;
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

proc validate_PostUpdateScalingParameters_614136(path: JsonNode; query: JsonNode;
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
  var valid_614138 = query.getOrDefault("Action")
  valid_614138 = validateParameter(valid_614138, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_614138 != nil:
    section.add "Action", valid_614138
  var valid_614139 = query.getOrDefault("Version")
  valid_614139 = validateParameter(valid_614139, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_614139 != nil:
    section.add "Version", valid_614139
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
  var valid_614140 = header.getOrDefault("X-Amz-Signature")
  valid_614140 = validateParameter(valid_614140, JString, required = false,
                                 default = nil)
  if valid_614140 != nil:
    section.add "X-Amz-Signature", valid_614140
  var valid_614141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614141 = validateParameter(valid_614141, JString, required = false,
                                 default = nil)
  if valid_614141 != nil:
    section.add "X-Amz-Content-Sha256", valid_614141
  var valid_614142 = header.getOrDefault("X-Amz-Date")
  valid_614142 = validateParameter(valid_614142, JString, required = false,
                                 default = nil)
  if valid_614142 != nil:
    section.add "X-Amz-Date", valid_614142
  var valid_614143 = header.getOrDefault("X-Amz-Credential")
  valid_614143 = validateParameter(valid_614143, JString, required = false,
                                 default = nil)
  if valid_614143 != nil:
    section.add "X-Amz-Credential", valid_614143
  var valid_614144 = header.getOrDefault("X-Amz-Security-Token")
  valid_614144 = validateParameter(valid_614144, JString, required = false,
                                 default = nil)
  if valid_614144 != nil:
    section.add "X-Amz-Security-Token", valid_614144
  var valid_614145 = header.getOrDefault("X-Amz-Algorithm")
  valid_614145 = validateParameter(valid_614145, JString, required = false,
                                 default = nil)
  if valid_614145 != nil:
    section.add "X-Amz-Algorithm", valid_614145
  var valid_614146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614146 = validateParameter(valid_614146, JString, required = false,
                                 default = nil)
  if valid_614146 != nil:
    section.add "X-Amz-SignedHeaders", valid_614146
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
  var valid_614147 = formData.getOrDefault("ScalingParameters.DesiredReplicationCount")
  valid_614147 = validateParameter(valid_614147, JString, required = false,
                                 default = nil)
  if valid_614147 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_614147
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_614148 = formData.getOrDefault("DomainName")
  valid_614148 = validateParameter(valid_614148, JString, required = true,
                                 default = nil)
  if valid_614148 != nil:
    section.add "DomainName", valid_614148
  var valid_614149 = formData.getOrDefault("ScalingParameters.DesiredPartitionCount")
  valid_614149 = validateParameter(valid_614149, JString, required = false,
                                 default = nil)
  if valid_614149 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_614149
  var valid_614150 = formData.getOrDefault("ScalingParameters.DesiredInstanceType")
  valid_614150 = validateParameter(valid_614150, JString, required = false,
                                 default = nil)
  if valid_614150 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_614150
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614151: Call_PostUpdateScalingParameters_614135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_614151.validator(path, query, header, formData, body)
  let scheme = call_614151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614151.url(scheme.get, call_614151.host, call_614151.base,
                         call_614151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614151, url, valid)

proc call*(call_614152: Call_PostUpdateScalingParameters_614135;
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
  var query_614153 = newJObject()
  var formData_614154 = newJObject()
  add(formData_614154, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  add(formData_614154, "DomainName", newJString(DomainName))
  add(query_614153, "Action", newJString(Action))
  add(formData_614154, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(formData_614154, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  add(query_614153, "Version", newJString(Version))
  result = call_614152.call(nil, query_614153, nil, formData_614154, nil)

var postUpdateScalingParameters* = Call_PostUpdateScalingParameters_614135(
    name: "postUpdateScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_PostUpdateScalingParameters_614136, base: "/",
    url: url_PostUpdateScalingParameters_614137,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateScalingParameters_614116 = ref object of OpenApiRestCall_612658
proc url_GetUpdateScalingParameters_614118(protocol: Scheme; host: string;
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

proc validate_GetUpdateScalingParameters_614117(path: JsonNode; query: JsonNode;
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
  var valid_614119 = query.getOrDefault("ScalingParameters.DesiredPartitionCount")
  valid_614119 = validateParameter(valid_614119, JString, required = false,
                                 default = nil)
  if valid_614119 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_614119
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_614120 = query.getOrDefault("DomainName")
  valid_614120 = validateParameter(valid_614120, JString, required = true,
                                 default = nil)
  if valid_614120 != nil:
    section.add "DomainName", valid_614120
  var valid_614121 = query.getOrDefault("ScalingParameters.DesiredInstanceType")
  valid_614121 = validateParameter(valid_614121, JString, required = false,
                                 default = nil)
  if valid_614121 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_614121
  var valid_614122 = query.getOrDefault("Action")
  valid_614122 = validateParameter(valid_614122, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_614122 != nil:
    section.add "Action", valid_614122
  var valid_614123 = query.getOrDefault("Version")
  valid_614123 = validateParameter(valid_614123, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_614123 != nil:
    section.add "Version", valid_614123
  var valid_614124 = query.getOrDefault("ScalingParameters.DesiredReplicationCount")
  valid_614124 = validateParameter(valid_614124, JString, required = false,
                                 default = nil)
  if valid_614124 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_614124
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
  var valid_614125 = header.getOrDefault("X-Amz-Signature")
  valid_614125 = validateParameter(valid_614125, JString, required = false,
                                 default = nil)
  if valid_614125 != nil:
    section.add "X-Amz-Signature", valid_614125
  var valid_614126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614126 = validateParameter(valid_614126, JString, required = false,
                                 default = nil)
  if valid_614126 != nil:
    section.add "X-Amz-Content-Sha256", valid_614126
  var valid_614127 = header.getOrDefault("X-Amz-Date")
  valid_614127 = validateParameter(valid_614127, JString, required = false,
                                 default = nil)
  if valid_614127 != nil:
    section.add "X-Amz-Date", valid_614127
  var valid_614128 = header.getOrDefault("X-Amz-Credential")
  valid_614128 = validateParameter(valid_614128, JString, required = false,
                                 default = nil)
  if valid_614128 != nil:
    section.add "X-Amz-Credential", valid_614128
  var valid_614129 = header.getOrDefault("X-Amz-Security-Token")
  valid_614129 = validateParameter(valid_614129, JString, required = false,
                                 default = nil)
  if valid_614129 != nil:
    section.add "X-Amz-Security-Token", valid_614129
  var valid_614130 = header.getOrDefault("X-Amz-Algorithm")
  valid_614130 = validateParameter(valid_614130, JString, required = false,
                                 default = nil)
  if valid_614130 != nil:
    section.add "X-Amz-Algorithm", valid_614130
  var valid_614131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614131 = validateParameter(valid_614131, JString, required = false,
                                 default = nil)
  if valid_614131 != nil:
    section.add "X-Amz-SignedHeaders", valid_614131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614132: Call_GetUpdateScalingParameters_614116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_614132.validator(path, query, header, formData, body)
  let scheme = call_614132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614132.url(scheme.get, call_614132.host, call_614132.base,
                         call_614132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614132, url, valid)

proc call*(call_614133: Call_GetUpdateScalingParameters_614116; DomainName: string;
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
  var query_614134 = newJObject()
  add(query_614134, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(query_614134, "DomainName", newJString(DomainName))
  add(query_614134, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  add(query_614134, "Action", newJString(Action))
  add(query_614134, "Version", newJString(Version))
  add(query_614134, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  result = call_614133.call(nil, query_614134, nil, nil, nil)

var getUpdateScalingParameters* = Call_GetUpdateScalingParameters_614116(
    name: "getUpdateScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_GetUpdateScalingParameters_614117, base: "/",
    url: url_GetUpdateScalingParameters_614118,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_614172 = ref object of OpenApiRestCall_612658
proc url_PostUpdateServiceAccessPolicies_614174(protocol: Scheme; host: string;
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

proc validate_PostUpdateServiceAccessPolicies_614173(path: JsonNode;
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
  var valid_614175 = query.getOrDefault("Action")
  valid_614175 = validateParameter(valid_614175, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_614175 != nil:
    section.add "Action", valid_614175
  var valid_614176 = query.getOrDefault("Version")
  valid_614176 = validateParameter(valid_614176, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_614176 != nil:
    section.add "Version", valid_614176
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
  var valid_614177 = header.getOrDefault("X-Amz-Signature")
  valid_614177 = validateParameter(valid_614177, JString, required = false,
                                 default = nil)
  if valid_614177 != nil:
    section.add "X-Amz-Signature", valid_614177
  var valid_614178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614178 = validateParameter(valid_614178, JString, required = false,
                                 default = nil)
  if valid_614178 != nil:
    section.add "X-Amz-Content-Sha256", valid_614178
  var valid_614179 = header.getOrDefault("X-Amz-Date")
  valid_614179 = validateParameter(valid_614179, JString, required = false,
                                 default = nil)
  if valid_614179 != nil:
    section.add "X-Amz-Date", valid_614179
  var valid_614180 = header.getOrDefault("X-Amz-Credential")
  valid_614180 = validateParameter(valid_614180, JString, required = false,
                                 default = nil)
  if valid_614180 != nil:
    section.add "X-Amz-Credential", valid_614180
  var valid_614181 = header.getOrDefault("X-Amz-Security-Token")
  valid_614181 = validateParameter(valid_614181, JString, required = false,
                                 default = nil)
  if valid_614181 != nil:
    section.add "X-Amz-Security-Token", valid_614181
  var valid_614182 = header.getOrDefault("X-Amz-Algorithm")
  valid_614182 = validateParameter(valid_614182, JString, required = false,
                                 default = nil)
  if valid_614182 != nil:
    section.add "X-Amz-Algorithm", valid_614182
  var valid_614183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614183 = validateParameter(valid_614183, JString, required = false,
                                 default = nil)
  if valid_614183 != nil:
    section.add "X-Amz-SignedHeaders", valid_614183
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
  var valid_614184 = formData.getOrDefault("AccessPolicies")
  valid_614184 = validateParameter(valid_614184, JString, required = true,
                                 default = nil)
  if valid_614184 != nil:
    section.add "AccessPolicies", valid_614184
  var valid_614185 = formData.getOrDefault("DomainName")
  valid_614185 = validateParameter(valid_614185, JString, required = true,
                                 default = nil)
  if valid_614185 != nil:
    section.add "DomainName", valid_614185
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614186: Call_PostUpdateServiceAccessPolicies_614172;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_614186.validator(path, query, header, formData, body)
  let scheme = call_614186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614186.url(scheme.get, call_614186.host, call_614186.base,
                         call_614186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614186, url, valid)

proc call*(call_614187: Call_PostUpdateServiceAccessPolicies_614172;
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
  var query_614188 = newJObject()
  var formData_614189 = newJObject()
  add(formData_614189, "AccessPolicies", newJString(AccessPolicies))
  add(formData_614189, "DomainName", newJString(DomainName))
  add(query_614188, "Action", newJString(Action))
  add(query_614188, "Version", newJString(Version))
  result = call_614187.call(nil, query_614188, nil, formData_614189, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_614172(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_614173, base: "/",
    url: url_PostUpdateServiceAccessPolicies_614174,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_614155 = ref object of OpenApiRestCall_612658
proc url_GetUpdateServiceAccessPolicies_614157(protocol: Scheme; host: string;
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

proc validate_GetUpdateServiceAccessPolicies_614156(path: JsonNode;
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
  var valid_614158 = query.getOrDefault("DomainName")
  valid_614158 = validateParameter(valid_614158, JString, required = true,
                                 default = nil)
  if valid_614158 != nil:
    section.add "DomainName", valid_614158
  var valid_614159 = query.getOrDefault("Action")
  valid_614159 = validateParameter(valid_614159, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_614159 != nil:
    section.add "Action", valid_614159
  var valid_614160 = query.getOrDefault("Version")
  valid_614160 = validateParameter(valid_614160, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_614160 != nil:
    section.add "Version", valid_614160
  var valid_614161 = query.getOrDefault("AccessPolicies")
  valid_614161 = validateParameter(valid_614161, JString, required = true,
                                 default = nil)
  if valid_614161 != nil:
    section.add "AccessPolicies", valid_614161
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
  var valid_614162 = header.getOrDefault("X-Amz-Signature")
  valid_614162 = validateParameter(valid_614162, JString, required = false,
                                 default = nil)
  if valid_614162 != nil:
    section.add "X-Amz-Signature", valid_614162
  var valid_614163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614163 = validateParameter(valid_614163, JString, required = false,
                                 default = nil)
  if valid_614163 != nil:
    section.add "X-Amz-Content-Sha256", valid_614163
  var valid_614164 = header.getOrDefault("X-Amz-Date")
  valid_614164 = validateParameter(valid_614164, JString, required = false,
                                 default = nil)
  if valid_614164 != nil:
    section.add "X-Amz-Date", valid_614164
  var valid_614165 = header.getOrDefault("X-Amz-Credential")
  valid_614165 = validateParameter(valid_614165, JString, required = false,
                                 default = nil)
  if valid_614165 != nil:
    section.add "X-Amz-Credential", valid_614165
  var valid_614166 = header.getOrDefault("X-Amz-Security-Token")
  valid_614166 = validateParameter(valid_614166, JString, required = false,
                                 default = nil)
  if valid_614166 != nil:
    section.add "X-Amz-Security-Token", valid_614166
  var valid_614167 = header.getOrDefault("X-Amz-Algorithm")
  valid_614167 = validateParameter(valid_614167, JString, required = false,
                                 default = nil)
  if valid_614167 != nil:
    section.add "X-Amz-Algorithm", valid_614167
  var valid_614168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614168 = validateParameter(valid_614168, JString, required = false,
                                 default = nil)
  if valid_614168 != nil:
    section.add "X-Amz-SignedHeaders", valid_614168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614169: Call_GetUpdateServiceAccessPolicies_614155; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_614169.validator(path, query, header, formData, body)
  let scheme = call_614169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614169.url(scheme.get, call_614169.host, call_614169.base,
                         call_614169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614169, url, valid)

proc call*(call_614170: Call_GetUpdateServiceAccessPolicies_614155;
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
  var query_614171 = newJObject()
  add(query_614171, "DomainName", newJString(DomainName))
  add(query_614171, "Action", newJString(Action))
  add(query_614171, "Version", newJString(Version))
  add(query_614171, "AccessPolicies", newJString(AccessPolicies))
  result = call_614170.call(nil, query_614171, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_614155(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_614156, base: "/",
    url: url_GetUpdateServiceAccessPolicies_614157,
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
