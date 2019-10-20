
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostBuildSuggesters_592974 = ref object of OpenApiRestCall_592364
proc url_PostBuildSuggesters_592976(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostBuildSuggesters_592975(path: JsonNode; query: JsonNode;
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
  var valid_592977 = query.getOrDefault("Action")
  valid_592977 = validateParameter(valid_592977, JString, required = true,
                                 default = newJString("BuildSuggesters"))
  if valid_592977 != nil:
    section.add "Action", valid_592977
  var valid_592978 = query.getOrDefault("Version")
  valid_592978 = validateParameter(valid_592978, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_592978 != nil:
    section.add "Version", valid_592978
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
  var valid_592979 = header.getOrDefault("X-Amz-Signature")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Signature", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Content-Sha256", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Date")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Date", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-Credential")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Credential", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-Security-Token")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Security-Token", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Algorithm")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Algorithm", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-SignedHeaders", valid_592985
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_592986 = formData.getOrDefault("DomainName")
  valid_592986 = validateParameter(valid_592986, JString, required = true,
                                 default = nil)
  if valid_592986 != nil:
    section.add "DomainName", valid_592986
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592987: Call_PostBuildSuggesters_592974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_592987.validator(path, query, header, formData, body)
  let scheme = call_592987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592987.url(scheme.get, call_592987.host, call_592987.base,
                         call_592987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592987, url, valid)

proc call*(call_592988: Call_PostBuildSuggesters_592974; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## postBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_592989 = newJObject()
  var formData_592990 = newJObject()
  add(formData_592990, "DomainName", newJString(DomainName))
  add(query_592989, "Action", newJString(Action))
  add(query_592989, "Version", newJString(Version))
  result = call_592988.call(nil, query_592989, nil, formData_592990, nil)

var postBuildSuggesters* = Call_PostBuildSuggesters_592974(
    name: "postBuildSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_PostBuildSuggesters_592975, base: "/",
    url: url_PostBuildSuggesters_592976, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuildSuggesters_592703 = ref object of OpenApiRestCall_592364
proc url_GetBuildSuggesters_592705(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBuildSuggesters_592704(path: JsonNode; query: JsonNode;
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
  var valid_592817 = query.getOrDefault("DomainName")
  valid_592817 = validateParameter(valid_592817, JString, required = true,
                                 default = nil)
  if valid_592817 != nil:
    section.add "DomainName", valid_592817
  var valid_592831 = query.getOrDefault("Action")
  valid_592831 = validateParameter(valid_592831, JString, required = true,
                                 default = newJString("BuildSuggesters"))
  if valid_592831 != nil:
    section.add "Action", valid_592831
  var valid_592832 = query.getOrDefault("Version")
  valid_592832 = validateParameter(valid_592832, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_592832 != nil:
    section.add "Version", valid_592832
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
  var valid_592833 = header.getOrDefault("X-Amz-Signature")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "X-Amz-Signature", valid_592833
  var valid_592834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Content-Sha256", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Date")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Date", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Credential")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Credential", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Security-Token")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Security-Token", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-Algorithm")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-Algorithm", valid_592838
  var valid_592839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592839 = validateParameter(valid_592839, JString, required = false,
                                 default = nil)
  if valid_592839 != nil:
    section.add "X-Amz-SignedHeaders", valid_592839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592862: Call_GetBuildSuggesters_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_592862.validator(path, query, header, formData, body)
  let scheme = call_592862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592862.url(scheme.get, call_592862.host, call_592862.base,
                         call_592862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592862, url, valid)

proc call*(call_592933: Call_GetBuildSuggesters_592703; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## getBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_592934 = newJObject()
  add(query_592934, "DomainName", newJString(DomainName))
  add(query_592934, "Action", newJString(Action))
  add(query_592934, "Version", newJString(Version))
  result = call_592933.call(nil, query_592934, nil, nil, nil)

var getBuildSuggesters* = Call_GetBuildSuggesters_592703(
    name: "getBuildSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_GetBuildSuggesters_592704, base: "/",
    url: url_GetBuildSuggesters_592705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_593007 = ref object of OpenApiRestCall_592364
proc url_PostCreateDomain_593009(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDomain_593008(path: JsonNode; query: JsonNode;
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
  var valid_593010 = query.getOrDefault("Action")
  valid_593010 = validateParameter(valid_593010, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_593010 != nil:
    section.add "Action", valid_593010
  var valid_593011 = query.getOrDefault("Version")
  valid_593011 = validateParameter(valid_593011, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593011 != nil:
    section.add "Version", valid_593011
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
  var valid_593012 = header.getOrDefault("X-Amz-Signature")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-Signature", valid_593012
  var valid_593013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-Content-Sha256", valid_593013
  var valid_593014 = header.getOrDefault("X-Amz-Date")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "X-Amz-Date", valid_593014
  var valid_593015 = header.getOrDefault("X-Amz-Credential")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-Credential", valid_593015
  var valid_593016 = header.getOrDefault("X-Amz-Security-Token")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-Security-Token", valid_593016
  var valid_593017 = header.getOrDefault("X-Amz-Algorithm")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-Algorithm", valid_593017
  var valid_593018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-SignedHeaders", valid_593018
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593019 = formData.getOrDefault("DomainName")
  valid_593019 = validateParameter(valid_593019, JString, required = true,
                                 default = nil)
  if valid_593019 != nil:
    section.add "DomainName", valid_593019
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593020: Call_PostCreateDomain_593007; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593020.validator(path, query, header, formData, body)
  let scheme = call_593020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593020.url(scheme.get, call_593020.host, call_593020.base,
                         call_593020.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593020, url, valid)

proc call*(call_593021: Call_PostCreateDomain_593007; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593022 = newJObject()
  var formData_593023 = newJObject()
  add(formData_593023, "DomainName", newJString(DomainName))
  add(query_593022, "Action", newJString(Action))
  add(query_593022, "Version", newJString(Version))
  result = call_593021.call(nil, query_593022, nil, formData_593023, nil)

var postCreateDomain* = Call_PostCreateDomain_593007(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_593008,
    base: "/", url: url_PostCreateDomain_593009,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_592991 = ref object of OpenApiRestCall_592364
proc url_GetCreateDomain_592993(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDomain_592992(path: JsonNode; query: JsonNode;
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
  var valid_592994 = query.getOrDefault("DomainName")
  valid_592994 = validateParameter(valid_592994, JString, required = true,
                                 default = nil)
  if valid_592994 != nil:
    section.add "DomainName", valid_592994
  var valid_592995 = query.getOrDefault("Action")
  valid_592995 = validateParameter(valid_592995, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_592995 != nil:
    section.add "Action", valid_592995
  var valid_592996 = query.getOrDefault("Version")
  valid_592996 = validateParameter(valid_592996, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_592996 != nil:
    section.add "Version", valid_592996
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
  var valid_592997 = header.getOrDefault("X-Amz-Signature")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-Signature", valid_592997
  var valid_592998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Content-Sha256", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-Date")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Date", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-Credential")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Credential", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Security-Token")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Security-Token", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-Algorithm")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Algorithm", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-SignedHeaders", valid_593003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593004: Call_GetCreateDomain_592991; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593004.validator(path, query, header, formData, body)
  let scheme = call_593004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593004.url(scheme.get, call_593004.host, call_593004.base,
                         call_593004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593004, url, valid)

proc call*(call_593005: Call_GetCreateDomain_592991; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593006 = newJObject()
  add(query_593006, "DomainName", newJString(DomainName))
  add(query_593006, "Action", newJString(Action))
  add(query_593006, "Version", newJString(Version))
  result = call_593005.call(nil, query_593006, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_592991(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_592992,
    base: "/", url: url_GetCreateDomain_592993, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineAnalysisScheme_593043 = ref object of OpenApiRestCall_592364
proc url_PostDefineAnalysisScheme_593045(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDefineAnalysisScheme_593044(path: JsonNode; query: JsonNode;
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
  var valid_593046 = query.getOrDefault("Action")
  valid_593046 = validateParameter(valid_593046, JString, required = true,
                                 default = newJString("DefineAnalysisScheme"))
  if valid_593046 != nil:
    section.add "Action", valid_593046
  var valid_593047 = query.getOrDefault("Version")
  valid_593047 = validateParameter(valid_593047, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593047 != nil:
    section.add "Version", valid_593047
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
  var valid_593048 = header.getOrDefault("X-Amz-Signature")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "X-Amz-Signature", valid_593048
  var valid_593049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593049 = validateParameter(valid_593049, JString, required = false,
                                 default = nil)
  if valid_593049 != nil:
    section.add "X-Amz-Content-Sha256", valid_593049
  var valid_593050 = header.getOrDefault("X-Amz-Date")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-Date", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Credential")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Credential", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Security-Token")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Security-Token", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Algorithm")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Algorithm", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-SignedHeaders", valid_593054
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
  var valid_593055 = formData.getOrDefault("AnalysisScheme.AnalysisSchemeLanguage")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_593055
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593056 = formData.getOrDefault("DomainName")
  valid_593056 = validateParameter(valid_593056, JString, required = true,
                                 default = nil)
  if valid_593056 != nil:
    section.add "DomainName", valid_593056
  var valid_593057 = formData.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_593057
  var valid_593058 = formData.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_593058
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593059: Call_PostDefineAnalysisScheme_593043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593059.validator(path, query, header, formData, body)
  let scheme = call_593059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593059.url(scheme.get, call_593059.host, call_593059.base,
                         call_593059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593059, url, valid)

proc call*(call_593060: Call_PostDefineAnalysisScheme_593043; DomainName: string;
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
  var query_593061 = newJObject()
  var formData_593062 = newJObject()
  add(formData_593062, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(formData_593062, "DomainName", newJString(DomainName))
  add(formData_593062, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_593061, "Action", newJString(Action))
  add(formData_593062, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  add(query_593061, "Version", newJString(Version))
  result = call_593060.call(nil, query_593061, nil, formData_593062, nil)

var postDefineAnalysisScheme* = Call_PostDefineAnalysisScheme_593043(
    name: "postDefineAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_PostDefineAnalysisScheme_593044, base: "/",
    url: url_PostDefineAnalysisScheme_593045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineAnalysisScheme_593024 = ref object of OpenApiRestCall_592364
proc url_GetDefineAnalysisScheme_593026(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefineAnalysisScheme_593025(path: JsonNode; query: JsonNode;
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
  var valid_593027 = query.getOrDefault("DomainName")
  valid_593027 = validateParameter(valid_593027, JString, required = true,
                                 default = nil)
  if valid_593027 != nil:
    section.add "DomainName", valid_593027
  var valid_593028 = query.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_593028
  var valid_593029 = query.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_593029
  var valid_593030 = query.getOrDefault("Action")
  valid_593030 = validateParameter(valid_593030, JString, required = true,
                                 default = newJString("DefineAnalysisScheme"))
  if valid_593030 != nil:
    section.add "Action", valid_593030
  var valid_593031 = query.getOrDefault("AnalysisScheme.AnalysisSchemeLanguage")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_593031
  var valid_593032 = query.getOrDefault("Version")
  valid_593032 = validateParameter(valid_593032, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593032 != nil:
    section.add "Version", valid_593032
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
  var valid_593033 = header.getOrDefault("X-Amz-Signature")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-Signature", valid_593033
  var valid_593034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "X-Amz-Content-Sha256", valid_593034
  var valid_593035 = header.getOrDefault("X-Amz-Date")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-Date", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Credential")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Credential", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Security-Token")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Security-Token", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Algorithm")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Algorithm", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-SignedHeaders", valid_593039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593040: Call_GetDefineAnalysisScheme_593024; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593040.validator(path, query, header, formData, body)
  let scheme = call_593040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593040.url(scheme.get, call_593040.host, call_593040.base,
                         call_593040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593040, url, valid)

proc call*(call_593041: Call_GetDefineAnalysisScheme_593024; DomainName: string;
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
  var query_593042 = newJObject()
  add(query_593042, "DomainName", newJString(DomainName))
  add(query_593042, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_593042, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  add(query_593042, "Action", newJString(Action))
  add(query_593042, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(query_593042, "Version", newJString(Version))
  result = call_593041.call(nil, query_593042, nil, nil, nil)

var getDefineAnalysisScheme* = Call_GetDefineAnalysisScheme_593024(
    name: "getDefineAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_GetDefineAnalysisScheme_593025, base: "/",
    url: url_GetDefineAnalysisScheme_593026, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineExpression_593081 = ref object of OpenApiRestCall_592364
proc url_PostDefineExpression_593083(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDefineExpression_593082(path: JsonNode; query: JsonNode;
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
  var valid_593084 = query.getOrDefault("Action")
  valid_593084 = validateParameter(valid_593084, JString, required = true,
                                 default = newJString("DefineExpression"))
  if valid_593084 != nil:
    section.add "Action", valid_593084
  var valid_593085 = query.getOrDefault("Version")
  valid_593085 = validateParameter(valid_593085, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593085 != nil:
    section.add "Version", valid_593085
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
  var valid_593086 = header.getOrDefault("X-Amz-Signature")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-Signature", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-Content-Sha256", valid_593087
  var valid_593088 = header.getOrDefault("X-Amz-Date")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "X-Amz-Date", valid_593088
  var valid_593089 = header.getOrDefault("X-Amz-Credential")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "X-Amz-Credential", valid_593089
  var valid_593090 = header.getOrDefault("X-Amz-Security-Token")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-Security-Token", valid_593090
  var valid_593091 = header.getOrDefault("X-Amz-Algorithm")
  valid_593091 = validateParameter(valid_593091, JString, required = false,
                                 default = nil)
  if valid_593091 != nil:
    section.add "X-Amz-Algorithm", valid_593091
  var valid_593092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-SignedHeaders", valid_593092
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
  var valid_593093 = formData.getOrDefault("Expression.ExpressionName")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "Expression.ExpressionName", valid_593093
  var valid_593094 = formData.getOrDefault("Expression.ExpressionValue")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "Expression.ExpressionValue", valid_593094
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593095 = formData.getOrDefault("DomainName")
  valid_593095 = validateParameter(valid_593095, JString, required = true,
                                 default = nil)
  if valid_593095 != nil:
    section.add "DomainName", valid_593095
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593096: Call_PostDefineExpression_593081; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593096.validator(path, query, header, formData, body)
  let scheme = call_593096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593096.url(scheme.get, call_593096.host, call_593096.base,
                         call_593096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593096, url, valid)

proc call*(call_593097: Call_PostDefineExpression_593081; DomainName: string;
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
  var query_593098 = newJObject()
  var formData_593099 = newJObject()
  add(formData_593099, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(formData_593099, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(formData_593099, "DomainName", newJString(DomainName))
  add(query_593098, "Action", newJString(Action))
  add(query_593098, "Version", newJString(Version))
  result = call_593097.call(nil, query_593098, nil, formData_593099, nil)

var postDefineExpression* = Call_PostDefineExpression_593081(
    name: "postDefineExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_PostDefineExpression_593082, base: "/",
    url: url_PostDefineExpression_593083, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineExpression_593063 = ref object of OpenApiRestCall_592364
proc url_GetDefineExpression_593065(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefineExpression_593064(path: JsonNode; query: JsonNode;
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
  var valid_593066 = query.getOrDefault("DomainName")
  valid_593066 = validateParameter(valid_593066, JString, required = true,
                                 default = nil)
  if valid_593066 != nil:
    section.add "DomainName", valid_593066
  var valid_593067 = query.getOrDefault("Expression.ExpressionValue")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "Expression.ExpressionValue", valid_593067
  var valid_593068 = query.getOrDefault("Action")
  valid_593068 = validateParameter(valid_593068, JString, required = true,
                                 default = newJString("DefineExpression"))
  if valid_593068 != nil:
    section.add "Action", valid_593068
  var valid_593069 = query.getOrDefault("Expression.ExpressionName")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "Expression.ExpressionName", valid_593069
  var valid_593070 = query.getOrDefault("Version")
  valid_593070 = validateParameter(valid_593070, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593070 != nil:
    section.add "Version", valid_593070
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
  var valid_593071 = header.getOrDefault("X-Amz-Signature")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Signature", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-Content-Sha256", valid_593072
  var valid_593073 = header.getOrDefault("X-Amz-Date")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-Date", valid_593073
  var valid_593074 = header.getOrDefault("X-Amz-Credential")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-Credential", valid_593074
  var valid_593075 = header.getOrDefault("X-Amz-Security-Token")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Security-Token", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Algorithm")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Algorithm", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-SignedHeaders", valid_593077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593078: Call_GetDefineExpression_593063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593078.validator(path, query, header, formData, body)
  let scheme = call_593078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593078.url(scheme.get, call_593078.host, call_593078.base,
                         call_593078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593078, url, valid)

proc call*(call_593079: Call_GetDefineExpression_593063; DomainName: string;
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
  var query_593080 = newJObject()
  add(query_593080, "DomainName", newJString(DomainName))
  add(query_593080, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(query_593080, "Action", newJString(Action))
  add(query_593080, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(query_593080, "Version", newJString(Version))
  result = call_593079.call(nil, query_593080, nil, nil, nil)

var getDefineExpression* = Call_GetDefineExpression_593063(
    name: "getDefineExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_GetDefineExpression_593064, base: "/",
    url: url_GetDefineExpression_593065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_593129 = ref object of OpenApiRestCall_592364
proc url_PostDefineIndexField_593131(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDefineIndexField_593130(path: JsonNode; query: JsonNode;
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
  var valid_593132 = query.getOrDefault("Action")
  valid_593132 = validateParameter(valid_593132, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_593132 != nil:
    section.add "Action", valid_593132
  var valid_593133 = query.getOrDefault("Version")
  valid_593133 = validateParameter(valid_593133, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593133 != nil:
    section.add "Version", valid_593133
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
  var valid_593134 = header.getOrDefault("X-Amz-Signature")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "X-Amz-Signature", valid_593134
  var valid_593135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-Content-Sha256", valid_593135
  var valid_593136 = header.getOrDefault("X-Amz-Date")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "X-Amz-Date", valid_593136
  var valid_593137 = header.getOrDefault("X-Amz-Credential")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Credential", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-Security-Token")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Security-Token", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-Algorithm")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Algorithm", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-SignedHeaders", valid_593140
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
  var valid_593141 = formData.getOrDefault("IndexField.IntOptions")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "IndexField.IntOptions", valid_593141
  var valid_593142 = formData.getOrDefault("IndexField.TextArrayOptions")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "IndexField.TextArrayOptions", valid_593142
  var valid_593143 = formData.getOrDefault("IndexField.DoubleOptions")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "IndexField.DoubleOptions", valid_593143
  var valid_593144 = formData.getOrDefault("IndexField.LatLonOptions")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "IndexField.LatLonOptions", valid_593144
  var valid_593145 = formData.getOrDefault("IndexField.LiteralArrayOptions")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_593145
  var valid_593146 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "IndexField.IndexFieldType", valid_593146
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593147 = formData.getOrDefault("DomainName")
  valid_593147 = validateParameter(valid_593147, JString, required = true,
                                 default = nil)
  if valid_593147 != nil:
    section.add "DomainName", valid_593147
  var valid_593148 = formData.getOrDefault("IndexField.TextOptions")
  valid_593148 = validateParameter(valid_593148, JString, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "IndexField.TextOptions", valid_593148
  var valid_593149 = formData.getOrDefault("IndexField.IntArrayOptions")
  valid_593149 = validateParameter(valid_593149, JString, required = false,
                                 default = nil)
  if valid_593149 != nil:
    section.add "IndexField.IntArrayOptions", valid_593149
  var valid_593150 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_593150 = validateParameter(valid_593150, JString, required = false,
                                 default = nil)
  if valid_593150 != nil:
    section.add "IndexField.LiteralOptions", valid_593150
  var valid_593151 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_593151 = validateParameter(valid_593151, JString, required = false,
                                 default = nil)
  if valid_593151 != nil:
    section.add "IndexField.IndexFieldName", valid_593151
  var valid_593152 = formData.getOrDefault("IndexField.DateOptions")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "IndexField.DateOptions", valid_593152
  var valid_593153 = formData.getOrDefault("IndexField.DateArrayOptions")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "IndexField.DateArrayOptions", valid_593153
  var valid_593154 = formData.getOrDefault("IndexField.DoubleArrayOptions")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_593154
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593155: Call_PostDefineIndexField_593129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_593155.validator(path, query, header, formData, body)
  let scheme = call_593155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593155.url(scheme.get, call_593155.host, call_593155.base,
                         call_593155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593155, url, valid)

proc call*(call_593156: Call_PostDefineIndexField_593129; DomainName: string;
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
  var query_593157 = newJObject()
  var formData_593158 = newJObject()
  add(formData_593158, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(formData_593158, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(formData_593158, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(formData_593158, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  add(formData_593158, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(formData_593158, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(formData_593158, "DomainName", newJString(DomainName))
  add(formData_593158, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(formData_593158, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  add(formData_593158, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_593157, "Action", newJString(Action))
  add(formData_593158, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(formData_593158, "IndexField.DateOptions", newJString(IndexFieldDateOptions))
  add(formData_593158, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(query_593157, "Version", newJString(Version))
  add(formData_593158, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  result = call_593156.call(nil, query_593157, nil, formData_593158, nil)

var postDefineIndexField* = Call_PostDefineIndexField_593129(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_593130, base: "/",
    url: url_PostDefineIndexField_593131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_593100 = ref object of OpenApiRestCall_592364
proc url_GetDefineIndexField_593102(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefineIndexField_593101(path: JsonNode; query: JsonNode;
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
  var valid_593103 = query.getOrDefault("IndexField.TextOptions")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "IndexField.TextOptions", valid_593103
  var valid_593104 = query.getOrDefault("IndexField.LiteralArrayOptions")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_593104
  var valid_593105 = query.getOrDefault("IndexField.DoubleArrayOptions")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_593105
  var valid_593106 = query.getOrDefault("IndexField.IntArrayOptions")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "IndexField.IntArrayOptions", valid_593106
  var valid_593107 = query.getOrDefault("IndexField.IndexFieldType")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "IndexField.IndexFieldType", valid_593107
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_593108 = query.getOrDefault("DomainName")
  valid_593108 = validateParameter(valid_593108, JString, required = true,
                                 default = nil)
  if valid_593108 != nil:
    section.add "DomainName", valid_593108
  var valid_593109 = query.getOrDefault("IndexField.IndexFieldName")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "IndexField.IndexFieldName", valid_593109
  var valid_593110 = query.getOrDefault("IndexField.DoubleOptions")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "IndexField.DoubleOptions", valid_593110
  var valid_593111 = query.getOrDefault("IndexField.TextArrayOptions")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "IndexField.TextArrayOptions", valid_593111
  var valid_593112 = query.getOrDefault("Action")
  valid_593112 = validateParameter(valid_593112, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_593112 != nil:
    section.add "Action", valid_593112
  var valid_593113 = query.getOrDefault("IndexField.DateOptions")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "IndexField.DateOptions", valid_593113
  var valid_593114 = query.getOrDefault("IndexField.LiteralOptions")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "IndexField.LiteralOptions", valid_593114
  var valid_593115 = query.getOrDefault("IndexField.IntOptions")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "IndexField.IntOptions", valid_593115
  var valid_593116 = query.getOrDefault("Version")
  valid_593116 = validateParameter(valid_593116, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593116 != nil:
    section.add "Version", valid_593116
  var valid_593117 = query.getOrDefault("IndexField.DateArrayOptions")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "IndexField.DateArrayOptions", valid_593117
  var valid_593118 = query.getOrDefault("IndexField.LatLonOptions")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "IndexField.LatLonOptions", valid_593118
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
  var valid_593119 = header.getOrDefault("X-Amz-Signature")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Signature", valid_593119
  var valid_593120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-Content-Sha256", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-Date")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-Date", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Credential")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Credential", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-Security-Token")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-Security-Token", valid_593123
  var valid_593124 = header.getOrDefault("X-Amz-Algorithm")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "X-Amz-Algorithm", valid_593124
  var valid_593125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-SignedHeaders", valid_593125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593126: Call_GetDefineIndexField_593100; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_593126.validator(path, query, header, formData, body)
  let scheme = call_593126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593126.url(scheme.get, call_593126.host, call_593126.base,
                         call_593126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593126, url, valid)

proc call*(call_593127: Call_GetDefineIndexField_593100; DomainName: string;
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
  var query_593128 = newJObject()
  add(query_593128, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_593128, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(query_593128, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  add(query_593128, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  add(query_593128, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_593128, "DomainName", newJString(DomainName))
  add(query_593128, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_593128, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(query_593128, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(query_593128, "Action", newJString(Action))
  add(query_593128, "IndexField.DateOptions", newJString(IndexFieldDateOptions))
  add(query_593128, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_593128, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(query_593128, "Version", newJString(Version))
  add(query_593128, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(query_593128, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  result = call_593127.call(nil, query_593128, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_593100(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_593101, base: "/",
    url: url_GetDefineIndexField_593102, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineSuggester_593177 = ref object of OpenApiRestCall_592364
proc url_PostDefineSuggester_593179(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDefineSuggester_593178(path: JsonNode; query: JsonNode;
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
  var valid_593180 = query.getOrDefault("Action")
  valid_593180 = validateParameter(valid_593180, JString, required = true,
                                 default = newJString("DefineSuggester"))
  if valid_593180 != nil:
    section.add "Action", valid_593180
  var valid_593181 = query.getOrDefault("Version")
  valid_593181 = validateParameter(valid_593181, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593181 != nil:
    section.add "Version", valid_593181
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
  var valid_593182 = header.getOrDefault("X-Amz-Signature")
  valid_593182 = validateParameter(valid_593182, JString, required = false,
                                 default = nil)
  if valid_593182 != nil:
    section.add "X-Amz-Signature", valid_593182
  var valid_593183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593183 = validateParameter(valid_593183, JString, required = false,
                                 default = nil)
  if valid_593183 != nil:
    section.add "X-Amz-Content-Sha256", valid_593183
  var valid_593184 = header.getOrDefault("X-Amz-Date")
  valid_593184 = validateParameter(valid_593184, JString, required = false,
                                 default = nil)
  if valid_593184 != nil:
    section.add "X-Amz-Date", valid_593184
  var valid_593185 = header.getOrDefault("X-Amz-Credential")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "X-Amz-Credential", valid_593185
  var valid_593186 = header.getOrDefault("X-Amz-Security-Token")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Security-Token", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-Algorithm")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Algorithm", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-SignedHeaders", valid_593188
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
  var valid_593189 = formData.getOrDefault("DomainName")
  valid_593189 = validateParameter(valid_593189, JString, required = true,
                                 default = nil)
  if valid_593189 != nil:
    section.add "DomainName", valid_593189
  var valid_593190 = formData.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_593190
  var valid_593191 = formData.getOrDefault("Suggester.SuggesterName")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "Suggester.SuggesterName", valid_593191
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593192: Call_PostDefineSuggester_593177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593192.validator(path, query, header, formData, body)
  let scheme = call_593192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593192.url(scheme.get, call_593192.host, call_593192.base,
                         call_593192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593192, url, valid)

proc call*(call_593193: Call_PostDefineSuggester_593177; DomainName: string;
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
  var query_593194 = newJObject()
  var formData_593195 = newJObject()
  add(formData_593195, "DomainName", newJString(DomainName))
  add(formData_593195, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(query_593194, "Action", newJString(Action))
  add(formData_593195, "Suggester.SuggesterName",
      newJString(SuggesterSuggesterName))
  add(query_593194, "Version", newJString(Version))
  result = call_593193.call(nil, query_593194, nil, formData_593195, nil)

var postDefineSuggester* = Call_PostDefineSuggester_593177(
    name: "postDefineSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_PostDefineSuggester_593178, base: "/",
    url: url_PostDefineSuggester_593179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineSuggester_593159 = ref object of OpenApiRestCall_592364
proc url_GetDefineSuggester_593161(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefineSuggester_593160(path: JsonNode; query: JsonNode;
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
  var valid_593162 = query.getOrDefault("DomainName")
  valid_593162 = validateParameter(valid_593162, JString, required = true,
                                 default = nil)
  if valid_593162 != nil:
    section.add "DomainName", valid_593162
  var valid_593163 = query.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_593163
  var valid_593164 = query.getOrDefault("Action")
  valid_593164 = validateParameter(valid_593164, JString, required = true,
                                 default = newJString("DefineSuggester"))
  if valid_593164 != nil:
    section.add "Action", valid_593164
  var valid_593165 = query.getOrDefault("Suggester.SuggesterName")
  valid_593165 = validateParameter(valid_593165, JString, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "Suggester.SuggesterName", valid_593165
  var valid_593166 = query.getOrDefault("Version")
  valid_593166 = validateParameter(valid_593166, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593166 != nil:
    section.add "Version", valid_593166
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
  var valid_593167 = header.getOrDefault("X-Amz-Signature")
  valid_593167 = validateParameter(valid_593167, JString, required = false,
                                 default = nil)
  if valid_593167 != nil:
    section.add "X-Amz-Signature", valid_593167
  var valid_593168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "X-Amz-Content-Sha256", valid_593168
  var valid_593169 = header.getOrDefault("X-Amz-Date")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "X-Amz-Date", valid_593169
  var valid_593170 = header.getOrDefault("X-Amz-Credential")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "X-Amz-Credential", valid_593170
  var valid_593171 = header.getOrDefault("X-Amz-Security-Token")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-Security-Token", valid_593171
  var valid_593172 = header.getOrDefault("X-Amz-Algorithm")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Algorithm", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-SignedHeaders", valid_593173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593174: Call_GetDefineSuggester_593159; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593174.validator(path, query, header, formData, body)
  let scheme = call_593174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593174.url(scheme.get, call_593174.host, call_593174.base,
                         call_593174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593174, url, valid)

proc call*(call_593175: Call_GetDefineSuggester_593159; DomainName: string;
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
  var query_593176 = newJObject()
  add(query_593176, "DomainName", newJString(DomainName))
  add(query_593176, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(query_593176, "Action", newJString(Action))
  add(query_593176, "Suggester.SuggesterName", newJString(SuggesterSuggesterName))
  add(query_593176, "Version", newJString(Version))
  result = call_593175.call(nil, query_593176, nil, nil, nil)

var getDefineSuggester* = Call_GetDefineSuggester_593159(
    name: "getDefineSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_GetDefineSuggester_593160, base: "/",
    url: url_GetDefineSuggester_593161, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAnalysisScheme_593213 = ref object of OpenApiRestCall_592364
proc url_PostDeleteAnalysisScheme_593215(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteAnalysisScheme_593214(path: JsonNode; query: JsonNode;
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
  var valid_593216 = query.getOrDefault("Action")
  valid_593216 = validateParameter(valid_593216, JString, required = true,
                                 default = newJString("DeleteAnalysisScheme"))
  if valid_593216 != nil:
    section.add "Action", valid_593216
  var valid_593217 = query.getOrDefault("Version")
  valid_593217 = validateParameter(valid_593217, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593217 != nil:
    section.add "Version", valid_593217
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
  var valid_593218 = header.getOrDefault("X-Amz-Signature")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "X-Amz-Signature", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Content-Sha256", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-Date")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Date", valid_593220
  var valid_593221 = header.getOrDefault("X-Amz-Credential")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-Credential", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-Security-Token")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-Security-Token", valid_593222
  var valid_593223 = header.getOrDefault("X-Amz-Algorithm")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-Algorithm", valid_593223
  var valid_593224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "X-Amz-SignedHeaders", valid_593224
  result.add "header", section
  ## parameters in `formData` object:
  ##   AnalysisSchemeName: JString (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AnalysisSchemeName` field"
  var valid_593225 = formData.getOrDefault("AnalysisSchemeName")
  valid_593225 = validateParameter(valid_593225, JString, required = true,
                                 default = nil)
  if valid_593225 != nil:
    section.add "AnalysisSchemeName", valid_593225
  var valid_593226 = formData.getOrDefault("DomainName")
  valid_593226 = validateParameter(valid_593226, JString, required = true,
                                 default = nil)
  if valid_593226 != nil:
    section.add "DomainName", valid_593226
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593227: Call_PostDeleteAnalysisScheme_593213; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_593227.validator(path, query, header, formData, body)
  let scheme = call_593227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593227.url(scheme.get, call_593227.host, call_593227.base,
                         call_593227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593227, url, valid)

proc call*(call_593228: Call_PostDeleteAnalysisScheme_593213;
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
  var query_593229 = newJObject()
  var formData_593230 = newJObject()
  add(formData_593230, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(formData_593230, "DomainName", newJString(DomainName))
  add(query_593229, "Action", newJString(Action))
  add(query_593229, "Version", newJString(Version))
  result = call_593228.call(nil, query_593229, nil, formData_593230, nil)

var postDeleteAnalysisScheme* = Call_PostDeleteAnalysisScheme_593213(
    name: "postDeleteAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_PostDeleteAnalysisScheme_593214, base: "/",
    url: url_PostDeleteAnalysisScheme_593215, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAnalysisScheme_593196 = ref object of OpenApiRestCall_592364
proc url_GetDeleteAnalysisScheme_593198(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteAnalysisScheme_593197(path: JsonNode; query: JsonNode;
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
  var valid_593199 = query.getOrDefault("DomainName")
  valid_593199 = validateParameter(valid_593199, JString, required = true,
                                 default = nil)
  if valid_593199 != nil:
    section.add "DomainName", valid_593199
  var valid_593200 = query.getOrDefault("Action")
  valid_593200 = validateParameter(valid_593200, JString, required = true,
                                 default = newJString("DeleteAnalysisScheme"))
  if valid_593200 != nil:
    section.add "Action", valid_593200
  var valid_593201 = query.getOrDefault("AnalysisSchemeName")
  valid_593201 = validateParameter(valid_593201, JString, required = true,
                                 default = nil)
  if valid_593201 != nil:
    section.add "AnalysisSchemeName", valid_593201
  var valid_593202 = query.getOrDefault("Version")
  valid_593202 = validateParameter(valid_593202, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593202 != nil:
    section.add "Version", valid_593202
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
  var valid_593203 = header.getOrDefault("X-Amz-Signature")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-Signature", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Content-Sha256", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-Date")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Date", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-Credential")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-Credential", valid_593206
  var valid_593207 = header.getOrDefault("X-Amz-Security-Token")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-Security-Token", valid_593207
  var valid_593208 = header.getOrDefault("X-Amz-Algorithm")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = nil)
  if valid_593208 != nil:
    section.add "X-Amz-Algorithm", valid_593208
  var valid_593209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593209 = validateParameter(valid_593209, JString, required = false,
                                 default = nil)
  if valid_593209 != nil:
    section.add "X-Amz-SignedHeaders", valid_593209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593210: Call_GetDeleteAnalysisScheme_593196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_593210.validator(path, query, header, formData, body)
  let scheme = call_593210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593210.url(scheme.get, call_593210.host, call_593210.base,
                         call_593210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593210, url, valid)

proc call*(call_593211: Call_GetDeleteAnalysisScheme_593196; DomainName: string;
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
  var query_593212 = newJObject()
  add(query_593212, "DomainName", newJString(DomainName))
  add(query_593212, "Action", newJString(Action))
  add(query_593212, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(query_593212, "Version", newJString(Version))
  result = call_593211.call(nil, query_593212, nil, nil, nil)

var getDeleteAnalysisScheme* = Call_GetDeleteAnalysisScheme_593196(
    name: "getDeleteAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_GetDeleteAnalysisScheme_593197, base: "/",
    url: url_GetDeleteAnalysisScheme_593198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_593247 = ref object of OpenApiRestCall_592364
proc url_PostDeleteDomain_593249(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDomain_593248(path: JsonNode; query: JsonNode;
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
  var valid_593250 = query.getOrDefault("Action")
  valid_593250 = validateParameter(valid_593250, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_593250 != nil:
    section.add "Action", valid_593250
  var valid_593251 = query.getOrDefault("Version")
  valid_593251 = validateParameter(valid_593251, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593251 != nil:
    section.add "Version", valid_593251
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
  var valid_593252 = header.getOrDefault("X-Amz-Signature")
  valid_593252 = validateParameter(valid_593252, JString, required = false,
                                 default = nil)
  if valid_593252 != nil:
    section.add "X-Amz-Signature", valid_593252
  var valid_593253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593253 = validateParameter(valid_593253, JString, required = false,
                                 default = nil)
  if valid_593253 != nil:
    section.add "X-Amz-Content-Sha256", valid_593253
  var valid_593254 = header.getOrDefault("X-Amz-Date")
  valid_593254 = validateParameter(valid_593254, JString, required = false,
                                 default = nil)
  if valid_593254 != nil:
    section.add "X-Amz-Date", valid_593254
  var valid_593255 = header.getOrDefault("X-Amz-Credential")
  valid_593255 = validateParameter(valid_593255, JString, required = false,
                                 default = nil)
  if valid_593255 != nil:
    section.add "X-Amz-Credential", valid_593255
  var valid_593256 = header.getOrDefault("X-Amz-Security-Token")
  valid_593256 = validateParameter(valid_593256, JString, required = false,
                                 default = nil)
  if valid_593256 != nil:
    section.add "X-Amz-Security-Token", valid_593256
  var valid_593257 = header.getOrDefault("X-Amz-Algorithm")
  valid_593257 = validateParameter(valid_593257, JString, required = false,
                                 default = nil)
  if valid_593257 != nil:
    section.add "X-Amz-Algorithm", valid_593257
  var valid_593258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593258 = validateParameter(valid_593258, JString, required = false,
                                 default = nil)
  if valid_593258 != nil:
    section.add "X-Amz-SignedHeaders", valid_593258
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593259 = formData.getOrDefault("DomainName")
  valid_593259 = validateParameter(valid_593259, JString, required = true,
                                 default = nil)
  if valid_593259 != nil:
    section.add "DomainName", valid_593259
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593260: Call_PostDeleteDomain_593247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_593260.validator(path, query, header, formData, body)
  let scheme = call_593260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593260.url(scheme.get, call_593260.host, call_593260.base,
                         call_593260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593260, url, valid)

proc call*(call_593261: Call_PostDeleteDomain_593247; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593262 = newJObject()
  var formData_593263 = newJObject()
  add(formData_593263, "DomainName", newJString(DomainName))
  add(query_593262, "Action", newJString(Action))
  add(query_593262, "Version", newJString(Version))
  result = call_593261.call(nil, query_593262, nil, formData_593263, nil)

var postDeleteDomain* = Call_PostDeleteDomain_593247(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_593248,
    base: "/", url: url_PostDeleteDomain_593249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_593231 = ref object of OpenApiRestCall_592364
proc url_GetDeleteDomain_593233(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDomain_593232(path: JsonNode; query: JsonNode;
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
  var valid_593234 = query.getOrDefault("DomainName")
  valid_593234 = validateParameter(valid_593234, JString, required = true,
                                 default = nil)
  if valid_593234 != nil:
    section.add "DomainName", valid_593234
  var valid_593235 = query.getOrDefault("Action")
  valid_593235 = validateParameter(valid_593235, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_593235 != nil:
    section.add "Action", valid_593235
  var valid_593236 = query.getOrDefault("Version")
  valid_593236 = validateParameter(valid_593236, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593236 != nil:
    section.add "Version", valid_593236
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
  var valid_593237 = header.getOrDefault("X-Amz-Signature")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-Signature", valid_593237
  var valid_593238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "X-Amz-Content-Sha256", valid_593238
  var valid_593239 = header.getOrDefault("X-Amz-Date")
  valid_593239 = validateParameter(valid_593239, JString, required = false,
                                 default = nil)
  if valid_593239 != nil:
    section.add "X-Amz-Date", valid_593239
  var valid_593240 = header.getOrDefault("X-Amz-Credential")
  valid_593240 = validateParameter(valid_593240, JString, required = false,
                                 default = nil)
  if valid_593240 != nil:
    section.add "X-Amz-Credential", valid_593240
  var valid_593241 = header.getOrDefault("X-Amz-Security-Token")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "X-Amz-Security-Token", valid_593241
  var valid_593242 = header.getOrDefault("X-Amz-Algorithm")
  valid_593242 = validateParameter(valid_593242, JString, required = false,
                                 default = nil)
  if valid_593242 != nil:
    section.add "X-Amz-Algorithm", valid_593242
  var valid_593243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "X-Amz-SignedHeaders", valid_593243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593244: Call_GetDeleteDomain_593231; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_593244.validator(path, query, header, formData, body)
  let scheme = call_593244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593244.url(scheme.get, call_593244.host, call_593244.base,
                         call_593244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593244, url, valid)

proc call*(call_593245: Call_GetDeleteDomain_593231; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593246 = newJObject()
  add(query_593246, "DomainName", newJString(DomainName))
  add(query_593246, "Action", newJString(Action))
  add(query_593246, "Version", newJString(Version))
  result = call_593245.call(nil, query_593246, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_593231(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_593232,
    base: "/", url: url_GetDeleteDomain_593233, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteExpression_593281 = ref object of OpenApiRestCall_592364
proc url_PostDeleteExpression_593283(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteExpression_593282(path: JsonNode; query: JsonNode;
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
  var valid_593284 = query.getOrDefault("Action")
  valid_593284 = validateParameter(valid_593284, JString, required = true,
                                 default = newJString("DeleteExpression"))
  if valid_593284 != nil:
    section.add "Action", valid_593284
  var valid_593285 = query.getOrDefault("Version")
  valid_593285 = validateParameter(valid_593285, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593285 != nil:
    section.add "Version", valid_593285
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
  var valid_593286 = header.getOrDefault("X-Amz-Signature")
  valid_593286 = validateParameter(valid_593286, JString, required = false,
                                 default = nil)
  if valid_593286 != nil:
    section.add "X-Amz-Signature", valid_593286
  var valid_593287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593287 = validateParameter(valid_593287, JString, required = false,
                                 default = nil)
  if valid_593287 != nil:
    section.add "X-Amz-Content-Sha256", valid_593287
  var valid_593288 = header.getOrDefault("X-Amz-Date")
  valid_593288 = validateParameter(valid_593288, JString, required = false,
                                 default = nil)
  if valid_593288 != nil:
    section.add "X-Amz-Date", valid_593288
  var valid_593289 = header.getOrDefault("X-Amz-Credential")
  valid_593289 = validateParameter(valid_593289, JString, required = false,
                                 default = nil)
  if valid_593289 != nil:
    section.add "X-Amz-Credential", valid_593289
  var valid_593290 = header.getOrDefault("X-Amz-Security-Token")
  valid_593290 = validateParameter(valid_593290, JString, required = false,
                                 default = nil)
  if valid_593290 != nil:
    section.add "X-Amz-Security-Token", valid_593290
  var valid_593291 = header.getOrDefault("X-Amz-Algorithm")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-Algorithm", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-SignedHeaders", valid_593292
  result.add "header", section
  ## parameters in `formData` object:
  ##   ExpressionName: JString (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ExpressionName` field"
  var valid_593293 = formData.getOrDefault("ExpressionName")
  valid_593293 = validateParameter(valid_593293, JString, required = true,
                                 default = nil)
  if valid_593293 != nil:
    section.add "ExpressionName", valid_593293
  var valid_593294 = formData.getOrDefault("DomainName")
  valid_593294 = validateParameter(valid_593294, JString, required = true,
                                 default = nil)
  if valid_593294 != nil:
    section.add "DomainName", valid_593294
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593295: Call_PostDeleteExpression_593281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593295.validator(path, query, header, formData, body)
  let scheme = call_593295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593295.url(scheme.get, call_593295.host, call_593295.base,
                         call_593295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593295, url, valid)

proc call*(call_593296: Call_PostDeleteExpression_593281; ExpressionName: string;
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
  var query_593297 = newJObject()
  var formData_593298 = newJObject()
  add(formData_593298, "ExpressionName", newJString(ExpressionName))
  add(formData_593298, "DomainName", newJString(DomainName))
  add(query_593297, "Action", newJString(Action))
  add(query_593297, "Version", newJString(Version))
  result = call_593296.call(nil, query_593297, nil, formData_593298, nil)

var postDeleteExpression* = Call_PostDeleteExpression_593281(
    name: "postDeleteExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_PostDeleteExpression_593282, base: "/",
    url: url_PostDeleteExpression_593283, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteExpression_593264 = ref object of OpenApiRestCall_592364
proc url_GetDeleteExpression_593266(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteExpression_593265(path: JsonNode; query: JsonNode;
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
  var valid_593267 = query.getOrDefault("ExpressionName")
  valid_593267 = validateParameter(valid_593267, JString, required = true,
                                 default = nil)
  if valid_593267 != nil:
    section.add "ExpressionName", valid_593267
  var valid_593268 = query.getOrDefault("DomainName")
  valid_593268 = validateParameter(valid_593268, JString, required = true,
                                 default = nil)
  if valid_593268 != nil:
    section.add "DomainName", valid_593268
  var valid_593269 = query.getOrDefault("Action")
  valid_593269 = validateParameter(valid_593269, JString, required = true,
                                 default = newJString("DeleteExpression"))
  if valid_593269 != nil:
    section.add "Action", valid_593269
  var valid_593270 = query.getOrDefault("Version")
  valid_593270 = validateParameter(valid_593270, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593270 != nil:
    section.add "Version", valid_593270
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
  var valid_593271 = header.getOrDefault("X-Amz-Signature")
  valid_593271 = validateParameter(valid_593271, JString, required = false,
                                 default = nil)
  if valid_593271 != nil:
    section.add "X-Amz-Signature", valid_593271
  var valid_593272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593272 = validateParameter(valid_593272, JString, required = false,
                                 default = nil)
  if valid_593272 != nil:
    section.add "X-Amz-Content-Sha256", valid_593272
  var valid_593273 = header.getOrDefault("X-Amz-Date")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amz-Date", valid_593273
  var valid_593274 = header.getOrDefault("X-Amz-Credential")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-Credential", valid_593274
  var valid_593275 = header.getOrDefault("X-Amz-Security-Token")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-Security-Token", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-Algorithm")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Algorithm", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-SignedHeaders", valid_593277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593278: Call_GetDeleteExpression_593264; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593278.validator(path, query, header, formData, body)
  let scheme = call_593278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593278.url(scheme.get, call_593278.host, call_593278.base,
                         call_593278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593278, url, valid)

proc call*(call_593279: Call_GetDeleteExpression_593264; ExpressionName: string;
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
  var query_593280 = newJObject()
  add(query_593280, "ExpressionName", newJString(ExpressionName))
  add(query_593280, "DomainName", newJString(DomainName))
  add(query_593280, "Action", newJString(Action))
  add(query_593280, "Version", newJString(Version))
  result = call_593279.call(nil, query_593280, nil, nil, nil)

var getDeleteExpression* = Call_GetDeleteExpression_593264(
    name: "getDeleteExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_GetDeleteExpression_593265, base: "/",
    url: url_GetDeleteExpression_593266, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_593316 = ref object of OpenApiRestCall_592364
proc url_PostDeleteIndexField_593318(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteIndexField_593317(path: JsonNode; query: JsonNode;
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
  var valid_593319 = query.getOrDefault("Action")
  valid_593319 = validateParameter(valid_593319, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_593319 != nil:
    section.add "Action", valid_593319
  var valid_593320 = query.getOrDefault("Version")
  valid_593320 = validateParameter(valid_593320, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593320 != nil:
    section.add "Version", valid_593320
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
  var valid_593321 = header.getOrDefault("X-Amz-Signature")
  valid_593321 = validateParameter(valid_593321, JString, required = false,
                                 default = nil)
  if valid_593321 != nil:
    section.add "X-Amz-Signature", valid_593321
  var valid_593322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593322 = validateParameter(valid_593322, JString, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "X-Amz-Content-Sha256", valid_593322
  var valid_593323 = header.getOrDefault("X-Amz-Date")
  valid_593323 = validateParameter(valid_593323, JString, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "X-Amz-Date", valid_593323
  var valid_593324 = header.getOrDefault("X-Amz-Credential")
  valid_593324 = validateParameter(valid_593324, JString, required = false,
                                 default = nil)
  if valid_593324 != nil:
    section.add "X-Amz-Credential", valid_593324
  var valid_593325 = header.getOrDefault("X-Amz-Security-Token")
  valid_593325 = validateParameter(valid_593325, JString, required = false,
                                 default = nil)
  if valid_593325 != nil:
    section.add "X-Amz-Security-Token", valid_593325
  var valid_593326 = header.getOrDefault("X-Amz-Algorithm")
  valid_593326 = validateParameter(valid_593326, JString, required = false,
                                 default = nil)
  if valid_593326 != nil:
    section.add "X-Amz-Algorithm", valid_593326
  var valid_593327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593327 = validateParameter(valid_593327, JString, required = false,
                                 default = nil)
  if valid_593327 != nil:
    section.add "X-Amz-SignedHeaders", valid_593327
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldName: JString (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593328 = formData.getOrDefault("DomainName")
  valid_593328 = validateParameter(valid_593328, JString, required = true,
                                 default = nil)
  if valid_593328 != nil:
    section.add "DomainName", valid_593328
  var valid_593329 = formData.getOrDefault("IndexFieldName")
  valid_593329 = validateParameter(valid_593329, JString, required = true,
                                 default = nil)
  if valid_593329 != nil:
    section.add "IndexFieldName", valid_593329
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593330: Call_PostDeleteIndexField_593316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593330.validator(path, query, header, formData, body)
  let scheme = call_593330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593330.url(scheme.get, call_593330.host, call_593330.base,
                         call_593330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593330, url, valid)

proc call*(call_593331: Call_PostDeleteIndexField_593316; DomainName: string;
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
  var query_593332 = newJObject()
  var formData_593333 = newJObject()
  add(formData_593333, "DomainName", newJString(DomainName))
  add(formData_593333, "IndexFieldName", newJString(IndexFieldName))
  add(query_593332, "Action", newJString(Action))
  add(query_593332, "Version", newJString(Version))
  result = call_593331.call(nil, query_593332, nil, formData_593333, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_593316(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_593317, base: "/",
    url: url_PostDeleteIndexField_593318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_593299 = ref object of OpenApiRestCall_592364
proc url_GetDeleteIndexField_593301(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteIndexField_593300(path: JsonNode; query: JsonNode;
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
  var valid_593302 = query.getOrDefault("DomainName")
  valid_593302 = validateParameter(valid_593302, JString, required = true,
                                 default = nil)
  if valid_593302 != nil:
    section.add "DomainName", valid_593302
  var valid_593303 = query.getOrDefault("Action")
  valid_593303 = validateParameter(valid_593303, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_593303 != nil:
    section.add "Action", valid_593303
  var valid_593304 = query.getOrDefault("IndexFieldName")
  valid_593304 = validateParameter(valid_593304, JString, required = true,
                                 default = nil)
  if valid_593304 != nil:
    section.add "IndexFieldName", valid_593304
  var valid_593305 = query.getOrDefault("Version")
  valid_593305 = validateParameter(valid_593305, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593305 != nil:
    section.add "Version", valid_593305
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
  var valid_593306 = header.getOrDefault("X-Amz-Signature")
  valid_593306 = validateParameter(valid_593306, JString, required = false,
                                 default = nil)
  if valid_593306 != nil:
    section.add "X-Amz-Signature", valid_593306
  var valid_593307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "X-Amz-Content-Sha256", valid_593307
  var valid_593308 = header.getOrDefault("X-Amz-Date")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-Date", valid_593308
  var valid_593309 = header.getOrDefault("X-Amz-Credential")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-Credential", valid_593309
  var valid_593310 = header.getOrDefault("X-Amz-Security-Token")
  valid_593310 = validateParameter(valid_593310, JString, required = false,
                                 default = nil)
  if valid_593310 != nil:
    section.add "X-Amz-Security-Token", valid_593310
  var valid_593311 = header.getOrDefault("X-Amz-Algorithm")
  valid_593311 = validateParameter(valid_593311, JString, required = false,
                                 default = nil)
  if valid_593311 != nil:
    section.add "X-Amz-Algorithm", valid_593311
  var valid_593312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593312 = validateParameter(valid_593312, JString, required = false,
                                 default = nil)
  if valid_593312 != nil:
    section.add "X-Amz-SignedHeaders", valid_593312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593313: Call_GetDeleteIndexField_593299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593313.validator(path, query, header, formData, body)
  let scheme = call_593313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593313.url(scheme.get, call_593313.host, call_593313.base,
                         call_593313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593313, url, valid)

proc call*(call_593314: Call_GetDeleteIndexField_593299; DomainName: string;
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
  var query_593315 = newJObject()
  add(query_593315, "DomainName", newJString(DomainName))
  add(query_593315, "Action", newJString(Action))
  add(query_593315, "IndexFieldName", newJString(IndexFieldName))
  add(query_593315, "Version", newJString(Version))
  result = call_593314.call(nil, query_593315, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_593299(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_593300, base: "/",
    url: url_GetDeleteIndexField_593301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteSuggester_593351 = ref object of OpenApiRestCall_592364
proc url_PostDeleteSuggester_593353(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteSuggester_593352(path: JsonNode; query: JsonNode;
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
  var valid_593354 = query.getOrDefault("Action")
  valid_593354 = validateParameter(valid_593354, JString, required = true,
                                 default = newJString("DeleteSuggester"))
  if valid_593354 != nil:
    section.add "Action", valid_593354
  var valid_593355 = query.getOrDefault("Version")
  valid_593355 = validateParameter(valid_593355, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593355 != nil:
    section.add "Version", valid_593355
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
  var valid_593356 = header.getOrDefault("X-Amz-Signature")
  valid_593356 = validateParameter(valid_593356, JString, required = false,
                                 default = nil)
  if valid_593356 != nil:
    section.add "X-Amz-Signature", valid_593356
  var valid_593357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593357 = validateParameter(valid_593357, JString, required = false,
                                 default = nil)
  if valid_593357 != nil:
    section.add "X-Amz-Content-Sha256", valid_593357
  var valid_593358 = header.getOrDefault("X-Amz-Date")
  valid_593358 = validateParameter(valid_593358, JString, required = false,
                                 default = nil)
  if valid_593358 != nil:
    section.add "X-Amz-Date", valid_593358
  var valid_593359 = header.getOrDefault("X-Amz-Credential")
  valid_593359 = validateParameter(valid_593359, JString, required = false,
                                 default = nil)
  if valid_593359 != nil:
    section.add "X-Amz-Credential", valid_593359
  var valid_593360 = header.getOrDefault("X-Amz-Security-Token")
  valid_593360 = validateParameter(valid_593360, JString, required = false,
                                 default = nil)
  if valid_593360 != nil:
    section.add "X-Amz-Security-Token", valid_593360
  var valid_593361 = header.getOrDefault("X-Amz-Algorithm")
  valid_593361 = validateParameter(valid_593361, JString, required = false,
                                 default = nil)
  if valid_593361 != nil:
    section.add "X-Amz-Algorithm", valid_593361
  var valid_593362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593362 = validateParameter(valid_593362, JString, required = false,
                                 default = nil)
  if valid_593362 != nil:
    section.add "X-Amz-SignedHeaders", valid_593362
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   SuggesterName: JString (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593363 = formData.getOrDefault("DomainName")
  valid_593363 = validateParameter(valid_593363, JString, required = true,
                                 default = nil)
  if valid_593363 != nil:
    section.add "DomainName", valid_593363
  var valid_593364 = formData.getOrDefault("SuggesterName")
  valid_593364 = validateParameter(valid_593364, JString, required = true,
                                 default = nil)
  if valid_593364 != nil:
    section.add "SuggesterName", valid_593364
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593365: Call_PostDeleteSuggester_593351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593365.validator(path, query, header, formData, body)
  let scheme = call_593365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593365.url(scheme.get, call_593365.host, call_593365.base,
                         call_593365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593365, url, valid)

proc call*(call_593366: Call_PostDeleteSuggester_593351; DomainName: string;
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
  var query_593367 = newJObject()
  var formData_593368 = newJObject()
  add(formData_593368, "DomainName", newJString(DomainName))
  add(formData_593368, "SuggesterName", newJString(SuggesterName))
  add(query_593367, "Action", newJString(Action))
  add(query_593367, "Version", newJString(Version))
  result = call_593366.call(nil, query_593367, nil, formData_593368, nil)

var postDeleteSuggester* = Call_PostDeleteSuggester_593351(
    name: "postDeleteSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_PostDeleteSuggester_593352, base: "/",
    url: url_PostDeleteSuggester_593353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteSuggester_593334 = ref object of OpenApiRestCall_592364
proc url_GetDeleteSuggester_593336(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteSuggester_593335(path: JsonNode; query: JsonNode;
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
  var valid_593337 = query.getOrDefault("DomainName")
  valid_593337 = validateParameter(valid_593337, JString, required = true,
                                 default = nil)
  if valid_593337 != nil:
    section.add "DomainName", valid_593337
  var valid_593338 = query.getOrDefault("Action")
  valid_593338 = validateParameter(valid_593338, JString, required = true,
                                 default = newJString("DeleteSuggester"))
  if valid_593338 != nil:
    section.add "Action", valid_593338
  var valid_593339 = query.getOrDefault("Version")
  valid_593339 = validateParameter(valid_593339, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593339 != nil:
    section.add "Version", valid_593339
  var valid_593340 = query.getOrDefault("SuggesterName")
  valid_593340 = validateParameter(valid_593340, JString, required = true,
                                 default = nil)
  if valid_593340 != nil:
    section.add "SuggesterName", valid_593340
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
  var valid_593341 = header.getOrDefault("X-Amz-Signature")
  valid_593341 = validateParameter(valid_593341, JString, required = false,
                                 default = nil)
  if valid_593341 != nil:
    section.add "X-Amz-Signature", valid_593341
  var valid_593342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593342 = validateParameter(valid_593342, JString, required = false,
                                 default = nil)
  if valid_593342 != nil:
    section.add "X-Amz-Content-Sha256", valid_593342
  var valid_593343 = header.getOrDefault("X-Amz-Date")
  valid_593343 = validateParameter(valid_593343, JString, required = false,
                                 default = nil)
  if valid_593343 != nil:
    section.add "X-Amz-Date", valid_593343
  var valid_593344 = header.getOrDefault("X-Amz-Credential")
  valid_593344 = validateParameter(valid_593344, JString, required = false,
                                 default = nil)
  if valid_593344 != nil:
    section.add "X-Amz-Credential", valid_593344
  var valid_593345 = header.getOrDefault("X-Amz-Security-Token")
  valid_593345 = validateParameter(valid_593345, JString, required = false,
                                 default = nil)
  if valid_593345 != nil:
    section.add "X-Amz-Security-Token", valid_593345
  var valid_593346 = header.getOrDefault("X-Amz-Algorithm")
  valid_593346 = validateParameter(valid_593346, JString, required = false,
                                 default = nil)
  if valid_593346 != nil:
    section.add "X-Amz-Algorithm", valid_593346
  var valid_593347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593347 = validateParameter(valid_593347, JString, required = false,
                                 default = nil)
  if valid_593347 != nil:
    section.add "X-Amz-SignedHeaders", valid_593347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593348: Call_GetDeleteSuggester_593334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593348.validator(path, query, header, formData, body)
  let scheme = call_593348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593348.url(scheme.get, call_593348.host, call_593348.base,
                         call_593348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593348, url, valid)

proc call*(call_593349: Call_GetDeleteSuggester_593334; DomainName: string;
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
  var query_593350 = newJObject()
  add(query_593350, "DomainName", newJString(DomainName))
  add(query_593350, "Action", newJString(Action))
  add(query_593350, "Version", newJString(Version))
  add(query_593350, "SuggesterName", newJString(SuggesterName))
  result = call_593349.call(nil, query_593350, nil, nil, nil)

var getDeleteSuggester* = Call_GetDeleteSuggester_593334(
    name: "getDeleteSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_GetDeleteSuggester_593335, base: "/",
    url: url_GetDeleteSuggester_593336, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAnalysisSchemes_593387 = ref object of OpenApiRestCall_592364
proc url_PostDescribeAnalysisSchemes_593389(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAnalysisSchemes_593388(path: JsonNode; query: JsonNode;
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
  var valid_593390 = query.getOrDefault("Action")
  valid_593390 = validateParameter(valid_593390, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_593390 != nil:
    section.add "Action", valid_593390
  var valid_593391 = query.getOrDefault("Version")
  valid_593391 = validateParameter(valid_593391, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593391 != nil:
    section.add "Version", valid_593391
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
  var valid_593392 = header.getOrDefault("X-Amz-Signature")
  valid_593392 = validateParameter(valid_593392, JString, required = false,
                                 default = nil)
  if valid_593392 != nil:
    section.add "X-Amz-Signature", valid_593392
  var valid_593393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593393 = validateParameter(valid_593393, JString, required = false,
                                 default = nil)
  if valid_593393 != nil:
    section.add "X-Amz-Content-Sha256", valid_593393
  var valid_593394 = header.getOrDefault("X-Amz-Date")
  valid_593394 = validateParameter(valid_593394, JString, required = false,
                                 default = nil)
  if valid_593394 != nil:
    section.add "X-Amz-Date", valid_593394
  var valid_593395 = header.getOrDefault("X-Amz-Credential")
  valid_593395 = validateParameter(valid_593395, JString, required = false,
                                 default = nil)
  if valid_593395 != nil:
    section.add "X-Amz-Credential", valid_593395
  var valid_593396 = header.getOrDefault("X-Amz-Security-Token")
  valid_593396 = validateParameter(valid_593396, JString, required = false,
                                 default = nil)
  if valid_593396 != nil:
    section.add "X-Amz-Security-Token", valid_593396
  var valid_593397 = header.getOrDefault("X-Amz-Algorithm")
  valid_593397 = validateParameter(valid_593397, JString, required = false,
                                 default = nil)
  if valid_593397 != nil:
    section.add "X-Amz-Algorithm", valid_593397
  var valid_593398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593398 = validateParameter(valid_593398, JString, required = false,
                                 default = nil)
  if valid_593398 != nil:
    section.add "X-Amz-SignedHeaders", valid_593398
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  section = newJObject()
  var valid_593399 = formData.getOrDefault("Deployed")
  valid_593399 = validateParameter(valid_593399, JBool, required = false, default = nil)
  if valid_593399 != nil:
    section.add "Deployed", valid_593399
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593400 = formData.getOrDefault("DomainName")
  valid_593400 = validateParameter(valid_593400, JString, required = true,
                                 default = nil)
  if valid_593400 != nil:
    section.add "DomainName", valid_593400
  var valid_593401 = formData.getOrDefault("AnalysisSchemeNames")
  valid_593401 = validateParameter(valid_593401, JArray, required = false,
                                 default = nil)
  if valid_593401 != nil:
    section.add "AnalysisSchemeNames", valid_593401
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593402: Call_PostDescribeAnalysisSchemes_593387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593402.validator(path, query, header, formData, body)
  let scheme = call_593402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593402.url(scheme.get, call_593402.host, call_593402.base,
                         call_593402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593402, url, valid)

proc call*(call_593403: Call_PostDescribeAnalysisSchemes_593387;
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
  var query_593404 = newJObject()
  var formData_593405 = newJObject()
  add(formData_593405, "Deployed", newJBool(Deployed))
  add(formData_593405, "DomainName", newJString(DomainName))
  if AnalysisSchemeNames != nil:
    formData_593405.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_593404, "Action", newJString(Action))
  add(query_593404, "Version", newJString(Version))
  result = call_593403.call(nil, query_593404, nil, formData_593405, nil)

var postDescribeAnalysisSchemes* = Call_PostDescribeAnalysisSchemes_593387(
    name: "postDescribeAnalysisSchemes", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_PostDescribeAnalysisSchemes_593388, base: "/",
    url: url_PostDescribeAnalysisSchemes_593389,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAnalysisSchemes_593369 = ref object of OpenApiRestCall_592364
proc url_GetDescribeAnalysisSchemes_593371(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAnalysisSchemes_593370(path: JsonNode; query: JsonNode;
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
  var valid_593372 = query.getOrDefault("DomainName")
  valid_593372 = validateParameter(valid_593372, JString, required = true,
                                 default = nil)
  if valid_593372 != nil:
    section.add "DomainName", valid_593372
  var valid_593373 = query.getOrDefault("AnalysisSchemeNames")
  valid_593373 = validateParameter(valid_593373, JArray, required = false,
                                 default = nil)
  if valid_593373 != nil:
    section.add "AnalysisSchemeNames", valid_593373
  var valid_593374 = query.getOrDefault("Deployed")
  valid_593374 = validateParameter(valid_593374, JBool, required = false, default = nil)
  if valid_593374 != nil:
    section.add "Deployed", valid_593374
  var valid_593375 = query.getOrDefault("Action")
  valid_593375 = validateParameter(valid_593375, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_593375 != nil:
    section.add "Action", valid_593375
  var valid_593376 = query.getOrDefault("Version")
  valid_593376 = validateParameter(valid_593376, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593376 != nil:
    section.add "Version", valid_593376
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
  var valid_593377 = header.getOrDefault("X-Amz-Signature")
  valid_593377 = validateParameter(valid_593377, JString, required = false,
                                 default = nil)
  if valid_593377 != nil:
    section.add "X-Amz-Signature", valid_593377
  var valid_593378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593378 = validateParameter(valid_593378, JString, required = false,
                                 default = nil)
  if valid_593378 != nil:
    section.add "X-Amz-Content-Sha256", valid_593378
  var valid_593379 = header.getOrDefault("X-Amz-Date")
  valid_593379 = validateParameter(valid_593379, JString, required = false,
                                 default = nil)
  if valid_593379 != nil:
    section.add "X-Amz-Date", valid_593379
  var valid_593380 = header.getOrDefault("X-Amz-Credential")
  valid_593380 = validateParameter(valid_593380, JString, required = false,
                                 default = nil)
  if valid_593380 != nil:
    section.add "X-Amz-Credential", valid_593380
  var valid_593381 = header.getOrDefault("X-Amz-Security-Token")
  valid_593381 = validateParameter(valid_593381, JString, required = false,
                                 default = nil)
  if valid_593381 != nil:
    section.add "X-Amz-Security-Token", valid_593381
  var valid_593382 = header.getOrDefault("X-Amz-Algorithm")
  valid_593382 = validateParameter(valid_593382, JString, required = false,
                                 default = nil)
  if valid_593382 != nil:
    section.add "X-Amz-Algorithm", valid_593382
  var valid_593383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593383 = validateParameter(valid_593383, JString, required = false,
                                 default = nil)
  if valid_593383 != nil:
    section.add "X-Amz-SignedHeaders", valid_593383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593384: Call_GetDescribeAnalysisSchemes_593369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593384.validator(path, query, header, formData, body)
  let scheme = call_593384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593384.url(scheme.get, call_593384.host, call_593384.base,
                         call_593384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593384, url, valid)

proc call*(call_593385: Call_GetDescribeAnalysisSchemes_593369; DomainName: string;
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
  var query_593386 = newJObject()
  add(query_593386, "DomainName", newJString(DomainName))
  if AnalysisSchemeNames != nil:
    query_593386.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_593386, "Deployed", newJBool(Deployed))
  add(query_593386, "Action", newJString(Action))
  add(query_593386, "Version", newJString(Version))
  result = call_593385.call(nil, query_593386, nil, nil, nil)

var getDescribeAnalysisSchemes* = Call_GetDescribeAnalysisSchemes_593369(
    name: "getDescribeAnalysisSchemes", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_GetDescribeAnalysisSchemes_593370, base: "/",
    url: url_GetDescribeAnalysisSchemes_593371,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_593423 = ref object of OpenApiRestCall_592364
proc url_PostDescribeAvailabilityOptions_593425(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAvailabilityOptions_593424(path: JsonNode;
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
  var valid_593426 = query.getOrDefault("Action")
  valid_593426 = validateParameter(valid_593426, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_593426 != nil:
    section.add "Action", valid_593426
  var valid_593427 = query.getOrDefault("Version")
  valid_593427 = validateParameter(valid_593427, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593427 != nil:
    section.add "Version", valid_593427
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
  var valid_593428 = header.getOrDefault("X-Amz-Signature")
  valid_593428 = validateParameter(valid_593428, JString, required = false,
                                 default = nil)
  if valid_593428 != nil:
    section.add "X-Amz-Signature", valid_593428
  var valid_593429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593429 = validateParameter(valid_593429, JString, required = false,
                                 default = nil)
  if valid_593429 != nil:
    section.add "X-Amz-Content-Sha256", valid_593429
  var valid_593430 = header.getOrDefault("X-Amz-Date")
  valid_593430 = validateParameter(valid_593430, JString, required = false,
                                 default = nil)
  if valid_593430 != nil:
    section.add "X-Amz-Date", valid_593430
  var valid_593431 = header.getOrDefault("X-Amz-Credential")
  valid_593431 = validateParameter(valid_593431, JString, required = false,
                                 default = nil)
  if valid_593431 != nil:
    section.add "X-Amz-Credential", valid_593431
  var valid_593432 = header.getOrDefault("X-Amz-Security-Token")
  valid_593432 = validateParameter(valid_593432, JString, required = false,
                                 default = nil)
  if valid_593432 != nil:
    section.add "X-Amz-Security-Token", valid_593432
  var valid_593433 = header.getOrDefault("X-Amz-Algorithm")
  valid_593433 = validateParameter(valid_593433, JString, required = false,
                                 default = nil)
  if valid_593433 != nil:
    section.add "X-Amz-Algorithm", valid_593433
  var valid_593434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593434 = validateParameter(valid_593434, JString, required = false,
                                 default = nil)
  if valid_593434 != nil:
    section.add "X-Amz-SignedHeaders", valid_593434
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_593435 = formData.getOrDefault("Deployed")
  valid_593435 = validateParameter(valid_593435, JBool, required = false, default = nil)
  if valid_593435 != nil:
    section.add "Deployed", valid_593435
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593436 = formData.getOrDefault("DomainName")
  valid_593436 = validateParameter(valid_593436, JString, required = true,
                                 default = nil)
  if valid_593436 != nil:
    section.add "DomainName", valid_593436
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593437: Call_PostDescribeAvailabilityOptions_593423;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593437.validator(path, query, header, formData, body)
  let scheme = call_593437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593437.url(scheme.get, call_593437.host, call_593437.base,
                         call_593437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593437, url, valid)

proc call*(call_593438: Call_PostDescribeAvailabilityOptions_593423;
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
  var query_593439 = newJObject()
  var formData_593440 = newJObject()
  add(formData_593440, "Deployed", newJBool(Deployed))
  add(formData_593440, "DomainName", newJString(DomainName))
  add(query_593439, "Action", newJString(Action))
  add(query_593439, "Version", newJString(Version))
  result = call_593438.call(nil, query_593439, nil, formData_593440, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_593423(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_593424, base: "/",
    url: url_PostDescribeAvailabilityOptions_593425,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_593406 = ref object of OpenApiRestCall_592364
proc url_GetDescribeAvailabilityOptions_593408(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAvailabilityOptions_593407(path: JsonNode;
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
  var valid_593409 = query.getOrDefault("DomainName")
  valid_593409 = validateParameter(valid_593409, JString, required = true,
                                 default = nil)
  if valid_593409 != nil:
    section.add "DomainName", valid_593409
  var valid_593410 = query.getOrDefault("Deployed")
  valid_593410 = validateParameter(valid_593410, JBool, required = false, default = nil)
  if valid_593410 != nil:
    section.add "Deployed", valid_593410
  var valid_593411 = query.getOrDefault("Action")
  valid_593411 = validateParameter(valid_593411, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_593411 != nil:
    section.add "Action", valid_593411
  var valid_593412 = query.getOrDefault("Version")
  valid_593412 = validateParameter(valid_593412, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593412 != nil:
    section.add "Version", valid_593412
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
  var valid_593413 = header.getOrDefault("X-Amz-Signature")
  valid_593413 = validateParameter(valid_593413, JString, required = false,
                                 default = nil)
  if valid_593413 != nil:
    section.add "X-Amz-Signature", valid_593413
  var valid_593414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593414 = validateParameter(valid_593414, JString, required = false,
                                 default = nil)
  if valid_593414 != nil:
    section.add "X-Amz-Content-Sha256", valid_593414
  var valid_593415 = header.getOrDefault("X-Amz-Date")
  valid_593415 = validateParameter(valid_593415, JString, required = false,
                                 default = nil)
  if valid_593415 != nil:
    section.add "X-Amz-Date", valid_593415
  var valid_593416 = header.getOrDefault("X-Amz-Credential")
  valid_593416 = validateParameter(valid_593416, JString, required = false,
                                 default = nil)
  if valid_593416 != nil:
    section.add "X-Amz-Credential", valid_593416
  var valid_593417 = header.getOrDefault("X-Amz-Security-Token")
  valid_593417 = validateParameter(valid_593417, JString, required = false,
                                 default = nil)
  if valid_593417 != nil:
    section.add "X-Amz-Security-Token", valid_593417
  var valid_593418 = header.getOrDefault("X-Amz-Algorithm")
  valid_593418 = validateParameter(valid_593418, JString, required = false,
                                 default = nil)
  if valid_593418 != nil:
    section.add "X-Amz-Algorithm", valid_593418
  var valid_593419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593419 = validateParameter(valid_593419, JString, required = false,
                                 default = nil)
  if valid_593419 != nil:
    section.add "X-Amz-SignedHeaders", valid_593419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593420: Call_GetDescribeAvailabilityOptions_593406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593420.validator(path, query, header, formData, body)
  let scheme = call_593420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593420.url(scheme.get, call_593420.host, call_593420.base,
                         call_593420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593420, url, valid)

proc call*(call_593421: Call_GetDescribeAvailabilityOptions_593406;
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
  var query_593422 = newJObject()
  add(query_593422, "DomainName", newJString(DomainName))
  add(query_593422, "Deployed", newJBool(Deployed))
  add(query_593422, "Action", newJString(Action))
  add(query_593422, "Version", newJString(Version))
  result = call_593421.call(nil, query_593422, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_593406(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_593407, base: "/",
    url: url_GetDescribeAvailabilityOptions_593408,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_593457 = ref object of OpenApiRestCall_592364
proc url_PostDescribeDomains_593459(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDomains_593458(path: JsonNode; query: JsonNode;
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
  var valid_593460 = query.getOrDefault("Action")
  valid_593460 = validateParameter(valid_593460, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_593460 != nil:
    section.add "Action", valid_593460
  var valid_593461 = query.getOrDefault("Version")
  valid_593461 = validateParameter(valid_593461, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593461 != nil:
    section.add "Version", valid_593461
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
  var valid_593462 = header.getOrDefault("X-Amz-Signature")
  valid_593462 = validateParameter(valid_593462, JString, required = false,
                                 default = nil)
  if valid_593462 != nil:
    section.add "X-Amz-Signature", valid_593462
  var valid_593463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593463 = validateParameter(valid_593463, JString, required = false,
                                 default = nil)
  if valid_593463 != nil:
    section.add "X-Amz-Content-Sha256", valid_593463
  var valid_593464 = header.getOrDefault("X-Amz-Date")
  valid_593464 = validateParameter(valid_593464, JString, required = false,
                                 default = nil)
  if valid_593464 != nil:
    section.add "X-Amz-Date", valid_593464
  var valid_593465 = header.getOrDefault("X-Amz-Credential")
  valid_593465 = validateParameter(valid_593465, JString, required = false,
                                 default = nil)
  if valid_593465 != nil:
    section.add "X-Amz-Credential", valid_593465
  var valid_593466 = header.getOrDefault("X-Amz-Security-Token")
  valid_593466 = validateParameter(valid_593466, JString, required = false,
                                 default = nil)
  if valid_593466 != nil:
    section.add "X-Amz-Security-Token", valid_593466
  var valid_593467 = header.getOrDefault("X-Amz-Algorithm")
  valid_593467 = validateParameter(valid_593467, JString, required = false,
                                 default = nil)
  if valid_593467 != nil:
    section.add "X-Amz-Algorithm", valid_593467
  var valid_593468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593468 = validateParameter(valid_593468, JString, required = false,
                                 default = nil)
  if valid_593468 != nil:
    section.add "X-Amz-SignedHeaders", valid_593468
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_593469 = formData.getOrDefault("DomainNames")
  valid_593469 = validateParameter(valid_593469, JArray, required = false,
                                 default = nil)
  if valid_593469 != nil:
    section.add "DomainNames", valid_593469
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593470: Call_PostDescribeDomains_593457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593470.validator(path, query, header, formData, body)
  let scheme = call_593470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593470.url(scheme.get, call_593470.host, call_593470.base,
                         call_593470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593470, url, valid)

proc call*(call_593471: Call_PostDescribeDomains_593457;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593472 = newJObject()
  var formData_593473 = newJObject()
  if DomainNames != nil:
    formData_593473.add "DomainNames", DomainNames
  add(query_593472, "Action", newJString(Action))
  add(query_593472, "Version", newJString(Version))
  result = call_593471.call(nil, query_593472, nil, formData_593473, nil)

var postDescribeDomains* = Call_PostDescribeDomains_593457(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_593458, base: "/",
    url: url_PostDescribeDomains_593459, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_593441 = ref object of OpenApiRestCall_592364
proc url_GetDescribeDomains_593443(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDomains_593442(path: JsonNode; query: JsonNode;
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
  var valid_593444 = query.getOrDefault("DomainNames")
  valid_593444 = validateParameter(valid_593444, JArray, required = false,
                                 default = nil)
  if valid_593444 != nil:
    section.add "DomainNames", valid_593444
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593445 = query.getOrDefault("Action")
  valid_593445 = validateParameter(valid_593445, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_593445 != nil:
    section.add "Action", valid_593445
  var valid_593446 = query.getOrDefault("Version")
  valid_593446 = validateParameter(valid_593446, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593446 != nil:
    section.add "Version", valid_593446
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
  var valid_593447 = header.getOrDefault("X-Amz-Signature")
  valid_593447 = validateParameter(valid_593447, JString, required = false,
                                 default = nil)
  if valid_593447 != nil:
    section.add "X-Amz-Signature", valid_593447
  var valid_593448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593448 = validateParameter(valid_593448, JString, required = false,
                                 default = nil)
  if valid_593448 != nil:
    section.add "X-Amz-Content-Sha256", valid_593448
  var valid_593449 = header.getOrDefault("X-Amz-Date")
  valid_593449 = validateParameter(valid_593449, JString, required = false,
                                 default = nil)
  if valid_593449 != nil:
    section.add "X-Amz-Date", valid_593449
  var valid_593450 = header.getOrDefault("X-Amz-Credential")
  valid_593450 = validateParameter(valid_593450, JString, required = false,
                                 default = nil)
  if valid_593450 != nil:
    section.add "X-Amz-Credential", valid_593450
  var valid_593451 = header.getOrDefault("X-Amz-Security-Token")
  valid_593451 = validateParameter(valid_593451, JString, required = false,
                                 default = nil)
  if valid_593451 != nil:
    section.add "X-Amz-Security-Token", valid_593451
  var valid_593452 = header.getOrDefault("X-Amz-Algorithm")
  valid_593452 = validateParameter(valid_593452, JString, required = false,
                                 default = nil)
  if valid_593452 != nil:
    section.add "X-Amz-Algorithm", valid_593452
  var valid_593453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593453 = validateParameter(valid_593453, JString, required = false,
                                 default = nil)
  if valid_593453 != nil:
    section.add "X-Amz-SignedHeaders", valid_593453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593454: Call_GetDescribeDomains_593441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593454.validator(path, query, header, formData, body)
  let scheme = call_593454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593454.url(scheme.get, call_593454.host, call_593454.base,
                         call_593454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593454, url, valid)

proc call*(call_593455: Call_GetDescribeDomains_593441;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593456 = newJObject()
  if DomainNames != nil:
    query_593456.add "DomainNames", DomainNames
  add(query_593456, "Action", newJString(Action))
  add(query_593456, "Version", newJString(Version))
  result = call_593455.call(nil, query_593456, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_593441(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_593442, base: "/",
    url: url_GetDescribeDomains_593443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeExpressions_593492 = ref object of OpenApiRestCall_592364
proc url_PostDescribeExpressions_593494(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeExpressions_593493(path: JsonNode; query: JsonNode;
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
  var valid_593495 = query.getOrDefault("Action")
  valid_593495 = validateParameter(valid_593495, JString, required = true,
                                 default = newJString("DescribeExpressions"))
  if valid_593495 != nil:
    section.add "Action", valid_593495
  var valid_593496 = query.getOrDefault("Version")
  valid_593496 = validateParameter(valid_593496, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593496 != nil:
    section.add "Version", valid_593496
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
  var valid_593497 = header.getOrDefault("X-Amz-Signature")
  valid_593497 = validateParameter(valid_593497, JString, required = false,
                                 default = nil)
  if valid_593497 != nil:
    section.add "X-Amz-Signature", valid_593497
  var valid_593498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593498 = validateParameter(valid_593498, JString, required = false,
                                 default = nil)
  if valid_593498 != nil:
    section.add "X-Amz-Content-Sha256", valid_593498
  var valid_593499 = header.getOrDefault("X-Amz-Date")
  valid_593499 = validateParameter(valid_593499, JString, required = false,
                                 default = nil)
  if valid_593499 != nil:
    section.add "X-Amz-Date", valid_593499
  var valid_593500 = header.getOrDefault("X-Amz-Credential")
  valid_593500 = validateParameter(valid_593500, JString, required = false,
                                 default = nil)
  if valid_593500 != nil:
    section.add "X-Amz-Credential", valid_593500
  var valid_593501 = header.getOrDefault("X-Amz-Security-Token")
  valid_593501 = validateParameter(valid_593501, JString, required = false,
                                 default = nil)
  if valid_593501 != nil:
    section.add "X-Amz-Security-Token", valid_593501
  var valid_593502 = header.getOrDefault("X-Amz-Algorithm")
  valid_593502 = validateParameter(valid_593502, JString, required = false,
                                 default = nil)
  if valid_593502 != nil:
    section.add "X-Amz-Algorithm", valid_593502
  var valid_593503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593503 = validateParameter(valid_593503, JString, required = false,
                                 default = nil)
  if valid_593503 != nil:
    section.add "X-Amz-SignedHeaders", valid_593503
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  section = newJObject()
  var valid_593504 = formData.getOrDefault("Deployed")
  valid_593504 = validateParameter(valid_593504, JBool, required = false, default = nil)
  if valid_593504 != nil:
    section.add "Deployed", valid_593504
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593505 = formData.getOrDefault("DomainName")
  valid_593505 = validateParameter(valid_593505, JString, required = true,
                                 default = nil)
  if valid_593505 != nil:
    section.add "DomainName", valid_593505
  var valid_593506 = formData.getOrDefault("ExpressionNames")
  valid_593506 = validateParameter(valid_593506, JArray, required = false,
                                 default = nil)
  if valid_593506 != nil:
    section.add "ExpressionNames", valid_593506
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593507: Call_PostDescribeExpressions_593492; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593507.validator(path, query, header, formData, body)
  let scheme = call_593507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593507.url(scheme.get, call_593507.host, call_593507.base,
                         call_593507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593507, url, valid)

proc call*(call_593508: Call_PostDescribeExpressions_593492; DomainName: string;
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
  var query_593509 = newJObject()
  var formData_593510 = newJObject()
  add(formData_593510, "Deployed", newJBool(Deployed))
  add(formData_593510, "DomainName", newJString(DomainName))
  add(query_593509, "Action", newJString(Action))
  if ExpressionNames != nil:
    formData_593510.add "ExpressionNames", ExpressionNames
  add(query_593509, "Version", newJString(Version))
  result = call_593508.call(nil, query_593509, nil, formData_593510, nil)

var postDescribeExpressions* = Call_PostDescribeExpressions_593492(
    name: "postDescribeExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_PostDescribeExpressions_593493, base: "/",
    url: url_PostDescribeExpressions_593494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeExpressions_593474 = ref object of OpenApiRestCall_592364
proc url_GetDescribeExpressions_593476(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeExpressions_593475(path: JsonNode; query: JsonNode;
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
  var valid_593477 = query.getOrDefault("ExpressionNames")
  valid_593477 = validateParameter(valid_593477, JArray, required = false,
                                 default = nil)
  if valid_593477 != nil:
    section.add "ExpressionNames", valid_593477
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_593478 = query.getOrDefault("DomainName")
  valid_593478 = validateParameter(valid_593478, JString, required = true,
                                 default = nil)
  if valid_593478 != nil:
    section.add "DomainName", valid_593478
  var valid_593479 = query.getOrDefault("Deployed")
  valid_593479 = validateParameter(valid_593479, JBool, required = false, default = nil)
  if valid_593479 != nil:
    section.add "Deployed", valid_593479
  var valid_593480 = query.getOrDefault("Action")
  valid_593480 = validateParameter(valid_593480, JString, required = true,
                                 default = newJString("DescribeExpressions"))
  if valid_593480 != nil:
    section.add "Action", valid_593480
  var valid_593481 = query.getOrDefault("Version")
  valid_593481 = validateParameter(valid_593481, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593481 != nil:
    section.add "Version", valid_593481
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
  var valid_593482 = header.getOrDefault("X-Amz-Signature")
  valid_593482 = validateParameter(valid_593482, JString, required = false,
                                 default = nil)
  if valid_593482 != nil:
    section.add "X-Amz-Signature", valid_593482
  var valid_593483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593483 = validateParameter(valid_593483, JString, required = false,
                                 default = nil)
  if valid_593483 != nil:
    section.add "X-Amz-Content-Sha256", valid_593483
  var valid_593484 = header.getOrDefault("X-Amz-Date")
  valid_593484 = validateParameter(valid_593484, JString, required = false,
                                 default = nil)
  if valid_593484 != nil:
    section.add "X-Amz-Date", valid_593484
  var valid_593485 = header.getOrDefault("X-Amz-Credential")
  valid_593485 = validateParameter(valid_593485, JString, required = false,
                                 default = nil)
  if valid_593485 != nil:
    section.add "X-Amz-Credential", valid_593485
  var valid_593486 = header.getOrDefault("X-Amz-Security-Token")
  valid_593486 = validateParameter(valid_593486, JString, required = false,
                                 default = nil)
  if valid_593486 != nil:
    section.add "X-Amz-Security-Token", valid_593486
  var valid_593487 = header.getOrDefault("X-Amz-Algorithm")
  valid_593487 = validateParameter(valid_593487, JString, required = false,
                                 default = nil)
  if valid_593487 != nil:
    section.add "X-Amz-Algorithm", valid_593487
  var valid_593488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593488 = validateParameter(valid_593488, JString, required = false,
                                 default = nil)
  if valid_593488 != nil:
    section.add "X-Amz-SignedHeaders", valid_593488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593489: Call_GetDescribeExpressions_593474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593489.validator(path, query, header, formData, body)
  let scheme = call_593489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593489.url(scheme.get, call_593489.host, call_593489.base,
                         call_593489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593489, url, valid)

proc call*(call_593490: Call_GetDescribeExpressions_593474; DomainName: string;
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
  var query_593491 = newJObject()
  if ExpressionNames != nil:
    query_593491.add "ExpressionNames", ExpressionNames
  add(query_593491, "DomainName", newJString(DomainName))
  add(query_593491, "Deployed", newJBool(Deployed))
  add(query_593491, "Action", newJString(Action))
  add(query_593491, "Version", newJString(Version))
  result = call_593490.call(nil, query_593491, nil, nil, nil)

var getDescribeExpressions* = Call_GetDescribeExpressions_593474(
    name: "getDescribeExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_GetDescribeExpressions_593475, base: "/",
    url: url_GetDescribeExpressions_593476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_593529 = ref object of OpenApiRestCall_592364
proc url_PostDescribeIndexFields_593531(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeIndexFields_593530(path: JsonNode; query: JsonNode;
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
  var valid_593532 = query.getOrDefault("Action")
  valid_593532 = validateParameter(valid_593532, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_593532 != nil:
    section.add "Action", valid_593532
  var valid_593533 = query.getOrDefault("Version")
  valid_593533 = validateParameter(valid_593533, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593533 != nil:
    section.add "Version", valid_593533
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
  var valid_593534 = header.getOrDefault("X-Amz-Signature")
  valid_593534 = validateParameter(valid_593534, JString, required = false,
                                 default = nil)
  if valid_593534 != nil:
    section.add "X-Amz-Signature", valid_593534
  var valid_593535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593535 = validateParameter(valid_593535, JString, required = false,
                                 default = nil)
  if valid_593535 != nil:
    section.add "X-Amz-Content-Sha256", valid_593535
  var valid_593536 = header.getOrDefault("X-Amz-Date")
  valid_593536 = validateParameter(valid_593536, JString, required = false,
                                 default = nil)
  if valid_593536 != nil:
    section.add "X-Amz-Date", valid_593536
  var valid_593537 = header.getOrDefault("X-Amz-Credential")
  valid_593537 = validateParameter(valid_593537, JString, required = false,
                                 default = nil)
  if valid_593537 != nil:
    section.add "X-Amz-Credential", valid_593537
  var valid_593538 = header.getOrDefault("X-Amz-Security-Token")
  valid_593538 = validateParameter(valid_593538, JString, required = false,
                                 default = nil)
  if valid_593538 != nil:
    section.add "X-Amz-Security-Token", valid_593538
  var valid_593539 = header.getOrDefault("X-Amz-Algorithm")
  valid_593539 = validateParameter(valid_593539, JString, required = false,
                                 default = nil)
  if valid_593539 != nil:
    section.add "X-Amz-Algorithm", valid_593539
  var valid_593540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593540 = validateParameter(valid_593540, JString, required = false,
                                 default = nil)
  if valid_593540 != nil:
    section.add "X-Amz-SignedHeaders", valid_593540
  result.add "header", section
  ## parameters in `formData` object:
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_593541 = formData.getOrDefault("FieldNames")
  valid_593541 = validateParameter(valid_593541, JArray, required = false,
                                 default = nil)
  if valid_593541 != nil:
    section.add "FieldNames", valid_593541
  var valid_593542 = formData.getOrDefault("Deployed")
  valid_593542 = validateParameter(valid_593542, JBool, required = false, default = nil)
  if valid_593542 != nil:
    section.add "Deployed", valid_593542
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593543 = formData.getOrDefault("DomainName")
  valid_593543 = validateParameter(valid_593543, JString, required = true,
                                 default = nil)
  if valid_593543 != nil:
    section.add "DomainName", valid_593543
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593544: Call_PostDescribeIndexFields_593529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593544.validator(path, query, header, formData, body)
  let scheme = call_593544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593544.url(scheme.get, call_593544.host, call_593544.base,
                         call_593544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593544, url, valid)

proc call*(call_593545: Call_PostDescribeIndexFields_593529; DomainName: string;
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
  var query_593546 = newJObject()
  var formData_593547 = newJObject()
  if FieldNames != nil:
    formData_593547.add "FieldNames", FieldNames
  add(formData_593547, "Deployed", newJBool(Deployed))
  add(formData_593547, "DomainName", newJString(DomainName))
  add(query_593546, "Action", newJString(Action))
  add(query_593546, "Version", newJString(Version))
  result = call_593545.call(nil, query_593546, nil, formData_593547, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_593529(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_593530, base: "/",
    url: url_PostDescribeIndexFields_593531, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_593511 = ref object of OpenApiRestCall_592364
proc url_GetDescribeIndexFields_593513(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeIndexFields_593512(path: JsonNode; query: JsonNode;
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
  var valid_593514 = query.getOrDefault("DomainName")
  valid_593514 = validateParameter(valid_593514, JString, required = true,
                                 default = nil)
  if valid_593514 != nil:
    section.add "DomainName", valid_593514
  var valid_593515 = query.getOrDefault("Deployed")
  valid_593515 = validateParameter(valid_593515, JBool, required = false, default = nil)
  if valid_593515 != nil:
    section.add "Deployed", valid_593515
  var valid_593516 = query.getOrDefault("Action")
  valid_593516 = validateParameter(valid_593516, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_593516 != nil:
    section.add "Action", valid_593516
  var valid_593517 = query.getOrDefault("Version")
  valid_593517 = validateParameter(valid_593517, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593517 != nil:
    section.add "Version", valid_593517
  var valid_593518 = query.getOrDefault("FieldNames")
  valid_593518 = validateParameter(valid_593518, JArray, required = false,
                                 default = nil)
  if valid_593518 != nil:
    section.add "FieldNames", valid_593518
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
  var valid_593519 = header.getOrDefault("X-Amz-Signature")
  valid_593519 = validateParameter(valid_593519, JString, required = false,
                                 default = nil)
  if valid_593519 != nil:
    section.add "X-Amz-Signature", valid_593519
  var valid_593520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593520 = validateParameter(valid_593520, JString, required = false,
                                 default = nil)
  if valid_593520 != nil:
    section.add "X-Amz-Content-Sha256", valid_593520
  var valid_593521 = header.getOrDefault("X-Amz-Date")
  valid_593521 = validateParameter(valid_593521, JString, required = false,
                                 default = nil)
  if valid_593521 != nil:
    section.add "X-Amz-Date", valid_593521
  var valid_593522 = header.getOrDefault("X-Amz-Credential")
  valid_593522 = validateParameter(valid_593522, JString, required = false,
                                 default = nil)
  if valid_593522 != nil:
    section.add "X-Amz-Credential", valid_593522
  var valid_593523 = header.getOrDefault("X-Amz-Security-Token")
  valid_593523 = validateParameter(valid_593523, JString, required = false,
                                 default = nil)
  if valid_593523 != nil:
    section.add "X-Amz-Security-Token", valid_593523
  var valid_593524 = header.getOrDefault("X-Amz-Algorithm")
  valid_593524 = validateParameter(valid_593524, JString, required = false,
                                 default = nil)
  if valid_593524 != nil:
    section.add "X-Amz-Algorithm", valid_593524
  var valid_593525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593525 = validateParameter(valid_593525, JString, required = false,
                                 default = nil)
  if valid_593525 != nil:
    section.add "X-Amz-SignedHeaders", valid_593525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593526: Call_GetDescribeIndexFields_593511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593526.validator(path, query, header, formData, body)
  let scheme = call_593526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593526.url(scheme.get, call_593526.host, call_593526.base,
                         call_593526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593526, url, valid)

proc call*(call_593527: Call_GetDescribeIndexFields_593511; DomainName: string;
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
  var query_593528 = newJObject()
  add(query_593528, "DomainName", newJString(DomainName))
  add(query_593528, "Deployed", newJBool(Deployed))
  add(query_593528, "Action", newJString(Action))
  add(query_593528, "Version", newJString(Version))
  if FieldNames != nil:
    query_593528.add "FieldNames", FieldNames
  result = call_593527.call(nil, query_593528, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_593511(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_593512, base: "/",
    url: url_GetDescribeIndexFields_593513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeScalingParameters_593564 = ref object of OpenApiRestCall_592364
proc url_PostDescribeScalingParameters_593566(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeScalingParameters_593565(path: JsonNode; query: JsonNode;
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
  var valid_593567 = query.getOrDefault("Action")
  valid_593567 = validateParameter(valid_593567, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_593567 != nil:
    section.add "Action", valid_593567
  var valid_593568 = query.getOrDefault("Version")
  valid_593568 = validateParameter(valid_593568, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593568 != nil:
    section.add "Version", valid_593568
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
  var valid_593569 = header.getOrDefault("X-Amz-Signature")
  valid_593569 = validateParameter(valid_593569, JString, required = false,
                                 default = nil)
  if valid_593569 != nil:
    section.add "X-Amz-Signature", valid_593569
  var valid_593570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593570 = validateParameter(valid_593570, JString, required = false,
                                 default = nil)
  if valid_593570 != nil:
    section.add "X-Amz-Content-Sha256", valid_593570
  var valid_593571 = header.getOrDefault("X-Amz-Date")
  valid_593571 = validateParameter(valid_593571, JString, required = false,
                                 default = nil)
  if valid_593571 != nil:
    section.add "X-Amz-Date", valid_593571
  var valid_593572 = header.getOrDefault("X-Amz-Credential")
  valid_593572 = validateParameter(valid_593572, JString, required = false,
                                 default = nil)
  if valid_593572 != nil:
    section.add "X-Amz-Credential", valid_593572
  var valid_593573 = header.getOrDefault("X-Amz-Security-Token")
  valid_593573 = validateParameter(valid_593573, JString, required = false,
                                 default = nil)
  if valid_593573 != nil:
    section.add "X-Amz-Security-Token", valid_593573
  var valid_593574 = header.getOrDefault("X-Amz-Algorithm")
  valid_593574 = validateParameter(valid_593574, JString, required = false,
                                 default = nil)
  if valid_593574 != nil:
    section.add "X-Amz-Algorithm", valid_593574
  var valid_593575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593575 = validateParameter(valid_593575, JString, required = false,
                                 default = nil)
  if valid_593575 != nil:
    section.add "X-Amz-SignedHeaders", valid_593575
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593576 = formData.getOrDefault("DomainName")
  valid_593576 = validateParameter(valid_593576, JString, required = true,
                                 default = nil)
  if valid_593576 != nil:
    section.add "DomainName", valid_593576
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593577: Call_PostDescribeScalingParameters_593564; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593577.validator(path, query, header, formData, body)
  let scheme = call_593577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593577.url(scheme.get, call_593577.host, call_593577.base,
                         call_593577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593577, url, valid)

proc call*(call_593578: Call_PostDescribeScalingParameters_593564;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593579 = newJObject()
  var formData_593580 = newJObject()
  add(formData_593580, "DomainName", newJString(DomainName))
  add(query_593579, "Action", newJString(Action))
  add(query_593579, "Version", newJString(Version))
  result = call_593578.call(nil, query_593579, nil, formData_593580, nil)

var postDescribeScalingParameters* = Call_PostDescribeScalingParameters_593564(
    name: "postDescribeScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_PostDescribeScalingParameters_593565, base: "/",
    url: url_PostDescribeScalingParameters_593566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeScalingParameters_593548 = ref object of OpenApiRestCall_592364
proc url_GetDescribeScalingParameters_593550(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeScalingParameters_593549(path: JsonNode; query: JsonNode;
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
  var valid_593551 = query.getOrDefault("DomainName")
  valid_593551 = validateParameter(valid_593551, JString, required = true,
                                 default = nil)
  if valid_593551 != nil:
    section.add "DomainName", valid_593551
  var valid_593552 = query.getOrDefault("Action")
  valid_593552 = validateParameter(valid_593552, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_593552 != nil:
    section.add "Action", valid_593552
  var valid_593553 = query.getOrDefault("Version")
  valid_593553 = validateParameter(valid_593553, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593553 != nil:
    section.add "Version", valid_593553
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
  var valid_593554 = header.getOrDefault("X-Amz-Signature")
  valid_593554 = validateParameter(valid_593554, JString, required = false,
                                 default = nil)
  if valid_593554 != nil:
    section.add "X-Amz-Signature", valid_593554
  var valid_593555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593555 = validateParameter(valid_593555, JString, required = false,
                                 default = nil)
  if valid_593555 != nil:
    section.add "X-Amz-Content-Sha256", valid_593555
  var valid_593556 = header.getOrDefault("X-Amz-Date")
  valid_593556 = validateParameter(valid_593556, JString, required = false,
                                 default = nil)
  if valid_593556 != nil:
    section.add "X-Amz-Date", valid_593556
  var valid_593557 = header.getOrDefault("X-Amz-Credential")
  valid_593557 = validateParameter(valid_593557, JString, required = false,
                                 default = nil)
  if valid_593557 != nil:
    section.add "X-Amz-Credential", valid_593557
  var valid_593558 = header.getOrDefault("X-Amz-Security-Token")
  valid_593558 = validateParameter(valid_593558, JString, required = false,
                                 default = nil)
  if valid_593558 != nil:
    section.add "X-Amz-Security-Token", valid_593558
  var valid_593559 = header.getOrDefault("X-Amz-Algorithm")
  valid_593559 = validateParameter(valid_593559, JString, required = false,
                                 default = nil)
  if valid_593559 != nil:
    section.add "X-Amz-Algorithm", valid_593559
  var valid_593560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593560 = validateParameter(valid_593560, JString, required = false,
                                 default = nil)
  if valid_593560 != nil:
    section.add "X-Amz-SignedHeaders", valid_593560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593561: Call_GetDescribeScalingParameters_593548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593561.validator(path, query, header, formData, body)
  let scheme = call_593561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593561.url(scheme.get, call_593561.host, call_593561.base,
                         call_593561.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593561, url, valid)

proc call*(call_593562: Call_GetDescribeScalingParameters_593548;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593563 = newJObject()
  add(query_593563, "DomainName", newJString(DomainName))
  add(query_593563, "Action", newJString(Action))
  add(query_593563, "Version", newJString(Version))
  result = call_593562.call(nil, query_593563, nil, nil, nil)

var getDescribeScalingParameters* = Call_GetDescribeScalingParameters_593548(
    name: "getDescribeScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_GetDescribeScalingParameters_593549, base: "/",
    url: url_GetDescribeScalingParameters_593550,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_593598 = ref object of OpenApiRestCall_592364
proc url_PostDescribeServiceAccessPolicies_593600(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeServiceAccessPolicies_593599(path: JsonNode;
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
  var valid_593601 = query.getOrDefault("Action")
  valid_593601 = validateParameter(valid_593601, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_593601 != nil:
    section.add "Action", valid_593601
  var valid_593602 = query.getOrDefault("Version")
  valid_593602 = validateParameter(valid_593602, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593602 != nil:
    section.add "Version", valid_593602
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
  var valid_593603 = header.getOrDefault("X-Amz-Signature")
  valid_593603 = validateParameter(valid_593603, JString, required = false,
                                 default = nil)
  if valid_593603 != nil:
    section.add "X-Amz-Signature", valid_593603
  var valid_593604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593604 = validateParameter(valid_593604, JString, required = false,
                                 default = nil)
  if valid_593604 != nil:
    section.add "X-Amz-Content-Sha256", valid_593604
  var valid_593605 = header.getOrDefault("X-Amz-Date")
  valid_593605 = validateParameter(valid_593605, JString, required = false,
                                 default = nil)
  if valid_593605 != nil:
    section.add "X-Amz-Date", valid_593605
  var valid_593606 = header.getOrDefault("X-Amz-Credential")
  valid_593606 = validateParameter(valid_593606, JString, required = false,
                                 default = nil)
  if valid_593606 != nil:
    section.add "X-Amz-Credential", valid_593606
  var valid_593607 = header.getOrDefault("X-Amz-Security-Token")
  valid_593607 = validateParameter(valid_593607, JString, required = false,
                                 default = nil)
  if valid_593607 != nil:
    section.add "X-Amz-Security-Token", valid_593607
  var valid_593608 = header.getOrDefault("X-Amz-Algorithm")
  valid_593608 = validateParameter(valid_593608, JString, required = false,
                                 default = nil)
  if valid_593608 != nil:
    section.add "X-Amz-Algorithm", valid_593608
  var valid_593609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593609 = validateParameter(valid_593609, JString, required = false,
                                 default = nil)
  if valid_593609 != nil:
    section.add "X-Amz-SignedHeaders", valid_593609
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_593610 = formData.getOrDefault("Deployed")
  valid_593610 = validateParameter(valid_593610, JBool, required = false, default = nil)
  if valid_593610 != nil:
    section.add "Deployed", valid_593610
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593611 = formData.getOrDefault("DomainName")
  valid_593611 = validateParameter(valid_593611, JString, required = true,
                                 default = nil)
  if valid_593611 != nil:
    section.add "DomainName", valid_593611
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593612: Call_PostDescribeServiceAccessPolicies_593598;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593612.validator(path, query, header, formData, body)
  let scheme = call_593612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593612.url(scheme.get, call_593612.host, call_593612.base,
                         call_593612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593612, url, valid)

proc call*(call_593613: Call_PostDescribeServiceAccessPolicies_593598;
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
  var query_593614 = newJObject()
  var formData_593615 = newJObject()
  add(formData_593615, "Deployed", newJBool(Deployed))
  add(formData_593615, "DomainName", newJString(DomainName))
  add(query_593614, "Action", newJString(Action))
  add(query_593614, "Version", newJString(Version))
  result = call_593613.call(nil, query_593614, nil, formData_593615, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_593598(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_593599, base: "/",
    url: url_PostDescribeServiceAccessPolicies_593600,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_593581 = ref object of OpenApiRestCall_592364
proc url_GetDescribeServiceAccessPolicies_593583(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeServiceAccessPolicies_593582(path: JsonNode;
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
  var valid_593584 = query.getOrDefault("DomainName")
  valid_593584 = validateParameter(valid_593584, JString, required = true,
                                 default = nil)
  if valid_593584 != nil:
    section.add "DomainName", valid_593584
  var valid_593585 = query.getOrDefault("Deployed")
  valid_593585 = validateParameter(valid_593585, JBool, required = false, default = nil)
  if valid_593585 != nil:
    section.add "Deployed", valid_593585
  var valid_593586 = query.getOrDefault("Action")
  valid_593586 = validateParameter(valid_593586, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_593586 != nil:
    section.add "Action", valid_593586
  var valid_593587 = query.getOrDefault("Version")
  valid_593587 = validateParameter(valid_593587, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593587 != nil:
    section.add "Version", valid_593587
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
  var valid_593588 = header.getOrDefault("X-Amz-Signature")
  valid_593588 = validateParameter(valid_593588, JString, required = false,
                                 default = nil)
  if valid_593588 != nil:
    section.add "X-Amz-Signature", valid_593588
  var valid_593589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593589 = validateParameter(valid_593589, JString, required = false,
                                 default = nil)
  if valid_593589 != nil:
    section.add "X-Amz-Content-Sha256", valid_593589
  var valid_593590 = header.getOrDefault("X-Amz-Date")
  valid_593590 = validateParameter(valid_593590, JString, required = false,
                                 default = nil)
  if valid_593590 != nil:
    section.add "X-Amz-Date", valid_593590
  var valid_593591 = header.getOrDefault("X-Amz-Credential")
  valid_593591 = validateParameter(valid_593591, JString, required = false,
                                 default = nil)
  if valid_593591 != nil:
    section.add "X-Amz-Credential", valid_593591
  var valid_593592 = header.getOrDefault("X-Amz-Security-Token")
  valid_593592 = validateParameter(valid_593592, JString, required = false,
                                 default = nil)
  if valid_593592 != nil:
    section.add "X-Amz-Security-Token", valid_593592
  var valid_593593 = header.getOrDefault("X-Amz-Algorithm")
  valid_593593 = validateParameter(valid_593593, JString, required = false,
                                 default = nil)
  if valid_593593 != nil:
    section.add "X-Amz-Algorithm", valid_593593
  var valid_593594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593594 = validateParameter(valid_593594, JString, required = false,
                                 default = nil)
  if valid_593594 != nil:
    section.add "X-Amz-SignedHeaders", valid_593594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593595: Call_GetDescribeServiceAccessPolicies_593581;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593595.validator(path, query, header, formData, body)
  let scheme = call_593595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593595.url(scheme.get, call_593595.host, call_593595.base,
                         call_593595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593595, url, valid)

proc call*(call_593596: Call_GetDescribeServiceAccessPolicies_593581;
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
  var query_593597 = newJObject()
  add(query_593597, "DomainName", newJString(DomainName))
  add(query_593597, "Deployed", newJBool(Deployed))
  add(query_593597, "Action", newJString(Action))
  add(query_593597, "Version", newJString(Version))
  result = call_593596.call(nil, query_593597, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_593581(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_593582, base: "/",
    url: url_GetDescribeServiceAccessPolicies_593583,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSuggesters_593634 = ref object of OpenApiRestCall_592364
proc url_PostDescribeSuggesters_593636(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeSuggesters_593635(path: JsonNode; query: JsonNode;
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
  var valid_593637 = query.getOrDefault("Action")
  valid_593637 = validateParameter(valid_593637, JString, required = true,
                                 default = newJString("DescribeSuggesters"))
  if valid_593637 != nil:
    section.add "Action", valid_593637
  var valid_593638 = query.getOrDefault("Version")
  valid_593638 = validateParameter(valid_593638, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593638 != nil:
    section.add "Version", valid_593638
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
  var valid_593639 = header.getOrDefault("X-Amz-Signature")
  valid_593639 = validateParameter(valid_593639, JString, required = false,
                                 default = nil)
  if valid_593639 != nil:
    section.add "X-Amz-Signature", valid_593639
  var valid_593640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593640 = validateParameter(valid_593640, JString, required = false,
                                 default = nil)
  if valid_593640 != nil:
    section.add "X-Amz-Content-Sha256", valid_593640
  var valid_593641 = header.getOrDefault("X-Amz-Date")
  valid_593641 = validateParameter(valid_593641, JString, required = false,
                                 default = nil)
  if valid_593641 != nil:
    section.add "X-Amz-Date", valid_593641
  var valid_593642 = header.getOrDefault("X-Amz-Credential")
  valid_593642 = validateParameter(valid_593642, JString, required = false,
                                 default = nil)
  if valid_593642 != nil:
    section.add "X-Amz-Credential", valid_593642
  var valid_593643 = header.getOrDefault("X-Amz-Security-Token")
  valid_593643 = validateParameter(valid_593643, JString, required = false,
                                 default = nil)
  if valid_593643 != nil:
    section.add "X-Amz-Security-Token", valid_593643
  var valid_593644 = header.getOrDefault("X-Amz-Algorithm")
  valid_593644 = validateParameter(valid_593644, JString, required = false,
                                 default = nil)
  if valid_593644 != nil:
    section.add "X-Amz-Algorithm", valid_593644
  var valid_593645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593645 = validateParameter(valid_593645, JString, required = false,
                                 default = nil)
  if valid_593645 != nil:
    section.add "X-Amz-SignedHeaders", valid_593645
  result.add "header", section
  ## parameters in `formData` object:
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_593646 = formData.getOrDefault("SuggesterNames")
  valid_593646 = validateParameter(valid_593646, JArray, required = false,
                                 default = nil)
  if valid_593646 != nil:
    section.add "SuggesterNames", valid_593646
  var valid_593647 = formData.getOrDefault("Deployed")
  valid_593647 = validateParameter(valid_593647, JBool, required = false, default = nil)
  if valid_593647 != nil:
    section.add "Deployed", valid_593647
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593648 = formData.getOrDefault("DomainName")
  valid_593648 = validateParameter(valid_593648, JString, required = true,
                                 default = nil)
  if valid_593648 != nil:
    section.add "DomainName", valid_593648
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593649: Call_PostDescribeSuggesters_593634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593649.validator(path, query, header, formData, body)
  let scheme = call_593649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593649.url(scheme.get, call_593649.host, call_593649.base,
                         call_593649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593649, url, valid)

proc call*(call_593650: Call_PostDescribeSuggesters_593634; DomainName: string;
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
  var query_593651 = newJObject()
  var formData_593652 = newJObject()
  if SuggesterNames != nil:
    formData_593652.add "SuggesterNames", SuggesterNames
  add(formData_593652, "Deployed", newJBool(Deployed))
  add(formData_593652, "DomainName", newJString(DomainName))
  add(query_593651, "Action", newJString(Action))
  add(query_593651, "Version", newJString(Version))
  result = call_593650.call(nil, query_593651, nil, formData_593652, nil)

var postDescribeSuggesters* = Call_PostDescribeSuggesters_593634(
    name: "postDescribeSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_PostDescribeSuggesters_593635, base: "/",
    url: url_PostDescribeSuggesters_593636, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSuggesters_593616 = ref object of OpenApiRestCall_592364
proc url_GetDescribeSuggesters_593618(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeSuggesters_593617(path: JsonNode; query: JsonNode;
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
  var valid_593619 = query.getOrDefault("DomainName")
  valid_593619 = validateParameter(valid_593619, JString, required = true,
                                 default = nil)
  if valid_593619 != nil:
    section.add "DomainName", valid_593619
  var valid_593620 = query.getOrDefault("Deployed")
  valid_593620 = validateParameter(valid_593620, JBool, required = false, default = nil)
  if valid_593620 != nil:
    section.add "Deployed", valid_593620
  var valid_593621 = query.getOrDefault("Action")
  valid_593621 = validateParameter(valid_593621, JString, required = true,
                                 default = newJString("DescribeSuggesters"))
  if valid_593621 != nil:
    section.add "Action", valid_593621
  var valid_593622 = query.getOrDefault("Version")
  valid_593622 = validateParameter(valid_593622, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593622 != nil:
    section.add "Version", valid_593622
  var valid_593623 = query.getOrDefault("SuggesterNames")
  valid_593623 = validateParameter(valid_593623, JArray, required = false,
                                 default = nil)
  if valid_593623 != nil:
    section.add "SuggesterNames", valid_593623
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
  var valid_593624 = header.getOrDefault("X-Amz-Signature")
  valid_593624 = validateParameter(valid_593624, JString, required = false,
                                 default = nil)
  if valid_593624 != nil:
    section.add "X-Amz-Signature", valid_593624
  var valid_593625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593625 = validateParameter(valid_593625, JString, required = false,
                                 default = nil)
  if valid_593625 != nil:
    section.add "X-Amz-Content-Sha256", valid_593625
  var valid_593626 = header.getOrDefault("X-Amz-Date")
  valid_593626 = validateParameter(valid_593626, JString, required = false,
                                 default = nil)
  if valid_593626 != nil:
    section.add "X-Amz-Date", valid_593626
  var valid_593627 = header.getOrDefault("X-Amz-Credential")
  valid_593627 = validateParameter(valid_593627, JString, required = false,
                                 default = nil)
  if valid_593627 != nil:
    section.add "X-Amz-Credential", valid_593627
  var valid_593628 = header.getOrDefault("X-Amz-Security-Token")
  valid_593628 = validateParameter(valid_593628, JString, required = false,
                                 default = nil)
  if valid_593628 != nil:
    section.add "X-Amz-Security-Token", valid_593628
  var valid_593629 = header.getOrDefault("X-Amz-Algorithm")
  valid_593629 = validateParameter(valid_593629, JString, required = false,
                                 default = nil)
  if valid_593629 != nil:
    section.add "X-Amz-Algorithm", valid_593629
  var valid_593630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593630 = validateParameter(valid_593630, JString, required = false,
                                 default = nil)
  if valid_593630 != nil:
    section.add "X-Amz-SignedHeaders", valid_593630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593631: Call_GetDescribeSuggesters_593616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593631.validator(path, query, header, formData, body)
  let scheme = call_593631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593631.url(scheme.get, call_593631.host, call_593631.base,
                         call_593631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593631, url, valid)

proc call*(call_593632: Call_GetDescribeSuggesters_593616; DomainName: string;
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
  var query_593633 = newJObject()
  add(query_593633, "DomainName", newJString(DomainName))
  add(query_593633, "Deployed", newJBool(Deployed))
  add(query_593633, "Action", newJString(Action))
  add(query_593633, "Version", newJString(Version))
  if SuggesterNames != nil:
    query_593633.add "SuggesterNames", SuggesterNames
  result = call_593632.call(nil, query_593633, nil, nil, nil)

var getDescribeSuggesters* = Call_GetDescribeSuggesters_593616(
    name: "getDescribeSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_GetDescribeSuggesters_593617, base: "/",
    url: url_GetDescribeSuggesters_593618, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_593669 = ref object of OpenApiRestCall_592364
proc url_PostIndexDocuments_593671(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostIndexDocuments_593670(path: JsonNode; query: JsonNode;
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
  var valid_593672 = query.getOrDefault("Action")
  valid_593672 = validateParameter(valid_593672, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_593672 != nil:
    section.add "Action", valid_593672
  var valid_593673 = query.getOrDefault("Version")
  valid_593673 = validateParameter(valid_593673, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593673 != nil:
    section.add "Version", valid_593673
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
  var valid_593674 = header.getOrDefault("X-Amz-Signature")
  valid_593674 = validateParameter(valid_593674, JString, required = false,
                                 default = nil)
  if valid_593674 != nil:
    section.add "X-Amz-Signature", valid_593674
  var valid_593675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593675 = validateParameter(valid_593675, JString, required = false,
                                 default = nil)
  if valid_593675 != nil:
    section.add "X-Amz-Content-Sha256", valid_593675
  var valid_593676 = header.getOrDefault("X-Amz-Date")
  valid_593676 = validateParameter(valid_593676, JString, required = false,
                                 default = nil)
  if valid_593676 != nil:
    section.add "X-Amz-Date", valid_593676
  var valid_593677 = header.getOrDefault("X-Amz-Credential")
  valid_593677 = validateParameter(valid_593677, JString, required = false,
                                 default = nil)
  if valid_593677 != nil:
    section.add "X-Amz-Credential", valid_593677
  var valid_593678 = header.getOrDefault("X-Amz-Security-Token")
  valid_593678 = validateParameter(valid_593678, JString, required = false,
                                 default = nil)
  if valid_593678 != nil:
    section.add "X-Amz-Security-Token", valid_593678
  var valid_593679 = header.getOrDefault("X-Amz-Algorithm")
  valid_593679 = validateParameter(valid_593679, JString, required = false,
                                 default = nil)
  if valid_593679 != nil:
    section.add "X-Amz-Algorithm", valid_593679
  var valid_593680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593680 = validateParameter(valid_593680, JString, required = false,
                                 default = nil)
  if valid_593680 != nil:
    section.add "X-Amz-SignedHeaders", valid_593680
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593681 = formData.getOrDefault("DomainName")
  valid_593681 = validateParameter(valid_593681, JString, required = true,
                                 default = nil)
  if valid_593681 != nil:
    section.add "DomainName", valid_593681
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593682: Call_PostIndexDocuments_593669; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_593682.validator(path, query, header, formData, body)
  let scheme = call_593682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593682.url(scheme.get, call_593682.host, call_593682.base,
                         call_593682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593682, url, valid)

proc call*(call_593683: Call_PostIndexDocuments_593669; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593684 = newJObject()
  var formData_593685 = newJObject()
  add(formData_593685, "DomainName", newJString(DomainName))
  add(query_593684, "Action", newJString(Action))
  add(query_593684, "Version", newJString(Version))
  result = call_593683.call(nil, query_593684, nil, formData_593685, nil)

var postIndexDocuments* = Call_PostIndexDocuments_593669(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_593670, base: "/",
    url: url_PostIndexDocuments_593671, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_593653 = ref object of OpenApiRestCall_592364
proc url_GetIndexDocuments_593655(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetIndexDocuments_593654(path: JsonNode; query: JsonNode;
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
  var valid_593656 = query.getOrDefault("DomainName")
  valid_593656 = validateParameter(valid_593656, JString, required = true,
                                 default = nil)
  if valid_593656 != nil:
    section.add "DomainName", valid_593656
  var valid_593657 = query.getOrDefault("Action")
  valid_593657 = validateParameter(valid_593657, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_593657 != nil:
    section.add "Action", valid_593657
  var valid_593658 = query.getOrDefault("Version")
  valid_593658 = validateParameter(valid_593658, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593658 != nil:
    section.add "Version", valid_593658
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
  var valid_593659 = header.getOrDefault("X-Amz-Signature")
  valid_593659 = validateParameter(valid_593659, JString, required = false,
                                 default = nil)
  if valid_593659 != nil:
    section.add "X-Amz-Signature", valid_593659
  var valid_593660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593660 = validateParameter(valid_593660, JString, required = false,
                                 default = nil)
  if valid_593660 != nil:
    section.add "X-Amz-Content-Sha256", valid_593660
  var valid_593661 = header.getOrDefault("X-Amz-Date")
  valid_593661 = validateParameter(valid_593661, JString, required = false,
                                 default = nil)
  if valid_593661 != nil:
    section.add "X-Amz-Date", valid_593661
  var valid_593662 = header.getOrDefault("X-Amz-Credential")
  valid_593662 = validateParameter(valid_593662, JString, required = false,
                                 default = nil)
  if valid_593662 != nil:
    section.add "X-Amz-Credential", valid_593662
  var valid_593663 = header.getOrDefault("X-Amz-Security-Token")
  valid_593663 = validateParameter(valid_593663, JString, required = false,
                                 default = nil)
  if valid_593663 != nil:
    section.add "X-Amz-Security-Token", valid_593663
  var valid_593664 = header.getOrDefault("X-Amz-Algorithm")
  valid_593664 = validateParameter(valid_593664, JString, required = false,
                                 default = nil)
  if valid_593664 != nil:
    section.add "X-Amz-Algorithm", valid_593664
  var valid_593665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593665 = validateParameter(valid_593665, JString, required = false,
                                 default = nil)
  if valid_593665 != nil:
    section.add "X-Amz-SignedHeaders", valid_593665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593666: Call_GetIndexDocuments_593653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_593666.validator(path, query, header, formData, body)
  let scheme = call_593666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593666.url(scheme.get, call_593666.host, call_593666.base,
                         call_593666.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593666, url, valid)

proc call*(call_593667: Call_GetIndexDocuments_593653; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593668 = newJObject()
  add(query_593668, "DomainName", newJString(DomainName))
  add(query_593668, "Action", newJString(Action))
  add(query_593668, "Version", newJString(Version))
  result = call_593667.call(nil, query_593668, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_593653(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_593654,
    base: "/", url: url_GetIndexDocuments_593655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomainNames_593701 = ref object of OpenApiRestCall_592364
proc url_PostListDomainNames_593703(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListDomainNames_593702(path: JsonNode; query: JsonNode;
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
  var valid_593704 = query.getOrDefault("Action")
  valid_593704 = validateParameter(valid_593704, JString, required = true,
                                 default = newJString("ListDomainNames"))
  if valid_593704 != nil:
    section.add "Action", valid_593704
  var valid_593705 = query.getOrDefault("Version")
  valid_593705 = validateParameter(valid_593705, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593705 != nil:
    section.add "Version", valid_593705
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
  var valid_593706 = header.getOrDefault("X-Amz-Signature")
  valid_593706 = validateParameter(valid_593706, JString, required = false,
                                 default = nil)
  if valid_593706 != nil:
    section.add "X-Amz-Signature", valid_593706
  var valid_593707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593707 = validateParameter(valid_593707, JString, required = false,
                                 default = nil)
  if valid_593707 != nil:
    section.add "X-Amz-Content-Sha256", valid_593707
  var valid_593708 = header.getOrDefault("X-Amz-Date")
  valid_593708 = validateParameter(valid_593708, JString, required = false,
                                 default = nil)
  if valid_593708 != nil:
    section.add "X-Amz-Date", valid_593708
  var valid_593709 = header.getOrDefault("X-Amz-Credential")
  valid_593709 = validateParameter(valid_593709, JString, required = false,
                                 default = nil)
  if valid_593709 != nil:
    section.add "X-Amz-Credential", valid_593709
  var valid_593710 = header.getOrDefault("X-Amz-Security-Token")
  valid_593710 = validateParameter(valid_593710, JString, required = false,
                                 default = nil)
  if valid_593710 != nil:
    section.add "X-Amz-Security-Token", valid_593710
  var valid_593711 = header.getOrDefault("X-Amz-Algorithm")
  valid_593711 = validateParameter(valid_593711, JString, required = false,
                                 default = nil)
  if valid_593711 != nil:
    section.add "X-Amz-Algorithm", valid_593711
  var valid_593712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593712 = validateParameter(valid_593712, JString, required = false,
                                 default = nil)
  if valid_593712 != nil:
    section.add "X-Amz-SignedHeaders", valid_593712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593713: Call_PostListDomainNames_593701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_593713.validator(path, query, header, formData, body)
  let scheme = call_593713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593713.url(scheme.get, call_593713.host, call_593713.base,
                         call_593713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593713, url, valid)

proc call*(call_593714: Call_PostListDomainNames_593701;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## postListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593715 = newJObject()
  add(query_593715, "Action", newJString(Action))
  add(query_593715, "Version", newJString(Version))
  result = call_593714.call(nil, query_593715, nil, nil, nil)

var postListDomainNames* = Call_PostListDomainNames_593701(
    name: "postListDomainNames", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_PostListDomainNames_593702, base: "/",
    url: url_PostListDomainNames_593703, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomainNames_593686 = ref object of OpenApiRestCall_592364
proc url_GetListDomainNames_593688(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListDomainNames_593687(path: JsonNode; query: JsonNode;
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
  var valid_593689 = query.getOrDefault("Action")
  valid_593689 = validateParameter(valid_593689, JString, required = true,
                                 default = newJString("ListDomainNames"))
  if valid_593689 != nil:
    section.add "Action", valid_593689
  var valid_593690 = query.getOrDefault("Version")
  valid_593690 = validateParameter(valid_593690, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593690 != nil:
    section.add "Version", valid_593690
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
  var valid_593691 = header.getOrDefault("X-Amz-Signature")
  valid_593691 = validateParameter(valid_593691, JString, required = false,
                                 default = nil)
  if valid_593691 != nil:
    section.add "X-Amz-Signature", valid_593691
  var valid_593692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593692 = validateParameter(valid_593692, JString, required = false,
                                 default = nil)
  if valid_593692 != nil:
    section.add "X-Amz-Content-Sha256", valid_593692
  var valid_593693 = header.getOrDefault("X-Amz-Date")
  valid_593693 = validateParameter(valid_593693, JString, required = false,
                                 default = nil)
  if valid_593693 != nil:
    section.add "X-Amz-Date", valid_593693
  var valid_593694 = header.getOrDefault("X-Amz-Credential")
  valid_593694 = validateParameter(valid_593694, JString, required = false,
                                 default = nil)
  if valid_593694 != nil:
    section.add "X-Amz-Credential", valid_593694
  var valid_593695 = header.getOrDefault("X-Amz-Security-Token")
  valid_593695 = validateParameter(valid_593695, JString, required = false,
                                 default = nil)
  if valid_593695 != nil:
    section.add "X-Amz-Security-Token", valid_593695
  var valid_593696 = header.getOrDefault("X-Amz-Algorithm")
  valid_593696 = validateParameter(valid_593696, JString, required = false,
                                 default = nil)
  if valid_593696 != nil:
    section.add "X-Amz-Algorithm", valid_593696
  var valid_593697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593697 = validateParameter(valid_593697, JString, required = false,
                                 default = nil)
  if valid_593697 != nil:
    section.add "X-Amz-SignedHeaders", valid_593697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593698: Call_GetListDomainNames_593686; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_593698.validator(path, query, header, formData, body)
  let scheme = call_593698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593698.url(scheme.get, call_593698.host, call_593698.base,
                         call_593698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593698, url, valid)

proc call*(call_593699: Call_GetListDomainNames_593686;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## getListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593700 = newJObject()
  add(query_593700, "Action", newJString(Action))
  add(query_593700, "Version", newJString(Version))
  result = call_593699.call(nil, query_593700, nil, nil, nil)

var getListDomainNames* = Call_GetListDomainNames_593686(
    name: "getListDomainNames", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_GetListDomainNames_593687, base: "/",
    url: url_GetListDomainNames_593688, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_593733 = ref object of OpenApiRestCall_592364
proc url_PostUpdateAvailabilityOptions_593735(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateAvailabilityOptions_593734(path: JsonNode; query: JsonNode;
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
  var valid_593736 = query.getOrDefault("Action")
  valid_593736 = validateParameter(valid_593736, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_593736 != nil:
    section.add "Action", valid_593736
  var valid_593737 = query.getOrDefault("Version")
  valid_593737 = validateParameter(valid_593737, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593737 != nil:
    section.add "Version", valid_593737
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
  var valid_593738 = header.getOrDefault("X-Amz-Signature")
  valid_593738 = validateParameter(valid_593738, JString, required = false,
                                 default = nil)
  if valid_593738 != nil:
    section.add "X-Amz-Signature", valid_593738
  var valid_593739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593739 = validateParameter(valid_593739, JString, required = false,
                                 default = nil)
  if valid_593739 != nil:
    section.add "X-Amz-Content-Sha256", valid_593739
  var valid_593740 = header.getOrDefault("X-Amz-Date")
  valid_593740 = validateParameter(valid_593740, JString, required = false,
                                 default = nil)
  if valid_593740 != nil:
    section.add "X-Amz-Date", valid_593740
  var valid_593741 = header.getOrDefault("X-Amz-Credential")
  valid_593741 = validateParameter(valid_593741, JString, required = false,
                                 default = nil)
  if valid_593741 != nil:
    section.add "X-Amz-Credential", valid_593741
  var valid_593742 = header.getOrDefault("X-Amz-Security-Token")
  valid_593742 = validateParameter(valid_593742, JString, required = false,
                                 default = nil)
  if valid_593742 != nil:
    section.add "X-Amz-Security-Token", valid_593742
  var valid_593743 = header.getOrDefault("X-Amz-Algorithm")
  valid_593743 = validateParameter(valid_593743, JString, required = false,
                                 default = nil)
  if valid_593743 != nil:
    section.add "X-Amz-Algorithm", valid_593743
  var valid_593744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593744 = validateParameter(valid_593744, JString, required = false,
                                 default = nil)
  if valid_593744 != nil:
    section.add "X-Amz-SignedHeaders", valid_593744
  result.add "header", section
  ## parameters in `formData` object:
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `MultiAZ` field"
  var valid_593745 = formData.getOrDefault("MultiAZ")
  valid_593745 = validateParameter(valid_593745, JBool, required = true, default = nil)
  if valid_593745 != nil:
    section.add "MultiAZ", valid_593745
  var valid_593746 = formData.getOrDefault("DomainName")
  valid_593746 = validateParameter(valid_593746, JString, required = true,
                                 default = nil)
  if valid_593746 != nil:
    section.add "DomainName", valid_593746
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593747: Call_PostUpdateAvailabilityOptions_593733; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593747.validator(path, query, header, formData, body)
  let scheme = call_593747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593747.url(scheme.get, call_593747.host, call_593747.base,
                         call_593747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593747, url, valid)

proc call*(call_593748: Call_PostUpdateAvailabilityOptions_593733; MultiAZ: bool;
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
  var query_593749 = newJObject()
  var formData_593750 = newJObject()
  add(formData_593750, "MultiAZ", newJBool(MultiAZ))
  add(formData_593750, "DomainName", newJString(DomainName))
  add(query_593749, "Action", newJString(Action))
  add(query_593749, "Version", newJString(Version))
  result = call_593748.call(nil, query_593749, nil, formData_593750, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_593733(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_593734, base: "/",
    url: url_PostUpdateAvailabilityOptions_593735,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_593716 = ref object of OpenApiRestCall_592364
proc url_GetUpdateAvailabilityOptions_593718(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateAvailabilityOptions_593717(path: JsonNode; query: JsonNode;
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
  var valid_593719 = query.getOrDefault("DomainName")
  valid_593719 = validateParameter(valid_593719, JString, required = true,
                                 default = nil)
  if valid_593719 != nil:
    section.add "DomainName", valid_593719
  var valid_593720 = query.getOrDefault("Action")
  valid_593720 = validateParameter(valid_593720, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_593720 != nil:
    section.add "Action", valid_593720
  var valid_593721 = query.getOrDefault("MultiAZ")
  valid_593721 = validateParameter(valid_593721, JBool, required = true, default = nil)
  if valid_593721 != nil:
    section.add "MultiAZ", valid_593721
  var valid_593722 = query.getOrDefault("Version")
  valid_593722 = validateParameter(valid_593722, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593722 != nil:
    section.add "Version", valid_593722
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
  var valid_593723 = header.getOrDefault("X-Amz-Signature")
  valid_593723 = validateParameter(valid_593723, JString, required = false,
                                 default = nil)
  if valid_593723 != nil:
    section.add "X-Amz-Signature", valid_593723
  var valid_593724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593724 = validateParameter(valid_593724, JString, required = false,
                                 default = nil)
  if valid_593724 != nil:
    section.add "X-Amz-Content-Sha256", valid_593724
  var valid_593725 = header.getOrDefault("X-Amz-Date")
  valid_593725 = validateParameter(valid_593725, JString, required = false,
                                 default = nil)
  if valid_593725 != nil:
    section.add "X-Amz-Date", valid_593725
  var valid_593726 = header.getOrDefault("X-Amz-Credential")
  valid_593726 = validateParameter(valid_593726, JString, required = false,
                                 default = nil)
  if valid_593726 != nil:
    section.add "X-Amz-Credential", valid_593726
  var valid_593727 = header.getOrDefault("X-Amz-Security-Token")
  valid_593727 = validateParameter(valid_593727, JString, required = false,
                                 default = nil)
  if valid_593727 != nil:
    section.add "X-Amz-Security-Token", valid_593727
  var valid_593728 = header.getOrDefault("X-Amz-Algorithm")
  valid_593728 = validateParameter(valid_593728, JString, required = false,
                                 default = nil)
  if valid_593728 != nil:
    section.add "X-Amz-Algorithm", valid_593728
  var valid_593729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593729 = validateParameter(valid_593729, JString, required = false,
                                 default = nil)
  if valid_593729 != nil:
    section.add "X-Amz-SignedHeaders", valid_593729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593730: Call_GetUpdateAvailabilityOptions_593716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593730.validator(path, query, header, formData, body)
  let scheme = call_593730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593730.url(scheme.get, call_593730.host, call_593730.base,
                         call_593730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593730, url, valid)

proc call*(call_593731: Call_GetUpdateAvailabilityOptions_593716;
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
  var query_593732 = newJObject()
  add(query_593732, "DomainName", newJString(DomainName))
  add(query_593732, "Action", newJString(Action))
  add(query_593732, "MultiAZ", newJBool(MultiAZ))
  add(query_593732, "Version", newJString(Version))
  result = call_593731.call(nil, query_593732, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_593716(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_593717, base: "/",
    url: url_GetUpdateAvailabilityOptions_593718,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateScalingParameters_593770 = ref object of OpenApiRestCall_592364
proc url_PostUpdateScalingParameters_593772(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateScalingParameters_593771(path: JsonNode; query: JsonNode;
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
  var valid_593773 = query.getOrDefault("Action")
  valid_593773 = validateParameter(valid_593773, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_593773 != nil:
    section.add "Action", valid_593773
  var valid_593774 = query.getOrDefault("Version")
  valid_593774 = validateParameter(valid_593774, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593774 != nil:
    section.add "Version", valid_593774
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
  var valid_593775 = header.getOrDefault("X-Amz-Signature")
  valid_593775 = validateParameter(valid_593775, JString, required = false,
                                 default = nil)
  if valid_593775 != nil:
    section.add "X-Amz-Signature", valid_593775
  var valid_593776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593776 = validateParameter(valid_593776, JString, required = false,
                                 default = nil)
  if valid_593776 != nil:
    section.add "X-Amz-Content-Sha256", valid_593776
  var valid_593777 = header.getOrDefault("X-Amz-Date")
  valid_593777 = validateParameter(valid_593777, JString, required = false,
                                 default = nil)
  if valid_593777 != nil:
    section.add "X-Amz-Date", valid_593777
  var valid_593778 = header.getOrDefault("X-Amz-Credential")
  valid_593778 = validateParameter(valid_593778, JString, required = false,
                                 default = nil)
  if valid_593778 != nil:
    section.add "X-Amz-Credential", valid_593778
  var valid_593779 = header.getOrDefault("X-Amz-Security-Token")
  valid_593779 = validateParameter(valid_593779, JString, required = false,
                                 default = nil)
  if valid_593779 != nil:
    section.add "X-Amz-Security-Token", valid_593779
  var valid_593780 = header.getOrDefault("X-Amz-Algorithm")
  valid_593780 = validateParameter(valid_593780, JString, required = false,
                                 default = nil)
  if valid_593780 != nil:
    section.add "X-Amz-Algorithm", valid_593780
  var valid_593781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593781 = validateParameter(valid_593781, JString, required = false,
                                 default = nil)
  if valid_593781 != nil:
    section.add "X-Amz-SignedHeaders", valid_593781
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
  var valid_593782 = formData.getOrDefault("ScalingParameters.DesiredReplicationCount")
  valid_593782 = validateParameter(valid_593782, JString, required = false,
                                 default = nil)
  if valid_593782 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_593782
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593783 = formData.getOrDefault("DomainName")
  valid_593783 = validateParameter(valid_593783, JString, required = true,
                                 default = nil)
  if valid_593783 != nil:
    section.add "DomainName", valid_593783
  var valid_593784 = formData.getOrDefault("ScalingParameters.DesiredPartitionCount")
  valid_593784 = validateParameter(valid_593784, JString, required = false,
                                 default = nil)
  if valid_593784 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_593784
  var valid_593785 = formData.getOrDefault("ScalingParameters.DesiredInstanceType")
  valid_593785 = validateParameter(valid_593785, JString, required = false,
                                 default = nil)
  if valid_593785 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_593785
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593786: Call_PostUpdateScalingParameters_593770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_593786.validator(path, query, header, formData, body)
  let scheme = call_593786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593786.url(scheme.get, call_593786.host, call_593786.base,
                         call_593786.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593786, url, valid)

proc call*(call_593787: Call_PostUpdateScalingParameters_593770;
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
  var query_593788 = newJObject()
  var formData_593789 = newJObject()
  add(formData_593789, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  add(formData_593789, "DomainName", newJString(DomainName))
  add(query_593788, "Action", newJString(Action))
  add(formData_593789, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(formData_593789, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  add(query_593788, "Version", newJString(Version))
  result = call_593787.call(nil, query_593788, nil, formData_593789, nil)

var postUpdateScalingParameters* = Call_PostUpdateScalingParameters_593770(
    name: "postUpdateScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_PostUpdateScalingParameters_593771, base: "/",
    url: url_PostUpdateScalingParameters_593772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateScalingParameters_593751 = ref object of OpenApiRestCall_592364
proc url_GetUpdateScalingParameters_593753(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateScalingParameters_593752(path: JsonNode; query: JsonNode;
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
  var valid_593754 = query.getOrDefault("ScalingParameters.DesiredPartitionCount")
  valid_593754 = validateParameter(valid_593754, JString, required = false,
                                 default = nil)
  if valid_593754 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_593754
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_593755 = query.getOrDefault("DomainName")
  valid_593755 = validateParameter(valid_593755, JString, required = true,
                                 default = nil)
  if valid_593755 != nil:
    section.add "DomainName", valid_593755
  var valid_593756 = query.getOrDefault("ScalingParameters.DesiredInstanceType")
  valid_593756 = validateParameter(valid_593756, JString, required = false,
                                 default = nil)
  if valid_593756 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_593756
  var valid_593757 = query.getOrDefault("Action")
  valid_593757 = validateParameter(valid_593757, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_593757 != nil:
    section.add "Action", valid_593757
  var valid_593758 = query.getOrDefault("Version")
  valid_593758 = validateParameter(valid_593758, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593758 != nil:
    section.add "Version", valid_593758
  var valid_593759 = query.getOrDefault("ScalingParameters.DesiredReplicationCount")
  valid_593759 = validateParameter(valid_593759, JString, required = false,
                                 default = nil)
  if valid_593759 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_593759
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
  var valid_593760 = header.getOrDefault("X-Amz-Signature")
  valid_593760 = validateParameter(valid_593760, JString, required = false,
                                 default = nil)
  if valid_593760 != nil:
    section.add "X-Amz-Signature", valid_593760
  var valid_593761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593761 = validateParameter(valid_593761, JString, required = false,
                                 default = nil)
  if valid_593761 != nil:
    section.add "X-Amz-Content-Sha256", valid_593761
  var valid_593762 = header.getOrDefault("X-Amz-Date")
  valid_593762 = validateParameter(valid_593762, JString, required = false,
                                 default = nil)
  if valid_593762 != nil:
    section.add "X-Amz-Date", valid_593762
  var valid_593763 = header.getOrDefault("X-Amz-Credential")
  valid_593763 = validateParameter(valid_593763, JString, required = false,
                                 default = nil)
  if valid_593763 != nil:
    section.add "X-Amz-Credential", valid_593763
  var valid_593764 = header.getOrDefault("X-Amz-Security-Token")
  valid_593764 = validateParameter(valid_593764, JString, required = false,
                                 default = nil)
  if valid_593764 != nil:
    section.add "X-Amz-Security-Token", valid_593764
  var valid_593765 = header.getOrDefault("X-Amz-Algorithm")
  valid_593765 = validateParameter(valid_593765, JString, required = false,
                                 default = nil)
  if valid_593765 != nil:
    section.add "X-Amz-Algorithm", valid_593765
  var valid_593766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593766 = validateParameter(valid_593766, JString, required = false,
                                 default = nil)
  if valid_593766 != nil:
    section.add "X-Amz-SignedHeaders", valid_593766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593767: Call_GetUpdateScalingParameters_593751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_593767.validator(path, query, header, formData, body)
  let scheme = call_593767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593767.url(scheme.get, call_593767.host, call_593767.base,
                         call_593767.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593767, url, valid)

proc call*(call_593768: Call_GetUpdateScalingParameters_593751; DomainName: string;
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
  var query_593769 = newJObject()
  add(query_593769, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(query_593769, "DomainName", newJString(DomainName))
  add(query_593769, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  add(query_593769, "Action", newJString(Action))
  add(query_593769, "Version", newJString(Version))
  add(query_593769, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  result = call_593768.call(nil, query_593769, nil, nil, nil)

var getUpdateScalingParameters* = Call_GetUpdateScalingParameters_593751(
    name: "getUpdateScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_GetUpdateScalingParameters_593752, base: "/",
    url: url_GetUpdateScalingParameters_593753,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_593807 = ref object of OpenApiRestCall_592364
proc url_PostUpdateServiceAccessPolicies_593809(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateServiceAccessPolicies_593808(path: JsonNode;
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
  var valid_593810 = query.getOrDefault("Action")
  valid_593810 = validateParameter(valid_593810, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_593810 != nil:
    section.add "Action", valid_593810
  var valid_593811 = query.getOrDefault("Version")
  valid_593811 = validateParameter(valid_593811, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593811 != nil:
    section.add "Version", valid_593811
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
  var valid_593812 = header.getOrDefault("X-Amz-Signature")
  valid_593812 = validateParameter(valid_593812, JString, required = false,
                                 default = nil)
  if valid_593812 != nil:
    section.add "X-Amz-Signature", valid_593812
  var valid_593813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593813 = validateParameter(valid_593813, JString, required = false,
                                 default = nil)
  if valid_593813 != nil:
    section.add "X-Amz-Content-Sha256", valid_593813
  var valid_593814 = header.getOrDefault("X-Amz-Date")
  valid_593814 = validateParameter(valid_593814, JString, required = false,
                                 default = nil)
  if valid_593814 != nil:
    section.add "X-Amz-Date", valid_593814
  var valid_593815 = header.getOrDefault("X-Amz-Credential")
  valid_593815 = validateParameter(valid_593815, JString, required = false,
                                 default = nil)
  if valid_593815 != nil:
    section.add "X-Amz-Credential", valid_593815
  var valid_593816 = header.getOrDefault("X-Amz-Security-Token")
  valid_593816 = validateParameter(valid_593816, JString, required = false,
                                 default = nil)
  if valid_593816 != nil:
    section.add "X-Amz-Security-Token", valid_593816
  var valid_593817 = header.getOrDefault("X-Amz-Algorithm")
  valid_593817 = validateParameter(valid_593817, JString, required = false,
                                 default = nil)
  if valid_593817 != nil:
    section.add "X-Amz-Algorithm", valid_593817
  var valid_593818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593818 = validateParameter(valid_593818, JString, required = false,
                                 default = nil)
  if valid_593818 != nil:
    section.add "X-Amz-SignedHeaders", valid_593818
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
  var valid_593819 = formData.getOrDefault("AccessPolicies")
  valid_593819 = validateParameter(valid_593819, JString, required = true,
                                 default = nil)
  if valid_593819 != nil:
    section.add "AccessPolicies", valid_593819
  var valid_593820 = formData.getOrDefault("DomainName")
  valid_593820 = validateParameter(valid_593820, JString, required = true,
                                 default = nil)
  if valid_593820 != nil:
    section.add "DomainName", valid_593820
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593821: Call_PostUpdateServiceAccessPolicies_593807;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_593821.validator(path, query, header, formData, body)
  let scheme = call_593821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593821.url(scheme.get, call_593821.host, call_593821.base,
                         call_593821.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593821, url, valid)

proc call*(call_593822: Call_PostUpdateServiceAccessPolicies_593807;
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
  var query_593823 = newJObject()
  var formData_593824 = newJObject()
  add(formData_593824, "AccessPolicies", newJString(AccessPolicies))
  add(formData_593824, "DomainName", newJString(DomainName))
  add(query_593823, "Action", newJString(Action))
  add(query_593823, "Version", newJString(Version))
  result = call_593822.call(nil, query_593823, nil, formData_593824, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_593807(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_593808, base: "/",
    url: url_PostUpdateServiceAccessPolicies_593809,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_593790 = ref object of OpenApiRestCall_592364
proc url_GetUpdateServiceAccessPolicies_593792(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateServiceAccessPolicies_593791(path: JsonNode;
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
  var valid_593793 = query.getOrDefault("DomainName")
  valid_593793 = validateParameter(valid_593793, JString, required = true,
                                 default = nil)
  if valid_593793 != nil:
    section.add "DomainName", valid_593793
  var valid_593794 = query.getOrDefault("Action")
  valid_593794 = validateParameter(valid_593794, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_593794 != nil:
    section.add "Action", valid_593794
  var valid_593795 = query.getOrDefault("Version")
  valid_593795 = validateParameter(valid_593795, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_593795 != nil:
    section.add "Version", valid_593795
  var valid_593796 = query.getOrDefault("AccessPolicies")
  valid_593796 = validateParameter(valid_593796, JString, required = true,
                                 default = nil)
  if valid_593796 != nil:
    section.add "AccessPolicies", valid_593796
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
  var valid_593797 = header.getOrDefault("X-Amz-Signature")
  valid_593797 = validateParameter(valid_593797, JString, required = false,
                                 default = nil)
  if valid_593797 != nil:
    section.add "X-Amz-Signature", valid_593797
  var valid_593798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593798 = validateParameter(valid_593798, JString, required = false,
                                 default = nil)
  if valid_593798 != nil:
    section.add "X-Amz-Content-Sha256", valid_593798
  var valid_593799 = header.getOrDefault("X-Amz-Date")
  valid_593799 = validateParameter(valid_593799, JString, required = false,
                                 default = nil)
  if valid_593799 != nil:
    section.add "X-Amz-Date", valid_593799
  var valid_593800 = header.getOrDefault("X-Amz-Credential")
  valid_593800 = validateParameter(valid_593800, JString, required = false,
                                 default = nil)
  if valid_593800 != nil:
    section.add "X-Amz-Credential", valid_593800
  var valid_593801 = header.getOrDefault("X-Amz-Security-Token")
  valid_593801 = validateParameter(valid_593801, JString, required = false,
                                 default = nil)
  if valid_593801 != nil:
    section.add "X-Amz-Security-Token", valid_593801
  var valid_593802 = header.getOrDefault("X-Amz-Algorithm")
  valid_593802 = validateParameter(valid_593802, JString, required = false,
                                 default = nil)
  if valid_593802 != nil:
    section.add "X-Amz-Algorithm", valid_593802
  var valid_593803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593803 = validateParameter(valid_593803, JString, required = false,
                                 default = nil)
  if valid_593803 != nil:
    section.add "X-Amz-SignedHeaders", valid_593803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593804: Call_GetUpdateServiceAccessPolicies_593790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_593804.validator(path, query, header, formData, body)
  let scheme = call_593804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593804.url(scheme.get, call_593804.host, call_593804.base,
                         call_593804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593804, url, valid)

proc call*(call_593805: Call_GetUpdateServiceAccessPolicies_593790;
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
  var query_593806 = newJObject()
  add(query_593806, "DomainName", newJString(DomainName))
  add(query_593806, "Action", newJString(Action))
  add(query_593806, "Version", newJString(Version))
  add(query_593806, "AccessPolicies", newJString(AccessPolicies))
  result = call_593805.call(nil, query_593806, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_593790(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_593791, base: "/",
    url: url_GetUpdateServiceAccessPolicies_593792,
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
